m4_define([fsogsmd_released], [0])
m4_define([fsogsmd_base_version], [0.11.0])
m4_define([fsogsmd_maybe_gitrev], m4_if(fsogsmd_released, [1], [], [m4_esyscmd([git show-ref --hash=5 HEAD | tr -d '\n\r'])]))
m4_define([fsogsmd_version], m4_if(fsogsmd_released, [1], [fsogsmd_base_version], [fsogsmd_base_version-fsogsmd_maybe_gitrev]))

AC_INIT([fsogsmd], fsogsmd_version, [smartphones-userland@linuxtogo.org], [fsogsmd])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PREREQ([2.65])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2 no-dist-gzip tar-ustar])
AM_MAINTAINER_MODE([enable])

AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_CC_C99
AC_GNU_SOURCE
AC_DISABLE_STATIC
AC_PROG_LIBTOOL
PKG_PROG_PKG_CONFIG([0.21])

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

#########################################################################################
# Vala building options -- allows tarball builds without installing vala
#########################################################################################

VALA_REQUIRED=0.14.2

AC_ARG_ENABLE([vala], AS_HELP_STRING([--enable-vala],[Enable building from Vala sources]),
              [enable_vala=$enableval], [enable_vala=no])

# Force Vala for non-release builds
m4_if(fsogsmd_released, [1], [],
      [
        enable_vala=yes
        echo "Vala compiler required for non-release builds; requiring Vala..."
      ])

if test "x$enable_vala" = "xyes" ; then
    AM_PROG_VALAC([$VALA_REQUIRED])
    if test "x$VALAC" = "x" ; then
        AC_MSG_ERROR([Vala requested but valac is not installed])
    fi
fi

AM_CONDITIONAL([HAVE_VALA], [test "x$enable_vala" = "xyes"])

#########################################################################################
# Check for various dependencies
#########################################################################################

VALA_REQUIRED=0.14.2
GLIB_REQUIRED=2.26.0
GEE_REQUIRED=0.5.0
XML_REQUIRED=2.7.3
GSMMUX_REQUIRED=0.3.4
GISICOMM_REQUIRED=0.1.0
MSMCOMM_SPECS_REQUIRED=0.10.0
FSO_GLIB_REQUIRED=2012.05.24.1
FSO_REQUIRED=0.11.0
SAMSUNG_IPC_REQUIRED=0.1

PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

PKG_CHECK_MODULES(GEE,
  gee-1.0 >= $GEE_REQUIRED)
AC_SUBST(GEE_CFLAGS)
AC_SUBST(GEE_LIBS)

PKG_CHECK_MODULES(FSO,
  fso-glib-1.0 >= $FSO_GLIB_REQUIRED
  fsosystem-2.0 >= $FSO_REQUIRED
  fsoframework-2.0 >= $FSO_REQUIRED
  fsotransport-2.0 >= $FSO_REQUIRED
  fsoresource-2.0 >= $FSO_REQUIRED)
AC_SUBST(FSO_CFLAGS)
AC_SUBST(FSO_LIBS)

#########################################################################################
# dbus conf directory
#########################################################################################

AC_ARG_WITH(dbusconfdir, AC_HELP_STRING([--with-dbusconfdir=PATH], [path to D-Bus config directory]),
			[path_dbusconf=${withval}], [path_dbusconf="`$PKG_CONFIG --variable=sysconfdir dbus-1`"])

if (test -z "${path_dbusconf}"); then
  DBUS_DIR="${sysconfdir}/dbus-1"
else
  DBUS_DIR="${path_dbusconf}/dbus-1"
fi
AC_SUBST(DBUS_DIR)

#########################################################################################
# dbus service directory
#########################################################################################

AC_ARG_WITH(dbusservicedir, AC_HELP_STRING([--with-dbusdatadir=PATH], [path to D-Bus data directory]),
			[path_dbusdata=${withval}], [path_dbusdata="`$PKG_CONFIG --variable=datadir dbus-1`"])

if (test -z "${path_dbusdata}"); then
	DBUS_SERVICE_DIR="${datadir}/dbus-1/system-services"
else
	DBUS_SERVICE_DIR="${path_dbusdata}/dbus-1/system-services"
