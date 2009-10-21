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
public class FsoFramework.BaseTransport : FsoFramework.Transport
{
    protected string name;
    protected uint speed;
    protected bool raw;
    protected bool hard;
    protected int fd = -1;

    private IOChannel channel;

    private uint readwatch;
    private int readpriority;
    private uint writewatch;
    private int writepriority;

    protected TransportHupFunc hupfunc;
    protected TransportReadFunc readfunc;

    protected ByteArray buffer;

    protected FsoFramework.Logger logger;

    protected void restartWriter()
    {
        writewatch = channel.add_watch_full( writepriority, IOCondition.OUT, writeCallback );
    }

    private bool actionCallback( IOChannel source, IOCondition condition )
    {
        assert( logger.debug( "actionCallback called with condition = %d".printf( condition ) ) );

        if ( ( condition & IOCondition.HUP ) == IOCondition.HUP )
        {
            if ( hupfunc != null )
                hupfunc( this );
            return false;
        }

        if ( ( condition & IOCondition.IN ) == IOCondition.IN )
        {
            if ( readfunc != null )
                readfunc( this );
            return true;
        }

        logger.warning( "actionCallback called with unknown condition %d".printf( condition ) );

        return false;
    }

    private bool writeCallback( IOChannel source, IOCondition condition )
    {
        assert( logger.debug( "writeCallback called with %u bytes in buffer".printf( buffer.len ) ) );
        /*
        for( int i = 0; i < buffer.len; ++i )
        logger.debug( "byte: 0x%02x".printf( buffer.data[i] ) );
        */
        int len = 64 > buffer.len? (int)buffer.len : 64;
        var byteswritten = _write( buffer.data, len );
        assert( logger.debug( "writeCallback wrote %d bytes".printf( (int)byteswritten ) ) );
        buffer.remove_range( 0, (int)byteswritten );

        return ( buffer.len != 0 );
    }

    internal int _write( void* data, int len )
    {
        assert( fd != -1 );
        ssize_t byteswritten = Posix.write( fd, data, len );
        return (int)byteswritten;
    }

