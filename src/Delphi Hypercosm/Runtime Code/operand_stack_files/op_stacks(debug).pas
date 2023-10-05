unit op_stacks;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             op_stacks                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       These stack routines can be used to simulate the        }
{       action of the operand stack to evaluate expressions.    }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, complex_numbers, vectors, colors, data_types, addr_types, data;


{************************************}
{ addresses are cached for later use }
{************************************}
var
  addr_cache: addr_type;


procedure Init_operand_stacks;

{********************************************************}
{ routines to push primitive data onto the operand stack }
{********************************************************}
procedure Push_boolean_operand(boolean_val: boolean_type);
procedure Push_char_operand(char_val: char_type);

procedure Push_byte_operand(byte_val: byte_type);
procedure Push_short_operand(short_val: short_type);

procedure Push_integer_operand(integer_val: integer_type);
procedure Push_long_operand(long_val: long_type);

procedure Push_scalar_operand(scalar_val: scalar_type);
procedure Push_double_operand(double_val: double_type);

{*******************************************************}
{ routines to push compound data onto the operand stack }
{*******************************************************}
procedure Push_complex_operand(complex_val: complex_type);
procedure Push_vector_operand(vector_val: vector_type);
procedure Push_color_operand(color_val: color_type);
procedure Push_addr_operand(addr: addr_type);

{******************************************************}
{ routines to push address data onto the operand stack }
{******************************************************}
procedure Push_stack_index_operand(stack_index: stack_index_type);
procedure Push_heap_index_operand(heap_index: heap_index_type);

procedure Push_handle_operand(handle: handle_type);
procedure Push_memref_operand(memref: memref_type);

{******************************************************}
{ routines to push pointer data onto the operand stack }
{******************************************************}
procedure Push_type_operand(type_ptr: abstract_type_ptr_type);
procedure Push_code_operand(code_ptr: abstract_code_ptr_type);

{************************************************************}
{ routines to retreive primitive data from the operand stack }
{************************************************************}
function Pop_boolean_operand: boolean_type;
function Pop_char_operand: char_type;

function Pop_byte_operand: byte_type;
function Pop_short_operand: short_type;

function Pop_integer_operand: integer_type;
function Pop_long_operand: long_type;

function Pop_scalar_operand: scalar_type;
function Pop_double_operand: double_type;

{***********************************************************}
{ routines to retreive compound data from the operand stack }
{***********************************************************}
function Pop_complex_operand: complex_type;
function Pop_vector_operand: vector_type;
function Pop_color_operand: color_type;
function Pop_addr_operand: addr_type;

{**********************************************************}
{ routines to retreive address data from the operand stack }
{**********************************************************}
function Pop_stack_index_operand: stack_index_type;
function Pop_heap_index_operand: heap_index_type;

function Pop_handle_operand: handle_type;
function Pop_memref_operand: memref_type;

{**********************************************************}
{ routines to retreive pointer data from the operand stack }
{**********************************************************}
function Pop_type_operand: abstract_type_ptr_type;
function Pop_code_operand: abstract_code_ptr_type;

{***********************************************************}
{ routines to examine primitive data from the operand stack }
{***********************************************************}
function Peek_boolean_operand: boolean_type;
function Peek_char_operand: char_type;

function Peek_byte_operand: byte_type;
function Peek_short_operand: short_type;

function Peek_integer_operand: integer_type;
function Peek_long_operand: long_type;

function Peek_scalar_operand: scalar_type;
function Peek_double_operand: double_type;

{*********************************************************}
{ routines to examine address data from the operand stack }
{*********************************************************}
function Peek_stack_index_operand: stack_index_type;
function Peek_heap_index_operand: heap_index_type;

function Peek_handle_operand: handle_type;
function Peek_memref_operand: memref_type;

{*********************************************************}
{ routines to examine pointer data from the operand stack }
{*********************************************************}
function Peek_type_operand: abstract_type_ptr_type;
function Peek_code_operand: abstract_code_ptr_type;

{*****************************************}
{ routines for tracing garbage collection }
{*****************************************}
procedure Touch_operand_stacks;


implementation
uses
  errors, new_memory, get_data, set_data;


{***********************}
{ external declarations }
{***********************}
procedure Touch_handle(handle: handle_type);
  external;
