
using FsoGsm;
using Gee;

namespace Gtm601
{
public class PlusCOPS : FsoGsm.PlusCOPS
{
    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        oper = decodeString( oper );
    }
}

/* register all custom at commands */
public void registerCustomAtCommands( HashMap<string,AtCommand> table )
{
    table[ "+COPS" ] = new PlusCOPS();
}

} // namespace Gtm601

// vim:ts=4:sw=4:expandtab
