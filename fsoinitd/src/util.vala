/**
 * Copyright (C) 2010 Simon Busch <morphis@gravedo.de>
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
 */

namespace FsoInit.Util
{

public const string CONSOLE_PATH = "/dev/console";
public const string DEV_NULL_PATH = "/dev/null";

public enum ConsoleType 
{
	OUTPUT,
	OWNER,
	NONE,
}

public errordomain SetupConsoleError 
{
	COULD_NOT_OPEN_CONSOLE,
}

/* fairly copied from upstart: init/system.c */

/**
 * setupConsole:
 * @type: console type
 * @reset: reset console to sane defaults
 *
 * Set up the standard input, output and error file descriptors for the
 * current process based on the console @type given. If @reset is TRUE then
 * the console device will be reset to sane defaults.
 **/
public void setupConsole(ConsoleType type, bool reset) throws SetupConsoleError
{
	int fd = -1, i;

	/* Close the standard file descriptors since we're about to re-open
	 * them; it may be that some of these aren't already open, we got
	 * called in some very strange ways.
	 */
	for (i = 0; i < 3; i++)
		Posix.close(i);

	/* Open the new first descriptor, which always become 
	 * file zero.
	 */
	switch (type) {
	case ConsoleType.OUTPUT:
	case ConsoleType.OWNER:
		/* Ordinary console input and output */
		fd = Posix.open(CONSOLE_PATH, Posix.O_RDWR | Posix.O_NOCTTY);
		if (fd < 0) {
			var msg = @"Could not open console on '$(CONSOLE_PATH)'";
			throw new SetupConsoleError.COULD_NOT_OPEN_CONSOLE(msg);
		}

		if (type == ConsoleType.OWNER)
			Posix.ioctl(Linux.Termios.TIOCSCTTY, 1);
		break;
	case ConsoleType.NONE:
		/* No console really means /dev/null */
		fd = Posix.open(DEV_NULL_PATH, Posix.O_RDWR | Posix.O_NOCTTY);
		if (fd < 0) {
			var msg = @"Could not open console on '$(DEV_NULL_PATH)'";
			throw new SetupConsoleError.COULD_NOT_OPEN_CONSOLE(msg);
		}
		break;
	}
	
	/* Reset to sane defaults, cribbed from sysviit, initng, etc. */
	if (reset) {
		Posix.termios tty = {};
		Posix.tcgetattr(fd, tty);

		tty.c_cflag &= (Posix.CBAUD | Posix.CBAUDEX | Posix.CSIZE | Posix.CSTOPB
						| Posix.PARENB | Posix.PARODD);
		tty.c_cflag |= (Posix.HUPCL | Posix.CLOCAL | Posix.CREAD);

		/* Set up usual keys */
		tty.c_cc[Posix.VINTR]  = 3;   /* ^C */
		tty.c_cc[Posix.VQUIT]  = 28;  /* ^\ */
		tty.c_cc[Posix.VERASE] = 127;
		tty.c_cc[Posix.VKILL]  = 24;  /* ^X */
		tty.c_cc[Posix.VEOF]   = 4;   /* ^D */
		tty.c_cc[Posix.VTIME]  = 0;
		tty.c_cc[Posix.VMIN]   = 1;
		tty.c_cc[Posix.VSTART] = 17;  /* ^Q */
		tty.c_cc[Posix.VSTOP]  = 19;  /* ^S */
		tty.c_cc[Posix.VSUSP]  = 26;  /* ^Z */

		tty.c_iflag = (Posix.IGNPAR | Posix.ICRNL | Posix.IXON | Posix.IXANY);
		tty.c_oflag = (Posix.OPOST | Posix.ONLCR);
		tty.c_lflag = (Posix.ISIG | Posix.ICANON | Posix.ECHO | Posix.ECHOCTL
					   | Posix.ECHOPRT | Posix.ECHOKE);

		/* Set the terminal line and flush it */
		Posix.tcsetattr(0, Posix.TCSANOW, tty);
		Posix.tcflush(0, Posix.TCIOFLUSH);
	}

	while (Posix.dup(fd) < 2);
}

public delegate bool Predicate();

public bool CHECK( Predicate p, string message, bool abort = false )
{
	if ( p() )
	{
		return true;
	}

	FsoFramework.theLogger.error( @"$message: $(strerror(errno))" );

	if ( abort )
	{
		Posix.exit( -1 );
	}

	return false;
}


} // namespace

