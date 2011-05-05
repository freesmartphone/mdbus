/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

namespace FsoUsage {

public enum ResumeReason
{
    Invalid = 0,
    Accelerometer,
    AuxKey,
    Bluetooth,
    Debug,
    FullBattery,
    GSM,
    GFX,
    GPS,
    Headphone,
    LowBattery,
    PMU,
    PowerKey,
    PhoneKey,
    Unknown,
    WiFi,
    RingerSwitch,
    Slider,
    Keypad,
    RTC,
}

public interface LowLevel : FsoFramework.AbstractObject
{
    /**
     * Whether a resume reason is user initiated or not
     **/
    public bool isUserInitiated( ResumeReason r )
    {
        var res = false;

        switch (r)
        {
            case ResumeReason.Accelerometer:
                res = true;
                break;
            case ResumeReason.Headphone:
                res = true;
                break;
            case ResumeReason.PowerKey:
                res = true;
                break;
            case ResumeReason.PhoneKey:
                res = true;
                break;
            case ResumeReason.Unknown:
                res = true;
                break;
        }

        return res;
    }
    /**
     * Suspend the device
     **/
    public abstract void suspend();
    /**
     * Resume the device, return the resume reason, if available
     **/
    public abstract ResumeReason resume();
}

public class NullLowLevel : LowLevel, FsoFramework.AbstractObject
{
    public override string repr()
    {
        return "<>";
    }

    public void suspend()
    {
        logger.warning( "NullLowlevel::suspend() - this is probably not what you want. Sleeping 5 seconds..." );
        Posix.sleep( 5 );
    }

    public ResumeReason resume()
    {
        logger.warning( "NullLowlevel::resume() - this is probably not what you want. Resume reason will be unknown!" );
        return ResumeReason.Unknown;
    }
}

}

// vim:ts=4:sw=4:expandtab
