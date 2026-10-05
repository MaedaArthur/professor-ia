#!/usr/bin/env bash
#
# Setup do workshop "Professor de IA": macOS e Linux.
#
#   bash setup.sh
#
# Variavel de ambiente de teste:
#   SETUP_DRY_RUN=1 bash setup.sh
#     Nao instala nada e nao acessa a rede: pula o pip install, a instalacao do
#     OpenCode e o teste final. Serve para conferir o script numa maquina ja
#     configurada (ou em CI) sem efeito colateral. Tudo o mais roda igual,
#     inclusive a escrita do .env.
#
# Escrito para bash 3.2 (o que vem no macOS): sem arrays associativos,
# sem mapfile, sem 'read -i'.

set -euo pipefail

# O script usa caminhos relativos (requirements.txt, .env.example), entao
# precisa rodar a partir da pasta dele: nao de onde o aluno chamou.
DIRETORIO=$(cd "$(dirname "$0")" && pwd)
cd "$DIRETORIO"

ARQ_ENV="$DIRETORIO/.env"
ARQ_EXEMPLO="$DIRETORIO/.env.example"
DRY_RUN="${SETUP_DRY_RUN:-0}"

# ---------------------------------------------------------------- aparencia --

# Cor so faz sentido num terminal: em pipe ou redirecionamento ela viraria
# lixo no meio do texto.
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    C_VERDE=$(tput setaf 2)
    C_VERM=$(tput setaf 1)
    C_AMAR=$(tput setaf 3)
    C_FORTE=$(tput bold)
    C_OFF=$(tput sgr0)
else
    C_VERDE=""; C_VERM=""; C_AMAR=""; C_FORTE=""; C_OFF=""
fi

titulo() { printf '\n%s%s%s\n' "$C_FORTE" "$1" "$C_OFF"; }
ok()     { printf '  %sok%s    %s\n' "$C_VERDE" "$C_OFF" "$1"; }
aviso()  { printf '  %saviso%s %s\n' "$C_AMAR" "$C_OFF" "$1"; }
falha()  { printf '  %serro%s  %s\n' "$C_VERM" "$C_OFF" "$1" >&2; }
info()   { printf '        %s\n' "$1"; }

# Erro fatal: primeira linha diz o que faltou, as seguintes dizem como resolver.
# Nunca deixamos um traceback cru chegar no aluno.
morrer() {
    falha "$1"
    shift
    for linha in "$@"; do info "$linha"; done
    printf '\n'
    exit 1
}

# Resumo final. Acumulo em string porque array vazio + "set -u" explode no
# bash 3.2 do macOS.
NL=$'\n'
FEITO=""
FALTOU=""
registrar_feito()  { FEITO="${FEITO}  - ${1}${NL}"; }
registrar_faltou() { FALTOU="${FALTOU}  - ${1}${NL}"; }

printf '%s\n' "================================================================"
printf '%s\n' " Professor de IA, setup (macOS / Linux)"
printf '%s\n' "================================================================"
if [ "$DRY_RUN" = "1" ]; then
    aviso "SETUP_DRY_RUN=1: nada sera instalado e a rede nao sera usada."
fi

# --------------------------------------------------------- 1. Python 3.9+ --

titulo "1. Python 3.9 ou mais novo"

PYTHON=""
VERSAO_ACHADA=""
for candidato in python3 python; do
    if command -v "$candidato" >/dev/null 2>&1; then
        if "$candidato" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 9) else 1)' >/dev/null 2>&1; then
            PYTHON="$candidato"
            break
        fi
        # Guardo a versao velha para o erro poder dizer o que a maquina tem.
        VERSAO_ACHADA=$("$candidato" -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null || echo "desconhecida")
    fi
done

if [ -z "$PYTHON" ]; then
    if [ -n "$VERSAO_ACHADA" ]; then
        morrer "Python encontrado, mas e a versao $VERSAO_ACHADA, o workshop precisa de 3.9 ou mais novo." \
                "Baixe uma versao nova em https://www.python.org/downloads/" \
                "Depois feche e abra o terminal e rode 'bash setup.sh' de novo."
    fi
    morrer "Python nao encontrado (procurei por 'python3' e 'python')." \
            "Instale em https://www.python.org/downloads/" \
            "No macOS tambem da com Homebrew: brew install python" \
            "Depois feche e abra o terminal e rode 'bash setup.sh' de novo."
fi

VERSAO_PY=$("$PYTHON" -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])')
ok "$PYTHON $VERSAO_PY"

# ------------------------------------------------------------------ 2. Git --

titulo "2. Git"

