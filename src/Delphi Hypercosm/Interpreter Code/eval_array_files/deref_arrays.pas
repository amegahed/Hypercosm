unit deref_arrays;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            deref_arrays               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module has routines for dereferencing arrays       }
{       to find the element at a particular index.              }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, addr_types, arrays, exprs;


{********************************}
{ routines to dereference arrays }
{********************************}
function Deref_array(handle: handle_type;
  array_index_list_ptr: array_index_list_ptr_type;
  element_size: integer): heap_index_type;
function Deref_row_array(handle: handle_type;
  index: integer;
  element_size: integer): heap_index_type;

{************************************}
{ routine to dereference char arrays }
{************************************}
function Get_string_from_handle(handle: handle_type): string_type;


implementation
uses
  errors, get_heap_data, array_limits, eval_limits, interpreter;


{********************************}
{ routines to dereference arrays }
{********************************}


function Deref_array(handle: handle_type;
  array_index_list_ptr: array_index_list_ptr_type;
  element_size: integer): heap_index_type;
var
  array_index_ptr: array_index_ptr_type;
  index, array_index: heap_index_type;
  min, max, multiplier: heap_index_type;
  dimension: integer;
begin
  if (handle <> 0) then
    begin
      dimension := array_index_list_ptr^.max_indices;
      array_index := Get_handle_heap_index(handle, 1);
      index := 1;

      array_index_ptr := array_index_list_ptr^.first;
      while (array_index_ptr <> nil) do
        begin
          {*****************}
          { bounds checking }
          {*****************}
          min := Get_handle_heap_index(handle, index + 1);
          max := Get_handle_heap_index(handle, index + 2);

          if (array_index_ptr^.index_val < min) or (array_index_ptr^.index_val >
            max) then
            begin
              writeln('Can not access element ', array_index_ptr^.index_val: 1);
              writeln('of an array with min = ', min: 1, ', max = ', max: 1,
                '.');
              Runtime_error('Array index out of range.');
            end;

          {*****************}
          { find multiplier }
          {*****************}
          if (dimension = 1) then
            multiplier := 1
          else
            multiplier := Get_handle_heap_index(handle, index + 3);

          {*******************}
          { array dereference }
          {*******************}
          array_index := array_index + ((array_index_ptr^.index_val - min) *
            multiplier) * element_size;

          {**********************}
          { go to next dimension }
          {**********************}
          dimension := dimension - 1;
          index := index + 3;
          array_index_ptr := array_index_ptr^.next;
        end; {while}
    end
  else
    begin
      Runtime_error('Can not dereference a nil array.');
      array_index := 0;
    end;

  Deref_array := array_index;
end; {function Deref_array}


function Deref_row_array(handle: handle_type;
  index: integer;
  element_size: integer): heap_index_type;
var
  array_index: heap_index_type;
  min, max: heap_index_type;
begin
  {*****************}
  { bounds checking }
  {*****************}
  min := Get_handle_heap_index(handle, 2);
  max := Get_handle_heap_index(handle, 3);

  if (index < min) or (index > max) then
    begin
      writeln('Can not access element ', index: 1);
      writeln('of an array with min = ', min: 1, ', max = ', max: 1, '.');
      Runtime_error('Array index out of range.');
    end;

  {*******************}
  { array dereference }
  {*******************}
  array_index := 4 + ((index - min) * element_size);

  Deref_row_array := array_index;
end; {function Deref_row_array}


{************************************}
{ routine to dereference char arrays }
{************************************}


function Get_string_from_handle(handle: handle_type): string_type;
var
  char_num, char_index, counter: integer;
  str: string_type;
  ch: char;
begin
  char_num := Array_num(handle, 0);
  str := '';

  if char_num <> 0 then
    begin
      char_index := Get_handle_heap_index(handle, 1);
      for counter := 0 to (char_num - 1) do
        begin
          ch := Get_handle_char(handle, char_index + counter);
          Append_char_to_str(ch, str);
        end;
    end;

  Get_string_from_handle := str;
end; {function Get_string_from_handle}


end.
