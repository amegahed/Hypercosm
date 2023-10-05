unit get_stack_data;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            get_stack_data             3d       }
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
{ routines to get primitive data types by stack addr }
{****************************************************}
function Get_stack_boolean(stack_addr: stack_addr_type): boolean_type;
function Get_stack_char(stack_addr: stack_addr_type): char_type;

function Get_stack_byte(stack_addr: stack_addr_type): byte_type;
function Get_stack_short(stack_addr: stack_addr_type): short_type;

function Get_stack_integer(stack_addr: stack_addr_type): integer_type;
function Get_stack_long(stack_addr: stack_addr_type): long_type;

function Get_stack_scalar(stack_addr: stack_addr_type): scalar_type;
function Get_stack_double(stack_addr: stack_addr_type): double_type;

{***************************************************}
{ routines to get compound data types by stack addr }
{***************************************************}
function Get_stack_complex(stack_addr: stack_addr_type): complex_type;
function Get_stack_vector(stack_addr: stack_addr_type): vector_type;
function Get_stack_color(stack_addr: stack_addr_type): color_type;

function Get_stack_string(stack_addr: stack_addr_type): string_type;
function Get_stack_addr(stack_addr: stack_addr_type): addr_type;

{**************************************************}
{ routines to get address data types by stack addr }
{**************************************************}
function Get_stack_stack_index(stack_addr: stack_addr_type): stack_index_type;
function Get_stack_heap_index(stack_addr: stack_addr_type): heap_index_type;

function Get_stack_handle(stack_addr: stack_addr_type): handle_type;
function Get_stack_memref(stack_addr: stack_addr_type): memref_type;

{**************************************************}
{ routines to get pointer data types by stack addr }
{**************************************************}
function Get_stack_code(stack_addr: stack_addr_type): abstract_code_ptr_type;
function Get_stack_type(stack_addr: stack_addr_type): abstract_type_ptr_type;

{*************************************************************}
{ routines to get primitive data types from local stack frame }
{*************************************************************}
function Get_local_boolean(index: stack_index_type): boolean_type;
function Get_local_char(index: stack_index_type): char_type;

function Get_local_byte(index: stack_index_type): byte_type;
function Get_local_short(index: stack_index_type): short_type;

function Get_local_integer(index: stack_index_type): integer_type;
function Get_local_long(index: stack_index_type): long_type;

function Get_local_scalar(index: stack_index_type): scalar_type;
function Get_local_double(index: stack_index_type): double_type;

{************************************************************}
{ routines to get compound data types from local stack frame }
{************************************************************}
function Get_local_complex(index: stack_index_type): complex_type;
function Get_local_vector(index: stack_index_type): vector_type;
function Get_local_color(index: stack_index_type): color_type;

function Get_local_string(index: stack_index_type): string_type;
function Get_local_addr(index: stack_index_type): addr_type;

{***********************************************************}
{ routines to get address data types from local stack frame }
{***********************************************************}
function Get_local_stack_index(index: stack_index_type): stack_index_type;
function Get_local_heap_index(index: heap_index_type): heap_index_type;

function Get_local_handle(index: stack_index_type): handle_type;
function Get_local_memref(index: stack_index_type): memref_type;

{***********************************************************}
{ routines to get pointer data types from local stack frame }
{***********************************************************}
function Get_local_code(index: stack_index_type): abstract_code_ptr_type;
function Get_local_type(index: stack_index_type): abstract_type_ptr_type;

{*****************************************************}
{ routines to get primitive data types by stack index }
{*****************************************************}
function Get_global_boolean(index: stack_index_type): boolean_type;
function Get_global_char(index: stack_index_type): char_type;

function Get_global_byte(index: stack_index_type): byte_type;
function Get_global_short(index: stack_index_type): short_type;

function Get_global_integer(index: stack_index_type): integer_type;
function Get_global_long(index: stack_index_type): long_type;

function Get_global_scalar(index: stack_index_type): scalar_type;
function Get_global_double(index: stack_index_type): double_type;

