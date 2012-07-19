/*
 * Copyright (C) 2011-2012 Simon Busch <morphis@gravedo.de>
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

using Gee;
using FsoGsm;

/**
 * @class Samsung.SmsHandler
 **/
public class Samsung.SmsHandler : FsoGsm.AbstractSmsHandler
{
    //
    // protected
    //

    protected override async string retrieveImsiFromSIM()
    {
        var channel = modem.channel( "main" ) as Samsung.IpcChannel;
        unowned SamsungIpc.Response? response = null;

        // first we retrieve the IMSI from SIM card to create a unique storage for all SMS
        // messages for this card otherwise we use a "unknown" storage to store incoming
        // SMS messages
        var rsimreq = SamsungIpc.Security.RSimAccessRequestMessage();
        rsimreq.command = SamsungIpc.Security.RSimCommandType.READ_BINARY;
        rsimreq.fileid = (uint16) Constants.simFilesystemEntryNameToCode( "EFimsi" );

        response = yield channel.enqueue_async( SamsungIpc.RequestType.GET, SamsungIpc.MessageType.SEC_RSIM_ACCESS, rsimreq.data );

        return ( response != null ? SamsungIpc.Security.RSimAccessResponseMessage.get_file_data( response ) : "unknown" );
    }

    protected override async bool acknowledgeSmsMessage()
    {
        var channel = modem.channel( "main" ) as Samsung.IpcChannel;
        unowned SamsungIpc.Response? response = null;

        var ackmsg = SamsungIpc.Sms.DeliverReportMessage();
        ackmsg.type = SamsungIpc.Sms.MessageType.STATUS_REPORT;
        ackmsg.error = SamsungIpc.Sms.AcknowledgeErrorType.NO_ERROR;
        ackmsg.msg_tpid = 0;
        // ackmsg.unk = 0;

        response = yield channel.enqueue_async( SamsungIpc.RequestType.EXEC,
            SamsungIpc.MessageType.SMS_DELIVER_REPORT, ackmsg.data );

        if ( response == null )
        {
            logger.error( @"Failed to acknowledge incoming SMS message!" );
            return false;
        }

        return true;
    }

    protected override async bool readSmsMessageFromSIM( uint index, out string hexpdu, out int tpdulen )
    {
        hexpdu = "";
        tpdulen = 0;
        return true;
    }

    protected override async void fillStorageWithMessageFromSIM()
    {
    }

    //
    // public API
    //

    public SmsHandler( FsoGsm.Modem modem )
    {
        base( modem );
    }

    public override string repr()
    {
        return storage != null ? storage.repr() : "<None>";
    }
}

// vim:ts=4:sw=4:expandtab
