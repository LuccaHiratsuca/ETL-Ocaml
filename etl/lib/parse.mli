(** parse.mli
    Interface para funções de parsing de linhas CSV. *)

    open Types

    (** [parse_order_line line] converte uma linha CSV em um registro [order].
        @param line Array de strings representando uma linha do CSV
        @return Um registro [order] preenchido
        @raise Failure se a conversão de strings para inteiros falhar *)
    val parse_order_line : string array -> order
    
    (** [parse_order_item_line line] converte uma linha CSV em um registro [order_item].
        @param line Array de strings representando uma linha do CSV
        @return Um registro [order_item] preenchido
        @raise Failure se a conversão de strings para inteiros ou floats falhar *)
    val parse_order_item_line : string array -> order_item