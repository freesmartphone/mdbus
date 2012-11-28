/*
 * Copyright (C) 2012 Lukas Märdian <luk@slyon.de>
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
     * Kernel Info (/proc/cpuinfo) for OpenPhoenux GTA04
     * Manually detect hardware revision, as it isn't listed in /proc/cpuinfo.
     **/
    class Info : FreeSmartphone.Device.Info, FsoFramework.AbstractObject
    {

        private FsoFramework.Subsystem subsystem;
        private const string PROC_NODE = "/proc/cpuinfo";
        private string sysfs_revision_check_gpio;

        public Info( FsoFramework.Subsystem subsystem )
        {
            this.subsystem = subsystem;
            sysfs_revision_check_gpio = config.stringValue( Gta04.MODULE_NAME+"/info", "revision_check_gpio", "/sys/class/gpio/gpio186/value" );
            subsystem.registerObjectForService<FreeSmartphone.Device.Info>( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.InfoServicePath, this );
            logger.info( "Created new Info Object" );
        }

        public override string repr()
        {
            return "<FsoFramework.Device.Info @ %s>".printf( FsoFramework.Device.InfoServicePath );
        }


        //
        // FreeSmartphone.Device.Info (DBUS API)
        //
        public async HashTable<string,Variant> get_cpu_info() throws DBusError, IOError
        {
            File node_file = File.new_for_path( PROC_NODE );
            string line;
            HashTable<string, Variant> _ret = new HashTable<string, Variant>( str_hash, str_equal );
            Variant val;
            DataInputStream stream = new DataInputStream( node_file.read(null) );
            try
            {
                line = stream.read_line( null, null );
                while (( line = stream.read_line( null, null ) ) != null)
                {
                    if ( line == "\n" || line == "" )
                        continue;

                    string[] _list = line.split(":");
                    if ( (_list[1] != "") && (_list[0] != "") )
                    {
                        val = _list[1].strip();
                        _ret.insert ( _list[0].strip(), val );
                    }
                }
                //manually adopt the GTA04 Revision
                if ( !FsoFramework.FileHandling.isPresent( sysfs_revision_check_gpio ) )
                {
                    _ret["Revision"] = "A3";
                    FsoFramework.DataSharing.setValueForKey("model", "gta04a3");
                }
                else
                {
                    _ret["Revision"] = "A4+";
                }
            }
            catch (GLib.Error error)
            {
                logger.warning( error.message );
            }
            return _ret;
        }
    }

}

// vim:ts=4:sw=4:expandtab
