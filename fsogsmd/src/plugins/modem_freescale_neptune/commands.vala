/*
 * Copyright (C) 2010  Antonio Ospite <ospite@studenti.unina.it>
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

namespace FreescaleNeptune
{

/**
 * Modem violating GSM 07.07 here.
 *
 * Format seems to be +CPIN=<number>,"<PIN>", where 1 is PIN1, 2 may be PIN2 or PUK1
 **/
public class NeptunePlusCPIN : PlusCPIN
{
    public new string issue( int pin_type, string pin)
    {
        return "+CPIN=%d,\"%s\"".printf( pin_type, pin );
    }
}


/**
 * Register all custom commands
 **/
public void registerCustomAtCommands( HashMap<string,AtCommand> table )
{
    table[ "+CPIN" ]              = new NeptunePlusCPIN();
}

} /* namespace FreescaleNeptune */
