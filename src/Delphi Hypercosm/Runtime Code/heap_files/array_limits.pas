unit array_limits;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            array_limits               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       Contains routines for extracting the array limits       }
{	from smart arrays.					}
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  addr_types;


{*******************************************}
{ routines to query smary arrays for limits }
{*******************************************}
function Array_min(handle: handle_type;
  derefs: integer): heap_index_type;
function Array_max(handle: handle_type;
  derefs: integer): heap_index_type;
function Array_num(handle: handle_type;
  derefs: integer): heap_index_type;
procedure Get_array_limits(handle: handle_type;
  derefs: integer;
  var min, max: heap_index_type);


implementation
uses
  handles, op_stacks, get_heap_data;


{*******************************************}
{ routines to query smary arrays for limits }
{*******************************************}


function Array_min(handle: handle_type;
  derefs: integer): heap_index_type;
var
  min, index: heap_index_type;
begin
  if handle <> 0 then
    begin
      index := (derefs * 3) + 2;
      min := Get_handle_heap_index(handle, index);
    end
  else
    min := 1;

  Array_min := min;
end; {function Array_min}


function Array_max(handle: handle_type;
  derefs: integer): heap_index_type;
var
  max, index: heap_index_type;
begin
  if handle <> 0 then
    begin
      index := (derefs * 3) + 3;
      max := Get_handle_heap_index(handle, index);
    end
  else
    max := 0;

  Array_max := max;
end; {function Array_max}


function Array_num(handle: handle_type;
  derefs: integer): heap_index_type;
var
  min, max, num, index: heap_index_type;
begin
  if handle <> 0 then
    begin
      index := (derefs * 3);
      min := Get_handle_heap_index(handle, index + 2);
      max := Get_handle_heap_index(handle, index + 3);
      num := max - min + 1;
    end
  else
    num := 0;

  Array_num := num;
end; {function Array_num}


procedure Get_array_limits(handle: handle_type;
  derefs: integer;
  var min, max: heap_index_type);
var
  index: heap_index_type;
begin
  if handle <> 0 then
    begin
      index := (derefs * 3);
      min := Get_handle_heap_index(handle, index + 2);
      max := Get_handle_heap_index(handle, index + 3);
    end
  else
    begin
      min := 1;
      max := 0;
    end;
end; {procedure Get_array_limits}


end.
