unit compare_exprs;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            compare_exprs              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the attributes and which are       }
{       used to describe variables and types used by the        }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  expr_attributes;


{**********************************************}
{ routines for comparing expression attributes }
{**********************************************}
function Equal_expr_attributes(expr_attributes_ptr1: expr_attributes_ptr_type;
  expr_attributes_ptr2: expr_attributes_ptr_type): boolean;
function Same_expr_attributes(expr_attributes_ptr1: expr_attributes_ptr_type;
  expr_attributes_ptr2: expr_attributes_ptr_type): boolean;


implementation
uses
  type_attributes, compare_types;


{**********************************************}
{ routines for comparing expression attributes }
{**********************************************}


function Equal_expr_attributes(expr_attributes_ptr1: expr_attributes_ptr_type;
  expr_attributes_ptr2: expr_attributes_ptr_type): boolean;
var
  equal: boolean;
  base_type_attributes_ptr1, base_type_attributes_ptr2:
  type_attributes_ptr_type;
begin
  if expr_attributes_ptr1^.dimensions <> expr_attributes_ptr2^.dimensions then
    equal := false
  else
    begin
      base_type_attributes_ptr1 :=
        Unalias_type_attributes(expr_attributes_ptr1^.type_attributes_ptr);
      base_type_attributes_ptr2 :=
        Unalias_type_attributes(expr_attributes_ptr2^.type_attributes_ptr);

      if base_type_attributes_ptr1 <> nil then
        if base_type_attributes_ptr1^.kind = type_array then
          base_type_attributes_ptr1 :=
            base_type_attributes_ptr1^.base_type_attributes_ptr;

      if base_type_attributes_ptr2 <> nil then
        if base_type_attributes_ptr2^.kind = type_array then
          base_type_attributes_ptr2 :=
            base_type_attributes_ptr2^.base_type_attributes_ptr;

      equal := Equal_type_attributes(base_type_attributes_ptr1,
        base_type_attributes_ptr2);
    end;

  Equal_expr_attributes := equal;
end; {function Equal_expr_attributes}


function Same_dimensions(expr_attributes_ptr1: expr_attributes_ptr_type;
  expr_attributes_ptr2: expr_attributes_ptr_type): boolean;
var
  same: boolean;
begin
  if expr_attributes_ptr1^.dimensions = expr_attributes_ptr2^.dimensions then
    same := true
  else if expr_attributes_ptr1^.type_attributes_ptr = nil then
    same := true
  else if expr_attributes_ptr2^.type_attributes_ptr = nil then
    same := true
  else
    same := false;

  Same_dimensions := same;
end; {function Same_dimensions}


function Same_expr_attributes(expr_attributes_ptr1: expr_attributes_ptr_type;
  expr_attributes_ptr2: expr_attributes_ptr_type): boolean;
var
  same: boolean;
begin
  if expr_attributes_ptr1^.type_attributes_ptr = nil then
    same := true
  else if expr_attributes_ptr2^.type_attributes_ptr = nil then
    same := true
  else if not Same_dimensions(expr_attributes_ptr1, expr_attributes_ptr2) then
    same := false
  else
    same := Same_type_attributes(expr_attributes_ptr1^.type_attributes_ptr,
      expr_attributes_ptr2^.type_attributes_ptr);

  Same_expr_attributes := same;
end; {function Same_expr_attributes}


end.
