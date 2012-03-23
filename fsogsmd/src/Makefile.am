include $(top_srcdir)/Makefile.decl

NULL =

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	3rdparty \
	lib \
	plugins \
	bin \
	$(NULL)

if WANT_PPP
SUBDIRS += ppp
endif

if WANT_CONNMAN
SUBDIRS += connman
endif
