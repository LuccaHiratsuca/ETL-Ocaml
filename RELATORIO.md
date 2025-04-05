# Relatório do Projeto ETL em OCaml

Este relatório detalha o fluxo de desenvolvimento do projeto ETL, construído em OCaml, seguindo etapas específicas para atender requisitos obrigatórios e, posteriormente, opcionais.

Sendo assim, primeiramente, comecei a trabalhar nos requisitos obrigatórios, que são essenciais para o funcionamento do projeto. Após a conclusão desses requisitos, passei a implementar funcionalidades adicionais que enriqueceram o projeto e melhoraram sua usabilidade.

---

## Etapas Obrigatórias

### Etapa 1: Análise dos Dados e Entendimento do Problema
Inicialmente, analisei os arquivos CSV (`order.csv` e `order_item.csv`) e identifiquei quais campos deveriam ser tratados e quais cálculos seriam necessários para atender à demanda do gestor. Isso incluiu entender claramente quais informações eram necessárias: total do pedido e total de impostos, com filtros parametrizados por status e origem.

A partir disso, acabei procurando entender como poderia arquitetar o meu projeto, quais libraries iria utilizar e como poderia organizar o código para que ele ficasse mais limpo e fácil de entender.
A arquitetura do projeto foi pensada para ser modular, separando claramente as funções puras (processamento de dados) das funções impuras (entrada e saída de dados) com o intuito de facilitar a manutenção e a realização dos testes (posteriormente).

Com isso, foi criado a estrutura que podemos observar no ![readme](README.md)

### Etapa 2: Definição dos Tipos (types.ml/types.mli)

Em seguida, defini os tipos principais do projeto, que são fundamentais para garantir a integridade dos dados e facilitar o processamento. Os tipos foram definidos em um módulo separado (`types.ml` e `types.mli`), permitindo uma clara separação de responsabilidades.

Os tipos principais definidos foram, esses podem ser encontrados no arquivo `types.ml`:
- `order`: representando os pedidos, com campos como `id`, `status`, `origin`, `total` e `taxes`.
- `order_item`: representando itens individuais de cada pedido, com campos como `id`, `order_id`, `product_id`, `quantity` e `price`.
- `order_result`: representando a agregação final dos resultados por pedido, com campos como `id`, `total` e `taxes`.
- `monthly_avg`: para uma eventual média mensal (opcional).

### Etapa 3: Leitura e Parsing dos Dados (parse.ml/parse.mli)
Criei funções puras responsáveis por transformar linhas CSV em registros (`order` e `order_item`). Estas funções lidaram com conversões de tipo (ex.: strings para inteiros ou floats), com tratamento adequado de erros.

### Etapa 4: Implementação das Funções Puras de Processamento (process.ml/process.mli)

Nessa etapa, vale ressaltar que mesmo sabendo que usar o `inner join` era um dos requisitos opcionais, optei por implementá-lo desde o início, pois, depois, não teria que refatorar ou ter que voltar e fazer alterações no código.

Sendo assim, implementei funções puras para:
- Filtragem dos pedidos com base em status e origem usando `filter`.
- Junção (`inner join`) das listas de pedidos e itens.
- Cálculo dos totais dos pedidos utilizando `map` e `reduce`.

Essas funções foram desenvolvidas separadamente para garantir clareza e modularidade.

### Etapa 5: Funções Impuras (IO) para CSV:
Separei as funções impuras em um módulo específico:
- Leitura de CSV (local).
- Escrita dos resultados em CSV.

A separação das funções impuras é fundamental para garantir modularidade e facilitar testes.

### Etapa 6: Entrada Principal (main.ml)
Implementei o ponto de entrada (`main.ml`) para coordenar as etapas do pipeline ETL:
- Recebimento de parâmetros pela linha de comando (status, origem, arquivos de entrada).
- Execução das etapas: leitura, filtragem, junção, cálculo dos totais e escrita dos resultados.

---

## Etapas Opcionais

Após a conclusão dos requisitos obrigatórios, passei a trabalhar em requisitos adicionais para enriquecer o projeto:

### Etapa 7: Testes Unitários (test_domain.ml)
Desenvolvi testes unitários completos para garantir a correção das funções puras usando OUnit2, cobrindo parsing e processamento. Isso assegurou maior robustez e facilidade em futuras manutenções.

### Etapa 8: Carregamento Remoto de CSV (opcional implementado)
Adicionei a funcionalidade de leitura de CSV diretamente de URLs utilizando `ocurl`. Isso ampliou a flexibilidade para a origem dos dados de entrada.

### Etapa 9: Armazenamento em Banco SQLite (opcional implementado)
Inseri os resultados diretamente em um banco SQLite, permitindo um consumo mais eficiente por aplicações que exigem acesso ao banco, facilitando análises futuras mais complexas.

### Etapa 10: Médias Mensais (opcional implementado)
Implementei o cálculo e a gravação adicional das médias mensais de receitas e impostos, adicionando valor analítico extra.

### Etapa 11: Organização do Projeto com dune (opcional implementado)
Configurei e organizei o projeto utilizando o build system `dune`, padronizando builds, testes e execução.

### Etapa 12: Documentação Completa e Docstrings (opcional implementado)
Todas as funções e arquivos foram documentadas usando comentários no formato `docstring`, esclarecendo parâmetros, retornos e exceções possíveis.

---

## Considerações Finais

**Uso de IA Generativa:** Sim, utilizei IA generativa (ChatGPT) como suporte pontual para definição da arquitetura, geração inicial/correção de código e auxílio na documentação. Porém, todo o código foi criado (inicialmente), validado, ajustado e testado manualmente por mim.