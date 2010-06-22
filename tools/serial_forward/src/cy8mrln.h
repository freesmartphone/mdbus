/*
 *  From tslib library: tslib/plugins/cy8mrln-palmpre.c
 *
 *  Copyright (C) 2010 Frederik Sdun <frederik.sdun@googlemail.com>
 *		       Thomas Zimmermann <ml@vdm-design.de>
 *
 *
 * This file is placed under the LGPL.  Please see the file
 * COPYING for more details.
 *
 *
 * Pluging for the cy8mrln touchscreen with the Firmware used on the Palm Pre
 */

/* IOCTLs */
#define CY8MRLN_IOCTL_SET_SCANRATE       _IOW('c', 0x08, int)
#define CY8MRLN_IOCTL_SET_SLEEPMODE      _IOW('c', 0x09, int)
#define CY8MRLN_IOCTL_SET_VERBOSE_MODE   _IOW('c', 0x0e, int)
#define CY8MRLN_IOCTL_SET_TIMESTAMP_MODE _IOW('c', 0x17, int)
#define CY8MRLN_IOCTL_SET_WOT_THRESHOLD  _IOW('c', 0x1d, int)
#define CY8MRLN_IOCTL_SET_WOT_SCANRATE   _IOW('c', 0x22, int)

/* PSoC Power State */
enum {
	CY8MRLN_OFF_STATE = 0,
	CY8MRLN_SLEEP_STATE,
	CY8MRLN_ON_STATE
};

/* WOT Scan Rate Index */
enum{
	WOT_SCANRATE_512HZ = 0,
	WOT_SCANRATE_256HZ,
	WOT_SCANRATE_171HZ,
	WOT_SCANRATE_128HZ
};
