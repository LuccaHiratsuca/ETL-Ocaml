(** parse.ml
    Funções para parsing de linhas CSV em tipos definidos. *)

    open Types

    (** [parse_order_line line] converte uma linha CSV em um registro [order].
        @param line Array de strings representando uma linha do CSV
        @return Um registro [order] preenchido
        @raise Failure se a conversão de strings para inteiros falhar *)
    let parse_order_line (line : string array) : order =
      {
        id = int_of_string line.(0);
        client_id = int_of_string line.(1);
        order_date = line.(2);
        status = line.(3);
        origin = line.(4);
      }
    
    (** [parse_order_item_line line] converte uma linha CSV em um registro [order_item].
        @param line Array de strings representando uma linha do CSV
        @return Um registro [order_item] preenchido
        @raise Failure se a conversão de strings para inteiros ou floats falhar *)
    let parse_order_item_line (line : string array) : order_item =
      {
        order_id = int_of_string line.(0);
        product_id = int_of_string line.(1);
        quantity = float_of_string line.(2);
        price = float_of_string line.(3);
        tax = float_of_string line.(4);
      }