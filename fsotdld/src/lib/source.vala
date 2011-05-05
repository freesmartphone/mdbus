/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using Gee;

namespace FsoTime { public FsoTime.Source theSource; }

public interface FsoTime.Source : FsoFramework.AbstractObject
{
    public abstract void triggerQuery();

    public signal void reportTime( int since_epoch, FsoTime.Source source );
    public signal void reportZone( string zone, FsoTime.Source source );
    public signal void reportLocation( double lat, double lon, int height, FsoTime.Source source );
}

public abstract class FsoTime.AbstractSource : FsoTime.Source, FsoFramework.AbstractObject
{
    public abstract void triggerQuery();

    construct
    {
    }

    ~AbstractSource()
    {
    }

}

// vim:ts=4:sw=4:expandtab

