unit get_heap_data;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            get_heap_data              3d       }
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


{*******************************************************}
{ routines to get primitive data types from handle heap }
{*******************************************************}
function Get_handle_boolean(handle: handle_type;
  index: heap_index_type): boolean_type;
function Get_handle_char(handle: handle_type;
  index: heap_index_type): char_type;

function Get_handle_byte(handle: handle_type;
  index: heap_index_type): byte_type;
function Get_handle_short(handle: handle_type;
  index: heap_index_type): short_type;

function Get_handle_integer(handle: handle_type;
  index: heap_index_type): integer_type;
function Get_handle_long(handle: handle_type;
  index: heap_index_type): long_type;

function Get_handle_scalar(handle: handle_type;
  index: heap_index_type): scalar_type;
function Get_handle_double(handle: handle_type;
  index: heap_index_type): double_type;

{******************************************************}
{ routines to get compound data types from handle heap }
{******************************************************}
function Get_handle_complex(handle: handle_type;
  index: heap_index_type): complex_type;
function Get_handle_vector(handle: handle_type;
  index: heap_index_type): vector_type;
function Get_handle_color(handle: handle_type;
  index: heap_index_type): color_type;

function Get_handle_string(handle: handle_type;
  index: heap_index_type): string_type;
function Get_handle_addr(handle: handle_type;
  index: heap_index_type): addr_type;

{*****************************************************}
{ routines to get address data types from handle heap }
{*****************************************************}
function Get_handle_stack_index(handle: handle_type;
  index: heap_index_type): stack_index_type;
function Get_handle_heap_index(handle: handle_type;
  index: heap_index_type): heap_index_type;

function Get_handle_handle(handle: handle_type;
  index: heap_index_type): handle_type;
function Get_handle_memref(handle: handle_type;
  index: heap_index_type): memref_type;

{*****************************************************}
{ routines to get pointer data types from handle heap }
{*****************************************************}
function Get_handle_code(handle: handle_type;
  index: heap_index_type): abstract_code_ptr_type;
function Get_handle_type(handle: handle_type;
  index: heap_index_type): abstract_type_ptr_type;

{*******************************************************}
{ routines to get primitive data types from memref heap }
{*******************************************************}
function Get_memref_boolean(memref: memref_type;
  index: heap_index_type): boolean_type;
function Get_memref_char(memref: memref_type;
  index: heap_index_type): char_type;

function Get_memref_byte(memref: memref_type;
  index: heap_index_type): byte_type;
function Get_memref_short(memref: memref_type;
  index: heap_index_type): short_type;

function Get_memref_integer(memref: memref_type;
  index: heap_index_type): integer_type;
function Get_memref_long(memref: memref_type;
  index: heap_index_type): long_type;

function Get_memref_scalar(memref: memref_type;
  index: heap_index_type): scalar_type;
function Get_memref_double(memref: memref_type;
  index: heap_index_type): double_type;

{******************************************************}
{ routines to get compound data types from memref heap }
{******************************************************}
function Get_memref_complex(memref: memref_type;
  index: heap_index_type): complex_type;
function Get_memref_vector(memref: memref_type;
  index: heap_index_type): vector_type;
function Get_memref_color(memref: memref_type;
  index: heap_index_type): color_type;

function Get_memref_string(memref: memref_type;
  index: heap_index_type): string_type;
function Get_memref_addr(memref: memref_type;
  index: heap_index_type): addr_type;

{*****************************************************}
{ routines to get address data types from memref heap }
{*****************************************************}
function Get_memref_stack_index(memref: memref_type;
  index: heap_index_type): stack_index_type;
function Get_memref_heap_index(memref: memref_type;
  index: heap_index_type): heap_index_type;

function Get_memref_handle(memref: memref_type;
  index: heap_index_type): handle_type;
function Get_memref_memref(memref: memref_type;
  index: heap_index_type): memref_type;

{*****************************************************}
{ routines to get pointer data types from memref heap }
{*****************************************************}
function Get_memref_code(memref: memref_type;
  index: heap_index_type): abstract_code_ptr_type;
function Get_memref_type(memref: memref_type;
  index: heap_index_type): abstract_type_ptr_type;


implementation
uses
  errors, handles, memrefs, get_data, interpreter;


{*******************************************************}
{ routines to get primitive data types from handle heap }
{*******************************************************}


function Get_handle_boolean(handle: handle_type;
  index: heap_index_type): boolean_type;
var
  data: data_type;
begin
  data := Get_handle_data(handle, index);
  if data.kind <> boolean_data then
    Runtime_error('Can not access uninitialized boolean element.');
  Get_handle_boolean := data.boolean_val;
