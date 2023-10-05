unit eval_row_arrays;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           eval_row_arrays             3d       }
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
  complex_numbers, vectors, addr_types, exprs, stmts, type_decls;


{*********************************}
{ new primitive enumerated arrays }
{*********************************}
procedure Eval_new_boolean_row_array(min, max: integer);
procedure Eval_new_char_row_array(min, max: integer);

{*******************************}
{ new primitive integral arrays }
{*******************************}
procedure Eval_new_byte_row_array(min, max: integer);
procedure Eval_new_short_row_array(min, max: integer);
procedure Eval_new_integer_row_array(min, max: integer);
procedure Eval_new_long_row_array(min, max: integer);

{*****************************}
{ new primitive scalar arrays }
{*****************************}
procedure Eval_new_scalar_row_array(min, max: integer);
procedure Eval_new_double_row_array(min, max: integer);

{*******************************}
{ new primitive compound arrays }
{*******************************}
procedure Eval_new_complex_row_array(min, max: integer);
procedure Eval_new_vector_row_array(min, max: integer);

{********************************}
{ new primitive reference arrays }
{********************************}
procedure Eval_new_array_row_array(min, max: integer;
  array_element_expr_ptr: expr_ptr_type);
procedure Eval_new_struct_row_array(min, max: integer;
  struct_new_expr_ptr: expr_ptr_type);
procedure Eval_new_static_struct_row_array(min, max: integer;
  static_struct_type_ptr: type_ptr_type;
  init_stmt_ptr: stmt_ptr_type);
procedure Eval_new_code_row_array(min, max: integer);
procedure Eval_new_reference_row_array(min, max: integer);


implementation
uses
  handles, op_stacks, get_heap_data, set_heap_data, eval_arrays, eval_structs,
  exec_structs, exec_stmts, interpreter;


{*******************************************************}
{                  array memory layout                  }
{*******************************************************}
{                                                       }
{                         heap:                         }
{                                                       }
{               |-----------------------|               }
{               |           .           |               }
{               |           .           |               }
{               |           .           |               }
{               |-----------------------|               }
{               |       array data      |               }
{               |-----------------------|               }
{               |       dope vector     |<---\          }
{               |-----------------------|    |          }
{                                            |          }
{                         stack:             |          }
{                                            |          }
{  end of  -->  |-----------------------|    |          }
{  static data  |       integer 5       |    |          }
{               |-----------------------|    |          }
{               |         array         |----/          }
{               |-----------------------|               }
{               |       scalar 3.14     |               }
{               |-----------------------|               }
{               |           .           |               }
{               |           .           |               }
{               |     local variables   |               }
{               |-----------------------|               }
{                                                       }
{*******************************************************}
{               dope vector organization:               }
{*******************************************************}
{                                                       }
{               |-----------------------|               }
{               |  max of dimension 1   |               }
{               |-----------------------|               }
{               |  min of dimension 1   |               }
{               |-----------------------|               }
{               |     multiplier 2      |               }
{               |-----------------------|               }
{               |  max of dimension 2   |               }
{               |-----------------------|               }
{               |  min of dimension 2   |               }
{               |-----------------------|               }
{                           .                           }
{                           .                           }
{                           .                           }
{               |-----------------------|               }
{               |     multiplier 3      |               }
{               |-----------------------|               }
{               |  max of dimension 3   |               }
{               |-----------------------|               }
{               |  min of dimension 3   |               }
{               |-----------------------|               }
{       addr->  |  addr of array data   |               }
{               |-----------------------|               }
{                                                       }
{*******************************************************}
{       For example, to find the data pointed to by     }
{                    a[index2][index1]:                 }
{                                                       }
{       1) find the dope vector pointed to by a         }
{       2) check the array indices against the          }
{          min and max for each dimension.              }
{       3) dope_vector_size = dimensions * 3            }
{       4) correct stack address = data_addr +          }
{          (element_size * index)                       }
{       5) index = (index1 - min1) +                    }
{          (index2 - min2) * multiplier2) + ...         }
{          (indexN - minN) * multiplierN)               }
{       6) addr of multiplierN = (addr + (N - 1) * 3)   }
{*******************************************************}


const
  autoinit = false;
  verbose = false;


procedure Init_row_array_dope_vector(handle: handle_type;
  min, max: integer);
var
  dope_vector_size: heap_index_type;
  index: heap_index_type;
