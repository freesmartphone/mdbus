// scheduled for upstream inclusion to Vala

[CCode (cheader_filename = "alsa/asoundlib.h")]
namespace Alsa2
{
    [CCode (cname = "snd_spcm_latency_t", cprefix = "SND_SPCM_LATENCY_", has_type_id = false)]
    public enum PcmSimpleLatency
    {
        STANDARD,
        MEDIUM,
        REALTIME
    }

    [CCode (cname = "snd_spcm_xrun_type_t", cprefix = "SND_SPCM_XRUN_", has_type_id = false)]
    public enum PcmSimpleXrunType
    {
        IGNORE,
        STOP,
    }

    [CCode (cname = "snd_spcm_duplex_t", cprefix = "SND_SPCM_DUPLEX_", has_type_id = false)]
    public enum PcmSimpleDuplex {
	    LIBERAL,
	    PEDANTIC,
    }

    [CCode (cname = "snd_pcm_access_t", cprefix = "SND_PCM_ACCESS_", has_type_id = false)]
    public enum PcmAccess
    {
        MMAP_INTERLEAVED,
        MMAP_NONINTERLEAVED,
        MMAP_COMPLEX,
        RW_INTERLEAVED,
        RW_NONINTERLEAVED,
        LAST,
    }

    [CCode (cname = "snd_pcm_class_t", cprefix = "SND_PCM_CLASS_", has_type_id = false)]
    public enum PcmClass
    {
        GENERIC,
        MULTI,
        MODEM,
        DIGITIZER,
        LAST,
    }

    [CCode (cname = "snd_pcm_format_t", cprefix = "SND_PCM_FORMAT_", has_type_id = false)]
    public enum PcmFormat
    {
        UNKNOWN,
        S8,
        U8,
        S16_LE,
        S16_BE,
        U16_LE,
        U16_BE,
        S24_LE,
        S24_BE,
        U24_LE,
        U24_BE,
        S32_LE,
        S32_BE,
        U32_LE,
        U32_BE,
        FLOAT_LE,
        FLOAT_BE,
        FLOAT64_LE,
        FLOAT64_BE,
        IEC958_SUBFRAME_LE,
        IEC958_SUBFRAME_BE,
        MU_LAW,
        A_LAW,
        IMA_ADPCM,
        MPEG,
        GSM,
        SPECIAL,
        S24_3LE,
        S24_3BE,
        U24_3LE,
        U24_3BE,
        S20_3LE,
        S20_3BE,
        U20_3LE,
        U20_3BE,
        S18_3LE,
        S18_3BE,
        U18_3LE,
        U18_3BE,
        LAST,
        S16,
        U16,
        S24,
        U24,
        S32,
        U32,
        FLOAT,
        FLOAT64,
        IEC958_SUBFRAME,
    }

    [CCode (cname = "gint", cprefix = "SND_PCM_", has_type_id = false)]
    public enum PcmMode
    {
        NONBLOCK,
        ASYNC,
        NO_AUTO_RESAMPLE,
        NO_AUTO_CHANNELS,
        NO_AUTO_FORMAT,
        NO_SOFTVOL,
    }

    [CCode (cname = "snd_pcm_start_t", cprefix = "SND_PCM_START_", has_type_id = false)]
    public enum PcmStart
    {
        DATA,
        EXPLICIT,
        LAST,
    }

    [CCode (cname = "snd_pcm_state_t", cprefix = "", has_type_id = false)]
    public enum PcmState
    {
        OPEN,
        SETUP,
        PREPARED,
        RUNNING,
        XRUN,
        DRAINING,
        PAUSED,
        SUSPENDED,
        DISCONNECTED,
        LAST,
    }

    [CCode (cname = "snd_pcm_stream_t", cprefix = "SND_PCM_STREAM_", has_type_id = false)]
    public enum PcmStream
    {
        PLAYBACK,
        CAPTURE,
        LAST,
    }

    [CCode (cname = "snd_pcm_subclass_t", cprefix = "SND_PCM_SUBCLASS_", has_type_id = false)]
    public enum PcmSubclass
    {
        GENERIC_MIX,
        MULTI_MIX,
        LAST,
    }

    [CCode (cname = "snd_pcm_subformat_t", cprefix = "SND_PCM_SUBFORMAT_", has_type_id = false)]
    public enum PcmSubformat
    {
        STD,
        LAST,
    }

