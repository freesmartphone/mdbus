/*
 * Generic Resource Controller
 *
 * Written by Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 * All Rights Reserved
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

using GLib;
using Gee;

internal const string DBUS_BUS_NAME = "org.freedesktop.DBus";
internal const string DBUS_BUS_PATH = "/org/freedesktop/DBus";
internal const string DBUS_BUS_INTERFACE = "org.freedesktop.DBus";

internal const string RESOURCE_INTERFACE = "org.freesmartphone.Resource";

internal const string CONFIG_SECTION = "fsousage";

namespace Usage
{
/**
 * Enum for resource status
 **/
public enum ResourceStatus
{
    UNKNOWN,
    ENABLING,
    ENABLED,
    SUSPENDING,
    SUSPENDED,
    RESUMING,
    DISABLING,
    DISABLED
}

/**
 * Helper class encapsulating a registered resource
 **/
public class Resource
{
    public string name;
    public DBus.BusName busname;
    public DBus.ObjectPath objectpath;
    public ResourceStatus status;
    public FreeSmartphone.UsageResourcePolicy policy;
    public ArrayList<string> users;

    private FreeSmartphone.Resource proxy;

    public Resource( string name, DBus.BusName busname, DBus.ObjectPath objectpath )
    {
        this.name = name;
        this.busname = busname;
        this.objectpath = objectpath;
        this.status = ResourceStatus.UNKNOWN;
        this.policy = FreeSmartphone.UsageResourcePolicy.AUTO;
        this.users = new ArrayList<string>( str_equal );

        proxy = dbusconn.get_object( busname, objectpath, RESOURCE_INTERFACE ) as FreeSmartphone.Resource;
        // workaround until vala 0.7.4
        proxy.ref();

        //message( "Resource %s served by %s @ %s created", name, busname, objectpath );
    }

    ~Resource()
    {
        //message( "Resource %s served by %s @ %s destroyed", name, busname, objectpath );
    }

    private void updateStatus()
    {
        var info = new HashTable<string,Value?>( str_hash, str_equal );
        var p = Value( typeof(int) );
        p.set_int( policy );
        info.insert( "policy", p );
        var u = Value( typeof(int) );
        u.set_int( users.size );
        info.insert( "refcount", u );
        instance.resource_changed( name, isEnabled(), info ); // DBUS SIGNAL
    }

    public bool isEnabled()
    {
        return ( status == ResourceStatus.ENABLED );
    }

    public bool hasUser( string user )
    {
        return ( user in users );
    }

    public void setPolicy( FreeSmartphone.UsageResourcePolicy policy )
    {
        if ( policy == this.policy )
            return;
        else
            ( this.policy = policy );

        switch ( policy )
        {
            case FreeSmartphone.UsageResourcePolicy.DISABLED:
                disable();
                break;
            case FreeSmartphone.UsageResourcePolicy.ENABLED:
                enable();
                break;
            case FreeSmartphone.UsageResourcePolicy.AUTO:
                if ( users.size > 0 )
                    enable();
                else
                    disable();
                break;
            default:
                assert_not_reached();
        }

        updateStatus();
    }

    public void addUser( string user ) throws FreeSmartphone.UsageError
    {
        if ( user in users )
            throw new FreeSmartphone.UsageError.USER_EXISTS( "Resource %s already requested by user %s".printf( name, user ) );

        if ( policy == FreeSmartphone.UsageResourcePolicy.DISABLED )
            throw new FreeSmartphone.UsageError.POLICY_DISABLED( "Resource %s cannot be requested by %s per policy".printf( name, user ) );

        users.insert( 0, user );

        if ( policy == FreeSmartphone.UsageResourcePolicy.AUTO && users.size == 1 )
            enable();

        updateStatus();
    }

    public void delUser( string user ) throws FreeSmartphone.UsageError
    {
        if ( !(user in users) )
            throw new FreeSmartphone.UsageError.USER_UNKNOWN( "Resource %s never been requested by user %s".printf( name, user ) );

        users.remove( user );

        if ( policy == FreeSmartphone.UsageResourcePolicy.AUTO && users.size == 0 )
            disable();

        updateStatus();
    }

