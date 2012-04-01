/*
 * Copyright (C) 2011-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *                         Denis 'GNUtoo' Carikli <GNUtoo@no-log.org>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
extern int snd_pcm_format_set_silence (Alsa.PcmFormat format,void * data, uint samples );


/**
 * @class RingBuffer
 *
 * Provides a ring buffer for alsa frames
 **/
errordomain RingError {
    Overflow,
    Underflow
}

class RingBuffer : FsoFramework.AbstractObject
{
    private uint8[] ring;
    private int ring_head;
    private int ring_tail;
    private int ring_size;
    
    public RingBuffer( int size )
    {
        this.ring = new uint8[size];
        this.ring_head = 0;
        this.ring_tail = 0;
        this.ring_size = size;
    }

    public void write( uint8[] x, int count ) throws RingError
    {
        int new_ring_head = (ring_head + count) % ring_size;
        int free = (ring_size + ring_tail - ring_head) % ring_size;
        if ( free == 0 )
            free = ring_size;
        logger.debug( @"RingBuffer.write: ring_head=$(ring_head), ring_tail=$(ring_tail), count=$(count), free=$(free)");
        if ( count > free )
        {
            throw new RingError.Overflow( @"Buffer is full (free: $free / wanted to write: $count)" );
        }		 

        logger.debug( @"RingBuffer.write: new ring_head would be $(new_ring_head)");
        /* check wraparound */
        if ( new_ring_head == 0 || new_ring_head > ring_head )
        {
            /* check next line for +-1 errors I made! */
            logger.debug( @"RingBuffer.write: does not overlap - chunk = $(count)");
            Memory.copy( &ring[ring_head], x, count );
        }
        else
        {
            logger.debug( @"RingBuffer.write: does overlap - first chunk = $(ring_size - ring_head)");
            /* check next 2 lines for +-1 errors I made! */
            Memory.copy( &ring[ring_head], x, ring_size - ring_head );
            logger.debug( @"RingBuffer.write: second chunk = $(ring_size - ring_head)");
            Memory.copy( &ring[0], &x[ring_size - ring_head], count - (ring_size - ring_head) );
        }
        ring_head = new_ring_head;
    }

    /* we pass the pointer to buffer as a parameter, so you can use existing buffers */
    /* wouldn't want the function to malloc a new buffer each time */
    public void read( uint8[] x, int count ) throws RingError
    {
        int avail = (ring_size + ring_head - ring_tail) % ring_size;

        logger.debug( @"RingBuffer.read: ring_head=$(ring_head), ring_tail=$(ring_tail), count=$(count), avail=$(avail)");
        if ( avail < count )
        {
            throw new RingError.Underflow( @"Buffer has only $avail bytes available ($count requested)" );
        }

        int new_ring_tail = (ring_tail + count) % ring_size;
        logger.debug( @"RingBuffer.read: new_ring_tail would be $(new_ring_tail)");

        if ( new_ring_tail == 0 || new_ring_tail > ring_tail )
        {
            logger.debug( @"RingBuffer.read: does not wrap - chunk = $(count)" );
            Memory.copy( x, &ring[ring_tail], count );
        }
        else
        {
            logger.debug( @"RingBuffer.read: does overwrap - first chunk = $(ring_size - ring_tail)");
            Memory.copy( x, &ring[ring_tail], ring_size - ring_tail );
            logger.debug( @"RingBuffer.read: second chunk = $(count - (ring_size - ring_tail))");
            Memory.copy( &x[ring_size - ring_tail], ring, count - (ring_size - ring_tail) );
        }
        ring_tail = new_ring_tail;
    }

    public void reset()
    {
        ring_tail = ring_head = 0;
    }
    public override string repr()
    {
        return "<RingBuffer>";
    }
}



/**
 * @class CmtHandler
 *
 * Handles Audio via libcmtspeechdata
 **/
public class CmtHandler : FsoFramework.AbstractObject
{
    private CmtSpeech.Connection connection;
    private IOChannel channel;
    private FsoAudio.PcmDevice pcmout = null;
    private FsoAudio.PcmDevice pcmin = null;
    private bool status;
    private const int FCOUNT = 160;
    private const int FRAMESIZE = 2;
    private const int BUFSIZE = 3 * FCOUNT * FRAMESIZE;

    /* alsa parameters */
    private Alsa.PcmFormat format = Alsa.PcmFormat.S16_LE;
    private Alsa.PcmAccess access = Alsa.PcmAccess.RW_INTERLEAVED;

    /* silence buffer */
    private uint8[] silence_buffer = null;

