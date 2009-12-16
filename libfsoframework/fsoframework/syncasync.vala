/**
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

public class FsoFramework.SyncWrapper : GLib.Object
{
    protected GLib.VoidFunc func;
    protected GLib.MainLoop loop;
    
    public SyncWrapper( owned GLib.VoidFunc func )
    {
        this.func = func;
        loop = new MainLoop();
        // unfortunately a closure does not work here, ideally we'd just:
        // Idle.add( () => { func(); loop.quit(); return false; } );
        // however vala bails out with some target_func not found then
        Idle.add( onIdle );
        loop.run();
    }

    protected virtual bool onIdle()
    {
        func();
        loop.quit();
        return false;
    }
}

public class FsoFramework.WaitForPredicate : GLib.Object
{
    private GLib.SourceFunc func;
    private GLib.MainLoop   loop;
    private uint secs;
    public  bool timeout;

    public WaitForPredicate( uint secs, owned GLib.SourceFunc func )
    {
        this.secs = secs;
        this.func = func;
        loop = new MainLoop();
        Idle.add( onIdle );
        loop.run();
    }

    protected bool onIdle()
    {
        var now = time_t();
        var then = now + (time_t) secs;

        while ( time_t() < then && func() )
        {
            loop.get_context().iteration( false );
        }
        timeout = func();
        loop.quit();
        return false;
    }
}
