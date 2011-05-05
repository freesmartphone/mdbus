
namespace Linux
{
    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace UserspaceInput
    {
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int VERSION;

        [CCode (cheader_filename = "linux/uinput.h")]
        public const int EV_UINPUT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_FF_UPLOAD;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_FF_ERASE;

        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_DEV_CREATE;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_DEV_DESTROY;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_EVBIT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_KEYBIT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_RELBIT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_ABSBIT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_MSCBIT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_LEDBIT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_SNDBIT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_FFBIT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_PHYS;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_SWBIT;

        [CCode (cname = "struct uinput_user_dev", cheader_filename = "linux/uinput.h")]
        struct UserDevice
        {
            string name;
            Input.Id id;
            int ff_effects_max;
            int[] absmax;
            int[] absmin;
            int[] absfuzz;
            int[] absflat;
        }
    }
}

// vim:ts=4:sw=4:expandtab