procedure Touch_memref(memref: memref_type);
  external;


const
  memory_alert = false;
  auto_stack_init = true;
  verbose = false;


type
  stack_type = data_type;
  stack_ptr_type = ^stack_type;


var
  operand_stack_base_ptr: stack_ptr_type;
  operand_stack_top_ptr: stack_ptr_type;
  operand_stack_size: stack_index_type;


function New_operand_stack(size: stack_index_type): stack_ptr_type;
var
  stack_ptr, temp: stack_ptr_type;
  counter: longint;
begin
  if memory_alert then
    writeln('allocating new operand stack');
  stack_ptr := stack_ptr_type(NewPtr(size * sizeof(stack_type)));
  Memcheck;

  {******************}
  { initialize stack }
  {******************}
  if auto_stack_init then
    begin
      temp := stack_ptr;
      for counter := 1 to size do
        begin
          temp^.kind := error_data;
          temp := stack_ptr_type(longint(temp) + sizeof(stack_type));
        end;
    end;

  New_operand_stack := stack_ptr;
end; {function New_stack}


procedure Init_operand_stacks;
begin
  operand_stack_size := 1024;
  operand_stack_base_ptr := New_operand_stack(operand_stack_size);
  operand_stack_top_ptr := operand_stack_base_ptr;
  operand_stack_top_ptr^.kind := error_data;
end; {procedure Init_operand_stacks}


{*****************************************}
{ routines for tracing garbage collection }
{*****************************************}


procedure Touch_operand_stacks;
var
  operand_stack_ptr: stack_ptr_type;
  data: data_type;
begin
  if verbose then
    writeln('toucing operand stacks');

  operand_stack_ptr := operand_stack_base_ptr;

  while longint(operand_stack_ptr) <= longint(operand_stack_top_ptr) do
    begin
      data := operand_stack_ptr^;
      if data.kind = handle_data then
        Touch_handle(data.handle)
      else if data.kind = memref_data then
        Touch_memref(data.memref);

      operand_stack_ptr := stack_ptr_type(longint(operand_stack_ptr) +
        sizeof(stack_type));
    end;
end; {procedure Touch_operand_stacks}


{**********************************************************}
{ routines to push and pop operands from the operand stack }
{**********************************************************}


procedure Push_operand(data: data_type);
begin
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) +
    sizeof(stack_type));
  operand_stack_top_ptr^ := data;
end; {procedure Push_operand}


function Pop_operand: data_type;
var
  data: data_type;
begin
  data := operand_stack_top_ptr^;
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) -
    sizeof(stack_type));
  Pop_operand := data;
end; {function Pop_operand}


{*************************************************}
{ routine to look at the top of the operand stack }
{*************************************************}


function Peek_operand: data_type;
begin
  Peek_operand := operand_stack_top_ptr^;
end; {function Peek_operand}


{********************************************************}
{ routines to push primitive data onto the operand stack }
{********************************************************}


procedure Push_boolean_operand(boolean_val: boolean_type);
begin
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) +
    sizeof(stack_type));
  operand_stack_top_ptr^.kind := boolean_data;
  operand_stack_top_ptr^.boolean_val := boolean_val;
end; {procedure Push_boolean_operand}


procedure Push_char_operand(char_val: char_type);
begin
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) +
    sizeof(stack_type));
  operand_stack_top_ptr^.kind := char_data;
  operand_stack_top_ptr^.char_val := char_val;
end; {procedure Push_char_operand}


procedure Push_byte_operand(byte_val: byte_type);
begin
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) +
    sizeof(stack_type));
  operand_stack_top_ptr^.kind := byte_data;
  operand_stack_top_ptr^.byte_val := byte_val;
end; {procedure Push_byte_operand}


procedure Push_short_operand(short_val: short_type);
begin
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) +
    sizeof(stack_type));
  operand_stack_top_ptr^.kind := short_data;
  operand_stack_top_ptr^.short_val := short_val;
end; {procedure Push_short_operand}


procedure Push_integer_operand(integer_val: integer_type);
begin
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) +
    sizeof(stack_type));
  operand_stack_top_ptr^.kind := integer_data;
  operand_stack_top_ptr^.integer_val := integer_val;
end; {procedure Push_integer_operand}


