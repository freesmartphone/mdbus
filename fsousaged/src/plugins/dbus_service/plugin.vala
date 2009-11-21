/**
 * Resource Controller DBus Service
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

internal const string RESOURCE_INTERFACE = "org.freesmartphone.Resource";
internal const string CONFIG_SECTION = "fsousage";
internal const string DEFAULT_LOWLEVEL_MODULE = "kernel26";

internal const string FSO_IDLENOTIFIER_BUS   = "org.freesmartphone.odeviced";
internal const string FSO_IDLENOTIFIER_PATH  = "/org/freesmartphone/Device/IdleNotifier/0";
internal const string FSO_IDLENOTIFIER_IFACE = "org.freesmartphone.Device.IdleNotifier";

namespace Usage {

/**
 * Serialized state class
 *
 * All properties here will be saved on forced shutdown
 **/
public class PersistentData : Object
{
    public HashMap<string,Resource> resources { get; set; }

    construct
    {
        resources = new HashMap<string,Resource>( str_hash, str_equal, str_equal );
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

    private FsoUsage.LowLevel lowlevel;
    private bool debug_do_not_suspend;
    private bool debug_enable_on_startup;
    private bool disable_on_startup;
    private bool disable_on_shutdown;

    private PersistentData data;
    private HashMap<string,Resource> resources;

    dynamic DBus.Object dbus;
    dynamic DBus.Object idlenotifier;

    public Controller( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;

        this.subsystem.registerServiceName( FsoFramework.Usage.ServiceDBusName );
        this.subsystem.registerServiceObject( FsoFramework.Usage.ServiceDBusName,
                                              FsoFramework.Usage.ServicePathPrefix, this );

        // debug option: should we really suspend?
        debug_do_not_suspend = config.boolValue( CONFIG_SECTION, "debug_do_not_suspend", false );
        // debug option: should we enable on startup?
        debug_enable_on_startup = config.boolValue( CONFIG_SECTION, "debug_enable_on_startup", false );

        var sync_resources_with_lifecycle = config.stringValue( CONFIG_SECTION, "sync_resources_with_lifecycle", "always" );
        disable_on_startup = ( sync_resources_with_lifecycle == "always" || sync_resources_with_lifecycle == "startup" );
        disable_on_shutdown = ( sync_resources_with_lifecycle == "always" || sync_resources_with_lifecycle == "shutdown" );

        // start listening for name owner changes
        dbusconn = ( (FsoFramework.DBusSubsystem)subsystem ).dbusConnection();
        dbus = dbusconn.get_object( DBus.DBUS_SERVICE_DBUS, DBus.DBUS_PATH_DBUS, DBus.DBUS_INTERFACE_DBUS );
        dbus.NameOwnerChanged += onNameOwnerChanged;

        // get handle to IdleNotifier
        idlenotifier = dbusconn.get_object( FSO_IDLENOTIFIER_BUS, FSO_IDLENOTIFIER_PATH, FSO_IDLENOTIFIER_IFACE );

        // init resources and low level helpers
        initResources();
        initLowlevel();
    }

    public override string repr()
    {
        return @"<$(resources.size) resources>";
    }

#if PERSISTENCE
    private void syncResourcesAndUsers()
    {
        // for ever resource, we check whether it's still present, and if so,
        // whether any of the consumers might have disappeared meanwhile
        var resourcesToRemove = new Gee.HashSet<Resource>();

        foreach ( var r in resources.values )
        {
            if ( !r.isPresent() )
            {
                resourcesToRemove.add( r );
            }
        }
        foreach ( var r in resourcesToRemove )
        {
            resources.remove( r.name );
            this.resource_available( r.name, false ); // DBUS SIGNAL
        }

        foreach ( var r in resources.values )
        {
            r.syncUsers();
        }
    }
#endif

    private void initLowlevel()
    {
        // check preferred low level suspend/resume plugin and instanciate
        var lowleveltype = config.stringValue( CONFIG_SECTION, "lowlevel_type", DEFAULT_LOWLEVEL_MODULE );
        string typename = "none";

        switch ( lowleveltype )
        {
            case "kernel26":
                typename = "LowLevelKernel26";
                break;
            case "openmoko":
                typename = "LowLevelOpenmoko";
                break;
            default:
                warning( "Invalid lowlevel_type '%s'; suspend/resume will NOT be available!".printf( lowleveltype ) );
                lowlevel = new FsoUsage.NullLowLevel();
                return;
        }

        if ( lowleveltype != "none" )
        {
            var lowlevelclass = Type.from_name( typename );
            if ( lowlevelclass == Type.INVALID  )
            {
                logger.warning( "Can't find plugin for lowlevel_type = '%s'; suspend/resume will NOT be available!".printf( lowleveltype ) );
                lowlevel = new FsoUsage.NullLowLevel();
                return;
            }

            lowlevel = Object.new( lowlevelclass ) as FsoUsage.LowLevel;
            logger.info( "Ready. Using lowlevel plugin '%s' to handle suspend/resume".printf( lowleveltype ) );
        }
    }

    public void initResources()
    {
#if PERSISTENCE
        // check whether we have crash data
        if ( loadPersistentData() )
        {
            resources = data.resources;
            syncResourcesAndUsers();
        }
        else
#endif
        {
            data = new PersistentData();
            //data.resources = new HashMap<string,Resource>( str_hash, str_equal );
            resources = data.resources;
        }
        assert( resources != null );
    }

    private void onResourceAppearing( Resource r )
    {
        assert( logger.debug( "Resource %s served by %s @ %s has just been registered".printf( r.name, r.busname, r.objectpath ) ) );
        this.resource_available( r.name, true ); // DBUS SIGNAL

        if ( debug_enable_on_startup )
        {
            try
            {
                r.enable();
            }
            catch ( FreeSmartphone.ResourceError e )
            {
                logger.warning( "Error while trying to (initially) enable resource %s: %s".printf( r.name, e.message ) );
            }
            catch ( DBus.Error e )
            {
                logger.warning( "Error while trying to (initially) enable resource %s: %s".printf( r.name, e.message ) );
            }
        }

        if ( disable_on_startup )
        {
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
    }

    private void onResourceVanishing( Resource r )
    {
        assert( logger.debug( "Resource %s served by %s @ %s has just been unregistered".printf( r.name, r.busname, r.objectpath ) ) );
        this.resource_available( r.name, false ); // DBUS SIGNAL

#if WHY_TRYING_TO_DISABLE_A_VANISHED_RESOURCE
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
#endif

        //resources.remove( r.name );
    }

    private void onNameOwnerChanged( dynamic DBus.Object obj, string name, string oldowner, string newowner )
    {
        //message( "name owner changed: %s (%s => %s)", name, oldowner, newowner );
        // we're only interested in services disappearing
        if ( newowner != "" )
            return;

        assert( logger.debug( "%s disappeared. checking whether resources are affected...".printf( name ) ) );

        //FIXME: Consider keeping the known busnames in a map as well, so we don't have to iterate through all values

        var resourcesToRemove = new Gee.HashSet<Resource>();

        foreach ( var r in resources.values )
        {
            // first, check whether the resource provider might have vanished
            if ( r.busname == name )
            {
                onResourceVanishing( r );
                resourcesToRemove.add( r );
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
        foreach ( var r in resourcesToRemove )
        {
            resources.remove( r.name );
        }
    }

    private bool onIdleForShutdown()
    {
        Posix.system( "shutdown -now " );
        return true;
    }

    private bool onIdleForReboot()
    {
        Posix.system( "reboot" );
        return true;
    }

    private bool onIdleForSuspend()
    {
        logger.info( ">>>>>>> KERNEL SUSPEND" );

        var resourcesAlive = 0;
        foreach ( var r in resources.values )
        {
            if ( ( r.status != ResourceStatus.SUSPENDED ) && ( r.status != ResourceStatus.DISABLED ) )
            {
                logger.warning( "Resource $(r.name) is not suspended nor disabled" );
                resourcesAlive++;
            }
        }
        if ( resourcesAlive > 0 )
        {
            logger.error( "%d resources still alive :( Aborting Suspend!" );
            return false;
        }

        if ( !debug_do_not_suspend )
        {
            lowlevel.suspend();
        }
        else
        {
            Posix.sleep( 5 );
        }
        logger.info( "<<<<<<< KERNEL RESUME" );

        FsoUsage.ResumeReason reason = lowlevel.resume();
        logger.info( "Resume reason seems to be %s".printf( FsoFramework.StringHandling.enumToString( typeof( FsoUsage.ResumeReason ), reason) ) );
        resumeAllResources();
        this.system_action( FreeSmartphone.UsageSystemAction.RESUME ); // DBUS SIGNAL

        var idlestate = lowlevel.isUserInitiated( reason ) ? "busy" : "idle";
        try
        {
            idlenotifier.SetState( idlestate );
        }
        catch ( DBus.Error e )
        {
            logger.error( "DBus Error while talking to IdleNotifier: %s".printf( e.message ) );
        }
        return false; // MainLoop: Don't call again
    }

    private Resource getResource( string name ) throws FreeSmartphone.UsageError
    {
        Resource r = resources[name];
        if ( r == null )
            throw new FreeSmartphone.UsageError.RESOURCE_UNKNOWN( "Resource %s had never been registered".printf( name ) );

        assert( logger.debug( "current users for %s = %s".printf( r.name, FsoFramework.StringHandling.stringListToString( r.allUsers() ) ) ) );

        return r;
    }

    private async void disableAllResources()
    {
        assert( logger.debug( "Disabling all resources..." ) );
        foreach ( var r in resources.values )
        {
            try
            {
                yield r.disable();
            }
            catch ( FreeSmartphone.ResourceError e1 )
            {
                logger.warning( "Error while trying to suspend resource %s: %s".printf( r.name, e1.message ) );
            }
            catch ( DBus.Error e2 )
            {
                logger.warning( "Error while trying to disable resource %s: %s".printf( r.name, e2.message ) );
            }
        }
        assert( logger.debug( "... done" ) );
    }

    private async void suspendAllResources()
    {
        assert( logger.debug( "Suspending all resources..." ) );
        foreach ( var r in resources.values )
        {
            try
            {
                yield r.suspend();
            }
            catch ( FreeSmartphone.ResourceError e1 )
            {
                logger.warning( "Error while trying to suspend resource %s: %s".printf( r.name, e1.message ) );
            }
            catch ( DBus.Error e2 )
            {
                logger.warning( "Error while trying to suspend resource %s: %s".printf( r.name, e2.message ) );
            }
        }
        assert( logger.debug( "... done disabling." ) );
    }

    private async void resumeAllResources()
    {
        assert( logger.debug( "Resuming all resources..." ) );
        foreach ( var r in resources.values )
        {
            try
            {
                yield r.resume();
            }
            catch ( FreeSmartphone.ResourceError e1 )
            {
                logger.warning( "Error while trying to suspend resource %s: %s".printf( r.name, e1.message ) );
            }
            catch ( DBus.Error e2 )
            {
                logger.warning( "Error while trying to resume resource %s: %s".printf( r.name, e2.message ) );
            }
        }
        assert( logger.debug( "... done resuming." ) );
    }

#if PERSISTENCE
    // not public, since we don't want to expose it via dbus
    internal void savePersistentData()
    {
        logger.info( "Saving resource status to file..." );
        var file = File.new_for_path( "/tmp/serialize.output" );
        var stream = file.replace( null, false, FileCreateFlags.NONE, null );
        Persistence.JsonTypeSerializer.instance().ignoreUnknown = true;
        var serializer = new Persistence.JsonSerializer( stream );
        serializer.serialize_object( data );
    }

    internal bool loadPersistentData()
    {
        var file = File.new_for_path( "/tmp/serialize.output" );
        if ( !file.query_exists( null ) )
        {
            return false;
        }
        var stream = file.read( null );
        Persistence.JsonTypeSerializer.instance().ignoreUnknown = true;
        var deserializer = new Persistence.JsonDeserializer<PersistentData>( stream );
        data = deserializer.deserialize_object() as PersistentData;
        return true;
    }
#endif

    //
    // DBUS API (for providers)
    //
    public void register_resource( DBus.BusName sender, string name, DBus.ObjectPath path ) throws FreeSmartphone.UsageError, DBus.Error
    {
        message( "register_resource called with parameters: %s %s %s", sender, name, path );
        if ( name in resources.keys )
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

    internal void shutdownPlugin()
    {
        if ( disable_on_shutdown )
        {
            disableAllResources();
        }
    }


    //
    // DBUS API (for consumers)
    //
    //public FreeSmartphone.UsageResourcePolicy get_resource_policy( string name ) throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBus.Error
    public async string get_resource_policy( string name ) throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBus.Error
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
    public async void set_resource_policy( string name, string policy ) throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBus.Error
    {
        logger.debug( @"Set resource policy for $name to $policy" );
        var resource = getResource( name );

        switch ( policy )
        {
            case "enabled":
                yield resource.setPolicy( FreeSmartphone.UsageResourcePolicy.ENABLED );
                break;
            case "disabled":
                yield resource.setPolicy( FreeSmartphone.UsageResourcePolicy.DISABLED );
                break;
            case "auto":
                yield resource.setPolicy( FreeSmartphone.UsageResourcePolicy.AUTO );
                break;
            default:
                throw new FreeSmartphone.Error.INVALID_PARAMETER( "ResourcePolicy needs to be one of { \"enabled\", \"disabled\", \"auto\" }" );
                break;
        }
    }

    public async bool get_resource_state( string name ) throws FreeSmartphone.UsageError, DBus.Error
    {
        return getResource( name ).isEnabled();
    }

    public async string[] get_resource_users( string name ) throws FreeSmartphone.UsageError, DBus.Error
    {
        return getResource( name ).allUsers();
    }

    public async string[] list_resources() throws DBus.Error
    {
        string[] res = {};
        foreach ( var key in resources.keys )
            res += key;
        return res;
    }

    public async void request_resource( DBus.BusName sender, string name ) throws FreeSmartphone.UsageError, DBus.Error
    {
        var resource = getResource( name );
        yield resource.addUser( sender );
    }

    public async void release_resource( DBus.BusName sender, string name ) throws FreeSmartphone.UsageError, DBus.Error
    {
        var resource = getResource( name );
        yield resource.delUser( sender );
    }

    public async void shutdown() throws DBus.Error
    {
        this.system_action( FreeSmartphone.UsageSystemAction.SHUTDOWN ); // DBUS SIGNAL
        yield disableAllResources();
        Idle.add( onIdleForShutdown );
    }

    public async void reboot() throws DBus.Error
    {
        this.system_action( FreeSmartphone.UsageSystemAction.REBOOT ); // DBUS SIGNAL
        yield disableAllResources();
        Idle.add( onIdleForReboot );
    }

    public async void suspend() throws DBus.Error
    {
        this.system_action( FreeSmartphone.UsageSystemAction.SUSPEND ); // DBUS SIGNAL
        yield suspendAllResources();
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
    return "fsousage.dbus_service";
}

public static void fso_shutdown_function()
{
#if PERSISTENCE
    instance.savePersistentData();
#endif
    instance.shutdownPlugin();
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "usage dbus_service fso_register_function()" );
}
