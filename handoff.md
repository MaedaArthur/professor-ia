# Handoff: Workshop de IA, o deck

> Terceiro handoff deste projeto. O primeiro, que fechou a direção visual, está
> preservado em `handoff-01-direcao-visual.md`. O segundo construiu o deck de 104
> slides. Este aqui é o estado atual: a sessão que **cortou, reequilibrou e
> separou o setup**.

## O que é este projeto

Um workshop de IA para alunos de graduação, **135 minutos**, lidos agora como
**três aulas de 45**. O material (apostila, SPEC, repositório do aluno) já
existia. O deck foi construído na segunda sessão e reestruturado nesta.

O estudo de caso é o **professor de IA**: um chat de terminal socrático que
estuda com o aluno a partir do material da matéria e se recusa a entregar
resposta pronta.

**Tudo mora no repositório que vai para os alunos**, `professor-ia/`, publicado
em github.com/MaedaArthur/professor-ia, branch `main`.

## Leia primeiro

```
professor-ia/slides/deck.html       o deck, 97 slides, arquivo único
professor-ia/slides/README.md       a sintaxe de autoria e os arquétipos
professor-ia/SETUP.md               a pré-tarefa: o aluno faz em casa
professor-ia/prompts/               5 prompts prontos para copiar
professor-ia/setup.sh  setup.ps1    instalam tudo, um por sistema
plano-das-aulas.md                  o plano minuto a minuto
.design/branding/workshop-ia/       o brief, o estado e a spec do mascote
```

Para abrir o deck: `open professor-ia/slides/deck.html`.
Setas navegam, `#12.3` reabre no slide 13 passo 3 (o índice do hash é base zero,
então `#12` abre o décimo terceiro), `p` imprime tudo, `?audit=1` roda a
auditoria de layout.

## As três aulas

A quebra é marcada com `@aula: 1|2|3` no primeiro slide de cada parte. O parser
joga diretiva desconhecida em `s.meta` e nenhum renderizador lê `@aula`, então
**ela não aparece na tela e não quebra nada**: é marcação para quem apresenta.

| aula | slides | quantos | onde o marcador está |
|---|---|---|---|
| 1 | 1 a 31 | 31 | slide 1, a capa |
| 2 | 32 a 75 | 44 | slide 32, um `pergunta`, não um `titulo` |
| 3 | 76 a 89 | 14 | slide 76, `titulo`, "degrau 3" |
| apêndice | 90 a 97 | 8 | slide 90, "Apêndice · setup" |

A aula 1 termina em "cada chamada começa do zero" (slide 31), que é o gancho
para as quatro peças.

**Franqueza sobre o ritmo:** a aula 2 caiu de 60 para 44 slides, o que resolve o
desequilíbrio entre as três, mas em 45 minutos ela continua a mais apertada
(cerca de 1 minuto por slide, com cinco mãos no teclado dentro). Se tiver que
cortar mais, corte dela.

## O setup virou pré-tarefa

Era 8 slides ao vivo (os antigos 20 a 28), que comiam o começo da aula. Agora:

- **`SETUP.md` na raiz do repositório** é o passo a passo em texto corrido, para
  mandar ao aluno **uma semana antes**. Tem os dois sistemas, as duas chaves
  passo a passo, onde o `.env` mora, o modelo `:free` do OpenCode e o teste
  final com `01_chamada_minima.py`.
- **No corpo da aula sobraram dois slides**: o 16, que diz "você já fez em casa,
  vamos conferir", e o 17, o teste que prova que funcionou.
- **Os 7 slides de passo a passo foram para o apêndice** (91 a 97), atrás de um
  slide de título. Ficam para consulta e para quem chegar sem ter feito.

## O `.env` é lido sozinho

Mudança desta sessão, e ela **invalidou instrução que estava em cinco lugares**.
Os três scripts Python (`01_chamada_minima.py`, `professor.py`,
`professor_extras.py`) carregam o `.env` da raiz por conta própria:

```python
try:
    from dotenv import load_dotenv

    load_dotenv()  # lê o .env da raiz: nenhum export à mão, em nenhum terminal
except ImportError:
    pass  # sem python-dotenv, vale o que já estiver no ambiente
```

O `try/except` é de propósito: na máquina em que o `pip install` falhou, o
programa ainda roda com o que estiver no ambiente, em vez de morrer com
traceback de import.

`python-dotenv==1.2.1` está fixado no `requirements.txt`, e **a versão é
load-bearing**: da 1.2.2 em diante o pacote declara `requires-python >=3.10`, e
este projeto suporta 3.9. Sem o pino, um aluno em 3.9 receberia a 1.2.4 e
quebraria. Não solte esse pino sem olhar isso de novo.

