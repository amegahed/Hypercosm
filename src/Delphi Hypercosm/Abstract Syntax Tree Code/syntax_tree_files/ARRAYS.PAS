unit arrays;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               arrays                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The exprs module defines all of the array structs       }
{       used in the abstract syntax tree, the internal          }
{       representation of the code which is used by the         }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, addr_types, expr_attributes;


type
  {***************************************************************}
  {           Simulation / Modelling Programming Language         }
  {                  SMPL (pronounced 'simple')                   }
  {***************************************************************}
  {                             arrays                            }
  {***************************************************************}


  forward_expr_ptr_type = forward_expr_ref_type;


  {********************************************************}
  { A ref type is like a ptr type except that a type ref   }
  { is a secondary reference to the type node and hence,   }
  { is not responsible for allocating or freeing the node. }
  {********************************************************}
  array_index_ptr_type = ^array_index_type;
  array_index_ref_type = array_index_ptr_type;
  array_index_list_ptr_type = ^array_index_list_type;
  array_index_list_ref_type = array_index_list_ptr_type;

  array_bounds_ptr_type = ^array_bounds_type;
  array_bounds_ref_type = array_bounds_ptr_type;
  array_bounds_list_ptr_type = ^array_bounds_list_type;
  array_bounds_list_ref_type = array_bounds_list_ptr_type;

  array_subrange_ptr_type = ^array_subrange_type;
  array_subrange_ref_type = array_subrange_ptr_type;


  {***********************************}
  { This structure is a list of exprs }
  { to be evaluated at run time to    }
  { compute indices for array acesses.}
  {***********************************}
  array_index_type = record
    index_expr_ptr: forward_expr_ptr_type;
    index_val: heap_index_type;
    array_bounds_ref: array_bounds_ref_type;
    array_index_index: longint;
    next, prev: array_index_ptr_type;
  end; {array_index_type}

  array_index_list_type = record
    indices, max_indices: integer;
    first, last: array_index_ptr_type;
    array_index_list_index: longint;
    next: array_index_list_ptr_type;
  end; {array_index_list_type}


  {***********************************}
  { This structure is a list of pairs }
  { of expressions to be evaluated at }
  { run time to compute array bounds. }
  {***********************************}
  array_bounds_type = record
    min_expr_ptr, max_expr_ptr: forward_expr_ptr_type;
    min_val, max_val: heap_index_type;
    array_index_ref: array_index_ref_type;
    array_bounds_index: longint;
    next, prev: array_bounds_ptr_type;
  end; {array_bounds_type}

  array_bounds_list_type = record
    dimensions: integer;
    size: heap_index_type;
    first, last: array_bounds_ptr_type;
    array_bounds_list_index: longint;
    next: array_bounds_list_ptr_type;
  end; {array_bounds_list_type}


  {********************************************************}
  { This structure is used to iterate over array subranges }
  {********************************************************}
  array_subrange_type = record
    array_expr_ptr: forward_expr_ptr_type;
    array_base_ref: forward_expr_ref_type;
    array_bounds_ref: array_bounds_ref_type;
    array_derefs: integer;
    next: array_subrange_ptr_type;
  end; {subrange_type}


{*******************************************************}
{ routines for allocating and initializing array bounds }
{*******************************************************}
function New_array_bounds: array_bounds_ptr_type;
procedure Init_array_bounds(array_bounds_ptr: array_bounds_ptr_type);
function New_array_bounds_list: array_bounds_list_ptr_type;
procedure Init_array_bounds_list(array_bounds_list_ptr:
  array_bounds_list_ptr_type);
procedure Add_array_bounds(array_bounds_list_ptr: array_bounds_list_ptr_type;
  array_bounds_ptr: array_bounds_ptr_type);
procedure Set_array_bounds_list(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  source_bounds_list_ptr: array_bounds_list_ptr_type);
function Array_bounds_to_size(array_bounds_list_ptr:
  array_bounds_list_ptr_type): heap_index_type;

{********************************************************}
{ routines for allocating and initializing array indices }
{********************************************************}
function New_array_index: array_index_ptr_type;
procedure Init_array_index(array_index_ptr: array_index_ptr_type);
function New_array_index_list(max_indices: integer): array_index_list_ptr_type;
procedure Init_array_index_list(array_index_list_ptr: array_index_list_ptr_type;
  max_indices: integer);
