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

/**
 * @class FsoFramework.AbstractWorkerQueue
 **/
public abstract interface FsoFramework.AbstractWorkerQueue<T> : GLib.Object
{
    public delegate void WorkerFunc<T>( T element );

    public abstract void setDelegate( WorkerFunc<T> worker );
    public abstract void enqueue( T element );
    public abstract void trigger();
}

/**
 * @class FsoFramework.AsyncWorkerQueue
 **/
public class FsoFramework.AsyncWorkerQueue<T> : FsoFramework.AbstractWorkerQueue<T>, GLib.Object
{
    protected GLib.Queue<T> q;
    protected AbstractWorkerQueue.WorkerFunc<T> worker;
    uint watch;

    protected bool _onIdle()
    {
        assert( worker != null );

        worker( q.pop_tail() );
        watch = 0;
        return false; // don't call again
    }

    construct
    {
        q = new GLib.Queue<T>();
    }

    public void setDelegate( AbstractWorkerQueue.WorkerFunc<T> worker )
    {
        this.worker = worker;
        trigger();
    }

    public void enqueue( T element )
    {
        var retrigger = ( q.length == 0 );
        q.push_head( element );

        if ( retrigger && worker != null )
            trigger();
    }

    public void trigger()
    {
        assert( q.length > 0 );
        assert( worker != null );
        watch = GLib.Idle.add( _onIdle );
    }
}

