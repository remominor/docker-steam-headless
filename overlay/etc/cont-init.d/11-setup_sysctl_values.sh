
# Configure kernel parameters
print_header "Configure some system kernel parameters"


if [ "$(cat /proc/sys/vm/max_map_count)" -lt 524288 ]; then
    if printf '%s\n' 524288 2>/dev/null >/proc/sys/vm/max_map_count; then
        print_step_header "Set the maximum number of memory map areas a process can create to 524288"
    else
        print_warning "Unable to set vm.max_map_count on unprivileged container"
    fi
else
    print_step_header "The vm.max_map_count is already at least '524288'"
fi

echo -e "\e[34mDONE\e[0m"
