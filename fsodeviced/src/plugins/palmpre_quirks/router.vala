/*
 * Copyright (C) 2010 Simon Busch <morphis@gravedo.de>
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

using Gee;

const string FSO_PALMPRE_AUDIO_SCRUN_PATH = "/sys/devices/platform/twl4030_audio/scrun";
const string FSO_PALMPRE_AUDIO_SCINIT_PATH = "/sys/devices/platform/twl4030_audio/scinit";

namespace Router
{
    private class KernelScriptInterface
    {
        public static void loadAndStoreScriptFromFile(string filename)
        {
            if (FsoFramework.FileHandling.isPresent(filename))
            {
                FsoFramework.theLogger.debug( @"loading audio script from '$(filename)'" );
                string script = FsoFramework.FileHandling.read(filename);
                FsoFramework.FileHandling.write(script, FSO_PALMPRE_AUDIO_SCINIT_PATH);
            }
        }

        public static void runScript(string script_name)
        {
            FsoFramework.theLogger.debug( @"executing audio script '$(script_name)'" );
            FsoFramework.FileHandling.write(script_name, FSO_PALMPRE_AUDIO_SCRUN_PATH);
        }

        public static void runScripts(string[] scripts)
        {
            foreach ( var script in scripts )
            {
                runScript( script );
            }
        }
    }

    private enum AudioStateType
    {
        MEDIA_BACKSPEAKER,
        MEDIA_A2DP,
        MEDIA_FRONTSPEAKER,
        MEDIA_HEADSET,
        MEDIA_HEADSET_MIC,
        MEDIA_WIRELESS,
        PHONE_BACKSPEAKER,
        PHONE_BLUETOOTH,
        PHONE_FRONTSPEAKER,
        PHONE_HEADSET,
        PHONE_HEADSET_MIC,
        PHONE_TTY_FULL,
        PHONE_TTY_HCO,
        PHONE_TTY_VCO,
        VOICE_DIALING_BACKSPEAKER,
        VOICE_DIALING_BLUETOOTH_SCO,
        VOICE_DIALING_FRONTSPEAKER,
        VOICE_DIALING_HEADSET_MIC,
        VOICE_DIALING_HEADSET,
    }

    private string audioStateTypeToString( AudioStateType state )
    {
        string result = "<unknown>";

        switch ( state )
        {
            case AudioStateType.MEDIA_BACKSPEAKER:
                result = "MEDIA_BACKSPEAKER";
                break;
            case AudioStateType.MEDIA_A2DP:
                result = "MEDIA_A2DP";
                break;
            case AudioStateType.MEDIA_FRONTSPEAKER:
                result = "MEDIA_FRONTSPEAKER";
                break;
            case AudioStateType.MEDIA_HEADSET:
                result = "MEDIA_HEADSET";
                break;
            case AudioStateType.MEDIA_HEADSET_MIC:
                result = "MEDIA_HEADSET_MIC";
                break;
            case AudioStateType.MEDIA_WIRELESS:
                result = "MEDIA_WIRELESS";
                break;
            case AudioStateType.PHONE_BACKSPEAKER:
                result = "PHONE_BACKSPEAKER";
                break;
            case AudioStateType.PHONE_BLUETOOTH:
                result = "PHONE_BLUETOOTH";
                break;
            case AudioStateType.PHONE_FRONTSPEAKER:
                result = "PHONE_FRONTSPEAKER";
                break;
            case AudioStateType.PHONE_HEADSET:
                result = "PHONE_HEADSET";
                break;
            case AudioStateType.PHONE_HEADSET_MIC:
                result = "PHONE_HEADSET_MIC";
                break;
            case AudioStateType.PHONE_TTY_FULL:
                result = "PHONE_TTY_FULL";
                break;
            case AudioStateType.PHONE_TTY_HCO:
                result = "PHONE_TTY_HCO";
                break;
            case AudioStateType.PHONE_TTY_VCO:
                result = "PHONE_TTY_VCO";
                break;
            case AudioStateType.VOICE_DIALING_BACKSPEAKER:
                result = "VOICE_DIALING_BACKSPEAKER";
                break;
            case AudioStateType.VOICE_DIALING_BLUETOOTH_SCO:
                result = "VOICE_DIALING_BLUETOOTH_SCO";
                break;
            case AudioStateType.VOICE_DIALING_FRONTSPEAKER:
                result = "VOICE_DIALING_FRONTSPEAKER";
                break;
            case AudioStateType.VOICE_DIALING_HEADSET_MIC:
                result = "VOICE_DIALING_HEADSET_MIC";
                break;
            case AudioStateType.VOICE_DIALING_HEADSET:
                result = "VOICE_DIALING_HEADSET";
                break;
        }

        return result;
    }

    private enum AudioEventType
    {
        NONE,
        CALL_STARTED,
        CALL_ENDED,
        HEADSET_IN,
        HEADSET_OUT,
        SWITCH_TO_BACK_SPEAKER,
        SWITCH_TO_FRONT_SPEAKER,
        VOIP_STARTED,
        VOIP_ENDED,
    }

    private AudioEventType stringToAudioEventType( string str )
    {
        AudioEventType event = AudioEventType.NONE;

        switch ( str )
        {
            case "CALL_STARTED":
                event = AudioEventType.CALL_STARTED;
                break;
            case "CALL_ENDED":
                event = AudioEventType.CALL_ENDED;
                break;
            case "HEADSET_IN":
                event = AudioEventType.HEADSET_IN;
                break;
            case "HEADSET_OUT":
                event = AudioEventType.HEADSET_OUT;
                break;
            case "SWITCH_TO_BACK_SPEAKER":
                event = AudioEventType.SWITCH_TO_BACK_SPEAKER;
                break;
            case "SWITCH_TO_FRONT_SPEAKER":
                event = AudioEventType.SWITCH_TO_FRONT_SPEAKER;
                break;
            case "VOIP_STARTED":
                event = AudioEventType.VOIP_STARTED;
                break;
            case "VOIP_ENDED":
                event = AudioEventType.VOIP_ENDED;
                break;
        }

        return event;
    }

    private string audioEventTypeToString( AudioEventType event )
    {
        string result = "<unknown>";
        switch ( event )
        {
            case AudioEventType.CALL_STARTED:
                result = "CALL_STARTED";
                break;
            case AudioEventType.CALL_ENDED:
                result = "CALL_ENDED";
                break;
            case AudioEventType.HEADSET_IN:
                result = "HEADSET_IN";
                break;
            case AudioEventType.HEADSET_OUT:
                result = "HEADSET_OUT";
                break;
            case AudioEventType.SWITCH_TO_BACK_SPEAKER:
                result = "SWITCH_TO_BACK_SPEAKER";
                break;
            case AudioEventType.SWITCH_TO_FRONT_SPEAKER:
                result = "SWITCH_TO_FRONT_SPEAKER";
                break;
            case AudioEventType.VOIP_STARTED:
                result = "VOIP_STARTED";
                break;
            case AudioEventType.VOIP_ENDED:
                result = "VOIP_ENDED";
                break;
        }
        return result;
    }

    private class AudioTransition : GLib.Object
    {
        public AudioStateType next_state
        {
            get; private set;
        }

        public AudioEventType event
        {
            get; private set;
        }

        public AudioTransition( AudioEventType event, AudioStateType next_state )
        {
            this.event = event;
            this.next_state = next_state;
        }
    }

    /**
    * palmpre Audio Router
    **/
    class PalmPre : FsoDevice.BaseAudioRouter
    {
        private const string ROUTER_MODULE_NAME = "fsodevice.palmpre_quirks/audio";
        private Gee.HashMap<AudioStateType,Gee.ArrayList<AudioTransition>> transitions;
        private AudioStateType current_state;
        private string[] available_events;
        private uint8 current_volume;

        construct
        {
            FsoFramework.theLogger.debug( @"Initializing ..." );

            current_volume = 10; // FIXME maybe use some lower volume at startup
            current_state = AudioStateType.MEDIA_BACKSPEAKER;

            /*
            * Here we add all currently available state transitions
            */

            transitions = new Gee.HashMap<AudioStateType,Gee.ArrayList<AudioTransition>>();

            transitions[AudioStateType.MEDIA_BACKSPEAKER] = new Gee.ArrayList<AudioTransition>();
            transitions[AudioStateType.MEDIA_BACKSPEAKER].add(new AudioTransition( AudioEventType.HEADSET_IN, AudioStateType.MEDIA_HEADSET ) );
            transitions[AudioStateType.MEDIA_BACKSPEAKER].add(new AudioTransition( AudioEventType.CALL_STARTED, AudioStateType.PHONE_BACKSPEAKER ) ) ;
            transitions[AudioStateType.MEDIA_BACKSPEAKER].add(new AudioTransition( AudioEventType.SWITCH_TO_FRONT_SPEAKER, AudioStateType.MEDIA_FRONTSPEAKER ) );

            transitions[AudioStateType.MEDIA_FRONTSPEAKER] = new Gee.ArrayList<AudioTransition>();
            transitions[AudioStateType.MEDIA_FRONTSPEAKER].add(new AudioTransition( AudioEventType.SWITCH_TO_BACK_SPEAKER, AudioStateType.MEDIA_BACKSPEAKER ) );
            transitions[AudioStateType.MEDIA_FRONTSPEAKER].add(new AudioTransition( AudioEventType.HEADSET_IN, AudioStateType.MEDIA_HEADSET ) );
            transitions[AudioStateType.MEDIA_FRONTSPEAKER].add(new AudioTransition( AudioEventType.CALL_STARTED, AudioStateType.PHONE_FRONTSPEAKER ) );

            transitions[AudioStateType.MEDIA_HEADSET] = new Gee.ArrayList<AudioTransition>();
            transitions[AudioStateType.MEDIA_HEADSET].add(new AudioTransition( AudioEventType.HEADSET_OUT, AudioStateType.MEDIA_BACKSPEAKER ) );
            transitions[AudioStateType.MEDIA_HEADSET].add(new AudioTransition( AudioEventType.CALL_STARTED, AudioStateType.PHONE_HEADSET ) );

            transitions[AudioStateType.PHONE_BACKSPEAKER] = new Gee.ArrayList<AudioTransition>();
            transitions[AudioStateType.PHONE_BACKSPEAKER].add(new AudioTransition( AudioEventType.HEADSET_IN, AudioStateType.PHONE_HEADSET ) );
            transitions[AudioStateType.PHONE_BACKSPEAKER].add(new AudioTransition( AudioEventType.CALL_ENDED, AudioStateType.MEDIA_BACKSPEAKER ) );
            transitions[AudioStateType.PHONE_BACKSPEAKER].add(new AudioTransition( AudioEventType.SWITCH_TO_FRONT_SPEAKER, AudioStateType.PHONE_FRONTSPEAKER ) );

            transitions[AudioStateType.PHONE_FRONTSPEAKER] = new Gee.ArrayList<AudioTransition>();
            transitions[AudioStateType.PHONE_FRONTSPEAKER].add(new AudioTransition( AudioEventType.HEADSET_IN, AudioStateType.PHONE_HEADSET ) );
            transitions[AudioStateType.PHONE_FRONTSPEAKER].add(new AudioTransition( AudioEventType.CALL_ENDED, AudioStateType.MEDIA_FRONTSPEAKER ) );
            transitions[AudioStateType.PHONE_FRONTSPEAKER].add(new AudioTransition( AudioEventType.SWITCH_TO_BACK_SPEAKER, AudioStateType.PHONE_BACKSPEAKER ) );

            transitions[AudioStateType.PHONE_HEADSET] = new Gee.ArrayList<AudioTransition>();
            transitions[AudioStateType.PHONE_HEADSET].add(new AudioTransition( AudioEventType.HEADSET_OUT, AudioStateType.PHONE_BACKSPEAKER ) );
            transitions[AudioStateType.PHONE_HEADSET].add(new AudioTransition( AudioEventType.CALL_ENDED, AudioStateType.MEDIA_HEADSET ) );
            transitions[AudioStateType.PHONE_HEADSET].add(new AudioTransition( AudioEventType.SWITCH_TO_BACK_SPEAKER, AudioStateType.PHONE_BACKSPEAKER ) );
            transitions[AudioStateType.PHONE_HEADSET].add(new AudioTransition( AudioEventType.SWITCH_TO_FRONT_SPEAKER, AudioStateType.PHONE_FRONTSPEAKER ) );

            /*
            * All available events
            */

            available_events = { };
            available_events += audioEventTypeToString(AudioEventType.CALL_STARTED);
            available_events += audioEventTypeToString(AudioEventType.CALL_ENDED);
            available_events += audioEventTypeToString(AudioEventType.HEADSET_IN);
            available_events += audioEventTypeToString(AudioEventType.HEADSET_OUT);
            available_events += audioEventTypeToString(AudioEventType.SWITCH_TO_BACK_SPEAKER);
            available_events += audioEventTypeToString(AudioEventType.SWITCH_TO_FRONT_SPEAKER);
            available_events += audioEventTypeToString(AudioEventType.VOIP_STARTED);
            available_events += audioEventTypeToString(AudioEventType.VOIP_ENDED);

            /*
            * Load all needed scripts
            */
            var script_path = FsoFramework.theConfig.stringValue( ROUTER_MODULE_NAME, "script_path", "/etc/audio/scripts" );
            string[] scripts_needed = {
                "media_back_speaker",
                "media_front_speaker",
                "media_headset",
                "phone_back_speaker",
                "phone_front_speaker",
                "phone_headset",
                "default"
            };

            foreach ( var script in scripts_needed )
            {
                KernelScriptInterface.loadAndStoreScriptFromFile( @"$(script_path)/$(script).txt" );
            }
        }

        private void handleEvent( AudioEventType event )
        {
            // First handle the transition for the incomming event and switch into the next
            // state
            foreach ( var transition in transitions[current_state] )
            {
                if ( transition.event == event )
                {
                    FsoFramework.theLogger.debug( @"Event '$(audioEventTypeToString(event))' is known by the current state '$(audioStateTypeToString(current_state))'" );
                    releaseState( current_state );
                    initState ( transition.next_state );
                    FsoFramework.theLogger.debug( @"Switched to '$(audioStateTypeToString(current_state))' state" );
                    current_state = transition.next_state;
                    break;
                }
            }

            // Secondly we have to take of incomming call_started and call_ended events. This
            // two requires an additional script to be executed.
            if ( event == AudioEventType.CALL_STARTED )
            {
                KernelScriptInterface.runScript( "call_started" );
            }
            else if ( event == AudioEventType.CALL_ENDED )
            {
                KernelScriptInterface.runScript( "call_ended" );
            }

        }

        private void initState( AudioStateType state )
        {
            string[] scripts = { };

            FsoFramework.theLogger.debug(@"Init '$(audioStateTypeToString(state))' state");

            switch ( state )
            {
                case AudioStateType.MEDIA_BACKSPEAKER:
                    scripts += "media_back_speaker";
                    break;
                case AudioStateType.MEDIA_FRONTSPEAKER:
                    scripts += "media_front_speaker";
                    break;
                case AudioStateType.MEDIA_HEADSET:
                    scripts += "media_headset";
                    break;
                case AudioStateType.PHONE_BACKSPEAKER:
                    scripts += "phone_back_speaker";
                    break;
                case AudioStateType.PHONE_FRONTSPEAKER:
                    scripts += "phone_front_speaker";
                    break;
                case AudioStateType.PHONE_HEADSET:
                    scripts += "phone_headset";
                    break;
            }

            KernelScriptInterface.runScripts(scripts);
        }

        private void releaseState( AudioStateType state )
        {
            string[] scripts = { };

            FsoFramework.theLogger.debug(@"Release '$(audioStateTypeToString(state))' state");

            switch ( state )
            {
                default:
                    break;
            }

            KernelScriptInterface.runScripts(scripts);
        }

        public override void setScenario( string scenario )
        {
            FsoFramework.theLogger.debug("got a $(scenario) audio event");
            // For now we treat the scenario given as event. API need to be
            // reworked for a audio state machine ...
            handleEvent( stringToAudioEventType( scenario.up() ) );
        }

        public override bool isScenarioAvailable( string scenario )
        {
            return (scenario in available_events);
        }

        public override override string[] availableScenarios()
        {
            return available_events;
        }

        public override uint8 currentVolume() throws FreeSmartphone.Error
        {
            return current_volume;
        }

        public override void setVolume( uint8 volume ) throws FreeSmartphone.Error
        {
            if ( current_state == AudioStateType.PHONE_BACKSPEAKER ||
                current_state == AudioStateType.PHONE_FRONTSPEAKER ||
                current_state == AudioStateType.PHONE_HEADSET )
            {
                if (volume < 0 || volume > 10)
                {
                    // FIXME throw some exception?
                    FsoFramework.theLogger.error( @"Invalid volume supplied: $(volume); Only numbers from 0 - 10 are valid" );
                    return;
                }

                string volume_script_name = audioStateTypeToString(current_state).down() + @"_volume_$(volume)";
                KernelScriptInterface.runScript( volume_script_name );
                current_volume = volume;
            }
            else
            {
                // FIXME we need alsa here to set the volume if we are not in a state which
                // has its own volume scripts
            }
        }


        /*
        * NOTE: The following methods are not used by this plugin as we
        *       don't implement audio routing in the way the other plugins
        *       does.
        */

        public override string currentScenario()
        {
            return "";
        }


        public override string pullScenario() throws FreeSmartphone.Device.AudioError
        {
            return "";
        }

        public override void pushScenario( string scenario )
        {
        }

        public override void saveScenario( string scenario )
        {
        }
    }
} /* namespace Router */
