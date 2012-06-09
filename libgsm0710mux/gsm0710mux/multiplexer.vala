/*
 * This file is part of libgsm0710mux
 *
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

//===========================================================================
using GLib;
using CONST;
using Gsm0710;
using Gsm0710mux;

//===========================================================================
// callback forwarders
//

internal static bool at_command_fwd( Context ctx, string command )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    return m.at_command( command );
}

internal static int read_fwd( Context ctx, void* data, int len )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    return m.read( data, len );
}

internal static bool write_fwd( Context ctx, void* data, int len )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    return m.write( data, len );
}

internal static void deliver_data_fwd( Context ctx, int channel, void* data, int len )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    m.deliver_data( channel, data, len );
}

internal static void deliver_status_fwd( Context ctx, int channel, int status )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    m.deliver_status( channel, status );
}

internal static void debug_message_fwd( Context ctx, string msg )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    m.debug_message( msg );
}

internal static void open_channel_fwd( Context ctx, int channel )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    m.open_channel( channel );
}

internal static void close_channel_fwd( Context ctx, int channel )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    m.close_channel( channel );
}

internal static void terminate_fwd( Context ctx )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    m.terminate();
}

internal static void response_to_test_fwd( Context ctx, char[] data )
{
    Multiplexer m = (Multiplexer) ctx.user_data;
    m.response_to_test( data );
}

//===========================================================================
// The Multiplexer class
//
internal class Multiplexer
{
    Manager manager;

    string portname;
    string porttype;
    int portspeed;

    FsoFramework.Logger logger;

    Context ctx;

    uint pingwatch;

    Timer idle_wakeup_timer;
    uint idle_wakeup_threshold;
    uint idle_wakeup_waitms;

    Timer send_pause_timer;
    uint send_pause_threshold;

    Channel[] vc = new Channel[MAX_CHANNELS];

    FsoFramework.Transport transport;

    public Multiplexer( bool advanced, int framesize, string porttype, string portname, int portspeed, Manager manager )
    {
        assert( porttype != null );
        assert( portname != null );
        this.porttype = porttype;
        this.portname = portname;
        this.portspeed = portspeed;
        this.manager = manager;

        ctx = new Context();

        ctx.mode = advanced? 1 : 0;
        ctx.frame_size = framesize;
        ctx.port_speed = portspeed;

        ctx.user_data = this;

        ctx.at_command = at_command_fwd;
        ctx.read = read_fwd;
        ctx.write = write_fwd;
        ctx.deliver_data = deliver_data_fwd;
        ctx.deliver_status = deliver_status_fwd;
        ctx.debug_message = debug_message_fwd;
        ctx.open_channel = open_channel_fwd;
        ctx.close_channel = close_channel_fwd;
        ctx.terminate = terminate_fwd;
        ctx.response_to_test = response_to_test_fwd;

        logger = FsoFramework.Logger.createFromKeyFile( FsoFramework.theConfig, LIBGSM0710MUX_CONFIG_SECTION, LIBGSM0710MUX_LOGGING_DOMAIN );
        logger.setReprDelegate( repr );
        assert( logger.debug( "Created" ) );
    }

    ~Multiplexer()
    {
        if ( transport != null )
        {
            transport.freeze();
            transport.close();
        }
        assert( logger.debug( "Destructed" ) );
    }

    public string repr()
    {
        return "<%c%d %s@%d>".printf( ( ctx.mode == 1 ? 'A':'B' ), ctx.frame_size, portname, ctx.port_speed );
    }

    public bool initSession()
    {
        assert( logger.debug( "InitSession()" ) );

        if ( !openTransport() )
        {
            logger.error( "Can't open the transport" );
            return false;
        }

        if ( manager.leave_mux_alone )
        {
            logger.warning( "Assuming device is already in MUX mode..." );
            transport.flush();
            var ok = ctx.startup( false );
            transport.drain();
            return ok;
        }

        transport.flush();
        ctx.shutdown();
        ctx.shutdown();
        transport.drain();
        transport.flush();

        bool ok;

        if ( ctx.mode == 0 )
        {
            if (!at_command( "AT+CMUX=0\r\n" ) )
                return false;
            ok = ctx.startup( false );
        }
        else
        {
            ok = ctx.startup( true );
        }

        /*
        if (ok)
            Timeout.add_seconds( GSM_PING_SEND_TIMEOUT, protocol_ping_send_timeout );
        */

        return ok;
    }

    public void closeSession()
    {
        assert( logger.debug( "closeSession()" ) );
        for ( int i = 1; i < MAX_CHANNELS; ++i )
        {
            if ( vc != null && vc[i] != null )
            {
                vc[i].close();
            }
        }

        if ( ctx != null && !Manager.leave_mux_alone )
        {
            ctx.shutdown();
        }
    }

    public async int allocChannel( ChannelInfo info ) throws MuxerError
    {
        assert( logger.debug( @"allocChannel() requested for channel $(info.number)" ) );

        if ( info.number == 0 )
        {
            // find the first free one
            for ( int i = 1; i < MAX_CHANNELS; ++i )
            {
                if ( vc[i] == null )
                {
                    info.number = i;
                    break;
                }
            }
        }
        else
        {
            // lets check whether we already have this channel
            if ( vc[info.number] != null )
            {
                throw new MuxerError.CHANNEL_TAKEN( @"Channel $(info.number) is already taken." );
            }
        }

        wakeupIfNecessary();

        var ok = ctx.openChannel( info.number );
        assert( logger.debug( @"0710 open channel returned $ok" ) );
        if ( !ok )
        {
            throw new MuxerError.NO_CHANNEL( @"Modem does not provide channel $(info.number)." );
        }
        vc[info.number] = new Channel( this, info, allocChannel.callback, manager.channel_ack_timeout );

        yield;

        if ( vc[info.number].isAcked() )
        {
            var path = vc[info.number].path();
            assert( logger.debug( @"0710 channel $(info.number) opened and connected to $path" ) );
            return info.number;
        }

        assert( logger.debug( @"0710 timeout while waiting for channel $(info.number) status signal" ) );
        vc[info.number] = null;
        throw new MuxerError.NO_CHANNEL( "Modem does not provide this channel." );
    }

    public void releaseChannel( string name ) throws MuxerError
    {
        assert( logger.debug( @"releaseChannel() requested for $name" ) );
        if ( vc == null )
        {
            logger.warning( "Channel array has already been destroyed" );
            return;
        }
        var closed = 0;
        for ( int i = 1; i < MAX_CHANNELS; ++i )
        {
            if ( vc[i] != null && vc[i].name() == name )
            {
                vc[i].close();
                closed++;
            }
        }
        if ( closed > 0 )
        {
            manager.channelsHaveBeenClosed( closed );
        }
        else
        {
            throw new MuxerError.NO_CHANNEL( "Could not find any channel with that name." );
        }
    }

    public void setStatus( int channel, string status ) throws MuxerError
    {
        assert( logger.debug( @"setStatus() requested for channel $channel" ) );
        if ( vc[channel] == null )
            throw new MuxerError.NO_CHANNEL( "Could not find channel with that index." );

        var v24 = stringToSerialStatus( status );
        wakeupIfNecessary();
        ctx.setStatus( channel, v24 );
    }

    public void setWakeupThreshold( uint seconds, uint waitms ) throws MuxerError
    {
        if ( seconds == 0 ) /* disable */
        {
            idle_wakeup_timer = null;
        }
        else /* enable */
        {
            if ( idle_wakeup_timer == null )
            {
                idle_wakeup_timer = new Timer();
                idle_wakeup_timer.start();
            }
        }
        idle_wakeup_threshold = seconds;
        idle_wakeup_waitms = waitms;
    }

    public void setSendPauseThreshold( uint ms )
    {
        if ( ms == 0 )
        {
            send_pause_timer = null;
        }
        else
        {
            send_pause_timer = new Timer();
        }
        send_pause_threshold = ms;
    }

    public void testCommand( uint8[] data )
    {
        debug( "muxer: testCommand" );
        wakeupIfNecessary();
        ctx.sendTest( data, data.length );
    }

    //
    // internal helpers
    //
    internal bool openTransport()
    {
        assert( transport == null );
        transport = FsoFramework.Transport.create( porttype, portname, portspeed );
        if ( transport == null )
        {
            return false;
        }
        transport.setDelegates( onReadFromTransport, onHupFromTransport );
        transport.setBuffered( false );
        transport.open();
        return transport.isOpen();
    }

