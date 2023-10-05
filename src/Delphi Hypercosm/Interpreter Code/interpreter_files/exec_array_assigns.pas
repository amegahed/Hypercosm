unit exec_array_assigns;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          exec_array_assigns           3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to aid the interpreter    }
{       in executing assignment statements.                     }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  exprs, stmts;


{***********************************************}
{ routines to execute complex array assignments }
{***********************************************}
procedure Exec_array_assign(stmt_ptr: stmt_ptr_type);
procedure Exec_array_expr_assign(stmt_ptr: stmt_ptr_type;
  array_expr_ptr: expr_ptr_type);

{***************************************************}
{ routines to execute complex structure assignments }
{***************************************************}
procedure Exec_struct_base_assign(stmt_ptr: stmt_ptr_type);
procedure Exec_struct_assign(stmt_ptr: stmt_ptr_type);


implementation
uses
  errors, data_types, addr_types, arrays, instructs, decls, type_decls,
  code_decls, data, handles, memrefs, op_stacks, get_heap_data, set_heap_data,
  get_data, set_data, store_operands, eval_addrs, eval_arrays, eval_structs,
  eval_references, eval_new_arrays, eval_subranges, exec_structs,
  exec_instructs, exec_stmts, exec_methods, interpreter;


const
  debug = false;


  {*********************************************}
  { routines for interpreting array assignments }
  {*********************************************}


procedure Exec_subarray_assign(lhs_array_subrange_ptr, rhs_array_subrange_ptr:
  array_subrange_ptr_type;
  assign_stmt_ptr: stmt_ptr_type);
var
  lhs_array_bounds_ptr, rhs_array_bounds_ptr: array_bounds_ptr_type;
  lhs_array_index_ptr, rhs_array_index_ptr: array_index_ptr_type;
  lhs_min, lhs_max, lhs_num, rhs_min, rhs_max, rhs_num: integer;
  counter: integer;
begin
  {*********************************}
  { lookup precomputed array bounds }
  {*********************************}
  lhs_array_bounds_ptr := lhs_array_subrange_ptr^.array_bounds_ref;
  rhs_array_bounds_ptr := rhs_array_subrange_ptr^.array_bounds_ref;

  {************************}
  { find lhs subrange size }
  {************************}
  lhs_min := lhs_array_bounds_ptr^.min_val;
  lhs_max := lhs_array_bounds_ptr^.max_val;
  lhs_num := lhs_max - lhs_min + 1;

  {************************}
  { find rhs subrange size }
  {************************}
  rhs_min := rhs_array_bounds_ptr^.min_val;
  rhs_max := rhs_array_bounds_ptr^.max_val;
  rhs_num := rhs_max - rhs_min + 1;

  if debug then
    begin
      writeln('lhs min, max = ', lhs_min: 1, ', ', lhs_max: 1);
      writeln('rhs min, max = ', rhs_min: 1, ', ', rhs_max: 1);
    end;

  {***********************}
  { loop through elements }
  {***********************}
  if lhs_num = rhs_num then
    begin
      lhs_array_index_ptr := lhs_array_bounds_ptr^.array_index_ref;
      rhs_array_index_ptr := rhs_array_bounds_ptr^.array_index_ref;

      lhs_array_index_ptr^.index_val := lhs_min;
      rhs_array_index_ptr^.index_val := rhs_min;

      for counter := 1 to lhs_num do
        begin
          if debug then
            begin
              writeln('lhs_index = ', lhs_array_index_ptr^.index_val: 1);
              writeln('rhs_index = ', rhs_array_index_ptr^.index_val: 1);
            end;

          {***********************}
          { assign array elements }
          {***********************}
          if assign_stmt_ptr^.kind <> subarray_assign then
            Interpret_stmt(assign_stmt_ptr)

            {**************************}
            { assign subarray elements }
            {**************************}
          else
            with assign_stmt_ptr^ do
              begin
                {**************************************************}
                { the first subrange of each dimension is already  }
                { evaluated in order to find if we can perform the }
                { assignment or to dimension the left hand side    }
                { array to match the right hand side array.        }
                {**************************************************}
                if counter <> 1 then
                  begin
                    Eval_subarray_subrange(lhs_subarray_subrange_ptr);
                    Eval_subarray_subrange(rhs_subarray_subrange_ptr);
                  end;

                Exec_subarray_assign(lhs_subarray_subrange_ptr,
                  rhs_subarray_subrange_ptr, subarray_assign_stmt_ptr);

                {*********************************}
                { free temporary subrange handles }
                {*********************************}
                Free_array_value_subrange_handle(lhs_subarray_subrange_ptr);
                Free_array_value_subrange_handle(rhs_subarray_subrange_ptr);
              end;

          lhs_array_index_ptr^.index_val := lhs_array_index_ptr^.index_val + 1;
          rhs_array_index_ptr^.index_val := rhs_array_index_ptr^.index_val + 1;
        end;
    end
  else
    begin
      write('can not assign an array[', rhs_min: 1, '..', rhs_max: 1, ']');
      writeln(' to an array[', lhs_min: 1, '..', lhs_max: 1, '].');
      Runtime_error('Can not assign arrays of differing sizes.');
    end;