Saiu de: slide 96 do deck, `setup.sh`, `setup.ps1`, `README.md` e nunca entrou
no `SETUP.md`. A receita antiga (`set -a; . ./.env; set +a`) **não existe mais
em lugar nenhum** do repositório.

## Como o deck funciona

Arquivo único, sem build, sem servidor. O conteúdo é markdown dentro de um
`<script type="text/x-slides">` no próprio HTML, com slides separados por `===`.

**Diretivas por slide:** `@type` (o arquétipo), `@n` (numeração, regerada por
script quando se insere slide), `@piece` (prompt/memoria/ferramentas/loop),
`@tema` (o assunto, que alimenta o índice), `@aula`, `@acende`, `@cap`, `@soft`,
`@num`, `@lado: nao`, `@voltas`, `@virada`, `@foto`, `@quem: voce`.

**Blocos:** `# título`, `## subtítulo`, `::lede::`, `::quote::`, `::step::`,
`::row::`, `::note::`, `::esq::`/`::dir::`, `::big::`, `::subzinho::`,
`::rodape::`. `::quote::` e `::step::` aparecem a cada clique.
Código entre crases triplas, com `«guillemets»` para destacar uma linha.

**14 arquétipos**, documentados em `slides/README.md`:
`codigo 26 · pergunta 13 · titulo 11 · mecanismo 11 · aovivo 9 · pratica 8 ·
comparacao 4 · leva 4 · medicao 3 · capa 2 · mascote 2 · pecas 2 · quemsou 1 ·
progressao 1`.

### Três limites do renderizador que mordem quem edita

Descobertos na dura, nesta sessão. **Leia antes de mover conteúdo entre tipos.**

1. **`medicao` só imprime `::big::` e o PRIMEIRO `::lede::`.** Nada de `#`, `##`
   ou `::quote::`. Foi por isso que o conteúdo do antigo slide 57 teve que
   caber dentro do lede único do 43, em vez de virar um bloco próprio.
2. **`pecas` imprime `h2`, não `h1`.** Título de `titulo` que migra para `pecas`
   tem que virar `##`, senão desaparece sem aviso.
3. **`preClass` troca o corpo do bloco de código por contagem de linha**:
   `> 15 linhas` cai em `xxs`, `> 12` em `xs`, `> 7` em `sm`. Isso não é
   monotônico do jeito que a intuição diz: **tirar uma linha de um bloco de 16
   aumenta a altura dele**, porque sobe de `xxs` para `xs`. Me custou uma
   rodada: a árvore do slide 92 estourava 3px com 16 linhas e passou a estourar
   18px com 15.

### A auditoria

`?audit=1` percorre os 97 slides, revela todos os passos e mede estouro de
altura, de largura **e dentro do bloco de código**. O limiar é 2px. Escreve o
resultado em `document.body[data-audit]`. Rode sempre depois de mexer em
conteúdo:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless \
  --disable-gpu --no-sandbox --virtual-time-budget=16000 \
  --dump-dom "file://$PWD/professor-ia/slides/deck.html?audit=1" 2>/dev/null \
  | grep -o 'data-audit="[^"]*"'
```

Hoje responde `AUDIT OK [total 97]`. Ela já pegou defeitos que passavam
despercebidos a olho, então **não confie no olho sozinho**. Nesta sessão ela
pegou cinco estouros que eu tinha acabado de criar, todos invisíveis na tela.

## Decisões já tomadas (não reabra sem motivo)

- **São três aulas de 45, mas o documento é contínuo.** Sem capa de ato, sem
  cabeçalho de aula, sem numeração que reinicia: `@n` corre de 1 a 97, apêndice
  incluído. A quebra existe só como `@aula` para quem apresenta.
- **Base clara, código em bloco escuro.** Decisão de projeção, não de gosto: a
  sala é clara e o projetor é comum, então fundo escuro vira cinza lavado.
- **Nunca slide de bullet.** Se precisa de lista, vira vários slides. É o que o
  tipo `pratica` faz com as boas práticas.
- **Nunca travessão.** Vírgula, dois-pontos ou parênteses. Vale para tudo:
  deck, prompts, README, scripts, SETUP.md, este arquivo.
- **Nenhuma referência numérica a slide no texto falado.** O deck não diz "como
  no slide 51", porque qualquer corte mente. Diz "a progressão de antes". Tem um
  `grep` para isso na seção de verificação.
- **Tipografia:** Bricolage Grotesque na display, IBM Plex Mono em todo número e
  código. Papel `#F6F3EC`, tinta `#1B1A17`, acento óxido `#9C3B28`.