#if WHO_IS_USING_THAT
    public int channelByName( string name )
    {
        for ( int i = 1; i < MAX_CHANNELS; ++i )
        {
            if ( vc[i] != null && vc[i].name() == name )
                return i;
        }
        return 0;
    }
#endif

    public string serialStatusToString( int status ) // module -> application
    {
        var sb = new StringBuilder();
        if ( ( status & SerialStatus.FC ) == SerialStatus.FC )
            sb.append( "FC ");
        if ( ( status & SerialStatus.RTC ) == SerialStatus.RTC )
            sb.append( "DSR ");
        if ( ( status & SerialStatus.RTR ) == SerialStatus.RTR )
            sb.append( "CTS ");
        if ( ( status & SerialStatus.RING ) == SerialStatus.RING )
            sb.append( "RING ");
        if ( ( status & SerialStatus.DCD ) == SerialStatus.DCD )
            sb.append( "DCD ");
        return sb.str;
    }

    public int stringToSerialStatus( string status ) // application -> module
    {
        int v24 = 0;
        var bits = status.split( " " );
        foreach( var bit in bits )
        {
            if ( bit == "DTR" )
                v24 |= SerialStatus.RTC;
            else if ( bit == "RTS" )
                v24 |= SerialStatus.RTR;
        }
        return v24;
    }

    public void clearPingResponseTimeout()
    {
        if ( pingwatch != 0 )
            Source.remove( pingwatch );
    }

    private void sleepIfNecessary()
    {
        if ( send_pause_timer == null )
        {
            return;
        }
        var timediff = send_pause_threshold - send_pause_timer.elapsed();
        if ( timediff > 0 )
        {
            assert( logger.debug( "Attempting to send too fast, sleeping %.2f seconds".printf( timediff ) ) );
            Thread.usleep( (ulong)(timediff * 1000) );
        }
    }

    public void wakeupIfNecessary()
    {
        if ( idle_wakeup_timer != null )
        {
            var elapsed = idle_wakeup_timer.elapsed();
            if ( elapsed > idle_wakeup_threshold )
            {
                assert( logger.debug( "Channel has been idle for %.2f seconds, waking up".printf( elapsed ) ) );
                var wakeup = new char[] { 'W', 'A', 'K', 'E', 'U', 'P', '!' };
                ctx.sendTest( wakeup, wakeup.length );
                Thread.usleep( 1000 * idle_wakeup_waitms );
            }
        }
    }

    // callbacks from modem transport
    public void onReadFromTransport( FsoFramework.Transport transport )
    {
        ctx.readyRead();
    }

    public void onHupFromTransport( FsoFramework.Transport transport )
    {
        logger.error( "HUP from modem transport; closing session" );
        closeSession();
    }

    //
    // callbacks from channel
    //
    public void submit_data( int channel, void* data, int len )
    {
        sleepIfNecessary();
        wakeupIfNecessary();
        ctx.writeDataForChannel( channel, data, len );
    }

    public void channel_closed( int channel )
    {
        wakeupIfNecessary();
        ctx.closeChannel( channel );
    }

    public void remove_channel( int channel )
    {
        vc[channel] = null;
    }

    //
    // callbacks from 0710 core
    //
    public int read( void* data, int len )
    {
        assert( logger.debug( "0710 -> should read max %d bytes to %p".printf( len, data ) ) );
        var numread = transport.read( data, len );
        hexdump( false, data, numread, logger );
        return numread;
    }

    public bool write( void* data, int len )
    {
        assert( logger.debug( "0710 -> should write %d bytes".printf( len ) ) );
        if ( idle_wakeup_timer != null )
        {
            idle_wakeup_timer.reset();
        }
        hexdump( true, data, len, logger );
        if ( send_pause_timer != null )
        {
            send_pause_timer.reset();
        }
        var numsent = transport.write( data, len );
        return ( numsent > 0 );
    }

    public bool at_command( string command )
    {
        assert( logger.debug( "0710 -> should send at_command '%s'".printf( command ) ) );

        var response = new char[1024];
        var numread = transport.writeAndRead( command, (int)command.length, response, response.length );
        assert( logger.debug( "Got %u bytes back w/ content = %s".printf( (uint)numread, ((string)response).escape( "" ) ) ) );
        return "OK" in (string)response;
    }

    public void deliver_data( int channel, void* data, int len )
    {
        logger.debug( "0710 -> deliver %d bytes for channel %d".printf( len, channel ) );
        if ( vc[channel] == null )
        {
            assert( logger.debug( "Should deliver bytes for unknown channel: ignoring" ) );
        }
        else
        {
            vc[channel].deliverData( data, len );
        }
        clearPingResponseTimeout();
    }

    public void deliver_status( int channel, int serial_status )
    {
        string status = serialStatusToString( serial_status );
        assert( logger.debug( "0710 -> deliver status %d = '%s' for channel %d".printf( serial_status, status, channel ) ) );
        if ( vc[channel] == null )
        {
            assert( logger.debug( ":::should deliver status for unknown channel: ignoring" ) );
        }
        else
        {
            if ( !vc[channel].isAcked() )
            {
                vc[channel].acked();
            }
            vc[channel].setSerialStatus( serial_status );
        }
        clearPingResponseTimeout();
    }

    public void debug_message( string msg )
    {
        assert( logger.debug( "0710 -> say '%s".printf( msg ) ) );
    }

    public void open_channel( int channel )
    {
        assert( logger.debug( "0710 -> open channel %d".printf( channel ) ) );
        logger.error( "Unhandled modem side open channel command" );
    }

    public void close_channel( int channel )
    {
        logger.debug( "0710 -> close channel %d".printf( channel ) );
        var message = new char[] { '\r', '\n', '!', 'S', 'H', 'U', 'T', 'D', 'O', 'W', 'N', '\r', '\n' };
        deliver_data( channel, message, message.length );
        vc[channel] = null;
    }

    public void terminate()
    {
        assert( logger.debug( "0710 -> terminate" ) );
        // FIXME send close session signal, remove muxer object
    }

    public void response_to_test( char[] data )
    {
        var b = new StringBuilder();
        foreach( var c in data )
        {
            b.append_printf( "%c", c );
        }
        assert( logger.debug( "0710 -> response to test (%d bytes): %s".printf( data.length, b.str ) ) );
        clearPingResponseTimeout();
    }

#if WHO_IS_USING_THAT
    public bool protocol_ping_response_timeout()
    {
        logger.warning( "\n*\n*\n* PING TIMEOUT !!!\n*\n*\n*" );
        return true;
    }

    public bool protocol_ping_send_timeout()
    {
        var data = new char[] { 'P', 'I', 'N', 'G' };
        ctx.sendTest( data, data.length );

        if ( pingwatch != 0 )
            Source.remove( pingwatch );
        pingwatch = Timeout.add_seconds( GSM_PING_RESPONSE_TIMEOUT, protocol_ping_response_timeout );
        return true;
    }
#endif
}

// vim:ts=4:sw=4:expandtab
