/*
 * Copyright (C) 2011-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

const int LINE_DISCIPLINE_N_GSM = 21;
const uchar MKNOD_TTYGSM_MAJOR = 249;

//===========================================================================
public class FsoFramework.NgsmTransport : FsoFramework.BaseTransport
//===========================================================================
{
    private int oldisc;
    private uint mode;
    private uint framesize;

    public NgsmTransport( string portname, uint portspeed, bool advanced, uint framesize = 64 )
    {
        base( portname, portspeed, true, true );
        this.framesize = framesize;
        this.mode = advanced ? 1 : 0;
    }

    public override bool open()
    {
        fd = Posix.open( name, Posix.O_RDWR | Posix.O_NOCTTY | Posix.O_NONBLOCK );
        if ( fd == -1 )
        {
            logger.warning( "Could not open %s: %s".printf( name, Posix.strerror( Posix.errno ) ) );
            return false;
        }

        configure();

        if ( !base.open() )
        {
            return false;
        }

        if ( !enterMuxMode() )
        {
            return false;
        }

        return true;
    }

    private bool enterMuxMode()
    {
        assert( logger.debug( "Entering MUX mode..." ) );

        var buffer = new char[128];
        var command = "\r\nATE0Q0V1\r\n";
        var bread = writeAndRead( command, command.length, buffer, 128 );
        command = mode == 0 ? "AT+CMUX=0\r\n" : "AT+CMUX=1,0,5,%u\r\n".printf( framesize );
        bread = writeAndRead( command, command.length, buffer, 128 );
        buffer[bread] = '\0';
        var response = ( (string)buffer ).strip();
        if ( response != "OK" )
        {
            logger.error( @"Can't enter MUX mode: Modem answered '$response'" );
            return false;
        }

        assert( logger.debug( "Setting line discipline..." ) );

        freeze();
        int ldisc = LINE_DISCIPLINE_N_GSM;

        if ( Linux.ioctl( fd, Linux.Termios.TIOCGETD, &oldisc ) == -1 )
        {
            logger.error( @"Can't get old line discipline: $(strerror(errno))" );
            return false;
        }

        if ( Linux.ioctl( fd, Linux.Termios.TIOCSETD, &ldisc ) == -1 )
        {
            logger.error( @"Can't set N_GSM line discipline: $(strerror(errno))" );
            return false;
        }

        var muxconfig = Linux.Gsm.Config();
        if ( Linux.ioctl( fd, Linux.Gsm.GSMIOC_GETCONF, &muxconfig ) == -1 )
        {
            logger.error( @"Can't get N_GSM configuration: $(strerror(errno))" );
            Linux.ioctl( fd, Linux.Termios.TIOCSETD, &oldisc );
            return false;
        }
        muxconfig.initiator = 1;
        muxconfig.encapsulation = mode;
        muxconfig.mru = 127;
        muxconfig.mtu = 127;
        if ( Linux.ioctl( fd, Linux.Gsm.GSMIOC_SETCONF, &muxconfig ) == -1 )
        {
            logger.error( @"Can't set N_GSM configuration: $(strerror(errno))" );
            Linux.ioctl( fd, Linux.Termios.TIOCSETD, &oldisc );
            return false;
        }

        assert( logger.debug( "Creating device nodes... (needs root privileges)" ) );
        for ( int i = 1; i < 8; ++i )
        {
            Posix.mknod( @"/dev/ttygsm$i", Posix.S_IFCHR | 0666, Linux.makedev( MKNOD_TTYGSM_MAJOR, i ) );
        }

        assert( logger.debug( "MUX mode established, you can now use /dev/ttygsm[1-n]" ) );

        return true;
    }

    public override void close()
    {
        freeze();
        Linux.ioctl( fd, Linux.Termios.TIOCSETD, &oldisc );
        thaw();
        base.close();
    }

    public override string repr()
    {
        return "<N_GSM %s@%u (fd %d)>".printf( name, speed, fd );
    }
}

//===========================================================================
public class FsoFramework.NgsmBasicMuxTransport : FsoFramework.NgsmTransport
//===========================================================================
{
    public NgsmBasicMuxTransport( string portname, uint portspeed, uint framesize = 64 )
    {
        base( portname, portspeed, false, framesize );
    }
}

//===========================================================================
public class FsoFramework.NgsmAdvancedMuxTransport : FsoFramework.NgsmTransport
//===========================================================================
{
    public NgsmAdvancedMuxTransport( string portname, uint portspeed, uint framesize = 64 )
    {
        base( portname, portspeed, true, framesize );
    }
}

// vim:ts=4:sw=4:expandtab