    public string[] allUsers()
    {
        string[] res = {};
        foreach ( var user in users )
            res += user;
        return res;
    }

    public void enable() throws FreeSmartphone.ResourceError, DBus.Error
    {
        try
        {
            proxy.enable();
            status = ResourceStatus.ENABLED;
            updateStatus();
        }
        catch ( DBus.Error e )
        {
            instance.logger.error( "Resource %s can't be enabled: %s. Trying to disable instead".printf( name, e.message ) );
            proxy.disable();
            throw e;
        }
    }

    public void disable() throws FreeSmartphone.ResourceError, DBus.Error
    {
        try
        {
            proxy.disable();
            status = ResourceStatus.DISABLED;
        }
        catch ( DBus.Error e )
        {
            instance.logger.error( "Resource %s can't be disabled: %s. Setting status to UNKNOWN".printf( name, e.message ) );
            status = ResourceStatus.UNKNOWN;
            throw e;
        }
    }

    public void suspend() throws FreeSmartphone.ResourceError, DBus.Error
    {
        if ( status == ResourceStatus.ENABLED )
        {
            try
            {
                proxy.suspend();
                status = ResourceStatus.SUSPENDED;
            }
            catch ( DBus.Error e )
            {
                instance.logger.error( "Resource %s can't be suspended: %s. Trying to disable instead".printf( name, e.message ) );
                proxy.disable();
                throw e;
            }
        }
        else
        {
            instance.logger.debug( "Resource %s not enabled: not suspending".printf( name ) );
        }
    }

    public void resume() throws FreeSmartphone.ResourceError, DBus.Error
    {
        if ( status == ResourceStatus.SUSPENDED )
        {
            try
            {
                proxy.resume();
                status = ResourceStatus.ENABLED;
            }
            catch ( DBus.Error e )
            {
                instance.logger.error( "Resource %s can't be resumed: %s. Trying to disable instead".printf( name, e.message ) );
                proxy.disable();
                throw e;
            }
        }
        else
        {
            instance.logger.debug( "Resource %s not suspended: not resuming".printf( name ) );
        }
    }
}

/**
 * Controller class implementing org.freesmartphone.Usage API
 *
 * Note: Unfortunately we can't just use libfso-glib (FreeSmartphone.Usage interface)
 * here, since we need access to the dbus sender name (which modifies the interface signature).
 **/
