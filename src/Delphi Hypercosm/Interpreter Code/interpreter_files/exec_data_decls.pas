unit exec_data_decls;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           exec_data_decls             3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module controls how the interpreter creates        }
{       and initializes its data.                               }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  addr_types, decls;


{*****************************************************}
{ routines for interpreting general data declarations }
{*****************************************************}
procedure Interpret_data_decl(decl_ptr: decl_ptr_type);


implementation
uses
  chars, strings, complex_numbers, vectors, exprs, code_decls, type_decls, data,
  stacks, op_stacks, set_data, eval_addrs, eval_arrays, eval_structs,
  exec_structs, exec_stmts, exec_native;


const
  autoinit = false;


  {*************************************************************}
  { routines for interpreting primitive enumerated declarations }
  {*************************************************************}


procedure Exec_boolean_decl(data_decl: data_decl_type);
var
  addr: addr_type;
begin
  with data_decl do
    begin
      Eval_addr(data_expr_ptr);
      addr := Pop_addr_operand;

      {****************************}
      { set value to uninitialized }
      {****************************}
      if autoinit then
        Set_addr_boolean(addr, false)
      else
        Set_addr_error(addr);

      {***********************}
      { interpret initializer }
      {***********************}
      if init_stmt_ptr <> nil then
        Interpret_stmt(init_stmt_ptr);

      {**************************}
      { native data declarations }
      {**************************}
      if native then
        Set_native_data_index(native_index, Addr_to_stack_index(addr));

      Free_addr(addr);
    end;
end; {procedure Exec_boolean_decl}


procedure Exec_char_decl(data_decl: data_decl_type);
var
  addr: addr_type;
begin
  with data_decl do
    begin
      Eval_addr(data_expr_ptr);
      addr := Pop_addr_operand;

      {****************************}
      { set value to uninitialized }
      {****************************}
      if autoinit then
        Set_addr_char(addr, space)
      else
        Set_addr_error(addr);

      {***********************}
      { interpret initializer }
      {***********************}
      if init_stmt_ptr <> nil then
        Interpret_stmt(init_stmt_ptr);

      {**************************}
      { native data declarations }
      {**************************}
      if native then
        Set_native_data_index(native_index, Addr_to_stack_index(addr));

      Free_addr(addr);
    end;
end; {procedure Exec_char_decl}


{*********************************}
{ primitive integral declarations }
{*********************************}


procedure Exec_byte_decl(data_decl: data_decl_type);
var
  addr: addr_type;
begin
  with data_decl do
    begin
      Eval_addr(data_expr_ptr);
      addr := Pop_addr_operand;

      {****************************}
      { set value to uninitialized }
      {****************************}
      if autoinit then
        Set_addr_byte(addr, 0)
      else
        Set_addr_error(addr);

      {***********************}
      { interpret initializer }
      {***********************}
      if init_stmt_ptr <> nil then
        Interpret_stmt(init_stmt_ptr);

      {**************************}
      { native data declarations }
      {**************************}
      if native then
        Set_native_data_index(native_index, Addr_to_stack_index(addr));

      Free_addr(addr);
    end;
end; {procedure Exec_byte_decl}


procedure Exec_short_decl(data_decl: data_decl_type);
var
  addr: addr_type;
begin
  with data_decl do
    begin
      Eval_addr(data_expr_ptr);
      addr := Pop_addr_operand;

      {****************************}
      { set value to uninitialized }
      {****************************}
      if autoinit then
        Set_addr_short(addr, 0)
      else
        Set_addr_error(addr);

      {***********************}
      { interpret initializer }
      {***********************}
      if init_stmt_ptr <> nil then
        Interpret_stmt(init_stmt_ptr);

      {**************************}
      { native data declarations }
      {**************************}
      if native then
        Set_native_data_index(native_index, Addr_to_stack_index(addr));

      Free_addr(addr);
    end;
end; {procedure Exec_short_decl}


procedure Exec_integer_decl(data_decl: data_decl_type);
var
  addr: addr_type;
begin
  with data_decl do
    begin
      Eval_addr(data_expr_ptr);
      addr := Pop_addr_operand;

      {****************************}
      { set value to uninitialized }
      {****************************}
      if autoinit then
        Set_addr_integer(addr, 0)
      else
        Set_addr_error(addr);

      {***********************}
      { interpret initializer }
      {***********************}
      if init_stmt_ptr <> nil then
        Interpret_stmt(init_stmt_ptr);

      {**************************}
      { native data declarations }
      {**************************}
      if native then
        Set_native_data_index(native_index, Addr_to_stack_index(addr));

      Free_addr(addr);
    end;
end; {procedure Exec_integer_decl}


procedure Exec_long_decl(data_decl: data_decl_type);
var
  addr: addr_type;
