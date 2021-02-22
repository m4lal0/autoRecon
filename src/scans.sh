#!/bin/bash

# By @m4lal0

function GetOS(){
    echo -e ""
    info "Iniciando Escaneo del objetivo"
    TTL=$(ping -c 1 $TARGET | grep "ttl" | awk '{print $6}' | cut -d '=' -f2 2> /dev/null)
    if [[ "$TTL" -ne 0 ]]; then
        if [[ "$TTL" == 63 ]] || [[ "$TTL" == 64 ]]; then
            data "S.O." "Linux"
        elif [[ "$TTL" == 127 ]] || [[ "$TTL" == 128 ]]; then
            data "S.O." "Windows"
        else
            data "S.O." "Cisco/Solaris/OpenBSD"
        fi
    else
        error "No hay conexión con el objetivo"
    fi
}

function Nmap_TCP(){
    nmap -p- --open -T5 -v -n $TARGET -oA targets/$TARGET/scans/TCPports &> /dev/null
    if [ $? -eq 0 ]; then
        # ports_tcp="$(cat targets/$TARGET/scans/TCPports.gnmap | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
        # services_tcp="$(cat targets/$TARGET/scans/TCPports.gnmap | grep -oP '/tcp//\w*' | awk '{print $2}' FS='//' | xargs | tr ' ' ',')"
        section "Puertos abiertos TCP"
        echo -e "${BGray}"
        cat targets/$TARGET/scans/TCPports.nmap | grep -w "open" | grep -v "Nmap" 2>/dev/null
        echo -e "${Color_Off}"
        # data "Puertos TCP abiertos" "$ports_tcp"
        # data "Servicios encontrados" "$services_tcp"
        nmap -sV -p$ports_tcp $TARGET -oX targets/$TARGET/scans/TCPServices.xml &> /dev/null
    else
        error "Fallo en la consulta con NMAP-TCP"
    fi
}

function Nmap_UDP(){
    nmap -sU --min-rate 5000 -p- --open -Pn -n $TARGET -oA targets/$TARGET/scans/UDPports &> /dev/null
    if [ $? -eq 0 ]; then
        # ports_udp="$(cat targets/$TARGET/scans/UDPports.gnmap | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
        # services_udp="$(cat targets/$TARGET/scans/UDPports.gnmap | grep -oP '/tcp//\w*' | awk '{print $2}' FS='//' | xargs | tr ' ' ',')"
        section "Puertos abiertos UDP"
        echo -e "${BGray}"
        cat targets/$TARGET/scans/UDPports.nmap | grep -w "open" | grep -v "Nmap" 2>/dev/null
        echo -e "${Color_Off}"
        # data "Puertos UDP abiertos" "$ports_udp"
        # data "Servicios encontrados" "$services_udp"
    else
        error "Fallo en la consulta con NMAP-UDP"
    fi
}

function enumGoTo(){
    info "Buscando vulnerabilidades"
    nmap_enum
    searchsploit_enum
    if [[ -s "targets/$TARGET/services/ftp_found" ]]; then
        ftp_enum
    fi
    if [[ -s "targets/$TARGET/services/ssh_found" ]]; then
        ssh_enum
    fi
    if [[ -s "targets/$TARGET/services/smtp_found" ]]; then
        smtp_enum
    fi
    if [[ -s "targets/$TARGET/services/dns_found" ]]; then
        dns_enum
    fi
    if [[ -s "targets/$TARGET/services/rpc_found" ]]; then
        rpc_enum
    fi
    if [[ -s "targets/$TARGET/servicesnfs_found" ]]; then
        nfs_enum
    fi
    if [[ -s "targets/$TARGET/services/pop3_found" ]]; then
        pop3_enum
    fi
    if [[ -s "targets/$TARGET/services/http_found" ]]; then
        http_enum
    fi
    good "Finalizado el Reconocimiento"
}

function IdenServices(){
    cat targets/$TARGET/scans/TCPports.nmap | grep "ftp" | sort -u > targets/$TARGET/services/ftp_found
    cat targets/$TARGET/scans/TCPports.nmap | grep "ssh" | sort -u > targets/$TARGET/services/ssh_found
    cat targets/$TARGET/scans/TCPports.nmap | grep "smtp" | sort -u > targets/$TARGET/services/smtp_found
    cat targets/$TARGET/scans/TCPports.nmap | grep "http" | sort -u > targets/$TARGET/services/http_found
    cat targets/$TARGET/scans/TCPports.nmap | grep -E "domain|dns" | sort -u > targets/$TARGET/services/dns_found
    cat targets/$TARGET/scans/TCPports.nmap | grep -E "rpc|rpcbind" | sort -u > targets/$TARGET/services/rpc_found
    cat targets/$TARGET/scans/TCPports.nmap | grep "pop3" | sort -u > targets/$TARGET/services/pop3_found
    cat targets/$TARGET/scans/TCPports.nmap | grep "nfs" | sort -u > targets/$TARGET/services/nfs_found
    enumGoTo
}

function mainScans(){
    GetOS
    createDirectories
    Nmap_TCP
    Nmap_UDP
    IdenServices
    tput cnorm
}