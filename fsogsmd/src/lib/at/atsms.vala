/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *               2012 Simon Busch <morphis@gravedo.de>
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

using Gee;

/**
 * @class AtSmsHandler
 **/
public class FsoGsm.AtSmsHandler : FsoGsm.AbstractSmsHandler
{
    private bool ack_supported = true;

    //
    // protected
    //

    /**
     * Choose a preferred value from a list if it's in a list of supported values too
     *
     * @param pref Priorized list of prefered values.
     * @param supported List of supported values
     * @return The most priorized, prefered and supported value. Otherwise -1
     **/
    protected int choose_from_preference( int[] pref, ArrayList<int> supported )
    {
        foreach ( var p in pref )
        {
            if ( p in pref )
                return p;
        }

        return -1;
    }

    /**
     * Configure SMS message service mode. See 27.005, section 3.2.1 for more details.
     *
     * If a single modem needs a different configuration (because some settings are
     * supported by the modem but not working correctly) it should subclass this class and
     * override this method to provide it's specific configuration.
     *
     * @return True, if configuration was successfull. False, otherwise.
     **/
    protected virtual async bool configureMessageService()
    {
        // First we're gathing which types of SMS services are supported and select the
        // one which suites best for our needs.
        var csms = modem.createAtCommand<PlusCSMS>( "+CSMS" );
        // Try to enable GSM phase 2+ commands
        var response = yield modem.processAtCommandAsync( csms, csms.issue( 1 ) );
        if ( csms.validateOk( response ) != Constants.AtResponse.OK )
        {
            logger.warning( @"Desired SMS service mode is not available; SMS acknowledgement support will be disabled." );
            ack_supported = false;

            response = yield modem.processAtCommandAsync( csms, csms.issue( 0 ) );
            if ( csms.validateOk( response ) != Constants.AtResponse.OK )
            {
                logger.error( @"Could not set minimal SMS service mode; SMS support will be disabled" );
                supported = false;
                return false;
            }
        }

        return true;
    }

    /**
     * Configure SMS message format. See 27.005, section 3.2.3 for more details.
     *
     * We intend to use PDU format when possible and disable SMS message support
     * otherwise.
     *
     * If a single modem needs a different configuration (because some settings are
     * supported by the modem but not working correctly) it should subclass this class and
     * override this method to provide it's specific configuration.
     *
     * @return True, if configuration was successfull. False, otherwise.
     **/
    protected virtual async bool configureMessageFormat()
    {
        // We need to get into PDU mode otherwise we can't provide SMS support
        var cmgf = modem.createAtCommand<PlusCMGF>( "+CMGF" );
        var response = yield modem.processAtCommandAsync( cmgf, cmgf.issue( 0 ) );
        if ( cmgf.validateOk( response ) != Constants.AtResponse.OK )
        {
            logger.error( @"Could not enable SMS PDU mode; SMS support will be disabled" );
            supported = false;
            return false;
        }

        return true;
    }

    /**
     * Configure procedure how receiving new messages from the network is indicated by the
     * modem. As first step we check which modes are supported and trying to find the best
     * solution to feed our needs.
     *
     * If a single modem needs a different configuration (because some settings are
     * supported by the modem but not working correctly) it should subclass this class and
     * override this method to provide it's specific configuration.
     *
     * Inspired by ofono's configuration (see drivers/atmodem/sms.c)
     *
     * See TS 27.005, section 3.4.1 for more details.
     *
     * @return True, if configuration was successfull. False, otherwise.
     **/
    protected virtual async bool configureMessageIndications()
    {
        int mode = 2;
        int mt = 2;
        int bm = 2;
        int ds = 1;
        int bfr = 0;

        // Check which indications are supported for new SMS messages
        var cnmi = modem.createAtCommand<PlusCNMI>( "+CNMI" );
        var response = yield modem.processAtCommandAsync( cnmi, cnmi.test() );
        if ( cnmi.validateTest( response ) != Constants.AtResponse.VALID )
        {
            logger.error( @"Could not retrieve support indications for new SMS messages; trying to set our default ..." );
        }
        else
        {
            // buffer message reception indications when possible
            mode = choose_from_preference( new int[] { 2, 3, 1, 0 } , cnmi.supported_opts[0] );
            // prefer to deliver SMS via +CMT if we have support for acknowledgement
            mt = choose_from_preference( ack_supported ? new int[] { 2, 1 } : new int[] { 1 }, cnmi.supported_opts[1] );
            // always deliver CB via +CBM or don't deliver at all
            bm = choose_from_preference( new int[] { 2, 0 }, cnmi.supported_opts[2] );
            // deliver status reports via +CDS , +CSDI or don't deliver at all
            ds = choose_from_preference( new int[] { 1, 2, 0 }, cnmi.supported_opts[3] );
            // don't really care about buffering
            bfr = choose_from_preference( new int[] { 0, 1 }, cnmi.supported_opts[4] );

            if ( mode == -1 || mt == -1 || bm == -1 || ds == -1 || bfr == -1 )
                return false;
        }

        response = yield modem.processAtCommandAsync( cnmi, cnmi.issue( mode, mt, bm, ds, bfr ) );
        if ( cnmi.validateOk( response ) != Constants.AtResponse.OK )
            return false;

        return true;
    }

