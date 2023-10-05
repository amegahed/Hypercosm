unit get_params;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             get_params                3d       }
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
  strings, complex_numbers, vectors, colors, data_types, addr_types, data;


{*************************************************************}
{ routines to get primitive parameters from local stack frame }
{*************************************************************}
function Get_boolean_param(var index: stack_index_type): boolean_type;
function Get_char_param(var index: stack_index_type): char_type;

function Get_byte_param(var index: stack_index_type): byte_type;
function Get_short_param(var index: stack_index_type): short_type;

function Get_integer_param(var index: stack_index_type): integer_type;
function Get_long_param(var index: stack_index_type): long_type;

function Get_scalar_param(var index: stack_index_type): scalar_type;
function Get_double_param(var index: stack_index_type): double_type;

{************************************************************}
{ routines to get compound parameters from local stack frame }
{************************************************************}
function Get_complex_param(var index: stack_index_type): complex_type;
function Get_vector_param(var index: stack_index_type): vector_type;
function Get_color_param(var index: stack_index_type): color_type;

function Get_string_param(var index: stack_index_type): string_type;
function Get_addr_param(var index: stack_index_type): addr_type;

{***********************************************************}
{ routines to get address parameters from local stack frame }
{***********************************************************}
function Get_stack_index_param(var index: stack_index_type): stack_index_type;
function Get_heap_index_param(var index: heap_index_type): heap_index_type;

function Get_handle_param(var index: stack_index_type): handle_type;
function Get_memref_param(var index: stack_index_type): memref_type;

{***********************************************************}
{ routines to get pointer data types from local stack frame }
{***********************************************************}
function Get_code_param(var index: stack_index_type): abstract_code_ptr_type;
function Get_type_param(var index: stack_index_type): abstract_type_ptr_type;


implementation
uses
  errors, stacks, get_data, get_stack_data, interpreter;


{***********************************************************}
{ routines to get primitive parameters from top stack frame }
{***********************************************************}


function Get_boolean_param(var index: stack_index_type): boolean_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> boolean_data then
    Runtime_error('Can not access uninitialized boolean parameter.');
  index := index + 1;
  Get_boolean_param := data.boolean_val;
end; {function Get_boolean_param}


function Get_char_param(var index: stack_index_type): char_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> char_data then
    Runtime_error('Can not access uninitialized char parameter.');
  index := index + 1;
  Get_char_param := data.char_val;
end; {function Get_char_param}


function Get_byte_param(var index: stack_index_type): byte_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> byte_data then
    Runtime_error('Can not access uninitialized byte parameter.');
  index := index + 1;
  Get_byte_param := data.byte_val;
end; {function Get_byte_param}


function Get_short_param(var index: stack_index_type): short_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> short_data then
    Runtime_error('Can not access uninitialized short parameter.');
  index := index + 1;
  Get_short_param := data.short_val;
end; {function Get_short_param}


function Get_integer_param(var index: stack_index_type): integer_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> integer_data then
    Runtime_error('Can not access uninitialized integer parameter.');
  index := index + 1;
  Get_integer_param := data.integer_val;
end; {function Get_integer_param}


function Get_long_param(var index: stack_index_type): long_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> long_data then
    Runtime_error('Can not access uninitialized long parameter.');
  index := index + 1;
  Get_long_param := data.long_val;
end; {function Get_long_param}


function Get_scalar_param(var index: stack_index_type): scalar_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> scalar_data then
    Runtime_error('Can not access uninitialized scalar parameter.');
  index := index + 1;
  Get_scalar_param := data.scalar_val;
end; {function Get_scalar_param}


function Get_double_param(var index: stack_index_type): double_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> double_data then
    Runtime_error('Can not access uninitialized double parameter.');
  index := index + 1;
  Get_double_param := data.double_val;
end; {function Get_double_param}


{**********************************************************}
{ routines to get compound parameters from top stack frame }
{**********************************************************}


function Get_complex_param(var index: stack_index_type): complex_type;
var
  complex_val: complex_type;
begin
  complex_val.a := Get_scalar_param(index);
  complex_val.b := Get_scalar_param(index);
  Get_complex_param := complex_val;
end; {function Get_complex_param}


function Get_vector_param(var index: stack_index_type): vector_type;
var
  vector_val: vector_type;
begin
  vector_val.x := Get_scalar_param(index);
  vector_val.y := Get_scalar_param(index);
  vector_val.z := Get_scalar_param(index);
  Get_vector_param := vector_val;
end; {function Get_vector_param}


function Get_color_param(var index: stack_index_type): color_type;
var
  color_val: color_type;
begin
  color_val.r := Get_scalar_param(index);
  color_val.g := Get_scalar_param(index);
  color_val.b := Get_scalar_param(index);
  Get_color_param := color_val;
end; {function Get_color_param}


function Get_string_param(var index: stack_index_type): string_type;
var
  str_handle: handle_type;
begin
  str_handle := Get_handle_param(index);
  Get_string_param := Get_string(str_handle);
end; {function Get_string_param}


function Get_addr_param(var index: stack_index_type): addr_type;
var
  addr: addr_type;
begin
  addr := Get_local_addr(index);
  index := index + 2;
  Get_addr_param := addr;
end; {function Get_addr_param}


{*********************************************************}
{ routines to get address parameters from top stack frame }
{*********************************************************}


function Get_stack_index_param(var index: stack_index_type): stack_index_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> stack_index_data then
    Error('Can not access uninitialized stack index parameter.');
  index := index + 1;
  Get_stack_index_param := data.stack_index;
end; {function Get_local_stack_index}


function Get_heap_index_param(var index: stack_index_type): stack_index_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> heap_index_data then
    Error('Can not access uninitialized heap index parameter.');
  index := index + 1;
  Get_heap_index_param := data.heap_index;
end; {function Get_heap_index_param}


function Get_handle_param(var index: stack_index_type): handle_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> handle_data then
    Error('Can not access uninitialized handle parameter.');
  index := index + 1;
  Get_handle_param := data.handle;
end; {function Get_handle_param}


function Get_memref_param(var index: stack_index_type): memref_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> memref_data then
    Error('Can not access uninitialized memref parameter.');
  index := index + 1;
  Get_memref_param := data.memref;
end; {function Get_memref_param}


{*********************************************************}
{ routines to get pointer parameters from top stack frame }
{*********************************************************}


function Get_code_param(var index: stack_index_type): abstract_code_ptr_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> code_data then
    Error('Can not access uninitialized reference parameter.');
  index := index + 1;
  Get_code_param := data.code_ptr;
end; {function Get_code_param}


function Get_type_param(var index: stack_index_type): abstract_type_ptr_type;
var
  data: data_type;
begin
  data := Get_local_stack(index);
  if data.kind <> type_data then
    Error('Can not access uninitialized reference parameter.');
  index := index + 1;
  Get_type_param := data.type_ptr;
end; {function Get_local_type}


end.
