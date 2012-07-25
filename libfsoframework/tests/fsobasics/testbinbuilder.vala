/* 
 * File Name: 
 * Creation Date: 
 * Last Modified: 
 *
 * Authored by Frederik 'playya' Sdun <Frederik.Sdun@googlemail.com>
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */
using GLib;

void test_string()
{
    var bin = new FsoFramework.BinBuilder();
    var s = "HEllo World";
    bin.append_string(s);
    assert((s.length + 1) == bin.length);
}

void test_string_padding()
{
    var bin = new FsoFramework.BinBuilder();
    bin.append_string("HELLO WORLD", true, 20, ' ');
    assert(bin.length == 20);
}

void test_align()
{
    var bin = new FsoFramework.BinBuilder(4, ' ');
    bin.append_uint8('H');
    assert((bin.length % 4) == 0);

    bin.append_uint16(42);
    assert((bin.length % 4) == 0);

    bin.append_uint32((uint32)0xFFFFFFFF);
    assert((bin.length % 4) == 0);

    bin.append_uint64((uint64)0x1111111111111111);
    assert((bin.length % 4) == 0);

    bin.append_string("hallo welt");
    assert((bin.length % 4) == 0);

    bin.append_data({0x11, 0x22, 0x33});
    assert((bin.length % 4) == 0);
}

void test_set()
{
    var bin = new FsoFramework.BinBuilder();
    bin.set_uint8(10, 100);
    assert(bin.length == 101);

    bin.set_uint64(0xFFFF, 10);
    assert(bin.length == 101);

    bin.set_uint32(11, 100);
    assert(bin.length == 104);
}

void main(string[] args)
{
    Test.init(ref args);

    Test.add_func("/FsoFramework.BinBuilder/Set", test_set);
    Test.add_func("/FsoFramework.BinBuilder/Align", test_align);
    Test.add_func("/FsoFramework.BinBuilder/Padding", test_string_padding);
    Test.add_func("/FsoFramework.BinBuilder/Strings", test_string);

    Test.run();
}

// vim:ts=4:sw=4:expandtab
