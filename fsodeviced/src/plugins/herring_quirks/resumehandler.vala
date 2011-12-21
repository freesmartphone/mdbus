/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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

using GLib;

internal class Herring.ResumeHandler : FsoFramework.AbstractObject
{
    private int fd = 0;
    private IOChannel channel;
    private FreeSmartphone.Usage usage;
    private uint readwatch;
    private int inputnodenumber;
    private int powerkeycode;

    private async void request_usage_service()
    {
        try
        {
            usage = yield Bus.get_proxy<FreeSmartphone.Usage>( BusType.SYSTEM, FsoFramework.Usage.ServiceDBusName,
                FsoFramework.Usage.ServicePathPrefix );
            usage.system_action.connect( on_system_action );
            assert( logger.debug( @"Finished with setup up FSO usage subsystem for use!" ) );
        }
        catch ( GLib.Error err )
        {
            logger.error( @"Could not request proxy object for usage service: $(err.message)" );
        }
    }

    private async void wakeup_system()
    {
        try
        {
            yield usage.resume( "", "" );
        }
        catch ( GLib.Error err )
        {
            logger.error( @"Could not tell the usage daemon to wakeup the system completely: $(err.message)" );
        }
    }

    private bool actionCallback( IOChannel? source, IOCondition condition )
    {
        Linux.Input.Event ev = {};

        if ( ( condition & IOCondition.IN ) == IOCondition.IN )
        {
            var bytesread = Posix.read( fd, &ev, sizeof(Linux.Input.Event) );
            if ( bytesread == 0 )
            {
                assert( logger.debug( @"Action on input node, but can't read from fd $fd; waking up!" ) );
            }
            else if ( ev.code == powerkeycode )
            {
                assert( logger.debug( @"Power key; waking up!" ) );
                stop_resume_watch();
                Idle.add( () => { wakeup_system(); return false; } );
            }
            else
            {
                assert( logger.debug( @"Some other key w/ value $(ev.code); NOT waking up!" ) );
            }
        }

        return true;
    }

    private void stop_resume_watch()
    {
        Source.remove( readwatch );
        assert( logger.debug( "Ungrabbing input node" ) );
        Linux.ioctl( fd, Linux.Input.EVIOCGRAB, 0 );
        Posix.close( fd );
    }

    private void setup_resume_watch()
    {
        if ( fd != 0 )
        {
            logger.warning( @"Input node was still open; closing it first ..." );
            Posix.close( fd );
        }

        assert( logger.debug( "Grabbing input node" ) );
        fd = Posix.open( @"/dev/input/event$inputnodenumber", Posix.O_RDONLY );
        Linux.ioctl( fd, Linux.Input.EVIOCGRAB, 1 );

        channel = new IOChannel.unix_new( fd );

        try
        {
            channel.set_encoding( null );
        }
        catch ( GLib.IOChannelError e )
        {
            logger.warning( @"Can't set channel encoding to null: $(e.message)" );
        }

        channel.set_buffer_size( 32768 );
        readwatch = channel.add_watch_full( 0, IOCondition.IN | IOCondition.HUP, actionCallback );
    }

    private void on_system_action( FreeSmartphone.UsageSystemAction action )
    {
        switch ( action )
        {
            case FreeSmartphone.UsageSystemAction.RESUME:
            case FreeSmartphone.UsageSystemAction.ALIVE:
                assert( logger.debug( @"System is alive again; stopping resume watch ..." ) );
                stop_resume_watch();
                break;
            case FreeSmartphone.UsageSystemAction.SUSPEND:
                assert( logger.debug( @"System is in suspend state now; starting resume watch ..." ) );
                setup_resume_watch();
                break;
        }
    }

    //
    // public API
    //

    public ResumeHandler()
    {
        Idle.add( () => { request_usage_service(); return false; } );

        inputnodenumber = config.intValue( Herring.MODULE_NAME, "wakeup_inputnode", -1 );
        powerkeycode = config.intValue( Herring.MODULE_NAME, "wakeup_powerkeycode", -1 );
    }

    public override string repr()
    {
        return @"<>";
    }
}

// vim:ts=4:sw=4:expandtab
