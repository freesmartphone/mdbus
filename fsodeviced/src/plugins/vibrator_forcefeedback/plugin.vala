/*
 * Copyright (C) 2013 Rico Rommel <rico@bierrommel.de>
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

namespace Vibrator
{

    internal const string PLUGIN_NAME = "fsodevice.vibrator_forcefeedback";
    internal const string DEFAULT_DEVICE_NODE = "/dev/input/rumble";

class ForceFeedback : FreeSmartphone.Device.Vibrator, FsoFramework.AbstractObject
{

    FsoFramework.Subsystem subsystem;
    private string eventnode;
    internal static int vib_fd;
    int eff_id = -1;

    public ForceFeedback( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;

        this.eventnode = config.stringValue( PLUGIN_NAME, "inputnode", DEFAULT_DEVICE_NODE);
        logger.debug("devicenode is %s".printf(eventnode));

        vib_fd = Posix.open( this.eventnode, Posix.O_RDWR );
            
        if ( vib_fd != -1 )
        {            
    
            subsystem.registerObjectForService<FreeSmartphone.Device.Vibrator>( FsoFramework.Device.ServiceDBusName, FsoFramework.Device.VibratorServicePath, this );
            logger.info( "Created" );
        }
        
        else
        {
            logger.error( "No forcefeedback vibrator device found; vibrator object will not be available" );
        }

    }

    ~ForceFeedback()
    {
        //remove effect
        Posix.ioctl( vib_fd, Linux.Input.EVIOCRMFF, eff_id );
        Posix.close( vib_fd );
    }

    public override string repr()
    {
        return @"<$eventnode>";
    }

    //don't know how to implement this in vala
    [CCode (cname = "setvibration")]
    public static extern int16 setvibration(int fd, int *id, int length, int delay, int strength, int repeat);


    //
    // FreeSmartphone.Device.Vibrator (DBUS API)
    //
/*    public async string get_name() throws DBusError, IOError
    {
        return PLUGIN_NAME;
    }
*/

    public async void vibrate_pattern( int pulses, int delay_on, int delay_off, int strength ) throws FreeSmartphone.Error, DBusError, IOError
    {

        setvibration(vib_fd, &eff_id, delay_on, delay_off, strength, pulses); 

    }


    public async void vibrate( int milliseconds, int strength ) throws FreeSmartphone.Error, DBusError, IOError
    {

        setvibration( vib_fd, &eff_id, milliseconds, 0, strength, 1 );

    }


    public async void stop() throws FreeSmartphone.Error, DBusError, IOError
    {
        if ( eff_id != -1 )
        {
            var inputevent = Linux.Input.Event() { time = Posix.timeval() { tv_sec=0, tv_usec=0 }, type=(uint16)Linux.Input.EV_FF, code=(int16)eff_id, value = 0 };
            Posix.write( vib_fd, &inputevent, sizeof( Linux.Input.Event ) );
        }
    }
}

} /* namespace */

Vibrator.ForceFeedback instance;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{

    instance = new Vibrator.ForceFeedback( subsystem );
    return Vibrator.PLUGIN_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.vibrator_forcefeedback fso_register_function()" );
}

/**
 * This function gets called on plugin load time.
 * @return false, if the plugin operating conditions are present.
 * @note Some versions of glib contain a bug that leads to a SIGSEGV
 * in g_module_open, if you return true here.
 **/
/*public static bool g_module_check_init( void* m )
{

}
*/

// vim:ts=4:sw=4:expandtab