end; {function Get_handle_boolean}


function Get_handle_char(handle: handle_type;
  index: heap_index_type): char_type;
var
  data: data_type;
begin
  data := Get_handle_data(handle, index);
  if data.kind <> char_data then
    Runtime_error('Can not access uninitialized char element.');
  Get_handle_char := data.char_val;
end; {function Get_handle_char}


function Get_handle_byte(handle: handle_type;
  index: heap_index_type): byte_type;
var
  data: data_type;
begin
  data := Get_handle_data(handle, index);
  if data.kind <> byte_data then
    Runtime_error('Can not access uninitialized byte element.');
  Get_handle_byte := data.byte_val;
end; {function Get_handle_byte}


function Get_handle_short(handle: handle_type;
  index: heap_index_type): short_type;
var
  data: data_type;
begin
  data := Get_handle_data(handle, index);
  if data.kind <> short_data then
    Runtime_error('Can not access uninitialized short element.');
  Get_handle_short := data.short_val;
end; {function Get_handle_short}


function Get_handle_integer(handle: handle_type;
  index: heap_index_type): integer_type;
var
  data: data_type;
begin
  data := Get_handle_data(handle, index);
  if data.kind <> integer_data then
    Runtime_error('Can not access uninitialized integer element.');
  Get_handle_integer := data.integer_val;
end; {function Get_handle_integer}


function Get_handle_long(handle: handle_type;
  index: heap_index_type): long_type;
var
  data: data_type;
begin
  data := Get_handle_data(handle, index);
  if data.kind <> long_data then
    Runtime_error('Can not access uninitialized long element.');
  Get_handle_long := data.long_val;
end; {function Get_handle_long}


function Get_handle_scalar(handle: handle_type;
  index: heap_index_type): scalar_type;
var
  data: data_type;
begin
  data := Get_handle_data(handle, index);
  if data.kind <> scalar_data then
    Runtime_error('Can not access uninitialized scalar element.');
  Get_handle_scalar := data.scalar_val;
end; {function Get_handle_scalar}


function Get_handle_double(handle: handle_type;
  index: heap_index_type): double_type;
var
  data: data_type;
begin
  data := Get_handle_data(handle, index);
  if data.kind <> double_data then
    Runtime_error('Can not access uninitialized double element.');
  Get_handle_double := data.double_val;
end; {function Get_handle_double}


{******************************************************}
{ routines to get compound data types from handle heap }
{******************************************************}


function Get_handle_complex(handle: handle_type;
  index: heap_index_type): complex_type;
var
  complex_val: complex_type;
begin
  complex_val.a := Get_handle_scalar(handle, index);
  complex_val.b := Get_handle_scalar(handle, index + 1);
  Get_handle_complex := complex_val;
end; {function Get_handle_complex}


function Get_handle_vector(handle: handle_type;
  index: heap_index_type): vector_type;
var
  vector_val: vector_type;
begin
  vector_val.x := Get_handle_scalar(handle, index);
  vector_val.y := Get_handle_scalar(handle, index + 1);
  vector_val.z := Get_handle_scalar(handle, index + 2);
  Get_handle_vector := vector_val;
end; {function Get_handle_vector}


function Get_handle_color(handle: handle_type;
  index: heap_index_type): color_type;
var
  color_val: color_type;
begin
  color_val.r := Get_handle_scalar(handle, index);
  color_val.g := Get_handle_scalar(handle, index + 1);
  color_val.b := Get_handle_scalar(handle, index + 2);
  Get_handle_color := color_val;
end; {function Get_handle_color}


function Get_handle_string(handle: handle_type;
  index: heap_index_type): string_type;
var
  str_handle: handle_type;
begin
  str_handle := Get_handle_handle(handle, index);
  Get_handle_string := Get_string(str_handle);
end; {function Get_handle_string}


function Get_handle_addr(handle: handle_type;
  index: heap_index_type): addr_type;
var
  data: data_type;
  addr: addr_type;
  heap_index: heap_index_type;
begin
  data := Get_handle_data(handle, index);

  if data.kind = stack_index_data then
    addr := Stack_index_to_addr(data.stack_index)
  else if data.kind = handle_data then
    begin
      heap_index := Get_handle_heap_index(handle, index + 1);
      addr := Handle_addr_to_addr(data.handle, heap_index);
    end
  else if data.kind = memref_data then
    begin
      heap_index := Get_handle_heap_index(handle, index + 1);
      addr := Memref_addr_to_addr(data.memref, heap_index);
    end
  else
    Error('Can not access uninitialized reference element.');

  Get_handle_addr := addr;
end; {function Get_handle_addr}


{*****************************************************}
{ routines to get address data types from handle heap }
{*****************************************************}


