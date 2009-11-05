/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using GLib;
using FsoGsm;

public const string IMSI = "26203123456789";
public const string LONG_TEXT = """freesmartphone.org is a collaboration platform for open source and open discussion software projects working on interoperability and shared technology for Linux-based SmartPhones. freesmartphone.org works on a service layer (middleware) that allows developers to concentrate on their application business logic rather than dealing with device specifics. freesmartphone.org honours and bases on specifications and software created by the freedesktop.org community.""";
public const uint16 LONG_TEXT_REF = 1;
public const string LONG_TEXT_PDUS[] = {
    "0051000B919421436587F90000A7A0060804000104016679B93C6F87E57438FAED2EBBDEF233283D078541E3379B1D16BFE5617AFAED06C1D961BAF92D6F83CC6F39E80D2FBB41F3775D3E2E83C26E32E80D2FBB41E4F47C5C9FCFD36F3768FE36D3EF6179190497BFD5E5317D0EBABFE5EBB4FB0C7ABB416937BD2C7FC3CBF2B038CD4ED3F3A0B09B0C9AA3C3F23219442F8FD1EE37FB7DCE83CC000000000000000000000000000000000000000000",
    "0051000B919421436587F90000A7A0060804000104026F39889976D7F12D71785E2683A6EDB09C0E45BFDDE5B90B649697CBF376584E87A3DFEEB2EB2D3F83EE6FF97A0E7ABB4161D0BC2CB7A7C765103B9C2FCB41A8769A4C6697EF61793905A2A3C3745098CD7EDFE72072D95E66BFE165F91C447F83C66FF7B8ECA6CBC3F432E8ED06D1D1E5B41C1486C3D9E971989E7EBB41E2FA3CED2ECFE7000000000000000000000000000000000000000000",
    "0051000B919421436587F90000A7A00608040001040320F6FB9C1E83E4613ABA2C07D1D16137885C0EB3D3EE33E89EA6A341E4B23D3D2E83E6F0F2386D4E8FE72E90595E2ECFDB61391D8E7EBBCBAEB7FC0C42BFDDEFBA7C0E0ABBC92071785E9E83DE6ED01C5E1EA7CDE971989E7EBBE7A0B09B0C9ABFCDF47B585E068DE5E530BD4C0689F3203ABA0C32CBCB657279BEA6BFE1AEB7FC0C1ABFDB000000000000000000000000000000000000000000",
    "0051000B919421436587F90000A70F06080400010404EDBA3B4DCFBB00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
    };
public const int LONG_TEXT_PDULENS[] = { 154, 154, 154, 28 };

public const string SHORT_TEXT = "Hoffentlich diesmal mit ACKPDU";
public const string PHONE_NUMBER = "+49123456789";

public const int pdulengths1[] = { 159, 159, 159, 159, 159, 159, 159, 159, 159, 159, 54 };

