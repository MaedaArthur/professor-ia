# Contexto do projeto

Este repositório é o material de um workshop de IA para alunos de graduação. O
objetivo do código aqui é **ser lido e entendido por quem programa pouco**.

> Este arquivo é o contexto para quem **programa** neste repo. As regras de ensino
> do professor socrático ficam em `.opencode/agents/professor.md`, não aqui — de
> propósito, para não contaminar quem está escrevendo código.

## O que estamos construindo

`professor.py`: um chat de terminal que estuda com o aluno a partir do material
da matéria. A especificação completa está em **`SPEC.md`**. Leia o SPEC antes de
escrever qualquer linha e siga-o.

## Regras técnicas

- **Python 3.9 ou mais novo.** Apenas `requests` + `python-dotenv` + biblioteca
  padrão: o `python-dotenv` só carrega o `.env`, não é framework de LLM.
  (o código roda na máquina do aluno, então não assuma uma versão nova)
- **Sem frameworks de LLM.** Nada de LangChain, LlamaIndex, SDK do OpenAI ou do
  Google. A chamada é um `requests.post` cru — isso é didático, não é descuido.
- **Um arquivo.** `professor.py` resolve tudo. Não crie pacotes nem módulos.
- **Código curto e comentado em português.** Nomes de função e variável em
  português. Comente o *porquê*, não o *o quê*.
- **Chaves de API só por variável de ambiente** (`os.environ`). Nunca escreva uma
  chave no código, nem num arquivo de exemplo, nem num comentário.
- **Planeje antes de executar.** Diga em 3–5 passos o que vai fazer, depois faça.

## Como testar

**Nunca rode `professor.py` de forma interativa. Ele espera input e trava.**

Para testar, use uma destas duas formas:

```bash
# 1. Uma função isolada, sem entrar no loop de chat
python -c "import professor; print(professor.carregar_material()[:200])"

# 2. O programa inteiro, alimentando o stdin
echo "o que é um token?" | python professor.py
printf 'o que é temperatura?\n/sair\n' | python professor.py
```

Antes de dizer que terminou, rode `python -m py_compile professor.py`.

## Arquivos

| arquivo | o que é |
|---|---|
| `SPEC.md` | a especificação do professor — a fonte da verdade |
| `professor.py` | o que estamos construindo |
| `01_chamada_minima.py` | exemplo de referência: uma requisição HTTP crua ao LLM |
| `material/apostila.md` | o conteúdo da matéria que o professor usa |
| `perfil.md` | o perfil de aprendizado do aluno |
