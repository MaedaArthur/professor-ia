# Professor de IA — workshop

Três aulas de 45 minutos. No fim, você tem um professor de IA que estuda com você
a partir do material da sua matéria — e você entende cada linha dele.

| aula | o que você faz |
|---|---|
| **1** | vê uma requisição crua a um modelo: `01_chamada_minima.py` |
| **2** | conversa com o professor de IA dentro do OpenCode |
| **3** | pede ao OpenCode para construir esse professor em Python, a partir do `SPEC.md` |

---

## Antes da aula: as duas chaves

Você precisa de duas chaves de API. As duas são **grátis** e **não pedem cartão**.

### 1. `GEMINI_API_KEY` — para o código Python

1. Entre em **https://aistudio.google.com/apikey**
2. "Create API key"
3. Copie a chave

### 2. `OPENROUTER_API_KEY` — para o OpenCode

1. Entre em **https://openrouter.ai/keys**
2. Crie a conta e clique em "Create key"
3. Copie a chave

### Guardar as chaves no GitHub

Guarde as duas como **Codespaces secrets**, não num arquivo:

1. Vá em **https://github.com/settings/codespaces**
2. Em "Codespaces secrets" → **New secret**
3. Crie `GEMINI_API_KEY` e dê acesso a este repositório
4. Repita para `OPENROUTER_API_KEY`

> Nunca coloque uma chave dentro de um arquivo do repositório. Chave em commit é
> chave vazada.

## Abrir o Codespace

No GitHub, neste repositório: botão verde **Code** → aba **Codespaces** → **Create
codespace on main**.

Se as chaves já estiverem nos secrets, o GitHub as injeta automaticamente. Se não,
ele pede na tela de criação (é o campo `secrets` do `.devcontainer/devcontainer.json`).

A primeira abertura leva alguns minutos: ele instala o Python, o `requests` e o
OpenCode. Quando terminar, confira:

```bash
opencode --version
echo "gemini: ${GEMINI_API_KEY:+ok}"
echo "openrouter: ${OPENROUTER_API_KEY:+ok}"
```

Os dois últimos comandos devem imprimir `ok`. Se imprimirem vazio, a chave não
chegou — veja "Problemas" no fim deste arquivo.

---

## Aula 1 — é só um POST

```bash
python 01_chamada_minima.py
```

Ele mostra o JSON que sai, o JSON que volta e a contagem de tokens. Olhe o
`prompt_tokens`: é por ali que a conta é cobrada.

## Aula 2 — conversar com o professor

```bash
opencode
```

Dentro do OpenCode, aperte **Tab** até aparecer o agente **professor**. Então
converse:

- "não entendi janela de contexto"
- "resolve o exercício 2 da apostila"  ← ele vai recusar, de propósito
- "o que eu te perguntei antes?"

Seu perfil de aprendizado está em `perfil.md`. Edite-o e veja a diferença no jeito
de explicar.

> O agente professor não escreve nem roda código — ele só ensina. Para programar,
> volte com **Tab** para o agente **Build**.

## Aula 3 — construir o professor

Leia o `SPEC.md`. Ele é a especificação do que você vai construir.

```bash
opencode
```

No agente **Build**, peça algo como:

> Leia o SPEC.md e o AGENTS.md. Planeje em 5 passos como implementar o
> professor.py e me mostre o plano antes de escrever código.

Depois de aprovar o plano, deixe ele implementar. Para testar sem travar o
terminal:

```bash
printf 'o que é um token?\n/sair\n' | python professor.py
```

Os critérios de aceite estão na seção 4 do `SPEC.md`. Terminou antes? A seção 5
tem três extras.

---

## Modelos

O OpenCode está configurado com um modelo gratuito em `opencode.json`:

```json
"model": "openrouter/poolside/laguna-s-2.1:free"
```

**Se ele estiver fora do ar ou lento**, troque por um destes (todos `:free` e todos
com suporte a ferramentas, que o OpenCode exige):

| modelo | observação |
|---|---|
| `openrouter/cohere/north-mini-code:free` | focado em código |
| `openrouter/qwen/qwen3.8-27b:free` | generalista, rápido |
| `openrouter/nvidia/nemotron-3-super-120b-a12b:free` | modelo maior |
| `openrouter/poolside/laguna-xs-2.1:free` | versão menor do padrão |

Troque no `opencode.json` ou, dentro do OpenCode, com o comando `/models`.

> A lista de modelos gratuitos do OpenRouter muda com frequência. A lista viva está
> em **https://openrouter.ai/models?max_price=0** — filtre por "Tools" se o modelo
> for usado pelo OpenCode.

### Limite dos modelos gratuitos

Nos modelos `:free` do OpenRouter, uma conta sem créditos comprados tem:

- **20 requisições por minuto**
- **50 requisições por dia**

Cada mensagem sua no OpenCode pode gastar **mais de uma** requisição (ele chama o
modelo de novo a cada ferramenta que usa). Então: pense antes de mandar, e use
mensagens com contexto em vez de muitas mensagens curtas.

Acompanhe o seu gasto em **https://openrouter.ai/activity**.

Se bater o limite, você verá um erro **429**. Espere um minuto (ou até o dia
seguinte, se foi o limite diário) ou troque de modelo.

---

## ⚠️ Privacidade: não coloque dado pessoal

No **nível gratuito** da API do Gemini, os termos do Google dizem que o conteúdo
que você envia é usado para treinar e melhorar os produtos deles — e que
**revisores humanos podem ler** a entrada e a saída da API.

Os próprios termos dizem: *"Do not submit sensitive, confidential, or personal
information to the Unpaid Services."*

Na prática, para este workshop:

- **Não** coloque nome completo, matrícula, e-mail, CPF ou telefone no `perfil.md`.
- **Não** cole prova, trabalho não publicado, laudo, contrato ou dado de empresa.
- O `perfil.md` que vem no repo é fictício de propósito. Adapte o conteúdo
  (curso, nível, como você aprende) sem se identificar.

Termos completos: https://ai.google.dev/gemini-api/terms

---

## Problemas

**`opencode: command not found`**
O binário fica em `~/.opencode/bin`. Rode `export PATH="$HOME/.opencode/bin:$PATH"`.
Se persistir, o `postCreateCommand` falhou: veja o log em **Codespaces: View Creation
Log** na paleta de comandos (`Ctrl+Shift+P`).

**`echo "gemini: ${GEMINI_API_KEY:+ok}"` imprime vazio**
O secret não chegou. Confira em https://github.com/settings/codespaces que o
secret existe **e** que este repositório está na lista de acesso dele. Depois
**recrie o Codespace** — secret novo não entra em Codespace já criado.

**O OpenCode pede para fazer login num provedor**
Não deveria: ele lê a `OPENROUTER_API_KEY` do ambiente. Se a variável estiver
vazia, ele não acha credencial. Confira o `echo` acima. Em último caso, dentro do
OpenCode use `/connect` e cole a chave do OpenRouter na mão.

**Erro 429 no `professor.py`**
Limite do Gemini. Espere um minuto e tente de novo.

**O professor me deu a resposta do exercício**
Acontece com modelo pequeno. Reforce a regra 1 no system prompt do `professor.py`
(ou em `.opencode/agents/professor.md`, na aula 2) e repita o teste.
