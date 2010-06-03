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
using Gee;
using FsoGsm;

/**
 * @class QualcommPalm.Modem
 *
 * This modem plugin supports the Qualcomm MSM chipset used on Palm Pre (Plus).
 *
 * The modem uses a binary protocol which has been implemented in libmsmcomm.
 **/
class QualcommPalm.Modem : FsoGsm.AbstractModem
{
    private const string AT_CHANNEL_NAME = "data";
    private const string MSM_CHANNEL_NAME = "main";
    private bool launch_msmcommd = false;
    private string workdir_msmcommd = "/tmp";
    
    construct 
    {
        launch_msmcommd = config.boolValue("fsogsm.modem_qualcomm_palm", "launch_msmcommd", false);
        workdir_msmcommd = config.stringValue("fsogsm.modem_qualcomm_palm", "workdir_msmcommd", "/tmp");
    }

    public override string repr()
    {
        return "<>";
    }
    
    private bool launchMsmcommDaemon(bool restart)
    {
        if (Msmcomm.isDaemonRunning()) {
            if (restart) {
                logger.info("Msmcomm daemon is already running; we kill it now!");
                Msmcomm.shutdownDaemon();
            }
            else {
                logger.info("Msmcomm daemon is already running, but should not be restarted -> let it running");
                return true;
            }
        }
        
        if (!Msmcomm.launchDaemon(workdir_msmcommd)) {
            logger.error("Could not launch the Msmcomm daemon - that is bad, everything else will even fail");
            return false;
        }
        
        logger.info("Msmcomm daemon was successfully started");
        
        Thread.usleep(1000 * 1000);
        
        return true;
    }
    
    private void shutdownMsmcommDaemon()
    {
        if (Msmcomm.isDaemonRunning()) {
            logger.info("Shutdown Msmcomm daemon");
            Msmcomm.shutdownDaemon();
        }
        else {
            logger.error("Msmcomm daemon could not be shut down as it is not running anymore. Maybe it was killed or died itself?");
        }
    }
    
    protected override bool powerOn()
    {
        /* As per configuration option we have to launch the msmcomm daemon
         * before the channel and transport are opened as both depend on it */
        var result = false;
        if (launch_msmcommd && launchMsmcommDaemon(true) || !launch_msmcommd) 
            result = true;
        return result;
    }
    
    protected override void powerOff()
    {
        if (launch_msmcommd)
            shutdownMsmcommDaemon();
    }

    protected override void createChannels()
    {
#if 0
        // create AT channel for data use
        var datatransport = FsoFramework.Transport.create( data_transport, data_port, data_speed );
        var parser = new FsoGsm.StateBasedAtParser();
        new FsoGsm.AtChannel( AT_CHANNEL_NAME, datatransport, parser );
#endif
        
        // create MAIN channel
        var maintransport = FsoFramework.Transport.create( modem_transport, modem_port, modem_speed );
        if (maintransport != null)
            new MsmChannel( MSM_CHANNEL_NAME, maintransport );
    }

    protected override FsoGsm.Channel channelForCommand( FsoGsm.AtCommand command, string query )
    {
        // nothing to do here as qualcomm_palm only has one AT channel
        return channels[ AT_CHANNEL_NAME ];
    }

    protected override void registerCustomMediators( HashMap<Type,Type> mediators )
    {
        registerMsmMediators( mediators );
    }

    public async void openAuxChannel()
    {
/*
        // create AT channel for data use
        var datatransport = FsoFramework.Transport.create( data_transport, data_port, data_speed );
        var parser = new FsoGsm.StateBasedAtParser();
        var channel = new FsoGsm.AtChannel( AT_CHANNEL_NAME, datatransport, parser );

        var ok = yield channel.open();

        if ( ok )
        {
            debug( "COMPANION AT CHANNEL OPEN OK" );
        }
        else
        {
            debug( "COMPANION AT CHANNEL OPEN FAILED" );
        }
*/
    }
}

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    FsoFramework.theLogger.debug( "qualcomm_palm fso_factory_function" );
    return "fsogsm.modem_qualcomm_palm";
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
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
