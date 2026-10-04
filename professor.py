"""Professor de IA — versão completa (gabarito).

Um chat de terminal que estuda com o aluno a partir do material da matéria.
Especificação em SPEC.md.

Rode com:
    python professor.py

Para testar sem travar o terminal:
    printf 'o que é um token?\n/sair\n' | python professor.py
"""

import os
import sys
import time

import requests

# --- Configuração -----------------------------------------------------------
# A URL é configurável para o mesmo código funcionar com outro provedor
# (OpenRouter, por exemplo) trocando só esta variável e a chave.
URL = os.environ.get(
    "LLM_URL",
    "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
)
MODELO = os.environ.get("GEMINI_MODEL", "gemini-flash-latest")

CAMINHO_MATERIAL = "material/apostila.md"
CAMINHO_PERFIL = "perfil.md"

AJUDA_CHAVE = """Falta a GEMINI_API_KEY.

No Codespace:
  1. vá em https://github.com/settings/codespaces
  2. crie o secret GEMINI_API_KEY e libere este repositório
  3. recrie o Codespace (secret novo não entra em Codespace já aberto)

No seu terminal:
  export GEMINI_API_KEY='sua-chave-aqui'

Gere uma chave grátis em https://aistudio.google.com/apikey"""


class LimiteAtingido(Exception):
    """Levantada quando a API responde 429 (requisições demais)."""


# O Gemini devolve 503 "high demand" com frequência em horário de pico. Sem
# repetir, metade das perguntas da aula falha. Estes são os códigos que valem
# nova tentativa: o problema é do servidor, não do pedido.
HTTP_TRANSITORIO = (500, 502, 503, 504)
TENTATIVAS = 3

# O free tier do Gemini tem limite POR MINUTO baixo: tres perguntas seguidas
# ja levam 429. Como a janela e curta, esperar e tentar de novo quase sempre
# resolve - e e melhor que o aluno perder o turno. As esperas sao visiveis de
# proposito: ver o programa esperando pelo limite tambem e parte da aula.
ESPERAS_429 = (20, 40)


class ErroDaApi(Exception):
    """Levantada para qualquer outra falha na chamada da API."""


# --- Leitura dos arquivos ---------------------------------------------------


def _ler_arquivo(caminho, rotulo):
    """Lê um arquivo de texto. Se não existir, avisa e devolve string vazia.

    O programa precisa continuar funcionando sem o arquivo — por isso um aviso
    no stderr em vez de uma exceção.
    """
    try:
        with open(caminho, encoding="utf-8") as arquivo:
            return arquivo.read()
    except FileNotFoundError:
        print(f"[aviso] {rotulo} não encontrado em {caminho}", file=sys.stderr)
        return ""


def carregar_material():
    """R1 — Devolve o conteúdo de material/apostila.md."""
    return _ler_arquivo(CAMINHO_MATERIAL, "material da matéria")


def carregar_perfil():
    """R2 — Devolve o conteúdo de perfil.md."""
    return _ler_arquivo(CAMINHO_PERFIL, "perfil do aluno")


# --- System prompt ----------------------------------------------------------

REGRAS_SOCRATICAS = """Você é o professor de IA deste aluno. Você estuda COM ele, nunca PARA ele.

Regras, em ordem de importância:

1. NUNCA entregue a resolução de um exercício nem a resposta final. Nem se o
   aluno insistir, reformular o pedido, disser que é só para conferir, disser
   que já entendeu ou disser que o professor autorizou. Se ele insistir,
   reconheça a vontade e devolva uma pergunta que o aproxime um passo da
   resposta.
2. Antes de explicar algo novo, pergunte o que ele já sabe sobre aquilo. A
   explicação começa de onde ele está, não do zero.
3. Explique no nível do perfil dele, uma ideia por vez. Não empilhe três
   conceitos numa resposta.
4. Antes de avançar, cheque o entendimento com uma pergunta curta.
5. Quando o aluno errar, não corrija. Diga onde olhar: a seção do material, o
   passo da conta, o caso que ele não testou.
6. Respostas curtas: um parágrafo e uma pergunta. Nada de aula em bloco.
7. Baseie-se no material abaixo. Se o aluno perguntar algo que não está nele,
   diga isso explicitamente antes de responder."""