- **Teoria e prática intercalam.** Cada peça fecha com o aluno no teclado, e os
  slides práticos mostram o transcript esperado, para servirem sozinhos se a
  demo ao vivo falhar.
- **Três degraus**, cada um útil sozinho: usar melhor (prompt colado, sem
  código), usar bem o agente (contexto, plano, permissão, diff, worktree,
  handoff), construir o seu (SPEC → OpenCode).
- **A escolha de modelo é conteúdo, não rodapé.** Entrou nesta sessão como três
  slides mais uma prática "0 · modelo", porque a decisão que o loop multiplica
  merece estar antes do prompt, não depois.

### O Nozinho

O mascote é um emaranhado de tinta **gerado**, não desenhado: orbita um miolo
protegido, então o traço nunca colide com os olhos em nenhuma densidade (folga
mínima medida: 5,94 unidades). A spec completa está em
`.design/branding/workshop-ia/identity/MASCOTE.md`.

A narrativa dele é um arco único. Com a reestruturação, a curva é esta:

```
slide   1    1,50 voltas    começa frouxo
slide  64    3,80           pico, no slide "Lembra do Nozinho?" (@virada)
slide  88    2,13           último slide de conteúdo
slide  97    1,50           fim do apêndice
```

**Isto é uma concessão consciente, decidida nesta sessão.** O desenovelar é
calculado com `SLIDES.length`, então os 8 slides de apêndice esticam o
denominador e o arco não fecha mais em 1,50 no fim da aula: fecha em 2,13, e só
chega a 1,50 no fim do apêndice (que é consulta, e onde o nó mais frouxo não
significa nada). As saídas eram fixar `@voltas` à mão nos últimos slides do
corpo ou mudar duas linhas de JS para o desenovelar terminar antes do apêndice.
**Optou-se por aceitar.** Se um dia incomodar, é ali que se mexe.

Ele mora no índice do rodapé, que tem **dois modos**: lista os oito assuntos até
as peças começarem e passa a listar as quatro peças depois disso. Os oito
assuntos continuam oito, na mesma ordem: motivação, demonstração, usar melhor,
setup, o modelo, o agente, construir, fecho.

**Efeito colateral conhecido:** os slides 56 a 62 (o desvio de "desvio curto" e
a escolha de modelo) têm `@tema`, não `@piece`, e estão no meio da corrida das
peças. Então o rodapé volta ao índice dos assuntos por sete slides e depois
retorna às peças. **Esse comportamento já existia** antes da mudança (o mesmo
bloco ficava entre memória e ferramentas, por quatro slides); a mudança só o
deixou mais longo. Se quiser eliminar, é dar `@piece: loop` a esses sete.

### O Subzinho

Aparece uma vez, no slide 2, como credencial. É SVG inline **copiado 1:1 do
produto**: `BODY_PATH` e a expressão `contente` de
`VendAI/ai-core-referral-context/front/src/features/copilot/subzinho/model.ts`,
com as animações `grant-subzinho` e `subzinho-swing` do `index.css` de lá.
A cara certa são **dois arcos**, sem esclera, sem pupila e sem sorriso: a versão
com olho redondo e boca é de um mock antigo e está errada.

## Defeitos que já foram caçados (não reintroduza)

| defeito | causa |
|---|---|
| realce de Python vazando `"k">def` na tela | a regex de string casava com os atributos `class="k"` que a própria função inserira. Resolvido com tokenização em duas passadas |
| código cortado sem aviso | o `<pre>` é item flex e era espremido em silêncio. Resolvido com `flex-shrink: 0`, e a auditoria passou a medir dentro dele |
| mascote sem olhos a partir de certo slide | a classe `balled` vazava quando se avançava com uma viagem no ar |
| mascote parado num canto | `placeMascot` recebia string vazia e caía num ponto fixo |
| ponta da seta solta do corpo | `border-left` transparente ocupando espaço |
| auditoria morrendo calada | `var TEMAS` declarado depois do uso, e redeclarado zerando a lista |
| bloco de código engordando ao perder uma linha | `preClass` escolhe o corpo por faixa de contagem de linha, e 16 linhas cai numa faixa menor que 15 |

**Lição de processo:** todo patch por script usa `assert` antes de substituir.
Duas vezes uma substituição falhou em silêncio e o sintoma só apareceu minutos
depois, em outro lugar. A reestruturação desta sessão foi feita assim: um script
que indexa os slides por `@n`, afirma o conteúdo de cada um antes de tocar, e
falha barulhento se o deck não for o que ele pensa que é.

## O que falta