public const string pdus1[] = {

        "0791947101670000440C91947120270030000090010321610440A0050003040B01AEE932081D1697DD2072BA0C22CAC3FA34C8FE7683C865394858A697D3ECF4B9EE3E83C86539685876D3C375791A54969BC36879D9FD033DC96539081D1697DDA079BA0C2AA7DDE6F0180D72D7E5A0739D0E3A97E5617AD9FD0311C320E6DB4D7E83DCE9319A0EBA97D31E16E81E9E83D8EF39283DA7B340E83D9D5E7683E6E932A83C07B9D3",

        "0791947101670000440C91947120270030000090010321614440A0050003040B02C6683A885C978FD1A034DA0D4297E5E1FADC9C7693CB6ED09AEF7697DD2CD0BCCC16CFE9A07BD9ED06CDD365505A7E2EBBC9F7B0DB0D9A97D36E50B41E96D3D36539A82C37BFD96779393D4683EC65F93DECD6D341E83D9D5E76BB14CCB79BFC06A1C3747A19242D8FD1741039DC4ED3592072D803B2A6E520F77B8C06B9D363341D242ECBCB",

        "0791947101670000440C91947120270030000090010321618440A0050003040B03D27490D92F0791C37350B04D0791CB7390F04D9F8FD16133BD2C9F83D273BA0E644DCB41F7B49C0CB2BFDD2072D90D0ABBC96579D90DB2F2D9EBB2DC0D0AB3E7A0F9187D0F8FD1A0BA9B0CAABBE9E1FA999D1EA34161F7B93C2FA3CB6E16E89E2E83CA7310B92C0711E5617DBA85DCBBC9ECB21CA42FA7CF7417E829BEBFD16C10F3ED26BFE7",

        "0791947101670000440C91947120270030000090010321611540A0050003040B0440C272BB2C5FD7DD67D0B97C2EBBFDE2B21CA40D8FD7207BBACC6697D363341DA4AFB741D4729A0D2AA7DDA0E9185D96EB41F7B09C055AF3DD6E7A19544EBBCBA035BB9C769741CBB7DB2C7FBBE9617AFAED06D9DF6E379F5E7683E6E5B49B052287DB693AC89A9683CA72F79C0E3A97DDF533E85C76BFDBEDB21B744FCBC9A07A1B544EBB41",

        "0791947101670000440C91947120270030000090010321615540A0050003040B05CA6673794D4FDBCB7290F04D9F8FD16133BD2C07E9EBA07939ED76298EA765580E1297DD75BA9E0E22A7CBA0A03BCC7E9FD3655039ED2ECF41CCF4184D2FCF592072780E0AD7CDA072DA5D065DC36E32683E4697D36E3A0B546F83F47590B83C1FA3E5E5B4B8EC6681EEE932889C2E8398E53ABD0C3ABEE974D03D8C96BBCBE876D9ED0231CB",

        "0791947101670000440C91947120270030000090010321619540A0050003040B06DCEE74590E4287E9A0B41B2422A6CBA0E9182D4F9BE9A0707D0E12B2EB7411A89C7697417BB49B9D1EA3CBA0A03BCC7E9FD36590B8ECAED3F5741628CC9E83CA7210395D0605DDF3F4184D0791CB725033ED1687E569905F5C968384F23AB92C0715C9F7B09C3C074DCB657619242ECFC76879BA2C76299865B73B5D9683EE61B99B5E0619D3",

        "0791947101670000440C91947120270030000090010321713040A0050003040B07DCE4329B0D2287ED6F390B442EBB4141373B7C9AA3DF6B50B83E0791CB6E9039CC9E8FD16537E828F7BBC96537485C4EEBEB7479995E76835AA0B0B82C0795D3E7B29BCE4E8FD1A0F49C0E2ACF41E7B23B5C0791C37316E81E9E839865B73B5D9683E665B6784E079DCBF4B01B840ED359207218549E83CA6977790E9A97D3EEB21CA44D97D9",

        "0791947101670000440C91947120270030000090010321717040A0050003040B08CAA0F49CCE0211CBECB2DB0DD2D741E27239ED26CBEBE375D90D4295E5A079F84C2F83CAF47B780E2297E561393D7D2ECF41693748147483C86539683A46DFCB6C7619442ECF41D437B93C17A55C2062589E7683D67CB79B5E0691CB72D0748C66FBE7F3321BA4AF83E6E5B4BBDC06B5F967767A8C2EBB41D6B25C1EA683C26E10B9EC0649C3",

        "0791947101670000440C91947120270030000090010321711140A0050003040B09DCE7B27C0E62A7CBE7B29B052297DDA0E65B4E2EBB41F6B71C5D96CFC3677A19841211CB7210357C0691CB7210F54D2FBB452917E85A76BB416539C8FE9683C86539E81A46B341737A194D6781886576D9ED0691D3F2F29A0E7A93CB7210B9EC0605DDECF0698E7EAF41FA3A889C2EBBCB6E1668CD77BBE96550590E9A97D172D0FD8D6683C8",

        "0791947101670000440C91947120270030000090010321714140A0050003040B0AC27350593EA797E565D07D8F6697DD2C90B83C7FBBC965F91C742FBBDD2072BA0CBA86D16C5039ED2E83CA72F79C8E0E9BE96590B04C96BFD175F71964F6CB41C432BBEC7683C4E5B41B1D66D3CB7417A898769741F3377B8C2E839AFC333B3D46AFCB693A683E4697D36E3A28DD061DCB73B87C3F4683F4F7F47C8C2EBB41C432BBEC7683EA",

        "0791947101670000440C9194712027003000009001032171714027050003040B0BDC6410B3EC76A7CB7250D87D2E93CB757A990ED2D741F7B29C5C76BB00"
};

public const int pdulengths2[] = { 159, 54 };

public const string pdus2[] = {

    "0791947101670000440C91947120270030000090010351645540A0050003050201A665B9BD3E6781C8E9F21C949ED341E5B41B740EBBF520F29BCD2ECB4165FA3D3C07B1F7EE73595E9683A8653C1DD402A1DF6673D94D67A7C768500C346D4E4173B8BCEC3E97DDE432A8054297EBF432285C9FBBC3E8F6FC5E4ECFCBA07698ED0205DDF3B77B4E2FBB41F2F7784D0791C37310325C9F83EEE93228DD6E97E52E970BA460A6CB", /* sms 2, fragment 1/2 */

    "0791947101670000440C919471202700300000900103516475401E050003050202C465D051EEF79441F6B71BC4840643A110A8F83402" /* sms 2, fragment 2/2 */
};

public const string pdu3 = "0791947106004034040C9194713900303341009001910002108059D6B75B076A86D36CF11BEF024DD365103A2C2EBB413290BB5C2F839CE1315A9E1EA3E96537C805D2D6DBA0A0585E3797DDA0FB1ECD2EBB41D37419244ED3E965906845CBC56EB9190C069BCD6622";
public const int pdulength3 = 97;

SList<weak Sms.Message> smslist;

/******************************************************************************************
 ******************************************************************************************/

void test_sms_decode_deliver_single_default_alphabet()
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
    uint dcs;
    uint8 max;

    var ud = sms.extract_common( out udhi, out dcs, out max );
    assert( ud != null );
    assert( ud.length == 30 );
    assert( dcs == 0 );
    assert( max == 140 );
    assert( !udhi );
}

