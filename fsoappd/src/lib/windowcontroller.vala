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
    public abstract class AbstractWindowController : AbstractObject
    {
        public abstract WindowProperties[] list_all();
        public abstract void hide( WindowProperties window );
        public abstract void show( WindowProperties window );
        public abstract void destroy( WindowProperties window );
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
        logger.warning( "NullWindowController::list_all() - this is probably not what you want" );

        FsoApp.WindowProperties[] result = { };
        return result;
    }

    public override void hide( FsoApp.WindowProperties window )
    {
        logger.warning( "NullWindowController::hide() - this is probably not what you want" );
    }

    public override void show( FsoApp.WindowProperties window )
    {
        logger.warning( "NullWindowController::show() - this is probably not what you want" );
    }

    public override void destroy( FsoApp.WindowProperties window )
    {
        logger.warning( "NullWindowController::destroy() - this is probably not what you want" );
    }
}
