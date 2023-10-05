unit math_expr_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           math_expr_parser            3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse expressions      }
{       into an abstract syntax tree representation.            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  expr_attributes, exprs;


{*************************************************}
{ do we allow complex doublet and vector triplet  }
{ expressions without explicit delimeting tokens: }
{                                                 }
{ example:                                        }
{          implicit: vector v = 0 0 1;            }
{          explicit: vector v = <0 0 1>;          }
{*************************************************}
const
  implicit_tuplets = false;


  {*****************************************}
  { parse a general mathematical expression }
  {*****************************************}
procedure Parse_math_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_number(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_vector_tail(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);


implementation
uses
  complex_numbers, vectors, type_attributes, lit_attributes, prim_attributes,
  value_attributes, make_exprs, tokens, tokenizer, parser, term_parser, casting,
  operators, implicit_derefs, expr_parser;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


{***************************************************************}
{                     mathematical expressions                  }
{***************************************************************}
{       <math_expr> ::= <term> <math_expr_tail>                 }
{       <math_expr_tail> ::= + <term> <math_expr_tail>          }
{       <math_expr_tail> ::= - <term> <math_expr_tail>          }
{                                                               }
{       <term> ::= <factor> <term_tail>                         }
{       <term_tail> ::= * <factor> <term_tail>                  }
{       <term_tail> ::= / <factor> <term_tail>                  }
{       <term_tail> ::= div <factor> <term_tail>                }
{       <term_tail> ::= mod <factor> <term_tail>                }
{       <term_tail> ::=                                         }
{                                                               }
{       <factor> ::= <thing> <factor_tail>                      }
{       <factor_tail> ::= dot <thing>                           }
{                                                               }
{       <thing> ::= <number> <thing_tail>                       }
{       <thing_tail> ::= cross <number> <thing_tail>            }
{                                                               }
{       <number> ::= <number> <number_tail>                     }
{       <number_tail> ::= ^ <number> <number_tail>              }
{       <number_tail> ::= <number> <number>                     }
{       <number_tail> ::=                                       }
{***************************************************************}


function New_complex_expr(var a_expr_ptr, b_expr_ptr: expr_ptr_type):
  expr_ptr_type;
var
  expr_ptr: expr_ptr_type;
  complex_val: complex_type;
  a_decimal_places, b_decimal_places: integer;
  a_exponential_notation, b_exponential_notation: boolean;
begin
  expr_ptr := New_expr(complex_pair);
  expr_ptr^.a_expr_ptr := a_expr_ptr;
  expr_ptr^.b_expr_ptr := b_expr_ptr;

  {***************************}
  { cast to a complex literal }
  {***************************}
  if (a_expr_ptr^.kind = scalar_lit) then
    if (b_expr_ptr^.kind = scalar_lit) then
      begin
        {****************************}
        { save scalar literal values }
        {****************************}
        complex_val.a := a_expr_ptr^.scalar_val;
        complex_val.b := b_expr_ptr^.scalar_val;

        {********************************}
        { save scalar literal attributes }
        {********************************}
        a_decimal_places :=
          a_expr_ptr^.scalar_attributes_ptr^.scalar_decimal_places;
        b_decimal_places :=
          b_expr_ptr^.scalar_attributes_ptr^.scalar_decimal_places;
        a_exponential_notation :=
          a_expr_ptr^.scalar_attributes_ptr^.scalar_exponential_notation;
        b_exponential_notation :=
          b_expr_ptr^.scalar_attributes_ptr^.scalar_exponential_notation;

        {*********************************}
        { free scalar literal expressions }
        {*********************************}
        Destroy_exprs(expr_ptr^.a_expr_ptr, true);
        Destroy_exprs(expr_ptr^.b_expr_ptr, true);

        {***************************************}
        { create new complex literal expression }
        {***************************************}
        expr_ptr^.kind := complex_lit;
        expr_ptr^.complex_val := complex_val;

        {***************************************}
        { create new complex literal attributes }
        {***************************************}
        Set_literal_attributes(expr_ptr,
          New_literal_attributes(complex_attributes));
        with expr_ptr^ do
          begin
            complex_attributes_ptr^.a_decimal_places := a_decimal_places;
            complex_attributes_ptr^.b_decimal_places := b_decimal_places;
            complex_attributes_ptr^.a_exponential_notation :=
              a_exponential_notation;
            complex_attributes_ptr^.b_exponential_notation :=
              b_exponential_notation;
          end;
      end;

  New_complex_expr := expr_ptr;
end; {function New_complex_expr}


function New_vector_expr(var x_expr_ptr, y_expr_ptr, z_expr_ptr: expr_ptr_type):
  expr_ptr_type;
var
  expr_ptr: expr_ptr_type;
  vector_val: vector_type;
  x_decimal_places, y_decimal_places, z_decimal_places: integer;
  x_exponential_notation, y_exponential_notation, z_exponential_notation:
  boolean;
begin
  expr_ptr := New_expr(vector_triplet);
  expr_ptr^.x_expr_ptr := x_expr_ptr;
  expr_ptr^.y_expr_ptr := y_expr_ptr;
  expr_ptr^.z_expr_ptr := z_expr_ptr;

  {**************************}
  { cast to a vector literal }
  {**************************}
  if (x_expr_ptr^.kind = scalar_lit) then
    if (y_expr_ptr^.kind = scalar_lit) then
      if (z_expr_ptr^.kind = scalar_lit) then
        begin
          {****************************}
          { save vector literal values }
          {****************************}
          vector_val.x := x_expr_ptr^.scalar_val;
          vector_val.y := y_expr_ptr^.scalar_val;
          vector_val.z := z_expr_ptr^.scalar_val;

          {********************************}
          { save scalar literal attributes }
          {********************************}
          x_decimal_places :=
            x_expr_ptr^.scalar_attributes_ptr^.scalar_decimal_places;
          y_decimal_places :=
            y_expr_ptr^.scalar_attributes_ptr^.scalar_decimal_places;
          z_decimal_places :=
            z_expr_ptr^.scalar_attributes_ptr^.scalar_decimal_places;
          x_exponential_notation :=
            x_expr_ptr^.scalar_attributes_ptr^.scalar_exponential_notation;
          y_exponential_notation :=
            y_expr_ptr^.scalar_attributes_ptr^.scalar_exponential_notation;
          z_exponential_notation :=
            z_expr_ptr^.scalar_attributes_ptr^.scalar_exponential_notation;

          {*********************************}
          { free scalar literal expressions }
          {*********************************}
          Destroy_exprs(expr_ptr^.x_expr_ptr, true);
          Destroy_exprs(expr_ptr^.y_expr_ptr, true);
          Destroy_exprs(expr_ptr^.z_expr_ptr, true);

          {**************************************}
          { create new vector literal expression }
          {**************************************}
          expr_ptr^.kind := vector_lit;
          expr_ptr^.vector_val := vector_val;

          {**************************************}
          { create new vector literal attributes }
          {**************************************}
          Set_literal_attributes(expr_ptr,
            New_literal_attributes(vector_attributes));
          with expr_ptr^ do
            begin
              vector_attributes_ptr^.x_decimal_places := x_decimal_places;
              vector_attributes_ptr^.y_decimal_places := y_decimal_places;
              vector_attributes_ptr^.z_decimal_places := z_decimal_places;
              vector_attributes_ptr^.x_exponential_notation :=
                x_exponential_notation;
              vector_attributes_ptr^.y_exponential_notation :=
                y_exponential_notation;
              vector_attributes_ptr^.z_exponential_notation :=
                z_exponential_notation;
            end;
        end;

  New_vector_expr := expr_ptr;
end; {function New_vector_expr}


procedure Parse_exponent_tail(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  expr_kind: expr_kind_type;
  operator_kind: token_kind_type;
  left_kind, right_kind, return_kind: type_kind_type;
  left_operand_ptr, right_operand_ptr: expr_ptr_type;
  left_expr_attributes_ptr, right_expr_attributes_ptr: expr_attributes_ptr_type;
begin
  if next_token.kind = up_arrow_tok then
    begin
      operator_kind := next_token.kind;
      Get_next_token;

      {************************}
      { make exponent operands }
      {************************}
      Deref_expr(expr_ptr, expr_attributes_ptr);
      left_operand_ptr := expr_ptr;
      left_expr_attributes_ptr := expr_attributes_ptr;

      Parse_equal_unit(right_operand_ptr, scalar_value_attributes_ptr);
      right_expr_attributes_ptr := scalar_value_attributes_ptr;

      if parsing_ok then
        begin
          Cast_operator_expr(operator_kind, left_operand_ptr, right_operand_ptr,
            left_expr_attributes_ptr, right_expr_attributes_ptr,
            expr_attributes_ptr);

          if expr_attributes_ptr <> nil then
            begin
              {********************}
              { make exponent node }
              {********************}
              return_kind := expr_attributes_ptr^.type_attributes_ptr^.kind;
              left_kind := left_expr_attributes_ptr^.type_attributes_ptr^.kind;
              right_kind :=
                right_expr_attributes_ptr^.type_attributes_ptr^.kind;

              expr_kind := Num_operator_expr_kind(operator_kind, left_kind,
                right_kind, return_kind);
              expr_ptr := New_expr(expr_kind);

              expr_ptr^.left_operand_ptr := left_operand_ptr;
              expr_ptr^.right_operand_ptr := right_operand_ptr;
            end
          else
            begin
              Parse_error;
              writeln('Invalid operand for ', Token_kind_to_id(operator_kind),
                '.');
              error_reported := true;

              Destroy_exprs(left_operand_ptr, true);
              Destroy_exprs(right_operand_ptr, true);

              expr_ptr := nil;
              expr_attributes_ptr := nil;
            end;

        end;
    end
end; {procedure Parse_exponent_tail}


{************************  productions  ************************}
{       <unit> ::= <unit> <unit>                                }
{***************************************************************}

procedure Parse_complex_tail(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
  a_expr_ptr: expr_ptr_type;
  b_expr_ptr: expr_ptr_type;
begin
  if parsing_ok then
    if next_token.kind in scalar_predict_set then
      begin
        type_attributes_ptr :=
          Deref_type_attributes(expr_attributes_ptr^.type_attributes_ptr);

        if type_attributes_ptr <> nil then
          if type_attributes_ptr^.kind in [type_integer, type_scalar] then
            begin
              Deref_expr(expr_ptr, expr_attributes_ptr);

              if type_attributes_ptr^.kind = type_integer then
                Cast_integer_to_scalar(expr_ptr, expr_attributes_ptr);

              {********************}
              { parse complex pair }
              {********************}
              a_expr_ptr := expr_ptr;
              Parse_equal_unit(b_expr_ptr, scalar_value_attributes_ptr);

              {*******************}
              { make complex pair }
              {*******************}
              if parsing_ok then
                begin
                  expr_ptr := New_complex_expr(a_expr_ptr, b_expr_ptr);
                  expr_attributes_ptr := complex_value_attributes_ptr;
                end; {complex}
            end;
      end;
end; {procedure Parse_complex_tail}


{************************  productions  ************************}
{       <unit> ::= <unit> <unit> <unit>                         }
{***************************************************************}

procedure Parse_vector_tail(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
  x_expr_ptr: expr_ptr_type;
  y_expr_ptr: expr_ptr_type;
  z_expr_ptr: expr_ptr_type;
begin
  if parsing_ok then
    if next_token.kind in scalar_predict_set then
      begin
        type_attributes_ptr :=
          Deref_type_attributes(expr_attributes_ptr^.type_attributes_ptr);

        if type_attributes_ptr <> nil then
          if type_attributes_ptr^.kind in [type_scalar, type_integer] then
            begin
              Deref_expr(expr_ptr, expr_attributes_ptr);

              if type_attributes_ptr^.kind = type_integer then
                Cast_integer_to_scalar(expr_ptr, expr_attributes_ptr);

              x_expr_ptr := expr_ptr;
              Parse_equal_unit(y_expr_ptr, scalar_value_attributes_ptr);

              {**********************}
              { parse vector triplet }
              {**********************}
              if next_token.kind in scalar_predict_set then
                begin
                  Parse_equal_unit(z_expr_ptr, scalar_value_attributes_ptr);

                  {*********************}
                  { make vector triplet }
                  {*********************}
                  if parsing_ok then
                    begin
                      expr_ptr := New_vector_expr(x_expr_ptr, y_expr_ptr,
                        z_expr_ptr);
                      expr_attributes_ptr := vector_value_attributes_ptr;
                    end; {vector}
                end
              else
                begin
                  expr_ptr := New_complex_expr(x_expr_ptr, y_expr_ptr);
                  expr_attributes_ptr := complex_value_attributes_ptr;
                end;
            end;
      end;
end; {procedure Parse_vector_tail}


{************************  productions  ************************}
{       <number> ::= <unit> <number_tail>                       }
{***************************************************************}

procedure Parse_number(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if parsing_ok then
    begin
      Parse_unit(expr_ptr, expr_attributes_ptr);
      Parse_exponent_tail(expr_ptr, expr_attributes_ptr);
    end;
end; {procedure Parse_number}


procedure Parse_number2(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
  expected_kind: type_kind_type;
begin
  if parsing_ok then
    begin
      if expr_attributes_ptr <> nil then
        begin
          type_attributes_ptr :=
            Deref_type_attributes(expr_attributes_ptr^.type_attributes_ptr);

          if type_attributes_ptr <> nil then
            expected_kind := type_attributes_ptr^.kind
          else
            expected_kind := type_error;
        end
      else
        expected_kind := type_error;

      Parse_unit(expr_ptr, expr_attributes_ptr);
      Parse_exponent_tail(expr_ptr, expr_attributes_ptr);

      {******************************************************}
      { parse implicit tuplets (for backwards compatibility) }
      {******************************************************}
      if not (expected_kind in [type_integer, type_scalar]) then
        Parse_vector_tail(expr_ptr, expr_attributes_ptr);
    end;
end; {procedure Parse_number2}


{************************  productions  ************************}
{       <thing_tail> ::= cross <number> <thing_tail>            }
{       <thing_tail> ::= parallel <number> <thing_tail>         }
{       <thing_tail> ::= perpendicular <number> <thing_tail>    }
{***************************************************************}

procedure Parse_thing_tail(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [cross_tok, parallel_tok, perpendicular_tok];
var
  type_attributes_ptr: type_attributes_ptr_type;
  kind: expr_kind_type;
  factor_ptr: expr_ptr_type;
  operator_kind: token_kind_type;
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        type_attributes_ptr :=
          Deref_type_attributes(expr_attributes_ptr^.type_attributes_ptr);

        if type_attributes_ptr <> vector_type_attributes_ptr then
          begin
            Parse_error;
            writeln('Expected a vector expression here.');
            error_reported := true;
          end
        else
          begin
            operator_kind := next_token.kind;
            case operator_kind of
              cross_tok:
                kind := vector_cross_product;
              parallel_tok:
                kind := vector_parallel;
              perpendicular_tok:
                kind := vector_perpendicular;
            else
              kind := error_expr;
            end; {case}

            Get_next_token;
            Deref_expr(expr_ptr, expr_attributes_ptr);
            factor_ptr := New_expr(kind);
            factor_ptr^.left_operand_ptr := expr_ptr;
            Parse_number(factor_ptr^.right_operand_ptr, expr_attributes_ptr);
            Deref_expr(factor_ptr^.right_operand_ptr, expr_attributes_ptr);

            if parsing_ok then
              begin
                if expr_attributes_ptr^.type_attributes_ptr <>
                  vector_type_attributes_ptr then
                  begin
                    Parse_error;
                    writeln('Expected a vector expression here.');
                    error_reported := true;
                  end;

                expr_ptr := factor_ptr;
                Parse_thing_tail(expr_ptr, expr_attributes_ptr);
              end;
          end
      end;
end; {procedure Parse_thing_tail}


{************************  productions  ************************}
{       <thing> ::= <number> <thing_tail>                       }
{***************************************************************}

procedure Parse_thing(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if parsing_ok then
    begin
      Parse_number(expr_ptr, expr_attributes_ptr);
      Parse_thing_tail(expr_ptr, expr_attributes_ptr);
    end;
end; {procedure Parse_thing}


{************************  productions  ************************}
{       <factor_tail> ::= dot <thing>                           }
{***************************************************************}

procedure Parse_factor_tail(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [dot_tok];
var
  type_attributes_ptr: type_attributes_ptr_type;
  factor_ptr: expr_ptr_type;
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        type_attributes_ptr :=
          Deref_type_attributes(expr_attributes_ptr^.type_attributes_ptr);

        if type_attributes_ptr <> vector_type_attributes_ptr then
          begin
            Parse_error;
            writeln('Expected a vector experession here.');
            error_reported := true;
          end
        else
          begin
            Get_next_token;

            Deref_expr(expr_ptr, expr_attributes_ptr);
            factor_ptr := New_expr(vector_dot_product);
            factor_ptr^.left_operand_ptr := expr_ptr;
            Parse_thing(factor_ptr^.right_operand_ptr, expr_attributes_ptr);
            Deref_expr(factor_ptr^.right_operand_ptr, expr_attributes_ptr);

            if parsing_ok then
              begin
                if expr_attributes_ptr^.type_attributes_ptr <>
                  vector_type_attributes_ptr then
                  begin
                    Parse_error;
                    writeln('Expected a vector expression here.');
                    error_reported := true;
                  end;

                expr_ptr := factor_ptr;
                expr_attributes_ptr := scalar_value_attributes_ptr;
              end;
          end
      end;
end; {procedure Parse_factor_tail}


{************************  productions  ************************}
{       <factor> ::= <thing> <factor_tail>                      }
{***************************************************************}

procedure Parse_factor(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if parsing_ok then
    begin
      Parse_thing(expr_ptr, expr_attributes_ptr);
      Parse_factor_tail(expr_ptr, expr_attributes_ptr);
    end;
end; {procedure Parse_factor}


{************************  productions  ************************}
{       <term_tail> ::= * <factor> <term_tail>                  }
{       <term_tail> ::= / <factor> <term_tail>                  }
{       <term_tail> ::= div <factor> <term_tail>                }
{       <term_tail> ::= mod <factor> <term_tail>                }
{       <term_tail> ::=                                         }
{***************************************************************}

procedure Parse_term_tail(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [times_tok, divide_tok, div_tok, mod_tok];
var
  expr_kind: expr_kind_type;
  operator_kind: token_kind_type;
  left_kind, right_kind, return_kind: type_kind_type;
  left_operand_ptr, right_operand_ptr: expr_ptr_type;
  left_expr_attributes_ptr, right_expr_attributes_ptr: expr_attributes_ptr_type;
begin
  if parsing_ok then
    if (next_token.kind in predict_set) then
      begin
        operator_kind := next_token.kind;
        Get_next_token;

        {********************}
        { make term operands }
        {********************}
        Deref_expr(expr_ptr, expr_attributes_ptr);
        left_operand_ptr := expr_ptr;
        left_expr_attributes_ptr := expr_attributes_ptr;
        right_expr_attributes_ptr := integer_value_attributes_ptr;
        Parse_factor(right_operand_ptr, right_expr_attributes_ptr);
        Deref_expr(right_operand_ptr, right_expr_attributes_ptr);

        if parsing_ok then
          begin
            Cast_operator_expr(operator_kind, left_operand_ptr,
              right_operand_ptr, left_expr_attributes_ptr,
              right_expr_attributes_ptr, expr_attributes_ptr);

            if expr_attributes_ptr <> nil then
              begin
                {****************}
                { make term node }
                {****************}
                left_kind :=
                  left_expr_attributes_ptr^.type_attributes_ptr^.kind;
                right_kind :=
                  right_expr_attributes_ptr^.type_attributes_ptr^.kind;
                return_kind := expr_attributes_ptr^.type_attributes_ptr^.kind;

                expr_kind := Num_operator_expr_kind(operator_kind, left_kind,
                  right_kind, return_kind);
                expr_ptr := New_expr(expr_kind);

                expr_ptr^.left_operand_ptr := left_operand_ptr;
                expr_ptr^.right_operand_ptr := right_operand_ptr;
                Parse_term_tail(expr_ptr, expr_attributes_ptr);
              end
            else
              begin
                Parse_error;
                writeln('Invalid operand for ', Token_kind_to_id(operator_kind),
                  '.');
                error_reported := true;

                Destroy_exprs(left_operand_ptr, true);
                Destroy_exprs(right_operand_ptr, true);

                expr_ptr := nil;
                expr_attributes_ptr := nil;
              end;

          end;
      end;
end; {procedure Parse_term_tail}


{************************  productions  ************************}
{       <term> ::= <factor> <term_tail>                         }
{***************************************************************}

procedure Parse_term(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if parsing_ok then
    begin
      Parse_factor(expr_ptr, expr_attributes_ptr);
      Parse_term_tail(expr_ptr, expr_attributes_ptr);
    end;
end; {procedure Parse_term}


{************************  productions  ************************}
{       <math_expr_tail> ::= + <term> <math_expr_tail>          }
{       <math_expr_tail> ::= - <term> <math_expr_tail>          }
{       <math_expr_tail> ::=                                    }
{***************************************************************}

procedure Parse_math_expr_tail(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [plus_tok, minus_tok];
var
  expr_kind: expr_kind_type;
  operator_kind: token_kind_type;
  left_kind, right_kind, return_kind: type_kind_type;
  left_operand_ptr, right_operand_ptr: expr_ptr_type;
  left_expr_attributes_ptr, right_expr_attributes_ptr: expr_attributes_ptr_type;
begin
  if parsing_ok then
    if (next_token.kind in predict_set) then
      begin
        operator_kind := next_token.kind;
        Get_next_token;

        {*******************************}
        { make math expression operands }
        {*******************************}
        Deref_expr(expr_ptr, expr_attributes_ptr);
        left_operand_ptr := expr_ptr;
        left_expr_attributes_ptr := expr_attributes_ptr;
        right_expr_attributes_ptr := nil;
        Parse_term(right_operand_ptr, right_expr_attributes_ptr);
        Deref_expr(right_operand_ptr, right_expr_attributes_ptr);

        if parsing_ok then
          begin
            Cast_operator_expr(operator_kind, left_operand_ptr,
              right_operand_ptr, left_expr_attributes_ptr,
              right_expr_attributes_ptr, expr_attributes_ptr);

            if expr_attributes_ptr <> nil then
              begin
                {***************************}
                { make math expression node }
                {***************************}
                left_kind :=
                  left_expr_attributes_ptr^.type_attributes_ptr^.kind;
                right_kind :=
                  right_expr_attributes_ptr^.type_attributes_ptr^.kind;
                return_kind := expr_attributes_ptr^.type_attributes_ptr^.kind;

                expr_kind := Num_operator_expr_kind(operator_kind, left_kind,
                  right_kind, return_kind);
                expr_ptr := New_expr(expr_kind);

                expr_ptr^.left_operand_ptr := left_operand_ptr;
                expr_ptr^.right_operand_ptr := right_operand_ptr;
                Parse_math_expr_tail(expr_ptr, expr_attributes_ptr);
              end
            else
              begin
                Parse_error;
                writeln('Invalid operand for ', Token_kind_to_id(operator_kind),
                  '.');
                error_reported := true;

                Destroy_exprs(left_operand_ptr, true);
                Destroy_exprs(right_operand_ptr, true);

                expr_ptr := nil;
                expr_attributes_ptr := nil;
              end;

          end;
      end;
end; {procedure Parse_math_expr_tail}


{************************  productions  ************************}
{       <math_expr> ::= <term> <math_expr_tail>                 }
{***************************************************************}

procedure Parse_math_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if parsing_ok then
    begin
      Parse_term(expr_ptr, expr_attributes_ptr);
      Parse_math_expr_tail(expr_ptr, expr_attributes_ptr);
    end;
end; {procedure Parse_math_expr}


end.

