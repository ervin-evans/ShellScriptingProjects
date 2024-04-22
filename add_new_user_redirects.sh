#!/bin/bash

# Author: Ervin Triano
# Date: 10-01-2013

#******************************************************************************
# COLORS
#******************************************************************************
greenColor="\e[0;32m\033[1m"
endColor="\033[0m\e[0m"
redColor="\e[0;31m\033[1m"
blueColor="\e[0;34m\033[1m"
yellowColor="\e[0;33m\033[1m"
purpleColor="\e[0;35m\033[1m"
grayColor="\e[0;37m\033[1m"

trap ctrl_c INT
function ctrl_c(){
	echo "[*] Saliendo"
}

function help_panel(){	
	echo -e "\n${yellowColor}[*]${endColor}${grayColor}Uso: ${0} ${endColor}"
}
# MAIN FUNCTION
if [[ ${UID} -ne 0 ]]
then
	echo -e "${redColor}[*]  No tienes permisos suficientes para ejecutar el script ${endColor}"
	exit 1

fi

declare -i PARAMETER_COUNTER=0
while getopts ":u:c:h" arg
do
	case $arg in
		u) 
			USER_NAME=${OPTARG}
			let PARAMETER_COUNTER+=1
			;;
		c)
			USER_COMMENTS=${OPTARG}
			let PARAMETER_COUNTER+=1
			;;
		h)
			help_panel
			;;
	esac
done

if [[ ${PARAMETER_COUNTER} -eq 1 ]]
then
	useradd -m ${USER_NAME} &> /dev/null
	echo -e "${purpleColor}[*]${endColor}${greenColor} El usuario ${USER_NAME} ha sido agregado satisfactoriamente ${endColor}" 
elif [[ ${PARAMETER_COUNTER} -eq 2 ]]
then
	useradd -c ${USER_COMMENTS} -m ${USER_NAME} &> /dev/null
	echo -e "${purpleColor}[*]${endColor}${greenColor} El usuario ${USER_NAME} ha sido agregado satisfactoriamente [FULL]${endColor}"
else
	help_panel
	exit 1
fi
if [[ ${?} -eq 0 ]]
then
	RANDOM_PASSWORD=$(date +%s%N | sha256sum | head -c48)
	echo ${RANDOM_PASSWORD} | passwd  --stdin ${USER_NAME} &> /dev/null
	if [[ ${?} -ne 0 ]]
	then

		echo -e "${redColor}[*] Hubo algunos errores al crear la password para el usuario ${endColor} ${greenColor}${USER_NAME}${endColor}"
		echo -e ${redColor}"[*] Removiendo al usuario${endColor}${greenColor} ${USER_NAME}${endColor}${redColor} previamente creado"
		sleep 1
		userdel -r ${USER_NAME}
		echo -e "El usuario${endColor}${greenColor} ${USER_NAME} ${endColor}${redColor}ha sido removido del sistema${endColor}"
		exit 1
	fi
	passwd -e ${USER_NAME} &> /dev/null
	if [[ ${?} -eq 0 ]]
	then
		echo -e "${yellowColor}[?] Es necesario que el usuario ${endColor}${purpleColor}${USER_NAME}${endColor}${yellowColor} cambie su password en el primer login${endColor}"
	fi
	echo -e "${greenColor}[*] El password del usuario${endColor}${purpleColor} ${USER_NAME}${endColor}${greenColor} ha sido creada con exito!${endColor}"
	echo
	echo -e "${purpleColor}[*] USERNAME: ${endColor}${yellowColor}${USER_NAME}${endColor}"
	echo -e "${purpleColor}[*] PASSWORD GENERATED: ${endColor}${yellowColor}${RANDOM_PASSWORD}${endColor}"
	echo -e "${purpleColor}[*] HOSTNAME: ${endColor}${yellowColor}$(cat /etc/hostname)${endColor}"
	exit 0
else
	echo -e "${redColor}[*] El usuario no pudo ser creado${endColor}"
	exit 1
fi
