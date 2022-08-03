
#!/bin/bash
clear

if [ ! -d ./aux ]
then
	mkdir ./aux
fi

if [ ! -d ./prev ]
then
	mkdir ./prev
fi

if [ ! -d ./escaneos ]
then
	mkdir ./escaneos
fi

touch ./aux/lista_ips.txt
touch ./aux/tiempo_reg.txt
touch ./aux/ip_h.txt

error_msg=""
t_actual=$(date +%s)
fecha=$(date +%d-%m-%Y)
hora=$(date +%H-%M)
t_reg=0
version=1
fecha_v="08_2022"

if [ -s ./aux/tiempo_reg.txt ]
then
	t_reg=$(cat ./aux/tiempo_reg.txt)
else
	t_reg=0
fi





#### Funciones Auxiliares ####
#---Formatos del texto
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

#----
banner()
{	
	clear
	printf "%1s\n" "${BRIGHT}----------------------------------------------${NORMAL}"
	printf "%1s\n" "${LIME_YELLOW}                 Escaneo Remoto v${version}${NORMAL}"
	printf "%1s\n" "${BRIGHT}-- $fecha ----------------------- $hora --${NORMAL}"
	echo ""
	
}

#----
#parámetro 1: rango
buscar_h()
{
	ip_l=$(nmap -sP $1 >/dev/null && arp -an)
	echo "$ip_l">./aux/lista_ips.txt
	date +%s>./aux/tiempo_reg.txt #Se registra el tiempo UNIX de la búsqueda
}

# # # # # # # # # # # # # # # 
banner
mac_disp=$(cat ./dispositivo.txt)
echo "Obteniendo los parámetros de la red..."
echo "Por favor espere..."
ip_local=$(ip addr |sed -e 's/^[ \t]*//'| grep -e "inet[^6]"|cut -d" " -f2|grep -v 127.0.0.1)
ip_parte1=$(echo $ip_local|cut -d"." -f1,2,3)
ip_parte2=$(echo $ip_local|cut -d"/" -f2)
ip_rango="$ip_parte1.0/$ip_parte2"


opcion=1
ult_reg=$(expr $t_actual - $t_reg)
while  [ $opcion -ne 0 ]
	do  
        banner		
		
		echo ""
		if [ $ult_reg -le 86400 ]
		then
			printf "%1s\n" "${RED}ATENCIÓN:${NORMAL}"
			echo "El último registro de uso es de hace menos de 24 horas."
			echo "No es necesario buscar en la red..."
			echo "...a no ser que tenga problemas."
			echo ""
			printf "%1s\n" "${YELLOW}¿Buscar en la red de todas maneras?${NORMAL}"
			echo ""
			echo "Si - Presione S y ENTER"
			echo "No - Presione N y ENTER"
			read opcion
			case $opcion in
				[Ss])
					ult_reg=86401
					opcion=1
					;;
				[Nn])
					opcion=0
					break
					;;
				*)
					opcion=1
					;;
			esac
		else
			banner
			printf "%1s\n" "${WHITE}-----------------${NORMAL}"
			printf "%1s\n" "${LIME_YELLOW}    Escaneo de Red${NORMAL}"
			printf "%1s\n" "${WHITE}-----------------${NORMAL}"
			echo ""
			echo "Rango de red local: $ip_rango"
			echo "Ubicando la PC con el escaner: $mac_disp"
			buscar_h "$ip_rango" & PID=$! #simulate a long process
			echo "Por favor espere..."
			printf "["
			# While process is running...
			while kill -0 $PID 2> /dev/null; do 
				printf  "▓"
				sleep 1
			done
			printf "]"
			echo "Búsqueda Completa"
			#Código de animación de espera tomado del usuario cosbor11 de stackoverflow.com
			#Obtenido de https://stackoverflow.com/questions/12498304/using-bash-to-display-a-progress-indicator
			opcion=0
		fi
	done
#------




#ip_h1=$(cat ./aux/lista_ips.txt)
#$(nmap -sP $ip_rango >/dev/null && arp -an)
ip_h2=$(cat ./aux/lista_ips.txt|grep -c "$mac_disp")
#$(echo "$ip_h1"|grep -c "$mac_disp")



