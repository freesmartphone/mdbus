AC_INIT([fsogsmd], [0.5.0], [smartphones-userland@linuxtogo.org], [fsogsmd])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
#AC_CONFIG_MACRO_DIR([m4]
AM_INIT_AUTOMAKE([dist-bzip2])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_CC_C99
AC_GNU_SOURCE
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

##############################################################################
# pkg-config requirements
PKG_PROG_PKG_CONFIG

VALA_REQUIRED=0.12.1
GLIB_REQUIRED=2.26.0
GEE_REQUIRED=0.5.0
XML_REQUIRED=2.7.3
GSMMUX_REQUIRED=0.3.4
GISICOMM_REQUIRED=0.0.0
MSMCOMM_SPECS_REQUIRED=0.6.0
FSO_GLIB_REQUIRED=2010.07.28.1
FSO_FRAMEWORK_REQUIRED=0.2.3
FSO_TRANSPORT_REQUIRED=0.9.5.9
FSO_RESOURCE_REQUIRED=0.1.0
CONNMAN_REQUIRED=0.68
SAMSUNG_IPC_REQUIRED=0.1

##############################################################################
# vala
AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)
m4_ifdef([AM_PROG_VALAC], [AM_PROG_VALAC([$VALA_REQUIRED])])

##############################################################################
# glib and friends
PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

##############################################################################
# gee
PKG_CHECK_MODULES(GEE,
  gee-1.0 >= $GEE_REQUIRED)
AC_SUBST(GEE_CFLAGS)
AC_SUBST(GEE_LIBS)

##############################################################################
# dbus conf directory
DBUS_DIR="`$PKG_CONFIG --variable=sysconfdir dbus-1`"
if (test -z "{DBUS_DIR}"); then
  DBUS_DIR="${sysconfdir}/dbus-1"
else
  DBUS_DIR="$DBUS_DIR/dbus-1"
fi
AC_SUBST(DBUS_DIR)

##############################################################################
# dbus service directory
DBUS_SERVICE_DIR="`$PKG_CONFIG --variable=session_bus_services_dir dbus-1`"
if (test -z "{DBUS_SERVICE_DIR}"); then
  DBUS_SERVICE_DIR="${datadir}/dbus-1/services"
fi
AC_SUBST(DBUS_SERVICE_DIR)

##############################################################################
# fso-glib and framework
PKG_CHECK_MODULES(FSO,
  fso-glib-1.0 >= $FSO_GLIB_REQUIRED
  fsoframework-2.0 >= $FSO_FRAMEWORK_REQUIRED
  fsotransport-2.0 >= $FSO_TRANSPORT_REQUIRED
  fsoresource-2.0 >= $FSO_RESOURCE_REQUIRED)
AC_SUBST(FSO_CFLAGS)
AC_SUBST(FSO_LIBS)

##############################################################################
# optional feature: ppp
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

##############################################################################
# optional feature: connman
AC_ARG_ENABLE(connman-support,
  [  --disable-connman-support   Disable building connman support (default=enabled)],
  [connman=$enableval],
  [connman="yes"])

if test "x$connman" = "xyes"; then
    PKG_CHECK_MODULES(CONNMAN, connman >= $CONNMAN_REQUIRED)
    AC_SUBST(CONNMAN_CFLAGS)
    AC_SUBST(CONNMAN_LIBS)
fi
AM_CONDITIONAL( [WANT_CONNMAN], [test x"$connman" = x"yes"])


##############################################################################
# optional feature: libgsm0710mux support
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

##############################################################################
# optional feature: Qualcomm modem support as found in Palm WebOS devices
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

##############################################################################
# optional feature: Nokia ISI modem support as found in Nokia N900
AC_ARG_ENABLE(modem-nokia-isi,
  [  --enable-modem-nokia-isi  Enable building the nokia_isi plugin (default=disabled)],
  [isi=$enableval],
  [isi="no"])

