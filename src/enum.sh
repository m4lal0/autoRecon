#!/bin/bash

# By @m4lal0


function nmap_enum(){
    ports_tcp="$(cat targets/$TARGET/scans/TCPports.gnmap | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
    nmap -sV -sC -p$ports_tcp $TARGET -oN nmap_vulns &>/dev/null
    data "Archivo de vulnerabilidades con Nmap" "nmap_vulns -> (targets/$TARGET/vulns/nmap_vulns)"
}

function searchsploit_enum(){
    searchsploit -j --nmap targets/$TARGET/scans/TCPVersions.xml > targets/$TARGET/services/searchsploit_nmap 2>/dev/null
    cat targets/$TARGET/services/searchsploit_nmap | jq >> targets/$TARGET/vulns/searchsploit_nmap.json 2>/dev/null
    rm targets/$TARGET/services/searchsploit_nmap &> /dev/null
    data "Archivo Searchsploit" "searchsploit_nmap.json -> (targets/$TARGET/vulns/searchsploit_nmap.json)"
}

function ftp_enum(){
    ports_ftp=$(cat targets/$TARGET/services/ftp_found | cut -d ' ' -f1 | awk '{print $1}' FS='/' | xargs | tr ' ' ',')
    nmap -sV -p$ports_ftp --script=ftp-anon,ftp-bounce,ftp-libopie,ftp-proftpd-backdoor,ftp-vsftpd-backdoor,ftp-vuln-cve2010-4221,ftp-syst $TARGET | tee -a targets/$TARGET/vulns/ftp_vulns &>/dev/null
    if [ $? -eq 0 ]; then
        data "Archivo de vulnerabilidades FTP" "ftp_vulns -> (targets/$TARGET/vulns/ftp_vulns)"
    fi
}

function ssh_enum(){
    ports_ssh=$(cat targets/$TARGET/services/ssh_found | cut -d ' ' -f1 | awk '{print $1}' FS='/' | xargs | tr ' ' ',')
    nmap -sV -p$ports_ssh --script=ssh-auth-methods,ssh2-enum-algos,sshv1 $TARGET | tee -a targets/$TARGET/vulns/ssh_vulns &>/dev/null
    if [ $? -eq 0 ]; then
        data "Archivo de vulnerabilidades SSH" "ssh_vulns -> (targets/$TARGET/vulns/ssh_vulns)"
    fi
}

function smtp_enum(){
    cat targets/$TARGET/services/smtp_found | cut -d ' ' -f1 | awk '{print $1}' FS='/' | xargs | tr ' ' ',' > targets/$TARGET/services/smtp_tmp 2> /dev/null
    for port_smtp in $(cat targets/$TARGET/services/smtp_tmp); do
        smtp-user-enum -M VRFY -U /usr/share/metasploit-framework/data/wordlists/unix_users.txt -t TARGET -p $ports_smtp | tee -a targets/$TARGET/vulns/smtp_vulns &>/dev/null
    done
    if [ $? -eq 0 ]; then
        data "Archivo de vulnerabilidades SMTP" "smtp_vulns -> (targets/$TARGET/vulns/smtp_vulns)"
        rm targets/$TARGET/services/smtp_tmp &> /dev/null
    fi
}

function pop3_enum(){
    ports_pop3=$(cat targets/$TARGET/services/pop3_found | cut -d ' ' -f1 | awk '{print $1}' FS='/' | xargs | tr ' ' ',')
    nmap -sV -p$ports_pop3 --script=pop3-brute $TARGET | tee -a targets/$TARGET/vulns/pop3_vulns &>/dev/null
    if [ $? -eq 0 ]; then
        data "Archivo de vulnerabilidades POP3" "pop3_vulns -> (targets/$TARGET/vulns/pop3_vulns)"
    fi
}

function rpc_enum(){
    ports_rpc=$(cat targets/$TARGET/services/rpc_found | cut -d ' ' -f1 | awk '{print $1}' FS='/' | xargs | tr ' ' ',')
    nmap -sV -p$ports_rpc --script=rpcinfo $TARGET | tee -a targets/$TARGET/vulns/rpc_vulns &>/dev/null
    if [ $? -eq 0 ]; then
        data "Archivo de vulnerabilidades RPC" "rpc_vulns -> (targets/$TARGET/vulns/rpc_vulns)"
    fi
}

function nfs_enum(){
    ports_nfs=$(cat targets/$TARGET/services/nfs_found | cut -d ' ' -f1 | awk '{print $1}' FS='/' | xargs | tr ' ' ',')
    nmap -sV -p$ports_nfs --script=nfs* $TARGET | tee -a targets/$TARGET/vulns/nfs_vulns &>/dev/null
    if [ $? -eq 0 ]; then
        data "Archivo de vulnerabilidades NFS" "nfs_vulns -> (targets/$TARGET/vulns/nfs_vulns)"
    fi
}

