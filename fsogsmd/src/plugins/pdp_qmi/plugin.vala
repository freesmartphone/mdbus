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

    static char[] buffer = new char[512];

    public int fd;

    public override string repr()
    {
        return "<>";
    }

    construct
    {
        string node = Path.build_filename( devfs_root, QMI_DEVNODE );
        fd = Posix.open( node, Posix.O_RDWR | Posix.O_NONBLOCK );
        if ( fd < 0 )
        {
            logger.error( @"Can't open $node: $(strerror(errno))" );
        }
        //else
        {
            GLib.g_thread_init();
            FsoFramework.Threading.callDelegateOnNewThread( qmiListenerThread, null );
        }
    }

    private void qmiListenerThread( void* data )
    {

        while ( true )
        {
            assert( logger.debug( "qmi listener thread waiting for data from QMI..." ) );
            var bread = Posix.read( fd, buffer, buffer.length );
            assert( logger.debug( @"got $bread bytes" ) );
            Idle.add( () => { onInputFromQmi( buffer, bread ); return false; } );
        }
    }

    private void onInputFromQmi( char* data, ssize_t length )
    {
        // QMI messages always have the form FOO=BAR\nFOO2=BAR2\n..., we're not
        // interested in the last \n, so we nullterminate it there.
        data[length-1] = '\0';
        string message = (string)data;
        assert( logger.debug( @"QMI says: $(message.escape( """""" ))" ) );

        onUpdateFromQmi( FsoFramework.StringHandling.splitKeyValuePairs( message ) );
    }

    private void onUpdateFromQmi( GLib.HashTable<string,string> properties )
    {
        var state = properties.lookup( "STATE" ) ?? "unknown";
        message( @"onUpdateFromQmi with $(properties.size()) properties [state=$state]" );

        if ( state == "up" )
        {
            var addr = properties.lookup( "ADDR" ) ?? "unknown";
            var mask = properties.lookup( "MASK" ) ?? "unknown";
            var gway = properties.lookup( "GATEWAY" ) ?? "unknown";
            var dns1 = properties.lookup( "DNS1" ) ?? "unknown";
            var dns2 = properties.lookup( "DNS2" ) ?? "unknown";

            this.connectedWithNewDefaultRoute( RMNET_IFACE, addr, mask, gway, dns1, dns2 );
        }
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

        Posix.write( fd, cmdline, cmdline.length );
    }

    public async override void deactivate()
    {
        Posix.write( fd, "down", 5 );
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
