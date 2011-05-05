/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 * Debug Mediators
 **/
public class AtDebugCommand : DebugCommand
{
    public override async void run( string command, string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = new CustomAtCommand( command );

        AtChannel channel = theModem.channel( category ) as AtChannel;
        //FIXME: assert channel is really an At channel
        if ( channel == null )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Channel $category not known" );
        }

        var response = yield channel.enqueueAsync( cmd, command, 0 );
        var result = "";
        for ( int i = 0; i < response.length; ++i )
        {
            result += "\r\n";
            result += response[i];
        }
        this.response = result;
    }
}

public class AtDebugInjectResponse : DebugInjectResponse
{
    public override async void run( string command, string category ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( category );
        if ( channel == null )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Channel $category not known" );
        }
        theModem.injectResponse( command, category );
    }
}

public class AtDebugPing : DebugPing
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<CustomAtCommand>( "CUSTOM" );

        AtChannel channel = theModem.channel( "main" ) as AtChannel;
        //FIXME: assert channel is really an At channel
        if ( channel == null )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Main channel not found" );
        }

        var response = yield channel.enqueueAsync( cmd, "", 0 );
        checkResponseOk( cmd, response );
    }
}

} // namespace FsoGsm

// vim:ts=4:sw=4:expandtab
