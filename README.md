# ETL-OCaml

Este projeto realiza um fluxo **ETL** (Extract, Transform, Load) em OCaml, cumprindo os seguintes objetivos:

- **Extrair** dados de `Order` e `OrderItem` de arquivos CSV (ou via HTTP, opcional).
- **Transformar** usando `filter`, `map`, `fold` (reduce) para:
  - Filtrar pedidos por status e origin.
  - Fazer join (Order x OrderItem).
  - Calcular total_amount (soma de receita) e total_taxes (soma de impostos) por pedido.
  - Calcular médias mensais de receita e imposto (agrupado por ano-mês).
- **Carregar** (Load) tanto em um arquivo CSV final quanto em um banco SQLite.

## Sumário

1. [Estrutura do Projeto](#estrutura-do-projeto)  
2. [Features Implementadas](#features-implementadas)  
3. [Pré-Requisitos](#pré-requisitos)  
4. [Como Executar](#como-executar)  
   1. [Compilação](#compilação)  
   2. [Execução do ETL](#execução-do-etl)  
   3. [Opções de Execução](#opções-de-execução)  
   4. [Execução de Testes](#execução-de-testes)  
5. [Detalhes Internos](#detalhes-internos)  
   1. [Lendo arquivos locais](#lendo-arquivos-locais)  
   2. [Lendo via HTTP (ocurl)](#lendo-via-http-ocurl)  
   3. [Transformações (Funções Puras)](#transformações-funções-puras)  
   4. [Salvando resultados em CSV e SQLite](#salvando-resultados-em-csv-e-sqlite)  
   5. [Cálculo de médias mensais](#cálculo-de-médias-mensais)  

---

## Project's Structure
```bash
## Estrutura do Projeto

O projeto está organizado em uma subpasta chamada `etl` dentro do diretório raiz `ETL-Ocaml`. Abaixo está a estrutura completa:

```bash
ETL-Ocaml/
├── README.md
├── RELATORIO.md
├── .gitignore
├── etl/
│   ├── _build/
│   ├── assets/
│   │   ├── ocaml_version.png
│   │   ├── opam_version.png
│   │   └── dune_version.png
│   ├── bin/
│   │   ├── dune
│   │   └── main.ml
│   ├── data/
│   │   ├── processed/
│   │   ├── raw/
│   │   │   ├── order.csv
│   │   │   └── order_item.csv
│   ├── dune-project
│   ├── etl.opam
│   ├── lib/
│   │   ├── dune
│   │   ├── types.ml
│   │   ├── types.mli
│   │   ├── parse.ml
│   │   ├── parse.mli
│   │   ├── process.ml
│   │   ├── process.mli
│   │   ├── io.ml
│   │   └── io.mli
│   ├── test/
│   │   ├── dune
│   │   └── test_domain.ml

```

### Componentes

- **domain.ml**: Lógica pura (tipos, parse, join, cálculo).  
- **io.ml**: Lógica impura (ler CSV, escrever CSV, salvar em SQLite, etc.).  
- **main.ml**: Orquestra o ETL; lê parâmetros de status e origin.  
- **test_domain.ml**: Testes OUnit das funções de parsing (funções puras).  

---

## Features Implementadas

1. **Leitura de arquivos CSV locais** (em `data/order.csv` e `data/order_item.csv`).  
2. **Leitura opcional via HTTP** (função de download usando `ocurl`).
3. **Funções de parse** de cada linha CSV em registros customizados (`order`, `order_item`).  
4. **Filtragem** dos pedidos por `status` (pending, complete, cancelled) e `origin` (O, P).  
5. **Inner Join** entre `Order` e `OrderItem` com base em `order_id`.  
6. **Cálculo** de:  
   - **total_amount** (soma de `price * quantity` por pedido).  
   - **total_taxes** (soma de `(price * quantity) * tax` por pedido).  
7. **Saída em CSV** (`out.csv`), contendo `order_id`, `total_amount` e `total_taxes`.  
8. **Persistência em SQLite** (criando tabela `order_results`).  
9. **Cálculo adicional** de **médias mensais** (agrupadas por `YYYY-MM`), gerando `out_monthly.csv` com `year_month, avg_amount, avg_tax`.  
10. **Testes** (via OUnit) das funções de parse.

---

## Pré-Requisitos
Para o desenvolvimento e execução do projeto, foi utilizado:
- **OCaml** 
    - Versão: 5.2.1
    ![Ocaml](etl/assets/ocaml_version.png)
- **Dune** (para build e gerenciamento de dependências)
    - Versão: 3.18.0
    ![Dune](etl/assets/dune_version.png)
- **Opam** (gerenciador de pacotes OCaml)
    - Versão: 2.3.0
    ![Opam](etl/assets/opam_version.png)
- **Bibliotecas**:  
  1. `csv`  (para leitura de CSV)
  2. `ocurl` (para requisições HTTP bloqueantes)  
  3. `sqlite3` (para persistência em SQLite)  
  4. `oUnit` (para testes) 

---

## Como Executar

### Instalação de Dependências
Na raiz do projeto, execute:
```bash
opam install csv ocurl sqlite3 oUnit
```
Isso instalará as dependências necessárias para o projeto.

### Compilação
Na raiz do projeto:

1. Inicie o Dune:
```bash
eval $(opam env)
```

2. Compile o projeto:
```bash
dune build
```
O Dune vai compilar o executável `etl`.

### Execução do ETL
Depois de compilar, rode:
```bash
dune exec etl.main -- [status] [origin] [orders_source] [items_source]
```
- **status**: `pending`, `complete` ou `cancelled`.
- **origin**: `O` (online) ou `P` (paraphysical).
- **orders_source**: URL ou caminho local para `order.csv` (opcional).
- **items_source**: URL ou caminho local para `order_item.csv` (opcional).
Obs.: Se omitir `orders_source` e `items_source`, usa por padrão `data/raw/order.csv` e `data/raw/order_item.csv`.

**Opções de Execução:**
1. Modo Local (padrão):
    ```bash
    dune exec etl -- complete O
    ```
    Lê `data/raw/order.csv` e` data/raw/order_item.csv`, filtra por `status=complete` e `origin=O`.

2. Local Explicitamente:
    ```bash
    dune exec etl -- complete O data/raw/order.csv data/raw/order_item.csv
    ```
    Mesmo resultado que o anterior.

3. Via HTTP:
    ```bash
    dune exec etl -- complete O https://raw.githubusercontent.com/LuccaHiratsuca/ETL-Ocaml/refs/heads/main/etl/data/raw/order.csv?token=GHSAT0AAAAAAC7YKUZOVOCZKNHPG6CSBP4YZ7QYNNQ https://raw.githubusercontent.com/LuccaHiratsuca/ETL-Ocaml/refs/heads/main/etl/data/raw/order_item.csv?token=GHSAT0AAAAAAC7YKUZOCOI3G5VBPAFLXKRAZ7QYOKQ
    ```
    Se `orders_source` ou `items_source` começa com `http://` ou `https://`, a leitura usará read_csv_http_ocurl


Qualquer uma dessas opções irá:
1. Ler os arquivos CSV (local ou via HTTP).
2. Filtrar pedidos com status `complete` e `origin O`.
3. Fazer o join (pedido x itens).
4. Calcular `total_amount` e `total_taxes`.
5. Gerar `out.csv`.
6. Inserir resultados em `out.db` (tabela `order_results`).
7. Gerar `out_monthly.csv` com médias mensais.

Exemplo de Saída (`out.csv`)
```bash
order_id,total_amount,total_taxes
1,1345.88,20.34
5,34.54,2.35
14,334.44,30.45
```

### Execução de Testes
Para rodar os testes de unidade das funções puras:
```bash
dune runtest
```
Isso executará o arquivo `test/test_domain.ml`.

**Explicação dos Testes Unitários em `test_domain.ml`:**

Os testes unitários em `test/test_domain.ml` foram criados com a biblioteca OUnit2 para validar as funções puras do pipeline ETL definidas em `lib/parse.ml` e `lib/process.ml`. Abaixo está a explicação de cada teste, detalhando o que é testado, como é testado e o que se espera como resultado.

## 1. `test_parse_order_line`
**Propósito**: Verificar se a função `parse_order_line` em `parse.ml` converte corretamente uma linha CSV em um registro do tipo `order`.  
**Como funciona**: O teste cria uma linha CSV simulada como um array de strings `["1"; "10"; "2023-01-02"; "complete"; "O"]`, que representa um pedido com `id=1`, `client_id=10`, `order_date="2023-01-02"`, `status="complete"` e `origin="O"`. A função `parse_order_line` é chamada com essa linha, e o resultado é um registro `order`. O teste usa `assert_equal` para verificar se cada campo do registro (`id`, `client_id`, `order_date`, `status`, `origin`) corresponde aos valores esperados.  
**Resultado esperado**: Todos os campos do registro `order` devem coincidir exatamente com os valores da linha CSV, confirmando que o parsing foi bem-sucedido.

## 2. `test_parse_order_item_line`
**Propósito**: Validar que a função `parse_order_item_line` em `parse.ml` transforma corretamente uma linha CSV em um registro do tipo `order_item`.  
**Como funciona**: Uma linha CSV simulada `["2"; "999"; "2.0"; "15.00"; "0.20"]` é criada, representando um item de pedido com `order_id=2`, `product_id=999`, `quantity=2.0`, `price=15.00` e `tax=0.20`. A função `parse_order_item_line` é aplicada a essa linha, gerando um registro `order_item`. O teste verifica cada campo do registro (`order_id`, `product_id`, `quantity`, `price`, `tax`) com `assert_equal` para garantir que os valores foram parseados corretamente como inteiros ou floats, conforme o tipo.  
**Resultado esperado**: O registro `order_item` reflete os valores da linha CSV, com conversões de string para os tipos numéricos apropriados funcionando corretamente.

## 3. `test_filter_orders_by`
**Propósito**: Testar se a função `filter_orders_by` em `process.ml` filtra corretamente uma lista de pedidos com base em `status` e `origin`.  
**Como funciona**: O teste define uma lista de três pedidos: um com `status="complete"` e `origin="O"`, outro com `status="pending"` e `origin="P"`, e um terceiro com `status="complete"` e `origin="P"`. A função `filter_orders_by` é chamada com os argumentos `"complete"` e `"O"`, e o resultado é uma lista filtrada. O teste verifica com `assert_equal` se a lista retornada tem comprimento 1 e se o `id` do único pedido retornado é 1, correspondendo ao pedido que satisfaz ambos os critérios.  
**Resultado esperado**: Apenas o pedido com `status="complete"` e `origin="O"` deve ser retornado, confirmando a filtragem correta.

## 4. `test_filter_orders_by_case_insensitive`
**Propósito**: Garantir que a função `filter_orders_by` é insensível a maiúsculas e minúsculas ao filtrar `status` e `origin`.  
**Como funciona**: Um único pedido é criado com `status="COMPLETE"` (em maiúsculas) e `origin="o"` (em minúsculas). A função `filter_orders_by` é chamada com `"complete"` e `"O"`, e o teste verifica se o resultado contém exatamente esse pedido, usando `assert_equal` para checar o comprimento da lista retornada. Isso testa a conversão para minúsculas feita pela função com `String.lowercase_ascii`.  
**Resultado esperado**: O pedido é retornado apesar das diferenças de capitalização, provando que a filtragem ignora maiúsculas e minúsculas.

## 5. `test_join_orders_and_items`
**Propósito**: Verificar se a função `join_orders_and_items` em `process.ml` realiza corretamente um inner join entre listas de `order` e `order_item` com base em `order_id`.  
**Como funciona**: São criadas duas listas: uma com dois pedidos (`id=1` e `id=2`) e outra com dois itens, ambos com `order_id=1`. A função `join_orders_and_items` é chamada, e o resultado é uma lista de pares `(order, order_item)`. O teste usa `assert_equal` para verificar que a lista tem dois pares (os dois itens associados ao pedido com `id=1`) e checa se o primeiro par contém o pedido com `id=1` e o item com `product_id=101`.  
**Resultado esperado**: A lista contém apenas pares onde `order.id` coincide com `order_item.order_id`, excluindo o pedido com `id=2` que não tem itens correspondentes.

## 6. `test_update_assoc_new`
**Propósito**: Testar se a função `update_assoc` em `process.ml` adiciona corretamente uma nova entrada a uma lista de associação vazia.  
**Como funciona**: Uma lista de associação vazia é criada, e `update_assoc` é chamada com `order_id=1`, `rev=100.0` e `tx=10.0`. O resultado é comparado com `[(1, (100.0, 10.0))]` usando `assert_equal`, verificando se a nova entrada foi adicionada como um par `(order_id, (revenue, tax))`.  
**Resultado esperado**: A lista de associação contém a nova entrada, indicando que a função funciona corretamente ao adicionar novos valores.

## 7. `test_update_assoc_update`
**Propósito**: Validar que a função `update_assoc` atualiza corretamente uma entrada existente em uma lista de associação, somando os valores.  
**Como funciona**: Uma lista de associação inicial `[(1, (50.0, 5.0))]` é criada, representando um pedido com receita 50.0 e imposto 5.0. A função `update_assoc` é chamada com `order_id=1`, `rev=100.0` e `tx=10.0`, e o resultado é comparado com `[(1, (150.0, 15.0))]`. O teste verifica se os valores antigos foram somados aos novos (50.0 + 100.0 = 150.0 e 5.0 + 10.0 = 15.0).  
**Resultado esperado**: A entrada existente é atualizada com os novos totais, confirmando o comportamento de acumulação.

## 8. `test_calculate_order_totals`
**Propósito**: Testar se a função `calculate_order_totals` em `process.ml` calcula corretamente `total_amount` e `total_taxes` para um pedido com múltiplos itens.  
**Como funciona**: Uma lista de dois pares `(order, order_item)` é criada para o mesmo pedido (`id=1`): um item com `quantity=2.0`, `price=10.0` e `tax=0.1`, e outro com `quantity=1.0`, `price=20.0` e `tax=0.2`. A função `calculate_order_totals` é chamada, e o teste verifica que o resultado tem um único `order_result` com `order_id_result=1`, `total_amount=40.0` (2*10 + 1*20) e `total_taxes=6.0` (20*0.1 + 20*0.2).  
**Resultado esperado**: Os totais refletem a soma correta dos itens, confirmando a agregação por pedido.

## 9. `test_reduce_monthly_averages`
**Propósito**: Verificar se a função `reduce_monthly_averages` em `process.ml` calcula corretamente as médias mensais de receita e imposto agrupadas por `year_month`.  
**Como funciona**: Uma tabela hash (`orders_map`) é preenchida com três pedidos em dois meses (dois em janeiro de 2023 e um em fevereiro de 2023), e uma lista de `order_result` é criada com `total_amount` e `total_taxes` para cada pedido. A função `reduce_monthly_averages` é chamada, e o teste verifica que o resultado tem duas entradas (uma por mês), com `avg_amount=150.0` e `avg_tax=15.0` para janeiro (média de 100.0 e 200.0 para receita, 10.0 e 20.0 para imposto) e os mesmos valores para fevereiro (um único pedido).  
**Resultado esperado**: As médias são calculadas corretamente por mês, agrupadas por `YYYY-MM`, validando a lógica de redução.

---

## Sobre o uso de IA
O projeto integrou soluções de IA em diferentes etapas do ciclo de desenvolvimento, otimizando eficiência e qualidade técnica. Os recursos utilizados e suas aplicações incluem:

- GitHub Copilot: 
  - Auxiliou na parte de completar linhas de código, sugerindo implementações e funções.
  - Acelerou a escrita de funções e testes unitários.
  - Ajudou a identificar e corrigir erros de sintaxe e lógica.
- ChatGPT:
  - Forneceu explicações sobre conceitos de OCaml e bibliotecas.
  - Ajudou a entender melhor o funcionamento do SQLite e como integrá-lo ao projeto.
  - Ofereceu sugestões para otimizar o código e melhorar a legibilidade.
  - Ajudou a fornecer um passo-a-passo sobre como realizar o ETL, testes unitários e comentários sobre o código.

## Observações Finais
Caso queira entender mais afundo como foram os processos para realização do projeto, como foram as decisões tomadas e como foram os testes realizados, consulte o arquivo `relatorio.md` que contém um relatório mais detalhado sobre as etapas do projeto.