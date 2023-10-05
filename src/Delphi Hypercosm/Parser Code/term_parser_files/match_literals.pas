unit match_literals;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           match_literals              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse and create       }
{       literal values.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, type_attributes, expr_attributes, exprs, tokens;


{***********************************}
{ routine to match a specific token }
{***********************************}
procedure Match(kind: token_kind_type);
procedure Match_name(var name: string_type);

{**********************************}
{ routines to match literal values }
{**********************************}
procedure Match_boolean_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Match_char_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);

procedure Match_byte_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Match_short_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);

procedure Match_integer_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Match_long_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);

procedure Match_scalar_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Match_double_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);

procedure Match_enum_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type);


implementation
uses
  symbol_tables, value_attributes, lit_attributes, tokenizer, parser;


const
  max_scalar_decimal_places = 8;
  max_double_decimal_places = 16;


  {***********************************}
  { routine to match a specific token }
  {***********************************}


procedure Match(kind: token_kind_type);
begin
  if parsing_ok then
    if next_token.kind <> kind then
      begin
        Parse_error;
        writeln('Expected ', Quotate_str(Token_kind_to_id(kind)), ' here.');
        error_reported := true;
      end
    else if (next_token.kind <> eof_tok) then
      Get_next_token;
end; {procedure Match}


procedure Match_name(var name: string_type);
begin
  if parsing_ok then
    if next_token.kind <> id_tok then
      begin
        Parse_error;
        write('Expected an identifier here.');
        error_reported := true;
      end
    else
      begin
        name := Token_to_id(next_token);
        Get_next_token;
      end;
end; {procedure Match_name}


{**********************************}
{ routines to match literal values }
{**********************************}


procedure Match_boolean_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [true_tok, false_tok];
begin
  if next_token.kind in predict_set then
    begin
      case next_token.kind of
        true_tok:
          expr_ptr := New_expr(true_val);
        false_tok:
          expr_ptr := New_expr(false_val);
      end; {case}
      expr_attributes_ptr := boolean_value_attributes_ptr;
      Get_next_token;
    end
  else
    begin
      Parse_error;
      writeln('Expected ', Quotate_str('true'), ' or ', Quotate_str('false'),
        ' here .');
      error_reported := true;
    end;
end; {procedure Match_boolean_lit}


procedure Match_char_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [string_lit_tok];
begin
  if next_token.kind in predict_set then
    begin
      expr_ptr := New_expr(char_lit);
      expr_attributes_ptr := char_value_attributes_ptr;
      with expr_ptr^ do
        begin
          if String_length(next_token.string_ptr) = 1 then
            begin
              char_val := Index_string(next_token.string_ptr, 1);
            end
          else
            begin
              Parse_error;
              writeln('Can not assign a string to a char.');
              error_reported := true;
            end;
        end; {with}
      Get_next_token;
    end
  else
    begin
      Parse_error;
      writeln('Expected a character here.');
      error_reported := true;
    end;
end; {procedure Match_char_lit}


procedure Match_byte_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [integer_lit_tok];
begin
  if next_token.kind in predict_set then
    begin
      expr_ptr := New_expr(byte_lit);
      expr_attributes_ptr := byte_value_attributes_ptr;
      expr_ptr^.byte_val := next_token.integer_val;
      Get_next_token;
    end
  else
    begin
      Parse_error;
      writeln('Expected an integer literal here.');
      error_reported := true;
    end;
end; {procedure Match_byte_lit}


procedure Match_short_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [integer_lit_tok];
begin
  if next_token.kind in predict_set then
    begin
      expr_ptr := New_expr(short_lit);
      expr_attributes_ptr := short_value_attributes_ptr;
      expr_ptr^.short_val := next_token.integer_val;
      Get_next_token;
    end
  else
    begin
      Parse_error;
      writeln('Expected an integer literal here.');
      error_reported := true;
    end;
end; {procedure Match_short_lit}


