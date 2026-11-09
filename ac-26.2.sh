#!/bin/bash

trap '' INT QUIT TSTP

if [ "$(whoami)" = "root" ]; then
	echo "Por segurança, este programa não pode ser executado como root."
	exit 1
fi


# ------------------------------------------------------------------------------- #
# FUNCOES DE APOIO 
# ------------------------- 

LARGURA=70

borda(){
	echo "######################################################################"
}

linhaDivisoria(){
	echo "#--------------------------------------------------------------------#"
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

voltarParaMenu(){
	echo
	read -p "Pressione Enter para continuar..."
}

# -------------------------------------------------------------------------------- #
# FUNCOES DO SISTEMA 
# ------------------------

cabecalho(){
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
	linha "Rio de Janeiro, $(date '+%d de %B de %Y')"
	linha "Hora do Sistema: $(date '+%H Horas e %M Minutos')"
	borda
}

menu(){
	cabecalho
	echo "Menu de Escolhas:"
	echo " 1) Organizador de pastas"
	echo " 2) Compactador de arquivos"
	echo " 3) Monitor do sistema"
	echo " 4) Gerenciador de repositórios git"
	echo " 5) Finalizar o programa"
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

	if [ "$1" = "" ]; then
		echo "Nenhuma pasta informada."
		return 1
	fi

	if ! cd "$1" 2> /dev/null; then
		echo "A pasta não existe ou não pode ser acessada."
		return 1
	fi

	case "$(pwd)" in
		//|/|/bin|/sbin|/etc|/usr|/usr/*|/var|/System|/Library|/Applications)
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

	echo "Analisando os arquivos..."

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
		mkdir -p "$destino" 2> /dev/null
		if [ -e "$destino/$nome" ]; then
			echo "  Já existe $destino/$nome, pulando."
		elif mv "./$nome" "$destino/" 2> /dev/null; then
			echo "  $nome  ->  $destino/"
		else
			echo "  Não foi possível mover $nome, pulando."
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
	read  -p "Qual pasta deseja organizar? " pasta

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
	read  -p "Qual pasta deseja organizar? " pasta

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
	read  -p "Qual pasta deseja organizar? " pasta

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
		clear
		cabecalho
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
		voltarParaMenu
	done
}

opt2(){
# Bloco da opção 2 -> compactador e descompactador

# --------------------------------------- #
# funcoes de apoio
# -------

# Navegador de pastas: começa na home e o usuário escolhe por número.
# $1 = "tudo" (mostra pastas e arquivos) ou "pastas" (só pastas)
# $2 = título mostrado no topo
# O caminho escolhido fica na variável CMP_ESCOLHA
cmp_navegar() {
	local titulo="$2"
	local volta="$PWD"          # pasta onde o script estava, para voltar no final
	local filtro=""
	local PS3="  Escolha: "     # texto da pergunta do select
	local COLUMNS itens item

	[ "$1" = "pastas" ] && filtro="/$"   # "/$" = linhas que terminam com /

	cd "$HOME"
	while true; do
		clear
		echo "$titulo"
		echo
		echo "  Pasta atual: $PWD"
		echo "  V) Voltar uma pasta   S) Selecionar esta pasta   C) Cancelar"
		echo

		# ls -p coloca / no final das pastas; o grep filtra se for só pastas
		mapfile -t itens < <(ls -p | grep "$filtro")
		item=""

		if [ ${#itens[@]} -eq 0 ]; then
			# Pasta vazia: o select não funciona sem itens, então lemos direto
			echo "  (pasta vazia)"
			read -p "$PS3" REPLY
		else
			# select numera os itens, lê a resposta e guarda o item em $item
			# (COLUMNS=1 faz a lista sair em uma coluna só)
			COLUMNS=1
			select item in "${itens[@]}"; do
				break
			done
		fi

		# $REPLY = o que foi digitado (letra ou número)
		case "$REPLY" in
			V|v)
				# Só volta se não estiver na home (não deixa sair dela)
				[ "$PWD" != "$HOME" ] && cd ..
				;;
			S|s)
				CMP_ESCOLHA="$PWD"
				cd "$volta"
				return 0
				;;
			C|c)
				cd "$volta"
				return 1
				;;
			*)
				if [ -d "$item" ]; then
					cd "$item"                     # pasta: entra nela
				elif [ -f "$item" ]; then
					CMP_ESCOLHA="$PWD/$item"       # arquivo: seleciona
					cd "$volta"
					return 0
				fi                                 # número inválido: só redesenha
				;;
		esac
	done
}