fi
AC_SUBST(DBUS_SERVICE_DIR)

#########################################################################################
# optional feature: ppp
#########################################################################################

AC_ARG_ENABLE(ppp-support,
  [  --disable-ppp-support   Disable building ppp support (default=enabled)],
  [ppp=$enableval],
  [ppp="yes"])

if test "x$ppp" = "xyes"; then
    # pppd
    AC_CHECK_HEADERS([pppd/pppd.h],,
      [AC_MSG_ERROR([Could not find pppd.h. pppd development headers are required to build the ppp plugin.])])
fi
AM_CONDITIONAL( [WANT_PPP], [test x"$ppp" = x"yes"])

#########################################################################################
# optional feature: libgsm0710mux support
#########################################################################################

AC_ARG_ENABLE(libgsm0710mux,
  [  --enable-libgsm0710mux  Build modem plugins which require libgsm0710mux (default=disabled)],
  [mux=$enableval],
  [mux="no"])

if test x$mux = "xyes"; then
    PKG_CHECK_MODULES(GSMMUX,gsm0710mux-1.0 >= $GSMMUX_REQUIRED)
AC_SUBST(GSMMUX_CFLAGS)
AC_SUBST(GSMMUX_LIBS)

fi
AM_CONDITIONAL( [WANT_MUX], [test x"$mux" = x"yes"])

#########################################################################################
# optional feature: Qualcomm modem support as found in Palm WebOS devices
#########################################################################################

AC_ARG_ENABLE(modem-qualcomm-palm,
  [  --enable-modem-qualcomm-palm  Enable building the modem_qualcomm_palm plugin (default=disabled)],
  [palm=$enableval],
  [palm="no"])

if test x$palm = "xyes"; then
    PKG_CHECK_MODULES(PALM,
      msmcomm-specs-2.0 >= $MSMCOMM_SPECS_REQUIRED)
AC_SUBST(PALM_CFLAGS)
AC_SUBST(PALM_LIBS)

fi
AM_CONDITIONAL( [WANT_PALM], [test x"$palm" = x"yes"])

#########################################################################################
# optional feature: Nokia ISI modem support as found in Nokia N900
#########################################################################################

AC_ARG_ENABLE(modem-nokia-isi,
  [  --enable-modem-nokia-isi  Enable building the nokia_isi plugin (default=disabled)],
  [isi=$enableval],
  [isi="no"])

if test x$isi = "xyes"; then
    PKG_CHECK_MODULES(ISI,
      gisicomm-1.0 >= $GISICOMM_REQUIRED)
AC_SUBST(ISI_CFLAGS)
AC_SUBST(ISI_LIBS)

fi
AM_CONDITIONAL( [WANT_ISI], [test x"$isi" = x"yes"])

#########################################################################################
# optional feature: Samsung modem support as found in Samsung Nexus S / H1
#########################################################################################

AC_ARG_ENABLE(modem-samsung,
  [  --enable-modem-samsung  Enable building the samsung plugin (default=disabled)],
  [samsung=$enableval],
  [samsung="no"])

AM_CONDITIONAL( [WANT_SAMSUNG], [test x"$samsung" = x"yes"])

if test x$samsung = "xyes"; then
    PKG_CHECK_MODULES(SAMSUNG,
      samsung-ipc-1.0 >= $SAMSUNG_IPC_REQUIRED)
AC_SUBST(SAMSUNG_CFLAGS)
AC_SUBST(SAMSUNG_LIBS)

fi

#########################################################################################
# datadir
#########################################################################################

if test "x$prefix" != "xNONE"; then
  pkgdatadir='${prefix}/share/fsogsmd'
else
  pkgdatadir='/usr/local/share/fsogsmd'
fi
eval PACKAGE_DATADIR="${pkgdatadir}"
AC_DEFINE_UNQUOTED([PACKAGE_DATADIR], ["${PACKAGE_DATADIR}"], [Shared data directory])

#########################################################################################
# gather libdir
#########################################################################################

if test "x$prefix" != "xNONE"; then
  pkglibdir='${prefix}/lib/cornucopia/modules/fsogsm'
