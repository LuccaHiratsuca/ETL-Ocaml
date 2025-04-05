(** process.mli
    Interface para funções de processamento do pipeline ETL. *)

    open Types

    (** [filter_orders_by orders status origin] filtra a lista de pedidos por status e origem.
        @param orders Lista de pedidos a filtrar
        @param status Status desejado (case-insensitive)
        @param origin Origem desejada (case-insensitive)
        @return Lista filtrada de pedidos *)
    val filter_orders_by : order list -> string -> string -> order list
    
    (** [join_orders_and_items orders items] realiza um inner join entre pedidos e itens.
        @param orders Lista de pedidos
        @param items Lista de itens de pedidos
        @return Lista de pares (order, order_item) onde order_id coincide *)
    val join_orders_and_items : order list -> order_item list -> (order * order_item) list
    
    (** [update_assoc order_id rev tx assoc] atualiza uma lista de associação com somas acumuladas.
        @param order_id ID do pedido
        @param rev Receita a adicionar
        @param tx Imposto a adicionar
        @param assoc Lista de associação existente
        @return Lista de associação atualizada *)
    val update_assoc : int -> float -> float -> (int * (float * float)) list -> (int * (float * float)) list
    
    (** [calculate_order_totals pairs] calcula totais por pedido a partir de pares.
        @param pairs Lista de pares (order, order_item)
        @return Lista de resultados agregados por pedido *)
    val calculate_order_totals : (order * order_item) list -> order_result list
    
    (** [reduce_monthly_averages orders_map results] calcula médias mensais.
        @param orders_map Hash table mapeando order_id para order
        @param order_results Lista de resultados de pedidos
        @return Lista de médias mensais *)
    val reduce_monthly_averages : (int, order) Hashtbl.t -> order_result list -> monthly_avg list