# ----------------------------------------------- #
# OPCAO 2/1 -> compactar arquivo ou pasta
# ------------

cmp_compactar() {
	local origem destino nome final

	cmp_navegar "tudo" "Escolha o arquivo ou a pasta que deseja compactar:" || return
	origem="$CMP_ESCOLHA"

	cmp_navegar "pastas" "Escolha a pasta onde o .tar.gz será salvo:" || return
	destino="$CMP_ESCOLHA"

	nome=$(basename "$origem")
	final="$destino/$nome.tar.gz"

	echo
	echo "  Compactando: $origem"

	if [ -e "$final" ]; then
		echo "  Já existe '$final'. Nada foi feito."
		return
	fi

	# -c cria, -z comprime com gzip, -f diz o nome do arquivo final
	# -C entra na pasta de origem, assim o .tar.gz não guarda o caminho inteiro
	if tar -czf "$final" -C "$(dirname "$origem")" "$nome" 2> /dev/null; then
		echo "  Compactado com sucesso: $final"
		echo "  Tamanho original:   $(du -sh "$origem" | cut -f1)"
		echo "  Tamanho compactado: $(du -sh "$final" | cut -f1)"
	else
		echo "  Erro ao compactar."
		rm -f "$final"
	fi
}

# ----------------------------------------------- #
# OPCAO 2/2 -> descompactar arquivo
# ------------

cmp_descompactar() {
	local arquivo destino

	cmp_navegar "tudo" "Escolha o arquivo .tar.gz para descompactar:" || return
	arquivo="$CMP_ESCOLHA"

	# Confere o formato pelo final do nome
	case "$arquivo" in
		*.tar.gz|*.tgz) ;;
		*)
			echo
			echo "  '$(basename "$arquivo")' não é um .tar.gz ou .tgz."
			return
			;;
	esac

	cmp_navegar "pastas" "Escolha a pasta onde os arquivos serão extraídos:" || return
	destino="$CMP_ESCOLHA"

	echo
	# -x extrai, -z usa gzip, -k não sobrescreve o que já existe, -C escolhe a pasta
	if tar -xzkf "$arquivo" -C "$destino" 2> /dev/null; then
		echo "  Descompactado com sucesso em: $destino"
	else
		echo "  Erro ao descompactar (arquivo corrompido ou já existente no destino)."
	fi
}

# ------------------------------------------ #
# SUBMENU COMPACTADOR
# ------------

while true; do
		clear
		cabecalho
		echo
		echo "Compactador de arquivos:"
		echo "1. Compactar arquivo ou pasta"
		echo "2. Descompactar arquivo"
		echo "3. Voltar ao menu principal"
		read -p "Escolha uma opção: " escolha_cmp

		case $escolha_cmp in
			1) cmp_compactar ;;
			2) cmp_descompactar ;;
			3) return ;;
			*) echo "Opção inválida." ;;
		esac
		voltarParaMenu
	done
}

opt3(){
# Bloco da opção 3 -> monitor do sistema e processos

# ----------------------------------------------- #
# OPCAO 3/1 -> resumo do sistema
# ------------

mon_resumo() {
	echo
	echo "  Ligado há: $(uptime -p | sed 's/up //')"
	echo "  Núcleos de CPU: $(nproc)"
	echo
	echo "  Memória:"
	free -h | while IFS= read -r linha; do
		echo "    $linha"
	done
	echo
	echo "  Disco da pasta pessoal:"
	df -h "$HOME" | while IFS= read -r linha; do
		echo "    $linha"
	done
}

# ----------------------------------------------- #
# OPCAO 3/2 -> processos que mais consomem
# ------------

mon_top() {
	local tipo coluna linha
	read -p "  Ordenar por (1) CPU ou (2) memória? " tipo

	case $tipo in
		1) coluna="-%cpu" ;;      # o "-" na frente ordena do maior pro menor
		2) coluna="-%mem" ;;
		*) echo "  Opção inválida."; return ;;
	esac

	echo
	# head -n 11 = cabeçalho + 10 processos
	ps -eo pid,user,%cpu,%mem,comm --sort="$coluna" | head -n 11 | while IFS= read -r linha; do
		echo "    $linha"
	done
}

