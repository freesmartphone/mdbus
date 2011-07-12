/*
 * FSO Resource Abstraction
 *
 * (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

namespace Usage {

/**
 * @interface IResource
 **/
public interface IResource : Object
{
    public abstract async void setPolicy( FreeSmartphone.UsageResourcePolicy policy ) throws FreeSmartphone.ResourceError, DBusError, IOError;
    public abstract async void enable() throws FreeSmartphone.ResourceError, DBusError, IOError;
    public abstract async void disable() throws FreeSmartphone.ResourceError, DBusError, IOError;
    public abstract async void suspend() throws FreeSmartphone.ResourceError, DBusError, IOError;
    public abstract async void resume() throws FreeSmartphone.ResourceError, DBusError, IOError;
}

/**
 * Helper class encapsulating a registered resource
 **/
public class Resource : IResource, Object
{
    public string name { get; set; }
    public GLib.BusName busname { get; set; }
    public GLib.ObjectPath? objectpath { get; set; }
    public FsoFramework.ResourceStatus status { get; set; }
    public FreeSmartphone.UsageResourcePolicy policy { get; set; }
    public ArrayList<string> users { get; set; }
    public ArrayList<string> processDependencies { get; set; }
    public ArrayList<string> busDependencies { get; set; }

    public FreeSmartphone.Resource proxy;

    // every resource has a command queue
    public LinkedList<unowned ResourceCommand> q;

    public Resource( string name, GLib.BusName busname, GLib.ObjectPath? objectpath = null )
    {
        this.users = new ArrayList<string>();
        this.q = new LinkedList<unowned ResourceCommand>();

        this.name = name;
        this.busname = busname;
        this.objectpath = objectpath;
        this.status = FsoFramework.ResourceStatus.UNKNOWN;
        this.policy = FreeSmartphone.UsageResourcePolicy.AUTO;
        this.busDependencies = new ArrayList<string>();

        if ( objectpath != null )
        {
            proxy = Bus.get_proxy_sync<FreeSmartphone.Resource>( BusType.SYSTEM, busname, objectpath );
            assert( FsoFramework.theLogger.debug( @"Resource $name served by $busname ($objectpath) created" ) );
            syncDependencies();
        }
        else
        {
            assert( FsoFramework.theLogger.debug( @"Shadow Resource $name served by $busname (unknown objectpath) created" ) );
        }
    }

    ~Resource()
    {
        assert( FsoFramework.theLogger.debug( @"Resource $name served by $busname ($objectpath) destroyed" ) );
    }

    /**
     * Sync dependencies of the resource with our local list.
     **/
    private async void syncDependencies()
    {
        try
        {
            var dependenciesFromResource = yield proxy.get_dependencies();

            if ( dependenciesFromResource == null )
            {
                assert( FsoFramework.theLogger.debug(@"There are no dependencies for resource '$(name)'.") );
                return;
            }

            var services = dependenciesFromResource.lookup( "services" );
            if ( services != null )
            {
                var servicesStr = services as string;
                if ( servicesStr != null )
                {
                    assert( FsoFramework.theLogger.debug( @"Resource '$name' has the following dependencies: $servicesStr" ) );

                    var parts = servicesStr.split(",");
                    foreach ( var service in parts )
                    {
                        busDependencies.add( service );
                    }
                }
            }
            else
            {
                assert( FsoFramework.theLogger.debug(@"Resource '$name' does not has any dependencies.") );
            }
        }
        catch ( GLib.Error error )
        {
            FsoFramework.theLogger.error(@"Can't sync dependencies of resource '$(name)': $(error.message)" );
        }
    }

    private void updateStatus()
    {
        // NOTE: Ok, here's a "funny" one: updateStatus is the async reply handler for a call
        // that results in the caller (this very object) to be destroyed. The reply handler
        // will then be called with a half-destroyed ( this!=null ) object.
        // TODO: Investigate whether this is a vala bug or not
        if ( users == null )
        {
            FsoFramework.theLogger.warning( @"Resource $name already destroyed." );
            return;
        }
        var info = new HashTable<string,Variant>( str_hash, str_equal );
        info.insert( "policy", policy );
        info.insert( "refcount", users.size );
        instance.resource_changed( name, isEnabled(), info ); // DBUS SIGNAL
    }

