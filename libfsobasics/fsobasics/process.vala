/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using FsoFramework.FileHandling;

/**
 * @interface FsoFramework.IProcessGuard
 **/
public interface FsoFramework.IProcessGuard : GLib.Object
{
    public abstract bool launch( string[] command );
    public abstract void stop( int sig = Posix.SIGTERM );
    public abstract void setAutoRelaunch( bool on );

    public abstract bool sendSignal( int sig );
    public abstract bool isRunning();

    public signal void running();
    public signal void stopped();
}

/**
 * Some process relevant utility functions
 **/
namespace FsoFramework.Process
{
    private static const string PROC_PATH = "/proc";

    public Posix.pid_t pidof( string name )
    {
        int result = 0;
        int pid = 0;
        string statfile, pstat, comm, pname;
        string[] stat_info;
        string[] subdirs = listDirectory( PROC_PATH );

        foreach ( var dirname in subdirs )
        {
            pid = dirname.to_int();

            // check for invalid pid and ignore them
            if ( pid <= 0 )
                continue;

            // Now we have a valid pid, find out more about the process! (see man 5 proc
            // for more details)
            statfile = @"$(PROC_PATH)/$(pid)/stat";
            if ( !isPresent(statfile) )
                continue;

            pstat = read( statfile );
            stat_info = pstat.split( " " );

            // validate process command name for correct length
            if ( !( stat_info.length >= 2 ) && stat_info[1].length > 2 )
                continue;

            // extract and check process name for the correct one
            pname = (stat_info[1])[1:stat_info[1].length-2];
            if ( name.has_prefix( pname ) )
            {
                result = pid;
                break;
            }
        }

        return (Posix.pid_t) result;
    }
}

/**
 * @class FsoFramework.GProcessGuard
 **/
public class FsoFramework.GProcessGuard : FsoFramework.IProcessGuard, GLib.Object
{
    private Pid pid;
    private uint watch;
    private string[] command;
    private bool relaunch;

    public Posix.pid_t _pid()
    {
        return (Posix.pid_t)pid;
    }

    ~GProcessGuard()
    {
        if ( pid != (Pid)0 )
        {
#if DEBUG
            warning( "Guard being freed, while child %d still running. This is most likely a bug in your problem. Trying to kill the child in a synchronous way...", (int)pid );
#endif
            relaunch = false;
            syncStop();
        }
    }

    public bool launch( string[] command )
    {
        this.command = command; // save for possible relaunching

        if ( pid != (Pid)0 )
        {
            warning( @"Can't launch $(command[0]); already running as pid %d".printf( (int)pid ) );
            return false;
        }

        try
        {
            GLib.Process.spawn_async( GLib.Environment.get_variable( "PWD" ),
                                      command,
                                      null,
                                      GLib.SpawnFlags.DO_NOT_REAP_CHILD | GLib.SpawnFlags.SEARCH_PATH,
                                      null,
                                      out pid );
        }
        catch ( SpawnError e )
        {
            warning( @"Can't spawn $(command[0]): $(strerror(errno))" );
            return false;
        }

        watch = GLib.ChildWatch.add( pid, onChildWatchEvent );
        this.running(); // SIGNAL
        return true;
    }

    public bool launchWithPipes( string[] command, out int fdin, out int fdout )
    {
        this.command = command; // save for possible relaunching

        if ( pid != (Pid)0 )
        {
            warning( @"Can't launch $(command[0]); already running as pid %d".printf( (int)pid ) );
            return false;
        }

        try
        {
            GLib.Process.spawn_async_with_pipes(
                GLib.Environment.get_variable( "PWD" ),
                command,
                null,
                GLib.SpawnFlags.DO_NOT_REAP_CHILD | GLib.SpawnFlags.SEARCH_PATH,
                null,
                out pid,
                out fdin,
                out fdout,
                null );
        }
        catch ( SpawnError e )
        {
            warning( @"Can't spawn w/ pipes $(command[0]): $(e.message))" );
            return false;
        }

        watch = GLib.ChildWatch.add( pid, onChildWatchEvent );
        this.running(); // SIGNAL
        return true;
    }

    // FIXME: consider making this async?
    public void stop( int sig = Posix.SIGTERM )
    {
        stopSendStopped( true );
    }

    public void setAutoRelaunch( bool on )
    {
        relaunch = on;
    }

