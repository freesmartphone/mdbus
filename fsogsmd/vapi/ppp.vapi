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
[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "pppd/pppd.h")]
namespace PPPD
{
    [CCode (instance_pos = 0.9)]
    public delegate void notify_func( int arg );

    [CCode (cname = "struct notifier")]
    public struct notifier {
    }

    // notifiers to register with
    extern notifier pidchange;   /* for notifications of pid changing */
    extern notifier phasechange; /* for notifications of phase changes */
    extern notifier exitnotify;  /* for notification that we're exiting */
    extern notifier sigreceived; /* notification of received signal */
    extern notifier ip_up_notifier; /* IPCP has come up */
    extern notifier ip_down_notifier; /* IPCP has gone down */
    extern notifier auth_up_notifier; /* peer has authenticated */
    extern notifier link_down_notifier; /* link has gone down */
    extern notifier fork_notifier;  /* we are a new child process */
}
                                  
