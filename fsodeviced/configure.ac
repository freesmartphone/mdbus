AC_INIT([fsodeviced], [0.1.0.0], [smartphones-userland@linuxtogo.org], [fsodeviced])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])

AC_PROG_CC
AM_PROG_CC_C_O
AC_GNU_SOURCE
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

VALA_REQUIRED=0.7.2
GLIB_REQUIRED=2.18.0
GEE_REQUIRED=0.1.6
DBUS_REQUIRED=1.2.1
DBUS_GLIB_REQUIRED=0.76
FSO_GLIB_REQUIRED=0.1.0
FSO_REQUIRED=0.0.0.0
CANBERRA_REQUIRED=0.12

# vala
PKG_CHECK_MODULES(VALA,
  vala-1.0 >= $VALA_REQUIRED)

# glib and friends
PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

# gee
PKG_CHECK_MODULES(GEE,
  gee-1.0 >= $GEE_REQUIRED)

# dbus and dbus-glib
PKG_CHECK_MODULES(DBUS,
  dbus-1 >= $DBUS_REQUIRED
  dbus-glib-1 >= $DBUS_GLIB_REQUIRED)
AC_SUBST(DBUS_CFLAGS)
AC_SUBST(DBUS_LIBS)

# fso-glib and framework
PKG_CHECK_MODULES(FSO,
  fso-glib-1.0 >= $FSO_GLIB_REQUIRED
  fsoframework-2.0 >= $FSO_REQUIRED)
AC_SUBST(FSO_CFLAGS)
AC_SUBST(FSO_LIBS)

# libcanberra
PKG_CHECK_MODULES(CANBERRA,
  libcanberra >= $CANBERRA_REQUIRED)
AC_SUBST(CANBERRA_CFLAGS)
AC_SUBST(CANBERRA_LIBS)

AC_CONFIG_FILES([
  Makefile
  data/Makefile
  src/Makefile
  src/lib/Makefile
  src/bin/Makefile
  src/plugins/Makefile
  src/plugins/accelerometer/Makefile
  src/plugins/accelerometer_lis302/Makefile
  src/plugins/alsa_audio/Makefile
  src/plugins/kernel26_display/Makefile
  src/plugins/kernel26_leds/Makefile
  src/plugins/kernel26_powersupply/Makefile
  src/plugins/kernel26_rtc/Makefile
  src/plugins/kernel_idle/Makefile
  src/plugins/kernel_info/Makefile
  src/plugins/kernel_input/Makefile
  src/plugins/thinkpad_powercontrol/Makefile
  src/plugins/openmoko_powercontrol/Makefile
  tests/Makefile
])

AC_OUTPUT