procedure Add_array_index(array_index_list_ptr: array_index_list_ptr_type;
  array_index_ptr: array_index_ptr_type);
procedure Set_array_index_list(array_index_list_ptr: array_index_list_ptr_type;
  source_index_list_ptr: array_index_list_ptr_type);

{**********************************************************}
{ routines for allocating and initializing array subranges }
{**********************************************************}
function New_array_subrange: array_subrange_ptr_type;
procedure Init_array_subrange(array_subrange_ptr: array_subrange_ptr_type);

{***************************************}
{ routines for creating array subranges }
{***************************************}
procedure Add_array_subrange(array_bounds_list_ptr: array_bounds_list_ptr_type;
  array_index_list_ptr: array_index_list_ptr_type;
  array_bounds_ptr: array_bounds_ptr_type);
procedure Link_array_bounds_index_list(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  array_index_list_ptr: array_index_list_ptr_type);

{**********************************************************}
{ routines for copying array bounds, indices and subranges }
{**********************************************************}
function Copy_array_bounds(array_bounds_ptr: array_bounds_ptr_type):
  array_bounds_ptr_type;
function Copy_array_bounds_list(array_bounds_list_ptr:
  array_bounds_list_ptr_type): array_bounds_list_ptr_type;
function Copy_array_index(array_index_ptr: array_index_ptr_type):
  array_index_ptr_type;
function Copy_array_index_list(array_index_list_ptr: array_index_list_ptr_type):
  array_index_list_ptr_type;
function Copy_array_subrange(array_subrange_ptr: array_subrange_ptr_type):
  array_subrange_ptr_type;

{**********************************************************}
{ routines for freeing array bounds, indices and subranges }
{**********************************************************}
procedure Free_array_bounds(var array_bounds_ptr: array_bounds_ptr_type);
procedure Free_array_bounds_list(var array_bounds_list_ptr:
  array_bounds_list_ptr_type);
procedure Free_array_index(var array_index_ptr: array_index_ptr_type);
procedure Free_array_index_list(var array_index_list_ptr:
  array_index_list_ptr_type);
procedure Free_array_subrange(var array_subrange_ptr: array_subrange_ptr_type);

{**********************************************************}
{ routines for finding the number of array nodes allocated }
{**********************************************************}
function Array_bounds_count: longint;
function Array_bounds_list_count: longint;
function Array_index_count: longint;
function Array_index_list_count: longint;
function Array_subrange_count: longint;

{***********************************************}
{ routines for writing array bounds and indices }
{***********************************************}
function Array_bounds_to_str(array_bounds_ptr: array_bounds_ptr_type):
  string_type;
function Array_bounds_list_to_str(array_bounds_list_ptr:
  array_bounds_list_ptr_type): string_type;
function Array_index_to_str(array_index_ptr: array_index_ptr_type): string_type;
function Array_index_list_to_str(array_index_list_ptr:
  array_index_list_ptr_type): string_type;


implementation
uses
  errors, new_memory, string_io;


const
  block_size = 512;
  memory_alert = false;


type
  {************************}
  { block allocation types }
  {************************}
  array_bounds_block_ptr_type = ^array_bounds_block_type;
  array_bounds_block_type = array[0..block_size] of array_bounds_type;

  array_bounds_list_block_ptr_type = ^array_bounds_list_block_type;
  array_bounds_list_block_type = array[0..block_size] of array_bounds_list_type;

  array_index_block_ptr_type = ^array_index_block_type;
  array_index_block_type = array[0..block_size] of array_index_type;

  array_index_list_block_ptr_type = ^array_index_list_block_type;
  array_index_list_block_type = array[0..block_size] of array_index_list_type;

  array_subrange_block_ptr_type = ^array_subrange_block_type;
  array_subrange_block_type = array[0..block_size] of array_subrange_type;