{****************************************************}
{ routines to get compound data types by stack index }
{****************************************************}
function Get_global_complex(index: stack_index_type): complex_type;
function Get_global_vector(index: stack_index_type): vector_type;
function Get_global_color(index: stack_index_type): color_type;

function Get_global_string(index: stack_index_type): string_type;
function Get_global_addr(index: stack_index_type): addr_type;

{***************************************************}
{ routines to get address data types by stack index }
{***************************************************}
function Get_global_stack_index(index: stack_index_type): stack_index_type;
function Get_global_heap_index(index: stack_index_type): heap_index_type;

function Get_global_handle(index: stack_index_type): handle_type;
function Get_global_memref(index: stack_index_type): memref_type;

{***************************************************}
{ routines to get pointer data types by stack index }
{***************************************************}
function Get_global_code(index: stack_index_type): abstract_code_ptr_type;
function Get_global_type(index: stack_index_type): abstract_type_ptr_type;


implementation
uses
  errors, get_data, interpreter;


{****************************************************}
{ routines to get primitive data types by stack addr }
{****************************************************}


function Get_stack_boolean(stack_addr: stack_addr_type): boolean_type;
var
  data: data_type;
begin
  data := Get_stack(stack_addr);
  if data.kind <> boolean_data then
    Runtime_error('Can not access uninitialized boolean.');
  Get_stack_boolean := data.boolean_val;
end; {function Get_stack_boolean}


function Get_stack_char(stack_addr: stack_addr_type): char_type;
var
  data: data_type;
begin
  data := Get_stack(stack_addr);
  if data.kind <> char_data then
    Runtime_error('Can not access uninitialized char.');
  Get_stack_char := data.char_val;
end; {function Get_stack_char}


function Get_stack_byte(stack_addr: stack_addr_type): byte_type;
var
  data: data_type;
begin
  data := Get_stack(stack_addr);
  if data.kind <> byte_data then
    Runtime_error('Can not access uninitialized byte.');
  Get_stack_byte := data.byte_val;
end; {function Get_stack_byte}


function Get_stack_short(stack_addr: stack_addr_type): short_type;
var
  data: data_type;
begin
  data := Get_stack(stack_addr);
  if data.kind <> short_data then
    Runtime_error('Can not access uninitialized short.');
  Get_stack_short := data.short_val;
end; {function Get_stack_short}


function Get_stack_integer(stack_addr: stack_addr_type): integer_type;
var
  data: data_type;
begin
  data := Get_stack(stack_addr);
  if data.kind <> integer_data then
    Runtime_error('Can not access uninitialized integer.');
  Get_stack_integer := data.integer_val;
end; {function Get_stack_integer}


function Get_stack_long(stack_addr: stack_addr_type): long_type;
var
  data: data_type;
begin
  data := Get_stack(stack_addr);
  if data.kind <> long_data then
    Runtime_error('Can not access uninitialized long.');
  Get_stack_long := data.long_val;
end; {function Get_stack_long}


function Get_stack_scalar(stack_addr: stack_addr_type): scalar_type;
var
  data: data_type;
begin
  data := Get_stack(stack_addr);
  if data.kind <> scalar_data then
    Runtime_error('Can not access uninitialized scalar.');
  Get_stack_scalar := data.scalar_val;
end; {function Get_stack_scalar}


function Get_stack_double(stack_addr: stack_addr_type): double_type;
var
  data: data_type;
begin
  data := Get_stack(stack_addr);
  if data.kind <> double_data then
    Runtime_error('Can not access uninitialized double.');
  Get_stack_double := data.double_val;
end; {function Get_stack_double}


{***************************************************}
{ routines to get compound data types by stack addr }
{***************************************************}


function Get_stack_complex(stack_addr: stack_addr_type): complex_type;
var
  complex_val: complex_type;
  stack_index: stack_index_type;
