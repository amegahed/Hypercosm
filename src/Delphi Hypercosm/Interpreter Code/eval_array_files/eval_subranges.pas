unit eval_subranges;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           eval_subranges              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       To evaluate the expression, we interpret the syntax     }
{       tree by traversing it and performing the indicated      }
{       operation at each node.                                 }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  addr_types, arrays, exprs;


{***********************************}
{ routines to evaluate array bounds }
{***********************************}
procedure Eval_array_bounds(array_bounds_ptr: array_bounds_ptr_type);
procedure Eval_array_bounds_list(array_bounds_list_ptr:
  array_bounds_list_ptr_type);

{************************************}
{ routines to evaluate array indices }
{************************************}
procedure Eval_array_index(array_index_ptr: array_index_ptr_type);
procedure Eval_array_index_list(array_index_list_ptr:
  array_index_list_ptr_type);

{**************************************}
{ routines to evaluate array subranges }
{**************************************}
procedure Eval_array_bounds_or_limits(array_bounds_ptr: array_bounds_ptr_type;
  array_expr_ptr: expr_ptr_type;
  array_derefs: integer);
procedure Eval_array_subrange_limits(subrange_bounds_ptr: array_bounds_ptr_type;
  subrange_expr_ptr: expr_ptr_type;
  dimensions, derefs: integer);

procedure Eval_array_subrange(array_subrange_ptr: array_subrange_ptr_type);
procedure Eval_array_value_subrange(array_subrange_ptr:
  array_subrange_ptr_type);
procedure Eval_subarray_subrange(array_subrange_ptr: array_subrange_ptr_type);

{******************************************}
{ routines to free temporary array handles }
{******************************************}
procedure Free_array_subrange_handle(array_subrange_ptr:
  array_subrange_ptr_type);
procedure Free_array_value_subrange_handle(array_subrange_ptr:
  array_subrange_ptr_type);

{*************************************************************}
{ routines to transfer array bounds from one array to another }
{*************************************************************}
procedure Transfer_array_bounds(lhs_array_bounds_ptr, rhs_array_bounds_ptr:
  array_bounds_ptr_type);
procedure Transfer_subrange_array_bounds(lhs_subrange_ptr, rhs_subrange_ptr:
  expr_ptr_type;
  subrange_bounds_ptr: array_bounds_ptr_type);


implementation
uses
  errors, heaps, handles, get_heap_data, get_data, set_data, op_stacks,
  eval_limits, eval_integers, eval_addrs, eval_arrays;


{***********************************}
{ routines to evaluate array bounds }
{***********************************}


procedure Eval_array_bounds(array_bounds_ptr: array_bounds_ptr_type);
begin
  {***********************************}
  { evaluate array bounds expressions }
  {***********************************}
  with array_bounds_ptr^ do
    begin
      if min_expr_ptr <> nil then
        begin
          Eval_integer(expr_ptr_type(min_expr_ptr));
          min_val := Pop_integer_operand;
        end;
      if max_expr_ptr <> nil then
        begin
          Eval_integer(expr_ptr_type(max_expr_ptr));
          max_val := Pop_integer_operand;
        end;
    end;
end; {procedure Eval_array_bounds}


procedure Eval_array_bounds_list(array_bounds_list_ptr:
  array_bounds_list_ptr_type);
var
  array_bounds_ptr: array_bounds_ptr_type;
begin
  {***********************************}
  { evaluate array bounds expressions }
  {***********************************}
  array_bounds_ptr := array_bounds_list_ptr^.first;
  while (array_bounds_ptr <> nil) do
    begin
      Eval_array_bounds(array_bounds_ptr);
      array_bounds_ptr := array_bounds_ptr^.next;
    end;
end; {procedure Eval_array_bounds_list}


{************************************}
{ routines to evaluate array indices }
{************************************}


procedure Eval_array_index(array_index_ptr: array_index_ptr_type);
begin
  with array_index_ptr^ do
    begin
      Eval_integer(expr_ptr_type(index_expr_ptr));
      index_val := Pop_integer_operand;
    end;
end; {procedure Eval_array_index}


procedure Eval_array_index_list(array_index_list_ptr:
  array_index_list_ptr_type);
var
  array_index_ptr: array_index_ptr_type;