else
  pkglibdir='/usr/local/lib/cornucopia/modules/fsogsm'
fi
eval PACKAGE_LIBDIR="${pkglibdir}"
AC_DEFINE_UNQUOTED([PACKAGE_LIBDIR], ["${PACKAGE_LIBDIR}"], [Module directory])

#########################################################################################
# check for debugging
#########################################################################################

AC_ARG_ENABLE(debug,
  [  --enable-debug            Enable debug build (default=disabled)],
  [enable_debug=$enableval],
  [enable_debug="no"])
AM_CONDITIONAL( [WANT_DEBUG], [test x"$enable_debug" = x"yes"])

#########################################################################################
# data files
#########################################################################################

AC_ARG_ENABLE(datafiles, AC_HELP_STRING([--disable-datafiles],
			[don't install configuration and data files]),
					[enable_datafiles=${enableval}])
AM_CONDITIONAL(WANT_DATAFILES, test "${enable_datafiles}" != "no")

#########################################################################################
# output
#########################################################################################

AC_CONFIG_FILES([
  Makefile
  conf/Makefile
  conf/default/Makefile
  conf/htc_qualcomm_dream/Makefile
  conf/htc_qualcomm_msm/Makefile
  conf/htcleo/Makefile
  conf/motorola_ezx/Makefile
  conf/openmoko_gta/Makefile
  conf/palm_pre/Makefile
  conf/nexusone/Makefile
  conf/nokia_n900/Makefile
  conf/herring/Makefile
  conf/GTA04/Makefile
  conf/phonesim/Makefile
  data/Makefile
  data/org.freesmartphone.ogsmd.service
  src/Makefile
  src/3rdparty/Makefile
  src/3rdparty/ppp/Makefile
  src/lib/Makefile
  src/bin/Makefile
  src/plugins/Makefile
  src/plugins/dbus_service/Makefile
  src/plugins/lowlevel_motorola_ezx/Makefile
  src/plugins/lowlevel_openmoko/Makefile
  src/plugins/lowlevel_gta04/Makefile
  src/plugins/lowlevel_palmpre/Makefile
  src/plugins/lowlevel_samsung_crespo/Makefile
  src/plugins/modem_cinterion_mc75/Makefile
  src/plugins/modem_dummy/Makefile
  src/plugins/modem_freescale_neptune/Makefile
  src/plugins/modem_nokia_isi/Makefile
  src/plugins/modem_singleline/Makefile
  src/plugins/modem_ti_calypso/Makefile
  src/plugins/modem_qualcomm_htc/Makefile
  src/plugins/modem_qualcomm_palm/Makefile
  src/plugins/modem_samsung/Makefile
  src/plugins/modem_option_gtm601/Makefile
  src/plugins/modem_phonesim/Makefile
  src/plugins/pdp_ppp/Makefile
  src/plugins/pdp_ppp_internal/Makefile
  src/plugins/pdp_ppp_mux/Makefile
  src/plugins/pdp_qmi/Makefile
  src/plugins/pdp_nokia_isi/Makefile
  src/ppp/Makefile
  tests/Makefile
  vapi/Makefile
])
AC_OUTPUT

#########################################################################################
# info
#########################################################################################

echo
echo "------------------------------------------------------------------------"
echo "$PACKAGE_NAME $PACKAGE_VERSION"
echo "------------------------------------------------------------------------"
echo
echo "Configuration Options:"
echo
echo "  ppp support.............: $ppp"
echo "  pdp_mux.................: $mux"
echo "  modem_ti_calypso........: $mux"
echo "  modem_cinterion_mc75....: $mux"
echo "  modem_qualcomm_palm.....: $palm"
echo "  modem_nokia_isi.........: $isi"
echo "  modem_samsung...........: $samsung"
echo
echo "  shared data directory...: $pkgdatadir"
echo
echo "  plugin directory........: $pkglibdir"
echo
echo "  Vala....................: $enable_vala"
echo
echo "  Vala Compiler...........: ${VALAC}"
echo
echo "  debug build.............: $enable_debug"
echo
echo "  prefix..................: $prefix"
echo
echo "------------------------------------------------------------------------"
echo
echo "Now type 'make' to compile and 'make install' to install this package."
