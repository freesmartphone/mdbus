/*
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

namespace PowerSupply
{

const string N900_CHARGER_I2C_FILE = "/dev/i2c-2";

const uint8 N900_CHARGER_I2C_DEVICE = 0x55;
const uint8 N900_CHARGER_READ_CAPACITY = 0x0b;

public errordomain I2C_ERROR
{
    SELECT_SLAVE_DEVICE,
    READ_FROM_DEVICE,
    WRITE_TO_DEVICE
}

/**
 * Implementation of org.freesmartphone.Device.PowerSupply for the Nokia N900 device
 **/
class N900 : FreeSmartphone.Device.PowerSupply,
             FreeSmartphone.Info,
             FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;

    private string sysfsnode;

    // internal (accessible for aggregate power supply)
    internal string name;
    internal string typ;
    internal FreeSmartphone.Device.PowerStatus status = FreeSmartphone.Device.PowerStatus.UNKNOWN;
    internal bool present;
    internal int fd = -1;

    internal int capacity = -1;

    public N900( FsoFramework.Subsystem subsystem, string sysfsnode )
    {
        this.subsystem = subsystem;
        this.sysfsnode = sysfsnode;

        fd = Posix.open( N900_CHARGER_I2C_FILE, Posix.O_RDWR );
        if ( fd == -1 )
        {
            logger.warning( @"Can't open $N900_CHARGER_I2C_FILE: $(strerror(errno)). Powersupply will not available." );
            return;
        }

        Idle.add( onIdle );
        Timeout.add_seconds( 15, onTimeout );

        //subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        //subsystem.registerServiceObjectWithPrefix( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.PowerSupplyServicePath, this );

        logger.info( "Created" );
    }

    public override string repr()
    {
        return @"<$sysfsnode>";
    }

    private void pushMaskedByteToI2C( int file, uint8 device, uint8 mask, uint8 command, uint8 value ) throws I2C_ERROR
    {
        if ( Posix.ioctl( fd, Linux.I2C.SLAVE, device) == -1)
        {
            throw new I2C_ERROR.SELECT_SLAVE_DEVICE( "Could not select slave device 0x%02X".printf( device ) );
        }
        int32 result = Linux.I2C.SMBUS.write_byte_data_masked (file, mask, command, value);
        if ( result == -1 )
        {
            throw new I2C_ERROR.WRITE_TO_DEVICE( "Could not write at 0x%02X:0x%02X".printf( device, command ) );
        }        
    }

    private void pushByteToI2C( int file, uint8 device, uint8 command, uint8 value ) throws I2C_ERROR
    {
        if ( Posix.ioctl( fd, Linux.I2C.SLAVE, device) == -1)
        {
            throw new I2C_ERROR.SELECT_SLAVE_DEVICE( "Could not select i2c slave device 0x%02X".printf( device ) );
        }
        int32 result = Linux.I2C.SMBUS.write_byte_data (file, command, value);
        if ( result == -1 )
        {
            throw new I2C_ERROR.WRITE_TO_DEVICE( "Could not write at 0x%02X:0x%02X".printf( device, command ) );
        }        
    }

    private uint8 pullByteFromI2C( int file, uint8 device, uint8 command ) throws I2C_ERROR
    {
        if ( Posix.ioctl( fd, Linux.I2C.SLAVE, device) == -1)
        {
            throw new I2C_ERROR.SELECT_SLAVE_DEVICE( "Could not select i2c slave device 0x%02X".printf( device ) );
        }
        int32 result = Linux.I2C.SMBUS.read_byte_data (file, command);
        if ( result == -1 )
        {
            throw new I2C_ERROR.READ_FROM_DEVICE( "Could not read at 0x%02X:0x%02X".printf( device, command ) );
        }
        return (uint8) result & 0xff;
    }

    private bool onTimeout()
    {
        /*
        logger.debug( "Reading capacity from i2c..." );

        var ok = Posix.ioctl( fd, Linux.I2C.SLAVE, N900_CHARGER_I2C_DEVICE );
        if ( ok < 0 )
        {
            logger.warning( @"Can't change I2C SLAVE: $(strerror(errno))." );
            return true;
        }
        
        var res = Linux.I2C.SMBUS.read_byte_data( fd, N900_CHARGER_READ_CAPACITY );
        if ( res < 0 )
        {
            logger.warning( @"Can't i2c read_byte_data: $(strerror(errno))." );
            return true; // mainloop: don't call us again
        }
        logger.debug( @"i2c reports capacity as $(res)" );
        capacity = res;
        */
        return true; // mainloop: call us again
    }

    public bool onIdle()
    {
        /*
        // trigger initial coldplug change notification, if we are on a real sysfs
        if ( sysfsnode.has_prefix( "/sys" ) )
        {
            assert( logger.debug( "Triggering initial coldplug change notification" ) );
            FsoFramework.FileHandling.write( "change", "%s/uevent".printf( sysfsnode ) );
        }
        else
        {
            assert( logger.debug( "Synthesizing initial coldplug change notification" ) );
            var uevent = FsoFramework.FileHandling.read( "%s/uevent".printf( sysfsnode ) );
            var parts = uevent.split( "\n" );
            var properties = new HashTable<string, string>( str_hash, str_equal );
            foreach ( var part in parts )
            {
#if DEBUG
                message( "%s", part );
#endif
                var elements = part.split( "=" );
                if ( elements.length == 2 )
                {
                    properties.insert( elements[0], elements[1] );
                }
            }
            aggregate.onPowerSupplyChangeNotification( properties );
        }
        */
        return false; // mainloop: don't call again
    }

    public bool isBattery()
    {
        return typ == "battery";
    }

    public bool isPresent()
    {
        /*
        var node = isBattery() ? "%s/present" : "%s/online";
        var value = FsoFramework.FileHandling.read( node.printf( sysfsnode ) );
        return ( value != null && value == "1" );
        */
        return true;
    }

    public int getCapacity()
    {
        return capacity;
    }

    //
    // FreeSmartphone.Info (DBUS API)
    //
    public async HashTable<string,Value?> get_info() throws DBus.Error
    {
        var res = new HashTable<string,Value?>( str_hash, str_equal );
        /*
        res.insert( "name", name );

        var dir = Dir.open( sysfsnode );
        var entry = dir.read_name();
        while ( entry != null )
        {
            if ( entry != "uevent" )
            {
                var filename = Path.build_filename( sysfsnode, entry );
                var contents = FsoFramework.FileHandling.read( filename );
                if ( contents != "" )
                {
                    res.insert( entry, contents );
                }
            }
            entry = dir.read_name();
        }
        */
        return res;
    }

    //
    // FreeSmartphone.Device.PowerStatus (DBUS API)
    //
    public async FreeSmartphone.Device.PowerStatus get_power_status() throws DBus.Error
    {
        return status;
    }

    public async int get_capacity() throws DBus.Error
    {
        return getCapacity();
    }
}

} /* namespace */

internal static string sysfs_root;
internal static string sys_devices_platform_msusb_hdrc;
internal PowerSupply.N900 instance;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // grab sysfs paths
    var config = FsoFramework.theConfig;
    sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
    sys_devices_platform_msusb_hdrc = "%s/devices/platform/musb_hdrc".printf( sysfs_root );
    
    instance = new PowerSupply.N900( subsystem, sys_devices_platform_msusb_hdrc );
    return "fsodevice.powersupply_n900";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.powersupply_n900 fso_register_function()" );
}

/**
 * This function gets called on plugin load time.
 * @return false, if the plugin operating conditions are present.
 * @note Some versions of glib contain a bug that leads to a SIGSEGV
 * in g_module_open, if you return true here.
 **/
/*public static bool g_module_check_init( void* m )
{
    var ok = FsoFramework.FileHandling.isPresent( Kernel26.SYS_CLASS_LEDS );
    return (!ok);
}
*/
