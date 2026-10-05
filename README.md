# Professor de IA, workshop

Um encontro só, de 135 minutos, contínuo. No fim você tem um professor de IA que
estuda com você a partir do material da sua matéria, e entende cada linha dele.

Ao longo do encontro você vai, nesta ordem:

- ver uma requisição crua a um modelo rodando no seu terminal (`01_chamada_minima.py`);
- conversar com o professor de IA dentro do OpenCode e mexer no perfil dele;
- apagar o `professor.py` e pedir ao OpenCode para construí-lo de novo, do zero,
  a partir do `SPEC.md`;
- testar o que saiu contra os critérios de aceite do SPEC.

Não há divisão em partes nem intervalo marcado no material. É um fio só.

---

# Antes do encontro

Faça o setup **antes**, não no dia. O tempo do encontro é para programar.

São três coisas: pegar as duas chaves, clonar o repositório e rodar o script de
setup.

## 1. Pegue as duas chaves

As duas são **grátis** e **não pedem cartão**.

| chave | onde | começa com |
|---|---|---|
| `GEMINI_API_KEY` | https://aistudio.google.com/apikey, botão "Create API key" | `AIza` |
| `OPENROUTER_API_KEY` | https://openrouter.ai/keys, botão "Create API Key" | `sk-or-v1-` |

> A do OpenRouter **aparece uma vez só**. Se fechar a página sem copiar, apague a
> chave e crie outra.

Deixe as duas num lugar que você consiga colar depois (um editor de texto aberto
serve). O script vai pedir as duas.

## 2. Clone o repositório

```bash
git clone https://github.com/MaedaArthur/professor-ia.git
cd professor-ia
```

Se o `git` não existir na sua máquina, instale antes: https://git-scm.com/downloads

## 3. Rode o script de setup

Este é o caminho principal. Escolha a linha do seu sistema, rode de dentro da
pasta `professor-ia`:

```bash
# macOS e Linux
bash setup.sh
```

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File setup.ps1
```

O script faz o seguinte, nesta ordem:

1. confere se você tem **Python 3.9 ou mais novo** e **Git**, e diz onde baixar
   se faltar algum;
2. instala a dependência do projeto (`requirements.txt`, que é só o `requests`);
3. instala o **OpenCode**;
4. pede as duas chaves de API, uma por vez, e grava as duas no arquivo `.env`.

O `.env` está no `.gitignore`, então ele não vai para o repositório. Chave em
commit é chave vazada.

<details>
<summary><b>Se o script falhar: o procedimento manual, passo a passo</b></summary>

### Python

**Python 3.9 ou mais novo.** Confira com `python --version` (ou `python3 --version`).
Se não tiver: https://www.python.org/downloads/

### Dependências

```bash
pip install -r requirements.txt
```

> Se `pip` não existir, tente `pip3`. Se der erro de permissão, use
> `pip install --user -r requirements.txt`.

### OpenCode

```bash
# macOS e Linux
curl -fsSL https://opencode.ai/install | bash
```

```powershell
# Windows (precisa de Node.js: https://nodejs.org)
npm install -g opencode-ai
```

O `npm install -g opencode-ai` também funciona em macOS e Linux, se você já tiver
Node e preferir.

Confira com `opencode --version`.

### As chaves

As chaves vivem em **variáveis de ambiente**, nunca dentro de um arquivo do
repositório.

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

Para não digitar isso toda vez, no macOS e no Linux copie o modelo de arquivo de
chaves e preencha:

```bash
cp .env.example .env
# edite o .env e ponha as chaves
```

</details>

## 4. Carregue as chaves no terminal

⚠️ **Variável de ambiente vale só para a janela de terminal atual.** Fechou,
sumiu. Isso vale também para as chaves que o script gravou no `.env`: o arquivo
fica guardado, mas cada terminal novo precisa carregá-lo.

**macOS / Linux**, em todo terminal novo, de dentro da pasta do projeto:

```bash
set -a; . ./.env; set +a
```

<details>
<summary><b>Deixar permanente, para não carregar a cada vez</b></summary>

macOS e Linux: acrescente as linhas `export ...` no fim do seu `~/.bashrc` ou
`~/.zshrc`, e abra um terminal novo.

Windows:

```powershell
[Environment]::SetEnvironmentVariable('GEMINI_API_KEY','sua-chave','User')
[Environment]::SetEnvironmentVariable('OPENROUTER_API_KEY','sua-chave','User')
```

Depois abra um PowerShell novo.
</details>

## 5. Confira que deu certo

```bash
python 01_chamada_minima.py
```

Se imprimir um JSON e uma resposta do modelo, está pronto. Se reclamar da chave,
volte ao passo 4: provavelmente a variável não está neste terminal.

---

# A estrutura do repositório

```
professor-ia/
├── README.md                     este guia, o que você está lendo agora
├── SPEC.md                       a especificação do professor.py, a fonte da verdade
├── AGENTS.md                     contexto técnico do repo, o OpenCode lê sozinho
├── setup.sh                      setup automático no macOS e no Linux
├── setup.ps1                     setup automático no Windows
├── requirements.txt              a única dependência Python, o requests
├── opencode.json                 configuração do OpenCode: modelo e permissões
├── .env.example                  modelo do arquivo de chaves, copie para .env
├── .gitignore                    o que o Git não deve subir, o .env está nele
├── 01_chamada_minima.py          uma requisição HTTP crua ao modelo, o exemplo de partida
├── professor.py                  o professor pronto, que você vai apagar e reescrever
├── perfil.md                     seu perfil de aprendizado, fictício de propósito
├── material/
│   └── apostila.md               o conteúdo da matéria que o professor usa
├── prompts/
│   ├── README.md                 índice: qual prompt usar em cada momento
│   ├── 01-estudo-guiado.md       faz uma IA qualquer estudar com você
│   ├── 02-meu-perfil.md          modelo de perfil de aprendizado para preencher
│   ├── 03-plano-antes-do-codigo.md  pede o plano antes de deixar escrever código
│   ├── 04-handoff.md             passa o estado para uma sessão nova
│   └── 05-testar-o-professor.md  os testes que provam que o professor atende o SPEC
├── slides/
│   ├── README.md                 como navegar o deck e como escrever slides nele
│   ├── deck.html                 o deck do workshop, abre direto no navegador
│   ├── prototipo.html            banco de testes do mascote, não é o deck
│   └── retrato.png               o retrato do slide de apresentação
├── .opencode/
│   └── agents/
│       └── professor.md          o agente professor: as regras de ensino dele
└── .git/                         o histórico do Git, você não mexe aqui
```

## slides/

O deck do workshop é o `slides/deck.html`. É um arquivo único: abra no navegador,
sem servidor e sem instalar nada.

- as **setas** navegam, avançando passo a passo dentro do slide antes de trocar;
- a tecla **`p`** monta o deck paginado e abre o diálogo de impressão, que é como
  você gera o PDF.

O `slides/README.md` tem o resto: como voltar a um slide específico pela URL e
como escrever slides novos.

## prompts/

Prompts prontos para copiar e colar, um por arquivo `.md`. São cinco: o de estudo
guiado, o modelo de perfil de aprendizado, o pedido de plano antes do código, o
handoff para uma sessão nova e os testes do professor. O `prompts/README.md` diz
qual usar em cada momento.

---

# O que você faz no encontro

## Ver a requisição crua

```bash
python 01_chamada_minima.py
```

Ele mostra o JSON que sai, o JSON que volta e a contagem de tokens. Olhe o
`prompt_tokens`: é por ali que a conta é cobrada.

## Conversar com o professor

```bash
opencode
```

Aperte **Tab** até aparecer o agente **professor**. Então converse:

- "não entendi janela de contexto"
- "resolve o exercício 2 da apostila" (ele vai recusar, de propósito)
- "o que eu te perguntei antes?"

Seu perfil de aprendizado está em `perfil.md`. Edite e veja o jeito de explicar
mudar.

> O agente professor não escreve nem roda código, ele só ensina. Para programar,
> volte com **Tab** para o agente **Build**.

## Construir o professor

Leia o `SPEC.md`. Ele é a especificação do que você vai construir.

```bash
git switch -c minha-versao    # trabalhe na sua própria branch
rm professor.py               # começamos do zero
opencode
```

No agente **Build**, peça o plano antes do código (o prompt pronto está em
`prompts/03-plano-antes-do-codigo.md`):

> Leia o SPEC.md e o AGENTS.md. Planeje em 5 passos como implementar o
> professor.py e me mostre o plano antes de escrever código.

Depois de aprovar o plano, deixe ele implementar.

## Testar

Para testar sem travar o terminal, alimente a entrada:

```bash
printf 'o que é um token?\n/sair\n' | python professor.py
```

Os critérios de aceite estão na seção 4 do `SPEC.md`, e o roteiro de testes
pronto está em `prompts/05-testar-o-professor.md`. Quando passar, guarde seu
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
> **https://openrouter.ai/models?max_price=0**, filtre por "Tools".

## Os limites

**OpenRouter**, modelos `:free`, conta sem crédito comprado:
**20 requisições por minuto** e **50 por dia**.

Cada mensagem sua no OpenCode pode gastar **mais de uma** requisição: ele chama o
modelo de novo a cada ferramenta que usa. Em teste, construir o `professor.py`
inteiro do zero gastou **11 requisições**. Cabe, mas pense antes de mandar.

Acompanhe em **https://openrouter.ai/activity**.

**Gemini**, free tier: o limite é **por minuto** e é baixo, três perguntas
seguidas já podem dar erro `429`. O `professor.py` espera e tenta de novo
sozinho. Se insistir, espere um minuto.

---

# ⚠️ Privacidade: não coloque dado pessoal

No **nível gratuito** da API do Gemini, os termos do Google dizem que o conteúdo
enviado é usado para treinar e melhorar os produtos deles, e que **revisores
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
No macOS e no Linux o binário fica em `~/.opencode/bin`. Rode
`export PATH="$HOME/.opencode/bin:$PATH"` e, para não repetir, ponha essa linha
no seu `~/.bashrc` ou `~/.zshrc`. Se instalou pelo npm, confira com `npm list -g`.

**`python: command not found`**
Tente `python3`. No Windows, reinstale o Python marcando "Add Python to PATH".

**`ModuleNotFoundError: No module named 'requests'`**
As dependências não foram instaladas. Rode `pip install -r requirements.txt`.

**`Falta a GEMINI_API_KEY`**
A variável não está no terminal atual. Refaça o passo 4, e lembre que ela some
quando você fecha o terminal.

**Erro 429 no `professor.py`**
Limite por minuto do Gemini. O programa já espera e tenta de novo. Se insistir,
espere um minuto.

**Erro 503 "high demand" no `professor.py`**
O modelo do Google está sobrecarregado, não é problema seu nem da sua chave.
O programa repete sozinho. Se insistir, troque de modelo:
`GEMINI_MODEL=gemini-flash-lite-latest python professor.py`

**O OpenCode pede para fazer login num provedor**
Ele lê a `OPENROUTER_API_KEY` do ambiente. Se a variável não estiver no terminal
atual, ele não acha credencial, refaça o passo 4. Em último caso, dentro do
OpenCode use `/connect` e cole a chave na mão.

**O professor me deu a resposta do exercício**
Acontece com modelo pequeno. Reforce a regra 1 no system prompt e repita o teste.