if ! command -v git >/dev/null 2>&1; then
    morrer "Git nao encontrado." \
            "Instale em https://git-scm.com/downloads" \
            "No macOS tambem da com: xcode-select --install" \
            "Depois feche e abra o terminal e rode 'bash setup.sh' de novo."
fi
ok "$(git --version)"

# ---------------------------------------------------------- 3. dependencias --

titulo "3. Dependencias do Python (requirements.txt)"

if [ ! -f requirements.txt ]; then
    morrer "Nao achei o requirements.txt em $DIRETORIO" \
            "Rode o setup.sh de dentro da pasta clonada do repositorio."
fi

# Procuro o pip na ordem que o README ensina: pip, pip3 e, por ultimo,
# 'python -m pip' (que e o que sempre casa com o interpretador certo).
PIP=""
for candidato in pip pip3; do
    if command -v "$candidato" >/dev/null 2>&1; then PIP="$candidato"; break; fi
done
if [ -z "$PIP" ] && "$PYTHON" -m pip --version >/dev/null 2>&1; then
    PIP="$PYTHON -m pip"
fi

if [ -z "$PIP" ]; then
    aviso "Nao achei o pip."
    info "Instale com: $PYTHON -m ensurepip --upgrade"
    info "Depois rode: $PYTHON -m pip install -r requirements.txt"
    registrar_faltou "dependencias do Python (pip nao encontrado)"
elif [ "$DRY_RUN" = "1" ]; then
    aviso "pulado (SETUP_DRY_RUN=1). Comando que seria usado: $PIP install -r requirements.txt"
else
    # $PIP pode ser "python3 -m pip" (duas palavras), por isso sem aspas.
    if SAIDA=$($PIP install -r requirements.txt 2>&1); then
        ok "dependencias instaladas ($PIP)"
        registrar_feito "dependencias do requirements.txt"
    else
        aviso "o pip falhou; tentando de novo com --user (sem sudo)"
        if SAIDA=$($PIP install --user -r requirements.txt 2>&1); then
            ok "dependencias instaladas com --user"
            registrar_feito "dependencias do requirements.txt (--user)"
        else
            falha "nao consegui instalar as dependencias."
            printf '%s\n' "$SAIDA" | tail -n 8 | sed 's/^/        /'
            info ""
            info "Saidas possiveis:"
            info "  1) ambiente isolado:  $PYTHON -m venv .venv && . .venv/bin/activate"
            info "                        pip install -r requirements.txt"
            info "  2) so para voce:      $PIP install --user -r requirements.txt"
            info "Nao use sudo: instalar pacote como root quebra o Python do sistema."
            registrar_faltou "dependencias do Python (veja o erro do pip acima)"
        fi
    fi
fi

# -------------------------------------------------------------- 4. OpenCode --

titulo "4. OpenCode"

# O instalador poe o binario em ~/.opencode/bin, que normalmente ainda nao esta
# no PATH desta sessao: por isso a checagem olha o caminho direto tambem.
BIN_OPENCODE="$HOME/.opencode/bin"
if [ -d "$BIN_OPENCODE" ]; then
    case ":$PATH:" in
        *":$BIN_OPENCODE:"*) : ;;
        *) PATH="$BIN_OPENCODE:$PATH"; export PATH ;;
    esac
fi

tem_opencode() { command -v opencode >/dev/null 2>&1 && opencode --version >/dev/null 2>&1; }

if tem_opencode; then
    ok "OpenCode ja instalado (versao $(opencode --version 2>/dev/null | head -n 1))"
elif [ "$DRY_RUN" = "1" ]; then
    aviso "pulado (SETUP_DRY_RUN=1). Comando que seria usado: curl -fsSL https://opencode.ai/install | bash"
    registrar_faltou "OpenCode (nao instalado por causa do SETUP_DRY_RUN)"
else
    if ! command -v curl >/dev/null 2>&1; then
        aviso "curl nao encontrado, nao consigo instalar o OpenCode sozinho."
        info "Instale o curl, ou use o npm: npm install -g opencode-ai"
        registrar_faltou "OpenCode (instale com: npm install -g opencode-ai)"
    else
        printf '  instalando o OpenCode (pode levar um minuto)...\n'
        if curl -fsSL https://opencode.ai/install | bash; then
            if [ -d "$BIN_OPENCODE" ]; then PATH="$BIN_OPENCODE:$PATH"; export PATH; fi
            if tem_opencode; then
                ok "opencode instalado"
                registrar_feito "OpenCode"
                aviso "num terminal novo o 'opencode' pode nao ser achado. Se isso acontecer, rode:"
                info "echo 'export PATH=\"\$HOME/.opencode/bin:\$PATH\"' >> ~/.zshrc"
                info "(use ~/.bashrc se o seu terminal for bash) e abra um terminal novo."
            else
                aviso "o instalador rodou, mas o 'opencode' nao responde nesta sessao."
                info "Rode: export PATH=\"\$HOME/.opencode/bin:\$PATH\"  e tente 'opencode --version'"
                registrar_faltou "OpenCode no PATH (binario em ~/.opencode/bin)"
            fi
        else
            aviso "a instalacao do OpenCode falhou."
            info "Tente na mao: curl -fsSL https://opencode.ai/install | bash"
            info "Ou, se voce tem Node: npm install -g opencode-ai"
            registrar_faltou "OpenCode"
        fi
    fi
