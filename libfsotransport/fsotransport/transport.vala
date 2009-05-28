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
    FROZEN,
    DEAD,
}

//===========================================================================
public abstract class FsoFramework.Transport : Object
{
    /**
     * @returns true, if the @a transport is open; else false.
     */
    public abstract bool isOpen();
    /**
     * Open the transport. @returns true, if successful; else false.
     */
    public abstract bool open();
    /**
     * Transport Configure the transport. @returns true, if successful; else false.
     **/
    public abstract string getName();
    /**
     * Set delegates being called when there is something to read or there has been an exception.
     **/
    public abstract void setDelegates( TransportReadFunc? readfunc, TransportHupFunc? hupfunc );
    /**
     * Get delegates
     **/
    public abstract void getDelegates( out TransportReadFunc? readfun, out TransportHupFunc? hupfun );
    /**
     * Set priorities for reading and writing
     **/
    public abstract void setPriorities( int rp, int wp );
    /**
     * Read data from the transport into buffer provided and owned by caller.
     **/
    public abstract int read( void* data, int len );
    /**
     * Pause reading and writing from/to the transport.
     **/
    public abstract void freeze();
    /**
     * Resume reading and writing from/to the transport.
     **/
    public abstract void thaw();
    /**
     * Close the transport. Closing an already closed transport is allowed.
     **/
    public abstract int write( void* data, int length );
    /**
     * Close the transport. Closing an already closed transport is allowed.
     **/
    public abstract void close();
    /**
     * Create @a FsoFramework.Transport as indicated by @a type
     **/
    public static Transport? create( string type, string name = "", uint speed = 0, bool raw = true, bool hard = true )
    {
        switch ( type )
        {
            case "serial":
                return new FsoFramework.SerialTransport( name, speed, raw, hard );
            case "pty":
                return new FsoFramework.PtyTransport();
            default:
                return null;
        }
    }
}

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

    protected void restartWriter()
    {
        writewatch = channel.add_watch_full( writepriority, IOCondition.OUT, writeCallback );
    }

    //=====================================================================//
    // PUBLIC API
    //=====================================================================//

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

        debug( "created" );
    }

    ~BaseTransport()
    {
        debug( "destroyed" );
    }

    public override string getName()
    {
        return name;
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
                tspeed = Linux26.Termios.B460800;
                break;
            case 500000:
                tspeed = Linux26.Termios.B500000;
                break;
            case 576000:
                tspeed = Linux26.Termios.B576000;
                break;
            case 921600:
                tspeed = Linux26.Termios.B921600;
                break;
            case 1000000:
                tspeed = Linux26.Termios.B1000000;
                break;
            case 1152000:
                tspeed = Linux26.Termios.B1152000;
                break;
            case 1500000:
                tspeed = Linux26.Termios.B1500000;
                break;
            case 2000000:
                tspeed = Linux26.Termios.B2000000;
                break;
            case 2500000:
                tspeed = Linux26.Termios.B2500000;
                break;
            case 3000000:
                tspeed = Linux26.Termios.B3000000;
                break;
            case 3500000:
                tspeed = Linux26.Termios.B3500000;
                break;
            case 4000000:
                tspeed = Linux26.Termios.B4000000;
                break;
            default:
                warning( "invalid speed '%u' selected. using '0'".printf( speed ) );
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
            termios.c_cflag |= Linux26.Termios.CRTSCTS;

            // software flow control OFF
            termios.c_iflag &= ~(Posix.IXON | Posix.IXOFF | Posix.IXANY);
        }
        else
        {
            // hardware flow control OFF
            termios.c_cflag &= Linux26.Termios.CRTSCTS;

            // software flow control ON
            termios.c_iflag |= ~(Posix.IXON | Posix.IXOFF | Posix.IXANY);
        }

        if ( raw )
        {
            // raw input
            termios.c_lflag &= ~(Posix.ICANON | Posix.ECHO | Posix.ECHOE | Posix.ISIG);
            termios.c_iflag &= ~(Posix.INLCR | Posix.ICRNL | Posix.IGNCR);

            // raw output
            termios.c_oflag &= ~(Posix.OPOST | Linux26.Termios.OLCUC | Posix.ONLRET | Posix.ONOCR | Posix.OCRNL );

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
            message( "could not configure fd %d: %s".printf( fd, Posix.strerror( Posix.errno ) ) );
        }

        if ( hard )
        {
            // set ready to read/write
            var v24 = Linux26.Termios.TIOCM_DTR | Linux26.Termios.TIOCM_RTS;
            Posix.ioctl( fd, Linux26.Termios.TIOCMBIS, &v24 );
        }
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
            debug( "error while setting encoding");
        }
        channel.set_buffer_size( 32768 );
        // setup watch
        readwatch = channel.add_watch_full( readpriority, IOCondition.IN | IOCondition.HUP, actionCallback );
        // we might have already queued something up in the buffer
        if ( buffer.len > 0 )
            restartWriter();

        debug( "opened" );
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
        debug( "closed" );

    }

    public override bool isOpen()
    {
        return ( fd != -1 );
    }

    public virtual string repr()
    {
        return "<BaseTransport fd %d>".printf( fd );
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

    internal int _write( void* data, int len )
    {
        assert( fd != -1 );
        ssize_t byteswritten = Posix.write( fd, data, len );
        return (int)byteswritten;
    }

    public override int write( void* data, int len )
    {
        debug( "writing %d bytes".printf( len ) );
        assert( data != null );
        if ( fd == -1 )
            warning( "writing although transport still closed; buffering." );
        var restart = ( fd != -1 && buffer.len == 0 );
        //TODO: avoid copying the buffer
        var temp = new uint8[len];
        Memory.copy( temp, data, len );
        buffer.append( temp );

        if ( restart )
            restartWriter();
        return len;
    }

    public override void freeze()
    {
        if ( buffer.len > 0 )
            warning( "freeze called while buffer not yet empty" );
        if ( readwatch != 0 )
            Source.remove( readwatch );
        if ( writewatch != 0 )
            Source.remove( writewatch );
        debug( "frozen" );
    }

    public override void thaw()
    {
        // setup watch
        readwatch = channel.add_watch_full( readpriority, IOCondition.IN | IOCondition.HUP, actionCallback );
        // we might have already queued something up in the buffer
        if ( buffer.len > 0 )
            restartWriter();
        debug( "thawn" );
    }

    public bool actionCallback( IOChannel source, IOCondition condition )
    {
        debug( "actionCallback called with condition = %d".printf( condition ) );

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

        warning( "actionCallback called with unknown condition" );

        return false;
    }

    public bool writeCallback( IOChannel source, IOCondition condition )
    {
        debug( "writeCallback called with %u bytes in buffer".printf( buffer.len ) );
        /*
        for( int i = 0; i < buffer.len; ++i )
            debug( "byte: 0x%02x".printf( buffer.data[i] ) );
        */
        int len = 64 > buffer.len? (int)buffer.len : 64;
        var byteswritten = _write( buffer.data, len );
        debug( "writeCallback wrote %d bytes".printf( (int)byteswritten ) );
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
                            bool raw = true,
                            bool hard = true )
    {
        base( portname, portspeed, raw, hard );
    }

    public override bool open()
    {
        fd = Posix.open( name, Posix.O_RDWR | Posix.O_NOCTTY | Posix.O_NONBLOCK );
        if ( fd == -1 )
        {
            warning( "could not open %s: %s".printf( name, Posix.strerror( Posix.errno ) ) );
            return false;
        }

        configure();

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

    public PtyTransport()
    {
        base( "Pty", 115200 );
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
        fd = Posix.posix_openpt( Posix.O_RDWR | Posix.O_NOCTTY | Posix.O_NONBLOCK );
        if ( fd == -1 )
        {
            warning( "could not open %s: %s".printf( name, Posix.strerror( Posix.errno ) ) );
            return false;
        }

        Posix.grantpt( fd );
        Posix.unlockpt( fd );
        Linux26.Termios.ptsname_r( fd, ptyname );

        int flags = Posix.fcntl( fd, Posix.F_GETFL );
        int res = Posix.fcntl( fd, Posix.F_SETFL, flags | Posix.O_NONBLOCK );
        if ( res < 0 )
            warning( "can't set pty master to NONBLOCK: %s".printf( Posix.strerror( Posix.errno ) ) );

        configure();

        return base.open();
    }
}


//===========================================================================
public delegate void FsoFramework.TransportReadFunc( Transport transport );
public delegate void FsoFramework.TransportHupFunc( Transport transport );

}

