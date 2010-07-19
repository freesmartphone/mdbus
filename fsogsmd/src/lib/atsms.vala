/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

namespace FsoGsm
{
    public const string SMS_STORAGE_DEFAULT_STORAGE_DIR = "/tmp/fsogsmd/sms";
    public const int SMS_STORAGE_DIRECTORY_PERMISSIONS = (int)Posix.S_IRUSR|Posix.S_IWUSR|Posix.S_IXUSR|Posix.S_IRGRP|Posix.S_IXGRP|Posix.S_IROTH|Posix.S_IXOTH;
} /* namespace FsoGsm */

/**
 * @class SmsStorage
 *
 * A high level persistent SMS Storage abstraction.
 */
public class FsoGsm.SmsStorage : FsoFramework.AbstractObject
{
    private static string storagedirprefix;
    private string imsi;
    private string storagedir;

    static construct
    {
        storagedirprefix = SMS_STORAGE_DEFAULT_STORAGE_DIR;
    }

    // for debugging purposes mainly
    public static void setStorageDir( string dirname )
    {
        storagedirprefix = dirname;
    }

    public override string repr()
    {
        return imsi != null ? @"<$imsi>" : @"<>";
    }

    //
    // public API
    //

    public SmsStorage( string imsi )
    {
        this.imsi = imsi;
        storagedirprefix = config.stringValue( CONFIG_SECTION, "sms_storage_dir", SMS_STORAGE_DEFAULT_STORAGE_DIR );
        this.storagedir = GLib.Path.build_filename( storagedirprefix, imsi );
        GLib.DirUtils.create_with_parents( storagedir, SMS_STORAGE_DIRECTORY_PERMISSIONS );
        logger.info( @"Created w/ storage dir $(this.storagedir)" );
    }

    public const int SMS_ALREADY_SEEN = -1;
    public const int SMS_MULTI_INCOMPLETE = 0;
    public const int SMS_SINGLE_COMPLETE = 1;

    public void clean()
    {
        FsoFramework.FileHandling.removeTree( this.storagedir );
    }

    /**
     * Hand a new message over to the storage.
     *
     * @note The storage will now own the message.
     * @returns -1, if the message is already known.
     * @returns 0, if the message is a fragment of an incomplete concatenated sms.
     * @returns 1, if the message is not concatenated, hence complete.
     * @returns n > 1, if the message is a fragment which completes an incomplete concatenated sms composed out of n fragments.
     **/
    public int addSms( Sms.Message message )
    {
        // only deal with DELIVER types for now
        if ( message.type != Sms.Type.DELIVER )
        {
            logger.info( "Ignoring message with type %u (!= DELIVER)".printf( (uint)message.type ) );
            return SMS_ALREADY_SEEN;
        }
        // generate hash
        var smshash = message.hash();

        uint16 ref_num;
        uint8 max_msgs = 1;
        uint8 seq_num = 1;

        GLib.DirUtils.create_with_parents( GLib.Path.build_filename( storagedir, smshash ), SMS_STORAGE_DIRECTORY_PERMISSIONS );

        if ( !message.extract_concatenation( out ref_num, out max_msgs, out seq_num ) )
        {
            // message is not concatenated
            var filename = GLib.Path.build_filename( storagedir, smshash, "001" );
            if ( FsoFramework.FileHandling.isPresent( filename ) )
            {
                return SMS_ALREADY_SEEN;
            }
            // message is not present, save it
            FsoFramework.FileHandling.writeBuffer( message, message.size(), filename, true );
            return SMS_SINGLE_COMPLETE;
        }
        else
        {
            // message is concatenated
            var filename = GLib.Path.build_filename( storagedir, smshash, "%03u".printf( seq_num ) );
            if ( FsoFramework.FileHandling.isPresent( filename ) )
            {
                return SMS_ALREADY_SEEN;
            }
#if DEBUG
            GLib.message( "fragment file %s now present, checking for completeness...", filename );
#endif
            // message is not present, save it
            FsoFramework.FileHandling.writeBuffer( message, message.size(), filename, true );
            // check whether we have all fragments?
            for( int i = 1; i <= max_msgs; ++i )
            {
                var fragmentfilename = GLib.Path.build_filename( storagedir, smshash, "%03u".printf( i ) );
                if( !FsoFramework.FileHandling.isPresent( fragmentfilename ) )
                {
#if DEBUG
                    GLib.message( "fragment file %s not present ==> INCOMPLETE", fragmentfilename );
#endif
                    return SMS_MULTI_INCOMPLETE;
                }
#if DEBUG
                GLib.message( "fragment file %s present", fragmentfilename );
#endif
            }
            return max_msgs; // SMS_MULTI_COMPLETE
        }
    }

