/*
 * Copyright (C) 2011 Klaus 'mrmoku' Kurzmann <mok@fluxnetz.de>
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

namespace Gta04
{
    /**
     * GPS device power control for Openmoko GTA04
     **/
    class GpsPowerControl : FsoDevice.BasePowerControl
    {

        private FsoFramework.Subsystem subsystem;
        private string sysfsnode;
        private string name;

        public GpsPowerControl( FsoFramework.Subsystem subsystem, string sysfsnode )
        {
            base( Path.build_filename( sysfsnode, "value" ) );
            this.subsystem = subsystem;
            this.sysfsnode = sysfsnode;
            this.name = Path.get_basename( sysfsnode );

            subsystem.registerObjectForServiceWithPrefix<FreeSmartphone.Device.PowerControl>( FsoFramework.Device.ServiceDBusName,
                FsoFramework.Device.PowerControlServicePath, this );

            logger.info( "created." );
        }

        public override void setPower( bool on )
        {
            if ( on )
            {
                // on - off - on to properly reset the GPS
                base.setPower( true );
                Posix.usleep( 200 );
                base.setPower( false );
                Posix.usleep( 200 );
                base.setPower( true );
            }
            else
            {
                base.setPower( false );
            }
        }
    }

} /* namespace */

// vim:ts=4:sw=4:expandtab
