/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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
 **/

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#define CONNMAN_API_SUBJECT_TO_CHANGE
#include <connman/plugin.h>

int fsogsm_plugin_init (void);
void fsogsm_plugin_exit (void);

CONNMAN_PLUGIN_DEFINE(fsogsm, "FSO GSM Telephony Plugin", VERSION,
			CONNMAN_PLUGIN_PRIORITY_LOW, fsogsm_plugin_init, fsogsm_plugin_exit)
