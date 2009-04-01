/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

using GLib;

//===========================================================================
public errordomain FsoFramework.TransportError
{
    UNABLE_TO_OPEN,
    UNABLE_TO_WRITE,
}

//===========================================================================
public enum FsoFramework.TransportState
{
    CLOSED,
    OPEN,
    ALIVE,
    DEAD,
}

//===========================================================================
public abstract interface FsoFramework.Transport : Object
{
    public abstract int write( void* data, int length );
}

//===========================================================================
public class FsoFramework.BaseTransport : FsoFramework.Transport, Object
{
    protected Logger logger;

    protected string name;
    protected uint speed;
    protected int fd = -1;

    private IOChannel channel;

    private uint readwatch;
    private int readpriority;
    private uint writewatch;
    private int writepriority;

    protected TransportHupFunc hupfunc;
    protected TransportReadFunc readfunc;

    protected ByteArray buffer;

    protected void restartWriter()
    {
        writewatch = channel.add_watch_full( writepriority, IOCondition.OUT, writeCallback );
    }

    //
    // public API
    //
    public BaseTransport( string name,
                          uint speed = 0,
                          TransportHupFunc? hupfunc = null,
                          TransportReadFunc? readfunc = null,
                          int rp = 0,
                          int wp = 0 )
    {
        this.name = name;
        this.speed = speed;
        this.hupfunc = hupfunc;
        this.readfunc = readfunc;
        readpriority = rp;
        writepriority = wp;
        buffer = new ByteArray();

        // create and configure the logger
        logger = FsoFramework.createLogger( "transport" );
        logger.setReprDelegate( repr );
        logger.debug( "created" );
    }

    public virtual string getName()
    {
        return name;
    }

    public virtual bool open()
    {
        assert( fd != -1 );
        // construct IO channel
        channel = new IOChannel.unix_new( fd );
        channel.set_encoding( null );
        channel.set_buffer_size( 32768 );
        // setup watches, if we have delegates
        if ( hupfunc != null || readfunc != null )
        {
            readwatch = channel.add_watch_full( readpriority, IOCondition.IN | IOCondition.HUP, actionCallback );
        }
        // we might have already queued something up in the buffer
        if ( buffer.len > 0 )
            restartWriter();

        return true;
    }

    public void close()
    {
        if ( readwatch != 0 )
            Source.remove( readwatch );
        channel = null;
        if ( fd != -1 )
            Posix.close( fd );
        logger.debug( "closed" );
    }

    public bool isOpen()
    {
        return ( fd != -1 );
    }

    public virtual string repr()
    {
        return "<BaseTransport fd %d>".printf( fd );
    }

    public int read( void* data, int len )
    {
        assert( fd != -1 );
        ssize_t bytesread = Posix.read( fd, data, len );
        return (int)bytesread;
    }

    public int _write( void* data, int len )
    {
        assert( fd != -1 );
        ssize_t byteswritten = Posix.write( fd, data, len );
        return (int)byteswritten;
    }

    public int write( void* data, int len )
    {
        var restart = ( fd != -1 && buffer.len == 0 );
        var temp = new uint8[len];
        Memory.copy( temp, data, len );
        buffer.append( temp );

        if ( restart )
            restartWriter();
        return len;
    }

    public bool actionCallback( IOChannel source, IOCondition condition )
    {
        logger.debug( "actionCallback called with condition = %d".printf( condition ) );
        if ( IOCondition.IN == condition && readfunc != null )
        {
            readfunc( this );
            return true;
        }
        if ( IOCondition.HUP == condition && hupfunc != null )
            hupfunc( this );
        return false;
    }

    public bool writeCallback( IOChannel source, IOCondition condition )
    {
        logger.debug( "writeCallback called with %u bytes in buffer".printf( buffer.len ) );
        /*
        for( int i = 0; i < buffer.len; ++i )
            logger.debug( "byte: 0x%02x".printf( buffer.data[i] ) );
        */
        int len = 64 > buffer.len? (int)buffer.len : 64;
        var byteswritten = _write( buffer.data, len );
        logger.debug( "writeCallback wrote %d bytes".printf( (int)byteswritten ) );
        buffer.remove_range( 0, (int)byteswritten );

        return ( buffer.len != 0 );
    }
}