end; {procedure Exec_subarray_assign}


{*************************************************}
{ routines to evaluate array assignment subranges }
{*************************************************}


procedure Eval_subarray_assign_subranges(stmt_ptr: stmt_ptr_type);
begin
  while (stmt_ptr^.kind = subarray_assign) do
    begin
      Eval_array_subrange(stmt_ptr^.lhs_subarray_subrange_ptr);
      Eval_array_value_subrange(stmt_ptr^.rhs_subarray_subrange_ptr);
      stmt_ptr := stmt_ptr^.subarray_assign_stmt_ptr;
    end;
end; {procedure Eval_subarray_assign_subranges}


procedure Eval_array_assign_subranges(stmt_ptr: stmt_ptr_type);
begin
  Eval_array_subrange(stmt_ptr^.lhs_array_subrange_ptr);
  Eval_array_value_subrange(stmt_ptr^.rhs_array_subrange_ptr);
  Eval_subarray_assign_subranges(stmt_ptr^.array_assign_stmt_ptr);
end; {procedure Eval_array_assign_subranges}


{****************************************************}
{ routines to free array assignment subrange handles }
{****************************************************}


procedure Free_subarray_assign_subranges(stmt_ptr: stmt_ptr_type);
begin
  while (stmt_ptr^.kind = subarray_assign) do
    begin
      Free_array_subrange_handle(stmt_ptr^.lhs_subarray_subrange_ptr);
      Free_array_value_subrange_handle(stmt_ptr^.rhs_subarray_subrange_ptr);
      stmt_ptr := stmt_ptr^.subarray_assign_stmt_ptr;
    end;
end; {procedure Free_subarray_assign_subranges}


procedure Free_array_assign_subranges(stmt_ptr: stmt_ptr_type);
begin
  Free_array_subrange_handle(stmt_ptr^.lhs_array_subrange_ptr);
  Free_array_value_subrange_handle(stmt_ptr^.rhs_array_subrange_ptr);
  Free_subarray_assign_subranges(stmt_ptr^.array_assign_stmt_ptr);
end; {procedure Eval_array_assign_subranges}


{*************************************************}
{ routines to transfer array assignment subranges }
{*************************************************}


procedure Transfer_subarray_assign_bounds(stmt_ptr: stmt_ptr_type);
var
  lhs_array_bounds_ptr, rhs_array_bounds_ptr: array_bounds_ptr_type;
begin
  while (stmt_ptr^.kind = subarray_assign) do
    begin
      lhs_array_bounds_ptr :=
        stmt_ptr^.lhs_subarray_subrange_ptr^.array_bounds_ref;
      rhs_array_bounds_ptr :=
        stmt_ptr^.rhs_subarray_subrange_ptr^.array_bounds_ref;
      Transfer_array_bounds(lhs_array_bounds_ptr, rhs_array_bounds_ptr);
      stmt_ptr := stmt_ptr^.subarray_assign_stmt_ptr;
    end;
end; {procedure Transfer_subarray_assign_bounds}


procedure Transfer_array_assign_bounds(stmt_ptr: stmt_ptr_type);
var
  lhs_array_bounds_ptr, rhs_array_bounds_ptr: array_bounds_ptr_type;
begin
  lhs_array_bounds_ptr := stmt_ptr^.lhs_array_subrange_ptr^.array_bounds_ref;
  rhs_array_bounds_ptr := stmt_ptr^.rhs_array_subrange_ptr^.array_bounds_ref;
  Transfer_array_bounds(lhs_array_bounds_ptr, rhs_array_bounds_ptr);
  Transfer_subarray_assign_bounds(stmt_ptr^.array_assign_stmt_ptr);