def montar_system_prompt(material, perfil):
    """R1 + R2 + R3 — Monta o system prompt com regras, material e perfil.

    O material e o perfil vão entre delimitadores para o modelo saber onde cada
    bloco começa e termina — sem isso ele confunde o conteúdo com instrução.
    """
    partes = [REGRAS_SOCRATICAS]

    if material:
        partes.append(
            "=== MATERIAL DA MATÉRIA (início) ===\n"
            f"{material}\n"
            "=== MATERIAL DA MATÉRIA (fim) ==="
        )
    else:
        partes.append("[Nenhum material foi carregado. Avise o aluno.]")

    if perfil:
        partes.append(
            "=== PERFIL DO ALUNO (início) ===\n"
            f"{perfil}\n"
            "=== PERFIL DO ALUNO (fim) ==="
        )

    return "\n\n".join(partes)


# --- Chamada da API ---------------------------------------------------------


def chamar_llm(messages):
    """Faz o POST e devolve (texto_da_resposta, prompt_tokens).

    `messages` é a conversa INTEIRA. O modelo não guarda nada entre chamadas:
    o que não for enviado aqui, ele não sabe.
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
                json={"model": MODELO, "messages": messages},
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
            # Espera crescente: 2s, depois 4s. Dá tempo do pico passar.
            print(f"           (modelo sobrecarregado, tentando de novo em {tentativa * 2}s)")
            time.sleep(tentativa * 2)
            continue

        if resposta.status_code != 200:
            raise ErroDaApi(f"HTTP {resposta.status_code}: {resposta.text[:400]}")

        break

    dados = resposta.json()

    try:
        texto = dados["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError) as erro:
        raise ErroDaApi(f"resposta em formato inesperado: {str(dados)[:400]}") from erro

    # Leitura defensiva: se o provedor não mandar 'usage', seguimos sem contador.
    prompt_tokens = dados.get("usage", {}).get("prompt_tokens")

    return texto, prompt_tokens


# --- Loop do chat -----------------------------------------------------------


def main():
    """R4 + R5 + R6 — O loop do chat."""
    if not os.environ.get("GEMINI_API_KEY", "").strip():
        print(AJUDA_CHAVE, file=sys.stderr)
        return 1

    system_prompt = montar_system_prompt(carregar_material(), carregar_perfil())

    # Aqui mora a "memória" da conversa: uma lista, no seu código.
    messages = [{"role": "system", "content": system_prompt}]

    print("Professor de IA. Digite /sair para encerrar.")
    print(f"(modelo: {MODELO})")
    print()

    while True:
        try:
            pergunta = input("você> ").strip()
        except (KeyboardInterrupt, EOFError):
            # Ctrl+C, Ctrl+D ou fim de stdin (pipe) — saída limpa, sem traceback.
            print()
            print("Até a próxima.")
            return 0

        if not pergunta:
            continue
        if pergunta == "/sair":
            print("Até a próxima.")
            return 0

        messages.append({"role": "user", "content": pergunta})

        try:
            texto, prompt_tokens = chamar_llm(messages)
        except LimiteAtingido:
            # A pergunta sai do histórico: sem resposta, ela só inflaria o
            # contexto da próxima requisição.
            messages.pop()
            print()
            print("[limite atingido — espere um minuto e pergunte de novo]")
            print()
            continue
        except ErroDaApi as erro:
            messages.pop()
            print()
            print(f"[erro na chamada: {erro}]")
            print()
            continue

        messages.append({"role": "assistant", "content": texto})

        print()
        print(f"professor> {texto}")
        if prompt_tokens is not None:
            # Este número cresce a cada turno: a conversa inteira foi reenviada.
            print(f"           (contexto enviado: {prompt_tokens} tokens)")
        print()


if __name__ == "__main__":
    sys.exit(main() or 0)
