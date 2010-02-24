/**
 * FSO Resource Abstraction
 *
 * (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
public class Resource : Object
{
    public string name { get; set; }
    public DBus.BusName busname { get; set; }
    public DBus.ObjectPath objectpath { get; set; }
    public ResourceStatus status { get; set; }
    public FreeSmartphone.UsageResourcePolicy policy { get; set; }
    public ArrayList<string> users { get; set; }

    private FreeSmartphone.Resource proxy;

    // every resource has a command queue
    public LinkedList<unowned ResourceCommand> q;

    public Resource( string name, DBus.BusName busname, DBus.ObjectPath objectpath )
    {
        this.users = new ArrayList<string>();
        this.q = new LinkedList<unowned ResourceCommand>();

        this.name = name;
        this.busname = busname;
        this.objectpath = objectpath;
        this.status = ResourceStatus.UNKNOWN;
        this.policy = FreeSmartphone.UsageResourcePolicy.AUTO;

        proxy = dbusconn.get_object( busname, objectpath, RESOURCE_INTERFACE ) as FreeSmartphone.Resource;

        assert( FsoFramework.theLogger.debug( @"Resource $name served by $busname ($objectpath) created" ) );
    }

    ~Resource()
    {
        assert( FsoFramework.theLogger.debug( @"Resource $name served by $busname ($objectpath) destroyed" ) );
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

    public async void setPolicy( FreeSmartphone.UsageResourcePolicy policy )
    {
        if ( policy == this.policy )
            return;
        else
            ( this.policy = policy );

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
            yield enable();
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
        dynamic DBus.Object busobj = dbusconn.get_object( DBus.DBUS_SERVICE_DBUS, DBus.DBUS_PATH_DBUS, DBus.DBUS_INTERFACE_DBUS );
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
        dynamic DBus.Object peer = dbusconn.get_object( busname, objectpath, DBus.DBUS_INTERFACE_PEER );
        try
        {
            peer.Ping();
            return true;
        }
        catch ( DBus.Error e )
        {
            instance.logger.warning( @"Resource $name incommunicado: $(e.message)" );
            return false;
        }
    }

    public async void enable() throws FreeSmartphone.ResourceError, DBus.Error
    {
        try
        {
            yield proxy.enable();
            status = ResourceStatus.ENABLED;
            updateStatus();
        }
        catch ( GLib.Error e )
        {
            instance.logger.error( @"Resource $name can't be enabled: $(e.message). Trying to disable instead" );
            yield proxy.disable();
            throw e;
        }
    }

    public async void disable() throws FreeSmartphone.ResourceError, DBus.Error
    {
        try
        {
            yield proxy.disable();
            status = ResourceStatus.DISABLED;
            updateStatus();
        }
        catch ( DBus.Error e )
        {
            instance.logger.error( @"Resource $name can't be disabled: $(e.message). Setting status to UNKNOWN" );
            status = ResourceStatus.UNKNOWN;
            throw e;
        }
    }

    public async void suspend() throws FreeSmartphone.ResourceError, DBus.Error
    {
        if ( status == ResourceStatus.ENABLED )
        {
            try
            {
                yield proxy.suspend();
                status = ResourceStatus.SUSPENDED;
                updateStatus();
            }
            catch ( DBus.Error e )
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

    public async void resume() throws FreeSmartphone.ResourceError, DBus.Error
    {
        if ( status == ResourceStatus.SUSPENDED )
        {
            try
            {
                yield proxy.resume();
                status = ResourceStatus.ENABLED;
                updateStatus();
            }
            catch ( DBus.Error e )
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
