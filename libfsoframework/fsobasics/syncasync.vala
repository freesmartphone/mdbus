/**
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

namespace FsoFramework
{
    public async void asyncWaitSeconds( int seconds )
    {
        GLib.Timeout.add_seconds( seconds, asyncWaitSeconds.callback );
        yield;
    }
} /* namespace */

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
    private int secs;
    private  bool timeout;

    public static bool Wait( uint secs, owned GLib.SourceFunc func )
    {
        var w = new WaitForPredicate( secs, func );
#if DEBUG
        debug( "ended with timeout %d", (int)w.timeout );
#endif
        return w.timeout;
    }

    public WaitForPredicate( uint secs, owned GLib.SourceFunc func )
    {
        this.secs = (int)secs;
        this.func = func;
        loop = new MainLoop();
        Timeout.add_seconds( 1, onTimeout );
        loop.run();
    }

    protected bool onTimeout()
    {
#if DEBUG
        debug( "onTimeout: secs = %d", secs );
#endif
        if ( secs-- == 0 )
        {
            timeout = true;
            loop.quit();
            return false;
        }

        timeout = func();
        if ( !timeout )
        {
            loop.quit();
            return false;
        }
        return true;
    }
}

// vim:ts=4:sw=4:expandtab
