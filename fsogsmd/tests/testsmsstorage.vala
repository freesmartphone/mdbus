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

using GLib;
using FsoGsm;

//===========================================================================
void test_fso_sms_storage_new()
//===========================================================================
{
    var storage = SmsStorageFactory.create( "default", IMSI );
}

void test_fso_sms_storage_add_single()
{
    var storage = SmsStorageFactory.create( "default", IMSI );
    storage.clean();

    var sms = Sms.Message.newFromHexPdu( pdu3, pdulength3 );
    assert( sms != null );

    // new one
    assert( storage.addSms( sms ) == SmsStorage.SMS_SINGLE_COMPLETE );

    // this one we have already seen
    assert( storage.addSms( sms ) == SmsStorage.SMS_ALREADY_SEEN );
}

//===========================================================================
void test_fso_sms_storage_add_concatenated()
//===========================================================================
{
    var storage = SmsStorageFactory.create( "default", IMSI );
    storage.clean();

    var smses = new Sms.Message[pdulengths1.length] {};

    for( int i = 0; i < pdulengths1.length; ++i )
    {
        smses[i] = Sms.Message.newFromHexPdu( pdus1[i], pdulengths1[i] );
    }

    for( int i = 0; i < pdulengths1.length-1; ++i )
    {
        assert( storage.addSms( smses[i] ) == SmsStorage.SMS_MULTI_INCOMPLETE );
    }
    assert( storage.addSms( smses[pdulengths1.length-1] ) == pdulengths1.length );
}

//===========================================================================
void test_fso_sms_storage_store_transaction_index()
//===========================================================================
{
    var handler = new AtSmsHandler( new NullModem() );
    handler.storage = SmsStorageFactory.create( "default", IMSI );
    //handler.storage.clean();
    var pdus = handler.formatTextMessage( PHONE_NUMBER, LONG_TEXT, true );
    var i = 0;
    foreach ( var pdu in pdus )
    {
        pdu.transaction_index = ++i;
    }
    handler.storeTransactionIndizesForSentMessage( pdus );
}

//===========================================================================
void test_fso_sms_storage_confirm_ack()
//===========================================================================
{
    var handler = new AtSmsHandler( new NullModem() );
    handler.storage = SmsStorageFactory.create( "default", IMSI );
    //handler.storage.clean();
    assert( handler.storage.confirmReceivedMessage( 2 ) == -1 );
    assert( handler.storage.confirmReceivedMessage( 3 ) == -1 );
    assert( handler.storage.confirmReceivedMessage( 4 ) == -1 );
    assert( handler.storage.confirmReceivedMessage( 1 ) != -1 );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/Fso/Sms/Storage/New", test_fso_sms_storage_new );
    // Test.add_func( "/Fso/Sms/Storage/Existing", test_fso_sms_storage_new_existing );
    Test.add_func( "/Fso/Sms/Storage/Add/Single", test_fso_sms_storage_add_single );
    Test.add_func( "/Fso/Sms/Storage/Add/Concatenated", test_fso_sms_storage_add_concatenated );
    Test.add_func( "/Fso/Sms/Storage/StoreTransactionIndex", test_fso_sms_storage_store_transaction_index );
    Test.add_func( "/Fso/Sms/Storage/ConfirmReceivedMessage", test_fso_sms_storage_confirm_ack );

    Test.run();
}

// vim:ts=4:sw=4:expandtab
