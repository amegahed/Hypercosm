unit exec_stmts;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             exec_stmts                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The interpreter controls all aspects of the renderer.   }
{       It instructs the geometry layer to build the database   }
{       and the rendering layers to build their data structs    }
{       and when and how to render the database.                }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  stmts;


var
  current_stmt_ptr: stmt_ptr_type;


{***********************************}
{ routines for executing statements }
{***********************************}
procedure Interpret_stmt(stmt_ptr: stmt_ptr_type);
procedure Interpret_stmts(stmts_ptr: stmt_ptr_type);
procedure Interpret_return_stmts(stmts_ptr: stmt_ptr_type);


implementation
uses
  errors, data_types, addr_types, arrays, exprs, instructs, decls, type_decls,
  code_decls, data, handles, memrefs, op_stacks, get_heap_data, set_heap_data,
  get_data, set_data, eval_addrs, eval_booleans, eval_chars, eval_integers,
  eval_scalars, eval_arrays, eval_structs, eval_references, eval_subranges,
  exec_structs, exec_assigns, exec_array_assigns, exec_instructs, exec_methods,
  exec_decls, interpreter;


const
  debug = false;
  memory_alert = false;


var
  loop_break_ptr: stmt_ptr_type;
  continue_break_ptr: stmt_ptr_type;

  breaking_out: boolean;
  continuing_on: boolean;


{***********************************************}
{ routines for executing conditional statements }
{***********************************************}


procedure Exec_if_stmt(stmt_ptr: stmt_ptr_type);
begin
  with stmt_ptr^ do
    begin
      Eval_boolean(if_expr_ptr);
      if Pop_boolean_operand then
        begin
          Interpret_decls(decl_ptr_type(then_decls_ptr));
          Interpret_stmts(then_stmts_ptr);
        end
      else
        begin
          Interpret_decls(decl_ptr_type(else_decls_ptr));
          Interpret_stmts(else_stmts_ptr);
        end;
    end; {with}
end; {procedure Exec_if_stmt}


procedure Exec_case_char_stmt(stmt_ptr: stmt_ptr_type);
var
  switch_case_ptr: switch_case_ptr_type;
begin
  with stmt_ptr^ do
    begin
      Eval_char(switch_expr_ptr);
      switch_case_ptr :=
        switch_array_ptr^.switch_case_array[ord(Pop_char_operand)];

      if (switch_case_ptr <> nil) then
        begin
          Interpret_decls(decl_ptr_type(switch_case_ptr^.case_decls_ptr));
          Interpret_stmts(switch_case_ptr^.case_stmts_ptr);
        end
      else
        begin
          Interpret_decls(decl_ptr_type(switch_else_decls_ptr));
          Interpret_stmts(switch_else_stmts_ptr);
        end;
    end; {with}
end; {procedure Exec_case_char_stmt}


procedure Exec_case_enum_stmt(stmt_ptr: stmt_ptr_type);
var
  switch_case_ptr: switch_case_ptr_type;
begin
  with stmt_ptr^ do
    begin
      Eval_integer(switch_expr_ptr);
      switch_case_ptr :=
        switch_array_ptr^.switch_case_array[Pop_integer_operand];

      if (switch_case_ptr <> nil) then
        begin
          Interpret_decls(decl_ptr_type(switch_case_ptr^.case_decls_ptr));
          Interpret_stmts(switch_case_ptr^.case_stmts_ptr);
        end
      else
        begin
          Interpret_decls(decl_ptr_type(switch_else_decls_ptr));
          Interpret_stmts(switch_else_stmts_ptr);
        end;
    end; {with}
end; {procedure Exec_case_enum_stmt}


{*******************************************}
{ routines for executing scoping statements }
{*******************************************}


procedure Exec_with_stmt(stmt_ptr: stmt_ptr_type);
begin
  with stmt_ptr^ do
    begin
      Interpret_decls(decl_ptr_type(with_decls_ptr));
      Interpret_stmts(with_stmts_ptr);
    end; {with}
