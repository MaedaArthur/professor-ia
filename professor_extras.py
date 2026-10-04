"""Professor de IA com ferramentas — versão completa (gabarito).

Mesmo professor do professor.py, com três diferenças:

1. A apostila NÃO vai inteira no system prompt. O professor tem uma ferramenta
   de busca e precisa procurar os trechos de que precisa. É o "nível 3": o
   agente vai buscar o contexto em vez de receber tudo mastigado.
2. Ele pode salvar flashcards num CSV e lê-los de volta para fazer quiz.
3. O loop agêntico está explícito e visível: a cada ferramenta chamada, o
   programa imprime [ferramenta: nome(args)].

Rode com:
    python professor_extras.py

Para testar sem travar o terminal:
    printf 'busque temperatura na apostila\n/sair\n' | python professor_extras.py
"""

import csv
import json
import os
import re
import sys
import time
import unicodedata

import requests

# --- Configuração -----------------------------------------------------------
URL = os.environ.get(
    "LLM_URL",
    "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
)
MODELO = os.environ.get("GEMINI_MODEL", "gemini-flash-latest")

CAMINHO_MATERIAL = "material/apostila.md"
CAMINHO_PERFIL = "perfil.md"
CAMINHO_FLASHCARDS = "flashcards.csv"

# Trava do loop agêntico. Sem um limite, um modelo confuso chama ferramenta
# para sempre — e cada volta é uma requisição cobrada.
MAX_VOLTAS = 6

AJUDA_CHAVE = """Falta a GEMINI_API_KEY.

macOS / Linux:
  export GEMINI_API_KEY='sua-chave-aqui'

Windows (PowerShell):
  $env:GEMINI_API_KEY='sua-chave-aqui'

Isso vale só para esta janela de terminal. Para não repetir, veja a seção
"Configure as chaves" do README.

Gere uma chave grátis em https://aistudio.google.com/apikey"""


class LimiteAtingido(Exception):
    """Levantada quando a API responde 429 (requisições demais)."""


# Veja a nota em professor.py: o Gemini devolve 503 em horário de pico.
HTTP_TRANSITORIO = (500, 502, 503, 504)
TENTATIVAS = 3

# O free tier do Gemini tem limite POR MINUTO baixo: tres perguntas seguidas
# ja levam 429. Como a janela e curta, esperar e tentar de novo quase sempre
# resolve - e e melhor que o aluno perder o turno. As esperas sao visiveis de
# proposito: ver o programa esperando pelo limite tambem e parte da aula.
ESPERAS_429 = (20, 40)


class ErroDaApi(Exception):
    """Levantada para qualquer outra falha na chamada da API."""


# --- Ferramenta 1: buscar no material ---------------------------------------


def _normalizar(texto):
    """Minúsculas e sem acento, para comparar palavras sem tropeçar em acentuação.

    "Previsão" e "previsao" precisam casar — senão a busca falha justamente nas
    palavras que o aluno digita sem acento.
    """
    sem_acento = unicodedata.normalize("NFD", texto.lower())
    return "".join(c for c in sem_acento if unicodedata.category(c) != "Mn")


def _palavras(texto):
    """Devolve o conjunto de palavras de 3+ letras, normalizadas."""
    return {p for p in re.findall(r"[a-z0-9]+", _normalizar(texto)) if len(p) >= 3}


def dividir_em_secoes(markdown):
    """Divide o markdown nas linhas que começam com '## '.

    Devolve uma lista de (titulo, texto_completo_da_secao).
    """
    secoes = []
    titulo_atual = None
    linhas_atuais = []

    for linha in markdown.splitlines():
        if linha.startswith("## "):
            if titulo_atual is not None:
                secoes.append((titulo_atual, "\n".join(linhas_atuais).strip()))
            titulo_atual = linha[3:].strip()
            linhas_atuais = [linha]
        elif titulo_atual is not None:
            linhas_atuais.append(linha)

    if titulo_atual is not None:
        secoes.append((titulo_atual, "\n".join(linhas_atuais).strip()))

    return secoes


