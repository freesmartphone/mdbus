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

using GLib;

//===========================================================================
public errordomain FsoFramework.TransportError
{
    UNABLE_TO_OPEN,
    UNABLE_TO_WRITE,
}

//===========================================================================
public enum FsoFramework.TransportState
{
    CLOSED,
    OPEN,
    ALIVE,
    DEAD,
}

//===========================================================================
public abstract interface FsoFramework.Transport : Object
{
    //public abstract void write( void* data, uint length ) throws TransportError;
}

//===========================================================================
public class FsoFramework.BaseTransport : FsoFramework.Transport, Object
{
    protected Logger logger;

    protected string name;
    protected uint speed;
    protected int fd = -1;

    private IOChannel channel;

    private uint readwatch;
    private int readpriority;
    private uint writewatch;
    private int writepriority;

    protected TransportHupFunc hupfunc;
    protected TransportReadFunc readfunc;

    protected ByteArray buffer;

    protected void restartWriter()
    {
        writewatch = channel.add_watch_full( writepriority, IOCondition.OUT, writeCallback );
    }

    //
    // public API
    //
    public BaseTransport( string name,
                          uint speed = 0,
                          TransportHupFunc? hupfunc = null,
                          TransportReadFunc? readfunc = null,
                          int rp = 0,
                          int wp = 0 )
    {
        this.name = name;
        this.hupfunc = hupfunc;
        this.readfunc = readfunc;
        readpriority = rp;
        writepriority = wp;
        buffer = new ByteArray();

        // create and configure the logger
        logger = FsoFramework.createLogger( "transport" );
        logger.setReprDelegate( repr );
        logger.debug( "created" );
    }

    public virtual bool open()
    {
        assert( fd != -1 );
        // setup watches, if we have delegates
        if ( hupfunc != null || readfunc != null )
        {
            channel = new IOChannel.unix_new( fd );
            channel.set_encoding( null );
            channel.set_buffer_size( 32768 );
            readwatch = channel.add_watch_full( readpriority, IOCondition.IN | IOCondition.HUP, actionCallback );
        }
        // we might have already queued something up in the buffer
        if ( buffer.len > 0 )
            restartWriter();

        return true;
    }

    public void close()
    {
        if ( readwatch != 0 )
            Source.remove( readwatch );
        channel = null;
        if ( fd != -1 )
            Posix.close( fd );
        logger.debug( "closed" );
    }

    public bool isOpen()
    {
        return ( fd != -1 );
    }

    public virtual string repr()
    {
        return "<BaseTransport fd %d>".printf( fd );
    }

    public int read( void* data, int len )
    {
        assert( fd != -1 );
        ssize_t bytesread = Posix.read( fd, data, len );
        return (int)bytesread;
    }

    public int _write( void* data, int len )
    {
        assert( fd != -1 );
        ssize_t byteswritten = Posix.write( fd, data, len );
        return (int)byteswritten;
    }

    public int write( void* data, int len )
    {
        var restart = ( fd != -1 && buffer.len == 0 );
        var temp = new uint8[len];
        Memory.copy( temp, data, len );
        buffer.append( temp );

        if ( restart )
            restartWriter();
        return len;
    }

    public bool actionCallback( IOChannel source, IOCondition condition )
    {
        //debug( "actionCallback, condition = %d", condition );
        if ( IOCondition.IN == condition && readfunc != null )
        {
            readfunc( this );
            return true;
        }
        if ( IOCondition.HUP == condition && hupfunc != null )
            hupfunc( this );
        return false;
    }

    public bool writeCallback( IOChannel source, IOCondition condition )
    {
        //debug( "writeCallback, condition = %d", condition );

        int len = 64 > buffer.len? (int)buffer.len : 64;

        var byteswritten = write( buffer.data, len  );
        //debug( "writeCallback: wrote %d bytes", (int)byteswritten );
        buffer.remove_range( 0, (int)byteswritten );

        return ( buffer.len != 0 );
    }
}

/*
//===========================================================================
public class TransportLibGsm0710mux : TransportLibGsm0710mux
{
    Gsm0710mux.Manager manager;
    Gsm0710mux.ChannelInfo channelinfo;

    public TransportLibGsm0710mux()
    {
        manager = new Gsm0710mux.Manager();
        var version = manager.getVersion();
        var hasAutoSession = manager.hasAutoSession();
        debug( "TransportLibGsm0710mux created, using libgsm0710mux version %s; autosession is %s".printf( version, hasAutoSession.to_string() ) );

    }

    public void open() throws TransportError
    {

    
}
*/

//===========================================================================
public delegate void FsoFramework.TransportReadFunc( Transport transport );
public delegate void FsoFramework.TransportHupFunc( Transport transport );