function Get_handle_stack_index(handle: handle_type;
  index: heap_index_type): stack_index_type;
var
  data: data_type;
begin
  data := Get_handle_data(handle, index);
  if data.kind <> stack_index_data then
    Error('Can not access uninitialized stack index element.');
  Get_handle_stack_index := data.stack_index;
end; {function Get_handle_stack_index}


function Get_handle_heap_index(handle: handle_type;
  index: heap_index_type): heap_index_type;
var
  data: data_type;
begin
  data := Get_handle_data(handle, index);
  if data.kind <> heap_index_data then
    Error('Can not access uninitialized heap index element.');
  Get_handle_heap_index := data.heap_index;
end; {function Get_handle_heap_index}


function Get_handle_handle(handle: handle_type;
  index: heap_index_type): handle_type;
var
  data: data_type;
begin
  data := Get_handle_data(handle, index);
  if data.kind <> handle_data then
    Error('Can not access uninitialized handle element.');
  Get_handle_handle := data.handle;
end; {function Get_handle_handle}


function Get_handle_memref(handle: handle_type;
  index: heap_index_type): memref_type;
var
  data: data_type;
begin
  data := Get_handle_data(handle, index);
  if data.kind <> memref_data then
    Error('Can not access uninitialized memref element.');
  Get_handle_memref := data.memref;
end; {function Get_handle_memref}


{*****************************************************}
{ routines to get pointer data types from handle heap }
{*****************************************************}


function Get_handle_code(handle: handle_type;
  index: heap_index_type): abstract_code_ptr_type;
var
  data: data_type;
begin
  data := Get_handle_data(handle, index);
  if data.kind <> code_data then
    Error('Can not access uninitialized reference element.');
  Get_handle_code := data.code_ptr;
end; {function Get_handle_code}


function Get_handle_type(handle: handle_type;
  index: heap_index_type): abstract_type_ptr_type;
var
  data: data_type;
begin
  data := Get_handle_data(handle, index);
  if data.kind <> type_data then
    Error('Can not access uninitialized reference element.');
  Get_handle_type := data.type_ptr;
end; {function Get_handle_type}


{*******************************************************}
{ routines to get primitive data types from memref heap }
{*******************************************************}


function Get_memref_boolean(memref: memref_type;
  index: heap_index_type): boolean_type;
var
  data: data_type;
begin
  data := Get_memref_data(memref, index);
  if data.kind <> boolean_data then
    Error('Can not access uninitialized boolean field.');
  Get_memref_boolean := data.boolean_val;
end; {function Get_memref_boolean}


function Get_memref_char(memref: memref_type;
  index: heap_index_type): char_type;
var
  data: data_type;
begin
  data := Get_memref_data(memref, index);
  if data.kind <> char_data then
    Error('Can not access uninitialized char field.');
  Get_memref_char := data.char_val;
end; {function Get_memref_char}


function Get_memref_byte(memref: memref_type;
  index: heap_index_type): byte_type;
var
  data: data_type;
begin
  data := Get_memref_data(memref, index);
  if data.kind <> byte_data then
    Error('Can not access uninitialized byte field.');
  Get_memref_byte := data.byte_val;
end; {function Get_memref_byte}


function Get_memref_short(memref: memref_type;
  index: heap_index_type): short_type;
var
  data: data_type;
begin
  data := Get_memref_data(memref, index);
  if data.kind <> short_data then
    Error('Can not access uninitialized short field.');
  Get_memref_short := data.short_val;
end; {function Get_memref_short}


function Get_memref_integer(memref: memref_type;
  index: heap_index_type): integer_type;
var
  data: data_type;
begin
  data := Get_memref_data(memref, index);
  if data.kind <> integer_data then
    Error('Can not access uninitialized integer field.');
  Get_memref_integer := data.integer_val;
end; {function Get_memref_integer}


function Get_memref_long(memref: memref_type;
  index: heap_index_type): long_type;
var
  data: data_type;
begin
  data := Get_memref_data(memref, index);
  if data.kind <> long_data then
    Error('Can not access uninitialized long field.');
  Get_memref_long := data.long_val;
end; {function Get_memref_long}


function Get_memref_scalar(memref: memref_type;
  index: heap_index_type): scalar_type;
var
  data: data_type;
begin
  data := Get_memref_data(memref, index);
  if data.kind <> scalar_data then
    Error('Can not access uninitialized scalar field.');
  Get_memref_scalar := data.scalar_val;
end; {function Get_memref_scalar}


function Get_memref_double(memref: memref_type;
  index: heap_index_type): double_type;
var
  data: data_type;
