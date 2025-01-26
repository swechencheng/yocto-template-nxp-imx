#!/usr/bin/env bash

set -ueE -o pipefail -o posix
shopt -s failglob

# Default options
FORCE_CLEANALL=0
KEEP_GOING=0
BLACKLIST=0

# Default settings
REPO_ROOT="$(git rev-parse --show-toplevel)"
BUILD_DIR=build
DISTRO=fsl-wayland
TEMPLATE_LAYER=openembedded-core/meta
TEMPLATE=default
MACHINE=imx6ulevk
IMAGE=core-image-minimal
INITRAMFS_IMAGE=fsl-image-mfgtool-initramfs
BB_CMD=bitbake
TARGET=

# Some logging utilities
tput()
{
    command tput "$@" 2> /dev/null || true
}
log_info()
{
    >&2 printf -- "%s\n" "$(tput setaf 6)$*$(tput sgr 0)"
}
log_succ()
{
    >&2 printf -- "%s\n" "$(tput setaf 2)========================================================================$(tput sgr 0)"
    >&2 printf -- "%s\n" "$(tput setaf 2)$*$(tput sgr 0)"
    >&2 printf -- "%s\n" "$(tput setaf 2)========================================================================$(tput sgr 0)"
}
log_warn()
{
    >&2 printf -- "%s\n" "$(tput setaf 3)$*$(tput sgr 0)"
}
log_err()
{
    >&2 printf -- "%s\n" "$(tput setaf 1)$*$(tput sgr 0)"
}

show_help()
{
    >&2 cat <<EOF
Usage: $0 [OPTIONS]... [TARGET]
Wrapper of bitbake engine which builds Yocto.

OPTIONS:
    -B                  If specified, blacklist certain recipes
                            which conflicts with OE-core.

    -h                  If specified, display this help message.

    -H                  If specified, clean the build workspace thouroughly
                            and build from scratch.
                            "H" reflects "Hygiene".

    -k                  If specified, Continue bitbake as much as possible
                            after an error.
                            "-k" is the same option in bitbake command.

TARGET:
    If specified, build only the specific target.
    Should be "bootloader", "kernel", "initramfs", "image",
    or a valid recipe name.

Example:
    To build a default image (core-image-minimal):

        $0

    To build a specific target such as busybox:

        $0 busybox

EOF
}

# Parse args
while getopts "BHhk" opt; do
    case "$opt" in
        B)
            BLACKLIST=1
            ;;
        h)
            show_help
            exit 0
            ;;
        H)
            FORCE_CLEANALL=1
            ;;
        k)
            KEEP_GOING=1
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
done

# When we have processed the flags we shift past them to be able to
# properly parse the single recipe
shift "$((OPTIND-1))"
[ "${1:-}" = "--" ] && shift

