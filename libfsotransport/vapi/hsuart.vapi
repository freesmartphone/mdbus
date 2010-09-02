/**
 * (C) 2010 Simon Busch <morphis@gravedo.de>
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
 **/
 
namespace PalmPre.Hsuart
{
    [CCode (cname = "int", has_type_id = false, cprefix = "HSUART_", cheader_filename = "hsuart.h")]
    public enum SpeedType
    {
        SPEED_38K,
        SPEED_115K,
        SPEED_3686K,
    }

    [CCode (cname = "int", has_type_id = false, cprefix = "HSUART_MODE_", cheader_filename = "hsuart.h")]
    public enum FlagType 
    {
        LOOPBACK,
        FLOW_CTRL_BIT,
        FLOW_CTRL_MASK,
        FLOW_CTRL_NONE,
        FLOW_CTRL_HW,
        FLOW_CTRL_SW,
        PARITY_BIT,
        PARITY_MASK,
        PARITY_NONE,
        PARITY_ODD,
        PARITY_EVEN,
    }
    
    /*
     * Specifies target HSUART_IOCTL_CLEAR_FIFO/HSUART_IOCTL_FLUSH
     */

    [CCode (cname = "int", has_type_id = false, cprefix = "HSUART_", cheader_filename = "hsuart.h")]
    public enum FlushType
    {
        RX_FIFO,
        TX_FIFO,
        RX_QUEUE,
        TX_QUEUE,
    }
    
    /*
     *  Rx flow control
     */
     
    [CCode (cname = "int", has_type_id = false, cprefix = "HSUART_RX_FLOW_", cheader_filename = "hsuart.h")]
    public enum RxFlowControlType
    {
        OFF, // DEPRECATED
        AUTO,
        ON,
    }
    
    [CCode (cname = "int", has_type_id = false, cprefix = "HSUART_IOCTL_", cheader_filename = "hsuart.h")]
    public enum IoctlType
    {
        GET_VERSION,
        GET_BUF_INF,
        GET_UARTMODE,
        SET_UARTMODE,
        RESET_UART,
        CLEAR_FIFO,
        GET_STATS,
        SET_RXLAT,
        TX_DRAIN,
        RX_BYTES,
        RX_FLOW,
        FLUSH,
    }
    
    [CCode (cname = "struct hsuart_mode", cheader_filename = "hsuart.h")]
    public struct Mode
    {
        public int speed;
        public int flags;
    }
    
    [CCode (cname = "struct hsuart_stat", cheader_filename = "hsuart.h")]
    public struct Stat
    {
        public ulong tx_bytes;
        public ulong rx_bytes;
        public ulong rx_dropped;
    }
} // namespace PalmPre.Hsuart
