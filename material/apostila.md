# Como um modelo de linguagem funciona

Apostila curta da matéria. Tudo que o professor de IA sabe vem daqui.

## Tokens

Um modelo de linguagem não lê letras nem palavras: lê **tokens**. Um token é um
pedaço de texto, geralmente entre 3 e 4 caracteres em português. A palavra
"computador" pode virar dois ou três tokens; "o" é um token; um espaço em branco
costuma vir junto com a palavra seguinte.

Isso tem duas consequências práticas. Primeira: contar palavras não serve para
estimar custo — a conta é em tokens. Uma regra de bolso razoável para português
é **1 token para cada 3 caracteres**, ou cerca de 750 palavras a cada 1000
tokens. Segunda: o modelo não "vê" a grafia de uma palavra do jeito que você vê,
e por isso erra tarefas como contar letras.

Antes de sair do modelo, o texto é convertido de volta de tokens para
caracteres. Todo número que você vê em conta de API — entrada, saída, limite de
contexto — está em tokens, não em palavras.

## Previsão do próximo token

O modelo faz **uma coisa só**: dado o texto até agora, estimar qual é o próximo
token mais provável. Ele produz uma distribuição de probabilidade sobre todos os
tokens possíveis do vocabulário, escolhe um, acrescenta ao texto, e repete.

Uma frase de 50 tokens é, portanto, 50 passos desse processo — cada passo lendo
tudo que veio antes, incluindo o que o próprio modelo acabou de escrever. Não
existe um plano guardado em algum lugar: a resposta é construída token a token.

É daí que vem o comportamento mais confuso dos LLMs. O modelo não consulta uma
base de fatos e não sabe se está certo — ele produz a continuação mais provável.
Quando a continuação mais provável é falsa, sai uma afirmação errada dita com
total confiança. Isso costuma ser chamado de **alucinação**.

## Temperatura

A **temperatura** controla o quanto a escolha do próximo token se afasta do mais
provável.

Com temperatura 0, o modelo sempre escolhe o token de maior probabilidade. A
resposta fica estável e repetível: a mesma pergunta tende a dar a mesma resposta.
Com temperatura alta (perto de 1, ou acima), tokens menos prováveis ganham
chance. A resposta fica mais variada — e também mais propensa a erro e a fugir
do assunto.

Não existe valor certo, existe valor adequado à tarefa. Extrair um CPF de um
documento pede temperatura baixa. Gerar dez nomes para um projeto pede
temperatura mais alta. Note que temperatura alta não deixa o modelo mais
criativo no sentido de mais inteligente — deixa a amostragem mais aleatória.

## Janela de contexto

A **janela de contexto** é o limite de tokens que cabe numa requisição. Ela conta
tudo junto: a instrução de sistema, o material que você colou, todo o histórico
da conversa e a resposta que está sendo gerada.

Quando a conversa passa do limite, algo precisa sair. Na prática, descarta-se o
início do histórico, resume-se o que passou, ou a requisição é recusada. Nenhuma
dessas saídas é invisível: o modelo passa a não ter mais acesso ao que foi dito
no começo.

Janela grande não é o mesmo que atenção boa. Informação enterrada no meio de um
contexto muito longo tende a ser menos usada do que a mesma informação colocada
no início ou no fim.

## Memória é só reenvio de mensagens

Aqui está a parte que mais surpreende: **o modelo não guarda nada entre
requisições**. Cada chamada de API é independente e começa do zero.

Quando um chat parece lembrar do que você disse, o que aconteceu foi que o
programa guardou as mensagens anteriores numa lista e **reenviou a lista inteira**
na requisição seguinte. A "memória" mora no seu código, não no modelo.

Um turno de conversa, visto de perto:

```
requisição 1  ->  [sistema, pergunta_1]
requisição 2  ->  [sistema, pergunta_1, resposta_1, pergunta_2]
requisição 3  ->  [sistema, pergunta_1, resposta_1, pergunta_2, resposta_2, pergunta_3]
```

Repare que a pergunta 1 é enviada de novo em todas as requisições seguintes. Se
você apagar a lista, o modelo não tem como lembrar — não houve esquecimento,
houve simplesmente nada enviado.

## Custo cresce com o histórico

Juntando as duas seções anteriores: se cada requisição reenvia a conversa
inteira, e se a cobrança é por token de entrada, então **o custo de um turno
cresce conforme a conversa anda**.

Com uma instrução de sistema de 500 tokens e turnos de 100 tokens cada, a
entrada de cada requisição fica mais ou menos assim:

