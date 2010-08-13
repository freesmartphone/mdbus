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

    private override string repr()
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
    
    private async FreeSmartphone.GSM.SIMEntry[] readPhonebook( Msmcomm.PhonebookType type, int slot_count, int slots_used )
    {
        FreeSmartphone.GSM.SIMEntry[] phonebook = new FreeSmartphone.GSM.SIMEntry[] { };
        var channel = theModem.channel( "main" ) as MsmChannel;
        
        // We read as much phonebook entries as we have stored in the phonebook. The
        // entries in the phonebook are always in the right order as the modem firmware
        // fills the gap between the entries already stored in the phonebook by itself.
        
        for ( var i = 0; i < slots_used; i++ )
        {
            var cmd = new Msmcomm.Command.ReadPhonebook();
            cmd.book_type = type;
            cmd.position = i;
            unowned Msmcomm.Reply.Phonebook response = 
                (Msmcomm.Reply.Phonebook) (yield channel.enqueueAsync( (owned) cmd ));
                
            if (response != null && response.result == Msmcomm.ResultType.OK)
            {
                var entry = new FreeSmartphone.GSM.SIMEntry( i, response.title, response.number );
                phonebook += entry;
            }
        }
        
        return phonebook;
    }

    public async void syncWithSim()
    {
        var channel = theModem.channel( "main" ) as MsmChannel;
        
        // gather IMSI
        var cmd1 = new Msmcomm.Command.SimInfo();
        cmd1.field_type = Msmcomm.SimInfoFieldType.IMSI;
        unowned Msmcomm.Reply.Sim simInfoResponse = (Msmcomm.Reply.Sim) (yield channel.enqueueAsync( (owned)cmd1 ));
        
        if ( simInfoResponse == null || 
             simInfoResponse.result != Msmcomm.ResultType.OK || 
             simInfoResponse.field_data == null)
        {
            logger.warning( "Can't synchronize PB storage with SIM" );
            return;
        }
        
        // create Storage for current IMSI
        storage = new FsoGsm.PhonebookStorage( simInfoResponse.field_data );
        
        // FIXME we can't retrieve phonebooks, so we have to build a 
        // static list of available phonebooks
        string[] phonebooks = { "fixed", "abbreviated" };
        
        foreach ( var pbcode in phonebooks )
        {
            Msmcomm.PhonebookType phonebookType = Msmcomm.simPhonebookStringToPhonebookType( pbcode );
            
            var cmd = new Msmcomm.Command.GetPhonebookProperties();
            cmd.book_type = phonebookType;
            
            unowned Msmcomm.Reply.GetPhonebookProperties response = 
                (Msmcomm.Reply.GetPhonebookProperties) (yield channel.enqueueAsync( (owned) cmd ));
                
            if ( response == null ||
                 response.result != Msmcomm.ResultType.OK )
            {
                // FIXME what about the min index?
                assert( logger.debug( @"Found  phonebook '$pbcode' w/ indices 0-$(response.slot_count)" ) );
                var phonebook = yield readPhonebook( phonebookType, response.slot_count, response.slots_used );
                storage.addPhonebook( pbcode, 0, response.slot_count, phonebook );
            }
            else
            {
                assert( logger.debug( @"Can't parse PB $pbcode" ) );
            }
        }
    }
}
    
