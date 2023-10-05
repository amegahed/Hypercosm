unit expr_subtrees;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            expr_subtrees              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is used to navigage an expression           }
{       tree and to extract sub expressions.                    }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  exprs;


type
  {**************************************************}
  { These types are used to control the direction of }
  { sub expression searches. One type determines the }
  { up - down hierarchical direction of the search,  }
  { the other determines the left - right lateral    }
  { direction of the search.                         }
  {**************************************************}
  {                                                  }
  {                         *                        }
  {     lateral            / \     hierarchical  ^   }
  {    direction          *   *     direction    |   }
  {       <->            / \                     v   }
  {  (base, element)    *   *      (sub, super)      }
  {                                                  }
  {**************************************************}
  sub_expr_member_kind_type = (base_sub_expr, element_sub_expr);


  {*****************************************}
  { routines for extracting sub expressions }
  {*****************************************}
function Sub_expr(expr_ptr: expr_ptr_type;
  sub_expr_member_kind: sub_expr_member_kind_type): expr_ptr_type;
function First_sub_expr(expr_ptr: expr_ptr_type;
  sub_expr_member_kind: sub_expr_member_kind_type;
  expr_kind_set: expr_kind_set_type): expr_ptr_type;
function Last_sub_expr(expr_ptr: expr_ptr_type;
  sub_expr_member_kind: sub_expr_member_kind_type;
  expr_kind_set: expr_kind_set_type): expr_ptr_type;

{*******************************************}
{ routines for extracting super expressions }
{*******************************************}
function Super_expr(expr_ptr: expr_ptr_type): expr_ptr_type;
function First_super_expr(expr_ptr: expr_ptr_type;
  expr_kind_set: expr_kind_set_type): expr_ptr_type;
function Last_super_expr(expr_ptr: expr_ptr_type;
  expr_kind_set: expr_kind_set_type): expr_ptr_type;


implementation


{*****************************************}
{ routines for extracting sub expressions }
{*****************************************}


function Sub_expr(expr_ptr: expr_ptr_type;
  sub_expr_member_kind: sub_expr_member_kind_type): expr_ptr_type;
begin
  if expr_ptr <> nil then
    begin
      if expr_ptr^.kind in unary_operator_set then
        expr_ptr := expr_ptr^.operand_ptr

      else if expr_ptr^.kind = array_base then
        expr_ptr := expr_ptr^.array_base_expr_ref

      else if expr_ptr^.kind in nonterminal_id_set then
        case expr_ptr^.kind of

          {*************}
          { identifiers }
          {*************}
          nested_identifier:
            expr_ptr := expr_ptr^.nested_id_expr_ptr;

          {**************************}
          { identifier dereferencing }
          {**************************}
          deref_op:
            expr_ptr := expr_ptr^.operand_ptr;

          {********************}
          { array dimensioning }
          {********************}
          boolean_array_dim..reference_array_dim:
            expr_ptr := expr_ptr^.dim_element_expr_ptr;

          {*********************}
          { array dereferencing }
          {*********************}
          boolean_array_deref..reference_array_deref:
            expr_ptr := expr_ptr^.deref_base_ptr;

          {****************************}
          { array subrange expressions }
          {****************************}
          boolean_array_subrange..reference_array_subrange:
            expr_ptr := expr_ptr^.subrange_base_ptr;

          {*************************}
          { structure dereferencing }
          {*************************}
          struct_deref, struct_offset:
            case sub_expr_member_kind of
              base_sub_expr:
                expr_ptr := expr_ptr^.base_expr_ptr;
              element_sub_expr:
                expr_ptr := expr_ptr^.field_expr_ptr;
            end;
          field_deref, field_offset:
            case sub_expr_member_kind of
              base_sub_expr:
                expr_ptr := expr_ptr^.base_expr_ref;
              element_sub_expr:
                expr_ptr := expr_ptr^.field_name_ptr;
            end; {case}

        end {case}
      else
        expr_ptr := nil;
    end
  else
    expr_ptr := nil;

  Sub_expr := expr_ptr;
