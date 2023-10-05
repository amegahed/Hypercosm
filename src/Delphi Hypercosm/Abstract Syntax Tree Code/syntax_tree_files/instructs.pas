unit instructs;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              instructs                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The fns module defines all of the built in              }
{       instructions used in the abstract syntax tree, the      }
{       internal representation of the code which is            }
{       used by the interpreter.                                }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  exprs;


type
  {***************************************************************}
  {           Simulation / Modelling Programming Language         }
  {                  SMPL (pronounced 'simple')                   }
  {***************************************************************}
  {                         instructions                          }
  {***************************************************************}


  instruct_kind_type = (

    {***************************************************************}
    {                       output instructions                     }
    {***************************************************************}

    {******************}
    { enumerated types }
    {******************}
    boolean_write, char_write,

    {****************}
    { integral types }
    {****************}
    byte_write, integer_write, short_write, long_write,

    {**************}
    { scalar types }
    {**************}
    scalar_write, double_write, complex_write, vector_write,

    {***************}
    { complex types }
    {***************}
    string_write,

    {*************************}
    { new line (no arguments) }
    {*************************}
    write_newline,

    {***************************************************************}
    {                        input instructions                     }
    {***************************************************************}

    {******************}
    { enumerated types }
    {******************}
    boolean_read, char_read,

    {****************}
    { integral types }
    {****************}
    byte_read, integer_read, short_read, long_read,

    {**************}
    { scalar types }
    {**************}
    scalar_read, double_read, complex_read, vector_read,

    {***************}
    { complex types }
    {***************}
    string_read,

    {*************************}
    { new line (no arguments) }
    {*************************}
    read_newline

    ); {instruct_kind_type}


type
  instruct_kind_set_type = set of instruct_kind_type;


var
  {***********************}
  { various subrange sets }
  {***********************}
  output_instruct_set, input_instruct_set, io_instruct_set:
  instruct_kind_set_type;


type
  {**************************************}
  { the abstract syntax tree instruction }
  {**************************************}
  instruct_ptr_type = ^instruct_type;
  instruct_ref_type = instruct_ptr_type;


  {******************************************************}
  { Note:                                                }
  { the names 'expr_ptr', 'stmt_ptr' and 'decl_ptr' are  }
  { intentionally not used as fields so that they may be }
  { used as locals inside of a 'with expr_ptr^' block.   }
  {                                                      }
  { Otherwise be wary of 'with expr_ptr^' blocks because }
  { the expr node has so many fields that an identifier  }
  { clash may easily cause a misunderstanding not found  }
  { by the compiler.                                     }
  {******************************************************}
  instruct_type = record
    next: instruct_ptr_type;

    case kind: instruct_kind_type of

      {***************************************************************}
      {                       output instructions                     }
      {***************************************************************}

      {******************}
      { enumerated types }
      {******************}
      boolean_write, char_write,

      {****************}
      { integral types }
      {****************}
      byte_write, integer_write, short_write, long_write,

      {**************}
      { scalar types }
      {**************}
      scalar_write, double_write, complex_write, vector_write,

      {***************}
      { complex types }
      {***************}
      string_write,

      {*************************}
      { new line (no arguments) }
      {*************************}
      write_newline,

      {***************************************************************}
      {                        input instructions                     }
      {***************************************************************}

      {******************}
      { enumerated types }
      {******************}
      boolean_read, char_read,

      {****************}
      { integral types }
      {****************}
      byte_read, integer_read, short_read, long_read,

      {**************}
      { scalar types }
      {**************}
      scalar_read, double_read, complex_read, vector_read,

      {***************}
      { complex types }
      {***************}
      string_read,

      {*************************}
      { new line (no arguments) }
      {*************************}
      read_newline: (
        argument_ptr: expr_ptr_type;
        );

  end; {instruct_type}


{****************************************************}
{ routines for allocating and initializing instructs }
{****************************************************}
function New_instruct(kind: instruct_kind_type): instruct_ptr_type;
procedure Init_instruct(instruct_ptr: instruct_ptr_type;
  kind: instruct_kind_type);
function Copy_instruct(instruct_ptr: instruct_ptr_type): instruct_ptr_type;
function Copy_instructs(instruct_ptr: instruct_ptr_type): instruct_ptr_type;
procedure Free_instruct(var instruct_ptr: instruct_ptr_type);
procedure Free_instructs(var instruct_ptr: instruct_ptr_type);
function Instruct_count: longint;

{***************************************}
{ routines for writing enumerated types }
{***************************************}
procedure Write_instruct_kind(kind: instruct_kind_type);


implementation
uses
  new_memory;


const
  block_size = 512;
  memory_alert = false;


type
  instruct_block_ptr_type = ^instruct_block_type;
  instruct_block_type = array[0..block_size] of instruct_type;


var
  instruct_free_list: instruct_ptr_type;
  instruct_block_ptr: instruct_block_ptr_type;
  instruct_counter: longint;


procedure Init_instruct_sets;
begin
  output_instruct_set := [boolean_write..write_newline];
  input_instruct_set := [boolean_read..read_newline];
  io_instruct_set := [boolean_write..write_newline];
end; {procedure Init_instruct_sets}


{****************************************************}
{ routines for allocating and initializing instructs }
{****************************************************}


procedure Init_instruct(instruct_ptr: instruct_ptr_type;
  kind: instruct_kind_type);
begin
  {********************}
  { init common fields }
  {********************}
  instruct_ptr^.kind := kind;
  instruct_ptr^.next := nil;

  {**********************}
  { init specific fields }
  {**********************}
  with instruct_ptr^ do
    case kind of

      {*****************************}
      { input / output instructions }
      {*****************************}
      boolean_write..write_newline, boolean_read..read_newline:
        argument_ptr := nil;

    end; {case}
