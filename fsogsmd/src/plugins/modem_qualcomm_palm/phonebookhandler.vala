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
    
    private async FreeSmartphone.GSM.SIMEntry[] readPhonebook( Msmcomm.PhonebookBookType book_type, int slot_count, int slots_used )
    {
        FreeSmartphone.GSM.SIMEntry[] phonebook = new FreeSmartphone.GSM.SIMEntry[] { };
        var cmds = MsmModemAgent.instance().commands;
        
        // We read as much phonebook entries as we have stored in the phonebook. The
        // entries in the phonebook are always in the right order as the modem firmware
        // fills the gap between the entries already stored in the phonebook by itself.
        
        for ( var i = 0; i < slots_used; i++ )
        {
            try 
            {
                var phonebookEntry = yield cmds.read_phonebook( book_type, i );
                var entry = FreeSmartphone.GSM.SIMEntry( i, phonebookEntry.title, phonebookEntry.number );
                phonebook += entry;
            }
            catch ( DBus.Error err0 )
            {
            }
            catch ( Msmcomm.Error err1 )
            {
            }

        }
        
        return phonebook;
    }

    public async void syncWithSim()
    {
        var cmds = MsmModemAgent.instance().commands;
    
        // gather IMSI
        string imsi = "";
        try 
        {
            imsi = yield cmds.sim_info( "imsi" );
        }
        catch ( DBus.Error err0 )
        {
        }
        catch ( Msmcomm.Error err1 )
        {
        }
        
        if ( imsi.length == 0 )
        {
            logger.warning( "Can't synchronize PB storage with SIM" );
            return;
        }
        
        // create Storage for current IMSI
        storage = new FsoGsm.PhonebookStorage( imsi );
        
        // FIXME we can't retrieve phonebooks, so we have to build a 
        // static list of available phonebooks
        Msmcomm.PhonebookBookType[] phonebooks = { Msmcomm.PhonebookBookType.FDN, 
                                                   Msmcomm.PhonebookBookType.ADN,
                                                   Msmcomm.PhonebookBookType.SDN };

        foreach ( var pb in phonebooks )
        {
            try 
            {
                var pbprops = yield cmds.get_phonebook_properties( pb );
                
                // assert( logger.debug( @"Found  phonebook '$(Msmcomm.phonebookBookTypeToString(pb))' w/ indices 0-$(pbprops.slot_count)" ) );

                var phonebook = yield readPhonebook( pb, pbprops.slot_count, pbprops.slots_used );
                storage.addPhonebook( Msmcomm.phonebookBookTypeToString(pb), 0, pbprops.slot_count, phonebook );
            }
            catch ( DBus.Error err2 )
            {
            }
            catch ( Msmcomm.Error err3 )
            {
            }
        }
    }
}
    