begin
  stack_index := Stack_addr_to_index(stack_addr);
  complex_val.a := Get_global_scalar(stack_index);
  complex_val.b := Get_global_scalar(stack_index + 1);
  Get_stack_complex := complex_val;
end; {function Get_stack_complex}


function Get_stack_vector(stack_addr: stack_addr_type): vector_type;
var
  vector_val: vector_type;
  stack_index: stack_index_type;
begin
  stack_index := Stack_addr_to_index(stack_addr);
  vector_val.x := Get_global_scalar(stack_index);
  vector_val.y := Get_global_scalar(stack_index + 1);
  vector_val.z := Get_global_scalar(stack_index + 2);
  Get_stack_vector := vector_val;
end; {function Get_stack_vector}


function Get_stack_color(stack_addr: stack_addr_type): color_type;
var
  color_val: color_type;
  stack_index: stack_index_type;
begin
  stack_index := Stack_addr_to_index(stack_addr);
  color_val.r := Get_global_scalar(stack_index);
  color_val.g := Get_global_scalar(stack_index + 1);
  color_val.b := Get_global_scalar(stack_index + 2);
  Get_stack_color := color_val;
end; {function Get_stack_color}


function Get_stack_string(stack_addr: stack_addr_type): string_type;
var
  handle: handle_type;
begin
  handle := Get_stack_handle(stack_addr);
  Get_stack_string := Get_string(handle);
end; {function Get_stack_string}


function Get_stack_addr(stack_addr: stack_addr_type): addr_type;
var
  data: data_type;
  addr: addr_type;
  heap_index: heap_index_type;
  stack_index: stack_index_type;
begin
  stack_index := Stack_addr_to_index(stack_addr);
  data := Get_global_stack(stack_index);

  if data.kind = stack_index_data then
    addr := Stack_index_to_addr(data.stack_index)
  else if data.kind = handle_data then
    begin
      heap_index := Get_global_heap_index(stack_index + 1);
      addr := Handle_addr_to_addr(data.handle, heap_index);
    end
  else if data.kind = memref_data then
    begin
      heap_index := Get_global_heap_index(stack_index + 1);
      addr := Memref_addr_to_addr(data.memref, heap_index);
    end
  else
    Error('Can not access uninitialized reference.');

  Get_stack_addr := addr;
end; {function Get_stack_addr}


{**************************************************}
{ routines to get address data types by stack addr }
{**************************************************}


function Get_stack_stack_index(stack_addr: stack_addr_type): stack_index_type;
var
  data: data_type;
begin
  data := Get_stack(stack_addr);
  if data.kind <> stack_index_data then
    Error('Can not access uninitialized stack index.');
  Get_stack_stack_index := data.stack_index;
end; {function Get_stack_stack_index}


function Get_stack_heap_index(stack_addr: stack_addr_type): heap_index_type;
var
  data: data_type;
begin
  data := Get_stack(stack_addr);
  if data.kind <> heap_index_data then
    Error('Can not access uninitialized heap index.');
  Get_stack_heap_index := data.heap_index;
end; {function Get_stack_heap_index}


function Get_stack_handle(stack_addr: stack_addr_type): handle_type;
var
  data: data_type;
begin
  data := Get_stack(stack_addr);
  if data.kind <> handle_data then
    Error('Can not access uninitialized handle.');
  Get_stack_handle := data.handle;
end; {function Get_stack_handle}


function Get_stack_memref(stack_addr: stack_addr_type): memref_type;
var
  data: data_type;
begin
  data := Get_stack(stack_addr);
  if data.kind <> memref_data then
    Error('Can not access uninitialized memref.');
  Get_stack_memref := data.memref;
end; {function Get_stack_memref}


{**************************************************}
{ routines to get pointer data types by stack addr }
{**************************************************}


function Get_stack_code(stack_addr: stack_addr_type): abstract_code_ptr_type;
var
  data: data_type;
begin
  data := Get_stack(stack_addr);
  if data.kind <> code_data then
    Error('Can not access uninitialized reference.');
  Get_stack_code := data.code_ptr;
