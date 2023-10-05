unit set_data;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              set_data                 3d       }
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
uses
  strings, complex_numbers, vectors, colors, data_types, addr_types, data;


procedure Set_string(handle: handle_type;
  str: string_type);
procedure Free_addr(var addr: addr_type);

{************************************************}
{ routines to set primitive data types from addr }
{************************************************}
procedure Set_addr_boolean(addr: addr_type;
  boolean_val: boolean_type);
procedure Set_addr_char(addr: addr_type;
  char_val: char_type);

procedure Set_addr_byte(addr: addr_type;
  byte_val: byte_type);
procedure Set_addr_short(addr: addr_type;
  short_val: short_type);

procedure Set_addr_integer(addr: addr_type;
  integer_val: integer_type);
procedure Set_addr_long(addr: addr_type;
  long_val: long_type);

procedure Set_addr_scalar(addr: addr_type;
  scalar_val: scalar_type);
procedure Set_addr_double(addr: addr_type;
  double_val: double_type);

{***********************************************}
{ routines to set compound data types from addr }
{***********************************************}
procedure Set_addr_complex(addr: addr_type;
  complex_val: complex_type);
procedure Set_addr_vector(addr: addr_type;
  vector_val: vector_type);
procedure Set_addr_color(addr: addr_type;
  color_val: color_type);

procedure Set_addr_string(addr: addr_type;
  str: string_type);
procedure Set_addr_addr(addr: addr_type;
  addr_val: addr_type);

{**********************************************}
{ routines to set address data types from addr }
{**********************************************}
procedure Set_addr_stack_index(addr: addr_type;
  stack_index: stack_index_type);
procedure Set_addr_heap_index(addr: addr_type;
  heap_index: heap_index_type);

procedure Set_addr_handle(addr: addr_type;
  handle: handle_type);
procedure Set_addr_memref(addr: addr_type;
  memref: memref_type);

{**********************************************}
{ routines to set pointer data types from addr }
{**********************************************}
procedure Set_addr_code(addr: addr_type;
  code_ptr: abstract_code_ptr_type);
procedure Set_addr_type(addr: addr_type;
  type_ptr: abstract_type_ptr_type);

{***********************************************}
{ routines to set sentinel data types from addr }
{***********************************************}
procedure Set_addr_error(addr: addr_type);


implementation
uses
  errors, stacks, handles, memrefs, get_heap_data, set_heap_data, get_data,
  interpreter;


{**************************************************}
{ routines to set and get data from stack and heap }
{**************************************************}


procedure Set_addr_data(addr: addr_type;
  data: data_type);
begin
  case addr.kind of

    stack_index_addr:
      begin
        if addr.stack_index <> 0 then
          Set_global_stack(addr.stack_index, data)
        else
          Runtime_error('Can not assign a nil variable.');
      end;

    handle_heap_addr:
      begin
        if addr.handle <> 0 then
          Set_handle_data(addr.handle, addr.handle_index, data)
        else
          Runtime_error('Can not assign a nil array.');
      end;

    memref_heap_addr:
      begin
        if addr.memref <> 0 then
          Set_memref_data(addr.memref, addr.memref_index, data)
        else
          Runtime_error('Can not assign a nil struct or object.');
      end;

  end;
end; {procedure Set_addr_data}


procedure Set_string(handle: handle_type;
  str: string_type);
var
  str_index, counter: heap_index_type;
  ch: char;
begin
  str_index := Get_handle_heap_index(handle, 1);
  for counter := 0 to (length(str) - 1) do
    begin
      ch := str[counter];
      Set_handle_char(handle, str_index + counter, ch);
    end;
end; {procedure Set_string}


procedure Free_addr(var addr: addr_type);
begin
  case addr.kind of

    stack_index_addr:
      ;

    handle_heap_addr:
      if addr.handle <> 0 then
        Free_handle(addr.handle);

    memref_heap_addr:
      if addr.memref <> 0 then
        Free_memref(addr.memref);

  end;
end; {procedure Free_addr}


{************************************************}
{ routines to set primitive data types from addr }
{************************************************}


procedure Set_addr_boolean(addr: addr_type;
  boolean_val: boolean_type);
var
  data: data_type;
begin
  data.kind := boolean_data;
  data.boolean_val := boolean_val;
  Set_addr_data(addr, data);
end; {procedure Set_addr_boolean}


procedure Set_addr_char(addr: addr_type;
  char_val: char_type);
var
  data: data_type;
begin
  data.kind := char_data;
  data.char_val := char_val;
  Set_addr_data(addr, data);
end; {procedure Set_addr_char}


procedure Set_addr_byte(addr: addr_type;
  byte_val: byte_type);
var
  data: data_type;
begin
  data.kind := byte_data;
  data.byte_val := byte_val;
  Set_addr_data(addr, data);
end; {procedure Set_addr_byte}


procedure Set_addr_short(addr: addr_type;
  short_val: short_type);
var
  data: data_type;
begin
  data.kind := short_data;
  data.short_val := short_val;
  Set_addr_data(addr, data);
end; {procedure Set_addr_short}


