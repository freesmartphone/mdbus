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

using GLib;
using FsoGsm;

/*


2010-05-01T16:03:47.060686Z [INFO]  libfsotransport <0710:3>: URC: [ "+CBM: 22", "001000DD001133DAED46ABD56AB5186CD668341A8D46" ]
2010-05-01T16:03:47.060710Z [DEBUG] TiCalypsoUnsolicitedResponseHandler : Dispatching AT unsolicited '+CBM', '22'
2010-05-01T16:03:47.060725Z [WARN]  TiCalypsoModem <4C>: No handler for URC +CBM w/ rhs 22, please report to Mickey <smartphones-userland@linuxtogo.org>
2010-05-01T16:03:47.060762Z [INFO]  libfsotransport <0710:2>: SRC: "+COPS=3,0;+COPS?" -> [ "+COPS: 0,0,"Alice"", "OK" ]
2010-05-01T16:03:47.060799Z [DEBUG] TiCalypsoModem <4C>: Did receive a valid response for FsoGsmPlusCOPS
2010-05-01T16:03:47.162590Z [INFO]  libfsotransport <0710:2>: SRC: "+COPS=3,1;+COPS?" -> [ "+COPS: 0", "OK" ]
2010-05-01T16:03:47.162632Z [DEBUG] TiCalypsoModem <4C>: Did receive a valid response for FsoGsmPlusCOPS
2010-05-01T16:03:47.260580Z [INFO]  libfsotransport <0710:2>: SRC: "+COPS=3,1;+COPS?" -> [ "+COPS: 0", "OK" ]
2010-05-01T16:03:47.260623Z [DEBUG] TiCalypsoModem <4C>: Did receive a valid response for FsoGsmPlusCOPS
2010-05-01T16:03:47.360585Z [INFO]  libfsotransport <0710:2>: SRC: "+COPS=3,2;+COPS?" -> [ "+COPS: 0,2,"26207"", "OK" ]
2010-05-01T16:03:47.360632Z [DEBUG] TiCalypsoModem <4C>: Did receive a valid response for FsoGsmPlusCOPS
2010-05-01T16:03:47.470611Z [INFO]  libfsotransport <0710:2>: SRC: "+COPS=3,2;+COPS?" -> [ "+COPS: 0,2,"26207"", "OK" ]
2010-05-01T16:03:47.470656Z [DEBUG] TiCalypsoModem <4C>: Did receive a valid response for FsoGsmPlusCOPS
2010-05-01T16:03:47.560585Z [INFO]  libfsotransport <0710:2>: SRC: "+CGREG?" -> [ "+CGREG: 0,1", "OK" ]
2010-05-01T16:03:47.560626Z [DEBUG] TiCalypsoModem <4C>: Did receive a valid response for FsoGsmPlusCGREG
2010-05-01T16:03:47.650606Z [INFO]  libfsotransport <0710:2>: SRC: "+CGREG?" -> [ "+CGREG: 0,1", "OK" ]
2010-05-01T16:03:47.650649Z [DEBUG] TiCalypsoModem <4C>: Did receive a valid response for FsoGsmPlusCGREG
2010-05-01T16:03:47.750619Z [INFO]  libfsotransport <0710:2>: SRC: "+CGREG=2;+CGREG?;+CGREG=0" -> [ "+CGREG: 2,1,"9D0B","1B81"", "OK" ]
2010-05-01T16:03:47.750665Z [DEBUG] TiCalypsoModem <4C>: Did receive a valid response for FsoGsmPlusCGREG
2010-05-01T16:03:47.750699Z [DEBUG] TiCalypsoModem <4C>: triggerUpdateNetworkStatus() status = home
2010-05-01T16:03:47.850618Z [INFO]  libfsotransport <0710:2>: SRC: "+CGREG=2;+CGREG?;+CGREG=0" -> [ "+CGREG: 2,1,"9D0B","1B81"", "OK" ]
2010-05-01T16:03:47.850662Z [DEBUG] TiCalypsoModem <4C>: Did receive a valid response for FsoGsmPlusCGREG
2010-05-01T16:03:47.850697Z [DEBUG] TiCalypsoModem <4C>: triggerUpdateNetworkStatus() status = home
2010-05-01T16:03:51.511536Z [INFO]  libfsotransport <0710:3>: URC: [ "+CBM: 88", "001000DD001133DAED46ABD56AB5186CD668341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D168341A8D46A3D100" ]
2010-05-01T16:03:51.511563Z [DEBUG] TiCalypsoUnsolicitedResponseHandler : Dispatching AT unsolicited '+CBM', '88'

*/




//===========================================================================
void test_cb_decode()
//===========================================================================
{
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/3rdparty/Cb/Decode", test_cb_decode );

    Test.run();
}