function dns_enum(){
    host $TARGET > targets/$TARGET/vulns/dns_vulns 2>/dev/null
    host -t mx $TARGET >> targets/$TARGET/vulns/dns_vulns 2>/dev/null
    host -t txt $TARGET >> targets/$TARGET/vulns/dns_vulns 2>/dev/null
    host -t ns $TARGET >> targets/$TARGET/vulns/dns_vulns 2>/dev/null
    host -t ptr $TARGET >> targets/$TARGET/vulns/dns_vulns 2>/dev/null
    host -t cname $TARGET >> targets/$TARGET/vulns/dns_vulns 2>/dev/null
    host -t a $TARGET >> targets/$TARGET/vulns/dns_vulns 2>/dev/null
    data "Archivo de reconocimiento DNS" "dns_vulns -> (targets/$TARGET/vulns/dns_vulns)"
    dnsenum --enum $TARGET > targets/$TARGET/vulns/dns_enum_vulns 2>/dev/null
    data "Archivo de DNS-Enum" "dns_enum_vulns -> (targets/$TARGET/vulns/dns_enum_vulns)"
    dnsrecon -d $TARGET > targets/$TARGET/vulns/dns_recon_vulns 2>/dev/null
    data "Archivo de DNS-Enum" "dns_recon_vulns -> (targets/$TARGET/vulns/dns_recon_vulns)"
}

function http_enum(){
    info "Enumeración HTTP"
    ports_http=$(cat targets/$TARGET/services/http_found | cut -d ' ' -f1 | awk '{print $1}' FS='/' | xargs | tr ' ' ',')
    section "Nikto"
    nikto -ask=no -h $TARGET:$ports_http -T 123b | tee -a targets/$TARGET/vulns/nikto_vulns 2>/dev/null
    data "Resultado guardado de Nikto" "nikto_vulns -> (targets/$TARGET/vulns/nikto_vulns)"
    section "SSLScan"
    sslscan --show-certificate $TARGET:$ports_http | tee -a targets/$TARGET/vulns/ssl_vulns 2>/dev/null
    data "Resultado guardado de SSL" "ssl_vulns -> (targets/$TARGET/vulns/ssl_vulns)"
    extensions=$(echo 'index' >./index && ffuf -s -w ./index:FUZZ -mc '200' -e '.asp,.aspx,.html,.jsp,.php' -u http://${TARGET}:$ports_http/FUZZ 2>/dev/null | awk -F 'index' {'print $2'} | tr '\n' ',' | head -c-1 && rm ./index)
    section "Sitio Principal"
    curl_extension=$(echo $extensions | tr -d ',')
    curl -sSiK $TARGET:$ports_http | tee -a targets/$TARGET/vulns/curl_home_vulns
    data "Resultado guardado del sitio principal index$curl_extension" "curl_home_vulns -> (targets/$TARGET/vulns/curl_home_vulns)"
    section "Archivo robots.txt"
	curl -sSik $TARGET:$ports_http/robots.txt | tee -a targets/$TARGET/vulns/curl_robots_vulns
    data "Resultado guardado de robots.txt" "curl_robots_vulns -> (targets/$TARGET/vulns/curl_robots_vulns)"
    section "Reconocimiento de tecnologias del sitio"
    whatweb -a3 $TARGET:$ports_http 2>/dev/null | tee -a targets/$TARGET/vulns/whatweb_vulns
    data "Resultado guardado de Whatweb" "whatweb_vulns -> (targets/$TARGET/vulns/whatweb_vulns)"
    section "Detectar WAF del sitio"
    wafw00f http://$TARGET | tee -a targets/$TARGET/vulns/wafw00f_vulns
    data "Resultado guardado de wafw00f" "wafw00f_vulns -> (targets/$TARGET/vulns/whatweb_vulns)"
    section "Fuerza bruta de archivos con la extensión $extensions con ffuf"
    ffuf -ic -w /usr/share/wordlists/dirb/common.txt -e '$extensions' -u http://${TARGET}:$ports_http/FUZZ | tee targets/$TARGET/vulns/ffuf_extensions_vulns
    data "Resultado guardado con ffuf" "ffuf_extensions_vulns -> (targets/$TARGET/vulns/ffuf_extensions_vulns)"
    section "Fuerza bruta en directorios con Gobuster"
    gobuster dir -re -t 65 -u http://$TARGET:$ports_http -w /usr/share/wordlists/dirbuster/directory-list-2.3-small.txt -o targets/$TARGET/vulns/gobuster_vulns -k
    data "Resultado guardado de Gobuster" "gobuster_vulns -> (targets/$TARGET/vulns/gobuster_vulns)"
}