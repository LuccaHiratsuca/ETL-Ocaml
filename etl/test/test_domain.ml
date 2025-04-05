(** test_domain.ml
    Testes OUnit para as funções puras do pipeline ETL (parse e process). *)

    open OUnit2
    open Etl.Types
    open Etl.Parse
    open Etl.Process
    
    (** Testes para parse.ml *)
    
    (** Testa parse_order_line com uma linha válida *)
    let test_parse_order_line _ =
      let line = [| "1"; "10"; "2023-01-02"; "complete"; "O" |] in
      let o = parse_order_line line in
      assert_equal 1 o.id ~msg:"ID deve ser 1";
      assert_equal 10 o.client_id ~msg:"client_id deve ser 10";
      assert_equal "2023-01-02" o.order_date ~msg:"order_date deve ser 2023-01-02";
      assert_equal "complete" o.status ~msg:"status deve ser complete";
      assert_equal "O" o.origin ~msg:"origin deve ser O"
    
    (** Testa parse_order_item_line com uma linha válida *)
    let test_parse_order_item_line _ =
      let line = [| "2"; "999"; "2.0"; "15.00"; "0.20" |] in
      let it = parse_order_item_line line in
      assert_equal 2 it.order_id ~msg:"order_id deve ser 2";
      assert_equal 999 it.product_id ~msg:"product_id deve ser 999";
      assert_equal 2.0 it.quantity ~msg:"quantity deve ser 2.0";
      assert_equal 15.00 it.price ~msg:"price deve ser 15.00";
      assert_equal 0.20 it.tax ~msg:"tax deve ser 0.20"
    
    (** Testes para process.ml *)
    
    (** Testa filter_orders_by com filtros válidos *)
    let test_filter_orders_by _ =
      let orders = [
        { id = 1; client_id = 1; order_date = "2023-01-01"; status = "complete"; origin = "O" };
        { id = 2; client_id = 2; order_date = "2023-01-02"; status = "pending"; origin = "P" };
        { id = 3; client_id = 3; order_date = "2023-01-03"; status = "complete"; origin = "P" }
      ] in
      let filtered = filter_orders_by orders "complete" "O" in
      assert_equal 1 (List.length filtered) ~msg:"Deve retornar 1 pedido";
      assert_equal 1 (List.hd filtered).id ~msg:"ID do pedido filtrado deve ser 1"
    
    (** Testa filter_orders_by com case-insensitive *)
    let test_filter_orders_by_case_insensitive _ =
      let orders = [
        { id = 1; client_id = 1; order_date = "2023-01-01"; status = "COMPLETE"; origin = "o" }
      ] in
      let filtered = filter_orders_by orders "complete" "O" in
      assert_equal 1 (List.length filtered) ~msg:"Deve ignorar case e retornar 1 pedido"
    
    (** Testa join_orders_and_items com correspondências *)
    let test_join_orders_and_items _ =
      let orders = [
        { id = 1; client_id = 1; order_date = "2023-01-01"; status = "complete"; origin = "O" };
        { id = 2; client_id = 2; order_date = "2023-01-02"; status = "pending"; origin = "P" }
      ] in
      let items = [
        { order_id = 1; product_id = 101; quantity = 2.0; price = 10.0; tax = 0.1 };
        { order_id = 1; product_id = 102; quantity = 1.0; price = 20.0; tax = 0.2 }
      ] in
      let joined = join_orders_and_items orders items in
      assert_equal 2 (List.length joined) ~msg:"Deve retornar 2 pares";
      let (o1, i1) = List.hd joined in
      assert_equal 1 o1.id ~msg:"Primeiro pedido deve ter ID 1";
      assert_equal 101 i1.product_id ~msg:"Primeiro item deve ter product_id 101"
    
    (** Testa update_assoc com nova entrada *)
    let test_update_assoc_new _ =
      let assoc = [] in
      let updated = update_assoc 1 100.0 10.0 assoc in
      assert_equal [(1, (100.0, 10.0))] updated ~msg:"Deve adicionar nova entrada"
    
    (** Testa update_assoc com atualização de entrada existente *)
    let test_update_assoc_update _ =
      let assoc = [(1, (50.0, 5.0))] in
      let updated = update_assoc 1 100.0 10.0 assoc in
      assert_equal [(1, (150.0, 15.0))] updated ~msg:"Deve somar valores existentes"
    
    (** Testa calculate_order_totals com pares válidos *)
    let test_calculate_order_totals _ =
      let pairs = [
        ({ id = 1; client_id = 1; order_date = "2023-01-01"; status = "complete"; origin = "O" },
         { order_id = 1; product_id = 101; quantity = 2.0; price = 10.0; tax = 0.1 });
        ({ id = 1; client_id = 1; order_date = "2023-01-01"; status = "complete"; origin = "O" },
         { order_id = 1; product_id = 102; quantity = 1.0; price = 20.0; tax = 0.2 })
      ] in
      let totals = calculate_order_totals pairs in
      assert_equal 1 (List.length totals) ~msg:"Deve retornar 1 resultado";
      let result = List.hd totals in
      assert_equal 1 result.order_id_result ~msg:"order_id_result deve ser 1";
      assert_equal 40.0 result.total_amount ~msg:"total_amount deve ser 40.0 (2*10 + 1*20)";
      assert_equal 6.0 result.total_taxes ~msg:"total_taxes deve ser 6.0 (20*0.1 + 20*0.2)"
    
    (** Testa reduce_monthly_averages com dados válidos *)
    let test_reduce_monthly_averages _ =
      let orders = [
        { id = 1; client_id = 1; order_date = "2023-01-01"; status = "complete"; origin = "O" };
        { id = 2; client_id = 2; order_date = "2023-01-02"; status = "complete"; origin = "O" };
        { id = 3; client_id = 3; order_date = "2023-02-01"; status = "complete"; origin = "O" }
      ] in
      let order_results = [
        { order_id_result = 1; total_amount = 100.0; total_taxes = 10.0 };
        { order_id_result = 2; total_amount = 200.0; total_taxes = 20.0 };
        { order_id_result = 3; total_amount = 150.0; total_taxes = 15.0 }
      ] in
      let orders_map = Hashtbl.create 3 in
      List.iter (fun o -> Hashtbl.add orders_map o.id o) orders;
      let monthly = reduce_monthly_averages orders_map order_results in
      assert_equal 2 (List.length monthly) ~msg:"Deve retornar 2 meses";
      let jan = List.find (fun m -> m.year_month = "2023-01") monthly in
      assert_equal 150.0 jan.avg_amount ~msg:"Média de janeiro deve ser 150.0 (100+200)/2";
      assert_equal 15.0 jan.avg_tax ~msg:"Média de impostos de janeiro deve ser 15.0 (10+20)/2";
      let feb = List.find (fun m -> m.year_month = "2023-02") monthly in
      assert_equal 150.0 feb.avg_amount ~msg:"Média de fevereiro deve ser 150.0";
      assert_equal 15.0 feb.avg_tax ~msg:"Média de impostos de fevereiro deve ser 15.0"
    
    (** Suite de testes *)
    let suite =
      "TestDomain" >::: [
        "test_parse_order_line" >:: test_parse_order_line;
        "test_parse_order_item_line" >:: test_parse_order_item_line;
        "test_filter_orders_by" >:: test_filter_orders_by;
        "test_filter_orders_by_case_insensitive" >:: test_filter_orders_by_case_insensitive;
        "test_join_orders_and_items" >:: test_join_orders_and_items;
        "test_update_assoc_new" >:: test_update_assoc_new;
        "test_update_assoc_update" >:: test_update_assoc_update;
        "test_calculate_order_totals" >:: test_calculate_order_totals;
        "test_reduce_monthly_averages" >:: test_reduce_monthly_averages;
      ]
    
    let () =
      run_test_tt_main suite