var
  {****************************}
  { free lists for array nodes }
  {****************************}
  array_bounds_free_list: array_bounds_ptr_type;
  array_bounds_list_free_list: array_bounds_list_ptr_type;
  array_index_free_list: array_index_ptr_type;
  array_index_list_free_list: array_index_list_ptr_type;
  array_subrange_free_list: array_subrange_ptr_type;

  {****************************}
  { block allocation variables }
  {****************************}
  array_bounds_block_ptr: array_bounds_block_ptr_type;
  array_bounds_counter: longint;

  array_bounds_list_block_ptr: array_bounds_list_block_ptr_type;
  array_bounds_list_counter: longint;

  array_index_block_ptr: array_index_block_ptr_type;
  array_index_counter: longint;

  array_index_list_block_ptr: array_index_list_block_ptr_type;
  array_index_list_counter: longint;

  array_subrange_block_ptr: array_subrange_block_ptr_type;
  array_subrange_counter: longint;


{******************************************}
{ routines for creating array bounds lists }
{******************************************}


procedure Init_array_bounds(array_bounds_ptr: array_bounds_ptr_type);
begin
  with array_bounds_ptr^ do
    begin
      min_expr_ptr := nil;
      max_expr_ptr := nil;
      min_val := 0;
      max_val := 0;
      array_index_ref := nil;
      array_bounds_index := 0;
      next := nil;
      prev := nil;
    end;
end; {procedure Init_array_bounds}


function New_array_bounds: array_bounds_ptr_type;
var
  array_bounds_ptr: array_bounds_ptr_type;
  index: integer;
begin
  {*********************************}
  { get array bounds from free list }
  {*********************************}
  if (array_bounds_free_list <> nil) then
    begin
      array_bounds_ptr := array_bounds_free_list;
      array_bounds_free_list := array_bounds_free_list^.next;
    end
  else
    begin
      index := array_bounds_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new array bounds block');
          new(array_bounds_block_ptr);
        end;
      array_bounds_ptr := @array_bounds_block_ptr^[index];
    end;

  {********************************}
  { increment array bounds counter }
  {********************************}
  array_bounds_counter := array_bounds_counter + 1;

  {*************************}
  { initialize array bounds }
  {*************************}
  Init_array_bounds(array_bounds_ptr);

  New_array_bounds := array_bounds_ptr;
end; {function New_array_bounds}


procedure Init_array_bounds_list(array_bounds_list_ptr:
  array_bounds_list_ptr_type);
begin
  with array_bounds_list_ptr^ do
    begin
      dimensions := 0;
      size := 0;
      first := nil;
      last := nil;
      array_bounds_list_index := 0;
      next := nil;
    end;
end; {procedure Init_array_bounds_list}


function New_array_bounds_list: array_bounds_list_ptr_type;
var
  array_bounds_list_ptr: array_bounds_list_ptr_type;
  index: integer;
begin
  {**************************************}
  { get array bounds list from free list }
  {**************************************}
  if (array_bounds_list_free_list <> nil) then
    begin
      array_bounds_list_ptr := array_bounds_list_free_list;
      array_bounds_list_free_list := array_bounds_list_free_list^.next;
    end
  else
    begin
      index := array_bounds_list_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new array bounds list block');
          new(array_bounds_list_block_ptr);
        end;
      array_bounds_list_ptr := @array_bounds_list_block_ptr^[index];
    end;

  {*************************************}
  { increment array bounds list counter }
  {*************************************}
  array_bounds_list_counter := array_bounds_list_counter + 1;

  {******************************}
  { initialize array bounds list }
  {******************************}
  Init_array_bounds_list(array_bounds_list_ptr);

  New_array_bounds_list := array_bounds_list_ptr;
end; {function New_array_bounds_list}


procedure Add_array_bounds(array_bounds_list_ptr: array_bounds_list_ptr_type;
  array_bounds_ptr: array_bounds_ptr_type);
begin
  array_bounds_list_ptr^.dimensions := array_bounds_list_ptr^.dimensions + 1;

  {************************}
  { insert at tail of list }
  {************************}
  array_bounds_ptr^.next := nil;
  array_bounds_ptr^.prev := array_bounds_list_ptr^.last;

  if (array_bounds_list_ptr^.last = nil) then
    begin
      array_bounds_list_ptr^.first := array_bounds_ptr;
      array_bounds_list_ptr^.last := array_bounds_ptr;
    end
  else
    begin
      array_bounds_list_ptr^.last^.next := array_bounds_ptr;
      array_bounds_list_ptr^.last := array_bounds_ptr;
    end;
