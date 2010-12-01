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

using Gee;

/**
 * @class WrapSms
 *
 * A helper class
 */
public class WrapSms
{
    public Sms.Message message;
    public int index;

    public WrapSms( owned Sms.Message message, int index = -1 )
    {
        this.index = index;
        this.message = (owned) message;

        if ( this.message.type == Sms.Type.DELIVER )
        {
#if DEBUG
            debug( "WRAPSMS: Created for message hash %s", this.message.hash() );
#endif
        }
        else
        {
            FsoFramework.theLogger.warning( "SMS type %d not yet supported".printf( this.message.type ) );
        }
    }

    ~WrapSms()
    {
        if ( message.type == Sms.Type.DELIVER )
        {
#if DEBUG
            debug( "WRAPSMS: Destructed for message hash %s", this.message.hash() );
#endif
        }
    }
}

/**
 * @class WrapHexPdu
 *
 * A helper class
 */
public class WrapHexPdu
{
    public string hexpdu;
    public uint tpdulen;
    public int transaction_index;

    public WrapHexPdu( string hexpdu, uint tpdulen )
    {
        this.hexpdu = hexpdu;
        this.tpdulen = tpdulen;
        this.transaction_index = -1;
    }
}

/**
 * @interface SmsHandler
 */
public interface FsoGsm.SmsHandler : FsoFramework.AbstractObject
{
    public abstract SmsStorage storage { get; set; }

    public abstract async void handleIncomingSmsOnSim( uint index );
    public abstract async void handleIncomingSms( string hexpdu, int tpdulen );
    public abstract async void handleIncomingSmsReport( string hexpdu, int tpdulen );

    public abstract uint16 lastReferenceNumber();
    public abstract uint16 nextReferenceNumber();

    public abstract Gee.ArrayList<WrapHexPdu> formatTextMessage( string number, string contents, bool requestReport );
    public abstract void storeTransactionIndizesForSentMessage( Gee.ArrayList<WrapHexPdu> hexpdus );
}
