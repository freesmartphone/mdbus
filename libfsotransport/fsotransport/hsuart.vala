/*
 * Copyright (C) 2010 Simon Busch <morphis@gravedo.de>
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
using PalmPre;

//===========================================================================
public class FsoFramework.HsuartTransport : FsoFramework.BaseTransport
//===========================================================================
{
    public HsuartTransport( string portname )
    {
        base( portname );
    }

    public override bool open()
    {
        fd = Posix.open( name, Posix.O_RDWR | Posix.O_NOCTTY );
        if ( fd == -1 )
        {
            logger.warning( "could not open %s: %s".printf( name, Posix.strerror( Posix.errno ) ) );
            return false;
        }

        configure();

        return base.open();
    }

    public override string repr()
    {
        return "<Hsuart %s@%u (fd %d)>".printf( name, speed, fd );
    }

    /**
     * Configure the high speed to be ready for sending and receiving bytes.
     **/
    protected override void configure()
    {
        // Flush everything
        var flush = Hsuart.FlushType.RX_QUEUE |
                    Hsuart.FlushType.TX_QUEUE |
                    Hsuart.FlushType.RX_FIFO |
                    Hsuart.FlushType.TX_FIFO;

        Linux.ioctl(fd, Hsuart.IoctlType.FLUSH, flush);

        // Get current mode and modify it
        var mode = Hsuart.Mode();
        Linux.ioctl(fd, Hsuart.IoctlType.GET_UARTMODE, mode);

        mode.speed = Hsuart.SpeedType.SPEED_115K;
        mode.flags |= Hsuart.FlagType.PARITY_NONE;
        mode.flags |= Hsuart.FlagType.FLOW_CTRL_HW;
        Linux.ioctl(fd, Hsuart.IoctlType.SET_UARTMODE, mode);

        // We want flow control for the rx line
        Linux.ioctl(fd, Hsuart.IoctlType.RX_FLOW, Hsuart.RxFlowControlType.ON);
    }

    /**
     * This will suspend the transport. After it is suspend we can't send any more bytes
     * to the remote side.
     **/
    public override bool suspend()
    {
        int rc = 0;

        // We need to deactivate flow control so we don't get interrupted during the
        // suspend by the other side.
        rc = Posix.ioctl(fd, Hsuart.IoctlType.RX_FLOW, Hsuart.RxFlowControlType.OFF);
        if (rc < 0)
        {
            logger.error(@"Could not deactivate flow control for the transport!");
            return false;
        }

        // Check wether we have any bytes left to receive.
        rc = Posix.ioctl(fd, Hsuart.IoctlType.RX_BYTES, 0);
        if (rc > 0)
        {
            logger.error(@"Could not suspend the transport as we have bytes left to send.");
            return false;
        }

        // Drain all left bytes for transmission to the remote side. NOTE this will block
        // until all bytes are send or it timed out (2000ms).
        rc = Posix.ioctl(fd, Hsuart.IoctlType.TX_DRAIN, 2000);
        if (rc < 0)
        {
            logger.error(@"Could not drain the last bytes from hsuart buffer!");

            // Try again as non-blocking call; this will give us only the status of
            // transmission buffer and will not drain the bytes from the buffer.
            rc = Posix.ioctl(fd, Hsuart.IoctlType.TX_DRAIN, 0);
            logger.error(@"Status of tx is $(rc)");

            return false;
        }

        logger.debug(@"Successfully suspended the transport!");

        return true;
    }

    /**
     * Resume the transport so we can send and receive our bytes again.
     **/
    public override void resume()
    {
        int rc = 0;

        // Enable rx flow control again
        rc = Posix.ioctl(fd, Hsuart.IoctlType.RX_FLOW, Hsuart.RxFlowControlType.ON);
        if (rc < 0)
        {
            logger.error(@"Could not enable rx flow control!");
            return;
        }

        logger.debug(@"Successfully enabled rx flow control!");
    }
}

// vim:ts=4:sw=4:expandtab