end; {procedure Exec_with_stmt}


{*****************************************************}
{ routines for executing memory allocation statements }
{*****************************************************}


procedure Exec_dim_stmt(stmt_ptr: stmt_ptr_type);
var
  addr: addr_type;
begin
  with stmt_ptr^ do
    begin
      Eval_addr(dim_data_ptr);
      addr := Pop_addr_operand;

      if Get_addr_handle(addr) = 0 then
        begin
          Eval_array(dim_expr_ptr);
          Set_addr_handle(addr, Pop_handle_operand)
        end
      else
        Runtime_error('Arrays must be nil before dimensioning.');

      Free_addr(addr);
    end; {with}
end; {procedure Exec_dim_stmt}


procedure Exec_new_struct_stmt(stmt_ptr: stmt_ptr_type);
var
  addr: addr_type;
begin
  with stmt_ptr^ do
    begin
      Eval_addr(new_data_ptr);
      addr := Pop_addr_operand;

      if Get_addr_memref(addr) = 0 then
        begin
          Eval_struct(new_expr_ptr);
          Set_addr_memref(addr, Pop_memref_operand);
        end
      else
        Runtime_error('Can not new an object which is not nil.');

      Free_addr(addr);
    end; {with}
end; {procedure Exec_new_struct_stmt}


{*******************************************************}
{ routines for executing memory reallocation statements }
{*******************************************************}


procedure Exec_redim_stmt(stmt_ptr: stmt_ptr_type);
var
  addr: addr_type;
  handle: handle_type;
begin
  with stmt_ptr^ do
    begin
      {*******************************************}
      { dim array from array dimension expression }
      {*******************************************}
      Eval_addr(dim_data_ptr);
      addr := Pop_addr_operand;
      handle := Get_addr_handle(addr);
      Free_addr(addr);

      if handle <> 0 then
        begin
          Eval_array_bounds_list(dim_data_ptr^.dim_bounds_list_ptr);
          {
          element_size := 1;
          Redim_array(handle, dim_data_ptr^.dim_bounds_list_ptr, element_size, Error_to_data, false);
          Init_array_elements(dim_data_ptr^.kind, handle, dim_data_ptr^.dim_bounds_list_ptr, dim_data_ptr^.dim_element_ptr);
          }
        end
      else
        Runtime_error('Can not redimension a nil array.');
    end; {with}
end; {procedure Exec_redim_stmt}


procedure Exec_renew_stmt(stmt_ptr: stmt_ptr_type);
var
  addr: addr_type;
  memref: memref_type;
  type_ptr: type_ptr_type;
begin
  with stmt_ptr^ do
    begin
      if new_data_ptr <> nil then
        begin
          Eval_addr(new_data_ptr);
          addr := Pop_addr_operand;
          memref := Get_addr_memref(addr);
          Free_addr(addr);

          if memref <> 0 then
            begin
              type_ptr := type_ptr_type(new_expr_ptr^.new_struct_type_ref);
              Resize_memref(memref, type_ptr^.size);

              {*******************}
              { initialize fields }
              {*******************}
              Init_struct_fields(memref, type_ptr);

              {***********************}
              { interpret constructor }
              {***********************}
              Interpret_stmt(stmt_ptr_type(new_expr_ptr^.new_struct_init_stmt_ptr));
            end
          else
            Runtime_error('Can not redimension a nil struct or object.');
        end
      else
        Collect_garbage;
    end; {with}
end; {procedure Exec_renew_stmt}


{****************************************************}
{ routines to execute memory deallocation statements }
{****************************************************}


procedure Exec_free_array(expr_ptr: expr_ptr_type);
var
  addr: addr_type;
  handle: handle_type;
