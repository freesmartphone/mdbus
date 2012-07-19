/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using Gee;

/**
 * @class AtPhonebookHandler
 **/
public class FsoGsm.AtPhonebookHandler : FsoGsm.AbstractPhonebookHandler
{
    public override PhonebookStorage storage { get; set; }

    //
    // private
    //

    private void onModemStatusChanged( FsoGsm.Modem modem, FsoGsm.Modem.Status status )
    {
        switch ( status )
        {
            case Modem.Status.ALIVE_SIM_READY:
                simIsReady();
                break;
            default:
                break;
        }
    }

    private async void simIsReady()
    {
        yield syncWithSim();
    }

    private T[] copy<T>( T[] array )
    {
        T[] result = new T[] {};
        foreach ( T t in array )
        {
            result += t;
        }
        return result;
    }

    //
    // public API
    //

    public AtPhonebookHandler( FsoGsm.Modem modem )
    {
        base( modem );
        modem.signalStatusChanged.connect( onModemStatusChanged );
    }

    public override string repr()
    {
        return storage != null ? storage.repr() : "<None>";
    }

    public override async void syncWithSim()
    {
        if ( storage == null )
        {
            assert( logger.debug( @"No storage yet available; creating a new one ..." ) );

            var cimi = modem.createAtCommand<PlusCIMI>( "+CIMI" );
            var resp = yield modem.processAtCommandAsync( cimi, cimi.execute() );
            if ( cimi.validate( resp ) != Constants.AtResponse.VALID )
            {
                logger.warning( "Can't synchronize PB storage with SIM" );
                return;
            }

            storage = new PhonebookStorage( cimi.value );
        }

        storage.clean();

        // retrieve all known phonebooks
        var cmd = modem.createAtCommand<PlusCPBS>( "+CPBS" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.test() );
        if ( cmd.validateTest( response ) != Constants.AtResponse.VALID )
        {
            logger.warning( "Can't parse phonebook result" );
            return;
        }

        // NOTE: Work around a reentrancy issue by copying the phonebooks
        // FIXME: This has to be investigated in more detail!
        var phonebooks = copy<string>( cmd.phonebooks );

        foreach ( var pbcode in phonebooks )
        {
            var cpbr = modem.createAtCommand<PlusCPBR>( "+CPBR" );
            var answer = yield modem.processAtCommandAsync( cpbr, cpbr.test( pbcode ) );
            if ( cpbr.validateTest( answer ) == Constants.AtResponse.VALID )
            {
                assert( logger.debug( @"Found phonebook '$pbcode' w/ indices $(cpbr.min)-$(cpbr.max)" ) );
                response = yield modem.processAtCommandAsync( cpbr, cpbr.issue( pbcode, cpbr.min, cpbr.max ) );

                var valid = cpbr.validateMulti( response );
                if ( valid != Constants.AtResponse.VALID && valid != Constants.AtResponse.CME_ERROR_022_NOT_FOUND )
                {
                    logger.warning( @"Can't parse PB $pbcode" );
                    continue;
                }

                storage.addPhonebook( pbcode, cpbr.min, cpbr.max, cpbr.phonebook );
            }
        }
    }

}


