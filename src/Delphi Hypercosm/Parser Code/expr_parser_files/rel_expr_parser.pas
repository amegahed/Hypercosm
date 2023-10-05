unit rel_expr_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          rel_expr_parser              3d       }
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


{**************************************************}
{ routines to parse general relational expressions }
{**************************************************}
procedure Parse_rel_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_rel_expr_tail(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);

{***********************************************************}
{ routines to parse expressions of the form: a > b and <> c }
{***********************************************************}
procedure Parse_rel_bool_term_tail(var expr_ptr: expr_ptr_type);

{**********************************************************}
{ routines to parse expressions of the form: a > b or <> c }
{**********************************************************}
procedure Parse_rel_bool_expr_tail(var expr_ptr: expr_ptr_type);


implementation
uses
  strings, type_attributes, code_attributes, decl_attributes, prim_attributes,
    value_attributes, tokens, tokenizer, parser, match_literals, term_parser,
    id_expr_parser, array_expr_parser, math_expr_parser, casting, operators,
    implicit_derefs;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


{***************************************************************}
{                     relational expressions                    }
{***************************************************************}
{       <rel_expr> ::= <math_expr> <rel_expr_tail>              }
{       <rel_expr_tail> ::= <rel_op> <math_expr> <rel_expr_tail>}
{       <rel_expr_tail> ::=                                     }
{                                                               }
{       <rel_op> ::= less_than                                  }
{       <rel_op> ::= greater_than                               }
{       <rel_op> ::= not_equal                                  }
{       <rel_op> ::= equal                                      }
{       <rel_op> ::= less_equal                                 }
{       <rel_op> ::= greater_equal                              }
{***************************************************************}


function New_num_operation(operator_kind: token_kind_type;
  var left_operand_ptr, right_operand_ptr: expr_ptr_type;
  var left_expr_attributes_ptr, right_expr_attributes_ptr:
    expr_attributes_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type): expr_ptr_type;
var
  expr_ptr: expr_ptr_type;
  left_kind, right_kind, return_kind: type_kind_type;
  expr_kind: expr_kind_type;
begin
  Deref_expr(left_operand_ptr, left_expr_attributes_ptr);
  Deref_expr(right_operand_ptr, right_expr_attributes_ptr);
  Cast_operator_expr(operator_kind, left_operand_ptr, right_operand_ptr,
    left_expr_attributes_ptr, right_expr_attributes_ptr, expr_attributes_ptr);

  if expr_attributes_ptr <> nil then
    begin
      left_kind := left_expr_attributes_ptr^.type_attributes_ptr^.kind;
      if right_expr_attributes_ptr <> nil then
        right_kind := right_expr_attributes_ptr^.type_attributes_ptr^.kind
      else
        right_kind := left_kind;
      return_kind := expr_attributes_ptr^.type_attributes_ptr^.kind;

      expr_kind := Num_operator_expr_kind(operator_kind, left_kind, right_kind,
        return_kind);
      expr_ptr := New_expr(expr_kind);

      expr_ptr^.left_operand_ptr := left_operand_ptr;
      expr_ptr^.right_operand_ptr := right_operand_ptr;
    end
  else
    expr_ptr := nil;

  New_num_operation := expr_ptr;
end; {procedure New_num_operation}


function New_sym_operation(operator_kind: token_kind_type;
  var left_operand_ptr, right_operand_ptr: expr_ptr_type;
  var left_expr_attributes_ptr, right_expr_attributes_ptr:
    expr_attributes_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type): expr_ptr_type;
var
  expr_ptr: expr_ptr_type;
  operand_kind: type_kind_type;
  expr_kind: expr_kind_type;
begin
  Deref_expr(left_operand_ptr, left_expr_attributes_ptr);
  Deref_expr(right_operand_ptr, right_expr_attributes_ptr);

  if expr_attributes_ptr <> nil then
    begin
      operand_kind := left_expr_attributes_ptr^.type_attributes_ptr^.kind;
      expr_kind := Sym_rel_operator_expr_kind(operator_kind, operand_kind);
      expr_ptr := New_expr(expr_kind);

      expr_ptr^.left_operand_ptr := left_operand_ptr;
      expr_ptr^.right_operand_ptr := right_operand_ptr;
      expr_attributes_ptr := boolean_value_attributes_ptr;
    end
  else
    expr_ptr := nil;

  New_sym_operation := expr_ptr;
