unit make_arrays;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            make_arrays                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module defines recursive operations which          }
{       are performed on the array syntax trees.                }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  arrays;


{**********************************************}
{ routines for recursively copying array trees }
{**********************************************}
function Clone_array_bounds(array_bounds_ptr: array_bounds_ptr_type;
  copy_attributes: boolean): array_bounds_ptr_type;
function Clone_array_bounds_list(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  copy_attributes: boolean): array_bounds_list_ptr_type;
function Clone_array_index(array_index_ptr: array_index_ptr_type;
  copy_attributes: boolean): array_index_ptr_type;
function Clone_array_index_list(array_index_list_ptr: array_index_list_ptr_type;
  copy_attributes: boolean): array_index_list_ptr_type;
function Clone_array_subrange(array_subrange_ptr: array_subrange_ptr_type;
  copy_attributes: boolean): array_subrange_ptr_type;

{**********************************************}
{ routines for recursively freeing array trees }
{**********************************************}
procedure Destroy_array_bounds(var array_bounds_ptr: array_bounds_ptr_type;
  free_attributes: boolean);
procedure Destroy_array_bounds_list(var array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  free_attributes: boolean);
procedure Destroy_array_index(var array_index_ptr: array_index_ptr_type;
  free_attributes: boolean);
procedure Destroy_array_index_list(var array_index_list_ptr:
  array_index_list_ptr_type;
  free_attributes: boolean);
procedure Destroy_array_subrange(var array_subrange_ptr:
  array_subrange_ptr_type;
  free_attributes: boolean);

{**********************************************}
{ routines for recursively marking array trees }
{**********************************************}
procedure Mark_array_bounds(array_bounds_ptr: array_bounds_ptr_type;
  touched: boolean);
procedure Mark_array_bounds_list(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  touched: boolean);
procedure Mark_array_index(array_index_ptr: array_index_ptr_type;
  touched: boolean);
procedure Mark_array_index_list(array_index_list_ptr: array_index_list_ptr_type;
  touched: boolean);
procedure Mark_array_subrange(array_subrange_ptr: array_subrange_ptr_type;
  touched: boolean);


implementation
uses
  exprs, make_exprs;


{**********************************************}
{ routines for recursively copying array trees }
{**********************************************}


function Clone_array_bounds(array_bounds_ptr: array_bounds_ptr_type;
  copy_attributes: boolean): array_bounds_ptr_type;
var
  new_bounds_ptr: array_bounds_ptr_type;
begin
  if (array_bounds_ptr <> nil) then
    begin
      new_bounds_ptr := Copy_array_bounds(array_bounds_ptr);

      with new_bounds_ptr^ do
        begin
          min_expr_ptr :=
            forward_expr_ptr_type(Clone_expr(expr_ptr_type(min_expr_ptr),
            copy_attributes));
          max_expr_ptr :=
            forward_expr_ptr_type(Clone_expr(expr_ptr_type(max_expr_ptr),
            copy_attributes));
        end;

      array_bounds_ptr := new_bounds_ptr;
    end;

  Clone_array_bounds := array_bounds_ptr;
end; {function Clone_array_bounds}


function Clone_array_bounds_list(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  copy_attributes: boolean): array_bounds_list_ptr_type;
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
          new_bounds_ptr := Clone_array_bounds(follow, copy_attributes);
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

  Clone_array_bounds_list := new_list_ptr;
end; {function Clone_array_bounds_list}


function Clone_array_index(array_index_ptr: array_index_ptr_type;
  copy_attributes: boolean): array_index_ptr_type;
var
  new_index_ptr: array_index_ptr_type;
begin
  if (array_index_ptr <> nil) then
    begin
      new_index_ptr := Copy_array_index(array_index_ptr);

      with new_index_ptr^ do
        index_expr_ptr :=
          forward_expr_ptr_type(Clone_expr(expr_ptr_type(index_expr_ptr),
          copy_attributes));

      array_index_ptr := new_index_ptr;
    end;

  Clone_array_index := array_index_ptr;
end; {function Clone_array_index}


function Clone_array_index_list(array_index_list_ptr: array_index_list_ptr_type;
  copy_attributes: boolean): array_index_list_ptr_type;
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
          new_index_ptr := Clone_array_index(follow, copy_attributes);
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

  Clone_array_index_list := new_list_ptr;
end; {function Clone_array_index_list}


function Clone_array_subrange(array_subrange_ptr: array_subrange_ptr_type;
  copy_attributes: boolean): array_subrange_ptr_type;
var
  new_subrange_ptr: array_subrange_ptr_type;
begin
  if (array_subrange_ptr <> nil) then
    begin
      new_subrange_ptr := Copy_array_subrange(array_subrange_ptr);

      with new_subrange_ptr^ do
        array_expr_ptr :=
          forward_expr_ptr_type(Clone_expr(expr_ptr_type(array_expr_ptr),
          copy_attributes));

      array_subrange_ptr := new_subrange_ptr;
    end;

  Clone_array_subrange := array_subrange_ptr;
end; {function Clone_array_subrange}


{**********************************************}
{ routines for recursively freeing array trees }
{**********************************************}


procedure Destroy_array_bounds(var array_bounds_ptr: array_bounds_ptr_type;
  free_attributes: boolean);