| turno | tokens de entrada |
|---|---|
| 1 | 600 |
| 2 | 800 |
| 3 | 1000 |
| 10 | 2400 |

O gasto total de uma conversa de N turnos cresce com o **quadrado** de N, não de
forma linear. Uma conversa de 20 turnos custa muito mais que o dobro de uma de 10.

Daí as técnicas para controlar isso: resumir o histórico antigo em vez de
reenviar literalmente; cortar os turnos mais velhos; e — a mais eficaz — **não
colocar todo o material no contexto**, e sim deixar o modelo buscar só os
trechos de que precisa.

## Raciocínio: quando o modelo pensa antes de responder

Alguns modelos, antes de escrever a resposta, geram um texto intermediário que
você não vê: o **raciocínio**. São tokens como quaisquer outros — gerados um a
um, pela mesma previsão do próximo token — só que descartados da resposta final.

Isso tem dois efeitos. O bom: em problema de várias etapas, o modelo que
"pensa" erra menos, porque escreveu os passos antes de concluir. O ruim: você
paga por eles e espera por eles.

Um exemplo medido nesta matéria. Pedimos a um modelo Flash do Gemini que
respondesse apenas `ok`. O que voltou na conta de tokens:

```
prompt_tokens: 4      completion_tokens: 1      total_tokens: 80
```

Quatro de entrada, um de saída — e oitenta no total. Os **75 tokens que faltam
são raciocínio**: o modelo pensou setenta e cinco tokens para dizer "ok". Se
você somar entrada e saída e achar que fechou a conta, vai errar por vinte
vezes.

Daí a regra prática: **para tarefa simples, prefira o modelo que não raciocina**.
Extrair um campo de um texto não precisa de deliberação, e o modelo que pensa
cobra e demora igual.

## Ferramentas: o modelo pede, o seu código executa

Um modelo de linguagem só produz texto. Ele não lê arquivo, não acessa a
internet e não roda comando. Então como é que um assistente de IA faz essas
coisas?

A resposta é mais simples do que parece. Você manda, junto com a pergunta, uma
lista de **ferramentas** disponíveis: o nome de cada uma, o que ela faz e quais
argumentos aceita — tudo em JSON. O modelo então pode, em vez de responder ao
usuário, devolver uma mensagem dizendo *"chame `buscar_material` com a consulta
'temperatura'"*.

Repare no que **não** aconteceu: o modelo não buscou nada. Ele só escreveu um
pedido, em texto, no formato que você combinou. Quem abre o arquivo e procura é
o seu programa. O resultado volta para o modelo como mais uma mensagem no
histórico, e aí ele responde ao usuário.

Isso se chama **tool calling**, e é a peça que separa um chat de um agente. O
modelo continua só prevendo o próximo token — mas agora alguns desses tokens
são ordens que o seu código obedece.

## O loop agêntico

Com ferramentas, uma pergunta deixa de ser uma requisição e vira um **loop**:

```
repita:
    mande o histórico para o modelo
    ele pediu ferramenta?
        não  -> essa é a resposta final, mostre e saia
        sim  -> execute, ponha o resultado no histórico, repita
```

É isso. Um `while`, uma lista de mensagens e um `if`. Quando alguém diz que um
agente "decidiu" buscar um arquivo, foi isso que aconteceu: o modelo pediu, o
loop executou, o resultado voltou para o contexto.

Duas consequências práticas. Primeira: **cada volta é uma requisição cobrada**.
Uma pergunta que precisa de três ferramentas custa quatro chamadas, não uma.
Segunda: **o loop precisa de um limite**. Um modelo confuso pede ferramenta
para sempre, e sem um teto de voltas o seu programa gira até acabar a sua cota.

## Agentes de terminal

Um agente de terminal — Claude Code, Codex, OpenCode — é exatamente o loop
acima, com um catálogo maior de ferramentas: ler arquivo, escrever arquivo,
rodar comando, buscar na web, procurar texto no projeto.

Quando você pede "implemente o que está no SPEC.md", o que acontece é uma
sequência de voltas: ele pede para ler o `SPEC.md`, lê; pede para listar os
arquivos, lista; pede para escrever o `professor.py`, escreve; pede para rodar
o teste, roda. Cada passo desses é uma volta do mesmo `while`.