//===========================================================================
public class FsoFramework.SerialTransport : FsoFramework.BaseTransport
//===========================================================================
{
    public SerialTransport( string portname,
                            uint portspeed,
                            TransportHupFunc? hupfunc = null,
                            TransportReadFunc? readfunc = null,
                            int rp = 0,
                            int wp = 0 )
    {
        base( portname, portspeed, hupfunc, readfunc, rp, wp );
    }

    public override bool open()
    {
        fd = Posix.open( name, Posix.O_RDWR | Posix.O_NOCTTY | Posix.O_NONBLOCK );
        if ( fd == -1 )
        {
            logger.warning( "could not open %s: %s".printf( name, Posix.strerror( Posix.errno ) ) );
            return false;
        }

        Posix.fcntl( fd, Posix.F_SETFL, 0 );
        PosixExtra.TermIOs termios = {};
        PosixExtra.tcgetattr( fd, termios );

        if ( speed == 115200 )
        {
            // 115200
            PosixExtra.cfsetispeed( termios, PosixExtra.B115200 );
            PosixExtra.cfsetospeed( termios, PosixExtra.B115200 );
        }
        else
            logger.warning( "portspeed != 115200" );

        // local read
        termios.c_cflag |= (PosixExtra.CLOCAL | PosixExtra.CREAD);

        // 8n1
        termios.c_cflag &= ~PosixExtra.PARENB;
        termios.c_cflag &= ~PosixExtra.CSTOPB;
        termios.c_cflag &= ~PosixExtra.CSIZE;
        termios.c_cflag |= PosixExtra.CS8;

        // hardware flow control
        //termios.c_cflag |= PosixExtra.CRTSCTS;

        // software flow control off
        //termios.c_iflag &= ~(PosixExtra.IXON | PosixExtra.IXOFF | PosixExtra.IXANY);

        // raw input
        termios.c_lflag &= ~(PosixExtra.ICANON | PosixExtra.ECHO | PosixExtra.ECHOE | PosixExtra.ISIG);
        termios.c_iflag &= ~(PosixExtra.INLCR | PosixExtra.ICRNL | PosixExtra.IGNCR);

        // raw output
        termios.c_oflag &= ~(PosixExtra.OPOST | PosixExtra.OLCUC | PosixExtra.ONLRET | PosixExtra.ONOCR | PosixExtra.OCRNL );

        /*
        // no special character handling
        termios.c_cc[PosixExtra.VMIN] = 0;
        termios.c_cc[PosixExtra.VTIME] = 2;
        termios.c_cc[PosixExtra.VINTR] = 0;
        termios.c_cc[PosixExtra.VQUIT] = 0;
        termios.c_cc[PosixExtra.VSTART] = 0;
        termios.c_cc[PosixExtra.VSTOP] = 0;
        termios.c_cc[PosixExtra.VSUSP] = 0;
        */
        PosixExtra.tcsetattr( fd, PosixExtra.TCSANOW, termios);

        /*
        _v24 = PosixExtra.TIOCM_DTR | PosixExtra.TIOCM_RTS;
        Posix.ioctl( _fd, PosixExtra.TIOCMBIS, &_v24 );
        */

        return base.open();
    }

    public override string repr()
    {
        return "<Serial Transport %s @ %u (fd %d)>".printf( name, speed, fd );
    }

}

