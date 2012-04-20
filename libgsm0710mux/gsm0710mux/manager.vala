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

namespace Gsm0710mux {

//===========================================================================
public class ChannelInfo
{
    /**
     * Consumer Identification
     **/
    public string consumer;
    /**
     * Requested multiplexing channel number
     **/
    public int number;
    /**
     * Transport specification for the transport the
     * channel should be exposed over
     **/
    public FsoFramework.Transport transport;
}

//===========================================================================
public class Manager : Object
{
    private Multiplexer muxer;
    private FsoFramework.SmartKeyFile config;
    private FsoFramework.Logger logger;

    private bool autoopen = false;
    private bool autoclose = false;
    private bool autoexit = true;
    private string session_type = "serial";
    private string session_path = "/dev/ttySAC0";
    private uint session_speed = 115200;
    private bool session_mode = true;
    private uint session_framesize = 64;
    private bool session_unclosable = false;
    public uint channel_ack_timeout = 10;
    private uint wakeup_threshold = 0;
    private uint wakeup_waitms = 0;
    private uint send_pause_threshold = 0;

    public static bool leave_mux_alone = false;
    public static bool leave_fc_alone  = false;

    private uint channelsOpen;

    public Manager()
    {
        config = FsoFramework.theConfig; // use standard config for this binary
        logger = FsoFramework.Logger.createFromKeyFile( config, LIBGSM0710MUX_CONFIG_SECTION, LIBGSM0710MUX_LOGGING_DOMAIN );
        logger.setReprDelegate( repr );
        assert( logger.debug( "Constructed" ) );

        autoopen = config.boolValue( LIBGSM0710MUX_CONFIG_SECTION, "muxer_autoopen", autoopen );
        autoclose = config.boolValue( LIBGSM0710MUX_CONFIG_SECTION, "muxer_autoclose", autoclose );
        autoexit = config.boolValue( LIBGSM0710MUX_CONFIG_SECTION, "muxer_autoexit", autoexit );

        session_type = config.stringValue( LIBGSM0710MUX_CONFIG_SECTION, "device_type", session_type );
        session_path = config.stringValue( LIBGSM0710MUX_CONFIG_SECTION, "device_port", session_path );
        session_speed = config.intValue( LIBGSM0710MUX_CONFIG_SECTION, "device_speed", (int)session_speed );

        session_mode = config.boolValue( LIBGSM0710MUX_CONFIG_SECTION, "device_mux_mode", session_mode );
        session_framesize = config.intValue( LIBGSM0710MUX_CONFIG_SECTION, "device_mux_framesize", (int)session_framesize );
        session_unclosable = config.boolValue( LIBGSM0710MUX_CONFIG_SECTION, "device_close_broken", session_unclosable );
        channel_ack_timeout = config.intValue( LIBGSM0710MUX_CONFIG_SECTION, "device_ack_timeout", (int)channel_ack_timeout );

        wakeup_threshold = config.intValue( LIBGSM0710MUX_CONFIG_SECTION, "device_wakeup_threshold", (int)wakeup_threshold );
        wakeup_waitms = config.intValue( LIBGSM0710MUX_CONFIG_SECTION, "device_wakeup_waitms", (int)wakeup_waitms );
        send_pause_threshold = config.intValue( LIBGSM0710MUX_CONFIG_SECTION, "device_sendpause_threshold", (int)send_pause_threshold );

        leave_mux_alone = config.boolValue( LIBGSM0710MUX_CONFIG_SECTION, "session_debug_leave_mux_alone", false );
        leave_fc_alone = config.boolValue( LIBGSM0710MUX_CONFIG_SECTION, "session_debug_leave_fc_alone", false );
    }

    public string repr()
    {
        return "<>";
    }

    ~Manager()
    {
        assert( logger.debug( "Destructed" ) );
    }

    internal void _shutdown()
    {
        assert( logger.debug( "_shutdown" ) );
        if ( muxer != null )
        {
            muxer.closeSession();
            muxer = null;
        }
    }

    internal void channelsHaveBeenClosed( int num )
    {
        channelsOpen -= num;
        if ( channelsOpen == 0 && autoclose )
        {
            _shutdown();
        }
    }

    //
    // Public API
    //
    public string getVersion()
    {
        return Config.PACKAGE_VERSION;
    }

    public bool hasAutoSession()
    {
        return autoopen;
    }

