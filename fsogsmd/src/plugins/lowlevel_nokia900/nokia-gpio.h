/*
 *
 *  oFono - Open Source Telephony
 *
 *  Copyright (C) 2010  Nokia Corporation and/or its subsidiary(-ies).
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

/**
 * DBG:
 * @fmt: format string
 * @arg...: list of arguments
 *
 * Simple macro around ofono_debug() which also include the function
 * name it is called in.
 */
extern void ofono_debug(const char *format, ...) __attribute__((format(printf, 1, 2)));

#define DBG(fmt, args...) g_debug(fmt, ##args)


typedef enum {
        PN_LINK_REMOVED,
        PN_LINK_DOWN,
        PN_LINK_UP
} GPhonetLinkState;

enum power_state {
	POWER_STATE_NONE,
	POWER_STATE_ON_STARTED,
	POWER_STATE_ON,
	POWER_STATE_ON_RESET,
	POWER_STATE_ON_FAILED,
	POWER_STATE_OFF_STARTED,
	POWER_STATE_OFF_WAITING,
	POWER_STATE_OFF,
};

typedef void (*gpio_finished_cb_t)(enum power_state value, void *opaque);

int gpio_probe();
int gpio_enable();
int gpio_disable();
int gpio_remove();

char const *gpio_power_state_name(enum power_state value);