end; {function Add_array_bounds}


procedure Set_array_bounds_list(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  source_bounds_list_ptr: array_bounds_list_ptr_type);
var
  array_bounds_ptr: array_bounds_ptr_type;
  source_bounds_ptr: array_bounds_ptr_type;
begin
  if (array_bounds_list_ptr^.dimensions = source_bounds_list_ptr^.dimensions)
    then
    begin
      array_bounds_ptr := array_bounds_list_ptr^.first;
      source_bounds_ptr := source_bounds_list_ptr^.first;
      while (source_bounds_ptr <> nil) do
        begin
          array_bounds_ptr^.min_val := source_bounds_ptr^.min_val;
          array_bounds_ptr^.max_val := source_bounds_ptr^.max_val;
          array_bounds_ptr := array_bounds_ptr^.next;
          source_bounds_ptr := source_bounds_ptr^.next;
        end;
    end
  else
    Error('array bounds dimensions mismatch');
end; {procedure Set_array_bounds_list}


function Array_bounds_to_size(array_bounds_list_ptr:
  array_bounds_list_ptr_type): heap_index_type;
var
  array_bounds_ptr: array_bounds_ptr_type;
  size: heap_index_type;
begin
  size := 0;

  if (array_bounds_list_ptr <> nil) then
    begin
      array_bounds_ptr := array_bounds_list_ptr^.first;
      size := 1;
      while (array_bounds_ptr <> nil) do
        begin
          size := size * (array_bounds_ptr^.max_val - array_bounds_ptr^.min_val
            + 1);
          array_bounds_ptr := array_bounds_ptr^.next;
        end;
      array_bounds_list_ptr^.size := size;
    end;

  Array_bounds_to_size := size;
end; {function Array_bounds_to_size}


{**************************************}
{ routines to create array index lists }
{**************************************}


procedure Init_array_index(array_index_ptr: array_index_ptr_type);
begin
  with array_index_ptr^ do
    begin
      index_expr_ptr := nil;
      index_val := 0;
      array_bounds_ref := nil;
      array_index_index := 0;
      next := nil;
      prev := nil;
    end;
end; {procedure Init_array_index}


function New_array_index: array_index_ptr_type;
var
  array_index_ptr: array_index_ptr_type;
  index: integer;
begin
  {********************************}
  { get array index from free list }
  {********************************}
  if (array_index_free_list <> nil) then
    begin
      array_index_ptr := array_index_free_list;
      array_index_free_list := array_index_free_list^.next;
    end
  else
    begin
      index := array_index_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new array index block');
          new(array_index_block_ptr);
        end;
      array_index_ptr := @array_index_block_ptr^[index];
    end;

  {*******************************}
  { increment array index counter }
  {*******************************}
  array_index_counter := array_index_counter + 1;

  {************************}
  { initialize array index }
  {************************}
  Init_array_index(array_index_ptr);

  New_array_index := array_index_ptr;
end; {function New_array_index}


procedure Init_array_index_list(array_index_list_ptr: array_index_list_ptr_type;
  max_indices: integer);
begin
  array_index_list_ptr^.max_indices := max_indices;
  with array_index_list_ptr^ do
    begin
      indices := 0;
      first := nil;
      last := nil;
      array_index_list_index := 0;
      next := nil;
    end;
end; {procedure Init_array_index_list}


function New_array_index_list(max_indices: integer): array_index_list_ptr_type;
var
  array_index_list_ptr: array_index_list_ptr_type;
  index: integer;
begin
  {*************************************}
  { get array index list from free list }
  {*************************************}
  if (array_index_list_free_list <> nil) then
    begin
      array_index_list_ptr := array_index_list_free_list;
      array_index_list_free_list := array_index_list_free_list^.next;
    end
  else
    begin
      index := array_index_list_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new array index list block');
          new(array_index_list_block_ptr);
        end;
      array_index_list_ptr := @array_index_list_block_ptr^[index];
    end;

  {************************************}
  { increment array index list counter }
  {************************************}
  array_index_list_counter := array_index_list_counter + 1;

  {*****************************}
  { initialize array index list }
  {*****************************}
  Init_array_index_list(array_index_list_ptr, max_indices);

  New_array_index_list := array_index_list_ptr;