begin
  {**********************************}
  { evaluate array index expressions }
  {**********************************}
  array_index_ptr := array_index_list_ptr^.first;
  while (array_index_ptr <> nil) do
    begin
      if (array_index_ptr^.index_expr_ptr <> nil) then
        Eval_array_index(array_index_ptr);
      array_index_ptr := array_index_ptr^.next;
    end;
end; {procedure Eval_array_index_list}


{**************************************}
{ routines to evaluate array subranges }
{**************************************}


procedure Eval_array_bounds_or_limits(array_bounds_ptr: array_bounds_ptr_type;
  array_expr_ptr: expr_ptr_type;
  array_derefs: integer);
begin
  if array_bounds_ptr = nil then
    Error('nil array bounds');

  with array_bounds_ptr^ do
    begin
      if (min_expr_ptr <> nil) or (max_expr_ptr <> nil) then
        begin
          {***************************}
          { evaluate bounds or limits }
          {***************************}
          Eval_array_bounds(array_bounds_ptr);

          if min_expr_ptr = nil then
            min_val := Eval_array_min(array_expr_ptr, array_derefs);

          if max_expr_ptr = nil then
            max_val := Eval_array_max(array_expr_ptr, array_derefs);
        end
      else
        begin
          {***********************************}
          { evaluate limits, bounds undefined }
          {***********************************}
          Eval_array_limits(array_expr_ptr, array_derefs, min_val, max_val);
        end;

      {**************************************************}
      { for future reference, let index be first element }
      {**************************************************}
      array_index_ref^.index_val := min_val;
    end;
end; {procedure Eval_array_bounds_or_limits}


procedure Eval_array_subrange_limits(subrange_bounds_ptr: array_bounds_ptr_type;
  subrange_expr_ptr: expr_ptr_type;
  dimensions, derefs: integer);
var
  array_bounds_list_ptr: array_bounds_list_ptr_type;
  array_bounds_ptr: array_bounds_ptr_type;
  counter: integer;
begin
  array_bounds_ptr := subrange_bounds_ptr;

  for counter := 1 to dimensions do
    begin
      Eval_array_bounds_or_limits(array_bounds_ptr,
        subrange_expr_ptr^.subrange_base_ptr, derefs);
      array_bounds_ptr := array_bounds_ptr^.next;
      derefs := derefs + 1;

      {*******************}
      { dereference array }
      {*******************}
      if (array_bounds_ptr = nil) and (counter < dimensions) then
        begin
          subrange_expr_ptr := subrange_expr_ptr^.subrange_element_ref;
          array_bounds_list_ptr := subrange_expr_ptr^.subrange_bounds_list_ptr;
          array_bounds_ptr := array_bounds_list_ptr^.first;
          derefs := 0;
        end;
    end;
end; {procedure Eval_array_subrange_limits}


procedure Transfer_array_bounds(lhs_array_bounds_ptr, rhs_array_bounds_ptr:
  array_bounds_ptr_type);
var
  min_unspecified, max_unspecified: boolean;
  lhs_min, lhs_max, rhs_min, rhs_max: integer;
begin
  min_unspecified := (lhs_array_bounds_ptr^.min_expr_ptr = nil);
  max_unspecified := (lhs_array_bounds_ptr^.max_expr_ptr = nil);

  if min_unspecified or max_unspecified then
    begin
      rhs_min := rhs_array_bounds_ptr^.min_val;
      rhs_max := rhs_array_bounds_ptr^.max_val;

      {****************************}
      { set lhs min and max values }
      {****************************}
      if min_unspecified and max_unspecified then
        begin
          lhs_array_bounds_ptr^.min_val := rhs_min;
          lhs_array_bounds_ptr^.max_val := rhs_max;
        end

          {**********************************************}
          { set lhs min from lhs max and rhs min and max }
          {**********************************************}
      else if min_unspecified then
        begin
          lhs_max := lhs_array_bounds_ptr^.max_val;
          lhs_array_bounds_ptr^.min_val := lhs_max - (rhs_max - rhs_min);
        end

          {**********************************************}
          { set lhs max from lhs min and rhs min and max }
          {**********************************************}
      else if max_unspecified then
        begin
          lhs_min := lhs_array_bounds_ptr^.min_val;
          lhs_array_bounds_ptr^.max_val := lhs_min + (rhs_max - rhs_min);
        end;

    end;
end; {procedure Transfer_array_bounds}


procedure Transfer_subrange_array_bounds(lhs_subrange_ptr, rhs_subrange_ptr:
  expr_ptr_type;
  subrange_bounds_ptr: array_bounds_ptr_type);
