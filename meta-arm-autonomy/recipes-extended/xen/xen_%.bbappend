# Use OVERRIDES to minimize the usage of
# ${@bb.utils.contains('DISTRO_FEATURES', 'arm-autonomy-host', ...
OVERRIDES_append = "${ARM_AUTONOMY_HOST_OVERRIDES}"

# Make Xen machine specific
# This ensures that sstate is properly handled and that each machine can have
# its own configuration
PACKAGE_ARCH_autonomy-host = "${MACHINE_ARCH}"

PACKAGECONFIG_remove_autonomy-host = "sdl"
