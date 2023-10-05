unit instruct_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           instruct_parser             3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse built in         }
{       statements into an abstract syntax tree                 }
{       representation.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  stmts;


procedure Parse_instructs(var stmt_ptr, last_stmt_ptr: stmt_ptr_type);


implementation
uses
  type_attributes, expr_attributes, value_attributes, compare_exprs, exprs,
    instructs, tokens, tokenizer, parser, match_literals, comment_parser,
    term_parser, expr_parser, implicit_derefs;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


{***************************************************************}
{                  input / output statements                    }
{***************************************************************}
{       <io_stmt> ::= <read_stmt>                               }
{       <io_stmt> ::= <readln_stmt>                             }
{       <io_stmt> ::= <write_stmt>                              }
{       <io_stmt> ::= <writln_stmt>                             }
{       <io_stmt> ::= <fread_stmt>                              }
{       <io_stmt> ::= <freadln_stmt>                            }
{       <io_stmt> ::= <fwrite_stmt>                             }
{       <io_stmt> ::= <fwriteln_stmt>                           }
{                                                               }
{       <read_stmt> ::= read <read_things> ;                    }
{       <readln_stmt> ::= readln <read_things> ;                }
{       <read_things> ::= <read_thing> <more_read_things>       }
{       <more_read_things> ::= , <read_thing>                   }
{       <more_read_things> ::                                   }
{       <read_thing> ::= id                                     }
{                                                               }
{       <write_stmt> ::= write <write_things> ;                 }
{       <writeln_stmt> ::= writeln <write_things> ;             }
{       <write_things> ::= <write_thing> <more_write_things>    }
{       <more_write_things> ::= , <write_thing>                 }
{       <more_write_things> ::=                                 }
{       <write_thing> ::= <expr>                                }
{                                                               }
{       <fread_stmt> ::= fread integer <read_things> ;          }
{       <freadln_stmt> ::= fread integer <read_things> ;        }
{                                                               }
{       <fwrite_stmt> ::= fwrite integer <write_things> ;       }
{       <fwriteln_stmt> ::= fwriteln integer <write_things> ;   }
{                                                               }
{       <fclose_stmt> ::= fclose integer ;                      }
{***************************************************************}


{***************************************************************}
{                  input / output statements                    }
{***************************************************************}
{       <io_stmt> ::= <read_stmt>                               }
{       <io_stmt> ::= <write_stmt>                              }
{                                                               }
{       <io_stmt> ::= <fread_stmt>                              }
{       <io_stmt> ::= <fwrite_stmt>                             }
{***************************************************************}


function New_prim_read_instruct(kind: type_kind_type): instruct_ptr_type;
var
  instruct_ptr: instruct_ptr_type;
begin
  case kind of

    {******************}
    { enumerated types }
    {******************}
    type_boolean:
      instruct_ptr := New_instruct(boolean_read);
    type_char:
      instruct_ptr := New_instruct(char_read);

    {***************}
    { integer types }
    {***************}
    type_byte:
      instruct_ptr := New_instruct(byte_read);
    type_short:
      instruct_ptr := New_instruct(short_read);
    type_integer:
      instruct_ptr := New_instruct(integer_read);
    type_long:
      instruct_ptr := New_instruct(long_read);

    {**************}
    { scalar types }
    {**************}
    type_scalar:
      instruct_ptr := New_instruct(scalar_read);
    type_double:
      instruct_ptr := New_instruct(double_read);
    type_complex:
      instruct_ptr := New_instruct(complex_read);
    type_vector:
      instruct_ptr := New_instruct(vector_read);

  else
    instruct_ptr := nil;
  end; {case}

  New_prim_read_instruct := instruct_ptr;
end; {function New_prim_read_instruct}


{************************  productions  ************************}
{       <read_stmt> ::= read <expr> ;                           }
{***************************************************************}

procedure Parse_read_stmt(var stmt_ptr: stmt_ptr_type);
var
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  instruct_ptr: instruct_ptr_type;
  stmt_info_ptr: stmt_info_ptr_type;
begin
  if parsing_ok then
    begin
      Get_prev_stmt_info(stmt_info_ptr);

      {****************}
      { parse argument }
      {****************}
      if not (next_token.kind in [comma_tok, semi_colon_tok]) then
        begin
          expr_attributes_ptr := nil;
          Parse_expr(expr_ptr, expr_attributes_ptr);

          {********************************}
          { create reference to expression }
          {********************************}
          Check_reference_attributes(expr_attributes_ptr);
          Reference_expr(expr_ptr, expr_attributes_ptr);
        end
      else
        expr_ptr := nil;

      {*****************************************************}
      { create new instruction depending upon argument type }
      {*****************************************************}
      instruct_ptr := nil;
      if expr_ptr <> nil then
        begin
          if expr_attributes_ptr^.dimensions = 0 then
            begin
              type_attributes_ptr :=
                Deref_type_attributes(expr_attributes_ptr^.type_attributes_ptr);
              if type_attributes_ptr^.kind in primitive_type_kinds then
                begin
                  instruct_ptr :=
                    New_prim_read_instruct(type_attributes_ptr^.kind);
                  instruct_ptr^.argument_ptr := expr_ptr;
                end

              else
                begin
                  Parse_error;
                  writeln('Invalid type for read statement.');
                  error_reported := true;
                end
            end

          else
            begin
              Parse_error;
              writeln('Invalid type for read statement.');
              error_reported := true;
            end;
        end

          {************************}
          { new line (no arguments }
          {************************}
      else
        instruct_ptr := New_instruct(write_newline);

      {**********************}
      { create new statement }
      {**********************}
      if parsing_ok then
        begin
          stmt_ptr := New_stmt(built_in_stmt);
          Set_stmt_info(stmt_ptr, stmt_info_ptr);
          stmt_ptr^.instruct_ptr := instruct_ptr;
        end;

      if not (next_token.kind in [right_paren_tok, comma_tok]) then
        Match(semi_colon_tok);

      Get_post_stmt_info(stmt_info_ptr);
    end;
end; {procedure Parse_read_stmt}


{************************  productions  ************************}
{       <read_stmt> ::= read <exprs> ;                          }
{***************************************************************}

procedure Parse_read_stmts(var stmt_ptr, last_stmt_ptr: stmt_ptr_type);
begin
  if parsing_ok then
    begin
      {****************************}
      { parse first read statement }
      {****************************}
      Match(read_tok);
      Parse_read_stmt(stmt_ptr);

      if parsing_ok then
        begin
          {******************************************}
          { parse additional reads in same statement }
          {******************************************}
          last_stmt_ptr := stmt_ptr;
          while (next_token.kind = comma_tok) and parsing_ok do
            begin
              Get_next_token;
              Parse_read_stmt(last_stmt_ptr^.next);

              if parsing_ok then
                begin
                  last_stmt_ptr^.next^.stmt_info_ptr^.stmt_number :=
                    last_stmt_ptr^.stmt_info_ptr^.stmt_number + 1;
                  last_stmt_ptr := last_stmt_ptr^.next;
                end;
            end; {while}
        end; {if}
    end;
end; {procedure Parse_read_stmts}


function New_prim_write_instruct(kind: type_kind_type): instruct_ptr_type;
var
  instruct_ptr: instruct_ptr_type;
begin
  case kind of

    {******************}
    { enumerated types }
    {******************}
    type_boolean:
      instruct_ptr := New_instruct(boolean_write);
    type_char:
      instruct_ptr := New_instruct(char_write);

    {***************}
    { integer types }
    {***************}
    type_byte:
      instruct_ptr := New_instruct(byte_write);
    type_short:
      instruct_ptr := New_instruct(short_write);
    type_integer:
      instruct_ptr := New_instruct(integer_write);
    type_long:
      instruct_ptr := New_instruct(long_write);

    {**************}
    { scalar types }
    {**************}
    type_scalar:
      instruct_ptr := New_instruct(scalar_write);
    type_double:
      instruct_ptr := New_instruct(double_write);
    type_complex:
      instruct_ptr := New_instruct(complex_write);
    type_vector:
      instruct_ptr := New_instruct(vector_write);

  else
    instruct_ptr := nil;
  end; {case}

  New_prim_write_instruct := instruct_ptr;
end; {function New_prim_write_instruct}


{************************  productions  ************************}
{       <write_stmt> ::= write <expr> ;                         }
{***************************************************************}

procedure Parse_write_stmt(var stmt_ptr: stmt_ptr_type);
var
  expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  instruct_ptr: instruct_ptr_type;
  stmt_info_ptr: stmt_info_ptr_type;
begin
  if parsing_ok then
    begin
      Get_prev_stmt_info(stmt_info_ptr);

      {****************}
      { parse argument }
      {****************}
      if not (next_token.kind in [comma_tok, semi_colon_tok]) then
        begin
          expr_attributes_ptr := nil;
          Parse_expr(expr_ptr, expr_attributes_ptr);
          Deref_expr(expr_ptr, expr_attributes_ptr);
        end
      else
        expr_ptr := nil;

      {*****************************************************}
      { create new instruction depending upon argument type }
      {*****************************************************}
      instruct_ptr := nil;
      if parsing_ok then
        if expr_ptr <> nil then
          begin
            if expr_attributes_ptr^.dimensions = 0 then
              begin
                type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
                if type_attributes_ptr^.kind in primitive_type_kinds then
                  begin
                    instruct_ptr :=
                      New_prim_write_instruct(type_attributes_ptr^.kind);
                    instruct_ptr^.argument_ptr := expr_ptr;
                  end
                else
                  begin
                    Parse_error;
                    writeln('Invalid type for write statement.');
                    error_reported := true;
                  end;
              end

                {**************}
                { string types }
                {**************}
            else if Same_expr_attributes(expr_attributes_ptr,
              string_value_attributes_ptr) then
              begin
                instruct_ptr := New_instruct(string_write);
                instruct_ptr^.argument_ptr := expr_ptr;
              end

            else
              begin
                Parse_error;
                writeln('Invalid array type for write statement.');
                error_reported := true;
              end;
          end

            {************************}
            { new line (no arguments }
            {************************}
        else
          instruct_ptr := New_instruct(write_newline);

      {**********************}
      { create new statement }
      {**********************}
      if parsing_ok then
        begin
          stmt_ptr := New_stmt(built_in_stmt);
          Set_stmt_info(stmt_ptr, stmt_info_ptr);
          stmt_ptr^.instruct_ptr := instruct_ptr;
        end;

      if not (next_token.kind in [right_paren_tok, comma_tok]) then
        Match(semi_colon_tok);

      Get_post_stmt_info(stmt_info_ptr);
    end;
end; {procedure Parse_write_stmt}


{************************  productions  ************************}
{       <write_stmts> ::= write <exprs> ;                       }
{***************************************************************}

procedure Parse_write_stmts(var stmt_ptr: stmt_ptr_type;
  var last_stmt_ptr: stmt_ptr_type);
begin
  if parsing_ok then
    begin
      {*****************************}
      { parse first write statement }
      {*****************************}
      Match(write_tok);
      Parse_write_stmt(stmt_ptr);

      if parsing_ok then
        begin
          {*******************************************}
          { parse additional writes in same statement }
          {*******************************************}
          last_stmt_ptr := stmt_ptr;
          while (next_token.kind = comma_tok) and parsing_ok do
            begin
              Get_next_token;
              Parse_write_stmt(last_stmt_ptr^.next);

              if parsing_ok then
                begin
                  last_stmt_ptr^.next^.stmt_info_ptr^.stmt_number :=
                    last_stmt_ptr^.stmt_info_ptr^.stmt_number + 1;
                  last_stmt_ptr := last_stmt_ptr^.next;
                end;
            end; {while}
        end;
    end;
end; {procedure Parse_write_stmts}


procedure Parse_instructs(var stmt_ptr, last_stmt_ptr: stmt_ptr_type);
begin
  if next_token.kind in io_stmt_predict_set then
    case next_token.kind of
      read_tok:
        Parse_read_stmts(stmt_ptr, last_stmt_ptr);
      write_tok:
        Parse_write_stmts(stmt_ptr, last_stmt_ptr);
    end {case}
  else
    begin
      Parse_error;
      writeln('Invalid built in statement.');
      error_reported := true;
    end;
end; {procedure Parse_instructs}


end.
