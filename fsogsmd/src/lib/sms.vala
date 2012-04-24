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

using Gee;

/**
 * @class WrapSms
 *
 * A helper class
 */
public class WrapSms
{
    public Sms.Message message;
    public int index;

    public WrapSms( owned Sms.Message message, int index = -1 )
    {
        this.index = index;
        this.message = (owned) message;

        if ( this.message.type == Sms.Type.DELIVER )
        {
#if DEBUG
            debug( "WRAPSMS: Created for message hash %s", this.message.hash() );
#endif
        }
        else
        {
            FsoFramework.theLogger.warning( "SMS type %d not yet supported".printf( this.message.type ) );
        }
    }

    ~WrapSms()
    {
        if ( message.type == Sms.Type.DELIVER )
        {
#if DEBUG
            debug( "WRAPSMS: Destructed for message hash %s", this.message.hash() );
#endif
        }
    }
}

/**
 * @class WrapHexPdu
 *
 * A helper class
 */
public class WrapHexPdu
{
    public string hexpdu;
    public uint tpdulen;
    public int transaction_index;

    public WrapHexPdu( string hexpdu, uint tpdulen )
    {
        this.hexpdu = hexpdu;
        this.tpdulen = tpdulen;
        this.transaction_index = -1;
    }
}

/**
 * @interface SmsHandler
 */
public interface FsoGsm.SmsHandler : FsoFramework.AbstractObject
{
    public abstract ISmsStorage storage { get; set; }

    public abstract async void handleIncomingSmsOnSim( uint index );
    public abstract async void handleIncomingSms( string hexpdu, int tpdulen );
    public abstract async void handleIncomingSmsReport( string hexpdu, int tpdulen );

    public abstract uint16 lastReferenceNumber();
    public abstract uint16 nextReferenceNumber();

    public abstract Gee.ArrayList<WrapHexPdu> formatTextMessage( string number, string contents, bool requestReport );
    public abstract void storeTransactionIndizesForSentMessage( Gee.ArrayList<WrapHexPdu> hexpdus );
}

/**
 * @class AbstractSmsHandler
 *
 * An abstract SMS message handler which implements most parts for handling
 * incoming and outgoing message and only requires an subclass to implement
 * the real actions like acknowledging a message.
 **/
public abstract class FsoGsm.AbstractSmsHandler : FsoGsm.SmsHandler, FsoFramework.AbstractObject
{
    public ISmsStorage storage { get; set; }

    protected abstract async string retrieveImsiFromSIM();
    protected abstract async void fillStorageWithMessageFromSIM();
    protected abstract async bool readSmsMessageFromSIM( uint index, out string hexpdu, out int tpdulen );
    protected abstract async bool acknowledgeSmsMessage( int id );

    //
    // private
    //

    private void onModemStatusChanged( FsoGsm.Modem modem, FsoGsm.Modem.Status status )
    {
        if ( status == Modem.Status.ALIVE_SIM_READY )
            simIsReady();
    }

    private async void simIsReady()
    {
        yield syncWithSim();
    }

    private async void syncWithSim()
    {
        string imsi = yield retrieveImsiFromSIM();

        if ( imsi == "" || imsi == null )
            imsi = "unknown";

        storage = SmsStorageFactory.create( "default", imsi );

        yield fillStorageWithMessageFromSIM();
    }

    private async void _handleIncomingSms( string hexpdu, int tpdulen )
    {
        var sms = Sms.Message.newFromHexPdu( hexpdu, tpdulen );
        if ( sms == null )
        {
            logger.warning( @"Can't parse incoming SMS" );
            return;
        }
        var result = storage.addSms( sms );
        if ( result == SmsStorage.SMS_ALREADY_SEEN )
        {
            logger.warning( @"Ignoring already seen SMS" );
            return;
        }
        else if ( result == SmsStorage.SMS_MULTI_INCOMPLETE )
        {
            logger.info( @"Got new fragment for still-incomplete concatenated SMS" );
            return;
        }
        else /* complete */
        {
            logger.info( @"Got new SMS from $(sms.number())" );
            var msg = storage.message( sms.hash() );
            var obj = theModem.theDevice<FreeSmartphone.GSM.SMS>();
            obj.incoming_text_message( msg.number, msg.timestamp, msg.contents );
        }
    }

