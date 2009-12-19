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
    FROZEN,
    DEAD,
}

public struct FsoFramework.TransportSpec
{
    public TransportSpec( string type, string name = "", uint speed = 0, bool raw = true, bool hard = true )
    {
        this.type = type;
        this.name = name;
        this.speed = speed;
        this.raw = raw;
        this.hard = hard;
    }

    public void create()
    {
        if ( transport != null )
        {
            warning( "Transport already created" );
            return;
        }

        switch ( type )
        {
            case "serial":
                transport = new FsoFramework.SerialTransport( name, speed, raw, hard );
                break;
            case "pty":
                transport = new FsoFramework.PtyTransport();
                break;
            case "unix":
            case "udp":
            case "tcp":
                transport = new FsoFramework.SocketTransport( type, name, speed );
                break;
            case "null":
                transport = new FsoFramework.NullTransport();
                break;
            default:
                warning( @"Invalid transport type $type. Using NullTransport" );
                transport = new FsoFramework.NullTransport();
                break;
        }
    }

    public bool open()
    {
        if ( transport == null )
        {
            create();
        }
        return transport.open();
    }

    public string type;
    public string name;
    public uint speed;
    public bool raw;
    public bool hard;
    public Transport transport;
}

//===========================================================================
public abstract class FsoFramework.Transport : Object
{
    /**
     * @returns true, if the @a transport is open; else false.
     */
    public abstract bool isOpen();
    /**
     * Open the transport. @returns true, if successful; else false.
     */
    public abstract bool open();
    /**
     * Close the transport. Closing an already closed transport is allowed.
     **/
    public abstract void close();
    /**
     * Return the transport identification.
     **/
    public abstract string getName();
    /**
     * Set delegates for being called when there is something to read or there has been an exception.
     **/
    public abstract void setDelegates( TransportFunc? readfunc, TransportFunc? hupfunc );
    /**
     * Get delegates
     **/
    public abstract void getDelegates( out TransportFunc? readfun, out TransportFunc? hupfun );
    /**
     * Set priorities for reading and writing
     **/
    public abstract void setPriorities( int rp, int wp );
    /**
     * Set buffered or unbuffered mode
     **/
    public abstract void setBuffered( bool on );
    /**
     * Write data to the transport and wait for a response.
     * Read the response into a buffer provided and owned by the caller.
     * @warning This will only succeed if you don't use delegates!
     **/
    public abstract int writeAndRead( void* wdata, int wlength, void* rdata, int rlength, int maxWait = 1000 );
    /**
     * Read data from the transport into buffer provided and owned by caller.
     **/
    public abstract int read( void* data, int length );
    /**
     * Write data to the transport.
     **/
    public abstract int write( void* data, int length );
    /**
     * Pause reading and writing from/to the transport.
     **/
    public abstract void freeze();
    /**
     * Resume reading and writing from/to the transport.
     **/
    public abstract void thaw();
    /**
     * Create @a FsoFramework.Transport as indicated by @a type
     **/
    public static Transport? create( string type, string name = "", uint speed = 0, bool raw = true, bool hard = true )
    {
        switch ( type )
        {
            case "serial":
                return new FsoFramework.SerialTransport( name, speed, raw, hard );
            case "pty":
                return new FsoFramework.PtyTransport();
            case "unix":
            case "udp":
            case "tcp":
                return new FsoFramework.SocketTransport( type, name, speed );
            default:
                return null;
        }
    }
    /**
     * Should not be here, but wants to be accessed from the command queue
     **/
    public FsoFramework.Logger logger;
}

//===========================================================================
public delegate void FsoFramework.TransportFunc( Transport transport );
public delegate int FsoFramework.TransportDataFunc( void* data, int length, Transport transport );
public delegate bool FsoFramework.TransportBoolFunc( Transport transport );