begin
  Eval_addr(expr_ptr);
  addr := Pop_addr_operand;
  handle := Get_addr_handle(addr);

  if handle <> 0 then
    begin
      Free_handle(handle);
      Set_addr_handle(addr, 0);
    end;

  Free_addr(addr);
end; {procedure Exec_free_array}


procedure Exec_free_struct(expr_ptr: expr_ptr_type);
var
  addr: addr_type;
  memref: memref_type;
begin
  Eval_addr(expr_ptr);
  addr := Pop_addr_operand;
  memref := Get_addr_memref(addr);

  if memref <> 0 then
    begin
      Free_memref(memref);
      Set_addr_memref(addr, 0);
    end;

  Free_addr(addr);
end; {procedure Exec_free_struct}


procedure Exec_free_reference(expr_ptr: expr_ptr_type);
var
  addr: addr_type;
  reference_addr: addr_type;
begin
  Eval_addr(expr_ptr);
  addr := Pop_addr_operand;
  reference_addr := Get_addr_addr(addr);

  Free_addr(reference_addr);
  Set_addr_stack_index(addr, 0);

  Free_addr(addr);
end; {procedure Exec_free_reference}


{*******************************************}
{ routines for executing looping statements }
{*******************************************}


procedure Exec_while_loop(stmt_ptr: stmt_ptr_type);
begin
  with stmt_ptr^ do
    begin
      Eval_boolean(while_expr_ptr);
      while (Pop_boolean_operand) and (not (breaking_out or returning_from)) do
        begin
          Interpret_decls(decl_ptr_type(while_decls_ptr));
          Interpret_stmts(while_stmts_ptr);

          {********************}
          { end continue break }
          {********************}
          if continuing_on then
            if (stmt_ptr = continue_break_ptr) then
              continuing_on := false;

          Eval_boolean(while_expr_ptr);
        end; {while}

      {****************}
      { end loop break }
      {****************}
      if breaking_out then
        if (stmt_ptr = loop_break_ptr) then
          breaking_out := false;
    end; {with}
end; {procedure Exec_while_loop}


procedure Exec_for_loop(stmt_ptr: stmt_ptr_type);
var
  min, max, counter: integer;
  addr: addr_type;
begin
  with stmt_ptr^ do
    begin
      Eval_addr(decl_ptr_type(counter_decl_ptr)^.data_decl.data_expr_ptr);
      addr := Pop_addr_operand;
      Eval_integer(start_expr_ptr);
      min := Pop_integer_operand;
      Eval_integer(end_expr_ptr);
      max := Pop_integer_operand;

      {********************}
      { loop through range }
      {********************}
      counter := min;
      while (counter <= max) and (not (breaking_out or returning_from)) do
        begin
          Set_addr_integer(addr, counter);

          Interpret_decls(decl_ptr_type(for_decls_ptr));
          Interpret_stmts(for_stmts_ptr);

          counter := counter + 1;

          {********************}
          { end continue break }
          {********************}
          if continuing_on then
            if (stmt_ptr = continue_break_ptr) then
              continuing_on := false;
        end; {with}

      {****************}
      { end loop break }
      {****************}
      if breaking_out then
        if (stmt_ptr = loop_break_ptr) then
          breaking_out := false;
    end; {with}
end; {procedure Exec_for_loop}


procedure Exec_for_each_loop(stmt_ptr: stmt_ptr_type);
var
  min, max, counter: integer;
  array_bounds_ptr: array_bounds_ptr_type;
  array_index_ptr: array_index_ptr_type;
