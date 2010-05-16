/*
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

#include <glib-object.h>

// Unfortunately we need to do this in a C file, since Vala
// does not have support for it yet. I have created a bug
// report for that but chances are it won't be accepted upstream
// See https://bugzilla.gnome.org/show_bug.cgi?id=599606

void gcc_library_init() __attribute__((constructor));
void gcc_library_fini() __attribute__((destructor));

void gcc_library_init()
{
    //FIXME: Find out whether it's ok to call g_type_init() multiple times,
    //since Vala is (unconditionally) calling it before launching main()
    g_type_init();
    vala_library_init();
}

void gcc_library_fini()
{
    vala_library_fini();
}