    public bool isEnabled()
    {
        return ( status == FsoFramework.ResourceStatus.ENABLED );
    }

    public bool hasUser( string user )
    {
        return ( user in users );
    }

    public virtual async void setPolicy( FreeSmartphone.UsageResourcePolicy policy ) throws FreeSmartphone.ResourceError, DBusError, IOError
    {
        if ( policy == this.policy )
            return;
        else
            ( this.policy = policy );

        assert( FsoFramework.theLogger.debug( @"Policy for resource '$name' is now $policy" ) );

        /* does not work, bug in vala async */
#if VALA_BUG_602200_FIXED
        switch ( policy )
        {
            case FreeSmartphone.UsageResourcePolicy.DISABLED:
                yield disable();
                break;
            case FreeSmartphone.UsageResourcePolicy.ENABLED:
                yield enable();
                break;
            case FreeSmartphone.UsageResourcePolicy.AUTO:
                if ( users.size > 0 )
                    yield enable();
                else
                    yield disable();
                break;
            default:
                assert_not_reached();
        }
#else
        if ( policy == FreeSmartphone.UsageResourcePolicy.DISABLED )
        {
            yield disable();
        }
        else if ( policy == FreeSmartphone.UsageResourcePolicy.ENABLED )
        {
            yield enable();
        }
        else if ( policy == FreeSmartphone.UsageResourcePolicy.AUTO )
        {
            if ( users.size > 0 )
            {
                yield enable();
            }
            else
            {
                yield disable();
            }
        }
        else
        {
            FsoFramework.theLogger.error( "Unknown usage resouce policy. Ignoring" );
        }
#endif
    }

    public async void addUser( string user ) throws FreeSmartphone.ResourceError, FreeSmartphone.UsageError
    {
        if ( user in users )
            throw new FreeSmartphone.UsageError.USER_EXISTS( @"Resource $name already requested by user $user" );

        if ( policy == FreeSmartphone.UsageResourcePolicy.DISABLED )
            throw new FreeSmartphone.UsageError.POLICY_DISABLED( @"Resource $name cannot be requested by $user per policy" );

        if ( policy == FreeSmartphone.UsageResourcePolicy.AUTO && users.size == 0 )
        {
            try
            {
                yield enable();
            }
            catch ( GLib.Error error )
            {
                throw new FreeSmartphone.ResourceError.UNABLE_TO_ENABLE( @"Could not enable resource '$name': $(error.message)" );
            }
        }

        users.insert( 0, user );
        updateStatus();
    }

    public async void delUser( string user ) throws FreeSmartphone.UsageError
    {
        if ( !(user in users) )
            throw new FreeSmartphone.UsageError.USER_UNKNOWN( @"Resource $name never been requested by user $user" );

        users.remove( user );

        if ( policy == FreeSmartphone.UsageResourcePolicy.AUTO && users.size == 0 )
            yield disable();
    }

    public void syncUsers()
    {
        DBusService.IDBusSync busobj = Bus.get_proxy_sync<DBusService.IDBusSync>( BusType.SYSTEM, DBusService.DBUS_SERVICE_DBUS, DBusService.DBUS_PATH_DBUS );
        string[] busnames = busobj.ListNames();

        var usersToRemove = new ArrayList<string>();

        foreach ( var userbusname in users )
        {
            var found = false;
            foreach ( var busname in busnames )
            {
                if ( userbusname == busname )
                    found = true;
                    break;
            }
            if ( !found )
                usersToRemove.add( userbusname );
        }
        foreach ( var userbusname in usersToRemove )
        {
            instance.logger.warning( @"Resource $name user $userbusname has vanished." );
            delUser( userbusname );
        }
    }

    public string[] allUsers()
    {
        string[] res = {};
        foreach ( var user in users )
            res += user;
        return res;
    }

    public bool isPresent()
    {
        DBusService.IPeer peer = Bus.get_proxy_sync<DBusService.IPeer>( BusType.SYSTEM, busname, objectpath );
        try
        {
            peer.Ping();
            return true;
        }
        catch ( Error e )
        {
            instance.logger.warning( @"Resource $name incommunicado: $(e.message)" );
            return false;
        }
    }

