/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using Gee;

/**
 * @interface FsoGsm.CallHandler
 **/
public abstract interface FsoGsm.CallHandler : FsoFramework.AbstractObject
{
    public enum SingleCallState
    {
        RELEASED,
        OUTGOING,
        INCOMING,
        ACTIVE,
        HELD
    }

    public struct CallStatus
    {
        public CallHandler.SingleCallState first;
        public CallHandler.SingleCallState second;
    }

    public abstract async void initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    /*
    public abstract async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void hold( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void conference() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    public abstract async void join() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error;
    */
}

/**
 * @class FsoGsm.AbstractCallHandler
 **/
public abstract class FsoGsm.AbstractCallHandler : FsoGsm.Mediator, FsoGsm.CallHandler, FsoFramework.AbstractObject
{
    public CallHandler.CallStatus status;

    construct
    {
        status = CallHandler.CallStatus() { first=SingleCallState.RELEASED, second=SingleCallState.RELEASED };
    }

    public virtual async void initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
    }
    public virtual async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
    }
}

/**
 * @class FsoGsm.GenericAtCallHandler
 */
public class FsoGsm.GenericAtCallHandler : FsoGsm.AbstractCallHandler
{
    public override string repr()
    {
        return "<>";
    }

    public override async void initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var cmd = theModem.createAtCommand<V250D>( "D" );
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( number, ctype == "voice" ) );
    }

    public override async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var cmd = theModem.createAtCommand<V250H>( "H" );
        var response = yield theModem.processCommandAsync( cmd, cmd.execute() );
    }
    /*

    public override async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        var cmd = theModem.createAtCommand<V250D>( "D" );
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( number, ctype == "voice" ) );
    }
    */
}