begin
  with stmt_ptr^ do
    begin
      {*****************************}
      { eval array bounds or limits }
      {*****************************}
      Eval_array_subrange(for_each_array_subrange_ptr);
      array_bounds_ptr := for_each_array_subrange_ptr^.array_bounds_ref;
      min := array_bounds_ptr^.min_val;
      max := array_bounds_ptr^.max_val;
      array_index_ptr := array_bounds_ptr^.array_index_ref;

      if debug then
        writeln('for each min, max = ', min: 1, ', ', max: 1);

      {***********************}
      { loop through elements }
      {***********************}
      counter := min;
      while (counter <= max) and (not (breaking_out or returning_from)) do
        begin
          if debug then
            writeln('for each index = ', counter: 1);

          array_index_ptr^.index_val := counter;
          Interpret_stmt(loop_stmts_ptr);
          counter := counter + 1;

          {********************}
          { end continue break }
          {********************}
          if continuing_on then
            if (stmt_ptr = continue_break_ptr) then
              continuing_on := false;
        end;

      {****************}
      { end loop break }
      {****************}
      if breaking_out then
        if (stmt_ptr = loop_break_ptr) then
          breaking_out := false;
    end; {with}
end; {procedure Exec_for_each_loop}


procedure Exec_for_each_stmt(stmt_ptr: stmt_ptr_type);
var
  decl_ptr: decl_ptr_type;
  index_addr, array_addr: addr_type;
begin
  with stmt_ptr^ do
    begin
      {*********************************}
      { get address of counter variable }
      {*********************************}
      decl_ptr := decl_ptr_type(each_index_decl_ptr);
      Eval_addr(decl_ptr^.data_decl.data_expr_ptr);
      index_addr := Pop_addr_operand;

      {********************************}
      { set counter reference to array }
      {********************************}
      Eval_addr(each_array_ptr);
      array_addr := Pop_addr_operand;
      Set_addr_addr(index_addr, array_addr);

      {***************************}
      { interpret loop statements }
      {***************************}
      Interpret_decls(decl_ptr_type(each_decls_ptr));
      Interpret_stmts(each_stmts_ptr);

      Free_addr(array_addr);
    end; {with}
end; {procedure Exec_for_each_stmt}


procedure Exec_for_each_list(stmt_ptr: stmt_ptr_type);
var
  decl_ptr: decl_ptr_type;
  addr: addr_type;
begin
  with stmt_ptr^ do
    begin
      decl_ptr := decl_ptr_type(each_struct_decl_ptr);
      Eval_addr(decl_ptr^.data_decl.data_expr_ptr);
      addr := Pop_addr_operand;
      Set_addr_memref(addr, 0);

      {*****************************}
      { find starting point of list }
      {*****************************}
      Exec_struct_ptr_assign(decl_ptr^.data_decl.data_expr_ptr,
        each_list_expr_ptr);

      while (Get_addr_memref(addr) <> 0) do
        begin
          {***************************}
          { Interpret loop statements }
          {***************************}
          Interpret_decls(decl_ptr_type(list_decls_ptr));
          Interpret_stmts(list_stmts_ptr);

          {***************}
          { evaluate next }
          {***************}
          Exec_struct_ptr_assign(decl_ptr^.data_decl.data_expr_ptr,
            each_next_expr_ptr);
        end;
    end;
end; {procedure Exec_for_each_list}


{************************************************}
{ routines for executing flow control statements }
{************************************************}


procedure Exec_break_stmt(stmt_ptr: stmt_ptr_type);
begin
  breaking_out := true;
  loop_break_ptr := stmt_ptr^.enclosing_loop_ref;
end; {procedure Exec_break_stmt}


procedure Exec_continue_stmt(stmt_ptr: stmt_ptr_type);
begin
  continuing_on := true;
  continue_break_ptr := stmt_ptr^.enclosing_loop_ref;
end; {procedure Exec_continue_stmt}


