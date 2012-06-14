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
 * Network Mediators
 **/
public class AtNetworkGetSignalStrength : NetworkGetSignalStrength
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCSQ>( "+CSQ" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.execute() );
        checkResponseValid( cmd, response );
        signal = cmd.signal;
    }
}

public class AtNetworkGetStatus : NetworkGetStatus
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
#if 0
        if ( modem.data().simIssuer == null )
        {
            var mediator = new AtSimGetInformation();
            yield mediator.run();
        }
#endif
        status = new GLib.HashTable<string,Variant>( str_hash, str_equal );
        Variant strvalue;
        Variant intvalue;

        status.insert( "registration", "unknown" );
        status.insert( "mode", "unknown" );
        status.insert( "act", "unknown" );

        // query field strength
        var csq = modem.createAtCommand<PlusCSQ>( "+CSQ" );
        var response = yield modem.processAtCommandAsync( csq, csq.execute() );
        if ( csq.validate( response ) == Constants.AtResponse.VALID )
        {
            intvalue = csq.signal;
            status.insert( "strength", intvalue );
        }
#if 0
        bool overrideProviderWithSimIssuer = false;
#endif
        // query telephony registration status and lac/cid
        var creg = modem.createAtCommand<PlusCREG>( "+CREG" );
        var cregResult = yield modem.processAtCommandAsync( creg, creg.query() );
        if ( creg.validate( cregResult ) == Constants.AtResponse.VALID )
        {
            strvalue = Constants.networkRegistrationStatusToString( creg.status );
            status.insert( "registration", strvalue );

#if 0
            overrideProviderWithSimIssuer = ( modem.data().simIssuer != null && creg.status == 1 /* home */ );
#endif

            if ( creg.lac != "" )
                status.insert( "lac", new Variant.string( creg.lac ) );

            if ( creg.cid != "" )
                status.insert( "cid", new Variant.string( creg.cid ) );
        }

        // query operator code
        var cops = modem.createAtCommand<PlusCOPS>( "+COPS" );
        var copsResult3 = yield modem.processAtCommandAsync( cops, cops.query( PlusCOPS.Format.NUMERIC ) );
        if ( cops.validate( copsResult3 ) == Constants.AtResponse.VALID )
        {
            strvalue = cops.oper;
            status.insert( "code", strvalue );
        }

        // query registration mode, operator name, access technology
        var copsResult = yield modem.processAtCommandAsync( cops, cops.query( PlusCOPS.Format.ALPHANUMERIC ) );
        if ( cops.validate( copsResult ) == Constants.AtResponse.VALID )
        {
            strvalue = Constants.networkRegistrationModeToString( cops.mode );
            status.insert( "mode", strvalue );
            strvalue = cops.oper;
            if ( strvalue != "" )
            {
                status.insert( "provider", strvalue );
                status.insert( "network", strvalue ); // base value
                status.insert( "display", strvalue ); // base value
            }
            strvalue = cops.act;
            status.insert( "act", strvalue );
        }
        else if ( cops.validate( copsResult ) == Constants.AtResponse.CME_ERROR_030_NO_NETWORK_SERVICE )
        {
            status.insert( "registration", "unregistered" );
        }

        // query operator display name
        var copsResult2 = yield modem.processAtCommandAsync( cops, cops.query( PlusCOPS.Format.ALPHANUMERIC_SHORT ) );
        if ( cops.validate( copsResult2 ) == Constants.AtResponse.VALID )
        {
            // only override default, if set
            if ( cops.oper != "" )
            {
                strvalue = cops.oper;
                status.insert( "display", strvalue );
                status.insert( "network", strvalue );
            }
        }

        // if we still don't have any valid value for the provider of the currently
        // connected network we're looking into our local database for it.
        if ( status.lookup( "provider" ) == null )
        {
            var code = status.lookup( "code" );
            if ( code != null )
            {
                var provider = yield findProviderNameForMccMnc( code.get_string() );
                status.insert( "provider", provider );
                status.insert( "display", provider );
                status.insert( "network", provider );
            }
        }

#if 0
        // check whether we want to override display name with SIM issuer
        if ( overrideProviderWithSimIssuer )
        {
            status.insert( "display", modem.data().simIssuer );
        }
#endif

        // query pdp registration status and lac/cid
        var cgreg = modem.createAtCommand<PlusCGREG>( "+CGREG" );
        var cgregResult = yield modem.processAtCommandAsync( cgreg, cgreg.query() );
        if ( cgreg.validate( cgregResult ) == Constants.AtResponse.VALID )
        {
            var cgregResult2 = yield modem.processAtCommandAsync( cgreg, cgreg.queryFull( cgreg.mode ) );
            if ( cgreg.validate( cgregResult2 ) == Constants.AtResponse.VALID )
            {
                strvalue = Constants.networkRegistrationStatusToString( cgreg.status );
                status.insert( "pdp.registration", strvalue );
                strvalue = cgreg.lac;
                status.insert( "pdp.lac", strvalue );
                strvalue = cgreg.cid;
                status.insert( "pdp.cid", strvalue );
            }
        }
    }
}

public class AtNetworkListProviders : NetworkListProviders
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCOPS>( "+COPS" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.test() );
        checkTestResponseValid( cmd, response );
        providers = cmd.providers;
    }
}

public class AtNetworkRegister : NetworkRegister
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCOPS>( "+COPS" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( PlusCOPS.Action.REGISTER_WITH_BEST_PROVIDER ) );
        checkResponseOk( cmd, response );
    }
}

public class AtNetworkUnregister : NetworkUnregister
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCOPS>( "+COPS" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( PlusCOPS.Action.UNREGISTER ) );
        checkResponseOk( cmd, response );
    }
}

public class AtNetworkSendUssdRequest : NetworkSendUssdRequest
{
    public override async void run( string request ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCUSD>( "+CUSD" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.query( request ) );
        checkResponseOk( cmd, response );
    }
}

public class AtNetworkGetCallingId : NetworkGetCallingId
{
    public override async void run() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCLIR>( "+CLIR" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.query() );
        checkResponseValid( cmd, response );
        status = (FreeSmartphone.GSM.CallingIdentificationStatus) cmd.value;
    }
}

public class AtNetworkSetCallingId : NetworkSetCallingId
{
    public override async void run( FreeSmartphone.GSM.CallingIdentificationStatus status ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var cmd = modem.createAtCommand<PlusCLIR>( "+CLIR" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( status ) );
        checkResponseOk( cmd, response );
    }
}

} // namespace FsoGsm

// vim:ts=4:sw=4:expandtab