if test x$isi = "xyes"; then
    PKG_CHECK_MODULES(ISI,
      gisicomm-0.0 >= $GISICOMM_REQUIRED)
AC_SUBST(ISI_CFLAGS)
AC_SUBST(ISI_LIBS)

fi
AM_CONDITIONAL( [WANT_ISI], [test x"$isi" = x"yes"])

##############################################################################
# optional feature: Samsung modem support as found in Samsung Nexus S / H1
AC_ARG_ENABLE(modem-samsung,
  [  --enable-modem-samsung  Enable building the samsung plugin (default=disabled)],
  [samsung=$enableval],
  [samsung="no"])

AM_CONDITIONAL( [WANT_SAMSUNG], [test x"$samsung" = x"yes"])

##############################################################################
# datadir
if test "x$prefix" != "xNONE"; then
  pkgdatadir='${prefix}/share/fsogsmd'
else
  pkgdatadir='/usr/local/share/fsogsmd'
fi
eval PACKAGE_DATADIR="${pkgdatadir}"
AC_DEFINE_UNQUOTED([PACKAGE_DATADIR], ["${PACKAGE_DATADIR}"], [Shared data directory])

##############################################################################
# gather libdir
if test "x$prefix" != "xNONE"; then
  pkglibdir='${prefix}/lib/cornucopia/modules/fsogsm'
else
  pkglibdir='/usr/local/lib/cornucopia/modules/fsogsm'
fi
eval PACKAGE_LIBDIR="${pkglibdir}"
AC_DEFINE_UNQUOTED([PACKAGE_LIBDIR], ["${PACKAGE_LIBDIR}"], [Module directory])

##############################################################################
# check for debugging
AC_ARG_ENABLE(debug,
  [  --enable-debug            Enable debug build (default=disabled)],
  [debug=$enableval],
  [debug="no"])
AM_CONDITIONAL( [WANT_DEBUG], [test x"$debug" = x"yes"])

##############################################################################
# git version
GITV=`cat ../.git/refs/heads/master || echo "unknown"`
AC_DEFINE_UNQUOTED([PACKAGE_GITV], ["${GITV}"], [git version])

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
  data/Makefile
  data/org.freesmartphone.ogsmd.service
  src/Makefile
  src/lib/Makefile
  src/bin/Makefile
  src/plugins/Makefile
  src/plugins/dbus_service/Makefile
  src/plugins/lowlevel_motorola_ezx/Makefile
  src/plugins/lowlevel_openmoko/Makefile
  src/plugins/lowlevel_palmpre/Makefile
  src/plugins/modem_cinterion_mc75/Makefile
  src/plugins/modem_dummy/Makefile
  src/plugins/modem_freescale_neptune/Makefile
  src/plugins/modem_nokia_isi/Makefile
  src/plugins/modem_singleline/Makefile
  src/plugins/modem_ti_calypso/Makefile
  src/plugins/modem_qualcomm_htc/Makefile
  src/plugins/modem_qualcomm_palm/Makefile
  src/plugins/modem_samsung/Makefile
  src/plugins/pdp_ppp/Makefile
  src/plugins/pdp_ppp_internal/Makefile
  src/plugins/pdp_ppp_mux/Makefile
  src/plugins/pdp_qmi/Makefile
  src/plugins/pdp_nokia_isi/Makefile
  src/ppp/Makefile
  src/connman/Makefile
  tests/Makefile
])

AC_OUTPUT

##############################################################################
# info
echo
echo
echo
echo "------------------------------------------------------------------------"
echo "$PACKAGE_NAME $PACKAGE_VERSION-$GITV"
echo "------------------------------------------------------------------------"
echo
echo "Configuration Options:"
echo
echo "  ppp support.............: $ppp"
echo "  pdp_mux.................: $mux"
echo "  connman_support.........: $connman"
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
echo "  debug build.............: $debug"
echo
echo "  prefix..................: $prefix"
echo
echo "------------------------------------------------------------------------"
echo
echo "Now type 'make' to compile and 'make install' to install this package."