    [CCode (cname = "snd_pcm_tstamp_t", cprefix = "SND_PCM_TSTAMP_", has_type_id = false)]
    public enum PcmTimestamp
    {
        NONE,
        ENABLE,
        MMAP,
        LAST,
    }

    [CCode (cname = "snd_pcm_type_t", cprefix = "SND_PCM_TYPE_", has_type_id = false)]
    public enum PcmType
    {
        HW,
        HOOKS,
        MULTI,
        FILE,
        NULL,
        SHM,
        INET,
        COPY,
        LINEAR,
        ALAW,
        MULAW,
        ADPCM,
        RATE,
        ROUTE,
        PLUG,
        SHARE,
        METER,
        MIX,
        DROUTE,
        LBSERVER,
        LINEAR_FLOAT,
        LADSPA,
        DMIX,
        JACK,
        DSNOOP,
        DSHARE,
        IEC958,
        SOFTVOL,
        IOPLUG,
        MMAP_EMUL,
        LAST,
    }

    [CCode (cname = "snd_pcm_xrun_t", cprefix = "SND_PCM_XRUN_", has_type_id = false)]
    public enum PcmXrun
    {
        NONE,
        STOP,
        LAST,
    }

    [SimpleType]
    [CCode (cname = "snd_pcm_access_mask_t")]
    public struct PcmAccessMask
    {
    }

    [SimpleType]
    [CCode (cname = "snd_pcm_format_mask_t")]
    public struct PcmFormatMask
    {
    }

    [SimpleType]
    [CCode (cname = "snd_pcm_subformat_mask_t")]
    public struct PcmSubformatMask
    {
    }

    [SimpleType]
    [CCode (cname = "snd_pcm_timestamp_t")]
    public struct PcmSoftwareTimestamp
    {
    }

    [SimpleType]
    [CCode (cname = "snd_pcm_htimestamp_t")]
    public struct PcmHardwareTimestamp
    {
    }

    [Compact]
    [CCode (cname = "snd_pcm_info_t", cprefix = "snd_pcm_info_")]
    public class PcmInfo
    {
        public static int alloca( out PcmInfo info );
        public static int malloc( out PcmInfo info );
        public void free();
        public void copy( PcmInfo source );
        public uint get_device();
        public uint get_subdevice();
        public PcmStream get_stream();
        public int get_card();
        public string get_id();
        public string get_name();
        public string get_subdevice_name();
        public PcmClass get_class();
        public PcmSubclass get_subclass();
        public uint get_subdevices_count();
        public uint get_subdevices_avail();
        public PcmSyncId get_sync();
        public void set_device( uint val );
        public void set_subdevice( uint val );
        public void set_stream( PcmStream val );
    }

    [Compact]
    [CCode (cname = "snd_pcm_hw_params_t", cprefix = "snd_pcm_hw_params_", free_function = "snd_pcm_hw_params_free")]
    public class PcmHardwareParams
    {
        public static int alloca( out PcmHardwareParams params );
        public static int malloc( out PcmHardwareParams params );
        public void free();
        public void copy( PcmHardwareParams source );
        public int get_access( PcmAccess access );
        public int get_access_mask( PcmAccessMask mask );
        public int get_format( PcmFormat format );
        public void get_format_mask( PcmFormatMask mask );
        public int get_subformat( PcmSubformat subformat );
        public void get_subformat_mask( PcmSubformatMask mask );
        public int get_channels( out int val );
        public int get_channels_min( out int val );
        public int get_channels_max( out int val );
        public int get_rate( out int val, out int dir );
        public int get_rate_min( out int val, out int dir );
        public int get_rate_max( out int val, out int dir );
        public int get_period_time( out int val, out int dir );
        public int get_period_time_min( out int val, out int dir );
        public int get_period_time_max( out int val, out int dir );
        public int get_period_size( out PcmUnsignedFrames frames, out int dir );
        public int get_period_size_min( out PcmUnsignedFrames frames, out int dir );
        public int get_period_size_max( out PcmUnsignedFrames frames, out int dir );
        public int get_periods( out int val, out int dir );
        public int get_periods_min( out int val, out int dir );
        public int get_periods_max( out int val, out int dir );
        public int get_buffer_time( out int val, out int dir );
        public int get_buffer_time_min( out int val, out int dir );
        public int get_buffer_time_max( out int val, out int dir );
        public int get_buffer_size( out PcmUnsignedFrames frames );
        public int get_buffer_size_min( out PcmUnsignedFrames frames );
        public int get_buffer_size_max( out PcmUnsignedFrames frames );
        public int get_min_align( out PcmUnsignedFrames frames );

