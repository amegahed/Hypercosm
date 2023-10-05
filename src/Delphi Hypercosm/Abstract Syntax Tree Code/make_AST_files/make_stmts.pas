unit make_stmts;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             make_stmts                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module defines recursive operations which          }
{       are performed on the statement syntax trees.            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  exprs, stmts;


{**************************************************}
{ routines for recursively copying statement trees }
{**************************************************}
function Clone_stmt(stmt_ptr: stmt_ptr_type;
  copy_attributes: boolean): stmt_ptr_type;
function Clone_stmts(stmt_ptr: stmt_ptr_type;
  copy_attributes: boolean): stmt_ptr_type;

{**************************************************}
{ routines for recursively freeing statement trees }
{**************************************************}
procedure Destroy_stmt(var stmt_ptr: stmt_ptr_type;
  free_attributes: boolean);
procedure Destroy_stmts(var stmt_ptr: stmt_ptr_type;
  free_attributes: boolean);
procedure Destroy_abstract_stmt(var stmt_ptr: forward_stmt_ptr_type;
  free_attributes: boolean);

{**************************************************}
{ routines for recursively marking statement trees }
{**************************************************}
procedure Mark_stmt(stmt_ptr: stmt_ptr_type;
  touched: boolean);
procedure Mark_stmts(stmt_ptr: stmt_ptr_type;
  touched: boolean);

{****************************************************}
{ routines for recursively comparing statement trees }
{****************************************************}
function Equal_stmts(stmt_ptr1, stmt_ptr2: stmt_ptr_type): boolean;
function Same_stmts(stmt_ptr1, stmt_ptr2: stmt_ptr_type): boolean;


implementation
uses
  decls, code_decls, type_decls, make_arrays, make_exprs, make_instructs,
  make_decls, make_type_decls, make_code_decls;


{**************************************************}
{ routines for recursively copying statement trees }
{**************************************************}


function Clone_switch_case(switch_case_ptr: switch_case_ptr_type;
  copy_attributes: boolean): switch_case_ptr_type;
var
  new_switch_case_ptr: switch_case_ptr_type;
begin
  if switch_case_ptr <> nil then
    begin
      new_switch_case_ptr := New_switch_case;
      new_switch_case_ptr^.case_decls_ptr :=
        forward_decl_ptr_type(Clone_decls(decl_ptr_type(switch_case_ptr^.case_decls_ptr), copy_attributes));
      new_switch_case_ptr^.case_stmts_ptr :=
        Clone_stmts(switch_case_ptr^.case_stmts_ptr, copy_attributes);
    end
  else
    new_switch_case_ptr := nil;

  Clone_switch_case := new_switch_case_ptr;
end; {function Clone_switch_case}


function Clone_switch_array(switch_array_ptr: switch_array_ptr_type;
  copy_attributes: boolean): switch_array_ptr_type;
var
  new_switch_array_ptr: switch_array_ptr_type;
  new_switch_case_ptr: switch_case_ptr_type;
  counter: integer;
begin
  if switch_array_ptr <> nil then
    begin
      new_switch_array_ptr := New_switch_array;
      for counter := 0 to switch_array_size do
        begin
          new_switch_case_ptr :=
            Clone_switch_case(switch_array_ptr^.switch_case_array[counter],
            copy_attributes);
          new_switch_array_ptr^.switch_case_array[counter] :=
            new_switch_case_ptr;
        end;
    end
  else
    new_switch_array_ptr := nil;

  Clone_switch_array := new_switch_array_ptr;
end; {function Clone_switch_array}


function Clone_case_constant(case_constant_ptr: case_constant_ptr_type;
  copy_attributes: boolean): case_constant_ptr_type;
var
  new_case_constant_ptr: case_constant_ptr_type;
begin
  if case_constant_ptr <> nil then
    begin
      new_case_constant_ptr := New_case_constant;
      new_case_constant_ptr^.case_expr_ptr :=
        Clone_expr(case_constant_ptr^.case_expr_ptr, copy_attributes);
      new_case_constant_ptr^.value := case_constant_ptr^.value;
    end
  else
    new_case_constant_ptr := nil;

  Clone_case_constant := new_case_constant_ptr;
end; {function Clone_case_constant}


function Clone_case_constants(case_constant_ptr: case_constant_ptr_type;
  copy_attributes: boolean): case_constant_ptr_type;
var
  new_case_constant_ptr: case_constant_ptr_type;
  first_case_constant_ptr, last_case_constant_ptr: case_constant_ptr_type;
begin
  first_case_constant_ptr := nil;
  last_case_constant_ptr := nil;

  while case_constant_ptr <> nil do
    begin
      new_case_constant_ptr := Clone_case_constant(case_constant_ptr,
        copy_attributes);

      {**************************************}
      { add new case constant to end of list }
      {**************************************}
      if (last_case_constant_ptr <> nil) then
        begin
          last_case_constant_ptr^.next := new_case_constant_ptr;
          last_case_constant_ptr := new_case_constant_ptr;
        end
      else
        begin
          first_case_constant_ptr := new_case_constant_ptr;
          last_case_constant_ptr := new_case_constant_ptr;
        end;

      case_constant_ptr := case_constant_ptr^.next;
    end;

  Clone_case_constants := first_case_constant_ptr;
end; {function Clone_case_constants}


function Clone_stmt_data(stmt_data_ptr: stmt_data_ptr_type;
  copy_attributes: boolean): stmt_data_ptr_type;
var
  new_stmt_data_ptr: stmt_data_ptr_type;
begin
  if stmt_data_ptr <> nil then
    begin
      new_stmt_data_ptr := New_stmt_data;
      new_stmt_data_ptr^.shader_stmt_ptr :=
        Clone_stmt(stmt_data_ptr^.shader_stmt_ptr, copy_attributes);
      new_stmt_data_ptr^.edge_shader_stmt_ptr :=
        Clone_stmt(stmt_data_ptr^.edge_shader_stmt_ptr, copy_attributes);
    end
  else
    new_stmt_data_ptr := nil;

  Clone_stmt_data := new_stmt_data_ptr;
end; {function Clone_stmt_data}


function Clone_stmt(stmt_ptr: stmt_ptr_type;
  copy_attributes: boolean): stmt_ptr_type;
var
  new_stmt_ptr: stmt_ptr_type;
begin
  if (stmt_ptr <> nil) then
    begin
      new_stmt_ptr := Copy_stmt(stmt_ptr);

      {***************************}
      { copy auxilliary stmt info }
      {***************************}
      if stmt_ptr^.stmt_info_ptr <> nil then
        begin
          new_stmt_ptr^.stmt_info_ptr := Copy_stmt_info(stmt_ptr^.stmt_info_ptr,
            true);
          Set_stmt_info(new_stmt_ptr, new_stmt_ptr^.stmt_info_ptr);
        end;

      with new_stmt_ptr^ do
        case kind of

          {***********************}
          { null or nop statement }
          {***********************}
          null_stmt:
            ;

          {******************************}
          { simple assignment statements }
          {******************************}
          boolean_assign..reference_assign:
            begin
              lhs_data_ptr := Clone_expr(lhs_data_ptr, copy_attributes);
              rhs_expr_ptr := Clone_expr(rhs_expr_ptr, copy_attributes);
            end;

          {*****************************}
          { array assignment statements }
          {*****************************}
          boolean_array_assign..reference_array_assign:
            begin
              lhs_array_subrange_ptr :=
                Clone_array_subrange(lhs_array_subrange_ptr, copy_attributes);
              rhs_array_subrange_ptr :=
                Clone_array_subrange(rhs_array_subrange_ptr, copy_attributes);
              array_assign_stmt_ptr := Clone_stmt(array_assign_stmt_ptr,
                copy_attributes);

              {******************************************************}
              { structure array implicit allocation / initialization }
              {******************************************************}
              array_struct_new_ptr := Clone_expr(array_struct_new_ptr,
                copy_attributes);
            end;
          subarray_assign:
            begin
              lhs_subarray_subrange_ptr :=
                Clone_array_subrange(lhs_subarray_subrange_ptr,
                copy_attributes);
              rhs_subarray_subrange_ptr :=
                Clone_array_subrange(rhs_subarray_subrange_ptr,
                copy_attributes);
              subarray_assign_stmt_ptr := Clone_stmt(subarray_assign_stmt_ptr,
                copy_attributes);
            end;

          {****************************************}
          { array expression assignment statements }
          {****************************************}
          boolean_array_expr_assign..reference_array_expr_assign:
            begin
              array_expr_subrange_ptr :=
                Clone_array_subrange(array_expr_subrange_ptr, copy_attributes);
              array_expr_assign_stmt_ptr :=
                Clone_stmt(array_expr_assign_stmt_ptr, copy_attributes);

              {******************************************************}
              { structure array implicit allocation / initialization }
              {******************************************************}
              array_expr_struct_new_ptr := Clone_expr(array_expr_struct_new_ptr,
                copy_attributes);
            end;
          subarray_expr_assign:
            begin
              subarray_expr_subrange_ptr :=
                Clone_array_subrange(subarray_expr_subrange_ptr,
                copy_attributes);
              subarray_expr_assign_stmt_ptr :=
                Clone_stmt(subarray_expr_assign_stmt_ptr, copy_attributes);
            end;

          {******************************}
          { struct assignment statements }
          {******************************}
          struct_assign:
            begin
              lhs_struct_expr_ptr := Clone_expr(lhs_struct_expr_ptr,
                copy_attributes);
              rhs_struct_expr_ptr := Clone_expr(rhs_struct_expr_ptr,
                copy_attributes);
            end;
          struct_base_assign:
            begin
              lhs_struct_base_ptr := Clone_expr(lhs_struct_base_ptr,
                copy_attributes);
              rhs_struct_base_ptr := Clone_expr(rhs_struct_base_ptr,
                copy_attributes);
              field_assign_stmts_ptr := Clone_stmts(field_assign_stmts_ptr,
                copy_attributes);
            end;

          {************************}
          { conditional statements }
          {************************}
          if_then_else:
            begin
              if_expr_ptr := Clone_expr(if_expr_ptr, copy_attributes);
              then_decls_ptr :=
                forward_decl_ptr_type(Clone_decls(decl_ptr_type(then_decls_ptr),
                copy_attributes));
              then_stmts_ptr := Clone_stmts(then_stmts_ptr, copy_attributes);
              else_decls_ptr :=
                forward_decl_ptr_type(Clone_decls(decl_ptr_type(else_decls_ptr),
                copy_attributes));
              else_stmts_ptr := Clone_stmts(else_stmts_ptr, copy_attributes);
            end;
          case_char_stmt, case_enum_stmt:
            begin
              switch_expr_ptr := Clone_expr(switch_expr_ptr, copy_attributes);
              switch_array_ptr := Clone_switch_array(switch_array_ptr,
                copy_attributes);
              switch_else_decls_ptr :=
                forward_decl_ptr_type(Clone_decls(decl_ptr_type(switch_else_decls_ptr), copy_attributes));
              switch_else_stmts_ptr := Clone_stmts(switch_else_stmts_ptr,
                copy_attributes);
              switch_case_constant_ptr :=
                Clone_case_constants(switch_case_constant_ptr, copy_attributes);
            end;

          {********************}
          { looping statements }
          {********************}
          while_loop:
            begin
              while_expr_ptr := Clone_expr(while_expr_ptr, copy_attributes);
              while_decls_ptr :=
                forward_decl_ptr_type(Clone_decls(decl_ptr_type(while_decls_ptr),
                copy_attributes));
              while_stmts_ptr := Clone_stmts(while_stmts_ptr, copy_attributes);
            end;
          for_loop:
            begin
              counter_decl_ptr :=
                forward_decl_ptr_type(Clone_decl(decl_ptr_type(counter_decl_ptr),
                copy_attributes));
              start_expr_ptr := Clone_expr(start_expr_ptr, copy_attributes);
              end_expr_ptr := Clone_expr(end_expr_ptr, copy_attributes);
              for_decls_ptr :=
                forward_decl_ptr_type(Clone_decls(decl_ptr_type(for_decls_ptr),
                copy_attributes));
              for_stmts_ptr := Clone_stmts(for_stmts_ptr, copy_attributes);
            end;
          for_each:
            begin
              each_index_decl_ptr :=
                forward_decl_ptr_type(Clone_decl(decl_ptr_type(each_index_decl_ptr), copy_attributes));
              each_array_ptr := Clone_expr(each_array_ptr, copy_attributes);
              each_decls_ptr :=
                forward_decl_ptr_type(Clone_decls(decl_ptr_type(each_decls_ptr),
                copy_attributes));
              each_stmts_ptr := Clone_stmts(each_stmts_ptr, copy_attributes);
            end;
          for_each_loop:
            begin
              for_each_array_subrange_ptr :=
                Clone_array_subrange(for_each_array_subrange_ptr,
                copy_attributes);
              loop_stmts_ptr := Clone_stmts(loop_stmts_ptr, copy_attributes);
            end;
          for_each_list:
            begin
              each_struct_decl_ptr :=
                forward_decl_ptr_type(Clone_decl(decl_ptr_type(each_struct_decl_ptr), copy_attributes));
              each_next_expr_ptr := Clone_expr(each_next_expr_ptr,
                copy_attributes);
              each_list_expr_ptr := Clone_expr(each_list_expr_ptr,
                copy_attributes);
              list_decls_ptr :=
                forward_decl_ptr_type(Clone_decls(decl_ptr_type(list_decls_ptr),
                copy_attributes));
              list_stmts_ptr := Clone_stmts(list_stmts_ptr, copy_attributes);
            end;

          {*************************}
          { flow control statements }
          {*************************}
          break_stmt, continue_stmt, return_stmt, exit_stmt:
            ;
          loop_label_stmt:
            loop_stmt_ptr := Clone_stmt(loop_stmt_ptr, copy_attributes);
          boolean_answer..reference_answer:
            answer_expr_ptr := Clone_expr(answer_expr_ptr, copy_attributes);

          {********************}
          { scoping statements }
          {********************}
          with_stmt:
            begin
              with_expr_ptr := Clone_expr(with_expr_ptr, copy_attributes);
              with_decls_ptr :=
                forward_decl_ptr_type(Clone_decls(decl_ptr_type(with_decls_ptr),
                copy_attributes));
              with_stmts_ptr := Clone_stmts(with_stmts_ptr, copy_attributes);
            end;

          {******************************}
          { memory allocation statements }
          {******************************}
          dim_stmt, redim_stmt:
            begin
              dim_data_ptr := Clone_expr(dim_data_ptr, copy_attributes);
              dim_expr_ptr := Clone_expr(dim_expr_ptr, copy_attributes);
            end;
          new_struct_stmt, renew_struct_stmt:
            begin
              new_data_ptr := Clone_expr(new_data_ptr, copy_attributes);
              new_expr_ptr := Clone_expr(new_expr_ptr, copy_attributes);
            end;

          {********************************}
          { memory deallocation statements }
          {********************************}
          implicit_free_array_stmt, implicit_free_struct_stmt:
            ;
          implicit_free_reference_stmt, implicit_free_params_stmt:
            ;

          {*********************}
          { built in statements }
          {*********************}
          built_in_stmt:
            instruct_ptr := Clone_instruct(instruct_ptr, copy_attributes);

          {*****************************************}
          { user defined subprogram call statements }
          {*****************************************}
          static_method_stmt, dynamic_method_stmt, interface_method_stmt,
            proto_method_stmt:
            begin
              stmt_name_ptr := Clone_expr(stmt_name_ptr, copy_attributes);
              implicit_stmts_ptr := Clone_stmts(implicit_stmts_ptr,
                copy_attributes);

              param_assign_stmts_ptr := Clone_stmts(param_assign_stmts_ptr,
                copy_attributes);
              param_stmts_ptr := Clone_stmts(param_stmts_ptr, copy_attributes);

              return_assign_stmts_ptr := Clone_stmts(return_assign_stmts_ptr,
                copy_attributes);
              return_stmts_ptr := Clone_stmts(return_stmts_ptr,
                copy_attributes);
            end
        end; {case}
    end
  else
    new_stmt_ptr := nil;

  Clone_stmt := new_stmt_ptr;
end; {function Clone_stmt}


function Clone_stmts(stmt_ptr: stmt_ptr_type;
  copy_attributes: boolean): stmt_ptr_type;
var
  new_stmt_ptr: stmt_ptr_type;
  first_stmt_ptr, last_stmt_ptr: stmt_ptr_type;
begin
  first_stmt_ptr := nil;
  last_stmt_ptr := nil;

  while stmt_ptr <> nil do
    begin
      new_stmt_ptr := Clone_stmt(stmt_ptr, copy_attributes);

      {**********************************}
      { add new stmt node to end of list }
      {**********************************}
      if (last_stmt_ptr <> nil) then
        begin
          last_stmt_ptr^.next := new_stmt_ptr;
          last_stmt_ptr := new_stmt_ptr;
        end
      else
        begin
          first_stmt_ptr := new_stmt_ptr;
          last_stmt_ptr := new_stmt_ptr;
        end;

      stmt_ptr := stmt_ptr^.next;
    end;

  Clone_stmts := first_stmt_ptr;
end; {function Clone_stmts}


{**************************************************}
{ routines for recursively freeing statement trees }
{**************************************************}


procedure Destroy_switch_case(var switch_case_ptr: switch_case_ptr_type;
  free_attributes: boolean);
begin
  if switch_case_ptr <> nil then
    begin
      Destroy_decls(decl_ptr_type(switch_case_ptr^.case_decls_ptr),
        free_attributes);
      Destroy_stmts(switch_case_ptr^.case_stmts_ptr, free_attributes);

      {******************************}
      { add switch case to free list }
      {******************************}
      Free_switch_case(switch_case_ptr);
    end;
end; {procedure Destroy_switch_case}


procedure Destroy_switch_array(var switch_array_ptr: switch_array_ptr_type;
  free_attributes: boolean);
var
  counter: integer;
begin
  if switch_array_ptr <> nil then
    begin
      {*******************}
      { free switch cases }
      {*******************}
      for counter := 1 to switch_array_size do
        Destroy_switch_case(switch_array_ptr^.switch_case_array[counter],
          free_attributes);

      {*******************************}
      { add switch array to free list }
      {*******************************}
      Free_switch_array(switch_array_ptr);
    end;
end; {procedure Destroy_switch_array}


procedure Destroy_case_constant(var case_constant_ptr: case_constant_ptr_type;
  free_attributes: boolean);
begin
  if case_constant_ptr <> nil then
    begin
      Destroy_expr(case_constant_ptr^.case_expr_ptr, free_attributes);

      {********************************}
      { add case constant to free list }
      {********************************}
      Free_case_constant(case_constant_ptr);
    end;
end; {procedure Destroy_case_constant}


procedure Destroy_case_constants(var case_constant_ptr: case_constant_ptr_type;
  free_attributes: boolean);
var
  temp: case_constant_ptr_type;
begin
  while (case_constant_ptr <> nil) do
    begin
      temp := case_constant_ptr;
      case_constant_ptr := case_constant_ptr^.next;
      Destroy_case_constant(temp, free_attributes);
    end;
end; {procedure Destroy_case_constants}


procedure Destroy_stmt_data(var stmt_data_ptr: stmt_data_ptr_type;
  free_attributes: boolean);
begin
  if stmt_data_ptr <> nil then
    begin
      Destroy_stmt(stmt_data_ptr^.shader_stmt_ptr, free_attributes);
      Destroy_stmt(stmt_data_ptr^.edge_shader_stmt_ptr, free_attributes);

      {****************************}
      { add stmt data to free list }
      {****************************}
      Free_stmt_data(stmt_data_ptr);
    end;
end; {procedure Destroy_stmt_data}


procedure Destroy_stmt(var stmt_ptr: stmt_ptr_type;
  free_attributes: boolean);
begin
  if (stmt_ptr <> nil) then
    begin
      {***************************************}
      { free auxilliary statement information }
      {***************************************}
      Free_stmt_info(stmt_ptr^.stmt_info_ptr, free_attributes);

      with stmt_ptr^ do
        case kind of

          {***********************}
          { null or nop statement }
          {***********************}
          null_stmt:
            ;

          {******************************}
          { simple assignment statements }
          {******************************}
          boolean_assign..reference_assign:
            begin
              Destroy_expr(lhs_data_ptr, free_attributes);
              Destroy_expr(rhs_expr_ptr, free_attributes);
            end;

          {*****************************}
          { array assignment statements }
          {*****************************}
          boolean_array_assign..reference_array_assign:
            begin
              Destroy_array_subrange(lhs_array_subrange_ptr, free_attributes);
              Destroy_array_subrange(rhs_array_subrange_ptr, free_attributes);
              Destroy_stmt(array_assign_stmt_ptr, free_attributes);

              {******************************************************}
              { structure array implicit allocation / initialization }
              {******************************************************}
              Destroy_expr(array_struct_new_ptr, free_attributes);
            end;
          subarray_assign:
            begin
              Destroy_array_subrange(lhs_subarray_subrange_ptr,
                free_attributes);
              Destroy_array_subrange(rhs_subarray_subrange_ptr,
                free_attributes);
              Destroy_stmt(subarray_assign_stmt_ptr, free_attributes);
            end;

          {****************************************}
          { array expression assignment statements }
          {****************************************}
          boolean_array_expr_assign..reference_array_expr_assign:
            begin
              Destroy_array_subrange(array_expr_subrange_ptr, free_attributes);
              Destroy_stmt(array_expr_assign_stmt_ptr, free_attributes);

              {******************************************************}
              { structure array implicit allocation / initialization }
              {******************************************************}
              Destroy_expr(array_expr_struct_new_ptr, free_attributes);
            end;
          subarray_expr_assign:
            begin
              Destroy_array_subrange(subarray_expr_subrange_ptr,
                free_attributes);
              Destroy_stmt(subarray_expr_assign_stmt_ptr, free_attributes);
            end;

          {******************************}
          { struct assignment statements }
          {******************************}
          struct_assign:
            begin
              Destroy_expr(lhs_struct_expr_ptr, free_attributes);
              Destroy_expr(rhs_struct_expr_ptr, free_attributes);
            end;
          struct_base_assign:
            begin
              Destroy_expr(lhs_struct_base_ptr, free_attributes);
              Destroy_expr(rhs_struct_base_ptr, free_attributes);
              Destroy_stmts(field_assign_stmts_ptr, free_attributes);
            end;

          {************************}
          { conditional statements }
          {************************}
          if_then_else:
            begin
              Destroy_expr(if_expr_ptr, free_attributes);
              Destroy_decls(decl_ptr_type(then_decls_ptr), free_attributes);
              Destroy_stmts(then_stmts_ptr, free_attributes);
              Destroy_decls(decl_ptr_type(else_decls_ptr), free_attributes);
              Destroy_stmts(else_stmts_ptr, free_attributes);
            end;
          case_char_stmt, case_enum_stmt:
            begin
              Destroy_expr(switch_expr_ptr, free_attributes);
              Destroy_switch_array(switch_array_ptr, free_attributes);
              Destroy_decls(decl_ptr_type(switch_else_decls_ptr),
                free_attributes);
              Destroy_stmts(switch_else_stmts_ptr, free_attributes);
              Destroy_case_constants(switch_case_constant_ptr, free_attributes);
            end;

          {********************}
          { looping statements }
          {********************}
          while_loop:
            begin
              Destroy_expr(while_expr_ptr, free_attributes);
              Destroy_decls(decl_ptr_type(while_decls_ptr), free_attributes);
              Destroy_stmts(while_stmts_ptr, free_attributes);
            end;
          for_loop:
            begin
              Destroy_decl(decl_ptr_type(counter_decl_ptr), free_attributes);
              Destroy_expr(start_expr_ptr, free_attributes);
              Destroy_expr(end_expr_ptr, free_attributes);
              Destroy_decls(decl_ptr_type(for_decls_ptr), free_attributes);
              Destroy_stmts(for_stmts_ptr, free_attributes);
            end;
          for_each:
            begin
              Destroy_decl(decl_ptr_type(each_index_decl_ptr), free_attributes);
              Destroy_expr(each_array_ptr, free_attributes);
              Destroy_decls(decl_ptr_type(each_decls_ptr), free_attributes);
              Destroy_stmts(each_stmts_ptr, free_attributes);
            end;
          for_each_loop:
            begin
              Destroy_array_subrange(for_each_array_subrange_ptr,
                free_attributes);
              Destroy_stmts(loop_stmts_ptr, free_attributes);
            end;
          for_each_list:
            begin
              Destroy_decl(decl_ptr_type(each_struct_decl_ptr),
                free_attributes);
              Destroy_expr(each_next_expr_ptr, free_attributes);
              Destroy_expr(each_list_expr_ptr, free_attributes);
              Destroy_decls(decl_ptr_type(list_decls_ptr), free_attributes);
              Destroy_stmts(list_stmts_ptr, free_attributes);
            end;

          {*************************}
          { flow control statements }
          {*************************}
          break_stmt, continue_stmt, return_stmt, exit_stmt:
            ;
          loop_label_stmt:
            Destroy_stmt(loop_stmt_ptr, free_attributes);
          boolean_answer..reference_answer:
            Destroy_expr(answer_expr_ptr, free_attributes);

          {********************}
          { scoping statements }
          {********************}
          with_stmt:
            begin
              Destroy_expr(with_expr_ptr, free_attributes);
              Destroy_decls(decl_ptr_type(with_decls_ptr), free_attributes);
              Destroy_stmts(with_stmts_ptr, free_attributes);
            end;

          {******************************}
          { memory allocation statements }
          {******************************}
          dim_stmt, redim_stmt:
            begin
              Destroy_expr(dim_data_ptr, free_attributes);
              Destroy_expr(dim_expr_ptr, free_attributes);
            end;
          new_struct_stmt, renew_struct_stmt:
            begin
              Destroy_expr(new_data_ptr, free_attributes);
              Destroy_expr(new_expr_ptr, free_attributes);
            end;

          {********************************}
          { memory deallocation statements }
          {********************************}
          implicit_free_array_stmt, implicit_free_struct_stmt:
            ;
          implicit_free_reference_stmt, implicit_free_params_stmt:
            ;

          {*********************}
          { built in statements }
          {*********************}
          built_in_stmt:
            Destroy_instruct(instruct_ptr, free_attributes);

          {*****************************************}
          { user defined subprogram call statements }
          {*****************************************}
          static_method_stmt, dynamic_method_stmt, interface_method_stmt,
            proto_method_stmt:
            begin
              Destroy_expr(stmt_name_ptr, free_attributes);
              Destroy_stmts(implicit_stmts_ptr, free_attributes);

              Destroy_stmts(param_assign_stmts_ptr, free_attributes);
              Destroy_stmts(param_stmts_ptr, free_attributes);

              Destroy_stmts(return_assign_stmts_ptr, free_attributes);
              Destroy_stmts(return_stmts_ptr, free_attributes);

              Destroy_stmt_data(stmt_data_ptr, free_attributes);
            end;
        end; {case}

      {***********************}
      { add stmt to free list }
      {***********************}
      Free_stmt(stmt_ptr);
    end;
end; {procedure Destroy_stmt}


procedure Destroy_stmts(var stmt_ptr: stmt_ptr_type;
  free_attributes: boolean);
var
  temp: stmt_ptr_type;
begin
  while (stmt_ptr <> nil) do
    begin
      temp := stmt_ptr;
      stmt_ptr := stmt_ptr^.next;
      Destroy_stmt(temp, free_attributes);
    end;
end; {procedure Destroy_stmts}


procedure Destroy_abstract_stmt(var stmt_ptr: forward_stmt_ptr_type;
  free_attributes: boolean);
begin
  Destroy_stmt(stmt_ptr_type(stmt_ptr), free_attributes);
end; {Destroy_abstract_stmt}


{**************************************************}
{ routines for recursively marking statement trees }
{**************************************************}


procedure Mark_switch_case(switch_case_ptr: switch_case_ptr_type;
  touched: boolean);
begin
  if switch_case_ptr <> nil then
    begin
      Mark_decls(decl_ptr_type(switch_case_ptr^.case_decls_ptr), touched);
      Mark_stmts(switch_case_ptr^.case_stmts_ptr, touched);
    end;
end; {procedure Mark_switch_case}


procedure Mark_switch_array(switch_array_ptr: switch_array_ptr_type;
  touched: boolean);
var
  counter: integer;
begin
  if switch_array_ptr <> nil then
    begin
      {*******************}
      { mark switch cases }
      {*******************}
      for counter := 1 to switch_array_size do
        Mark_switch_case(switch_array_ptr^.switch_case_array[counter], touched);
    end;
end; {procedure Mark_switch_array}


procedure Mark_case_constant(case_constant_ptr: case_constant_ptr_type;
  touched: boolean);
begin
  if case_constant_ptr <> nil then
    begin
      Mark_expr(case_constant_ptr^.case_expr_ptr, touched);
    end;
end; {procedure Mark_case_constant}


procedure Mark_case_constants(case_constant_ptr: case_constant_ptr_type;
  touched: boolean);
begin
  while (case_constant_ptr <> nil) do
    begin
      Mark_case_constant(case_constant_ptr, touched);
      case_constant_ptr := case_constant_ptr^.next;
    end;
end; {procedure Mark_case_constants}


procedure Mark_stmt_data(stmt_data_ptr: stmt_data_ptr_type;
  touched: boolean);
begin
  if stmt_data_ptr <> nil then
    begin
      Mark_stmt(stmt_data_ptr^.shader_stmt_ptr, touched);
      Mark_stmt(stmt_data_ptr^.edge_shader_stmt_ptr, touched);
    end;
end; {procedure Mark_stmt_data}


procedure Mark_stmt(stmt_ptr: stmt_ptr_type;
  touched: boolean);
begin
  if (stmt_ptr <> nil) then
    begin
      with stmt_ptr^ do
        case kind of

          {***********************}
          { null or nop statement }
          {***********************}
          null_stmt:
            ;

          {******************************}
          { simple assignment statements }
          {******************************}
          boolean_assign..reference_assign:
            begin
              Mark_expr(lhs_data_ptr, touched);
              Mark_expr(rhs_expr_ptr, touched);
            end;

          {*****************************}
          { array assignment statements }
          {*****************************}
          boolean_array_assign..reference_array_assign:
            begin
              Mark_array_subrange(lhs_array_subrange_ptr, touched);
              Mark_array_subrange(rhs_array_subrange_ptr, touched);
              Mark_stmt(array_assign_stmt_ptr, touched);

              {******************************************************}
              { structure array implicit allocation / initialization }
              {******************************************************}
              Mark_expr(array_struct_new_ptr, touched);

              {************************************************}
              { static structure array implicit initialization }
              {************************************************}
              Mark_type_decl(type_ptr_type(array_static_struct_type_ref),
                touched);
            end;
          subarray_assign:
            begin
              Mark_array_subrange(lhs_subarray_subrange_ptr, touched);
              Mark_array_subrange(rhs_subarray_subrange_ptr, touched);
              Mark_stmt(subarray_assign_stmt_ptr, touched);
            end;

          {****************************************}
          { array expression assignment statements }
          {****************************************}
          boolean_array_expr_assign..reference_array_expr_assign:
            begin
              Mark_array_subrange(array_expr_subrange_ptr, touched);
              Mark_stmt(array_expr_assign_stmt_ptr, touched);

              {******************************************************}
              { structure array implicit allocation / initialization }
              {******************************************************}
              Mark_expr(array_expr_struct_new_ptr, touched);
            end;
          subarray_expr_assign:
            begin
              Mark_array_subrange(subarray_expr_subrange_ptr, touched);
              Mark_stmt(subarray_expr_assign_stmt_ptr, touched);
            end;

          {******************************}
          { struct assignment statements }
          {******************************}
          struct_assign:
            begin
              Mark_expr(lhs_struct_expr_ptr, touched);
              Mark_expr(rhs_struct_expr_ptr, touched);
            end;
          struct_base_assign:
            begin
              Mark_expr(lhs_struct_base_ptr, touched);
              Mark_expr(rhs_struct_base_ptr, touched);
              Mark_stmts(field_assign_stmts_ptr, touched);
            end;

          {************************}
          { conditional statements }
          {************************}
          if_then_else:
            begin
              Mark_expr(if_expr_ptr, touched);
              Mark_decls(decl_ptr_type(then_decls_ptr), touched);
              Mark_stmts(then_stmts_ptr, touched);
              Mark_decls(decl_ptr_type(else_decls_ptr), touched);
              Mark_stmts(else_stmts_ptr, touched);
            end;
          case_char_stmt, case_enum_stmt:
            begin
              Mark_expr(switch_expr_ptr, touched);
              Mark_switch_array(switch_array_ptr, touched);
              Mark_case_constants(switch_case_constant_ptr, touched);
              Mark_decls(decl_ptr_type(switch_else_decls_ptr), touched);
              Mark_stmts(switch_else_stmts_ptr, touched);
              Mark_case_constants(switch_case_constant_ptr, touched);
            end;

          {********************}
          { looping statements }
          {********************}
          while_loop:
            begin
              Mark_expr(while_expr_ptr, touched);
              Mark_decls(decl_ptr_type(while_decls_ptr), touched);
              Mark_stmts(while_stmts_ptr, touched);
            end;
          for_loop:
            begin
              Mark_decl(decl_ptr_type(counter_decl_ptr), touched);
              Mark_expr(start_expr_ptr, touched);
              Mark_expr(end_expr_ptr, touched);
              Mark_decls(decl_ptr_type(for_decls_ptr), touched);
              Mark_stmts(for_stmts_ptr, touched);
            end;
          for_each:
            begin
              Mark_decl(decl_ptr_type(each_index_decl_ptr), touched);
              Mark_expr(each_array_ptr, touched);
              Mark_decls(decl_ptr_type(each_decls_ptr), touched);
              Mark_stmts(each_stmts_ptr, touched);
            end;
          for_each_loop:
            begin
              Mark_array_subrange(for_each_array_subrange_ptr, touched);
              Mark_stmts(loop_stmts_ptr, touched);
            end;
          for_each_list:
            begin
              Mark_decl(decl_ptr_type(each_struct_decl_ptr), touched);
              Mark_expr(each_next_expr_ptr, touched);
              Mark_expr(each_list_expr_ptr, touched);
              Mark_decls(decl_ptr_type(list_decls_ptr), touched);
              Mark_stmts(list_stmts_ptr, touched);
            end;

          {*************************}
          { flow control statements }
          {*************************}
          break_stmt, continue_stmt, return_stmt, exit_stmt:
            ;
          loop_label_stmt:
            Mark_stmt(loop_stmt_ptr, touched);
          boolean_answer..reference_answer:
            Mark_expr(answer_expr_ptr, touched);

          {********************}
          { scoping statements }
          {********************}
          with_stmt:
            begin
              Mark_expr(with_expr_ptr, touched);
              Mark_decls(decl_ptr_type(with_decls_ptr), touched);
              Mark_stmts(with_stmts_ptr, touched);
            end;

          {******************************}
          { memory allocation statements }
          {******************************}
          dim_stmt, redim_stmt:
            begin
              Mark_expr(dim_data_ptr, touched);
              Mark_expr(dim_expr_ptr, touched);
            end;
          new_struct_stmt, renew_struct_stmt:
            begin
              Mark_expr(new_data_ptr, touched);
              Mark_expr(new_expr_ptr, touched);
            end;

          {********************************}
          { memory deallocation statements }
          {********************************}
          implicit_free_array_stmt, implicit_free_struct_stmt:
            ;
          implicit_free_reference_stmt, implicit_free_params_stmt:
            ;

          {*********************}
          { built in statements }
          {*********************}
          built_in_stmt:
            Mark_instruct(instruct_ptr, touched);

          {*****************************************}
          { user defined subprogram call statements }
          {*****************************************}
          static_method_stmt, dynamic_method_stmt, interface_method_stmt,
            proto_method_stmt:
            begin
              Mark_code_decl(code_ptr_type(stmt_code_ref), touched);
              Mark_expr(stmt_name_ptr, touched);
              Mark_stmts(implicit_stmts_ptr, touched);

              Mark_stmts(param_assign_stmts_ptr, touched);
              Mark_stmts(param_stmts_ptr, touched);

              Mark_stmts(return_assign_stmts_ptr, touched);
              Mark_stmts(return_stmts_ptr, touched);

              Mark_stmt_data(stmt_data_ptr, touched);
            end;

        end; {case}
    end;
end; {procedure Mark_stmt}


procedure Mark_stmts(stmt_ptr: stmt_ptr_type;
  touched: boolean);
begin
  while (stmt_ptr <> nil) do
    begin
      Mark_stmt(stmt_ptr, touched);
      stmt_ptr := stmt_ptr^.next;
    end;
end; {procedure Mark_stmts}


{****************************************************}
{ routines for recursively comparing statement trees }
{****************************************************}


function Equal_stmts(stmt_ptr1, stmt_ptr2: stmt_ptr_type): boolean;
begin
  Equal_stmts := stmt_ptr1 = stmt_ptr2;
end; {function Equal_stmts}


function Same_stmts(stmt_ptr1, stmt_ptr2: stmt_ptr_type): boolean;
begin
  Same_stmts := stmt_ptr1 = stmt_ptr2;
end; {function Same_stmts}


end.
