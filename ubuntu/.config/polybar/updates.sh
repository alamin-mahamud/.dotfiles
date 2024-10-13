#!/bin/sh

for a in $(ls /bin); do
  case $a in
    xbps-install) b=$(xbps-install -Mun | wc -l);;
    pacman) b=$(pacman -Qu | wc -l);;
    apt) b=$(apt list --upgradable 2>/dev/null | wc -l);;
  esac
done

if [ "$b" -ne "0" ]; then
  printf "";
fi
