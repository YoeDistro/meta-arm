HOMEPAGE = "https://developer.arm.com/tools-and-software/simulation-models/fixed-virtual-platforms"

# FVP has an End User License Agreement. Add Arm-FVP-EULA to your
# LICENSE_FLAGS_WHITELIST if you agree to these terms.
LICENSE_FLAGS = "Arm-FVP-EULA"

LICENSE = "Proprietary & Apache-2.0 & Python-2.0 & GPL-3.0-with-GCC-exception & Zlib & NCSA & LGPLv2+ & MIT & BSD-3-Clause"

COMPATIBLE_HOST = '(x86_64|i.86).*-linux'
FVP_ARCH = "Linux64_GCC-6.4"

# The directory the FVP is installed into
FVPDIR = "${libdir}/fvp/${BPN}"

# Used in do_install to create symlinks in $bindir to $FVPDIR
fvp_link_binaries() {
    for FVP in ${D}${FVPDIR}/models/${FVP_ARCH}/FVP_*; do
        lnr $FVP ${D}${bindir}/$(basename $FVP)
    done
    # But not the .so files too
    rm -f ${D}${bindir}/*.so
}

FILES_${PN} = "${bindir} ${FVPDIR}"

# Prebuilt binaries are already stripped
INSANE_SKIP_${PN} += "already-stripped"
# FVP can optionally have a GUI, but we can use the host libraries in native/nativesdk
INSANE_SKIP_${PN} += "file-rdeps"

# FVP brings its own standard library so don't let it be used as a shlib provider
PRIVATE_LIBS = "libgcc_s.so.1 libstdc++.so.6"

INHIBIT_DEFAULT_DEPS = "1"

BBCLASSEXTEND = "native nativesdk"
