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
		// Mount proc and sysfs filesystem
		queue.registerAction(new SpawnProcessAction.with_settings("mount -t proc proc /proc -o rw,noexec,nosuid,nodev"));
		queue.registerAction(new SpawnProcessAction.with_settings("mount -t sysfs sys /sys -o rw,noexec,nosuid,nodev"));
		
		// Remount rootfs read-write
		queue.registerAction(new SpawnProcessAction.with_settings("mount -o remount,rw /"));
		
		// FIXME: we don't want to use udev anymore, but currently we 
		// don't have devtmpfs in our kernel. When devtmpfs is ported to
		// our kernel we stop using udev
		
		// Start udev
		queue.registerAction(new SpawnProcessAction.with_settings("/etc/init.d/udev start"));
		
		// Turn led on, so the user know the init process has been started
		queue.registerAction(new SysfsConfigAction.with_settings("/sys/class/leds/core_navi_center/brightness", "50"));
		
		// Populate volatile
		// FIXME

		// Mount relevant filesystems
		queue.registerAction(new SpawnProcessAction.with_settings("mount -t tmpfs tmpfs /tmp"));
		queue.registerAction(new SpawnProcessAction.with_settings("mount -t devpts devpts /dev/pts"));
		
		// Debug!
		queue.registerAction(new SysfsConfigAction.with_settings("/sys/class/leds/core_navi_left/brightness", "50"));

		// Set the hostname
		queue.registerAction(new SetupHostnameAction());
		
		// Configure network interface
		queue.registerAction(new SpawnProcessAction.with_settings("/sbin/ifup -f lo"));
		queue.registerAction(new SpawnProcessAction.with_settings("/sbin/ifup -f usb0"));
		queue.registerAction(new SpawnProcessAction.with_settings("/sbin/ifconfig usb0 192.168.0.202"));
		
		// Debug!
		queue.registerAction(new SysfsConfigAction.with_settings("/sys/class/leds/core_navi_right/brightness", "50"));

		// Launch several other daemons we need right after the init process is over
		queue.registerAction(new SpawnProcessAction.with_settings("dbus-daemon --system --fork"));
		queue.registerAction(new SpawnProcessAction.with_settings("/etc/init.d/dropbear start"));
		
		queue.registerAction(new SpawnProcessAction.with_settings("/sbin/getty 38400 tty0"));
		
		// Debug!
		queue.registerAction(new SysfsConfigAction.with_settings("/sys/class/leds/core_navi_right/brightness", "0"));
		queue.registerAction(new SysfsConfigAction.with_settings("/sys/class/leds/core_navi_left/brightness", "0"));

		// Turn led off to let the user know we have finished
		queue.registerAction(new SysfsConfigAction.with_settings("/sys/class/leds/core_navi_center/brightness", "0"));
	}
}

} // namespace

