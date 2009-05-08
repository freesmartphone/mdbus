AC_INIT([libfsoframework], [0.1.0.0], [smartphones-userland@linuxtogo.org], [libfsoframework])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])

AC_PROG_CC
AM_PROG_CC_C_O
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

#
# pkg-config requirements
#
PKG_PROG_PKG_CONFIG

VALA_REQUIRED=0.7.3
DBUS_REQUIRED=1.2.1
DBUS_GLIB_REQUIRED=0.76
GLIB_REQUIRED=2.18.0

# vala
AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)
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

#
# default features
#
want_keyfile=yes
want_logging=yes
want_subsystem=yes
want_transport=yes
want_transportlibgsm0710mux=yes

#
# enable/disable features
#
AC_ARG_ENABLE([keyfile],
   [AC_HELP_STRING([--disable-keyfile], [build keyfile suppport (default=yes)])],
   [want_keyfile=$enableval]
)
AC_MSG_CHECKING([whether to build keyfile support])
AC_MSG_RESULT([${want_keyfile}])

AC_ARG_ENABLE([logging],
   [AC_HELP_STRING([--disable-logging], [build logging suppport (default=yes)])],
   [want_logging=$enableval]
)
AC_MSG_CHECKING([whether to build logging support])
AC_MSG_RESULT([${want_logging}])

AC_ARG_ENABLE([subsystem],
   [AC_HELP_STRING([--disable-subsystem], [build plugin and subsystem suppport (default=yes)])],
   [want_subsystem=$enableval]
)
AC_MSG_CHECKING([whether to build plugin and subsystem support])
AC_MSG_RESULT([${want_subsystem}])

AC_ARG_ENABLE([transport],
   [AC_HELP_STRING([--disable-transport], [build transport suppport (default=yes)])],
   [want_transport=$enableval]
)
AC_MSG_CHECKING([whether to build transport support])
AC_MSG_RESULT([${want_transport}])

AC_ARG_ENABLE([transport_libgsm0710mux],
   [AC_HELP_STRING([--disable-transport-libgsm0710mux], [libgsm0710mux transport suppport (default=yes)])],
   [want_transportlibgsm0710mux=$enableval]
)
AC_MSG_CHECKING([whether to build transport-libgsm0710mux support])
AC_MSG_RESULT([${want_transportlibgsm0710mux}])

#
# compute conditionals
#
if test "x${want_keyfile}" = "xyes" ; then
   have_keyfile="yes"
   AC_DEFINE(HAVE_KEYFILE, 1, [Have keyfile support built in])
fi

if test "x${want_logging}" = "xyes" ; then
   have_logging="yes"
   AC_DEFINE(HAVE_LOGGING, 1, [Have logging support built in])
fi

if test "x${want_transport}" = "xyes" ; then
   have_transport="yes"
   AC_DEFINE(HAVE_TRANSPORT, 1, [Have transport support built in])

   if test "x${want_transportlibgsm0710mux}" = "xyes" ; then
   have_transportlibgsm0710mux="yes"
   AC_DEFINE(HAVE_TRANSPORT_LIBGSM0710MUX, 1, [Have transport libgsm0710mux support built in])
   fi
fi

#
# output
#
AC_CONFIG_FILES([Makefile
  fsoframework-2.0.pc
  fsoframework/Makefile
  tests/Makefile
  vapi/Makefile])

AC_OUTPUT

#
# Info
#
echo
echo
echo
echo "------------------------------------------------------------------------"
echo "$PACKAGE_NAME $PACKAGE_VERSION"
echo "------------------------------------------------------------------------"
echo
echo "Configuration Options Summary:"
echo
echo "  Smart Keyfile Support.....: ${want_keyfile}"
echo
echo "  Logging Support...........: ${want_logging}"
echo
echo "  Plugin & Subsystem........: ${want_subsystem}"
echo
echo "  Transport Support.........: ${want_transport}"
echo "    - libgsm0710mux.........: ${want_transportlibgsm0710mux}"
echo
echo "  Compilation...............: make"
echo
echo "  Installation..............: make install"
echo
echo "    prefix..................: $prefix"
echo
