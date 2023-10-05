unit get_data;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              get_data                 3d       }
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


function Get_addr_data(addr: addr_type): data_type;
function Get_string(handle: handle_type): string_type;
function Clone_addr(addr: addr_type): addr_type;

{************************************************}
{ routines to get primitive data types from addr }
{************************************************}
function Get_addr_boolean(addr: addr_type): boolean_type;
function Get_addr_char(addr: addr_type): char_type;

function Get_addr_byte(addr: addr_type): byte_type;
function Get_addr_short(addr: addr_type): short_type;

function Get_addr_integer(addr: addr_type): integer_type;
function Get_addr_long(addr: addr_type): long_type;

function Get_addr_scalar(addr: addr_type): scalar_type;
function Get_addr_double(addr: addr_type): double_type;

{***********************************************}
{ routines to get compound data types from addr }
{***********************************************}
function Get_addr_complex(addr: addr_type): complex_type;
function Get_addr_vector(addr: addr_type): vector_type;
function Get_addr_color(addr: addr_type): color_type;

function Get_addr_string(addr: addr_type): string_type;
function Get_addr_addr(addr: addr_type): addr_type;

{**********************************************}
{ routines to get address data types from addr }
{**********************************************}
function Get_addr_stack_index(addr: addr_type): stack_index_type;
function Get_addr_heap_index(addr: addr_type): heap_index_type;

function Get_addr_handle(addr: addr_type): handle_type;
function Get_addr_memref(addr: addr_type): memref_type;

{**********************************************}
{ routines to get pointer data types from addr }
{**********************************************}
function Get_addr_code(addr: addr_type): abstract_code_ptr_type;
function Get_addr_type(addr: addr_type): abstract_type_ptr_type;


implementation
uses
  errors, stacks, handles, memrefs, get_heap_data, array_limits, interpreter;


{******************************************}
{ routines to get data from stack and heap }
{******************************************}


function Get_addr_data(addr: addr_type): data_type;
var
  data: data_type;
begin
  {**********************************}
  { retreive data from stack or heap }
  {**********************************}
  if addr.kind in [stack_index_addr, handle_heap_addr, memref_heap_addr] then
    case addr.kind of

      stack_index_addr:
        begin
          if addr.stack_index <> 0 then
            data := Get_global_stack(addr.stack_index)
          else
            Runtime_error('Can not dereference a nil variable.');
        end;

      handle_heap_addr:
        begin
          if addr.handle <> 0 then
            data := Get_handle_data(addr.handle, addr.handle_index)
          else
            Runtime_error('Can not dereference a nil array.');
        end;

      memref_heap_addr:
        begin
          if addr.memref <> 0 then
            data := Get_memref_data(addr.memref, addr.memref_index)
          else
            Runtime_error('Can not dereference a nil struct or object.');
        end;

    end {case}
  else
    Internal_error('Can not get data from heap index.');

  Get_addr_data := data;
end; {function Get_addr_data}


function Get_string(handle: handle_type): string_type;
var
  str_num: integer;
  str_index, counter: heap_index_type;
  str: string_type;
  ch: char;
begin
  str_num := Array_num(handle, 0);
  str_index := Get_handle_heap_index(handle, 1);
  str := '';
  for counter := 0 to (str_num - 1) do
    begin
      ch := Get_handle_char(handle, str_index + counter);
      Append_char_to_str(ch, str);
    end;
  Get_string := str;
end; {function Get_string}


function Clone_addr(addr: addr_type): addr_type;
begin
  if addr.kind in [handle_heap_addr, memref_heap_addr] then
    case addr.kind of

      handle_heap_addr:
        addr.handle := Clone_handle(addr.handle);

      memref_heap_addr:
        addr.memref := Clone_memref(addr.memref);

    end; {case}

  Clone_addr := addr;
end; {function Clone_addr}


{************************************************}
{ routines to get primitive data types from addr }
{************************************************}


function Get_addr_boolean(addr: addr_type): boolean_type;
var
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind <> boolean_data then
    Runtime_error('Can not access uninitialized boolean.');
  Get_addr_boolean := data.boolean_val;
end; {function Get_addr_boolean}


function Get_addr_char(addr: addr_type): char_type;
var
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind <> char_data then
    Runtime_error('Can not access uninitialized char.');
  Get_addr_char := data.char_val;
end; {function Get_addr_char}


function Get_addr_byte(addr: addr_type): byte_type;
var
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind <> byte_data then
    Runtime_error('Can not access uninitialized byte.');
  Get_addr_byte := data.byte_val;
end; {function Get_addr_byte}


function Get_addr_short(addr: addr_type): short_type;
var
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind <> short_data then
    Runtime_error('Can not access uninitialized short.');
  Get_addr_short := data.short_val;
