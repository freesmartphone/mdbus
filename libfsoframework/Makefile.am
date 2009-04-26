include $(top_srcdir)/Makefile.decl

NULL =

SUBDIRS = \
  fsoframework \
  tests \
  vapi \
  $(NULL)

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = fsoframework-2.0.pc

EXTRA_DIST += \
  MAINTAINERS \
  fsoframework-2.0.pc.in \
  $(NULL)

MAINTAINERCLEANFILES = \
  aclocal.m4 compile config.guess config.sub \
  configure depcomp install-sh ltmain.sh     \
  Makefile.in missing config.h.in            \
  mkinstalldirs *~ \
  $(NULL)
