# 04 Handoff: passar o estado para uma sessão nova

**Como usar:** quando a sessão estiver longa (a IA começa a esquecer decisões, a
repetir coisas já feitas ou a ficar mais lenta e mais cara), cole o bloco abaixo,
salve a resposta num arquivo `handoff.md`, abra uma sessão nova e cole esse arquivo
como primeira mensagem.

```
Esta sessão já está longa. Antes de continuarmos, gere um handoff: um resumo do
estado deste trabalho para eu colar numa sessão nova e continuar de onde paramos,
sem você perder nada do que já decidimos.

Escreva em markdown, direto, nestas seções:

1. O que é este projeto, em três linhas, para quem nunca viu.
2. O que já foi feito. Liste por item, e diga o que está testado e o que não está.
3. O que falta. Em ordem, com o próximo passo concreto em primeiro lugar.
4. Onde estão os arquivos. Caminho de cada arquivo que importa e o que ele é.
   Diga quais devem ser lidos primeiro na sessão nova.
5. Decisões tomadas e o porquê de cada uma. Inclua as alternativas que foram
   descartadas e o motivo, para a sessão nova não reabrir discussão já fechada.
6. Armadilhas: o que deu errado no caminho, o que não funciona, o que eu já tentei
   e falhou.
7. Perguntas abertas: o que ainda não foi decidido e precisa de mim.

Regras: não invente nada. Se você não souber se algo foi testado, escreva que não
sabe. Não resuma a ponto de perder número, nome de arquivo ou comando, porque é
exatamente isso que a sessão nova não vai ter.
```

## Por que isso é necessário

Toda a conversa é reenviada ao modelo em cada pergunta. Quanto mais longa a
sessão, mais caro cada turno e maior a chance de o modelo perder o fio. Um handoff
troca uma conversa inflada por uma página densa de estado.

## Tem um handoff real neste projeto

O arquivo `handoff.md` na raiz deste repositório (um nível acima de
`professor-ia/`) é um handoff de verdade, escrito exatamente por esse motivo: a
sessão anterior ficou longa e o estado foi resumido e passado adiante. Ele foi
usado para construir este próprio workshop.

Vale ler como exemplo. Repare em três coisas:

- a seção de decisões já tomadas diz "não reabra sem motivo", e explica o porquê
  de cada uma;
- os números medidos estão escritos no documento, não "ficaram na conversa";
- existe uma seção de pergunta aberta, admitindo o que ainda não foi decidido.

É o formato que você deve esperar da resposta ao prompt acima.
