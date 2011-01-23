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

public class MsmPhonebookHandler : FsoGsm.PhonebookHandler, FsoFramework.AbstractObject
{
    public FsoGsm.PhonebookStorage storage { get; set; }

    public MsmPhonebookHandler()
    {
        assert( theModem != null ); // Can't create PB handler before modem
    }

    public override string repr()
    {
        return storage != null ? storage.repr() : "<None>";
    }

    private async void retrievePhonebookProperties( PhonebookBookType book_type )
    {
        try
        {
            var channel = theModem.channel( "main" ) as MsmChannel;
            yield channel.phonebook_service.extended_file_info( book_type );
        }
        catch ( Msmcomm.Error err0 )
        {
        }
        catch ( GLib.Error err1 )
        {
        }
    }

    public async void syncPhonebook( PhonebookBookType book_type )
    {
        var channel = theModem.channel( "main" ) as MsmChannel;

        // Retrieve phonebook properties but don't care about the result; Will timeout
        // as we get the correct result with an unsolicited response.
        Idle.add( () => { retrievePhonebookProperties( book_type ); return false; });

        var info = (yield channel.urc_handler.waitForUnsolicitedResponse( MsmUrcType.EXTENDED_FILE_INFO )) as PhonebookInfo;
        assert( logger.debug( @"Got the phonebook properties from modem: book_type = $(info.book_type) slot_count = $(info.slot_count), slots_used = $(info.slots_used)" ) );

        var position = 1;
        FreeSmartphone.GSM.SIMEntry[] phonebook = new FreeSmartphone.GSM.SIMEntry[] { };
        for ( var n = 0; n < info.slots_used; n++ )
        {
            // Try to read entry from phonebook as long as we have records left
            for ( var m = position; m < info.slot_count; m++, position++ )
            {
                try
                {
                    var record = yield channel.phonebook_service.read_record( book_type, m );

                    var entry = FreeSmartphone.GSM.SIMEntry( position, record.title, record.number );
                    phonebook += entry;

                    position++;
                    break;
                }
                catch ( Msmcomm.Error err0 )
                {
                }
                catch ( GLib.Error err1 )
                {
                }
            }
        }

        if ( phonebook.length != info.slots_used )
        {
            logger.debug( @"Could not retrieve all records for phonebook $(bookTypeToCategory(book_type)) from SIM!" );
        }
        else
        {
            logger.debug( @"Retrieved all phonebook entries for book $(bookTypeToCategory(book_type))!" );
        }

        storage.addPhonebook( bookTypeToCategory( book_type ), 0, (int) info.slot_count, phonebook );
    }

    public async void initializeStorage()
    {
        try
        {
            var channel = theModem.channel( "main" ) as MsmChannel;

            // Fetch and check imsi from sim
            var fi = yield channel.sim_service.read( SimFieldType.IMSI );
            string imsi = fi.data;
            if ( imsi.length == 0 )
            {
                logger.warning( "Can't retrieve imsi from SIM for identifying the correct phonebook storage" );
                return;
            }

            // create Storage for current IMSI and clean it up
            storage = new FsoGsm.PhonebookStorage( imsi );
            storage.clean();
        }
        catch ( Msmcomm.Error err0 )
        {
        }
        catch ( GLib.Error err1 )
        {
        }
    }
}
