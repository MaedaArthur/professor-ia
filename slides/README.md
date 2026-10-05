# slides/

| arquivo | o que é |
|---|---|
| `deck.html` | **o deck.** 79 slides, arquivo único, sem build |
| `prototipo.html` | banco de testes do mascote, 8 slides. Não é o deck |
| `retrato.png` | o retrato que aparece no slide de apresentação |

## Usar

Abra `deck.html` no navegador. Nenhum servidor, nenhuma instalação.

```
← →        navega, avança passo a passo dentro do slide, depois troca
espaço     igual a →
clique     igual a →
#12.3      abre direto no slide 12, passo 3 (a URL se atualiza sozinha)
Home / r   volta ao começo
p          monta o deck inteiro paginado e abre o diálogo de impressão → PDF
?audit=1   percorre os 79 slides e reporta os que estouram a altura
```

O `#slide.passo` serve para reabrir exatamente onde parou, em vez de avançar
79 slides até achar o ponto. Útil no ensaio e se a sala precisar de uma pausa.

**Fontes:** Bricolage Grotesque e IBM Plex Mono vêm do Google Fonts. Sem rede,
caem para a pilha do sistema e o deck continua legível, mas perde o caráter. Se a
sala não tiver internet confiável, exporte o PDF antes (`p`).

## Escrever slides

O conteúdo fica no `<script type="text/x-slides">` dentro do próprio `deck.html`.
Slides separados por uma linha com `===`.

### Diretivas de slide

```
@type:    o arquétipo (abaixo). Padrão: mecanismo
@n:       o número impresso no rodapé
@piece:   prompt | memoria | ferramentas | loop
          acende a estação na trilha e leva o mascote até lá.
          Sem @piece, a trilha apaga e o mascote fica parado.
@tema:    texto do cabeçalho quando não há @piece
@dir:     texto do canto direito do cabeçalho
@soft:    linha de apoio acima do título, em peso normal (tipo pergunta)
@cap:     etiqueta acima do bloco de código
@num:     índice à esquerda (tipos titulo e pratica)
@lado:    nao, força o código a ocupar a largura toda em vez de ficar ao lado
@hot:     1, pinta o número grande no acento (tipo medicao)
@setup:   linha de condições acima da tabela (tipo progressao)
@foto:    caminho da imagem do slide de apresentação
@cargo:   etiqueta pequena acima do nome
@topo /
@rodape:  linhas de topo e base da capa
```

### Blocos

```
# título             vira o título grande (no acento, nos tipos de pergunta)
## subtítulo
::lede:: ...         parágrafo de apoio
::quote:: ...        bloco com filete no acento, é o remate do slide
::step:: ...         parágrafo que só aparece no próximo clique
::big:: 2154         número gigante (tipo medicao)
::row:: rótulo | valor | voltas | hot
                     linha da progressão. "voltas" é a densidade do mascote
::note:: ...         linha de respiro entre as linhas da progressão
::esq:: título | linha | linha
::dir:: título | linha | linha
                     as duas colunas da comparação; a da direita é a marcada
```

`::quote::` e `::step::` são passos: aparecem a cada clique, na ordem.
Dentro de qualquer texto cabe `<b>negrito</b>` e `<code>mono</code>`.

### Código

Cerque com crase tripla e diga a linguagem: `json`, `py`, `sh`, `txt`.
Para destacar uma linha, envolva em `«guillemets»`.

````
```py
messages = [{"role": "system", "content": system}]
«messages.append({"role": "user", "content": pergunta})»
```
````

### Os quatorze arquétipos

| `@type` | para quê |
|---|---|
| `capa` | abertura do deck, sem cabeçalho nem trilha |
| `titulo` | marco de seção: índice à esquerda, título grande |
| `pergunta` | uma pergunta em pé sozinha, com muito ar |
| `mecanismo` | o "como funciona": subtítulo, apoio, diagrama em texto |
| `progressao` | a tabela que soma, com o mascote no palco engordando |
| `medicao` | um número gigante e sua legenda |
| `comparacao` | duas colunas lado a lado; a direita é a marcada |
| `codigo` | texto à esquerda, bloco escuro à direita |
| `terminal` | igual ao código, para saída de comando |
| `aovivo` | marcador de "sai do slide, vai para a ferramenta" |
| `pratica` | uma boa prática e o motivo dela |
| `leva` | "o que você leva daqui", fecho de degrau, em caixa |
| `retomada` | reancora um fio deixado em aberto |
| `quemsou` | apresentação: retrato à esquerda (`@foto:`), texto à direita |

## Regras que o deck segue

- **Não tem separação por aula.** Sem capa de ato, sem numeração que reinicia.
  É um encontro só, de 135 minutos, num documento contínuo.
- **Nunca slide de bullet.** Se precisa de lista, vira vários slides, é o que
  o tipo `pratica` faz com as boas práticas.
- **Base clara, código em bloco escuro.** A decisão é de projeção, não de gosto:
  a sala é clara e o projetor é comum.
- O mascote está documentado em
  `../.design/branding/workshop-ia/identity/MASCOTE.md`.
