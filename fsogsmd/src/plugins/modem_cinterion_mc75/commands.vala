/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

using FsoGsm;
using Gee;

namespace CinterionMc75
{

/**
 * +CIEV: ciphcall,1
 **/
public class CinterionPlusCIEV : FsoGsm.TwoParamsAtCommand<string,int>
{
    public CinterionPlusCIEV()
    {
        base( "+CIEV" );
    }
}

/**
 * Register all custom commands
 **/
public void registerCustomAtCommands( HashMap<string,AtCommand> table )
{
    table[ "+CIEV" ]           = new CinterionPlusCIEV();
}

} /* namespace QualcommHtc */

// vim:ts=4:sw=4:expandtab
