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
 * @interface PdpHandler
 **/
public abstract class FsoGsm.PdpHandler : FsoFramework.AbstractObject
{
    public async abstract void activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public async abstract void deactivate();

    public async abstract void statusUpdate( string status, GLib.HashTable<string,Value?> properties );
}

/**
 * @class AtPdpHandler
 *
 * This PdpHandler uses AT commands and ppp to implement the Pdp handler interface
 **/
public class FsoGsm.AtPdpHandler : FsoGsm.PdpHandler
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

    public async override void activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( ppp != null && ppp.isRunning() )
        {
            return;
        }

        // build ppp command line
        var data = theModem.data();
        var cmdline = new string[] { data.pppCommand, theModem.allocateDataPort() };
        // add modem specific options to command line
        foreach ( var option in data.pppOptions )
        {
            cmdline += option;
        }

        /*
        // prepare modem
        var cmd = theModem.createAtCommand<V250D>( "D" );
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( "*99#" ) );
        checkResponseOk( cmd, response );
        */

        // launch ppp
        ppp = new FsoFramework.GProcessGuard();
        ppp.stopped.connect( onPppStopped );

        if ( !ppp.launch( cmdline ) )
        {
            throw new FreeSmartphone.Error.SYSTEM_ERROR( "Could not launch ppp binary" );
        }
    }

    public async override void deactivate()
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

    public async override void statusUpdate( string status, GLib.HashTable<string,Value?> properties )
    {
        //FIXME: communicate with fsonetworkd to offer new route to internet
    }
}