begin
  with data_decl do
    begin
      Eval_addr(data_expr_ptr);
      addr := Pop_addr_operand;

      {****************************}
      { set value to uninitialized }
      {****************************}
      if autoinit then
        Set_addr_long(addr, 0)
      else
        Set_addr_error(addr);

      {***********************}
      { interpret initializer }
      {***********************}
      if init_stmt_ptr <> nil then
        Interpret_stmt(init_stmt_ptr);

      {**************************}
      { native data declarations }
      {**************************}
      if native then
        Set_native_data_index(native_index, Addr_to_stack_index(addr));

      Free_addr(addr);
    end;
end; {procedure Exec_long_decl}


{*******************************}
{ primitive scalar declarations }
{*******************************}


procedure Exec_scalar_decl(data_decl: data_decl_type);
var
  addr: addr_type;
begin
  with data_decl do
    begin
      Eval_addr(data_expr_ptr);
      addr := Pop_addr_operand;

      {****************************}
      { set value to uninitialized }
      {****************************}
      if autoinit then
        Set_addr_scalar(addr, 0)
      else
        Set_addr_error(addr);

      {***********************}
      { interpret initializer }
      {***********************}
      if init_stmt_ptr <> nil then
        Interpret_stmt(init_stmt_ptr);

      {**************************}
      { native data declarations }
      {**************************}
      if native then
        Set_native_data_index(native_index, Addr_to_stack_index(addr));

      Free_addr(addr);
    end;
end; {procedure Exec_scalar_decl}


procedure Exec_double_decl(data_decl: data_decl_type);
var
  addr: addr_type;
begin
  with data_decl do
    begin
      Eval_addr(data_expr_ptr);
      addr := Pop_addr_operand;

      {****************************}
      { set value to uninitialized }
      {****************************}
      if autoinit then
        Set_addr_double(addr, 0)
      else
        Set_addr_error(addr);

      {***********************}
      { interpret initializer }
      {***********************}
      if init_stmt_ptr <> nil then
        Interpret_stmt(init_stmt_ptr);

      {**************************}
      { native data declarations }
      {**************************}
      if native then
        Set_native_data_index(native_index, Addr_to_stack_index(addr));

      Free_addr(addr);
    end;
end; {procedure Exec_double_decl}


procedure Exec_complex_decl(data_decl: data_decl_type);
var
  addr: addr_type;
begin
  with data_decl do
    begin
      Eval_addr(data_expr_ptr);
      addr := Pop_addr_operand;

      {****************************}
      { set value to uninitialized }
      {****************************}
      if autoinit then
        Set_addr_complex(addr, To_complex(0, 0))
      else
        Set_addr_error(addr);

      {***********************}
      { interpret initializer }
      {***********************}
      if init_stmt_ptr <> nil then
        Interpret_stmt(init_stmt_ptr);

      {**************************}
      { native data declarations }
      {**************************}
      if native then
        Set_native_data_index(native_index, Addr_to_stack_index(addr));

      Free_addr(addr);
    end;
end; {procedure Exec_complex_decl}


procedure Exec_vector_decl(data_decl: data_decl_type);
var
  addr: addr_type;
begin
  with data_decl do
    begin
      Eval_addr(data_expr_ptr);
      addr := Pop_addr_operand;

      {****************************}
      { set value to uninitialized }
      {****************************}
      if autoinit then
        Set_addr_vector(addr, zero_vector)
      else
        Set_addr_error(addr);

      {***********************}
      { interpret initializer }
      {***********************}
      if init_stmt_ptr <> nil then
        Interpret_stmt(init_stmt_ptr);

      {**************************}
      { native data declarations }
      {**************************}
      if native then
        Set_native_data_index(native_index, Addr_to_stack_index(addr));

      Free_addr(addr);
    end;
end; {procedure Exec_vector_decl}


{*******************************************}
{ array, struct, and reference declarations }
{*******************************************}


procedure Exec_array_decl(data_decl: data_decl_type);
var
  addr: addr_type;
begin
  with data_decl do
    begin
      Eval_addr(data_expr_ptr);
      addr := Pop_addr_operand;

      if init_expr_ptr <> nil then
        begin
          {********************************}
          { dimension new array and assign }
          {********************************}
          Eval_array(init_expr_ptr);
          Set_addr_handle(addr, Pop_handle_operand);
        end
      else
        begin
          {**************************}
          { set array pointer to nil }
          {**************************}
          Set_addr_handle(addr, 0);
        end;

      {***********************}
      { interpret initializer }
      {***********************}
      if init_stmt_ptr <> nil then
        begin
          addr_cache := addr;
          Interpret_stmt(init_stmt_ptr);
        end;

      {**************************}
      { native data declarations }
      {**************************}
      if native then
        Set_native_data_index(native_index, Addr_to_stack_index(addr));

      Free_addr(addr);
    end;
end; {procedure Exec_array_decl}


procedure Exec_struct_decl(data_decl: data_decl_type);
var
  addr: addr_type;
