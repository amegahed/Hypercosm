unit set_stack_data;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           set_stack_data              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       These routines are used in conjunction with the         }
{       stack module to more easily access the runtime          }
{       system's data.                                          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, complex_numbers, vectors, colors, data_types, addr_types, data,
  stacks;


{****************************************************}
{ routines to set primitive data types by stack addr }
{****************************************************}
procedure Set_stack_boolean(stack_addr: stack_addr_type;
  boolean_val: boolean_type);
procedure Set_stack_char(stack_addr: stack_addr_type;
  char_val: char_type);

procedure Set_stack_byte(stack_addr: stack_addr_type;
  byte_val: byte_type);
procedure Set_stack_short(stack_addr: stack_addr_type;
  short_val: short_type);

procedure Set_stack_integer(stack_addr: stack_addr_type;
  integer_val: integer_type);
procedure Set_stack_long(stack_addr: stack_addr_type;
  long_val: long_type);

procedure Set_stack_scalar(stack_addr: stack_addr_type;
  scalar_val: scalar_type);
procedure Set_stack_double(stack_addr: stack_addr_type;
  double_val: double_type);

{***************************************************}
{ routines to set compound data types by stack addr }
{***************************************************}
procedure Set_stack_complex(stack_addr: stack_addr_type;
  complex_val: complex_type);
procedure Set_stack_vector(stack_addr: stack_addr_type;
  vector_val: vector_type);
procedure Set_stack_color(stack_addr: stack_addr_type;
  color_val: color_type);

procedure Set_stack_string(stack_addr: stack_addr_type;
  str: string_type);
procedure Set_stack_addr(stack_addr: stack_addr_type;
  addr: addr_type);

{**************************************************}
{ routines to set address data types by stack addr }
{**************************************************}
procedure Set_stack_stack_index(stack_addr: stack_addr_type;
  stack_index: stack_index_type);
procedure Set_stack_heap_index(stack_addr: stack_addr_type;
  heap_index: heap_index_type);

procedure Set_stack_handle(stack_addr: stack_addr_type;
  handle: handle_type);
procedure Set_stack_memref(stack_addr: stack_addr_type;
  memref: memref_type);

{**************************************************}
{ routines to set pointer data types by stack addr }
{**************************************************}
procedure Set_stack_code(stack_addr: stack_addr_type;
  code_ptr: abstract_code_ptr_type);
procedure Set_stack_type(stack_addr: stack_addr_type;
  type_ptr: abstract_type_ptr_type);

{***************************************************}
{ routines to set sentinel data types by stack addr }
{***************************************************}
procedure Set_stack_error(stack_addr: stack_addr_type);

{*************************************************************}
{ routines to set primitive data types from local stack frame }
{*************************************************************}
procedure Set_local_boolean(index: stack_index_type;
  boolean_val: boolean_type);
procedure Set_local_char(index: stack_index_type;
  char_val: char_type);

procedure Set_local_byte(index: stack_index_type;
  byte_val: byte_type);
procedure Set_local_short(index: stack_index_type;
  short_val: short_type);

procedure Set_local_integer(index: stack_index_type;
  integer_val: integer_type);
procedure Set_local_long(index: stack_index_type;
  long_val: long_type);

procedure Set_local_scalar(index: stack_index_type;
  scalar_val: scalar_type);
procedure Set_local_double(index: stack_index_type;
  double_val: double_type);

{************************************************************}
{ routines to set compound data types from local stack frame }
{************************************************************}
procedure Set_local_complex(index: stack_index_type;
  complex_val: complex_type);
procedure Set_local_vector(index: stack_index_type;
  vector_val: vector_type);
procedure Set_local_color(index: stack_index_type;
  color_val: color_type);

procedure Set_local_string(index: stack_index_type;
  str: string_type);
procedure Set_local_addr(index: stack_index_type;
  addr: addr_type);

{***********************************************************}
{ routines to set address data types from local stack frame }
{***********************************************************}
procedure Set_local_stack_index(index: stack_index_type;
  stack_index: stack_index_type);
procedure Set_local_heap_index(index: stack_index_type;
  heap_index: heap_index_type);

procedure Set_local_handle(index: stack_index_type;
  handle: handle_type);
procedure Set_local_memref(index: stack_index_type;
  memref: memref_type);

{***********************************************************}
{ routines to set pointer data types from local stack frame }
{***********************************************************}
procedure Set_local_code(index: stack_index_type;
  code_ptr: abstract_code_ptr_type);
procedure Set_local_type(index: stack_index_type;
  type_ptr: abstract_type_ptr_type);

{************************************************************}
{ routines to set sentinel data types from local stack frame }
{************************************************************}
procedure Set_local_error(index: stack_index_type);

{*****************************************************}
{ routines to set primitive data types by stack index }
{*****************************************************}
procedure Set_global_boolean(index: stack_index_type;
  boolean_val: boolean_type);
procedure Set_global_char(index: stack_index_type;
  char_val: char_type);

procedure Set_global_byte(index: stack_index_type;
  byte_val: byte_type);
procedure Set_global_short(index: stack_index_type;
  short_val: short_type);

procedure Set_global_integer(index: stack_index_type;
  integer_val: integer_type);
procedure Set_global_long(index: stack_index_type;
  long_val: long_type);

procedure Set_global_scalar(index: stack_index_type;
  scalar_val: scalar_type);
procedure Set_global_double(index: stack_index_type;
  double_val: double_type);

{****************************************************}
{ routines to set compound data types by stack index }
{****************************************************}
procedure Set_global_complex(index: stack_index_type;
  complex_val: complex_type);
procedure Set_global_vector(index: stack_index_type;
  vector_val: vector_type);
procedure Set_global_color(index: stack_index_type;
  color_val: color_type);

procedure Set_global_string(index: stack_index_type;
  str: string_type);
procedure Set_global_addr(index: stack_index_type;
  addr: addr_type);

{***************************************************}
{ routines to set address data types by stack index }
{***************************************************}
procedure Set_global_stack_index(index: stack_index_type;
  stack_index: stack_index_type);
procedure Set_global_heap_index(index: stack_index_type;
  heap_index: heap_index_type);

procedure Set_global_handle(index: stack_index_type;
  handle: handle_type);
procedure Set_global_memref(index: stack_index_type;
  memref: memref_type);

{***************************************************}
{ routines to set pointer data types by stack index }
{***************************************************}
procedure Set_global_code(index: stack_index_type;
  code_ptr: abstract_code_ptr_type);
procedure Set_global_type(index: stack_index_type;
  type_ptr: abstract_type_ptr_type);

{****************************************************}
{ routines to set sentinel data types by stack index }
{****************************************************}
procedure Set_global_error(index: stack_index_type);


implementation
uses
  get_stack_data, set_data;


{****************************************************}
{ routines to set primitive data types by stack addr }
{****************************************************}


procedure Set_stack_boolean(stack_addr: stack_addr_type;
  boolean_val: boolean_type);
var
  data: data_type;
begin
  data.kind := boolean_data;
  data.boolean_val := boolean_val;
  Set_stack(stack_addr, data);
end; {procedure Set_stack_boolean}


procedure Set_stack_char(stack_addr: stack_addr_type;
  char_val: char_type);
var
  data: data_type;
begin
  data.kind := char_data;
  data.char_val := char_val;
  Set_stack(stack_addr, data);
end; {procedure Set_stack_char}


procedure Set_stack_byte(stack_addr: stack_addr_type;
  byte_val: byte_type);
var
  data: data_type;
begin
  data.kind := byte_data;
  data.byte_val := byte_val;
  Set_stack(stack_addr, data);
end; {procedure Set_stack_byte}


procedure Set_stack_short(stack_addr: stack_addr_type;
  short_val: short_type);
var
  data: data_type;
begin
  data.kind := short_data;
  data.short_val := short_val;
  Set_stack(stack_addr, data);
end; {procedure Set_stack_short}


procedure Set_stack_integer(stack_addr: stack_addr_type;
  integer_val: integer_type);
var
  data: data_type;
begin
  data.kind := integer_data;
  data.integer_val := integer_val;
  Set_stack(stack_addr, data);
end; {procedure Set_stack_integer}


procedure Set_stack_long(stack_addr: stack_addr_type;
  long_val: long_type);
var
  data: data_type;
begin
  data.kind := long_data;
  data.long_val := long_val;
  Set_stack(stack_addr, data);
end; {procedure Set_stack_long}


procedure Set_stack_scalar(stack_addr: stack_addr_type;
  scalar_val: scalar_type);
var
  data: data_type;
begin
  data.kind := scalar_data;
  data.scalar_val := scalar_val;
  Set_stack(stack_addr, data);
end; {procedure Set_stack_scalar}


procedure Set_stack_double(stack_addr: stack_addr_type;
  double_val: double_type);
var
  data: data_type;
begin
  data.kind := double_data;
  data.double_val := double_val;
  Set_stack(stack_addr, data);
end; {procedure Set_stack_double}


{***************************************************}
{ routines to set compound data types by stack addr }
{***************************************************}


procedure Set_stack_complex(stack_addr: stack_addr_type;
  complex_val: complex_type);
var
  stack_index: stack_index_type;
begin
  stack_index := Stack_addr_to_index(stack_addr);
  Set_global_scalar(stack_index, complex_val.a);
  Set_global_scalar(stack_index + 1, complex_val.b);
end; {procedure Set_stack_complex}


procedure Set_stack_vector(stack_addr: stack_addr_type;
  vector_val: vector_type);
var
  stack_index: stack_index_type;
begin
  stack_index := Stack_addr_to_index(stack_addr);
  Set_global_scalar(stack_index, vector_val.x);
  Set_global_scalar(stack_index + 1, vector_val.y);
  Set_global_scalar(stack_index + 2, vector_val.z);
end; {procedure Set_stack_vector}


procedure Set_stack_color(stack_addr: stack_addr_type;
  color_val: color_type);
var
  stack_index: stack_index_type;
begin
  stack_index := Stack_addr_to_index(stack_addr);
  Set_global_scalar(stack_index, color_val.r);
  Set_global_scalar(stack_index + 1, color_val.g);
  Set_global_scalar(stack_index + 2, color_val.b);
end; {procedure Set_stack_color}


procedure Set_stack_string(stack_addr: stack_addr_type;
  str: string_type);
var
  handle: handle_type;
begin
  handle := Get_stack_handle(stack_addr);
  Set_string(handle, str);
end; {procedure Set_stack_string}


procedure Set_stack_addr(stack_addr: stack_addr_type;
  addr: addr_type);
var
  index: stack_index_type;
begin
  index := Stack_addr_to_index(stack_addr);
  case addr.kind of

    {*****************}
    { stack addresses }
    {*****************}
    stack_index_addr:
      Set_global_stack_index(index, addr.stack_index);

    {*************************}
    { relative heap addresses }
    {*************************}
    heap_index_addr:
      Set_global_heap_index(index, addr.heap_index);

    {*************************}
    { absolute heap addresses }
    {*************************}
    handle_heap_addr:
      begin
        Set_global_handle(index, addr.handle);
        Set_global_heap_index(index + 1, addr.handle_index);
      end;
    memref_heap_addr:
      begin
        Set_global_memref(index, addr.memref);
        Set_global_heap_index(index + 1, addr.memref_index);
      end;

  end; {case}
end; {procedure Set_stack_addr}


{**************************************************}
{ routines to set address data types by stack addr }
{**************************************************}


procedure Set_stack_stack_index(stack_addr: stack_addr_type;
  stack_index: stack_index_type);
var
  data: data_type;
begin
  data.kind := stack_index_data;
  data.stack_index := stack_index;
  Set_stack(stack_addr, data);
end; {procedure Set_stack_stack_index}


procedure Set_stack_heap_index(stack_addr: stack_addr_type;
  heap_index: heap_index_type);
var
  data: data_type;
begin
  data.kind := heap_index_data;
  data.heap_index := heap_index;
  Set_stack(stack_addr, data);
end; {procedure Set_stack_heap_index}


procedure Set_stack_handle(stack_addr: stack_addr_type;
  handle: handle_type);
var
  data: data_type;
begin
  data.kind := handle_data;
  data.handle := handle;
  Set_stack(stack_addr, data);
end; {procedure Set_stack_handle}


procedure Set_stack_memref(stack_addr: stack_addr_type;
  memref: memref_type);
var
  data: data_type;
begin
  data.kind := memref_data;
  data.memref := memref;
  Set_stack(stack_addr, data);
end; {procedure Set_stack_memref}


{**************************************************}
{ routines to set pointer data types by stack addr }
{**************************************************}


procedure Set_stack_code(stack_addr: stack_addr_type;
  code_ptr: abstract_code_ptr_type);
var
  data: data_type;
begin
  data.kind := code_data;
  data.code_ptr := code_ptr;
  Set_stack(stack_addr, data);
end; {procedure Set_stack_code}


procedure Set_stack_type(stack_addr: stack_addr_type;
  type_ptr: abstract_type_ptr_type);
var
  data: data_type;
begin
  data.kind := type_data;
  data.type_ptr := type_ptr;
  Set_stack(stack_addr, data);
end; {procedure Set_stack_type}


{***************************************************}
{ routines to set sentinel data types by stack addr }
{***************************************************}


procedure Set_stack_error(stack_addr: stack_addr_type);
var
  data: data_type;
begin
  data.kind := error_data;
  Set_stack(stack_addr, data);
end; {procedure Set_stack_error}


{***********************************************************}
{ routines to set primitive data types from top stack frame }
{***********************************************************}


procedure Set_local_boolean(index: stack_index_type;
  boolean_val: boolean_type);
var
  data: data_type;
begin
  data.kind := boolean_data;
  data.boolean_val := boolean_val;
  Set_local_stack(index, data);
end; {procedure Set_local_boolean}


procedure Set_local_char(index: stack_index_type;
  char_val: char_type);
var
  data: data_type;
begin
  data.kind := char_data;
  data.char_val := char_val;
  Set_local_stack(index, data);
end; {procedure Set_local_char}


procedure Set_local_byte(index: stack_index_type;
  byte_val: byte_type);
var
  data: data_type;
begin
  data.kind := byte_data;
  data.byte_val := byte_val;
  Set_local_stack(index, data);
end; {procedure Set_local_byte}


procedure Set_local_short(index: stack_index_type;
  short_val: short_type);
var
  data: data_type;
begin
  data.kind := short_data;
  data.short_val := short_val;
  Set_local_stack(index, data);
end; {procedure Set_local_short}


procedure Set_local_integer(index: stack_index_type;
  integer_val: integer_type);
var
  data: data_type;
begin
  data.kind := integer_data;
  data.integer_val := integer_val;
  Set_local_stack(index, data);
end; {procedure Set_local_integer}


procedure Set_local_long(index: stack_index_type;
  long_val: long_type);
var
  data: data_type;
begin
  data.kind := long_data;
  data.long_val := long_val;
  Set_local_stack(index, data);
end; {procedure Set_local_long}


procedure Set_local_scalar(index: stack_index_type;
  scalar_val: scalar_type);
var
  data: data_type;
begin
  data.kind := scalar_data;
  data.scalar_val := scalar_val;
  Set_local_stack(index, data);
end; {procedure Set_local_scalar}


procedure Set_local_double(index: stack_index_type;
  double_val: double_type);
var
  data: data_type;
begin
  data.kind := double_data;
  data.double_val := double_val;
  Set_local_stack(index, data);
end; {procedure Set_local_double}


{**********************************************************}
{ routines to set compound data types from top stack frame }
{**********************************************************}


procedure Set_local_complex(index: stack_index_type;
  complex_val: complex_type);
begin
  Set_local_scalar(index, complex_val.a);
  Set_local_scalar(index + 1, complex_val.b);
end; {procedure Set_local_complex}


procedure Set_local_vector(index: stack_index_type;
  vector_val: vector_type);
begin
  Set_local_scalar(index, vector_val.x);
  Set_local_scalar(index + 1, vector_val.y);
  Set_local_scalar(index + 2, vector_val.z);
end; {procedure Set_local_vector}


procedure Set_local_color(index: stack_index_type;
  color_val: color_type);
begin
  Set_local_scalar(index, color_val.r);
  Set_local_scalar(index + 1, color_val.g);
  Set_local_scalar(index + 2, color_val.b);
end; {procedure Set_local_color}


procedure Set_local_string(index: stack_index_type;
  str: string_type);
var
  handle: handle_type;
begin
  handle := Get_local_handle(index);
  Set_string(handle, str);
end; {procedure Set_local_string}


procedure Set_local_addr(index: stack_index_type;
  addr: addr_type);
begin
  case addr.kind of

    {*****************}
    { stack addresses }
    {*****************}
    stack_index_addr:
      Set_local_stack_index(index, addr.stack_index);

    {*************************}
    { relative heap addresses }
    {*************************}
    heap_index_addr:
      Set_local_heap_index(index, addr.heap_index);

    {*************************}
    { absolute heap addresses }
    {*************************}
    handle_heap_addr:
      begin
        Set_local_handle(index, addr.handle);
        Set_local_heap_index(index + 1, addr.handle_index);
      end;
    memref_heap_addr:
      begin
        Set_local_memref(index, addr.memref);
        Set_local_heap_index(index + 1, addr.memref_index);
      end;

  end; {case}
end; {procedure Set_local_addr}


{*********************************************************}
{ routines to set address data types from top stack frame }
{*********************************************************}


procedure Set_local_stack_index(index: stack_index_type;
  stack_index: stack_index_type);
var
  data: data_type;
begin
  data.kind := stack_index_data;
  data.stack_index := stack_index;
  Set_local_stack(index, data);
end; {procedure Set_local_stack_index}


procedure Set_local_heap_index(index: stack_index_type;
  heap_index: heap_index_type);
var
  data: data_type;
begin
  data.kind := heap_index_data;
  data.heap_index := heap_index;
  Set_local_stack(index, data);
end; {procedure Set_local_heap_index}


procedure Set_local_handle(index: stack_index_type;
  handle: handle_type);
var
  data: data_type;
begin
  data.kind := handle_data;
  data.handle := handle;
  Set_local_stack(index, data);
end; {procedure Set_local_handle}


procedure Set_local_memref(index: stack_index_type;
  memref: memref_type);
var
  data: data_type;
begin
  data.kind := memref_data;
  data.memref := memref;
  Set_local_stack(index, data);
end; {procedure Set_local_memref}


{*********************************************************}
{ routines to set pointer data types from top stack frame }
{*********************************************************}


procedure Set_local_code(index: stack_index_type;
  code_ptr: abstract_code_ptr_type);
var
  data: data_type;
begin
  data.kind := code_data;
  data.code_ptr := code_ptr;
  Set_local_stack(index, data);
end; {procedure Set_local_code}


procedure Set_local_type(index: stack_index_type;
  type_ptr: abstract_type_ptr_type);
var
  data: data_type;
begin
  data.kind := type_data;
  data.type_ptr := type_ptr;
  Set_local_stack(index, data);
end; {procedure Set_local_type}


{**********************************************************}
{ routines to set sentinel data types from top stack frame }
{**********************************************************}


procedure Set_local_error(index: stack_index_type);
var
  data: data_type;
begin
  data.kind := error_data;
  Set_local_stack(index, data);
end; {procedure Set_local_error}


{*****************************************************}
{ routines to set primitive data types by stack index }
{*****************************************************}


procedure Set_global_boolean(index: stack_index_type;
  boolean_val: boolean_type);
var
  data: data_type;
begin
  data.kind := boolean_data;
  data.boolean_val := boolean_val;
  Set_global_stack(index, data);
end; {procedure Set_global_boolean}


procedure Set_global_char(index: stack_index_type;
  char_val: char_type);
var
  data: data_type;
begin
  data.kind := char_data;
  data.char_val := char_val;
  Set_global_stack(index, data);
end; {procedure Set_global_char}


procedure Set_global_byte(index: stack_index_type;
  byte_val: byte_type);
var
  data: data_type;
begin
  data.kind := byte_data;
  data.byte_val := byte_val;
  Set_global_stack(index, data);
end; {procedure Set_global_byte}


procedure Set_global_short(index: stack_index_type;
  short_val: short_type);
var
  data: data_type;
begin
  data.kind := short_data;
  data.short_val := short_val;
  Set_global_stack(index, data);
end; {procedure Set_global_short}


procedure Set_global_integer(index: stack_index_type;
  integer_val: integer_type);
var
  data: data_type;
begin
  data.kind := integer_data;
  data.integer_val := integer_val;
  Set_global_stack(index, data);
end; {procedure Set_global_integer}


procedure Set_global_long(index: stack_index_type;
  long_val: long_type);
var
  data: data_type;
begin
  data.kind := long_data;
  data.long_val := long_val;
  Set_global_stack(index, data);
end; {procedure Set_global_long}


procedure Set_global_scalar(index: stack_index_type;
  scalar_val: scalar_type);
var
  data: data_type;
begin
  data.kind := scalar_data;
  data.scalar_val := scalar_val;
  Set_global_stack(index, data);
end; {procedure Set_global_scalar}


procedure Set_global_double(index: stack_index_type;
  double_val: double_type);
var
  data: data_type;
begin
  data.kind := double_data;
  data.double_val := double_val;
  Set_global_stack(index, data);
end; {procedure Set_global_double}


{*****************************************************}
{ routines to set primitive data types by stack index }
{*****************************************************}


procedure Set_global_complex(index: stack_index_type;
  complex_val: complex_type);
begin
  Set_global_scalar(index, complex_val.a);
  Set_global_scalar(index + 1, complex_val.b);
end; {procedure Set_global_complex}


procedure Set_global_vector(index: stack_index_type;
  vector_val: vector_type);
begin
  Set_global_scalar(index, vector_val.x);
  Set_global_scalar(index + 1, vector_val.y);
  Set_global_scalar(index + 2, vector_val.z);
end; {procedure Set_global_vector}


procedure Set_global_color(index: stack_index_type;
  color_val: color_type);
begin
  Set_global_scalar(index, color_val.r);
  Set_global_scalar(index + 1, color_val.g);
  Set_global_scalar(index + 2, color_val.b);
end; {procedure Set_global_color}


procedure Set_global_string(index: stack_index_type;
  str: string_type);
var
  handle: handle_type;
begin
  handle := Get_global_handle(index);
  Set_string(handle, str);
end; {procedure Set_global_string}


procedure Set_global_addr(index: stack_index_type;
  addr: addr_type);
begin
  case addr.kind of

    {*****************}
    { stack addresses }
    {*****************}
    stack_index_addr:
      Set_global_stack_index(index, addr.stack_index);

    {*************************}
    { relative heap addresses }
    {*************************}
    heap_index_addr:
      Set_global_heap_index(index, addr.heap_index);

    {*************************}
    { absolute heap addresses }
    {*************************}
    handle_heap_addr:
      begin
        Set_global_handle(index, addr.handle);
        Set_global_heap_index(index, addr.handle_index);
      end;
    memref_heap_addr:
      begin
        Set_global_memref(index, addr.memref);
        Set_global_heap_index(index, addr.memref_index);
      end;

  end; {case}
end; {procedure Set_global_addr}


{***************************************************}
{ routines to set address data types by stack index }
{***************************************************}


procedure Set_global_stack_index(index: stack_index_type;
  stack_index: stack_index_type);
var
  data: data_type;
begin
  data.kind := stack_index_data;
  data.stack_index := stack_index;
  Set_global_stack(index, data);
end; {procedure Set_global_stack_index}


procedure Set_global_heap_index(index: stack_index_type;
  heap_index: heap_index_type);
var
  data: data_type;
begin
  data.kind := heap_index_data;
  data.heap_index := heap_index;
  Set_global_stack(index, data);
end; {procedure Set_global_heap_index}


procedure Set_global_handle(index: stack_index_type;
  handle: handle_type);
var
  data: data_type;
begin
  data.kind := handle_data;
  data.handle := handle;
  Set_global_stack(index, data);
end; {procedure Set_global_handle}


procedure Set_global_memref(index: stack_index_type;
  memref: memref_type);
var
  data: data_type;
begin
  data.kind := memref_data;
  data.memref := memref;
  Set_global_stack(index, data);
end; {procedure Set_global_memref}


{***************************************************}
{ routines to set pointer data types by stack index }
{***************************************************}


procedure Set_global_code(index: stack_index_type;
  code_ptr: abstract_code_ptr_type);
var
  data: data_type;
begin
  data.kind := code_data;
  data.code_ptr := code_ptr;
  Set_global_stack(index, data);
end; {procedure Set_global_code}


procedure Set_global_type(index: stack_index_type;
  type_ptr: abstract_type_ptr_type);
var
  data: data_type;
begin
  data.kind := type_data;
  data.type_ptr := type_ptr;
  Set_global_stack(index, data);
end; {procedure Set_global_type}


{****************************************************}
{ routines to set sentinel data types by stack index }
{****************************************************}


procedure Set_global_error(index: stack_index_type);
var
  data: data_type;
begin
  data.kind := error_data;
  Set_global_stack(index, data);
end; {procedure Set_global_error}


end.
