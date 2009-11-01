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
        FsoFramework.FileHandling.createDirectoryHierarchy( storagedir );
        //FIXME: read from backup
        logger.info( "Created" );
    }

    public const int SMS_ALREADY_SEEN = -1;
    public const int SMS_FRAGMENT_INCOMPLETE = 0;
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
        debug( smshash );

        uint16 ref_num;
        uint8 max_msgs = 1;
        uint8 seq_num = 1;

        FsoFramework.FileHandling.createDirectoryHierarchy( GLib.Path.build_filename( storagedir, smshash ) );

        if ( !message.extract_concatenation( out ref_num, out max_msgs, out seq_num ) )
        {
            // message is not concatenated
            var filename = GLib.Path.build_filename( storagedir, smshash, "001" );
            if ( FsoFramework.FileHandling.isPresent( filename ) )
            {
                return -1;
            }
            // message is not present, save it
            FsoFramework.FileHandling.writeBuffer( &message, sizeof( Sms.Message ), filename, true );
            return 1;
        }
        else
        {
            // message is concatenated
            assert_not_reached();
            return -1;
        }
    }
}

/**
 * @class AtSmsHandler
 **/
public class FsoGsm.SmsHandler : FsoFramework.AbstractObject
{
    protected SmsStorage storage;

    public SmsHandler()
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
}



