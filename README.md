# Professor de IA — workshop

Três aulas de 45 minutos. No fim, você tem um professor de IA que estuda com você
a partir do material da sua matéria — e você entende cada linha dele.

| aula | o que você faz |
|---|---|
| **1** | vê uma requisição crua a um modelo: `01_chamada_minima.py` |
| **2** | conversa com o professor de IA dentro do OpenCode |
| **3** | pede ao OpenCode para construir esse professor em Python, a partir do `SPEC.md` |

---

# Antes da aula

São quatro passos. Faça **antes**, não no dia — os 45 minutos são para programar.

## 1. Pegue as duas chaves

As duas são **grátis** e **não pedem cartão**.

| chave | onde | começa com |
|---|---|---|
| `GEMINI_API_KEY` | https://aistudio.google.com/apikey → "Create API key" | `AIza` |
| `OPENROUTER_API_KEY` | https://openrouter.ai/keys → "Create API Key" | `sk-or-v1-` |

> A do OpenRouter **aparece uma vez só**. Se fechar sem copiar, apague e crie outra.

## 2. Instale o que precisa

**Python 3.9 ou mais novo** — confira com `python --version` (ou `python3 --version`).
Se não tiver: https://www.python.org/downloads/

**Git** — confira com `git --version`. Se não tiver: https://git-scm.com/downloads

**OpenCode:**

```bash
# macOS e Linux
curl -fsSL https://opencode.ai/install | bash
```

```powershell
# Windows (precisa de Node.js: https://nodejs.org)
npm install -g opencode-ai
```

> O `npm install -g opencode-ai` também funciona em macOS e Linux, se você já
> tiver Node e preferir.

Confira: `opencode --version`

## 3. Clone o repositório

```bash
git clone https://github.com/MaedaArthur/professor-ia.git
cd professor-ia
pip install -r requirements.txt
```

> Se `pip` não existir, tente `pip3`. Se der erro de permissão, use
> `pip install --user -r requirements.txt`.

## 4. Configure as chaves

As chaves vivem em **variáveis de ambiente** — nunca dentro de um arquivo do
repositório. Chave em commit é chave vazada.

**macOS / Linux:**

```bash
export GEMINI_API_KEY='sua-chave-do-gemini'
export OPENROUTER_API_KEY='sua-chave-do-openrouter'
```

**Windows (PowerShell):**

```powershell
$env:GEMINI_API_KEY='sua-chave-do-gemini'
$env:OPENROUTER_API_KEY='sua-chave-do-openrouter'
```

⚠️ **Isso vale só para a janela de terminal atual.** Fechou, sumiu.

Para não repetir a cada aula, há duas saídas:

<details>
<summary><b>macOS / Linux: use um arquivo .env</b></summary>

```bash
cp .env.example .env
# edite o .env e ponha as chaves

# carregue sempre que abrir um terminal novo:
set -a; . ./.env; set +a
```

O `.env` está no `.gitignore` — ele não vai para o repositório.
</details>

<details>
<summary><b>Deixar permanente</b></summary>

macOS/Linux: acrescente as linhas `export ...` no fim do seu `~/.bashrc` ou
`~/.zshrc`, e abra um terminal novo.

Windows: `[Environment]::SetEnvironmentVariable('GEMINI_API_KEY','sua-chave','User')`
e abra um PowerShell novo.
</details>

## Confira que deu certo

```bash
python 01_chamada_minima.py
```

Se imprimir JSON e uma resposta, está tudo pronto. Se reclamar da chave, volte
ao passo 4.

---

# As aulas

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

Aperte **Tab** até aparecer o agente **professor**. Então converse:

- "não entendi janela de contexto"
- "resolve o exercício 2 da apostila"  ← ele vai recusar, de propósito
- "o que eu te perguntei antes?"

Seu perfil de aprendizado está em `perfil.md`. Edite-o e veja a diferença no
jeito de explicar.

> O agente professor não escreve nem roda código — ele só ensina. Para programar,
> volte com **Tab** para o agente **Build**.

## Aula 3 — construir o professor

Leia o `SPEC.md`. Ele é a especificação do que você vai construir.

```bash
git switch -c minha-versao    # trabalhe na sua própria branch
rm professor.py               # começamos do zero
opencode
```

No agente **Build**, peça:

> Leia o SPEC.md e o AGENTS.md. Planeje em 5 passos como implementar o
> professor.py e me mostre o plano antes de escrever código.