    internal void configure()
    {
        Posix.fcntl( fd, Posix.F_SETFL, 0 );
        Posix.termios termios = {};
        Posix.tcgetattr( fd, termios );

        Posix.speed_t tspeed;

        switch ( speed )
        {
            case 0:
                tspeed = Posix.B0;
                break;
            case 50:
                tspeed = Posix.B50;
                break;
            case 75:
                tspeed = Posix.B75;
                break;
            case 110:
                tspeed = Posix.B110;
                break;
            case 134:
                tspeed = Posix.B134;
                break;
            case 150:
                tspeed = Posix.B150;
                break;
            case 200:
                tspeed = Posix.B200;
                break;
            case 300:
                tspeed = Posix.B300;
                break;
            case 600:
                tspeed = Posix.B600;
                break;
            case 1200:
                tspeed = Posix.B1200;
                break;
            case 1800:
                tspeed = Posix.B1800;
                break;
            case 2400:
                tspeed = Posix.B2400;
                break;
            case 4800:
                tspeed = Posix.B4800;
                break;
            case 9600:
                tspeed = Posix.B9600;
                break;
            case 19200:
                tspeed = Posix.B19200;
                break;
            case 38400:
                tspeed = Posix.B38400;
                break;
            case 57600:
                tspeed = Posix.B57600;
                break;
            case 115200:
                tspeed = Posix.B115200;
                break;
            case 230400:
                tspeed = Posix.B230400;
                break;
            case 460800:
                tspeed = Linux.Termios.B460800;
                break;
            case 500000:
                tspeed = Linux.Termios.B500000;
                break;
            case 576000:
                tspeed = Linux.Termios.B576000;
                break;
            case 921600:
                tspeed = Linux.Termios.B921600;
                break;
            case 1000000:
                tspeed = Linux.Termios.B1000000;
                break;
            case 1152000:
                tspeed = Linux.Termios.B1152000;
                break;
            case 1500000:
                tspeed = Linux.Termios.B1500000;
                break;
            case 2000000:
                tspeed = Linux.Termios.B2000000;
                break;
            case 2500000:
                tspeed = Linux.Termios.B2500000;
                break;
            case 3000000:
                tspeed = Linux.Termios.B3000000;
                break;
            case 3500000:
                tspeed = Linux.Termios.B3500000;
                break;
            case 4000000:
                tspeed = Linux.Termios.B4000000;
                break;
            default:
                logger.warning( "invalid speed '%u' selected. using '0'".printf( speed ) );
                tspeed = Posix.B0;
                break;
        }

        Posix.cfsetispeed( termios, tspeed );
        Posix.cfsetospeed( termios, tspeed );

        // local read
        termios.c_cflag |= (Posix.CLOCAL | Posix.CREAD);

        // 8n1
        termios.c_cflag &= ~Posix.PARENB;
        termios.c_cflag &= ~Posix.CSTOPB;
        termios.c_cflag &= ~Posix.CSIZE;
        termios.c_cflag |= Posix.CS8;

        if ( hard )
        {
            // hardware flow control ON
            termios.c_cflag |= Linux.Termios.CRTSCTS;

            // software flow control OFF
            termios.c_iflag &= ~(Posix.IXON | Posix.IXOFF | Posix.IXANY);
        }
        else
        {
            // hardware flow control OFF
            termios.c_cflag &= Linux.Termios.CRTSCTS;

            // software flow control ON
            termios.c_iflag |= ~(Posix.IXON | Posix.IXOFF | Posix.IXANY);
        }

        if ( raw )
        {
            // raw input
            termios.c_lflag &= ~(Posix.ICANON | Posix.ECHO | Posix.ECHOE | Posix.ISIG);
            termios.c_iflag &= ~(Posix.INLCR | Posix.ICRNL | Posix.IGNCR);

            // raw output
            termios.c_oflag &= ~(Posix.OPOST | Linux.Termios.OLCUC | Posix.ONLRET | Posix.ONOCR | Posix.OCRNL );

            // no special character handling
            termios.c_cc[Posix.VMIN] = 0;
            termios.c_cc[Posix.VTIME] = 2;
            termios.c_cc[Posix.VINTR] = 0;
            termios.c_cc[Posix.VQUIT] = 0;
            termios.c_cc[Posix.VSTART] = 0;
            termios.c_cc[Posix.VSTOP] = 0;

            termios.c_cc[Posix.VSUSP] = 0;
        }
        var ok = Posix.tcsetattr( fd, Posix.TCSANOW, termios);
        if ( ok == -1 )
        {
            logger.error( "could not configure fd %d: %s".printf( fd, Posix.strerror( Posix.errno ) ) );
        }

        if ( hard )
        {
            // set ready to read/write
            var v24 = Linux.Termios.TIOCM_DTR | Linux.Termios.TIOCM_RTS;
            Posix.ioctl( fd, Linux.Termios.TIOCMBIS, &v24 );
        }
    }

    public virtual string repr()
    {
        return "<fd %d>".printf( fd );
    }

    //
    // public API
    //

    public BaseTransport( string name,
                          uint speed = 0,
                          bool raw = true,
                          bool hard = true )
    {
        this.name = name;
        this.speed = speed;
        this.raw = raw;
        this.hard = hard;
        buffer = new ByteArray();

        // FIXME: Creating the debug logger may be better done in the global
        // library initializer (e.g. void __attribute__ ((constructor)) my_init(void); )
        var smk = new FsoFramework.SmartKeyFile();
        // FIXME: Do not hardcode this
        if ( smk.loadFromFile( "/etc/frameworkd.conf" ) )
        {
            logger = FsoFramework.Logger.createFromKeyFile( smk, "libfsotransport", "libfsotransport" );
            logger.setReprDelegate( repr );
        }
        else
        {
            logger = new FsoFramework.NullLogger( "none" );
        }

        assert( logger.debug( "created" ) );
    }

