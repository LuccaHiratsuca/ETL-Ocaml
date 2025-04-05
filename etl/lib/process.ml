(** process.ml
    Funções puras para filtragem, join e cálculos no pipeline ETL. *)

    open Types

    (** [filter_orders_by orders status origin] filtra a lista de pedidos por status e origem.
        @param orders Lista de pedidos a filtrar
        @param status Status desejado (case-insensitive)
        @param origin Origem desejada (case-insensitive)
        @return Lista filtrada de pedidos *)
    let filter_orders_by (orders : order list) (status : string) (origin : string) : order list =
      List.filter
        (fun o ->
           String.lowercase_ascii o.status = String.lowercase_ascii status
           && String.lowercase_ascii o.origin = String.lowercase_ascii origin
        )
        orders
    
    (** [join_orders_and_items orders items] realiza um inner join entre pedidos e itens.
        @param orders Lista de pedidos
        @param items Lista de itens de pedidos
        @return Lista de pares (order, order_item) onde order_id coincide *)
    let join_orders_and_items
        (orders : order list)
        (items : order_item list)
      : (order * order_item) list =
      let rec aux acc = function
        | [] -> acc
        | o :: tail ->
          let matched = List.filter (fun it -> it.order_id = o.id) items in
          let pairs = List.map (fun it -> (o, it)) matched in
          aux (acc @ pairs) tail
      in
      aux [] orders
    
    (** [update_assoc order_id rev tx assoc] atualiza uma lista de associação com somas acumuladas.
        @param order_id ID do pedido
        @param rev Receita a adicionar
        @param tx Imposto a adicionar
        @param assoc Lista de associação existente
        @return Lista de associação atualizada *)
    let update_assoc (order_id : int) (rev : float) (tx : float)
                     (assoc : (int * (float * float)) list)
      : (int * (float * float)) list =
      match List.assoc_opt order_id assoc with
      | None ->
        (order_id, (rev, tx)) :: assoc
      | Some (old_r, old_t) ->
        let new_r = old_r +. rev in
        let new_tx = old_t +. tx in
        (order_id, (new_r, new_tx)) :: List.remove_assoc order_id assoc
    
    (** [calculate_order_totals pairs] calcula totais por pedido a partir de pares.
        @param pairs Lista de pares (order, order_item)
        @return Lista de resultados agregados por pedido *)
    let calculate_order_totals (pairs : (order * order_item) list) : order_result list =
      let assoc_sums =
        List.fold_left
          (fun acc (o, it) ->
             let revenue = it.quantity *. it.price in
             let tax_val = revenue *. it.tax in
             update_assoc o.id revenue tax_val acc
          )
          []
          pairs
      in
      List.map
        (fun (oid, (rev, tx)) -> { order_id_result = oid; total_amount = rev; total_taxes = tx })
        assoc_sums
    
    (** [reduce_monthly_averages orders_map results] calcula médias mensais.
        @param orders_map Hash table mapeando order_id para order
        @param order_results Lista de resultados de pedidos
        @return Lista de médias mensais *)
    let reduce_monthly_averages
        (orders_map : (int, order) Hashtbl.t)
        (order_results : order_result list)
      : monthly_avg list =
      let update_ym ym (rev : float) (tx : float)
                     (assoc : (string * (float * float * int)) list)
        : (string * (float * float * int)) list =
        match List.assoc_opt ym assoc with
        | None ->
          (ym, (rev, tx, 1)) :: assoc
        | Some (old_r, old_t, old_c) ->
          (ym, (old_r +. rev, old_t +. tx, old_c + 1))
          :: (List.remove_assoc ym assoc)
      in
      let assoc_sums =
        List.fold_left
          (fun acc orr ->
             match Hashtbl.find_opt orders_map orr.order_id_result with
             | None -> acc
             | Some ord ->
               if String.length ord.order_date >= 7 then
                 let ym = String.sub ord.order_date 0 7 in
                 update_ym ym orr.total_amount orr.total_taxes acc
               else
                 acc
          )
          []
          order_results
      in
      List.map
        (fun (ym, (srev, stx, c)) ->
           {
             year_month = ym;
             avg_amount = srev /. float_of_int c;
             avg_tax = stx /. float_of_int c;
           }
        )
        assoc_sums