    protected override async string retrieveImsiFromSIM()
    {
        var cimi = modem.createAtCommand<PlusCIMI>( "+CIMI" );
        var response = yield modem.processAtCommandAsync( cimi, cimi.execute() );
        if ( cimi.validate( response ) != Constants.AtResponse.VALID )
        {
            logger.warning( "Can't retrieve IMSI from SIM to be used as identifier for SMS storage" );
            return "";
        }
        return cimi.value;
    }

    protected override async void fillStorageWithMessageFromSIM()
    {
        var cmgl = modem.createAtCommand<PlusCMGL>( "+CMGL" );
        var cmglresponse = yield modem.processAtCommandAsync( cmgl, cmgl.issue( PlusCMGL.Mode.ALL ) );
        if ( cmgl.validateMulti( cmglresponse ) != Constants.AtResponse.VALID )
        {
            logger.warning( "Can't synchronize SMS storage with SIM" );
            return;
        }

        foreach( var sms in cmgl.messagebook )
        {
            var ret = storage.addSms( sms.message );
            // send the incoming_text_message signal if ret == 1 (message is new).
            if ( ret == 1 )
            {
                var msg = storage.message( sms.message.hash() );
                var obj = modem.theDevice<FreeSmartphone.GSM.SMS>();
                obj.incoming_text_message( msg.number, msg.timestamp, msg.contents );
            }
        }
    }

    protected override async bool readSmsMessageFromSIM( uint index, out string hexpdu, out int tpdulen )
    {
        hexpdu = "";
        tpdulen = 0;

        var cmd = modem.createAtCommand<PlusCMGR>( "+CMGR" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( index ) );
        if ( cmd.validateUrcPdu( response ) != Constants.AtResponse.VALID )
        {
            logger.warning( @"Can't read new SMS from SIM storage at index $index." );
            return false;
        }

        hexpdu = cmd.hexpdu;
        tpdulen = cmd.tpdulen;

        return true;
    }

    protected override async bool acknowledgeSmsMessage()
    {
        if ( ! ack_supported )
        {
            assert( logger.debug( @"Skipping SMS acknowledgement because it's disabled" ) );
            return true;
        }

        var cmd = modem.createAtCommand<PlusCNMA>( "+CNMA" );
        var response = yield modem.processAtCommandAsync( cmd, cmd.issue( 0 ) );
        if ( cmd.validateOk( response ) != Constants.AtResponse.OK )
        {
            logger.warning( @"Failed to acknowledge SMS message; further SMS message handling will maybe faulty!" );
            return false;
        }

        return true;
    }

    //
    // public
    //

    public AtSmsHandler( FsoGsm.Modem modem )
    {
        base( modem );
    }

    public override async void configure()
    {
        base.configure();

        if ( !yield configureMessageService() )
        {
            logger.error( @"Could not configure SMS message service; SMS support will be disabled" );
            supported = false;
            return;
        }

        if ( !yield configureMessageFormat() )
        {
            logger.error( @"Could not configure SMS message format; SMS support will be disabled" );
            supported = false;
            return;
        }

        if ( !yield configureMessageIndications() )
        {
            logger.error( @"Could not configure SMS message indications; SMS support will be disabled" );
            supported = false;
            return;
        }

        assert( logger.info( @"Successfully configured for SMS message handling" ) );
    }

    public override string repr()
    {
        return storage != null ? storage.repr() : "<None>";
    }
}

// vim:ts=4:sw=4:expandtab