        public int can_mmap_sample_resolution();
        public int is_double();
        public int is_batch();
        public int is_block_transfer();
        public int is_monotonic();
        public int can_overrange();
        public int can_pause();
        public int can_resume();
        public int is_half_duplex();
        public int is_joint_duplex();
        public int can_sync_start();
        public int can_disable_period_wakeup();
        public int get_rate_numden( out uint rate_num, out uint rate_den );
        public int get_sbits();
        public int get_fifo_size();
    }

    [Compact]
    [CCode (cname = "snd_pcm_sw_params_t")]
    public class PcmSoftwareParams
    {
    }

    [SimpleType]
    [CCode (cname = "snd_pcm_uframes_t")]
    [IntegerType (rank = 9)]
    public struct PcmUnsignedFrames
    {
    }

    [SimpleType]
    [CCode (cname = "snd_pcm_sframes_t")]
    [IntegerType (rank = 8)]
    public struct PcmSignedFrames
    {
    }

    [Compact]
    [CCode (cname = "snd_pcm_channel_area_t", free_function = "")]
    public struct PcmChannelArea
    {
        public void *addr;
        public uint first;
        public uint step;
    }

    [Compact]
    [CCode (cname = "snd_pcm_sync_id_t", free_function = "")]
    public struct PcmSyncId
    {
        public uchar id[16];
        public ushort id16[8];
        public uint id32[4];
    }

    [Compact]
    [CCode (cname = "snd_pcm_t", cprefix = "snd_pcm_", free_function = "")]
    public class PcmDevice
    {
        public static int open( out PcmDevice pcm, string name, PcmStream stream, PcmMode mode = 0 );

        public int close();
        [CCode (cname = "snd_pcm_name")]
        public string get_name();
        [CCode (cname = "snd_pcm_type")]
        public PcmType get_type();
        [CCode (cname = "snd_pcm_stream")]
        public PcmStream get_stream();
        [CCode (cname = "snd_pcm_poll_descriptors_count")]
        public int get_poll_descriptors_count();
        [CCode (cname = "snd_pcm_poll_descriptors")]
        public int set_poll_descriptors( Posix.pollfd[] pfds );
        [CCode (cname = "snd_pcm_poll_descriptors_revents")]
        public int set_poll_descriptors_revents( Posix.pollfd[] pfds, ushort[] revents );
        [CCode (cname = "snd_pcm_nonblock")]
        public int set_nonblock( bool nonblock );

        //public int snd_async_add_pcm_handler( snd_async_handler_t **handler, snd_pcm_t *pcm, snd_async_callback_t callback, void *private_data );
        //public PcmDevice async_handler_get_pcm( snd_async_handler_t *handler );
        public int info( PcmInfo info );
        public int sw_params_current( out PcmSoftwareParams params );
        public int sw_params( PcmSoftwareParams params );
        public int hw_free();
        public int prepare();
        public int reset();
        [CCode (cname = "snd_pcm_status")]
        public int set_status( PcmState status );
        public int start();
        public int drop();
        public int drain();
        public int pause( bool enable );
        public PcmState state();
        public int hwsync();
        public int delay( PcmSignedFrames delayp );
        public int resume();
        public int htimestamp( PcmUnsignedFrames avail, PcmHardwareTimestamp tstamp );
        public PcmSignedFrames avail();
        public PcmSignedFrames avail_update();
        public int avail_delay( out PcmSignedFrames availp, out PcmSignedFrames delayp );
        public PcmSignedFrames rewindable();
        public PcmSignedFrames rewind( PcmUnsignedFrames frames );
        public PcmSignedFrames forwardable();
        public PcmSignedFrames forward( PcmUnsignedFrames frames );
        public PcmSignedFrames writei( [CCode (array_length = false)] uint8[] buffer, PcmUnsignedFrames size );
        public PcmSignedFrames writen( [CCode (array_length = false)] uint8* buffer, PcmUnsignedFrames size );
        //public PcmSignedFrames readi( [CCode (array_length = false)] out uint8[] buffer, PcmUnsignedFrames size );
        //public PcmSignedFrames readn( [CCode (array_length = false)] out uint8[] buffer, PcmUnsignedFrames size );
        public PcmSignedFrames readi( out uint8* buffer, PcmUnsignedFrames size );
        public PcmSignedFrames readn( out uint8* buffer, PcmUnsignedFrames size );
        public int wait( int timeout );
        public int link( PcmDevice otherDevice );
        public int unlink();

