# Guia de Arquitetura Multi-Repositório com AI-Memory

Este guia descreve como utilizar o **`ai-memory`** para conectar múltiplos repositórios de um mesmo projeto (ex: `frontend`, `backend`, `microservicos`) a um repositório centralizado de documentação e arquitetura.

---

## 🚀 O Problema Resolvido

Em ecossistemas multi-repositório, é comum enfrentar:
1. **Falta de Contexto Cruzado:** O agente de IA alterando o frontend não sabe das mudanças de contrato no backend.
2. **Documentação Desatualizada:** Features e regras de negócio mudam no código, mas o repositório de documentação dedicada não é atualizado.

Com o `ai-memory`, toda a base de conhecimento fica acessível por qualquer agente em qualquer repositório sob a mesma **Workspace**.

---

## 🛠️ Configuração Passo a Passo

### 1. Definir uma Workspace Compartilhada
Defina a variável de ambiente `AI_MEMORY_WORKSPACE` no seu shell (`~/.zshrc` ou no ambiente do projeto) para que todos os repositórios compartilhem o mesmo banco de memórias:

```bash
export AI_MEMORY_WORKSPACE="meu-projeto-macro"
```

---

### 2. Importar a Documentação Existente (`bootstrap`)
Navegue até a pasta do seu repositório dedicado de documentação e execute o comando de importação:

```bash
cd /caminho/do/repo-documentacao
ai-memory bootstrap
```
Este comando lê todos os arquivos `.md` existentes (arquitetura, diagramas, regras de negócio) e gera as páginas duráveis de wiki no `ai-memory`.

---

### 3. Configurar os Arquivos `AGENTS.md` nos Repositórios de Código
Em cada repositório de código (`frontend`, `backend`, etc.), adicione as seguintes diretrizes ao arquivo `AGENTS.md`:

```markdown
## Regras de Documentação Cruzada e Memória
- Antes de implementar uma nova funcionalidade ou refatoração, consulte a arquitetura no `ai-memory` via `memory_search`.
- Sempre que alterar um contrato de API, schema de dados ou regra de negócio, atualize a página de documentação correspondente no `ai-memory` usando `memory_write_page`.
```

---

## 🔄 Fluxo de Trabalho Diário

### Passo A: Desenvolvendo no Repositório de Código (`backend` ou `frontend`)
Ao trabalhar no repositório de código:
```bash
cd /caminho/do/repo-backend
ai-jail opencode --yolo
```
1. O agente consulta o `ai-memory` via MCP para entender a arquitetura atual.
2. O agente implementa a feature ou alteração no código.
3. Antes de encerrar, o agente grava ou atualiza a página no `ai-memory` com a mudança efetuada no contrato.

### Passo B: Sincronizando o Repositório de Documentação Dedicado
Para atualizar os arquivos Markdown do seu repositório de documentação:
```bash
cd /caminho/do/repo-documentacao
ai-jail opencode --yolo
```
Instrua o agente:
> *"Verifique no ai-memory as alterações recentes gravadas pelos outros serviços e atualize os arquivos Markdown deste repositório de documentação."*

O agente lerá as memórias gravadas e atualizará os arquivos `.md` do repositório de docs automaticamente.

---

## 🎯 Benefícios Alançados

* **Visão Holística:** Todas as IAs compartilham o mesmo contexto de arquitetura e contratos.
* **Documentação Sempre Viva:** O repositório de documentação é mantido em sintonia com os repositórios de código.
* **Histórico de Decisões:** Decisões tomadas em um serviço ficam registradas e visíveis para todo o ecossistema.
