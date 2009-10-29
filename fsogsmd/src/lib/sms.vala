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

using Gee;

namespace FsoGsm {

/**
 * @class ShortMessage
 *
 * Higher level SMS abstraction on top of the lowlevel 3rdparty SMS code
 **/
public class ShortMessage
{
    public string number { get; set; }
    //FIXME: might rather be a uint8[] (for binary SMS)?
    public string contents { get; set; }
    public GLib.HashTable<string,GLib.Value?> properties { get; set; }

    public ShortMessage( string number, string contents, GLib.HashTable<string,GLib.Value?>? properties = null )
    {
        this.number = number;
        this.contents = contents;
        this.properties = properties != null ? properties : new GLib.HashTable<string,GLib.Value?>( str_hash, str_equal );
    }

    public static ShortMessage decodeFromHexPdu( string pdu, int tpdulen )
    {
        long items_written = -1;
        char[] outbuffer = new char[1024];
        Conversions.decode_hex_own_buf( pdu, -1, out items_written, 0, outbuffer );
        message( "%ld items", items_written );

        var sms = Sms.Message();
        var res = Sms.decode( outbuffer, false, tpdulen, out sms );
        message( "decode: %d", (int)res );

        if ( res )
        {
            message( "type: %d", sms.type );
            message( "service center: %s", sms.sc_addr.to_string() );
            message( "number: %s", sms.number() );

            message( "scts: %u/%u/%u %u:%u:%u +%d",
                     sms.deliver.scts.year,
                     sms.deliver.scts.month,
                     sms.deliver.scts.day,
                     sms.deliver.scts.hour,
                     sms.deliver.scts.minute,
                     sms.deliver.scts.second,
                     sms.deliver.scts.timezone );
            message( "text: '%s'", sms.to_string() );

            var instance = new ShortMessage( sms.number(), sms.to_string(), sms.properties() );
            return instance;
        }
        else
        {
            return null;
        }
    }

    public static uint8 reference;

    public static uint8 nextReferenceNumber()
    {
        if ( ShortMessage.reference == 0 )
        {
            ShortMessage.reference = (uint8) Random.int_range( 1, 65535 );
        }
        return ++ShortMessage.reference;
    }

    public struct HexPdu
    {
        string pdu;
        int tpdulen;
    }

    public static HexPdu[] formatTextMessage( string number, string contents, out uint8 refnum )
    {
        //uint16 nextrefnum = nextReferenceNumber();
        uint8 nextrefnum = 42;

        var encodeWithUcs2 = true;

        int offset;
        var smslist = Sms.text_prepare( contents, 0, encodeWithUcs2, out offset );

        debug( "formatTextMessage: will create %u hexpdus w/ offset=%d", smslist.length(), offset );

        var hexpdus = new HexPdu[smslist.length()] {};

        // set reference number and to address
        smslist.foreach( (element) =>
        {
            var psms = (Sms.Message*)element;

            if ( offset != 0 )
            {
                psms->submit.ud[offset+0] = ( nextrefnum & 0xf0) >> 8;
                psms->submit.ud[offset+1] = ( nextrefnum & 0x0f);
            }

            psms->submit.daddr.from_string( number );
        } );

        char[] binpdu = new char[176];
        char[] hexpdu = new char[1024];
        var pdulen = 0;
        var tpdulen = 0;
        uint i = 0;

        // convert to PDU
        smslist.foreach( (element) =>
        {
            var psms = (Sms.Message*)element;

            var ok = Sms.encode( *psms, out pdulen, out tpdulen, binpdu );
            assert( ok );

            Conversions.encode_hex_own_buf( binpdu, 0, hexpdu );
            debug( "   hexpdu created w/ tpdulen = %d: %s", tpdulen, (string)hexpdu );
            hexpdus[i++] = HexPdu() { pdu=(string)hexpdu, tpdulen=tpdulen };
        } );

        refnum = nextrefnum;
        return hexpdus;
    }
}

/**
 * @class AtSmsHandler
 **/
public class SmsHandler : FsoFramework.AbstractObject
{
    private FsoFramework.SmartKeyFile smsconfig;
    private string key;

    public SmsHandler()
    {
        theModem.signalStatusChanged += onModemStatusChanged;

        var smsconfigfilename = config.stringValue( "fsogsmd", "smsconfig", "/tmp/fsogsmd.smsdb.conf" );
        smsconfig = new FsoFramework.SmartKeyFile();
        smsconfig.loadFromFile( smsconfigfilename );

        key = "unknown";
    }

    private override string repr()
    {
        return @"<$key>";
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

    public async void syncWithSim()
    {
        // gather IMSI
        var cimi = theModem.createAtCommand<PlusCGMR>( "+CIMI" );
        var response = yield theModem.processCommandAsync( cimi, cimi.execute() );
        if ( cimi.validate( response ) != Constants.AtResponse.VALID )
        {
            return;
        }

        key = @"IMSI.$(cimi.value)";

        if ( smsconfig.hasSection( key ) )
        {
            assert( logger.debug( @"IMSI $(cimi.value) seen before" ) );
        }
        else
        {
            logger.info( @"IMSI $(cimi.value) never seen before" );
        }

        // ...

        // write timestamp
        smsconfig.write<int>( key, "last_sync", (int)GLib.TimeVal().tv_sec );
    }
}


} /* namespace FsoGsm */
