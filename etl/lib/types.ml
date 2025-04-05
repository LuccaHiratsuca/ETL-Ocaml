(** types.ml
    Definição dos tipos de dados para o pipeline ETL. *)

(** Tipo representando um pedido na tabela [Order]. *)
type order = {
  id : int;
  client_id : int;
  order_date : string;  (** Data no formato "YYYY-MM-DD" *)
  status : string;      (** "pending", "complete", "cancelled" *)
  origin : string;      (** "O" ou "P" *)
}

(** Tipo representando um item de pedido na tabela [OrderItem]. *)
type order_item = {
  order_id : int;
  product_id : int;
  quantity : float;
  price : float;
  tax : float;  (** Ex: 0.10 = 10% *)
}

(** Tipo representando o resultado agregado de um pedido. *)
type order_result = {
  order_id_result : int;
  total_amount : float;
  total_taxes : float;
}

(** Tipo representando médias mensais de pedidos. *)
type monthly_avg = {
  year_month : string;  (** Ex: "2023-05" *)
  avg_amount : float;
  avg_tax : float;
}