void test_sms_decode_deliver_single_concatenated_default_alphabet()
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
    uint dcs;
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

void test_sms_decode_deliver_multiple_concatenated_default_alphabet()
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

void test_sms_decode_deliver_whole_concatenated_default_alphabet()
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

/******************************************************************************************
 ******************************************************************************************/

void test_sms_encode_submit_single_default_alphabet()
{
    int offset;
    smslist = Sms.text_prepare( SHORT_TEXT, 0, true, out offset );
    assert( smslist.length() == 1 );
    unowned Sms.Message sms = (Sms.Message)smslist.nth_data( 0 );
    assert( sms.type == Sms.Type.SUBMIT );
    assert( sms.to_string() == SHORT_TEXT );

    bool udhi;
    uint dcs;
    uint8 max;

    var ud = sms.extract_common( out udhi, out dcs, out max );
    assert( ud != null );
    assert( ud.length == SHORT_TEXT.length );
    assert( dcs == 0 );
    assert( max == 140 );
    assert( !udhi );
}

void test_sms_encode_submit_concatenated_default_alphabet()
{
    SmsHandler handler = new AtSmsHandler();
    var pdu = handler.formatTextMessage( PHONE_NUMBER, LONG_TEXT );
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

/******************************************************************************************
 ******************************************************************************************/
void test_sms_extraction()
{
    /*
    int dst;
    int src;
    bool is_8bit;

    //assert( sms.extract_app_port( out dst, out src, out is_8bit ) );

    for( uint8 refnum = 0; refnum < 65535; ++refnum )
    {
        int offset;
        smslist = Sms.text_prepare( LONG_TEXT, refnum, true, out offset );

        uint16 ref_num = 0;
        uint8 max_msgs = 0;
        uint8 seq_num  = 0;

        for( int i = 0; i < smslist.length(); ++i )
        {
            unowned Sms.Message sms = *( (Sms.Message*) smslist.nth_data( i ) );
            assert( sms.extract_concatenation( out ref_num, out max_msgs, out seq_num ) );
            assert( max_msgs == smslist.length() );
            assert( seq_num == i+1 );
        }
        message( "ref_num = %u", ref_num );
        assert( ref_num == refnum );
    }
    //assert( sms.extract_language_variant( out uint8 locking, out uint8 single );
    */
}

void test_fso_sms_storage_new()
{
    var storage = new SmsStorage( IMSI );
}

void test_fso_sms_storage_add_single()
{
    var storage = new SmsStorage( IMSI );
    storage.clean();

    var sms = Sms.Message.newFromHexPdu( pdu3, pdulength3 );
    assert( sms != null );

    // new one
    assert( storage.addSms( sms ) == SmsStorage.SMS_SINGLE_COMPLETE );

    // this one we have already seen
    assert( storage.addSms( sms ) == SmsStorage.SMS_ALREADY_SEEN );
}

void test_fso_sms_storage_add_concatenated()
{
    var storage = new SmsStorage( IMSI );
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
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/3rdparty/Sms/Decode/Deliver/Single/DefaultAlphabet", test_sms_decode_deliver_single_default_alphabet );
    Test.add_func( "/3rdparty/Sms/Decode/Deliver/Single/Concatenated/DefaultAlphabet", test_sms_decode_deliver_single_concatenated_default_alphabet );
    Test.add_func( "/3rdparty/Sms/Decode/Deliver/Multiple/Concatenated/DefaultAlphabet", test_sms_decode_deliver_multiple_concatenated_default_alphabet );
    Test.add_func( "/3rdparty/Sms/Decode/Deliver/Whole/Concatenated/DefaultAlphabet", test_sms_decode_deliver_whole_concatenated_default_alphabet );

    Test.add_func( "/3rdparty/Sms/Encode/Submit/Single/DefaultAlphabet", test_sms_encode_submit_single_default_alphabet );
    Test.add_func( "/3rdparty/Sms/Encode/Submit/Concatenated/DefaultAlphabet", test_sms_encode_submit_concatenated_default_alphabet );
    //Test.add_func( "/3rdparty/Sms/Encode/Submit/Multiple/Concatenated/DefaultAlphabet", test_sms_encode_submit_multiple_concatenated_default_alphabet );
    //Test.add_func( "/3rdparty/Sms/Encode/Submit/Whole/Concatenated/DefaultAlphabet", test_sms_encode_submit_whole_concatenated_default_alphabet );


#if FOO
    Test.add_func( "/Fso/Sms/Storage/New", test_fso_sms_storage_new );
    //Test.add_func( "/Fso/Sms/Storage/Existing", test_fso_sms_storage_new_existing );
    Test.add_func( "/Fso/Sms/Storage/Add/Single", test_fso_sms_storage_add_single );
    Test.add_func( "/Fso/Sms/Storage/Add/Concatenated", test_fso_sms_storage_add_concatenated );
    //Test.add_func( "/Fso/Sms/Storage/Add/Random", test_fso_sms_storage_add_random );
#endif
    Test.run();
}
