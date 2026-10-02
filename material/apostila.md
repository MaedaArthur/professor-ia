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

---

# Exercícios

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