    ~BaseTransport()
    {
        assert( logger.debug( "destroyed" ) );
    }

    public override string getName()
    {
        return name;
    }

    public override bool open()
    {
        assert( fd != -1 ); // fail, if trying to open the 2nd time
        // construct IO channel
        channel = new IOChannel.unix_new( fd );
        try
        {
            channel.set_encoding( null );
        }
        catch ( GLib.IOChannelError e )
        {
            logger.warning( "error while setting channel encoding to null" );
        }
        channel.set_buffer_size( 32768 );
        // setup watch
        readwatch = channel.add_watch_full( readpriority, IOCondition.IN | IOCondition.HUP, actionCallback );
        // we might have already queued something up in the buffer
        if ( buffer.len > 0 )
            restartWriter();

        assert( logger.debug( "opened" ) );
        return true;
    }

    public override void close()
    {
        if ( readwatch != 0 )
            Source.remove( readwatch );
        channel = null;
        if ( fd != -1 )
            Posix.close( fd );
        fd = -1; // mark closed
        assert( logger.debug( "closed" ) );
    }

    public override bool isOpen()
    {
        return ( fd != -1 );
    }

    public override void setDelegates( TransportReadFunc? readfunc, TransportHupFunc? hupfunc )
    {
        this.readfunc = readfunc;
        this.hupfunc = hupfunc;
    }

    public override void setPriorities( int rp, int wp )
    {
        this.readpriority = rp;
        this.writepriority = wp;
    }

    public override void getDelegates( out TransportReadFunc? readfun, out TransportHupFunc? hupfun )
    {
        readfun = this.readfunc;
        hupfun = this.hupfunc;
    }

    public override int read( void* data, int len )
    {
        assert( fd != -1 );
        assert( data != null );
        ssize_t bytesread = Posix.read( fd, data, len );
        //TODO: what to do if we got 0 bytes?
        return (int)bytesread;
    }

    public override int write( void* data, int len )
    {
        assert( logger.debug( "writing %d bytes".printf( len ) ) );
        assert( data != null );
        if ( fd == -1 )
        {
            logger.warning( "writing although transport still closed; buffering." );
        }
        var restart = ( fd != -1 && buffer.len == 0 );
        //TODO: avoid copying the buffer
        var temp = new uint8[len];
        Memory.copy( temp, data, len );
        buffer.append( temp );

        if ( restart )
            restartWriter();
        return len;
    }

    public override int writeAndRead( void* wdata, int wlength, void* rdata, int rlength, int maxWait = 1000 )
    {
        assert( fd != -1 );
        ssize_t byteswritten = Posix.write( fd, wdata, wlength );
        Posix.tcdrain( fd );

        var readfds = Posix.fd_set();
        var writefds = Posix.fd_set();
        var exceptfds = Posix.fd_set();
        Posix.FD_SET( fd, readfds );
        Posix.timeval t = { 1, 0 };
        int res = Posix.select( fd+1, readfds, writefds, exceptfds, t );
        if ( res < 0 || Posix.FD_ISSET( fd, readfds ) == 0 )
            return 0;
        ssize_t bread = Posix.read( fd, rdata, rlength );
        return (int)bread;
    }

    public override void freeze()
    {
        if ( buffer.len > 0 )
        {
            logger.warning( "freeze called while buffer not yet empty" );
        }
        if ( readwatch != 0 )
        {
            Source.remove( readwatch );
            readwatch = 0;
        }
        if ( writewatch != 0 )
        {
            Source.remove( writewatch );
            writewatch = 0;
        }
        assert( logger.debug( "frozen" ) );
    }

    public override void thaw()
    {
        // setup watch
        readwatch = channel.add_watch_full( readpriority, IOCondition.IN | IOCondition.HUP, actionCallback );
        // we might have already queued something up in the buffer
        if ( buffer.len > 0 )
            restartWriter();
        logger.debug( "thawn" );
    }
}