Por isso dois conselhos que parecem triviais e não são. **Dê o contexto antes
de pedir**: cada arquivo que ele precisa descobrir sozinho é uma volta a mais,
cobrada e demorada. E **controle as permissões**: escrever arquivo e rodar
comando são ferramentas como as outras, e nada impede o modelo de pedir a
errada. Um agente bem configurado pergunta antes de rodar comando.

## Instruções reutilizáveis: AGENTS.md, SPEC e skills

Você já viu que o comportamento de um agente vem do texto que ele recebe. O
passo seguinte é não reescrever esse texto toda vez.

Um arquivo `AGENTS.md` na raiz do projeto é carregado em toda conversa: é o
lugar das regras que valem sempre (a linguagem, o estilo, o que nunca fazer).
Um `SPEC.md` descreve uma tarefa específica com detalhe suficiente para alguém
executar sem perguntar. E uma **skill** é a forma empacotada dessa ideia:
instrução guardada que o agente carrega quando a tarefa aparece, em vez de
ficar sempre no contexto.

É a mesma economia da seção de custo: o que está sempre no contexto é pago
sempre. Instrução que só serve para uma tarefa deve ser carregada só naquela
tarefa.

## MCP: publicar as suas ferramentas

As ferramentas que você escreve ficam presas no seu programa. A busca na sua
apostila só o seu professor usa.

O **MCP** (Model Context Protocol) é um protocolo que resolve isso: você expõe
suas ferramentas num servidor, e qualquer agente que fale MCP — o Claude, o
Codex, o agente de um colega — passa a poder chamá-las. A declaração em JSON é
a mesma; muda só quem pode enxergar.

É a diferença entre **usar** ferramenta e **fornecer** ferramenta. Quem fornece
entra no fluxo de trabalho dos outros.

## Medições desta matéria

Números medidos por nós, nesta matéria, com conta gratuita. Eles não estão em
nenhum livro — são deste contexto.

**Custo de contexto no professor de IA**

| versão | tokens de entrada por turno |
|---|---|
| apostila inteira no system prompt | 2154 |
| com busca por seção (ferramenta) | **1667** |

23% a menos, e a diferença cresce conforme a apostila cresce. É a justificativa
concreta para dar ferramenta de busca ao agente em vez de despejar tudo no
contexto.

**Construir o professor com um agente de terminal**

Pedir a um agente de terminal que implementasse o `professor.py` do zero, a
partir do `SPEC.md`, custou **11 requisições** e alguns minutos. O código saiu
funcionando. Serve de referência para estimar: uma tarefa de um arquivo, bem
especificada, custa cerca de dez voltas do loop.

**Limites de conta gratuita**

| provedor | limite |
|---|---|
| OpenRouter, modelos `:free` | 20 por minuto, 50 por dia |
| Gemini, free tier | limite **por minuto**, baixo |

O do Gemini é o que mais incomoda: três perguntas seguidas já podem devolver
erro `429`. Não é defeito do seu código — é cota. A saída é o programa esperar
e tentar de novo, que é o que o nosso professor faz.


---

## Exercícios

1. Uma instrução de sistema tem 1200 caracteres. Estime quantos tokens ela ocupa
   e explique a regra de bolso que você usou.

2. Um chat tem instrução de sistema de 400 tokens. Cada pergunta do usuário ocupa
   60 tokens e cada resposta do modelo 140 tokens. Quantos tokens de **entrada**
   são enviados na quinta pergunta?

3. Você vai usar um LLM para extrair o número de uma nota fiscal de um texto, e
   depois para sugerir cinco títulos para um post de blog. Que temperatura você
   escolhe para cada tarefa, e por quê?

4. Um colega diz: "o modelo esqueceu o que eu falei no começo da conversa".
   Descreva duas causas técnicas diferentes para esse sintoma e como você
   distinguiria uma da outra.

5. Uma resposta volta com `prompt_tokens: 50`, `completion_tokens: 10` e
   `total_tokens: 310`. O que explica a diferença, e o que isso sugere sobre a
   escolha de modelo para essa tarefa?

6. Um aluno afirma: "o agente leu o meu arquivo". Descreva, passo a passo, o que
   de fato aconteceu entre o modelo e o programa — e diga em que momento o
   arquivo foi realmente aberto.

7. Você pergunta algo a um agente de terminal e ele usa três ferramentas antes de
   responder. Quantas requisições ao modelo essa única pergunta custou? Explique.

8. Seu agente tem uma ferramenta de busca na apostila. Dê dois motivos
   diferentes para preferir essa busca a colocar a apostila inteira no system
   prompt — um de custo e um de qualidade da resposta.
