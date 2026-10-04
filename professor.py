"""professor.py — um chat de terminal que estuda junto, no estilo Socrático.

Lê o material da matéria e o perfil do aluno, monta um system prompt com
regras de ensino, e conversa com o aluno pedindo um modelo de linguagem
através de uma chamada HTTP cru (requests).
"""

import os
import sys
import time

import requests

# Configuração via variáveis de ambiente — a chave nunca aparece no código.
URL = os.environ.get(
    "LLM_URL",
    "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
)
MODELO = os.environ.get("GEMINI_MODEL", "gemini-flash-latest")


def carregar_material():
    """Lê a apostila e a devolve envolta em tags delimitadoras."""
    caminho = "material/apostila.md"
    if not os.path.exists(caminho):
        # Avisa, mas não trava: o professor segue sem o material.
        print(f"Aviso: '{caminho}' não encontrado. Prosseguindo sem o material.",
              file=sys.stderr)
        return ""
    with open(caminho, encoding="utf-8") as f:
        conteudo = f.read()
    # As tags ajudam o modelo a saber onde o material começa e termina.
    return "=== MATERIAL DA MATÉRIA (início) ===\n" + conteudo + "\n=== MATERIAL DA MATÉRIA (fim) ==="


def carregar_perfil():
    """Lê o perfil do aluno e o devolve envolta em tags delimitadoras."""
    caminho = "perfil.md"
    if not os.path.exists(caminho):
        print(f"Aviso: '{caminho}' não encontrado. Prosseguindo sem perfil.",
              file=sys.stderr)
        return ""
    with open(caminho, encoding="utf-8") as f:
        conteudo = f.read()
    return "=== PERFIL DO ALUNO (início) ===\n" + conteudo + "\n=== PERFIL DO ALUNO (fim) ==="


def montar_system_prompt(material, perfil):
    """Junta material, perfil e as regras socráticas no system prompt."""
    prompt = f"""Você é um professor de IA que conversa pelo terminal. Siga estritamente estas regras:

1. NUNCA entregue a resolução de um exercício nem a resposta final — nem se o aluno insistir. Reformule o pedido e devolvia uma pergunta que puxe o raciocínio.
2. Antes de explicar algo novo, pergunte o que o aluno já sabe sobre aquilo.
3. Explique no nível do perfil do aluno, uma ideia por vez.
4. Cheque o entendimento com uma pergunta curta antes de avançar.
5. Quando o aluno errar, aponte onde olhar (seção do material, passo da conta) em vez de corrigir.
6. Respostas curtas: um parágrafo e uma pergunta.
7. Baseie-se no material. Se algo não estiver no material, avise explicitamente.

{material}

{perfil}
"""
    return prompt


def verificar_chave():
    """Valida a API key. Retorna True se ok, False se falta."""
    chave = os.environ.get("GEMINI_API_KEY", "").strip()
    if not chave:
        print("Falta a GEMINI_API_KEY.", file=sys.stderr)
        print("", file=sys.stderr)
        print("No Codespace: adicione o secret GEMINI_API_KEY e recrie o Codespace.", file=sys.stderr)
        print("No seu terminal: export GEMINI_API_KEY='sua-chave-aqui'", file=sys.stderr)
        print("Gere uma chave grátis em https://aistudio.google.com/apikey", file=sys.stderr)
        return False
    return True


def chamar_llm(messages):
    """
    Envia a lista inteira de mensagens para a API e devolve (texto, prompt_tokens).
    Retorna None em caso de 429 (após remover a pergunta do histórico).
    Levanta exceção apenas em erros não tratados.
    """
    corpo = {
        "model": MODELO,
        "messages": messages,
    }

    chave = os.environ["GEMINI_API_KEY"]

    # Estratégia de retry: 5xx/timeout -> tentar de novo (3 tentativas, com pausa).
    for tentativa in range(3):
        try:
            resposta = requests.post(
                URL,
                headers={
                    "Authorization": f"Bearer {chave}",
                    "Content-Type": "application/json",
                },
                json=corpo,
                timeout=60,
            )
        except requests.exceptions.RequestException as e:
            # Erro de rede ou timeout: retry como em 5xx.
            if tentativa < 2:
                # 2s na primeira falha, 4s na segunda.
                time.sleep(2 * (tentativa + 1))
                continue
            print(f"Erro de rede: {e}. Tente novamente mais tarde.", file=sys.stderr)
            return None

        # HTTP 429 — limite atingido: remove a pergunta e volta ao prompt.
        if resposta.status_code == 429:
            print("Limite atingido, espere um minuto.", file=sys.stderr)
            # Remove a última pergunta (user) para não reenviar sem resposta.
            if len(messages) > 1 and messages[-1]["role"] == "user":
                messages.pop()
            return None

        # HTTP 5xx — retry com backoff.
        if resposta.status_code in (500, 502, 503, 504):
            if tentativa < 2:
                time.sleep(2 * (tentativa + 1))
                continue
            print(f"Erro {resposta.status_code}: {resposta.text}. Tente novamente mais tarde.", file=sys.stderr)
            return None

        # Qualquer outro código de erro: informa e volta ao prompt.
        if resposta.status_code != 200:
            print(f"Erro HTTP {resposta.status_code}: {resposta.text}", file=sys.stderr)
            return None

        # Sucesso!
        dados = resposta.json()
        texto = dados["choices"][0]["message"]["content"].strip()
        uso = dados.get("usage", {})
        prompt_tokens = uso.get("prompt_tokens")
        return texto, prompt_tokens

    return None


def main():
    # Valida a chave antes de qualquer coisa.
    if not verificar_chave():
        return 1

    material = carregar_material()
    perfil = carregar_perfil()

    # messages[0] é sempre o system prompt — a "memória" é só reenvio de tudo.
    messages = [
        {"role": "system", "content": montar_system_prompt(material, perfil)},
    ]

    while True:
        try:
            pergunta = input("Você: ").strip()
        except EOFError:
            # Fim de entrada (Ctrl+D ou pipe esgotado): sai limpo.
            print()  # nova linha para não ficar grudado no prompt
            break
        except KeyboardInterrupt:
            # Ctrl+C: sai limpo, sem traceback.
            print()
            break

        if not pergunta:
            continue

        if pergunta == "/sair":
            break

        # Adiciona a pergunta do aluno ao histórico.
        messages.append({"role": "user", "content": pergunta})

        resultado = chamar_llm(messages)

        # 429 ou outro erro recuperável: a pergunta já foi removida por
        # chamar_llm; volta ao prompt.
        if resultado is None:
            continue

        texto, prompt_tokens = resultado

        # Adiciona a resposta do modelo — isso é a "memória".
        messages.append({"role": "assistant", "content": texto})

        print(f"Professor: {texto}")

        # Contador de tokens: cresce a cada turno porque reenviamos tudo.
        if prompt_tokens is not None:
            print(f"(contexto enviado: {prompt_tokens} tokens)")
        print()

    return 0


if __name__ == "__main__":
    sys.exit(main())
