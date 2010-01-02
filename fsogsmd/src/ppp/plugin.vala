/**
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

using FsoFramework;

static void fsogsmd_on_phase_change( int arg )
{
    theLogger.info( @"on_phase_change: $arg" );
    //FIXME: report phase to fsogsmd
}

static void fsogsmd_on_ip_up( int arg )
{
    theLogger.info( "on_ip_up" );
    //FIXME: report IP parameters to fsogsmd
}

static void fsogsmd_on_exit( int arg )
{
    theLogger.debug( "on_exit" );
}

static int fsogsmd_get_chap_check()
{
    theLogger.debug( "get_chap_check" );
	return 1; // we support CHAP
}

static int fsogsmd_get_pap_check()
{
    theLogger.info( "get_pap_check" );
	return 1; // we support PAP
}

static int fsogsmd_get_credentials( string username, string password )
{
    theLogger.info( "get_credentials" );
    if ( username != null && password == null )
    {
		// pppd is checking pap support; return 1 for supported
		return 1;
	}

    //FIXME: Get credentials from fsogsmd

    username = "";
    password = "";

	return 1;
}

static void plugin_init()
{
    theLogger.info( "fsogsmd plugin init" );
    PPPD.add_notifier( PPPD.phasechange, fsogsmd_on_phase_change );
    PPPD.add_notifier( PPPD.exitnotify, fsogsmd_on_exit );
    PPPD.add_notifier( PPPD.ip_up_notifier, fsogsmd_on_ip_up );

    PPPD.chap_passwd_hook = fsogsmd_get_credentials;
	PPPD.chap_check_hook = fsogsmd_get_chap_check;
	PPPD.pap_passwd_hook = fsogsmd_get_credentials;
	PPPD.pap_check_hook = fsogsmd_get_pap_check;

}