begin
  {************************}
  { create new dope vector }
  {************************}
  dope_vector_size := 3;
  index := dope_vector_size;

  {************************}
  { set addr of array data }
  {************************}
  Set_handle_heap_index(handle, 1, dope_vector_size + 1);

  {***************************************}
  { set array mins, maxes and multipliers }
  {***************************************}
  Set_handle_heap_index(handle, index, max);
  Set_handle_heap_index(handle, index - 1, min);
end; {procedure Init_row_array_dope_vector}


function New_row_array(min, max: integer;
  element_size: integer): handle_type;
var
  array_data_size, dope_vector_size: heap_index_type;
  handle: handle_type;
begin
  if verbose then
    begin
      write('Allocating row array ', min: 1, ' .. ', max: 1);
      writeln;
    end;

  array_data_size := (max - min + 1) * element_size;
  if array_data_size > 0 then
    begin
      dope_vector_size := 3;
      handle := New_handle(array_data_size + dope_vector_size);
      Init_row_array_dope_vector(handle, min, max);
    end
  else
    begin
      Runtime_error('Invalid array bounds.');
      handle := 0;
    end;

  New_row_array := handle;
end; {function New_row_array}


{*********************************}
{ new primitive enumerated arrays }
{*********************************}


procedure Eval_new_boolean_row_array(min, max: integer);
var
  handle: handle_type;
  // index, start, size: heap_index_type;
