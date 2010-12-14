/*
 * (C) 2010 Klaus 'mrmoku' Kurzmann <mok@fluxnetz.de>
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

namespace Kernel26
{
    internal const string NODE_NAME_GOVERNOR = "scaling_governor";
    internal const string NODE_NAME_MIN_FREQUENCY = "scaling_min_freq";
    internal const string NODE_NAME_MAX_FREQUENCY = "scaling_max_freq";

/**
 * @class Kernel26.CpuFreq
 *
 * A module to tweak cpufreq depending on configuration and battery condition
 **/
internal class CpuFreq : FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;

    public CpuFreq( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;

        _setGovernor( default_governor );
        if ( max_frequency > 0 )
            _setFrequency( NODE_NAME_MAX_FREQUENCY, max_frequency );
        if ( min_frequency > 0 )
            _setFrequency( NODE_NAME_MIN_FREQUENCY, min_frequency );

        logger.info( "Created" );
    }

    public override string repr()
    {
        return @"<>";
    }

    private void _checkAndAddCpu( string path )
    {
    }

    private void _setGovernor( string governor )
    {
        logger.debug( @"setting governor to $governor" );
        foreach (string node in sysfs_cpufreq_roots)
        {
            FsoFramework.FileHandling.write( governor, node + "/scaling_governor" );
        }
    }

    private void _setFrequency( string node_name, int frequency )
    {
        logger.debug( @"setting $node_name to $frequency" );
        foreach ( string node in sysfs_cpufreq_roots )
        {
            FsoFramework.FileHandling.write( frequency.to_string(), node + "/" + node_name );
        }
    }

}
} /* namespace */


internal static const string MODULE_NAME = "fsodevice.kernel26_cpufreq";
internal Kernel26.CpuFreq instance;
internal static string sysfs_root;
internal static List< string > sysfs_cpufreq_roots;
internal static string default_governor;
internal static int min_frequency;
internal static int max_frequency;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    var config = FsoFramework.theConfig;

    sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );

    string sys_devices_cpu = "%s/devices/system/cpu".printf( sysfs_root );

    try
    {
        var dir = Dir.open( sys_devices_cpu, 0 );
        string entry = dir.read_name();
        while ( entry != null )
        {
            if ( /cpu[0-9]/i.match( entry ) )
            {
                string node = Path.build_filename( sys_devices_cpu, entry ) + "/cpufreq";
                if ( FileUtils.test( node, FileTest.IS_DIR ) )
                    sysfs_cpufreq_roots.append( node );
            }
            entry = dir.read_name();
        }
    }
    catch ( FileError e )
    {
        FsoFramework.theLogger.error( @"Failed collecting sysfs nodes for cpufreq: $(e.message)" );
        return "";
    }

    if ( sysfs_cpufreq_roots.length() == 0 )
    {
        FsoFramework.theLogger.info( "No cpufreq sysfs nodes found" );
        return "";
    }

    default_governor = config.stringValue( MODULE_NAME, "default_governor", "ondemand" ).down();
    min_frequency = config.intValue( MODULE_NAME, "min_frequency", 0 );
    max_frequency = config.intValue( MODULE_NAME, "max_frequency", 0 );

    instance = new Kernel26.CpuFreq( subsystem );

    return "fsodevice.kernel26_cpufreq";
}


[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsodevice.kernel26_cpufreq fso_register_function()" );
}