        // high level API
        public int recover( int err, int silent );
        public int set_params( PcmFormat format, PcmAccess access, uint channels, uint rate, int soft_resample, uint latency );
        public int get_params( out PcmUnsignedFrames buffer_size, out PcmUnsignedFrames period_size );

        // simple setup
        [CCode (cname = "snd_spcm_init")]
        public int simple_init( uint rate, uint channels, PcmFormat format, PcmSubformat subformat, PcmSimpleLatency latency, PcmAccess access, PcmSimpleXrunType xrun );
        [CCode (cname = "snd_spcm_init_duplex")]
        public static int simple_init_duplex( PcmDevice playback, PcmDevice capture, uint rate, uint channels, PcmFormat format, PcmSubformat subformat, PcmSimpleLatency latency, PcmAccess access, PcmSimpleXrunType xrun, PcmSimpleDuplex duplex );
        [CCode (cname = "snd_spcm_get_params")]
        public int simple_get_params( out uint rate, out PcmUnsignedFrames buffer_size, out PcmUnsignedFrames period_size );

        // HW params API
        public int hw_params_current( out PcmHardwareParams params );
        public int hw_params( PcmHardwareParams params );
        public int hw_params_any( PcmHardwareParams params );
        public int hw_params_test_access( PcmHardwareParams params, PcmAccess access );
        public int hw_params_set_access( PcmHardwareParams params, PcmAccess access );
        public int hw_params_set_access_first( PcmHardwareParams params, out PcmAccess access );
        public int hw_params_set_access_last( PcmHardwareParams params, out PcmAccess access );
        public int hw_params_set_access_mask( PcmHardwareParams params, out PcmAccessMask mask );
        public int hw_params_test_format( PcmHardwareParams params, PcmFormat format );
        public int hw_params_set_format( PcmHardwareParams params, PcmFormat format );
        public int hw_params_set_format_first( PcmHardwareParams params, out PcmFormat format );
        public int hw_params_set_format_last( PcmHardwareParams params, out PcmFormat format );
        public int hw_params_set_format_mask( PcmHardwareParams params, out PcmFormatMask mask );
        public int hw_params_test_subformat( PcmHardwareParams params, PcmSubformat subformat );
        public int hw_params_set_subformat( PcmHardwareParams params, PcmSubformat subformat );
        public int hw_params_set_subformat_first( PcmHardwareParams params, out PcmSubformat subformat );
        public int hw_params_set_subformat_last( PcmHardwareParams params, out PcmSubformat subformat );
        public int hw_params_set_subformat_mask( PcmHardwareParams params, out PcmSubformatMask mask );
        public int hw_params_test_channels( PcmHardwareParams params, uint val );
        public int hw_params_set_channels( PcmHardwareParams params, uint val );
        public int hw_params_set_channels_min( PcmHardwareParams params, out int val );
        public int hw_params_set_channels_max( PcmHardwareParams params, out int val );
        public int hw_params_set_channels_minmax( PcmHardwareParams params, out uint min, out int max );
        public int hw_params_set_channels_near( PcmHardwareParams params, out int val );
        public int hw_params_set_channels_first( PcmHardwareParams params, out int val );
        public int hw_params_set_channels_last( PcmHardwareParams params, out int val );
        public int hw_params_test_rate( PcmHardwareParams params, uint val, int dir );
        public int hw_params_set_rate( PcmHardwareParams params, uint val, int dir );
        public int hw_params_set_rate_min( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_set_rate_max( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_set_rate_minmax( PcmHardwareParams params, out uint min, out int mindir, out int max, out int maxdir );
        public int hw_params_set_rate_near( PcmHardwareParams params, ref int val, int dir );
        public int hw_params_set_rate_first( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_set_rate_last( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_set_rate_resample( PcmHardwareParams params, uint val );
        public int hw_params_get_rate_resample( PcmHardwareParams params, out int val );
        public int hw_params_set_export_buffer( PcmHardwareParams params, uint val );
        public int hw_params_get_export_buffer( PcmHardwareParams params, out int val );
        public int hw_params_set_period_wakeup( PcmHardwareParams params, uint val );
        public int hw_params_get_period_wakeup( PcmHardwareParams params, out int val );
        public int hw_params_test_period_time( PcmHardwareParams params, uint val, int dir );
        public int hw_params_set_period_time( PcmHardwareParams params, uint val, int dir );
        public int hw_params_set_period_time_min( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_set_period_time_max( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_set_period_time_minmax( PcmHardwareParams params, out uint min, out int mindir, out int max, out int maxdir );
        public int hw_params_set_period_time_near( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_set_period_time_first( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_set_period_time_last( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_test_period_size( PcmHardwareParams params, PcmUnsignedFrames frames, int dir );
        public int hw_params_set_period_size( PcmHardwareParams params, PcmUnsignedFrames frames, int dir );
        public int hw_params_set_period_size_min( PcmHardwareParams params, out PcmUnsignedFrames frames, out int dir );
        public int hw_params_set_period_size_max( PcmHardwareParams params, out PcmUnsignedFrames frames, out int dir );
        public int hw_params_set_period_size_minmax( PcmHardwareParams params, out PcmUnsignedFrames min, out int mindir, out PcmUnsignedFrames max, out int maxdir );
        public int hw_params_set_period_size_near( PcmHardwareParams params, out PcmUnsignedFrames frames, out int dir );
        public int hw_params_set_period_size_first( PcmHardwareParams params, out PcmUnsignedFrames frames, out int dir );
        public int hw_params_set_period_size_last( PcmHardwareParams params, out PcmUnsignedFrames frames, out int dir );
        public int hw_params_set_period_size_integer( PcmHardwareParams params );
        public int hw_params_test_periods( PcmHardwareParams params, uint val, int dir );
        public int hw_params_set_periods( PcmHardwareParams params, uint val, int dir );
        public int hw_params_set_periods_min( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_set_periods_max( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_set_periods_minmax( PcmHardwareParams params, out uint min, out int mindir, out int max, out int maxdir );
        public int hw_params_set_periods_near( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_set_periods_first( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_set_periods_last( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_set_periods_integer( PcmHardwareParams params );
        public int hw_params_test_buffer_time( PcmHardwareParams params, uint val, int dir );
        public int hw_params_set_buffer_time( PcmHardwareParams params, uint val, int dir );
        public int hw_params_set_buffer_time_min( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_set_buffer_time_max( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_set_buffer_time_minmax( PcmHardwareParams params, out uint min, out int mindir, out int max, out int maxdir );
        public int hw_params_set_buffer_time_near( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_set_buffer_time_first( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_set_buffer_time_last( PcmHardwareParams params, out int val, out int dir );
        public int hw_params_test_buffer_size( PcmHardwareParams params, PcmUnsignedFrames frames );
        public int hw_params_set_buffer_size( PcmHardwareParams params, PcmUnsignedFrames frames );
        public int hw_params_set_buffer_size_min( PcmHardwareParams params, out PcmUnsignedFrames frames );
        public int hw_params_set_buffer_size_max( PcmHardwareParams params, out PcmUnsignedFrames frames );
        public int hw_params_set_buffer_size_minmax( PcmHardwareParams params, out PcmUnsignedFrames min, out PcmUnsignedFrames max );
        public int hw_params_set_buffer_size_near( PcmHardwareParams params, out PcmUnsignedFrames frames );
        public int hw_params_set_buffer_size_first( PcmHardwareParams params, out PcmUnsignedFrames frames );
        public int hw_params_set_buffer_size_last( PcmHardwareParams params, out PcmUnsignedFrames frames );

        // format conversion
        public PcmSignedFrames bytes_to_frames( ssize_t bytes );
        public ssize_t frames_to_bytes( PcmSignedFrames frames );
        public long bytes_to_samples( ssize_t bytes );
        public ssize_t samples_to_bytes( long samples );
    }
}

// vim:ts=4:sw=4:expandtab