end; {procedure Init_instruct}


function New_instruct(kind: instruct_kind_type): instruct_ptr_type;
var
  instruct_ptr: instruct_ptr_type;
  index: integer;
begin
  {*****************************}
  { get instruct from free list }
  {*****************************}
  if instruct_free_list <> nil then
    begin
      instruct_ptr := instruct_free_list;
      instruct_free_list := instruct_free_list^.next;
    end
  else
    begin
      index := instruct_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new instruct block');
          new(instruct_block_ptr);
        end;
      instruct_ptr := @instruct_block_ptr^[index];
    end;

  {****************************}
  { increment instruct counter }
  {****************************}
  instruct_counter := instruct_counter + 1;

  {*********************}
  { initialize instruct }
  {*********************}
  Init_instruct(instruct_ptr, kind);

  New_instruct := instruct_ptr;
end; {function New_instruct}


function Instruct_count: longint;
begin
  Instruct_count := instruct_counter;
end; {function instruct_count}


{******************************}
{ instruction copying routines }
{******************************}


function Copy_instruct(instruct_ptr: instruct_ptr_type): instruct_ptr_type;
var
  new_instruct_ptr: instruct_ptr_type;
begin
  if (instruct_ptr <> nil) then
    begin
      new_instruct_ptr := New_instruct(instruct_ptr^.kind);
      new_instruct_ptr^ := instruct_ptr^;
      new_instruct_ptr^.next := nil;
    end
  else
    new_instruct_ptr := nil;

  Copy_instruct := new_instruct_ptr;
end; {function Copy_instruct}


function Copy_instructs(instruct_ptr: instruct_ptr_type): instruct_ptr_type;
var
  new_instruct_ptr: instruct_ptr_type;
  first_instruct_ptr, last_instruct_ptr: instruct_ptr_type;
begin
  first_instruct_ptr := nil;
  last_instruct_ptr := nil;

  while instruct_ptr <> nil do
    begin
      new_instruct_ptr := Copy_instruct(instruct_ptr);

      {*********************************}
      { add new instruct to end of list }
      {*********************************}
      if (last_instruct_ptr <> nil) then
        begin
          last_instruct_ptr^.next := new_instruct_ptr;
          last_instruct_ptr := new_instruct_ptr;
        end
      else
        begin
          first_instruct_ptr := new_instruct_ptr;
          last_instruct_ptr := new_instruct_ptr;
        end;

      instruct_ptr := instruct_ptr^.next;
    end;

  Copy_instructs := first_instruct_ptr;
end; {function Copy_instructs}


{******************************}
{ instruction freeing routines }
{******************************}


procedure Free_instruct(var instruct_ptr: instruct_ptr_type);
begin
  if (instruct_ptr <> nil) then
    begin
      {***************************}
      { add instruct to free list }
      {***************************}
      instruct_ptr^.next := instruct_free_list;
      instruct_free_list := instruct_ptr;
      instruct_ptr := nil;

      {****************************}
      { decrement instruct counter }
      {****************************}
      instruct_counter := instruct_counter - 1;
    end;
end; {procedure Free_instruct}


procedure Free_instructs(var instruct_ptr: instruct_ptr_type);
var
  temp: instruct_ptr_type;
begin
  while (instruct_ptr <> nil) do
    begin
      temp := instruct_ptr;
      instruct_ptr := instruct_ptr^.next;
      Free_instruct(temp);
    end;
end; {procedure Free_instructs}


{***************************************}
{ routines for writing enumerated types }
{***************************************}


procedure Write_instruct_kind(kind: instruct_kind_type);
begin
  case kind of

    {***************************************************************}
    {                       output instructions                     }
    {***************************************************************}

    {******************}
    { enumerated types }
    {******************}
    boolean_write:
      write('boolean_write');
    char_write:
      write('char_write');

    {****************}
    { integral types }
    {****************}
    byte_write:
      write('byte_write');
    integer_write:
      write('integer_write');
    short_write:
      write('short_write');
    long_write:
      write('long_write');

    {**************}
    { scalar types }
    {**************}
    scalar_write:
      write('scalar_write');
    double_write:
      write('double_write');
    complex_write:
      write('complex_write');
    vector_write:
      write('vector_write');

    {***************}
    { complex types }
    {***************}
    string_write:
      write('string_write');

    {*************************}
    { new line (no arguments) }
    {*************************}
    write_newline:
      write('write_newline');

    {***************************************************************}
    {                        input instructions                     }
    {***************************************************************}

    {******************}
    { enumerated types }
    {******************}
    boolean_read:
      write('boolean_read');
    char_read:
      write('char_read');

    {****************}
    { integral types }
    {****************}
    byte_read:
      write('byte_read');
    integer_read:
      write('integer_read');
    short_read:
      write('short_read');
    long_read:
      write('long_read');

    {**************}
    { scalar types }
    {**************}
    scalar_read:
      write('scalar_read');
    double_read:
      write('double_read');
    complex_read:
      write('complex_read');
    vector_read:
      write('vector_read');

    {***************}
    { complex types }
    {***************}
    string_read:
      write('string_read');

    {*************************}
    { new line (no arguments) }
    {*************************}
    read_newline:
      write('read_newline');

  end; {case}
end; {procedure Write_instruct_kind}


initialization
  Init_instruct_sets;
  instruct_free_list := nil;
  instruct_block_ptr := nil;
  instruct_counter := 0;
end.
