/*
 * Copyright (C) 2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 * Copyright (C) 2011 Denis 'GNUtoo' Carikli <GNUtoo@no-log.org>
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


/**
 * @class CmtHandler
 *
 * Handles Audio via libcmtspeechdata
 **/
public class CmtHandler : FsoFramework.AbstractObject
{
    private CmtSpeech.Connection connection;
    private IOChannel channel;
    private FsoAudio.PcmDevice pcmout;
    private FsoAudio.PcmDevice pcmin;

    private bool status;

    private unowned Thread<void *> recordThread = null;
    private bool runRecordThread = false;
    private uint8 alsaSrcBuf[320];
    private Mutex alsaSrcBufMutex = new Mutex();

    //
    // Constructor
    //
    public CmtHandler()
    {
        status = false;

        assert( logger.debug( "Initializing cmtspeech" ) );
        CmtSpeech.init();

        assert( logger.debug( "Setting up traces" ) );
        CmtSpeech.trace_toggle( CmtSpeech.TraceType.STATE_CHANGE, true );
        CmtSpeech.trace_toggle( CmtSpeech.TraceType.IO, true );
        CmtSpeech.trace_toggle( CmtSpeech.TraceType.DEBUG, true );

        assert( logger.debug( "Instanciating connection" ) );
        connection = new CmtSpeech.Connection();
        if ( connection == null )
        {
            logger.error( "Can't instanciate connection" );
            return;
        }

        var fd = connection.descriptor();

        if ( fd == -1 )
        {
            logger.error( "Cmtspeech file descriptor invalid" );
        }

        assert( logger.debug( "Hooking up fd with main loop" ) );
        channel = new IOChannel.unix_new( fd );
        channel.add_watch( IOCondition.IN | IOCondition.HUP, onInputFromChannel );

        logger.info( "Created" );
    }

    //
    // Private API
    //

    private void * recordThreadFunc()
    {
        while ( runRecordThread )
        {
            try
            {
                alsaSrcBufMutex.lock();
                /* 160 S16_LE frames == 320 Bytes */
                pcmin.readi( alsaSrcBuf, 160 );
                alsaSrcBufMutex.unlock();
            }
            catch ( FsoAudio.SoundError e )
            {
                logger.error( @"Error: $(e.message)" );
            }
        }

        return null;
    }

    private void handleAlsaSink( CmtSpeech.FrameBuffer dlbuf )
    {
        try
        {
            pcmout.writei( (uint8[])dlbuf.payload, dlbuf.pcount / 2 );
        }
        catch ( FsoAudio.SoundError e )
        {
            logger.error( @"Error: $(e.message)" );
        }
    }

    private void handleAlsaSrc( CmtSpeech.FrameBuffer ulbuf )
    {
        alsaSrcBufMutex.lock();
        Memory.copy( ulbuf.payload, alsaSrcBuf, ulbuf.pcount );
        alsaSrcBufMutex.unlock();
    }

    private void alsaSinkSetup()
    {
        int channels = 1;
        int rate = 8000;
        Alsa2.PcmFormat format = Alsa2.PcmFormat.S16_LE;
        Alsa2.PcmAccess access = Alsa2.PcmAccess.RW_INTERLEAVED;

        pcmout = new FsoAudio.PcmDevice();
        assert( logger.debug( @"Setup alsa sink for modem audio" ) );
        try
        {
            pcmout.open( "plug:dmix" );
            pcmout.setFormat( access, format, rate, channels );
        }
        catch ( Error e )
        {
            logger.error( @"Error: $(e.message)" );
        }
    }

    private void alsaSrcSetup()
    {
        int channels = 1;
        int rate = 8000;
        Alsa2.PcmFormat format = Alsa2.PcmFormat.S16_LE;
        Alsa2.PcmAccess access = Alsa2.PcmAccess.RW_INTERLEAVED;

        pcmin = new FsoAudio.PcmDevice();
        assert( logger.debug( @"Setup alsa source for modem audio" ) );
        try
        {
            pcmin.open( "plug:dsnoop", Alsa2.PcmStream.CAPTURE );
            pcmin.setFormat( access, format, rate, channels );
        }
        catch ( Error e )
        {
            logger.error( @"Error: $(e.message)" );
        }

        /* start the recording now,
         * so we push the buffer that are already recorded
         */
        if ( !Thread.supported() )
        {
            stderr.printf( "Cannot run without threads.\n" );
        }
        else
        {
            if ( recordThread == null )
            {
                try
                {
                    recordThread = Thread.create<void *>( recordThreadFunc, true );
                }
                catch ( ThreadError e )
                {
                    stdout.printf( @"Error: $(e.message)" );
                    return;
                }
            }
            else
            {
                stdout.printf( "Thread already launched \n" );
            }
            runRecordThread = true;
        }

    }