    public void openSession( bool advanced, int framesize, string porttype, string portname, int portspeed ) throws MuxerError
    {
        logger.debug( "InitSession requested for mode %s, framesize %d, type %s, name %s @ %d".printf( advanced? "advanced":"basic", framesize, porttype, portname, portspeed ) );
        if ( muxer != null )
        {
            throw new MuxerError.SESSION_ALREADY_OPEN( "Close session before opening another one." );
        }
        else
        {
            muxer = new Multiplexer( advanced, framesize, porttype, portname, portspeed, this );
            if ( !muxer.initSession() )
            {
                muxer = null;
                throw new MuxerError.SESSION_OPEN_ERROR( "Can't initialize the session" );
            }
            else
            {
                // configure
                if ( wakeup_threshold > 0 && wakeup_waitms > 0 )
                {
                    setWakeupThreshold( wakeup_threshold, wakeup_waitms );
                }
                if ( send_pause_threshold > 0 )
                {
                    setSendPauseThreshold( send_pause_threshold );
                }
            }
        }
    }

    public void closeSession() throws MuxerError
    {
        logger.debug( "CloseSession requested" );
        if ( muxer == null )
        {
            throw new MuxerError.NO_SESSION( "Session has to be initialized first." );
        }
        else
        {
            if ( session_unclosable )
            {
                logger.debug( "This device can't close the session [ignoring]" );
            }
            else
            {
                muxer.closeSession();
            }
            //FIXME: This forcefully destroys the muxer and the transport and gives
            //them no chance to wait for the modem's reply
            muxer = null;
        }
    }

    public async int allocChannel( ChannelInfo channel ) throws MuxerError
    {
        assert( logger.debug( @"Consumer $(channel.consumer) requested channel $(channel.number) via $(channel.transport.getName())" ) );

        if ( autoopen && muxer == null )
        {
            logger.debug( "auto configuring..." );
            openSession( session_mode, (int)session_framesize, session_type, session_path, (int)session_speed );
        }

        if ( channel.number < 0 )
        {
            throw new MuxerError.INVALID_CHANNEL( "Channel has to be >= 0" );
        }

        if ( muxer == null )
        {
            throw new MuxerError.NO_SESSION( "Session has to be initialized first." );
        }
        else
        {
            var number = yield muxer.allocChannel( channel );
            channelsOpen++;
            return number;
        }
    }

    public void releaseChannel( string name ) throws MuxerError
    {
        logger.debug( "ReleaseChannel requested for name %s".printf( name ) );
        if ( muxer == null )
        {
            throw new MuxerError.NO_SESSION( "Session has to be initialized first." );
        }
        else
        {
            if ( session_unclosable )
            {
                logger.debug( "Not releasing channel due to session being unclosable (Ignoring)" );
                return;
            }
            else
            {
                muxer.releaseChannel( name );
            }
        }
    }

    public void setWakeupThreshold( uint seconds, uint waitms ) throws MuxerError
    {
        logger.debug( "SetWakeupThreshold to wakeup before transmitting after %u sec. of idleness, wait period = %u msec.".printf( seconds, waitms ) );
        if ( muxer == null )
        {
            throw new MuxerError.NO_SESSION( "Session has to be initialized first." );
        }
        else
        {
            muxer.setWakeupThreshold( seconds, waitms );
        }
    }

    public void setSendPauseThreshold( uint ms ) throws MuxerError
    {
        logger.debug( "SetSendPauseThreshold to sleep until %u msec. have been passed until last command has been sent.".printf( ms ) );
        if ( muxer == null )
        {
            throw new MuxerError.NO_SESSION( "Session has to be initialized first." );
        }
        else
        {
            muxer.setSendPauseThreshold( ms );
        }
    }

    public void setStatus( int channel, string status ) throws MuxerError
    {
        logger.debug( "SetStatus requested for channel %d, status = %s".printf( channel, status ) );
        if ( muxer == null )
        {
            throw new MuxerError.NO_SESSION( "Session has to be initialized first." );
        }
        else
        {
            muxer.setStatus( channel, status );
        }
    }

    //public signal void Status( int channel, string status );

    public void testCommand( uint8[] data ) throws MuxerError
    {
        logger.debug( "Sending %d test command bytes".printf( data.length ) );
        muxer.testCommand( data );
    }

}

} /* namespace Gsm0710mux */

// vim:ts=4:sw=4:expandtab