end; {function New_array_index_list}


procedure Add_array_index(array_index_list_ptr: array_index_list_ptr_type;
  array_index_ptr: array_index_ptr_type);
begin
  array_index_list_ptr^.indices := array_index_list_ptr^.indices + 1;
  if (array_index_list_ptr^.indices <= array_index_list_ptr^.max_indices) then
    begin
      {************************}
      { insert at tail of list }
      {************************}
      array_index_ptr^.next := nil;
      array_index_ptr^.prev := array_index_list_ptr^.last;

      if (array_index_list_ptr^.last = nil) then
        begin
          array_index_list_ptr^.first := array_index_ptr;
          array_index_list_ptr^.last := array_index_ptr;
        end
      else
        begin
          array_index_list_ptr^.last^.next := array_index_ptr;
          array_index_list_ptr^.last := array_index_ptr;
        end;
    end
  else
    Error('too many array indices');
end; {function Add_array_index}


procedure Set_array_index_list(array_index_list_ptr: array_index_list_ptr_type;
  source_index_list_ptr: array_index_list_ptr_type);
var
  array_index_ptr: array_index_ptr_type;
  source_index_ptr: array_index_ptr_type;
begin
  if (array_index_list_ptr^.indices = source_index_list_ptr^.indices) then
    begin
      array_index_ptr := array_index_list_ptr^.first;
      source_index_ptr := source_index_list_ptr^.first;
      while (source_index_ptr <> nil) do
        begin
          array_index_ptr^.index_val := source_index_ptr^.index_val;
          array_index_ptr := array_index_ptr^.next;
          source_index_ptr := source_index_ptr^.next;
        end;
    end
  else
    Error('index list elements mismatch');
end; {procedure Set_array_index_list}


{**********************************************************}
{ routines for allocating and initializing array subranges }
{**********************************************************}


function New_array_subrange: array_subrange_ptr_type;
var
  array_subrange_ptr: array_subrange_ptr_type;
  index: integer;
begin
  {***********************************}
  { get array subrange from free list }
  {***********************************}
  if (array_subrange_free_list <> nil) then
    begin
      array_subrange_ptr := array_subrange_free_list;
      array_subrange_free_list := array_subrange_free_list^.next;
    end
  else
    begin
      index := array_subrange_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new array subrange block');
          new(array_subrange_block_ptr);
        end;
      array_subrange_ptr := @array_subrange_block_ptr^[index];
    end;

  {**********************************}
  { increment array subrange counter }
  {**********************************}
  array_subrange_counter := array_subrange_counter + 1;

  {***************************}
  { initialize array subrange }
  {***************************}
  Init_array_subrange(array_subrange_ptr);

  New_array_subrange := array_subrange_ptr;
end; {function New_array_subrange}


procedure Init_array_subrange(array_subrange_ptr: array_subrange_ptr_type);
begin
  with array_subrange_ptr^ do
    begin
      array_expr_ptr := nil;
      array_base_ref := nil;
      array_bounds_ref := nil;
      array_derefs := 0;
      next := nil;
    end;
end; {procedure Init_array_subrange}


{***************************************}
{ routines for creating array subranges }
{***************************************}


procedure Add_array_subrange(array_bounds_list_ptr: array_bounds_list_ptr_type;
  array_index_list_ptr: array_index_list_ptr_type;
  array_bounds_ptr: array_bounds_ptr_type);
var
  array_index_ptr: array_index_ptr_type;
begin
  {************************}
  { create new array index }
  {************************}
  array_index_ptr := New_array_index;

  {*****************************}
  { link array bounds and index }
  {*****************************}
  array_bounds_ptr^.array_index_ref := array_index_ptr;
  array_index_ptr^.array_bounds_ref := array_bounds_ptr;

  {*******************************}
  { add to bounds and index lists }
  {*******************************}
  Add_array_bounds(array_bounds_list_ptr, array_bounds_ptr);
  Add_array_index(array_index_list_ptr, array_index_ptr);
