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
using FsoGsm.Constants;

public class FsoGsm.GsmCallForwardingService : FreeSmartphone.GSM.CallForwarding, Service
{
    //
    // private
    //

    private BearerClass class_from_rule_name( string name ) throws FreeSmartphone.Error
    {
        switch ( name )
        {
            case "voice unconditional":
            case "voice busy":
            case "voice no reply":
            case "voice not reachable":
                return BearerClass.VOICE;
        }

        throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Invalid rule name: $name" );
    }

    private CallForwardingType reason_from_rule_name( string name ) throws FreeSmartphone.Error
    {
        switch ( name )
        {
            case "voice unconditional":
                return CallForwardingType.UNCONDITIONAL;
            case "voice busy":
                return CallForwardingType.BUSY;
            case "voice no reply":
                return CallForwardingType.NO_REPLY;
            case "voice not reachable":
                return CallForwardingType.NOT_REACHABLE;
        }

        throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Invalid rule name: $name" );
    }

    //
    // public API
    //

    //
    // DBUS (org.freesmartphone.GSM.CallForwarding.*)
    //

    public async void disable_all( string type ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        var real_type = CallForwardingType.ALL;

        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );

        switch ( type )
        {
            case "all":
                real_type = CallForwardingType.ALL;
                break;
            case "conditional":
                real_type = CallForwardingType.ALL_CONDITIONAL;
                break;
            default:
                throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Unknown type: $type" );
        }

        var m = theModem.createMediator<CallForwardingDisable>();
        yield m.run( BearerClass.DEFAULT, real_type );
    }

    public async void enable( string rule, string number, int timeout ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );

        var cls = class_from_rule_name( rule );
        var reason = reason_from_rule_name( rule );

        validatePhoneNumber( number );
        if ( timeout < 0 || timeout > 30 )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Timeout is not inside range of [0:30]" );

        var m =  theModem.createMediator<CallForwardingEnable>();
        yield m.run( cls, reason, number, timeout );

        var status = yield this.get_status( rule );
        this.status_changed( rule, status ); // DBUS SIGNAL
    }

    public async void disable( string rule ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        checkAvailability( FsoGsm.Modem.Status.ALIVE_REGISTERED );

        var cls = class_from_rule_name( rule );
        var reason = reason_from_rule_name( rule );

        var m =  theModem.createMediator<CallForwardingDisable>();
        yield m.run( cls, reason );

        var status = yield this.get_status( rule );
        this.status_changed( rule, status ); // DBUS SIGNAL
    }

    public async GLib.HashTable<string,Variant> get_status( string rule ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBusError, IOError
    {
        var cls = class_from_rule_name( rule );
        var reason = reason_from_rule_name( rule );

        var m = theModem.createMediator<CallForwardingQuery>();
        yield m.run( cls, reason );

        return m.status;
    }
}

// vim:ts=4:sw=4:expandtab
