#!/bin/bash

clear

LARGURA=70
borda(){
	printf "%s\n" "`seq -s '#' $(($LARGURA + 1)) | tr -d [:digit:]`"
}

linhaDivisoria(){
	printf "#%s#\n" "`seq -s '-' $(($LARGURA - 1)) | tr -d [:digit:]`"
}

linha(){
	texto="$1"
	espacos=$((LARGURA - 4 - ${#texto}))
	printf "# %s%*s #\n" "$texto" $espacos ""	
}

linha2(){
	txtesquerda="$1"
	txtdireita="$2"
	espacos=$((LARGURA - 4 - ${#txtesquerda} - ${#txtdireita}))
	printf "# %s%*s%s #\n" "$txtesquerda" $espacos "" "$txtdireita" 
}

menu(){
	borda
	linha "IBMEC"
	linha2 "Sistemas Operacionais" "Semestre 2 de 2025"
	linha2 "Código IBM8940" "Turma 8001"
	linha "Professor: Luiz Fernando T. de Farias"
	linhaDivisoria
	linha "Equipe Desenvolvedora:"
	linha2 "Aluno: " "João Gabriel Teodosio de Oliveira Lima"
	linha2 "Aluna: " "Letícia Valadão"
	linhaDivisoria
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
		
		2)
			echo "escolheu 2"
			;;

		3)	
			echo "escolheu 3"
			;;

		4)
		 	echo "escolheu 4"
			;;


		5)
			break
			;;

		*)
			echo "nada"
			;;
	esac
done