    public bool sendSignal( int sig )
    {
        if ( pid == (Pid)0 )
        {
            return false;
        }

        var res = Posix.kill( (Posix.pid_t)pid, sig );
        return res == 0;
    }

    public bool isRunning()
    {
        return ( pid != (Pid)0 );
    }

    //
    // private API
    //
    private void stopSendStopped( bool send )
    {
        _stop( send );
    }

    private void cleanupResources()
    {
        if ( watch > 0 )
        {
            GLib.Source.remove( watch );
        }
        GLib.Process.close_pid( pid );
        pid = 0;
        this.stopped();
    }

    private void onChildWatchEvent( Pid pid, int status )
    {
        if ( this.pid != pid )
        {
            critical( "D'OH!" );
            return;
        }
#if DEBUG
        debug( "CHILD WATCH EVENT FOR %d: %d", (int)pid, status );
#endif
        pid = 0;
        cleanupResources();

        if ( relaunch )
        {
#if DEBUG
            debug( "Relanching requested..." );
#endif
            if ( ! launch( command ) )
            {
                warning( @"Could not relaunch $(command[0]); disabling." );
                relaunch = false;
            }
        }
    }

    internal const int KILL_SLEEP_TIMEOUT  = 1000 * 1000 * 5; // 5 seconds
    internal const int KILL_SLEEP_INTERVAL = 1000 * 1000 * 1; // 1 second

    private async void _stop( bool send )
    {
        if ( (Posix.pid_t)pid == 0 )
        {
            return;
        }
#if DEBUG
        debug( "Attempting to stop pid %d - sending SIGTERM first...", pid );
#endif
        Posix.kill( (Posix.pid_t)pid, Posix.SIGTERM );
        var done = false;
        var timer = new GLib.Timer();
        timer.start();

        while ( !done && pid != 0 )
        {
            var pid_result = Posix.waitpid( (Posix.pid_t)pid, null, Posix.WNOHANG );
#if DEBUG
            debug( "Waitpid result %d", pid_result );
#endif
			if ( pid_result < 0 )
			{
				done = true;
#if DEBUG
				debug( "Failed to wait for process to exit: waitpid returned %d", pid_result );
#endif
			}
			else if ( pid_result == 0 )
			{
				if ( timer.elapsed() >= KILL_SLEEP_TIMEOUT )
				{
#if DEBUG
					debug( "Timeout for pid %d elapsed, exiting wait loop", pid );
#endif
					done = true;
				}
				else
				{
#if DEBUG
					debug( "Process %d is still running, waiting...", pid );
#endif
                    Timeout.add_seconds( 1, _stop.callback );
                    yield;
				}
			}
			else /* pid_result > 0 */
			{
				done = true;
#if DEBUG
				debug( "Process %d terminated normally", pid );
#endif
				GLib.Process.close_pid( pid );
				pid = 0;
			}
        }

        if ( pid != 0 )
        {
            warning( "Process %d ignored SIGTERM, sending SIGKILL", pid );

            if ( watch > 0 )
            {
                GLib.Source.remove( watch );
                watch = 0;
            }

            Posix.kill( (Posix.pid_t)pid, Posix.SIGKILL );
            Thread.usleep( 1000 );
            pid = 0;
#if DEBUG
            debug( "Process %d stop complete", pid );
#endif
        }

        if ( send )
        {
            this.stopped();
        }
    }

    private void syncStop()
    {
        if ( watch > 0 )
        {
            GLib.Source.remove( watch );
            watch = 0;
        }
#if DEBUG
        debug( "Attempting to syncstop pid %d - sending SIGTERM first...", pid );
#endif
        Posix.kill( (Posix.pid_t)pid, Posix.SIGTERM );
        var done = false;
        var timer = new GLib.Timer();
        timer.start();

        while ( !done && pid != 0 )
        {
            var pid_result = Posix.waitpid( (Posix.pid_t)pid, null, Posix.WNOHANG );
#if DEBUG
            debug( "Waitpid result %d", pid_result );
#endif
			if ( pid_result < 0 )
			{
				done = true;
#if DEBUG
				debug( "Failed to syncwait for process to exit: waitpid returned %d", pid_result );
#endif
			}
			else if ( pid_result == 0 )
			{
				if ( timer.elapsed() >= KILL_SLEEP_TIMEOUT )
				{
#if DEBUG
					debug( "Timeout for pid %d elapsed, exiting syncwait loop", pid );
#endif
					done = true;
				}
				else
				{
#if DEBUG
					debug( "Process %d is still running, sync waiting...", pid );
#endif
                    Thread.usleep( KILL_SLEEP_INTERVAL );
				}
			}
			else /* pid_result > 0 */
			{
				done = true;
#if DEBUG
				debug( "Process %d terminated normally", pid );
#endif
				GLib.Process.close_pid( pid );
				pid = 0;
			}
        }

        if ( pid != 0 )
        {
            warning( "Process %d ignored SIGTERM, sending SIGKILL", pid );

            if ( watch > 0 )
            {
                GLib.Source.remove( watch );
            }

            Posix.kill( (Posix.pid_t)pid, Posix.SIGKILL );
            Thread.usleep( 1000 );
            pid = 0;
#if DEBUG
            debug( "Process %d stop complete", pid );
#endif
        }
    }
}

