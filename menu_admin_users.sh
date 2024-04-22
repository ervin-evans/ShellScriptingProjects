#!/bin/bash

# AUTHOR: Ervin Cordova Triano
# DATE: 10-03-2023

# *********************************************************************
#																COLORS
#**********************************************************************
greenColor="\e[0;32m\033[1m"
endColor="\033[0m\e[0m"
redColor="\e[0;31m\033[1m"
blueColor="\e[0;34m\033[1m"
yellowColor="\e[0;33m\033[1m"
purpleColor="\e[0;35m\033[1m"
grayColor="\e[0;37m\033[1m"

trap ctrl_c INT

# *********************************************************************
#																FUNCTIONS
#**********************************************************************
function ctrl_c(){
	echo -e "\n${yellowColor}[*]${endColor} -${purpleColor} Saliendo${endColor}"
	exit 1
}

function printWarningMessage(){
	local message=${1}
	echo -e "${yellowColor}[!] - ${message} ${endColor}"
}
function printErrorMessage(){
	local message=${1}
	echo -e "${redColor}[!!] - ${message} ${endColor}"
}
function printSuccessMessage(){
	local message=${1}
	echo -e "${greenColor}[*] - ${message} ${endColor}"
}
function printTitleMessage(){
	local message=${1}
	echo -e "${purpleColor} ******************************************************************************************** ${endColor}"
	echo -e "\t\t\t\t\t${greenColor} ** ${message} ** ${endColor}"
	echo -e "${purpleColor} ******************************************************************************************** ${endColor}"
	echo
}
function printMessage(){
	local message=${1}
	echo -e "${blueColor}[*] - ${message}${endColor}"
}
function print_menu(){
	clear
	echo
	printBanner
	echo
	echo -e "${yellowColor}[1]${endColor} - ${purpleColor}Agregar usuario${endColor}"
	echo -e "${yellowColor}[2]${endColor} - ${purpleColor}Modificar usuario${endColor}"
	echo -e "${yellowColor}[3]${endColor} - ${purpleColor}Eliminar usuario${endColor}"
	echo -e "${yellowColor}[4]${endColor} - ${purpleColor}Bloquear usuario${endColor}"
	echo -e "${yellowColor}[5]${endColor} - ${purpleColor}Desbloquear usuario${endColor}"
	echo
	echo -e "${redColor}[99] - Salir${endColor}"
	echo
}
function printBanner(){
	echo -e "${greenColor}##::::'##::'######::'########:'########::::::::'###::::'########::'##::::'##:'####:'##::: ##:"
	echo -e "##:::: ##:'##... ##: ##.....:: ##.... ##::::::'## ##::: ##.... ##: ###::'###:. ##:: ###:: ##:"
	echo -e "##:::: ##: ##:::..:: ##::::::: ##:::: ##:::::'##:. ##:: ##:::: ##: ####'####:: ##:: ####: ##:"
	echo -e "##:::: ##:. ######:: ######::: ########:::::'##:::. ##: ##:::: ##: ## ### ##:: ##:: ## ## ##:"
	echo -e "##:::: ##::..... ##: ##...:::: ##.. ##:::::: #########: ##:::: ##: ##. #: ##:: ##:: ##. ####:"
	echo -e "##:::: ##:'##::: ##: ##::::::: ##::. ##::::: ##.... ##: ##:::: ##: ##:.:: ##:: ##:: ##:. ###:"
	echo -e ".#######::. ######:: ########: ##:::. ##:::: ##:::: ##: ########:: ##:::: ##:'####: ##::. ##:"
	echo -e ":.......::::......:::........::..:::::..:::::..:::::..::........:::..:::::..::....::..::::..::${endColor}"
	echo -e "${purpleColor}(by ervin-evans)${endColor}"
}


# *********************************************************************
#								   FUNCTIONS PARA AGREGAR USUARIOS
#**********************************************************************
function add_user(){
	printTitleMessage "AGREGAR USUARIO"
	read -p "Nombre del usuario: " USERNAME
	read -p "Nombre completo del usuario: " FULLNAME
	# Verificar si el usuario ingresado existe
	getent passwd | grep -w ${USERNAME} &> /dev/null
	if [[ ${?} -eq 0 ]]
	then
		printErrorMessage "El usuario ya existe!"
		exit 1
	fi

	if [[ -n ${USERNAME} ]] && [[ -n ${FULLNAME} ]]
	then
		printMessage "Agregando usuario ... "
		sleep 1
		useradd -c "${FULLNAME}" -m ${USERNAME} &> /dev/null
	else
		printMessage "Vamos a  agregar usuario sin detalles"
		sleep 1
		useradd -m ${USERNAME} &> /dev/null
	fi
	if [[ ${?} -eq 0 ]]
	then
		printMessage "Generando password ..."
		sleep 1
		PASSWORD_GENERATED=$(generate_random_password)
		printMessage "El password generado es: ${PASSWORD_GENERATED}"
		echo ${PASSWORD_GENERATED} | passwd --stdin ${USERNAME} &> /dev/null
		passwd -e ${USERNAME} &> /dev/null
		printSuccessMessage "El usuario ${USERNAME} fue agregado con exito al sistema"
	else
		printErrorMessage "Hubo errores al agregar al usuario ${USERNAME} al sistema"
	fi
}

