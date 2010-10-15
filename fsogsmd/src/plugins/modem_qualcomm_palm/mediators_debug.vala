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
 
using FsoGsm;

public class MsmDebugPing : DebugPing
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        try
        {
            var cmds = MsmModemAgent.instance().commands;
            yield cmds.test_alive();
        }
        catch ( Msmcomm.Error err0 )
        {
            var msg = @"Could not process test_alive command, got: $(err0.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }
        catch ( DBus.Error err1 )
        {
        }
    }
}