if [ $# -gt 1 ]; then
    log_err "At most one target can be used. Please refer to help."
    exit 1
fi

INPUT=$*
if [ -n "$INPUT" ]; then
    if [[ "$INPUT" == "bootloader" ]]; then
        TARGET="virtual/bootloader"
    elif [[ "$INPUT" == "kernel" ]]; then
        TARGET="virtual/kernel"
    elif [[ "$INPUT" == "initramfs" ]]; then
        TARGET="${INITRAMFS_IMAGE}"
    elif [[ "$INPUT" == "image" ]]; then
        TARGET="${IMAGE}"
    else
        TARGET="${INPUT}"
    fi
    log_warn "Building only ${TARGET}..."
fi

# If force rebuild applies, remove all build caches
if [ ${FORCE_CLEANALL} -ne 0 ]; then
    log_info "Clean up build folder for a clean build..."
    # Temporarily disable failglob and enable nullglob
    shopt -u failglob
    shopt -s nullglob
    # Perform the removal
    rm -rf build/cache/ build/conf/ build/sstate-cache/ build/tmp*
    # Restore failglob and disable nullglob to avoid side effects
    shopt -u nullglob
    shopt -s failglob
fi

# If keep going, we want to have bitbake engine keep on running through the rest of the tasks without stopping
if [ ${KEEP_GOING} -ne 0 ]; then
    BB_CMD="${BB_CMD} -k"
fi

# Capture the submodule status output
status_output=$(git submodule status)

# Check if submodules are up-to-date
if echo "$status_output" | grep -qE '^[+\-]'; then
    log_warn "Submodules are not up-to-date. Updating..."
    git submodule update --init --recursive
    log_info "Clean up build folder to avoid bitbake conflicts..."
    # Temporarily disable failglob and enable nullglob
    shopt -u failglob
    shopt -s nullglob
    # Perform the removal
    rm -rf build/bitbake* build/buildhistory/ build/cache/ build/conf/ build/sstate-cache/ build/tmp*
    # Restore failglob and disable nullglob to avoid side effects
    shopt -u nullglob
    shopt -s failglob
else
    log_succ "Submodules are up-to-date."
fi

# Show options for debugging fore proceed to build
log_info "FORCE_CLEANALL=$FORCE_CLEANALL"
log_info "KEEP_GOING=$KEEP_GOING"
log_info "BLACKLIST=$BLACKLIST"

# Use a subshell when sourcing oe-init-build-env, so that its effects do not become permanent
(
    set +u   # oe-init-build-env relies on undefined variables expanding to empty strings
    rm -rf ${BUILD_DIR}/conf
    log_info "Starting bitbake process..."
    log_warn "Please refer to the following command if you need to manually run bitbake:"
    log_succ "MACHINE=${MACHINE} DISTRO=${DISTRO} TEMPLATECONF=${REPO_ROOT}/sources/${TEMPLATE_LAYER}/conf/templates/${TEMPLATE} source ${REPO_ROOT}/sources/openembedded-core/oe-init-build-env ${BUILD_DIR}"
    MACHINE=${MACHINE} DISTRO=${DISTRO} TEMPLATECONF=${REPO_ROOT}/sources/${TEMPLATE_LAYER}/conf/templates/${TEMPLATE} source ${REPO_ROOT}/sources/openembedded-core/oe-init-build-env ${BUILD_DIR}

    # We are under BUILD_DIR now
    echo "BBLAYERS += \"${REPO_ROOT}/sources/meta-openembedded/meta-oe\"" >> conf/bblayers.conf
    echo "BBLAYERS += \"${REPO_ROOT}/sources/meta-openembedded/meta-multimedia\"" >> conf/bblayers.conf
    echo "BBLAYERS += \"${REPO_ROOT}/sources/meta-openembedded/meta-networking\"" >> conf/bblayers.conf
    echo "BBLAYERS += \"${REPO_ROOT}/sources/meta-openembedded/meta-python\"" >> conf/bblayers.conf
    echo "BBLAYERS += \"${REPO_ROOT}/sources/meta-yocto/meta-yocto-bsp\"" >> conf/bblayers.conf
    echo "BBLAYERS += \"${REPO_ROOT}/sources/meta-yocto/meta-poky\"" >> conf/bblayers.conf
    echo "BBLAYERS += \"${REPO_ROOT}/sources/meta-imx/meta-imx-bsp\"" >> conf/bblayers.conf
    echo "BBLAYERS += \"${REPO_ROOT}/sources/meta-freescale\"" >> conf/bblayers.conf
    echo "BBLAYERS += \"${REPO_ROOT}/sources/meta-freescale-3rdparty\"" >> conf/bblayers.conf
    echo "BBLAYERS += \"${REPO_ROOT}/sources/meta-freescale-distro\"" >> conf/bblayers.conf
    echo "BBLAYERS += \"${REPO_ROOT}/sources/meta-arm/meta-arm\"" >> conf/bblayers.conf
    echo "BBLAYERS += \"${REPO_ROOT}/sources/meta-arm/meta-arm-bsp\"" >> conf/bblayers.conf
    echo "BBLAYERS += \"${REPO_ROOT}/sources/meta-arm/meta-arm-toolchain\"" >> conf/bblayers.conf

    echo "PREFERRED_PROVIDER_virtual/bootloader = \"u-boot-imx\"" >> conf/local.conf
    echo "PREFERRED_PROVIDER_virtual/kernel = \"linux-imx\"" >> conf/local.conf
    echo "PREFERRED_PROVIDER_linux-mfgtool = \"linux-imx-mfgtool\"" >> conf/local.conf
    echo "PREFERRED_PROVIDER_u-boot-mfgtool = \"u-boot-imx-mfgtool\"" >> conf/local.conf

    # To use some recipe e.g. 'firmware-imx' you need to accept the Freescale EULA
    echo "ACCEPT_FSL_EULA = \"1\"" >> conf/local.conf

    if [ ${BLACKLIST} -ne 0 ]; then
        # TODO: REMOVE THIS IN FUTURE IF meta-imx FIXES!
        # Temporary fix. The version of cryptodev in meta-imx (1.13) doesn't match version in openembedded-core (yocto-5.0.6).
        log_warn "Blacklisting cryptodev-linux_1.13.bbappend since it conflicts with OE-core (yocto-5.0.6) cryptodev-linux_1.14."
        echo "BBMASK += \"cryptodev-linux_1.13.bbappend\"" >> conf/local.conf
    fi

    # Build the specific target and quit
    if [[ -n "$INPUT" && -n "$TARGET" && "$INPUT" == "$TARGET" ]]; then
        ${BB_CMD} ${TARGET}
        result=$?
        if [ $result -eq 0 ]; then
            log_succ "Bitbake ${TARGET} succeeded."
            exit 0
        fi
    fi

    # Build u-boot
    if [[ -z "$INPUT" || "$INPUT" == "bootloader" ]]; then
        ${BB_CMD} virtual/bootloader
    fi

    # Build Linux kernel
    if [[ -z "$INPUT" || "$INPUT" == "kernel" ]]; then
        ${BB_CMD} virtual/kernel
    fi

    # Build initramfs
    if [[ -z "$INPUT" || "$INPUT" == "initramfs" ]]; then
        ${BB_CMD} ${INITRAMFS_IMAGE}
    fi

    # Build final image
    if [[ -z "$INPUT" || "$INPUT" == "image" ]]; then
        ${BB_CMD} ${IMAGE}
    fi

    if [ -z "$INPUT" ]; then
        log_succ "All tasks finished. Please check results above."
    else
        log_succ "Bitbake ${TARGET} succeeded."
    fi
)