//===========================================================================
public class FsoFramework.PtyTransport : FsoFramework.BaseTransport
//===========================================================================
{
    private char[] ptyname = new char[1024]; // PATH_MAX?

    public PtyTransport( TransportHupFunc? hupfunc = null,
                         TransportReadFunc? readfunc = null,
                         int rp = 0,
                         int wp = 0 )
    {
        base( "Pty", 115200, hupfunc, readfunc, rp, wp );
    }

    public override string getName()
    {
        return (string)ptyname;
    }

    public override string repr()
    {
        return "<Pseudo TTY %s (fd %d)>".printf( getName(), fd );
    }

    public override bool open()
    {
        fd = PosixExtra.posix_openpt( Posix.O_RDWR | Posix.O_NOCTTY | Posix.O_NONBLOCK );
        if ( fd == -1 )
        {
            logger.warning( "could not open %s: %s".printf( name, Posix.strerror( Posix.errno ) ) );
            return false;
        }

        PosixExtra.grantpt( fd );
        PosixExtra.unlockpt( fd );
        PosixExtra.ptsname_r( fd, ptyname );

        int flags = Posix.fcntl( fd, Posix.F_GETFL );
        int res = Posix.fcntl( fd, Posix.F_SETFL, flags | Posix.O_NONBLOCK );
        if ( res < 0 )
            logger.warning( "can't set pty master to NONBLOCK: %s".printf( Posix.strerror( Posix.errno ) ) );

        Posix.fcntl( fd, Posix.F_SETFL, 0 );

        PosixExtra.TermIOs termios = {};
        PosixExtra.tcgetattr( fd, termios );

        // local read
        termios.c_cflag |= (PosixExtra.CLOCAL | PosixExtra.CREAD);

        // 8n1
        termios.c_cflag &= ~PosixExtra.PARENB;
        termios.c_cflag &= ~PosixExtra.CSTOPB;
        termios.c_cflag &= ~PosixExtra.CSIZE;
        termios.c_cflag |= PosixExtra.CS8;

        // hardware flow control
        //termios.c_cflag |= PosixExtra.CRTSCTS;

        // software flow control off
        //termios.c_iflag &= ~(PosixExtra.IXON | PosixExtra.IXOFF | PosixExtra.IXANY);

        // raw input
        termios.c_lflag &= ~(PosixExtra.ICANON | PosixExtra.ECHO | PosixExtra.ECHOE | PosixExtra.ISIG);
        termios.c_iflag &= ~(PosixExtra.INLCR | PosixExtra.ICRNL | PosixExtra.IGNCR);

        // raw output
        termios.c_oflag &= ~(PosixExtra.OPOST | PosixExtra.OLCUC | PosixExtra.ONLRET | PosixExtra.ONOCR | PosixExtra.OCRNL );

        /*
        // no special character handling
        termios.c_cc[PosixExtra.VMIN] = 0;
        termios.c_cc[PosixExtra.VTIME] = 2;
        termios.c_cc[PosixExtra.VINTR] = 0;
        termios.c_cc[PosixExtra.VQUIT] = 0;
        termios.c_cc[PosixExtra.VSTART] = 0;
        termios.c_cc[PosixExtra.VSTOP] = 0;
        termios.c_cc[PosixExtra.VSUSP] = 0;
        */
        PosixExtra.tcsetattr( fd, PosixExtra.TCSANOW, termios);

        /*
        _v24 = PosixExtra.TIOCM_DTR | PosixExtra.TIOCM_RTS;
        Posix.ioctl( _fd, PosixExtra.TIOCMBIS, &_v24 );
        */
        return base.open();
    }
}

/*
//===========================================================================
public class LibGsm0710muxTransport : FsoFramework.BaseTransport
{
    Gsm0710mux.Manager manager;
    Gsm0710mux.ChannelInfo channelinfo;

    public LibGsm0710muxTransport()
    {
        manager = new Gsm0710mux.Manager();
        var version = manager.getVersion();
        var hasAutoSession = manager.hasAutoSession();
        debug( "TransportLibGsm0710mux created, using libgsm0710mux version %s; autosession is %s".printf( version, hasAutoSession.to_string() ) );

    }

    public void open() throws TransportError
    {

    
}
*/

//===========================================================================
public delegate void FsoFramework.TransportReadFunc( Transport transport );
public delegate void FsoFramework.TransportHupFunc( Transport transport );
