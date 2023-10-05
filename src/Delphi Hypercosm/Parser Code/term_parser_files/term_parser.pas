unit term_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            term_parser                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse terminals        }
{       into an abstract syntax tree representation.            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  decl_attributes, expr_attributes, exprs;


{********************************}
{ parsing identifier expressions }
{********************************}
procedure Parse_id_inst(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_id_fields_and_derefs(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);

{****************************************************}
{ routines for setting antecedent pronouns, 'itself' }
{****************************************************}
procedure Reset_antecedent;
procedure Set_antecedent(expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);

{**********************************************************}
{ routines for setting scope for antecedent pronoun, 'its' }
{**********************************************************}
procedure Push_antecedent_scope(expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
procedure Pop_antecedent_scope;


{***************************************************************}
{                   Types of id expressions:                    }
{***************************************************************}
{                                                               }
{ array expr id:                                                }
{ --------------                                                }
{ This type of id expr is used in expressions and assignments:  }
{                                                               }
{       a = b[10];                                              }
{       a[4] = b[1][1..10];                                     }
{       a[4, 3] = 5;                                            }
{       a[1..5] = b[4, ];                                       }
{                                                               }
{***************************************************************}
{                                                               }
{ array decl id:                                                }
{ --------------                                                }
{ This type of id expr is used in array declarations such as:   }
{                                                               }
{       integer a[1..10][1..4];                                 }
{       integer a[4, 3];                                        }
{       integer a;                                              }
{       integer b[];                                            }
{       integer b[][1.4];       // error - no specified bounds  }
{                               following empty bounds allowed  }
{                                                               }
{ Note that the bounds expressions are optional and the range   }
{ expressions are optional (dynamic arrays).                    }
{                                                               }
{***************************************************************}
{                                                               }
{ array inst id:                                                }
{ --------------                                                }
{ This type of id expr is used in min max expressions such as:  }
{                                                               }
{       i = min a;                                              }
{       i = max a[4][3];                                        }
{       i = min a[3][,];                                        }
{       i = max a[3..4];        // error - no bounds allowed    }
{                                                               }
{***************************************************************}
{                                                               }
{ array inst decl:                                              }
{ ----------------                                              }
{ This type if id expr is used in declaring the dimensions of   }
{ arrays or sub arrays.  For example:                           }
{                                                               }
{       dim a[1..3];                                            }
{       dim a[1][1..20];                                        }
{       dim a;                  // illegal - needs array bounds }
{                                                               }
{***************************************************************}


implementation
uses
  errors, strings, prim_attributes, type_attributes, arrays, type_decls,
  make_exprs, tokens, tokenizer, parser, subrange_parser, deref_parser, scoping,
  match_terms, implicit_derefs, field_parser;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


{***************************************************************}
{                            terminals                          }
{***************************************************************}
{       <unit> ::= id <array_indices> <struct_offsets>          }
{                                                               }
{       <array_indices> ::= [ <integer_expr> ] <array_indices>  }
{       <array_indices> ::=                                     }
{                                                               }
{       <struct_offsets> ::= . id <struct_offsets>              }
{       <struct_offsets> ::=                                    }
{***************************************************************}

{***************************************************************}
{                            terminals                          }
{***************************************************************}
{       <array_expr> ::= <derefs> <partial_deref> <sub_range>   }
{       <array_addr> ::= <derefs>                               }
{       <array_bounds> ::= <ranges> <unspecified_ranges>        }
{       <array_dim> ::= <derefs> <ranges>                       }
{       <array_min_max> ::= <derefs> <unspecified_deref>        }
{                                                               }
{       <range> ::=     [ <integer_expr> .. <integer_expr> ]    }
{       <unspecified_range> ::= [ ]                             }
{                                                               }
{       <deref> ::=     [ <integer_expr> ]                      }
{       <unspecified_deref> ::=  [ ]                            }
{***************************************************************}
const
  stack_size = 8;


var
  antecedent_expr_ptr: expr_ptr_type;
  antecedent_attr_ptr: expr_attributes_ptr_type;
  antecedent_scope_expr_ptr: expr_ptr_type;
  antecedent_scope_attr_ptr: expr_attributes_ptr_type;

  antecedent_stack_ptr: integer;
  antecedent_expr_stack: array[1..stack_size] of expr_ptr_type;
  antecedent_attr_stack: array[1..stack_size] of expr_attributes_ptr_type;


procedure Init_antecedent_expr_stack;
var
  counter: integer;
begin
  for counter := 1 to stack_size do
    begin
      antecedent_expr_stack[counter] := nil;
      antecedent_attr_stack[counter] := nil;
    end;
end; {procedure Init_antecedent_expr_stack}


{**********************************************************}
{ routines for setting antecedent pronouns, itself and its }
{**********************************************************}


procedure Push_antecedent_scope(expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if (antecedent_stack_ptr < stack_size) then
    begin
      antecedent_stack_ptr := antecedent_stack_ptr + 1;
      antecedent_expr_stack[antecedent_stack_ptr] := expr_ptr;
      antecedent_attr_stack[antecedent_stack_ptr] := expr_attributes_ptr;
      antecedent_scope_expr_ptr := expr_ptr;
      antecedent_scope_attr_ptr := expr_attributes_ptr;
    end
  else
    Error('antecedent scope stack overflow');
end; {procedure Push_antecedent_scope}


procedure Pop_antecedent_scope;
begin
  if (antecedent_stack_ptr > 0) then
    begin
      antecedent_stack_ptr := antecedent_stack_ptr - 1;
      antecedent_scope_expr_ptr := antecedent_expr_stack[antecedent_stack_ptr];
      antecedent_scope_attr_ptr := antecedent_attr_stack[antecedent_stack_ptr];
    end
  else
    Error('antecedent scope stack underflow');
end; {procedure Pop_antecedent_scope}


procedure Reset_antecedent;
begin
  antecedent_expr_ptr := nil;
  antecedent_attr_ptr := nil;
end; {procedure Reset_antecedent}


procedure Set_antecedent(expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
begin
  antecedent_expr_ptr := expr_ptr;
  antecedent_attr_ptr := expr_attributes_ptr;
end; {procedure Set_antecedent}


procedure Reset_antecedent_scope;
begin
  antecedent_scope_expr_ptr := nil;
  antecedent_scope_attr_ptr := nil;
end; {procedure Reset_antecedent_scope}


procedure Set_antecedent_scope(expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
begin
  antecedent_scope_expr_ptr := expr_ptr;
  antecedent_scope_attr_ptr := expr_attributes_ptr;
end; {procedure Set_antecedent_scope}


{********************************}
{ parsing identifier expressions }
{********************************}


{************************  productions  ************************}
{       <array_id> ::= id <array_indices>                       }
{***************************************************************}

procedure Parse_id_derefs(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  predict_set = [left_bracket_tok];
begin
  if parsing_ok then
    begin
      if (next_token.kind in predict_set) then
        if (expr_attributes_ptr^.dimensions <> 0) then
          if (expr_ptr^.kind in deref_expr_kinds) then
            begin
              Parse_array_deref_or_subrange(expr_ptr, expr_attributes_ptr);
              Parse_id_derefs(expr_ptr, expr_attributes_ptr);
            end
          else
            begin
              Parse_error;
              writeln('Invalid dereference.');
              error_reported := true;
            end;
    end; {if parsing_ok}
end; {procedure Parse_id_derefs}


{************************  productions  ************************}
{       <expr> ::= . <x y z>                                    }
{***************************************************************}

procedure Parse_vector_component(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
  vector_expr_ptr: expr_ptr_type;
begin
  if parsing_ok then
    begin
      type_attributes_ptr :=
        Deref_type_attributes(expr_attributes_ptr^.type_attributes_ptr);

      if type_attributes_ptr <> vector_type_attributes_ptr then
        begin
          Parse_error;
          writeln('Expected a vector experession here.');
          error_reported := true;
        end
      else if expr_attributes_ptr^.kind <> variable_attributes_kind then
        begin
          Parse_error;
          writeln('expected a variable here.');
          error_reported := true;
        end
      else
        begin
          vector_expr_ptr := nil;

          if next_token.kind <> id_tok then
            begin
              Parse_error;
              writeln('expected a vector field here.');
              error_reported := true;
            end
          else if next_token.id = 'x' then
            begin
              Get_next_token;
              vector_expr_ptr := New_expr(vector_x);
            end
          else if next_token.id = 'y' then
            begin
              Get_next_token;
              vector_expr_ptr := New_expr(vector_y);
            end
          else if next_token.id = 'z' then
            begin
              Get_next_token;
              vector_expr_ptr := New_expr(vector_z);
            end
          else
            begin
              Parse_error;
              writeln('"', next_token.id, '" is not a valid vector field.');
              error_reported := true;
            end;

          if parsing_ok then
            begin
              Deref_expr(expr_ptr, expr_attributes_ptr);
              vector_expr_ptr^.operand_ptr := expr_ptr;

              {**************************}
              { return scalar expression }
              {**************************}
              expr_ptr := vector_expr_ptr;
              expr_attributes_ptr^.type_attributes_ptr :=
                scalar_type_attributes_ptr;
            end;
        end
    end;
end; {procedure Parse_vector_component}


{************************  productions  ************************}
{       <array_id> ::= id <array_indices> <struct_offset>       }
{***************************************************************}

procedure Parse_id_fields_and_derefs(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if parsing_ok then
    if next_token.kind in deref_predict_set then
      if (expr_ptr^.kind in deref_expr_kinds) then
        case next_token.kind of

          {*********************}
          { parse struct derefs }
          {*********************}
          s_tok:
            begin
              Get_next_token;
              Parse_struct_field(expr_ptr, expr_attributes_ptr);
              Parse_id_fields_and_derefs(expr_ptr, expr_attributes_ptr);
            end;

          {********************}
          { parse array derefs }
          {********************}
          left_bracket_tok:
            begin
              if (expr_attributes_ptr^.dimensions <> 0) then
                begin
                  Parse_array_deref_or_subrange(expr_ptr, expr_attributes_ptr);
                  Parse_id_derefs(expr_ptr, expr_attributes_ptr);
                  Parse_id_fields_and_derefs(expr_ptr, expr_attributes_ptr);
                end;
            end;

          {************************}
          { parse vector component }
          {************************}
          period_tok:
            begin
              Get_next_token;
              Parse_vector_component(expr_ptr, expr_attributes_ptr);
            end;

        end {case}
      else
        begin
          Parse_error;
          writeln('Invalid dereference.');
          error_reported := true;
        end;
end; {procedure Parse_id_fields_and_derefs}


procedure Parse_implicit_method_id(id: string_type;
  var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type;
  scope_decl_attributes_ptr: decl_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
begin
  {**********************************************}
  { push implicit scopes of all enclosing scopes }
  {**********************************************}
  Push_local_scope(scope_decl_attributes_ptr);
  while scope_decl_attributes_ptr <> nil do
    begin
      type_attributes_ptr := scope_decl_attributes_ptr^.type_attributes_ptr;
      if type_attributes_ptr^.kind = type_code then
        Push_prev_scope(type_attributes_ptr^.code_attributes_ptr^.implicit_table_ptr);
      scope_decl_attributes_ptr :=
        scope_decl_attributes_ptr^.scope_decl_attributes_ptr;
    end;

  Make_implicit_local_id(id, expr_ptr, expr_attributes_ptr);
  Pop_local_scope;
end; {procedure Parse_implicit_method_id}


procedure Make_implicit_method_deref(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  type_decl_attributes_ptr: decl_attributes_ptr_type;
  method_decl_attributes_ptr: decl_attributes_ptr_type;
  implicit_expr_attributes_ptr: expr_attributes_ptr_type;
  class_type_ptr: type_ptr_type;
  new_expr_ptr: expr_ptr_type;
  class_name: string_type;
begin
  decl_attributes_ptr := expr_attributes_ptr^.decl_attributes_ptr;
  type_decl_attributes_ptr := decl_attributes_ptr^.scope_decl_attributes_ptr;
  if type_decl_attributes_ptr^.type_attributes_ptr^.kind = type_class then
    begin
      {*******************************************}
      { get type declaration from type descriptor }
      {*******************************************}
      class_type_ptr :=
        Get_type_decl(type_decl_attributes_ptr^.type_attributes_ptr);

      {************************}
      { dereference expression }
      {************************}
      if class_type_ptr^.static then
        new_expr_ptr := New_expr(struct_offset)
      else
        new_expr_ptr := New_expr(struct_deref);

      new_expr_ptr^.field_expr_ptr := expr_ptr;
      new_expr_ptr^.implicit_field := true;

      {********************************************************}
      { create reference to enclosing method's first parameter }
      {********************************************************}
      method_decl_attributes_ptr := Get_scope_decl_attributes;
      class_name := Get_decl_attributes_name(type_decl_attributes_ptr);
      Parse_implicit_method_id(class_name, new_expr_ptr^.base_expr_ptr,
        implicit_expr_attributes_ptr, method_decl_attributes_ptr);
      expr_ptr := new_expr_ptr;

      {******************************}
      { object of a reference method }
      {******************************}
      if (implicit_expr_attributes_ptr^.type_attributes_ptr^.kind =
        type_reference) then
        begin
          new_expr_ptr := New_expr(deref_op);
          new_expr_ptr^.operand_ptr := expr_ptr^.base_expr_ptr;
          expr_ptr^.base_expr_ptr := new_expr_ptr;
        end;

    end
  else
    Error('can not apply implicit class dereference');
end; {procedure Make_implicit_method_deref}


procedure Parse_id_term(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if parsing_ok then
    begin
      expr_ptr := nil;
      expr_attributes_ptr := nil;

      {******************************}
      { create reference to 'itself' }
      {******************************}
      if next_token.kind = itself_tok then
        begin
          if antecedent_expr_ptr <> nil then
            begin
              Get_next_token;
              expr_ptr := New_expr(itself);
              Set_expr_attributes(expr_ptr,
                Copy_expr_attributes(antecedent_attr_ptr));
              expr_attributes_ptr := antecedent_attr_ptr;
            end
          else
            begin
              Parse_error;
              writeln('No antecedent for pronoun, ', Quotate_str('itself'),
                '.');
              error_reported := true;
            end;
        end

          {******************************}
          { parse id with static scoping }
          {******************************}
      else if next_token.kind = static_id_tok then
        begin
          Match_static_id(expr_ptr, expr_attributes_ptr);
          if parsing_ok then
            expr_attributes_ptr^.explicit_static := true;
        end

          {******************************}
          { parse id with global scoping }
          {******************************}
      else if next_token.kind = global_tok then
        begin
          Get_next_token;
          Match_global_id(expr_ptr, expr_attributes_ptr);
          if parsing_ok then
            expr_attributes_ptr^.explicit_global := true;
        end

          {******************************}
          { parse id with normal scoping }
          {******************************}
      else
        Match_id(expr_ptr, expr_attributes_ptr);

    end; {if parsing_ok}
end; {procedure Parse_id_term}


procedure Parse_id_inst(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  scope_decl_attributes_ptr: decl_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      Parse_id_term(expr_ptr, expr_attributes_ptr);

      if parsing_ok then
        begin
          {****************************************}
          { dereference implicit object references }
          {****************************************}
          if expr_ptr^.kind <> itself then
            begin
              decl_attributes_ptr := expr_attributes_ptr^.decl_attributes_ptr;
              if decl_attributes_ptr^.kind = field_decl_attributes then
                begin
                  scope_decl_attributes_ptr := Get_scope_decl_attributes;
                  if scope_decl_attributes_ptr <> nil then
                    if scope_decl_attributes_ptr^.type_attributes_ptr^.kind =
                      type_code then
                      if not parsing_member_decls then
                        Make_implicit_method_deref(expr_ptr,
                          expr_attributes_ptr);

                end; {if field}
            end;

          {************************************}
          { set antecedent for later reference }
          {************************************}
          Set_antecedent(expr_ptr, expr_attributes_ptr);
        end;
    end; {if parsing_ok}
end; {procedure Parse_id_inst}


procedure Parse_its(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
begin
  if (antecedent_scope_expr_ptr <> nil) then
    begin
      Get_next_token;
      expr_attributes_ptr := antecedent_scope_attr_ptr;
      type_attributes_ptr :=
        Deref_type_attributes(expr_attributes_ptr^.type_attributes_ptr);

      case type_attributes_ptr^.kind of

        {*******************}
        { parse 'its' field }
        {*******************}
        type_struct, type_class:
          begin
            expr_ptr := Clone_expr(antecedent_scope_expr_ptr, true);
            Parse_struct_field(expr_ptr, expr_attributes_ptr);
            expr_ptr^.antecedent_field := true;
          end;

        {*******************}
        { parse 'its' param }
        {*******************}
        type_code:
          Match_local_id(expr_ptr, expr_attributes_ptr);

      end; {case}

      {****************************}
      { parse field's dereferences }
      {****************************}
      if parsing_ok then
        begin
          {type_attributes_ptr := Deref_type_attributes(expr_attributes_ptr^.type_attributes_ptr);}
          {if type_attributes_ptr^.kind in reference_type_kinds then}
          if next_token.kind in deref_predict_set then
            begin
              Deref_expr(expr_ptr, expr_attributes_ptr);
              Parse_id_fields_and_derefs(expr_ptr, expr_attributes_ptr);
            end;
        end;
    end
  else
    begin
      Parse_error;
      writeln('No antecedent for pronoun, ', Quotate_str('its'), '.');
      error_reported := true;
    end;
end; {procedure Parse_its}


procedure Parse_id(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if parsing_ok then
    if next_token.kind <> its_tok then
      begin
        Parse_id_inst(expr_ptr, expr_attributes_ptr);

        if parsing_ok then
          if next_token.kind in deref_predict_set then
            {if Deref_type_attributes(expr_attributes_ptr^.type_attributes_ptr)^.kind in reference_type_kinds then}
            begin
              Deref_expr(expr_ptr, expr_attributes_ptr);
              Parse_id_fields_and_derefs(expr_ptr, expr_attributes_ptr);
            end;
      end
    else
      Parse_its(expr_ptr, expr_attributes_ptr);

  {************************************}
  { set antecedent for later reference }
  {************************************}
  Set_antecedent(expr_ptr, expr_attributes_ptr);
end; {procedure Parse_id}


initialization
  antecedent_stack_ptr := 1;
  antecedent_expr_ptr := nil;
  antecedent_attr_ptr := nil;
  antecedent_scope_expr_ptr := nil;
  antecedent_scope_attr_ptr := nil;
  Init_antecedent_expr_stack;
end.