# ----------------------------------------------- #
# OPCAO 3/3 -> buscar processo pelo nome
# ------------

mon_buscar() {
	local nome achados linha
	read -p "  Nome do processo: " nome

	if [ "$nome" = "" ]; then
		echo "  Nenhum nome informado."
		return
	fi

	# comm = nome do programa; o grep -i ignora maiúsculas/minúsculas
	achados=$(ps -eo pid,user,comm | grep -i -F -e "$nome")

	if [ "$achados" = "" ]; then
		echo "  Nenhum processo com '$nome' no nome."
		return
	fi

	echo
	echo "    PID     USUÁRIO  PROGRAMA"
	echo "$achados" | while IFS= read -r linha; do
		echo "    $linha"
	done
}

# ----------------------------------------------- #
# OPCAO 3/4 -> encerrar um processo
# ------------

mon_encerrar() {
	local pid dono programa resp
	read -p "  PID do processo a encerrar: " pid

	# Confere se é um número maior que zero
	if ! [ "$pid" -gt 0 ] 2> /dev/null; then
		echo "  '$pid' não é um PID válido."
		return
	fi

	# $$ = PID deste script; $PPID = PID de quem abriu o script (o terminal)
	if [ "$pid" -eq $$ ] || [ "$pid" -eq "$PPID" ]; then
		echo "  Esse processo é o próprio programa (ou o terminal dele). Não pode ser encerrado aqui."
		return
	fi

	# ps -p mostra só aquele PID; "=" depois do campo tira o cabeçalho
	programa=$(ps -p "$pid" -o comm= 2> /dev/null)
	if [ "$programa" = "" ]; then
		echo "  Não existe processo com PID $pid."
		return
	fi

	dono=$(ps -p "$pid" -o user=)
	if [ "$dono" != "$(whoami)" ]; then
		echo "  Esse processo é do usuário '$dono'. Você só pode encerrar os seus."
		return
	fi

	echo "  Processo: $programa (PID $pid)"
	read -r -p "  Digite SIM para encerrar (qualquer outra coisa cancela): " resp
	if [ "$resp" != "SIM" ]; then
		echo "  Cancelado."
		return
	fi

	# kill manda o sinal TERM: pede para o processo terminar
	if kill "$pid" 2> /dev/null; then
		echo "  Sinal de encerramento enviado para $programa."
	else
		echo "  Não foi possível encerrar o processo."
	fi
}

# ------------------------------------------ #
# SUBMENU MONITOR
# ------------

while true; do
		clear
		cabecalho
		echo
		echo "Monitor do sistema:"
		echo "1. Resumo do sistema"
		echo "2. Processos que mais consomem"
		echo "3. Buscar processo pelo nome"
		echo "4. Encerrar um processo"
		echo "5. Voltar ao menu principal"
		read -p "Escolha uma opção: " escolha_mon

		case $escolha_mon in
			1) mon_resumo ;;
			2) mon_top ;;
			3) mon_buscar ;;
			4) mon_encerrar ;;
			5) return ;;
			*) echo "Opção inválida." ;;
		esac
		voltarParaMenu
	done
}