if [ $ip_h2 -eq 1 ]
then
	echo 
	ip_h=$(cat ./aux/lista_ips.txt|grep "$mac_disp"|awk '{print $2}'|sed 's/[()]//g')
	#$(echo "$ip_h1"|grep "$mac_disp"|awk '{print $2}'|sed 's/[()]//g')


    opcion=1
    while  [ $opcion -ne 0 ]
	do  
        banner
        echo "Se ubicó la PC con el escaner en la IP: $ip_h"
		echo ""
		printf "%1s\n" "${WHITE}-----------------${NORMAL}"
		printf "%1s\n" "${LIME_YELLOW}    OPCIONES${NORMAL}"
		printf "%1s\n" "${WHITE}-----------------${NORMAL}"
        echo "Elija una opción y presione ENTER:"
		echo ""
	    echo "    P - Generar una vista previa del escaneo"
        echo "    E - Escanear el documento"
		echo "    A - Abrir carpeta de imágenes escaneadas"
		echo ""
        printf "%1s\n" "${RED}    S - Salir del programa${NORMAL}"
		printf "%1s\n" "${POWDER_BLUE}    I - Información sobre este programa${NORMAL}"     

        read opcion
        case $opcion in

			[Aa])
				banner
				echo "LanScan versión ${version}, ${fecha_v}"
				echo "Desarrollado por el docente Luis Sebastián de los Ángeles"
				echo ""
				echo "Todo el código de esta aplicación se encuentra bajo licencia MIT"
				echo ""
				read ok
				;;
			
			[Pp])
                banner
                echo "Se generará un escaneo rápido de vista previa."
				printf "%1s\n" "${RED}Presione ENTER para comenzar${NORMAL}"                
				echo ""
                read ok
                echo "Por favor espere..."
                
                echo "Limpiando directorios de previsualización remotos y locales..."
                rm ./prev/*
                ssh -oStrictHostKeyChecking=no usuario@$ip_h "rm /home/usuario/escaneos/prev.pn?"
                echo "Escaneando..."                
                ssh usuario@$ip_h "scanimage --progress --mode 'Color' --resolution '50'>/home/usuario/escaneos/prev.pnm"
                echo "Convirtiendo y obteniendo imágenes..."
                ssh usuario@$ip_h "convert /home/usuario/escaneos/prev.pnm /home/usuario/escaneos/prev.png"
                scp usuario@$ip_h:/home/usuario/escaneos/prev.png ./prev/prev.png
				xdg-open ./prev/prev.png
				opcion=1
				;;
			[Ee])
				banner
				modoE=0
				while  [ $modoE -eq 0 ]
				do
					echo ""
					printf "%1s\n" "${BRIGHT}    Escaneo de página completa${NORMAL}"
					echo ""
					
					printf "%1s\n" "${WHITE}----------------------------${NORMAL}"
					printf "%1s\n" "${LIME_YELLOW}    1) Modo de Escaneo${NORMAL}"
					printf "%1s\n" "${WHITE}----------------------------${NORMAL}"
					echo ""
					echo "    Elija una opción y presione ENTER:"
					echo ""
					echo "    C - Escaneo en Color"
					echo "    B - Escaneo en Blanco y Negro (Escala de Grises)"
					echo "    T - Escaneo en modo Texto (Monocromático)"
					printf "%1s\n" "${RED}    X - Cancelar y volver al menú principal${NORMAL}"
					read modoE

					case $modoE in
					[cC])
						modoE="Color"
						;;
					[bB])
						modoE="Grayscale"
						;;
					[tT])
						modoE="Monochrome"
						;;
					[xX])
						modoE=1
						;;
					*)
						modoE=0
						clear
						banner
						;;
					esac						
				done
				
				#Paso 2 - Resolución del escaneo
				banner
				res=0
				while  [ $res -eq 0 ]
				do
					echo ""
					printf "%1s\n" "${BRIGHT}    Escaneo de página completa${NORMAL}"
					printf "%1s\n" "${BRIGHT}    Modo: $modoE${NORMAL}"					
					echo ""
					
					printf "%1s\n" "${WHITE}----------------------------${NORMAL}"
					printf "%1s\n" "${LIME_YELLOW}    2) Resolución${NORMAL}"
					printf "%1s\n" "${WHITE}----------------------------${NORMAL}"
					echo ""
					echo "    Elija una opción y presione ENTER:"
					echo ""
					echo "    1 - Baja (150 ppp)"
					echo "    2 - Media (200 ppp)"
					echo "    3 - Alta (300 ppp)"
					echo "    4 - Muy Alta (500 ppp)"
					printf "%1s\n" "${RED}    X - Cancelar y volver al menú principal${NORMAL}"
					read res

					case $res in
					1)
						res="150"
						;;
					2)
						res="200"
						;;
					3)
						res="300"
						;;
					4)
						res="500"
						;;
					[xX])
						res=5
						;;
					*)
						res=0
						clear
						banner
						;;
					esac						
				done
				
				#paso 3 - Prefijo del nombre de archivo
				
				banner
				pref=0
				while  [ $pref -eq 0 ]
				do
					echo ""
					printf "%1s\n" "${BRIGHT}    Escaneo de página completa${NORMAL}"
					printf "%1s\n" "${BRIGHT}    Modo: $modoE  Resolución: $res ppp ${NORMAL}"					
					echo ""
					
					printf "%1s\n" "${WHITE}----------------------------${NORMAL}"
					printf "%1s\n" "${LIME_YELLOW}    3) Prefijo del Nombre de Archivo${NORMAL}"
					printf "%1s\n" "${WHITE}----------------------------${NORMAL}"
					echo ""
					echo "    ¿Desea un prefijo para el nombre del archivo resultante?"
					echo ""
					echo "    Todos los archivos generados incluyen fecha, hora y marca "
					echo "    de tiempo en su nombre de archivo, pero puede indicar un "
					echo "    prefijo para incluir en el nombre del mismo."
					echo ""
					echo "    Si - Presione S y ENTER"
					echo "    No - Presione N y ENTER"
					printf "%1s\n" "${RED}    X - Cancelar y volver al menú principal${NORMAL}"
					read pref

					case $pref in
					[sS])
						banner
						echo ""
						printf "%1s\n" "${BRIGHT}    Escaneo de página completa${NORMAL}"
						printf "%1s\n" "${BRIGHT}    Modo: $modoE  Resolución: $res ppp ${NORMAL}"					
						echo ""
					
						printf "%1s\n" "${WHITE}----------------------------${NORMAL}"
						printf "%1s\n" "${LIME_YELLOW}    3) Prefijo del Nombre de Archivo${NORMAL}"
						printf "%1s\n" "${WHITE}----------------------------${NORMAL}"
						echo ""
						printf "%1s\n" "${WHITE}    Escriba un prefijo para el nombre de archivo${NORMAL}"
						printf "%1s\n" "${WHITE}    y presione ENTER:${NORMAL}"
						echo ""
						read pref						
						;;
					[nN])
						pref=""
						;;
					[xX])
						pref=5
						;;
					*)
						pref=0
						clear
						banner
						;;
					esac						
				done
				
				banner
				printf "%1s\n" "${BRIGHT}    Escaneo de página completa${NORMAL}"
				printf "%1s\n" "${BRIGHT}    Modo: $modoE  Resolución: $res ppp ${NORMAL}"
				#if [ -z "$pref" ]
				#then
					printf "%1s\n" "${BRIGHT}    Prefijo del nombre de archivo: $pref ${NORMAL}"
				#fi					
				echo ""
				printf "%1s\n" "${RED}Presione ENTER para comenzar${NORMAL}"                
				echo ""
                read ok
				echo "Por favor espere..."
                
                echo "Limpiando directorios de previsualización remotos y locales..."
                rm ./prev/*
                ssh -oStrictHostKeyChecking=no usuario@$ip_h "rm /home/usuario/escaneos/*.pnm"
                echo "Escaneando..."                
								
				archivo="$fecha-$hora-$t_actual"
                ssh usuario@$ip_h "scanimage --progress --mode '$modoE' --resolution '$res'>/home/usuario/escaneos/$archivo.pnm"
                echo "Convirtiendo y obteniendo imágenes..."
                ssh usuario@$ip_h "convert /home/usuario/escaneos/$archivo.pnm /home/usuario/escaneos/$archivo.png"
                scp usuario@$ip_h:"/home/usuario/escaneos/$archivo.png" "./escaneos/$pref-$archivo.png"
				xdg-open "./escaneos/$pref-$archivo.png"
				

				opcion=1
				;;
			[Ss])
				banner
				printf "%1s\n" "${RED}    ATENCIÓN:${NORMAL}"
				printf "%1s\n" "${RED}    ¿Desea cerrar el programa?${NORMAL}"
				echo ""
				echo "    Si - Presione S y ENTER"
				echo "    No - Presione N y ENTER"
				read opcion
				case $opcion in
					[Ss])
						break
						;;
					[Nn])
						opcion=1
						;;
					*)
						opcion=1
						;;
				esac
				;;
			*)
				opcion=1
				;;
		esac
        
    done    
else
	opcion=1
	while  [ $opcion -ne 0 ]
	do
		banner

		printf "%1s\n" "${RED}    ERROR: No pudo ubicar la PC con el escaner en la red local.${NORMAL}"
		printf "%1s\n" "${YELLOW}    Verifique si se encuentra encendida.${NORMAL}"
		echo ""		
		echo "    ¿Desea repetir la búsqueda?" 
		echo "    Seleccione una opción y luego presione ENTER"
		echo ""
		echo "    SI                        - Presione S"
		echo "    NO (y salir del programa) - Presione N"
		read opcion
		case $opcion in
			[Ss])
				opcion=0
				bash $0
				;;
			[Nn])
				opcion=0
				;;
			*)
				opcion=1
				;;
		esac
	done
fi
clear