end; {procedure New_sym_operation}


{**************************************************}
{ routines to parse general relational expressions }
{**************************************************}


{************************  productions  ************************}
{       <rel_expr_tail> ::= <rel_op> <math_expr> <rel_expr_tail>}
{***************************************************************}

procedure Parse_num_rel_expr_tail(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  operator_kind: token_kind_type;
  left_operand_ptr, right_operand_ptr: expr_ptr_type;
  left_expr_attributes_ptr, right_expr_attributes_ptr: expr_attributes_ptr_type;
  left_expr_ptr, right_expr_ptr: expr_ptr_type;
begin
  if parsing_ok then
    if next_token.kind in num_rel_predict_set then
      begin
        operator_kind := next_token.kind;
        Get_next_token;

        if (expr_ptr^.kind in rel_op_set) then
          begin
            {***************************************}
            { unparse expression in the format:     }
            { <expr> <rel_op> <expr> <rel_op <expr> }
            { ex: (0 < a < 1)                       }
            {***************************************}

            {**************************}
            { make left rel expression }
            {**************************}
            left_expr_ptr := expr_ptr;

            {***************************}
            { make right rel expression }
            {***************************}
            left_operand_ptr := left_expr_ptr^.right_operand_ptr;
            left_expr_attributes_ptr := Get_expr_attributes(left_operand_ptr);
            right_expr_attributes_ptr := left_expr_attributes_ptr;
            Parse_math_expr(right_operand_ptr, right_expr_attributes_ptr);

            if parsing_ok then
              begin
                right_expr_ptr := New_num_operation(operator_kind,
                  left_operand_ptr, right_operand_ptr, left_expr_attributes_ptr,
                  right_expr_attributes_ptr, expr_attributes_ptr);
                if expr_attributes_ptr = boolean_value_attributes_ptr then
                  begin
                    {********************}
                    { make and operation }
                    {********************}
                    expr_ptr := New_expr(and_op);
                    expr_ptr^.left_operand_ptr := left_expr_ptr;
                    expr_ptr^.right_operand_ptr := right_expr_ptr;
                    expr_ptr^.implicit_and := true;
                  end
                else
                  begin
                    Parse_error;
                    writeln('Invalid relational operator.');
                    error_reported := true;
                  end;
              end;
          end
        else
          begin
            {*************************************}
            { make relational expression operands }
            {*************************************}
            left_operand_ptr := expr_ptr;
            left_expr_attributes_ptr := expr_attributes_ptr;
            right_expr_attributes_ptr := expr_attributes_ptr;
            Parse_math_expr(right_operand_ptr, right_expr_attributes_ptr);

            if parsing_ok then
              begin
                expr_ptr := New_num_operation(operator_kind, left_operand_ptr,
                  right_operand_ptr, left_expr_attributes_ptr,
                  right_expr_attributes_ptr, expr_attributes_ptr);
                if (expr_attributes_ptr <> boolean_value_attributes_ptr) then
                  begin
                    Parse_error;
                    writeln('Invalid relational operator.');
                    error_reported := true;
                  end;
              end;

            expr_attributes_ptr := boolean_value_attributes_ptr;
            if next_token.kind in rel_predict_set then
              Parse_rel_expr_tail(expr_ptr, expr_attributes_ptr);
          end;
      end
    else
      begin
        Parse_error;
        writeln('Expected a relational operator here.');
        error_reported := true;
      end;
end; {procedure Parse_num_rel_expr_tail}


{************************  productions  ************************}
{       <rel_expr_tail> ::= <rel_op> <math_expr> <rel_expr_tail>}
{***************************************************************}

procedure Parse_sym_rel_expr_tail(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  operator_kind: token_kind_type;
  left_operand_ptr, right_operand_ptr: expr_ptr_type;
  left_expr_attributes_ptr, right_expr_attributes_ptr: expr_attributes_ptr_type;
  left_expr_ptr, right_expr_ptr: expr_ptr_type;
begin
  if parsing_ok then
    if next_token.kind in sym_rel_predict_set then
      begin
        operator_kind := next_token.kind;
        Get_next_token;

        if (expr_ptr^.kind in rel_op_set) then
          begin
            {***************************************}
            { unparse expression in the format:     }
            { <expr> <rel_op> <expr> <rel_op <expr> }
            { ex: (a isn't b isn't c)               }
            {***************************************}

            {**************************}
            { make left rel expression }
            {**************************}
            left_expr_ptr := expr_ptr;

            {***************************}
            { make right rel expression }
            {***************************}
            left_operand_ptr := left_expr_ptr^.right_operand_ptr;
            left_expr_attributes_ptr := Get_expr_attributes(left_operand_ptr);
            right_expr_attributes_ptr := left_expr_attributes_ptr;
            Parse_math_expr(right_operand_ptr, right_expr_attributes_ptr);

            if parsing_ok then
              begin
                right_expr_ptr := New_sym_operation(operator_kind,
                  left_operand_ptr, right_operand_ptr, left_expr_attributes_ptr,
                  right_expr_attributes_ptr, expr_attributes_ptr);
                if expr_attributes_ptr = boolean_value_attributes_ptr then
                  begin
                    {********************}
                    { make and operation }
                    {********************}
                    expr_ptr := New_expr(and_op);
                    expr_ptr^.left_operand_ptr := left_expr_ptr;
                    expr_ptr^.right_operand_ptr := right_expr_ptr;
                    expr_ptr^.implicit_and := true;
                  end
                else
                  begin
                    Parse_error;
                    writeln('Invalid relational operator.');
                    error_reported := true;
                  end;
              end;
          end
        else
          begin
            {*************************************}
            { make relational expression operands }
            {*************************************}
            Deref_expr(expr_ptr, expr_attributes_ptr);
            left_operand_ptr := expr_ptr;
            left_expr_attributes_ptr := expr_attributes_ptr;
            right_expr_attributes_ptr := expr_attributes_ptr;
            Parse_math_expr(right_operand_ptr, right_expr_attributes_ptr);

            if parsing_ok then
              begin
                expr_ptr := New_sym_operation(operator_kind, left_operand_ptr,
                  right_operand_ptr, left_expr_attributes_ptr,
                  right_expr_attributes_ptr, expr_attributes_ptr);
                if (expr_attributes_ptr <> boolean_value_attributes_ptr) then
                  begin
                    Parse_error;
                    writeln('Invalid relational operator.');
                    error_reported := true;
                  end;
              end;

            expr_attributes_ptr := boolean_value_attributes_ptr;
            if next_token.kind in rel_predict_set then
              Parse_rel_expr_tail(expr_ptr, expr_attributes_ptr);
          end;
      end
    else
      begin
        Parse_error;
        writeln('Expected a relational operator here.');
        error_reported := true;
      end;
end; {procedure Parse_sym_rel_expr_tail}


{************************  productions  ************************}
{       <rel_expr_tail> ::= <rel_op> <math_expr> <rel_expr_tail>}
{***************************************************************}

procedure Parse_ref_rel_expr_tail(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  left_operand_ptr, right_operand_ptr: expr_ptr_type;
  left_expr_attributes_ptr, right_expr_attributes_ptr: expr_attributes_ptr_type;
  left_expr_ptr, right_expr_ptr: expr_ptr_type;
  refers_not: boolean;
begin
  if parsing_ok then
    if next_token.kind in ref_rel_predict_set then
      begin
        refers_not := false;
        Get_next_token;

        if next_token.kind = not_tok then
          begin
            Get_next_token;
            refers_not := true;
          end;

        Match(to_tok);

        if (expr_ptr^.kind in rel_op_set) then
          begin
            {***************************************}
            { unparse expression in the format:     }
            { <expr> <rel_op> <expr> <rel_op <expr> }
            { ex: (a refers to b refers to c)       }
            {***************************************}

            {**************************}
            { make left rel expression }
            {**************************}
            left_expr_ptr := expr_ptr;

            {***************************}
            { make right rel expression }
            {***************************}
            left_operand_ptr := left_expr_ptr^.right_operand_ptr;
            left_expr_attributes_ptr := Get_expr_attributes(left_operand_ptr);
            right_expr_attributes_ptr := left_expr_attributes_ptr;
            Parse_math_expr(right_operand_ptr, right_expr_attributes_ptr);

            if parsing_ok then
              begin
                if refers_not then
                  right_expr_ptr := New_expr(reference_not_equal)
                else
                  right_expr_ptr := New_expr(reference_equal);

                right_expr_ptr^.left_operand_ptr := left_operand_ptr;
                right_expr_ptr^.right_operand_ptr := right_operand_ptr;

                {********************}
                { make and operation }
                {********************}
                expr_ptr := New_expr(and_op);
                expr_ptr^.left_operand_ptr := left_expr_ptr;
                expr_ptr^.right_operand_ptr := right_expr_ptr;
                expr_ptr^.implicit_and := true;
              end;
          end
        else
          begin
            {*************************************}
            { make relational expression operands }
            {*************************************}
            left_operand_ptr := expr_ptr;
            right_expr_attributes_ptr := expr_attributes_ptr;
            Parse_math_expr(right_operand_ptr, right_expr_attributes_ptr);

            if parsing_ok then
              begin
                if refers_not then
                  expr_ptr := New_expr(reference_not_equal)
                else
                  expr_ptr := New_expr(reference_equal);

                expr_ptr^.left_operand_ptr := left_operand_ptr;
                expr_ptr^.right_operand_ptr := right_operand_ptr;
              end;
          end;

        expr_attributes_ptr := boolean_value_attributes_ptr;
        if next_token.kind = refers_tok then
          Parse_rel_expr_tail(expr_ptr, expr_attributes_ptr);
      end
    else
      begin
        Parse_error;
        writeln('Expected a relational reference operator here.');
        error_reported := true;
      end;
end; {procedure Parse_ref_rel_expr_tail}


procedure Parse_rel_expr_tail(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if next_token.kind in rel_predict_set then
    begin
      if next_token.kind in num_rel_predict_set then
        Parse_num_rel_expr_tail(expr_ptr, expr_attributes_ptr)
      else if next_token.kind in sym_rel_predict_set then
        Parse_sym_rel_expr_tail(expr_ptr, expr_attributes_ptr)
      else if next_token.kind in ref_rel_predict_set then
        Parse_ref_rel_expr_tail(expr_ptr, expr_attributes_ptr);
    end;
end; {procedure Parse_rel_expr_tail}


{************************  productions  ************************}
{       <rel_expr> ::= <math_expr> <rel_expr_tail>              }
{***************************************************************}

procedure Parse_rel_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  expected_kind: type_kind_type;
begin
  if parsing_ok then
    begin
      if expr_attributes_ptr <> nil then
        expected_kind := expr_attributes_ptr^.type_attributes_ptr^.kind
      else
        expected_kind := type_boolean;

      Parse_math_expr(expr_ptr, expr_attributes_ptr);
      if not (expected_kind in math_type_kinds) then
        if next_token.kind in rel_predict_set then
          Parse_rel_expr_tail(expr_ptr, expr_attributes_ptr);
    end;
end; {procedure Parse_rel_expr}


function Rel_expr_type_kind(expr_ptr: expr_ptr_type): type_kind_type;
var
  type_kind: type_kind_type;
begin
  if expr_ptr^.kind in [and_op, or_op] then
    type_kind := Rel_expr_type_kind(expr_ptr^.left_operand_ptr)
  else
    with expr_ptr^ do
      if kind in boolean_rel_op_set then
        type_kind := type_boolean
      else if kind in char_rel_op_set then
        type_kind := type_char
      else if kind in integer_rel_op_set then
        type_kind := type_integer
      else if kind in scalar_rel_op_set then
        type_kind := type_scalar
      else if kind in complex_rel_op_set then
        type_kind := type_complex
      else if kind in vector_rel_op_set then
        type_kind := type_vector
      else
        type_kind := type_error;

  Rel_expr_type_kind := type_kind;
end; {function Rel_expr_type_kind}


{***********************************************************}
{ routines to parse expressions of the form: a > b and <> c }
{***********************************************************}


procedure Parse_rel_bool_term_tail(var expr_ptr: expr_ptr_type);
var
  rel_term_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  type_kind: type_kind_type;
begin
  if expr_ptr^.kind in rel_op_set + [and_op] then
    begin
      rel_term_ptr := New_expr(and_op);
      rel_term_ptr^.left_operand_ptr := expr_ptr;
      rel_term_ptr^.right_operand_ptr := New_expr(implicit_expr);
      rel_term_ptr^.right_operand_ptr^.implicit_expr_ref :=
        expr_ptr^.left_operand_ptr;

      {***********************************************************}
      { parse ptr expressions of the form: (a is b and isn't nil) }
      {***********************************************************}
      if expr_ptr^.kind in ptr_rel_op_set + proto_rel_op_set then
        begin
          expr_attributes_ptr :=
            Get_expr_attributes(expr_ptr^.left_operand_ptr);
          if next_token.kind in rel_predict_set then
            Parse_rel_expr_tail(rel_term_ptr^.right_operand_ptr,
              expr_attributes_ptr);
        end

          {****************************************************}
          { parse ptr expressions of the form: (a > b and < c) }
          {****************************************************}
      else
        begin
          type_kind := Rel_expr_type_kind(expr_ptr);
          expr_attributes_ptr := Get_prim_value_attributes(type_kind);
          if next_token.kind in rel_predict_set then
            Parse_rel_expr_tail(rel_term_ptr^.right_operand_ptr,
              expr_attributes_ptr);
        end;

      expr_ptr := rel_term_ptr;
    end
  else
    begin
      Parse_error;
      writeln('Expected a relational expression here.');
      error_reported := true;
    end;
end; {procedure Parse_rel_bool_term_tail}


{**********************************************************}
{ routines to parse expressions of the form: a > b or <> c }
{**********************************************************}


procedure Parse_rel_bool_expr_tail(var expr_ptr: expr_ptr_type);
var
  rel_term_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  type_kind: type_kind_type;
begin
  if expr_ptr^.kind in rel_op_set + [or_op] then
    begin
      rel_term_ptr := New_expr(or_op);
      rel_term_ptr^.left_operand_ptr := expr_ptr;
      rel_term_ptr^.right_operand_ptr := New_expr(implicit_expr);
      rel_term_ptr^.right_operand_ptr^.implicit_expr_ref :=
        expr_ptr^.left_operand_ptr;

      {**********************************************************}
      { parse ptr expressions of the form: (a is b or isn't nil) }
      {**********************************************************}
      if expr_ptr^.kind in ptr_rel_op_set + proto_rel_op_set then
        begin
          expr_attributes_ptr :=
            Get_expr_attributes(expr_ptr^.left_operand_ptr);
          if next_token.kind in rel_predict_set then
            Parse_rel_expr_tail(rel_term_ptr^.right_operand_ptr,
              expr_attributes_ptr);
        end

          {***************************************************}
          { parse ptr expressions of the form: (a > b or < c) }
          {***************************************************}
      else
        begin
          type_kind := Rel_expr_type_kind(expr_ptr);
          expr_attributes_ptr := Get_prim_value_attributes(type_kind);
          if next_token.kind in rel_predict_set then
            Parse_rel_expr_tail(rel_term_ptr^.right_operand_ptr,
              expr_attributes_ptr);
        end;

      expr_ptr := rel_term_ptr;
    end
  else
    begin
      Parse_error;
      writeln('Expected a relational expression here.');
      error_reported := true;
    end;
end; {procedure Parse_rel_bool_expr_tail}


end.
