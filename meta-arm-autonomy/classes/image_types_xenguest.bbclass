# Create a xenguest image with kernel and filesystem produced by Yocto
# This will create a .xenguest file that the xenguest-manager can use.

inherit xenguest_image

# We are creating our guest in a local subdirectory
# force the value so that we are not impacted if the user is changing it
XENGUEST_IMAGE_DEPLOY_DIR = "${WORKDIR}/tmp-xenguest"

# Name of deployed file (keep standard image name and add .xenguest)
XENGUEST_IMAGE_DEPLOY ??= "${IMAGE_NAME}"

# Add kernel XENGUEST_IMAGE_KERNEL from DEPLOY_DIR_IMAGE to image
xenguest_image_add_kernel() {
    srcfile="${1:-}"
    if [ -z "${srcfile}" ]; then
        srcfile="${DEPLOY_DIR_IMAGE}/${XENGUEST_IMAGE_KERNEL}"
    fi
    call_xenguest_mkimage partial --xen-kernel=$srcfile
}

# Add rootfs file to the image
xenguest_image_add_rootfs() {
    call_xenguest_mkimage partial \
        --disk-add-file=${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.${IMAGE_TYPEDEP_xenguest}:rootfs.${IMAGE_TYPEDEP_xenguest}
}

# Pack xenguest image
xenguest_image_pack() {
    mkdir -p ${IMGDEPLOYDIR}
    rm -f ${IMGDEPLOYDIR}/${XENGUEST_IMAGE_DEPLOY}.xenguest
    call_xenguest_mkimage pack \
        ${IMGDEPLOYDIR}/${XENGUEST_IMAGE_DEPLOY}.xenguest
}

#
# Task finishing the bootimg
# We need this task to actually create the symlinks
#
python do_bootimg_xenguest() {
    subtasks = d.getVarFlag('do_bootimg_xenguest', 'subtasks')

    bb.build.exec_func('xenguest_image_clone', d)
    if subtasks:
        for tk in subtasks.split():
            bb.build.exec_func(tk, d)
    bb.build.exec_func('xenguest_image_pack', d)
    bb.build.exec_func('create_symlinks', d)
}
# This is used to add sub-tasks to do_bootimg_xenguest
do_bootimg_xenguest[subtasks] = ""
# Those are required by create_symlinks to find our image
do_bootimg_xenguest[subimages] = "xenguest"
do_bootimg_xenguest[imgsuffix] = "."
do_bootimg_xenguest[depends] += "xenguest-base-image:do_deploy"
# Need to have rootfs so all recipes have deployed their content
do_bootimg_xenguest[depends] += "${PN}:do_rootfs"

# This set in python anonymous after, just set a default value here
IMAGE_TYPEDEP_xenguest ?= "tar"

# We must not be built at rootfs build time because we need the kernel
IMAGE_TYPES_MASKED += "xenguest"
IMAGE_TYPES += "xenguest"

XENGUEST_IMAGE_RECIPE = "${PN}"
XENGUEST_IMAGE_VARS += "XENGUEST_IMAGE_RECIPE"

# Merge intermediate env files from all recipes into a single file
python do_merge_xenguestenv () {

    import re

    # Open final merged file in DEPLOY_DIR_IMAGE for writing, or create
    outdir = d.getVar('DEPLOY_DIR_IMAGE')
    with open(os.path.join(outdir,'xenguest.env'), 'w') as merged_file:

        # Adds vars from xenguest_image to list
        merged_env = []
        xenguest_vars = d.getVar('XENGUEST_IMAGE_VARS')
        for var in xenguest_vars.split():
            value = d.getVar(var)
            if value:
                merged_env.append(var + "=" + " ".join(value.split()) + "\n")

        # Resolve dependencies for this task to find names of intermediate
        # .xenguestenv files
        taskdepdata = d.getVar('BB_TASKDEPDATA')
        task_mc = d.getVar('BB_CURRENT_MC')
        task_file = d.getVar('FILE')

        # See runqueue.py function build_taskdepdata
        DEPS_INDEX = 3

        depdata_key = task_file + ":do_merge_xenguestenv"

        # If in a multiconfig, need to add that to the key
        if task_mc != "default":
            depdata_key = "mc:" + task_mc + ":" + depdata_key

        # Retrieve filename using regex
        get_filename = re.compile(r'/([^/]+\.bb):do_deploy_xenguestenv$')
        env_dir = d.getVar('XENGUEST_ENV_STAGING_DIR')

        for task_dep in taskdepdata[depdata_key][DEPS_INDEX]:
            if task_dep.endswith(":do_deploy_xenguestenv"):
                filename = re.search(get_filename, task_dep).group(1) + ".xenguestenv"
                bb.note("Merging: " + filename)
                try:
                    with open(env_dir + "/" + filename, 'r') as f:
                        # Eliminate duplicates
                        merged_env = list(set(merged_env + f.readlines()))
                except (FileNotFoundError, IOError):
                    bb.note(" " + filename + " has no extra vars")

        # Sort Alphabetically and write
        merged_env.sort()
        merged_file.write("".join(merged_env))
}
do_merge_xenguestenv[dirs] = "${DEPLOY_DIR_IMAGE}"
do_merge_xenguestenv[vardeps] += "${XENGUEST_IMAGE_VARS}"
do_merge_xenguestenv[vardepsexclude] += "BB_TASKDEPDATA"
do_merge_xenguestenv[recrdeptask] += "do_deploy_xenguestenv"

addtask merge_xenguestenv before do_populate_lic_deploy after do_image_complete

python __anonymous() {
    # Do not do anything if we are not in the want FSTYPES
    if bb.utils.contains_any('IMAGE_FSTYPES', 'xenguest', '1', '0', d):

        # Check the coherency of the configuration
        rootfs_needed = False
        rootfs_file = ''
        kernel_needed = False

        rootfs_file = xenguest_image_rootfs_file(d)
        if rootfs_file:
            rootfs_needed = True

        if d.getVar('XENGUEST_IMAGE_KERNEL') and not d.getVar('INITRAMFS_IMAGE'):
            # If INITRAMFS_IMAGE is set, even if INITRAMFS_IMAGE_BUNDLE is not
            # set to 1 to bundle the initramfs with the kernel, kernel.bbclass
            # is setting a dependency on ${PN}:do_image_complete. We cannot
            # in this case depend on do_deploy as it would create a circular
            # dependency:
            # do_image_complete would depend on kernel:do_deploy which would
            # depend on ${PN}:do_image_complete
            # In the case INITRAMFS_IMAGE_BUNDLE = 1, the kernel-xenguest class
            # will handle the creation of a xenguest image with the kernel.
            # In the other case the kernel can be added manually to the image.
            kernel_needed = True

        bb.build.addtask('do_bootimg_xenguest', 'do_image_complete', None, d)

        if rootfs_needed:
            # tell do_bootimg_xenguest to call add_rootfs
            d.appendVarFlag('do_bootimg_xenguest', 'subtasks', ' xenguest_image_add_rootfs')
            # do_bootimg_xenguest will need the tar file
            d.appendVarFlag('do_bootimg_xenguest', 'depends', ' %s:do_image_tar' % (d.getVar('PN')))
            # set our TYPEDEP to the proper compression
            d.setVar('IMAGE_TYPEDEP_xenguest', 'tar' + (rootfs_file.split('.tar', 1)[1] or ''))

        if kernel_needed:
            # Tell do_bootimg_xenguest to call xenguest_image_add_kernel
            d.appendVarFlag('do_bootimg_xenguest', 'subtasks', ' xenguest_image_add_kernel')
            # we will need kernel do_deploy
            d.appendVarFlag('do_bootimg_xenguest', 'depends', ' virtual/kernel:do_deploy')
}

