#!/bin/zsh


export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"


USERNAME=`whoami`
echo "username -> ${USERNAME}"


source utils/colors.sh
source utils/detect_os.sh


print_info "Running it for first time"

echo
echo "[Sudo]"
echo "Running 'sudo' up-front, so that we don't hassle you later."
sudo sleep 0


echo
echo "[Detecting OS]"

OS=`detect_os`

if [ $? != 0 ]; then
	print_error "Sorry, you appear to be running an Unknown OS. Aborting..."	exit 1
fi

print_info "You appear to be running ${OS}"

case "$OS" in
	$OS_MAC)
		source os/mac.sh || exit 1
		;;
	$OS_UBUNTU)
		source os/ubuntu.sh || exit 1
		;;
	*)
		print_error "Sorry, ${OS} is not yet supported, but is planned for the future. Aborting..."
		;;
esac


echo
echo "[Setup complete!]"
print_success "You're ready to Work!"
echo

if [[ $OS == $OS_UBUNTU ]]; then
    print_info "You must restart."
else
    print_info "Please start a *new* terminal."
fi
