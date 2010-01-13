/**
 * ppp.vapi
 *
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 **/
[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "./pppd-local.h")]
namespace PPPD
{
    // Consts
    public const int NUM_PPP;
    public const int MAXWORDLEN;
    public const int MAXARGS;
    public const int MAXNAMELEN;
    public const int MAXSECRETLEN;
    public const int MAX_ENDP_LEN;

    // Enums
    [CCode (cname = "int", cprefix = "PHASE_")]
    public enum Phase {
         DEAD,
         INITIALIZE,
         SERIALCONN,
         DORMANT,
         ESTABLISH,
         AUTHENTICATE,
         CALLBACK,
         NETWORK,
         RUNNING,
         TERMINATE,
         DISCONNECT,
         HOLDOFF,
         MASTER
    }

    // Delegates
    [CCode (instance_pos = 0.9)]
    public delegate void notify_func (int arg);

    public static delegate int  new_phase_hook_func        (int phase);
    public static delegate int  idle_time_hook_func        (ppp_idle idle);
    public static delegate int  holdoff_hook_func          ();
    public static delegate int  pap_check_hook_func        ();
    public static delegate int  pap_auth_hook_func         (string user, string passwd, out string msgp, out wordlist paddrs, out wordlist popts);
    public static delegate void pap_logout_hook_func       ();
    public static delegate int  pap_passwd_hook_func       (string user, string passwd);
    public static delegate int  allowed_address_hook_func  (uint32 addr);
    public static delegate void ip_up_hook_func            ();
    public static delegate void ip_down_hook_func          ();
    public static delegate void ip_choose_hook_func        (out uint32 addr);
    public static delegate int  chap_check_hook_func       ();
    public static delegate int  chap_passwd_hook_func      (string user, string passwd);
    public static delegate void multilink_join_hook_func   ();
    public static delegate void snoop_recv_hook_func       (char[] packet);
    public static delegate void snoop_send_hook_func       (char[] packet);

    // Structs
    [CCode (cname = "struct notifier")]
    public struct notifier {
    }

    [CCode (cname = "struct ppp_idle")]
    public struct ppp_idle {
    }

    [CCode (cname = "struct pppd_stats")]
    public struct pppd_stats {
        public uint	bytes_in;
        public uint	bytes_out;
        public uint	pkts_in;
        public uint	pkts_out;
    }

    [CCode (cname = "struct wordlist")]
    public struct wordlist {
    }

    // Global Variables
    extern int          hungup;		    /* Physical layer has disconnected */
    extern int	        ifunit;		    /* Interface unit number */
    extern char[]	    ifname;	        /* Interface name */
    extern char[]       hostname;	    /* Our hostname */
    extern char[]	    outpacket_buf;  /* Buffer for outgoing packets */
    extern int	        devfd;		    /* fd of underlying device */
    extern int	        fd_ppp;		    /* fd for talking PPP */
    extern int	        phase;		    /* Current state of link - see values below */
    extern int	        baud_rate;	    /* Current link speed in bits/sec */
    extern string	    progname;   	/* Name of this program */
    extern int	        redirect_stderr;/* Connector's stderr should go to file */
    extern char[]	    peer_authname;  /* Authenticated name of peer */
    extern int[]	    auth_done;      /* Methods actually used for auth */
    extern int	        privileged;	    /* We were run by real-uid root */
    extern int	        need_holdoff;	/* Need holdoff period after link terminates */
    extern string[]	    script_env;	    /* Environment variables for scripts */
    extern int	        detached;	    /* Have detached from controlling tty */
    extern Posix.gid_t[]groups;	        /* groups the user is in */
    extern int	        ngroups;	    /* How many groups valid in groups */
    extern pppd_stats   link_stats;     /* byte/packet counts etc. for link */
    extern int	        link_stats_valid; /* set if link_stats is valid */
    extern uint32   	link_connect_time;/* time the link was up for */
    extern int	        using_pty;	    /* using pty as device (notty or pty opt.) */
    extern int	        log_to_fd;	    /* logging to this fd as well as syslog */
    extern bool	        log_default;	/* log_to_fd is default (stdout) */
    extern string	    no_ppp_msg;	    /* message to print if ppp not in kernel */
    extern int          status;	        /* exit status for pppd */
    extern bool	        devnam_fixed;	/* can no longer change devnam */
    extern int	        unsuccess;	    /* # unsuccessful connection attempts */
    extern int	        do_callback;	/* set if we want to do callback next */
    extern int	        doing_callback;	/* set if this is a callback */
    extern int	        error_count;	/* # of times error() has been called */
    extern char[]	    ppp_devnam;
    extern char[]       remote_number;  /* Remote telephone number, if avail. */
    extern int          ppp_session_number; /* Session number (eg PPPoE session) */
    extern int	        fd_devnull;	    /* fd open to /dev/null */

