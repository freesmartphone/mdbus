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

    public async void syncPhonebook( PhonebookBookType book_type ) throws FreeSmartphone.Error
    {
        PhonebookInfo info = PhonebookInfo();
        var channel = theModem.channel( "main" ) as MsmChannel;

        try
        {
            info = yield channel.phonebook_service.get_extended_file_info( book_type );
        }
        catch ( GLib.Error err )
        {
            var msg = @"Could not process get_extended_file_info command, got: $(err.message)";
            throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
        }

        assert( logger.debug( @"Got phonebook properties from modem: book_type = $(info.book_type) slot_count = $(info.slot_count), slots_used = $(info.slots_used)" ) );

#if 0
        // Wait some seconds before modem can process next commands (FIXME this should be
        // fixed in msmcommd)
        Posix.sleep(2);
#endif

        if ( info.slots_used > 0 )
        {
            FreeSmartphone.GSM.SIMEntry[] phonebook = new FreeSmartphone.GSM.SIMEntry[] { };
            var count = 0;
            for ( var position = 1; position < info.slot_count; position++ )
            {
                logger.debug( @"Trying to read record at position $(position); We already have $(count) record of $(info.slots_used)" );

                try
                {
                    // Try to read a phonebook entry from current position
                    var record = yield channel.phonebook_service.read_record( book_type, position );
                    logger.debug( @"Got phonebook entry at position $(position)" );
                    var entry = FreeSmartphone.GSM.SIMEntry( position, record.title, record.number );
                    phonebook += entry;
                    count++;
                }
                catch ( Msmcomm.Error err0 )
                {
                    // If we get an exception here there is no entry at this position. We
                    // ignore this an try again at the next position.
                }
                catch ( GLib.Error err1 )
                {
                    throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Could not read record from SIM card due to a internal error: $(err1.message)" );
                }

                // We have already found all phonebook entries?
                if ( count == info.slots_used )
                {
                    break;
                }
            }

            if ( count != info.slots_used )
            {
                logger.debug( @"Could not retrieve all records for phonebook $(bookTypeToCategory(book_type)) from SIM!" );
            }
            else
            {
                logger.debug( @"Retrieved all phonebook entries for book $(bookTypeToCategory(book_type))!" );
            }

            storage.addPhonebook( bookTypeToCategory( book_type ), 0, (int) info.slot_count, phonebook );
        }
    }

    public async void initializeStorage()
    {
        try
        {
            var channel = theModem.channel( "main" ) as MsmChannel;

            // Fetch and check imsi from sim
            var fi = yield channel.sim_service.read_field( SimFieldType.IMSI );
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

// vim:ts=4:sw=4:expandtab
