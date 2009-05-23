/* ascenario.vapi
 *
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

[CCode (cprefix = "SND_", lower_case_cprefix = "snd_", cheader_filename = "alsa/ascenario.h")]
namespace Sound {

    public const string SCN_PLAYBACK_SPEAKER;
    public const string SCN_PLAYBACK_HEADPHONES;
    public const string SCN_PLAYBACK_HEADSET;
    public const string SCN_PLAYBACK_BLUETOOTH;
    public const string SCN_PLAYBACK_HANDSET;
    public const string SCN_PLAYBACK_GSM;
    public const string SCN_PLAYBACK_LINE;

    public const string SCN_CAPTURE_MIC;
    public const string SCN_CAPTURE_LINE;
    public const string SCN_CAPTURE_HEADSET;
    public const string SCN_CAPTURE_HANDSET;
    public const string SCN_CAPTURE_BLUETOOTH;
    public const string SCN_CAPTURE_GSM;

    public const string SCN_PHONECALL_HANDSET;
    public const string SCN_PHONECALL_HEADSET;
    public const string SCN_PHONECALL_BLUETOOTH;
    public const string SCN_PHONECALL_IP;

    public enum Qos {
        HIFI,
        VOICE,
        SYSTEM
    }

    [Compact]
    [CCode (cname = "struct snd_scenario", free_function = "snd_scenario_exit")]
    public class Scenario {
        [CCode (cname = "snd_scenario_init")]
        public Scenario (string card_name = "default");
        public int reload ();
        public int set_scn (string scenario);
        public string get_scn();
        public int list (out string[] scenarios);
        public int set_qos(Qos qos);
        public Qos get_qos();
        public int get_master_playback_volume();
        public int get_master_playback_switch();
        public int snd_scenario_get_master_capture_volume();
        public int snd_scenario_get_master_capture_switch();
        public static int dump(string card_name = "default");
    }
}
