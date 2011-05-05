/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

using GLib;

using FsoGsm;

class LowLevel.Openmoko : FsoGsm.LowLevel, FsoFramework.AbstractObject
{
    public const string MODULE_NAME = "fsogsm.lowlevel_openmoko";
    private string powerNode;
    private string fcNode;
    private FsoGsm.AbstractModem modem; // for access to modem properties
    private const uint POWERUP_RETRIES = 5;

    construct
    {
        // power node
        powerNode = config.stringValue( MODULE_NAME, "power_node", "unknown" );
        // flow control node
        fcNode = config.stringValue( MODULE_NAME, "fc_node", "unknown" );
        // modem
        modem = FsoGsm.theModem as FsoGsm.AbstractModem;

        logger.info( "Registering openmoko low level poweron/poweroff handling" );
    }

    public override string repr()
    {
        return "<>";
    }

    public bool poweron()
    {
        if ( powerNode == "unknown" )
        {
            logger.error( "power_node not defined. Can't poweron." );
            return false;
        }

        // always turn off first
        poweroff();
#if DEBUG
        debug( "lowlevel_openmoko_poweron()" );
#endif
        Thread.usleep( 1000 * 1000 );

        FsoFramework.FileHandling.write( "1\n", powerNode );
        Thread.usleep( 1000 * 1000 );

        var transport = FsoFramework.Transport.create( modem.modem_transport, modem.modem_port, modem.modem_speed );
        transport.open();
        assert( transport.isOpen() );

        var buf = new char[512];
        var bread = transport.writeAndRead( "AT\r\n", 4, buf, 512, 0 );
        bread = transport.writeAndRead( "AT\r\n", 4, buf, 512, 0 );
        uint i = 0;

        while ( i++ < POWERUP_RETRIES )
        {
            transport.drain();
            transport.flush();

            debug( @" --- while loop ENTER; i = $i" );
            bread = transport.writeAndRead( "ATE0Q0V1\r\n", 10, buf, 512 );
            buf[bread] = '\0';

            var displayString = ((string)buf).escape( "" );
#if DEBUG
            debug( @"setPower: 1) got '$displayString'" );
#endif
            if ( bread > 3 && buf[bread-1] == '\n' && buf[bread-2] == '\r' && buf[bread-3] == 'K' && buf[bread-4] == 'O' )
            {
#if DEBUG
                debug( "setPower: answer OK, ready to send first command" );
#endif
                bread = transport.writeAndRead( "AT%SLEEP=2\r\n", 12, buf, 512 );
                buf[bread] = '\0';

                displayString = ((string)buf).escape( "" );
#if DEBUG
                debug( @"setPower: 2) got '$displayString'" );
#endif

                if ( bread > 3 && buf[bread-1] == '\n' && buf[bread-2] == '\r' && buf[bread-3] == 'K' && buf[bread-4] == 'O' )
                {
#if DEBUG
                    debug( "setPower: answer OK, ready to send MUX command" );
#endif
                    transport.close();
                    return true;
                }
            }
        }
#if DEBUG
        debug( "NOTHING WORKS :/ returning false" );
#endif
        transport.close();
        return false;
    }

    public bool poweroff()
    {
#if DEBUG
        debug( "lowlevel_openmoko_poweroff()" );
#endif
        FsoFramework.FileHandling.write( "0\n", powerNode );
        return true;
    }

    public bool suspend()
    {
#if DEBUG
        debug( "lowlevel_openmoko_suspend()" );
#endif
        if ( fcNode == "unknown" )
        {
            logger.error( "fc_node not defined. Can't prepare for suspend." );
            return false;
        }
        FsoFramework.FileHandling.write( "1", fcNode );
        return true;
    }

    public bool resume()
    {
#if DEBUG
        debug( "lowlevel_openmoko_resume()" );
#endif
        if ( fcNode == "unknown" )
        {
            logger.error( "fc_node not defined. Can't recover from suspend." );
            return false;
        }
        FsoFramework.FileHandling.write( "0", fcNode );
        return true;
    }
}

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    FsoFramework.theLogger.debug( "lowlevel_openmoko fso_factory_function" );
    return LowLevel.Openmoko.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    // do not remove this function
}

// vim:ts=4:sw=4:expandtab
