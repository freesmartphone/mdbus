/*
 * Copyright (C) 2012 Simon Busch <morphis@gravedo.de>
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
using Gee;
using FsoGsm;

public class Gtm601.SmsHandler : AtSmsHandler
{
    public SmsHandler( FsoGsm.Modem modem )
    {
        base( modem );
    }

    protected override async bool configureMessageIndications()
    {
        // FIXME: do we really want to use a different configuration here?
        // As far as I know the default configuration should work.
        var cnmi = modem.createAtCommand<PlusCNMI>( "+CNMI" );
        var response = yield modem.processAtCommandAsync( cnmi, modem.data().simBuffersSms ? """+CNMI=2,1,2,1,1""" : """+CNMI=2,2,2,1,1""" );
        if ( cnmi.validateOk( response ) != Constants.AtResponse.OK )
            return false;

        return true;
    }
}