    public Gee.ArrayList<string> keys()
    {
        var result = new Gee.ArrayList<string>();
        GLib.Dir dir;
        try
        {
            dir = GLib.Dir.open( storagedir );
            for ( var smshash = dir.read_name(); smshash != null; smshash = dir.read_name() )
            {
                result.add( smshash );
            }
        }
        catch ( GLib.Error e )
        {
            logger.error( @"Can't access SMS storage dir: $(e.message)" );
        }
        return result;
    }

    public FreeSmartphone.GSM.SIMMessage message( string key, int index = 0 )
    {
        var result = FreeSmartphone.GSM.SIMMessage(
            index,
            "unknown",
            "unknown",
            "unknown",
            "unknown",
            new GLib.HashTable<string,Value?>( str_hash, str_equal )
        );

        if ( ! ( key in keys() ) )
        {
            return result;
        }

        if ( key.has_suffix( "_1" ) )
        {
            // single SMS
            string contents;
            try
            {
                GLib.FileUtils.get_contents( GLib.Path.build_filename( storagedir, key, "001" ), out contents );
            }
            catch ( GLib.Error e )
            {
                logger.error( @"Can't access SMS storage dir: $(e.message)" );
                return result;
            }
            unowned Sms.Message message = (Sms.Message) contents;

            result.status = "single";
            result.number = message.number();
            result.contents = message.to_string();
            result.timestamp = message.timestamp().to_string();
            result.properties = message.properties();
        }
        else
        {
            // concatenated SMS
            result.status = "concatenated";
            var namecomponents = key.split( "_" );
            var max_fragment = namecomponents[namecomponents.length-1].to_int();
#if DEBUG
            GLib.message( "highest fragment = %d", max_fragment );
#endif
            var smses = new Sms.Message[max_fragment-1] {};
            bool complete = true;
            bool info = false;

            for( int i = 1; i <= max_fragment; ++i )
            {
                smses[i-1] = new Sms.Message();
                var filename = GLib.Path.build_filename( storagedir, key, "%03u".printf( i ) );
                if ( ! FsoFramework.FileHandling.isPresent( filename ) )
                {
                    complete = false;
                    result.status = "incomplete";

                    smses[i-1] = null;
                }
                else
                {
                    string contents;
                    try
                    {
                        GLib.FileUtils.get_contents( filename, out contents );
                    }
                    catch ( GLib.Error e )
                    {
                        logger.error( @"Can't access SMS storage dir: $(e.message)" );
                        return result;
                    }
                    Memory.copy( smses[i-1], contents, Sms.Message.size() );

                    if ( !info )
                    {
                        result.number = smses[i-1].number();
                        result.timestamp = smses[i-1].timestamp().to_string();
                        result.properties = smses[i-1].properties();
                        info = true;
                    }
                }
            }

            var smslist = new SList<weak Sms.Message>();
            for( int i = 0; i < max_fragment; ++i )
            {
                if ( smses[i] != null )
                {
                        smslist.append( smses[i] );
                }
            }
            var text = Sms.decode_text( smslist );
            result.contents = ( text != null ) ? text : "decode error";
        }
        return result;
    }

    public FreeSmartphone.GSM.SIMMessage[] messagebook()
    {
        var mb = new FreeSmartphone.GSM.SIMMessage[] {};
        var index = 0;
        foreach ( var key in keys() )
        {
            mb += message( key, index = index++ );
        }
        return mb;
    }

    public uint16 lastReferenceNumber()
    {
        var filename = GLib.Path.build_filename( storagedir, "refnum" );
        return (uint16) FsoFramework.FileHandling.read( filename ).to_int();
    }

    public uint16 increasingReferenceNumber()
    {
        var filename = GLib.Path.build_filename( storagedir, "refnum" );
        var number = FsoFramework.FileHandling.read( filename );
        uint16 num = (uint16) number.to_int() + 1;
        FsoFramework.FileHandling.write( filename, num.to_string() );
        return num;
    }
}

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
        int byteOffsetForRefnum;

        var hexpdus = new Gee.ArrayList<WrapHexPdu>();

        var smslist = Sms.text_prepare( contents, inref, true, out byteOffsetForRefnum );
#if DEBUG
        debug( "message prepared in %u smses", smslist.length() );
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
        var obj = theModem.theDevice<FreeSmartphone.GSM.SMS>();
        obj.incoming_message_report( reference, status.to_string(), number, text );
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

}



