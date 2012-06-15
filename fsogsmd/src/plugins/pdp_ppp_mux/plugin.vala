/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

using GLib;

/**
 * @class Pdp.PppMux
 *
 * This PdpHandler uses ppp over a multiplexed line to implement the Pdp handler interface
 **/
public class Pdp.PppMux : FsoGsm.AtPdpHandler
{
    public const string MODULE_NAME = "fsogsm.pdp_ppp_mux";

    private FsoGsm.LibGsm0710muxTransport transport;

    int inputfd;
    int outputfd;

    public override string repr()
    {
        return "<>";
    }

    protected override string[] buildCommandLine()
    {
        var data = modem.data();
        var cmdline = new string[] { data.pppCommand };
        // MUX is not a tty
        cmdline += "notty";
        // modem-specific options
        foreach ( var option in data.pppOptions )
        {
            cmdline += option;
        }
        return cmdline;
    }

    protected async override void setupTransport()
    {
        // start forwarding to ppp
        var transport = modem.channel( "data" ).transport as FsoGsm.LibGsm0710muxTransport;
        transport.startForwardingToPPP( inputfd, outputfd );
    }

    protected override void shutdownTransport()
    {
        var transport = modem.channel( "data" ).transport as FsoGsm.LibGsm0710muxTransport;

        if ( transport.isForwardingToPPP() )
        {
            // FIXME: check whether transport is still in data mode...,
            // and if so, try to return gracefully to command mode
            transport.stopForwardingToPPP();
        }
    }

    protected override bool launchPppDaemon( string[] cmdline )
    {
        ppp = new FsoFramework.GProcessGuard();
        return ppp.launchWithPipes( cmdline, out inputfd, out outputfd );
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
    FsoFramework.theLogger.debug( "pdp_ppp_mux fso_factory_function" );
    return Pdp.PppMux.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}

// vim:ts=4:sw=4:expandtab
