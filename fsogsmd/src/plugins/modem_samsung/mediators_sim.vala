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
 */

using FsoGsm;

public class SamsungSimGetAuthStatus : SimGetAuthStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        // NOTE: there is no command to gather the actual SIM auth status
        // we have to remember the last state and set it to the right value
        // whenever a command/response needs a modified sim auth state
        var data = theModem.data();
        status = data.simAuthStatus;
    }
}

public class SamsungSimSendAuthCode : SimSendAuthCode
{
    public override async void run( string pin ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        SamsungIpc.Response response;
        var channel = theModem.channel( "main" ) as Samsung.IpcChannel;

        if ( pin.length != 4 || pin.length != 8 )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Got pin with invalid length of $(pin.length)" );

        var message = SamsungIpc.Security.PinStatusSetMessage();
        message.type = SamsungIpc.Security.PinType.PIN1;
        Memory.copy(message.pin1, pin, pin.length);

        var result = yield channel.enqueue_async( SamsungIpc.RequestType.SET, SamsungIpc.MessageType.SEC_PIN_STATUS,
                                                  (uint8[]) (&message), out response );

        var phoneresp = (SamsungIpc.Generic.PhoneResponseMessage*) (&response);
        if ( phoneresp.code != 0x8000 )
            throw new FreeSmartphone.GSM.Error.SIM_AUTH_FAILED( @"SIM card authentication failed" );
    }
}



