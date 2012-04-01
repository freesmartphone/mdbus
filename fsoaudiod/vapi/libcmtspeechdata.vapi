/*
 * (C) 2011-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 */

[CCode (cprefix = "", lower_case_cprefix = "cmtspeech_")]
namespace CmtSpeech
{
    /* Enums */

    [CCode (cname = "gint", cprefix = "CMTSPEECH_STATE_", has_type_id = false, cheader_filename = "cmtspeech.h")]
    public enum State
    {
        INVALID,
        DISCONNECTED,
        CONNECTED,
        ACTIVE_DL,
        ACTIVE_DLUL,
        TEST_RAMP_PING_ACTIVE
    }

    [CCode (cname = "gint", cprefix = "CMTSPEECH_TR_", has_type_id = false, cheader_filename = "cmtspeech.h")]
    public enum Transition
    {
        INVALID,
        0_NO_CHANGE,
        1_CONNECTED,
        2_DISCONNECTED,
        3_DL_START,
        4_DLUL_STOP,
        5_PARAM_UPDATE,
        6_TIMING_UPDATE,
        7_TIMING_UPDATE,
        10_RESET,
        11_UL_STOP,
        12_UL_START
    }

    [CCode (cname = "gint", cprefix = "CMTSPEECH_BUFFER_TYPE_", has_type_id = false, cheader_filename = "cmtspeech.h")]
    public enum BufferType
    {
        PCM_S16_LE
    }

    [CCode (cname = "gint", cprefix = "CMTSPEECH_EVENT_", has_type_id = false, cheader_filename = "cmtspeech.h")]
    public enum EventType
    {
        CONTROL,
        DL_DATA,
        XRUN
    }

    [CCode (cname = "gint", cprefix = "CMTSPEECH_DATA_TYPE_", has_type_id = false, cheader_filename = "cmtspeech.h")]
    public enum FrameFlags
    {
        ZERO,
        INVALID,
        VALID
    }

    [CCode (cname = "gint", cprefix = "CMTSPEECH_SPC_FLAGS_", has_type_id = false, cheader_filename = "cmtspeech.h")]
    public enum SpcFlags
    {
        SPEECH,
        BFI,
        ATTENUATE,
        DEC_RESET,
        MUTE,
        PREV,
        DTX_USED
    }

    [CCode (cname = "gint", cprefix = "CMTSPEECH_SAMPLE_RATE_", has_type_id = false, cheader_filename = "cmtspeech_msgs.h")]
    public enum SampleRate
    {
        NONE,
        8KHZ,
        16KHZ
    }

    [CCode (cname = "gint", cprefix = "CMTSPEECH_TRACE_", has_type_id = false, cheader_filename = "cmtspeech_msgs.h")]
    public enum TraceType
    {
        ERROR,
        INFO,
        STATE_CHANGE,
        IO,
        DEBUG,
        INTERNAL
    }

    /* Structs */

    [Compact]
    [CCode (cname = "struct cmtspeech_buffer_s", free_function = "", cheader_filename = "cmtspeech.h")]
    public class FrameBuffer
    {
        public BufferType type;        /**< buffer type (CMTSPEECH_BUFFER_TYPE_*) */
        public int count;              /**< octets of valid data (including header) */
        public int pcount;             /**< octets of valid payload data */
        public int size;               /**< octets of allocated space */
        public FrameFlags frame_flags; /**< frame flags; enum CMTSPEECH_DATATYPE_* */
        public SpcFlags spc_flags;     /**< speech codec flags for the frame;
                                            for UL: always set to zero,
                                            for DL: bitmask of CMTSPEECH_SPC_FLAGS_* */
        public uint8* data;            /**< pointer to a buffer of 'size' octets */
        public uint8* payload;         /**< pointer to frame payload */
    }

    [CCode (cname = "struct cmtspeech_event_s", destroy_function = "", cheader_filename = "cmtspeech.h,libcmtspeechdata.h")]
    public struct Event
    {
        public State state;
        public State prev_state;
        public int msg_type;
        public EventData msg;
    }

    [CCode (cname = "CmtSpeechEventData", destroy_function = "", cheader_filename = "libcmtspeechdata.h")]
    public struct EventData
    {
        public SsiConfigResp ssi_config_resp;
        public SpeechConfigReq speech_config_req;
        public TimingConfigNtf timing_config_ntf;
    }

    [CCode (cname = "CmtSpeechSsiConfigResp", destroy_function = "", cheader_filename = "libcmtspeechdata.h")]
    public struct SsiConfigResp
    {
        public uint8 layout;
        public uint8 version;
        public uint8 result;
    }

    [CCode (cname = "CmtSpeechConfigReq", destroy_function = "", cheader_filename = "libcmtspeechdata.h")]
    public struct SpeechConfigReq
    {
        public uint8 speech_data_stream;
        public uint8 call_user_connect_ind;
        public uint8 codec_info;
        public uint8 cellular_info;
        public uint8 sample_rate;
        public uint8 data_format;
        public bool layout_changed;
    }

    [CCode (cname = "CmtSpeechTimingConfigNtf", destroy_function = "", cheader_filename = "libcmtspeechdata.h")]
    public struct TimingConfigNtf
    {
        uint16 msec;
        uint16 usec;
        Posix.timespec tstamp;
    }

    /* Static */

    public static string version_str();
    public static int protocol_version();
    public static void init();
    [CCode (has_target = false)]
    public delegate void trace_handler_t( int priority, string message, va_list args );
    public static void trace_toggle( int priority, bool enabled );
    public static int set_trace_handler( trace_handler_t func );

    /* Classes */

    [Compact]
    [CCode (cprefix = "cmtspeech_", cname = "cmtspeech_t", free_function = "cmtspeech_close", cheader_filename = "cmtspeech.h")]
    public class Connection
    {
        [CCode (cname = "cmtspeech_open")]
        public Connection();

        //public int close();
        public int descriptor();
        public int check_pending( out EventType flags_mask );
        public int read_event( ref Event event );
        public Transition event_to_state_transition( Event event );

        public int set_wb_preference( bool enabled );
        public State protocol_state();

        public bool is_ssi_connection_enabled();
        public bool is_active();

        public int state_change_call_status( bool state );
        public int state_change_call_connect( bool state );
        public int state_change_error();

        public int ul_buffer_acquire( out FrameBuffer buffer );
        public int ul_buffer_release( FrameBuffer buffer );

        public int dl_buffer_acquire( out FrameBuffer buffer );
        public int dl_buffer_release( FrameBuffer buffer );

        public SampleRate buffer_codec_sample_rate();
        public SampleRate buffer_sample_rate();

        public FrameBuffer dl_buffer_find_with_data( uint8* data);

        public string backend_name();
        public int backend_message( int type, int args, ... );
        public int send_timing_request();
        public int send_ssi_config_request( bool active );

        public int test_data_ramp_req( uint8 rampstart, uint8 ramplen );
    }


} /* namespace CmtSpeech */

// vim:ts=4:sw=4:expandtab