var
  lhs_array_bounds_list_ptr: array_bounds_list_ptr_type;
  rhs_array_bounds_list_ptr: array_bounds_list_ptr_type;

  lhs_array_bounds_ptr: array_bounds_ptr_type;
  rhs_array_bounds_ptr: array_bounds_ptr_type;

  dimensions, counter: integer;
begin
  lhs_array_bounds_list_ptr := lhs_subrange_ptr^.subrange_bounds_list_ptr;
  lhs_array_bounds_ptr := lhs_array_bounds_list_ptr^.first;
  rhs_array_bounds_ptr := subrange_bounds_ptr;

  dimensions := lhs_subrange_ptr^.subrange_bounds_list_ptr^.dimensions;

  for counter := 1 to dimensions do
    begin
      Transfer_array_bounds(lhs_array_bounds_ptr, rhs_array_bounds_ptr);
      lhs_array_bounds_ptr := lhs_array_bounds_ptr^.next;
      rhs_array_bounds_ptr := rhs_array_bounds_ptr^.next;

      {*******************}
      { dereference array }
      {*******************}
      if (rhs_array_bounds_ptr = nil) and (counter < dimensions) then
        begin
          rhs_subrange_ptr := rhs_subrange_ptr^.subrange_element_ref;
          rhs_array_bounds_list_ptr :=
            rhs_subrange_ptr^.subrange_bounds_list_ptr;
          rhs_array_bounds_ptr := rhs_array_bounds_list_ptr^.first;
        end;
    end;
end; {procedure Transfer_subrange_array_bounds}


{**************************************}
{ routines to evaluate subrange arrays }
{**************************************}


procedure Eval_array_subrange(array_subrange_ptr: array_subrange_ptr_type);
var
  addr: addr_type;
begin
  with array_subrange_ptr^ do
    begin
      if array_expr_ptr <> nil then
        begin
          Eval_addr(expr_ptr_type(array_expr_ptr));
          addr := Pop_addr_operand;
          expr_ref_type(array_base_ref)^.array_base_addr := addr;
          expr_ref_type(array_base_ref)^.array_base_handle :=
            Get_addr_handle(addr);
        end;
      Eval_array_bounds_or_limits(array_bounds_ref,
        expr_ref_type(array_base_ref), array_derefs);
    end;
end; {procedure Eval_array_subrange}


procedure Eval_array_value_subrange(array_subrange_ptr:
  array_subrange_ptr_type);
var
  handle: handle_type;
begin
  with array_subrange_ptr^ do
    begin
      if array_expr_ptr <> nil then
        begin
          Eval_array(expr_ptr_type(array_expr_ptr));
          handle := Pop_handle_operand;
          expr_ref_type(array_base_ref)^.array_base_handle := handle;
        end;
      Eval_array_bounds_or_limits(array_bounds_ref,
        expr_ref_type(array_base_ref), array_derefs);
    end;
end; {procedure Eval_array_value_subrange}


procedure Eval_subarray_subrange(array_subrange_ptr: array_subrange_ptr_type);
var
  handle: handle_type;
begin
  with array_subrange_ptr^ do
    begin
      if array_expr_ptr <> nil then
        begin
          Eval_array(expr_ptr_type(array_expr_ptr));
          handle := Pop_handle_operand;
          expr_ref_type(array_base_ref)^.array_base_handle := handle;
        end;
    end;
end; {procedure Eval_subarray_subrange}


{******************************************}
{ routines to free temporary array handles }
{******************************************}


procedure Free_array_subrange_handle(array_subrange_ptr:
  array_subrange_ptr_type);
begin
  with array_subrange_ptr^ do
    begin
      if array_expr_ptr <> nil then
        begin
          Free_addr(expr_ref_type(array_base_ref)^.array_base_addr);
          expr_ref_type(array_base_ref)^.array_base_handle := 0;
        end;
    end;
end; {procedure Free_array_subrange_handle}


procedure Free_array_value_subrange_handle(array_subrange_ptr:
  array_subrange_ptr_type);
begin
  with array_subrange_ptr^ do
    begin
      if array_expr_ptr <> nil then
        begin
          if expr_ref_type(array_base_ref)^.array_base_handle <> 0 then
            Free_handle(expr_ref_type(array_base_ref)^.array_base_handle);
        end;
    end;
end; {procedure Free_array_value_subrange_handle}


end.
