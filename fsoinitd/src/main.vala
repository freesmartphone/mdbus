/**
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *                         Simon Busch <morphis@gravedo.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 **/

using FsoFramework;
using FsoInit;

GLib.MainLoop mainloop;

int main( string[] args )
{
    var binname = Utility.programName();

    theLogger.info("Starting system ...");

    mainloop = new GLib.MainLoop(null, false);

    // Assure that we are the number one in the system!
    var res = (int) Posix.getpid();
    if (res != 1)
    {
        theLogger.error("Aborting ... We are not the first process in the system!");
        return -1;
    }

    // Assure that we started as root
    res = (int) Posix.getuid();
    if (!Util.CHECK( () => { return res > -1; }, "Need to be root!"))
        return -1;

    // Become the leader of a new session and process group
    Posix.setsid();

    // Set root directory to be at the right place if we were
    // started from some strange place
    res = Posix.chdir("/");
    if (!Util.CHECK( () => { return res > -1; }, "Cannot set root directory!"))
    return -1;

    // Set path for binaries
    var path = "/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin";
    GLib.Environment.set_variable("PATH", path, true);

    // Change destination of stdout and stderr to the console device and stdin to
    // /dev/null
    if (!Util.setupConsole(true))
    {
        return -1;
    }

    // FIXME Mount relevant filesystems like dev, proc, sysfs, ...

    // FIXME Run machine specific init steps

    mainloop.run();

    theLogger.info("Stopping system ...");

    return 0;
}

// vim:ts=4:sw=4:expandtab
