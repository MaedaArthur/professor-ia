"""Aula 1 — a requisição mínima.

Uma única chamada HTTP a um modelo de linguagem. Sem SDK, sem framework:
é só um POST com um JSON dentro.

Rode com:
    python 01_chamada_minima.py
"""

import json
import os
import sys

import requests

# A URL é configurável de propósito: o mesmo código funciona com OpenRouter
# trocando só LLM_URL e a chave. Este é o endpoint do Gemini compatível com
# o formato da OpenAI.
URL = os.environ.get(
    "LLM_URL",
    "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
)
MODELO = os.environ.get("GEMINI_MODEL", "gemini-flash-latest")

PERGUNTA = "Explique em dois parágrafos o que é um token para um modelo de linguagem."


def main():
    chave = os.environ.get("GEMINI_API_KEY", "").strip()
    if not chave:
        print("Falta a GEMINI_API_KEY.", file=sys.stderr)
        print("", file=sys.stderr)
        print("No Codespace: adicione o secret GEMINI_API_KEY e recrie o Codespace.", file=sys.stderr)
        print("No seu terminal: export GEMINI_API_KEY='sua-chave-aqui'", file=sys.stderr)
        print("Gere uma chave grátis em https://aistudio.google.com/apikey", file=sys.stderr)
        return 1

    # Este dicionário é tudo o que o modelo recebe. Mais nada.
    corpo = {
        "model": MODELO,
        "messages": [
            {"role": "user", "content": PERGUNTA},
        ],
    }

    print("=" * 70)
    print("ENVIADO (é isso que vai dentro do POST):")
    print("=" * 70)
    print(json.dumps(corpo, indent=2, ensure_ascii=False))

    resposta = requests.post(
        URL,
        headers={
            "Authorization": f"Bearer {chave}",
            "Content-Type": "application/json",
        },
        json=corpo,
        timeout=60,
    )

    print()
    print("=" * 70)
    print(f"STATUS HTTP: {resposta.status_code}")
    print("=" * 70)

    if resposta.status_code != 200:
        print(resposta.text)
        return 1

    dados = resposta.json()

    print()
    print("=" * 70)
    print("RESPOSTA (o texto que o modelo gerou):")
    print("=" * 70)
    print(dados["choices"][0]["message"]["content"])

    # O 'usage' é onde a conta aparece. Tudo é medido em tokens, não em palavras.
    uso = dados.get("usage", {})
    print()
    print("=" * 70)
    print("TOKENS:")
    print("=" * 70)
    if uso:
        print(f"  entrada (prompt_tokens):     {uso.get('prompt_tokens')}")
        print(f"  saída   (completion_tokens): {uso.get('completion_tokens')}")
        print(f"  total   (total_tokens):      {uso.get('total_tokens')}")
    else:
        print("  o modelo não devolveu o campo 'usage' nesta resposta")

    print()
    print("JSON cru da resposta:")
    print(json.dumps(dados, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
