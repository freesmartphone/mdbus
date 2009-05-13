/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

[CCode (cprefix = "", lower_case_cprefix = "")]
namespace Linux26 {

    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace Input {

        /*
         * subsystem structures
         */

        [CCode (cname = "struct input_event", cheader_filename = "linux/input.h")]
        public struct Event {
            // FIXME: There should be a posix.TimeVal as well
            public GLib.TimeVal time;
            public uint16 type;
            public uint16 code;
            public int32 value;
        }

        [CCode (cname = "struct input_id", cheader_filename = "linux/input.h")]
        public struct Id {
            public uint16 bustype;
            public uint16 vendor;
            public uint16 product;
            public uint16 version;
        }

        [CCode (cname = "struct input_absinfo", cheader_filename = "linux/input.h")]
        public struct AbsInfo {
            public int32 value;
            public int32 minimum;
            public int32 maximum;
            public int32 fuzz;
            public int32 flat;
        }

        /*
         * ioctls
         */

        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCGVERSION;
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCGID;
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCGREP;
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCSREP;
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCGKEYCODE;
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCSKEYCODE;

        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGNAME( uint len );
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGPHYS( uint len );
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGUNIQ( uint len );

        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGKEY( uint len );
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGLED( uint len );
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGSND( uint len );
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGSW( uint len );

        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGBIT( uint ev, uint len );
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGABS( uint abs );
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCSABS( uint abs );

        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCSFF;
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCRMFF;
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCGEFFECTS;
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCGRAB;

        /*
         * event types
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int EV_SYN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int EV_KEY;
        [CCode (cheader_filename = "linux/input.h")]
        public const int EV_REL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int EV_ABS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int EV_MSC;
        [CCode (cheader_filename = "linux/input.h")]
        public const int EV_SW;
        [CCode (cheader_filename = "linux/input.h")]
        public const int EV_LED;
        [CCode (cheader_filename = "linux/input.h")]
        public const int EV_SND;
        [CCode (cheader_filename = "linux/input.h")]
        public const int EV_REP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int EV_FF;
        [CCode (cheader_filename = "linux/input.h")]
        public const int EV_PWR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int EV_FF_STATUS;

        /*
         * synchronization events
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int SYN_REPORT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SYN_CONFIG;

        /*
         * keys, switches, buttons, etc.
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RESERVED;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ESC;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_5;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_6;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_7;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_8;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_9;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_0;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MINUS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EQUAL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BACKSPACE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TAB;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_Q;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_W;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_E;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_R;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_T;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_U;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_I;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_O;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_P;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LEFTBRACE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RIGHTBRACE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ENTER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LEFTCTRL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_A;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_S;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_D;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_G;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_H;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_J;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_K;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_L;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SEMICOLON;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_APOSTROPHE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_GRAVE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LEFTSHIFT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BACKSLASH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_Z;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_C;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_V;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_B;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_N;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_M;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_COMMA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DOT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SLASH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RIGHTSHIFT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPASTERISK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LEFTALT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SPACE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CAPSLOCK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F5;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F6;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F7;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F8;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F9;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F10;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMLOCK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SCROLLLOCK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP7;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP8;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP9;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPMINUS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP5;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP6;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPPLUS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP0;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPDOT;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ZENKAKUHANKAKU;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_102ND;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F11;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F12;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KATAKANA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HIRAGANA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HENKAN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KATAKANAHIRAGANA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MUHENKAN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPJPCOMMA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPENTER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RIGHTCTRL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPSLASH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SYSRQ;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RIGHTALT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LINEFEED;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HOME;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_UP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PAGEUP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LEFT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RIGHT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_END;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PAGEDOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_INSERT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DELETE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MACRO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MUTE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VOLUMEDOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VOLUMEUP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_POWER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPEQUAL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPPLUSMINUS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PAUSE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SCALE;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPCOMMA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HANGEUL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HANGUEL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HANJA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_YEN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LEFTMETA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RIGHTMETA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_COMPOSE;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_STOP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_AGAIN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PROPS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_UNDO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FRONT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_COPY;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_OPEN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PASTE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FIND;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CUT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HELP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MENU;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CALC;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SETUP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SLEEP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_WAKEUP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FILE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SENDFILE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DELETEFILE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_XFER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PROG1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PROG2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_WWW;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MSDOS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_COFFEE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SCREENLOCK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DIRECTION;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CYCLEWINDOWS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MAIL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BOOKMARKS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_COMPUTER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BACK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FORWARD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CLOSECD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EJECTCD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EJECTCLOSECD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NEXTSONG;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PLAYPAUSE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PREVIOUSSONG;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_STOPCD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RECORD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_REWIND;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PHONE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ISO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CONFIG;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HOMEPAGE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_REFRESH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EXIT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MOVE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EDIT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SCROLLUP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SCROLLDOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPLEFTPAREN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPRIGHTPAREN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NEW;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_REDO;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F13;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F14;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F15;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F16;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F17;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F18;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F19;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F20;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F21;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F22;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F23;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F24;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PLAYCD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PAUSECD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PROG3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PROG4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DASHBOARD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SUSPEND;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CLOSE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PLAY;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FASTFORWARD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BASSBOOST;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PRINT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CAMERA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SOUND;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_QUESTION;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EMAIL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CHAT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SEARCH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CONNECT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FINANCE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SPORT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SHOP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ALTERASE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CANCEL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRIGHTNESSDOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRIGHTNESSUP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MEDIA;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SWITCHVIDEOMODE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KBDILLUMTOGGLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KBDILLUMDOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KBDILLUMUP;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SEND;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_REPLY;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FORWARDMAIL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SAVE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DOCUMENTS;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BATTERY;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BLUETOOTH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_WLAN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_UWB;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_UNKNOWN;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VIDEO_NEXT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VIDEO_PREV;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRIGHTNESS_CYCLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRIGHTNESS_ZERO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DISPLAY_OFF;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_WIMAX;

        /* Range 248 - 255 is reserved for special needs of AT keyboard driver */

        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_MISC;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_0;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_5;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_6;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_7;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_8;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_9;

        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_MOUSE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_LEFT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_RIGHT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_MIDDLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_SIDE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_EXTRA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_FORWARD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_BACK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TASK;

        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_JOYSTICK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_THUMB;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_THUMB2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOP2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_PINKIE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_BASE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_BASE2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_BASE3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_BASE4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_BASE5;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_BASE6;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_DEAD;

        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_GAMEPAD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_A;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_B;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_C;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_Z;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TL2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TR2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_SELECT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_START;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_MODE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_THUMBL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_THUMBR;

        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_DIGI;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_PEN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_RUBBER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_BRUSH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_PENCIL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_AIRBRUSH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_FINGER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_MOUSE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_LENS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOUCH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_STYLUS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_STYLUS2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_DOUBLETAP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_TRIPLETAP;

        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_WHEEL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_GEAR_DOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_GEAR_UP;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_OK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SELECT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_GOTO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CLEAR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_POWER2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_OPTION;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_INFO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TIME;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VENDOR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ARCHIVE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PROGRAM;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CHANNEL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FAVORITES;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EPG;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PVR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MHP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LANGUAGE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TITLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SUBTITLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ANGLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ZOOM;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MODE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KEYBOARD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SCREEN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PC;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TV;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TV2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VCR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VCR2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SAT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SAT2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TAPE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RADIO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TUNER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PLAYER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TEXT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DVD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_AUX;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MP3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_AUDIO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VIDEO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DIRECTORY;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LIST;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MEMO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CALENDAR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RED;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_GREEN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_YELLOW;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BLUE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CHANNELUP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CHANNELDOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FIRST;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LAST;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_AB;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NEXT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RESTART;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SLOW;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SHUFFLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BREAK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PREVIOUS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DIGITS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TEEN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TWEN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VIDEOPHONE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_GAMES;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ZOOMIN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ZOOMOUT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ZOOMRESET;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_WORDPROCESSOR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EDITOR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SPREADSHEET;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_GRAPHICSEDITOR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PRESENTATION;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DATABASE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NEWS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VOICEMAIL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ADDRESSBOOK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MESSENGER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DISPLAYTOGGLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SPELLCHECK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LOGOFF;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DOLLAR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EURO;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FRAMEBACK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FRAMEFORWARD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CONTEXT_MENU;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MEDIA_REPEAT;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DEL_EOL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DEL_EOS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_INS_LINE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DEL_LINE;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_ESC;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F5;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F6;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F7;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F8;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F9;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F10;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F11;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F12;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_D;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_E;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_S;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_B;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT5;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT6;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT7;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT8;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT9;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT10;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_0;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_5;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_6;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_7;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_8;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_9;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_STAR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_POUND;

        /*
        * Relative axes
        */

        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_Z;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_RX;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_RY;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_RZ;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_HWHEEL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_DIAL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_WHEEL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_MISC;
        [CCode (cheader_filename = "linux/input.h")]

        /*
         * Absolute axes
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_Z;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_RX;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_RY;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_RZ;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_THROTTLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_RUDDER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_WHEEL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_GAS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_BRAKE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_HAT0X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_HAT0Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_HAT1X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_HAT1Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_HAT2X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_HAT2Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_HAT3X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_HAT3Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_PRESSURE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_DISTANCE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_TILT_X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_TILT_Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_TOOL_WIDTH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_VOLUME;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MISC;

        /*
         * Switch events
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_LID;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_TABLET_MODE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_HEADPHONE_INSERT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_RFKILL_ALL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_RADIO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_MICROPHONE_INSERT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_DOCK;
        [CCode (cheader_filename = "linux/input.h")]

        /*
         * Misc events
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int MSC_SERIAL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int MSC_PULSELED;
        [CCode (cheader_filename = "linux/input.h")]
        public const int MSC_GESTURE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int MSC_RAW;
        [CCode (cheader_filename = "linux/input.h")]
        public const int MSC_SCAN;

        /*
         * LEDs
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_NUML;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_CAPSL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_SCROLLL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_COMPOSE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_KANA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_SLEEP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_SUSPEND;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_MUTE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_MISC;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_MAIL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_CHARGING;

        /*
         * Autorepeat values
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int REP_DELAY;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REP_PERIOD;

        /*
         * Sounds
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int SND_CLICK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SND_BELL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SND_TONE;
        [CCode (cheader_filename = "linux/input.h")]

        /*
         * IDs.
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int ID_BUS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ID_VENDOR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ID_PRODUCT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ID_VERSION;

        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_PCI;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_ISAPNP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_USB;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_HIL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_BLUETOOTH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_VIRTUAL;

        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_ISA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_I8042;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_XTKBD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_RS232;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_GAMEPORT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_PARPORT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_AMIGA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_ADB;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_I2C;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_HOST;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_GSC;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_ATARI;
    }

    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace Netlink {

        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_ROUTE;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_UNUSED;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_USERSOCK;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_FIREWALL;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_INET_DIAG;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_NFLOG;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_XFRM;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_SELINUX;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_ISCSI;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_AUDIT;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_FIB_LOOKUP;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_CONNECTOR;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_NETFILTER;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_IP6_FW;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_DNRTMSG;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_KOBJECT_UEVENT;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_GENERIC;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_SCSITRANSPORT;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_ECRYPTFS;

        // additions to the socket interface
        [CCode (cheader_filename = "sys/socket.h")]
        public const int AF_NETLINK;

        [CCode (cname = "struct sockaddr_nl", cheader_filename = "linux/netlink.h", destroy_function = "")]
        public struct SockAddrNl
        {
            public int nl_family;
            public ushort nl_pad;
            public uint32 nl_pid;
            public uint32 nl_groups;
        }

        /*
        [CCode (cheader_filename = "sys/socket.h", sentinel = "")]
        public int bind (int sockfd, SockAddrNl addr, ulong length );
        */
    }

    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace Rtc {

        [CCode (cname = "struct rtc_wkalrm", cheader_filename = "linux/rtc.h")]
        public struct WakeAlarm {
            public char enabled;
            public char pending;
            public GLib.Time time;
        }

        [CCode (cheader_filename = "linux/rtc.h,sys/ioctl.h")]
        public const int RTC_RD_TIME;
        [CCode (cheader_filename = "linux/rtc.h,sys/ioctl.h")]
        public const int RTC_SET_TIME;
        [CCode (cheader_filename = "linux/rtc.h,sys/ioctl.h")]
        public const int RTC_WKALM_RD;
        [CCode (cheader_filename = "linux/rtc.h,sys/ioctl.h")]
        public const int RTC_WKALM_SET;
    }
}