end; {procedure Add_array_subrange}


procedure Link_array_bounds_index_list(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  array_index_list_ptr: array_index_list_ptr_type);
var
  array_bounds_ptr: array_bounds_ptr_type;
  array_index_ptr: array_index_ptr_type;
begin
  {************************************************}
  { link array bounds to unspecified array indices }
  {************************************************}
  array_bounds_ptr := array_bounds_list_ptr^.first;
  array_index_ptr := array_index_list_ptr^.first;

  while (array_bounds_ptr <> nil) and (array_index_ptr <> nil) do
    begin
      if (array_index_ptr^.index_expr_ptr = nil) then
        begin
          array_bounds_ptr^.array_index_ref := array_index_ptr;
          array_index_ptr^.array_bounds_ref := array_bounds_ptr;
          array_bounds_ptr := array_bounds_ptr^.next;
          array_index_ptr := array_index_ptr^.next;
        end
      else
        array_index_ptr := array_index_ptr^.next;
    end;
end; {procedure Link_array_bounds_index_list}


{***********************************}
{ routines for freeing array bounds }
{***********************************}


procedure Free_array_bounds(var array_bounds_ptr: array_bounds_ptr_type);
begin
  if array_bounds_ptr <> nil then
    begin
      {*******************************}
      { add array bounds to free list }
      {*******************************}
      array_bounds_ptr^.next := array_bounds_free_list;
      array_bounds_free_list := array_bounds_ptr;
      array_bounds_ptr := nil;

      {********************************}
      { decrement array bounds counter }
      {********************************}
      array_bounds_counter := array_bounds_counter - 1;
    end;
end; {procedure Free_array_bounds}


procedure Free_array_bounds_list(var array_bounds_list_ptr:
  array_bounds_list_ptr_type);
begin
  if array_bounds_list_ptr <> nil then
    begin
      {************************************}
      { add array bounds list to free list }
      {************************************}
      array_bounds_list_ptr^.next := array_bounds_list_free_list;
      array_bounds_list_free_list := array_bounds_list_ptr;
      array_bounds_list_ptr := nil;

      {*************************************}
      { decrement array bounds list counter }
      {*************************************}
      array_bounds_list_counter := array_bounds_list_counter - 1;
    end;
end; {procedure Free_array_bounds_list}


{************************************}
{ routines for freeing array indices }
{************************************}


procedure Free_array_index(var array_index_ptr: array_index_ptr_type);
begin
  if array_index_ptr <> nil then
    begin
      {******************************}
      { add array index to free list }
      {******************************}
      array_index_ptr^.next := array_index_free_list;
      array_index_free_list := array_index_ptr;
      array_index_ptr := nil;

      {*******************************}
      { decrement array index counter }
      {*******************************}
      array_index_counter := array_index_counter - 1;
    end;
end; {procedure Free_array_index}


procedure Free_array_index_list(var array_index_list_ptr:
  array_index_list_ptr_type);
begin
  if array_index_list_ptr <> nil then
    begin
      {***********************************}
      { add array index list to free list }
      {***********************************}
      array_index_list_ptr^.next := array_index_list_free_list;
      array_index_list_free_list := array_index_list_ptr;
      array_index_list_ptr := nil;

      {************************************}
      { decrement array index list counter }
      {************************************}
      array_index_list_counter := array_index_list_counter - 1;
    end;
end; {procedure Free_array_index_list}


{**************************************}
{ routines for freeing array subranges }
{**************************************}


procedure Free_array_subrange(var array_subrange_ptr: array_subrange_ptr_type);
begin
  if array_subrange_ptr <> nil then
    begin
      {*********************************}
      { add array subrange to free list }
      {*********************************}
      array_subrange_ptr^.next := array_subrange_free_list;
      array_subrange_free_list := array_subrange_ptr;
      array_subrange_ptr := nil;

      {**********************************}
      { decrement array subrange counter }
      {**********************************}
      array_subrange_counter := array_subrange_counter - 1;
    end;
end; {procedure Free_array_subrange}


{***********************************}
{ routines for copying array bounds }
{***********************************}


