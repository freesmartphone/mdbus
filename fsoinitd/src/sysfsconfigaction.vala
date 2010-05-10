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
	public string path { get; set; default = ""; }
	public string valueForWrite { get; set; default = ""; }
	
	
	public SysfsConfigAction.with_settings(string pathname, string val) 
	{
		this.path = pathname;
		this.valueForWrite = val;
	}

	public string to_string() 
	{
		return @"[$(name)] :: path='$(path)' valueForWrite='$(valueForWrite)'";
	}

	public bool run()
	{
		if (path.length == 0 && valueForWrite.length == 0) 
		{
			FsoFramework.theLogger.error("Arguments are invalid!");
			return false;
		}
		
		if (FsoFramework.FileHandling.isPresent(path)) 
		{
			FsoFramework.theLogger.debug(@"SysfsConfigAction: '$(valueForWrite)' = '$(path)'");
			FsoFramework.FileHandling.write(valueForWrite, path);
		}
		else 
		{
			FsoFramework.theLogger.error("Could not sysfs node");
			return false;
		}
		
		return true;
	}

	public bool reset()
	{
		// do nothing ...
		return true;
	}
}

} // namespace