procedure Match_integer_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [integer_lit_tok];
begin
  if next_token.kind in predict_set then
    begin
      expr_ptr := New_expr(integer_lit);
      expr_attributes_ptr := integer_value_attributes_ptr;
      expr_ptr^.integer_val := next_token.integer_val;
      Get_next_token;
    end
  else
    begin
      Parse_error;
      writeln('Expected an integer literal here.');
      error_reported := true;
    end;
end; {procedure Match_integer_lit}


procedure Match_long_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [integer_lit_tok];
begin
  if next_token.kind in predict_set then
    begin
      expr_ptr := New_expr(long_lit);
      expr_attributes_ptr := long_value_attributes_ptr;
      expr_ptr^.long_val := next_token.integer_val;
      Get_next_token;
    end
  else
    begin
      Parse_error;
      writeln('Expected an integer literal here.');
      error_reported := true;
    end;
end; {procedure Match_long_lit}


procedure Match_scalar_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [scalar_lit_tok];
begin
  if next_token.kind in predict_set then
    begin
      if next_token.decimal_places > max_scalar_decimal_places then
        begin
          Parse_error;
          writeln('Literal value has too much precision for a scalar.');
          error_reported := true;
        end
      else
        begin
          expr_ptr := New_expr(scalar_lit);
          expr_ptr^.scalar_val := next_token.scalar_val;
          Set_literal_attributes(expr_ptr,
            New_literal_attributes(scalar_attributes));

          with expr_ptr^.scalar_attributes_ptr^ do
            begin
              scalar_decimal_places := next_token.decimal_places;
              scalar_exponential_notation := next_token.exponential_notation;
            end;

          expr_attributes_ptr := scalar_value_attributes_ptr;
          Get_next_token;
        end;
    end
  else
    begin
      Parse_error;
      writeln('Expected a scalar literal here.');
      error_reported := true;
    end;
end; {procedure Match_scalar_lit}


procedure Match_double_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [scalar_lit_tok];
begin
  if next_token.kind in predict_set then
    begin
      if next_token.decimal_places > max_double_decimal_places then
        begin
          Parse_error;
          writeln('Literal value has too much precision for a double.');
          error_reported := true;
        end
      else
        begin
          expr_ptr := New_expr(double_lit);
          expr_ptr^.double_val := next_token.scalar_val;
          Set_literal_attributes(expr_ptr,
            New_literal_attributes(double_attributes));

          with expr_ptr^.double_attributes_ptr^ do
            begin
              double_decimal_places := next_token.decimal_places;
              double_exponential_notation := next_token.exponential_notation;
            end;

          expr_attributes_ptr := double_value_attributes_ptr;
          Get_next_token;
        end;
    end
  else
    begin
      Parse_error;
      writeln('Expected a scalar literal here.');
      error_reported := true;
    end;
end; {procedure Match_double_lit}


procedure Match_enum_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type);
var
  symbol_table_ptr: symbol_table_ptr_type;
  id_ptr: id_ptr_type;
begin
  {*******************}
  { enum member value }
  {*******************}
  if next_token.kind = id_tok then
    begin
      symbol_table_ptr := type_attributes_ptr^.enum_table_ptr;
      if Found_id_by_name(symbol_table_ptr, id_ptr, next_token.id) then
        begin
          Get_next_token;
          expr_ptr := New_expr(enum_lit);
          expr_ptr^.enum_val := Get_id_value(id_ptr);
          expr_attributes_ptr := New_value_expr_attributes(type_attributes_ptr);
          Set_expr_attributes(expr_ptr, expr_attributes_ptr);
        end
      else
        begin
          Parse_error;
          write('This is not a member of the enumerated type, ');
          writeln(Get_id_name(type_attributes_ptr^.id_ptr), '.');
          error_reported := true;
        end;
    end

      {***********************}
      { enum non member value }
      {***********************}
  else if next_token.kind = none_tok then
    begin
      expr_ptr := New_expr(enum_lit);
      expr_ptr^.enum_val := 0;
    end

  else
    begin
      Parse_error;
      writeln('Expected an enum literal here.');
      error_reported := true;
    end;
end; {procedure Match_enum_lit}


end.
