unit store_operands;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           store_operands              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       These routines are used in conjunction with the         }
{       stack and heap modules to more easily access the        }
{       runtime system's data.                                  }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface


{***************************************}
{ routines to store enumerated operands }
{***************************************}
procedure Store_boolean_operand;
procedure Store_char_operand;

{************************************}
{ routines to store integer operands }
{************************************}
procedure Store_byte_operand;
procedure Store_short_operand;
procedure Store_integer_operand;
procedure Store_long_operand;

{***********************************}
{ routines to store scalar operands }
{***********************************}
procedure Store_scalar_operand;
procedure Store_double_operand;

{*************************************}
{ routines to store compound operands }
{*************************************}
procedure Store_complex_operand;
procedure Store_vector_operand;

{**************************************}
{ routines to store reference operands }
{**************************************}
procedure Store_handle_operand;
procedure Store_memref_operand;
procedure Store_code_operand;
procedure Store_proto_operand;
procedure Store_addr_operand;


implementation
uses
  complex_numbers, vectors, data_types, addr_types, data, handles, memrefs,
  op_stacks, set_data, get_data;


{***************************************}
{ routines to store enumerated operands }
{***************************************}


procedure Store_boolean_operand;
var
  boolean_val: boolean_type;
  addr: addr_type;
begin
  boolean_val := Pop_boolean_operand;
  addr := Pop_addr_operand;
  Set_addr_boolean(addr, boolean_val);
  Free_addr(addr);
end; {procedure Store_boolean_operand}


procedure Store_char_operand;
var
  char_val: char_type;
  addr: addr_type;
begin
  char_val := Pop_char_operand;
  addr := Pop_addr_operand;
  Set_addr_char(addr, char_val);
  Free_addr(addr);
end; {procedure Store_char_operand}


{************************************}
{ routines to store integer operands }
{************************************}


procedure Store_byte_operand;
var
  byte_val: byte_type;
  addr: addr_type;
begin
  byte_val := Pop_byte_operand;
  addr := Pop_addr_operand;
  Set_addr_byte(addr, byte_val);
  Free_addr(addr);
end; {procedure Store_byte_operand}


procedure Store_short_operand;
var
  short_val: short_type;
  addr: addr_type;
begin
  short_val := Pop_short_operand;
  addr := Pop_addr_operand;
  Set_addr_short(addr, short_val);
  Free_addr(addr);
end; {procedure Store_short_operand}


procedure Store_integer_operand;
var
  integer_val: integer_type;
  addr: addr_type;
begin
  integer_val := Pop_integer_operand;
  addr := Pop_addr_operand;
  Set_addr_integer(addr, integer_val);
  Free_addr(addr);
end; {procedure Store_integer_operand}


procedure Store_long_operand;
var
  long_val: long_type;
  addr: addr_type;
begin
  long_val := Pop_long_operand;
  addr := Pop_addr_operand;
  Set_addr_long(addr, long_val);
  Free_addr(addr);
end; {procedure Store_long_operand}


{***********************************}
{ routines to store scalar operands }
{***********************************}


procedure Store_scalar_operand;
var
  scalar_val: scalar_type;
  addr: addr_type;
begin
  scalar_val := Pop_scalar_operand;
  addr := Pop_addr_operand;
  Set_addr_scalar(addr, scalar_val);
  Free_addr(addr);
end; {procedure Store_scalar_operand}


procedure Store_double_operand;
var
  double_val: double_type;
  addr: addr_type;
begin
  double_val := Pop_double_operand;
  addr := Pop_addr_operand;
  Set_addr_double(addr, double_val);
  Free_addr(addr);
end; {procedure Store_double_operand}


{*************************************}
{ routines to store compound operands }
{*************************************}


procedure Store_complex_operand;
var
  complex_val: complex_type;
  addr: addr_type;
begin
  complex_val := Pop_complex_operand;
  addr := Pop_addr_operand;
  Set_addr_complex(addr, complex_val);
  Free_addr(addr);
end; {procedure Store_complex_operand}


procedure Store_vector_operand;
var
  vector_val: vector_type;
  addr: addr_type;
begin
  vector_val := Pop_vector_operand;
  addr := Pop_addr_operand;
  Set_addr_vector(addr, vector_val);
  Free_addr(addr);
end; {procedure Store_vector_operand}


{**************************************}
{ routines to store reference operands }
{**************************************}


procedure Store_handle_operand;
var
  handle, previous_handle: handle_type;
  addr: addr_type;
begin
  handle := Pop_handle_operand;
  addr := Pop_addr_operand;

  {**********************}
  { free previous handle }
  {**********************}
  previous_handle := Get_addr_handle(addr);
  if previous_handle <> 0 then
    Free_handle(previous_handle);

  Set_addr_handle(addr, handle);
  Free_addr(addr);
end; {procedure Store_handle_operand}


procedure Store_memref_operand;
var
  memref, previous_memref: memref_type;
  addr: addr_type;
begin
  memref := Pop_memref_operand;
  addr := Pop_addr_operand;

  {**********************}
  { free previous memref }
  {**********************}
  previous_memref := Get_addr_memref(addr);
  if previous_memref <> 0 then
    Free_memref(previous_memref);

  Set_addr_memref(addr, memref);
  Free_addr(addr);
end; {procedure Store_memref_operand}


procedure Store_code_operand;
var
  code_ptr: abstract_code_ptr_type;
  addr: addr_type;
begin
  code_ptr := Pop_code_operand;
  addr := Pop_addr_operand;
  Set_addr_code(addr, code_ptr);
  Free_addr(addr);
end; {procedure Store_code_operand}


procedure Store_proto_operand;
var
  stack_index: stack_index_type;
  code_ptr: abstract_code_ptr_type;
  addr: addr_type;
begin
  stack_index := Pop_stack_index_operand;
  code_ptr := Pop_code_operand;
  addr := Pop_addr_operand;
  Set_addr_code(addr, code_ptr);
  Set_addr_stack_index(Get_offset_addr(addr, 1), stack_index);
  Free_addr(addr);
end; {procedure Store_proto_operand}


procedure Store_addr_operand;
var
  addr_val: addr_type;
  addr: addr_type;
begin
  addr_val := Pop_addr_operand;
  addr := Pop_addr_operand;
  Set_addr_addr(addr, addr_val);
  Free_addr(addr);
end; {procedure Store_addr_operand}


end.
