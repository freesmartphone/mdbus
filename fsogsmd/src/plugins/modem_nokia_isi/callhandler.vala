/*
 * Copyright (C) 2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

/**
 * @class IsiCallHandler
 **/
public class FsoGsm.IsiCallHandler : FsoGsm.AbstractCallHandler
{
    public override string repr()
    {
        return "<>";
    }

    public override void handleIncomingCall( FsoGsm.CallInfo call_info )
    {
    }

    public override void handleConnectingCall( FsoGsm.CallInfo call_info )
    {
    }

    public override void handleEndingCall( FsoGsm.CallInfo call_info )
    {
    }

    public override void addSupplementaryInformation( string direction, string info )
    {
    }

    public override async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public override async int  initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        return 0;
    }

    public override async void hold() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public override async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public override async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    protected override async void cancelOutgoingWithId( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    protected override async void rejectIncomingWithId( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    protected override void startTimeoutIfNecessary()
    {
    }

}
