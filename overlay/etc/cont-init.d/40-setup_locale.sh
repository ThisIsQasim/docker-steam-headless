
# Configure dbus
print_header "Configure local"

user_local=$(echo ${USER_LOCALES} | cut -d ' ' -f 1)

# Detect which package manager is available
if command -v dnf &>/dev/null; then
    # Fedora-based system
    current_local=$(grep -E '^LANG=' /etc/locale.conf 2>/dev/null | cut -d '=' -f 2)
    if [ "${current_local}" != "${user_local}" ]; then
        print_step_header "Configuring Locales to ${user_local} (Fedora)"
        
        # Extract language code (e.g., en_US from en_US.UTF-8)
        lang_code=$(echo "${user_local}" | cut -d '.' -f 1)
        
        # Install the required language pack if not already installed
        if ! dnf list installed | grep -q "glibc-langpack-${lang_code}" 2>/dev/null; then
            dnf install -y "glibc-langpack-${lang_code}" 2>/dev/null || \
                print_warning "Failed to install glibc-langpack-${lang_code}, continuing with default locale"
        fi
        
        # Update /etc/locale.conf
        echo "LANG=${user_local}" > /etc/locale.conf
        export LANGUAGE="${user_local%.*}:en"
        export LANG="${user_local}"
        export LC_ALL="${user_local}" 2> /dev/null
    else
        print_step_header "Locales already set correctly to ${user_local}"
    fi
elif command -v pacman &>/dev/null; then
    # Arch-based system
    current_local=$(head -n 1 /etc/locale.gen 2>/dev/null)
    if [ "${current_local}" != "${USER_LOCALES}" ]; then
        print_step_header "Configuring Locales to ${USER_LOCALES} (Arch)"
        rm -f /etc/locale.gen
        echo -e "${USER_LOCALES}\nen_US.UTF-8 UTF-8" > "/etc/locale.gen"
        export LANGUAGE="${user_local}"
        export LANG="${user_local}"
        export LC_ALL="${user_local}" 2> /dev/null
        sleep 0.5
        locale-gen
    else
        print_step_header "Locales already set correctly to ${USER_LOCALES}"
    fi
elif command -v apt-get &>/dev/null; then
    # Debian-based system
    current_local=$(head -n 1 /etc/locale.gen 2>/dev/null)
    if [ "${current_local}" != "${USER_LOCALES}" ]; then
        print_step_header "Configuring Locales to ${USER_LOCALES} (Debian)"
        rm -f /etc/locale.gen
        echo -e "${USER_LOCALES}\nen_US.UTF-8 UTF-8" > "/etc/locale.gen"
        export LANGUAGE="${user_local}"
        export LANG="${user_local}"
        export LC_ALL="${user_local}" 2> /dev/null
        sleep 0.5
        locale-gen
        update-locale LC_ALL="${user_local}"
    else
        print_step_header "Locales already set correctly to ${USER_LOCALES}"
    fi
else
    print_warning "Unable to detect package manager for locale configuration"
fi

echo -e "\e[34mDONE\e[0m"
