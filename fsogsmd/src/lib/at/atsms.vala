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
 * @class AtSmsHandler
 **/
public class FsoGsm.AtSmsHandler : FsoGsm.SmsHandler, FsoFramework.AbstractObject
{
    public SmsStorage storage { get; set; }

    public AtSmsHandler()
    {
        //FIXME: Use random init or read from file, so that this is increasing even during relaunches
        if ( theModem == null )
        {
            logger.warning( "SMS Handler created before modem" );
        }
        else
        {
            theModem.signalStatusChanged.connect( onModemStatusChanged );
        }
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

    public async void simIsReady()
    {
        yield syncWithSim();
    }

    public async void syncWithSim()
    {
        // gather IMSI
        var cimi = theModem.createAtCommand<PlusCIMI>( "+CIMI" );
        var response = yield theModem.processAtCommandAsync( cimi, cimi.execute() );
        if ( cimi.validate( response ) != Constants.AtResponse.VALID )
        {
            logger.warning( "Can't synchronize SMS storage with SIM" );
            return;
        }

        // create Storage for current IMSI
        storage = new SmsStorage( cimi.value );

        // read all messages
        var cmgl = theModem.createAtCommand<PlusCMGL>( "+CMGL" );
        var cmglresponse = yield theModem.processAtCommandAsync( cmgl, cmgl.issue( PlusCMGL.Mode.ALL ) );
        if ( cmgl.validateMulti( cmglresponse ) != Constants.AtResponse.VALID )
        {
            logger.warning( "Can't synchronize SMS storage with SIM" );
            return;
        }

        foreach( var sms in cmgl.messagebook )
        {
            storage.addSms( sms.message );
        }
    }

    public async void handleIncomingSmsOnSim( uint index )
    {
        // read SMS
        var cmd = theModem.createAtCommand<PlusCMGR>( "+CMGR" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( index ) );
        if ( cmd.validateUrcPdu( response ) != Constants.AtResponse.VALID )
        {
            logger.warning( @"Can't read new SMS from SIM storage at index $index." );
            return;
        }
        yield _handleIncomingSms( cmd.hexpdu, cmd.tpdulen );
    }

    public async void handleIncomingSms( string hexpdu, int tpdulen )
    {
        // acknowledge SMS
        var cmd = theModem.createAtCommand<PlusCNMA>( "+CNMA" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( 0 ) );
        if ( cmd.validate( response ) != Constants.AtResponse.VALID )
        {
            logger.warning( @"Can't acknowledge new SMS" );
        }
        yield _handleIncomingSms( hexpdu, tpdulen );
    }

    public async void _handleIncomingSms( string hexpdu, int tpdulen )
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

    public void _handleIncomingSmsReport( Sms.Message sms )
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