procedure Set_addr_integer(addr: addr_type;
  integer_val: integer_type);
var
  data: data_type;
begin
  data.kind := integer_data;
  data.integer_val := integer_val;
  Set_addr_data(addr, data);
end; {procedure Set_addr_integer}


procedure Set_addr_long(addr: addr_type;
  long_val: long_type);
var
  data: data_type;
begin
  data.kind := long_data;
  data.long_val := long_val;
  Set_addr_data(addr, data);
end; {procedure Set_addr_long}


procedure Set_addr_scalar(addr: addr_type;
  scalar_val: scalar_type);
var
  data: data_type;
begin
  data.kind := scalar_data;
  data.scalar_val := scalar_val;
  Set_addr_data(addr, data);
end; {procedure Set_addr_scalar}


procedure Set_addr_double(addr: addr_type;
  double_val: double_type);
var
  data: data_type;
begin
  data.kind := double_data;
  data.double_val := double_val;
  Set_addr_data(addr, data);
end; {procedure Set_addr_double}


{***********************************************}
{ routines to set compound data types from addr }
{***********************************************}


procedure Set_addr_complex(addr: addr_type;
  complex_val: complex_type);
begin
  Set_addr_scalar(addr, complex_val.a);
  Set_addr_scalar(Get_offset_addr(addr, 1), complex_val.b);
end; {procedure Set_addr_complex}


procedure Set_addr_vector(addr: addr_type;
  vector_val: vector_type);
begin
  Set_addr_scalar(addr, vector_val.x);
  Set_addr_scalar(Get_offset_addr(addr, 1), vector_val.y);
  Set_addr_scalar(Get_offset_addr(addr, 2), vector_val.z);
end; {procedure Set_addr_vector}


procedure Set_addr_color(addr: addr_type;
  color_val: color_type);
begin
  Set_addr_scalar(addr, color_val.r);
  Set_addr_scalar(Get_offset_addr(addr, 1), color_val.g);
  Set_addr_scalar(Get_offset_addr(addr, 2), color_val.b);
end; {procedure Set_addr_color}


procedure Set_addr_string(addr: addr_type;
  str: string_type);
var
  handle: handle_type;
begin
  handle := Get_addr_handle(addr);
  Set_string(handle, str);
end; {procedure Set_addr_string}


procedure Set_addr_addr(addr: addr_type;
  addr_val: addr_type);
begin
  case addr_val.kind of

    {*****************}
    { stack addresses }
    {*****************}
    stack_index_addr:
      Set_addr_stack_index(addr, addr_val.stack_index);

    {*************************}
    { relative heap addresses }
    {*************************}
    heap_index_addr:
      Set_addr_heap_index(addr, addr_val.heap_index);

    {*************************}
    { absolute heap addresses }
    {*************************}
    handle_heap_addr:
      begin
        Set_addr_handle(addr, addr_val.handle);
        Set_addr_heap_index(Get_offset_addr(addr, 1), addr_val.handle_index);
      end;
    memref_heap_addr:
      begin
        Set_addr_memref(addr, addr_val.memref);
        Set_addr_heap_index(Get_offset_addr(addr, 1), addr_val.memref_index);
      end;

  end; {case}
end; {procedure Set_addr_addr}


{**********************************************}
{ routines to set address data types from addr }
{**********************************************}


procedure Set_addr_stack_index(addr: addr_type;
  stack_index: stack_index_type);
var
  data: data_type;
begin
  data.kind := stack_index_data;
  data.stack_index := stack_index;
  Set_addr_data(addr, data);
end; {procedure Set_addr_stack_index}


procedure Set_addr_heap_index(addr: addr_type;
  heap_index: heap_index_type);
var
  data: data_type;
begin
  data.kind := heap_index_data;
  data.heap_index := heap_index;
  Set_addr_data(addr, data);
end; {procedure Set_addr_heap_index}


procedure Set_addr_handle(addr: addr_type;
  handle: handle_type);
var
  data: data_type;
begin
  data.kind := handle_data;
  data.handle := handle;
  Set_addr_data(addr, data);
end; {procedure Set_addr_handle}


procedure Set_addr_memref(addr: addr_type;
  memref: memref_type);
var
  data: data_type;
begin
  data.kind := memref_data;
  data.memref := memref;
  Set_addr_data(addr, data);
end; {procedure Set_addr_memref}


{**********************************************}
{ routines to set pointer data types from addr }
{**********************************************}


procedure Set_addr_code(addr: addr_type;
  code_ptr: abstract_code_ptr_type);
begin
  Set_addr_data(addr, Code_to_data(code_ptr));
end; {procedure Set_addr_code}


procedure Set_addr_type(addr: addr_type;
  type_ptr: abstract_type_ptr_type);
begin
  Set_addr_data(addr, Type_to_data(type_ptr));
end; {procedure Set_addr_type}


{***********************************************}
{ routines to set sentinel data types from addr }
{***********************************************}


procedure Set_addr_error(addr: addr_type);
var
  data: data_type;
begin
  data.kind := error_data;
  Set_addr_data(addr, data);
end; {procedure Set_addr_error}


end.
