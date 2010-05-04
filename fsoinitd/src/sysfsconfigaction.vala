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

public class SysfsConfigAction : IAction, GLib.Object
{
	public string name { get { return "SysfsConfigAction"; } }
	public string path { get; set; }
	public string valueForWrite { get; set; }
	
	
	public SysfsConfigAction.with_settings(string path, string valueToWrite) 
	{
		this.path = path;
		this.valueForWrite = valueForWrite;
	}

	public void run() throws ActionError
	{
		if (FsoFramework.FileHandling.isPresent(path)) 
		{
			FsoFramework.theLogger.info(@"SysfsConfigAction: '$(valueForWrite)' = '$(path)'");
			FsoFramework.FileHandling.write(valueForWrite, path);
		}
		else 
		{
			throw new ActionError.COULD_NOT_FIND_SYSFS_NODE("Could not sysfs node");
		}
	}

	public void reset() throws ActionError
	{
		// do nothing ...
	}
}

} // namespace

