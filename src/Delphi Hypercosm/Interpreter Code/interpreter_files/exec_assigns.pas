unit exec_assigns;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            exec_assigns               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to aid the interpreter    }
{       in executing primitive assignment statements.           }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  exprs;


{********************************************}
{ routines to execute enumerated assignments }
{********************************************}
procedure Exec_boolean_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
procedure Exec_char_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);

{*****************************************}
{ routines to execute integer assignments }
{*****************************************}
procedure Exec_byte_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
procedure Exec_short_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
procedure Exec_integer_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
procedure Exec_long_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);

{****************************************}
{ routines to execute scalar assignments }
{****************************************}
procedure Exec_scalar_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
procedure Exec_double_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
procedure Exec_complex_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
procedure Exec_vector_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);

{*******************************************}
{ routines to execute reference assignments }
{*******************************************}
procedure Exec_array_ptr_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
procedure Exec_struct_ptr_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
procedure Exec_proto_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type;
  static_level: integer);
procedure Exec_reference_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);


implementation
uses
  addr_types, code_decls, data, op_stacks, set_data, store_operands, eval_addrs,
  eval_booleans, eval_chars, eval_integers, eval_scalars, eval_arrays,
  eval_structs, eval_references, interpreter;


{********************************************}
{ routines to execute enumerated assignments }
{********************************************}


procedure Exec_boolean_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
begin
  Eval_addr(lhs_data_ptr);
  Eval_boolean(rhs_expr_ptr);
  Store_boolean_operand;
end; {procedure Exec_boolean_assign}


procedure Exec_char_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
begin
  Eval_addr(lhs_data_ptr);
  Eval_char(rhs_expr_ptr);
  Store_char_operand;
end; {procedure Exec_char_assign}


{*****************************************}
{ routines to execute integer assignments }
{*****************************************}


procedure Exec_byte_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
begin
  Eval_addr(lhs_data_ptr);
  Eval_byte(rhs_expr_ptr);
  Store_byte_operand;
end; {procedure Exec_byte_assign}


procedure Exec_short_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
begin
  Eval_addr(lhs_data_ptr);
  Eval_short(rhs_expr_ptr);
  Store_short_operand;
end; {procedure Exec_short_assign}


procedure Exec_integer_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
begin
  Eval_addr(lhs_data_ptr);
  Eval_integer(rhs_expr_ptr);
  Store_integer_operand;
end; {procedure Exec_integer_assign}


procedure Exec_long_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
begin
  Eval_addr(lhs_data_ptr);
  Eval_long(rhs_expr_ptr);
  Store_long_operand;
end; {procedure Exec_long_assign}


{****************************************}
{ routines to execute scalar assignments }
{****************************************}


procedure Exec_scalar_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
begin
  Eval_addr(lhs_data_ptr);
  Eval_scalar(rhs_expr_ptr);
  Store_scalar_operand;
end; {procedure Exec_scalar_assign}


procedure Exec_double_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
begin
  Eval_addr(lhs_data_ptr);
  Eval_double(rhs_expr_ptr);
  Store_double_operand;
end; {procedure Exec_double_assign}


procedure Exec_complex_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
begin
  Eval_addr(lhs_data_ptr);
  Eval_complex(rhs_expr_ptr);
  Store_complex_operand;
end; {procedure Exec_complex_assign}


procedure Exec_vector_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
begin
  Eval_addr(lhs_data_ptr);
  Eval_vector(rhs_expr_ptr);
  Store_vector_operand;
end; {procedure Exec_vector_assign}


{*******************************************}
{ routines to execute reference assignments }
{*******************************************}


procedure Exec_array_ptr_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
begin
  Eval_addr(lhs_data_ptr);
  Eval_array(rhs_expr_ptr);
  Store_handle_operand;
end; {procedure Exec_array_ptr_assign}


procedure Exec_struct_ptr_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
begin
  Eval_addr(lhs_data_ptr);
  Eval_struct(rhs_expr_ptr);
  Store_memref_operand;
end; {procedure Exec_struct_ptr_assign}


procedure Exec_proto_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type;
  static_level: integer);
var
  addr: addr_type;
  code_ptr: code_ptr_type;
  static_link: stack_index_type;
begin
  Eval_addr(lhs_data_ptr);
  addr := Pop_addr_operand;

  Eval_proto(rhs_expr_ptr);
  static_link := Pop_stack_index_operand;
  code_ptr := code_ptr_type(Pop_code_operand);

  if code_ptr <> nil then
    if (static_level < code_ptr^.decl_static_level) then
      Runtime_error('Can not assign a subprogram to an outer scope.');

  Set_addr_code(addr, abstract_code_ptr_type(code_ptr));
  Set_addr_stack_index(Get_offset_addr(addr, 1), static_link);
end; {procedure Exec_proto_assign}


procedure Exec_reference_assign(lhs_data_ptr, rhs_expr_ptr: expr_ptr_type);
begin
  Eval_addr(lhs_data_ptr);
  Eval_reference(rhs_expr_ptr);
  Store_addr_operand;
end; {procedure Exec_reference_assign}


end.