begin
  data := Get_memref_data(memref, index);
  if data.kind <> double_data then
    Error('Can not access uninitialized double field.');
  Get_memref_double := data.double_val;
end; {function Get_memref_double}


{******************************************************}
{ routines to get compound data types from memref heap }
{******************************************************}


function Get_memref_complex(memref: memref_type;
  index: heap_index_type): complex_type;
var
  complex_val: complex_type;
begin
  complex_val.a := Get_memref_scalar(memref, index);
  complex_val.b := Get_memref_scalar(memref, index + 1);
  Get_memref_complex := complex_val;
end; {function Get_memref_complex}


function Get_memref_vector(memref: memref_type;
  index: heap_index_type): vector_type;
var
  vector_val: vector_type;
begin
  vector_val.x := Get_memref_scalar(memref, index);
  vector_val.y := Get_memref_scalar(memref, index + 1);
  vector_val.z := Get_memref_scalar(memref, index + 2);
  Get_memref_vector := vector_val;
end; {function Get_memref_vector}


function Get_memref_color(memref: memref_type;
  index: heap_index_type): color_type;
var
  color_val: color_type;
begin
  color_val.r := Get_memref_scalar(memref, index);
  color_val.g := Get_memref_scalar(memref, index + 1);
  color_val.b := Get_memref_scalar(memref, index + 2);
  Get_memref_color := color_val;
end; {function Get_memref_color}


function Get_memref_string(memref: memref_type;
  index: heap_index_type): string_type;
var
  str_handle: handle_type;
begin
  str_handle := Get_memref_handle(memref, index);
  Get_memref_string := Get_string(str_handle);
end; {function Get_memref_string}


function Get_memref_addr(memref: memref_type;
  index: heap_index_type): addr_type;
var
  data: data_type;
  addr: addr_type;
  heap_index: heap_index_type;
begin
  data := Get_memref_data(memref, index);

  if data.kind = stack_index_data then
    addr := Stack_index_to_addr(data.stack_index)
  else if data.kind = handle_data then
    begin
      heap_index := Get_memref_heap_index(memref, index + 1);
      addr := Handle_addr_to_addr(data.handle, heap_index);
    end
  else if data.kind = memref_data then
    begin
      heap_index := Get_memref_heap_index(memref, index + 1);
      addr := Memref_addr_to_addr(data.memref, heap_index);
    end
  else
    Error('Can not access uninitialized reference field.');

  Get_memref_addr := addr;
end; {function Get_memref_addr}


{*****************************************************}
{ routines to get address data types from memref heap }
{*****************************************************}


function Get_memref_stack_index(memref: memref_type;
  index: heap_index_type): stack_index_type;
var
  data: data_type;
begin
  data := Get_memref_data(memref, index);
  if data.kind <> stack_index_data then
    Error('Can not access uninitialized stack index field.');
  Get_memref_stack_index := data.stack_index;
end; {function Get_memref_stack_index}


function Get_memref_heap_index(memref: memref_type;
  index: heap_index_type): stack_index_type;
var
  data: data_type;
begin
  data := Get_memref_data(memref, index);
  if data.kind <> heap_index_data then
    Error('Can not access uninitialized heap index field.');
  Get_memref_heap_index := data.heap_index;
end; {function Get_memref_heap_index}


function Get_memref_handle(memref: memref_type;
  index: heap_index_type): handle_type;
var
  data: data_type;
begin
  data := Get_memref_data(memref, index);
  if data.kind <> handle_data then
    Error('Can not access uninitialized handle field.');
  Get_memref_handle := data.handle;
end; {function Get_memref_handle}


function Get_memref_memref(memref: memref_type;
  index: heap_index_type): memref_type;
var
  data: data_type;
begin
  data := Get_memref_data(memref, index);
  if data.kind <> memref_data then
    Error('Can not access uninitialized memref field.');
  Get_memref_memref := data.memref;
end; {function Get_memref_memref}


{*****************************************************}
{ routines to get pointer data types from memref heap }
{*****************************************************}


function Get_memref_code(memref: memref_type;
  index: heap_index_type): abstract_code_ptr_type;
var
  data: data_type;
begin
  data := Get_memref_data(memref, index);
  if data.kind <> code_data then
    Error('Can not access uninitialized reference field.');
  Get_memref_code := data.code_ptr;
end; {function Get_memref_code}


function Get_memref_type(memref: memref_type;
  index: heap_index_type): abstract_type_ptr_type;
var
  data: data_type;
begin
  data := Get_memref_data(memref, index);
  if data.kind <> type_data then
    Error('Can not access uninitialized reference field.');
  Get_memref_type := data.type_ptr;
end; {function Get_memref_type}


end.
