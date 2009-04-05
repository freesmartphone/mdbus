/* 
 * display-helpers.c
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

/* Display helpers */
#include <glib.h>
#include "display.h"
#include <fcntl.h>
#include <sys/ioctl.h>

#define FBIOBLANK 0x4611
#define FB_BLANK_UNBLANK 0
#define FB_BLANK_POWERDOWN 4

void fb_set_power(gboolean enable, int fd) {
	if(enable)
		ioctl(fd, FBIOBLANK, FB_BLANK_UNBLANK);
	else
		ioctl(fd, FBIOBLANK, FB_BLANK_POWERDOWN);
}
	
