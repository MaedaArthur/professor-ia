# Setup, para fazer em casa antes da aula

Este setup é pré-tarefa. Você faz em casa, com calma, na semana antes do workshop. Na aula a gente só confere que funcionou.

Reserve de 20 a 30 minutos. Siga os passos na ordem. Se travar em algum, pare e avise o professor antes da aula.

## 1. Clone o repositório

Abra o terminal e rode:

```sh
git clone https://github.com/MaedaArthur/professor-ia.git
cd professor-ia
```

Se o terminal responder que não conhece o comando `git`, instale o Git em `git-scm.com/downloads`, feche o terminal, abra de novo e volte para este passo.

## 2. O que tem dentro do repositório

Você não precisa entender tudo agora. Vale saber o que é cada coisa:

- `setup.sh` e `setup.ps1`: os instaladores. Instalam tudo, um para cada sistema operacional. Você vai usar apenas um dos dois.
- `01_chamada_minima.py`: uma requisição crua ao modelo. É o menor programa possível que fala com a IA, e é o que você vai usar para testar o setup.
- `professor.py`: o esqueleto do projeto da aula. Na aula você vai apagar esse arquivo e gerar o conteúdo dele com o agente.
- `professor_extras.py`: a mesma coisa, com uma ferramenta a mais.
- `SPEC.md`: diz **o que construir**.
- `AGENTS.md`: diz **como se programa** neste projeto.
- `perfil.md`: é quem você é. O professor de IA lê esse arquivo para explicar a matéria no seu nível.
- `material/apostila.md`: o conteúdo da matéria.
- `prompts/`: prompts prontos para você copiar.
- `handoff.md`: um handoff real, de verdade, para você ler.
- `slides/`: os slides do workshop. Eles entram no repositório na hora da aula, então não estranhe se a pasta ainda não estiver aí.

## 3. Rode o setup do seu sistema

Escolha a linha do seu sistema operacional:

```sh
# macOS e Linux
bash setup.sh

# Windows, no PowerShell
powershell -ExecutionPolicy Bypass -File setup.ps1
```

O script confere se você tem Python e Git, instala as dependências, instala o OpenCode e pergunta as suas chaves. Ele foi feito para ser rodado quantas vezes você quiser: se der errado no meio, rode de novo sem medo.

As duas chaves que ele vai pedir estão nos dois passos seguintes. Deixe esta página aberta.

## 4. A chave do Gemini, passo a passo

1. abra aistudio.google.com/apikey
2. entre com a sua conta Google
3. clique em "Create API key"
4. escolha "Create API key in new project"
5. copie a chave: ela começa com `AIza...`
6. cole quando o setup pedir

É grátis e não pede cartão.

A chave é como uma senha: não mande no chat, não suba para o GitHub.

## 5. A chave do OpenRouter, para o OpenCode

São duas chaves porque são duas coisas diferentes. A do Gemini alimenta o código Python que você vai escrever. A do OpenRouter alimenta o OpenCode, o agente que escreve junto com você.

1. abra openrouter.ai e entre com Google ou GitHub
2. vá em openrouter.ai/keys
3. clique em "Create API Key" e dê um nome qualquer
4. copie agora: ela começa com `sk-or-v1-`
5. cole quando o setup pedir

Essa chave aparece **uma vez só**. Se você fechar a janela sem copiar, não tem como ver de novo: apague a chave e crie outra.

## 6. Onde as chaves moram

As chaves ficam em um arquivo chamado `.env`, na raiz do repositório. O setup pergunta e grava para você. Esta seção serve para o caso de você precisar conferir o arquivo ou preenchê-lo à mão.

```sh
cp .env.example .env          # só na primeira vez
```

O conteúdo do `.env` fica assim, com as suas chaves no lugar dos pontinhos:

```txt
GEMINI_API_KEY=AIza...
OPENROUTER_API_KEY=sk-or-v1-...
```

Os scripts Python deste repositório leem o `.env` automaticamente, então você não precisa exportar nada no terminal.

O `.env` está listado no `.gitignore`, ou seja, ele nunca vai para o GitHub. Chave em commit é chave vazada.

## 7. Dentro do OpenCode, escolha um modelo de graça

Na primeira vez que você abrir o OpenCode, ele pergunta qual modelo usar. Procure um que termine em `:free`.

```txt
/models      ->  lista os modelos disponíveis
             ->  escolha um que termine em  :free
```

Conta nova no OpenRouter tem limite de 20 requisições por minuto e 50 por dia. Se aparecer um erro de limite, espere um minuto e tente de novo. Não é o seu código que quebrou.

## 8. O teste final, que é como você sabe que terminou

Na pasta do repositório, rode:

```sh
python 01_chamada_minima.py
```

O programa tem que imprimir três coisas: o JSON do que foi enviado, uma resposta do modelo e a contagem de tokens.

Se imprimiu, o seu setup está pronto. Pode fechar o terminal.

Se ele reclamou da chave, rode o setup do passo 3 de novo e cole as chaves com atenção.

## Se algo não funcionar

Na ordem:

1. Rode o setup do seu sistema de novo. Ele conserta a maior parte dos problemas e pode ser rodado várias vezes.
2. Confira o `.env`. Veja se as duas chaves estão lá, cada uma na sua linha, sem espaço antes nem depois do sinal de igual, e se começam com `AIza...` e `sk-or-v1-`.
3. Se continuar travado, avise o professor **antes da aula**, não durante. Mande o comando que você rodou e a mensagem de erro inteira, copiada do terminal. Com isso dá para resolver por mensagem e você chega na aula com tudo funcionando.