Depois de aprovar o plano, deixe ele implementar. Para testar sem travar o
terminal:

```bash
printf 'o que é um token?\n/sair\n' | python professor.py
```

Os critérios de aceite estão na seção 4 do `SPEC.md`. Quando passar, guarde seu
trabalho:

```bash
git add professor.py
git commit -m "Meu professor de IA"
```

Terminou antes? A seção 5 do SPEC tem três extras.

---

# Modelos

O OpenCode está configurado com um modelo gratuito em `opencode.json`:

```json
"model": "openrouter/poolside/laguna-s-2.1:free"
```

**Se ele estiver fora do ar ou lento**, troque por um destes (todos `:free` e
todos com suporte a ferramentas, que o OpenCode exige):

| modelo | observação |
|---|---|
| `openrouter/cohere/north-mini-code:free` | focado em código |
| `openrouter/qwen/qwen3.8-27b:free` | generalista, rápido |
| `openrouter/nvidia/nemotron-3-super-120b-a12b:free` | modelo maior |
| `openrouter/poolside/laguna-xs-2.1:free` | versão menor do padrão |

Troque no `opencode.json` ou, dentro do OpenCode, com o comando `/models`.

> A lista muda com frequência. A lista viva está em
> **https://openrouter.ai/models?max_price=0** — filtre por "Tools".

## Os limites

**OpenRouter**, modelos `:free`, conta sem crédito comprado:
**20 requisições por minuto** e **50 por dia**.

Cada mensagem sua no OpenCode pode gastar **mais de uma** requisição — ele chama
o modelo de novo a cada ferramenta que usa. Em teste, construir o `professor.py`
inteiro do zero gastou **11 requisições**. Cabe, mas pense antes de mandar.

Acompanhe em **https://openrouter.ai/activity**.

**Gemini**, free tier: o limite é **por minuto** e é baixo — três perguntas
seguidas já podem dar erro `429`. O `professor.py` espera e tenta de novo
sozinho. Se insistir, espere um minuto.

---

# ⚠️ Privacidade: não coloque dado pessoal

No **nível gratuito** da API do Gemini, os termos do Google dizem que o conteúdo
enviado é usado para treinar e melhorar os produtos deles — e que **revisores
humanos podem ler** a entrada e a saída da API.

Os próprios termos dizem: *"Do not submit sensitive, confidential, or personal
information to the Unpaid Services."*

Na prática:

- **Não** coloque nome completo, matrícula, e-mail, CPF ou telefone no `perfil.md`.
- **Não** cole prova, trabalho não publicado, laudo, contrato ou dado de empresa.
- O `perfil.md` que vem no repo é fictício de propósito. Adapte o conteúdo
  (curso, nível, como você aprende) sem se identificar.

Termos completos: https://ai.google.dev/gemini-api/terms

---

# Problemas

**`opencode: command not found`**
No macOS/Linux o binário fica em `~/.opencode/bin`. Rode
`export PATH="$HOME/.opencode/bin:$PATH"` e, para não repetir, ponha essa linha
no seu `~/.bashrc` ou `~/.zshrc`. Se instalou pelo npm, confira com `npm list -g`.

**`python: command not found`**
Tente `python3`. No Windows, reinstale o Python marcando "Add Python to PATH".

**`ModuleNotFoundError: No module named 'requests'`**
Faltou o passo 3: `pip install -r requirements.txt`.

**`Falta a GEMINI_API_KEY`**
A variável não está no terminal atual. Refaça o passo 4 — e lembre que ela some
quando você fecha o terminal.

**Erro 429 no `professor.py`**
Limite por minuto do Gemini. O programa já espera e tenta de novo. Se insistir,
espere um minuto.

**Erro 503 "high demand" no `professor.py`**
O modelo do Google está sobrecarregado — não é problema seu nem da sua chave.
O programa repete sozinho. Se insistir, troque de modelo:
`GEMINI_MODEL=gemini-flash-lite-latest python professor.py`

**O OpenCode pede para fazer login num provedor**
Ele lê a `OPENROUTER_API_KEY` do ambiente. Se a variável não estiver no terminal
atual, ele não acha credencial — refaça o passo 4. Em último caso, dentro do
OpenCode use `/connect` e cole a chave na mão.

**O professor me deu a resposta do exercício**
Acontece com modelo pequeno. Reforce a regra 1 no system prompt e repita o teste.
