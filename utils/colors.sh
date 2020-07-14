#!/bin/bash

txtred='\033[0;31m'
txtgreen='\033[0;32m'
txtyellow='\033[0;33m'
txtlightblue='\033[1;36m'

txtrst='\033[0m'    # Text Reset


print_error () {
    printf "${txtred}${1}${txtrst}\n"
}

print_warning () {
    printf "${txtyellow}${1}${txtrst}\n"
}

print_info () {
    printf "${txtlightblue}${1}${txtrst}\n"
}

print_success () {
    printf "${txtgreen}${1}${txtrst}\n"
}

