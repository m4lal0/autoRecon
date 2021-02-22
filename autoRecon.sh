#!/bin/bash

# By @m4lal0

source src/func.sh
source src/scans.sh
source src/enum.sh

clear
banner

### Opciones
arg=""
for arg; do
	delim=""
	case $arg in
		--target)	args="${args}-t";;
		--help)		args="${args}-h";;
		*) [[ "${arg:0:1}" == "-" ]] || delim="\""
        args="${args}${delim}${arg}${delim} ";;
	esac
done

eval set -- $args

declare -i parameter_counter=0; while getopts ":t:h" opt; do
    case $opt in
        t) TARGET=$OPTARG && let parameter_counter+=1 ;;
        h|*) helpPanel ;;
    esac
done

if [ $parameter_counter -eq 0 ]; then
    helpPanel
else
    validations
    mainScans
fi