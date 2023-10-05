unit limit_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            limit_parser               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse array            }
{       limit queries into an abstract syntax tree              }
{       representation.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  expr_attributes, exprs;


procedure Parse_array_limit_fn(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);


implementation
uses
  type_attributes, value_attributes, make_exprs, tokens, tokenizer, parser,
    deref_parser, implicit_derefs, field_parser, term_parser;


procedure Parse_abstract_array_derefs(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [left_bracket_tok];
var
  abstract_deref: boolean;
begin
  if (next_token.kind in predict_set) and parsing_ok then
    if (expr_ptr^.kind in deref_expr_kinds) then
      case next_token.kind of

        {********************}
        { parse array derefs }
        {********************}
        left_bracket_tok:
          begin
            Parse_array_deref(expr_ptr, expr_attributes_ptr, abstract_deref);

            if parsing_ok then
              if (expr_attributes_ptr^.dimensions < 1) then
                begin
                  Parse_error;
                  writeln('An array is required here.');
                  error_reported := true;
                end;

            {*********************************************}
            { partial multidimensional array dereference: }
            { the actual array indices must be left un    }
            { specified because they are unnecessary.     }
            {*********************************************}
            if parsing_ok then
              if (expr_ptr^.kind in [boolean_array_deref..reference_array_deref])
                then
                if (expr_attributes_ptr^.dimensions <>
                  Get_data_abs_dims(expr_attributes_ptr^.type_attributes_ptr))
                  then
                  if not abstract_deref then
                    begin
                      Parse_error;
                      writeln('In specifying a subdimension of a');
                      writeln('multidimensional array, the actual');
                      writeln('array indices need not be specified.');
                      error_reported := true;
                    end;

            Parse_abstract_array_derefs(expr_ptr, expr_attributes_ptr);
          end {left_bracket}

      end {case}
    else
      begin
        Parse_error;
        writeln('Expected an identifier here.');
        error_reported := true;
      end;
end; {procedure Parse_abstract_array_derefs}


procedure Parse_abstract_array_inst(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [left_bracket_tok, s_tok];
begin
  if (next_token.kind in predict_set) and parsing_ok then
    if (expr_ptr^.kind in deref_expr_kinds) then
      case next_token.kind of

        {*********************}
        { parse struct derefs }
        {*********************}
        s_tok:
          begin
            Get_next_token;
            Parse_struct_field(expr_ptr, expr_attributes_ptr);
            Parse_abstract_array_inst(expr_ptr, expr_attributes_ptr);
          end;

        {********************}
        { parse array derefs }
        {********************}
        left_bracket_tok:
          begin
            if (expr_attributes_ptr^.dimensions > 0) then
              begin
                Parse_abstract_array_derefs(expr_ptr, expr_attributes_ptr);
                Parse_abstract_array_inst(expr_ptr, expr_attributes_ptr);
              end;
          end;

      end {case}
    else
      begin
        Parse_error;
        writeln('Expected an identifier here.');
        error_reported := true;
      end;
end; {procedure Parse_abstract_array_inst}


{************************  productions  ************************}
{       <integer_fn> ::= min <array expr>                       }
{       <integer_fn> ::= max <array expr>                       }
{       <integer_fn> ::= num <array expr>                       }
{***************************************************************}

procedure Parse_array_limit_fn(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [min_tok, max_tok, num_tok];
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        case next_token.kind of
          min_tok:
            expr_ptr := New_expr(min_fn);
          max_tok:
            expr_ptr := New_expr(max_fn);
          num_tok:
            expr_ptr := New_expr(num_fn);
        end;

        Get_next_token;

        Parse_id_inst(expr_ptr^.operand_ptr, expr_attributes_ptr);
        Deref_expr(expr_ptr^.operand_ptr, expr_attributes_ptr);
        Parse_abstract_array_inst(expr_ptr^.operand_ptr, expr_attributes_ptr);

        if parsing_ok then
          if expr_attributes_ptr^.dimensions <= 0 then
            begin
              Parse_error;
              writeln('An array is required here.');
              error_reported := true;

              Destroy_exprs(expr_ptr, true);
              expr_attributes_ptr := nil;
            end
          else
            expr_attributes_ptr := integer_value_attributes_ptr;
      end;
end; {procedure Parse_array_limit_fn}


end.
