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
 */

/**
 * Mediator Interfaces and Base Class
 **/

public abstract interface FsoGsm.Mediator
{
}

public abstract class FsoGsm.AbstractMediator : FsoGsm.Mediator, GLib.Object
{
    protected void enqueue( FsoGsm.AtCommand command, string chars, FsoGsm.ResponseHandler handler )
    {
        debug( "FsoGsm.AbstractMediator::enqueueing %s", Type.from_instance( command ).name() );
        var channel = theModem.channel("main");
        channel.enqueue( command, chars, handler );
    }

    protected void enqueueAsync( FsoGsm.AtCommand command, string chars, SourceFunc? callback, string[] response )
    {
        debug( "FsoGsm.AbstractMediator::enqueueing %s", Type.from_instance( command ).name() );
        var channel = theModem.channel("main");
        channel.enqueueAsync( command, chars, callback, response );
    }

    protected void checkResponseOk( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        if ( command.validateOk( response ) != AtResponse.OK )
        {
            //FIXME gather better error message out of response status
            throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( "AT command ERROR" );
        }
    }

    protected void checkResponseValid( FsoGsm.AtCommand command, string[] response ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error, DBus.Error
    {
        if ( command.validate( response ) != AtResponse.VALID )
        {
            //FIXME gather better error message out of response status
            throw new FreeSmartphone.GSM.Error.DEVICE_FAILED( "AT command ERROR" );
        }
    }
}

//
// org.freesmartphone.GSM.Device.*
//
public abstract class FsoGsm.DeviceGetAntennaPower : FsoGsm.AbstractMediator
{
    public bool antenna_power { get; set; }
    public abstract async void run() throws FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceGetFeatures : FsoGsm.AbstractMediator
{
    public GLib.HashTable<string,GLib.Value?> features { get; set; }
    public abstract async void run() throws FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceGetInformation : FsoGsm.AbstractMediator
{
    public GLib.HashTable<string,GLib.Value?> info { get; set; }
    public abstract async void run() throws FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceGetMicrophoneMuted : FsoGsm.AbstractMediator
{
    public bool muted { get; set; }
    public abstract async void run() throws FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceGetPowerStatus : FsoGsm.AbstractMediator
{
    public string status { get; set; }
    public int level { get; set; }
    public abstract async void run() throws FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceGetSimBuffersSms : FsoGsm.AbstractMediator
{
    public bool buffers { get; set; }
    public abstract async void run() throws FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceGetSpeakerVolume : FsoGsm.AbstractMediator
{
    public int volume { get; set; }
    public abstract async void run() throws FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceSetMicrophoneMuted : FsoGsm.AbstractMediator
{
    public abstract async void run( bool muted ) throws FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceSetSimBuffersSms : FsoGsm.AbstractMediator
{
    public abstract async void run( bool buffers ) throws FreeSmartphone.Error;
}

public abstract class FsoGsm.DeviceSetSpeakerVolume : FsoGsm.AbstractMediator
{
    public abstract async void run( int volume ) throws FreeSmartphone.Error;
}

//
// org.freesmartphone.GSM.Network.*
//
public abstract class FsoGsm.NetworkListProviders : FsoGsm.AbstractMediator
{
    public FreeSmartphone.GSM.NetworkProvider[] providers { get; set; }
    public abstract async void run() throws FreeSmartphone.Error;
}
