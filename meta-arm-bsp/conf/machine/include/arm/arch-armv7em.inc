#
# Defaults for ARMv7e-m
#
DEFAULTTUNE ?= "armv7em"

TUNEVALID[armv7em] = "Enable instructions for ARMv7e-m"
TUNE_CCARGS .= "${@bb.utils.contains('TUNE_FEATURES', 'armv7em', ' -march=armv7e-m', '', d)}"
MACHINEOVERRIDES =. "${@bb.utils.contains('TUNE_FEATURES', 'armv7em', 'armv7em:', '', d)}"

TUNECONFLICTS[armv7em] = "armv4 armv5 armv6 armv7a"

require conf/machine/include/arm/arch-armv7m.inc

AVAILTUNES                            += "armv7em"
ARMPKGARCH_tune-armv7em                = "armv7em"
TUNE_FEATURES_tune-armv7em             = "armv7em"
PACKAGE_EXTRA_ARCHS_tune-armv7em       = "armv7em"