    extern int	        listen_time;	/* time to listen first (ms) */
    extern bool	        doing_multilink;
    extern bool	        multilink_master;
    extern bool	        bundle_eof;
    extern bool	        bundle_terminating;

    // Notifiers to register with
    extern notifier pidchange;   /* for notifications of pid changing */
    extern notifier phasechange; /* for notifications of phase changes */
    extern notifier exitnotify;  /* for notification that we're exiting */
    extern notifier sigreceived; /* notification of received signal */
    extern notifier ip_up_notifier; /* IPCP has come up */
    extern notifier ip_down_notifier; /* IPCP has gone down */
    extern notifier auth_up_notifier; /* peer has authenticated */
    extern notifier link_down_notifier; /* link has gone down */
    extern notifier fork_notifier;  /* we are a new child process */

    // Procedures exported from main.c
    public void add_notifier           (notifier n, notify_func func);
    public void remove_notifier        (notifier n, notify_func func);

    // Procedures exported from utils.c
    public void dbglog (string format, ...);      /* log a debug message */
    public void info   (string format, ...);   /* log an informational message */
    public void notice (string format, ...); /* log a notice-level message */
    public void warn   (string format, ...);   /* log a warning message */
    public void error  (string format, ...);  /* log an error message */
    public void fatal  (string format, ...);  /* log an error message and die(1) */

    // Hooks to enable plugins to change various things
    extern new_phase_hook_func         new_phase_hook;
    extern idle_time_hook_func         idle_time_hook;
    extern holdoff_hook_func           holdoff_hook;
    extern pap_check_hook_func         pap_check_hook;
    extern pap_auth_hook_func          pap_auth_hook;
    extern pap_logout_hook_func        pap_logout_hook;
    extern pap_passwd_hook_func        pap_passwd_hook;
    extern allowed_address_hook_func   allowed_address_hook;
    extern ip_up_hook_func             ip_up_hook;
    extern ip_down_hook_func           ip_down_hook;
    extern ip_choose_hook_func         ip_choose_hook;
    extern chap_check_hook_func        chap_check_hook;
    extern chap_passwd_hook_func       chap_passwd_hook;
    extern multilink_join_hook_func    multilink_join_hook;
    extern snoop_recv_hook_func        snoop_recv_hook;
    extern snoop_send_hook_func        snoop_send_hook;

    [CCode (cprefix = "ipcp_", cheader_filename = "pppd/fsm.h,pppd/ipcp.h")]
    namespace IPCP {
        [CCode (cname = "struct ipcp_options", destroy_function = "", copy_function = "")]
        public struct Options {
            public bool neg_addr;              /* Negotiate IP Address? */
            public bool old_addrs;             /* Use old (IP-Addresses) option? */
            public bool req_addr;              /* Ask peer to send IP address? */
            public bool default_route;         /* Assign default route through interface? */
            public bool replace_default_route; /* Replace default route through interface? */
            public bool proxy_arp;             /* Make proxy ARP entry for peer? */
            public bool neg_vj;                /* Van Jacobson Compression? */
            public bool old_vj;                /* use old (short) form of VJ option? */
            public bool accept_local;          /* accept peer's value for ouraddr */
            public bool accept_remote;         /* accept peer's value for hisaddr */
            public bool req_dns1;              /* Ask peer to send primary DNS address? */
            public bool req_dns2;              /* Ask peer to send secondary DNS address? */
            public int  vj_protocol;           /* protocol value to use in VJ option */
            public int  maxslotindex;          /* values for RFC1332 VJ compression neg. */
            public bool cflag;
            public uint32 ouraddr;             /* Our address in NETWORK BYTE ORDER */
            public uint32 hisaddr;             /* His address in NETWORK BYTE ORDER */
            public uint32[] dnsaddr;          /* Primary and secondary MS DNS entries */
            public uint32[] winsaddr;         /* Primary and secondary MS WINS entries */
        }

        [CCode (cname = "ipcp_wantoptions")]
        extern Options[] wantoptions;
        extern Options[] gotoptions;
        extern Options[] allowoptions;
        extern Options[] hisoptions;
    }

}