end; {function Sub_expr}


function First_sub_expr(expr_ptr: expr_ptr_type;
  sub_expr_member_kind: sub_expr_member_kind_type;
  expr_kind_set: expr_kind_set_type): expr_ptr_type;
var
  sub_expr_ptr: expr_ptr_type;
begin
  sub_expr_ptr := nil;

  while (sub_expr_ptr = nil) and (expr_ptr <> nil) do
    begin
      if expr_ptr <> nil then
        if expr_ptr^.kind in expr_kind_set then
          sub_expr_ptr := expr_ptr;
      expr_ptr := Sub_expr(expr_ptr, sub_expr_member_kind);
    end;

  First_sub_expr := sub_expr_ptr;
end; {function First_sub_expr}


function Last_sub_expr(expr_ptr: expr_ptr_type;
  sub_expr_member_kind: sub_expr_member_kind_type;
  expr_kind_set: expr_kind_set_type): expr_ptr_type;
var
  sub_expr_ptr: expr_ptr_type;
begin
  sub_expr_ptr := nil;

  while (expr_ptr <> nil) do
    begin
      if expr_ptr <> nil then
        if expr_ptr^.kind in expr_kind_set then
          sub_expr_ptr := expr_ptr;
      expr_ptr := Sub_expr(expr_ptr, sub_expr_member_kind);
    end;

  Last_sub_expr := sub_expr_ptr;
end; {function Last_sub_expr}


{*******************************************}
{ routines for extracting super expressions }
{*******************************************}


function Super_expr(expr_ptr: expr_ptr_type): expr_ptr_type;
begin
  if expr_ptr^.kind = array_base then
    expr_ptr := expr_ptr^.array_base_expr_ref

  else if expr_ptr^.kind in nonterminal_id_set then
    case expr_ptr^.kind of

      {*************}
      { identifiers }
      {*************}
      nested_identifier, deref_op:
        expr_ptr := nil;

      {*********************}
      { array dereferencing }
      {*********************}
      boolean_array_deref..reference_array_deref:
        expr_ptr := expr_ptr^.deref_element_ref;

      {****************************}
      { array subrange expressions }
      {****************************}
      boolean_array_subrange..reference_array_subrange:
        expr_ptr := expr_ptr^.subrange_element_ref;

      {**********************}
      { structure allocation }
      {**********************}
      struct_new:
        expr_ptr := nil;

      {*************************}
      { structure dereferencing }
      {*************************}
      struct_deref, struct_offset, field_deref, field_offset:
        expr_ptr := nil;

    end {case}
  else
    expr_ptr := nil;

  Super_expr := expr_ptr;
end; {function Super_expr}


function First_super_expr(expr_ptr: expr_ptr_type;
  expr_kind_set: expr_kind_set_type): expr_ptr_type;
var
  super_expr_ptr: expr_ptr_type;
begin
  super_expr_ptr := nil;

  while (super_expr_ptr = nil) and (expr_ptr <> nil) do
    begin
      if expr_ptr <> nil then
        if expr_ptr^.kind in expr_kind_set then
          super_expr_ptr := expr_ptr;
      expr_ptr := Super_expr(expr_ptr);
    end;

  First_super_expr := super_expr_ptr;
end; {function First_super_expr}


function Last_super_expr(expr_ptr: expr_ptr_type;
  expr_kind_set: expr_kind_set_type): expr_ptr_type;
var
  super_expr_ptr: expr_ptr_type;
begin
  super_expr_ptr := nil;

  while (expr_ptr <> nil) do
    begin
      if expr_ptr <> nil then
        if expr_ptr^.kind in expr_kind_set then
          super_expr_ptr := expr_ptr;
      expr_ptr := Super_expr(expr_ptr);
    end;

  Last_super_expr := super_expr_ptr;
end; {function Last_super_expr}


end.