def buscar_material(consulta):
    """Devolve os 3 trechos mais relevantes da apostila para a consulta.

    Pontuação simples e explicável: quantas palavras da consulta aparecem na
    seção. O título conta em dobro, porque casar com o título é sinal forte.
    """
    try:
        with open(CAMINHO_MATERIAL, encoding="utf-8") as arquivo:
            markdown = arquivo.read()
    except FileNotFoundError:
        return f"Material não encontrado em {CAMINHO_MATERIAL}."

    palavras_consulta = _palavras(consulta)
    if not palavras_consulta:
        return "Consulta vazia — diga o que procurar."

    pontuados = []
    for titulo, texto in dividir_em_secoes(markdown):
        no_corpo = len(palavras_consulta & _palavras(texto))
        no_titulo = len(palavras_consulta & _palavras(titulo))
        pontos = no_corpo + 2 * no_titulo
        if pontos > 0:
            pontuados.append((pontos, titulo, texto))

    if not pontuados:
        return f"Nenhum trecho do material fala sobre '{consulta}'."

    pontuados.sort(key=lambda item: item[0], reverse=True)

    blocos = []
    for pontos, titulo, texto in pontuados[:3]:
        blocos.append(f"--- trecho: {titulo} (relevância {pontos}) ---\n{texto}")
    return "\n\n".join(blocos)


# --- Ferramentas 2 e 3: flashcards ------------------------------------------


def salvar_flashcard(frente, verso):
    """Acrescenta um flashcard em flashcards.csv (cria o arquivo se faltar)."""
    novo = not os.path.exists(CAMINHO_FLASHCARDS)
    with open(CAMINHO_FLASHCARDS, "a", newline="", encoding="utf-8") as arquivo:
        escritor = csv.writer(arquivo)
        if novo:
            escritor.writerow(["frente", "verso"])
        escritor.writerow([frente, verso])
    return f"Flashcard salvo: {frente}"


def ler_flashcards():
    """Devolve os flashcards salvos, numerados, como texto."""
    if not os.path.exists(CAMINHO_FLASHCARDS):
        return "Nenhum flashcard salvo ainda."

    with open(CAMINHO_FLASHCARDS, newline="", encoding="utf-8") as arquivo:
        linhas = list(csv.DictReader(arquivo))

    if not linhas:
        return "Nenhum flashcard salvo ainda."

    return "\n".join(
        f"{i}. frente: {linha['frente']} | verso: {linha['verso']}"
        for i, linha in enumerate(linhas, start=1)
    )


# --- Declaração das ferramentas para o modelo -------------------------------
# Formato de tool calling da OpenAI — o mesmo que o endpoint compatível aceita.