begin
  if array_bounds_ptr <> nil then
    begin
      {******************************}
      { free min and max expressions }
      {******************************}
      Destroy_expr(expr_ptr_type(array_bounds_ptr^.min_expr_ptr),
        free_attributes);
      Destroy_expr(expr_ptr_type(array_bounds_ptr^.max_expr_ptr),
        free_attributes);

      {*******************************}
      { add array bounds to free list }
      {*******************************}
      Free_array_bounds(array_bounds_ptr);
    end;
end; {procedure Destroy_array_bounds}


procedure Destroy_array_bounds_list(var array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  free_attributes: boolean);
var
  array_bounds_ptr: array_bounds_ptr_type;
begin
  if array_bounds_list_ptr <> nil then
    begin
      {*******************************}
      { add array bounds to free list }
      {*******************************}
      with array_bounds_list_ptr^ do
        while first <> nil do
          begin
            array_bounds_ptr := first;
            first := first^.next;
            Destroy_array_bounds(array_bounds_ptr, free_attributes);
          end;

      {************************************}
      { add array bounds list to free list }
      {************************************}
      Free_array_bounds_list(array_bounds_list_ptr);
    end;
end; {procedure Destroy_array_bounds_list}


procedure Destroy_array_index(var array_index_ptr: array_index_ptr_type;
  free_attributes: boolean);
begin
  if array_index_ptr <> nil then
    begin
      {*****************************}
      { free array index expression }
      {*****************************}
      Destroy_expr(expr_ptr_type(array_index_ptr^.index_expr_ptr),
        free_attributes);

      {******************************}
      { add array index to free list }
      {******************************}
      Free_array_index(array_index_ptr);
    end;
end; {procedure Destroy_array_index}


procedure Destroy_array_index_list(var array_index_list_ptr:
  array_index_list_ptr_type;
  free_attributes: boolean);
var
  array_index_ptr: array_index_ptr_type;
begin
  if array_index_list_ptr <> nil then
    begin
      {********************************}
      { add array indices to free list }
      {********************************}
      with array_index_list_ptr^ do
        while (first <> nil) do
          begin
            array_index_ptr := first;
            first := first^.next;
            Destroy_array_index(array_index_ptr, free_attributes);
          end;

      {***********************************}
      { add array index list to free list }
      {***********************************}
      Free_array_index_list(array_index_list_ptr);
    end;
end; {procedure Destroy_array_index_list}


procedure Destroy_array_subrange(var array_subrange_ptr:
  array_subrange_ptr_type;
  free_attributes: boolean);
begin
  if array_subrange_ptr <> nil then
    begin
      Destroy_expr(expr_ptr_type(array_subrange_ptr^.array_expr_ptr),
        free_attributes);

      {*********************************}
      { add array subrange to free list }
      {*********************************}
      Free_array_subrange(array_subrange_ptr);
    end;
end; {procedure Destroy_array_subrange}


{**********************************************}
{ routines for recursively marking array trees }
{**********************************************}


procedure Mark_array_bounds(array_bounds_ptr: array_bounds_ptr_type;
  touched: boolean);
begin
  if array_bounds_ptr <> nil then
    begin
      {******************************}
      { mark min and max expressions }
      {******************************}
      Mark_expr(expr_ptr_type(array_bounds_ptr^.min_expr_ptr), touched);
      Mark_expr(expr_ptr_type(array_bounds_ptr^.max_expr_ptr), touched);
    end;
end; {procedure Mark_array_bounds}


procedure Mark_array_bounds_list(array_bounds_list_ptr:
  array_bounds_list_ptr_type;
  touched: boolean);
var
  array_bounds_ptr: array_bounds_ptr_type;
begin
  if array_bounds_list_ptr <> nil then
    begin
      {***************************}
      { mark array bounds in list }
      {***************************}
      array_bounds_ptr := array_bounds_list_ptr^.first;
      while array_bounds_ptr <> nil do
        begin
          Mark_array_bounds(array_bounds_ptr, touched);
          array_bounds_ptr := array_bounds_ptr^.next;
        end;
    end;
end; {procedure Mark_array_bounds_list}


procedure Mark_array_index(array_index_ptr: array_index_ptr_type;
  touched: boolean);
begin
  if array_index_ptr <> nil then
    begin
      {*****************************}
      { mark array index expression }
      {*****************************}
      Mark_expr(expr_ptr_type(array_index_ptr^.index_expr_ptr), touched);
    end;
end; {procedure Mark_array_index}


procedure Mark_array_index_list(array_index_list_ptr: array_index_list_ptr_type;
  touched: boolean);
var
  array_index_ptr: array_index_ptr_type;
begin
  if array_index_list_ptr <> nil then
    begin
      {****************************}
      { mark array indices in list }
      {****************************}
      array_index_ptr := array_index_list_ptr^.first;
      while (array_index_ptr <> nil) do
        begin
          Mark_array_index(array_index_ptr, touched);
          array_index_ptr := array_index_ptr^.next;
        end;
    end;
end; {procedure Mark_array_index_list}


procedure Mark_array_subrange(array_subrange_ptr: array_subrange_ptr_type;
  touched: boolean);
begin
  if array_subrange_ptr <> nil then
    begin
      {********************************}
      { mark array subrange expression }
      {********************************}
      Mark_expr(expr_ptr_type(array_subrange_ptr^.array_expr_ptr), touched);
    end;
end; {procedure Mark_array_subrange}


end.
