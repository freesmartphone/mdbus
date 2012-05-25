include $(top_srcdir)/Makefile.decl

NULL =

SUBDIRS = \
	src \
	tests \
	vapi \
	$(NULL)

if WANT_DATAFILES
SUBDIRS += \
	conf \
	data \
	$(NULL)
endif

DISTCHECK_CONFIGURE_FLAGS = \
	--disable-datafiles \
	--enable-libgsm0710mux \
	--enable-modem-nokia-isi \
	--enable-modem-samsung \
	$(NULL)

MAINTAINERCLEANFILES = \
	aclocal.m4 compile config.guess config.sub \
	configure depcomp install-sh ltmain.sh     \
	Makefile.in missing config.h.in            \
	mkinstalldirs \
	$(NULL)