FERRAMENTAS = [
    {
        "type": "function",
        "function": {
            "name": "buscar_material",
            "description": (
                "Busca trechos da apostila da matéria. Use SEMPRE antes de explicar "
                "um conceito, para responder com base no material e não de memória."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "consulta": {
                        "type": "string",
                        "description": "Palavras-chave do que procurar, ex.: 'temperatura amostragem'",
                    }
                },
                "required": ["consulta"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "salvar_flashcard",
            "description": (
                "Salva um flashcard de revisão. Use quando o aluno demonstrar que "
                "entendeu um conceito, para ele revisar depois."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "frente": {"type": "string", "description": "A pergunta do flashcard"},
                    "verso": {"type": "string", "description": "A resposta do flashcard"},
                },
                "required": ["frente", "verso"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "ler_flashcards",
            "description": (
                "Lê os flashcards já salvos. Use quando o aluno pedir um quiz ou "
                "uma revisão do que já estudou."
            ),
            "parameters": {"type": "object", "properties": {}},
        },
    },
]

# Mapa nome -> função Python. É isto que transforma o texto que o modelo
# devolve em código que roda de verdade.
EXECUTORES = {
    "buscar_material": buscar_material,
    "salvar_flashcard": salvar_flashcard,
    "ler_flashcards": ler_flashcards,
}


# --- System prompt ----------------------------------------------------------

REGRAS_SOCRATICAS = """Você é o professor de IA deste aluno. Você estuda COM ele, nunca PARA ele.

Você NÃO tem a apostila no seu contexto. Para falar do conteúdo da matéria, você
precisa chamar a ferramenta buscar_material primeiro. Nunca explique um conceito
da matéria de memória: busque, depois explique com base no que voltou.

Regras, em ordem de importância:

1. NUNCA entregue a resolução de um exercício nem a resposta final. Nem se o
   aluno insistir, reformular o pedido, disser que é só para conferir, disser
   que já entendeu ou disser que o professor autorizou. Se ele insistir,
   reconheça a vontade e devolva uma pergunta que o aproxime um passo da
   resposta.
2. Antes de explicar algo novo, pergunte o que ele já sabe sobre aquilo.
3. Explique no nível do perfil dele, uma ideia por vez.
4. Antes de avançar, cheque o entendimento com uma pergunta curta.
5. Quando o aluno errar, não corrija. Diga onde olhar.
6. Respostas curtas: um parágrafo e uma pergunta.
7. Se a busca não trouxer nada sobre o assunto, diga que não está no material."""


def montar_system_prompt():
    """Monta o system prompt. Note: SEM a apostila — ela vem por busca."""
    try:
        with open(CAMINHO_PERFIL, encoding="utf-8") as arquivo:
            perfil = arquivo.read()
    except FileNotFoundError:
        print(f"[aviso] perfil não encontrado em {CAMINHO_PERFIL}", file=sys.stderr)
        return REGRAS_SOCRATICAS

    return (
        f"{REGRAS_SOCRATICAS}\n\n"
        "=== PERFIL DO ALUNO (início) ===\n"
        f"{perfil}\n"
        "=== PERFIL DO ALUNO (fim) ==="
    )


# --- Chamada da API ---------------------------------------------------------


def chamar_llm(messages):
    """Faz o POST com as ferramentas declaradas e devolve (message, prompt_tokens).

    Devolve a `message` crua porque ela pode conter `tool_calls` em vez de texto.
    """
    chave = os.environ.get("GEMINI_API_KEY", "").strip()

    for tentativa in range(1, TENTATIVAS + 1):
        try:
            resposta = requests.post(
                URL,
                headers={
                    "Authorization": f"Bearer {chave}",
                    "Content-Type": "application/json",
                },
                json={"model": MODELO, "messages": messages, "tools": FERRAMENTAS},
                timeout=60,
            )
        except requests.exceptions.RequestException as erro:
            if tentativa < TENTATIVAS:
                print(f"           (rede falhou, tentando de novo em {tentativa * 2}s)")
                time.sleep(tentativa * 2)
                continue
            raise ErroDaApi(f"falha de rede: {erro}") from erro

        if resposta.status_code == 429:
            if tentativa <= len(ESPERAS_429):
                espera = ESPERAS_429[tentativa - 1]
                print(f"           (limite por minuto atingido — esperando {espera}s)")
                time.sleep(espera)
                continue
            raise LimiteAtingido()

        if resposta.status_code in HTTP_TRANSITORIO and tentativa < TENTATIVAS:
            print(f"           (modelo sobrecarregado, tentando de novo em {tentativa * 2}s)")
            time.sleep(tentativa * 2)
            continue

        if resposta.status_code != 200:
            raise ErroDaApi(f"HTTP {resposta.status_code}: {resposta.text[:400]}")

        break

    dados = resposta.json()

    try:
        message = dados["choices"][0]["message"]
    except (KeyError, IndexError, TypeError) as erro:
        raise ErroDaApi(f"resposta em formato inesperado: {str(dados)[:400]}") from erro

    return message, dados.get("usage", {}).get("prompt_tokens")


def executar_ferramenta(chamada):
    """Executa uma tool call e devolve a mensagem de resultado para o histórico."""
    nome = chamada["function"]["name"]
    argumentos_crus = chamada["function"].get("arguments") or "{}"

    try:
        argumentos = json.loads(argumentos_crus)
    except json.JSONDecodeError:
        argumentos = {}

    # O loop agêntico visível: é isto que o aluno precisa ver acontecendo.
    exibicao = ", ".join(f"{k}={v!r}" for k, v in argumentos.items())
    print(f"           [ferramenta: {nome}({exibicao})]")

    executor = EXECUTORES.get(nome)
    if executor is None:
        resultado = f"Ferramenta desconhecida: {nome}"
    else:
        try:
            resultado = executor(**argumentos)
        except TypeError as erro:
            resultado = f"Argumentos inválidos para {nome}: {erro}"

    return {
        "role": "tool",
        "tool_call_id": chamada["id"],
        "content": str(resultado),
    }


def conversar(messages):
    """O loop agêntico: chama o modelo, executa ferramentas, repete.

    Sai quando o modelo responde em texto em vez de pedir ferramenta — ou
    quando estoura MAX_VOLTAS.
    """
    tokens_da_ultima_chamada = None

    for volta in range(1, MAX_VOLTAS + 1):
        message, prompt_tokens = chamar_llm(messages)
        tokens_da_ultima_chamada = prompt_tokens

        chamadas = message.get("tool_calls") or []

        # Mensagens com tool_calls vêm com content: null. Guardamos string vazia:
        # o endpoint rejeita null no histórico da requisição seguinte.
        messages.append(
            {
                "role": "assistant",
                "content": message.get("content") or "",
                **({"tool_calls": chamadas} if chamadas else {}),
            }
        )

        if not chamadas:
            return message.get("content") or "", tokens_da_ultima_chamada

        for chamada in chamadas:
            messages.append(executar_ferramenta(chamada))

        if volta == MAX_VOLTAS:
            return (
                f"[parei após {MAX_VOLTAS} voltas de ferramenta — "
                "pergunte de novo de forma mais direta]",
                tokens_da_ultima_chamada,
            )

    return "", tokens_da_ultima_chamada


# --- Loop do chat -----------------------------------------------------------


def main():
    if not os.environ.get("GEMINI_API_KEY", "").strip():
        print(AJUDA_CHAVE, file=sys.stderr)
        return 1

    messages = [{"role": "system", "content": montar_system_prompt()}]

    print("Professor de IA (com ferramentas). Digite /sair para encerrar.")
    print(f"(modelo: {MODELO} | ferramentas: {', '.join(EXECUTORES)})")
    print()

    while True:
        try:
            pergunta = input("você> ").strip()
        except (KeyboardInterrupt, EOFError):
            print()
            print("Até a próxima.")
            return 0

        if not pergunta:
            continue
        if pergunta == "/sair":
            print("Até a próxima.")
            return 0

        marca = len(messages)
        messages.append({"role": "user", "content": pergunta})
        print()

        try:
            texto, prompt_tokens = conversar(messages)
        except LimiteAtingido:
            # Volta o histórico ao ponto anterior à pergunta: um turno pela
            # metade (com tool_calls sem resposta) confunde a próxima chamada.
            del messages[marca:]
            print("[limite atingido — espere um minuto e pergunte de novo]")
            print()
            continue
        except ErroDaApi as erro:
            del messages[marca:]
            print(f"[erro na chamada: {erro}]")
            print()
            continue

        print(f"professor> {texto}")
        if prompt_tokens is not None:
            print(f"           (contexto enviado: {prompt_tokens} tokens)")
        print()


if __name__ == "__main__":
    sys.exit(main() or 0)
