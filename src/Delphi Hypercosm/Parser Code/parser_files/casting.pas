unit casting;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              casting                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The casting module contains routines to cast            }
{       expressions from one type to another.                   }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  type_attributes, expr_attributes, exprs, tokens, cast_literals;


procedure Cast_byte_to_short(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Cast_short_to_integer(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);

procedure Cast_integer_to_long(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Cast_integer_to_scalar(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);

procedure Cast_long_to_scalar(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Cast_long_to_double(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);

procedure Cast_scalar_to_double(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Cast_scalar_to_complex(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);


procedure Promote_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  expected_attributes_ptr: expr_attributes_ptr_type);
procedure Cast_operator_expr(operator_kind: token_kind_type;
  var left_operand_ptr, right_operand_ptr: expr_ptr_type;
  var left_attributes_ptr, right_attributes_ptr: expr_attributes_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);


implementation
uses
  complex_numbers, data_types, value_attributes, typechecker;


procedure Cast_byte_to_short(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  new_expr_ptr: expr_ptr_type;
begin
  if (expr_ptr^.kind = byte_lit) then
    Cast_byte_literal_to_short(expr_ptr)
  else
    begin
      new_expr_ptr := New_expr(byte_to_short);
      new_expr_ptr^.operand_ptr := expr_ptr;
      expr_ptr := new_expr_ptr;
    end;
  expr_attributes_ptr := byte_value_attributes_ptr;
end; {procedure Cast_byte_to_short}


procedure Cast_short_to_integer(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  new_expr_ptr: expr_ptr_type;
begin
  if (expr_ptr^.kind = short_lit) then
    Cast_short_literal_to_integer(expr_ptr)
  else
    begin
      new_expr_ptr := New_expr(short_to_integer);
      new_expr_ptr^.operand_ptr := expr_ptr;
      expr_ptr := new_expr_ptr;
    end;
  expr_attributes_ptr := integer_value_attributes_ptr;
end; {procedure Cast_short_to_integer}


procedure Cast_integer_to_long(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  new_expr_ptr: expr_ptr_type;
begin
  if (expr_ptr^.kind = integer_lit) then
    Cast_integer_literal_to_long(expr_ptr)
  else
    begin
      new_expr_ptr := New_expr(integer_to_long);
      new_expr_ptr^.operand_ptr := expr_ptr;
      expr_ptr := new_expr_ptr;
    end;
  expr_attributes_ptr := long_value_attributes_ptr;
end; {procedure Cast_integer_to_long}


procedure Cast_integer_to_scalar(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  new_expr_ptr: expr_ptr_type;
begin
  if (expr_ptr^.kind = integer_lit) then
    Cast_integer_literal_to_scalar(expr_ptr)
  else
    begin
      new_expr_ptr := New_expr(integer_to_scalar);
      new_expr_ptr^.operand_ptr := expr_ptr;
      expr_ptr := new_expr_ptr;
    end;
  expr_attributes_ptr := scalar_value_attributes_ptr;
end; {procedure Cast_integer_to_scalar}


procedure Cast_long_to_scalar(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  new_expr_ptr: expr_ptr_type;
begin
  if (expr_ptr^.kind = long_lit) then
    Cast_long_literal_to_scalar(expr_ptr)
  else
    begin
      new_expr_ptr := New_expr(long_to_scalar);
      new_expr_ptr^.operand_ptr := expr_ptr;
      expr_ptr := new_expr_ptr;
    end;
  expr_attributes_ptr := scalar_value_attributes_ptr;
end; {procedure Cast_long_to_scalar}


procedure Cast_long_to_double(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  new_expr_ptr: expr_ptr_type;
begin
  if (expr_ptr^.kind = long_lit) then
    Cast_long_literal_to_double(expr_ptr)
  else
    begin
      new_expr_ptr := New_expr(long_to_double);
      new_expr_ptr^.operand_ptr := expr_ptr;
      expr_ptr := new_expr_ptr;
    end;
  expr_attributes_ptr := double_value_attributes_ptr;
end; {procedure Cast_long_to_double}


procedure Cast_scalar_to_double(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  new_expr_ptr: expr_ptr_type;
begin
  if (expr_ptr^.kind = scalar_lit) then
    Cast_scalar_literal_to_double(expr_ptr)
  else
    begin
      new_expr_ptr := New_expr(scalar_to_double);
      new_expr_ptr^.operand_ptr := expr_ptr;
      expr_ptr := new_expr_ptr;
    end;
  expr_attributes_ptr := double_value_attributes_ptr;
end; {procedure Cast_scalar_to_double}


procedure Cast_scalar_to_complex(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  new_expr_ptr: expr_ptr_type;
begin
  if (expr_ptr^.kind = scalar_lit) then
    Cast_scalar_literal_to_complex(expr_ptr)
  else
    begin
      new_expr_ptr := New_expr(scalar_to_complex);
      new_expr_ptr^.operand_ptr := expr_ptr;
      expr_ptr := new_expr_ptr;
    end;
  expr_attributes_ptr := complex_value_attributes_ptr;
end; {procedure Cast_scalar_to_complex}


{***********************************************}
{ routines to promote a type to a 'higher' type }
{***********************************************}


procedure Promote_to_short(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if expr_attributes_ptr^.type_attributes_ptr^.kind = type_byte then
    Cast_byte_to_short(expr_ptr, expr_attributes_ptr);
end; {procedure Promote_to_short}


procedure Promote_to_integer(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  Promote_to_short(expr_ptr, expr_attributes_ptr);
  if expr_attributes_ptr^.type_attributes_ptr^.kind = type_short then
    Cast_short_to_integer(expr_ptr, expr_attributes_ptr);
end; {procedure Promote_to_integer}


procedure Promote_to_long(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  Promote_to_integer(expr_ptr, expr_attributes_ptr);
  if expr_attributes_ptr^.type_attributes_ptr^.kind = type_integer then
    Cast_integer_to_long(expr_ptr, expr_attributes_ptr);
end; {procedure Promote_to_integer}


procedure Promote_to_scalar(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  Promote_to_integer(expr_ptr, expr_attributes_ptr);
  if expr_attributes_ptr^.type_attributes_ptr^.kind = type_integer then
    Cast_integer_to_scalar(expr_ptr, expr_attributes_ptr);
  if expr_attributes_ptr^.type_attributes_ptr^.kind = type_long then
    Cast_long_to_scalar(expr_ptr, expr_attributes_ptr);
end; {procedure Promote_to_scalar}


procedure Promote_to_double(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  Promote_to_long(expr_ptr, expr_attributes_ptr);
  if expr_attributes_ptr^.type_attributes_ptr^.kind = type_long then
    Cast_long_to_double(expr_ptr, expr_attributes_ptr);
  if expr_attributes_ptr^.type_attributes_ptr^.kind = type_scalar then
    Cast_scalar_to_double(expr_ptr, expr_attributes_ptr);
end; {procedure Promote_to_double}


procedure Promote_to_complex(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  Promote_to_scalar(expr_ptr, expr_attributes_ptr);
  if expr_attributes_ptr^.type_attributes_ptr^.kind = type_scalar then
    Cast_scalar_to_complex(expr_ptr, expr_attributes_ptr);
end; {procedure Promote_to_complex}


procedure Promote_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  expected_attributes_ptr: expr_attributes_ptr_type);
var
  type_kind: type_kind_type;
begin
  type_kind := expected_attributes_ptr^.type_attributes_ptr^.kind;
  if type_kind in [type_short..type_complex] then
    case type_kind of
      type_short:
        Promote_to_short(expr_ptr, expr_attributes_ptr);
      type_integer:
        Promote_to_integer(expr_ptr, expr_attributes_ptr);
      type_long:
        Promote_to_long(expr_ptr, expr_attributes_ptr);
      type_scalar:
        Promote_to_scalar(expr_ptr, expr_attributes_ptr);
      type_double:
        Promote_to_double(expr_ptr, expr_attributes_ptr);
      type_complex:
        Promote_to_complex(expr_ptr, expr_attributes_ptr);
    end;
end; {procedure Promote_expr}


{***************************}
{ routines to cast operands }
{***************************}


procedure Unify_operands(var left_operand_ptr, right_operand_ptr: expr_ptr_type;
  var left_attributes_ptr, right_attributes_ptr: expr_attributes_ptr_type;
  return_attributes_ptr: expr_attributes_ptr_type);
var
  left_type_kind, right_type_kind: type_kind_type;
  return_type_kind: type_kind_type;
  left_promotable, right_promotable, return_promotable: boolean;
begin
  if left_attributes_ptr <> nil then
    if right_attributes_ptr <> nil then
      begin
        left_type_kind := left_attributes_ptr^.type_attributes_ptr^.kind;
        right_type_kind := right_attributes_ptr^.type_attributes_ptr^.kind;
        return_type_kind := return_attributes_ptr^.type_attributes_ptr^.kind;

        left_promotable := left_type_kind in [type_byte..type_complex];
        right_promotable := right_type_kind in [type_byte..type_complex];
        return_promotable := return_type_kind in [type_byte..type_complex];

        if left_promotable then
          if right_promotable then
            begin
              if return_promotable and (return_type_kind > left_type_kind) and
                (return_type_kind > right_type_kind) then
                begin
                  {*****************************************************}
                  { unify operands by promoting operands to return type }
                  {*****************************************************}
                  Promote_expr(right_operand_ptr, right_attributes_ptr,
                    return_attributes_ptr);
                  Promote_expr(left_operand_ptr, left_attributes_ptr,
                    return_attributes_ptr);
                end
              else
                begin
                  {**************************************************************}
                  { unify operands by promoting the lower one to the higher kind }
                  {**************************************************************}
                  if left_type_kind > right_type_kind then
                    Promote_expr(right_operand_ptr, right_attributes_ptr,
                      left_attributes_ptr)
                  else
                    Promote_expr(left_operand_ptr, left_attributes_ptr,
                      right_attributes_ptr);
                end;
            end;
      end;
end; {procedure Unify_operands}


procedure Cast_operator_expr(operator_kind: token_kind_type;
  var left_operand_ptr, right_operand_ptr: expr_ptr_type;
  var left_attributes_ptr, right_attributes_ptr: expr_attributes_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  left_kind, right_kind: type_kind_type;
  type_kind: type_kind_type;
begin
  {***********************************************************}
  { find result info kind based on operator and operand types }
  {***********************************************************}
  expr_attributes_ptr := nil;

  left_kind := left_attributes_ptr^.type_attributes_ptr^.kind;
  if right_attributes_ptr <> nil then
    right_kind := right_attributes_ptr^.type_attributes_ptr^.kind
  else
    right_kind := left_kind;

  type_kind := Result_type_kind(operator_kind, left_kind, right_kind);
  if type_kind <> type_error then
    begin
      expr_attributes_ptr := Get_prim_value_attributes(type_kind);

      if expr_attributes_ptr <> nil then
        begin
          {**********************************************}
          { cast operands to fit the resulting operation }
          {**********************************************}
          if type_kind = type_boolean then
            Unify_operands(left_operand_ptr, right_operand_ptr,
              left_attributes_ptr, right_attributes_ptr, expr_attributes_ptr)
          else
            begin
              if (left_kind = type_vector) and (right_kind in integer_type_kinds)
                then
                Promote_to_scalar(right_operand_ptr, right_attributes_ptr)
              else
                Unify_operands(left_operand_ptr, right_operand_ptr,
                  left_attributes_ptr, right_attributes_ptr, expr_attributes_ptr)
            end;
        end;
    end;
end; {procedure Cast_operand_expr}


end.
