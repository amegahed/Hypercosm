unit exec_native_conversion;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm       exec_native_conversion          3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines for executing native      }
{       conversion methods.                                     }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  native_conversion;


{*****************************************************************}
{ routine to switch between and execute native conversion methods }
{*****************************************************************}
procedure Exec_native_conversion_method(kind:
  native_conversion_method_kind_type);


implementation
uses
  vectors, data_types, addr_types, get_params, op_stacks, eval_row_arrays,
  deref_arrays, set_heap_data, get_heap_data, data_packer;


type
  byte_ptr_type = ^byte_type;


procedure Eval_byte_array(byte_ptr: byte_ptr_type;
  byte_buffer_size: integer);
var
  handle: handle_type;
  heap_index: heap_index_type;
  index: integer;
begin
  {*******************************}
  { create new row array of bytes }
  {*******************************}
  Eval_new_boolean_row_array(1, byte_buffer_size);
  handle := Peek_handle_operand;

  for index := 1 to byte_buffer_size do
    begin
      heap_index := Deref_row_array(handle, index, 1);
      Set_handle_byte(handle, heap_index, byte_ptr^);
      byte_ptr := byte_ptr_type(longint(byte_ptr) + sizeof(byte_type));
    end;
end; {procedure Eval_byte_array}


{*************************************************}
{ routines for converting primitive types to data }
{*************************************************}


procedure Eval_boolean_to_data;
var
  param_index: stack_index_type;
  boolean_value: boolean_type;
  boolean_bytes: boolean_bytes_type;
  endian: endian_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  boolean_value := Get_boolean_param(param_index);
  endian := endian_type(Get_integer_param(param_index));

  {**************************}
  { convert boolean to bytes }
  {**************************}
  boolean_bytes := Pack_boolean_to_bytes(boolean_value, endian);

  {************************************}
  { push byte array onto operand stack }
  {************************************}
  Eval_byte_array(byte_ptr_type(@boolean_bytes), boolean_byte_size);
end; {procedure Eval_boolean_to_data}


procedure Eval_char_to_data;
var
  param_index: stack_index_type;
  char_value: char_type;
  char_bytes: char_bytes_type;
  endian: endian_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  char_value := Get_char_param(param_index);
  endian := endian_type(Get_integer_param(param_index));

  {***********************}
  { convert char to bytes }
  {***********************}
  char_bytes := Pack_char_to_bytes(char_value, endian);

  {************************************}
  { push byte array onto operand stack }
  {************************************}
  Eval_byte_array(byte_ptr_type(@char_bytes), char_byte_size);
end; {procedure Eval_char_to_data}


procedure Eval_byte_to_data;
var
  param_index: stack_index_type;
  byte_value: byte_type;
  byte_bytes: byte_bytes_type;
  endian: endian_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  byte_value := Get_byte_param(param_index);
  endian := endian_type(Get_integer_param(param_index));

  {***********************}
  { convert byte to bytes }
  {***********************}
  byte_bytes := Pack_byte_to_bytes(byte_value, endian);

  {************************************}
  { push byte array onto operand stack }
  {************************************}
  Eval_byte_array(byte_ptr_type(@byte_bytes), byte_byte_size);
end; {procedure Eval_byte_to_data}


procedure Eval_short_to_data;
var
  param_index: stack_index_type;
  short_value: short_type;
  short_bytes: short_bytes_type;
  endian: endian_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  short_value := Get_short_param(param_index);
  endian := endian_type(Get_integer_param(param_index));

  {************************}
  { convert short to bytes }
  {************************}
  short_bytes := Pack_short_to_bytes(short_value, endian);

  {************************************}
  { push byte array onto operand stack }
  {************************************}
  Eval_byte_array(byte_ptr_type(@short_bytes), short_byte_size);
end; {procedure Eval_short_to_data}


procedure Eval_integer_to_data;
var
  param_index: stack_index_type;
  integer_value: integer_type;
  integer_bytes: integer_bytes_type;
  endian: endian_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  integer_value := Get_integer_param(param_index);
  endian := endian_type(Get_integer_param(param_index));

  {**************************}
  { convert integer to bytes }
  {**************************}
  integer_bytes := Pack_integer_to_bytes(integer_value, endian);

  {************************************}
  { push byte array onto operand stack }
  {************************************}
  Eval_byte_array(byte_ptr_type(@integer_bytes), integer_byte_size);
end; {procedure Eval_integer_to_data}