end; {function Get_stack_code}


function Get_stack_type(stack_addr: stack_addr_type): abstract_type_ptr_type;
var
  data: data_type;
begin
  data := Get_stack(stack_addr);
  if data.kind <> type_data then
    Error('Can not access uninitialized reference.');
  Get_stack_type := data.type_ptr;
end; {function Get_stack_type}


{***********************************************************}
{ routines to get primitive data types from top stack frame }
{***********************************************************}


function Get_local_boolean(index: stack_index_type): boolean_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> boolean_data then
    Runtime_error('Can not access uninitialized local boolean.');
  Get_local_boolean := data.boolean_val;
end; {function Get_local_boolean}


function Get_local_char(index: stack_index_type): char_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> char_data then
    Runtime_error('Can not access uninitialized local char.');
  Get_local_char := data.char_val;
end; {function Get_local_char}


function Get_local_byte(index: stack_index_type): byte_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> byte_data then
    Runtime_error('Can not access uninitialized local byte.');
  Get_local_byte := data.byte_val;
end; {function Get_local_byte}


function Get_local_short(index: stack_index_type): short_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> short_data then
    Runtime_error('Can not access uninitialized local short.');
  Get_local_short := data.short_val;
end; {function Get_local_short}


function Get_local_integer(index: stack_index_type): integer_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> integer_data then
    Runtime_error('Can not access uninitialized local integer.');
  Get_local_integer := data.integer_val;
end; {function Get_local_integer}


function Get_local_long(index: stack_index_type): long_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> long_data then
    Runtime_error('Can not access uninitialized local long.');
  Get_local_long := data.long_val;
end; {function Get_local_long}


function Get_local_scalar(index: stack_index_type): scalar_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> scalar_data then
    Runtime_error('Can not access uninitialized local scalar.');
  Get_local_scalar := data.scalar_val;
end; {function Get_local_scalar}


function Get_local_double(index: stack_index_type): double_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> double_data then
    Runtime_error('Can not access uninitialized local double.');
  Get_local_double := data.double_val;
end; {function Get_local_double}


{**********************************************************}
{ routines to get compound data types from top stack frame }
{**********************************************************}


function Get_local_complex(index: stack_index_type): complex_type;
var
  complex_val: complex_type;
begin
  complex_val.a := Get_local_scalar(index);
  complex_val.b := Get_local_scalar(index + 1);
  Get_local_complex := complex_val;
end; {function Get_local_complex}


function Get_local_vector(index: stack_index_type): vector_type;
var
  vector_val: vector_type;
begin
  vector_val.x := Get_local_scalar(index);
  vector_val.y := Get_local_scalar(index + 1);
  vector_val.z := Get_local_scalar(index + 2);
  Get_local_vector := vector_val;
end; {function Get_local_vector}


function Get_local_color(index: stack_index_type): color_type;
var
  color_val: color_type;
begin
  color_val.r := Get_local_scalar(index);
  color_val.g := Get_local_scalar(index + 1);
  color_val.b := Get_local_scalar(index + 2);
  Get_local_color := color_val;
end; {function Get_local_color}


function Get_local_string(index: stack_index_type): string_type;
var
  str_handle: handle_type;
begin
  str_handle := Get_local_handle(index);
  Get_local_string := Get_string(str_handle);
end; {function Get_local_string}


function Get_local_addr(index: stack_index_type): addr_type;
var
  data: data_type;
  addr: addr_type;
  heap_index: heap_index_type;
begin
  data := Get_local_stack(index);

  if data.kind = stack_index_data then
    addr := Stack_index_to_addr(data.stack_index)
  else if data.kind = handle_data then
    begin
      heap_index := Get_local_heap_index(index + 1);
      addr := Handle_addr_to_addr(data.handle, heap_index);
    end
  else if data.kind = memref_data then
    begin
      heap_index := Get_local_heap_index(index + 1);
      addr := Memref_addr_to_addr(data.memref, heap_index);
    end
  else
    Error('Can not access uninitialized local reference.');

  Get_local_addr := addr;
