/**
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 * Copyright (C) 2010 Denis 'GNUtoo' Carikli <GNUtoo@no-log.org>
 *                    Klaus 'mrmoku' Kurzmann <mok@fluxnetz.de>
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

using GLib;
using FsoGsm;


class LowLevel.Nokia900 : FsoGsm.LowLevel, FsoFramework.AbstractObject
{
    public enum PowerState
    {
        NONE,
        ON_STARTED,
        ON,
        ON_RESET,
        ON_FAILED,
        OFF_STARTED,
        OFF_WAITING,
        OFF
    }

    public enum RapuType
    {
        TYPE_1,
        TYPE_2
    }

    public enum PhonetLink
    {
        NONE = 0,
        DOWN,
        UP
    }

    public enum PowerEvent
    {
        NONE = 0,
        PHONET_LINK_UP = 1,
        PHONET_LINK_DOWN,
        ON,
        ON_TIMEOUT,
        REBOOT_TIMEOUT,
        OFF,
        OFF_IMMEDIATELY,
        OFF_TIMEOUT,
        OFF_COMPLETE,
    }

    public const string MODULE_NAME = "fsogsm.lowlevel_nokia900";

    private const string GPIO_SWITCH = "/sys/devices/platform/gpio-switch";
    private const string DEV_CMT = "/dev/cmt";
    private const string GPIO_DIR = "/sys/class/gpio";
    private const int RETRY_COUNT_POWER_ON = 10;
    private const int RETRY_COUNT_RESET = 5;
    private const int SOCKET_BUF_SIZE = 16384;

    private const int cmt_en = 0;
    private const int cmt_rst_rq = 1;
    private const int cmt_rst = 2;
    private const int cmt_bsi = 3;
    private const int cmt_apeslpx = 4;

    private RapuType rapu_type;
    private PowerState state;
    private PhonetLink current;
    private PhonetLink target;

    private int retry_count;

    private uint timeout_source;
    private PowerEvent timeout_event;

    private bool reset_in_progress;
    private bool startup_in_progress;

    private bool have_gpio_switch;
    private bool have_gpio[5];

    private int socket;
    private IOChannel chan;

    struct NetlinkInfoMessage
    {
        Linux.Netlink.NlMsgHdr nlh;
        Linux.Netlink.IfInfoMsg ifi;
    }

    construct
    {
		logger.info( "Registering nokia900 low level poweron/poweroff handling" );

        socket = -1;
        current = PhonetLink.NONE;
        target = PhonetLink.NONE;
        reset_in_progress = false;
        startup_in_progress = false;
        timeout_source = 0;
        timeout_event = PowerEvent.NONE;
        retry_count = 0;

		gpio_probe();
    }

    private string gpio_idx2string( int idx )
    {
        switch ( idx )
        {
            case cmt_en:
                return "cmt_en";
            case cmt_rst_rq:
                return "cmt_rst_rq";
            case cmt_rst:
                return "cmt_rst";
            case cmt_bsi:
                return "cmt_bsi";
            case cmt_apeslpx:
                return "cmt_apeslpx";
        }

        return "";
    }

    private string filename_for_gpio_line( int line )
    {
        if ( have_gpio_switch )
            return @"$GPIO_SWITCH/$(gpio_idx2string( line ))/state";

        return @"$DEV_CMT/$(gpio_idx2string( line ))/value";
    }

    private string value_to_gpio_string( bool value )
    {
        if ( have_gpio_switch )
            return value ? "active" : "inactive";

        return value ? "1" : "0";
    }


    private void gpio_write( int line, bool value )
    {
        if ( !have_gpio[line] )
        {
            logger.debug( @"gpio_write: we don't have gpio $(gpio_idx2string( line )) - ignoring" );
            return;
        }

        logger.debug( @"gpio_write: writing $( value_to_gpio_string( value )) to $( filename_for_gpio_line( line ))" );
        FsoFramework.FileHandling.write( value_to_gpio_string( value ), filename_for_gpio_line( line ) );
    }

    private bool gpio_line_probe( int line )
    {
        logger.debug( @"probing for $(filename_for_gpio_line( line ))" );
        return FsoFramework.FileHandling.isPresent( filename_for_gpio_line( line ) );
    }

    private void gpio_start_modem_power_on()
    {
        logger.debug( "starting modem power on" );

        if ( startup_in_progress )
        {
            logger.debug( "startup is already progressing" );
            return;
        }

        startup_in_progress = true;

        gpio_write( cmt_apeslpx, false ); /* skip flash mode */
        gpio_write( cmt_rst_rq, false ); /* prevent current drain */

        switch ( rapu_type )
        {
            case RapuType.TYPE_2:
                gpio_write( cmt_en, false );
                /* 15 ms needed for ASIC poweroff */
                Posix.usleep( 20000 );
                gpio_write( cmt_en, true );
                break;

            case RapuType.TYPE_1:
                gpio_write( cmt_en, false );
                gpio_write( cmt_bsi, false ); /* toggle BSI visible to modem */
                gpio_write( cmt_rst, false ); /* Assert PURX */
                gpio_write( cmt_en, true );   /* Press "power key" */
                gpio_write( cmt_rst, true );  /* Release CMT to boot */
                break;

            default:
                logger.warning( @"unknown rapu type $rapu_type" );
                return;
        }

        gpio_write( cmt_rst_rq, true );
    }

    private void gpio_finish_modem_power_on()
    {
        logger.debug( "finishing modem power on" );

        if ( !startup_in_progress )
        {
            logger.debug( "startup not in progress... can't finish power on" );
            return;
        }

        startup_in_progress = false;

        switch ( rapu_type )
        {
            case RapuType.TYPE_2:
                break;

            case RapuType.TYPE_1:
                gpio_write( cmt_en, false );  /* release "power key" */
                break;
        }
    }

    private void gpio_start_modem_reset()
    {
        logger.debug( "starting modem reset" );

        if ( reset_in_progress )
        {
            logger.debug( "reset already in progress" );
            return;
        }

        reset_in_progress = true;

        if ( have_gpio[cmt_rst_rq] )
        {
            gpio_write( cmt_rst_rq, false ); /* Just in case */
            gpio_write( cmt_rst_rq, true );
        }
        else
            gpio_start_modem_power_on();
    }

    private void gpio_finish_modem_reset()
    {
        logger.debug( "finishing modem reset" );
        if ( !reset_in_progress )
        {
            logger.debug( "can't finish modem reset... it's not in progress" );
            return;
        }

        reset_in_progress = false;
        gpio_finish_modem_power_on();
    }

    private void gpio_finish_modem_power_off()
    {
        logger.debug( "finishing modem power off" );

        if ( reset_in_progress )
        {
            logger.debug( "reset is in progress... finishing it before powering off the modem" );
            gpio_finish_modem_reset();
        }

        if ( startup_in_progress )
        {
            logger.debug( "startup is in progress... finishing it before powering off the modem" );
            gpio_finish_modem_power_on();
        }

        gpio_write( cmt_apeslpx, false ); /* skip flash mode */
        gpio_write( cmt_rst_rq, false );  /* prevent current drain */

        switch ( rapu_type )
        {
            case RapuType.TYPE_2:
                gpio_write( cmt_en, false ); /* Power off */
                break;

            case RapuType.TYPE_1:
                gpio_write( cmt_en, false );  /* release "power key" */
                gpio_write( cmt_rst, false ); /* force modem to reset state */
                gpio_write( cmt_rst, true );  /* release modem to be powered off by bootloader */
                break;
        }
    }

    protected bool onTimeout()
    {
        timeout_source = 0;

        logger.debug( @"onTimeout with $timeout_event" );
        if ( timeout_event != PowerEvent.NONE )
            gpio_power_state_machine( timeout_event );

        return false;
    }

    protected bool onNetlink(IOChannel chan, IOCondition cond)
    {
        logger.debug( @"OnNetlink: $cond" );
        /*
        struct {
            struct nlmsghdr nlh;
            char buf[SIZE_NLMSG];
        } resp;
        struct iovec iov = { &resp, sizeof(resp), };
        struct msghdr msg = { .msg_iov = &iov, .msg_iovlen = 1, };
        ssize_t ret;
        struct nlmsghdr *nlh;
        int fd = g_io_channel_unix_get_fd(channel);
        GPhonetNetlink *self = data;

        if (cond & (G_IO_NVAL|G_IO_HUP))
            return FALSE;

        ret = recvmsg(fd, &msg, 0);
        if (ret == -1)
            return TRUE;

        if (msg.msg_flags & MSG_TRUNC) {
            g_printerr("Netlink message of %zu bytes truncated at %zu\n",
                    ret, sizeof(resp));
            return TRUE;
        }

        for (nlh = &resp.nlh; NLMSG_OK(nlh, (size_t)ret);
                            nlh = NLMSG_NEXT(nlh, ret)) {
            if (nlh->nlmsg_type == NLMSG_DONE)
                break;

            switch (nlh->nlmsg_type) {
            case NLMSG_ERROR: {
                struct nlmsgerr *err = NLMSG_DATA(nlh);
                if (err->error)
                    g_printerr("Netlink error: %s",
                            strerror(-err->error));
                return TRUE;
            }
            case RTM_NEWADDR:
            case RTM_DELADDR:
                g_pn_nl_addr(self, nlh);
                break;
            case RTM_NEWLINK:
            case RTM_DELLINK:
                g_pn_nl_link(self, nlh);
                break;
            default:
                continue;
            }
        }
        return TRUE;
        */

        return false;
    }



    private void gpio_power_state_machine( PowerEvent event )
    {
        PowerState new_state;

        logger.debug( @"handling $event" );

        switch ( event )
        {
            case PowerEvent.ON:
                target = PhonetLink.UP;

                /* we have to wait for info from netlink */
                if ( current == PhonetLink.NONE )
                    return;

                switch ( state )
                {
                    case PowerState.ON_STARTED:
                    case PowerState.ON_RESET:
                    case PowerState.ON:
                        /* Do nothing */
                        break;

                    case PowerState.OFF_STARTED:
                        /* Do nothing */
                        break;

                    case PowerState.NONE:
                    case PowerState.OFF_WAITING:
                    case PowerState.OFF:
                    case PowerState.ON_FAILED:
                        gpio_power_set_state( PowerState.ON_STARTED );
                        break;
                }

                return;

            case PowerEvent.PHONET_LINK_DOWN:
                switch ( target )
                {
                    case PhonetLink.UP:
                        break;

                    case PhonetLink.DOWN:
                    case PhonetLink.NONE:
                        if ( state == PowerState.OFF || state == PowerState.NONE )
                            new_state = PowerState.OFF;
                        else
                            new_state = PowerState.OFF_WAITING;

                        gpio_power_set_state( new_state );
                        return;
                }

                switch ( state )
                {
                    case PowerState.NONE:
                        /* first connection down event => start modem */
                        gpio_power_set_state(PowerState.ON_STARTED);
                        break;

                    case PowerState.ON_STARTED:
                    case PowerState.ON_RESET:
                        break;

                    default:
                        retry_count = 0;
                        gpio_power_set_state( PowerState.ON_RESET );
                        break;
                }
                return;

            case PowerEvent.ON_TIMEOUT:
                if ( target == PhonetLink.DOWN )
                    new_state = PowerState.OFF_STARTED;
                else if ( retry_count <= RETRY_COUNT_POWER_ON )
                    new_state = PowerState.ON_STARTED;
                else
                    new_state = PowerState.ON_FAILED;

                gpio_power_set_state( new_state );
                return;

            case PowerEvent.REBOOT_TIMEOUT:
                /* Modem not rebooting - try to powercycle */
                if ( target == PhonetLink.DOWN)
                    new_state = PowerState.OFF_STARTED;
                else if ( retry_count <= RETRY_COUNT_RESET )
                    new_state = PowerState.ON_RESET;
                else
                    new_state = PowerState.ON_STARTED;

                gpio_power_set_state( new_state );
                return;

            case PowerEvent.PHONET_LINK_UP:
                switch (state)
                {
                    case PowerState.NONE:
                        return;

                    case PowerState.ON_STARTED:
                    case PowerState.ON_RESET:
                        break;

                    case PowerState.ON:
                        return;

                    case PowerState.OFF_STARTED:
                    case PowerState.OFF_WAITING:
                    case PowerState.OFF:
                    case PowerState.ON_FAILED:
                        logger.debug( "LINK_UP event while modem should be powered off" );
                        /* should never come here */
                        break;
                }

                if (target == PhonetLink.DOWN )
                    gpio_power_set_state( PowerState.OFF_STARTED );
                else
                    gpio_power_set_state( PowerState.ON );

                return;

            case PowerEvent.OFF:
                target = PhonetLink.DOWN;

                switch ( state )
                {
                    case PowerState.ON_STARTED:
                    case PowerState.ON_RESET:
                        /* Do nothing until a timer expires */
                        break;

                    case PowerState.ON:
                        gpio_power_set_state( PowerState.OFF_STARTED );
                        break;

                    case PowerState.OFF_STARTED:
                    case PowerState.OFF_WAITING:
                    case PowerState.OFF:
                        /* Do nothing */
                        break;

                    case PowerState.NONE:
                    case PowerState.ON_FAILED:
                        gpio_power_set_state( PowerState.OFF );
                        break;
                }
                return;

            case PowerEvent.OFF_IMMEDIATELY:
                gpio_power_set_state( PowerState.OFF );
                return;

            case PowerEvent.OFF_TIMEOUT:
                logger.debug( "Modem power off timed out" );
                gpio_power_set_state( PowerState.OFF );
                return;

            case PowerEvent.OFF_COMPLETE:
                if ( state == PowerState.OFF_WAITING )
                {
                    logger.debug( "Modem shutdown complete" );
                    gpio_power_set_state( PowerState.OFF );
                }
                return;
        }

        logger.debug( @"Event $event not handled" );
    }


    private void gpio_power_set_state( PowerState new_state )
    {
        PowerState old_state = state;
        uint timeout = 0;
        PowerEvent timer_event = PowerEvent.NONE;

        logger.debug( @"new state ($new_state) / old state ($old_state)" );

        switch ( old_state )
        {
            case PowerState.ON_STARTED:
                gpio_finish_modem_power_on();
                break;

            case PowerState.ON_RESET:
                gpio_finish_modem_reset();
                break;

            default:
                break;
        }

        if ( timeout_source > 0 )
        {
            logger.debug( "power_set_state: disabling timer" );
            Source.remove( timeout_source );
            timeout_source = 0;
            timeout_event = PowerEvent.NONE;
        }

        if ( old_state == new_state && new_state != PowerState.ON_STARTED && new_state != PowerState.ON_RESET )
        {
            logger.debug( @"power_set_state: nothing to do (old_state=$old_state new_state=$new_state)" );
            return;
        }

        state = new_state;

        switch ( state )
        {
            case PowerState.NONE:
                break;

            case PowerState.ON_STARTED:
                retry_count++;

                logger.debug( @"power_set_state: state=$state retry_count=$retry_count" );

                /* Maximum modem power on procedure on can take */
                timeout = 5000;
                timer_event = PowerEvent.ON_TIMEOUT;
                gpio_start_modem_power_on();
                break;

            case PowerState.ON_RESET:
                logger.debug( "power_set_state: Starting modem restart timeout" );

                /* Time allowed for modem to restart after crash */
                timeout = 5000;
                timer_event = PowerEvent.REBOOT_TIMEOUT;

                retry_count++;
                if ( retry_count > 0 )
                    gpio_start_modem_reset();
                break;

            case PowerState.ON:
                logger.debug( "Power on" );
                retry_count = 0;
                break;

            case PowerState.OFF_STARTED:
                logger.debug( "Starting power off" );

                /* Maximum time modem power_off can take */
                timeout = 6150;
                timer_event = PowerEvent.OFF_TIMEOUT;
                break;

            case PowerState.OFF_WAITING:
                gpio_finish_modem_power_off();
                logger.debug( "Waiting for modem to settle down" );

                /* Cooling time after power off */
                timeout = 1000;
                timer_event = PowerEvent.OFF_COMPLETE;
                break;

            case PowerState.OFF:
                if ( old_state != PowerState.OFF_WAITING && old_state != PowerState.ON_FAILED )
                    gpio_finish_modem_power_off();
                break;

            case PowerState.ON_FAILED:
                logger.debug( "Link to modem cannot be established, giving up" );
                gpio_finish_modem_power_off();
                break;
        }

        if (timeout > 0)
        {
            logger.debug( @"power_set_state: enabling timer (timeout=$timeout, event=$timer_event)" );
            timeout_event = timer_event;
            timeout_source = Timeout.add( timeout, onTimeout );
        }

        // TODO: self.callback needed ?
    }

    private bool gpio_probe_links()
    {
        /* we can't create the links in DEV_CMT as current kernels
         * lack the name property in /sys/class/gpio/gpioXYZ
         * only thing we can do is check if DEV_CMT is there
         * and hope the links in there are already set up */
        return FsoFramework.FileHandling.isPresent( DEV_CMT );
    }

    private void gpio_probe()
    {
        target = PhonetLink.NONE;
        have_gpio_switch = FsoFramework.FileHandling.isPresent( GPIO_SWITCH );

        if ( have_gpio_switch )
            logger.info( @"Using $GPIO_SWITCH switch" );
        else
        {
            if ( !gpio_probe_links() )
                return;
            logger.info( @"Using $DEV_CMT" );
        }

        /* GPIO lines availability depends on HW and SW versions */
        for ( int f = 0; f < 5; f++ )
        {
            have_gpio[f] = gpio_line_probe( f );
            logger.debug( @"   --> $(gpio_idx2string( f )): $(have_gpio[f])" );
        }

        if ( !have_gpio[cmt_en] )
        {
            logger.warning( "Modem control GPIO lines are not available" );
            return;
        }

        if ( have_gpio[cmt_bsi] )
            rapu_type = RapuType.TYPE_1;
        else
            rapu_type = RapuType.TYPE_2;

        logger.debug( @"gpio_probe: rapu is $rapu_type" );

        netlink_start();
    }

    private void gpio_remove()
    {
        netlink_stop();

        if ( timeout_source > 0 )
        {
            Source.remove( timeout_source );
            timeout_source = 0;
            timeout_event = PowerEvent.NONE;
        }
    }

    private void gpio_enable()
    {
        if ( state != PowerState.ON )
            gpio_power_state_machine( PowerEvent.ON );
    }

    private void gpio_disable()
    {
        if ( state != PowerState.OFF && state != PowerState.ON_FAILED )
            gpio_power_state_machine( PowerEvent.OFF );
    }


    public bool netlink_start()
    {
        int option;

        logger.debug( "starting netlink" );

        if ( socket > 0 )
        {
            logger.debug( "netlink socket for phonet already there" );
            return true;
        }

        socket = Posix.socket( Linux.Socket.AF_NETLINK, Posix.SOCK_DGRAM, Linux.Netlink.NETLINK_ROUTE );
        if ( socket == -1 )
        {
            logger.warning( "netlink_start: failed to open netlink socket" );
            return false;
        }

        option = SOCKET_BUF_SIZE;
        // FIXME: replace 1 with SOL_SOCKET
        // FIXME: replace 8 with SO_RCVBUF
        if ( Posix.setsockopt( socket, 1, 8, &option, (Posix.socklen_t) sizeof( int ) ) != 0 )
        {
            logger.warning( "netlink_start: failed to socket options" );
            Posix.close( socket );
            socket = -1;
            return false;
        }

        Posix.fcntl( socket, Posix.F_SETFL, Posix.fcntl( socket, Posix.F_GETFL ) | Posix.O_NONBLOCK );

        option = Linux.Netlink.RTNLGRP_LINK;
        // FIXME: replace 270 with SOL_NETLINK
        // FIXME: replace 1 with NETLINK_ADD_MEMBERSHIP
        Posix.setsockopt( socket, 270, 1, &option, (Posix.socklen_t) sizeof( int ) );

        int fd = Posix.socket( 1, Posix.SOCK_DGRAM, 0 );

        /* try to bring up the interface */
        var ifreq = Linux.Network.IfReq();
        ifreq.ifr_ifindex = 1;
        if ( Posix.ioctl( fd, Linux.Network.SIOCGIFNAME, &ifreq ) == 0 &&
                Posix.ioctl( fd, Linux.Network.SIOCGIFFLAGS, &ifreq ) == 0)
        {
            logger.debug( "netlink_start: flagging phonet interface as up and running" );
            ifreq.ifr_flags |= Linux.Network.IfFlag.UP | Linux.Network.IfFlag.RUNNING;
            Posix.ioctl( fd, Linux.Network.SIOCSIFFLAGS, &ifreq );
        }

        netlink_getlink( fd );

        chan = new IOChannel.unix_new( fd );
        chan.set_buffered( false );
        chan.add_watch( IOCondition.IN | IOCondition.ERR | IOCondition.HUP, onNetlink );

        return true;
    }

    private void netlink_getlink( int fd )
    {
        var req = NetlinkInfoMessage() {
            nlh = Linux.Netlink.NlMsgHdr() {
                nlmsg_type  = (uint16) Linux.Netlink.RtMessageType.GETLINK,
                nlmsg_len   = (uint32) sizeof( NetlinkInfoMessage ),
                nlmsg_flags = (uint16) Linux.Netlink.NLM_F_REQUEST | Linux.Netlink.NLM_F_ROOT | Linux.Netlink.NLM_F_MATCH,
                nlmsg_pid   = Posix.getpid() },
            ifi = Linux.Netlink.IfInfoMsg() {
                ifi_family = (uchar) Linux.Socket.AF_UNSPEC,
                ifi_type = (ushort) Linux.Network.IfArpHeaderType.PHONET,
                ifi_change = (uint32) 0xffFFffFF }
        };

        var addr = Linux.Netlink.SockAddrNl() { nl_family = Linux.Socket.AF_NETLINK };
        Posix.sendto( fd, &req, sizeof( NetlinkInfoMessage ), 0, &addr, sizeof( Linux.Netlink.SockAddrNl ) );
    }

    private void netlink_addr()
    {
#if 0
        int len;
        uint8_t local = 0xff;
        uint8_t remote = 0xff;

        const struct ifaddrmsg *ifa;
        const struct rtattr *rta;

        ifa = NLMSG_DATA(nlh);
        len = IFA_PAYLOAD(nlh);

        /* If Phonet is absent, kernel transmits other families... */
        if (ifa->ifa_family != AF_PHONET)
            return;

        if (ifa->ifa_index != self->interface)
            return;

        for (rta = IFA_RTA(ifa); RTA_OK(rta, len); rta = RTA_NEXT(rta, len)) {

            if (rta->rta_type == IFA_LOCAL)
                local = *(uint8_t *)RTA_DATA(rta);
            else if (rta->rta_type == IFA_ADDRESS)
                remote = *(uint8_t *)RTA_DATA(rta);
        }
#endif
    }

    private void netlink_link()
    {
#if 0
        const struct ifinfomsg *ifi;
        const struct rtattr *rta;
        int len;
        const char *ifname = NULL;
        GIsiModem *idx = NULL;
        GPhonetLinkState st;

        ifi = NLMSG_DATA(nlh);
        len = IFA_PAYLOAD(nlh);

        if (ifi->ifi_type != ARPHRD_PHONET)
            return;

        if (self->interface != 0 && self->interface != (unsigned)ifi->ifi_index)
            return;

        idx = make_modem(ifi->ifi_index);

//#define UP (IFF_UP | IFF_LOWER_UP | IFF_RUNNING)

        if (nlh->nlmsg_type == RTM_DELLINK)
            st = PN_LINK_REMOVED;
        else if ((ifi->ifi_flags & UP) != UP)
            st = PN_LINK_DOWN;
        else
            st = PN_LINK_UP;

        for (rta = IFLA_RTA(ifi); RTA_OK(rta, len);
            rta = RTA_NEXT(rta, len)) {

            if (rta->rta_type == IFLA_IFNAME)
                ifname = RTA_DATA(rta);
        }

        if (ifname && idx)
            self->callback(idx, st, ifname, self->opaque);

//#undef UP
#endif
    }

    private void netlink_stop()
    {
        if ( socket <= 0 )
            return;

        Posix.close( socket );
        socket = -1;
    }


    public override string repr()
    {
        return "<>";
    }

    public bool poweron()
    {
        logger.debug( "lowlevel_nokia900_poweron()" );

        // always turn off first
        poweroff();
		gpio_enable();
        return true;
    }

    public bool poweroff()
    {
        logger.debug( "lowlevel_nokia900_poweroff()" );
		gpio_disable();
        return true;
    }

    public bool suspend()
    {
        logger.debug( "lowlevel_nokia900_suspend()" );
        return true;
    }

    public bool resume()
    {
        logger.debug( "lowlevel_nokia900_resume()" );
        return true;
    }

}

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    FsoFramework.theLogger.debug( "lowlevel_nokia900 fso_factory_function" );
    return LowLevel.Nokia900.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}
