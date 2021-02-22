# autoRecon

[![GitHub top language](https://img.shields.io/github/languages/top/m4lal0/autoRecon?logo=gnu-bash&style=flat-square)](#)
[![GitHub repo size](https://img.shields.io/github/repo-size/m4lal0/autoRecon?logo=webpack&style=flat-square)](#)
[![Kali Linux Supported](https://img.shields.io/badge/Kali_Linux_2020-Supported-blue?style=flat-square&logo=linux)](#)
[![By](https://img.shields.io/badge/By-m4lal0-green?style=flat-square&logo=github)](#)

```
               __         __________                             
_____   __ ___/  |_  ____ \______   \ ____   ____   ____   ____  
\__  \ |  |  \   __\/ __ \ |       _// __ \_/ ___\ / __ \ /    \ 
 / __ \_  |  /|  | (  \_\ )|    |   \  ___/_  \___(  \_\ )   |  \
(____  /____/ |__|  \____/ |____|_  /\___  /\___  /\____/|___|  /
     \/                           \/     \/     \/            \/ 
```

autoRecon es una herramienta de reconocimiento que realiza una enumeración automática de los servicios descubiertos. Construí esto para poner en práctica algunas herramientas que he usado durante los CTF y los entornos de prueba que realizo.

## ¿Cómo trabaja?
autoRecon primero verifica si hay conexión con el objetivo, después ejecuta un escaneo con la herramienta nmap, para descubrir los puertos abiertos tanto TCP como UDP, una vez descubiertos. Una vez finalizado el escaneo, identifica los servicios que corre en cada puerto abierto para posteriormente realizar una enumeración activando una serie de herramientas y creando archivos para ese servicio ( eas decir, si detecta el servicio http, ejecutará herramientas como nikto, wafw00f, ffuf, otros). Por cada servicio detectado, autoRecon crea un archivo del resultado de cada herramientas utilizada.

## Instalación y uso
```
git clone https://github.com/m4lal0/autoRecon.git
cd autoRecon ; chmod +x autoRecon
./autoRecon -t <IP>
```

La herramienta cuenta con un menu de ayuda. Para ejecutar la herramienta es necesario colocar el parámetro "**-t**" y despues la dirección IP o dominio del objetivo a escanear.


## Dependencias.
Si utiliza Kali Linux ó Parrot es posible que ya tenga instalado de forma predeterminada ciertas herramientas que utiliza la herramienta, si no es asi, no se preocupe, autoRecon reconoce las herramientas que no están instaladas y las instala por usted.

+ nmap
+ nikto
+ gobuster
+ ffuf
+ whatweb
+ dnsenum
+ dnsrecon
+ sslscan
+ wafw00f
+ searchsploit
+ tput
+ jq