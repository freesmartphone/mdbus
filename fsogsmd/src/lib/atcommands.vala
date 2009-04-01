namespace FsoGsm
{

public class PlusCGMM : AtCommand
{
    // declare instance vars
    public string model;

    // construction
    public PlusCGMM()
    {
        re = new Regex( """(\+CGMM:\ )?"?(?P<model>[^"]*)"?""" );
    }

    // parse
    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        // populate instance vars
        model = to_string( "model" );
    }
}

public class PlusCGMI : AtCommand
{
    // declare instance vars
    public string manufacturer;

    // construction
    public PlusCGMI()
    {
        re = new Regex( """(\+CGMI:\ )?"?(?P<manufacturer>[^"]*)"?""" );
    }

    // parse
    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        // populate instance vars
        manufacturer = to_string( "manufacturer" );
    }
}

public class PlusCOPS_Test : AtCommand
{
    public struct Info
    {
        public int status;
        public string shortname;
        public string longname;
        public string mccmnc;
    }
    public List<Info?> info;

    public PlusCOPS_Test()
    {
        re = new Regex( """\((?<status>\d),"(?P<longname>[^"]*)","(?P<shortname>[^"]*)","(?P<mccmnc>[^"]*)"\)""" );
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        info = new List<Info?>();
        do
        {
            var i = Info() { status = to_int( "status" ),
                             longname = to_string( "longname" ),
                             shortname = to_string( "shortname" ),
                             mccmnc = to_string( "mccmnc" ) };
            info.append( i );
        }
        while ( mi.next() );
    }
}

public class PlusCPIN : AtCommand
{
    // declare instance vars
    public string pin;

    // construction
    public PlusCPIN()
    {
        re = new Regex( """\+CPIN:\ "?(?P<pin>[^"]*)"?""" );
    }

    // parse
    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        // populate instance vars
        pin = to_string( "pin" );
    }
}

public class PlusFCLASS : AtCommand
{
    // declare instance vars
    public string faxclass;

    // construction
    public PlusFCLASS()
    {
        re = new Regex( """"?(?P<faxclass>[^"]*)"?""" );
    }

    // parse
    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        // populate instance vars
        faxclass = to_string( "faxclass" );
    }
}

public class PlusCGCLASS : AtCommand
{
    // declare instance vars
    public string gprsclass;

    // construction
    public PlusCGCLASS()
    {
        re = new Regex( """\+CGCLASS:\ "?(?P<gprsclass>[^"]*)"?""" );
    }

    // parse
    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        // populate instance vars
        gprsclass = to_string( "gprsclass" );
    }
}

public class PlusCFUN : AtCommand
{
    // declare instance vars
    public int fun;

    // construction
    public PlusCFUN()
    {
        re = new Regex( """\+CFUN:\ (?P<fun>\d)""" );
    }

    // parse
    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        // populate instance vars
        fun = to_int( "fun" );
    }
}

public class PlusCOPS : AtCommand
{
    public int status;
    public int mode;
    public string oper;

    public PlusCOPS()
    {
        re = new Regex( """\+COPS:\ (?P<status>\d)(,(?P<mode>\d)?(,"(?P<oper>[^"]*)")?)?""" );
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        status = to_int( "status" );
        mode = to_int( "mode" );
        oper = to_string( "oper" );
    }
}

public class PlusCGSN : AtCommand
{
    // declare instance vars
    public string imei;

    // construction
    public PlusCGSN()
    {
        re = new Regex( """(\+CGSN:\ )?"?(?P<imei>[^"]*)"?""" );
    }

    // parse
    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        // populate instance vars
        imei = to_string( "imei" );
    }
}

public class PlusCGMR : AtCommand
{
    // declare instance vars
    public string revision;

    // construction
    public PlusCGMR()
    {
        re = new Regex( """(\+CGMR:\ )?"?(?P<revision>[^"]*)"?""" );
    }

    // parse
    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        // populate instance vars
        revision = to_string( "revision" );
    }
}

public void registerGeneratedAtCommands( GLib.HashTable<string, AtCommand> table )
{
    // register commands
    table.insert( "PlusCGMM",           new FsoGsm.PlusCGMM() );
    table.insert( "PlusCGMI",           new FsoGsm.PlusCGMI() );
    table.insert( "PlusCOPS_Test",      new FsoGsm.PlusCOPS_Test() );
    table.insert( "PlusCPIN",           new FsoGsm.PlusCPIN() );
    table.insert( "PlusFCLASS",         new FsoGsm.PlusFCLASS() );
    table.insert( "PlusCGCLASS",        new FsoGsm.PlusCGCLASS() );
    table.insert( "PlusCFUN",           new FsoGsm.PlusCFUN() );
    table.insert( "PlusCOPS",           new FsoGsm.PlusCOPS() );
    table.insert( "PlusCGSN",           new FsoGsm.PlusCGSN() );
    table.insert( "PlusCGMR",           new FsoGsm.PlusCGMR() );

}

} /* namespace FsoGsm */
