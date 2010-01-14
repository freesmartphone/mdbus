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
 **/

/**
 * @class MuxPppPdpHandler
 *
 * This PppHandler uses ppp over a multiplexed line to implement the Pdp handler interface
 **/
public class FsoGsm.MuxPppPdpHandler : FsoGsm.AtPdpHandler
{
    private LibGsm0710muxTransport transport;

    int inputfd;
    int outputfd;

    public override string repr()
    {
        return "<>";
    }

    protected override string[] buildCommandLine()
    {
        var data = theModem.data();
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
        var transport = theModem.channel( "data" ).transport as LibGsm0710muxTransport;
        transport.startForwardingToPPP( inputfd, outputfd );
    }

    protected override void shutdownTransport()
    {
        var transport = theModem.channel( "data" ).transport as LibGsm0710muxTransport;

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