opt4(){

# Bloco da opção 4 -> gerenciador de repos git
# --------------------------------------- #
# funcoes de apoio
# -------

git_eh_numero() {
	[ "$1" -gt 0 ] 2> /dev/null
}

git_pede_repo() {
	local pasta
	read -p "  Qual a pasta do repositório? " pasta

	if [ "$pasta" = "" ]; then
		echo "  Nenhuma pasta informada."
		return 1
	fi
	if [ ! -d "$pasta" ]; then
		echo "  A pasta '$pasta' não existe."
		return 1
	fi
	# Todo repositório git tem uma pasta oculta .git dentro dele
	if [ ! -d "$pasta/.git" ]; then
		echo "  '$pasta' não é um repositório git (não tem a pasta .git)."
		return 1
	fi

	GIT_REPO="$pasta"
	return 0
}


# ----------------------------------------------- #
# OPCAO 4/1 -> Localizar repo em um diretorio
# ------------

git_localizar() {
	local base lista qtd linha

	read -p "  Procurar em qual pasta? " base

	if [ "$base" = "" ]; then
		echo "  Nenhuma pasta informada."
		return
	fi

	if [ ! -d "$base" ]; then
		echo "  A pasta '$base' não existe."
		return
	fi

	echo "  Procurando (até 10 níveis de profundidade)..."

	# 2>/dev/null esconde os avisos de pastas sem permissão de leitura
	lista=$(find "$base" -maxdepth 10 -type d -name .git 2>/dev/null | sort)

	if [ "$lista" = "" ]; then
		echo "  Nenhum repositório encontrado."
		return
	fi

	# [FORA DA AULA] tr -d ' ': no Mac o wc põe espaços antes do número
	qtd=$(echo "$lista" | wc -l | tr -d ' ')
	echo "  $qtd repositório(s) encontrado(s):"
	echo "$lista" | while read -r linha; do
		echo "    ${linha%/.git}"
	done
}

# ---------------------------------------------------- #
# OPCAO 4/2 -> Situacao atual
# --------------

git_situacao() {
	git_pede_repo || return

	local branch mudancas qtd linha
	branch=$(git -C "$GIT_REPO" branch --show-current)
	mudancas=$(git -c core.quotePath=false -C "$GIT_REPO" status --short)

	echo
	echo "  Branch atual: $branch"

	if [ "$mudancas" = "" ]; then
		echo "  Nenhum arquivo modificado. Está tudo commitado."
		return
	fi

	qtd=$(echo "$mudancas" | wc -l | tr -d ' ')
	echo "  $qtd arquivo(s) com mudança:"
	# IFS= aqui importa: as linhas do status começam com espaço (" M a.txt"),
	# e sem ele o read apagaria esse espaço e as colunas ficariam tortas
	echo "$mudancas" | while IFS= read -r linha; do
		echo "    $linha"
	done
	echo "  (M = modificado, A = adicionado, ?? = novo, não acompanhado)"
}

# ---------------------------------------------------- #
# OPCAO 4/3 -> ultimos commits
# --------------

git_ultimos() {
	git_pede_repo || return

	local n total linha
	read -p "  Quantos commits quer ver? " n
	if ! git_eh_numero "$n"; then
		echo "  '$n' não é um número válido."
		return
	fi

	total=$(git -C "$GIT_REPO" log --oneline 2>/dev/null | wc -l | tr -d ' ')
	if [ "$total" -eq 0 ]; then
		echo "  Esse repositório ainda não tem nenhum commit."
		return
	fi

	[ "$n" -gt "$total" ] && n=$total	

	echo
	echo "  Últimos $n de $total commit(s):"
	git -C "$GIT_REPO" log --oneline | head -n "$n" | while read -r linha; do
		echo "    $linha"
	done
}


# --------------------------------------------------------- #
# OPCAO 4/4 -> busca em commits
# ---------------- 

git_buscar() {
	git_pede_repo || return

	local palavra achados qtd linha
	read -p "  Buscar qual palavra nas mensagens? " palavra
	if [ "$palavra" = "" ]; then
		echo "  Nenhuma palavra informada."
		return
	fi

	achados=$(git -C "$GIT_REPO" log --oneline 2>/dev/null | grep -i -F -e "$palavra")

	if [ "$achados" = "" ]; then
		echo "  Nenhum commit com '$palavra' na mensagem."
		return
	fi

	qtd=$(echo "$achados" | wc -l | tr -d ' ')
	echo
	echo "  $qtd commit(s) com '$palavra':"
	echo "$achados" | while read -r linha; do
		echo "    $linha"
	done
}

# -------------------------------------------
# SUBMENU GIT
# --------



while true; do
		clear
		cabecalho
		echo
		echo "Gerenciador de repositórios git:"
		echo "1. Localizar meus repositórios"
		echo "2. Ver situação de um repositório"
		echo "3. Ver últimos commits"
		echo "4. Buscar no histórico"
		echo "5. Voltar ao menu principal"
		read -p "Escolha uma opção: " escolha_git

		case $escolha_git in
			1) git_localizar ;;
			2) git_situacao ;;
			3) git_ultimos ;;
			4) git_buscar ;;
			5) return ;;
			*) echo "Opção inválida." ;;
		esac
		voltarParaMenu
	done
}

# --------------------------------------------------
# Fluxo Inicial e principal do programa

while true; do
	clear
	menu
	
	read -p "Selecione uma opção: " option

	case $option in 
		1)
			opt1
			;;
		
		2)
			opt2
			;;

		3)	
			opt3
			;;

		4)
		 	opt4
			;;


		5)
			break
			;;

		*)
			echo "Opção inválida."
			voltarParaMenu
			;;
	esac
done





