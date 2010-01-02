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
    [CCode (cname = "struct wordlist")]
    public struct wordlist {
    }

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
    void add_notifier           (notifier n, notify_func func);
    void remove_notifier        (notifier n, notify_func func);

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
}
