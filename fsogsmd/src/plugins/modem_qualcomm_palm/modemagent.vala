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
    public GLib.Variant? response { get; set; }
    public uint timeout { get; set; }
}


public class MsmModemAgent : FsoFramework.AbstractObject
{
    private GLib.DBusConnection _dbusconn;
    private FreeSmartphone.Usage _usage;
    private uint _watch;
    private static MsmModemAgent _instance;
    private bool _withUsageIntegration;
    private Gee.ArrayList<WaitForUnsolicitedResponseData> _urc_waiters;
    private bool _modemResourceIsReady;

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
            logger.debug( "Shutdown is called; release resource and move to in-active state" );

            if ( _withUsageIntegration && _modemResourceIsReady )
            {
                logger.debug( "Releasing Modem resource" );
                yield _usage.release_resource("Modem");
                _modemResourceIsReady = false;
            }

            ready = false;
        }
        else
        {
            logger.info("Tried to shutdown but we are already in inactive mode! Ignoring this ...");
        }
    }

    /**
     * Initialize all necessary stuff
     **/
    public async void initialize()
    {
        if (!ready)
        {
            // setup up dbus ...
            try {
                _dbusconn = yield GLib.Bus.get( GLib.BusType.SYSTEM );
            }
            catch (GLib.Error err)
            {
                logger.critical( "Can't communicate with DBus" );
                Posix.exit(1);
            }

            _withUsageIntegration = ( GLib.Environment.get_variable( "FSOGSMD_PALM_SKIP_USAGE" ) == null );

            _usage = yield _dbusconn.get_proxy<FreeSmartphone.Usage>( FsoFramework.Usage.ServiceDBusName,
                                                                      FsoFramework.Usage.ServicePathPrefix,
                                                                      DBusProxyFlags.NONE );

            _usage.resource_available.connect( onUsageResourceAvailable );

            Idle.add( () => { lookForObjects(); return false; } );
        }
        else
        {
            logger.info("Tried to initialize but we are already ready for work! Ignoring this ...");
        }
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
    public async void notifyUnsolicitedResponse( Msmcomm.UrcType type, GLib.Variant? response )
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

    /**
     *
     **/
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

    /**
     * Check wether we have to listen to fsousaged for the modem resource to
     * start up or proceed without resource handling and register modem interfaces
     * the simple way.
     **/
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
                _modemResourceIsReady = true;
                registerObjects();
                yield onModemAvailable();
            }
            else
            {
                logger.info( @"Usage daemon is present w/ $(resources.length) resoures. No Modem yet, waiting for resource" );
            }
        }
        catch ( GLib.Error err )
        {
            logger.error( @"Error: $(err.message); trying again in 5 seconds" );
            _watch = Timeout.add_seconds( 5, () => { lookForObjects(); return false; } );
        }
    }

    /**
     * Modem resource is now available proceed with additional initialization
     * steps here
     **/
    private async void onModemAvailable()
    {
        logger.info( "Modem available now, trying to get it's state" );

        // If we have a pending watch remove it as we don't have to wait for the
        // modem anymore
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

            // If modem is in closed state as maybe the msmcomm daemon disappeared
            // while fsogsmd was already running we have to reopen the modem
            if ( FsoGsm.theModem.status() == FsoGsm.Modem.Status.CLOSED )
            {
                FsoGsm.theModem.open();
            }
        }
        catch ( GLib.Error e )
        {
            logger.error( @"Error: $(e.message)" );
        }
    }

    /**
     * Handle modem resource state changes
     **/
    private void onUsageResourceAvailable( string resource, bool availability )
    {
        logger.info( @"Resource $resource is now %s".printf( availability ? "available" : "gone" ) );
        if ( resource == "Modem" )
        {
            if ( availability && !ready )
            {
                // Modem resource is now available: try to register all interfaces
                // we need
                lookForObjects();
            }
            else
            {
                // Modem resource has gone -> we need to deactivate the modem agent
                // and tell the modem handler that he has no modem in the background
                // anymore
                _modemResourceIsReady = false;
                FsoGsm.theModem.close();
            }
        }
    }

    /**
     * Register all needed dbus objects from msmcomm daemon
     **/
    private async void registerObjects()
    {
        management = yield _dbusconn.get_proxy<Msmcomm.Management>( "org.msmcomm", "/org/msmcomm", DBusProxyFlags.NONE );
        commands = yield _dbusconn.get_proxy<Msmcomm.Commands>( "org.msmcomm", "/org/msmcomm", DBusProxyFlags.NONE );
        unsolicited = yield _dbusconn.get_proxy<Msmcomm.ResponseUnsolicited>( "org.msmcomm", "/org/msmcomm", DBusProxyFlags.NONE );
    }
}

