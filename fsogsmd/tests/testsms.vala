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

using GLib;
using FsoGsm;

//===========================================================================
void test_sms_decode_deliver_single_default_alphabet()
//===========================================================================
{
    Sms.Message sms = Sms.Message.newFromHexPdu( "0791947106004034040D91947146093052F20000900192608270401EC8B7D95C76D3D9E9311A444E97E7ED301BD44ED341C1E1124AAC02", 47 );

    assert( sms.type == Sms.Type.DELIVER );
    assert( sms.sc_addr.to_string() == "+491760000443" );
    assert( sms.number() == "+4917649003252" );
    assert( sms.deliver.scts.year      == 9 );
    assert( sms.deliver.scts.month     == 10 );
    assert( sms.deliver.scts.day       == 29 );
    assert( sms.deliver.scts.hour      == 6 );
    assert( sms.deliver.scts.minute    == 28 );
    assert( sms.deliver.scts.second    == 7 );
    assert( sms.deliver.scts.timezone  == +4 );
    assert( sms.to_string() == "Hoffentlich diesmal mit ACKPDU" );

    bool udhi;
    uint8 dcs;
    uint8 max;

    var ud = sms.extract_common( out udhi, out dcs, out max );
    assert( ud != null );
    assert( ud.length == 30 );
    assert( dcs == 0 );
    assert( max == 140 );
    assert( !udhi );
}

//===========================================================================
void test_sms_decode_deliver_single_concatenated_default_alphabet()
//===========================================================================
{
    Sms.Message sms = Sms.Message.newFromHexPdu( "0791947101670000440C91947120270030000090010321614440A0050003040B02C6683A885C978FD1A034DA0D4297E5E1FADC9C7693CB6ED09AEF7697DD2CD0BCCC16CFE9A07BD9ED06CDD365505A7E2EBBC9F7B0DB0D9A97D36E50B41E96D3D36539A82C37BFD96779393D4683EC65F93DECD6D341E83D9D5E76BB14CCB79BFC06A1C3747A19242D8FD1741039DC4ED3592072D803B2A6E520F77B8C06B9D363341D242ECBCB", 159 );

    assert( sms.type == Sms.Type.DELIVER );
    assert( sms.sc_addr.to_string() == "+491710760000" );
    assert( sms.number() == "+491702720003" );
    assert( sms.deliver.scts.year      == 9 );
    assert( sms.deliver.scts.month     == 10 );
    assert( sms.deliver.scts.day       == 30 );
    assert( sms.deliver.scts.hour      == 12 );
    assert( sms.deliver.scts.minute    == 16 );
    assert( sms.deliver.scts.second    == 44 );
    assert( sms.deliver.scts.timezone  == +4 );

    bool udhi;
    uint8 dcs;
    uint8 max;
    var ud = sms.extract_common( out udhi, out dcs, out max );

    assert( ud != null );
    assert( ud.length == 160 );
    assert( dcs == 0 );
    assert( max == 140 );
    assert( udhi );

    uint16 ref_num;
    uint8 max_msgs;
    uint8 seq_num;

    assert( sms.extract_concatenation( out ref_num, out max_msgs, out seq_num ) );
    assert( ref_num == 4 );
    assert( max_msgs == 11 );
    assert( seq_num == 2 );

    /*
    uint dst;
    uint src;
    bool is_8bit;
    assert( !sms.extract_app_port( out dst, out src, out is_8bit ) );
    assert( dst == 0 );
    assert( src == 0 );
    assert( !is_8bit );
    */
}

//===========================================================================
void test_sms_decode_deliver_multiple_concatenated_default_alphabet()
//===========================================================================
{
    for( int i = 0; i < pdulengths1.length; ++i )
    {
        var sms = Sms.Message.newFromHexPdu( pdus1[i], pdulengths1[i] );
        uint16 ref_num;
        uint8 max_msgs;
        uint8 seq_num;
        assert( sms.extract_concatenation( out ref_num, out max_msgs, out seq_num ) );
        assert( ref_num == 4 );
        assert( max_msgs == 11 );
        assert( seq_num == i+1 );
    }
}

//===========================================================================
void test_sms_decode_deliver_whole_concatenated_default_alphabet()
//===========================================================================
{
    var smses = new Sms.Message[pdulengths1.length] {};

    for( int i = 0; i < pdulengths1.length; ++i )
    {
        smses[i] = Sms.Message.newFromHexPdu( pdus1[i], pdulengths1[i] );
    }

    var smslist = new SList<weak Sms.Message>();
    for( int i = 0; i < pdulengths1.length; ++i )
    {
        smslist.append( smses[i] );
    }

    var text = Sms.decode_text( smslist );
    assert( text.length == 1562 );
    assert( text.has_prefix( "Wie haben die Drazi von der Beteiligung der Centauri erfahren?" ) );
    assert( text.has_suffix( "zwischen Delenn und Lennier angedeutet zu werden." ) );
}