    /* playback Thread */
    private unowned Thread<void *> playbackThread = null;
    private int runPlaybackThread = 0;
    private Mutex playbackMutex = new Mutex();
    private RingBuffer fromModem;

    /* record Thread */
    private unowned Thread<void *> recordThread = null;
    private bool runRecordThread = false;
    private Mutex recordMutex = new Mutex();
    private RingBuffer toModem;
    private int timing; // feed UL to the modem (in ms)

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

        timing = 50;
        fromModem = new RingBuffer( BUFSIZE );
        toModem = new RingBuffer( BUFSIZE );

        assert( logger.debug( "Hooking up fd with main loop" ) );
        channel = new IOChannel.unix_new( fd );
        channel.add_watch( IOCondition.IN | IOCondition.HUP, onInputFromChannel );

        silence_buffer = new uint8[ FCOUNT  * FRAMESIZE ];
        snd_pcm_format_set_silence( format, silence_buffer, FCOUNT );

        logger.info( "Created" );
    }

    //
    // Private API
    //

    private void play_silence( int count )
    {
        Alsa.PcmSignedFrames ret;
        int retries = 3;

        while ( count > 0 && retries > 0 )
        {
            try
            {
                ret = pcmout.writei( silence_buffer, FCOUNT );
                if ( ret == -Posix.EPIPE )
                {
                    pcmout.recover( -Posix.EPIPE, 0 );
                    retries--;
                }
                else
                {
                    count--;
                }
            }
            catch ( FsoAudio.SoundError e )
            {
                logger.error( @"Error: $(e.message)" );
                return;
            }
        }
    }

    private bool feed_to_modem()
    {
        CmtSpeech.FrameBuffer ulbuf = null;

        assert( logger.debug( "feeding from ringbuffer to modem" ) );
        if ( connection.is_active() )
        {
            var ok = connection.ul_buffer_acquire( out ulbuf );
            if ( ok == 0 )
            {
                assert( logger.debug( "protocol state is ACTIVE_DLUL, uploading as well..." ) );
                try
                {
                    recordMutex.lock();
                    toModem.read( (uint8[])ulbuf.payload, ulbuf.pcount );
                    recordMutex.unlock();
                }
                catch ( RingError e )
                {
                    recordMutex.unlock();
                    Memory.copy( ulbuf.payload, silence_buffer, ulbuf.pcount > FCOUNT * FRAMESIZE ? FCOUNT * FRAMESIZE : ulbuf.pcount );
                }
                connection.ul_buffer_release( ulbuf );
            }
        }
        return false;
    }

    private void * playbackThreadFunc()
    {
        while ( runPlaybackThread > 0 )
        {
            var buf = new uint8[ FCOUNT * FRAMESIZE ];
            Alsa.PcmSignedFrames frames;

            try
            {
                playbackMutex.lock();
                fromModem.read( buf, FCOUNT * FRAMESIZE );
                playbackMutex.unlock();
                frames = pcmout.writei( (uint8[])buf, FCOUNT );
                if ( frames != FCOUNT )
                {
                    logger.debug(@"frames: $((long)frames)");
                }
                else if ( frames == -Posix.EPIPE )
                {
                    pcmout.recover( -Posix.EPIPE, 0 );
                }
            }
            catch ( FsoAudio.SoundError e )
            {
                logger.error( @"Error: $(e.message)" );
            }
            catch ( RingError e )
            {
                playbackMutex.unlock();
                logger.warning( @"RingBuffer error: $(e.message)" );
                play_silence( 1 );
            }
        }

        return null;
    }


    private void * recordThreadFunc()
    {
        while ( runRecordThread == true )
        {
            var buf = new uint8[ FCOUNT * FRAMESIZE ];
            Alsa.PcmSignedFrames frames;

            Timeout.add_full( Priority.HIGH, timing, feed_to_modem );
            try
            {
                frames = pcmin.readi( (uint8[])buf, FCOUNT );
                if ( frames == -Posix.EPIPE )
                {
                    pcmin.prepare();
                }
                recordMutex.lock();
                toModem.write( buf, (int)frames * FRAMESIZE );
                recordMutex.unlock();
            }
            catch ( FsoAudio.SoundError e )
            {
                logger.error( @"SoundError: $(e.message)" );
            }
            catch ( RingError e )
            {
                recordMutex.unlock();
            }
        }

        return null;
    }

    private void alsaSinkSetup()
    {
        int channels = 1;
        int rate = 8000;

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

        /* start the playback thread now
         */
        if ( !Thread.supported() )
        {
            logger.warning( "Cannot run without thread support!" );
        }
        else
        {
            if ( playbackThread == null )
            {
                try
                {
                    playbackThread = Thread.create<void *>( playbackThreadFunc, true );
                }
                catch ( ThreadError e )
                {
                    logger.debug( @"Error: $(e.message)" );
                    return;
               }
            }
            else
            {
                logger.debug( "Thread already launched" );
            }
            AtomicInt.set(ref runPlaybackThread,1);
        }
    }

    private void alsaSrcSetup()
    {
        int channels = 1;
        int rate = 8000;

        pcmin = new FsoAudio.PcmDevice();
        assert( logger.debug( @"Setup alsa source for modem audio" ) );
        try
        {
            pcmin.open( "plug:dsnoop", Alsa.PcmStream.CAPTURE );
            pcmin.setFormat( access, format, rate, channels );
        }
        catch ( Error e )
        {
            logger.error( @"Error: $(e.message)" );
        }

        /* start the record thread now */
        if ( !Thread.supported() )
        {
            logger.warning( "Cannot run without thread support!" );
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
                    logger.debug( @"Error: $(e.message)" );
                    return;
               }
            }
            else
            {
                logger.debug( "Thread already launched" );
            }
            runRecordThread = true;
        }

    }

    private void alsaSinkCleanup()
    {
        AtomicInt.set(ref runPlaybackThread,0);
        playbackThread.join();
        playbackThread = null;
        pcmout.close();
        pcmout = null;
        fromModem.reset();
    }

    private void alsaSrcCleanup()
    {
        runRecordThread = false;
        recordThread.join();
        recordThread = null;
        pcmin.close();
        pcmin = null;
        toModem.reset();
    }

    private void handleTimingUpdate( CmtSpeech.Event event )
    {
        CmtSpeech.EventData* msg = (CmtSpeech.EventData*) (&event.msg);
        assert( logger.debug( @"modem UL timing update: msec = $(msg.timing_config_ntf.msec) usec = $(msg.timing_config_ntf.usec)" ) );
        timing = msg.timing_config_ntf.msec;
    }

    private void handleDataEvent()
    {
        assert( logger.debug( @"handleDataEvent during protocol state $(connection.protocol_state())" ) );

        CmtSpeech.FrameBuffer dlbuf = null;

        var ok = connection.dl_buffer_acquire( out dlbuf );
        if ( ok == 0 )
        {
            assert( logger.debug( @"received DL packet w/ $(dlbuf.count) bytes (payload is $(dlbuf.pcount))" ) );

            try
            {
                playbackMutex.lock();
                fromModem.write( (uint8[])dlbuf.payload, dlbuf.pcount );
                playbackMutex.unlock();
            }
            catch ( RingError e )
            {
                playbackMutex.unlock();
                logger.warning( @"RingBuffer error: $(e.message)" );
            }

            connection.dl_buffer_release( dlbuf );
        }

    }

    private void handleControlEvent()
    {
        assert( logger.debug( @"handleControlEvent during protocol state $(connection.protocol_state())" ) );

        CmtSpeech.Event event = CmtSpeech.Event();
        CmtSpeech.Transition transition = 0;

        connection.read_event( ref event );

        assert( logger.debug( @"read event, type is $(event.msg_type)" ) );
        transition = connection.event_to_state_transition( event );

        switch ( transition )
        {
            case CmtSpeech.Transition.INVALID:
                assert( logger.debug( "ERROR: invalid state transition") );
                break;

            case CmtSpeech.Transition.6_TIMING_UPDATE:
            case CmtSpeech.Transition.7_TIMING_UPDATE:
                handleTimingUpdate( event );
                break;

            case CmtSpeech.Transition.3_DL_START:
                alsaSinkSetup();
                break;

            case CmtSpeech.Transition.12_UL_START:
                alsaSrcSetup();
                break;

            case CmtSpeech.Transition.4_DLUL_STOP:
                alsaSinkCleanup();
                alsaSrcCleanup();
                break;

            case CmtSpeech.Transition.1_CONNECTED:
            case CmtSpeech.Transition.2_DISCONNECTED:
            case CmtSpeech.Transition.5_PARAM_UPDATE:
            case CmtSpeech.Transition.10_RESET:
            case CmtSpeech.Transition.11_UL_STOP:
                assert( logger.debug( @"State transition ok, new state is $transition" ) );
                break;

            default:
                assert_not_reached();
                break;
        }
    }

    private bool onInputFromChannel( IOChannel source, IOCondition condition )
    {
        //the following line is commented to work arround a vala 0.12.1 bug
        //with the use of to_string() on an enum, which results in a segmentation fault
        //assert( logger.debug( @"onInputFromChannel, condition = $condition" ) );

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
        connection.state_change_call_status( enabled );
        status = enabled;
    }
}
// vim:ts=4:sw=4:expandtab
