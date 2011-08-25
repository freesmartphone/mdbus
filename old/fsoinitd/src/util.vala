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

using Posix;

namespace FsoInit.Util
{

public const string CONSOLE_PATH = "/dev/console";
public const string DEV_NULL_PATH = "/dev/null";
public const string TTY_PATH = "/dev/tty";

/**
 * setupConsole:
 * @reset: reset console to sane defaults
 *
 * Set up the standard input, output and error file descriptors for the
 * current process based on the console @type given. If @reset is TRUE then
 * the console device will be reset to sane defaults.
 *
 * @return:  setup process of the console was successfull
 **/
public bool setupConsole(bool reset)
{
    int tty_fd = -1, null_fd = -1, i;

    /* Close the standard file descriptors since we're about to re-open
     * them; it may be that some of these aren't already open, we got
     * called in some very strange ways.
     */
    for (i = 0; i < 3; i++)
        close(i);

    /* Release tty */
    tty_fd = open(TTY_PATH, O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (tty_fd < 0)
    {
        FsoFramework.theLogger.error(@"Could not open tty on '$(TTY_PATH)'");
        return false;
    }

    if (ioctl(tty_fd, Linux.Termios.TIOCNOTTY) < 0)
    {
        close(tty_fd);
        FsoFramework.theLogger.error(@"Could not run ioctl(TIOCNOTTY) on $(TTY_PATH)");
        return false;
    }

    close(tty_fd);

    /* Open /dev/console and /dev/null */
    tty_fd = open(CONSOLE_PATH, O_WRONLY);
    if (tty_fd < 0) {
        FsoFramework.theLogger.error(@"Could not open console on '$(CONSOLE_PATH)'");
        return false;
    }

    null_fd = open(DEV_NULL_PATH, O_RDONLY);
    if (null_fd < 0) {
        close(tty_fd);
        FsoFramework.theLogger.error(@"Could not open /dev/null on '$(DEV_NULL_PATH)'");
        return false;
    }

    GLib.assert(tty_fd >= 3);
    GLib.assert(null_fd >= 3);

    /* Reset to sane defaults, cribbed from sysviit, initng, etc. */
    if (reset) {
        termios tty = {};
        tcgetattr(tty_fd, tty);

        tty.c_cflag &= (CBAUD | CBAUDEX | CSIZE | CSTOPB
                        | PARENB | PARODD);
        tty.c_cflag |= (HUPCL | CLOCAL | CREAD);

        /* Set up usual keys */
        tty.c_cc[VINTR]  = 3;   /* ^C */
        tty.c_cc[VQUIT]  = 28;  /* ^\ */
        tty.c_cc[VERASE] = 127;
        tty.c_cc[VKILL]  = 24;  /* ^X */
        tty.c_cc[VEOF]   = 4;   /* ^D */
        tty.c_cc[VTIME]  = 0;
        tty.c_cc[VMIN]   = 1;
        tty.c_cc[VSTART] = 17;  /* ^Q */
        tty.c_cc[VSTOP]  = 19;  /* ^S */
        tty.c_cc[VSUSP]  = 26;  /* ^Z */

        tty.c_iflag = (IGNPAR | ICRNL | IXON | IXANY);
        tty.c_oflag = (OPOST | ONLCR);
        tty.c_lflag = (ISIG | ICANON | ECHO | ECHOCTL
                       | ECHOPRT | ECHOKE);

        /* Set the terminal line and flush it */
        tcsetattr(0, TCSANOW, tty);
        tcflush(0, TCIOFLUSH);
    }

    /* move stdout/stderr to /dev/console and stdin to /dev/null */
    if (dup2(tty_fd, STDOUT_FILENO) < 0 ||
        dup2(tty_fd, STDERR_FILENO) < 0 ||
        dup2(null_fd, STDIN_FILENO) < 0)
    {
        close(tty_fd);
        close(null_fd);
        FsoFramework.theLogger.error(@"Could not move stdin,stdout and stderr to console or /dev/null");
        return false;
    }

    close(tty_fd);
    close(null_fd);

    return true;
}

public delegate bool Predicate();

public bool CHECK( Predicate p, string message, bool abort = false )
{
    if ( p() )
    {
        return true;
    }

    FsoFramework.theLogger.error( @"$message: $(Posix.strerror(Posix.errno))" );

    if ( abort )
    {
        exit( -1 );
    }

    return false;
}


} // namespace

// vim:ts=4:sw=4:expandtab
