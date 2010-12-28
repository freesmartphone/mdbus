/*
 * Copyright (C) 2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using Gee;
using FsoGsm;

namespace NokiaIsi
{

public class IsiDeviceGetInformation : DeviceGetInformation
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        /* revision, model, manufacturer, imei */
        info = new GLib.HashTable<string,Variant>( str_hash, str_equal );

        info.insert( "manufacturer", "NOKIA" );
    }
}

static void registerMediators( HashMap<Type,Type> mediators )
{
    mediators[ typeof(DeviceGetInformation) ]            = typeof( IsiDeviceGetInformation );

    theModem.logger.debug( "Nokia ISI mediators registered" );
}

} /* namespace NokiaIsi */
