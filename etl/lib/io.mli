(** io.mli
    Interface para funções de entrada/saída do pipeline ETL. *)

    open Types

    (** [is_url source] verifica se a fonte é uma URL.
        @param source String representando o caminho ou URL
        @return true se for uma URL, false se for um caminho local *)
    val is_url : string -> bool
    
    (** [read_csv_local path parse_line] lê um CSV local no disco.
        @param path Caminho do arquivo CSV
        @param parse_line Função de parsing para cada linha
        @return Lista de registros parseados
        @raise Sys_error se o arquivo não puder ser aberto *)
    val read_csv_local : string -> (string array -> 'a) -> 'a list
    
    (** [read_csv_http url parse_line] lê um CSV via HTTP usando ocurl.
        @param url URL do arquivo CSV
        @param parse_line Função de parsing para cada linha
        @return Lista de registros parseados
        @raise Curl.CurlException se a requisição HTTP falhar *)
    val read_csv_http : string -> (string array -> 'a) -> 'a list
    
    (** [read_csv source parse_line] lê um CSV decidindo automaticamente se é local ou URL.
        @param source Caminho ou URL do arquivo CSV
        @param parse_line Função de parsing para cada linha
        @return Lista de registros parseados
        @raise Sys_error se o arquivo local não puder ser aberto
        @raise Curl.CurlException se a requisição HTTP falhar *)
    val read_csv : string -> (string array -> 'a) -> 'a list
    
    (** [write_csv_file path results] escreve resultados em um arquivo CSV.
        @param path Caminho do arquivo de saída
        @param results Lista de resultados de pedidos
        @return unit
        @raise Sys_error se o arquivo não puder ser criado ou escrito *)
    val write_csv_file : string -> order_result list -> unit
    
    (** [write_monthly_avg_csv path monthly_avgs] escreve médias mensais em um CSV.
        @param path Caminho do arquivo de saída
        @param monthly_avgs Lista de médias mensais
        @return unit
        @raise Sys_error se o arquivo não puder ser criado ou escrito *)
    val write_monthly_avg_csv : string -> monthly_avg list -> unit
    
    (** [save_to_sqlite db_path table_name results] salva resultados em uma tabela SQLite.
        @param db_path Caminho do banco de dados SQLite
        @param table_name Nome da tabela a criar/inserir
        @param results Lista de resultados de pedidos
        @return unit
        @raise Sqlite3.Error se a operação no banco de dados falhar *)
    val save_to_sqlite : string -> string -> order_result list -> unit