//===========================================================================
void test_sms_decode_deliver_incoming_mms_control_message()
//===========================================================================
{
    var sms = Sms.Message.newFromHexPdu( pdu5, pdulength5 );

    int dst;
    int src;
    bool is8bit;

    var has_app_port = sms.extract_app_port( out dst, out src, out is8bit );

    assert( has_app_port );
    assert( dst == 2948 );
    assert( src == 9200 );
    assert( !is8bit );

    string contents = "";
    uint8* ud = sms.deliver.ud;
    for ( var i = 0; i < sms.deliver.udl; ++i )
    {
        contents += "%c".printf( ud[i] );
    }
    debug( @"content = $contents" );

    assert( false );
}

//===========================================================================
void test_sms_decode_status_report()
//===========================================================================
{
    var sms = Sms.Message.newFromHexPdu( pdu4, pdulength4 );

    var number = sms.number();
    var reference = sms.status_report.mr;
    var status = sms.status_report.st;

    debug( @"sms report addr: $number" );
    debug( @"sms report ref: $reference" );
    debug( @"sms report status: $status" );
    debug( @"sms report text: $sms" );
}

//===========================================================================
void test_sms_encode_submit_single_default_alphabet()
//===========================================================================
{
    int offset;
    smslist = Sms.text_prepare( SHORT_TEXT, 0, true, out offset );
    assert( smslist.length() == 1 );
    unowned Sms.Message sms = (Sms.Message)smslist.nth_data( 0 );
    assert( sms.type == Sms.Type.SUBMIT );
    assert( sms.to_string() == SHORT_TEXT );

    bool udhi;
    uint8 dcs;
    uint8 max;

    var ud = sms.extract_common( out udhi, out dcs, out max );
    assert( ud != null );
    assert( ud.length == SHORT_TEXT.length );
    assert( dcs == 0 );
    assert( max == 140 );
    assert( !udhi );
}

//===========================================================================
void test_sms_encode_submit_concatenated_default_alphabet()
//===========================================================================
{
    SmsHandler handler = new AtSmsHandler( null );
    var pdu = handler.formatTextMessage( PHONE_NUMBER, LONG_TEXT, false );
    assert( pdu.size == 4 );

    assert( pdu[0].hexpdu == LONG_TEXT_PDUS[0] );
    assert( pdu[0].tpdulen == LONG_TEXT_PDULENS[0] );
    assert( pdu[1].hexpdu == LONG_TEXT_PDUS[1] );
    assert( pdu[1].tpdulen == LONG_TEXT_PDULENS[1] );
    assert( pdu[2].hexpdu == LONG_TEXT_PDUS[2] );
    assert( pdu[2].tpdulen == LONG_TEXT_PDULENS[2] );
    assert( pdu[3].hexpdu == LONG_TEXT_PDUS[3] );
    assert( pdu[3].tpdulen == LONG_TEXT_PDULENS[3] );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/3rdparty/Sms/Decode/Deliver/Single/DefaultAlphabet", test_sms_decode_deliver_single_default_alphabet );
    Test.add_func( "/3rdparty/Sms/Decode/Deliver/Single/Concatenated/DefaultAlphabet", test_sms_decode_deliver_single_concatenated_default_alphabet );
    Test.add_func( "/3rdparty/Sms/Decode/Deliver/Multiple/Concatenated/DefaultAlphabet", test_sms_decode_deliver_multiple_concatenated_default_alphabet );
    // Test.add_func( "/3rdparty/Sms/Decode/Deliver/Whole/Concatenated/DefaultAlphabet", test_sms_decode_deliver_whole_concatenated_default_alphabet );
    // Test.add_func( "/3rdparty/Sms/Decode/Deliver/IncomingMmsControlMessage", test_sms_decode_deliver_incoming_mms_control_message );
    Test.add_func( "/3rdparty/Sms/Decode/StatusReport", test_sms_decode_status_report );

    Test.add_func( "/3rdparty/Sms/Encode/Submit/Single/DefaultAlphabet", test_sms_encode_submit_single_default_alphabet );
    // Test.add_func( "/3rdparty/Sms/Encode/Submit/Concatenated/DefaultAlphabet", test_sms_encode_submit_concatenated_default_alphabet );

    Test.run();
}

// vim:ts=4:sw=4:expandtab
