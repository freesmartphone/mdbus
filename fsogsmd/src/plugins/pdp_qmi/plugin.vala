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

using FsoGsm;

class Pdp.Qmi : FsoGsm.PdpHandler
{
    public const string MODULE_NAME = "fsogsm.pdp_qmi";
    public const string RMNET_IFACE = "rmnet0";
    public const string QMI_DEVNODE = "qmi0";

    private FsoFramework.Async.ReactorChannel qmi;

    public override string repr()
    {
        return "<>";
    }

    construct
    {
        string node = Path.build_filename( devfs_root, QMI_DEVNODE );
        int fd = Posix.open( node, Posix.O_RDWR );
        if ( fd < 0 )
        {
            logger.error( @"Can't open $node: $(strerror(errno))" );
        }
        else
        {
            qmi = new FsoFramework.Async.ReactorChannel( fd, onInputFromQmi );
        }
    }

    private void onInputFromQmi( char* data, ssize_t length )
    {
        assert( logger.debug( @"QMI says: $(((string)data).escape( "" ))" ) );
        data[length] = '\0';
        string message = (string)data;

        var properties = new Gee.HashMap<string,string>();

        foreach ( var line in message.split( "\n" ) )
        {
            var components = line.split( "=" );
            if ( components.length != 2 )
            {
                logger.warning( @"Unknown message format in line $line" );
                return;
            }
            else
            {
                properties[components[0]] = components[1];
            }
        }
        Idle.add( () => { onUpdateFromQmi( properties ); return false; } );
    }

    private void onUpdateFromQmi( Gee.HashMap<string,string> properties )
    {
        message( @"onUpdateFromQmi with $(properties.size) properties" );
    }

    public async override void activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var data = theModem.data();

        if ( data.contextParams == null )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Context parameters not set" );
        }

        if ( data.contextParams.apn == null )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "APN not set" );
        }

        var cmdline = @"up:$(data.contextParams.apn) $(data.contextParams.username) $(data.contextParams.password)";

        Posix.write( qmi.fileno(), cmdline, cmdline.length );
    }

    public async override void deactivate()
    {
        Posix.write( qmi.fileno(), "down", 5 );
    }

    public async override void statusUpdate( string status, GLib.HashTable<string,Value?> properties )
    {
        assert_not_reached();
    }
}

static string sysfs_root;
static string devfs_root;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    FsoFramework.theLogger.debug( "pdp_qmi fso_factory_function" );
    // grab sysfs paths
    var config = FsoFramework.theConfig;
    sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
    devfs_root = config.stringValue( "cornucopia", "devfs_root", "/dev" );

    return Pdp.Qmi.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}
