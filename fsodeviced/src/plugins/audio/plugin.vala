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

using Gee;

namespace Hardware
{

/**
 * Audio Manager
 **/
class AudioManager : FreeSmartphone.Device.Audio, FsoFramework.AbstractObject
{
    private const string MODULE_NAME = "fsodevice.audio";

    private FsoFramework.Subsystem subsystem;
    private FsoDevice.AudioRouter router;
    private string routertype;
    private Gee.HashMap<string,FsoDevice.AudioPlayer> players;
    private string playertypes;

    public AudioManager( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;

        subsystem.registerServiceName( FsoFramework.Device.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Device.ServiceDBusName,
                                         FsoFramework.Device.AudioServicePath,
                                         this );

        // gather requested player types and instanciate object
        players = new Gee.HashMap<string,FsoDevice.AudioPlayer>();
        var playernames = config.stringListValue( MODULE_NAME, "player_type", {} );

        playertypes = "";

        foreach ( var playername in playernames )
        {
            var typename = "";

            switch ( playername )
            {
                case "alsa":
                    typename = "PlayerLibAlsa";
                    break;
                case "canberra":
                    typename = "PlayerLibCanberra";
                    break;
                case "gstreamer":
                    typename = "PlayerGstreamer";
                    break;
                default:
                    typename = "PlayerUnknown";
                    break;
            }
            var playertyp = GLib.Type.from_name( typename );
            if ( playertyp == GLib.Type.INVALID )
            {
                logger.warning( @"Can't instanciate requested player type $typename" );
            }
            else
            {
                var player = (FsoDevice.AudioPlayer) GLib.Object.new( playertyp );
                foreach ( var format in player.supportedFormats() )
                {
                    if ( players[format] == null ) // might have already been claimed
                    {
                        assert( logger.debug( @"Registering $playername ($typename) to handle format $format" ) );
                        players[format] = player;
                    }
                    else
                    {
                        assert( logger.debug( @"Can't register $playername ($typename) to handle format $format (already handled)" ) );
                    }
                }
                playertypes += @"%s$typename".printf( playertypes != "" ? "," : "" );
            }
        }

        if ( players.size == 0 )
        {
            logger.warning( "No player_type requested or available; will not be able to play audio" );
            var player = new FsoDevice.NullPlayer();
            foreach ( var format in player.supportedFormats() )
            {
                players[format] = player;
                playertypes = "NullPlayer";
            }
        }

        // gather requested router and instanciate object
        var routername = config.stringValue( MODULE_NAME, "router_type", "(not set)" );

        var typename = "";

        switch ( routername )
        {
            case "alsa":
                typename = "RouterLibAlsa";
                break;
            default:
                typename = "NullRouter";
                break;
        }
        var routertyp = GLib.Type.from_name( typename );
        if ( routertyp == GLib.Type.INVALID )
        {
            logger.warning( @"Can't instanciate requested router type $typename; will not be able to route audio" );
            router = new FsoDevice.NullRouter();
        }
        else
        {
            router = (FsoDevice.AudioRouter) GLib.Object.new( routertyp );
        }

        logger.info( "Created." );
    }

    public override string repr()
    {
        return playertypes != null ? @"<$playertypes>" : "<>";
    }

    //
    // FreeSmartphone.Device.Sound (DBUS API)
    //

    //
    // Scenario
    public async string[] get_available_scenarios() throws DBus.Error
    {
        return router.availableScenarios();
    }

    public async HashTable<string,Value?> get_info() throws DBus.Error
    {
        var dict = new HashTable<string,Value?>( str_hash, str_equal );

        /*
        var value = Value( typeof(string[] ) );
        string[] formats = { "wav" };
        value.take_
        value = formats;

        /*
        dict.insert( "formats", value );
        Value scenario = get_scenario();
        dict.insert( "scenario", value );
        Value scenarios = get_available_scenarios();
        dict.insert( "scenarios", value );
        */
        return dict;
    }

    public async string get_scenario() throws DBus.Error
    {
        return router.currentScenario();
    }

    public async string pull_scenario() throws FreeSmartphone.Device.AudioError, DBus.Error
    {
        return router.pullScenario();
    }

    public async void push_scenario( string scenario ) throws FreeSmartphone.Error, DBus.Error
    {
        if ( !router.isScenarioAvailable( scenario ) )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Scenario not available" );
        }
        router.pushScenario( scenario );
    }

    public async void set_scenario( string scenario ) throws FreeSmartphone.Error, DBus.Error
    {
        if ( !router.isScenarioAvailable( scenario ) )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Scenario not available" );
        }
        router.setScenario( scenario );
    }

    public async void save_scenario( string scenario ) throws FreeSmartphone.Error, DBus.Error
    {
        if ( !router.isScenarioAvailable( scenario ) )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Scenario not available" );
        }
        router.saveScenario( scenario );
    }

    //
    // Sound
    public async void play_sound( string name, int loop, int length ) throws FreeSmartphone.Device.AudioError, FreeSmartphone.Error, DBus.Error
    {
        var parts = name.split( "." );
        if ( parts.length == 0 )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Could not guess media format; need an extension" );
        }
        var extension = parts[ parts.length - 1 ]; // darn, I miss negative array indices
        var player = players[extension];
        if ( player == null )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Format .$extension not handled by any player" );
        }
        yield player.play_sound( name, loop, length );
    }

    public async void stop_all_sounds() throws DBus.Error
    {
        foreach ( var player in players.values )
        {
            yield player.stop_all_sounds();
        }
    }

    public async void stop_sound( string name ) throws FreeSmartphone.Error, DBus.Error
    {
        var parts = name.split( "." );
        if ( parts.length == 0 )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Could not guess media format; need an extension" );
        }
        var extension = parts[ parts.length - 1 ]; // darn, I miss negative array indices
        var player = players[extension];
        if ( player == null )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Format .$extension not handled by any player" );
        }
        yield player.stop_sound( name );
    }
}

} /* namespace Hardware */

internal Hardware.AudioManager instance;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    instance = new Hardware.AudioManager( subsystem );
    return "fsodevice.audio";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.audio fso_register_function()" );
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