procedure Eval_long_to_data;
var
  param_index: stack_index_type;
  long_value: long_type;
  long_bytes: long_bytes_type;
  endian: endian_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  long_value := Get_long_param(param_index);
  endian := endian_type(Get_integer_param(param_index));

  {***********************}
  { convert long to bytes }
  {***********************}
  long_bytes := Pack_long_to_bytes(long_value, endian);

  {************************************}
  { push byte array onto operand stack }
  {************************************}
  Eval_byte_array(byte_ptr_type(@long_bytes), long_byte_size);
end; {procedure Eval_long_to_data}


procedure Eval_scalar_to_data;
var
  param_index: stack_index_type;
  scalar_value: scalar_type;
  scalar_bytes: scalar_bytes_type;
  endian: endian_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  scalar_value := Get_scalar_param(param_index);
  endian := endian_type(Get_integer_param(param_index));

  {*************************}
  { convert scalar to bytes }
  {*************************}
  scalar_bytes := Pack_scalar_to_bytes(scalar_value, endian);

  {************************************}
  { push byte array onto operand stack }
  {************************************}
  Eval_byte_array(byte_ptr_type(@scalar_bytes), scalar_byte_size);
end; {procedure Eval_scalar_to_data}


procedure Eval_double_to_data;
var
  param_index: stack_index_type;
  double_value: double_type;
  double_bytes: double_bytes_type;
  endian: endian_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  double_value := Get_double_param(param_index);
  endian := endian_type(Get_integer_param(param_index));

  {*************************}
  { convert double to bytes }
  {*************************}
  double_bytes := Pack_double_to_bytes(double_value, endian);

  {************************************}
  { push byte array onto operand stack }
  {************************************}
  Eval_byte_array(byte_ptr_type(@double_bytes), double_byte_size);
end; {procedure Eval_double_to_data}


{*************************************************}
{ routines for converting data to primitive types }
{*************************************************}


procedure Eval_data_to_boolean;
var
  param_index: stack_index_type;
  handle: handle_type;
  endian: endian_type;
  index, heap_index: heap_index_type;
  boolean_bytes: boolean_bytes_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  handle := Get_handle_param(param_index);
  endian := endian_type(Get_integer_param(param_index));

  {*************************}
  { unpack bytes from array }
  {*************************}
  for index := 1 to boolean_byte_size do
    begin
      heap_index := Deref_row_array(handle, index, 1);
      boolean_bytes[index] := Get_handle_byte(handle, heap_index);
    end;

  {**************************************}
  { push return value onto operand stack }
  {**************************************}
  Push_boolean_operand(Unpack_bytes_to_boolean(boolean_bytes, endian));
end; {procedure Eval_data_to_boolean}


procedure Eval_data_to_char;
var
  param_index: stack_index_type;
  handle: handle_type;
  endian: endian_type;
  index, heap_index: heap_index_type;
  char_bytes: char_bytes_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  handle := Get_handle_param(param_index);
  endian := endian_type(Get_integer_param(param_index));

  {*************************}
  { unpack bytes from array }
  {*************************}
  for index := 1 to char_byte_size do
    begin
      heap_index := Deref_row_array(handle, index, 1);
      char_bytes[index] := Get_handle_byte(handle, heap_index);
    end;

  {**************************************}
  { push return value onto operand stack }
  {**************************************}
  Push_char_operand(Unpack_bytes_to_char(char_bytes, endian));
end; {procedure Eval_data_to_char}


procedure Eval_data_to_byte;
var
  param_index: stack_index_type;
  handle: handle_type;
  endian: endian_type;
  index, heap_index: heap_index_type;
  byte_bytes: byte_bytes_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  handle := Get_handle_param(param_index);
  endian := endian_type(Get_integer_param(param_index));

  {*************************}
  { unpack bytes from array }
  {*************************}
  for index := 1 to byte_byte_size do
    begin
      heap_index := Deref_row_array(handle, index, 1);
      byte_bytes[index] := Get_handle_byte(handle, heap_index);
    end;

  {**************************************}
  { push return value onto operand stack }
  {**************************************}
  Push_byte_operand(Unpack_bytes_to_byte(byte_bytes, endian));
end; {procedure Eval_data_to_byte}


procedure Eval_data_to_short;
var
  param_index: stack_index_type;
  handle: handle_type;
  endian: endian_type;
  index, heap_index: heap_index_type;
  short_bytes: short_bytes_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  handle := Get_handle_param(param_index);
  endian := endian_type(Get_integer_param(param_index));

  {*************************}
  { unpack bytes from array }
  {*************************}
  for index := 1 to short_byte_size do
    begin
      heap_index := Deref_row_array(handle, index, 1);
      short_bytes[index] := Get_handle_byte(handle, heap_index);
    end;

  {**************************************}
  { push return value onto operand stack }
  {**************************************}
  Push_short_operand(Unpack_bytes_to_short(short_bytes, endian));