procedure Exec_answer_stmt(stmt_ptr: stmt_ptr_type);
begin
  case stmt_ptr^.kind of

    {***************************************}
    { enumerated function return statements }
    {***************************************}
    boolean_answer:
      Eval_boolean(stmt_ptr^.answer_expr_ptr);
    char_answer:
      Eval_char(stmt_ptr^.answer_expr_ptr);

    {************************************}
    { integer function return statements }
    {************************************}
    byte_answer:
      Eval_byte(stmt_ptr^.answer_expr_ptr);
    short_answer:
      Eval_short(stmt_ptr^.answer_expr_ptr);
    integer_answer:
      Eval_integer(stmt_ptr^.answer_expr_ptr);
    long_answer:
      Eval_long(stmt_ptr^.answer_expr_ptr);

    {***********************************}
    { scalar function return statements }
    {***********************************}
    scalar_answer:
      Eval_scalar(stmt_ptr^.answer_expr_ptr);
    double_answer:
      Eval_double(stmt_ptr^.answer_expr_ptr);
    complex_answer:
      Eval_complex(stmt_ptr^.answer_expr_ptr);
    vector_answer:
      Eval_vector(stmt_ptr^.answer_expr_ptr);

    {**************************************}
    { reference function return statements }
    {**************************************}
    array_ptr_answer:
      Eval_array(stmt_ptr^.answer_expr_ptr);
    struct_ptr_answer:
      Eval_struct(stmt_ptr^.answer_expr_ptr);
    proto_answer:
      Eval_proto(stmt_ptr^.answer_expr_ptr);
    reference_answer:
      Eval_reference(stmt_ptr^.answer_expr_ptr);
  end; {case}

  returning_from := true;
end; {procedure Exec_answer_stmt}


{***********************************}
{ routines for executing statements }
{***********************************}