1. **`setup.ps1` nunca rodou num Windows de verdade**, e agora menos ainda: ele
   foi editado nesta sessão (as duas linhas que ensinavam a exportar chave à
   mão) **sem que o parser do PowerShell rodasse**, porque não existe `pwsh`
   nesta máquina. A edição é de baixo risco (dois literais `Info '...'` com
   aspas simples e sem apóstrofo dentro) e a varredura estática de aspas está
   limpa, mas **rode numa máquina Windows antes da aula**.
2. **O deck nunca foi cronometrado.** 97 slides para 135 minutos, divididos
   31/44/14, dá 1,4 min por slide, mas os slides com passos consomem mais, e a
   aula 2 é a apertada. A ordem de corte está em `plano-das-aulas.md`.
3. **A branch `gabarito` está defasada do `main`.** Ela não tem `prompts/`,
   `slides/`, `setup.sh`, `setup.ps1`, `SETUP.md` nem `handoff.md`, então o
   `git switch gabarito` que o slide 80 manda fazer **apaga os slides e os
   prompts do diretório do aluno**. Decidiu-se nesta sessão **não** consertar
   agora. Além disso, o `professor.py` e o `professor_extras.py` de lá **não
   têm** o carregamento do `.env`, então quem cair no gabarito volta a precisar
   exportar a chave à mão. Trazer o `main` para dentro dela resolve as duas
   coisas de uma vez.
4. **Travessões em arquivos antigos.** `apostila.md`, `SPEC.md`, `professor.py`,
   `README.md` e mais alguns. Tudo que foi escrito nesta sessão e na anterior
   está em zero.
5. **O slide do `usage`** (os 75 tokens de pensamento descartado, slide 57) é
   onde o Nozinho poderia enovelar como explicação, não como transição: o
   emaranhado é o pensamento, a bolinha é o token que sobra. Anotado na spec,
   não construído.
6. **Tokens não extraídos.** As cores e escalas vivem como custom properties no
   `:root` do `deck.html`. Virar um `STYLE.md` é trabalho de
   `/gsp-brand-guidelines`, se valer a pena.

## TODO: a coerência do "modelo que não raciocina"

**Este é o único item desta sessão que ficou aberto, e ele é de conteúdo.**

O slide 59 manda "escolha o modelo que não raciocina" e o slide 62 descreve o
professor como "flash, sem pensar". Fui verificar se dá para cumprir isso na API
compatível com OpenAI do Gemini. **Dá para confirmar na documentação que não
dá.** Nada disso foi testado rodando: não há chave nesta máquina.

O que a doc oficial diz:

- `reasoning_effort` **é** aceito nesse endpoint, inclusive em REST cru, e
  `extra_body.google.thinking_config` também (há exemplo `curl` oficial).
- Mas `reasoning_effort: "none"` **só existe para os modelos 2.5**, e
  `thinking_budget: 0` idem. O enum `ThinkingLevel` tem `MINIMAL`, `LOW`,
  `MEDIUM`, `HIGH`: **não existe `NONE`**.
- `thinking_budget` está **deprecado para Gemini 3 e posteriores**, e usá-lo lá
  pode dar `400: INVALID_ARGUMENT` **intermitente**, que é o pior
  comportamento possível numa aula (passa na demo, quebra no exercício).
- Os modelos 2.5, os únicos onde desligar funciona, estão **restritos a quem já
  os usava**, desde 18/09/2026. Chave nova de aluno provavelmente não acessa.
- `gemini-flash-latest` tem thinking **ligado por padrão** em qualquer candidato
  a que ele resolva. A última nota oficial de troca de alias é de 19/05/2026
  (`gemini-3.5-flash`), e três Flash novos saíram depois sem registro público,
  então **não se sabe ao certo o que ele resolve hoje**. Alias em material
  didático é escolha ruim por construção: troca o modelo embaixo de você, e com
  ele trocam os níveis aceitos.
- O Flash-Lite atual, `gemini-3.5-flash-lite`, é **grátis** no free tier, mas o
  default dele é `On (minimal)`, que já é o piso. Não dá para ir abaixo, e não
  achei nenhuma afirmação oficial sobre qualidade em português.
- A aritmética do slide 57 **está certa**: na API nativa, `totalTokenCount` é
  `prompt + thoughts + response`, e `thoughtsTokenCount` existe e é cobrado. Mas
  a página de compatibilidade OpenAI **não documenta o objeto `usage`**, então
  que `completion_tokens_details.reasoning_tokens` apareça nesse endpoint é
  **não confirmado**.

**O código ficou como estava**, conforme combinado. O que falta é decisão sua,
e são duas:

1. **A frase.** "O modelo que não raciocina" não é alcançável com o que a turma
   vai usar. O mínimo honesto é "o modelo que raciocina **menos**", no slide 59
   e no 62 ("flash, no piso de raciocínio" em vez de "flash, sem pensar"). É
   troca de palavra, não de estrutura.
2. **O modelo.** Se quiser fugir do alias, fixe `gemini-3.5-flash-lite` (grátis,
   já no piso). Exige rodar antes: confirmar qualidade em português e ver se o
   `usage` daquele endpoint reporta os tokens de pensamento em campo separado.

## Números reais, medidos em ensaio

| | |
|---|---|
| construir o `professor.py` do zero com agente | **11 requisições** |
| apostila inteira no system prompt | **2154 tokens/turno** |
| com busca por seção | **1667 tokens/turno** (−23%) |
| Gemini free, resposta `"ok"` | `prompt 4 + completion 1 = total 80` |
| turno k da progressão | `400 + 200k` tokens |
| acumulado em 10 turnos | **15.000 tokens** |
| OpenRouter `:free`, conta nova | 20/min, 50/dia |
| Gemini free | limite **por minuto**, baixo |

**Ressalva sobre a linha do `"ok"`:** os `4 / 1 / 80` **não foram reconferidos
nesta sessão** (não há chave na máquina). Vieram do ensaio anterior e estão nos
slides 57 e 58 como estão. Se você for citar de viva voz como medição fresca,
rode uma vez antes:

```bash
cd professor-ia
python3 -c "
import importlib.util
spec = importlib.util.spec_from_file_location('m', '01_chamada_minima.py')
m = importlib.util.module_from_spec(spec)
m.PERGUNTA = 'ok'
spec.loader.exec_module(m)
"
```

A conta da progressão (`400 + 200k`, acumulado 15.000) é aritmética, não
medição, e está conferida: turno 1 = 600, turno 10 = 2400, soma dos dez = 15.000.

## Risco: limite diário do OpenRouter

Conta nova no `:free` do OpenRouter tem **20 requisições por minuto e 50 por
dia**. A aula encosta nesse teto, e vale saber antes de descobrir ao vivo:

```
hands-on do professor (as conversas da aula)      ~15 a 25 requisições
construir o professor.py com o agente             11 requisições
um aluno que refaz porque não gostou              +11
                                                  ------------------
                                                  perto de 50
```

Quem errar o caminho duas vezes **bate o teto e para**, e o erro não parece
limite: parece que o código quebrou. Duas saídas, as duas precisam ser
preparadas antes da aula:

1. **Crédito numa conta compartilhada.** Dez dólares numa conta do OpenRouter
   tiram o limite diário do caminho. A chave vira a mesma para a sala, o que é
   ruim de higiene e ótimo de logística.
2. **Apontar o OpenCode para a chave do Gemini.** O aluno já tem uma, e ela é
   grátis. O limite do Gemini free é **por minuto**, não por dia, então ele
   atrapalha a rajada e não mata a aula. O `opencode.json` precisa do provedor
   trocado, e isso **não está escrito em lugar nenhum ainda**.

A saída 2 é a melhor para a turma e é a que exige trabalho. Se a aula for amanhã,
vai na 1.

## Como verificar antes de dizer que terminou

```bash
cd professor-ia/slides

# 1. o JS parseia
python3 -c "import re;src=open('deck.html',encoding='utf-8').read();\
open('/tmp/d.js','w').write(re.findall(r'<script>\n(.*?)\n</script>',src,re.S)[-1])"
node --check /tmp/d.js

# 2. nenhum travessão
grep -c "$(printf '\\u2014')" deck.html    # tem que dar 0
# (o caractere vai por printf para este arquivo nao conter nenhum)

# 3. nenhuma referência numérica a slide no texto falado
grep -c "slide [0-9]" deck.html           # tem que dar 0

# 4. a numeração é corrida, sem buraco nem repetição
python3 -c "
import re
s = open('deck.html', encoding='utf-8').read()
ns = re.findall(r'^@n: (\d+)\$', s, re.M)
assert ns == [str(i) for i in range(1, len(ns) + 1)], 'numeracao furada'
print('numeracao ok:', len(ns), 'slides')
"

# 5. nenhum slide estoura
#    (o comando da auditoria está na seção "A auditoria", acima)
```

E confira na tela: a auditoria mede caixa, não gosto.

Nos scripts Python, antes de dizer que terminou:

```bash
cd professor-ia
python3 -m py_compile 01_chamada_minima.py professor.py professor_extras.py
bash -n setup.sh
SETUP_DRY_RUN=1 bash setup.sh      # não toca a rede, não escreve chave
```
