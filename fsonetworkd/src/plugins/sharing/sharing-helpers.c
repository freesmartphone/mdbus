/* 
 * sharing-helpers.c
 * Written by Sudharshan "Sup3rkiddo" S <sudharsh@gmail.com>
 * All Rights Reserved
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */ 

/*
  FIXME: This piece of code used the API provided by net/if.h
  to get ip addresses for a given interface. Ideally the API should have
  had vala bindings of it own in entirety. 
*/

#include <stdio.h>
#include <unistd.h>
#include <string.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include <glib.h>


gchar * get_ip(const char * device) {
    struct ifreq ifr;
    gchar *ip;
    int result;
    int sockfd = socket(AF_INET, SOCK_DGRAM, 0);

    if(sockfd < 0)
        return NULL;
    strncpy(ifr.ifr_name, device, sizeof(device) + 1);

    result = ioctl(sockfd, SIOCGIFADDR, &ifr);
    close(sockfd);
    if(result < 0)
        return NULL;

    ip = (gchar *)inet_ntoa(((struct sockaddr_in*)&ifr.ifr_addr)->sin_addr);
    return g_strdup(ip);
    
}