end; {procedure Transfer_array_assign_bounds}


procedure Eval_implicit_array_assign_dim(stmt_ptr: stmt_ptr_type;
  array_bounds_list_ptr: array_bounds_list_ptr_type);
begin
  with stmt_ptr^ do
    case kind of

      {****************************************}
      { enumerated array assignment statements }
      {****************************************}
      boolean_array_assign:
        Eval_new_boolean_array(array_bounds_list_ptr);
      char_array_assign:
        Eval_new_char_array(array_bounds_list_ptr);

      {*************************************}
      { integer array assignment statements }
      {*************************************}
      byte_array_assign:
        Eval_new_byte_array(array_bounds_list_ptr);
      short_array_assign:
        Eval_new_short_array(array_bounds_list_ptr);
      integer_array_assign:
        Eval_new_integer_array(array_bounds_list_ptr);
      long_array_assign:
        Eval_new_long_array(array_bounds_list_ptr);

      {************************************}
      { scalar array assignment statements }
      {************************************}
      scalar_array_assign:
        Eval_new_scalar_array(array_bounds_list_ptr);
      double_array_assign:
        Eval_new_double_array(array_bounds_list_ptr);
      complex_array_assign:
        Eval_new_complex_array(array_bounds_list_ptr);
      vector_array_assign:
        Eval_new_vector_array(array_bounds_list_ptr);

      {***************************************}
      { reference array assignment statements }
      {***************************************}
      array_array_assign:
        Eval_new_array_array(array_bounds_list_ptr, nil);
      struct_array_assign:
        Eval_new_struct_array(array_bounds_list_ptr,
          expr_ptr_type(array_struct_new_ptr));
      static_struct_array_assign:
        Eval_new_static_struct_array(array_bounds_list_ptr,
          type_ptr_type(array_static_struct_type_ref), nil);
      proto_array_assign:
        Eval_new_code_array(array_bounds_list_ptr);
      reference_array_assign:
        Eval_new_reference_array(array_bounds_list_ptr);

    end; {case}
end; {procedure Eval_implicit_array_assign_dim}


procedure Exec_array_assign(stmt_ptr: stmt_ptr_type);
var
  handle: handle_type;
  addr: addr_type;
begin
  with stmt_ptr^ do
    begin
      {**************************}
      { evaluate array subranges }
      {**************************}
      Eval_array_assign_subranges(stmt_ptr);

      {*********************}
      { dimension nil array }
      {*********************}
      if expr_ref_type(lhs_array_subrange_ptr^.array_base_ref)^.array_base_handle
        = 0 then
        begin
          {*******************************************************}
          { number of dimensions to evaluate is determined by lhs }
          {*******************************************************}
          Transfer_array_assign_bounds(stmt_ptr);

          {******************}
          { create new array }
          {******************}
          Eval_implicit_array_assign_dim(stmt_ptr,
            array_assign_bounds_list_ref);
          handle := Pop_handle_operand;

          {**************************************}
          { assign new array to lhs array handle }
          {**************************************}
          addr :=
            expr_ref_type(lhs_array_subrange_ptr^.array_base_ref)^.array_base_addr;
          Set_addr_handle(addr, handle);
          expr_ref_type(lhs_array_subrange_ptr^.array_base_ref)^.array_base_handle := handle;
        end;

      {***********************}
      { assign array elements }
      {***********************}
      Exec_subarray_assign(lhs_array_subrange_ptr, rhs_array_subrange_ptr,
        array_assign_stmt_ptr);

      {*********************************}
      { free array assignment subranges }
      {*********************************}
      Free_array_assign_subranges(stmt_ptr);
    end;
end; {procedure Exec_array_assign}


{********************************************************}
{ routines for interpreting array expression assignments }
{********************************************************}


procedure Exec_subarray_expr_assign(lhs_array_subrange_ptr:
  array_subrange_ptr_type;
  rhs_array_bounds_ptr: array_bounds_ptr_type;
  rhs_element_exprs_ptr: expr_ptr_type;
  element_expr_ptr: expr_ptr_type;
  assign_stmt_ptr: stmt_ptr_type);