procedure Push_long_operand(long_val: long_type);
begin
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) +
    sizeof(stack_type));
  operand_stack_top_ptr^.kind := long_data;
  operand_stack_top_ptr^.long_val := long_val;
end; {procedure Push_long_operand}


procedure Push_scalar_operand(scalar_val: scalar_type);
begin
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) +
    sizeof(stack_type));
  operand_stack_top_ptr^.kind := scalar_data;
  operand_stack_top_ptr^.scalar_val := scalar_val;
end; {procedure Push_scalar_operand}


procedure Push_double_operand(double_val: double_type);
begin
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) +
    sizeof(stack_type));
  operand_stack_top_ptr^.kind := double_data;
  operand_stack_top_ptr^.double_val := double_val;
end; {procedure Push_double_operand}


{*******************************************************}
{ routines to push compound data onto the operand stack }
{*******************************************************}


procedure Push_complex_operand(complex_val: complex_type);
begin
  Push_scalar_operand(complex_val.a);
  Push_scalar_operand(complex_val.b);
end; {procedure Push_complex_operand}


procedure Push_vector_operand(vector_val: vector_type);
begin
  Push_scalar_operand(vector_val.x);
  Push_scalar_operand(vector_val.y);
  Push_scalar_operand(vector_val.z);
end; {procedure Push_vector_operand}


procedure Push_color_operand(color_val: color_type);
begin
  Push_scalar_operand(color_val.r);
  Push_scalar_operand(color_val.g);
  Push_scalar_operand(color_val.b);
end; {procedure Push_color_operand}


procedure Push_addr_operand(addr: addr_type);
begin
  case addr.kind of

    stack_index_addr:
      Push_stack_index_operand(addr.stack_index);

    heap_index_addr:
      Push_heap_index_operand(addr.heap_index);

    handle_heap_addr:
      begin
        Push_heap_index_operand(addr.handle_index);
        Push_handle_operand(addr.handle);
        addr_cache := addr;
      end;

    memref_heap_addr:
      begin
        Push_heap_index_operand(addr.memref_index);
        Push_memref_operand(addr.memref);
        addr_cache := addr;
      end;

  end; {case}
end; {procedure Push_addr_operand}


{******************************************************}
{ routines to push address data onto the operand stack }
{******************************************************}


procedure Push_stack_index_operand(stack_index: stack_index_type);
begin
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) +
    sizeof(stack_type));
  operand_stack_top_ptr^.kind := stack_index_data;
  operand_stack_top_ptr^.stack_index := stack_index;
  addr_cache := Stack_index_to_addr(stack_index);
end; {procedure Push_stack_index_operand}


procedure Push_heap_index_operand(heap_index: heap_index_type);
begin
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) +
    sizeof(stack_type));
  operand_stack_top_ptr^.kind := heap_index_data;
  operand_stack_top_ptr^.heap_index := heap_index;
end; {procedure Push_heap_index_operand}


procedure Push_handle_operand(handle: handle_type);
begin
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) +
    sizeof(stack_type));
  operand_stack_top_ptr^.kind := handle_data;
  operand_stack_top_ptr^.handle := handle;
end; {procedure Push_handle_operand}


procedure Push_memref_operand(memref: memref_type);
begin
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) +
    sizeof(stack_type));
  operand_stack_top_ptr^.kind := memref_data;
  operand_stack_top_ptr^.memref := memref;
end; {procedure Push_memref_operand}


{******************************************************}
{ routines to push pointer data onto the operand stack }
{******************************************************}


procedure Push_type_operand(type_ptr: abstract_type_ptr_type);
begin
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) +
    sizeof(stack_type));
  operand_stack_top_ptr^.kind := type_data;
  operand_stack_top_ptr^.type_ptr := type_ptr;
end; {procedure Push_type_operand}


procedure Push_code_operand(code_ptr: abstract_code_ptr_type);
begin
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) +
    sizeof(stack_type));
  operand_stack_top_ptr^.kind := code_data;
  operand_stack_top_ptr^.code_ptr := code_ptr;
end; {procedure Push_code_operand}


{************************************************************}
{ routines to retreive primitive data from the operand stack }
{************************************************************}


function Pop_boolean_operand: boolean_type;
var
  boolean_val: boolean_type;
begin
  boolean_val := operand_stack_top_ptr^.boolean_val;
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) -
    sizeof(stack_type));
  Pop_boolean_operand := boolean_val;
