/*
 * Copyright (C) 2010 Simon Busch <morphis@gravedo.de>
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

internal class WaitForUnsolicitedResponseData
{
    public GLib.SourceFunc callback { get; set; }
    public Msmcomm.UrcType urc_type { get; set; }
    public GLib.Variant response { get; set; }
    public uint timeout { get; set; }
}


public class MsmModemAgent : FsoFramework.AbstractObject
{
    private DBus.Connection _dbusconn;
    private FreeSmartphone.Usage _usage;
    private uint _watch;
    private static MsmModemAgent _instance;
    private bool _withUsageIntegration;
    private Gee.ArrayList<WaitForUnsolicitedResponseData> _urc_waiters;

    public bool ready { get; private set; }
    public Msmcomm.Management management { get; set; }
    public Msmcomm.Commands commands { get; set; }
    public Msmcomm.ResponseUnsolicited unsolicited { get; set; }

    //
    // public API
    //

    public static MsmModemAgent instance()
    {
        if ( _instance == null )
        {
            _instance = new MsmModemAgent();
        }
        return _instance;
    }

    public async void shutdown()
    {
        if (ready)
        {
            if (_withUsageIntegration)
            {
                yield _usage.release_resource("Modem");
            }
        }
    }

    /**
     * Initialize all necessary stuff
     **/
    public void initialize()
    {
        // setup up dbus ...
        try {
            _dbusconn = DBus.Bus.get( DBus.BusType.SYSTEM );
        }
        catch (GLib.Error err)
        {
            logger.critical( "Can't communicate with DBus" );
            // theModem.die();
            Posix.exit(1);
        }

        _withUsageIntegration = ( GLib.Environment.get_variable( "FSOGSMD_PALM_SKIP_USAGE" ) == null );

        _usage = _dbusconn.get_object( "org.freesmartphone.ousaged", "/org/freesmartphone/Usage", "org.freesmartphone.Usage" ) as FreeSmartphone.Usage;
        Idle.add( () => { lookForObjects(); return false; } );
    }

    public override string repr()
    {
        return "<>";
    }

    /**
     * Lets wait for a specific unsolicited response to recieve and return it's payload
     * after it finaly recieves.
     **/
    public async GLib.Variant waitForUnsolicitedResponse( Msmcomm.UrcType type )
    {
        // Create waiter and yield until urc occurs
        var data = new WaitForUnsolicitedResponseData();
        data.urc_type = type;
        data.callback = waitForUnsolicitedResponse.callback;
        _urc_waiters.add( data );
        yield;

        // Urc occured so we can return the recieved message structure to the caller who
        // has now not longer to wait for the urc
        _urc_waiters.remove( data );
        return data.response;
    }

    /**
     * Notify the occurence of a unsolicted response to the modem agent which informs all
     * registered clients for this type of message.
     **/
    public async void notifyUnsolicitedResponse( Msmcomm.UrcType type, GLib.Variant response )
    {
        var waiters = retriveUrcWaiters( type );

        // awake all waiters for the notified urc type and supply them the message payload
        foreach (var waiter in waiters )
        {
            waiter.response = response;
            waiter.callback();
        }
    }

    //
    // private API
    //

    private MsmModemAgent()
    {
        _watch = 0;
        ready = false;
        _withUsageIntegration = false;
        _urc_waiters = new Gee.ArrayList<WaitForUnsolicitedResponseData>();
    }

    private Gee.ArrayList<WaitForUnsolicitedResponseData> retriveUrcWaiters( Msmcomm.UrcType type )
    {
        var result = new Gee.ArrayList<WaitForUnsolicitedResponseData>();

        foreach ( var waiter in _urc_waiters )
        {
            if ( waiter.urc_type == type )
            {
                result.add( waiter );
            }
        }

        return result;
    }


    private async void lookForObjects()
    {
        if ( _watch > 0 )
        {
            Source.remove( _watch );
        }

        try
        {
            if (!_withUsageIntegration)
            {
                registerObjects();
                yield onModemAvailable();
                return;
            }

            var resources = yield _usage.list_resources();
            if ( "Modem" in resources )
            {
                yield _usage.request_resource( "Modem" );
                registerObjects();
                yield onModemAvailable();
            }
            else
            {
                logger.info( @"Usage daemon is present w/ $(resources.length) resoures. No Modem yet, waiting for resource" );
                _usage.resource_available.connect( onUsageResourceAvailable );
            }
        }
        catch ( GLib.Error err )
        {
            logger.error( @"Error: $(err.message); trying again in 5 seconds" );
            _watch = Timeout.add_seconds( 5, () => { lookForObjects(); return false; } );
        }
    }

    private async void onModemAvailable()
    {
        logger.info( "Modem available now, trying to get it's state" );
        if ( _watch > 0 )
        {
            Source.remove( _watch );
        }
        try
        {
            yield management.get_active();

            // We have an active modem resource now!
            ready = true;
            logger.debug("Modem resource is now acquired and ready to use");
        }
        catch ( GLib.Error e )
        {
            logger.error( @"Error: $(e.message)" );
        }
    }

    private void onUsageResourceAvailable( string resource, bool availability )
    {
        logger.info( @"Resource $resource is now %s".printf( availability ? "available" : "gone" ) );
        if ( resource == "Modem")
        {
            lookForObjects();
        }
    }

    private async void registerObjects()
    {
        management = _dbusconn.get_object( "org.msmcomm", "/org/msmcomm", "org.msmcomm.Management" ) as Msmcomm.Management;
        commands = _dbusconn.get_object( "org.msmcomm", "/org/msmcomm", "org.msmcomm.Commands" ) as Msmcomm.Commands;
        unsolicited = _dbusconn.get_object( "org.msmcomm", "/org/msmcomm", "org.msmcomm.Unsolicited" ) as Msmcomm.ResponseUnsolicited;
    }
}

