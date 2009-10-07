/*
 * plugin.vala
 * Written by Sudharshan "Sup3rkiddo" S <sudharsh@gmail.com>
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

namespace Kernel
{

class Info : FreeSmartphone.Device.Info, FsoFramework.AbstractObject
{

    private FsoFramework.Subsystem subsystem;
    private const string PROC_NODE = "/proc/cpuinfo";

    public Info( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;
        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                        FsoFramework.Device.InfoServicePath,
                                        this );
        logger.info( "Created new Info Object" );
    }


    public override string repr()
    {
        return "<FsoFramework.Device.Info @ %s>".printf( FsoFramework.Device.InfoServicePath );
    }


    //
    // FreeSmartphone.Device.Info (DBUS API)
    //
    public async HashTable<string, Value?> get_cpu_info()
    {
        File node_file = File.new_for_path( PROC_NODE );
        string line;
        var val = Value( typeof(string) );
        HashTable<string, Value?> _ret = new HashTable<string, Value?> ( (HashFunc)str_hash,
                                                                        (EqualFunc)str_equal );
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
                    val.take_string(_list[1].strip());
                    _ret.insert ( _list[0].strip(), val );
                }
            }
        }
        catch (GLib.Error error) {
            logger.warning( error.message );
        }
        return _ret;
    }

}

} /* namespace Kernel */

Kernel.Info instance;

public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    instance = new Kernel.Info( subsystem );
    return "fsodevice.kernel_info";
}


[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "info fso_register_function()" );
}
