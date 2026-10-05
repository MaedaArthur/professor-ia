# 03 Plano antes do código

**Como usar:** este é o primeiro pedido que você faz ao OpenCode dentro da pasta
`professor-ia/`, antes de qualquer outra coisa. Cole o bloco e espere o plano.
Não deixe ele escrever código nesta primeira mensagem.

```
Antes de escrever qualquer linha de código, leia estes dois arquivos deste
repositório, inteiros:

- SPEC.md (a especificação do professor.py, é a fonte da verdade)
- AGENTS.md (as regras técnicas deste repo)

Depois me mostre um plano em 5 passos para implementar o professor.py, numerado,
uma ou duas linhas por passo. Para cada passo diga qual requisito do SPEC ele
atende (R1 a R6).

No plano, deixe explícito:
- o que vai dentro do system prompt e como o material e o perfil ficam delimitados
- como o histórico de mensagens é montado e reenviado a cada turno
- como cada erro do R6 é tratado, incluindo o que acontece com a pergunta do aluno
  quando o turno falha
- quais formas de encerrar o programa você vai cobrir

Pare depois do plano. Não crie nem edite nenhum arquivo nesta resposta. Espere eu
aprovar ou corrigir o plano antes de implementar.

Se alguma parte do SPEC estiver ambígua para você, liste as dúvidas no fim em vez
de escolher por conta própria.
```

## Por que pedir o plano primeiro

Ler um plano de cinco linhas e corrigir uma delas custa poucos segundos seus e
quase nada de contexto. Ler duzentas linhas de código errado custa a sua leitura
inteira, mais a rodada de correção, mais o risco de o erro de entendimento
continuar escondido lá dentro.

Além disso, o plano mostra o que a IA entendeu do SPEC. Se ela entendeu errado, o
plano denuncia antes de o erro virar código.

## O que fazer com o plano

- Compare passo por passo com a seção "1. Requisitos" do `SPEC.md`. Faltou algum R?
- Olhe se o tratamento de erro do R6 aparece de verdade, e não como "tratar erros".
- Se o plano estiver bom, responda algo como "plano aprovado, implemente o passo 1
  e pare". Ir por passo custa mais mensagens, mas você entende o que foi escrito.
