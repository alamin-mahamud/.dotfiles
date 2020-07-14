#!/bin/zsh


check_installation_of()
{
    if [ $? != 0 ];then
        echo "Installation of $1 failed. Exiting..."
        exit 1
    fi
}
