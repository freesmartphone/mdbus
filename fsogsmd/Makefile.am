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
	$(NULL)

if WANT_MUX
DISTCHECK_CONFIGURE_FLAGS += \
	--enable-libgsm0710mux \
	$(NULL)
endif

if WANT_ISI
DISTCHECK_CONFIGURE_FLAGS += \
	--enable-modem-nokia-isi \
	$(NULL)
endif

if WANT_SAMSUNG
DISTCHECK_CONFIGURE_FLAGS += \
	--enable-modem-samsung \
	$(NULL)
endif

MAINTAINERCLEANFILES = \
	aclocal.m4 compile config.guess config.sub \
	configure depcomp install-sh ltmain.sh     \
	Makefile.in missing config.h.in            \
	mkinstalldirs \
	$(NULL)
