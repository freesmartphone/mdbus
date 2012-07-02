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
using FsoGsm.Constants;
using FsoFramework.StringHandling;

namespace FsoGsm {

/**
 * Call Mediators
 **/
public class AtCallActivate : CallActivate
{
    public override async void run( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield theModem.callhandler.activate( id );
    }
}

public class AtCallHoldActive : CallHoldActive
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield theModem.callhandler.hold();
    }
}

public class AtCallInitiate : CallInitiate
{
    public override async void run( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        validatePhoneNumber( number );
        id = yield theModem.callhandler.initiate( number, ctype );
    }
}

public class AtCallListCalls : CallListCalls
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCLCC>( "+CLCC" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.execute() );
        checkMultiResponseValid( cmd, response );
        calls = cmd.calls;
    }
}

public class AtCallSendDtmf : CallSendDtmf
{
    public override async void run( string tones ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusVTS>( "+VTS" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( tones ) );
        checkResponseOk( cmd, response );
    }
}

public class AtCallRelease : CallRelease
{
    public override async void run( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield theModem.callhandler.release( id );
    }
}

public class AtCallReleaseAll : CallReleaseAll
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield theModem.callhandler.releaseAll();
    }
}

public class AtCallTransfer : FsoGsm.CallTransfer
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield theModem.callhandler.transfer();
    }
}

public class AtCallDeflect : FsoGsm.CallDeflect
{
    public override async void run( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        yield theModem.callhandler.deflect( number );
    }
}

public class AtCallForwardingEnable : FsoGsm.CallForwardingEnable
{
    public override async void run( BearerClass cls, CallForwardingType reason, string number, int timeout ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCCFC>( "+CCFC" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue_ext( CallForwardingMode.REGISTRATION, reason, cls, number, timeout ) );
        checkResponseOk( cmd, response );
    }
}

public class AtCallForwardingDisable : FsoGsm.CallForwardingDisable
{
    public override async void run( BearerClass cls, CallForwardingType reason ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = theModem.createAtCommand<PlusCCFC>( "+CCFC" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( CallForwardingMode.ERASURE, reason, cls ) );
        checkResponseOk( cmd, response );
    }
}

public class AtCallForwardingQuery : FsoGsm.CallForwardingQuery
{
    public override async void run( BearerClass cls, CallForwardingType reason ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        status = new GLib.HashTable<string,Variant>( null, null );

        var cmd = theModem.createAtCommand<PlusCCFC>( "+CCFC" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.query( reason, cls ) );
        checkResponseValid( cmd, response );

        status.insert( "active", cmd.active );
        status.insert( "number", cmd.number );
        if ( cls == BearerClass.VOICE && reason == CallForwardingType.NO_REPLY )
            status.insert( "timeout", cmd.timeout );
    }
}

public class AtCallActivateConference : FsoGsm.CallActivateConference
{
    public override async void run( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        theModem.callhandler.conference( id );
    }
}

public class AtCallJoin : FsoGsm.CallJoin
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        theModem.callhandler.join();
    }
}

} // namespace FsoGsm

// vim:ts=4:sw=4:expandtab
