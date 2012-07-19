/**
 * Copyright (C) 2010-2012  Antonio Ospite <ospite@studenti.unina.it>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

using GLib;
using FsoGsm;

class LowLevel.MotorolaEZX : FsoGsm.LowLevel, FsoFramework.AbstractObject
{
    public const string MODULE_NAME = "fsogsm.lowlevel_motorola_ezx";
    private static bool initDone = false;
    private int muxfds[16];

    construct
    {
        logger.info( "Registering Motorola EZX low level poweron/poweroff handling" );
    }

    public override string repr()
    {
        return "<>";
    }

    private bool modem_init()
    {
        int count_retries = 10;

        logger.debug("********************** Modem init **********************");
        Posix.system("modprobe ohci-hcd");
        Posix.sleep(2);
        Posix.system("modprobe moto-usb-ipc");
        Posix.system("modprobe ts27010mux");

        var modem_node = config.stringValue( MODULE_NAME, "modem_node" );
        int ipc = -1;
        do {
            logger.debug(@"Trying to open $(modem_node)...");
            ipc = Posix.open(modem_node, Posix.O_RDWR);
            if (ipc < 0) {
                logger.debug(@"Error $ipc ... retrying ( $count_retries )");
                Posix.sleep(1);
            }
            count_retries--;
        } while (ipc < 0 && Posix.errno == Posix.ENODEV && count_retries >= 0);

        if (ipc < 0) {
            string message = Posix.strerror(Posix.errno);
            logger.debug(@"$(modem_node): $message");
            return false;
        }

        uint line = config.stringValue( MODULE_NAME, "gsm_ldisc" ).to_int();
        logger.debug(@"Setting ldisc $(line)...");
        uint ret;
        ret = Posix.ioctl(ipc, Linux.Termios.TIOCSETD, &line);
        if (ret < 0) {
            string message = Posix.strerror(Posix.errno);
            logger.debug(@"ioctl: $message");
            return false;
        }

        /* open mux devices */
        var muxnode_prefix = config.stringValue( MODULE_NAME, "muxnode_prefix");
        var dlci_lines = config.stringListValue( MODULE_NAME, "dlci_lines" );
        string devpath;
        for (uint i = 0; i < dlci_lines.length; i++) {
            devpath = muxnode_prefix + dlci_lines[i];
            logger.debug(@"Trying to open $devpath ...");

            muxfds[i] = Posix.open(devpath, Posix.O_RDWR|Posix.O_NOCTTY);
            if (muxfds[i] < 0) {
                string message = Posix.strerror(Posix.errno);
                logger.debug(@"$devpath : $message");
            } else {
                logger.debug(@"$devpath opened.");
            }
        }

        return true;
    }

    public bool poweron()
    {
        logger.debug( "lowlevel_motorola_ezx_poweron()" );
        if (initDone == true)
            return true;

        bool ret = modem_init();
        initDone = true;
        return ret;
    }

    public bool poweroff()
    {
        logger.debug( "lowlevel_motorola_ezx_poweroff()" );
        return true;
    }

    public bool suspend()
    {
        debug( "lowlevel_motorola_ezx_suspend()" );
        return true;
    }

    public bool resume()
    {
        debug( "lowlevel_motorola_ezx_resume()" );
        return true;
    }
}

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    FsoFramework.theLogger.debug( "lowlevel_motorola_ezx fso_factory_function" );
    return LowLevel.MotorolaEZX.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}

// vim:ts=4:sw=4:expandtab
