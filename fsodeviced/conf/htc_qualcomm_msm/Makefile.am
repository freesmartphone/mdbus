include $(top_srcdir)/Makefile.decl

NULL=

confdir = @DBUS_DIR@/../freesmartphone/conf/htc_qualcomm_msm
dist_conf_DATA = \
	fsodeviced.conf \
	$(NULL)

# boards compatible with htc_qualcomm_msm
COMPAT = \
	trout \
	raphael \
	diamond \
	$(NULL)
	
install-data-local: install-dist_confDATA
	for compat in $(COMPAT); do ln -sf ./htc_qualcomm_msm $(confdir)/../$$compat; done

MAINTAINERCLEANFILES = Makefile.in
