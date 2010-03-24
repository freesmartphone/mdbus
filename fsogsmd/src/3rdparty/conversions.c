/*
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

#include <string.h>

char* utf8_to_ucs2(const char* str)
{
    long len;
    unsigned char* ucs2 = g_convert(str, strlen(str), "UCS-2BE", "UTF-8//TRANSLIT", NULL, &len, NULL);
    char* hex = encode_hex(ucs2, len, 0);
    g_free(ucs2);
    return hex;
}

char* utf8_to_gsm(const char* str)
{
    long len;
    char* gsm = convert_utf8_to_gsm(str, strlen(str), NULL, &len, 0);
    char* hex = encode_hex(gsm, len, 0);
    g_free(gsm);
    return hex;
}

char* ucs2_to_utf8(const char* str)
{
//    g_debug( "ucs2_to_utf8: '%s'", str );
    long len;
    unsigned char *ucs2;
    char *utf8;
    ucs2 = decode_hex(str, -1, &len, 0);
//    g_debug( "--- ucs2 now '%s'", ucs2 );
    utf8 = g_convert((char *)ucs2, len, "UTF-8//TRANSLIT", "UCS-2BE", NULL, NULL, NULL);
    g_free(ucs2);
    return utf8;
}

char *gsm_to_utf8(const char* str)
{
//    g_debug( "gsm_to_utf8: '%s'", str );
    long len;
    long written;
    unsigned char *ucs2;
    char *utf8;
    ucs2 = decode_hex(str, -1, &len, 0);
//    g_debug( "--- ucs2 now '%s'", ucs2 );
    utf8 = convert_gsm_to_utf8((char*)ucs2, len, NULL, NULL, 0);
    g_free(ucs2);
    return utf8;
}

void sms_copy( void* self, void* dup )
{
//    g_warning( "sms %p being copied", self );
    memcpy( dup, self, sizeof( struct sms ) );
}

struct sms* sms_new()
{
    struct sms* sms;
    sms = g_malloc0( sizeof( struct sms ) );
//    g_debug( "sms %p has been created", sms );
    return sms;
}

void sms_free( struct sms* self )
{
//    g_debug( "sms %p is being destroyed", self );
    g_free( self );
}

long sms_size()
{
    return sizeof( struct sms );
}