end; {function Pop_boolean_operand}


function Pop_char_operand: char_type;
var
  char_val: char_type;
begin
  char_val := operand_stack_top_ptr^.char_val;
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) -
    sizeof(stack_type));
  Pop_char_operand := char_val;
end; {function Pop_char_operand}


function Pop_byte_operand: byte_type;
var
  byte_val: byte_type;
begin
  byte_val := operand_stack_top_ptr^.byte_val;
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) -
    sizeof(stack_type));
  Pop_byte_operand := byte_val;
end; {function Pop_byte_operand}


function Pop_short_operand: short_type;
var
  short_val: short_type;
begin
  short_val := operand_stack_top_ptr^.short_val;
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) -
    sizeof(stack_type));
  Pop_short_operand := short_val;
end; {function Pop_short_operand}


function Pop_integer_operand: integer_type;
var
  integer_val: integer_type;
begin
  integer_val := operand_stack_top_ptr^.integer_val;
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) -
    sizeof(stack_type));
  Pop_integer_operand := integer_val;
end; {function Pop_integer_operand}


function Pop_long_operand: long_type;
var
  long_val: long_type;
begin
  long_val := operand_stack_top_ptr^.long_val;
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) -
    sizeof(stack_type));
  Pop_long_operand := long_val;
end; {function Pop_long_operand}


function Pop_scalar_operand: scalar_type;
var
  scalar_val: scalar_type;
begin
  scalar_val := operand_stack_top_ptr^.scalar_val;
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) -
    sizeof(stack_type));
  Pop_scalar_operand := scalar_val;
end; {function Pop_scalar_operand}


function Pop_double_operand: double_type;
var
  double_val: double_type;
begin
  double_val := operand_stack_top_ptr^.double_val;
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) -
    sizeof(stack_type));
  Pop_double_operand := double_val;
end; {function Pop_double_operand}


{***********************************************************}
{ routines to retreive compound data from the operand stack }
{***********************************************************}


function Pop_complex_operand: complex_type;
var
  complex_val: complex_type;
begin
  complex_val.b := Pop_scalar_operand;
  complex_val.a := Pop_scalar_operand;
  Pop_complex_operand := complex_val;
end; {function Pop_complex_operand}


function Pop_vector_operand: vector_type;
var
  vector_val: vector_type;
begin
  vector_val.z := Pop_scalar_operand;
  vector_val.y := Pop_scalar_operand;
  vector_val.x := Pop_scalar_operand;
  Pop_vector_operand := vector_val;
end; {function Pop_vector_operand}


function Pop_color_operand: color_type;
var
  color_val: color_type;
begin
  color_val.b := Pop_scalar_operand;
  color_val.g := Pop_scalar_operand;
  color_val.r := Pop_scalar_operand;
  Pop_color_operand := color_val;
end; {function Pop_color_operand}


function Pop_addr_operand: addr_type;
var
  data: data_type;
  addr: addr_type;
begin
  data := Pop_operand;
  if data.kind in [stack_index_data, heap_index_data, handle_data, memref_data]
    then
    case data.kind of

      stack_index_data:
        begin
          addr.kind := stack_index_addr;
          addr.stack_index := data.stack_index;
        end;

      heap_index_data:
        begin
          addr.kind := heap_index_addr;
          addr.heap_index := data.heap_index;
        end;

      handle_data:
        begin
          addr.kind := handle_heap_addr;
          addr.handle := data.handle;
          addr.handle_index := Pop_heap_index_operand;
        end;

      memref_data:
        begin
          addr.kind := memref_heap_addr;
          addr.memref := data.memref;
          addr.memref_index := Pop_heap_index_operand;
        end;

    end
  else
    Internal_error('Can not pop uninitialized reference.');

  Pop_addr_operand := addr;
end; {function Pop_addr_operand}


{**********************************************************}
{ routines to retreive address data from the operand stack }
{**********************************************************}


function Pop_stack_index_operand: stack_index_type;
var
  stack_index: stack_index_type;
begin
  stack_index := Data_to_stack_index(operand_stack_top_ptr^);
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) -
    sizeof(stack_type));
  Pop_stack_index_operand := stack_index;
end; {function Pop_stack_index_operand}


