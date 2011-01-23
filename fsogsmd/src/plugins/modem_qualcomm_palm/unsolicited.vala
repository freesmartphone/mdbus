/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *                         Simon Busch <morphis@gravedo.de>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 */

using GLib;
using FsoGsm;
using FsoFramework;

public enum MsmUrcType
{
    INVALID,
    RESET_RADIO_IND,
    CALL_ORIGINATION,
    EXTENDED_FILE_INFO,
}

internal class WaitForUnsolicitedResponseData
{
    public GLib.SourceFunc callback;
    public MsmUrcType urc_type;
    public GLib.Variant? response;
}

/**
 * MSM Unsolicited Base Class and Handler
 **/
public class MsmUnsolicitedResponseHandler : AbstractObject
{
    private GLib.List<WaitForUnsolicitedResponseData> urc_waiters;

    //
    // public API
    //

    public MsmUnsolicitedResponseHandler()
    {
        urc_waiters = new GLib.List<WaitForUnsolicitedResponseData>();
    }

    public void setup()
    {
        var channel = theModem.channel( "main" ) as MsmChannel;

        channel.misc_service.radio_reset_ind.connect( () => {
            notifyUnsolicitedResponse( MsmUrcType.RESET_RADIO_IND, null );
        });

        channel.sim_service.sim_status.connect( ( urc_name ) => {
            /* Check if the channel is already ready for processing */
            if (!channel.is_ready())
                return;

            switch ( urc_name )
            {
                /*
                 * General sim events
                 */
                case "sim-inserted":
                    updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED );
                    break;

                case "sim-init-completed":
                    var pbhandler = theModem.pbhandler as MsmPhonebookHandler;
                    pbhandler.initializeStorage();
                    break;

                /*
                 * All pin status events
                 */
                case "pin1-enabled":
                    MsmData.pin1_status = MsmPinStatus.ENABLED;
                    break;
                case "pin1-disabled":
                    MsmData.pin1_status = MsmPinStatus.DISABLED;
                    break;
                case "pin1-blocked":
                    MsmData.pin1_status = MsmPinStatus.BLOCKED;
                    updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PUK_REQUIRED );
                    break;
                case "pin1-verified":
                    updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.READY );
                    break;
                case "pin1-perm-blocked":
                    MsmData.pin1_status = MsmPinStatus.PERM_BLOCKED;
                    updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.UNKNOWN );
                    break;
                case "pin2-enabled":
                    MsmData.pin2_status = MsmPinStatus.ENABLED;
                    break;
                case "pin2-disabled":
                    MsmData.pin2_status = MsmPinStatus.DISABLED;
                    break;
                case "pin2-blocked":
                    MsmData.pin2_status = MsmPinStatus.BLOCKED;
                    updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PUK_REQUIRED );
                    break;
                case "pin2-verified":
                    updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.READY );
                    break;
                case "pin2-perm-blocked":
                    MsmData.pin2_status = MsmPinStatus.PERM_BLOCKED;
                    updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.UNKNOWN );
                    break;
            }
        });

        channel.phonebook_service.extended_file_info_event.connect( ( info ) => {
            GLib.Variant vi = info;
            notifyUnsolicitedResponse( MsmUrcType.EXTENDED_FILE_INFO, vi );
        });

        channel.phonebook_service.ready.connect( ( book_type ) => {
            var pbhandler = theModem.pbhandler as MsmPhonebookHandler;
            if ( pbhandler != null)
            {
                pbhandler.syncPhonebook( book_type );
            }
        });
    }

    public override string repr()
    {
        return "<>";
    }

    /**
     * Lets wait for a specific unsolicited response to recieve and return it's payload
     * after it finaly recieves.
     **/
    public async GLib.Variant waitForUnsolicitedResponse( MsmUrcType type )
    {
        // Create waiter and yield until urc occurs
        var data = new WaitForUnsolicitedResponseData();
        data.urc_type = type;
        data.callback = waitForUnsolicitedResponse.callback;
        urc_waiters.append( data );
        yield;

        // Urc occured so we can return the recieved message structure to the caller who
        // has now not longer to wait for the urc
        urc_waiters.remove( data );
        return data.response;
    }

    /**
     * Notify the occurence of a unsolicted response to the modem agent which informs all
     * registered clients for this type of message.
     **/
    public async void notifyUnsolicitedResponse( MsmUrcType type, GLib.Variant? response )
    {
        var waiters = retriveUrcWaiters( type );

        // awake all waiters for the notified urc type and supply them the message payload
        foreach (var waiter in waiters )
        {
            waiter.response = response;
            waiter.callback();
        }
    }

    private GLib.List<WaitForUnsolicitedResponseData> retriveUrcWaiters( MsmUrcType type )
    {
        var result = new GLib.List<WaitForUnsolicitedResponseData>();

        foreach ( var waiter in urc_waiters )
        {
            if ( waiter.urc_type == type )
            {
                result.append( waiter );
            }
        }

        return result;
    }
}