fi

# ----------------------------------------------------------- 5. as  chaves --

titulo "5. Chaves de API"

if [ ! -f "$ARQ_ENV" ]; then
    if [ ! -f "$ARQ_EXEMPLO" ]; then
        morrer "Nao achei nem .env nem .env.example em $DIRETORIO" \
                "Rode o setup.sh de dentro da pasta clonada do repositorio."
    fi
    cp "$ARQ_EXEMPLO" "$ARQ_ENV"
    ok ".env criado a partir do .env.example"
else
    ok ".env ja existia (vou manter o que ja esta dentro)"
fi

# Le o valor atual de uma chave no .env. awk em vez de grep porque grep sem
# resultado retorna erro e, com 'set -e', derrubaria o script.
ler_do_env() {
    valor=$(awk -v n="$1" '
        index($0, "#") == 1 { next }
        $0 ~ "^[ \t]*"n"[ \t]*=" { sub(/^[^=]*=[ \t]*/, ""); v = $0 }
        END { print v }
    ' "$ARQ_ENV")
    valor=${valor%$'\r'}           # .env salvo no Windows deixa CR no fim
    valor=${valor%\"}; valor=${valor#\"}
    valor=${valor%\'}; valor=${valor#\'}
    printf '%s' "$valor"
}

# Upsert: se a linha existe, troca; se nao, acrescenta. E o que garante que
# rodar o setup duas vezes nao duplique chave nenhuma.
gravar_no_env() {
    nome="$1"
    valor="$2"
    temporario="$ARQ_ENV.setup.$$"
    if awk -v n="$nome" 'index($0, "#") != 1 && $0 ~ "^[ \t]*"n"[ \t]*=" { achou = 1 } END { exit achou ? 0 : 1 }' "$ARQ_ENV"; then
        awk -v n="$nome" -v v="$valor" '
            index($0, "#") != 1 && $0 ~ "^[ \t]*"n"[ \t]*=" && !feito { print n "=" v; feito = 1; next }
            { print }
        ' "$ARQ_ENV" > "$temporario"
    else
        cp "$ARQ_ENV" "$temporario"
        # Sem newline no fim do arquivo, a chave nova colaria na ultima linha.
        if [ -s "$temporario" ] && [ -n "$(tail -c 1 "$temporario")" ]; then
            printf '\n' >> "$temporario"
        fi
        printf '%s=%s\n' "$nome" "$valor" >> "$temporario"
    fi
    mv "$temporario" "$ARQ_ENV"
}

# Pergunta uma chave e grava. Enter vazio = pular, sem reclamar.
# Com stdin vindo de pipe ou /dev/null, o read falha e cai no mesmo "pular".
perguntar_chave() {
    nome="$1"
    link="$2"
    prefixo="$3"

    atual=$(ler_do_env "$nome")
    if [ -n "$atual" ]; then
        ok "$nome ja esta preenchida no .env"
        return 0
    fi

    printf '\n  %s\n' "$nome"
    printf '    pegue a sua em %s (gratis, sem cartao)\n' "$link"
    printf '    comeca com "%s", ou aperte Enter para pular e preencher depois\n' "$prefixo"

    tentativa=1
    while [ "$tentativa" -le 3 ]; do
        printf '    cole a chave: '
        if read -r digitado; then
            # Entrada vinda de pipe nao ecoa o Enter; sem isso a linha emenda.
            if [ ! -t 0 ]; then printf '\n'; fi
        else
            digitado=""
            printf '\n'
        fi

        if [ -z "$digitado" ]; then
            aviso "$nome pulada."
            registrar_faltou "$nome, pegue em $link e ponha no .env"
            return 0
        fi

        # Recuso caractere estranho porque chave colada com aspas, espaco ou
        # quebra de linha vira um .env quebrado e um erro confuso depois.
        case "$digitado" in
            *[!A-Za-z0-9_.-]*)
                falha "essa chave tem caractere que nao parece de chave (aspas, espaco ou acento?)."
                info "Cole so a chave, sem aspas e sem espaco em volta."
                tentativa=$((tentativa + 1))
                continue
                ;;
        esac

        case "$digitado" in
            "$prefixo"*) : ;;
            *) aviso "normalmente essa chave comeca com \"$prefixo\", confira se copiou a certa." ;;
        esac

        gravar_no_env "$nome" "$digitado"
        ok "$nome gravada no .env"
        registrar_feito "$nome no .env"
        return 0
    done

    aviso "$nome nao foi preenchida (tres tentativas invalidas)."
    registrar_faltou "$nome, pegue em $link e ponha no .env"
}

