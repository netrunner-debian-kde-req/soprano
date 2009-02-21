include /usr/share/cdbs/1/class/cmake.mk
include /usr/share/cdbs/1/rules/debhelper.mk
include /usr/share/cdbs/1/rules/patchsys-quilt.mk
include /usr/share/cdbs/1/rules/utils.mk

# Include default KDE 4 cmake configuration variables
include debian/cdbs/variables.mk

# Since cmake 2.6.2 or higher is required from now on, enable
# relative paths to get more ccache hits.
# NOTE: might not work with vanilla 2.6.2, only with Debian's one.
DEB_CMAKE_KDE4_FLAGS += -DCMAKE_USE_RELATIVE_PATHS=ON

# Pass standard KDE 4 flags to cmake via appropriate CDBS variable
# (DEB_CMAKE_EXTRA_FLAGS)
DEB_CMAKE_EXTRA_FLAGS += $(DEB_CMAKE_KDE4_FLAGS) $(DEB_CMAKE_CUSTOM_FLAGS)

DEB_COMPRESS_EXCLUDE = .dcl .docbook -license .tag .sty .el

#DEB_CMAKE_PREFIX = /usr/lib/kde4
DEB_DH_INSTALL_SOURCEDIR = debian/tmp
#DEB_DH_SHLIBDEPS_ARGS = -l/usr/lib/kde4/lib/
DEB_KDE_ENABLE_FINAL ?=
#DEB_MAKE_ENVVARS += XDG_CONFIG_DIRS=/etc/xdg XDG_DATA_DIRS=/usr/share
#DEB_STRIP_EXCLUDE = so

common-build-arch:: debian/stamp-man-pages
debian/stamp-man-pages:
	if ! test -d debian/man/out; then mkdir -p debian/man/out; fi
	for f in $$(find debian/man -name '*.sgml'); do \
		docbook-to-man $$f > debian/man/out/`basename $$f .sgml`.1; \
	done
	for f in $$(find debian/man -name '*.man'); do \
		soelim -I debian/man $$f \
		> debian/man/out/`basename $$f .man`.`head -n1 $$f | awk '{print $$NF}'`; \
	done
	touch debian/stamp-man-pages

clean::
ifndef THIS_SHOULD_GO_TO_UNSTABLE
	#guard against experimental uploads to unstable
	dpkg-parsechangelog | grep ^Distribution | grep -q 'experimental\|UNRELEASED\|jaunty'
endif
	rm -rf debian/man/out
	-rmdir debian/man
	rm -f debian/stamp-man-pages
	rm -f CMakeCache.txt


$(patsubst %,binary-install/%,$(DEB_PACKAGES)) :: binary-install/%:
	if test -x /usr/bin/dh_desktop; then dh_desktop -p$(cdbs_curpkg) $(DEB_DH_DESKTOP_ARGS); fi
	if test -e debian/$(cdbs_curpkg).lintian; then \
		install -p -D -m644 debian/$(cdbs_curpkg).lintian \
			debian/$(cdbs_curpkg)/usr/share/lintian/overrides/$(cdbs_curpkg); \
	fi
	if test -e debian/$(cdbs_curpkg).presubj; then \
		install -p -D -m644 debian/$(cdbs_curpkg).presubj \
			debian/$(cdbs_curpkg)/usr/share/bug/$(cdbs_curpkg)/presubj; \
	fi
	if test -e debian/$(cdbs_curpkg).bugscript; then \
		install -p -D -m755 debian/$(cdbs_curpkg).bugscript \
			debian/$(cdbs_curpkg)/usr/share/bug/$(cdbs_curpkg)/script; \
	fi
	if test -e debian/$(cdbs_curpkg).bugcontrol; then \
		install -p -D -m644 debian/$(cdbs_curpkg).bugcontrol \
			debian/$(cdbs_curpkg)/usr/share/bug/$(cdbs_curpkg)/control; \
	fi

binary-install/$(DEB_SOURCE_PACKAGE)-doc-html::
	set -e; \
	for doc in `cd $(DEB_DESTDIR)/usr/share/doc/kde/HTML/en; find . -name index.docbook`; do \
		pkg=$${doc%/index.docbook}; pkg=$${pkg#./}; \
		echo Building $$pkg HTML docs...; \
		mkdir -p $(CURDIR)/debian/$(DEB_SOURCE_PACKAGE)-doc-html/usr/share/doc/kde/HTML/en/$$pkg; \
		cd $(CURDIR)/debian/$(DEB_SOURCE_PACKAGE)-doc-html/usr/share/doc/kde/HTML/en/$$pkg; \
		meinproc4 $(DEB_DESTDIR)/usr/share/doc/kde/HTML/en/$$pkg/index.docbook; \
	done
	for pkg in $(DOC_HTML_PRUNE) ; do \
		rm -rf debian/$(DEB_SOURCE_PACKAGE)-doc-html/usr/share/doc/kde/HTML/en/$$pkg; \
	done


# Process "sameVersionDep:" substvars
DH_SAMEVERSIONDEPS=debian/cdbs/dh_sameversiondeps
common-binary-predeb-arch common-binary-predeb-indep::
	@if [ ! -x "$(DH_SAMEVERSIONDEPS)" ]; then chmod a+x "$(DH_SAMEVERSIONDEPS)"; fi
	$(DH_SAMEVERSIONDEPS) $(if $(filter common-binary-predeb-arch,$@),-a,-i)
