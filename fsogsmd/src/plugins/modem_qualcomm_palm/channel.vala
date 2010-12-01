/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
using FsoGsm;

public class MsmChannel : MsmCommandQueue, FsoGsm.Channel
{
    public FsoFramework.Transport transport { get; set; }
    public string name;
    
    public delegate void UnsolicitedHandler( string prefix, string response, string? pdu = null );

    private MsmUnsolicitedResponseHandler _urcHandler { get; set; }
    
    private Msmcomm.ModemControlStatus modemControlStatusOld { get; set; default = Msmcomm.ModemControlStatus.INACTIVE; }
    private bool restartRequested { get; set; default = false; }
    
    private MsmModemAgent _modemAgent;
    
    //
    // private API
    //

    /**
     * Handling the status updates from the low-lovel modem control layer
     **/
    private void onModemControlStatusUpdate(Msmcomm.ModemControlStatus status)
    {
        if ( status == Msmcomm.ModemControlStatus.ACTIVE )
        {
            Posix.sleep(2);
            syncWithModem();
            if ( restartRequested )
            {
                resetModem();
                restartRequested = false;
            }
        }
        
        modemControlStatusOld = status;
    }
   
    /**
     * Synchronize with the modem to have a common base for further commands (e.g. we can
     * recieve commands/responses from the modem)
     **/
    private async void syncWithModem()
    {
        theModem.logger.debug("sending test alive ...");
        try 
        {
            yield _modemAgent.commands.test_alive();
        }
        catch ( DBus.Error err0 )
        {
        }
        catch ( Msmcomm.Error err1 )
        {
        }
    }
   
    /**
     * Send the reset command to the modem
     **/
    private async void resetModem()
    {
        theModem.logger.debug("sending reset command ...");
        try
        {
            yield _modemAgent.commands.reset_modem();
        }
        catch ( DBus.Error err0 )
        {
        }
        catch ( Msmcomm.Error err1 )
        {
        }
    }
        
    //
    // public API
    //
    
    public MsmChannel( string name )
    {
        base( new FsoFramework.NullTransport() );
        this.name = name;
        theModem.registerChannel( name, this );
        theModem.signalStatusChanged.connect( onModemStatusChanged );
        
        restartRequested = true;
        
        _modemAgent = MsmModemAgent.instance();
        _urcHandler = new MsmUnsolicitedResponseHandler( _modemAgent );
    }

    public override async bool open()
    {
        theModem.logger.debug("MSMCHANNEL: open ...");
        
        // Let the modem agent initialise itself
        _modemAgent.setup();
        
        // Wait for modem agent to become ready 
        // FIXME maybe there is some better way to do this?
        Timeout.add_seconds( 5, () => {
            if (_modemAgent.ready) {
                open.callback();
                return false;
            }
            theModem.logger.debug("Modem agent is not ready yet ... waiting 5 seconds.");
            return true;
        });
        yield;
        
        // Connect to modem link layer status updates and reset the modem
        // to come in a well known state
        _modemAgent.management.status_update.connect(onModemControlStatusUpdate);
        _modemAgent.management.reset();
        
        // Setup up necessary handlers
        _urcHandler.setup();
        
        return true;
    }
  
    public override async void close()
    {
    }
    
    public void registerUnsolicitedHandler( UnsolicitedHandler urchandler )
    {
    }   
    
    public void injectResponse( string response )
    {
        assert_not_reached();
    }

    public async bool suspend()
    {
        // FIXME Release resource?
        return true;
    }

    public async bool resume()
    {
        return true;
    }

    public void onModemStatusChanged( Modem modem, Modem.Status status )
    {
    }
}