function Copy_array_bounds(array_bounds_ptr: array_bounds_ptr_type):
  array_bounds_ptr_type;
var
  new_bounds_ptr: array_bounds_ptr_type;
begin
  if (array_bounds_ptr <> nil) then
    begin
      new_bounds_ptr := New_array_bounds;
      new_bounds_ptr^ := array_bounds_ptr^;

      with new_bounds_ptr^ do
        begin
          next := nil;
          prev := nil;
        end;

      array_bounds_ptr := new_bounds_ptr;
    end;

  Copy_array_bounds := array_bounds_ptr;
end; {function Copy_array_bounds}


function Copy_array_bounds_list(array_bounds_list_ptr:
  array_bounds_list_ptr_type): array_bounds_list_ptr_type;
var
  new_list_ptr: array_bounds_list_ptr_type;
  new_bounds_ptr, follow: array_bounds_ptr_type;
begin
  if (array_bounds_list_ptr <> nil) then
    begin
      new_list_ptr := New_array_bounds_list;
      new_list_ptr^ := array_bounds_list_ptr^;
      new_list_ptr^.first := nil;
      new_list_ptr^.last := nil;
      new_list_ptr^.next := nil;

      follow := array_bounds_list_ptr^.first;
      while (follow <> nil) do
        begin
          new_bounds_ptr := Copy_array_bounds(follow);
          new_bounds_ptr^.prev := array_bounds_list_ptr^.last;

          with new_list_ptr^ do
            if last <> nil then
              begin
                last^.next := new_bounds_ptr;
                last := new_bounds_ptr;
              end
            else
              begin
                first := new_bounds_ptr;
                last := new_bounds_ptr;
              end;

          follow := follow^.next;
        end;
    end
  else
    new_list_ptr := nil;

  Copy_array_bounds_list := new_list_ptr;
end; {function Copy_array_bounds_list}


{************************************}
{ routines for copying array indices }
{************************************}


function Copy_array_index(array_index_ptr: array_index_ptr_type):
  array_index_ptr_type;
var
  new_index_ptr: array_index_ptr_type;
begin
  if (array_index_ptr <> nil) then
    begin
      new_index_ptr := New_array_index;
      new_index_ptr^ := array_index_ptr^;

      with new_index_ptr^ do
        begin
          next := nil;
          prev := nil;
        end;

      array_index_ptr := new_index_ptr;
    end;

  Copy_array_index := array_index_ptr;
end; {function Copy_array_index}


function Copy_array_index_list(array_index_list_ptr: array_index_list_ptr_type):
  array_index_list_ptr_type;
var
  new_list_ptr: array_index_list_ptr_type;
  new_index_ptr, follow: array_index_ptr_type;
begin
  if (array_index_list_ptr <> nil) then
    begin
      new_list_ptr := New_array_index_list(array_index_list_ptr^.max_indices);
      new_list_ptr^ := array_index_list_ptr^;
      new_list_ptr^.first := nil;
      new_list_ptr^.last := nil;
      new_list_ptr^.next := nil;

      follow := array_index_list_ptr^.first;
      while (follow <> nil) do
        begin
          new_index_ptr := Copy_array_index(follow);
          new_index_ptr^.prev := array_index_list_ptr^.last;

          with new_list_ptr^ do
            if last <> nil then
              begin
                last^.next := new_index_ptr;
                last := new_index_ptr;
              end
            else
              begin
                first := new_index_ptr;
                last := new_index_ptr;
              end;

          follow := follow^.next;
        end;
    end
  else
    new_list_ptr := nil;

  Copy_array_index_list := new_list_ptr;
end; {function Copy_array_index_list}


{**************************************}
{ routines for copying array subranges }
{**************************************}


function Copy_array_subrange(array_subrange_ptr: array_subrange_ptr_type):
  array_subrange_ptr_type;
var
  new_subrange_ptr: array_subrange_ptr_type;
begin
  if (array_subrange_ptr <> nil) then
    begin
      new_subrange_ptr := New_array_subrange;
      new_subrange_ptr^ := array_subrange_ptr^;

      with new_subrange_ptr^ do
        begin
          next := nil;
        end;

      array_subrange_ptr := new_subrange_ptr;
    end;

  Copy_array_subrange := array_subrange_ptr;
