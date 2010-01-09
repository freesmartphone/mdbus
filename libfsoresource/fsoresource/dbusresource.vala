/**
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
    private dynamic DBus.Object usage; /* needs to be dynamic for async */
    private string name;
    private DBus.ObjectPath path;

    public AbstractDBusResource( string name, FsoFramework.Subsystem subsystem )
    {
        this.name = name;
        this.subsystem = subsystem as FsoFramework.DBusSubsystem;
        this.path = new DBus.ObjectPath( "%s/%s".printf( FsoFramework.Resource.ServicePathPrefix, name ) );

        var conn = this.subsystem.dbusConnection();
        //FIXME: try/catch
        conn.register_object( this.path, this );

        Idle.add( registerWithUsage );
    }

    public override string repr()
    {
        return "<%s>".printf( name );
    }

    public bool registerWithUsage()
    {
#if DEBUG
        message( "registering..." );
#endif
        if (usage == null)
        {
            var conn = subsystem.dbusConnection();
            usage = conn.get_object( FsoFramework.Usage.ServiceDBusName,
                                     FsoFramework.Usage.ServicePathPrefix,
                                     FsoFramework.Usage.ServiceFacePrefix ); /* dynamic for async */
            usage.register_resource( name, path, onRegisterResourceReply );
        }
#if DEBUG
        message( "...OK" );
#endif
        return false; // MainLoop: don't call me again
    }

    public void onRegisterResourceReply( GLib.Error e )
    {
        if ( e != null )
        {
            logger.error( "%s. Can't register resource with fsousaged, enabling unconditionally".printf( e.message ) );
            enableResource();
            return;
        }
        else
        {
            logger.info( "registered with org.freesmartphone.ousaged" );
        }
    }

    public abstract async void enableResource();

    public abstract async void disableResource();

    public abstract async void suspendResource();

    public abstract async void resumeResource();

    //
    // DBUS API
    //
    public async void disable() throws FreeSmartphone.ResourceError, DBus.Error
    {
        yield disableResource();
    }

    public async void enable() throws DBus.Error
    {
        yield enableResource();
    }

    public async void resume() throws FreeSmartphone.ResourceError, DBus.Error
    {
        yield resumeResource();
    }

    public async void suspend() throws FreeSmartphone.ResourceError, DBus.Error
    {
        yield suspendResource();
    }
}

} /* namespace FsoFramework */
