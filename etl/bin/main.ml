(** main.ml
    Ponto de entrada do pipeline ETL. *)

    open Etl.Types
    open Etl.Parse
    open Etl.Process
    open Etl.Io
    
    (** [main] executa o pipeline ETL completo.
        Lê argumentos da linha de comando, processa dados e salva resultados.
        @return unit *)
    let () =
      (* Lê parâmetros da linha de comando *)
      let status = if Array.length Sys.argv > 1 then Sys.argv.(1) else "complete" in
      let origin = if Array.length Sys.argv > 2 then Sys.argv.(2) else "O" in
      let orders_source =
        if Array.length Sys.argv > 3 then Sys.argv.(3) else "data/raw/order.csv"
      in
      let items_source =
        if Array.length Sys.argv > 4 then Sys.argv.(4) else "data/raw/order_item.csv"
      in
    
      Printf.printf "Status=%s, Origin=%s\nOrders source=%s\nItems source=%s\n\n%!"
        status origin orders_source items_source;
    
      (* Carrega dados *)
      let orders = read_csv orders_source parse_order_line in
      let items = read_csv items_source parse_order_item_line in
    
      (* Filtra pedidos *)
      let filtered_orders = filter_orders_by orders status origin in
    
      (* Join e cálculo *)
      let joined = join_orders_and_items filtered_orders items in
      let results = calculate_order_totals joined in
    
      (* Gera CSV e salva em SQLite *)
      let out_csv = "data/processed/out.csv" in
      write_csv_file out_csv results;
      Printf.printf "Arquivo %s gerado.\n%!" out_csv;
    
      let db_path = "data/processed/out.db" in
      save_to_sqlite db_path "order_results" results;
      Printf.printf "Inserido em %s (tabela order_results).\n%!" db_path;
    
      (* Calcula e salva médias mensais *)
      let order_map = Hashtbl.create (List.length filtered_orders) in
      List.iter (fun o -> Hashtbl.add order_map o.id o) filtered_orders;
      let monthly = reduce_monthly_averages order_map results in
      let out_monthly = "data/processed/out_monthly.csv" in
      write_monthly_avg_csv out_monthly monthly;
      Printf.printf "Arquivo %s gerado (médias por mês).\n%!" out_monthly