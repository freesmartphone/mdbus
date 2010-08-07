/*
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

public class MsmData
{
    private static MsmData _instance = null;
    
    public static MsmData instance 
    {
        get
        {
            if (_instance == null)
            {
                _instance = new MsmData();
            }
            return _instance;
        }
    }
    
    public enum SimPinStatus
    {
        DISABLED,
        ENABLED,
        BLOCKED,
        PERM_BLOCKED,
        CHANGED, // TODO: do we really need this state here?
    }
    
    public SimPinStatus pin1_status { get; set; default = SimPinStatus.ENABLED; }
    public SimPinStatus pin2_status { get; set; default = SimPinStatus.ENABLED; }
    
    private MsmData()
    {
        
    }
}

