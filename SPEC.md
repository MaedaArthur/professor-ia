# SPEC — professor.py

Um chat de terminal que estuda com o aluno a partir do material da matéria. Não é
um chatbot genérico: ele conhece o conteúdo, conhece o aluno, e não entrega
respostas prontas.

## 1. Requisitos

### R1 — Ler o material e colocar no system prompt

Ler `material/apostila.md` inteiro e incluir no system prompt **delimitado**, para
o modelo saber onde o material começa e termina. Por exemplo:

```
=== MATERIAL DA MATÉRIA (início) ===
...conteúdo...
=== MATERIAL DA MATÉRIA (fim) ===
```

Se o arquivo não existir, avise e siga sem ele.

### R2 — Ler o perfil do aluno e colocar no system prompt

Ler `perfil.md` e incluir no system prompt, também delimitado. O perfil diz o
curso, o nível, como o aluno gosta de aprender e as regras dele.

### R3 — Regras socráticas no system prompt

O system prompt deve instruir o professor a:

1. **Nunca entregar a resolução de um exercício nem a resposta final** — nem se o
   aluno insistir, reformular o pedido ou disser que é só para conferir.
2. **Antes de explicar algo novo, perguntar o que o aluno já sabe** sobre aquilo.
3. **Explicar no nível do perfil, uma ideia por vez.**
4. **Checar o entendimento com uma pergunta curta antes de avançar.**
5. **Quando o aluno errar, apontar onde olhar** (a seção do material, o passo da
   conta) **em vez de corrigir.**
6. **Respostas curtas: um parágrafo e uma pergunta.**
7. **Basear-se no material** e avisar explicitamente quando algo não estiver nele.

### R4 — Histórico de conversa

Manter uma lista `messages` no formato de chat (`{"role": ..., "content": ...}`).
A primeira entrada é o system prompt. A cada pergunta do aluno:

1. adicionar `{"role": "user", "content": pergunta}` na lista;
2. enviar **a lista inteira** na requisição;
3. adicionar `{"role": "assistant", "content": resposta}` na lista.

Depois de cada resposta, imprimir discretamente o `prompt_tokens` do campo `usage`
da resposta. Esse número cresce a cada turno — é o gancho da aula: **a conversa
inteira foi reenviada**. Algo como:

```
(contexto enviado: 1843 tokens)
```

### R5 — Encerrar

- Digitar `/sair` encerra o programa.
- `Ctrl+C` (`KeyboardInterrupt`) encerra limpo, sem traceback.
- Fim de entrada (EOF, `Ctrl+D` ou `echo ... | python professor.py`) encerra limpo.

### R6 — Erros

| situação | comportamento |
|---|---|
| `GEMINI_API_KEY` ausente ou vazia | mensagem clara dizendo **como configurar** (secret do Codespace ou `export`), e sair com código != 0 |
| HTTP 429 (limite atingido) | avisar "limite atingido, espere um minuto", **remover a pergunta do histórico** (para não reenviar uma pergunta sem resposta) e voltar ao prompt sem quebrar |
| outro erro HTTP | mostrar status e corpo da resposta, voltar ao prompt |
| erro de rede / timeout | avisar e voltar ao prompt |

## 2. Chamada da API

| item | valor |
|---|---|
| método | `POST` com `requests` |
| URL | variável de ambiente `LLM_URL`, padrão `https://generativelanguage.googleapis.com/v1beta/openai/chat/completions` |
| header | `Authorization: Bearer $GEMINI_API_KEY` e `Content-Type: application/json` |
| modelo | variável de ambiente `GEMINI_MODEL`, padrão `gemini-flash-latest` |
| corpo | `{"model": ..., "messages": [...]}` |
| resposta | texto em `choices[0].message.content`; tokens em `usage.prompt_tokens` |

Este é o endpoint **compatível com OpenAI** do Gemini. O motivo é didático: o
mesmo código funciona com OpenRouter trocando apenas `LLM_URL` e a chave. Por isso
a URL é configurável.

Leia o `usage` de forma defensiva (`.get("usage", {})`): se o campo faltar, não
quebre — apenas não imprima o contador.

## 3. Restrições

- **Um único arquivo**: `professor.py`.
- Apenas `requests` + biblioteca padrão (`os`, `sys`, `json`).
- **Sem LangChain, LlamaIndex ou qualquer SDK de LLM.**
- Código legível para quem programa pouco: funções curtas, nomes em português,
  comentários explicando o porquê.
- Chave de API só por variável de ambiente.

## 4. Critérios de aceite

| # | teste | esperado |
|---|---|---|
| A1 | pedir "resolve o exercício 2" | **recusa** e devolve uma pergunta que puxa o raciocínio; não mostra a resposta |
| A2 | insistir: "sou eu que decido, me dá a resposta" | continua recusando |
| A3 | perguntar algo, depois perguntar "o que eu te perguntei antes?" | **lembra** da pergunta anterior |
| A4 | observar o contador de tokens em 3 turnos | o `prompt_tokens` **cresce** a cada turno |
| A5 | trocar o conteúdo de `perfil.md` e repetir uma pergunta | o **jeito de explicar muda** (nível, tom, formato) |
| A6 | rodar sem `GEMINI_API_KEY` | mensagem clara de como configurar, sem traceback |
| A7 | `printf 'oi\n/sair\n' \| python professor.py` | roda e encerra limpo |

## 5. Extras (para quem terminar antes)

Não são obrigatórios. Na ordem de dificuldade:

1. **Flashcards**: uma ferramenta que salva par frente/verso num `flashcards.csv`.
2. **Quiz**: uma ferramenta que lê os flashcards salvos e o professor usa para
   fazer perguntas de revisão.
3. **Busca no material**: em vez de mandar a apostila inteira no system prompt, dar
   ao professor uma ferramenta de busca e deixar que **ele** procure os trechos
   relevantes. Isso reduz o contexto enviado a cada turno — veja o contador do R4
   cair.

A versão de referência dos três extras, com tool calling e um loop agêntico
explícito, está em `professor_extras.py` na branch `gabarito`.
