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

using Gee;

namespace FsoInit
{

public class ActionQueue : IActionQueue, GLib.Object
{
	private ArrayList<IAction> actions;

	construct
	{
		actions = new ArrayList<IAction>();
	}
	
	public void registerAction(IAction action)
	{
		actions.add(action);
	}

	public void run() 
	{
		foreach (var action in actions)
		{
			
			FsoFramework.theLogger.debug(@"run '$(action.name)' action ...");
			FsoFramework.theLogger.debug(@"ACTION INFO: $(action.to_string())");
			
			if (!action.run())
			{
				FsoFramework.theLogger.error(@"an error occured while running action '$(action.name)'");
				FsoFramework.theLogger.error(@"action was executed as the following: ");
				FsoFramework.theLogger.error(@" -> $(action.to_string())");
			}	
			else 
			{
				FsoFramework.theLogger.debug(@"--> finished action'$(action.name)'");
			}
		}
	}
}

}
