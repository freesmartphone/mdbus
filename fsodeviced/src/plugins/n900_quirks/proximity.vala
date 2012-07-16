/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *                    2010 Sebastian Krzyszkowiak <seba.dos1@gmail.com>
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

namespace Proximity
{
    class N900 : FreeSmartphone.Device.Proximity,
                 FreeSmartphone.Device.PowerControl,
                 FsoFramework.AbstractObject
    {
        FsoFramework.Subsystem subsystem;

        private string node;
        private string powernode;

        private int lastvalue;
        private int lasttimestamp;

        public N900( FsoFramework.Subsystem subsystem, string node )
        {
            this.subsystem = subsystem;
            this.node = node;
            this.lastvalue = -1;
            this.lasttimestamp = 0;

            if ( !FsoFramework.FileHandling.isPresent( this.node ) )
            {
                logger.error( @"Sysfs class is damaged, missing $(this.node); skipping." );
                return;
            }

            this.powernode = GLib.Path.build_filename( this.node, "disable" );
            this.node = GLib.Path.build_filename( this.node, "state" );

            logger.debug( @"Trying to read from $(this.node)..." );

            subsystem.registerObjectForServiceWithPrefix<FreeSmartphone.Device.Proximity>( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.ProximityServicePath, this );

            var channel = new IOChannel.file( this.node, "r" );
            string value = "";
            size_t c = 0;
            channel.read_to_end(out value, out c);
            channel.seek_position(0, SeekType.SET);

            this.lastvalue = (value.strip() == "closed") ? 100 : 0;
            this.lasttimestamp = (int) TimeVal().tv_sec;

            this.set_power( false );

            channel.add_watch( IOCondition.IN | IOCondition.PRI | IOCondition.ERR, onInputEvent );

            logger.info( "Created" );

        }

        public override string repr()
        {
            return @"<$node>";
        }

        public bool onInputEvent( IOChannel source, IOCondition condition )
        {
          if ( ( ( condition & IOCondition.IN  ) == IOCondition.IN  ) || ( ( condition & IOCondition.PRI ) == IOCondition.PRI ) ) {
            string value = "";
            size_t c = 0;
            source.read_line (out value, out c, null);
            logger.debug( @"got data from sysfs node: $value" );
            // send dbus signal
            this.lastvalue = (value.strip() == "closed") ? 100 : 0;
            this.lasttimestamp = (int) TimeVal().tv_sec;
            this.proximity( this.lastvalue );

            source.seek_position(0, SeekType.SET);
            return true;
          }
          else {
            logger.error("onInputEvent error");
            return false;
          }
        }

        //
        // FreeSmartphone.Device.Proximity (DBUS API)
        //
        public async void get_proximity( out int proximity, out int timestamp ) throws FreeSmartphone.Error, DBusError, IOError
        {
            try {
                var value = FsoFramework.FileHandling.read( node ) ?? "";
                this.lastvalue = (value.strip() == "closed") ? 100 : 0;
                this.lasttimestamp = (int) TimeVal().tv_sec;
            }
            finally {
                proximity = this.lastvalue;
                timestamp = this.lasttimestamp;
        }
        }

        //
        // FreeSmartphone.Device.PowerControl (DBUS API)
        //
        public async bool get_power() throws DBusError, IOError
        {
            var contents = FsoFramework.FileHandling.read( powernode ) ?? "";
            return contents.strip() == "0";
        }

        public async void set_power( bool on ) throws DBusError, IOError
        {
            var contents = on ? "0" : "1";
            FsoFramework.FileHandling.write( contents, powernode );
        }

    }

    /**
     * Implementation of org.freesmartphone.Resource for the Proximity Resource
     **/
    class ProximityResource : FsoFramework.AbstractDBusResource
    {
        internal bool on;
        private Proximity.N900 instance;

        public ProximityResource( FsoFramework.Subsystem subsystem, Proximity.N900 instance )
        {
            base( "Proximity", subsystem );
            this.instance = instance;
        }

        public override async void enableResource()
        {
            if (on)
                return;
            assert( logger.debug( "Enabling..." ) );
            instance.set_power( true );
            on = true;
        }

        public override async void disableResource()
        {
            if (!on)
                return;
            assert( logger.debug( "Disabling..." ) );
            instance.set_power( false );
            on = false;
        }

        public override async void suspendResource()
        {
        }

        public override async void resumeResource()
        {
        }
    }
} /* namespace */

// vim:ts=4:sw=4:expandtab
