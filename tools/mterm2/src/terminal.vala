/*
 * (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

using GLib;
using FsoFramework;

const bool MAINLOOP_CALL_AGAIN = true;
const bool MAINLOOP_DONT_CALL_AGAIN = false;

const int BUFFER_SIZE = 8192;

char[] buffer;

const int LINE_DISCIPLINE_N_GSM = 21;
const uchar MKNOD_TTYGSM_MAJOR = 249;

//========================================================================//
public class Terminal : Object
//========================================================================//
{
    Transport transport;
    weak Options options;
    Reader reader;
    int fd;
    int oldisc;

    string transportname;
    string portname;

    public Terminal( Options option )
    {
        buffer = new char[BUFFER_SIZE];
        this.options = option;
    }

    public void close()
    {
        if ( Options.muxmode != -1 )
        {
            fsoMessage( @"Resetting line discipline" );
            Linux.ioctl( fd, Linux.Termios.TIOCSETD, &oldisc );
            transport.thaw();
            transport.close();
            transport = null;
            return;
        }
    }

    public void setMuxMode( int mode )
    {
        fsoMessage( "Opening port..." );

        transport = new SerialTransport( portname, options.portspeed );
        if ( !transport.open() )
        {
            quitWithMessage( @"Can't open transport: $(strerror(errno))" );
            return;
        }

        fsoMessage( "Entering MUX mode..." );

        var buffer = new char[128];
        var command = "\r\nATE0Q0V1\r\n";
        var bread = transport.writeAndRead( command, command.length, buffer, 128 );
        command = mode == 0 ? "AT+CMUX=0\r\n" : "AT+CMUX=1,0,5,64\r\n";
        bread = transport.writeAndRead( command, command.length, buffer, 128 );
        buffer[bread] = '\0';
        var response = ( (string)buffer ).strip();
        if ( response != "OK" )
        {
            quitWithMessage( @"Can't enter MUX mode: Modem answered '$response'" );
            return;
        }

        fsoMessage( "Setting line discipline..." );

        fd = transport.freeze();
        int ldisc = LINE_DISCIPLINE_N_GSM;

        if ( Linux.ioctl( fd, Linux.Termios.TIOCGETD, &oldisc ) == -1 )
        {
            quitWithMessage( @"Can't get old line disciplne: $(strerror(errno))" );
            return;
        }

        if ( Linux.ioctl( fd, Linux.Termios.TIOCSETD, &ldisc ) == -1 )
        {
            quitWithMessage( @"Can't set N_GSM line discipline: $(strerror(errno))" );
            return;
        }

        var muxconfig = Linux.Gsm.Config();
        if ( Linux.ioctl( fd, Linux.Gsm.GSMIOC_GETCONF, &muxconfig ) == -1 )
        {
            quitWithMessage( @"Can't get N_GSM configuration: $(strerror(errno))" );
            Linux.ioctl( fd, Linux.Termios.TIOCSETD, &oldisc );
            return;
        }
        muxconfig.initiator = 1;
        muxconfig.encapsulation = mode;
        muxconfig.mru = 127;
        muxconfig.mtu = 127;
        if ( Linux.ioctl( fd, Linux.Gsm.GSMIOC_SETCONF, &muxconfig ) == -1 )
        {
            quitWithMessage( @"Can't set N_GSM configuration: $(strerror(errno))" );
            Linux.ioctl( fd, Linux.Termios.TIOCSETD, &oldisc );
            return;
        }

        fsoMessage( "Creating device nodes... (needs root privileges)" );
        for ( int i = 1; i < 8; ++i )
        {
            Posix.mknod( @"/dev/ttygsm$i", Posix.S_IFCHR | 0666, Linux.makedev( MKNOD_TTYGSM_MAJOR, i ) );
        }

        fsoMessage( "MUX mode established, you can now use /dev/ttygsm[1-n]" );
    }

    public bool open()
    {
        if ( !parsePortspec() )
        {
            quitWithMessage( "FATAL: Can't parse portspec '%s'.".printf( options.portspec ) );
            return MAINLOOP_DONT_CALL_AGAIN;
        }

        if ( Options.muxmode != -1 && transportname != "serial" )
        {
            quitWithMessage( "FATAL: MUX Mode is only available with serial transports" );
            return MAINLOOP_DONT_CALL_AGAIN;
        }

        if ( Options.muxmode != -1 )
        {
            setMuxMode( Options.muxmode );
            return MAINLOOP_DONT_CALL_AGAIN;
        }

        switch ( transportname )
        {
            case "serial":
                transport = new SerialTransport( portname, options.portspeed );
                break;
            case "abyss":
                transport = new AbyssTransport( portname.to_int() );
                break;
            case "unix":
                transport = new SocketTransport( "unix", portname, 0 );
                break;
            case "tcp":
            case "udp":
                transport = new SocketTransport( transportname, portname, options.portspeed );
                break;
            default:
                quitWithMessage( "FATAL: Unknown transport method '%s'.".printf( transportname ) );
                return MAINLOOP_DONT_CALL_AGAIN;
        }
        transport.setDelegates( onTransportRead, onTransportHup );
        transport.open();

        if ( !transport.isOpen() )
        {
            quitWithMessage( "FATAL: Cannot open %s: %s".printf( options.portspec, Posix.strerror( Posix.errno ) ) );
            return MAINLOOP_DONT_CALL_AGAIN;
        }

        reader = new Reader( transport );

        return MAINLOOP_DONT_CALL_AGAIN;
    }

    public bool parsePortspec()
    {
        if ( ":" in options.portspec )
        {
            var elements = options.portspec.split( ":" );
            if ( elements.length != 2 )
                return false;

            transportname = elements[0];
            portname = elements[1];
        }
        else
        {
            transportname = "serial";
            portname = options.portspec;
        }
        return true;
    }

    public void onTransportRead( Transport transport )
    {
        int numread = transport.read( buffer, BUFFER_SIZE-1 );
        buffer[numread] = 0;
        stdout.printf( "%s", (string)buffer );
    }

    public void onTransportHup( Transport transport )
    {
        quitWithMessage( "FATAL: Peer closed connection." );
    }

}