    private void alsaSinkCleanup()
    {
        pcmout.close();
    }

    private void alsaSrcCleanup()
    {
        runRecordThread = false;
        recordThread.join();
        recordThread = null;
        pcmin.close();
    }

    private void handleDataEvent()
    {
        assert( logger.debug( @"handleDataEvent during protocol state $(connection.protocol_state())" ) );

        CmtSpeech.FrameBuffer dlbuf = null;
        CmtSpeech.FrameBuffer ulbuf = null;

        var ok = connection.dl_buffer_acquire( out dlbuf );
        if ( ok == 0 )
        {
            assert( logger.debug( "received DL packet w/ $(dlbuf.count) bytes" ) );

            handleAlsaSink( dlbuf );

            if ( connection.protocol_state() == CmtSpeech.State.ACTIVE_DLUL )
            {
                ok = connection.ul_buffer_acquire( out ulbuf );
                if ( ok == 0 )
                {
                    assert( logger.debug( "protocol state is ACTIVE_DLUL, uploading as well..." ) );
                    handleAlsaSrc( ulbuf );
                    connection.ul_buffer_release( ulbuf );
                }
            }
            connection.dl_buffer_release( dlbuf );
        }
    }

    private void handleControlEvent()
    {
        assert( logger.debug( @"handleControlEvent during protocol state $(connection.protocol_state())" ) );

        CmtSpeech.Event event = CmtSpeech.Event();
        CmtSpeech.Transition transition = 0;

        connection.read_event( event );

        assert( logger.debug( @"read event, type is $(event.msg_type)" ) );
        transition = connection.event_to_state_transition( event );

        switch ( transition )
        {
            case CmtSpeech.Transition.INVALID:
                assert( logger.debug( "ERROR: invalid state transition") );
                break;

            case CmtSpeech.Transition.1_CONNECTED:
            case CmtSpeech.Transition.2_DISCONNECTED:
            case CmtSpeech.Transition.3_DL_START:
            case CmtSpeech.Transition.4_DLUL_STOP:
            case CmtSpeech.Transition.5_PARAM_UPDATE:
                assert( logger.debug( @"State transition ok, new state is $transition" ) );
                break;

            case CmtSpeech.Transition.6_TIMING_UPDATE:
            case CmtSpeech.Transition.7_TIMING_UPDATE:
                assert( logger.debug( "WARNING: modem UL timing update ignored" ) );
                break;

            case CmtSpeech.Transition.10_RESET:
            case CmtSpeech.Transition.11_UL_STOP:
            case CmtSpeech.Transition.12_UL_START:
                assert( logger.debug( @"State transition ok, new state is $transition" ) );
                break;

            default:
                assert_not_reached();
                break;
        }
    }

    private bool onInputFromChannel( IOChannel source, IOCondition condition )
    {
        assert( logger.debug( @"onInputFromChannel, condition = $condition" ) );

        assert( condition == IOCondition.HUP || condition == IOCondition.IN );

        if ( condition == IOCondition.HUP )
        {
            logger.warning( "HUP! Will no longer handle input from cmtspeechdata" );
            return false;
        }

        CmtSpeech.EventType flags = 0;
        var ok = connection.check_pending( out flags );
        if ( ok < 0 )
        {
            assert( logger.debug( "Error while checking for pending events..." ) );
        }
        else if ( ok == 0 )
        {
            assert( logger.debug( "D'oh, cmt speech readable, but no events pending..." ) );
        }
        else
        {
            assert( logger.debug( "Connection reports pending events with flags 0x%0X".printf( flags ) ) );

            if ( ( flags & CmtSpeech.EventType.DL_DATA ) == CmtSpeech.EventType.DL_DATA )
            {
                handleDataEvent();
            }
            else if ( ( flags & CmtSpeech.EventType.CONTROL ) == CmtSpeech.EventType.CONTROL )
            {
                handleControlEvent();
            }
            else
            {
                assert( logger.debug( "Event no DL_DATA nor CONTROL, ignoring" ) );
            }
        }

        return true;
    }

    //
    // Public API
    //

    public override string repr()
    {
        CmtSpeech.State state = ( connection != null ) ? connection.protocol_state() : 0;
        return @"<$state>";
    }

    public void setAudioStatus( bool enabled )
    {
        if ( enabled == status )
        {
            assert( logger.debug( @"Status already $status" ) );
            return;
        }

        assert( logger.debug( @"Setting call status to $enabled" ) );

        if ( enabled )
        {
            alsaSinkSetup();
            alsaSrcSetup();
        }
        else
        {
            alsaSinkCleanup();
            alsaSrcCleanup();
        }

        connection.state_change_call_status( enabled );

        status = enabled;
    }
}

// vim:ts=4:sw=4:expandtab
