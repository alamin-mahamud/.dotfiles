#!/bin/zsh


export OS_MAC="macOS"
export OS_UBUNTU="Ubuntu"
export OS_WINDOWS="Windows"
export OS_UNKNOWN="Unknown"


function detect_os() {
	OS=$OS_UNKNOWN
	FOUND=1

	case "$(uname -s)" in
		Darwin*)
			OS=$OS_MAC
			FOUND=0
			;;
		Linux)
			if ! hash lsb_release 2> /dev/null; then
				OS=$OS_UNKNOWN
			fi
			
			DISTRO=`lsb_release -i`
			IS_UBUNTU=`echo $DISTRO | grep -o 'Ubuntu'`
			
			if [[ $IS_UBUNTU -eq "Ubuntu" ]]; then
				OS=$OS_UBUNTU
				FOUND=0
			fi
			;;
		CYGWIN*|MINGW32*|MSYS*)
			OS=$OS_WINDOWS
			FOUND=0
			;;
	esac
	
	echo $OS
	return $FOUND
}

