# KDE 4 global configuration file installation directory
DEB_CONFIG_INSTALL_DIR ?= /usr/share/kde4/config

# Standard Debian KDE 4 cmake flags
DEB_CMAKE_KDE4_FLAGS += \
        -DCMAKE_BUILD_TYPE=Debian \
        -DKDE4_ENABLE_FINAL=$(KDE4-ENABLE-FINAL) \
        -DKDE4_BUILD_TESTS=false \
        -DKDE_DISTRIBUTION_TEXT="Debian packages" \
        -DKDE_DEFAULT_HOME=.kde4 \
        -DCMAKE_SKIP_RPATH=true \
        -DKDE4_USE_ALWAYS_FULL_RPATH=false \
        -DCONFIG_INSTALL_DIR=$(DEB_CONFIG_INSTALL_DIR) \
        -DDATA_INSTALL_DIR=/usr/share/kde4/apps \
        -DHTML_INSTALL_DIR=/usr/share/doc/kde4/HTML \
        -DKCFG_INSTALL_DIR=/usr/share/kde4/config.kcfg \
        -DLIB_INSTALL_DIR=/usr/lib \
        -DSYSCONF_INSTALL_DIR=/etc \
        -DKDE4_USE_COMMON_CMAKE_PACKAGE_CONFIG_DIR:BOOL=TRUE

# Support building with enable final (disabled by default)
DEB_KDE_ENABLE_FINAL ?=
KDE4-ENABLE-FINAL := false
ifeq (,$(findstring noopt,$(DEB_BUILD_OPTIONS)))
    treat_me_gently_arches := arm m68k alpha ppc64 armel armeb
    DEB_HOST_ARCH_CPU ?= $(shell dpkg-architecture -qDEB_HOST_ARCH_CPU)
    ifeq (,$(filter $(DEB_HOST_ARCH_CPU),$(treat_me_gently_arches)))
        KDE4-ENABLE-FINAL := $(if $(DEB_KDE_ENABLE_FINAL),true,false)
    endif
endif

#### Default additional (custom) cmake flags ####
DEB_CMAKE_CUSTOM_FLAGS ?=

# Set the one below to something else than 'yes' to disable linking 
# with --as-needed (on by default)
DEB_KDE_LINK_WITH_AS_NEEDED ?= yes
ifneq (,$(findstring yes, $(DEB_KDE_LINK_WITH_AS_NEEDED)))
    ifeq (,$(findstring no-as-needed, $(DEB_BUILD_OPTIONS)))
        DEB_KDE_LINK_WITH_AS_NEEDED := yes
        DEB_CMAKE_CUSTOM_FLAGS += \
            -DCMAKE_SHARED_LINKER_FLAGS="-Wl,--no-undefined -Wl,--as-needed" \
            -DCMAKE_MODULE_LINKER_FLAGS="-Wl,--no-undefined -Wl,--as-needed" \
            -DCMAKE_EXE_LINKER_FLAGS="-Wl,--no-undefined -Wl,--as-needed"
    else
        DEB_KDE_LINK_WITH_AS_NEEDED := no
    endif
else
    DEB_KDE_LINK_WITH_AS_NEEDED := no
endif
