unit eval_expr_arrays;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           eval_expr_arrays            3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module controls the way that arrays are            }
{       handled by the interpreter. It is responsible           }
{       for the layout of the array structures on the           }
{       run-time stack.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  addr_types, arrays, exprs;


{*********************************}
{ new primitive enumerated arrays }
{*********************************}
procedure Eval_boolean_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
procedure Eval_char_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);

{*******************************}
{ new primitive integral arrays }
{*******************************}
procedure Eval_byte_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
procedure Eval_short_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
procedure Eval_integer_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
procedure Eval_long_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);

{*****************************}
{ new primitive scalar arrays }
{*****************************}
procedure Eval_scalar_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
procedure Eval_double_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);

{*******************************}
{ new primitive compound arrays }
{*******************************}
procedure Eval_complex_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
procedure Eval_vector_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);

{********************************}
{ new primitive reference arrays }
{********************************}
procedure Eval_array_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
procedure Eval_struct_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
procedure Eval_static_struct_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
procedure Eval_code_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
procedure Eval_reference_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);


implementation
uses
  heaps, op_stacks, get_heap_data, set_heap_data, eval_new_arrays, set_elements;


{*********************************}
{ new primitive enumerated arrays }
{*********************************}


procedure Eval_boolean_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
var
  handle: handle_type;
  index: heap_index_type;
begin
  handle := New_array(array_bounds_list_ptr, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  index := array_bounds_list_ptr^.dimensions * 3 + 1;
  Set_boolean_elements(element_expr_ptr, handle, index);
end; {procedure Eval_boolean_expr_array}


procedure Eval_char_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
var
  handle: handle_type;
  index: heap_index_type;
begin
  handle := New_array(array_bounds_list_ptr, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  index := array_bounds_list_ptr^.dimensions * 3 + 1;
  Set_char_elements(element_expr_ptr, handle, index);
end; {procedure Eval_char_expr_array}


{*******************************}
{ new primitive integral arrays }
{*******************************}


procedure Eval_byte_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
var
  handle: handle_type;
  index: heap_index_type;
begin
  handle := New_array(array_bounds_list_ptr, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  index := array_bounds_list_ptr^.dimensions * 3 + 1;
  Set_byte_elements(element_expr_ptr, handle, index);
end; {procedure Eval_byte_expr_array}


procedure Eval_short_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
var
  handle: handle_type;
  index: heap_index_type;
begin
  handle := New_array(array_bounds_list_ptr, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  index := array_bounds_list_ptr^.dimensions * 3 + 1;
  Set_short_elements(element_expr_ptr, handle, index);
end; {procedure Eval_short_expr_array}


procedure Eval_integer_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
var
  handle: handle_type;
  index: heap_index_type;
begin
  handle := New_array(array_bounds_list_ptr, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  index := array_bounds_list_ptr^.dimensions * 3 + 1;
  Set_integer_elements(element_expr_ptr, handle, index);
end; {procedure Eval_integer_expr_array}


procedure Eval_long_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
var
  handle: handle_type;
  index: heap_index_type;
begin
  handle := New_array(array_bounds_list_ptr, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  index := array_bounds_list_ptr^.dimensions * 3 + 1;
  Set_long_elements(element_expr_ptr, handle, index);
end; {procedure Eval_long_expr_array}


{*****************************}
{ new primitive scalar arrays }
{*****************************}


procedure Eval_scalar_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
var
  handle: handle_type;
  index: heap_index_type;
begin
  handle := New_array(array_bounds_list_ptr, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  index := array_bounds_list_ptr^.dimensions * 3 + 1;
  Set_scalar_elements(element_expr_ptr, handle, index);
end; {procedure Eval_scalar_expr_array}


procedure Eval_double_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
var
  handle: handle_type;
  index: heap_index_type;
begin
  handle := New_array(array_bounds_list_ptr, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  index := array_bounds_list_ptr^.dimensions * 3 + 1;
  Set_double_elements(element_expr_ptr, handle, index);
end; {procedure Eval_double_expr_array}


{*******************************}
{ new primitive compound arrays }
{*******************************}


procedure Eval_complex_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
var
  handle: handle_type;
  index: heap_index_type;
begin
  handle := New_array(array_bounds_list_ptr, 2);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  index := array_bounds_list_ptr^.dimensions * 3 + 1;
  Set_complex_elements(element_expr_ptr, handle, index);
end; {procedure Eval_complex_expr_array}


procedure Eval_vector_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
var
  handle: handle_type;
  index: heap_index_type;
begin
  handle := New_array(array_bounds_list_ptr, 3);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  index := array_bounds_list_ptr^.dimensions * 3 + 1;
  Set_vector_elements(element_expr_ptr, handle, index);
end; {procedure Eval_vector_expr_array}


{********************************}
{ new primitive reference arrays }
{********************************}


procedure Eval_array_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
var
  handle: handle_type;
  index: heap_index_type;
begin
  handle := New_array(array_bounds_list_ptr, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  index := array_bounds_list_ptr^.dimensions * 3 + 1;
  Set_array_elements(element_expr_ptr, handle, index);
end; {procedure Eval_array_expr_array}


procedure Eval_struct_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
var
  handle: handle_type;
  index: heap_index_type;
begin
  handle := New_array(array_bounds_list_ptr, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  index := array_bounds_list_ptr^.dimensions * 3 + 1;
  Set_struct_elements(element_expr_ptr, handle, index);
end; {procedure Eval_struct_expr_array}


procedure Eval_static_struct_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
var
  handle: handle_type;
  index: heap_index_type;
begin
  handle := New_array(array_bounds_list_ptr, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  index := array_bounds_list_ptr^.dimensions * 3 + 1;
  Set_static_struct_elements(element_expr_ptr, handle, index);
end; {procedure Eval_static_struct_expr_array}


procedure Eval_code_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
var
  handle: handle_type;
  index: heap_index_type;
begin
  handle := New_array(array_bounds_list_ptr, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  index := array_bounds_list_ptr^.dimensions * 3 + 1;
  Set_code_elements(element_expr_ptr, handle, index);
end; {procedure Eval_code_expr_array}


procedure Eval_reference_expr_array(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  element_expr_ptr: expr_ptr_type);
var
  handle: handle_type;
  index: heap_index_type;
begin
  handle := New_array(array_bounds_list_ptr, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  index := array_bounds_list_ptr^.dimensions * 3 + 1;
  Set_reference_elements(element_expr_ptr, handle, index);
end; {procedure Eval_reference_expr_array}


end.
