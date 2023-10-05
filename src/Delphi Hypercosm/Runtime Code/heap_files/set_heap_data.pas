unit set_heap_data;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            set_heap_data              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       These routines are used in conjunction with the         }
{       heap modules to more easily access the runtime          }
{       system's data.                                          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, complex_numbers, vectors, colors, data_types, addr_types, data;


{*******************************************************}
{ routines to set primitive data types from handle heap }
{*******************************************************}
procedure Set_handle_boolean(handle: handle_type;
  index: heap_index_type;
  boolean_val: boolean_type);
procedure Set_handle_char(handle: handle_type;
  index: heap_index_type;
  char_val: char_type);

procedure Set_handle_byte(handle: handle_type;
  index: heap_index_type;
  byte_val: byte_type);
procedure Set_handle_short(handle: handle_type;
  index: heap_index_type;
  short_val: short_type);

procedure Set_handle_integer(handle: handle_type;
  index: heap_index_type;
  integer_val: integer_type);
procedure Set_handle_long(handle: handle_type;
  index: heap_index_type;
  long_val: long_type);

procedure Set_handle_scalar(handle: handle_type;
  index: heap_index_type;
  scalar_val: scalar_type);
procedure Set_handle_double(handle: handle_type;
  index: heap_index_type;
  double_val: double_type);

{******************************************************}
{ routines to set compound data types from handle heap }
{******************************************************}
procedure Set_handle_complex(handle: handle_type;
  index: heap_index_type;
  complex_val: complex_type);
procedure Set_handle_vector(handle: handle_type;
  index: heap_index_type;
  vector_val: vector_type);
procedure Set_handle_color(handle: handle_type;
  index: heap_index_type;
  color_val: color_type);

procedure Set_handle_string(handle: handle_type;
  index: heap_index_type;
  str: string_type);
procedure Set_handle_addr(handle: handle_type;
  index: heap_index_type;
  addr: addr_type);

{*****************************************************}
{ routines to set address data types from handle heap }
{*****************************************************}
procedure Set_handle_stack_index(handle: handle_type;
  index: heap_index_type;
  stack_index: stack_index_type);
procedure Set_handle_heap_index(handle: handle_type;
  index: heap_index_type;
  heap_index: heap_index_type);

procedure Set_handle_handle(handle: handle_type;
  index: heap_index_type;
  handle_val: handle_type);
procedure Set_handle_memref(handle: handle_type;
  index: heap_index_type;
  memref: memref_type);

{*****************************************************}
{ routines to set pointer data types from handle heap }
{*****************************************************}
procedure Set_handle_code(handle: handle_type;
  index: heap_index_type;
  code_ptr: abstract_code_ptr_type);
procedure Set_handle_type(handle: handle_type;
  index: heap_index_type;
  type_ptr: abstract_type_ptr_type);

{******************************************************}
{ routines to set sentinel data types from handle heap }
{******************************************************}
procedure Set_handle_error(handle: handle_type;
  index: heap_index_type);

{*******************************************************}
{ routines to set primitive data types from memref heap }
{*******************************************************}
procedure Set_memref_boolean(memref: memref_type;
  index: heap_index_type;
  boolean_val: boolean_type);
procedure Set_memref_char(memref: memref_type;
  index: heap_index_type;
  char_val: char_type);

procedure Set_memref_byte(memref: memref_type;
  index: heap_index_type;
  byte_val: byte_type);
procedure Set_memref_short(memref: memref_type;
  index: heap_index_type;
  short_val: short_type);

procedure Set_memref_integer(memref: memref_type;
  index: heap_index_type;
  integer_val: integer_type);
procedure Set_memref_long(memref: memref_type;
  index: heap_index_type;
  long_val: long_type);

procedure Set_memref_scalar(memref: memref_type;
  index: heap_index_type;
  scalar_val: scalar_type);
procedure Set_memref_double(memref: memref_type;
  index: heap_index_type;
  double_val: double_type);

{******************************************************}
{ routines to set compound data types from memref heap }
{******************************************************}
procedure Set_memref_complex(memref: memref_type;
  index: heap_index_type;
  complex_val: complex_type);
procedure Set_memref_vector(memref: memref_type;
  index: heap_index_type;
  vector_val: vector_type);
procedure Set_memref_color(memref: memref_type;
  index: heap_index_type;
  color_val: color_type);

procedure Set_memref_string(memref: memref_type;
  index: heap_index_type;
  str: string_type);
procedure Set_memref_addr(memref: memref_type;
  index: heap_index_type;
  addr: addr_type);

{*****************************************************}
{ routines to set address data types from memref heap }
{*****************************************************}
procedure Set_memref_stack_index(memref: memref_type;
  index: heap_index_type;
  stack_index: stack_index_type);
procedure Set_memref_heap_index(memref: memref_type;
  index: heap_index_type;
  heap_index: heap_index_type);

procedure Set_memref_handle(memref: memref_type;
  index: heap_index_type;
  handle: handle_type);
procedure Set_memref_memref(memref: memref_type;
  index: heap_index_type;
  memref_val: memref_type);

{*****************************************************}
{ routines to set pointer data types from memref heap }
{*****************************************************}
procedure Set_memref_code(memref: memref_type;
  index: heap_index_type;
  code_ptr: abstract_code_ptr_type);
procedure Set_memref_type(memref: memref_type;
  index: heap_index_type;
  type_ptr: abstract_type_ptr_type);

{******************************************************}
{ routines to set sentinel data types from memref heap }
{******************************************************}
procedure Set_memref_error(memref: memref_type;
  index: heap_index_type);


implementation
uses
  handles, memrefs, get_heap_data, set_data;


{*******************************************************}
{ routines to set primitive data types from handle heap }
{*******************************************************}


procedure Set_handle_boolean(handle: handle_type;
  index: heap_index_type;
  boolean_val: boolean_type);
var
  data: data_type;
begin
  data.kind := boolean_data;
  data.boolean_val := boolean_val;
  Set_handle_data(handle, index, data);
end; {procedure Set_handle_boolean}


procedure Set_handle_char(handle: handle_type;
  index: heap_index_type;
  char_val: char_type);
var
  data: data_type;
begin
  data.kind := char_data;
  data.char_val := char_val;
  Set_handle_data(handle, index, data);
end; {procedure Set_handle_char}


procedure Set_handle_byte(handle: handle_type;
  index: heap_index_type;
  byte_val: byte_type);
var
  data: data_type;
begin
  data.kind := byte_data;
  data.byte_val := byte_val;
  Set_handle_data(handle, index, data);
end; {procedure Set_handle_byte}


procedure Set_handle_short(handle: handle_type;
  index: heap_index_type;
  short_val: short_type);
var
  data: data_type;
begin
  data.kind := short_data;
  data.short_val := short_val;
  Set_handle_data(handle, index, data);
end; {procedure Set_handle_short}


procedure Set_handle_integer(handle: handle_type;
  index: heap_index_type;
  integer_val: integer_type);
var
  data: data_type;
begin
  data.kind := integer_data;
  data.integer_val := integer_val;
  Set_handle_data(handle, index, data);
end; {procedure Set_handle_integer}


procedure Set_handle_long(handle: handle_type;
  index: heap_index_type;
  long_val: long_type);
var
  data: data_type;
begin
  data.kind := long_data;
  data.long_val := long_val;
  Set_handle_data(handle, index, data);
end; {procedure Set_handle_long}


procedure Set_handle_scalar(handle: handle_type;
  index: heap_index_type;
  scalar_val: scalar_type);
var
  data: data_type;
begin
  data.kind := scalar_data;
  data.scalar_val := scalar_val;
  Set_handle_data(handle, index, data);
end; {procedure Set_handle_scalar}


procedure Set_handle_double(handle: handle_type;
  index: heap_index_type;
  double_val: double_type);
var
  data: data_type;
begin
  data.kind := double_data;
  data.double_val := double_val;
  Set_handle_data(handle, index, data);
end; {procedure Set_handle_double}


{*******************************************************}
{ routines to set primitive data types from handle heap }
{*******************************************************}


procedure Set_handle_complex(handle: handle_type;
  index: heap_index_type;
  complex_val: complex_type);
begin
  Set_handle_scalar(handle, index, complex_val.a);
  Set_handle_scalar(handle, index + 1, complex_val.b);
end; {procedure Set_handle_complex}


procedure Set_handle_vector(handle: handle_type;
  index: heap_index_type;
  vector_val: vector_type);
begin
  Set_handle_scalar(handle, index, vector_val.x);
  Set_handle_scalar(handle, index + 1, vector_val.y);
  Set_handle_scalar(handle, index + 2, vector_val.z);
end; {procedure Set_handle_vector}


procedure Set_handle_color(handle: handle_type;
  index: heap_index_type;
  color_val: color_type);
begin
  Set_handle_scalar(handle, index, color_val.r);
  Set_handle_scalar(handle, index + 1, color_val.g);
  Set_handle_scalar(handle, index + 2, color_val.b);
end; {procedure Set_handle_color}


procedure Set_handle_string(handle: handle_type;
  index: stack_index_type;
  str: string_type);
var
  handle_val: handle_type;
begin
  handle_val := Get_handle_handle(handle, index);
  Set_string(handle_val, str);
end; {procedure Set_handle_string}


procedure Set_handle_addr(handle: handle_type;
  index: heap_index_type;
  addr: addr_type);
begin
  case addr.kind of

    {*****************}
    { stack addresses }
    {*****************}
    stack_index_addr:
      Set_handle_stack_index(handle, index, addr.stack_index);

    {*************************}
    { relative heap addresses }
    {*************************}
    heap_index_addr:
      Set_handle_heap_index(handle, index, addr.heap_index);

    {*************************}
    { absolute heap addresses }
    {*************************}
    handle_heap_addr:
      begin
        Set_handle_handle(handle, index, addr.handle);
        Set_handle_heap_index(handle, index + 1, addr.handle_index);
      end;
    memref_heap_addr:
      begin
        Set_handle_memref(handle, index, addr.memref);
        Set_handle_heap_index(handle, index + 1, addr.memref_index);
      end;

  end; {case}
end; {procedure Set_handle_addr}


{*****************************************************}
{ routines to set address data types from handle heap }
{*****************************************************}


procedure Set_handle_stack_index(handle: handle_type;
  index: heap_index_type;
  stack_index: stack_index_type);
var
  data: data_type;
begin
  data.kind := stack_index_data;
  data.stack_index := stack_index;
  Set_handle_data(handle, index, data);
end; {procedure Set_handle_stack_index}


procedure Set_handle_heap_index(handle: handle_type;
  index: heap_index_type;
  heap_index: heap_index_type);
var
  data: data_type;
begin
  data.kind := heap_index_data;
  data.heap_index := heap_index;
  Set_handle_data(handle, index, data);
end; {procedure Set_handle_heap_index}


procedure Set_handle_handle(handle: handle_type;
  index: heap_index_type;
  handle_val: handle_type);
var
  data: data_type;
begin
  data.kind := handle_data;
  data.handle := handle_val;
  Set_handle_data(handle, index, data);
end; {procedure Set_handle_handle}


procedure Set_handle_memref(handle: handle_type;
  index: heap_index_type;
  memref: memref_type);
var
  data: data_type;
begin
  data.kind := memref_data;
  data.memref := memref;
  Set_handle_data(handle, index, data);
end; {procedure Set_handle_memref}


{*****************************************************}
{ routines to set pointer data types from handle heap }
{*****************************************************}


procedure Set_handle_code(handle: handle_type;
  index: heap_index_type;
  code_ptr: abstract_code_ptr_type);
var
  data: data_type;
begin
  data.kind := code_data;
  data.code_ptr := code_ptr;
  Set_handle_data(handle, index, data);
end; {procedure Set_handle_code}


procedure Set_handle_type(handle: handle_type;
  index: heap_index_type;
  type_ptr: abstract_type_ptr_type);
var
  data: data_type;
begin
  data.kind := code_data;
  data.type_ptr := type_ptr;
  Set_handle_data(handle, index, data);
end; {procedure Set_handle_type}


{******************************************************}
{ routines to set sentinel data types from handle heap }
{******************************************************}


procedure Set_handle_error(handle: handle_type;
  index: stack_index_type);
var
  data: data_type;
begin
  data.kind := error_data;
  Set_handle_data(handle, index, data);
end; {procedure Set_handle_error}


{*******************************************************}
{ routines to set primitive data types from memref heap }
{*******************************************************}


procedure Set_memref_boolean(memref: memref_type;
  index: heap_index_type;
  boolean_val: boolean_type);
var
  data: data_type;
begin
  data.kind := boolean_data;
  data.boolean_val := boolean_val;
  Set_memref_data(memref, index, data);
end; {procedure Set_memref_boolean}


procedure Set_memref_char(memref: memref_type;
  index: heap_index_type;
  char_val: char_type);
var
  data: data_type;
begin
  data.kind := char_data;
  data.char_val := char_val;
  Set_memref_data(memref, index, data);
end; {procedure Set_memref_char}


procedure Set_memref_byte(memref: memref_type;
  index: heap_index_type;
  byte_val: byte_type);
var
  data: data_type;
begin
  data.kind := byte_data;
  data.byte_val := byte_val;
  Set_memref_data(memref, index, data);
end; {procedure Set_memref_byte}


procedure Set_memref_short(memref: memref_type;
  index: heap_index_type;
  short_val: short_type);
var
  data: data_type;
begin
  data.kind := short_data;
  data.short_val := short_val;
  Set_memref_data(memref, index, data);
end; {procedure Set_memref_short}


procedure Set_memref_integer(memref: memref_type;
  index: heap_index_type;
  integer_val: integer_type);
var
  data: data_type;
begin
  data.kind := integer_data;
  data.integer_val := integer_val;
  Set_memref_data(memref, index, data);
end; {procedure Set_memref_integer}


procedure Set_memref_long(memref: memref_type;
  index: heap_index_type;
  long_val: long_type);
var
  data: data_type;
begin
  data.kind := long_data;
  data.long_val := long_val;
  Set_memref_data(memref, index, data);
end; {procedure Set_memref_long}


procedure Set_memref_scalar(memref: memref_type;
  index: heap_index_type;
  scalar_val: scalar_type);
var
  data: data_type;
begin
  data.kind := scalar_data;
  data.scalar_val := scalar_val;
  Set_memref_data(memref, index, data);
end; {procedure Set_memref_scalar}


procedure Set_memref_double(memref: memref_type;
  index: heap_index_type;
  double_val: double_type);
var
  data: data_type;
begin
  data.kind := double_data;
  data.double_val := double_val;
  Set_memref_data(memref, index, data);
end; {procedure Set_memref_double}


{******************************************************}
{ routines to set compound data types from memref heap }
{******************************************************}


procedure Set_memref_complex(memref: memref_type;
  index: heap_index_type;
  complex_val: complex_type);
begin
  Set_memref_scalar(memref, index, complex_val.a);
  Set_memref_scalar(memref, index + 1, complex_val.b);
end; {procedure Set_memref_complex}


procedure Set_memref_vector(memref: memref_type;
  index: heap_index_type;
  vector_val: vector_type);
begin
  Set_memref_scalar(memref, index, vector_val.x);
  Set_memref_scalar(memref, index + 1, vector_val.y);
  Set_memref_scalar(memref, index + 2, vector_val.z);
end; {procedure Set_memref_vector}


procedure Set_memref_color(memref: memref_type;
  index: heap_index_type;
  color_val: color_type);
begin
  Set_memref_scalar(memref, index, color_val.r);
  Set_memref_scalar(memref, index + 1, color_val.g);
  Set_memref_scalar(memref, index + 2, color_val.b);
end; {procedure Set_memref_color}


procedure Set_memref_string(memref: memref_type;
  index: heap_index_type;
  str: string_type);
var
  handle: handle_type;
begin
  handle := Get_memref_handle(memref, index);
  Set_string(handle, str);
end; {procedure Set_memref_string}


procedure Set_memref_addr(memref: memref_type;
  index: heap_index_type;
  addr: addr_type);
begin
  case addr.kind of

    {*****************}
    { stack addresses }
    {*****************}
    stack_index_addr:
      Set_memref_stack_index(memref, index, addr.stack_index);

    {*************************}
    { relative heap addresses }
    {*************************}
    heap_index_addr:
      Set_memref_heap_index(memref, index, addr.heap_index);

    {*************************}
    { absolute heap addresses }
    {*************************}
    handle_heap_addr:
      begin
        Set_memref_handle(memref, index, addr.handle);
        Set_memref_heap_index(memref, index + 1, addr.handle_index);
      end;
    memref_heap_addr:
      begin
        Set_memref_memref(memref, index, addr.memref);
        Set_memref_heap_index(memref, index + 1, addr.memref_index);
      end;

  end; {case}
end; {procedure Set_memref_addr}


{*****************************************************}
{ routines to set address data types from memref heap }
{*****************************************************}


procedure Set_memref_stack_index(memref: memref_type;
  index: heap_index_type;
  stack_index: stack_index_type);
var
  data: data_type;
begin
  data.kind := stack_index_data;
  data.stack_index := stack_index;
  Set_memref_data(memref, index, data);
end; {procedure Set_memref_stack_index}


procedure Set_memref_heap_index(memref: memref_type;
  index: heap_index_type;
  heap_index: heap_index_type);
var
  data: data_type;
begin
  data.kind := heap_index_data;
  data.heap_index := heap_index;
  Set_memref_data(memref, index, data);
end; {procedure Set_memref_heap_index}


procedure Set_memref_handle(memref: memref_type;
  index: heap_index_type;
  handle: handle_type);
var
  data: data_type;
begin
  data.kind := handle_data;
  data.handle := handle;
  Set_memref_data(memref, index, data);
end; {procedure Set_memref_handle}


procedure Set_memref_memref(memref: memref_type;
  index: heap_index_type;
  memref_val: memref_type);
var
  data: data_type;
begin
  data.kind := memref_data;
  data.memref := memref_val;

  {**********************}
  { free previous memref }
  {**********************}
  memref_val := Get_memref_memref(memref, index);
  Free_memref(memref_val);

  Set_memref_data(memref, index, data);
end; {procedure Set_memref_memref}


{*****************************************************}
{ routines to set pointer data types from memref heap }
{*****************************************************}


procedure Set_memref_code(memref: memref_type;
  index: heap_index_type;
  code_ptr: abstract_code_ptr_type);
var
  data: data_type;
begin
  data.kind := code_data;
  data.code_ptr := code_ptr;
  Set_memref_data(memref, index, data);
end; {procedure Set_memref_code}


procedure Set_memref_type(memref: memref_type;
  index: heap_index_type;
  type_ptr: abstract_type_ptr_type);
var
  data: data_type;
begin
  data.kind := type_data;
  data.type_ptr := type_ptr;
  Set_memref_data(memref, index, data);
end; {procedure Set_memref_type}


{******************************************************}
{ routines to set sentinel data types from memref heap }
{******************************************************}


procedure Set_memref_error(memref: memref_type;
  index: heap_index_type);
var
  data: data_type;
begin
  data.kind := error_data;
  Set_memref_data(memref, index, data);
end; {procedure Set_memref_error}


end.
