/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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

/**
 * Simple abstraction for the wakelock mechanism found on every android device. In general
 * you never have to use this class as we don't work with wakelocks but in some situations
 * we can't work around them. Think twice before using this and ask other people if there
 * is a better solution!
 * NOTE: If there is no wakelock support build into your kernel (e.g. /sys/power/wake_*
 * nodes are not present) using this class does really nothing.
 */
public class FsoFramework.Wakelock : GLib.Object
{
    private const string sysfs_wk_lock_path = "/sys/power/wake_lock";
    private const string sysfs_wk_unlock_path = "/sys/power/wake_unlock";

    private bool wakelocks_supported = false;

    /**
     * Name of the wakelock which is used to register the wakelock with the kernel.
     */
    public string name { get; private set; default = "unknown"; }

    /**
     * Current state of the wakelock. True when the wakelock is acquired and false if not.
     */
    public bool acquired { get; private set; default = false; }

    /**
     * Setup up the wakelock with a specific name.
     */
    public Wakelock( string name )
    {
        this.name = name;

        wakelocks_supported = FsoFramework.FileSystem.isPresent( sysfs_wk_lock_path ) &&
                              FsoFramework.FileSystem.isPresent( sysfs_wk_unlock_path );
    }

    /**
     * Acquire the wakelock; it will prevent the system from being suspended now!
     */
    public void acquire()
    {
        if ( !wakelocks_supported )
            return;

        FileSystem.write( name, sysfs_wk_lock_path );
    }

    /**
     * Release the wakelock; it will not prevent the system from going into suspend state
     * anymore.
     */
    public void release()
    {
        if ( !wakelocks_supported )
            return;

        FileSystem.write( name, sysfs_wk_unlock_path );
    }
}

// vim:ts=4:sw=4:expandtab
