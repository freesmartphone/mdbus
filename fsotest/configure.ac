AC_INIT([fsotest], [0.1.0], [smartphones-userland@linuxtogo.org], [fsotest])
AC_PREREQ([2.65])
AC_CONFIG_SRCDIR([configure.ac])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])
AC_CANONICAL_BUILD
AC_CANONICAL_HOST
AC_ISC_POSIX

AM_INIT_AUTOMAKE([1.6 dist-bzip2])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PROG_CXX
AC_PROG_LIBTOOL

###############################################################################
# pkgconfig

PKG_PROG_PKG_CONFIG

###############################################################################
# vala
VALA_REQUIRED=0.14.0
AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)
m4_ifdef([AM_PROG_VALAC], [AM_PROG_VALAC([$VALA_REQUIRED])])

###############################################################################
# FSO Framework

FSOBASICS_REQUIRED=0.9.99
FSOFRAMEWORK_REQUIRED=0.8.2
FSOGLIB_REQUIRED=2011.06.01.1
FSORESOURCE_REQUIRED=0.0

PKG_CHECK_MODULES(FSOFRAMEWORK,
	fsobasics-2.0 >= $FSOBASICS_REQUIRED
	fsoframework-2.0 >= $FSOFRAMEWORK_REQUIRED
	fsoresource-2.0 >= $FSORESOURCE_REQUIRED
	fso-glib-1.0 >= $FSOGLIB_REQUIRED)
AC_SUBST(FSOFRAMEWORK_CFLAGS)
AC_SUBST(FSOFRAMEWORK_LIBS)

##############################################################################
# dbus conf directory
DBUS_DIR="`$PKG_CONFIG --variable=sysconfdir dbus-1`"
if (test -z "{DBUS_DIR}"); then
  DBUS_DIR="${sysconfdir}/dbus-1"
else
  DBUS_DIR="$DBUS_DIR/dbus-1"
fi
AC_SUBST(DBUS_DIR)

###############################################################################
# Other things

# git version
GITV=`cat ../.git/refs/heads/master || echo "unknown"`
AC_DEFINE_UNQUOTED([PACKAGE_GITV], ["${GITV}"], [git version])

# check for debugging
AC_ARG_ENABLE(debug,
  [  --enable-debug            Enable debug build (default=disabled)],
  debug="yes", debug="no")
AM_CONDITIONAL( [WANT_DEBUG], [test x"$debug" = x"yes"])

###############################################################################

AC_OUTPUT([
	Makefile
	data/Makefile
	src/Makefile
])

###############################################################################

echo
echo
echo
echo "------------------------------------------------------------------------"
echo "$PACKAGE $VERSION"
echo "------------------------------------------------------------------------"
echo
echo "Compilation............: make (or gmake)"
echo "  CPPFLAGS.............: $CPPFLAGS"
echo "  CFLAGS...............: $CFLAGS"
echo "  LDFLAGS..............: $LDFLAGS"
echo
echo "Installation...........: make install (as root if needed, with 'su' or 'sudo')"
echo "  prefix...............: $prefix"
echo
echo
