unit eval_limits;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            eval_limits                3d       }
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
  exprs, addr_types;


{*****************************************}
{ routines to evaluate smart array limits }
{*****************************************}
function Eval_array_min(expr_ptr: expr_ptr_type;
  array_derefs: integer): integer;
function Eval_array_max(expr_ptr: expr_ptr_type;
  array_derefs: integer): integer;
function Eval_array_num(expr_ptr: expr_ptr_type;
  array_derefs: integer): integer;
procedure Eval_array_limits(expr_ptr: expr_ptr_type;
  array_derefs: integer;
  var min, max: heap_index_type);


implementation
uses
  handles, op_stacks, get_heap_data, array_limits, eval_arrays;


{***********************************}
{ routines to evaluate array limits }
{***********************************}


function Abstract_array_derefs(expr_ptr: expr_ptr_type): integer;
var
  abstract_derefs: integer;
begin
  if (expr_ptr^.kind in [boolean_array_deref..reference_array_deref]) then
    if (expr_ptr^.deref_index_list_ptr^.max_indices <>
      expr_ptr^.deref_index_list_ptr^.indices) then
      abstract_derefs := expr_ptr^.deref_index_list_ptr^.indices
    else
      abstract_derefs := 0
  else
    abstract_derefs := 0;

  Abstract_array_derefs := abstract_derefs;
end; {function Abstract_array_derefs}


function Eval_array_min(expr_ptr: expr_ptr_type;
  array_derefs: integer): integer;
var
  abstract_derefs: integer;
  handle: handle_type;
  min: integer;
begin
  abstract_derefs := Abstract_array_derefs(expr_ptr);
  if abstract_derefs <> 0 then
    begin
      array_derefs := array_derefs + abstract_derefs;
      expr_ptr := expr_ptr^.deref_base_ptr;
    end;

  Eval_array(expr_ptr);
  handle := Pop_handle_operand;
  min := Array_min(handle, array_derefs);

  if handle <> 0 then
    Free_handle(handle);

  Eval_array_min := min;
end; {function Eval_array_min}


function Eval_array_max(expr_ptr: expr_ptr_type;
  array_derefs: integer): integer;
var
  abstract_derefs: integer;
  handle: handle_type;
  max: integer;
begin
  abstract_derefs := Abstract_array_derefs(expr_ptr);
  if abstract_derefs <> 0 then
    begin
      array_derefs := array_derefs + abstract_derefs;
      expr_ptr := expr_ptr^.deref_base_ptr;
    end;

  Eval_array(expr_ptr);
  handle := Pop_handle_operand;
  max := Array_max(handle, array_derefs);

  if handle <> 0 then
    Free_handle(handle);

  Eval_array_max := max;
end; {function Eval_array_max}


function Eval_array_num(expr_ptr: expr_ptr_type;
  array_derefs: integer): integer;
var
  abstract_derefs: integer;
  handle: handle_type;
  num: integer;
begin
  abstract_derefs := Abstract_array_derefs(expr_ptr);
  if abstract_derefs <> 0 then
    begin
      array_derefs := array_derefs + abstract_derefs;
      expr_ptr := expr_ptr^.deref_base_ptr;
    end;

  Eval_array(expr_ptr);
  handle := Pop_handle_operand;
  num := Array_num(handle, array_derefs);

  if handle <> 0 then
    Free_handle(handle);

  Eval_array_num := num;
end; {function Eval_array_num}


procedure Eval_array_limits(expr_ptr: expr_ptr_type;
  array_derefs: integer;
  var min, max: heap_index_type);
var
  abstract_derefs: integer;
  handle: handle_type;
begin
  abstract_derefs := Abstract_array_derefs(expr_ptr);
  if abstract_derefs <> 0 then
    begin
      array_derefs := array_derefs + abstract_derefs;
      expr_ptr := expr_ptr^.deref_base_ptr;
    end;

  Eval_array(expr_ptr);
  handle := Pop_handle_operand;
  Get_array_limits(handle, array_derefs, min, max);

  if handle <> 0 then
    Free_handle(handle);
end; {procedure Eval_array_limits}


end.