function Pop_heap_index_operand: heap_index_type;
var
  heap_index: heap_index_type;
begin
  heap_index := Data_to_heap_index(operand_stack_top_ptr^);
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) -
    sizeof(stack_type));
  Pop_heap_index_operand := heap_index;
end; {function Pop_heap_index_operand}


function Pop_handle_operand: handle_type;
var
  handle: handle_type;
begin
  handle := Data_to_handle(operand_stack_top_ptr^);
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) -
    sizeof(stack_type));
  Pop_handle_operand := handle;
end; {function Pop_handle_operand}


function Pop_memref_operand: memref_type;
var
  memref: memref_type;
begin
  memref := Data_to_memref(operand_stack_top_ptr^);
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) -
    sizeof(stack_type));
  Pop_memref_operand := memref;
end; {function Pop_memref_operand}


{**********************************************************}
{ routines to retreive pointer data from the operand stack }
{**********************************************************}


function Pop_type_operand: abstract_type_ptr_type;
var
  type_ptr: abstract_type_ptr_type;
begin
  type_ptr := Data_to_type(operand_stack_top_ptr^);
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) -
    sizeof(stack_type));
  Pop_type_operand := type_ptr;
end; {function Pop_type_operand}


function Pop_code_operand: abstract_code_ptr_type;
var
  code_ptr: abstract_code_ptr_type;
begin
  code_ptr := Data_to_code(operand_stack_top_ptr^);
  operand_stack_top_ptr := stack_ptr_type(longint(operand_stack_top_ptr) -
    sizeof(stack_type));
  Pop_code_operand := code_ptr;
end; {function Pop_code_operand}


{***********************************************************}
{ routines to examine primitive data from the operand stack }
{***********************************************************}


function Peek_boolean_operand: boolean_type;
begin
  Peek_boolean_operand := operand_stack_top_ptr^.boolean_val;
end; {function Peek_boolean_operand}


function Peek_char_operand: char_type;
begin
  Peek_char_operand := operand_stack_top_ptr^.char_val;
end; {function Peek_char_operand}


function Peek_byte_operand: byte_type;
begin
  Peek_byte_operand := operand_stack_top_ptr^.byte_val;
end; {function Peek_byte_operand}


function Peek_short_operand: short_type;
begin
  Peek_short_operand := operand_stack_top_ptr^.short_val;
end; {function Peek_short_operand}


function Peek_integer_operand: integer_type;
begin
  Peek_integer_operand := operand_stack_top_ptr^.integer_val;
end; {function Peek_integer_operand}


function Peek_long_operand: long_type;
begin
  Peek_long_operand := operand_stack_top_ptr^.long_val;
end; {function Peek_long_operand}


function Peek_scalar_operand: scalar_type;
begin
  Peek_scalar_operand := operand_stack_top_ptr^.scalar_val;
end; {function Peek_scalar_operand}


function Peek_double_operand: double_type;
begin
  Peek_double_operand := operand_stack_top_ptr^.double_val;
end; {function Peek_double_operand}


{*********************************************************}
{ routines to examine address data from the operand stack }
{*********************************************************}


function Peek_stack_index_operand: stack_index_type;
begin
  Peek_stack_index_operand := Data_to_stack_index(operand_stack_top_ptr^);
end; {function Peek_stack_index_operand}


function Peek_heap_index_operand: heap_index_type;
begin
  Peek_heap_index_operand := Data_to_heap_index(operand_stack_top_ptr^);
end; {function Peek_heap_index_operand}


function Peek_handle_operand: handle_type;
begin
  Peek_handle_operand := Data_to_handle(operand_stack_top_ptr^);
end; {function Peek_handle_operand}


function Peek_memref_operand: memref_type;
begin
  Peek_memref_operand := Data_to_memref(operand_stack_top_ptr^);
end; {function Peek_memref_operand}


{*********************************************************}
{ routines to examine pointer data from the operand stack }
{*********************************************************}


function Peek_type_operand: abstract_type_ptr_type;
begin
  Peek_type_operand := operand_stack_top_ptr^.type_ptr;
end; {function Peek_type_operand}


function Peek_code_operand: abstract_code_ptr_type;
begin
  Peek_code_operand := operand_stack_top_ptr^.code_ptr;
end; {function Peek_code_operand}


end. {module op_stacks}