public class AsyncProcess : GLib.Object
{
    static const int NUM_FRIENDLY_KILLS = 5;
    ~AsyncProcess()
    {
        Source.remove( child );
    }
    public int std_in
    {
        get
        {
            return _std_in;
        }
    }

    public void set_stdout_watch( GLib.IOFunc watch, GLib.IOCondition cond = GLib.IOCondition.IN | GLib.IOCondition.HUP, GLib.IOFlags flags = GLib.IOFlags.NONBLOCK )
    {
        stdout_watch = watch;
        stdout_condition = cond;
        stdout_flags = flags;
    }

    public void set_stderr_watch( GLib.IOFunc watch, GLib.IOCondition cond = GLib.IOCondition.IN | GLib.IOCondition.HUP, GLib.IOFlags flags = GLib.IOFlags.NONBLOCK )
    {
        stderr_watch = watch;
        stderr_condition = cond;
        stderr_flags = flags;
    }

    IOFunc stdout_watch;
    IOFlags stdout_flags;
    IOCondition stdout_condition;
    IOFunc stderr_watch;
    IOFlags stderr_flags;
    IOCondition stderr_condition;

    string _cmd_line = null;
    public string cmd_line
    {
        get
        {
            if( _cmd_line == null )
                _cmd_line = "\"" + string.joinv( """" """", argv ) + "\"";
            return _cmd_line;
        }
    }

    string[] argv;
    SourceFunc callback;
    Pid pid = 0;

    int _std_in = -1;
    int std_out;
    int std_err;
    IOChannel err_channel;
    IOChannel out_channel;

    int status = 0;
    uint child;

    public async int launch( Cancellable? cancel = null, string[] argv ) throws GLib.SpawnError
    {
        if( cancel != null && cancel.is_cancelled() )
            return -1;

        this.argv = argv;
        GLib.Process.spawn_async_with_pipes(
                        GLib.Environment.get_variable( "PWD" ),
                        argv,
                        null,
                        GLib.SpawnFlags.DO_NOT_REAP_CHILD | GLib.SpawnFlags.SEARCH_PATH,
                        null,
                        out pid,
                        out _std_in,
                        out std_out,
                        out std_err );
        if( stdout_watch != null )
        {
            out_channel = new IOChannel.unix_new( std_out );
            out_channel.set_flags( stdout_flags );
            out_channel.add_watch( stdout_condition, stdout_watch );
        }

        if( stderr_watch != null )
        {
            err_channel = new IOChannel.unix_new( std_out );
            err_channel.set_flags( stdout_flags );
            err_channel.add_watch( stdout_condition, stdout_watch );
        }

        child = ChildWatch.add( pid, onExit );

        if( cancel != null )
            cancel.cancelled.connect( onCancel );

        this.callback = launch.callback;
        yield;

        return status;
    }

    private void onCancel()
    {
        if ( ( Posix.pid_t )pid == 0 )
        {
            return;
        }
        onCancelAsync.begin();
    }

    private async void onCancelAsync()
    {
        for( int i = 0; i < NUM_FRIENDLY_KILLS; ++i )
        {
            if( pid == 0 )
                return;
            Posix.kill( ( Posix.pid_t )pid, Posix.SIGTERM );
            yield FsoFramework.Async.sleep_async( 1000 );
        }

        if( pid != 0 )
            Posix.kill( ( Posix.pid_t )pid, Posix.SIGKILL );
    }

    private void onExit( Pid p, int status )
    {
        assert( callback != null );
        this.status = status;
        pid = 0;
        this.callback();
    }

}
