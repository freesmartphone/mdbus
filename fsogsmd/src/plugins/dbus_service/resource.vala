/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using GLib;

/**
 * @class DBusService.Resource
 **/
public class DBusService.Resource : FsoFramework.AbstractDBusResource
{
    private FsoGsm.ServiceManager serviceManager;

    public Resource( FsoFramework.Subsystem subsystem, FsoGsm.ServiceManager serviceManager )
    {
        base( "GSM", subsystem );
        this.serviceManager = serviceManager;
    }

    public override async void enableResource() throws FreeSmartphone.ResourceError
    {
        assert( logger.debug( "Enabling GSM resource..." ) );

        var ok = yield serviceManager.enable();
        if ( !ok )
            throw new FreeSmartphone.ResourceError.UNABLE_TO_ENABLE( "Can't open the modem." );
    }

    public override async void disableResource()
    {
        assert( logger.debug( "Disabling GSM resource..." ) );
        yield serviceManager.disable();
    }

    public override async void suspendResource()
    {
        assert( logger.debug( "Suspending GSM resource..." ) );
        yield serviceManager.suspend();
    }

    public override async void resumeResource()
    {
        assert( logger.debug( "Resuming GSM resource..." ) );
        yield serviceManager.resume();
    }

    public override async GLib.HashTable<string,GLib.Variant?> dependencies()
    {
        var dependencies = new GLib.HashTable<string,GLib.Variant?>( GLib.str_hash, GLib.str_equal );

        // Service dependencies can be defined dynamically by the plugins with accessing
        // the theServiceDependencies global variable.
        string services = "";
        bool first = true;
        foreach ( var service in FsoGsm.theServiceDependencies )
        {
            if ( !first )
                services += ",";
            services += service;
            first = false;
        }

        dependencies.insert( "services", services );

        return dependencies;
    }
}

// vim:ts=4:sw=4:expandtab
