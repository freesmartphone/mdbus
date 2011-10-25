/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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

/**
 * @class Pdp.SamsungIpc
 *
 * Pdp Handler implements the Samsung IPC protocol handling for PDP sessions
 **/
class Samsung.PdpHandler : FsoGsm.PdpHandler
{
    private const string RMNET_IFACE = "rmnet0";

    //
    // private
    //

    /**
     * Define a new PDP context with the modem we will use in the following steps to setup
     * the GPRS data connection.
     **/
    private async void setupPdpContext( FsoGsm.ContextParams contextParams ) throws FreeSmartphone.Error
    {
        var channel = theModem.channel( "main") as Samsung.IpcChannel;
        unowned SamsungIpc.Response? response = null;

        var contextSetupMessage = SamsungIpc.Gprs.DefinePdpContextMessage();
        contextSetupMessage.setup( contextParams.apn );

        response = yield channel.enqueue_async( SamsungIpc.RequestType.SET,
            SamsungIpc.MessageType.GPRS_DEFINE_PDP_CONTEXT, contextSetupMessage.data );

        if ( response == null )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Did not receive a response from modem for PDP context setup" );

        var r = (SamsungIpc.Generic.PhoneResponseMessage*) response.data;
        if ( r.code == SamsungIpc.Gprs.ErrorType.UNAVAILABLE )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"It is not possible to setup a PDP context yet" );
    }

    /**
     * This will activate an already defined PDP context.
     **/
    private async void activatePdpContext( FsoGsm.ContextParams contextParams ) throws FreeSmartphone.Error
    {
        var channel = theModem.channel( "main") as Samsung.IpcChannel;
        unowned SamsungIpc.Response? response = null;

        var contextActMessage = SamsungIpc.Gprs.PdpContextMessage();
        contextActMessage.setup( contextParams.username, contextParams.password );

        response = yield channel.enqueue_async( SamsungIpc.RequestType.SET,
            SamsungIpc.MessageType.GPRS_PDP_CONTEXT, contextActMessage.data );

        if ( response == null )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Did not receive a response for PDP context activation" );
    }

    //
    // protected
    //

    protected override async void sc_activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( theModem.data().contextParams == null )
        {
            disconnected();
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "Context parameters not set" );
        }

        if ( theModem.data().contextParams.apn == null )
        {
            disconnected();
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "APN not set" );
        }

        yield setupPdpContext( theModem.data().contextParams );
        yield activatePdpContext( theModem.data().contextParams );

        // FIXME we now have to wait for the SamsungIpc.Message.GPRS_IP_CONFIGURATION
        // notification to arrive
    }

    protected override async void sc_deactivate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = theModem.channel( "main") as Samsung.IpcChannel;
    }

    //
    // public API
    //

    public async override void statusUpdate( string status, GLib.HashTable<string,Variant> properties )
    {
        assert_not_reached();
    }

    public override string repr()
    {
        return "<>";
    }
}

// vim:ts=4:sw=4:expandtab