end; {function Copy_array_subrange}


{**********************************************************}
{ routines for finding the number of array nodes allocated }
{**********************************************************}


function Array_bounds_count: longint;
begin
  Array_bounds_count := array_bounds_counter;
end; {function Array_bounds_count}


function Array_bounds_list_count: longint;
begin
  Array_bounds_list_count := array_bounds_list_counter;
end; {function Array_bounds_list_count}


function Array_index_count: longint;
begin
  Array_index_count := array_index_counter;
end; {function Array_index_count}


function Array_index_list_count: longint;
begin
  Array_index_list_count := array_index_list_counter;
end; {function Array_index_list_count}


function Array_subrange_count: longint;
begin
  Array_subrange_count := array_subrange_counter;
end; {function Array_subrange_count}


{*************************************}
{ procedures for writing array bounds }
{*************************************}


function Array_bounds_to_str(array_bounds_ptr: array_bounds_ptr_type):
  string_type;
var
  str: string_type;
begin
  str := '';
  if (array_bounds_ptr <> nil) then
    begin
      str := concat(str, Integer_to_str(array_bounds_ptr^.min_val));
      str := concat(str, '..');
      str := concat(str, Integer_to_str(array_bounds_ptr^.max_val));
    end;

  Array_bounds_to_str := str;
end; {function Array_bounds_to_str}


function Array_bounds_list_to_str(array_bounds_list_ptr:
  array_bounds_list_ptr_type): string_type;
var
  array_bounds_ptr: array_bounds_ptr_type;
  str: string_type;
begin
  str := '';
  if (array_bounds_list_ptr <> nil) then
    begin
      str := concat(str, '[');
      array_bounds_ptr := array_bounds_list_ptr^.first;
      while (array_bounds_ptr <> nil) do
        begin
          str := concat(str, Array_bounds_to_str(array_bounds_ptr));
          if (array_bounds_ptr^.next <> nil) then
            str := concat(str, ', ');
          array_bounds_ptr := array_bounds_ptr^.next;
        end;
      str := concat(str, ']');
    end;

  Array_bounds_list_to_str := str;
end; {procedure Array_bounds_list_to_str}


{**************************************}
{ procedures for writing array indices }
{**************************************}


function Array_index_to_str(array_index_ptr: array_index_ptr_type): string_type;
var
  str: string_type;
begin
  str := '';
  if (array_index_ptr <> nil) then
    if (array_index_ptr^.index_expr_ptr <> nil) then
      str := concat(str, Integer_to_str(array_index_ptr^.index_val));

  Array_index_to_str := str;
end; {procedure Array_index_to_str}


function Array_index_list_to_str(array_index_list_ptr:
  array_index_list_ptr_type): string_type;
var
  array_index_ptr: array_index_ptr_type;
  str: string_type;
begin
  str := '';
  if (array_index_list_ptr <> nil) then
    begin
      str := concat(str, '[');
      array_index_ptr := array_index_list_ptr^.first;
      while (array_index_ptr <> nil) do
        begin
          str := concat(str, Array_index_to_str(array_index_ptr));
          if (array_index_ptr^.next <> nil) then
            str := concat(str, ', ');
          array_index_ptr := array_index_ptr^.next;
        end;
      str := concat(str, ']');
    end;

  Array_index_list_to_str := str;
end; {function Array_index_list_to_str}


initialization
  {***********************}
  { initialize free lists }
  {***********************}
  array_bounds_free_list := nil;
  array_bounds_list_free_list := nil;
  array_index_free_list := nil;
  array_index_list_free_list := nil;
  array_subrange_free_list := nil;

  {***************************************}
  { initialize block allocation variables }
  {***************************************}
  array_bounds_block_ptr := nil;
  array_bounds_counter := 0;

  array_bounds_list_block_ptr := nil;
  array_bounds_list_counter := 0;

  array_index_block_ptr := nil;
  array_index_counter := 0;

  array_index_list_block_ptr := nil;
  array_index_list_counter := 0;

  array_subrange_block_ptr := nil;
  array_subrange_counter := 0;
end.
