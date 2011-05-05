/*
 * (c) 2011 Simon Busch <morphis@gravedo.de>
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
using FsoFramework;

namespace FsoApp
{
    public struct WindowProperties
    {
        public int id;
        public string classname;
        public Posix.pid_t pid;
    }

    public abstract class AbstractWindowController : AbstractObject
    {
        public abstract WindowProperties[] list_all();
        public abstract void hide( int id );
        public abstract void show( int id );
        public abstract void destroy( int id );
    }
}

public class NullWindowController : FsoApp.AbstractWindowController
{
    public override string repr()
    {
        return "<>";
    }

    public override FsoApp.WindowProperties[] list_all()
    {
        logger.warning( "NullController::list_all() - this is probably not what you want" );

        FsoApp.WindowProperties[] result = { };
        return result;
    }

    public override void hide( int id )
    {
        logger.warning( "NullController::hide() - this is probably not what you want" );
    }

    public override void show( int id )
    {
        logger.warning( "NullController::show() - this is probably not what you want" );
    }

    public override void destroy( int id )
    {
        logger.warning( "NullController::destroy() - this is probably not what you want" );
    }
}

// vim:ts=4:sw=4:expandtab
