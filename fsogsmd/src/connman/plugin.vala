/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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
 **/

using GLib;

Connman.NetworkDriver network_driver;
Connman.DeviceDriver modem_driver;
FsoGsm.ModemHandler modem;

public static int network_probe( Connman.Network network )
{
    debug( "network_probe()" );
    return 0;
}

public static int network_remove( Connman.Network network )
{
    debug( "network_remove()" );
    return 0;
}

public static int network_connect( Connman.Network network )
{
    debug( "network_connect()" );
    return 0;
}

public static int network_disconnect( Connman.Network network )
{
    debug( "network_disconnect()" );
    return 0;
}

public static int modem_probe( Connman.Device device )
{
    debug( "modem_probe()" );
    return 0;
}

public static int modem_remove( Connman.Device device )
{
    debug( "modem_remove()" );
    return 0;
}

public static int modem_enable( Connman.Device device )
{
    debug( "modem_enable()" );
    return 0;
}

public static int modem_disable( Connman.Device device )
{
    debug( "modem_disable()" );
    return 0;
}

public int fsogsm_plugin_init()
{
    int err;

    modem = new FsoGsm.ModemHandler();
    modem.initialize();

    network_driver = Connman.NetworkDriver() {
        name = "network",
        type = Connman.NetworkType.CELLULAR,
        probe = network_probe,
        remove = network_remove,
        connect = network_connect,
        disconnect = network_disconnect
    };

    modem_driver = Connman.DeviceDriver() {
        name = "modem",
        type = Connman.DeviceType.CELLULAR,
        probe = modem_probe,
        remove = modem_remove,
        enable = modem_enable,
        disable = modem_disable
    };

    err = network_driver.register();
    if ( err < 0 )
    {
        return err;
    }

    err = modem_driver.register();
    if ( err < 0 )
    {
        network_driver.unregister();
        return err;
    }

    return 0;
}

public void fsogsm_plugin_exit()
{
    modem.shutdown();
    network_driver.unregister();
}

