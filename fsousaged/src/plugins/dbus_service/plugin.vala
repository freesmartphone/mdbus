/*
 * FSO Resource Controller DBus Service
 *
 * (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *               Simon Busch <morphis@gravedo.de>
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

internal const string FSO_DBUS_RESOURCE_PROVIDER_SECTION = "D-BUS Service";
internal const string FSO_DBUS_RESOURCE_PROVIDER_KEY = "FSO-provides-resource";

namespace Usage {

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

    private bool debug_enable_on_startup;
    private bool debug_do_not_suspend;
    private bool debug_suspend_user_initiated;
    private bool disable_on_startup;
    private bool disable_on_shutdown;
    private bool wakelock_support;

    private HashMap<string,Resource> resources = new HashMap<string,Resource>( str_hash, str_equal );

    private DBusService.IDBus dbus;
    private FreeSmartphone.Device.IdleNotifier idlenotifier;
    private FreeSmartphone.UsageSystemAction system_status;

    public Controller( FsoFramework.Subsystem subsystem )
    {
        this.system_status = (FreeSmartphone.UsageSystemAction) 12345; // UNKNOWN
        this.subsystem = subsystem;
        this.subsystem.registerObjectForService<Controller>( FsoFramework.Usage.ServiceDBusName, FsoFramework.Usage.ServicePathPrefix, this );

        // debug option: should we enable on startup?
        debug_enable_on_startup = config.boolValue( CONFIG_SECTION, "debug_enable_on_startup", false );
        debug_do_not_suspend = config.boolValue( CONFIG_SECTION, "debug_do_not_suspend", false );
        debug_suspend_user_initiated = config.boolValue( CONFIG_SECTION, "debug_suspend_user_initiated", true );

        wakelock_support = config.boolValue( CONFIG_SECTION, "wakelock_support", false );
        if ( wakelock_support )
            logger.info( @"Running with wakelock support enabled" );

        var sync_resources_with_lifecycle = config.stringValue( CONFIG_SECTION, "sync_resources_with_lifecycle", "always" );
        disable_on_startup = ( sync_resources_with_lifecycle == "always" || sync_resources_with_lifecycle == "startup" );
        disable_on_shutdown = ( sync_resources_with_lifecycle == "always" || sync_resources_with_lifecycle == "shutdown" );

        try
        {
            // start listening for name owner changes
            dbus = Bus.get_proxy_sync<DBusService.IDBus>( BusType.SYSTEM, DBusService.DBUS_SERVICE_DBUS,
                DBusService.DBUS_PATH_DBUS );
            dbus.NameOwnerChanged.connect( onNameOwnerChanged );
        }
        catch ( GLib.Error err0 )
        {
            logger.critical( @"Can't setup up dbus connection for listener of name ownr changes: $(err0.message)" );
        }

        try
        {
            // get handle to IdleNotifier, don't autostart process
            idlenotifier = Bus.get_proxy_sync<FreeSmartphone.Device.IdleNotifier>( BusType.SYSTEM,
                FSO_IDLENOTIFIER_BUS, FSO_IDLENOTIFIER_PATH, DBusProxyFlags.DO_NOT_AUTO_START );
        }
        catch ( GLib.Error err1 )
        {
            logger.error( @"Can't get a dbus connection for the idle notifier. Will lack functionality ..." );
        }

        // init resources and low level helpers
        initResources();
        initLowlevel();

        var useShadowing = config.boolValue( CONFIG_SECTION, "enable_shadow_resources", false );
        if ( useShadowing )
        {
            scanForResourceProviders();
        }

        // initial status
        Idle.add( () => {
            updateSystemStatus( FreeSmartphone.UsageSystemAction.ALIVE );
            return false;
        } );
    }

    public override string repr()
    {
        return @"<$(resources.size) R>";
    }

    private void initResources()
    {
        resources.clear();
    }

    /**
     * Create the lowlevel handler as configuration requests.
     **/
    private void initLowlevel()
    {
        // check preferred low level suspend/resume plugin and instanciate
        var lowleveltype = config.stringValue( CONFIG_SECTION, "lowlevel_type", DEFAULT_LOWLEVEL_MODULE );
        string typename = "none";

        switch ( lowleveltype )
        {
            case "android":
                typename = "LowLevelAndroid";
                break;
            case "kernel26":
                typename = "LowLevelKernel26";
                break;
            case "kernel26_staysalive":
                typename = "LowLevelKernel26_StaysAlive";
                break;
            case "openmoko":
                typename = "LowLevelOpenmoko";
                break;
            default:
                logger.warning( @"Invalid lowlevel_type $lowleveltype; suspend/resume will NOT be available!" );
                lowlevel = new FsoUsage.NullLowLevel();
                return;
        }

        if ( lowleveltype != "none" )
        {
            var lowlevelclass = Type.from_name( typename );
            if ( lowlevelclass == Type.INVALID  )
            {
                logger.warning( @"Can't find plugin for lowlevel_type $lowleveltype; suspend/resume will NOT be available!" );
                lowlevel = new FsoUsage.NullLowLevel();
                return;
            }

            lowlevel = Object.new( lowlevelclass ) as FsoUsage.LowLevel;
            logger.info( @"Ready. Using lowlevel plugin $lowleveltype to handle suspend/resume" );
        }
    }

    /**
     * Search for shadow resource providers in the dbus system service dir. Each entry as
     * a FSO-provides-resources entry if it provides a resource.
     **/
    private void scanForResourceProviders()
    {
        assert( logger.debug( @"Scanning for resource providers in $(Config.DBUS_SYSTEM_SERVICE_DIR)" ) );

        try
        {
            var dir = GLib.Dir.open( Config.DBUS_SYSTEM_SERVICE_DIR );

            for ( var name = dir.read_name(); name != null; name = dir.read_name() )
            {
                if ( name.has_suffix( ".service" ) )
                {
                    var smk = new FsoFramework.SmartKeyFile();
                    if ( smk.loadFromFile( GLib.Path.build_filename( Config.DBUS_SYSTEM_SERVICE_DIR, name ) ) )
                    {
                        var fsoresources = smk.stringListValue( FSO_DBUS_RESOURCE_PROVIDER_SECTION, FSO_DBUS_RESOURCE_PROVIDER_KEY, {} );
                        if ( fsoresources.length > 0 )
                        {
                            foreach ( var resource in fsoresources )
                            {
                                assert( logger.debug( @"Service $name claims to provide FSO resource $resource" ) );
                                if ( resource in resources.keys )
                                {
                                    assert( logger.debug( @"Skipping resource $resource which has already been registered" ) );
                                }
                                else
                                {
                                    var r = new Resource( resource, new GLib.BusName( name.replace( ".service", "" ) ), null ); // register as shadow resource
                                    resources[resource] = r;
                                }
                            }
                        }
                        else
                        {
                            assert( logger.debug( @"Service $name does not provide any FSO resources" ) );
                        }
                    }
                }
            }
        }
        catch ( GLib.Error error )
        {
            logger.error( @"Could not detect all shadow resources from service configuration files: $(error.message)" );
        }
    }

    /**
     * Handle a resource appearing on the bus. This will send out a notification and
     * enable or disables the resource depending on which debug option is set.
     **/
    private async void onResourceAppearing( Resource r )
    {
        assert( logger.debug( @"Resource $(r.name) served by $(r.busname) @ $(r.objectpath) has just been registered" ) );
        this.resource_available( r.name, true ); // DBUS SIGNAL

        if ( debug_enable_on_startup )
        {
            try
            {
                yield r.enable();
            }
            catch ( Error e0 )
            {
                logger.warning( @"Error while trying to (initially) enable resource $(r.name): $(e0.message)" );
            }
        }

        if ( disable_on_startup )
        {
            // initial status is disabled
            try
            {
                yield r.disable();
            }
            catch ( Error e1 )
            {
                logger.warning( @"Error while trying to (initially) disable resource $(r.name): $(e1.message)" );
            }
        }
    }

    /**
     * When a resource is not available on the bus any longer we need to tell this all our
     * connected clients with sending out a notification.
     **/
    private void onResourceVanishing( Resource r )
    {
        assert( logger.debug( @"Resource $(r.name) served by $(r.busname) @ $(r.objectpath) has just been unregistered" ) );
        this.resource_available( r.name, false ); // DBUS SIGNAL
    }

    /**
     * Implements handling of new and old bus owners. If a new owner arrives on a bus we
     * need to handle this when it provides a resource and vice versa if a owner leaves
     * its bus.
     **/
    private void onNameOwnerChanged( string name, string oldowner, string newowner )
    {
#if DEBUG
        debug( "name owner changed: %s (%s => %s)", name, oldowner, newowner );
#endif
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
            resources.unset( r.name );
        }
    }

    /**
     * When suspend command is issued this will handle the suspend and resume process
     * itself by calling into the lowlevel handler and processing the resource handling.
     **/
    internal bool onIdleForSuspend()
    {
        var resourcesAlive = 0;
        var idleState = FreeSmartphone.Device.IdleState.BUSY;
        var reason = FsoUsage.ResumeReason.Invalid;
        bool user_initiated = false;

        foreach ( var r in resources.values )
        {
            // We also have to check for resources with the UNKNOWN status as when
            // we're using shadow resources they have UNKNOWN as status until they
            // get enabled.
            if ( ( r.status != FsoFramework.ResourceStatus.SUSPENDED ) &&
                 ( r.status != FsoFramework.ResourceStatus.DISABLED ) &&
                 ( r.status != FsoFramework.ResourceStatus.UNKNOWN) )
            {
                logger.warning( @"Resource $(r.name) is not suspended nor disabled" );
                resourcesAlive++;
            }
        }
        if ( resourcesAlive > 0 )
        {
            logger.error( @"$resourcesAlive resources still alive :( Aborting Suspend!" );
            return false;
        }

        if ( !debug_do_not_suspend )
        {
            logger.info( "Entering lowlevel suspend" );
            lowlevel.suspend();

            if ( !wakelock_support )
            {
                logger.info( "Leaving lowlevel suspend" );
                reason = lowlevel.resume();
                logger.info( @"Resume reason seems to be $reason" );
            }
        }
        else
        {
            logger.info( @"Not suspending due to configuration. System will stay in SUSPEND mode." );
        }

        if ( !wakelock_support )
        {
            resumeAllResources();

            instance.updateSystemStatus( FreeSmartphone.UsageSystemAction.RESUME );

            if ( !debug_do_not_suspend )
            {
                user_initiated = lowlevel.isUserInitiated( reason );
            }
            else
            {
                user_initiated = debug_suspend_user_initiated;
            }

            idleState = user_initiated ? FreeSmartphone.Device.IdleState.BUSY : FreeSmartphone.Device.IdleState.LOCK;
            assert( logger.debug( @"Resume is initiated by the user: $(user_initiated); switching to $(idleState) idle state ..." ) );
            updateIdleState( idleState );

            instance.updateSystemStatus( FreeSmartphone.UsageSystemAction.ALIVE );
        }

        return false; // MainLoop: Don't call again
    }

    internal bool onIdleForResume()
    {
        // when we're running without wakelock support things are much easier
        if ( !wakelock_support )
        {
            resumeAllResources();
            return false;
        }

        var idleState = FreeSmartphone.Device.IdleState.BUSY;
        var reason = FsoUsage.ResumeReason.Invalid;
        bool user_initiated = false;

        reason = lowlevel.resume();
        resumeAllResources();

        user_initiated = lowlevel.isUserInitiated( reason );
        if ( debug_do_not_suspend )
            user_initiated = debug_suspend_user_initiated;

        idleState = user_initiated ? FreeSmartphone.Device.IdleState.BUSY : FreeSmartphone.Device.IdleState.LOCK;
        assert( logger.debug( @"Resume is initiated by the user: $(user_initiated); switching to $(idleState) idle state ..." ) );
        updateIdleState( idleState );

        instance.updateSystemStatus( FreeSmartphone.UsageSystemAction.ALIVE );

        return false; // MainLoop: Don't call again
    }

    private async void updateIdleState( FreeSmartphone.Device.IdleState state )
    {
        try
        {
            yield idlenotifier.set_state( state );
        }
        catch ( Error e )
        {
            logger.error( @"Error while talking to IdleNotifier: $(e.message)" );
        }
    }

    /**
     * Simple helper method to get a resource by its name from our internal storage.
     **/
    internal Resource getResource( string name ) throws FreeSmartphone.UsageError, FreeSmartphone.Error
    {
        if ( system_status != FreeSmartphone.UsageSystemAction.ALIVE )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"System action $system_status in progress; please try again later." );
        }

        Resource r = resources[name];
        if ( r == null )
        {
            throw new FreeSmartphone.UsageError.RESOURCE_UNKNOWN( @"Resource $name had never been registered" );
        }

        assert( logger.debug( "Current users for %s = %s".printf( r.name, FsoFramework.StringHandling.stringListToString( r.allUsers() ) ) ) );

        return r;
    }

    /**
     * This will create a list of all dependency resources for the given resource.
     */
    private GLib.List<Resource> resolveResourceDependencies( Resource r )
    {
        GLib.List<Resource> resourceWithDependencies = new GLib.List<Resource>();

        foreach ( string dependencyName in r.busDependencies )
        {
            if ( resources.has_key( dependencyName ) )
            {
                resourceWithDependencies.append( resources[dependencyName] );
            }
            else
            {
                logger.warning(@"Found not registered resource dependency '$(dependencyName)' for resource '$(r.name)'");
            }
        }

        return resourceWithDependencies;
    }

    /**
     * This will increment the usage number of a resource with the given name by one.
     **/
    private void incrementResourcePriority( Gee.HashMap<string,int> resourcesWithPriority, string name )
    {
        if ( resourcesWithPriority.has_key( name ) )
        {
            resourcesWithPriority.set( name, 1 );
        }
        else
        {
            resourcesWithPriority[name] += 1;
        }
    }

    /**
     * Create a list of priorized resources. The priority is calculated by the
     * dependencies of each resource. If a resouce is a dependency of another one it get's
     * a higher priority. The first resource in the returned list is the resource with the
     * lowest priority.
     **/
    private Resource[] retrievePriorizedResourceList( bool revertOrder = false )
    {
        var resourcesWithPriority = new Gee.HashMap<string,int>();
        var priorizedResources = new Gee.ArrayList<Resource>();
        Resource[] result = null;

        // Priorize all resources by use count
        foreach ( var r in resources.values )
        {
            // For the fact that the resource is only available it gets a priority of 1
            incrementResourcePriority( resourcesWithPriority, r.name );

            var resourceDependencies = resolveResourceDependencies( r );
            foreach ( var resourceDependency in resourceDependencies )
            {
                incrementResourcePriority( resourcesWithPriority, resourceDependency.name );
            }

            priorizedResources.add( r );
        }

        // Sort all resources in the list by their priority
        priorizedResources.sort_with_data( (a, b) => {
            int rc = 0;
            Resource ra = a as Resource, rb = b as Resource;

            assert( ra != null );
            assert( rb != null );

            var priorityRa = resourcesWithPriority[ra.name];
            var priorityRb = resourcesWithPriority[rb.name];

            if ( priorityRa > priorityRb )
                rc = 1;
            else if ( priorityRa < priorityRb )
                rc = -1;

            return rc;
        } );

        result = priorizedResources.to_array();

        // In some cases we need the reverse order of the priorized resources
        if ( revertOrder )
        {
            result = new Resource[priorizedResources.size];
            int m = 0;
            for ( int n = priorizedResources.size - 1; n >= 0; n-- )
            {
                result[m] = priorizedResources[n];
                m++;
            }
        }

        return result;
    }

    internal async void disableAllResources()
    {
        assert( logger.debug( "Disabling all resources..." ) );

        foreach ( var r in retrievePriorizedResourceList() )
        {
            try
            {
                yield r.disable();
            }
            catch ( Error e )
            {
                logger.warning( @"Error while trying to disable resource $(r.name): $(e.message)" );
            }
        }

        assert( logger.debug( "... done" ) );
    }

    internal async void suspendAllResources()
    {
        assert( logger.debug( "Suspending all resources..." ) );

        foreach ( var r in retrievePriorizedResourceList() )
        {
            try
            {
                yield r.suspend();
            }
            catch ( Error e )
            {
                logger.warning( @"Error while trying to suspend resource $(r.name): $(e.message)" );
            }
        }

        assert( logger.debug( "... done disabling." ) );
    }

    internal async void resumeAllResources()
    {
        assert( logger.debug( "Resuming all resources..." ) );

        // We need the reverse order: the resource with the highest priority comes first
        foreach ( var r in retrievePriorizedResourceList( true ) )
        {
            try
            {
                assert( logger.debug( @"Resuming resource '$(r.name)'" ) );
                yield r.resume();
            }
            catch ( Error e )
            {
                logger.warning( @"Error while trying to resume resource $(r.name): $(e.message)" );
            }
        }

        assert( logger.debug( "... done resuming." ) );
    }

    //
    // DBUS API (for providers)
    //
    public void register_resource( GLib.BusName sender, string name, GLib.ObjectPath path ) 
        throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBusError, IOError
    {
#if DEBUG
        debug( "register_resource called with parameters: %s %s %s", sender, name, path );
#endif
        if ( name in resources.keys )
        {
            // shadow resource?
            if ( resources[name].objectpath != null )
            {
                // no
                throw new FreeSmartphone.UsageError.RESOURCE_EXISTS( @"Resource $name already registered" );
            }
            else
            {
#if DEBUG
                debug( @"shadow $name will now be substituted with the real thing..." );
#endif
                resources[name].objectpath = path;
                resources[name].proxy = Bus.get_proxy_sync<FreeSmartphone.Resource>( BusType.SYSTEM, sender, path );

                return;
            }
        }

        var r = new Resource( name, sender, path );
        resources[name] = r;

        onResourceAppearing( r );
    }

    public void unregister_resource( GLib.BusName sender, string name )
        throws FreeSmartphone.Error, FreeSmartphone.UsageError, DBusError, IOError
    {
        var r = getResource( name );

        if ( r.busname != sender )
            throw new FreeSmartphone.UsageError.RESOURCE_UNKNOWN( @"Resource $name not yours" );

        onResourceVanishing( r );

        resources.unset( name );
    }

    internal void shutdownPlugin()
    {
        if ( disable_on_shutdown )
        {
            disableAllResources();
        }
    }

    public void updateSystemStatus( FreeSmartphone.UsageSystemAction action )
    {
        if ( action == system_status )
        {
            return;
        }

        system_status = action;
        this.system_action( action );
    }

    //
    // DBUS API (for consumers)
    //
    public async string get_resource_policy( string name )
        throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBusError, IOError
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

    public async void set_resource_policy( string name, string policy )
        throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBusError, IOError, Error
    {
        logger.debug( @"Set resource policy for $name to $policy" );
        var resource = getResource( name );
        var policyToSet = FreeSmartphone.UsageResourcePolicy.AUTO;

        switch ( policy )
        {
            case "enabled":
                policyToSet = FreeSmartphone.UsageResourcePolicy.ENABLED;
                break;
            case "disabled":
                policyToSet = FreeSmartphone.UsageResourcePolicy.DISABLED;
                break;
            case "auto":
                policyToSet = FreeSmartphone.UsageResourcePolicy.AUTO;
                break;
            default:
                throw new FreeSmartphone.Error.INVALID_PARAMETER( "ResourcePolicy needs to be one of { \"enabled\", \"disabled\", \"auto\" }" );
        }

        yield resource.setPolicy( policyToSet );
    }

    public async bool get_resource_state( string name )
        throws FreeSmartphone.Error, FreeSmartphone.UsageError, DBusError, IOError
    {
        return getResource( name ).isEnabled();
    }

    public async string[] get_resource_users( string name )
        throws FreeSmartphone.Error, FreeSmartphone.UsageError, DBusError, IOError
    {
        return getResource( name ).allUsers();
    }

    public async string[] list_resources()
        throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBusError, IOError
    {
        string[] res = {};
        foreach ( var key in resources.keys )
            res += key;
        return res;
    }

    public async void request_resource( GLib.BusName sender, string name )
        throws FreeSmartphone.Error, FreeSmartphone.ResourceError, FreeSmartphone.UsageError, DBusError, IOError
    {
        var cmd = new RequestResource( getResource( name ) );
        yield cmd.run( sender );
    }

    public async void release_resource( GLib.BusName sender, string name )
        throws FreeSmartphone.Error, FreeSmartphone.UsageError, DBusError, IOError
    {
        var cmd = new ReleaseResource( getResource( name ) );
        yield cmd.run( sender );
    }

    public async void shutdown()
        throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBusError, IOError
    {
        var cmd = new Shutdown();
        yield cmd.run();
    }

    public async void reboot()
        throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBusError, IOError
    {
        var cmd = new Reboot();
        yield cmd.run();
    }

    public async void suspend()
        throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBusError, IOError
    {
        var cmd = new Suspend();
        yield cmd.run();
    }

    public async void resume( string source, string reason )
        throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBusError, IOError
    {
        var cmd = new Resume();
        yield cmd.run();
    }

    // DBUS SIGNALS
    public signal void resource_available( string name, bool availability );
    public signal void resource_changed( string name, bool state, GLib.HashTable<string,Variant> attributes );
    public signal void system_action( FreeSmartphone.UsageSystemAction action );
}

} /* end namespace */

namespace Usage { public Usage.Controller instance; }

public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    Usage.instance = new Usage.Controller( subsystem );
    return "fsousage.dbus_service";
}

public static void fso_shutdown_function()
{
    Usage.instance.shutdownPlugin();
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "usage dbus_service fso_register_function()" );
}

// vim:ts=4:sw=4:expandtab
