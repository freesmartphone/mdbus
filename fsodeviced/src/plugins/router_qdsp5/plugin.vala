/**
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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


namespace Router
{

/**
 * Qdsp5 Audio Router
 **/
class Qdsp5 : FsoDevice.BaseAudioRouter
{
    private const string MODULE_NAME = "fsodevice.router_qdsp5";
    private GLib.Queue<string> scenarios;
    string currentscenario;

    public Qdsp5()
    {
        scenarios = new GLib.Queue<string>();
        currentscenario = "unknown";
        updateScenarioIfChanged( "gsmhandset" );
    }

    private void updateScenarioIfChanged( string scenario )
    {
        if ( currentscenario != scenario )
        {
            switch ( scenario )
            {
                case "gsmhandset":
                    Playwav2.do_route_audio_rpc( 0, false, false );
                    break;

                default:
                    warning( @"Don't know how to handle scenario $scenario" );
                    break;
            }

            currentscenario = scenario;
        }
    }


    public override bool isScenarioAvailable( string scenario )
    {
        return true;
    }

    public override string[] availableScenarios()
    {
        return { "gsmhandset" };
    }

    public override string currentScenario()
    {
        return currentscenario;
    }

    public override string pullScenario() throws FreeSmartphone.Device.AudioError
    {
        scenarios.pop_head();
        var scenario = scenarios.peek_head();
        if ( scenario == null )
        {
            throw new FreeSmartphone.Device.AudioError.SCENARIO_STACK_UNDERFLOW( "No scenario left to activate" );
        }
        setScenario( scenario );
        return scenario;
    }

    public override void pushScenario( string scenario )
    {
        setScenario( scenario );
        scenarios.push_head( scenario );
    }

    public override void setScenario( string scenario )
    {
        updateScenarioIfChanged( scenario );
    }

    public override void saveScenario( string scenario )
    {
    }
}

} /* namespace Router */

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // instances will be created on demand by fsodevice.audio
    return "fsodevice.router_qdsp5";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.router_qdsp5 fso_register_function()" );
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

// vim:ts=4:sw=4:expandtab