end; {function Get_local_addr}


{*********************************************************}
{ routines to get address data types from top stack frame }
{*********************************************************}


function Get_local_stack_index(index: stack_index_type): stack_index_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> stack_index_data then
    Error('Can not access uninitialized local stack index.');
  Get_local_stack_index := data.stack_index;
end; {function Get_local_stack_index}


function Get_local_heap_index(index: stack_index_type): stack_index_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> heap_index_data then
    Error('Can not access uninitialized local heap index.');
  Get_local_heap_index := data.heap_index;
end; {function Get_local_heap_index}


function Get_local_handle(index: stack_index_type): handle_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> handle_data then
    Error('Can not access uninitialized local handle.');
  Get_local_handle := data.handle;
end; {function Get_local_handle}


function Get_local_memref(index: stack_index_type): memref_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> memref_data then
    Error('Can not access uninitialized local memref.');
  Get_local_memref := data.memref;
end; {function Get_local_memref}


{*********************************************************}
{ routines to get pointer data types from top stack frame }
{*********************************************************}


function Get_local_code(index: stack_index_type): abstract_code_ptr_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> code_data then
    Error('Can not access uninitialized local reference.');
  Get_local_code := data.code_ptr;
end; {function Get_local_code}


function Get_local_type(index: stack_index_type): abstract_type_ptr_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> type_data then
    Error('Can not access uninitialized local reference.');
  Get_local_type := data.type_ptr;
end; {function Get_local_type}


{*****************************************************}
{ routines to get primitive data types by stack index }
{*****************************************************}


function Get_global_boolean(index: stack_index_type): boolean_type;
var
  data: data_type;
begin
  data := Get_global_stack(index);
  if data.kind <> boolean_data then
    Runtime_error('Can not access uninitialized stack boolean.');
  Get_global_boolean := data.boolean_val;
end; {function Get_global_boolean}


function Get_global_char(index: stack_index_type): char_type;
var
  data: data_type;
begin
  data := Get_global_stack(index);
  if data.kind <> char_data then
    Runtime_error('Can not access uninitialized stack char.');
  Get_global_char := data.char_val;
end; {function Get_global_char}


function Get_global_byte(index: stack_index_type): byte_type;
var
  data: data_type;
begin
  data := Get_global_stack(index);
  if data.kind <> byte_data then
    Runtime_error('Can not access uninitialized stack byte.');
  Get_global_byte := data.byte_val;
end; {function Get_global_byte}


function Get_global_short(index: stack_index_type): short_type;
var
  data: data_type;
begin
  data := Get_global_stack(index);
  if data.kind <> short_data then
    Runtime_error('Can not access uninitialized stack short.');
  Get_global_short := data.short_val;
end; {function Get_global_short}


function Get_global_integer(index: stack_index_type): integer_type;
var
  data: data_type;
begin
  data := Get_global_stack(index);
  if data.kind <> integer_data then
    Runtime_error('Can not access uninitialized stack integer.');
  Get_global_integer := data.integer_val;
end; {function Get_global_integer}


function Get_global_long(index: stack_index_type): long_type;
var
  data: data_type;
begin
  data := Get_global_stack(index);
  if data.kind <> long_data then
    Runtime_error('Can not access uninitialized stack long.');
  Get_global_long := data.long_val;
end; {function Get_global_long}


function Get_global_scalar(index: stack_index_type): scalar_type;
var
  data: data_type;
begin
  data := Get_global_stack(index);
  if data.kind <> scalar_data then
    Runtime_error('Can not access uninitialized stack scalar.');
  Get_global_scalar := data.scalar_val;
end; {function Get_global_scalar}


function Get_global_double(index: stack_index_type): double_type;
var
  data: data_type;
begin
  data := Get_global_stack(index);
  if data.kind <> double_data then
    Runtime_error('Can not access uninitialized stack double.');
  Get_global_double := data.double_val;
