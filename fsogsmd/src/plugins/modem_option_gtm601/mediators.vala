
using FsoGsm;
using Gee;

namespace Gtm601
{
    public class AtCallSendDtmf : CallSendDtmf
    {
        public override async void run( string tones ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
        {
            var cmd = theModem.createAtCommand<PlusVTS>( "+VTS" );
            theModem.sendAtCommand( cmd, cmd.issue( tones ) );
        }
    }

    /* register all mediators */
    public void registerCustomMediators( HashMap<Type,Type> mediators )
    {
        mediators[ typeof(CallSendDtmf) ] = typeof( AtCallSendDtmf );
    }

} // namespace Gtm601

// vim:ts=4:sw=4:expandtab
