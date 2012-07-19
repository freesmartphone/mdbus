/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 * @class FsoGps.SatelliteInfo
 **/
public class FsoGps.SatelliteInfo
{
    int id;
    int elevation;
    int azimuth;
    int quality;

    public SatelliteInfo( int id, int elevation, int azimuth, int quality )
    {
        this.id = id;
        this.elevation = elevation;
        this.azimuth = azimuth;
        this.quality = quality;
    }
}

/**
 * @class FsoGps.FixInfo
 **/
public class FsoGps.FixInfo
{
    float lat;
    float lon;

    public FixInfo( float lat, float lon )
    {
        this.lat = lat;
        this.lon = lon;
    }
}

// vim:ts=4:sw=4:expandtab
