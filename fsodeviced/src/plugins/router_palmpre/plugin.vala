/**
 * Copyright (C) 2010 Simon Busch <morphis@gravedo.de>
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

const string FSO_PALMPRE_AUDIO_CONF_PATH = "/etc/freesmartphone/palmpre/default.conf";
const string FSO_PALMPRE_AUDIO_SCRUN_PATH = "/sys/devices/platform/twl4030_audio/scrun";
const string FSO_PALMPRE_AUDIO_SCINIT_PATH = "/sys/devices/platform/twl4030_audio/scinit";

namespace Router
{

private class KernelScriptInterface
{
    public static void loadAndStoreScriptFromFile(string filename)
    {
        if (FsoFramework.FileHandling.isPresent(filename))
        {
            string script = FsoFramework.FileHandling.read(filename);
            FsoFramework.FileHandling.write(FSO_PALMPRE_AUDIO_SCINIT_PATH, script);
        }
    }

    public static void runScript(string script_name)
    {
        FsoFramework.FileHandling.write(FSO_PALMPRE_AUDIO_SCRUN_PATH, script_name);
    }
}

/**
 * palmpre Audio Router
 **/
class PalmPre : FsoDevice.BaseAudioRouter
{
    private const string MODULE_NAME = "fsodevice.router_palmpre";
    private List<string> allscenarios;
    private string currentscenario;
    private GLib.Queue<string> scenarios;

    public PalmPre()
    {
        initScenarios();
    }

    private void initScenarios()
    {
        string scenarios_file = "";
        scenarios = new GLib.Queue<string>();

        FsoFramework.SmartKeyFile audioconf = new FsoFramework.SmartKeyFile();
        if (audioconf.loadFromFile(FSO_PALMPRE_AUDIO_CONF_PATH))
        {
            var defaultscenario = audioconf.stringValue("audio", "default_scenario", "phone_front_speaker");
            var data_path = audioconf.stringValue("audio", "data_path", "/etc/freesmartphone/palmpre/scenarii");

            var sections = audioconf.sectionsWithPrefix=("scenario.");
            foreach (var section in sections)
            {
                var scenario = sections.split(".")[1];
                if (scenario != "")
                {
                    KernelScriptInterface.loadFromFile
                        ("%s/%s.txt".printf(data_path, scenario);
                    allscenarios.append(scenario);
                }
            }
        }
    }

    public override bool isScenarioAvailable( string scenario )
    {
        return (scenario in allscenarios.keys);
    }

    public override string[] availableScenarios()
    {
        string[] list = {};
        foreach (var key in allscenarios.keys)
            list += key;
        return list;
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
        KernelScriptInterface.runScript(scenario);
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
    return "fsodevice.router_palmpre";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.router_palmpre fso_register_function()" );
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