begin
  with data_decl do
    begin
      Eval_addr(data_expr_ptr);
      addr := Pop_addr_operand;

      if init_expr_ptr <> nil then
        begin
          {********************************}
          { allocate new struct and assign }
          {********************************}
          Eval_struct(init_expr_ptr);
          Set_addr_memref(addr, Pop_memref_operand);
        end
      else
        begin
          {***************************}
          { set struct pointer to nil }
          {***************************}
          Set_addr_memref(addr, 0);
        end;

      {***********************}
      { interpret initializer }
      {***********************}
      if init_stmt_ptr <> nil then
        begin
          addr_cache := addr;
          Interpret_stmt(init_stmt_ptr);
        end;

      {**************************}
      { native data declarations }
      {**************************}
      if native then
        Set_native_data_index(native_index, Addr_to_stack_index(addr));

      Free_addr(addr);
    end;
end; {procedure Exec_struct_decl}


procedure Exec_static_struct_decl(data_decl: data_decl_type;
  type_ptr: type_ptr_type);
var
  addr: addr_type;
begin
  with data_decl do
    begin
      Eval_addr(data_expr_ptr);
      addr := Pop_addr_operand;

      {*******************************}
      { interpret default initializer }
      {*******************************}
      Init_static_struct_fields(addr, type_ptr);

      {***********************}
      { interpret initializer }
      {***********************}
      if init_stmt_ptr <> nil then
        begin
          addr_cache := addr;
          Interpret_stmt(init_stmt_ptr);
        end;

      {**************************}
      { native data declarations }
      {**************************}
      if native then
        Set_native_data_index(native_index, Addr_to_stack_index(addr));

      Free_addr(addr);
    end;
end; {procedure Exec_static_struct_decl}


procedure Exec_reference_decl(data_decl: data_decl_type);
var
  addr: addr_type;
begin
  with data_decl do
    begin
      Eval_addr(data_expr_ptr);
      addr := Pop_addr_operand;

      {**********************}
      { set reference to nil }
      {**********************}
      Set_addr_stack_index(addr, 0);

      {***********************}
      { interpret initializer }
      {***********************}
      if init_stmt_ptr <> nil then
        Interpret_stmt(init_stmt_ptr);

      {**************************}
      { native data declarations }
      {**************************}
      if native then
        Set_native_data_index(native_index, Addr_to_stack_index(addr));

      Free_addr(addr);
    end;
end; {procedure Exec_reference_decl}


{***********************************************}
{ user defined type and subprogram declarations }
{***********************************************}


procedure Exec_code_decl(data_decl: data_decl_type;
  code_ptr: code_ptr_type);
var
  addr: addr_type;
begin
  with data_decl do
    begin
      Eval_addr(data_expr_ptr);
      addr := Pop_addr_operand;

      with code_ptr^ do
        if (decl_kind <> proto_decl) then
          begin
            {********************************}
            { put actual decl ptr onto stack }
            {********************************}
            decl_static_link := Get_static_link;
            Set_addr_code(addr, abstract_code_ptr_type(code_ptr));
            Set_addr_stack_index(Get_offset_addr(addr, 1), decl_static_link);
          end
        else
          begin
            {***********************************}
            { put nil proto decl ptr onto stack }
            {***********************************}
            decl_static_link := 0;
            Set_addr_code(addr, nil);
            Set_addr_stack_index(Get_offset_addr(addr, 1), decl_static_link);
          end;

      {***********************}
      { interpret initializer }
      {***********************}
      if init_stmt_ptr <> nil then
        Interpret_stmt(init_stmt_ptr);

      Free_addr(addr);
    end;
end; {procedure Exec_code_decl}


{*****************************************************}
{ routines for interpreting general data declarations }
{*****************************************************}


procedure Interpret_data_decl(decl_ptr: decl_ptr_type);
begin
  with decl_ptr^ do
    case kind of

      {***********************************}
      { primitive enumerated declarations }
      {***********************************}
      boolean_decl:
        Exec_boolean_decl(data_decl);
      char_decl:
        Exec_char_decl(data_decl);

      {*********************************}
      { primitive integral declarations }
      {*********************************}
      byte_decl:
        Exec_byte_decl(data_decl);
      short_decl:
        Exec_short_decl(data_decl);
      integer_decl:
        Exec_integer_decl(data_decl);
      long_decl:
        Exec_long_decl(data_decl);

      {*******************************}
      { primitive scalar declarations }
      {*******************************}
      scalar_decl:
        Exec_scalar_decl(data_decl);
      double_decl:
        Exec_double_decl(data_decl);
      complex_decl:
        Exec_complex_decl(data_decl);
      vector_decl:
        Exec_vector_decl(data_decl);

      {*******************************************}
      { array, struct, and reference declarations }
      {*******************************************}
      array_decl:
        Exec_array_decl(data_decl);
      struct_decl:
        Exec_struct_decl(data_decl);
      static_struct_decl:
        Exec_static_struct_decl(data_decl,
          type_ptr_type(static_struct_type_ref));
      reference_decl:
        Exec_reference_decl(data_decl);

      {**************************************}
      { user defined subprogram declarations }
      {**************************************}
      code_decl:
        Exec_code_decl(code_data_decl, code_ptr_type(code_ptr));
      code_reference_decl:
        Exec_reference_decl(code_data_decl);

    end; {case}
end; {procedure Interpret_data_decl}


end.
