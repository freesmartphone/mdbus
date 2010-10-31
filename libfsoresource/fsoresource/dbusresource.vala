/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using GLib;

namespace FsoFramework {

/**
 * AbstractSimpleResource: A DBus Resource API service object
 */
public abstract class AbstractDBusResource : FreeSmartphone.Resource, FsoFramework.AbstractObject
{
    private FsoFramework.DBusSubsystem subsystem;
    private FreeSmartphone.Usage usage;
    private string name;
    private ObjectPath path;

    public AbstractDBusResource( string name, FsoFramework.Subsystem subsystem )
    {
        this.name = name;
        this.subsystem = subsystem as FsoFramework.DBusSubsystem;
        this.path = new ObjectPath( "%s/%s".printf( FsoFramework.Resource.ServicePathPrefix, name ) );

        var conn = this.subsystem.dbusConnection();
        //FIXME: try/catch
        //FIXME: Why is this not using the subsystem API?
        conn.register_object<FreeSmartphone.Resource>( this.path, this );

        Idle.add( () => {
            registerWithUsage();
        } );
    }

    public override string repr()
    {
        return @"<$name>";
    }

    public async void registerWithUsage()
    {
#if DEBUG
        message( "registering..." );
#endif
        if ( usage == null )
        {
            var conn = subsystem.dbusConnection();

            try
            {
                //usage = conn.get_proxy_sync<FreeSmartphone.Usage>( FsoFramework.Usage.ServiceDBusName, FsoFramework.Usage.ServicePathPrefix );
                usage = yield conn.get_proxy<FreeSmartphone.Usage>( FsoFramework.Usage.ServiceDBusName, FsoFramework.Usage.ServicePathPrefix );
                yield usage.register_resource( name, path );
                logger.info( "Ok. Registered with org.freesmartphone.ousaged" );
            }
            catch ( GLib.Error e )
            {
                logger.error( @"$(e.message): Can't register resource with fsousaged, enabling unconditionally..." );
                enableResource();
            }
        }
#if DEBUG
        message( "...OK" );
#endif
    }

    /**
     * Override this to enable your resource. Only complete once the resource has been fully initialized.
     **/
    public abstract async void enableResource() throws FreeSmartphone.ResourceError;

    public abstract async void disableResource();

    public abstract async void suspendResource();

    public abstract async void resumeResource();

    /**
     * This method has a default implementation for backwards compatibility,
     * subclasses need to override this.
     **/
    public virtual async GLib.HashTable<string,GLib.Value?> dependencies()
    {
        return new GLib.HashTable<string,GLib.Value?>( GLib.str_hash, GLib.str_equal );
    }

    //
    // DBUS API
    //
    public async void disable() throws FreeSmartphone.ResourceError, DBusError, IOError
    {
        assert( logger.debug( @"Disabling resource $classname..." ) );
        yield disableResource();
    }

    public async void enable() throws FreeSmartphone.ResourceError, DBusError, IOError
    {
        assert( logger.debug( @"Enabling resource $classname..." ) );
        yield enableResource();
    }

    public async void resume() throws FreeSmartphone.ResourceError, DBusError, IOError
    {
        assert( logger.debug( @"Resuming resource $classname..." ) );
        yield resumeResource();
    }

    public async void suspend() throws FreeSmartphone.ResourceError, DBusError, IOError
    {
        assert( logger.debug( @"Suspending resource $classname..." ) );
        yield suspendResource();
    }

    public async GLib.HashTable<string,GLib.Value?> get_dependencies() throws DBusError, IOError
    {
        assert( logger.debug( @"Inquiring dependencies for $classname..." ) );
        var result = yield dependencies();
        return result;
    }
}

} /* namespace FsoFramework */
