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

using GLib;

using FsoUsage;

internal const string SYSFS_RESUME_REASON_PATH    = "/power/wakeup_event_list";

class LowLevel.PalmPre : FsoUsage.LowLevel, FsoFramework.AbstractObject
{
    private HashTable<string,uint> eventSources;

    construct
    {
        logger.info( "Registering palmpre low level suspend/resume handling" );

        var sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
        sys_power_state = Path.build_filename( sysfs_root, "power", "state" );
        sys_resume_reason = Path.build_filename( sysfs_root, SYSFS_RESUME_REASON_PATH );

        eventSources = new HashTable<string,uint>( str_hash, str_equal );
        eventSources.insert( "RTC_WAKE", ResumeReason.RTC );
        eventSources.insert( "MODEM_WAKE_UART", ResumeReason.GSM );
        eventSources.insert( "MODEM_WAKE_USB", ResumeReason.GSM );
        eventSources.insert( "CORE_NAVI_WAKE", ResumeReason.Unknown ); /* FIXME */
        eventSources.insert( "BT_WAKE", ResumeReason.Bluetooth );
        eventSources.insert( "WIFI_WAKE", ResumeReason.WiFi );
        eventSources.insert( "MODEM_UART_WAKE", ResumeReason.GSM );
        eventSources.insert( "BT_UART_WAKE", ResumeReason.Bluetooth );
        eventSources.insert( "KEYPAD", ResumeReason.Keypad );
        eventSources.insert( "KEY_PTT", ResumeReason.Unknown ); /* FIXME */
        eventSources.insert( "SLIDER", ResumeReason.Slider );
        eventSources.insert( "RINGER_SWITCH", ResumeReason.RingerSwitch );
        eventSources.insert( "POWER_BUTTON", ResumeReason.PowerKey );
        eventSources.insert( "HEADSET_INSERT", ResumeReason.Headphone );
        eventSources.insert( "HEADSET_BUTTON", ResumeReason.Headphone );
        eventSources.insert( "UNKNOWN", ResumeReason.Invalid );
    }

    public override string repr()
    {
        return "<>";
    }

    public void suspend()
    {
        FsoFramework.FileHandling.write( "mem", sys_power_state );
    }

    public ResumeReason resume()
    {
        var reasons = FsoFramework.FileHandling.read( sys_resume_reason ).split( "\n" );
        var reasonkey = "unknown";

        /*
         * An entry in /sys/power/wakeup_event_list looks like this:
         * [    0.000012] GPIO (HEADSET_INSERT) omap3_wakeup_sources_save+0x114/0x144 (a004962c)
         */
        try
        {
            var regex = new Regex( """^\[.*\]\s.*\s\((\w*)\)\s.*\s\(.*\)$""" );

            if ( reasons != null && reasons.length > 0 )
            {
                string[] parts = regex.split_full(reasons[0]);
                if ( parts != null && parts.length == 3 )
                {
                    reasonkey = parts[1];
                }
            }
        }
        catch ( GLib.RegexError err )
        {
            logger.error("Regex determination of the resumevalue failed");
        }

        var reasonvalue = eventSources.lookup( reasonkey );
        if ( reasonvalue == 0 )
        {
           logger.info( "No resume reason marked in %s".printf( sys_resume_reason ) );
           return ResumeReason.Unknown;
        }

        return (ResumeReason) reasonvalue;
    }
}

string sys_power_state;
string sys_resume_reason;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    FsoFramework.theLogger.debug( "lowlevel_palmpre fso_factory_function" );
    return "fsousage.lowlevel_palmpre";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}

// vim:ts=4:sw=4:expandtab
