#!/bin/bash

# By @m4lal0

# Regular Colors
Black='\033[0;30m'      # Black
Red='\033[0;31m'        # Red
Green='\033[0;32m'      # Green
Yellow='\033[0;33m'     # Yellow
Blue='\033[0;34m'       # Blue
Purple='\033[0;35m'     # Purple
Cyan='\033[0;36m'       # Cyan
White='\033[0;97m'      # White
Color_Off='\033[0m'     # Text Reset

# Additional colors
LGray='\033[0;37m'      # Ligth Gray
DGray='\033[0;90m'      # Dark Gray
LRed='\033[0;91m'       # Ligth Red
LGreen='\033[0;92m'     # Ligth Green
LYellow='\033[0;93m'    # Ligth Yellow
LBlue='\033[0;94m'      # Ligth Blue
LPurple='\033[0;95m'    # Light Purple
LCyan='\033[0;96m'      # Ligth Cyan

# Bold
BBlack='\033[1;30m'     # Black
BGray='\033[1;37m'		# Gray
BRed='\033[1;31m'       # Red
BGreen='\033[1;32m'     # Green
BYellow='\033[1;33m'    # Yellow
BBlue='\033[1;34m'      # Blue
BPurple='\033[1;35m'    # Purple
BCyan='\033[1;36m'      # Cyan
BWhite='\033[1;37m'     # White

# Underline
UBlack='\033[4;30m'     # Black
UGray='\033[4;37m'		# Gray
URed='\033[4;31m'       # Red
UGreen='\033[4;32m'     # Green
UYellow='\033[4;33m'    # Yellow
UBlue='\033[4;34m'      # Blue
UPurple='\033[4;35m'    # Purple
UCyan='\033[4;36m'      # Cyan
UWhite='\033[4;37m'     # White

# Background
On_Black='\033[40m'     # Black
On_Red='\033[41m'       # Red
On_Green='\033[42m'     # Green
On_Yellow='\033[43m'    # Yellow
On_Blue='\033[44m'      # Blue
On_Purple='\033[45m'    # Purple
On_Cyan='\033[46m'      # Cyan
On_White='\033[47m'     # White

trap ctrl_c INT

function ctrl_c(){
    echo -e "\n\n${Cyan}[${BYellow}!${Cyan}] ${BRed}Saliendo de la aplicación...${Color_Off}"
    rm -rf targets/$TARGET
    tput cnorm
    exit 1
}

### Panel de Ayuda
function helpPanel(){
    echo -e "\n${Cyan}[${BYellow}!${Cyan}]${BGray} Uso:${Color_Off}"
    echo -e "\t${BGreen}./autoRecon -t <IP_or_Domain>${Color_Off}"
    echo -e "\n${BGray}OPCIONES:${Color_Off}"
    echo -e "\t${Cyan}[${BRed}-t, --target${Cyan}]${BPurple} \tDirección IP ó Dominio del objetivo.${Color_Off}"
    echo -e "\t${Cyan}[${BRed}-h, --help${Cyan}]${BPurple} \tMostrar este panel de ayuda.${Color_Off}"
    echo -e "\n${BGray}EJEMPLOS:${Color_Off}"
    echo -e "\t${LGray}Auto-reconocimiento a una Dirección IP${Color_Off}${Green}\n\t# bash autoRecon.sh ${Red}-t <IP-Address>\n${Color_Off}"
    echo -e "\t${LGray}Auto-reconocimiento a un Dominio${Color_Off}${Green}\n\t# bash autoRecon.sh ${Red}--target <Domain>\n${Color_Off}"
    tput cnorm; exit 0
}

### Banner
function banner(){
    echo -e "${BRed}"
    sleep 0.15 && echo -e "               __         __________                             "
    sleep 0.15 && echo -e "_____   __ ___/  |_  ____ \______   \ ____   ____   ____   ____  "
    sleep 0.15 && echo -e "\__  \ |  |  \   __\/ __ \ |       _// __ \_/ ___\ / __ \ /    \ "
    sleep 0.15 && echo -e " / __ \_  |  /|  | (  \_\ )|    |   \  ___/_  \___(  \_\ )   |  \\"
    sleep 0.15 && echo -e "(____  /____/ |__|  \____/ |____|_  /\___  /\___  /\____/|___|  /"
    sleep 0.15 && echo -e "     \/                           \/     \/     \/            \/ "
    echo -e "${Color_Off}"
	sleep 0.15 && echo -e "\t${Blue}---[ Github: https://github.com/m4lal0/autoRecon.git ]--- ${Color_Off}"
    sleep 0.15 && echo -e "\t\t\t\t${Blue} +--==[ By @m4lal0 ]==-- +${Color_Off}\n\n"
	tput civis
}

### Funciones informativos
function info(){
	echo -e "${Cyan}[${BYellow}!${Cyan}] ${LYellow}$1${Color_Off}"
}

function data(){
    echo -e "${Cyan}[${BBlue}+${Cyan}] ${BBlue}$1: ${BGray}$2"
}

function error(){
	echo -e "${Cyan}[${BRed}✘${Cyan}] ${BRed}Error - $1${Color_Off}"
	exit 1; tput cnorm
}

function good(){
	echo -e "\n${Cyan}[${BGreen}✔${Cyan}] ${BGreen}Exitoso - $1${Color_Off}\n"
}

function check(){
	if [ $? -ne 0 ]; then 
		error "$1"
	else
		good "$1"
	fi
}

function section(){
	echo -e "${Cyan}[${BBlue}+${Cyan}] ${BBlue}$1${Color_Off}"
}

function checkDependencies(){
    dependencies=(nmap wafw00f whatweb nikto gobuster ffuf searchsploit sslscan jq)
    info "Comprobando herramientas necesarias..."
    for program in "${dependencies[@]}"; do
        echo -ne "${Cyan}[${BPurple}*${Cyan}] ${LPurple}Herramienta $program...${Color_Off}"
        command -v $program > /dev/null 2>&1
        if [ "$(echo $?)" == "0" ]; then
            echo -e "${Cyan}($BGreen✔${Cyan})${Color_Off}"
        else
            echo -e "${Cyan}(${BRed}✘${Cyan})${Color_Off}"
            echo -e "${Cyan}[${BYellow}!${Cyan}] ${LYellow}Instalando herramienta ${BGreen}$program...${Color_Off}"
            apt-get install $program -y > /dev/null 2>&1
        fi; sleep 1
    done
}

### Revisando conexión a Internet
function checkInternet(){
	info "Comprobando conexión a internet"
	host www.google.com > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		error "En la resolución DNS - no se pudo resolver www.google.com"
		exit 1; tput cnorm
    else
        good "Con conexión a Internet"
	fi
}

function createDirectories(){
    if [ ! -d "targets/$TARGET/services" ]; then
        mkdir -p targets/$TARGET/services &> /dev/null
    fi
    if [ ! -d "targets/$TARGET/scans" ]; then
        mkdir -p targets/$TARGET/scans &> /dev/null
    fi
    if [ ! -d "targets/$TARGET/vulns" ]; then
        mkdir -p targets/$TARGET/vulns &> /dev/null
    fi
}

function validations(){
### Validación de ejecución con root
	if [ "$EUID" -ne 0 ]; then
		error "Este script debe ser ejecutado por r00t!\n"
	fi
    echo -e "\n\t${BBlue}OBJETIVO: ${BGray}$TARGET${Color_Off}\n"
    checkInternet
    checkDependencies
}