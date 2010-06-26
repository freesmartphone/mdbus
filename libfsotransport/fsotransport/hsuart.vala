/**
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
    
    protected override void configure()
    {
        // Flush everything
        var flush = Hsuart.FlushType.RX_QUEUE | 
                    Hsuart.FlushType.TX_QUEUE |
                    Hsuart.FlushType.RX_FIFO |
                    Hsuart.FlushType.TX_FIFO;
        
        Linux.ioctl(fd, Hsuart.IoctlType.FLUSH, flush);
        
        // Get current mode and modify it
        Hsuart.Mode mode;
        Linux.ioctl(fd, Hsuart.IoctlType.GET_UARTMODE, out mode);
        
        mode.speed = Hsuart.SpeedType.SPEED_115K;
        mode.flags |= Hsuart.FlagType.PARITY_NONE;
        mode.flags |= Hsuart.FlagType.FLOW_CTRL_HW;
        Linux.ioctl(fd, Hsuart.IoctlType.SET_UARTMODE, mode);
        
        // We want flow control for the rx line
        Linux.ioctl(fd, Hsuart.IoctlType.RX_FLOW, Hsuart.RxFlowControlType.ON);
    }
}


