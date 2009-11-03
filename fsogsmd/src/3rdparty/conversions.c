/*
 *
 *  oFono - Open Source Telephony
 *
 *  Copyright (C) 2008-2009  Intel Corporation. All rights reserved.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2 as
 *  published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#include "util.h"
#include "smsutil.h"

char *ucs2_to_utf8(const char *str)
{
    long len;
    unsigned char *ucs2;
    char *utf8;
    ucs2 = decode_hex(str, -1, &len, 0);
    utf8 = g_convert((char *)ucs2, len, "UTF-8//TRANSLIT", "UCS-2BE",
                      NULL, NULL, NULL);
    g_free(ucs2);
    return utf8;
}

void sms_copy( void* self, void* dup )
{
	memcpy( dup, self, sizeof( struct sms ) );
}

struct sms* sms_new()
{
	struct sms* sms;
	sms = g_malloc0( sizeof( struct sms ) );
	g_debug( "sms %p has been created", sms );
	return sms;
}

void sms_free( struct sms* self )
{
	g_debug( "sms %p is being destroyed", self );
	g_free( self );
}

