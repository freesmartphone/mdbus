/*
 * plugin.vala
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

namespace Usage
{

public class Controller : FreeSmartphone.Usage, FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;

    public Controller( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;
        this.subsystem.registerServiceName( FsoFramework.Network.ServiceDBusName );
        this.subsystem.registerServiceObject( FsoFramework.Network.ServiceDBusName, 
                                              FsoFramework.Network.UsageServicePath, this );
    }

    public override string repr()
    {
        return "<%s>".printf( FsoFramework.UsageServicePath );
    }

} /* end namespace */

Usage.Controller instance;

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
