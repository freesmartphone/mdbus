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
     * Transport Configure the transport. @returns true, if successful; else false.
     **/
    public abstract string getName();
    /**
     * Set delegates being called when there is something to read or there has been an exception.
     **/
    public abstract void setDelegates( TransportReadFunc? readfunc, TransportHupFunc? hupfunc );
    /**
     * Get delegates
     **/
    public abstract void getDelegates( out TransportReadFunc? readfun, out TransportHupFunc? hupfun );
    /**
     * Set priorities for reading and writing
     **/
    public abstract void setPriorities( int rp, int wp );
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
}

//===========================================================================
public delegate void FsoFramework.TransportReadFunc( Transport transport );
public delegate void FsoFramework.TransportHupFunc( Transport transport );