end; {function Get_addr_short}


function Get_addr_integer(addr: addr_type): integer_type;
var
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind <> integer_data then
    Runtime_error('Can not access uninitialized integer.');
  Get_addr_integer := data.integer_val;
end; {function Get_addr_integer}


function Get_addr_long(addr: addr_type): long_type;
var
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind <> long_data then
    Runtime_error('Can not access uninitialized long.');
  Get_addr_long := data.long_val;
end; {function Get_addr_long}


function Get_addr_scalar(addr: addr_type): scalar_type;
var
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind <> scalar_data then
    Runtime_error('Can not access uninitialized scalar.');
  Get_addr_scalar := data.scalar_val;
end; {function Get_addr_scalar}


function Get_addr_double(addr: addr_type): double_type;
var
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind <> double_data then
    Runtime_error('Can not access uninitialized double.');
  Get_addr_double := data.double_val;
end; {function Get_addr_double}


{***********************************************}
{ routines to get compound data types from addr }
{***********************************************}


function Get_addr_complex(addr: addr_type): complex_type;
var
  complex_val: complex_type;
begin
  complex_val.a := Get_addr_scalar(addr);
  complex_val.b := Get_addr_scalar(Get_offset_addr(addr, 1));
  Get_addr_complex := complex_val;
end; {function Get_addr_complex}


function Get_addr_vector(addr: addr_type): vector_type;
var
  vector_val: vector_type;
begin
  vector_val.x := Get_addr_scalar(addr);
  vector_val.y := Get_addr_scalar(Get_offset_addr(addr, 1));
  vector_val.z := Get_addr_scalar(Get_offset_addr(addr, 2));
  Get_addr_vector := vector_val;
end; {function Get_addr_vector}


function Get_addr_color(addr: addr_type): color_type;
var
  color_val: color_type;
begin
  color_val.r := Get_addr_scalar(addr);
  color_val.g := Get_addr_scalar(Get_offset_addr(addr, 1));
  color_val.b := Get_addr_scalar(Get_offset_addr(addr, 2));
  Get_addr_color := color_val;
end; {function Get_addr_color}


function Get_addr_string(addr: addr_type): string_type;
var
  handle: handle_type;
begin
  handle := Get_addr_handle(addr);
  Get_addr_string := Get_string(handle);
end; {function Get_addr_string}


function Get_addr_addr(addr: addr_type): addr_type;
var
  data: data_type;
  heap_index: heap_index_type;
begin
  data := Get_addr_data(addr);

  if data.kind = stack_index_data then
    addr := Stack_index_to_addr(data.stack_index)
  else if data.kind = handle_data then
    begin
      heap_index := Get_addr_heap_index(Get_offset_addr(addr, 1));
      addr := Handle_addr_to_addr(data.handle, heap_index);
    end
  else if data.kind = memref_data then
    begin
      heap_index := Get_addr_heap_index(Get_offset_addr(addr, 1));
      addr := Memref_addr_to_addr(data.memref, heap_index);
    end
  else
    Internal_error('Can not access uninitialized reference.');

  Get_addr_addr := addr;
end; {function Get_addr_addr}


{**********************************************}
{ routines to get address data types from addr }
{**********************************************}


function Get_addr_stack_index(addr: addr_type): stack_index_type;
var
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind <> stack_index_data then
    Internal_error('Can not access uninitialized stack index.');
  Get_addr_stack_index := data.stack_index;
end; {function Get_addr_stack_index}


function Get_addr_heap_index(addr: addr_type): heap_index_type;
var
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind <> heap_index_data then
    Internal_error('Can not access uninitialized heap index.');
  Get_addr_heap_index := data.heap_index;
end; {function Get_addr_heap_index}


function Get_addr_handle(addr: addr_type): handle_type;
var
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind <> handle_data then
    Internal_error('Can not access uninitialized handle.');
  Get_addr_handle := data.handle;
end; {function Get_addr_handle}


function Get_addr_memref(addr: addr_type): memref_type;
var
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind <> memref_data then
    Internal_error('Can not access uninitialized memref.');
  Get_addr_memref := data.memref;
end; {function Get_addr_memref}


{**********************************************}
{ routines to get pointer data types from addr }
{**********************************************}


function Get_addr_code(addr: addr_type): abstract_code_ptr_type;
var
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind <> code_data then
    Internal_error('Can not access uninitialized reference.');
  Get_addr_code := data.code_ptr;
end; {function Get_addr_code}


function Get_addr_type(addr: addr_type): abstract_type_ptr_type;
var
  data: data_type;
begin
  data := Get_addr_data(addr);
  if data.kind <> type_data then
    Internal_error('Can not access uninitialized reference.');
  Get_addr_type := data.type_ptr;
end; {function Get_addr_type}


end.