begin
  handle := New_row_array(min, max, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  {
  if autoinit and (handle <> 0) then
    begin
      start := 4;
      size := max - min + 1;

      for index := start to start + size - 1 do
        Set_handle_boolean(handle, index, false);
    end;
  }
end; {procedure Eval_new_boolean_row_array}


procedure Eval_new_char_row_array(min, max: integer);
var
  handle: handle_type;
  // index, start, size: heap_index_type;
begin
  handle := New_row_array(min, max, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  {
  if autoinit and (handle <> 0) then
    begin
      start := 4;
      size := max - min + 1;

      for index := start to start + size - 1 do
        Set_handle_char(handle, index, ' ');
    end;
  }
end; {procedure Eval_new_char_row_array}


{*******************************}
{ new primitive integral arrays }
{*******************************}


procedure Eval_new_byte_row_array(min, max: integer);
var
  handle: handle_type;
  // index, start, size: heap_index_type;
begin
  handle := New_row_array(min, max, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  {
  if autoinit and (handle <> 0) then
    begin
      start := 4;
      size := max - min + 1;

      for index := start to start + size - 1 do
        Set_handle_byte(handle, index, 0);
    end;
  }
end; {procedure Eval_new_byte_row_array}


procedure Eval_new_short_row_array(min, max: integer);
var
  handle: handle_type;
  // index, start, size: heap_index_type;
begin
  handle := New_row_array(min, max, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  {
  if autoinit and (handle <> 0) then
    begin
      start := 4;
      size := max - min + 1;

      for index := start to start + size - 1 do
        Set_handle_short(handle, index, 0);
    end;
  }
end; {procedure Eval_new_short_row_array}


procedure Eval_new_integer_row_array(min, max: integer);
var
  handle: handle_type;
  // index, start, size: heap_index_type;
begin
  handle := New_row_array(min, max, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  {
  if autoinit and (handle <> 0) then
    begin
      start := 4;
      size := max - min + 1;

      for index := start to start + size - 1 do
        Set_handle_integer(handle, index, 0);
    end;
  }
end; {procedure Eval_new_integer_row_array}


procedure Eval_new_long_row_array(min, max: integer);
var
  handle: handle_type;
  // index, start, size: heap_index_type;
begin
  handle := New_row_array(min, max, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  {
  if autoinit and (handle <> 0) then
    begin
      start := 4;
      size := max - min + 1;

      for index := start to start + size - 1 do
        Set_handle_long(handle, index, 0);
    end;
  }
end; {procedure Eval_new_long_row_array}


{*****************************}
{ new primitive scalar arrays }
{*****************************}


procedure Eval_new_scalar_row_array(min, max: integer);
var
  handle: handle_type;
  // index, start, size: heap_index_type;
begin
  handle := New_row_array(min, max, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  {
  if autoinit and (handle <> 0) then
    begin
      start := 4;
      size := max - min + 1;

      for index := start to start + size - 1 do
        Set_handle_scalar(handle, index, 0);
    end;
  }
end; {procedure Eval_new_scalar_row_array}


procedure Eval_new_double_row_array(min, max: integer);
var
  handle: handle_type;
  // index, start, size: heap_index_type;
begin
  handle := New_row_array(min, max, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  {
  if autoinit and (handle <> 0) then
    begin
      start := 4;
      size := max - min + 1;

      for index := start to start + size - 1 do
        Set_handle_double(handle, index, 0);
    end;
  }
end; {procedure Eval_new_double_row_array}


{*******************************}
{ new primitive compound arrays }
{*******************************}


procedure Eval_new_complex_row_array(min, max: integer);
var
  handle: handle_type;
  // index, counter, size: heap_index_type;
begin
  handle := New_row_array(min, max, 2);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  {
  if autoinit and (handle <> 0) then
    begin
      index := 4;
      size := max - min + 1;

      for counter := 1 to size do
        begin
          Set_handle_complex(handle, index, To_complex(0, 0));
          index := index + 2;
        end;
    end;
  }
end; {procedure Eval_new_complex_row_array}


procedure Eval_new_vector_row_array(min, max: integer);
var
  handle: handle_type;
  // index, counter, size: heap_index_type;
begin
  handle := New_row_array(min, max, 3);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  {
  if autoinit and (handle <> 0) then
    begin
      index := 4;
      size := max - min + 1;

      for counter := 1 to size do
        begin
          Set_handle_vector(handle, index, zero_vector);
          index := index + 3;
        end;
    end;
  }
end; {procedure Eval_new_vector_row_array}


{********************************}
{ new primitive reference arrays }
{********************************}


procedure Eval_new_array_row_array(min, max: integer;
  array_element_expr_ptr: expr_ptr_type);
var
  handle: handle_type;
  index, start, size: heap_index_type;
begin
  handle := New_row_array(min, max, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  if (handle <> 0) then
    begin
      start := 4;
      size := max - min + 1;

      if array_element_expr_ptr <> nil then
        for index := start to start + size - 1 do
          begin
            Eval_array(array_element_expr_ptr);
            Set_handle_handle(handle, index, Pop_handle_operand);
          end
      else
        for index := start to start + size - 1 do
          Set_handle_handle(handle, index, 0);
    end;
end; {procedure Eval_new_array_row_array}


procedure Eval_new_struct_row_array(min, max: integer;
  struct_new_expr_ptr: expr_ptr_type);
var
  handle: handle_type;
  index, start, size: heap_index_type;
begin
  handle := New_row_array(min, max, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  if (handle <> 0) then
    begin
      start := 4;
      size := max - min + 1;

      if struct_new_expr_ptr <> nil then
        for index := start to start + size - 1 do
          begin
            Eval_struct(struct_new_expr_ptr);
            Set_handle_memref(handle, index, Pop_memref_operand);
          end
      else
        for index := start to start + size - 1 do
          Set_handle_memref(handle, index, 0);
    end;
end; {procedure Eval_new_struct_row_array}


procedure Eval_new_static_struct_row_array(min, max: integer;
  static_struct_type_ptr: type_ptr_type;
  init_stmt_ptr: stmt_ptr_type);
var
  handle: handle_type;
  index, counter, size: heap_index_type;
begin
  handle := New_row_array(min, max, static_struct_type_ptr^.size);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  if (handle <> 0) then
    begin
      index := 4;
      size := max - min + 1;

      for counter := 1 to size do
        begin
          Init_static_struct_fields(Handle_addr_to_addr(handle, index),
            static_struct_type_ptr);

          {***********************}
          { interpret initializer }
          {***********************}
          if init_stmt_ptr <> nil then
            Interpret_stmt(init_stmt_ptr);

          index := index + static_struct_type_ptr^.size;
        end;
    end;
end; {procedure Eval_new_static_struct_row_array}


procedure Eval_new_code_row_array(min, max: integer);
var
  handle: handle_type;
  index, counter, size: heap_index_type;
begin
  handle := New_row_array(min, max, 2);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  if (handle <> 0) then
    begin
      index := 4;
      size := max - min + 1;

      for counter := 1 to size do
        begin
          Set_handle_code(handle, index, nil);
          Set_handle_stack_index(handle, index + 1, 0);
          index := index + 2;
        end;
    end;
end; {function New_code_row_array}


procedure Eval_new_reference_row_array(min, max: integer);
var
  handle: handle_type;
  index, start, size: heap_index_type;
begin
  handle := New_row_array(min, max, 1);
  Push_handle_operand(handle);

  {***************************}
  { initialize array elements }
  {***************************}
  if (handle <> 0) then
    begin
      start := 4;
      size := max - min + 1;

      for index := start to start + size - 1 do
        Set_handle_stack_index(handle, index, 0);
    end;
end; {procedure Eval_new_reference_row_array}


end.
