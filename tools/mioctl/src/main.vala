/*
 * -- Mickey's ioctl utility --
 *
 * Copyright (C) 2010-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 */

//=========================================================================//
int main( string[] args )
{
    if ( args.length != 4 )
    {
        stdout.printf( "Usage: mioctl <filename> <ioctl> <parameter>\n" );
        return 1;
    }

    var fd = Posix.open( args[1], Posix.O_RDONLY );
    if ( fd == -1 )
    {
        stdout.printf( @"Error: can't open $(args[1]): $(strerror(errno))\n" );
        return 1;
    }

    int ctl = 0;
    int param = 0;

    if ( args[2].has_prefix( "0x" ) )
    {
        args[2].scanf( "%x", &ctl );
    }
    else
    {
        ctl = args[2].to_int();
    }

    if ( args[3].has_prefix( "0x" ) )
    {
        args[3].scanf( "%x", &param );
    }
    else
    {
        param = args[3].to_int();
    }

    var res = Linux.ioctl( fd, ctl, param );
    if ( res == -1 )
    {
        stdout.printf( @"Error: can't ioctl on $(args[1]): $(strerror(errno))\n" );
        return 1;
    }

    return 0;
}

// vim:ts=4:sw=4:expandtab