var
  array_subrange_ptr: array_subrange_ptr_type;
  lhs_array_bounds_ptr, array_bounds_ptr: array_bounds_ptr_type;
  lhs_array_index_ptr: array_index_ptr_type;
  lhs_min, lhs_max, lhs_num, rhs_min, rhs_max, rhs_num: integer;
  expr_ptr: expr_ptr_type;
  stmt_ptr: stmt_ptr_type;
  counter: integer;
begin
  {*********************************}
  { lookup precomputed array bounds }
  {*********************************}
  lhs_array_bounds_ptr := lhs_array_subrange_ptr^.array_bounds_ref;

  {************************}
  { find lhs subrange size }
  {************************}
  lhs_min := lhs_array_bounds_ptr^.min_val;
  lhs_max := lhs_array_bounds_ptr^.max_val;
  lhs_num := lhs_max - lhs_min + 1;

  {************************}
  { find rhs subrange size }
  {************************}
  rhs_min := rhs_array_bounds_ptr^.min_val;
  rhs_max := rhs_array_bounds_ptr^.max_val;
  rhs_num := rhs_max - rhs_min + 1;

  if debug then
    begin
      writeln('lhs min, max = ', lhs_min: 1, ', ', lhs_max: 1);
      writeln('rhs min, max = ', rhs_min: 1, ', ', rhs_max: 1);
    end;

  {***********************}
  { loop through elements }
  {***********************}
  if lhs_num = rhs_num then
    begin
      lhs_array_index_ptr := lhs_array_bounds_ptr^.array_index_ref;
      lhs_array_index_ptr^.index_val := lhs_min;

      for counter := 1 to lhs_num do
        begin
          if debug then
            writeln('lhs_index = ', lhs_array_index_ptr^.index_val: 1);

          {*************************************}
          { assign subarray expression elements }
          {*************************************}
          if assign_stmt_ptr^.kind = subarray_expr_assign then
            begin
              array_subrange_ptr := assign_stmt_ptr^.subarray_expr_subrange_ptr;
              array_bounds_ptr := rhs_element_exprs_ptr^.array_expr_bounds_ref;
              expr_ptr := rhs_element_exprs_ptr^.subarray_element_exprs_ptr;
              stmt_ptr := assign_stmt_ptr^.subarray_expr_assign_stmt_ptr;
              element_expr_ptr := assign_stmt_ptr^.subarray_expr_element_ref;
              Exec_subarray_expr_assign(array_subrange_ptr, array_bounds_ptr,
                expr_ptr, element_expr_ptr, stmt_ptr);
            end

              {**********************************}
              { assign array expression elements }
              {**********************************}
          else if assign_stmt_ptr^.kind in array_expr_assign_stmt_set then
            Exec_array_expr_assign(assign_stmt_ptr, rhs_element_exprs_ptr)

            {***************************}
            { assign primitive elements }
            {***************************}
          else
            begin
              element_expr_ptr^.element_expr_ref := rhs_element_exprs_ptr;
              Interpret_stmt(assign_stmt_ptr);
            end;

          lhs_array_index_ptr^.index_val := lhs_array_index_ptr^.index_val + 1;
          rhs_element_exprs_ptr := rhs_element_exprs_ptr^.next;
        end;

    end
  else
    begin
      write('can not assign an array[', rhs_min: 1, '..', rhs_max: 1, ']');
      writeln(' to an array[', lhs_min: 1, '..', lhs_max: 1, '].');
      Runtime_error('Can not assign arrays of differing sizes.');
    end;
end; {procedure Exec_subarray_expr_assign}


procedure Eval_subarray_expr_assign_subranges(stmt_ptr: stmt_ptr_type);
begin
  while (stmt_ptr^.kind = subarray_expr_assign) do
    begin
      Eval_array_subrange(stmt_ptr^.subarray_expr_subrange_ptr);
      stmt_ptr := stmt_ptr^.subarray_expr_assign_stmt_ptr;
    end;
end; {procedure Eval_subarray_expr_assign_subranges}


procedure Eval_array_expr_assign_subranges(stmt_ptr: stmt_ptr_type);
begin
  Eval_array_subrange(stmt_ptr^.array_expr_subrange_ptr);
  Eval_subarray_expr_assign_subranges(stmt_ptr^.array_expr_assign_stmt_ptr);
end; {procedure Eval_array_expr_assign_subranges}