end; {procedure Eval_data_to_short}


procedure Eval_data_to_integer;
var
  param_index: stack_index_type;
  handle: handle_type;
  endian: endian_type;
  index, heap_index: heap_index_type;
  integer_bytes: integer_bytes_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  handle := Get_handle_param(param_index);
  endian := endian_type(Get_integer_param(param_index));

  {*************************}
  { unpack bytes from array }
  {*************************}
  for index := 1 to integer_byte_size do
    begin
      heap_index := Deref_row_array(handle, index, 1);
      integer_bytes[index] := Get_handle_byte(handle, heap_index);
    end;

  {**************************************}
  { push return value onto operand stack }
  {**************************************}
  Push_integer_operand(Unpack_bytes_to_integer(integer_bytes, endian));
end; {procedure Eval_data_to_integer}


procedure Eval_data_to_long;
var
  param_index: stack_index_type;
  handle: handle_type;
  endian: endian_type;
  index, heap_index: heap_index_type;
  long_bytes: long_bytes_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  handle := Get_handle_param(param_index);
  endian := endian_type(Get_integer_param(param_index));

  {*************************}
  { unpack bytes from array }
  {*************************}
  for index := 1 to long_byte_size do
    begin
      heap_index := Deref_row_array(handle, index, 1);
      long_bytes[index] := Get_handle_byte(handle, heap_index);
    end;

  {**************************************}
  { push return value onto operand stack }
  {**************************************}
  Push_long_operand(Unpack_bytes_to_long(long_bytes, endian));
end; {procedure Eval_data_to_long}


procedure Eval_data_to_scalar;
var
  param_index: stack_index_type;
  handle: handle_type;
  endian: endian_type;
  index, heap_index: heap_index_type;
  scalar_bytes: scalar_bytes_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  handle := Get_handle_param(param_index);
  endian := endian_type(Get_integer_param(param_index));

  {*************************}
  { unpack bytes from array }
  {*************************}
  for index := 1 to scalar_byte_size do
    begin
      heap_index := Deref_row_array(handle, index, 1);
      scalar_bytes[index] := Get_handle_byte(handle, heap_index);
    end;

  {**************************************}
  { push return value onto operand stack }
  {**************************************}
  Push_scalar_operand(Unpack_bytes_to_scalar(scalar_bytes, endian));
end; {procedure Eval_data_to_scalar}


procedure Eval_data_to_double;
var
  param_index: stack_index_type;
  handle: handle_type;
  endian: endian_type;
  index, heap_index: heap_index_type;
  double_bytes: double_bytes_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  handle := Get_handle_param(param_index);
  endian := endian_type(Get_integer_param(param_index));

  {*************************}
  { unpack bytes from array }
  {*************************}
  for index := 1 to double_byte_size do
    begin
      heap_index := Deref_row_array(handle, index, 1);
      double_bytes[index] := Get_handle_byte(handle, heap_index);
    end;

  {**************************************}
  { push return value onto operand stack }
  {**************************************}
  Push_double_operand(Unpack_bytes_to_double(double_bytes, endian));
end; {procedure Eval_data_to_double}


{*****************************************************************}
{ routine to switch between and execute native conversion methods }
{*****************************************************************}


procedure Exec_native_conversion_method(kind:
  native_conversion_method_kind_type);
begin
  case kind of

    {*************************************************}
    { routines for converting primitive types to data }
    {*************************************************}
    native_boolean_to_data:
      Eval_boolean_to_data;
    native_char_to_data:
      Eval_char_to_data;
    native_byte_to_data:
      Eval_byte_to_data;
    native_short_to_data:
      Eval_short_to_data;
    native_integer_to_data:
      Eval_integer_to_data;
    native_long_to_data:
      Eval_long_to_data;
    native_scalar_to_data:
      Eval_scalar_to_data;
    native_double_to_data:
      Eval_double_to_data;

    {*************************************************}
    { routines for converting data to primitive types }
    {*************************************************}
    native_data_to_boolean:
      Eval_data_to_boolean;
    native_data_to_char:
      Eval_data_to_char;
    native_data_to_byte:
      Eval_data_to_byte;
    native_data_to_short:
      Eval_data_to_short;
    native_data_to_integer:
      Eval_data_to_integer;
    native_data_to_long:
      Eval_data_to_long;
    native_data_to_scalar:
      Eval_data_to_scalar;
    native_data_to_double:
      Eval_data_to_double;

  end; {case}
end; {procedure Exec_native_conversion_method}


end. {module exec_native_conversion}
