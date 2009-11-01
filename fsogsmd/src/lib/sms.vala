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

    //private

    static construct
    {
        storagedirprefix = SMS_STORAGE_DEFAULT_STORAGE_DIR;
    }

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
        this.storagedir = GLib.Path.build_filename( storagedirprefix, imsi );
        GLib.DirUtils.create_with_parents( storagedir, SMS_STORAGE_DIRECTORY_PERMISSIONS );
        //FIXME: read from backup
        logger.info( "Created" );
    }

    public const int SMS_ALREADY_SEEN = -1;
    public const int SMS_MULTI_INCOMPLETE = 0;
    public const int SMS_SINGLE_COMPLETE = 1;

    public void clean()
    {
        Posix.remove( storagedir );
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
    public int addSms( owned Sms.Message message )
    {
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
            FsoFramework.FileHandling.writeBuffer( &message, sizeof( Sms.Message ), filename, true );
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
            FsoFramework.FileHandling.writeBuffer( &message, sizeof( Sms.Message ), filename, true );
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
}

/**
 * @interface SmsHandler
 */
public interface FsoGsm.SmsHandler : FsoFramework.AbstractObject
{
    public abstract async void handleIncomingSmsOnSim( uint index );
}

/**
 * @class AtSmsHandler
 **/
public class FsoGsm.AtSmsHandler : FsoGsm.SmsHandler, FsoFramework.AbstractObject
{
    protected SmsStorage storage;

    public AtSmsHandler()
    {
        theModem.signalStatusChanged += onModemStatusChanged;

        var smsstoragedir = config.stringValue( "fsogsmd", "sms_storage", "/tmp/fsogsmd/sms" );
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

    public async void syncWithSim()
    {
        // gather IMSI
        var cimi = theModem.createAtCommand<PlusCGMR>( "+CIMI" );
        var response = yield theModem.processCommandAsync( cimi, cimi.execute() );
        if ( cimi.validate( response ) != Constants.AtResponse.VALID )
        {
            return;
        }

        // create Storage for current IMSI
        storage = new SmsStorage( cimi.value );

        // write timestamp
        //smsconfig.write<int>( key, "last_sync", (int)GLib.TimeVal().tv_sec );
    }

    public async void handleIncomingSmsOnSim( uint index )
    {
        assert_not_reached();
    }
}



