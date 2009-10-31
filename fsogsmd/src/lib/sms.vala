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
        //FIXME: read from backup
    }

    /**
     * Hand a new message over to the storage.
     *
     * @note The storage will now own the message.
     * @returns -1, if the message is already known.
     * @returns 0, if the message is a fragment of an incomplete concatenated sms.
     * @returns n, if the message is a fragment which completes an incomplete concatenated sms.
     **/
    public int addSms( owned Sms.Message message )
    {
        return -1;
    }
}





/**
 * @class AtSmsHandler
 **/
public class FsoGsm.SmsHandler : FsoFramework.AbstractObject
{
    private FsoFramework.SmartKeyFile smsconfig;
    private string key;

    public SmsHandler()
    {
        theModem.signalStatusChanged += onModemStatusChanged;

        var smsconfigfilename = config.stringValue( "fsogsmd", "sms_storage", "/tmp/fsogsmd/sms" );

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

        // run through all and notify

        // write timestamp
        smsconfig.write<int>( key, "last_sync", (int)GLib.TimeVal().tv_sec );
    }
}



