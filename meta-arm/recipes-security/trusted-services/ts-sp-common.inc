# Common part of all Trusted Services SPs recipes

TS_ENV ?= "opteesp"

require trusted-services.inc
require ts-uuid.inc

DEPENDS += "dtc-native"
DEPENDS += "${@oe.utils.conditional('TS_ENV','sp','python3-pyelftools-native','', d)}"

FILES:${PN}-dev = "${TS_INSTALL}"

# Secure Partition DTS file might be updated in bbapend files
SP_DTS_FILE ?= "${D}${TS_INSTALL}/manifest/${SP_UUID}.dts"

do_install:append() {
    # Generate SP DTB which will be included automatically by optee-os build process
    dtc -I dts -O dtb -o ${D}${TS_INSTALL}/manifest/${SP_UUID}.dtb ${SP_DTS_FILE}

    # We do not need libs and headers
    rm -rf --one-file-system ${D}${TS_INSTALL}/lib
    rm -rf --one-file-system ${D}${TS_INSTALL}/include
}

# Use Yocto debug prefix maps for compiling assembler.
EXTRA_OECMAKE += '-DCMAKE_ASM_FLAGS="${DEBUG_PREFIX_MAP}"'

# Ignore that SP stripped.elf does not have GNU_HASH
# Older versions of optee support SYSV hash only.
INSANE_SKIP:${PN}-dev += "ldflags"

# Trusted Services SPs do not compile with clang
TOOLCHAIN = "gcc"
# FIXME - there is an issue with mbedtls unions and gcc15.  It has been
# fixed in commit 4c26d7d54cf5f5dc1e63e0dd0b902fda05e7063f but that has
# not been released yet.  Work around this issue here until that is out
TARGET_CFLAGS += "-fzero-init-padding-bits=unions"

# FORTIFY_SOURCE is a glibc feature. Disable it for all SPs as these do not use glibc.
TARGET_CFLAGS:remove = "-D_FORTIFY_SOURCE=2"
OECMAKE_C_FLAGS:remove = "-D_FORTIFY_SOURCE=2"
OECMAKE_CXX_FLAGS:remove = "-D_FORTIFY_SOURCE=2"

# Override yoctos default linux specific toolchain file. trusted-services.inc
# will add a proper tooclhain option.
OECMAKE_ARGS:remove = "-DCMAKE_TOOLCHAIN_FILE:FILEPATH=${WORKDIR}/toolchain.cmake"

# Set BranchProtection to standard
EXTRA_OECMAKE += "${@bb.utils.contains('MACHINE_FEATURES', 'arm-branch-protection', ' -DBRANCH_PROTECTION=1', '', d)}"
