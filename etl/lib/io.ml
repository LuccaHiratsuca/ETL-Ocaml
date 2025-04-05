(** io.ml
    Funções para leitura e escrita de dados em CSV e SQLite. *)

    open Types

    (** [is_url source] verifica se a fonte é uma URL.
        @param source String representando o caminho ou URL
        @return true se for uma URL, false se for um caminho local *)
    let is_url (source : string) : bool =
      let lower = String.lowercase_ascii source in
      String.starts_with ~prefix:"http://" lower
      || String.starts_with ~prefix:"https://" lower
    
    (** [read_csv_local path parse_line] lê um CSV local no disco.
        @param path Caminho do arquivo CSV
        @param parse_line Função de parsing para cada linha
        @return Lista de registros parseados
        @raise Sys_error se o arquivo não puder ser aberto *)
    let read_csv_local (path : string) (parse_line : string array -> 'a) : 'a list =
      let ic = open_in path in
      let csv_input = Csv.of_channel ~has_header:true ic in
      let rec loop acc =
        match Csv.next csv_input with
        | exception End_of_file -> List.rev acc
        | line ->
          let line_array = Array.of_list line in
          let parsed = parse_line line_array in
          loop (parsed :: acc)
      in
      let result = loop [] in
      close_in ic;
      result
    
    (** [read_csv_http url parse_line] lê um CSV via HTTP usando ocurl.
        @param url URL do arquivo CSV
        @param parse_line Função de parsing para cada linha
        @return Lista de registros parseados
        @raise Curl.CurlException se a requisição HTTP falhar *)
    let read_csv_http (url : string) (parse_line : string array -> 'a) : 'a list =
      let buffer = Buffer.create 16384 in
      let connection = Curl.init () in
      Curl.set_url connection url;
      Curl.set_writefunction connection (fun data ->
          Buffer.add_string buffer data;
          String.length data
        );
      Curl.perform connection;
      Curl.cleanup connection;
      let body_str = Buffer.contents buffer in
      let csv_input = Csv.of_string ~has_header:true body_str in
      let rec loop acc =
        match Csv.next csv_input with
        | exception End_of_file -> List.rev acc
        | line ->
          let line_array = Array.of_list line in
          let parsed = parse_line line_array in
          loop (parsed :: acc)
      in
      loop []
    
    (** [read_csv source parse_line] lê um CSV decidindo automaticamente se é local ou URL.
        @param source Caminho ou URL do arquivo CSV
        @param parse_line Função de parsing para cada linha
        @return Lista de registros parseados
        @raise Sys_error se o arquivo local não puder ser aberto
        @raise Curl.CurlException se a requisição HTTP falhar *)
    let read_csv (source : string) (parse_line : string array -> 'a) : 'a list =
      if is_url source then
        read_csv_http source parse_line
      else
        read_csv_local source parse_line
    
    (** [write_csv_file path results] escreve resultados em um arquivo CSV.
        @param path Caminho do arquivo de saída
        @param results Lista de resultados de pedidos
        @return unit
        @raise Sys_error se o arquivo não puder ser criado ou escrito *)
    let write_csv_file (path : string) (results : order_result list) : unit =
      let oc = open_out path in
      Printf.fprintf oc "order_id,total_amount,total_taxes\n";
      List.iter
        (fun r ->
           Printf.fprintf oc "%d,%.2f,%.2f\n" r.order_id_result r.total_amount r.total_taxes
        )
        results;
      close_out oc
    
    (** [write_monthly_avg_csv path monthly_avgs] escreve médias mensais em um CSV.
        @param path Caminho do arquivo de saída
        @param monthly_avgs Lista de médias mensais
        @return unit
        @raise Sys_error se o arquivo não puder ser criado ou escrito *)
    let write_monthly_avg_csv (path : string) (monthly_avgs : monthly_avg list) : unit =
      let oc = open_out path in
      Printf.fprintf oc "year_month,avg_amount,avg_tax\n";
      List.iter
        (fun m ->
           Printf.fprintf oc "%s,%.2f,%.2f\n" m.year_month m.avg_amount m.avg_tax
        )
        monthly_avgs;
      close_out oc
    
    (** [save_to_sqlite db_path table_name results] salva resultados em uma tabela SQLite.
        @param db_path Caminho do banco de dados SQLite
        @param table_name Nome da tabela a criar/inserir
        @param results Lista de resultados de pedidos
        @return unit
        @raise Sqlite3.Error se a operação no banco de dados falhar *)
    let save_to_sqlite (db_path : string) (table_name : string) (results : order_result list) : unit =
      let db = Sqlite3.db_open db_path in
      ignore (Sqlite3.exec db
        (Printf.sprintf
           "CREATE TABLE IF NOT EXISTS %s (
              order_id INTEGER,
              total_amount REAL,
              total_taxes REAL
            );" table_name));
      List.iter
        (fun r ->
           let query = Printf.sprintf
             "INSERT INTO %s (order_id, total_amount, total_taxes) VALUES (%d, %.2f, %.2f);"
             table_name r.order_id_result r.total_amount r.total_taxes
           in
           ignore (Sqlite3.exec db query)
        )
        results;
      ignore (Sqlite3.db_close db)