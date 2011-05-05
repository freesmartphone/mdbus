/*
 * server.vala - dbus server implementation, parameter validation
 *
 * (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

//===========================================================================
using GLib;
using CONST;

//===========================================================================
[DBus (name = "org.freesmartphone.GSM.MUX")]
public errordomain DBusMuxerError
{
    CHANNEL_TAKEN,
    NO_CHANNEL,
    NO_SESSION,
    SESSION_ALREADY_OPEN,
    SESSION_OPEN_ERROR,
}

//===========================================================================
[DBus (name = "org.freesmartphone.GSM.MUX")]
public abstract interface OrgFreesmartphoneGsmMux
{
    public abstract string GetVersion() throws DBus.Error, DBusMuxerError;
    public abstract bool HasAutoSession() throws DBus.Error, DBusMuxerError;
    public abstract void OpenSession( bool advanced, int framesize, string commtype, string portname, int portspeed ) throws DBus.Error, DBusMuxerError;
    public abstract void CloseSession() throws DBus.Error, DBusMuxerError;
    public abstract async void AllocChannel( string name, int channel, out string path, out int allocated_channel ) throws DBus.Error, DBusMuxerError;
    public abstract void ReleaseChannel( string name ) throws DBus.Error, DBusMuxerError;
    public abstract void SetWakeupThreshold( uint seconds, uint waitms ) throws DBus.Error, DBusMuxerError;
    public abstract void SetStatus( int channel, string status ) throws DBus.Error, DBusMuxerError;
    public signal void Status( int channel, string status );
    public abstract void TestCommand( uint8[] data ) throws DBus.Error, DBusMuxerError;
}

//===========================================================================
public class Server : OrgFreesmartphoneGsmMux, Object
{
    DBus.Connection conn;
    dynamic DBus.Object dbus;

    Gsm0710mux.Manager manager;

    public Server()
    {
        try
        {
            assert( logger.debug( "DBus-Server: created" ) );
            conn = DBus.Bus.get( DBus.BusType.SYSTEM );
            dbus = conn.get_object( DBUS_BUS_NAME, DBUS_OBJ_PATH, DBUS_INTERFACE );
        }
        catch ( DBusMuxerError e )
        {
            logger.error( @"DBus-Server: $(e.message)" );
        }

        manager = new Gsm0710mux.Manager();
    }

    ~Server()
    {
        assert( logger.debug( "DBus-Server: destructed" ) );
    }

    //
    // DBus API
    //

    public string GetVersion() throws DBus.Error, DBusMuxerError
    {
        return manager.getVersion();
    }

    public bool HasAutoSession() throws DBus.Error, DBusMuxerError
    {
        return manager.hasAutoSession();
    }

    public void OpenSession( bool advanced, int framesize, string commtype, string portname, int portspeed ) throws DBus.Error, DBusMuxerError
    {
        try
        {
            manager.openSession( advanced, framesize, commtype, portname, portspeed );
        }
        catch ( Gsm0710mux.MuxerError e )
        {
            if ( e is Gsm0710mux.MuxerError.SESSION_ALREADY_OPEN )
                throw new DBusMuxerError.SESSION_ALREADY_OPEN( e.message );
            else if ( e is Gsm0710mux.MuxerError.SESSION_OPEN_ERROR )
                throw new DBusMuxerError.SESSION_OPEN_ERROR( e.message );
            else
                throw e;
        }
    }

    public void CloseSession() throws DBus.Error, DBusMuxerError
    {
        try
        {
            manager.closeSession();
        }
        catch ( Gsm0710mux.MuxerError e )
        {
            if ( e is Gsm0710mux.MuxerError.NO_SESSION )
                throw new DBusMuxerError.NO_SESSION( e.message );
        }
    }

    public async void AllocChannel( string name, int channel, out string path, out int allocated_channel ) throws DBus.Error, DBusMuxerError
    {
        assert( logger.debug( @"AllocChannel requested for name $name, requested channel $channel" ) );

        var ci = new Gsm0710mux.ChannelInfo();
        ci.tspec = new FsoFramework.TransportSpec( "pty" );
        ci.consumer = name;
        ci.number = channel;

        var number = -1;

        try
        {
            number = yield manager.allocChannel( ci );
        }
        catch ( Gsm0710mux.MuxerError e )
        {
            if ( e is Gsm0710mux.MuxerError.NO_SESSION )
                throw new DBusMuxerError.NO_SESSION( e.message );
            else if ( e is Gsm0710mux.MuxerError.CHANNEL_TAKEN )
                throw new DBusMuxerError.CHANNEL_TAKEN( e.message );
            else if ( e is Gsm0710mux.MuxerError.NO_CHANNEL )
                throw new DBusMuxerError.NO_CHANNEL( e.message );
            else if ( e is Gsm0710mux.MuxerError.SESSION_OPEN_ERROR )
                throw new DBusMuxerError.SESSION_OPEN_ERROR( e.message );
            else throw e;
        }

        path = ci.tspec.transport.getName();
        allocated_channel = number;
    }

    public void ReleaseChannel( string name ) throws DBus.Error, DBusMuxerError
    {
        try
        {
            manager.releaseChannel( name );
        }
        catch ( Gsm0710mux.MuxerError e )
        {
            if ( e is Gsm0710mux.MuxerError.NO_SESSION )
                throw new DBusMuxerError.NO_SESSION( e.message );
            else if ( e is Gsm0710mux.MuxerError.NO_CHANNEL )
                throw new DBusMuxerError.NO_CHANNEL( e.message );
            else
                throw e;
        }
    }

    public void SetWakeupThreshold( uint seconds, uint waitms ) throws DBus.Error, DBusMuxerError
    {
        manager.setWakeupThreshold( seconds, waitms );
    }

    public void SetStatus( int channel, string status ) throws DBus.Error, DBusMuxerError
    {
        try
        {
            manager.setStatus( channel, status );
        }
        catch ( Gsm0710mux.MuxerError e )
        {
            if ( e is Gsm0710mux.MuxerError.NO_SESSION )
                throw new DBusMuxerError.NO_SESSION( e.message );
            else if ( e is Gsm0710mux.MuxerError.NO_CHANNEL )
                throw new DBusMuxerError.NO_CHANNEL( e.message );
            else
                throw e;
        }
    }

    public void TestCommand( uint8[] data ) throws DBus.Error, DBusMuxerError
    {
        try
        {
            manager.testCommand( data );
        }
        catch ( Gsm0710mux.MuxerError e )
        {
            if ( e is Gsm0710mux.MuxerError.NO_SESSION )
                throw new DBusMuxerError.NO_SESSION( e.message );
            else if ( e is Gsm0710mux.MuxerError.NO_CHANNEL )
                throw new DBusMuxerError.NO_CHANNEL( e.message );
            else
                throw e;
        }
    }
}

// vim:ts=4:sw=4:expandtab
