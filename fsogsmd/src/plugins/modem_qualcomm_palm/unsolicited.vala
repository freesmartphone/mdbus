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
    NETWORK_STATE_INFO,
    OPERATION_MODE,
    PIN1_VERIFIED,
}

internal class WaitForUnsolicitedResponseData
{
    public GLib.SourceFunc callback;
    public MsmUrcType urc_type;
    public GLib.Variant? response;
    public uint timeout;
    public SourceFunc? timeout_func;
}

internal void updateSimPinStatus( MsmPinStatus status )
{
    if ( status == MsmPinStatus.BLOCKED )
    {
        updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PUK_REQUIRED );
    }
    else if ( status == MsmPinStatus.PERM_BLOCKED )
    {
        // FIXME Is this correct? Means PERM_BLOCKED from msm that puk2 is required?
        updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PUK2_REQUIRED );
    }

    MsmData.pin_status = status;
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

        channel.state_service.operation_mode.connect( ( info ) => {
            // if modem goes offline we have to re-authenticate against the sim card
            if ( info.mode == Msmcomm.OperationMode.OFFLINE )
            {
                updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED );
            }

            notifyUnsolicitedResponse( MsmUrcType.OPERATION_MODE, info );
        });

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
                    updateMsmSimAuthStatus( FreeSmartphone.GSM.SIMAuthStatus.READY );
                    var pbhandler = theModem.pbhandler as MsmPhonebookHandler;
                    pbhandler.initializeStorage();
                    break;

                /*
                 * All pin status events
                 * NOTE: we completly ignore the PIN2 type msmcomm offers here!
                 */
                case "pin1-enabled":
                    updateSimPinStatus( MsmPinStatus.ENABLED );
                    break;
                case "pin1-disabled":
                    updateSimPinStatus( MsmPinStatus.DISABLED );
                    break;
                case "pin1-blocked":
                    updateSimPinStatus( MsmPinStatus.BLOCKED );
                    break;
                case "pin1-perm-blocked":
                    updateSimPinStatus( MsmPinStatus.PERM_BLOCKED );
                    break;
                case "pin1-verified":
                    notifyUnsolicitedResponse( MsmUrcType.PIN1_VERIFIED, null );
                    break;
            }
        });

        channel.phonebook_service.ready.connect( ( book_type ) => {
            var pbhandler = theModem.pbhandler as MsmPhonebookHandler;
            if ( pbhandler != null)
            {
                pbhandler.syncPhonebook( book_type );
            }
        });

        channel.network_service.network_status.connect( ( name, info ) => {
            switch ( name )
            {
                case "rssi":
                case "srv-changed":
                    var status = new GLib.HashTable<string,Variant>( str_hash, str_equal );

                    status.insert( "act", networkDataServiceToActString( info.data_service ) );
                    status.insert( "mode", "automatic" );
                    status.insert( "strength", (int) info.rssi );
                    status.insert( "registration", networkRegistrationStatusToString( info.reg_status ) );
                    status.insert( "lac", "unknown" );
                    status.insert( "cid", "unknown" );
                    status.insert( "provider", info.operator_name );
                    status.insert( "display", info.operator_name );
                    status.insert( "code", "unknown" );
                    status.insert( "pdp.registration", "unknown" );
                    status.insert( "pdp.lac", "unknown" );
                    status.insert( "pdp.cid", "unknown" );

                    var obj = FsoGsm.theModem.theDevice<FreeSmartphone.GSM.Network>();
                    obj.status( status );

                    MsmData.network_info.rssi = info.rssi;
                    MsmData.network_info.ecio = info.ecio;
                    MsmData.network_info.operator_name = info.operator_name;
                    MsmData.network_info.reg_status = info.reg_status;
                    MsmData.network_info.service_status = info.service_status;

                    if ( info.with_time_update )
                    {
                        var data = theModem.data();

                        // some modems strip the leading zero for one-digit chars, so we have to reassemble it
                        var timestr = "%02d/%02d/%02d,%02d:%02d:%02d".printf( (int) info.time.year, (int) info.time.month, (int) info.time.day, 
                                                                              (int) info.time.hours, (int) info.time.minutes, (int) info.time.seconds );
                        var formatstr = "%y/%m/%d,%H:%M:%S";
                        var t = GLib.Time();
                        t.strptime( timestr, formatstr );
                        data.networkTimeReport.setTime( (int) t.mktime() );
                    }

                    notifyUnsolicitedResponse( MsmUrcType.NETWORK_STATE_INFO, info );
                    triggerUpdateNetworkStatus();

                    break;
            }
        });

        channel.call_service.call_status.connect( ( name, info ) => {
            var call_info = createCallInfo( info );
            switch ( name )
            {
                case "orig":
                    notifyUnsolicitedResponse( MsmUrcType.CALL_ORIGINATION, info );
                    break;
                case "orig-fwd-status":
                    break;
                case "end":
                    theModem.callhandler.handleEndingCall( call_info );
                    break;
                case "incom":
                    theModem.callhandler.handleIncomingCall( call_info );
                    break;
                case "connect":
                    theModem.callhandler.handleConnectingCall( call_info );
                    break;
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
    public async GLib.Variant waitForUnsolicitedResponse( MsmUrcType type, int timeout = 0, SourceFunc? timeout_func = null )
    {
        logger.debug( @"Create an new urc waiter with type = $(type)" );

        // Create waiter and yield until urc occurs
        var data = new WaitForUnsolicitedResponseData();
        data.urc_type = type;
        data.callback = waitForUnsolicitedResponse.callback;
        data.timeout_func = timeout_func;
        urc_waiters.append( data );

        // if user specified a timeout for the wait we add it here and return to the
        // caller when the timeout occured
        if ( timeout > 0 )
        {
            data.timeout = Timeout.add_seconds( timeout, () => {
                urc_waiters.remove( data );

                if ( data.timeout_func != null )
                {
                    data.timeout_func();
                }

                data.callback();
                return false;
            } );
        }

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
        logger.debug( @"Awake all waiters for urc type $(type)" );
        var waiters = retriveUrcWaiters( type );

        // awake all waiters for the notified urc type and supply them the message payload
        foreach (var waiter in waiters )
        {
            // check wether this waiter has a timeout
            if ( waiter.timeout > 0 )
            {
                Source.remove( waiter.timeout );
                waiter.timeout = 0;
            }

            urc_waiters.remove( waiter );
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
