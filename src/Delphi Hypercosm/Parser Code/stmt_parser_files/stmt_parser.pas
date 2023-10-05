unit stmt_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            stmt_parser                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse statements       }
{       into an abstract syntax tree representation.            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  stmts;


{******************************}
{ routines to parse statements }
{******************************}
procedure Parse_stmt(var stmt_ptr: stmt_ptr_type);
procedure Parse_stmts(var stmt_ptr: stmt_ptr_type);

{***********************************}
{ routines to parse statement lists }
{***********************************}
procedure Parse_stmt_list(var stmt_ptr, last_stmt_ptr: stmt_ptr_type);
procedure Parse_stmts_list(var stmt_ptr, last_stmt_ptr: stmt_ptr_type);
procedure Parse_more_stmts(var stmt_ptr, last_stmt_ptr: stmt_ptr_type);
procedure Parse_null_stmt(var stmt_ptr, last_stmt_ptr: stmt_ptr_type);


implementation
uses
  errors, new_memory, strings, code_types, symbol_tables, type_attributes,
    code_attributes, decl_attributes, expr_attributes, value_attributes, comments,
    compare_types, arrays, exprs, decls, code_decls, type_decls, make_exprs,
    subranges, tokens, scanner, tokenizer, parser, comment_parser, match_literals,
    match_terms, scope_stacks, scoping, term_parser, deref_parser, expr_parser,
    array_parser, data_parser, cons_parser, instruct_parser, assign_parser,
    msg_parser, value_parser, implicit_derefs, decl_parser;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


{***************************************************************}
{                            statements                         }
{***************************************************************}
{       <stmts> ::= <stmt> <more_stmts>                         }
{       <more_stmts> ::= <stmts>                                }
{       <more_stmts> ::=                                        }
{***************************************************************}


{***************************************************************}
{                        simple  statements                     }
{***************************************************************}
{       <stmt> ::= <cond_stmt>                                  }
{       <stmt> ::= <loop_stmt>                                  }
{       <stmt> ::= <flow_stmt>                                  }
{       <stmt> ::= <scoping_stmt>                               }
{       <stmt> ::= <memory_stmt>                                }
{       <stmt> ::= <io_stmt>                                    }
{       <stmt> ::= id <assign_or_cmplx_stmt>                    }
{       <assign_or_cmplx_stmt> ::= := <assign_tail>             }
{       <assign_or_cmplx_stmt> ::= <cmplx_stmt_tail>            }
{       <assign_tail> ::= = <expr> ;                            }
{***************************************************************}


{***************************************************************}
{                     conditional statements                    }
{***************************************************************}
{       <cond_stmt> ::= <if_stmt>                               }
{       <cond_stmt> ::= <switch_stmt>                           }
{                                                               }
{       <if_stmt> ::= if <expr> then <stmts> <elseifs> <else>   }
{       <elseifs> ::= <elseif> <more_elseifs>                   }
{       <more_elseifs> ::= <elseifs>                            }
{       <more_elseifs> ::=                                      }
{       <elseif> ::= elseif <expr> then <stmts>                 }
{       <else> ::= else <stmts> end ;                           }
{       <else> ::= end ;                                        }
{                                                               }
{       <case_stmt> ::= in case <expr> of <cases> <else> end ;  }
{       <cases> ::= <case> <more_cases>                         }
{       <more_cases> ::= <cases>                                }
{       <more_cases> ::=                                        }
{       <case> ::= case <expr> do <stmts> end ;                 }
{       <else> ::= else <stmts>                                 }
{***************************************************************}


{***************************************************************}
{                       looping statements                      }
{***************************************************************}
{       <loop_stmt> ::= <while_stmt>                            }
{       <loop_stmt> ::= <for_stmt>                              }
{                                                               }
{       <while_stmt> ::= while <expr> do <stmts> end ;          }
{       <for_stmt> ::= for id = <expr>..<expr> do <stmts> end ; }
{***************************************************************}


{***************************************************************}
{                     flow control statements                   }
{***************************************************************}
{       <flow_stmt> ::= <break_stmt>                            }
{       <flow_stmt> ::= <continue_stmt>                         }
{       <flow_stmt> ::= <return_stmt>                           }
{                                                               }
{				<break_stmt> ::= break <label> ;                        }
{				<continue_stmt> ::= continue <label> ;                  }
{       <return_stmt> ::= return <expr> ;                       }
{***************************************************************}


{***************************************************************}
{                       scoping statements                      }
{***************************************************************}
{       <scoping_stmt> ::= <with_stmt>                          }
{                                                               }
{       <with_stmt> ::= with <expr> do <stmts> end ;            }
{***************************************************************}


{***************************************************************}
{                  memory allocation statements                 }
{***************************************************************}
{       <memory_stmt> ::= <new_stmt>                            }
{       <memory_stmt> ::= <dim_stmt>                            }
{                                                               }
{       <new_stmt> ::= new id <cmplx_stmt_tail> ;               }
{       <dim_stmt> ::= dim id <array_decls>                     }
{                                                               }
{       <array_decls> ::= <array_decl> <array_decls>            }
{       <array_decls> ::=                                       }
{       <array_decl> ::= [ <ranges> ]                           }
{       <array_decl> ::=                                        }
{                                                               }
{       <ranges> ::= <range> <more_ranges>                      }
{       <more_ranges> ::= , <ranges>                            }
{       <more_ranges> ::=                                       }
{                                                               }
{       <range> ::= <min> .. <max>                              }
{       <range> ::=                                             }
{       <min> ::= <integer_expr>                                }
{       <max> ::= <integer_expr>                                }
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
{                       complex statements                      }
{***************************************************************}
{       <cmplx_stmt> ::= id <shader_stmt_tail> <object_stmt> ;  }
{       <cmplx_stmt> ::= id <cmplx_stmt_tail> ;                 }
{       <object_stmt> ::= id <cmplx_stmt_tail> ;                }
{       <shader_stmt_tail> ::= <param_values> <edge_shader_stmt>}
{       <edge_shader_stmt> ::= id <param_values>                }
{       <cmplx_stmt_tail> ::= <param_values> <cmplx_stmt_body>  }
{       <cmplx_stmt_body> ::= <opt_stmts> <return_stmts> end    }
{       <opt_stmts> ::= with <stmts>                            }
{       <return_stmts> ::= return <stmts>                       }
{***************************************************************}


const
  label_stack_size = 16;
  memory_alert = false;


type
  label_ptr_type = ^label_type;
  label_type = record
    index: integer;
    stmt_ptr: stmt_ptr_type;
    next: label_ptr_type;
  end;


  label_stack_ptr_type = ^label_stack_type;
  label_stack_type = array[1..label_stack_size] of label_ptr_type;


var
  label_stack_ptr: integer;
  label_stack: label_stack_ptr_type;
  label_free_list: label_ptr_type;
  label_index: integer;


{***************************************}
{ routines for managing the label stack }
{***************************************}


function New_label(index: integer;
  stmt_ptr: stmt_ptr_type): label_ptr_type;
var
  label_ptr: label_ptr_type;
begin
  {****************************}
  { get surface from free list }
  {****************************}
  if (label_free_list <> nil) then
    begin
      label_ptr := label_free_list;
      label_free_list := label_ptr^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new label');
      new(label_ptr);
    end;

  {********************}
  { initialize surface }
  {********************}
  label_ptr^.index := index;
  label_ptr^.stmt_ptr := stmt_ptr;
  label_ptr^.next := nil;

  New_label := label_ptr;
end; {function New_label}


procedure Free_label(var label_ptr: label_ptr_type);
begin
  {************************}
  { add label to free list }
  {************************}
  label_ptr^.next := label_free_list;
  label_free_list := label_ptr;
  label_ptr := nil;
end; {procedure Free_label}


procedure Push_label_stack(index: integer;
  stmt_ptr: stmt_ptr_type);
var
  label_ptr: label_ptr_type;
begin
  if (label_stack_ptr < label_stack_size) then
    begin
      label_ptr := New_label(index, stmt_ptr);
      label_stack_ptr := label_stack_ptr + 1;
      label_stack^[label_stack_ptr] := label_ptr;
    end
  else
    Error('label stack overflow');
end; {procedure Push_object_stack}


procedure Pop_label_stack;
var
  label_ptr: label_ptr_type;
begin
  if (label_stack_ptr > 0) then
    begin
      label_ptr := label_stack^[label_stack_ptr];
      label_stack_ptr := label_stack_ptr - 1;
      Free_label(label_ptr);
    end
  else
    Error('label stack underflow');
end; {procedure Pop_label_stack}


function Get_label_stmt(index: integer): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
  label_ptr: label_ptr_type;
  counter: integer;
  found: boolean;
begin
  stmt_ptr := nil;
  counter := label_stack_ptr;
  found := false;

  while (counter > 0) and (not found) do
    begin
      label_ptr := label_stack^[counter];
      if label_ptr^.index = index then
        begin
          stmt_ptr := label_ptr^.stmt_ptr;
          found := true;
        end
      else
        counter := counter - 1;
    end;

  Get_label_stmt := stmt_ptr;
end; {function Get_label_stmt}


{***************************************}
{ routines for creating for..each loops }
{***************************************}


function New_for_each_loop(for_each_stmt_ptr: stmt_ptr_type;
  var loop_array_ptr: expr_ptr_type): stmt_ptr_type;
var
  decl_ptr: decl_ptr_type;
  stmt_ptr, last_stmt_ptr, new_stmt_ptr: stmt_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  array_subrange_ptr: array_subrange_ptr_type;
  subrange_expr_ptr: expr_ptr_type;
  dimensions, counter: integer;
begin
  {**********************}
  { get array attributes }
  {**********************}
  expr_attributes_ptr := Get_expr_attributes(loop_array_ptr);
  dimensions := expr_attributes_ptr^.dimensions;

  {****************************}
  { get array index attributes }
  {****************************}
  decl_ptr := decl_ptr_type(for_each_stmt_ptr^.each_index_decl_ptr);
  decl_attributes_ptr := Get_decl_attributes(decl_ptr);
  dimensions := dimensions - decl_attributes_ptr^.dimensions;

  {************************}
  { add implicit subranges }
  {************************}
  Complete_array_subrange(loop_array_ptr);

  {***************************}
  { find first subrange array }
  {***************************}
  array_subrange_ptr := New_first_subrange_dimension(loop_array_ptr,
    subrange_expr_ptr);

  stmt_ptr := nil;
  last_stmt_ptr := nil;
  for counter := 1 to dimensions do
    begin
      {**********************************}
      { add implicit derefs if necessary }
      {**********************************}
      if array_subrange_ptr = nil then
        begin
          Make_array_subrange(loop_array_ptr, expr_attributes_ptr);
          subrange_expr_ptr := loop_array_ptr;
          array_subrange_ptr := New_array_expr_subrange(subrange_expr_ptr);
        end;

      {*************************}
      { create array assignment }
      {*************************}
      new_stmt_ptr := New_stmt(for_each_loop);
      new_stmt_ptr^.for_each_array_subrange_ptr := array_subrange_ptr;

      {*********************}
      { add to tail of list }
      {*********************}
      if (last_stmt_ptr <> nil) then
        begin
          last_stmt_ptr^.loop_stmts_ptr := new_stmt_ptr;
          last_stmt_ptr := new_stmt_ptr;
        end
      else
        begin
          stmt_ptr := new_stmt_ptr;
          last_stmt_ptr := new_stmt_ptr;
        end;

      {******************************}
      { find next subrange dimension }
      {******************************}
      if (counter < dimensions) then
        array_subrange_ptr := New_next_subrange_dimension(array_subrange_ptr,
          subrange_expr_ptr);
    end; {for}

  {********************************}
  { create primitive looping stmts }
  {********************************}
  last_stmt_ptr^.loop_stmts_ptr := for_each_stmt_ptr;

  New_for_each_loop := stmt_ptr;
end; {function New_for_each_loop}


{*********************************************************}
{ routines for parsing local statement block declarations }
{*********************************************************}


procedure Parse_stmt_block(var forward_decl_ptr: forward_decl_ptr_type;
  var stmt_ptr: stmt_ptr_type);
var
  decl_ptr: decl_ptr_type;
  symbol_table_ptr: symbol_table_ptr_type;
begin
  if next_token.kind in decl_predict_set then
    begin
      symbol_table_ptr := New_symbol_table;
      Push_prev_scope(symbol_table_ptr);

      Parse_decls(decl_ptr, nil);
      forward_decl_ptr := forward_decl_ptr_type(decl_ptr);
      Parse_stmts(stmt_ptr);

      Pop_prev_scope;
      Free_symbol_table(symbol_table_ptr, false);
    end
  else
    begin
      decl_ptr := nil;
      Parse_stmts(stmt_ptr);
    end;
end; {procedure Parse_stmt_block}


{***************************************************************}
{                     conditional statements                    }
{***************************************************************}
{       <cond_stmt> ::= <if_stmt>                               }
{       <cond_stmt> ::= <switch_stmt>                           }
{***************************************************************}


{************************  productions  ************************}
{       <elseif> ::= elseif <expr> then <stmts>                 }
{***************************************************************}

procedure Parse_elseif(var stmt_ptr: stmt_ptr_type;
  var last_if_stmt_ptr: stmt_ptr_type);
begin
  Match(elseif_tok);
  stmt_ptr := New_stmt(if_then_else);
  stmt_ptr^.elseif_contraction := true;

  Parse_equal_expr(stmt_ptr^.if_expr_ptr, boolean_value_attributes_ptr);
  Match(then_tok);
  Parse_stmt_block(stmt_ptr^.then_decls_ptr, stmt_ptr^.then_stmts_ptr);
  last_if_stmt_ptr := stmt_ptr;
end; {procedure Parse_elseif}


{************************  productions  ************************}
{       <elseifs> ::= <elseif> <more_elseifs>                   }
{       <more_elseifs> ::= <elseifs>                            }
{       <more_elseifs> ::=                                      }
{       <elseif> ::= elseif <expr> then <stmts>                 }
{***************************************************************}

procedure Parse_elseifs(var stmt_ptr: stmt_ptr_type;
  var last_if_stmt_ptr: stmt_ptr_type);
const
  predict_set = [elseif_tok];
begin
  Parse_elseif(stmt_ptr, last_if_stmt_ptr);
  if parsing_ok then
    if next_token.kind in predict_set then
      Parse_elseifs(last_if_stmt_ptr^.else_stmts_ptr, last_if_stmt_ptr);
end; {procedure Parse_elseifs}


{************************  productions  ************************}
{       <if_stmt> ::= if <expr> then <stmts> <elseifs> <else>   }
{       <else> ::= else <stmts> end ;                           }
{       <else> ::= end ;                                        }
{***************************************************************}

procedure Parse_if_stmt(var stmt_ptr: stmt_ptr_type);
var
  last_if_stmt_ptr: stmt_ptr_type;
  stmt_info_ptr: stmt_info_ptr_type;
begin
  Get_prev_stmt_info(stmt_info_ptr);
  stmt_ptr := New_stmt(if_then_else);
  Set_stmt_info(stmt_ptr, stmt_info_ptr);

  Get_next_token;
  Parse_equal_expr(stmt_ptr^.if_expr_ptr, boolean_value_attributes_ptr);
  Match(then_tok);
  Parse_stmt_block(stmt_ptr^.then_decls_ptr, stmt_ptr^.then_stmts_ptr);

  {***************}
  { parse elseifs }
  {***************}
  if (next_token.kind = elseif_tok) then
    Parse_elseifs(stmt_ptr^.else_stmts_ptr, last_if_stmt_ptr)
  else
    last_if_stmt_ptr := stmt_ptr;

  if (next_token.kind = else_tok) then
    begin
      {************}
      { parse else }
      {************}
      Get_next_token;
      Parse_stmt_block(last_if_stmt_ptr^.else_decls_ptr,
        last_if_stmt_ptr^.else_stmts_ptr);
    end
  else
    begin
      {****************}
      { no else clause }
      {****************}
      last_if_stmt_ptr^.else_stmts_ptr := nil;
    end;

  Match(end_tok);
  if not (next_token.kind in [right_paren_tok, comma_tok]) then
    Match(semi_colon_tok);

  Get_post_stmt_info(stmt_ptr^.stmt_info_ptr);
end; {procedure Parse_if_stmt}


{************************  productions  ************************}
{       <case> ::= case <expr> do <stmts> end ;                 }
{***************************************************************}

procedure Parse_case(var switch_array_ptr: switch_array_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  var first, last: case_constant_ptr_type);
const
  valid_kinds = [id_tok, string_lit_tok];
var
  expr_ptr: expr_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  case_constant_ptr: case_constant_ptr_type;
  switch_case_ptr: switch_case_ptr_type;
  value: integer;
begin
  if parsing_ok then
    if next_token.kind in valid_kinds then
      begin
        {*********************}
        { parse case constant }
        {*********************}
        type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
        case type_attributes_ptr^.kind of
          type_char:
            begin
              Match_char_lit(expr_ptr, expr_attributes_ptr);
              value := ord(expr_ptr^.char_val);
            end;
          type_enum:
            begin
              Match_enum_lit(expr_ptr, expr_attributes_ptr,
                type_attributes_ptr);
              value := expr_ptr^.enum_val;
            end;

        else
          value := 0;
        end; {case}

        {************************************}
        { check for duplicate case constants }
        {************************************}
        if parsing_ok then
          if (switch_array_ptr^.switch_case_array[value] <> nil) then
            begin
              Parse_error;
              writeln('This case constant already specified.');
              error_reported := true;
              Destroy_exprs(expr_ptr, true);
            end
          else
            begin
              {******************}
              { parse statements }
              {******************}
              Match(colon_tok);

              if parsing_ok then
                begin
                  case_constant_ptr := New_case_constant;
                  case_constant_ptr^.case_expr_ptr := expr_ptr;
                  case_constant_ptr^.value := value;
                  case_constant_ptr^.next := nil;

                  switch_case_ptr := New_switch_case;
                  switch_array_ptr^.switch_case_array[value] := switch_case_ptr;
                  with switch_case_ptr^ do
                    Parse_stmt_block(case_decls_ptr, case_stmts_ptr);

                  {***************************}
                  { add case constant to list }
                  {***************************}
                  if (last = nil) then
                    begin
                      first := case_constant_ptr;
                      last := first;
                    end
                  else
                    begin
                      last^.next := case_constant_ptr;
                      last := case_constant_ptr;
                    end;

                  Match(end_tok);
                  Match(semi_colon_tok);
                end;
            end;
      end
    else
      begin
        Parse_error;
        writeln('This case constant is not of the');
        writeln('same type as the switch variable.');
        error_reported := true;
      end;
end; {procedure Parse_case}


{************************  productions  ************************}
{       <cases> ::= <case> <more_cases>                         }
{       <more_cases> ::= <cases>                                }
{       <more_cases> ::=                                        }
{***************************************************************}

procedure Parse_cases(var switch_array_ptr: switch_array_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  var first, last: case_constant_ptr_type);
const
  predict_set = [id_tok, string_lit_tok];
begin
  if next_token.kind in predict_set then
    begin
      Parse_case(switch_array_ptr, expr_attributes_ptr, first, last);
      if parsing_ok then
        Parse_cases(switch_array_ptr, expr_attributes_ptr, first, last);
    end;
end; {procedure Parse_cases}


{************************  productions  ************************}
{       <case_stmt> ::= when <id> is <cases> <else> end ;       }
{       <else> ::= else <stmts>                                 }
{***************************************************************}

procedure Parse_case_stmt(var stmt_ptr: stmt_ptr_type);
const
  valid_kinds = [type_char, type_enum];
var
  expr_ptr: expr_ptr_type;
  stmt_info_ptr: stmt_info_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  last: case_constant_ptr_type;
begin
  Get_prev_stmt_info(stmt_info_ptr);

  Get_next_token;
  expr_attributes_ptr := nil;
  Parse_unit(expr_ptr, expr_attributes_ptr);
  Deref_expr(expr_ptr, expr_attributes_ptr);

  if parsing_ok then
    if (expr_attributes_ptr^.type_attributes_ptr^.kind in valid_kinds) then
      begin
        case expr_attributes_ptr^.type_attributes_ptr^.kind of

          type_char:
            stmt_ptr := New_stmt(case_char_stmt);

          type_enum:
            stmt_ptr := New_stmt(case_enum_stmt);

        end; {case}

        Set_stmt_info(stmt_ptr, stmt_info_ptr);
        stmt_ptr^.switch_expr_ptr := expr_ptr;
        stmt_ptr^.switch_array_ptr := New_switch_array;
        Match(is_tok);

        last := nil;
        Parse_cases(stmt_ptr^.switch_array_ptr, expr_attributes_ptr,
          stmt_ptr^.switch_case_constant_ptr, last);
        if (next_token.kind = else_tok) then
          begin
            Get_next_token;
            Parse_stmt_block(stmt_ptr^.switch_else_decls_ptr,
              stmt_ptr^.switch_else_stmts_ptr);
          end;
      end
    else
      begin
        Parse_error;
        writeln('The switch variable must be an enum or a char.');
        error_reported := true;
      end;

  Match(end_tok);
  if not (next_token.kind in [right_paren_tok, comma_tok]) then
    Match(semi_colon_tok);

  Get_post_stmt_info(stmt_info_ptr);
end; {procedure Parse_case_stmt}


{***************************************************************}
{                       looping statements                      }
{***************************************************************}
{       <loop_stmt> ::= <while_stmt>                            }
{       <loop_stmt> ::= <for_stmt>                              }
{				<loop_stmt> ::= <break_stmt>														}
{				<loop_stmt> ::= <continue_stmt>													}
{***************************************************************}


{************************  productions  ************************}
{       <while_stmt> ::= while <expr> do <stmts> end ;          }
{***************************************************************}

procedure Parse_while_stmt(var stmt_ptr: stmt_ptr_type);
var
  stmt_info_ptr: stmt_info_ptr_type;
begin
  Get_prev_stmt_info(stmt_info_ptr);
  stmt_ptr := New_stmt(while_loop);
  Set_stmt_info(stmt_ptr, stmt_info_ptr);

  Get_next_token;
  Parse_equal_expr(stmt_ptr^.while_expr_ptr, boolean_value_attributes_ptr);
  Match(do_tok);

  Push_label_stack(label_index, stmt_ptr);
  label_index := 0;
  Parse_stmt_block(stmt_ptr^.while_decls_ptr, stmt_ptr^.while_stmts_ptr);
  Pop_label_stack;

  Match(end_tok);
  if not (next_token.kind in [right_paren_tok, comma_tok]) then
    Match(semi_colon_tok);

  Get_post_stmt_info(stmt_ptr^.stmt_info_ptr);
end; {procedure Parse_while_stmt}


{************************  productions  ************************}
{       <for_each_list> ::= for each <type> id and <expr> in    }
{                           <expr> do <stmts> end ;             }
{***************************************************************}

procedure Parse_for_each_list(var stmt_ptr: stmt_ptr_type;
  name: string_type;
  const_index: boolean;
  type_attributes_ptr: type_attributes_ptr_type;
  decl_info_ptr: decl_info_ptr_type);
var
  decl_ptr: decl_ptr_type;
  expr_ptr: expr_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  scope_ptr: scope_ptr_type;
begin
  {********************************}
  { create loop counter attributes }
  {********************************}
  decl_attributes_ptr := New_decl_attributes(data_decl_attributes,
    type_attributes_ptr, nil);
  decl_attributes_ptr^.final := true;
  decl_attributes_ptr^.final_reference := const_index;
  decl_attributes_ptr^.implicit_reference := true;

  {*********************************}
  { create loop counter declaration }
  {*********************************}
  expr_ptr := New_identifier(decl_attributes_ptr, expr_attributes_ptr);
  Set_scope_decl_attributes(decl_attributes_ptr, scope_ptr);
  Make_implicit_derefs(expr_ptr, expr_attributes_ptr, nil);
  decl_ptr := New_data_decl(expr_ptr, expr_attributes_ptr, decl_info_ptr);

  Match(and_tok);
  stmt_ptr := New_stmt(for_each_list);
  stmt_ptr^.each_struct_decl_ptr := forward_decl_ptr_type(decl_ptr);

  Push_antecedent_scope(decl_ptr^.data_decl.data_expr_ptr, expr_attributes_ptr);
  Parse_same_expr(stmt_ptr^.each_next_expr_ptr, expr_attributes_ptr);
  Pop_antecedent_scope;

  Match(in_tok);
  Parse_same_expr(stmt_ptr^.each_list_expr_ptr, expr_attributes_ptr);
  Match(do_tok);

  if parsing_ok then
    begin
      Push_label_stack(label_index, stmt_ptr);
      label_index := 0;

      {***********************************}
      { activate loop counter declaration }
      {***********************************}
      Enter_scope(scope_ptr, name, decl_attributes_ptr);

      {*****************************************}
      { parse local declarations and statements }
      {*****************************************}
      Parse_stmt_block(stmt_ptr^.list_decls_ptr, stmt_ptr^.list_stmts_ptr);

      Pop_label_stack;
      Match(end_tok);
    end;
end; {procedure Parse_for_each_list}


procedure Reference_decl_attributes(expr_attributes_ptr:
  expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
begin
  {******************************}
  { add array to type attributes }
  {******************************}
  decl_attributes_ptr^.type_attributes_ptr :=
    New_reference_type_attributes(decl_attributes_ptr^.type_attributes_ptr);

  {*************************************************}
  { update decl attributes to match type attributes }
  {*************************************************}
  decl_attributes_ptr^.dimensions :=
    Get_data_abs_dims(decl_attributes_ptr^.type_attributes_ptr);

  {*******************************************}
  { also update expr attributes to match decl }
  {*******************************************}
  expr_attributes_ptr^.dimensions := decl_attributes_ptr^.dimensions;
  expr_attributes_ptr^.alias_type_attributes_ptr :=
    decl_attributes_ptr^.type_attributes_ptr;
  expr_attributes_ptr^.type_attributes_ptr :=
    Unalias_type_attributes(expr_attributes_ptr^.alias_type_attributes_ptr);
end; {procedure Reference_decl_attributes}


procedure Parse_for_each_array(var stmt_ptr: stmt_ptr_type;
  name: string_type;
  const_index: boolean;
  type_attributes_ptr: type_attributes_ptr_type;
  decl_info_ptr: decl_info_ptr_type);
var
  decl_ptr: decl_ptr_type;
  expr_ptr, dim_expr_ptr: expr_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  array_type_attributes_ptr: type_attributes_ptr_type;
  each_array_ptr: expr_ptr_type;
  scope_ptr: scope_ptr_type;
begin
  {********************************}
  { create loop counter attributes }
  {********************************}
  decl_attributes_ptr := New_decl_attributes(data_decl_attributes,
    type_attributes_ptr, nil);
  decl_attributes_ptr^.final := true;
  decl_attributes_ptr^.final_reference := const_index;
  decl_attributes_ptr^.implicit_reference := true;

  {******************************}
  { create loop counter variable }
  {******************************}
  expr_ptr := New_identifier(decl_attributes_ptr, expr_attributes_ptr);
  Set_scope_decl_attributes(decl_attributes_ptr, scope_ptr);
  Make_implicit_derefs(expr_ptr, expr_attributes_ptr, nil);

  {*********************************}
  { create loop counter declaration }
  {*********************************}
  Parse_array_decl_dims(dim_expr_ptr, expr_attributes_ptr, decl_attributes_ptr,
    false);
  Reference_decl_attributes(expr_attributes_ptr, decl_attributes_ptr);
  decl_ptr := New_data_decl(expr_ptr, expr_attributes_ptr, decl_info_ptr);
  decl_ptr^.data_decl.init_expr_ptr := dim_expr_ptr;

  Match(in_tok);
  Parse_id(each_array_ptr, expr_attributes_ptr);

  if parsing_ok then
    if (expr_attributes_ptr^.dimensions = 0) then
      begin
        Parse_error;
        writeln('An array is required here.');
        error_reported := true;
      end
    else if ((not const_index) and
      expr_attributes_ptr^.decl_attributes_ptr^.final) then
      begin
        Parse_error;
        writeln('The index of this for each loop must be a constant.');
        error_reported := true;
      end
    else
      begin
        Deref_expr(each_array_ptr, expr_attributes_ptr);
        array_type_attributes_ptr :=
          expr_attributes_ptr^.type_attributes_ptr^.element_type_attributes_ptr;
        type_attributes_ptr :=
          Deref_type_attributes(decl_attributes_ptr^.type_attributes_ptr);

        if not Same_type_attributes(array_type_attributes_ptr,
          type_attributes_ptr) then
          begin
            Parse_error;
            writeln('The array element type does not match');
            writeln('the type of the index variable.');
            error_reported := true;
          end
        else
          begin
            Match(do_tok);
            stmt_ptr := New_stmt(for_each);
            stmt_ptr^.each_index_decl_ptr := forward_decl_ptr_type(decl_ptr);
            stmt_ptr^.each_array_ptr := each_array_ptr;

            Push_label_stack(label_index, stmt_ptr);
            label_index := 0;

            {***********************************}
            { activate loop counter declaration }
            {***********************************}
            Enter_scope(scope_ptr, name, decl_attributes_ptr);

            {*****************************************}
            { parse local declarations and statements }
            {*****************************************}
            Parse_stmt_block(stmt_ptr^.each_decls_ptr,
              stmt_ptr^.each_stmts_ptr);

            Pop_label_stack;

            Match(end_tok);
            if parsing_ok then
              stmt_ptr := New_for_each_loop(stmt_ptr, stmt_ptr^.each_array_ptr);
          end; {else}
      end; {else}
end; {procedure Parse_for_each_array}


{************************  productions  ************************}
{       <for_each> ::= for each <type> id in id do <stmts> end ;}
{***************************************************************}

procedure Parse_for_each(var stmt_ptr: stmt_ptr_type);
var
  decl_info_ptr: decl_info_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  symbol_table_ptr: symbol_table_ptr_type;
  const_index: boolean;
  name: string_type;
begin
  Match(each_tok);

  if next_token.kind = const_tok then
    begin
      Get_next_token;
      const_index := true;
    end
  else
    const_index := false;

  Parse_data_type(type_attributes_ptr);

  if parsing_ok then
    begin
      {**************************************************}
      { 'for each' statements always open up a new scope }
      {**************************************************}
      symbol_table_ptr := New_symbol_table;
      Push_prev_scope(symbol_table_ptr);

      {******************}
      { parse loop index }
      {******************}
      Get_prev_decl_info(decl_info_ptr);
      Match_unique_id(name);

      if parsing_ok then
        begin
          Get_post_decl_info(decl_info_ptr);

          if parsing_ok then
            begin
              if next_token.kind <> and_tok then
                Parse_for_each_array(stmt_ptr, name, const_index,
                  type_attributes_ptr, decl_info_ptr)
              else
                Parse_for_each_list(stmt_ptr, name, const_index,
                  type_attributes_ptr, decl_info_ptr);
            end; {if parsing_ok}
        end; {if parsing_ok}

      Pop_prev_scope;
      Free_symbol_table(symbol_table_ptr, false);
    end; {if parsing_ok}
end; {procedure Parse_for_each}


{************************  productions  ************************}
{       <for_stmt> ::= for id = <expr>..<expr> do <stmts> end ; }
{***************************************************************}

procedure Parse_for_stmt(var stmt_ptr: stmt_ptr_type);
const
  valid_kinds = [type_integer, type_enum];
var
  expr_ptr, dim_expr_ptr: expr_ptr_type;
  decl_ptr, decls_ptr: decl_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  symbol_table_ptr: symbol_table_ptr_type;
  stmt_info_ptr: stmt_info_ptr_type;
  decl_info_ptr: decl_info_ptr_type;
  scope_ptr: scope_ptr_type;
  name: string_type;
begin
  Get_prev_stmt_info(stmt_info_ptr);
  Get_next_token;

  if next_token.kind = each_tok then
    begin
      Parse_for_each(stmt_ptr);
      if parsing_ok then
        Set_stmt_info(stmt_ptr, stmt_info_ptr);
    end
  else
    begin
      stmt_ptr := New_stmt(for_loop);
      Set_stmt_info(stmt_ptr, stmt_info_ptr);

      Parse_data_type(type_attributes_ptr);
      if parsing_ok then
        begin
          if not (type_attributes_ptr^.kind in valid_kinds) then
            begin
              Parse_error;
              writeln('The ', Quotate_str('for loop'),
                ' counter must be an integer or enum.');
              error_reported := true;
            end
          else
            begin
              {*********************************************}
              { 'for' statements always open up a new scope }
              {*********************************************}
              symbol_table_ptr := New_symbol_table;
              Push_prev_scope(symbol_table_ptr);

              {********************************}
              { create loop counter attributes }
              {********************************}
              decl_attributes_ptr := New_decl_attributes(data_decl_attributes,
                type_attributes_ptr, nil);
              decl_attributes_ptr^.final := true;

              {********************}
              { parse loop counter }
              {********************}
              Get_prev_decl_info(decl_info_ptr);
              Match_unique_id(name);

              if parsing_ok then
                begin
                  {******************************}
                  { create loop counter variable }
                  {******************************}
                  expr_ptr := New_identifier(decl_attributes_ptr,
                    expr_attributes_ptr);
                  Set_scope_decl_attributes(decl_attributes_ptr, scope_ptr);
                  Make_implicit_derefs(expr_ptr, expr_attributes_ptr, nil);

                  {*********************************}
                  { create loop counter declaration }
                  {*********************************}
                  Parse_array_decl_dims(dim_expr_ptr, expr_attributes_ptr,
                    decl_attributes_ptr, false);
                  decl_ptr := New_data_decl(expr_ptr, expr_attributes_ptr,
                    decl_info_ptr);
                  decl_ptr^.data_decl.init_expr_ptr := dim_expr_ptr;
                  stmt_ptr^.counter_decl_ptr := forward_decl_ptr_type(decl_ptr);
                  Get_post_decl_info(decl_info_ptr);

                  {***************************}
                  { parse assignment operator }
                  {***************************}
                  if type_attributes_ptr^.kind in [type_char, type_enum] then
                    Match(is_tok)
                  else
                    Match(equal_tok);

                  {*******************}
                  { parse loop bounds }
                  {*******************}
                  Parse_equal_expr(stmt_ptr^.start_expr_ptr,
                    expr_attributes_ptr);
                  Match(dot_dot_tok);
                  Parse_equal_expr(stmt_ptr^.end_expr_ptr, expr_attributes_ptr);
                  Match(do_tok);

                  Push_label_stack(label_index, stmt_ptr);
                  label_index := 0;

                  {***********************************}
                  { activate loop counter declaration }
                  {***********************************}
                  Enter_scope(scope_ptr, name, decl_attributes_ptr);

                  {*****************************************}
                  { parse local declarations and statements }
                  {*****************************************}
                  Parse_decls(decls_ptr, nil);
                  stmt_ptr^.for_decls_ptr := forward_decl_ptr_type(decls_ptr);
                  Parse_stmts(stmt_ptr^.for_stmts_ptr);

                  Pop_label_stack;
                end;

              Pop_prev_scope;
              Free_symbol_table(symbol_table_ptr, false);

              Match(end_tok);
            end;
        end;
    end;

  if not (next_token.kind in [right_paren_tok, comma_tok]) then
    Match(semi_colon_tok);

  Get_post_stmt_info(stmt_info_ptr);
end; {procedure Parse_for_stmt}


{************************  productions  ************************}
{       <break_stmt> ::= break ;                                }
{***************************************************************}

procedure Parse_break_stmt(var stmt_ptr: stmt_ptr_type);
var
  stmt_info_ptr: stmt_info_ptr_type;
  label_stmt_ptr: stmt_ptr_type;
  symbol_table_ptr: symbol_table_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  id_ptr: id_ptr_type;
begin
  Get_prev_stmt_info(stmt_info_ptr);
  stmt_ptr := New_stmt(break_stmt);
  Set_stmt_info(stmt_ptr, stmt_info_ptr);

  Get_next_token;
  if next_token.kind = id_tok then
    begin
      {************************************************}
      { get label symbol table of current static scope }
      {************************************************}
      decl_attributes_ptr := Get_scope_decl_attributes;
      symbol_table_ptr :=
        decl_attributes_ptr^.type_attributes_ptr^.code_attributes_ptr^.label_table_ptr;

      if Found_id_by_name(symbol_table_ptr, id_ptr, next_token.id) then
        begin
          Get_next_token;
          stmt_ptr^.label_index := id_ptr^.value;
        end
      else
        begin
          Parse_error;
          writeln(Quotate_str(next_token.id), ' is not defined as a label.');
          error_reported := true;
        end;
    end
  else
    stmt_ptr^.label_index := 0;

  {********************************}
  { get statement from label stack }
  {********************************}
  if parsing_ok then
    begin
      label_stmt_ptr := Get_label_stmt(stmt_ptr^.label_index);
      if label_stmt_ptr <> nil then
        stmt_ptr^.enclosing_loop_ref := label_stmt_ptr
      else
        begin
          Parse_error;
          writeln(Quotate_str('break'),
            ' statements must be enclosed in a loop.');
          error_reported := true;
        end;
    end;

  Match(semi_colon_tok);
  Get_post_stmt_info(stmt_info_ptr);
end; {procedure Parse_break_stmt}


{************************  productions  ************************}
{       <continue_stmt> ::= continue ;                          }
{***************************************************************}

procedure Parse_continue_stmt(var stmt_ptr: stmt_ptr_type);
var
  stmt_info_ptr: stmt_info_ptr_type;
  label_stmt_ptr: stmt_ptr_type;
  symbol_table_ptr: symbol_table_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  id_ptr: id_ptr_type;
begin
  Get_prev_stmt_info(stmt_info_ptr);
  stmt_ptr := New_stmt(continue_stmt);
  Set_stmt_info(stmt_ptr, stmt_info_ptr);

  Get_next_token;
  if next_token.kind = id_tok then
    begin
      {************************************************}
      { get label symbol table of current static scope }
      {************************************************}
      decl_attributes_ptr := Get_scope_decl_attributes;
      symbol_table_ptr :=
        decl_attributes_ptr^.type_attributes_ptr^.code_attributes_ptr^.label_table_ptr;

      if Found_id_by_name(symbol_table_ptr, id_ptr, next_token.id) then
        begin
          Get_next_token;
          stmt_ptr^.label_index := id_ptr^.value;
        end
      else
        begin
          Parse_error;
          writeln(Quotate_str(next_token.id), ' is not defined as a label.');
          error_reported := true;
        end;
    end
  else
    stmt_ptr^.label_index := 0;

  {********************************}
  { get statement from label stack }
  {********************************}
  if parsing_ok then
    begin
      label_stmt_ptr := Get_label_stmt(stmt_ptr^.label_index);
      if label_stmt_ptr <> nil then
        stmt_ptr^.enclosing_loop_ref := label_stmt_ptr
      else
        begin
          Parse_error;
          writeln(Quotate_str('continue'),
            ' statements must be enclosed in a loop.');
          error_reported := true;
        end;
    end;

  Match(semi_colon_tok);
  Get_post_stmt_info(stmt_info_ptr);
end; {procedure Parse_continue_stmt}


{************************  productions  ************************}
{       <loop_stmt> ::= loop id : <loop_stmt>                   }
{***************************************************************}

procedure Parse_loop_stmt(var stmt_ptr: stmt_ptr_type);
var
  stmt_info_ptr: stmt_info_ptr_type;
  id_ptr: id_ptr_type;
  symbol_table_ptr: symbol_table_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  Get_prev_stmt_info(stmt_info_ptr);
  stmt_ptr := New_stmt(loop_label_stmt);
  Set_stmt_info(stmt_ptr, stmt_info_ptr);

  Get_next_token;
  if next_token.kind = id_tok then
    begin
      {************************************************}
      { get label symbol table of current static scope }
      {************************************************}
      decl_attributes_ptr := Get_scope_decl_attributes;
      symbol_table_ptr :=
        decl_attributes_ptr^.type_attributes_ptr^.code_attributes_ptr^.label_table_ptr;

      label_index := Symbol_table_size(symbol_table_ptr) + 1;
      id_ptr := Enter_id(symbol_table_ptr, next_token.id, label_index);
      Get_next_token;

      Match(colon_tok);
      if parsing_ok then
        if next_token.kind in [while_tok, for_tok] then
          begin
            stmt_ptr^.loop_label_index := id_ptr^.value;
            Parse_stmts(stmt_ptr^.loop_stmt_ptr);
          end
        else
          begin
            Parse_error;
            writeln('Expected a looping statement here.');
            error_reported := true;
          end;
    end
  else
    begin
      Parse_error;
      writeln('Expected an identifier label here.');
      error_reported := true;
    end;

  Get_post_stmt_info(stmt_info_ptr);
end; {procedure Parse_loop_stmt}


{************************  productions  ************************}
{       <return_stmt> ::= return ;                              }
{***************************************************************}

procedure Parse_return_stmt(var stmt_ptr: stmt_ptr_type);
var
  stmt_info_ptr: stmt_info_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type;
begin
  {*******************************************************}
  { find enclosing method kind from scope decl attributes }
  {*******************************************************}
  decl_attributes_ptr := Get_scope_decl_attributes;
  type_attributes_ptr := decl_attributes_ptr^.type_attributes_ptr;
  code_attributes_ptr := type_attributes_ptr^.code_attributes_ptr;

  if not (code_attributes_ptr^.kind in [function_code, shader_code]) then
    begin
      Get_prev_stmt_info(stmt_info_ptr);
      stmt_ptr := New_stmt(return_stmt);
      Set_stmt_info(stmt_ptr, stmt_info_ptr);

      Get_next_token;
      Match(semi_colon_tok);

      Get_post_stmt_info(stmt_info_ptr);
    end
  else
    begin
      Parse_error;
      writeln('Return statements are not allowed in functions.');
      writeln('Use an answer statement to return a value instead.');
      error_reported := true;
    end;
end; {procedure Parse_return_stmt}


{************************  productions  ************************}
{       <exit_stmt> ::= exit ;                                  }
{***************************************************************}

procedure Parse_exit_stmt(var stmt_ptr: stmt_ptr_type);
var
  stmt_info_ptr: stmt_info_ptr_type;
begin
  Get_prev_stmt_info(stmt_info_ptr);
  stmt_ptr := New_stmt(exit_stmt);
  Set_stmt_info(stmt_ptr, stmt_info_ptr);

  Get_next_token;
  Match(semi_colon_tok);

  Get_post_stmt_info(stmt_info_ptr);
end; {procedure Parse_exit_stmt}


function New_prim_answer_stmt(kind: type_kind_type): stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  case kind of

    {***************************************}
    { enumerated function return statements }
    {***************************************}
    type_boolean:
      stmt_ptr := New_stmt(boolean_answer);
    type_char:
      stmt_ptr := New_stmt(char_answer);

    {************************************}
    { integer function return statements }
    {************************************}
    type_byte:
      stmt_ptr := New_stmt(byte_answer);
    type_short:
      stmt_ptr := New_stmt(short_answer);
    type_integer:
      stmt_ptr := New_stmt(integer_answer);
    type_long:
      stmt_ptr := New_stmt(long_answer);

    {***********************************}
    { scalar function return statements }
    {***********************************}
    type_scalar:
      stmt_ptr := New_stmt(scalar_answer);
    type_double:
      stmt_ptr := New_stmt(double_answer);
    type_complex:
      stmt_ptr := New_stmt(complex_answer);
    type_vector:
      stmt_ptr := New_stmt(vector_answer);

  else
    stmt_ptr := nil;
  end; {case}

  New_prim_answer_stmt := stmt_ptr;
end; {function New_prim_answer_stmt}


function New_answer_stmt(type_attributes_ptr: type_attributes_ptr_type):
  stmt_ptr_type;
var
  stmt_ptr: stmt_ptr_type;
begin
  case type_attributes_ptr^.kind of

    {***********************}
    { primitive assignments }
    {***********************}
    type_boolean..type_vector:
      stmt_ptr := New_prim_answer_stmt(type_attributes_ptr^.kind);

    {*******************************}
    { user defined type assignments }
    {*******************************}
    type_enum:
      stmt_ptr := New_prim_answer_stmt(type_integer);
    type_alias:
      stmt_ptr :=
        New_answer_stmt(type_attributes_ptr^.alias_type_attributes_ptr);
    type_array:
      stmt_ptr := New_stmt(array_ptr_answer);
    type_struct, type_class:
      stmt_ptr := New_stmt(struct_ptr_answer);
    type_class_alias:
      stmt_ptr :=
        New_answer_stmt(type_attributes_ptr^.class_alias_type_attributes_ptr);
    type_code:
      stmt_ptr := New_stmt(proto_answer);

    {*******************************}
    { general reference assignments }
    {*******************************}
    type_reference:
      stmt_ptr := New_stmt(reference_answer);

  else
    stmt_ptr := nil;
  end; {case}

  New_answer_stmt := stmt_ptr;
end; {function New_answer_stmt}


{************************  productions  ************************}
{       <answer_stmt> ::= answer <expr> ;                       }
{***************************************************************}

procedure Parse_answer_stmt(var stmt_ptr: stmt_ptr_type);
var
  stmt_info_ptr: stmt_info_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type;
begin
  {*******************************************************}
  { find enclosing method kind from scope decl attributes }
  {*******************************************************}
  decl_attributes_ptr := Get_scope_decl_attributes;
  type_attributes_ptr := decl_attributes_ptr^.type_attributes_ptr;
  code_attributes_ptr := type_attributes_ptr^.code_attributes_ptr;

  if (code_attributes_ptr^.kind in [function_code, shader_code]) then
    begin
      {****************************}
      { find return type of method }
      {****************************}
      expr_attributes_ptr :=
        expr_attributes_ptr_type(code_attributes_ptr^.return_value_attributes_ptr);

      {*****************************}
      { create new answer statement }
      {*****************************}
      Get_prev_stmt_info(stmt_info_ptr);
      stmt_ptr := New_answer_stmt(expr_attributes_ptr^.type_attributes_ptr);
      Set_stmt_info(stmt_ptr, stmt_info_ptr);
      Get_next_token;

      {*********************************}
      { parse expression to be returned }
      {*********************************}
      if expr_attributes_ptr^.type_attributes_ptr^.kind in primitive_type_kinds
        then
        Parse_equal_expr(stmt_ptr^.answer_expr_ptr, expr_attributes_ptr)
      else
        Parse_same_expr(stmt_ptr^.answer_expr_ptr, expr_attributes_ptr);

      Match(semi_colon_tok);
      Get_post_stmt_info(stmt_info_ptr);
    end
  else
    begin
      Parse_error;
      writeln('Answer statements are only allowed in functions.');
      error_reported := true;
    end;
end; {procedure Parse_answer_stmt}


{***************************************************************}
{                       scoping statements                      }
{***************************************************************}
{       <scoping_stmt> ::= <with_stmt>                          }
{***************************************************************}


{************************  productions  ************************}
{       <with_stmt> ::= with <expr> do <stmts> end ;            }
{***************************************************************}

procedure Parse_with_stmt(var stmt_ptr: stmt_ptr_type);
var
  stmt_info_ptr: stmt_info_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
begin
  Get_prev_stmt_info(stmt_info_ptr);
  stmt_ptr := New_stmt(with_stmt);
  Set_stmt_info(stmt_ptr, stmt_info_ptr);

  Get_next_token;
  Parse_id(stmt_ptr^.with_expr_ptr, expr_attributes_ptr);
  Deref_expr(stmt_ptr^.with_expr_ptr, expr_attributes_ptr);

  if parsing_ok then
    begin
      Match(do_tok);
      Push_antecedent_scope(stmt_ptr^.with_expr_ptr, expr_attributes_ptr);
      Parse_stmt_block(stmt_ptr^.with_decls_ptr, stmt_ptr^.with_stmts_ptr);
      Pop_antecedent_scope;
      Match(end_tok);
    end;

  if not (next_token.kind in [right_paren_tok, comma_tok]) then
    Match(semi_colon_tok);

  Get_post_stmt_info(stmt_info_ptr);
end; {procedure Parse_with_stmt}


{***************************************************************}
{                  memory allocation statements                 }
{***************************************************************}
{       <memory_stmt> ::= <dim_stmt>                            }
{       <memory_stmt> ::= <redim_stmt>                          }
{       <memory_stmt> ::= <new_stmt>                            }
{       <memory_stmt> ::= <renew_stmt>                          }
{***************************************************************}


procedure Parse_dim_stmt_tail(stmt_ptr: stmt_ptr_type);
var
  expr_attributes_ptr: expr_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  struct_type_ptr: type_ptr_type;
  found_nil_token: boolean;
begin
  if (next_token.kind = none_tok) then
    begin
      found_nil_token := true;
      Get_next_token;
    end
  else
    found_nil_token := false;

  {**********************}
  { match array variable }
  {**********************}
  Parse_id_inst(stmt_ptr^.dim_data_ptr, expr_attributes_ptr);
  Deref_expr(stmt_ptr^.dim_data_ptr, expr_attributes_ptr);
  Parse_derefs_or_dims(stmt_ptr^.dim_data_ptr, stmt_ptr^.dim_expr_ptr,
    expr_attributes_ptr);

  if parsing_ok then
    if (stmt_ptr^.dim_expr_ptr <> nil) then
      begin
        type_attributes_ptr :=
          Base_type_attributes(expr_attributes_ptr^.type_attributes_ptr);

        if found_nil_token then
          begin
            {***********************************}
            { do not create implicit struct new }
            {***********************************}
            if not (type_attributes_ptr^.kind in structured_type_kinds) then
              begin
                Parse_error;
                writeln('Expected a structure or class variable here.');
                error_reported := true;
              end;
          end
        else if type_attributes_ptr^.kind in structured_type_kinds then
          begin
            struct_type_ptr := Get_type_decl(type_attributes_ptr);
            Parse_struct_array_new(stmt_ptr^.dim_expr_ptr, struct_type_ptr);
          end;
      end
    else
      begin
        Parse_error;
        writeln('Expected an array and its dimensions here.');
        error_reported := true;
      end;

  if not (next_token.kind in [right_paren_tok, comma_tok]) then
    Match(semi_colon_tok);

  Get_post_stmt_info(stmt_ptr^.stmt_info_ptr);
end; {procedure Parse_dim_stmt_tail}


{************************  productions  ************************}
{       <dim_stmt> ::= dim id <array_decls>                     }
{***************************************************************}

procedure Parse_dim_stmt(var stmt_ptr: stmt_ptr_type);
var
  stmt_info_ptr: stmt_info_ptr_type;
begin
  Get_prev_stmt_info(stmt_info_ptr);
  stmt_ptr := New_stmt(dim_stmt);
  Set_stmt_info(stmt_ptr, stmt_info_ptr);
  Get_next_token;
  Parse_dim_stmt_tail(stmt_ptr);
end; {procedure Parse_dim_stmt}


{************************  productions  ************************}
{       <dim_stmt> ::= dim id <array_decls>                     }
{***************************************************************}

procedure Parse_redim_stmt(var stmt_ptr: stmt_ptr_type);
var
  stmt_info_ptr: stmt_info_ptr_type;
begin
  Get_prev_stmt_info(stmt_info_ptr);
  stmt_ptr := New_stmt(redim_stmt);
  Set_stmt_info(stmt_ptr, stmt_info_ptr);
  Get_next_token;
  Parse_dim_stmt_tail(stmt_ptr);
end; {procedure Parse_redim_stmt}


{************************  productions  ************************}
{       <new_stmt> ::= new id <cmplx_stmt_tail> ;               }
{***************************************************************}

procedure Parse_new_stmt(var stmt_ptr: stmt_ptr_type);
var
  stmt_info_ptr: stmt_info_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  struct_type_ptr: type_ptr_type;
begin
  Get_prev_stmt_info(stmt_info_ptr);
  stmt_ptr := New_stmt(new_struct_stmt);
  Set_stmt_info(stmt_ptr, stmt_info_ptr);
  Get_next_token;

  Parse_id(stmt_ptr^.new_data_ptr, expr_attributes_ptr);
  Deref_expr(stmt_ptr^.new_data_ptr, expr_attributes_ptr);

  if parsing_ok then
    begin
      type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
      if not (type_attributes_ptr^.kind in structured_type_kinds) then
        begin
          Parse_error;
          writeln('A struct or class is required for new.');
          error_reported := true;
        end
      else if type_attributes_ptr^.static then
        begin
          Parse_error;
          writeln('A non static struct or class is required for new.');
          error_reported := true;
        end
      else
        begin
          struct_type_ptr := Get_type_decl(type_attributes_ptr);
          Parse_implicit_struct_new(stmt_ptr^.new_expr_ptr, struct_type_ptr);
        end;
    end;

  if not (next_token.kind in [right_paren_tok, comma_tok]) then
    Match(semi_colon_tok);

  Get_post_stmt_info(stmt_info_ptr);
end; {procedure Parse_new_stmt}


{************************  productions  ************************}
{       <new_stmt> ::= renew id <cmplx_stmt_tail> ;             }
{***************************************************************}

procedure Parse_renew_stmt(var stmt_ptr: stmt_ptr_type);
var
  stmt_info_ptr: stmt_info_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  struct_type_ptr: type_ptr_type;
begin
  Get_prev_stmt_info(stmt_info_ptr);
  stmt_ptr := New_stmt(renew_struct_stmt);
  Set_stmt_info(stmt_ptr, stmt_info_ptr);
  Get_next_token;

  if not (next_token.kind in stmt_terminator_set) then
    begin
      Parse_id(stmt_ptr^.new_data_ptr, expr_attributes_ptr);
      Deref_expr(stmt_ptr^.new_data_ptr, expr_attributes_ptr);

      if parsing_ok then
        begin
          type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
          if not (type_attributes_ptr^.kind in structured_type_kinds) then
            begin
              Parse_error;
              writeln('A struct or class is required for new.');
              error_reported := true;
            end
          else if type_attributes_ptr^.static then
            begin
              Parse_error;
              writeln('A non static struct or class is required for new.');
              error_reported := true;
            end
          else
            begin
              struct_type_ptr := Get_type_decl(type_attributes_ptr);
              Parse_implicit_struct_new(stmt_ptr^.new_expr_ptr,
                struct_type_ptr);
            end;
        end;
    end;

  if not (next_token.kind in [right_paren_tok, comma_tok]) then
    Match(semi_colon_tok);

  Get_post_stmt_info(stmt_info_ptr);
end; {procedure Parse_renew_stmt}


{************************  productions  ************************}
{       <stmt> ::= id <assign_or_proc_stmt>                     }
{       <assign_or_proc_stmt> ::= <assign_tail>                 }
{       <assign_or_proc_stmt> ::= <proc_stmt_tail>              }
{***************************************************************}

procedure Parse_assign_or_proc_stmt(var stmt_ptr, last_stmt_ptr: stmt_ptr_type);
const
  valid_kinds = [type_class, type_code];
var
  expr_ptr: expr_ptr_type;
  code_ptr: code_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
  code_attributes_ptr: code_attributes_ptr_type;
begin
  expr_ptr := nil;
  expr_attributes_ptr := nil;

  {*************************************}
  { parse lhs id of assign or proc stmt }
  {*************************************}
  Parse_unit(expr_ptr, expr_attributes_ptr);
  Parse_id_fields_and_derefs(expr_ptr, expr_attributes_ptr);

  if parsing_ok then
    begin
      {*****************}
      { parse statement }
      {*****************}
      if (next_token.kind = assignment_tok) then
        begin
          Parse_error;
          writeln('Please use the ', Quotate_str('='),
            ' sign for assignments.');
          error_reported := true;
        end

          {*************}
          { assignments }
          {*************}
      else if next_token.kind in initializer_predict_set then
        begin
          Parse_assign_stmt_tail(stmt_ptr, expr_ptr, expr_attributes_ptr);
          if parsing_ok then
            if stmt_ptr <> nil then
              last_stmt_ptr := stmt_ptr
            else
              begin
                Parse_error;
                writeln('No assignment defined for this type.');
                error_reported := true;
              end;
        end

          {*******************}
          { shader statements }
          {*******************}
      else if expr_ptr^.kind = user_fn then
        begin
          stmt_ptr := stmt_ptr_type(expr_ptr^.fn_stmt_ptr);
          code_ptr := code_ptr_type(stmt_ptr^.stmt_code_ref);
          if code_ptr^.kind = shader_code then
            Parse_shader_stmt_tail(stmt_ptr, last_stmt_ptr, expr_ptr,
              expr_attributes_ptr)
          else
            begin
              Parse_error;
              writeln('This expression does not belong here ');
              error_reported := true;
            end;
        end

          {***********************}
          { subprogram statements }
          {***********************}
      else
        begin
          type_attributes_ptr := expr_attributes_ptr^.alias_type_attributes_ptr;
          type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);

          if type_attributes_ptr^.kind = type_code then
            begin
              code_attributes_ptr := type_attributes_ptr^.code_attributes_ptr;
              if code_attributes_ptr^.kind in procedural_code_kinds then
                Parse_proc_stmt_tail(stmt_ptr, last_stmt_ptr, expr_ptr, nil,
                  expr_attributes_ptr)
            end
          else if type_attributes_ptr^.kind in class_type_kinds then
            Parse_proc_method_tail(stmt_ptr, last_stmt_ptr, expr_ptr,
              expr_attributes_ptr)
          else
            begin
              Parse_error;
              writeln('Expected an assignment or procedure call here.');
              error_reported := true;
            end;
        end;

      if not (next_token.kind in [right_paren_tok, comma_tok]) then
        Match(semi_colon_tok);

      if parsing_ok then
        Get_post_stmt_info(last_stmt_ptr^.stmt_info_ptr);
    end; {if parsing_ok}
end; {procedure Parse_assign_or_proc_stmt}


{************************  productions  ************************}
{				<stmt> ::= <break_stmt>																	}
{				<stmt> ::= <continue_stmt>															}
{       <stmt> ::= <return_stmt>                                }
{***************************************************************}

procedure Parse_last_stmt(var stmt_ptr: stmt_ptr_type);
begin
  if parsing_ok then
    if next_token.kind in last_stmt_predict_set then
      begin
        case next_token.kind of

          {*************************}
          { flow control statements }
          {*************************}
          break_tok:
            Parse_break_stmt(stmt_ptr);
          continue_tok:
            Parse_continue_stmt(stmt_ptr);
          return_tok:
            Parse_return_stmt(stmt_ptr);
          answer_tok:
            Parse_answer_stmt(stmt_ptr);
          exit_tok:
            Parse_exit_stmt(stmt_ptr);

        end; {case}
      end
    else
      parsing_ok := false;
end; {procedure Parse_last_stmt}


{******************************}
{ routines to parse statements }
{******************************}


procedure Parse_stmt(var stmt_ptr: stmt_ptr_type);
var
  last_stmt_ptr: stmt_ptr_type;
begin
  Parse_stmt_list(stmt_ptr, last_stmt_ptr);
end; {procedure Parse_stmt}


procedure Parse_stmts(var stmt_ptr: stmt_ptr_type);
var
  last_stmt_ptr: stmt_ptr_type;
begin
  Parse_stmts_list(stmt_ptr, last_stmt_ptr);
end; {procedure Parse_stmts}


{***********************************}
{ routines to parse statement lists }
{***********************************}


{************************  productions  ************************}
{       <stmt> ::= <if_stmt>                                    }
{       <stmt> ::= <case_stmt>                                  }
{       <stmt> ::= <while_stmt>                                 }
{       <stmt> ::= <for_stmt>                                   }
{       <stmt> ::= <loop_stmt>                                  }
{       <stmt> ::= <built_in_stmt>                              }
{***************************************************************}

procedure Parse_stmt_list(var stmt_ptr, last_stmt_ptr: stmt_ptr_type);
begin
  stmt_ptr := nil;
  last_stmt_ptr := nil;

  if parsing_ok then
    if next_token.kind in stmt_predict_set then
      begin
        {*****************************}
        { set antecedent for 'itself' }
        {*****************************}
        Reset_antecedent;
        last_stmt_ptr := nil;

        if next_token.kind in smpl_stmt_predict_set then
          case next_token.kind of

            {************************}
            { conditional statements }
            {************************}
            if_tok:
              Parse_if_stmt(stmt_ptr);
            when_tok:
              Parse_case_stmt(stmt_ptr);

            {********************}
            { looping statements }
            {********************}
            while_tok:
              Parse_while_stmt(stmt_ptr);
            for_tok:
              Parse_for_stmt(stmt_ptr);

            {*************************}
            { flow control statements }
            {*************************}
            break_tok:
              Parse_break_stmt(stmt_ptr);
            continue_tok:
              Parse_continue_stmt(stmt_ptr);
            loop_tok:
              Parse_loop_stmt(stmt_ptr);
            return_tok:
              Parse_return_stmt(stmt_ptr);
            answer_tok:
              Parse_answer_stmt(stmt_ptr);
            exit_tok:
              Parse_exit_stmt(stmt_ptr);

            {********************}
            { scoping statements }
            {********************}
            with_tok:
              Parse_with_stmt(stmt_ptr);

            {******************************}
            { memory allocation statements }
            {******************************}
            dim_tok:
              Parse_dim_stmt(stmt_ptr);
            redim_tok:
              Parse_redim_stmt(stmt_ptr);
            new_tok:
              Parse_new_stmt(stmt_ptr);
            renew_tok:
              Parse_renew_stmt(stmt_ptr);

          end {case}

            {*********************}
            { built in statements }
            {*********************}
        else if next_token.kind in io_stmt_predict_set then
          Parse_instructs(stmt_ptr, last_stmt_ptr)

          {***********************************}
          { assignments and complex statments }
          {***********************************}
        else
          Parse_assign_or_proc_stmt(stmt_ptr, last_stmt_ptr);

        if (last_stmt_ptr = nil) then
          last_stmt_ptr := stmt_ptr;
      end
    else
      begin
        Parse_error;
        writeln('Expected a statement here.');
        error_reported := true;
      end;
end; {procedure Parse_stmt_list}


{************************  productions  ************************}
{       <stmts> ::= <stmt> <more_stmts>                         }
{***************************************************************}

procedure Parse_stmts_list(var stmt_ptr, last_stmt_ptr: stmt_ptr_type);
var
  done: boolean;
begin
  stmt_ptr := nil;
  last_stmt_ptr := nil;

  if parsing_ok then
    begin
      done := false;

      {*******************************************************}
      { parse assignment, conditional, looping statements etc }
      {*******************************************************}
      if next_token.kind in stmt_predict_set then
        begin
          Parse_stmt_list(stmt_ptr, last_stmt_ptr);

          if parsing_ok then
            begin
              if Stmts_break(stmt_ptr) then
                done := true;

              if parsing_ok then
                begin
                  Get_post_stmt_info(stmt_ptr^.stmt_info_ptr);

                  if (next_token.kind in stmt_predict_set) and done then
                    begin
                      Parse_error;
                      writeln('This statement is never reached.');
                      error_reported := true;
                    end;

                  Parse_more_stmts(last_stmt_ptr^.next, last_stmt_ptr);
                end;
            end;
        end;

      {*******************************}
      { parse flow control statements }
      {*******************************}
      if parsing_ok then
        if (next_token.kind in last_stmt_predict_set) then
          begin
            if done then
              begin
                Parse_error;
                writeln('This statement is never reached.');
                error_reported := true;
              end;

            if (next_token.kind = return_tok) then
              if (parsing_param_decls or parsing_param_values) then
                done := true;

            if parsing_ok and (not done) then
              begin
                if last_stmt_ptr <> nil then
                  begin
                    Parse_last_stmt(last_stmt_ptr^.next);
                    last_stmt_ptr := last_stmt_ptr^.next;
                  end
                else
                  begin
                    Parse_last_stmt(stmt_ptr);
                    last_stmt_ptr := stmt_ptr;
                  end;

              end;
          end;

      {*************************}
      { parse trailing comments }
      {*************************}
      Parse_null_stmt(stmt_ptr, last_stmt_ptr);
    end;
end; {procedure Parse_stmts_list}


{************************  productions  ************************}
{       <more_stmts> ::= <stmts>                                }
{       <more_stmts> ::=                                        }
{***************************************************************}

procedure Parse_more_stmts(var stmt_ptr, last_stmt_ptr: stmt_ptr_type);
var
  done: boolean;
begin
  if parsing_ok then
    if next_token.kind in stmt_predict_set then
      begin
        Parse_stmt_list(stmt_ptr, last_stmt_ptr);

        if parsing_ok then
          begin
            done := Stmts_break(stmt_ptr);

            if parsing_ok then
              begin
                Get_post_stmt_info(stmt_ptr^.stmt_info_ptr);

                if (next_token.kind in stmt_predict_set) and done then
                  begin
                    Parse_error;
                    writeln('This statement is never reached.');
                    error_reported := true;
                  end;

                Parse_more_stmts(last_stmt_ptr^.next, last_stmt_ptr);
              end;
          end;
      end;
end; {procedure Parse_more_stmts}


procedure Parse_null_stmt(var stmt_ptr, last_stmt_ptr: stmt_ptr_type);
var
  comments_ptr: comments_ptr_type;
  stmt_info_ptr: stmt_info_ptr_type;
begin
  if parsing_ok then
    begin
      comments_ptr := nil;
      Get_prev_token_comments(comments_ptr);

      if comments_ptr <> nil then
        begin
          {************************************}
          { create null stmt to store comments }
          {************************************}
          if last_stmt_ptr <> nil then
            begin
              last_stmt_ptr^.next := New_stmt(null_stmt);
              last_stmt_ptr := last_stmt_ptr^.next;
            end
          else
            begin
              stmt_ptr := New_stmt(null_stmt);
              last_stmt_ptr := stmt_ptr;
            end;

          {***************}
          { save comments }
          {***************}
          stmt_info_ptr := New_stmt_info;
          stmt_info_ptr^.comments_ptr := comments_ptr;
          stmt_info_ptr^.line_number := Get_line_number;
          Set_stmt_info(last_stmt_ptr, stmt_info_ptr);
        end;
    end;
end; {procedure Parse_null_stmt}


initialization
  label_stack_ptr := 0;
  label_stack := nil;
  label_free_list := nil;
  label_index := 0;

  if memory_alert then
    writeln('allocating new label stack');
  new(label_stack);
end.
