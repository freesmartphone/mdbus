/* 
 * plugin.vala
 * Written by FSO Team
 * All Rights Reserved
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */ 


using GLib;
using FreeSmartphone;


public class Alarm : FreeSmartphone.Time.Alarm, FsoFramework.AbstractObject
{

	public override string repr()
    {
        return "<%s>".printf( FsoFramework.Time.AlarmServicePath );
    }
	
	public void clear_alarm(string busname) throws DBus.Error
	{
		
	}

	public void set_alarm(string busname, int timestamp) throws DBus.Error
	{

	}

}
    