end; {function Get_global_double}


{****************************************************}
{ routines to get compound data types by stack index }
{****************************************************}


function Get_global_complex(index: stack_index_type): complex_type;
var
  complex_val: complex_type;
begin
  complex_val.a := Get_global_scalar(index);
  complex_val.b := Get_global_scalar(index + 1);
  Get_global_complex := complex_val;
end; {function Get_global_complex}


function Get_global_vector(index: stack_index_type): vector_type;
var
  vector_val: vector_type;
begin
  vector_val.x := Get_global_scalar(index);
  vector_val.y := Get_global_scalar(index + 1);
  vector_val.z := Get_global_scalar(index + 2);
  Get_global_vector := vector_val;
end; {function Get_global_vector}


function Get_global_color(index: stack_index_type): color_type;
var
  color_val: color_type;
begin
  color_val.r := Get_global_scalar(index);
  color_val.g := Get_global_scalar(index + 1);
  color_val.b := Get_global_scalar(index + 2);
  Get_global_color := color_val;
end; {function Get_global_color}


function Get_global_string(index: stack_index_type): string_type;
var
  str_handle: handle_type;
begin
  str_handle := Get_global_handle(index);
  Get_global_string := Get_string(str_handle);
end; {function Get_global_string}


function Get_global_addr(index: stack_index_type): addr_type;
var
  data: data_type;
  addr: addr_type;
  heap_index: heap_index_type;
begin
  data := Get_global_stack(index);

  if data.kind = stack_index_data then
    addr := Stack_index_to_addr(data.stack_index)
  else if data.kind = handle_data then
    begin
      heap_index := Get_global_heap_index(index + 1);
      addr := Handle_addr_to_addr(data.handle, heap_index);
    end
  else if data.kind = memref_data then
    begin
      heap_index := Get_global_heap_index(index + 1);
      addr := Memref_addr_to_addr(data.memref, heap_index);
    end
  else
    Error('Can not access uninitialized global reference.');

  Get_global_addr := addr;
end; {function Get_global_addr}


{***************************************************}
{ routines to get address data types by stack index }
{***************************************************}


function Get_global_stack_index(index: stack_index_type): stack_index_type;
var
  data: data_type;
begin
  data := Get_global_stack(index);
  if data.kind <> stack_index_data then
    Error('Can not access uninitialized global stack index.');
  Get_global_stack_index := data.stack_index;
end; {function Get_global_stack_index}


function Get_global_heap_index(index: stack_index_type): heap_index_type;
var
  data: data_type;
begin
  data := Get_global_stack(index);
  if data.kind <> heap_index_data then
    Error('Can not access uninitialized global heap index.');
  Get_global_heap_index := data.heap_index;
end; {function Get_global_heap_index}


function Get_global_handle(index: stack_index_type): handle_type;
var
  data: data_type;
begin
  data := Get_global_stack(index);
  if data.kind <> handle_data then
    Error('Can not access uninitialized global handle.');
  Get_global_handle := data.handle;
end; {function Get_global_handle}


function Get_global_memref(index: stack_index_type): memref_type;
var
  data: data_type;
begin
  data := Get_global_stack(index);
  if data.kind <> memref_data then
    Error('Can not access uninitialized global memref.');
  Get_global_memref := data.memref;
end; {function Get_global_memref}


{***************************************************}
{ routines to get pointer data types by stack index }
{***************************************************}


function Get_global_code(index: stack_index_type): abstract_code_ptr_type;
var
  data: data_type;
begin
  data := Get_global_stack(index);
  if data.kind <> code_data then
    Error('Can not access uninitialized reference.');
  Get_global_code := data.code_ptr;
end; {function Get_global_code}


function Get_global_type(index: stack_index_type): abstract_type_ptr_type;
var
  data: data_type;
begin
  data := Get_global_stack(index);
  if data.kind <> type_data then
    Error('Can not access uninitialized reference.');
  Get_global_type := data.type_ptr;
end; {function Get_global_type}


end.
