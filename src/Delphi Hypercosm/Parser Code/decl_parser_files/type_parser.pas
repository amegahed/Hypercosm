unit type_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            type_parser                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse type             }
{       declarations into an abstract syntax tree               }
{       representation.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  decl_attributes, decls;


function Found_type_name(var decl_attributes_ptr: decl_attributes_ptr_type):
  boolean;
procedure Parse_type_decls(var decl_ptr: decl_ptr_type;
  var last_decl_ptr: decl_ptr_type);


implementation
uses
  strings, symbol_tables, type_attributes, stmt_attributes, expr_attributes,
  exprs, stmts, code_decls, type_decls, tokens, tokenizer, struct_assigns,
  parser, comment_parser, match_literals, match_terms, scoping, term_parser,
  data_parser, struct_parser, decl_parser, class_parser;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


{***************************************************************}
{                          declarations                         }
{***************************************************************}
{       <decl> ::= <include>                                    }
{       <decl> ::= <enum_decl>                                  }
{       <decl> ::= <alias_decl>                                 }
{       <decl> ::= <struct_decl>                                }
{       <decl> ::= <class_decl>                                 }
{                                                               }
{       <decls> ::= <decl> <more_decls>                         }
{       <decls> ::=                                             }
{       <more_decls> ::= <decls>                                }
{       <more_decls> ::=                                        }
{***************************************************************}


{***************************************************************}
{                       enum declarations                       }
{***************************************************************}
{       <enum_decl> ::= enum id = <enums> ;                     }
{       <enums> ::= <enums> <more_enums>                        }
{       <more_enums> ::= , <enums>                              }
{       <enum> ::= id                                           }
{***************************************************************}


{***************************************************************}
{                       type declarations                       }
{***************************************************************}
{       <alias_decl> ::= type id is <type> ;                    }
{***************************************************************}


{***************************************************************}
{                      struct declarations                      }
{***************************************************************}
{       <struct_decl> ::= struct id is <fields> ;               }
{       <fields> ::= <field> <more_fields>                      }
{       <more_fields> ::= , <fields>                            }
{       <fields> ::= <data_decl>                                }
{***************************************************************}


{***************************************************************}
{                        class declarations                     }
{***************************************************************}
{       <class_decl> ::= class id <methods> with <fields>       }
{                        is <decls> end;                        }
{                                                               }
{       <methods> ::= <complex_decl> <more_methods>             }
{       <more_methods> ::= <methods>                            }
{       <more_methods> ::=                                      }
{                                                               }
{       <fields> ::= <simple_decl> <more_fields>                }
{       <more_fields> ::= <fields>                              }
{       <more_fields> ::=                                       }
{***************************************************************}


const
  memory_alert = false;


procedure Match_type_name(var name: string_type);
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
        next_token.kind := type_id_tok;
        name := Token_to_id(next_token);
        Get_next_token;
      end;
end; {procedure Match_type_name}


function Found_type_name(var decl_attributes_ptr: decl_attributes_ptr_type):
  boolean;
var
  found: boolean;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
begin
  decl_attributes_ptr := nil;
  if next_token.kind in data_predict_set + subprogram_predict_set + [forward_tok]
    then
    found := true
  else
    begin
      found := false;
      if (next_token.kind = type_id_tok) then
        if Found_id(Token_to_id(next_token), decl_attributes_ptr,
          stmt_attributes_ptr) then
          if decl_attributes_ptr^.kind = type_decl_attributes then
            found := true;
    end;
  Found_type_name := found;
end; {function Found_type_name}


{************************  productions  ************************}
{       <enum> ::= id                                           }
{***************************************************************}

procedure Parse_enum(symbol_table_ptr: symbol_table_ptr_type);
var
  index: integer;
begin
  if parsing_ok then
    begin
      if next_token.kind = id_tok then
        begin
          index := Symbol_table_size(symbol_table_ptr) + 1;
          Enter_id(symbol_table_ptr, next_token.id, index);
          Get_next_token;
        end
      else
        begin
          Parse_error;
          writeln('Expected an identifier for this enum value.');
          error_reported := true;
        end;
    end;
end; {procedure Parse_enum}


{************************  productions  ************************}
{       <enums> ::= <enums> <more_enums>                        }
{       <more_enums> ::= , <enums>                              }
{***************************************************************}

procedure Parse_more_enums(symbol_table_ptr: symbol_table_ptr_type);
const
  predict_set = [comma_tok];
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        Get_next_token;
        Parse_enum(symbol_table_ptr);
        Parse_more_enums(symbol_table_ptr);
      end;
end; {procedure Parse_more_enums}


{************************  productions  ************************}
{       <enum_decl> ::= enum id = <enums> ;                     }
{       <enums> ::= <enums> <more_enums>                        }
{       <more_enums> ::= , <enums>                              }
{       <enum> ::= id                                           }
{***************************************************************}

procedure Parse_enum_decl(var decl_ptr: decl_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  decl_info_ptr: decl_info_ptr_type;
begin
  if parsing_ok then
    begin
      Get_prev_decl_info(decl_info_ptr);
      Match(enum_tok);

      {*******************************************}
      { create new type descriptor and attributes }
      {*******************************************}
      type_attributes_ptr := New_type_attributes(type_enum, true);
      type_attributes_ptr^.enum_table_ptr := New_symbol_table;
      decl_attributes_ptr := New_decl_attributes(type_decl_attributes,
        type_attributes_ptr, nil);

      {**********************}
      { create new type decl }
      {**********************}
      decl_ptr := New_decl(type_decl);
      New_type(enum_type, decl_ptr);
      Set_decl_info(decl_ptr, decl_info_ptr);

      {*****************}
      { parse type name }
      {*****************}
      Match_new_type_id(decl_attributes_ptr);

      if parsing_ok then
        begin
          {**********************************}
          { set links to and from attributes }
          {**********************************}
          Set_decl_attributes(decl_ptr, decl_attributes_ptr);

          {********************************}
          { parse body of enum declaration }
          {********************************}
          Match(is_tok);

          {******************}
          { enumerated enums }
          {******************}
          Parse_enum(type_attributes_ptr^.enum_table_ptr);
          Parse_more_enums(type_attributes_ptr^.enum_table_ptr);

          Match(semi_colon_tok);
          Get_post_decl_info(decl_info_ptr);
        end; {if parsing_ok}
    end; {if parsing_ok}
end; {procedure Parse_enum_decl}


{***************************************************************}
{                       type declarations                       }
{***************************************************************}
{       <type_decl> ::= type id is <type> ;                     }
{***************************************************************}


procedure Parse_alias_decl(var decl_ptr: decl_ptr_type);
var
  decl_info_ptr: decl_info_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  type_name: string_type;
begin
  if parsing_ok then
    begin
      Get_prev_decl_info(decl_info_ptr);
      Match(type_tok);
      Match_type_name(type_name);
      Match(is_tok);
      Parse_data_type(type_attributes_ptr);

      if parsing_ok then
        begin
          type_attributes_ptr := New_alias_type_attributes(type_attributes_ptr);

          {*******************************************}
          { create new type descriptor and attributes }
          {*******************************************}
          decl_attributes_ptr := New_decl_attributes(type_decl_attributes,
            type_attributes_ptr, nil);

          {**********************}
          { create new type decl }
          {**********************}
          decl_ptr := New_decl(type_decl);
          New_type(alias_type, decl_ptr);
          Set_decl_info(decl_ptr, decl_info_ptr);

          {******************}
          { create type name }
          {******************}
          Make_implicit_new_type_id(type_name, decl_attributes_ptr);

          {**********************************}
          { set links to and from attributes }
          {**********************************}
          Set_decl_attributes(decl_ptr, decl_attributes_ptr);

          Match(semi_colon_tok);
          Get_post_decl_info(decl_info_ptr);
        end; {if parsing_ok}
    end; {if parsing_ok}
end; {procedure Parse_alias_decl}


{************************  productions  ************************}
{       <type_decl> ::= <enum_decl>                             }
{       <type_decl> ::= <alias_decl>                            }
{       <type_decl> ::= <struct_decl>                           }
{***************************************************************}

procedure Parse_simple_type_decl(var type_decl_ptr: decl_ptr_type);
var
  token: token_type;
begin
  type_decl_ptr := nil;

  case next_token.kind of
    enum_tok:
      Parse_enum_decl(type_decl_ptr);
    type_tok:
      Parse_alias_decl(type_decl_ptr);
    struct_tok:
      Parse_struct_decl(type_decl_ptr, false);
    static_tok:
      begin
        token := next_token;
        Get_next_token;

        if next_token.kind = struct_tok then
          Parse_struct_decl(type_decl_ptr, true)
        else
          begin
            type_decl_ptr := nil;
            Put_token(token);
          end;
      end;
  end; {case}
end; {procedure Parse_simple_type_decl}


{************************  productions  ************************}
{       <type_decls> ::= <type_decl> <more_type_decls>          }
{       <more_type_decls> ::= <type_decls>                      }
{       <more_type_decls> ::=                                   }
{***************************************************************}

procedure Parse_type_decls(var decl_ptr: decl_ptr_type;
  var last_decl_ptr: decl_ptr_type);
var
  type_decl_ptr: decl_ptr_type;
  done: boolean;
begin
  decl_ptr := nil;
  last_decl_ptr := nil;
  done := false;

  while (next_token.kind in type_decl_predict_set) and (not done) and parsing_ok
    do
    begin
      type_decl_ptr := nil;

      if next_token.kind in simple_type_decl_predict_set then
        Parse_simple_type_decl(type_decl_ptr)
      else
        Parse_class_decl(type_decl_ptr);

      {******************************}
      { add type decl to end of list }
      {******************************}
      if (type_decl_ptr <> nil) then
        begin
          if (last_decl_ptr = nil) then
            begin
              decl_ptr := type_decl_ptr;
              last_decl_ptr := type_decl_ptr;
            end
          else
            begin
              last_decl_ptr^.next := type_decl_ptr;
              last_decl_ptr := type_decl_ptr;
            end;
        end
      else
        done := true;
    end; {while}
end; {procedure Parse_type_decls}


end.