    public virtual async void enableShadowResource() throws FreeSmartphone.ResourceError, DBusError, IOError
    {
        assert( instance.logger.debug( @"Resource $name is shadow resource; pinging..." ) );
        DBusService.IPeer service = Bus.get_proxy_sync<DBusService.IPeer>( BusType.SYSTEM, busname, "/" );
#if DEBUG
        message( "PING" );
#endif
        service.Ping();
#if DEBUG
        message( "PONG" );
        Timeout.add_seconds( 3, enableShadowResource.callback );
        yield;
#endif
    }

    public virtual async void enable() throws FreeSmartphone.ResourceError, DBusError, IOError
    {
        if ( objectpath == null )
        {
#if DEBUG
            message( "enableShadowResource" );
#endif
            yield enableShadowResource();
#if DEBUG
            message( "shadowResourceEnabled" );
#endif

            // Wait until the resource has registered or registration has timed out
            int retries = 0;
            Timeout.add_seconds( 1, () => {
                if ( retries > 10 )
                {
                    instance.logger.error( @"Can't enable resource '$name' as it has never registered!" );
                    return false;
                }

                if ( proxy != null )
                {
                    assert( instance.logger.debug( @"DBus proxy for resource '$name' is now available." ) );
                    enable.callback();
                    return false;
                }

                retries++;
                return true;
            });
            yield;
        }

        // Ensure that we have a dbus connection for our resource
        if ( proxy == null )
        {
            throw new FreeSmartphone.ResourceError.UNABLE_TO_ENABLE( @"Can't enable resource '$name'" );
        }

        try
        {
            yield proxy.enable();
            assert( instance.logger.debug( @"Enabled resource $name successfully" ) );
            status = FsoFramework.ResourceStatus.ENABLED;
            updateStatus();
        }
        catch ( Error e )
        {
            instance.logger.error( @"Resource $name can't be enabled: $(e.message). Trying to disable instead" );
            yield proxy.disable();
            throw e;
        }
    }

    public virtual async void disable() throws FreeSmartphone.ResourceError, DBusError, IOError
    {
        // no need to disable a shadow resource
        if ( objectpath == null )
            return;

        try
        {
            yield proxy.disable();
            assert( instance.logger.debug( @"Disabled resource $name successfully" ) );
            status = FsoFramework.ResourceStatus.DISABLED;
            updateStatus();
        }
        catch ( Error e )
        {
            instance.logger.error( @"Resource $name can't be disabled: $(e.message). Setting status to UNKNOWN" );
            status = FsoFramework.ResourceStatus.UNKNOWN;
            throw e;
        }
    }

    public virtual async void suspend() throws FreeSmartphone.ResourceError, DBusError, IOError
    {
        if ( status == FsoFramework.ResourceStatus.ENABLED )
        {
            try
            {
                yield proxy.suspend();
                assert( instance.logger.debug( @"Suspended resource $name successfully" ) );
                status = FsoFramework.ResourceStatus.SUSPENDED;
                updateStatus();
            }
            catch ( Error e )
            {
                instance.logger.error( @"Resource $name can't be suspended: $(e.message). Trying to disable instead" );
                yield proxy.disable();
                throw e;
            }
        }
        else
        {
            assert( instance.logger.debug( @"Resource $name not enabled: not suspending" ) );
        }
    }

    public virtual async void resume() throws FreeSmartphone.ResourceError, DBusError, IOError
    {
        if ( status == FsoFramework.ResourceStatus.SUSPENDED )
        {
            try
            {
                yield proxy.resume();
                assert( instance.logger.debug( @"Resumed resource $name successfully" ) );
                status = FsoFramework.ResourceStatus.ENABLED;
                updateStatus();
            }
            catch ( Error e )
            {
                instance.logger.error( @"Resource $name can't be resumed: $(e.message). Trying to disable instead" );
                yield proxy.disable();
                throw e;
            }
        }
        else
        {
            assert( instance.logger.debug( @"Resource $name not suspended: not resuming" ) );
        }
    }
}

} /* namespace Usage */

// vim:ts=4:sw=4:expandtab