procedure Transfer_subarray_expr_assign_bounds(stmt_ptr: stmt_ptr_type;
  rhs_array_bounds_ptr: array_bounds_ptr_type);
var
  lhs_array_bounds_ptr: array_bounds_ptr_type;
begin
  while (stmt_ptr^.kind = subarray_expr_assign) do
    begin
      lhs_array_bounds_ptr :=
        stmt_ptr^.subarray_expr_subrange_ptr^.array_bounds_ref;
      Transfer_array_bounds(lhs_array_bounds_ptr, rhs_array_bounds_ptr);
      stmt_ptr := stmt_ptr^.subarray_expr_assign_stmt_ptr;
      rhs_array_bounds_ptr := rhs_array_bounds_ptr^.next;
    end;
end; {procedure Transfer_subarray_expr_assign_bounds}


procedure Transfer_array_expr_assign_bounds(stmt_ptr: stmt_ptr_type;
  array_expr_ptr: expr_ptr_type);
var
  lhs_array_bounds_ptr, rhs_array_bounds_ptr: array_bounds_ptr_type;
begin
  lhs_array_bounds_ptr := stmt_ptr^.array_expr_subrange_ptr^.array_bounds_ref;
  rhs_array_bounds_ptr := array_expr_ptr^.array_expr_bounds_list_ptr^.first;
  Transfer_array_bounds(lhs_array_bounds_ptr, rhs_array_bounds_ptr);
  Transfer_subarray_expr_assign_bounds(stmt_ptr^.array_expr_assign_stmt_ptr,
    rhs_array_bounds_ptr^.next);
end; {procedure Transfer_array_expr_assign_bounds}


procedure Eval_implicit_array_expr_assign_dim(stmt_ptr: stmt_ptr_type;
  array_bounds_list_ptr: array_bounds_list_ptr_type);
begin
  with stmt_ptr^ do
    case kind of

      {***************************************************}
      { enumerated array expression assignment statements }
      {***************************************************}
      boolean_array_expr_assign:
        Eval_new_boolean_array(array_bounds_list_ptr);
      char_array_expr_assign:
        Eval_new_char_array(array_bounds_list_ptr);

      {************************************************}
      { integer array expression assignment statements }
      {************************************************}
      byte_array_expr_assign:
        Eval_new_byte_array(array_bounds_list_ptr);
      short_array_expr_assign:
        Eval_new_short_array(array_bounds_list_ptr);
      integer_array_expr_assign:
        Eval_new_integer_array(array_bounds_list_ptr);
      long_array_expr_assign:
        Eval_new_long_array(array_bounds_list_ptr);

      {***********************************************}
      { scalar array expression assignment statements }
      {***********************************************}
      scalar_array_expr_assign:
        Eval_new_scalar_array(array_bounds_list_ptr);
      double_array_expr_assign:
        Eval_new_double_array(array_bounds_list_ptr);
      complex_array_expr_assign:
        Eval_new_complex_array(array_bounds_list_ptr);
      vector_array_expr_assign:
        Eval_new_vector_array(array_bounds_list_ptr);

      {**************************************************}
      { reference array expression assignment statements }
      {**************************************************}
      array_array_expr_assign:
        Eval_new_array_array(array_bounds_list_ptr, nil);
      struct_array_expr_assign:
        Eval_new_struct_array(array_bounds_list_ptr,
          expr_ptr_type(array_expr_struct_new_ptr));
      static_struct_array_expr_assign:
        Eval_new_static_struct_array(array_bounds_list_ptr,
          type_ptr_type(array_expr_static_struct_type_ref), nil);
      proto_array_expr_assign:
        Eval_new_code_array(array_bounds_list_ptr);
      reference_array_expr_assign:
        Eval_new_reference_array(array_bounds_list_ptr);

    end; {case}
end; {procedure Eval_implicit_array_expr_assign_dim}


procedure Exec_array_expr_assign(stmt_ptr: stmt_ptr_type;
  array_expr_ptr: expr_ptr_type);
var
  exprs_ptr: expr_ptr_type;
  array_bounds_ptr: array_bounds_ptr_type;
  addr: addr_type;
  handle: handle_type;