# *********************************************************************
#						FUNCTIONS PARA ELIMINAR UN USUARIO
#**********************************************************************
function delete_user(){
	printMessage "Recuperando usuarios del sistema.."
	echo
	sleep 0.5
	LIST_OF_USERS=$(cat /etc/passwd | cut -d ':' -f 1)
	COUNT=0
	for USER in ${LIST_OF_USERS}
	do
		if [[ $(id -u ${USER}) -ge 1000 ]]
		then
			((COUNT++))
			echo -ne "${yellowColor}[${COUNT}] ${endColor}-${greenColor} ${USER}"
			USERNAME_LENGTH=$(echo ${USER} | wc -m)
			MAX_LENGTH_POINTS=70
			LIST_FROM=0
			if [[ ${COUNT} -lt 10 ]]
			then
				MAX_LENGTH_POINTS=71
			fi
			((LIST_TO=${MAX_LENGTH_POINTS}-${USERNAME_LENGTH}))
			for ((i=${LIST_FROM}; i<=${LIST_TO}; i++))
			do
				echo -n "."
			done
			echo -ne "[ENCONTRADO]${endColor}\n"
		fi
	done
	
	echo
	read -p "Ingresa el USERNAME a eliminar: " USERNAME
	clear
	getent passwd | grep -w ${USERNAME} &> /dev/null
	if [[ ${?} -eq 0 ]]
	then
		# Crear carpeta de respaldo
		BACKUP_FOLDER_PATH=/BACKUPS
		ARCHIVE_NAME="${USERNAME}-$(date +%F).tar"
		if [[ -d ${BACKUP_FOLDER_PATH} ]]
		then
			tar -zcvf "${BACKUP_FOLDER_PATH}/${ARCHIVE_NAME}" "/home/${USERNAME}/" &> /dev/null
			printSuccessMessage "Datos respaldados en ${BACKUP_FOLDER_PATH}/${ARCHIVE_NAME}"
		else
			mkdir ${BACKUP_FOLDER_PATH}
			tar -zcvf "${BACKUP_FOLDER_PATH}/${ARCHIVE_NAME}" "/home/${USERNAME}/" &> /dev/null
			printSuccessMessage "Datos respaldados en ${BACKUP_FOLDER_PATH}/${ARCHIVE_NAME}"
		fi
		printMessage "Eliminando usuario ${USERNAME} ..."
		userdel -r ${USERNAME}
		if [[ ${?} -eq 0 ]]
		then
			printSuccessMessage "El usuario ${USERNAME} ha sido eliminado del sistema con exito!"
			exit 0
		else
			printErrorMessage "No se ha podido eliminar al usuario ${USERNAME}"
			exit 1
		fi
	else
		printErrorMessage "El usuario ${USERNAME} no existe"
		exit 1
	fi
}

# *********************************************************************
#						   FUNCTION PARA BLOQUEAR CUENTA
#**********************************************************************
function lock_account(){
		printMessage "Bloquedar cuenta"
		read -p "Ingrese el USERNAME: " USERNAME
		getent passwd | grep -w ${USERNAME} &> /dev/null
		if [[ ${?} -eq 0 ]]
		then
			printMessage "Inhabilitando cuenta de ${USERNAME}"
			passwd -l ${USERNAME} &> /dev/null
			printSuccessMessage "La cuenta de ${USERNAME} ha sido bloqueda"
			exit 0
		else
			printErrorMessage "El usuario ${USERNAME} NO existe!"
			exit 1
		fi
}

# *********************************************************************
#						   FUNCTION PARA DESBLOQUEAR CUENTA
#**********************************************************************
function unlock_account(){
		printMessage "Desbloquedar cuenta"
		read -p "Ingrese el USERNAME: " USERNAME
		getent passwd | grep -w ${USERNAME}
		if [[ ${?} -eq 0 ]]
		then
			printMessage "Desbloqueand cuenta de ${USERNAME}"
			passwd -u ${USERNAME} &> /dev/null
			printSuccessMessage "La cuenta de ${USERNAME} ha sido desbloqueda"
			exit 0
		else
			printErrorMessage "El usuario ${USERNAME} NO existe!"
			exit 1
		fi
}

# *********************************************************************
#						   FUNCTIONS PARA GENERAR PASSWORS ALEATORIOS
#**********************************************************************

function generate_random_password(){
	echo $(date +%s%N${RANDOM}${RANDOM} | sha256sum | head -c48)
}

# *********************************************************************
#																MAIN TASK
#**********************************************************************
clear
if [[ ${UID} -ne 0 ]]
then
	printErrorMessage "Debes ejecutar el script con SUDO o ROOT"
	exit 1
fi
print_menu
read -p  "Elige una opcion: " CHOOSED_OPTION
case ${CHOOSED_OPTION} in
	1)
		add_user
		;;
	2) echo "Elegiste la option ${CHOOSED_OPTION}"
		;;

	3) 
		delete_user
		;;
	4)
		lock_account
		;;
	5)
		unlock_account
		;;
	99)
		printSuccessMessage "Adios!"
		exit 0
		;;
	*)
		printWarningMessage "La opcion elegida no se encuentra"
		exit 1
esac
