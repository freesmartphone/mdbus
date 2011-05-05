
[CCode (cheader_filename = "alsa/asoundlib.h")]
namespace AlsaExt
{
    [CCode (cname = "snd_pcm_stream_t", cprefix = "SND_PCM_STREAM_")]
    public enum PcmStream
    {
        PLAYBACK,
        CAPTURE,
        LAST
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
        LAST
    }

    [Compact]
    [CCode (cname = "snd_pcm_t", cprefix = "snd_pcm_", free_function = "")]
    public class PcmDevice
    {
        public static int open( out PcmDevice pcm, string name, PcmStream stream, int mode );

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
    }
}

// vim:ts=4:sw=4:expandtab