begin
  with stmt_ptr^ do
    begin
      {*******************************}
      { evaluate array expr subranges }
      {*******************************}
      Eval_array_expr_assign_subranges(stmt_ptr);

      {*********************}
      { dimension nil array }
      {*********************}
      if
        expr_ref_type(array_expr_subrange_ptr^.array_base_ref)^.array_base_handle
        = 0 then
        begin
          {*******************************************************}
          { number of dimensions to evaluate is determined by lhs }
          {*******************************************************}
          Transfer_array_expr_assign_bounds(stmt_ptr, array_expr_ptr);

          {******************}
          { create new array }
          {******************}
          Eval_implicit_array_expr_assign_dim(stmt_ptr,
            array_expr_bounds_list_ref);
          handle := Pop_handle_operand;

          {**************************************}
          { assign new array to lhs array handle }
          {**************************************}
          addr :=
            expr_ref_type(array_expr_subrange_ptr^.array_base_ref)^.array_base_addr;
          Set_addr_handle(addr, handle);
          expr_ref_type(array_expr_subrange_ptr^.array_base_ref)^.array_base_handle := handle;
        end;

      exprs_ptr := array_expr_ptr^.array_element_exprs_ptr;
      array_bounds_ptr := array_expr_ptr^.array_expr_bounds_list_ptr^.first;
      Exec_subarray_expr_assign(array_expr_subrange_ptr, array_bounds_ptr,
        exprs_ptr, array_expr_element_ref, array_expr_assign_stmt_ptr);
    end;
end; {procedure Exec_array_expr_assign}


{***************************************************}
{ routines to execute complex structure assignments }
{***************************************************}


procedure Exec_struct_base_assign(stmt_ptr: stmt_ptr_type);
begin
  with stmt_ptr^ do
    begin
      if parent_base_assign_ref <> nil then
        begin
          with lhs_struct_base_ptr^ do
            case kind of
              struct_base:
                parent_base_assign_ref^.lhs_struct_base_ptr^.struct_base_memref
                  := struct_base_memref;
              static_struct_base:
                parent_base_assign_ref^.lhs_struct_base_ptr^.static_struct_base_addr := static_struct_base_addr;
            end;

          with rhs_struct_base_ptr^ do
            case kind of
              struct_base:
                parent_base_assign_ref^.rhs_struct_base_ptr^.struct_base_memref
                  := struct_base_memref;
              static_struct_base:
                parent_base_assign_ref^.rhs_struct_base_ptr^.static_struct_base_addr := static_struct_base_addr;
            end;

          Interpret_stmt(parent_base_assign_ref);
        end;

      Interpret_stmts(field_assign_stmts_ptr);
    end;
end; {procedure Exec_struct_base_assign}


procedure Exec_struct_assign(stmt_ptr: stmt_ptr_type);
var
  struct_base_assign_ref: stmt_ptr_type;
begin
  with stmt_ptr^ do
    begin
      struct_base_assign_ref :=
        Get_type_copier(type_ptr_type(assign_struct_type_ref));

      {*****************************}
      { create temporary references }
      {*****************************}
      Eval_addr(lhs_struct_expr_ptr);
      with struct_base_assign_ref^.lhs_struct_base_ptr^ do
        case kind of
          struct_base:
            struct_base_memref := Get_addr_memref(Pop_addr_operand);
          static_struct_base:
            static_struct_base_addr := Pop_addr_operand;
        end;
      with struct_base_assign_ref^.rhs_struct_base_ptr^ do
        case kind of
          struct_base:
            begin
              Eval_struct(rhs_struct_expr_ptr);
              struct_base_memref := Pop_memref_operand;
            end;
          static_struct_base:
            begin
              Eval_addr(rhs_struct_expr_ptr);
              static_struct_base_addr := Pop_addr_operand;
            end;
        end;

      {***************}
      { assign fields }
      {***************}
      Interpret_stmt(struct_base_assign_ref);

      {***************************}
      { free temporary references }
      {***************************}
      with struct_base_assign_ref^.lhs_struct_base_ptr^ do
        case kind of
          struct_base:
            Free_memref(struct_base_memref);
          static_struct_base:
            Free_addr(static_struct_base_addr);
        end;
      with struct_base_assign_ref^.rhs_struct_base_ptr^ do
        case kind of
          struct_base:
            Free_memref(struct_base_memref);
          static_struct_base:
            Free_addr(static_struct_base_addr);
        end;
    end;
end; {procedure Exec_struct_assign}


end.
