/*
 * Copyright (C) 2010 Simon Busch <morphis@gravedo.de>
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


public class MsmModemAgent : FsoFramework.AbstractObject
{
    private DBus.Connection _dbusconn;
    private FreeSmartphone.Usage _usage;
    private uint _watch;
    private static MsmModemAgent _instance;
    private bool _withoutUsageDaemon;
    
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
    
    public void setup()
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
        
        // FIXME Skip usage daemon for now ...
        #if 0
        _usage = _dbusconn.get_object( "org.freesmartphone.ousaged", 
                                       "/org/freesmartphone/Usage", 
                                       "org.freesmartphone.Usage" ) as FreeSmartphone.Usage;
                                       
        Idle.add( () => { lookForObjects(); return false; } );
        #endif
        
        registerObjects();
        ready = true;
    }
    
    public override string repr()
    {
        return "<>";
    }

    public void notifyUnsolicitedResponse( string urcName )
    {

    }
    
    //
    // private API
    //
    
    private MsmModemAgent()
    {
        _watch = 0;
        ready = false;
        _withoutUsageDaemon = false;
    }
    
    private async void lookForObjects()
    {
        if ( _watch > 0 ) {
            Source.remove( _watch );
        }
        
        try {
            if (!_withoutUsageDaemon) {
                var resources = yield _usage.list_resources();
                if ( "Modem" in resources ) {
                    yield _usage.request_resource( "Modem" );
                    registerObjects();
                    ready = true;
                }
                else {
                    logger.info( @"Usage daemon is present w/ $(resources.length) resoures. No Modem yet, waiting for resource" );
                    _usage.resource_available.connect( onUsageResourceAvailable );
                }
            }
            else {
                registerObjects();
            }
        }
        catch ( GLib.Error err ) {
            logger.error( @"Error: $(err.message); trying again in 5 seconds" );
            _watch = Timeout.add_seconds( 5, () => { lookForObjects(); return false; } );
        }
    }
    
    private void onUsageResourceAvailable( string resource, bool availability )
    {
        logger.info( @"Resource $resource is now %s".printf( availability ? "available" : "gone" ) );
        if ( resource == "Modem" ) {
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
