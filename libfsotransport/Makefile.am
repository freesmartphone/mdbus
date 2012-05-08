include $(top_srcdir)/Makefile.decl

NULL =

SUBDIRS = \
  fsotransport \
  tests \
  vapi \
  $(NULL)

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = fsotransport-2.0.pc

EXTRA_DIST += \
  MAINTAINERS \
  fsotransport-2.0.pc.in \
  3rdparty/hsuart.h \
  3rdparty/linux/gsmmux.h \
  $(NULL)

MAINTAINERCLEANFILES = \
  aclocal.m4 compile config.guess config.sub \
  configure depcomp install-sh ltmain.sh     \
  Makefile.in missing config.h.in            \
  mkinstalldirs \
  *~ \
  $(NULL)
