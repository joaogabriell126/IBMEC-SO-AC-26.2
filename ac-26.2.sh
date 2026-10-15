#!/bin/sh

menu(){
	echo "##########################################################"
	echo "# IBMEC"
	printf "%-40s %s\n" "Sistemas Operacionais" "Semestre 2 de 2025"
	echo "Código IBM8940"
	echo "Turma 8001"
	echo "Professor: Luiz Fernando T. de Farias"
	echo "#------------------------------------------------#"
	echo Menu de Escolhas:
	echo "1. Opção 1"
	echo "2. Opção 2"
	echo "3. Opção 3"
	echo "4. Opção 4"
	echo "5. Sair"
}

opt1(){
# Bloco da opção 1
:
}

opt2(){
# Bloco da opção 2
:
}

opt3(){
# Bloco da opção 3
:
}

opt4(){
# Bloco da opção 4
:
}

# Fluxo Inicial e principal do programa

while true; do
	menu
	read -p "Escolha uma opção: " option
	
	case $option in 
		1)
			echo "escolheu 1"
			;;
		5)
			break
			;;

		*)
			echo "nada"
			;;
	esac
done




