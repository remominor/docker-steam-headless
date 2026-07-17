#!/usr/bin/env bash
# GPU userspace drivers must be supplied either by Debian packages installed at
# image-build time (Intel/AMD) or by the NVIDIA container runtime. Installing a
# full NVIDIA .run package over runtime-injected, version-matched libraries can
# leave a mixed driver stack and makes container startup depend on the network.

source /usr/bin/common-functions.sh

gpu_selector="${NVIDIA_PRIMARY_GPU:-${NVIDIA_VISIBLE_DEVICES:-all}}"
gpu_select=""

if command -v nvidia-smi >/dev/null 2>&1; then
    if ! gpu_select="$(get_nvidia_gpu_id)"; then
        print_header "NVIDIA runtime present but no GPU is visible"
        print_error "nvidia-smi could not resolve the requested GPU selector '${gpu_selector}'"
        print_note "Use --runtime=nvidia and verify that nvidia-smi lists at least one full GPU inside the container."
        exit 1
    fi
fi

if [[ -n "${gpu_select}" ]]; then
    nvidia_gpu_name="$(get_nvidia_gpu_property "${gpu_select}" name)"
    nvidia_pci_address="$(get_nvidia_gpu_property "${gpu_select}" pci.bus_id)"
    nvidia_host_driver_version="$(get_nvidia_gpu_property "${gpu_select}" driver_version)"

    if [[ ! "${nvidia_pci_address}" =~ ^[[:xdigit:]]+:[[:xdigit:]]+:[[:xdigit:]]+[.][[:xdigit:]]+$ ]]; then
        print_error "nvidia-smi returned invalid PCI data for '${gpu_select}': '${nvidia_pci_address}'"
        exit 1
    fi

    print_header "Found NVIDIA device '${nvidia_gpu_name}'"
    print_step_header "Primary GPU: ${gpu_select} at ${nvidia_pci_address}"
    print_step_header "Host driver: ${nvidia_host_driver_version}"
    print_step_header "Driver capabilities: ${NVIDIA_DRIVER_CAPABILITIES:-unset}"

    missing_components=()
    for library in \
        libnvidia-cfg.so.1 \
        libnvidia-encode.so.1 \
        libnvidia-ml.so.1 \
        libGLX_nvidia.so.0; do
        if ! ldconfig -p 2>/dev/null | grep -Fq "${library}"; then
            missing_components+=("${library}")
        fi
    done

    nvidia_xorg_driver=""
    for candidate in \
        /usr/lib64/xorg/modules/drivers/nvidia_drv.so \
        /usr/lib/x86_64-linux-gnu/nvidia/xorg/nvidia_drv.so \
        /usr/lib/xorg/modules/drivers/nvidia_drv.so; do
        if [[ -f "${candidate}" ]]; then
            nvidia_xorg_driver="${candidate}"
            break
        fi
    done

    if [[ -z "${nvidia_xorg_driver}" ]]; then
        missing_components+=("nvidia_drv.so")
    else
        print_step_header "Using runtime Xorg driver: ${nvidia_xorg_driver}"
    fi

    if (( ${#missing_components[@]} > 0 )); then
        print_error "The NVIDIA runtime did not provide: ${missing_components[*]}"
        print_note "Use --runtime=nvidia with NVIDIA_DRIVER_CAPABILITIES=all; do not install a driver inside the container."
        exit 1
    fi

    print_step_header "Using the host-matched NVIDIA runtime driver stack"
elif [[ -n "$(lspci 2>/dev/null | grep -i 'VGA compatible controller:.*AMD' || true)" ]]; then
    print_header "Found AMD graphics device"
    print_step_header "Using Mesa/Vulkan drivers installed in the image"
elif [[ -n "$(lspci 2>/dev/null | grep -i 'VGA compatible controller:.*Intel' || true)" ]]; then
    print_header "Found Intel graphics device"
    print_step_header "Using Mesa/Vulkan drivers installed in the image"
else
    print_header "No supported GPU device found"
fi

echo -e "\e[34mDONE\e[0m"
