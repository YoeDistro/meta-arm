require recipes-bsp/trusted-firmware-a/trusted-firmware-a.inc

# TF-A master
SRCREV_tfa = "bcce173da397f776fc0ec14e9dac03c13ddeb722"
SRCBRANCH = "master"

LIC_FILES_CHKSUM += "file://docs/license.rst;md5=83b7626b8c7a37263c6a58af8d19bee1"

# in TF-A src, docs/getting_started/prerequisites.rst lists the expected version mbedtls
# mbedtls-3.6.1
SRC_URI_MBEDTLS = "git://github.com/ARMmbed/mbedtls.git;name=mbedtls;protocol=https;destsuffix=git/mbedtls;branch=mbedtls-3.6"
SRCREV_mbedtls = "71c569d44bf3a8bd53d874c81ee8ac644dd6e9e3"

LIC_FILES_CHKSUM_MBEDTLS = "file://mbedtls/LICENSE;md5=379d5819937a6c2f1ef1630d341e026d"

# continue to boot also without TPM
SRC_URI += "\
    file://0001-qemu_measured_boot.c-ignore-TPM-error-and-continue-w.patch \
"

# Not a release recipe, try our hardest to not pull this in implicitly
DEFAULT_PREFERENCE = "-1"
