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

namespace FsoInit {

public class MountFilesystemAction : IAction, GLib.Object
{
	public Posix.mode_t mode;
	public string fs_type { get; set; }
	public string source { get; set; default = ""; }
	public string target { get; set; default = ""; }
	public string name { get { return "MountFileSystemAction"; } }
	public long flags { get; set; default = Linux.MountFlags.MS_SILENT; }
	
	construct
	{
		mode = (Posix.mode_t) 0755;
	}
	
	public MountFilesystemAction.with_settings(Posix.mode_t mode, string source, string target,  string fs_type, Linux.MountFlags flags)
	{
		this.mode = mode;
		this.fs_type = fs_type;
		this.source = source;
		this.target = target;
		this.flags = flags;
	}

	public string to_string() 
	{
		string tmp = @"[$(name)] :: ";
		tmp += "mode='%l' ".printf((long)mode);
		tmp += @"source='$(source)' ";
		tmp += @"target='$(target)' ";
		tmp += @"fs_type='$(fs_type)' ";
		// FIXME write function to translate flags into string
		tmp += @"flags=''"; 
		return tmp;
	}

	public void run() throws ActionError
	{
		if (!FsoFramework.FileHandling.isPresent(target))
		{
			FsoFramework.theLogger.info(@"$(target) is not present, trying to create..." );
			if (!FsoFramework.FileHandling.createDirectory(target, mode))
			{
				FsoFramework.theLogger.error(@"Can't create $(target): $(strerror(errno))" );
				throw new ActionError.COULD_NOT_CREATE_TARGET_DIRECTORY("could not create target directory");
			}
		}
		
		if (Linux.mount(source, target, fs_type, (Linux.MountFlags)flags) == -1)
		{
			FsoFramework.theLogger.error(@"can't mount $(source) on $(target)");
			throw new ActionError.COULD_NOT_MOUNT_FILESYSTEM("Could not mount filesystem");	
		}
	}

	public void reset() throws ActionError
	{
		if (!FsoFramework.FileHandling.isPresent( target ))
		{
			if (Linux.umount(target) == -1) 
			{
				FsoFramework.theLogger.error(@"can not umount $(target)");
				throw new ActionError.COULD_NOT_UMOUNT_FILESYSTEM("Could not umount filesystem");
			}
		}
	}
}

} // namespace

