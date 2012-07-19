/*
 * Copyright (C) 2011-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 * Copyright (C) 2012 Denis 'GNUtoo' Carikli <GNUtoo@no-log.org>

 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

extern int forwarder_start(char * conf_path);
extern void forwarder_stop();

namespace FsoAudio.GsmVoiceForwarder
{
    public const string MODULE_NAME = "fsoaudio.gsmvoice_alsa_forwarder";
}

class AlsaloopForwarder : FsoFramework.AbstractObject
{
    private char *  configFilePath;
    private unowned Thread<void *> alsaloopThread = null;
    private Mutex mutex = new  Mutex();

    public AlsaloopForwarder(char * path)
    {
        this.configFilePath = path;
    }

    private void * startWrapper()
    {
        int ret = 0;

        assert ( logger.info( "Alsaloop started" ) );

        ret = forwarder_start(this.configFilePath);

        /* At that point the forwarder_start thread exited  */
        this.alsaloopThread = null;
        assert ( logger.info( @"Alsaloop exited with status $(ret)" ) );

        return null;
    }

    public void start()
    {
        mutex.lock();
        try
        {
            if (alsaloopThread == null)
                alsaloopThread = Thread.create<void *>( this.startWrapper, false );
            else
                assert ( logger.error( @"FIXME: Are multiple calls at the same time supported by the modem driver?" ) );
        }
        catch ( ThreadError e )
        {
            assert ( logger.error( @"Error: $(e.message)" ) );
            return;
        }
        mutex.unlock();
    }

    public void stop(){
        forwarder_stop();
    }

    public override string repr()
    {
        return "<>";
    }
}

class FsoAudio.GsmVoiceForwarder.Plugin : FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;
    private FreeSmartphone.GSM.Call gsmcallproxy;
    private AlsaloopForwarder forwarder;

    //
    // Private API
    //
    private void onCallStatusSignal( int id, FreeSmartphone.GSM.CallStatus status, GLib.HashTable<string,Variant> properties )
    {
        assert( logger.debug( @"onCallStatusSignal $id w/ status $status" ) );
        switch ( status )
        {
            case FreeSmartphone.GSM.CallStatus.ACTIVE:
                this.forwarder.start();
                break;

            case FreeSmartphone.GSM.CallStatus.RELEASE:
                this.forwarder.stop();
                break;

            default:
                assert( logger.debug( @"Unhandled call status $status" ) );
                break;
        }
    }

    //
    // Public API
    //
    public Plugin( FsoFramework.Subsystem subsystem )
    {
        char * configurationPath = FsoFramework.Utility.machineConfigurationDir() + "/alsaloop.conf";
        this.subsystem = subsystem;
        this.forwarder = new AlsaloopForwarder(configurationPath);

        try
        {
            gsmcallproxy = Bus.get_proxy_sync<FreeSmartphone.GSM.Call>( BusType.SYSTEM, "org.freesmartphone.ogsmd", "/org/freesmartphone/GSM/Device", DBusProxyFlags.DO_NOT_AUTO_START );
            gsmcallproxy.call_status.connect( onCallStatusSignal );
        }
        catch ( Error e )
        {
            logger.error( @"Could not hook to fsogsmd: $(e.message)" );
        }
    }

    public override string repr()
    {
        return "<>";
    }
}

internal FsoAudio.GsmVoiceForwarder.Plugin instance;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    instance = new FsoAudio.GsmVoiceForwarder.Plugin( subsystem );
    return FsoAudio.GsmVoiceForwarder.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsoaudio.gsmvoice_alsa_forwarder fso_register_function" );
}