[DBus (name = "org.freesmartphone.Usage")]
public class Controller : FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;
    private HashMap<string,Resource> resources;
    private string sys_power_state;
    private bool do_not_suspend;

    dynamic DBus.Object dbus;

    public Controller( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;

        resources = new HashMap<string,Resource>( str_hash, str_equal, str_equal );

        this.subsystem.registerServiceName( FsoFramework.Usage.ServiceDBusName );
        this.subsystem.registerServiceObject( FsoFramework.Usage.ServiceDBusName,
                                              FsoFramework.Usage.ServicePathPrefix, this );

        // grab sysfs paths
        var sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
        sys_power_state = Path.build_filename( sysfs_root, "power", "state" );
        do_not_suspend = config.boolValue( CONFIG_SECTION, "do_not_suspend", false );

        // start listening for name owner changes
        dbusconn = ( (FsoFramework.DBusSubsystem)subsystem ).dbusConnection();
        dbus = dbusconn.get_object( DBUS_BUS_NAME, DBUS_BUS_PATH, DBUS_BUS_INTERFACE );
        dbus.NameOwnerChanged += onNameOwnerChanged;
    }

    public override string repr()
    {
        return "<%s>".printf( FsoFramework.Usage.ServicePathPrefix );
    }

    private void onResourceAppearing( Resource r )
    {
        logger.debug( "Resource %s served by %s @ %s has just been registered".printf( r.name, r.busname, r.objectpath ) );
        this.resource_available( r.name, true ); // DBUS SIGNAL

        // initial status is disabled
        try
        {
            r.disable();
        }
        catch ( FreeSmartphone.ResourceError e )
        {
            logger.warning( "Error while trying to (initially) disable resource %s: %s".printf( r.name, e.message ) );
        }
        catch ( DBus.Error e )
        {
            logger.warning( "Error while trying to (initially) disable resource %s: %s".printf( r.name, e.message ) );
        }
    }

    private void onResourceVanishing( Resource r )
    {
        logger.debug( "Resource %s served by %s @ %s has just been unregistered".printf( r.name, r.busname, r.objectpath ) );
        this.resource_available( r.name, false ); // DBUS SIGNAL

        try
        {
            r.disable();
        }
        catch ( FreeSmartphone.ResourceError e )
        {
            logger.warning( "Error while trying to (initially) disable resource %s: %s".printf( r.name, e.message ) );
        }
        catch ( DBus.Error e )
        {
            logger.warning( "Error while trying to (finally) disable resource %s: %s".printf( r.name, e.message ) );
        }
    }

    private void onNameOwnerChanged( dynamic DBus.Object obj, string name, string oldowner, string newowner )
    {
        //message( "name owner changed: %s (%s => %s)", name, oldowner, newowner );
        // we're only interested in services disappearing
        if ( newowner != "" )
            return;

        logger.debug( "%s disappeared. checking whether resources are affected...".printf( name ) );

        //FIXME: Consider keeping the known busnames in a map as well, so we don't have to iterate through all values
        foreach ( var r in resources.get_values() )
        {
            // first, check whether the resource provider might have vanished
            if ( r.busname == name )
            {
                onResourceVanishing( r );
                resources.remove( r.name );
            }
            // second, check whether it was one of the users
            else
            {
                if ( r.hasUser( name ) )
                {
                    r.delUser( name );
                }
            }
        }
    }

    private bool onIdleForSuspend()
    {
        suspendAllResources();
        logger.debug( ">>>>>>> KERNEL SUSPEND" );
        if ( !do_not_suspend )
            FsoFramework.FileHandling.write( "mem\n", sys_power_state );
        else
            Posix.sleep( 5 );
        logger.debug( "<<<<<<< KERNEL RESUME" );
        resumeAllResources();
        this.system_action( FreeSmartphone.UsageSystemAction.RESUME ); // DBUS SIGNAL
        return false; // MainLoop: Don't call again
    }

    private Resource getResource( string name ) throws FreeSmartphone.UsageError
    {
        Resource r = resources[name];
        if ( r == null )
            throw new FreeSmartphone.UsageError.RESOURCE_UNKNOWN( "Resource %s had never been registered".printf( name ) );

        logger.debug( "current users for %s = %s".printf( r.name, FsoFramework.StringHandling.stringListToString( r.allUsers() ) ) );

        return r;
    }

    private void disableAllResources()
    {
        foreach ( var r in resources.get_values() )
        {
            try
            {
                r.disable();
            }
            catch ( FreeSmartphone.ResourceError e )
            {
                logger.warning( "Error while trying to suspend resource %s: %s".printf( r.name, e.message ) );
            }
            catch ( DBus.Error e )
            {
                logger.warning( "Error while trying to disable resource %s: %s".printf( r.name, e.message ) );
            }
        }
    }

    private void suspendAllResources()
    {
        foreach ( var r in resources.get_values() )
        {
            try
            {
                r.suspend();
            }
            catch ( FreeSmartphone.ResourceError e )
            {
                logger.warning( "Error while trying to suspend resource %s: %s".printf( r.name, e.message ) );
            }
            catch ( DBus.Error e )
            {
                logger.warning( "Error while trying to suspend resource %s: %s".printf( r.name, e.message ) );
            }
        }
    }

    private void resumeAllResources()
    {
        foreach ( var r in resources.get_values() )
        {
            try
            {
                r.resume();
            }
            catch ( FreeSmartphone.ResourceError e )
            {
                logger.warning( "Error while trying to suspend resource %s: %s".printf( r.name, e.message ) );
            }
            catch ( DBus.Error e )
            {
                logger.warning( "Error while trying to resume resource %s: %s".printf( r.name, e.message ) );
            }
        }
    }

    //
    // DBUS API (for providers)
    //
    public void register_resource( DBus.BusName sender, string name, DBus.ObjectPath path ) throws FreeSmartphone.UsageError, DBus.Error
    {
        message( "register_resource called with parameters: %s %s %s", sender, name, path );
        if ( name in resources )
            throw new FreeSmartphone.UsageError.RESOURCE_EXISTS( "Resource %s already registered".printf( name ) );

        var r = new Resource( name, sender, path );
        resources[name] = r;

        onResourceAppearing( r );
    }

    public void unregister_resource( DBus.BusName sender, string name ) throws FreeSmartphone.UsageError, DBus.Error
    {
        var r = getResource( name );

        if ( r.busname != sender )
            throw new FreeSmartphone.UsageError.RESOURCE_UNKNOWN( "Resource %s not yours".printf( name ) );

        onResourceVanishing( r );

        resources.remove( name );
    }

    //
    // DBUS API (for consumers)
    //
    //public FreeSmartphone.UsageResourcePolicy get_resource_policy( string name ) throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBus.Error
    public string get_resource_policy( string name ) throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBus.Error
    {
        switch ( getResource( name ).policy )
        {
            case FreeSmartphone.UsageResourcePolicy.ENABLED:
                return "enabled";
            case FreeSmartphone.UsageResourcePolicy.DISABLED:
                return "disabled";
            case FreeSmartphone.UsageResourcePolicy.AUTO:
                return "auto";
            default:
                var error = "unknown resource policy value %d for resource %s".printf( getResource( name ).policy, name );
                logger.error( error );
                throw new FreeSmartphone.Error.INTERNAL_ERROR( error );
        }
    }

    //public void set_resource_policy( string name, FreeSmartphone.UsageResourcePolicy policy ) throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBus.Error
    public void set_resource_policy( string name, string policy ) throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBus.Error
    {
        message( "set resource policy for %s to %s", name, policy );

        if ( policy == "enabled" )
            getResource( name ).setPolicy( FreeSmartphone.UsageResourcePolicy.ENABLED );
        else if ( policy == "disabled" )
            getResource( name ).setPolicy( FreeSmartphone.UsageResourcePolicy.DISABLED );
        else if ( policy == "auto" )
            getResource( name ).setPolicy( FreeSmartphone.UsageResourcePolicy.AUTO );
        else
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "ResourcePolicy needs to be one of { \"enabled\", \"disabled\", \"auto\" }" );
    }

    public bool get_resource_state( string name ) throws FreeSmartphone.UsageError, DBus.Error
    {
        return getResource( name ).isEnabled();
    }

    public string[] get_resource_users( string name ) throws FreeSmartphone.UsageError, DBus.Error
    {
        return getResource( name ).allUsers();
    }

    public string[] list_resources() throws DBus.Error
    {
        string[] res = {};
        foreach ( var key in resources.get_keys() )
            res += key;
        return res;
    }

    public void request_resource( DBus.BusName sender, string name ) throws FreeSmartphone.UsageError, DBus.Error
    {
        getResource( name ).addUser( sender );
    }

    public void release_resource( DBus.BusName sender, string name ) throws FreeSmartphone.UsageError, DBus.Error
    {
        getResource( name ).delUser( sender );
    }

    public void shutdown() throws DBus.Error
    {
        this.system_action( FreeSmartphone.UsageSystemAction.SHUTDOWN ); // DBUS SIGNAL
        disableAllResources();
        Posix.system( "shutdown -h now" );
    }

    public void reboot() throws DBus.Error
    {
        this.system_action( FreeSmartphone.UsageSystemAction.REBOOT ); // DBUS SIGNAL
        disableAllResources();
        Posix.system( "reboot" );
    }

    public void suspend() throws DBus.Error
    {
        this.system_action( FreeSmartphone.UsageSystemAction.SUSPEND ); // DBUS SIGNAL
        // we need to suspend async, otherwise the dbus call would timeout
        Idle.add( onIdleForSuspend );
    }

    // DBUS SIGNALS
    public signal void resource_available( string name, bool availability );
    public signal void resource_changed( string name, bool state, GLib.HashTable<string,GLib.Value?> attributes );
    public signal void system_action( FreeSmartphone.UsageSystemAction action );
}

} /* end namespace */

Usage.Controller instance;
DBus.Connection dbusconn;

public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    instance = new Usage.Controller( subsystem );
    return "fsousage.controller";
}



[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "usage controller fso_register_function()" );
}
