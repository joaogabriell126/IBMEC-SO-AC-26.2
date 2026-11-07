#!/bin/bash

clear


# ------------------------------------------------------------------------------- #
# FUNCOES DE APOIO 
# ------------------------- 

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

# -------------------------------------------------------------------------------- #
# FUNCOES DO SISTEMA 
# ------------------------

menu(){
	borda
	linha "IBMEC"
	linha2 "Sistemas Operacionais" "Semestre 2 de 2026"
	linha2 "Código IBM0791" "Turma 8001"
	linha "Professor: Luiz Fernando T. de Farias"
	linhaDivisoria
	linha "Equipe Desenvolvedora:"
	linha2 "Aluno: " "João Gabriel Teodosio de Oliveira Lima"
	linha2 "Aluna: " "Letícia Rocha Valladão"
	linhaDivisoria
	linha "Rio de Janeiro, "
	linha "Hora do Sistema: "
	borda

	echo Menu de Escolhas:
	echo "1. Opcao 1"
	echo "2. Opção 2"
	echo "3. Opção 3"
	echo "4. Opção 4"
	echo "5. Sair"
}

voltarParaMenu(){
:
}


opt1(){
# Bloco da opção 1 -> organizador de diretorio

ORG_LISTA="/tmp/organizador_lista.txt"
ORG_PLANO="/tmp/organizador_plano.txt"

ORG_IGNORADAS=" para pela pelo como sobre entre desde final copia arquivo nome versao novo nova documento "

# -------------------------------------- #
# funcoes de apoio 
# ------

palavras() {
	local base="${1%.*}"
	local p
	
	echo "$base" \
	| sed -e 's/[áàãâä]/a/g' -e 's/[ÁÀÃÂÄ]/A/g' -e 's/[éèêë]/e/g' -e 's/[ÉÈÊË]/E/g' -e 's/[íìîï]/i/g' -e 's/[ÍÌÎÏ]/I/g' -e 's/[óòõôö]/o/g' -e 's/[ÓÒÕÔÖ]/O/g'  -e 's/[úùûü]/u/g' -e 's/[ÚÙÛÜ]/U/g' \
	 -e 's/ç/c/g' -e 's/Ç/C/g' \
	| grep -o -E '[A-Z]?[a-z]+|[A-Z]+' \
	| tr '[:upper:]' '[:lower:]' \
	| while read p; do
		[ ${#p} -lt 4 ] && continue 
		p="${p%s}"
		case "$ORG_IGNORADAS" in
			*" $p "*) continue ;;
		esac
		echo "$p"
	done
}

entra_na_pasta() {
	ORG_VOLTA=$(pwd)

	if ! cd "$1" 2> /dev/null; then
		echo "A pasta não existe ou não pode ser acessada."
		return 1
	fi

	case "$(pwd)" in
		/|/bin|/sbin|/etc|/usr|/usr/*|/var|/System|/Library|/Applications)
		echo "Por segurança, pastas do sistema não podem ser organizadas."
		cd "$ORG_VOLTA"
		return 1
		;;
	esac
	return 0
}

sai_da_pasta(){
	rm "$ORG_LISTA" "$ORG_PLANO" 2> /dev/null
	cd "$ORG_VOLTA"
}

plano_assunto(){
	local nome p destino qtd

	for nome in *; do
		[ -f "$nome" ] || continue
		palavras "$nome" | while read p; do
			echo "$p|$nome"
		done
	done > "$ORG_LISTA"


	for nome in *; do
		[ -f "$nome" ] || continue
	
		destino=""
		for p in $(palavras "$nome"); do
			qtd=$(grep "^$p|" "$ORG_LISTA" | sort -u | wc -l)
			if [ $qtd -ge 2 ]; then
				destino="$p"
				break
			fi
		done

		if [ "$destino" != "" ]; then
			echo "$nome|$destino"
		fi
	done > "$ORG_PLANO"
}

executa_plano() {
	local nome destino resp

	if [ ! -s "$ORG_PLANO" ]; then
		echo "Nada a organizar nessa pasta."
		return
	fi

	echo "Prévia:"
	while IFS='|' read -r nome destino; do
		echo "  $nome  ->  $destino/"
	done < "$ORG_PLANO"

	read -r -p "Digite SIM para mover (qualquer outra coisa cancela): " resp
	if [ "$resp" != "SIM" ]; then
		echo "Cancelado. Nada foi movido."
		return
	fi

	while IFS='|' read -r nome destino; do
		mkdir -p "$destino"
		if [ -e "$destino/$nome" ]; then
			echo "  Já existe $destino/$nome, pulando."
		else
			mv "$nome" "$destino/"
			echo "  $nome  ->  $destino/"
		fi
	done < "$ORG_PLANO"
	echo "Pronto."
}

extensao_de() {
	local ext
	case "$1" in
		*.*) ext="${1##*.}" ;;
		*)   ext="" ;;
	esac

	if [ "$ext" = "" ]; then
		echo "sem_extensao"
	else
		echo "$ext" | tr '[:upper:]' '[:lower:]'
	fi
}

plano_extensao() {
	local prefixo="$1"
	local nome

	for nome in *; do
		[ -f "$nome" ] || continue

		if cut -d'|' -f1 "$ORG_PLANO" 2> /dev/null | grep -q -x -F "$nome"; then
			continue                         # já tem destino (assunto): pula
		fi

		echo "$nome|$prefixo$(extensao_de "$nome")"
	done >> "$ORG_PLANO"
}


# ------------------------------------------- #
# OPCAO 1/1 -> organizar por assunto apenas
# ---------

organiza_assunto() {
	local pasta
	read -r -p "Qual pasta deseja organizar? " pasta

	entra_na_pasta "$pasta" || return    # se falhar, volta pro menu
	plano_assunto
	executa_plano
	sai_da_pasta
}

# -------------------------------------------- #
# OPCAO 1/2 -> organizar por extensao apenas 
# ---------

organiza_extensao() {
	local pasta
	read -r -p "Qual pasta deseja organizar? " pasta

	entra_na_pasta "$pasta" || return
	rm "$ORG_PLANO" 2> /dev/null       # começa com o plano vazio
	plano_extensao ""
	executa_plano
	sai_da_pasta
}


# ------------------------------------------- #
# OPCAO 1/3 -> organizar por ambos acima 
# --------
organiza_ambos() {
	local pasta
	read -r -p "Qual pasta deseja organizar? " pasta

	entra_na_pasta "$pasta" || return
	plano_assunto                      # primeiro, os que têm assunto
	plano_extensao "outros/"           # depois, o resto vai por extensão
	executa_plano
	sai_da_pasta
}

#--------------------------------------------- #
# SUBMENU OPC1
# ------

while true; do
		echo
		echo "Organizador de pastas:"
		echo "1. Organizar por assunto"
		echo "2. Organizar por extensão"
		echo "3. Organizar por assunto e o resto por extensão"
		echo "4. Voltar ao menu principal"
		read -p "Escolha uma opção: " escolha_org

		case $escolha_org in
			1) organiza_assunto ;;
			2) organiza_extensao ;;
			3) organiza_ambos ;;
			4) return ;;
			*) echo "Opção inválida." ;;
		esac
	done
}


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

# Bloco da opção 4 -> gerenciador de repos git
# --------------------------------------- #
# funcoes de apoio
# -------



# ----------------------------------------------- #
# OPCAO 4/1 -> Localizar repo em um diretorio
# ------------


 
:
}

# Fluxo Inicial e principal do programa

while true; do
	menu
	read -p "Escolha uma opção: " option
	
	case $option in 
		1)
			opt1
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
			echo "Opcao invalida. Por favor selecione uma das opcoes acima."
			;;
	esac
done





