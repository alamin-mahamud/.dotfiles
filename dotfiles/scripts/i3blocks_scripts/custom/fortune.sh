#!/bin/bash
fort=`fortune -n 40 -s | sed ':a;N;$!ba;s/\n/ /g' | tr -s ' ' | sed "s/\"/'/g"`
echo $fort
