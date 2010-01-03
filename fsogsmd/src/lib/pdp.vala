/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 * @interface PdpHandler
 **/
public interface FsoGsm.PdpHandler : GLib.Object
{
    public abstract async void activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void deactivate();
}

/**
 * @class AtPdpHandler
 *
 * This PdpHandler uses AT commands and ppp to implement the Pdp handler interface
 **/
public class FsoGsm.AtPdpHandler : FsoGsm.PdpHandler, FsoFramework.AbstractObject
{
    private FsoFramework.GProcessGuard ppp;

    public override string repr()
    {
        return "<>";
    }

    private void onPppStopped()
    {
        //FIXME: check for expected or unexpected stop
        logger.debug( "ppp has been stopped" );
    }

    //
    // public API
    //

    public async void activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( ppp != null && ppp.isRunning() )
        {
            return;
        }

        // build commandline
        var data = theModem.data();

        var cmdline = new string[] { data.pppCommand, theModem.pppPort() };
        foreach ( var option in data.pppOptions )
        {
            cmdline += option;
        }

        // prepare modem

        // launch ppp
        ppp = new FsoFramework.GProcessGuard();
        ppp.stopped.connect( onPppStopped );
        ppp.launch( cmdline );
    }

    public async void deactivate()
    {
        if ( ppp == null )
        {
            return;
        }
        if ( !ppp.isRunning() )
        {
            return;
        }
        ppp = null; // this will stop the process
    }
}
