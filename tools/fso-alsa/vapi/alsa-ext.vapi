// scheduled for upstream inclusion to Vala

[CCode (cheader_filename = "alsa/asoundlib.h")]
namespace Alsa2
{
    [CCode (cname = "snd_pcm_access_t", cprefix = "SND_PCM_ACCESS_")]
    public enum PcmAccess
    {
        MMAP_INTERLEAVED,
        MMAP_NONINTERLEAVED,
        MMAP_COMPLEX,
        RW_INTERLEAVED,
        RW_NONINTERLEAVED,
        LAST,
    }

    [CCode (cname = "snd_pcm_class_t", cprefix = "SND_PCM_CLASS_")]
    public enum PcmClass
    {
        GENERIC,
        MULTI,
        MODEM,
        DIGITIZER,
        LAST,
    }

    [CCode (cname = "snd_pcm_format_t", cprefix = "SND_PCM_FORMAT_")]
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

    [CCode (cname = "gint", cprefix = "SND_PCM_")]
    public enum PcmMode
    {
        NONBLOCK,
        ASYNC,
        NO_AUTO_RESAMPLE,
        NO_AUTO_CHANNELS,
        NO_AUTO_FORMAT,
        NO_SOFTVOL,
    }

    [CCode (cname = "snd_pcm_start_t", cprefix = "SND_PCM_START_")]
    public enum PcmStart
    {
        DATA,
        EXPLICIT,
        LAST,
    }

    [CCode (cname = "snd_pcm_state_t", cprefix = "")]
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

    [CCode (cname = "snd_pcm_stream_t", cprefix = "SND_PCM_STREAM_")]
    public enum PcmStream
    {
        PLAYBACK,
        CAPTURE,
        LAST,
    }

    [CCode (cname = "snd_pcm_subclass_t", cprefix = "SND_PCM_SUBCLASS_")]
    public enum PcmSubclass
    {
        GENERIC_MIX,
        MULTI_MIX,
        LAST,
    }

    [CCode (cname = "snd_pcm_subformat_t", cprefix = "SND_PCM_SUBFORMAT_")]
    public enum PcmSubformat
    {
        STD,
        LAST,
    }

    [CCode (cname = "snd_pcm_tstamp_t", cprefix = "SND_PCM_TSTAMP_")]
    public enum PcmTimestamp
    {
        NONE,
        ENABLE,
        MMAP,
        LAST,
    }

    [CCode (cname = "snd_pcm_type_t", cprefix = "SND_PCM_TYPE_")]
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

    [CCode (cname = "snd_pcm_xrun_t", cprefix = "SND_PCM_XRUN_")]
    public enum PcmXrun
    {
        NONE,
        STOP,
        LAST,
    }

    [Compact]
    [CCode (cname = "snd_pcm_access_mask_t")]
    public class PcmAccessMask
    {
    }

    [Compact]
    [CCode (cname = "snd_pcm_format_mask_t")]
    public class PcmFormatMask
    {
    }

    [Compact]
    [CCode (cname = "snd_pcm_subformat_mask_t")]
    public class PcmSubformatMask
    {
    }

    [Compact]
    [CCode (cname = "snd_pcm_timestamp_t")]
    public class PcmSoftwareTimestamp
    {
    }

    [Compact]
    [CCode (cname = "snd_pcm_htimestamp_t")]
    public class PcmHardwareTimestamp
    {
    }

    [Compact]
    [CCode (cname = "snd_pcm_info_t")]
    public class PcmInfo
    {
    }

    [Compact]
    [CCode (cname = "snd_pcm_sw_params_t")]
    public class PcmHardwareParams
    {
    }

    [Compact]
    [CCode (cname = "snd_pcm_sw_params_t")]
    public class PcmSoftwareParams
    {
    }

    [Compact]
    [CCode (cname = "snd_pcm_uframes_t")]
    public class PcmUnsignedFrames
    {
    }

    [Compact]
    [CCode (cname = "snd_pcm_sframes_t")]
    public class PcmSignedFrames
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
    public struct SyncId
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
        public int hw_params_current( out PcmHardwareParams params );
        public int hw_params( PcmHardwareParams params );
        public int hw_free();
        public int sw_params_current( out PcmSoftwareParams params );
        public int sw_params( PcmSoftwareParams params );
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
        public PcmSignedFrames writei( void* buffer, PcmUnsignedFrames size );
        public PcmSignedFrames readi( void* buffer, PcmUnsignedFrames size );
        public PcmSignedFrames writen( out void* bufs, PcmUnsignedFrames size );
        public PcmSignedFrames readn( out void* bufs, PcmUnsignedFrames size );
        public int wait( int timeout );
        public int link( PcmDevice otherDevice );
        public int unlink();
    }
}
