/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *               2012 Simon Busch <morphis@gravedo.de>
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

using FsoGsm.Constants;

public class FsoGsm.AtCallDriver : FsoGsm.ICallDriver, FsoFramework.AbstractObject
{
    private FsoGsm.Modem modem;

    //
    // public API
    //

    public AtCallDriver( FsoGsm.Modem modem )
    {
        this.modem = modem;
    }

    public async void dial( string number, string type ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<V250D>( "D" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( number, type == "voice" ) );
        checkResponseOk( cmd, response );
    }

    public async void activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<V250D>( "A" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.execute() );
        checkResponseOk( cmd, response );
    }

    public async void hold_all_active() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCHLD>( "+CHLD" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( PlusCHLD.Action.HOLD_ALL_AND_ACCEPT_WAITING_OR_HELD ) );
        checkResponseOk( cmd, response );
    }

    public async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCHLD>( "+CHLD" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( PlusCHLD.Action.DROP_SPECIFIC_AND_ACCEPT_WAITING_OR_HELD, id ) );
        checkResponseOk( cmd, response );
    }

    public async void release_all_held() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCHLD>( "+CHLD" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( (PlusCHLD.Action) 0 ) );
        checkResponseOk( cmd, response );
    }

    public async void release_all_active() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCHLD>( "+CHLD" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( (PlusCHLD.Action) 1 ) );
        checkResponseOk( cmd, response );
    }

    public async void create_conference() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCHLD>( "+CHLD" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( (PlusCHLD.Action) 3 ) );
        checkResponseOk( cmd, response );
    }

    public async void transfer() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCHLD>( "+CHLD" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( PlusCHLD.Action.DROP_SELF_AND_CONNECT_ACTIVE ) );
        checkResponseOk( cmd, response );
    }

    public async void deflect( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCTFR>( "+CTFR" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( number, determinePhoneNumberType( number ) ) );
        checkResponseOk( cmd, response );
    }

    public async void join() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCHLD>( "+CHLD" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( (PlusCHLD.Action) 4 ));
        checkResponseOk( cmd, response );
    }

    public async void cancel_outgoing_with_id( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        assert( logger.debug( @"Cancelling outgoing call with ID $id" ) );
        var cmd = modem.data().atCommandCancelOutgoing;
        if ( cmd != null )
        {
            var c1 = new CustomAtCommand();
            var r1 = yield modem.processAtCommandAsync( c1, cmd );
            checkResponseOk( c1, r1 );
        }
        else
        {
            var c2 = modem.createAtCommand<V250H>( "H" );
            var r2 = yield modem.processAtCommandAsync( c2, c2.execute() );
            checkResponseOk( c2, r2 );
        }
    }

    public async void reject_incoming_with_id( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        assert( logger.debug( @"Rejecting incoming call with ID $id" ) );
        var cmd = modem.data().atCommandRejectIncoming;
        if ( cmd != null )
        {
            var c1 = new CustomAtCommand();
            var r1 = yield modem.processAtCommandAsync( c1, cmd );
            checkResponseOk( c1, r1 );
        }
        else
        {
            var c2 = modem.createAtCommand<V250H>( "H" );
            var r2 = yield modem.processAtCommandAsync( c2, c2.execute() );
            checkResponseOk( c2, r2 );
        }
    }

    public override string repr()
    {
        return @"<>";
    }
}

// vim:ts=4:sw=4:expandtab