perguntar_chave GEMINI_API_KEY     "https://aistudio.google.com/apikey" "AIza"
perguntar_chave OPENROUTER_API_KEY "https://openrouter.ai/keys"         "sk-or-v1-"

printf '\n'
info "O .env esta no .gitignore: ele nao vai para o repositorio. Mesmo assim,"
info "nunca cole uma chave em commit, print, slide ou mensagem."
info "Para carregar as chaves num terminal novo:  set -a; . ./.env; set +a"

# ------------------------------------------------------------ 6. teste real --

titulo "6. Teste final"

CHAVE_GEMINI=$(ler_do_env GEMINI_API_KEY)
TESTE_PASSOU=0

if [ -z "$CHAVE_GEMINI" ]; then
    aviso "sem GEMINI_API_KEY no .env, pulei o teste."
    info "Preencha a GEMINI_API_KEY no .env e rode: $PYTHON 01_chamada_minima.py"
elif [ ! -f 01_chamada_minima.py ]; then
    aviso "nao achei o 01_chamada_minima.py, pulei o teste."
elif [ "$DRY_RUN" = "1" ]; then
    aviso "pulado (SETUP_DRY_RUN=1): o teste faz uma chamada de rede de verdade."
else
    printf '  chamando o modelo uma vez...\n'
    if SAIDA_TESTE=$(GEMINI_API_KEY="$CHAVE_GEMINI" "$PYTHON" 01_chamada_minima.py 2>&1); then
        ok "o teste passou, a chave do Gemini funciona."
        TESTE_PASSOU=1
        registrar_feito "teste 01_chamada_minima.py passou"
    else
        falha "o teste nao passou."
        printf '%s\n' "$SAIDA_TESTE" | tail -n 12 | sed 's/^/        /'
        info ""
        case "$SAIDA_TESTE" in
            *"No module named 'requests'"*)
                info "Faltou a dependencia: $PIP install -r requirements.txt" ;;
            *"API_KEY_INVALID"*|*"API key not valid"*|*"valid API key"*|*401*|*403*)
                info "A chave parece invalida. Crie outra em https://aistudio.google.com/apikey" ;;
            *429*)
                info "Limite por minuto do Gemini. Espere um minuto e rode de novo." ;;
            *"Could not resolve host"*|*"Temporary failure"*|*ConnectionError*)
                info "Parece problema de rede/internet. Confira a conexao e tente de novo." ;;
            *)
                info "Leia o erro acima. A secao 'Problemas' do README cobre os casos comuns." ;;
        esac
        registrar_faltou "teste 01_chamada_minima.py (veja o erro acima)"
    fi
fi

# ----------------------------------------------------------------- resumo --

printf '\n%s\n' "================================================================"
printf '%s\n' " Resumo"
printf '%s\n' "================================================================"

if [ -n "$FEITO" ]; then
    printf '\n%sPronto:%s\n' "$C_VERDE" "$C_OFF"
    printf '%s' "$FEITO"
else
    printf '\n%sPronto:%s\n' "$C_VERDE" "$C_OFF"
    printf '%s\n' "  - nada novo: tudo o que precisava ja estava no lugar"
fi

if [ -n "$FALTOU" ]; then
    printf '\n%sFalta voce:%s\n' "$C_AMAR" "$C_OFF"
    printf '%s' "$FALTOU"
fi

printf '\n%sProximo comando:%s\n' "$C_FORTE" "$C_OFF"
if [ -z "$CHAVE_GEMINI" ]; then
    printf '%s\n' "  1) abra o .env e preencha a GEMINI_API_KEY (https://aistudio.google.com/apikey)"
    printf '%s\n' "  2) $PYTHON 01_chamada_minima.py"
elif [ "$TESTE_PASSOU" = "1" ]; then
    printf '%s\n' "  opencode        # aula 2: converse com o agente professor (Tab troca de agente)"
else
    printf '%s\n' "  $PYTHON 01_chamada_minima.py        # resolva o erro acima e rode de novo"
fi
printf '\n'
