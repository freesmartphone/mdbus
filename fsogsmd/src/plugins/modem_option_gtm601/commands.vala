
using FsoGsm;
using Gee;

namespace Gtm601
{
internal const uint NETWORK_COMM_TIMEOUT = 120;

public class PlusCOPS : AbstractAtCommand
{
    public int format;
    public int mode;
    public string oper;
    public string act;
    public int status;

    public FreeSmartphone.GSM.NetworkProvider[] providers;

    public enum Action
    {
        REGISTER_WITH_BEST_PROVIDER     = 0,
        REGISTER_WITH_SPECIFIC_PROVIDER = 1,
        UNREGISTER                      = 2,
        SET_FORMAT                      = 3,
    }

    public enum Format
    {
        ALPHANUMERIC                    = 0,
        ALPHANUMERIC_SHORT              = 1,
        NUMERIC                         = 2,
    }

    public PlusCOPS()
    {
        try
        {
            re = new Regex( """\+COPS:\ (?P<mode>\d)(,(?P<format>\d)?(,"(?P<oper>[^"]*)")?)?(?:,(?P<act>\d))?""" );
            tere = new Regex( """\((?P<status>\d),(?:"(?P<longname>[^"]*)")?,(?:"(?P<shortname>[^"]*)")?,"(?P<mccmnc>[^"]*)"(?:,(?P<act>\d))?\)""" );
        }
        catch ( GLib.RegexError e )
        {
            assert_not_reached(); // fail here if Regex is broken
        }
        prefix = { "+COPS: " };
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        mode = to_int( "mode" );
        format = to_int( "format" );
        oper = decodeString( to_string( "oper" ) );
        act = Constants.instance().networkProviderActToString( to_int( "act" ) );
    }

    public override void parseTest( string response ) throws AtCommandError
    {
        base.parseTest( response );
        var providers = new FreeSmartphone.GSM.NetworkProvider[] {};
        try
        {
            do
            {
                var p = FreeSmartphone.GSM.NetworkProvider(
                    Constants.instance().networkProviderStatusToString( to_int( "status" ) ),
                    decodeString( to_string( "longname" ) ),
                    decodeString( to_string( "shortname" ) ),
                    to_string( "mccmnc" ),
                    Constants.instance().networkProviderActToString( to_int( "act" ) ) );
                providers += p;
            }
            while ( mi.next() );
        }
        catch ( GLib.RegexError e )
        {
            FsoFramework.theLogger.error( @"Regex error: $(e.message)" );
            throw new AtCommandError.UNABLE_TO_PARSE( e.message );
        }
        this.providers = providers;
    }

    public string issue( Action action, Format format = Format.ALPHANUMERIC, int param = 0 )
    {
        if ( action == Action.REGISTER_WITH_BEST_PROVIDER )
        {
            return "+COPS=0,0";
        }
        else
        {
            return "+COPS=%d,%d,\"%d\"".printf( (int)action, (int)format, (int)param );
        }
    }

    public string query( Format format = Format.ALPHANUMERIC )
    {
        return "+COPS=%d,%d;+COPS?".printf( (int)Action.SET_FORMAT, (int)format );
    }

    public string test()
    {
        return "+COPS=?";
    }

    public override uint get_timeout() { return NETWORK_COMM_TIMEOUT; }
}

/* register all custom at commands */
public void registerCustomAtCommands( HashMap<string,AtCommand> table )
{
    table[ "+COPS" ] = new PlusCOPS();
}

} // namespace Gtm601

// vim:ts=4:sw=4:expandtab
