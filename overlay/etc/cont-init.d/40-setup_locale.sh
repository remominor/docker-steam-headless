
# Configure locale
print_header "Configure locale"

user_locale="${USER_LOCALES%% *}"

if ! grep -Fqx "${USER_LOCALES}" /etc/locale.gen; then
    print_step_header "Configuring Locales to ${USER_LOCALES}"
    {
        printf '%s\n' "${USER_LOCALES}"
        [[ "${USER_LOCALES}" == "en_US.UTF-8 UTF-8" ]] || printf '%s\n' 'en_US.UTF-8 UTF-8'
    } > /etc/locale.gen
    locale-gen
else
    print_step_header "Locales already set correctly to ${USER_LOCALES}"
fi

export LANGUAGE="${user_locale}"
export LANG="${user_locale}"
export LC_ALL="${user_locale}"
update-locale LANG="${user_locale}" LANGUAGE="${user_locale}" LC_ALL="${user_locale}"

echo -e "\e[34mDONE\e[0m"
