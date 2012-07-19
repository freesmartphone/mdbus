/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

/**
 * This file contains Dbus/AT command mediators only using official 3GPP AT commands.
 *
 * Do _not_ add vendor-specific mediators here, instead add them to your modem plugin.
 **/

using Gee;

namespace FsoGsm {

/**
 * PDP Mediators
 **/
public class AtPdpActivateContext : PdpActivateContext
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var data = modem.data();
        if ( data.contextParams == null )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "No credentials set. Call org.freesmartphone.GSM.PDP.SetCredentials first." );
        }
        yield modem.pdphandler.activate();
    }
}

public class AtPdpDeactivateContext : PdpDeactivateContext
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield modem.pdphandler.deactivate();
    }
}

public class AtPdpGetCredentials : PdpGetCredentials
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var data = modem.data();
        if ( data.contextParams == null )
        {
            apn = "";
            username = "";
            password = "";
        }
        else
        {
            apn = data.contextParams.apn;
            username = data.contextParams.username;
            password = data.contextParams.password;
        }
    }
}

public class AtPdpSetCredentials : PdpSetCredentials
{
    public override async void run( string apn, string username, string password ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var data = modem.data();
        data.contextParams = new ContextParams( apn, username, password );
    }
}

} // namespace FsoGsm

// vim:ts=4:sw=4:expandtab
