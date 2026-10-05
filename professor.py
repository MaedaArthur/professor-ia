"""Professor de IA — esqueleto.

Um chat de terminal que estuda com o aluno a partir do material da matéria.

A especificação está em SPEC.md. Cada função abaixo tem o requisito
correspondente anotado no docstring. Implemente uma por vez.

ATENÇÃO: este programa espera input do teclado. Não o rode de forma
interativa durante o desenvolvimento — ele trava esperando você digitar.
Para testar, use:

    python -c "import professor; print(professor.carregar_material()[:200])"
    printf 'o que é um token?\n/sair\n' | python professor.py
"""

import os
import sys

import requests

try:
    from dotenv import load_dotenv

    load_dotenv()  # lê o .env da raiz: nenhum export à mão, em nenhum terminal
except ImportError:
    pass  # sem python-dotenv, vale o que já estiver no ambiente

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


def carregar_material():
    """R1 — Lê material/apostila.md e devolve o conteúdo como string.

    Se o arquivo não existir, avise e devolva string vazia (o programa deve
    continuar funcionando sem o material).
    """
    # TODO: abrir CAMINHO_MATERIAL com encoding="utf-8" e devolver o texto.
    # TODO: tratar FileNotFoundError.
    raise NotImplementedError("carregar_material — veja R1 no SPEC.md")


def carregar_perfil():
    """R2 — Lê perfil.md e devolve o conteúdo como string.

    Mesmo tratamento de erro de carregar_material.
    """
    # TODO: igual a carregar_material, mas com CAMINHO_PERFIL.
    raise NotImplementedError("carregar_perfil — veja R2 no SPEC.md")


def montar_system_prompt(material, perfil):
    """R1 + R2 + R3 — Monta o system prompt completo.

    Precisa conter três coisas:
      1. o material, delimitado (ex.: "=== MATERIAL (início) ===" ... fim)
      2. o perfil do aluno, delimitado
      3. as sete regras socráticas do R3

    Devolve uma string.
    """
    # TODO: escrever as regras socráticas (R3, itens 1 a 7).
    # TODO: interpolar material e perfil entre delimitadores claros.
    raise NotImplementedError("montar_system_prompt — veja R3 no SPEC.md")


def chamar_llm(messages):
    """Seção 2 do SPEC — Faz o POST e devolve (texto, prompt_tokens).

    - POST em URL com header Authorization: Bearer <GEMINI_API_KEY>
    - corpo: {"model": MODELO, "messages": messages}
    - texto da resposta: choices[0].message.content
    - tokens de entrada: usage.prompt_tokens (leia de forma defensiva)

    Em caso de HTTP 429, sinalize para quem chamou que foi limite de taxa
    (R6) — por exemplo devolvendo None ou levantando uma exceção própria.
    """
    # TODO: ler a chave de os.environ.
    # TODO: requests.post(..., timeout=60).
    # TODO: tratar status 429 e outros erros sem quebrar o programa.
    raise NotImplementedError("chamar_llm — veja a seção 2 do SPEC.md")


def main():
    """R4 + R5 — O loop do chat.

    1. verifica a GEMINI_API_KEY; se faltar, explica como configurar (R6)
    2. monta o system prompt e inicia a lista `messages` com ele
    3. loop: lê a pergunta, adiciona em `messages`, envia a lista INTEIRA,
       adiciona a resposta em `messages`, imprime o prompt_tokens (R4)
    4. `/sair`, Ctrl+C e EOF encerram limpo (R5)
    """
    # TODO: implementar o loop conforme R4 e R5.
    raise NotImplementedError("main — veja R4, R5 e R6 no SPEC.md")


if __name__ == "__main__":
    sys.exit(main() or 0)
