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

namespace GLib
{
    public const bool SOURCE_CALL_AGAIN = true;
    public const bool SOURCE_CALL_NEVER = false;
}

namespace FsoFramework
{
    public enum Ternary
    {
        UNKNOWN = -1,
        FALSE = 0,
        TRUE = 1,
    }

    public class Pair<T1,T2>
    {
        public T1 first;
        public T2 second;

        public Pair( T1 first, T2 second )
        {
            this.first = first;
            this.second = second;
        }
    }

    public class Triple<T1,T2,T3>
    {
        public T1 first;
        public T2 second;
        public T3 third;

        public Triple( T1 first, T2 second, T3 third )
        {
            this.first = first;
            this.second = second;
            this.third = third;
        }
    }

    public class Quadtruple<T1,T2,T3,T4>
    {
        public T1 first;
        public T2 second;
        public T3 third;
        public T4 fourth;

        public Quadtruple( T1 first, T2 second, T3 third, T4 fourth )
        {
            this.first = first;
            this.second = second;
            this.third = third;
            this.fourth = fourth;
        }
    }

    public bool typeInherits( Type subtype, Type type )
    {
        return type in subtype.children();
    }
}

// vim:ts=4:sw=4:expandtab
