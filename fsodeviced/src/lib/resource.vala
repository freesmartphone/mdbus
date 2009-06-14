/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

namespace FsoDevice {

/**
 * AbstractSimpleResource: A DBus Resource API service object
 */
public class AbstractSimpleResource : FreeSmartphone.Resource, FsoFramework.AbstractObject
{
    private FsoFramework.DBusSubsystem subsystem;
    private dynamic DBus.Object usage;
    private string name;
    private DBus.ObjectPath path;

    public AbstractSimpleResource( string name, FsoFramework.Subsystem subsystem )
    {
        this.name = name;
        this.subsystem = subsystem as FsoFramework.DBusSubsystem;
        this.path = new DBus.ObjectPath( "/org/freesmartphone/Resource/%s".printf( name ) );

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
        if (usage == null)
        {
            var conn = subsystem.dbusConnection();
            usage = conn.get_object( "org.freesmartphone.ousaged", "/org/freesmartphone/Usage", "org.freesmartphone.Usage" ) /* as FreeSmartphone.Usage */;
            usage.register_resource( name, path, onRegisterResourceReply );
        }
        return false; // MainLoop: don't call me again
    }

    public void onRegisterResourceReply( GLib.Error e )
    {
        if ( e != null )
        {
            logger.error( "%s".printf( e.message ) );
            return;
        }
        else
        {
            logger.debug( "registered with org.freesmartphone.ousaged" );
        }
    }

    public virtual void _enable()
    {
    }

    public virtual void _disable()
    {
    }

    public virtual void _suspend()
    {
    }

    public virtual void _resume()
    {
    }

    //
    // DBUS API
    //
    public void disable() throws FreeSmartphone.ResourceError, DBus.Error
    {
        _disable();
    }

    public void enable() throws DBus.Error
    {
        _enable();
    }

    public void resume() throws FreeSmartphone.ResourceError, DBus.Error
    {
        _resume();
    }

    public void suspend() throws FreeSmartphone.ResourceError, DBus.Error
    {
        _suspend();
    }
}

/**
 * BasePowerControlResource: Exports a BasePowerControl instance via the DBus Resource API
 */
public class BasePowerControlResource : AbstractSimpleResource
{
    private weak BasePowerControl bpc;

    public BasePowerControlResource( BasePowerControl bpc, string name, FsoFramework.Subsystem subsystem )
    {
        base( name, subsystem );
        this.bpc = bpc;
    }

    public override void _enable()
    {
        logger.debug( "enabling..." );
        bpc.setPower( true );
    }

    public override void _disable()
    {
        logger.debug( "disabling..." );
        bpc.setPower( false );
    }
}


} /* namespace FsoDevice */