procedure Interpret_stmt(stmt_ptr: stmt_ptr_type);
begin
  if stmt_ptr^.stmt_info_ptr <> nil then
    current_stmt_ptr := stmt_ptr;

  with stmt_ptr^ do
    case kind of

      {*********************************}
      { interpret null or nop statement }
      {*********************************}
      null_stmt:
        ;

      {********************************************}
      { interpret enumerated assignment statements }
      {********************************************}
      boolean_assign:
        Exec_boolean_assign(lhs_data_ptr, rhs_expr_ptr);
      char_assign:
        Exec_char_assign(lhs_data_ptr, rhs_expr_ptr);

      {*****************************************}
      { interpret integer assignment statements }
      {*****************************************}
      byte_assign:
        Exec_byte_assign(lhs_data_ptr, rhs_expr_ptr);
      short_assign:
        Exec_short_assign(lhs_data_ptr, rhs_expr_ptr);
      integer_assign:
        Exec_integer_assign(lhs_data_ptr, rhs_expr_ptr);
      long_assign:
        Exec_long_assign(lhs_data_ptr, rhs_expr_ptr);

      {****************************************}
      { interpret scalar assignment statements }
      {****************************************}
      scalar_assign:
        Exec_scalar_assign(lhs_data_ptr, rhs_expr_ptr);
      double_assign:
        Exec_double_assign(lhs_data_ptr, rhs_expr_ptr);
      complex_assign:
        Exec_complex_assign(lhs_data_ptr, rhs_expr_ptr);
      vector_assign:
        Exec_vector_assign(lhs_data_ptr, rhs_expr_ptr);

      {*******************************************}
      { interpret reference assignment statements }
      {*******************************************}
      array_ptr_assign:
        Exec_array_ptr_assign(lhs_data_ptr, rhs_expr_ptr);
      struct_ptr_assign:
        Exec_struct_ptr_assign(lhs_data_ptr, rhs_expr_ptr);
      proto_assign:
        Exec_proto_assign(lhs_data_ptr, rhs_expr_ptr, static_level);
      reference_assign:
        Exec_reference_assign(lhs_data_ptr, rhs_expr_ptr);

      {*****************************************}
      { interpret complex assignment statements }
      {*****************************************}
      boolean_array_assign..reference_array_assign:
        Exec_array_assign(stmt_ptr);
      boolean_array_expr_assign..reference_array_expr_assign:
        Exec_array_expr_assign(stmt_ptr,
          array_expr_element_ref^.element_array_expr_ptr);

      {*************************************************}
      { interpret structure value assignment statements }
      {*************************************************}
      struct_base_assign:
        Exec_struct_base_assign(stmt_ptr);
      struct_assign:
        Exec_struct_assign(stmt_ptr);

      {**********************************}
      { interpret conditional statements }
      {**********************************}
      if_then_else:
        Exec_if_stmt(stmt_ptr);
      case_char_stmt:
        Exec_case_char_stmt(stmt_ptr);
      case_enum_stmt:
        Exec_case_enum_stmt(stmt_ptr);

      {******************************}
      { interpret scoping statements }
      {******************************}
      with_stmt:
        Exec_with_stmt(stmt_ptr);

      {****************************************}
      { interpret memory allocation statements }
      {****************************************}
      dim_stmt:
        Exec_dim_stmt(stmt_ptr);
      new_struct_stmt:
        Exec_new_struct_stmt(stmt_ptr);

      {******************************************}
      { interpret memory reallocation statements }
      {******************************************}
      redim_stmt:
        Exec_redim_stmt(stmt_ptr);
      renew_struct_stmt:
        Exec_renew_stmt(stmt_ptr);

      {********************************}
      { memory deallocation statements }
      {********************************}
      implicit_free_array_stmt:
        Exec_free_array(free_array_expr_ref);
      implicit_free_struct_stmt:
        Exec_free_struct(free_struct_expr_ref);
      implicit_free_reference_stmt:
        Exec_free_reference(free_reference_expr_ref);
      implicit_free_params_stmt:
        Free_method_params(decl_ptr_type(free_decl_ref));

      {******************************}
      { interpret looping statements }
      {******************************}
      while_loop:
        Exec_while_loop(stmt_ptr);
      for_loop:
        Exec_for_loop(stmt_ptr);
      for_each:
        Exec_for_each_stmt(stmt_ptr);
      for_each_loop:
        Exec_for_each_loop(stmt_ptr);
      for_each_list:
        Exec_for_each_list(stmt_ptr);

      {***********************************}
      { interpret flow control statements }
      {***********************************}
      loop_label_stmt:
        Interpret_stmts(loop_stmt_ptr);
      break_stmt:
        Exec_break_stmt(stmt_ptr);
      continue_stmt:
        Exec_continue_stmt(stmt_ptr);
      return_stmt:
        returning_from := true;
      boolean_answer..reference_answer:
        Exec_answer_stmt(stmt_ptr);
      exit_stmt:
        Stop;

      {*******************************}
      { interpret built in statements }
      {*******************************}
      built_in_stmt:
        Exec_instruct(instruct_ptr_type(instruct_ptr));

      {********************************}
      { interpret user defined methods }
      {********************************}
      static_method_stmt, dynamic_method_stmt, interface_method_stmt,
        proto_method_stmt:
        Interpret_method_stmt(stmt_ptr);

    end; {case}
end; {procedure Interpret_stmt}


procedure Interpret_stmts(stmts_ptr: stmt_ptr_type);
begin
  while (stmts_ptr <> nil) do
    begin
      if (not (continuing_on or breaking_out or returning_from)) or
        (stmts_ptr^.kind in implicit_free_stmt_set) then
        Interpret_stmt(stmts_ptr);

      stmts_ptr := stmts_ptr^.next;
    end;
end; {procedure Interpret_stmts}


procedure Interpret_return_stmts(stmts_ptr: stmt_ptr_type);
var
  temp: boolean;
begin
  temp := returning_from;
  returning_from := false;
  Interpret_stmts(stmts_ptr);
  returning_from := temp;
end; {procedure Interpret_return_stmts}


initialization
  current_stmt_ptr := nil;

  loop_break_ptr := nil;
  continue_break_ptr := nil;

  breaking_out := false;
  continuing_on := false;
end.
