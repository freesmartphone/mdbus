AC_INIT([fsousaged], [0.1.0.0], [smartphones-userland@linuxtogo.org], [fsousaged])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])

AC_PROG_CC
AM_PROG_CC_C_O
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

VALA_REQUIRED=0.7.3
GLIB_REQUIRED=2.18.0
DBUS_REQUIRED=1.2.1
DBUS_GLIB_REQUIRED=0.76
FSO_GLIB_REQUIRED=0.1.0
FSO_REQUIRED=0.0.0.0

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

AC_CONFIG_FILES([
  Makefile
  src/Makefile
  src/lib/Makefile
  src/bin/Makefile
  src/plugins/Makefile
  src/plugins/controller/Makefile
  tests/Makefile
])

AC_OUTPUT
