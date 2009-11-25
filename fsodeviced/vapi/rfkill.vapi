// (C) Michael 'Mickey' Lauer <mickey@vanille-media.de>
// LGPL2
// scheduled for inclusion in linux.vapi

namespace Linux
{
    /*
     * RfKill
     */
    [CCode (cname = "struct irfkill_event", cheader_filename = "linux/rfkill.h")]
    public struct RfKillEvent {
        public uint32 idx;
        public uint8 type;
        public uint8 op;
        public uint8 soft;
        public uint8 hard;
    }

    [CCode (cname = "int", cprefix = "RFKILL_STATE_", cheader_filename = "linux/rfkill.h")]
    public enum RfKillState {
        SOFT_BLOCKED,
        UNBLOCKED,
        HARD_BLOCKED
    }

    [CCode (cname = "int", cprefix = "RFKILL_TYPE_", cheader_filename = "linux/rfkill.h")]
    public enum RfKillType {
        ALL,
        WLAN,
        BLUETOOTH,
        UWB,
        WIMAX,
        WWAN
    }

} /* namespace Linux */
