/*
 * Copyright (C) 2010-2011 Simon Busch <morphis@gravedo.de>
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
using Msmcomm;

// FIXME merge general code to base class PhonebookHandler and use it 
// together with the AtPhonebookHandler
public class MsmPhonebookHandler : FsoGsm.PhonebookHandler, FsoFramework.AbstractObject
{
    public FsoGsm.PhonebookStorage storage { get; set; }

    public MsmPhonebookHandler()
    {
        assert( theModem != null ); // Can't create PB handler before modem
        theModem.signalStatusChanged.connect( onModemStatusChanged );
    }

    public override string repr()
    {
        return storage != null ? storage.repr() : "<None>";
    }

    public void onModemStatusChanged( FsoGsm.Modem modem, FsoGsm.Modem.Status status )
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

    public async void simIsReady()
    {
        yield syncWithSim();
    }

    public T[] copy<T>( T[] array )
    {
        T[] result = new T[] {};
        foreach ( T t in array )
        {
            result += t;
        }
        return result;
    }

    private async FreeSmartphone.GSM.SIMEntry[] readPhonebook( uint book_type, int slot_count, int slots_used )
    {
        FreeSmartphone.GSM.SIMEntry[] phonebook = new FreeSmartphone.GSM.SIMEntry[] { };
        var channel = theModem.channel( "main" ) as MsmChannel;

        // We read as much phonebook entries as we have stored in the phonebook. The
        // entries in the phonebook are always in the right order as the modem firmware
        // fills the gap between the entries already stored in the phonebook by itself.

        for ( var i = 0; i < slots_used; i++ )
        {
            try 
            {
                var phonebookEntry = yield channel.phonebook_service.read_record( book_type, i );
                var entry = FreeSmartphone.GSM.SIMEntry( i, phonebookEntry.title, phonebookEntry.number );
                phonebook += entry;
            }
            catch ( Msmcomm.Error err0 )
            {
            }
            catch ( GLib.Error err1 )
            {
            }

        }

        return phonebook;
    }

    public async void syncWithSim()
    {
        try
        {
            var channel = theModem.channel( "main" ) as MsmChannel;

            // Fetch and check imsi from sim
            var fi = yield channel.sim_service.read( SimFieldType.IMSI );
            string imsi = fi.data;
            if ( imsi.length == 0 )
            {
                logger.warning( "Can't synchronize PB storage with SIM" );
                return;
            }

            // create Storage for current IMSI
            storage = new FsoGsm.PhonebookStorage( imsi );

            // FIXME we can't retrieve phonebooks, so we have to build a 
            // static list of available phonebooks
#if 0
            Msmcomm.PhonebookBookType[] phonebooks = { Msmcomm.PhonebookBookType.FDN, 
                                                    Msmcomm.PhonebookBookType.ADN,
                                                    Msmcomm.PhonebookBookType.SDN };

            foreach ( var pb in phonebooks )
            {
                var pbprops = yield channel.phonebook_service.get_phonebook_properties( pb );

                assert( logger.debug( @"Found  phonebook '$(Msmcomm.phonebookBookTypeToString(pb))' w/ indices 0-$(pbprops.slot_count)" ) );

                var phonebook = yield readPhonebook( pb, pbprops.slot_count, pbprops.slots_used );
                storage.addPhonebook( Msmcomm.phonebookBookTypeToString(pb), 0, pbprops.slot_count, phonebook );
            }
#endif
        }
        catch ( Msmcomm.Error err0 )
        {
        }
        catch ( GLib.Error err1 )
        {
        }
    }
}
