/**
 * -- freesmartphone.org boot utility --
 *
 * Copyright (C) 2010 Simon Busch <morphis@gravedo.de>
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

namespace FsoInit {

public BaseConfiguration createMachineConfiguration()
{
	return new PalmPreConfiguration();
}

public class PalmPreConfiguration : BaseConfiguration
{
	construct
	{
		name = "palmpre";
	}

	public override void registerActionsInQueue(IActionQueue queue)
	{
		queue.registerAction(new ValidateSystemAction());

		// Mount proc and sysfs filesystem
		queue.registerAction(new MountFilesystemAction.with_settings(0555, "proc", "/proc", "proc", Linux.MountFlags.MS_SILENT));
		queue.registerAction(new MountFilesystemAction.with_settings(0755, "sys", "/sys", "sysfs",  Linux.MountFlags.MS_SILENT | Linux.MountFlags.MS_NOEXEC | Linux.MountFlags.MS_NODEV | Linux.MountFlags.MS_NOSUID));
		queue.registerAction(new MountFilesystemAction.with_settings(0755, "devpts", "/dev/pts", "devpts", Linux.MountFlags.MS_SILENT | Linux.MountFlags.MS_NOEXEC | Linux.MountFlags.MS_NODEV | Linux.MountFlags.MS_NOSUID));

		// Remount rootfs read-write
		queue.registerAction(new SpawnProcessAction.with_settings("/bin/mount -o remount,rw /"));

		// Turn led on, so the user know the init process has been started
		queue.registerAction(new SysfsConfigAction.with_settings("/sys/class/leds/core_navi_center/brightness", "10"));

		// FIXME: we don't want to use udev anymore, but currently we
		// don't have devtmpfs in our kernel. When devtmpfs is ported to
		// our kernel we stop using udev

		// Start udev
		queue.registerAction(new SpawnProcessAction.with_settings("/etc/init.d/udev start"));

		// Turn led on, so the user know the init process has been started
		queue.registerAction(new SysfsConfigAction.with_settings("/sys/class/leds/core_navi_center/brightness", "50"));

		// Populate volatile
		// FIXME

		// Debug!
		queue.registerAction(new SysfsConfigAction.with_settings("/sys/class/leds/core_navi_left/brightness", "50"));

		// Set the hostname
		queue.registerAction(new SetupHostnameAction());

		// Configure network interface
		queue.registerAction(new ConfigureNetworkInterfaceAction.with_settings("usb0", "192.168.0.202", "255.255.255.0"));

		// Debug!
		queue.registerAction(new SysfsConfigAction.with_settings("/sys/class/leds/core_navi_right/brightness", "50"));

		// Launch several other daemons we need right after the init process is over
		queue.registerAction(new SpawnProcessAction.with_settings("/usr/bin/dbus-daemon --system --fork"));
		queue.registerAction(new SpawnProcessAction.with_settings("/etc/init.d/dropbear start"));

		queue.registerAction(new SpawnProcessAction.with_settings("/sbin/getty 115200 console"));

		// Debug!
		queue.registerAction(new SysfsConfigAction.with_settings("/sys/class/leds/core_navi_right/brightness", "0"));
		queue.registerAction(new SysfsConfigAction.with_settings("/sys/class/leds/core_navi_left/brightness", "0"));

		// Turn led off to let the user know we have finished
		queue.registerAction(new SysfsConfigAction.with_settings("/sys/class/leds/core_navi_center/brightness", "0"));
	}
}

} // namespace

// vim:ts=4:sw=4:expandtab