    private void _handleIncomingSmsReport( Sms.Message sms )
    {
        var number = sms.number();
        var reference = sms.status_report.mr;
        var status = sms.status_report.st;
        var text = sms.to_string();
#if DEBUG
        debug( @"sms report addr: $number" );
        debug( @"sms report ref: $reference" );
        debug( @"sms report status: $status" );
        debug( @"sms report text: '$text'" );
#endif
        var transaction_index = storage.confirmReceivedMessage( reference );
        if ( transaction_index >= 0 )
        {
            var obj = theModem.theDevice<FreeSmartphone.GSM.SMS>();
            obj.incoming_message_report( transaction_index, status.to_string(), number, text );
        }
    }

    //
    // protected
    //

    protected AbstractSmsHandler()
    {
        //FIXME: Use random init or read from file, so that this is increasing even during relaunches
        if ( theModem == null )
            logger.warning( "SMS Handler created before modem" );
        else theModem.signalStatusChanged.connect( onModemStatusChanged );
    }

    //
    // public API
    //

    public uint16 lastReferenceNumber()
    {
        return storage.lastReferenceNumber();
    }

    public uint16 nextReferenceNumber()
    {
        return storage.increasingReferenceNumber();
    }

    public Gee.ArrayList<WrapHexPdu> formatTextMessage( string number, string contents, bool requestReport )
    {
        uint16 inref = nextReferenceNumber();
#if DEBUG
        debug( @"using reference number $inref" );
#endif
        int byteOffsetForRefnum;

        var hexpdus = new Gee.ArrayList<WrapHexPdu>();

        var smslist = Sms.text_prepare( contents, inref, true, out byteOffsetForRefnum );
#if DEBUG
        debug( @"message prepared in $(smslist.length()) smses" );
#endif

        smslist.foreach ( (element) => {
            unowned Sms.Message msgelement = (Sms.Message) element;
            // FIXME: encode service center address?
            //msgelement.sc_addr.from_string( "+490000000" );
            // encode destination address
            msgelement.submit.daddr.from_string( number );
            // encode report request
            msgelement.submit.srr = requestReport;
            // decode to hex pdu
            var tpdulen = 0;
            var hexpdu = msgelement.toHexPdu( out tpdulen );
            assert( tpdulen > 0 );
            hexpdus.add( new WrapHexPdu( hexpdu, tpdulen ) );
        } );
#if DEBUG
        debug( "message encoded in %u hexpdus", hexpdus.size );
#endif
        return hexpdus;
    }

    public async void handleIncomingSmsOnSim( uint index )
    {
        string hexpdu = "";
        int tpdulen = 0;

        var result = yield readSmsMessageFromSIM( index, out hexpdu, out tpdulen );
        if ( !result )
        {
            logger.error( @"Could not read SMS message with index $(index) from SIM" );
            return;
        }

        yield _handleIncomingSms( hexpdu, tpdulen );
    }

    public async void handleIncomingSms( string hexpdu, int tpdulen )
    {
        var result = yield acknowledgeSmsMessage( 0 );
        if ( !result )
        {
            logger.warning( @"Could not acknowledge incoming message" );
            // FIXME should we revert here without processing the message anymore so it
            // gets lost (the modem has to resend it anyway and it should be saved within
            // the SMS storage center until we can successfully acknowledge it?)
        }

        yield _handleIncomingSms( hexpdu, tpdulen );
    }

    public async void handleIncomingSmsReport( string hexpdu, int tpdulen )
    {
        var sms = Sms.Message.newFromHexPdu( hexpdu, tpdulen );
        if ( sms == null )
        {
            logger.warning( @"Can't parse SMS Status Report" );
            return;
        }

        _handleIncomingSmsReport( (owned) sms );
    }

    public void storeTransactionIndizesForSentMessage( Gee.ArrayList<WrapHexPdu> hexpdus )
    {
        storage.storeTransactionIndizesForSentMessage( hexpdus );
    }
}

// vim:ts=4:sw=4:expandtab
