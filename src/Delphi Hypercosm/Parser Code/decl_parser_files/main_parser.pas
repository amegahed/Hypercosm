unit main_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             main_parser               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to parse the root         }
{       declaration into an abstract syntax tree                }
{       representation.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  syntax_trees;


{************************************}
{ routines to parse program listings }
{************************************}
function Parse_program(pedantic, optimize, implicit_args: boolean):
  syntax_tree_ptr_type;
function Parse_fragment(pedantic, optimize, implicit_args: boolean):
  syntax_tree_ptr_type;


implementation
uses
  new_memory, vectors, strings, code_types, hashtables, symbol_tables,
    code_attributes, type_attributes, decl_attributes, stmt_attributes,
    expr_attributes, lit_attributes, prim_attributes, value_attributes, comments,
    compare_types, arrays, exprs, instructs, stmts, decls, type_decls, code_decls,
    type_assigns, array_assigns, file_stack, scanner, tokens, tokenizer,
    scope_stacks, scoping, parser, typechecker, match_literals, match_terms,
    term_parser, include_parser, array_parser, data_parser, stmt_parser,
    class_parser, decl_parser, optimizer, native_glue, addressing;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


{***************************************************************}
{                           basic format                        }
{***************************************************************}
{       <goal> ::= <main_header> <decls> eof                    }
{                                                               }
{       <main_header> ::= do <tasks> ;                          }
{       <tasks> ::= <task> <more_tasks>                         }
{       <more_tasks> ::= <tasks>                                }
{       <more_tasks> ::=                                        }
{       <task> ::= <procedure_name>                             }
{       <task> ::= <picture_name>                               }
{       <task> ::= <anim_name>                                  }
{       <procedure_name> ::= id                                 }
{       <picture_name> ::= id                                   }
{       <anim_name> ::= id                                      }
{***************************************************************}


{***************************************************************}
{                          declarations                         }
{***************************************************************}
{       <decl> ::= <include>                                    }
{       <decl> ::= <enum_decl>                                  }
{       <decl> ::= <struct_decl>                                }
{       <decl> ::= <class_decl>                                 }
{       <decl> ::= <simple_decl>                                }
{       <decl> ::= <complex_decl>                               }
{                                                               }
{       <decls> ::= <decl> <more_decls>                         }
{       <decls> ::=                                             }
{       <more_decls> ::= <decls>                                }
{       <more_decls> ::=                                        }
{***************************************************************}


{***************************************************************}
{                            includes                           }
{***************************************************************}
{       <include> ::= include <file_names> ;                    }
{       <file_names> ::= <file_name> <more_file_names>          }
{       <more_file_names> ::= , <file_name> <more_file_names>   }
{       <more_file_names> ::=                                   }
{       <file_name> ::= string_lit                              }
{***************************************************************}


{***************************************************************}
{                       type declarations                       }
{***************************************************************}
{       <type_decl> ::= type id = <enums> ;                     }
{       <enums> ::= <enums> <more_enums>                        }
{       <more_enums> ::= , <enums>                              }
{       <enum> ::= id                                           }
{***************************************************************}


{***************************************************************}
{                      simple declarations                      }
{***************************************************************}
{       <simple_decl> ::= <const_decl>                          }
{       <simple_decl> ::= <var_decl>                            }
{                                                               }
{       <data_decl> ::= <data_type> id  <array_decls>           }
{       <data_type> ::= boolean                                 }
{       <data_type> ::= char                                    }
{       <data_type> ::= integer                                 }
{       <data_type> ::= scalar                                  }
{       <data_type> ::= complex                                 }
{       <data_type> ::= vector                                  }
{                                                               }
{       <initializer> ::= = <unit>                              }
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
{                      const declarations                       }
{***************************************************************}
{       <const_decl> ::= const <const_stuff> <more_consts> ;    }
{       <const_stuff> ::= <data_decl> <initializer>             }
{       <more_consts> ::= , <id> <initializer> <more_consts>    }
{       <more_consts> ::=                                       }
{***************************************************************}


{***************************************************************}
{                      var declarations                         }
{***************************************************************}
{       <var_decl> ::= <var_decl_stuff> <more_vars> ;           }
{       <var_decl_stuff> ::= <data_decl> <var_decl_end>         }
{       <more_vars> ::= , <id> <var_decl_end> <more_vars>       }
{       <more_vars> ::=                                         }
{                                                               }
{       <var_decl_end> ::= <initializer>                        }
{       <var_decl_end> ::=                                      }
{***************************************************************}


{***************************************************************}
{                      complex declarations                     }
{***************************************************************}
{       <complex_decl> ::= <proc_decl> <decl_body>              }
{       <complex_decl> ::= <func_decl> <decl_body>              }
{                                                               }
{       <params> ::= <param> <more_params>                      }
{       <params> ::=                                            }
{       <more_params> ::= <params>                              }
{       <more_params> ::=                                       }
{       <param> ::= <data_decl>                                 }
{       <param> ::= id                                          }
{                                                               }
{       <decl_body> ::= is <decls> <stmts> end ;                }
{***************************************************************}


{***************************************************************}
{                      procedural declarations                  }
{***************************************************************}
{       <proc_decl> ::= <proc_type> id <params> <proc_params>   }
{                                                               }
{       <proc_type> ::= procedure                               }
{       <proc_type> ::= object                                  }
{       <proc_type> ::= picture                                 }
{       <proc_type> ::= anim                                    }
{                                                               }
{       <proc_params> ::= <opt_params> <return_params>          }
{                                                               }
{       <opt_params> ::= with <decls> <stmts>                   }
{       <opt_params> ::=                                        }
{                                                               }
{       <return_params> ::= return <decls>                      }
{       <return_params> ::=                                     }
{***************************************************************}


{***************************************************************}
{                      functional declarations                  }
{***************************************************************}
{       <proc_decl> ::= <func_type> id <params> <return_decl>   }
{                                                               }
{       <func_type> ::= function                                }
{       <func_type> ::= shader                                  }
{                                                               }
{       <return_decl> ::= return <var_decl>                     }
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
  do_default_includes = false;
  check_native_decls = true;
  report_native_decls = false;
  verbose = false;


type
  task_ptr_type = ^task_type;
  task_type = record
    name: string_type;
    next: task_ptr_type;
  end; {task_type}


function New_task(name: string_type): task_ptr_type;
var
  task_ptr: task_ptr_type;
begin
  if memory_alert then
    writeln('allocating new task');
  new(task_ptr);

  task_ptr^.name := name;
  task_ptr^.next := nil;

  New_task := task_ptr;
end; {function New_task}


{************************  productions  ************************}
{       <task> ::= <procedure_name>                             }
{       <task> ::= <picture_name>                               }
{       <task> ::= <anim_name>                                  }
{       <picture_name> ::= id                                   }
{       <anim_name> ::= id                                      }
{***************************************************************}

procedure Parse_task(var task_ptr: task_ptr_type);
const
  predict_set = [id_tok];
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        {**************************************************}
        { tasks are forward declarations, so we don't know }
        { their type until they are formally declared.     }
        {**************************************************}
        task_ptr := New_task(next_token.id);
        Get_next_token;

        if (next_token.kind = comma_tok) then
          Get_next_token;
      end
    else
      parsing_ok := false;
end; {procedure Parse_task}


{************************  productions  ************************}
{       <tasks> ::= <task> <more_tasks>                         }
{       <more_tasks> ::= , <tasks>                              }
{       <more_tasks> ::=                                        }
{***************************************************************}

procedure Parse_tasks(var task_ptr: task_ptr_type);
const
  predict_set = [id_tok];
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        Parse_task(task_ptr);
        if parsing_ok then
          Parse_tasks(task_ptr^.next);
      end
    else
      task_ptr := nil;
end; {procedure Parse_tasks}


{************************  productions  ************************}
{       <main_header> ::= do <tasks> ;                          }
{***************************************************************}

procedure Parse_main_header(var task_ptr: task_ptr_type);
const
  predict_set = [id_tok];
begin
  Match(do_tok);

  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        Parse_tasks(task_ptr);
        Match(semi_colon_tok);
      end
    else
      parsing_ok := false;
end; {procedure Parse_main_header}


function Found_main_args(code_ptr: code_ptr_type): boolean;
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  signature_ptr: signature_ptr_type;
  parameter_ptr: parameter_ptr_type;
  found: boolean;
begin
  found := false;

  if parsing_ok then
    begin
      {**************}
      { check params }
      {**************}
      if not decl_problems then
        begin
          decl_attributes_ptr := Get_decl_attributes(code_ptr^.code_decl_ref);

          signature_ptr :=
            decl_attributes_ptr^.type_attributes_ptr^.code_attributes_ptr^.signature_ptr;
          if signature_ptr <> nil then
            parameter_ptr := signature_ptr^.parameter_ptr
          else
            parameter_ptr := nil;

          if parameter_ptr <> nil then
            begin
              if (parameter_ptr^.next <> nil) or (signature_ptr^.next <> nil)
                then
                begin
                  write('Error - ');
                  write(Quotate_str(Get_decl_attributes_name(decl_attributes_ptr)));
                  writeln(' has too many parameters.');
                  error_reported := true;
                  decl_problems := true;
                  parsing_ok := false;
                end
              else
                begin
                  decl_attributes_ptr :=
                    decl_attributes_ptr_type(Get_id_value(parameter_ptr^.id_ptr));
                  if not
                    Same_type_attributes(decl_attributes_ptr^.type_attributes_ptr,
                    string_array_type_attributes_ptr) then
                    begin
                      write('Error - ');
                      write(Quotate_str(Get_decl_attributes_name(decl_attributes_ptr)));
                      writeln(' has invalid parameters for main.');
                      error_reported := true;
                      decl_problems := true;
                      parsing_ok := false;
                    end
                  else
                    found := true;
                end;
            end;
        end;
    end; {if parsing_ok}

  Found_main_args := found;
end; {function Found_main_args}


procedure Check_main_method(code_ptr: code_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  if parsing_ok then
    begin
      decl_attributes_ptr := Get_decl_attributes(code_ptr^.code_decl_ref);

      {*************************************************}
      { main method must be a procedure picture or anim }
      {*************************************************}
      if not (code_ptr^.kind in procedural_code_kinds) then
        begin
          write('Error - ');
          write(Quotate_str(Get_decl_attributes_name(decl_attributes_ptr)));
          writeln(' is not a procedural method');
          error_reported := true;
          decl_problems := true;
        end;

      {*****************************************************************}
      { main method must be an actual decl, not a forward or proto decl }
      {*****************************************************************}
      if code_ptr^.decl_kind <> actual_decl then
        begin
          write('Error - ');
          write(Quotate_str(Get_decl_attributes_name(decl_attributes_ptr)));
          writeln(' is not an actual declaration.');
          error_reported := true;
          decl_problems := true;
        end;

      {***********************************}
      { main method must be a void method }
      {***********************************}
      if code_ptr^.method_kind <> void_method then
        begin
          write('Error - ');
          write(Quotate_str(Get_decl_attributes_name(decl_attributes_ptr)));
          writeln(' is not an actual declaration.');
          error_reported := true;
          decl_problems := true;
        end;

    end; {if parsing_ok}
end; {procedure Check_main_method}


function New_command_line_args_assign(expr_ptr: expr_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type): stmt_ptr_type;
var
  args_name: string_type;
  args_expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
begin
  Push_dynamic_scope(stmt_attributes_ptr);
  Push_prev_scope(decl_attributes_ptr^.type_attributes_ptr^.code_attributes_ptr^.private_param_table_ptr);

  {***********************************}
  { get attributes of first parameter }
  {***********************************}
  expr_attributes_ptr := Get_expr_attributes(expr_ptr);
  decl_attributes_ptr := expr_attributes_ptr^.decl_attributes_ptr;

  {******************************************}
  { create implicit parameter for assignment }
  {******************************************}
  args_name := Get_decl_attributes_name(decl_attributes_ptr);
  Make_implicit_id(args_name, expr_ptr, expr_attributes_ptr);
  Make_implicit_id('main args', args_expr_ptr, expr_attributes_ptr);
  Pop_dynamic_scope;

  {**************************************}
  { create implicit parameter assignment }
  {**************************************}
  New_command_line_args_assign := New_array_ptr_assign(expr_ptr, args_expr_ptr);
end; {function New_command_line_args_assign}


procedure Match_tasks(var stmt_ptr: stmt_ptr_type;
  task_ptr: task_ptr_type);
var
  found: boolean;
  decl_ptr: decl_ptr_type;
  code_ptr: code_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  last_stmt_ptr, new_stmt_ptr: stmt_ptr_type;
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  param_expr_ptr: expr_ptr_type;
  assign_stmt_ptr: stmt_ptr_type;
begin
  if parsing_ok then
    begin
      last_stmt_ptr := nil;

      while (task_ptr <> nil) do
        begin
          found := Found_id(task_ptr^.name, decl_attributes_ptr,
            stmt_attributes_ptr);

          {*****************************}
          { check to see if id is found }
          {*****************************}
          if not found then
            begin
              writeln('Error - ', Quotate_str(task_ptr^.name),
                ' was found in the header');
              writeln('        but not declared in the body of the program.');
              error_reported := true;
              decl_problems := true;
            end
          else
            {**************************************}
            { check to see if id is the right type }
            {**************************************}
            begin
              if not Found_method_attributes(decl_attributes_ptr,
                procedural_code_kinds) then
                begin
                  writeln('Error - ', task_ptr^.name,
                    ' is not a procedural method');
                  error_reported := true;
                  decl_problems := true;
                end
              else
                begin
                  {**************************************}
                  { get code declaration from attributes }
                  {**************************************}
                  decl_ptr := decl_ptr_type(decl_attributes_ptr^.decl_ref);
                  code_ptr := code_ptr_type(decl_ptr^.code_ptr);

                  {**********************}
                  { create new statement }
                  {**********************}
                  new_stmt_ptr := New_stmt(static_method_stmt);
                  Make_implicit_id(task_ptr^.name, new_stmt_ptr^.stmt_name_ptr,
                    expr_attributes_ptr);
                  new_stmt_ptr^.stmt_code_ref :=
                    forward_code_ref_type(code_ptr);

                  {*********************************}
                  { create new statement attributes }
                  {*********************************}
                  stmt_attributes_ptr :=
                    New_stmt_attributes(decl_attributes_ptr);
                  Set_stmt_attributes(new_stmt_ptr, stmt_attributes_ptr);

                  {************************************************}
                  { create commend line argument param assignments }
                  {************************************************}
                  if parsing_ok then
                    begin
                      Check_main_method(code_ptr);
                      if Found_main_args(code_ptr) then
                        begin
                          param_expr_ptr :=
                            code_ptr^.initial_param_decls_ptr^.data_decl.data_expr_ptr;
                          assign_stmt_ptr :=
                            New_command_line_args_assign(param_expr_ptr,
                            stmt_attributes_ptr, decl_attributes_ptr);
                          new_stmt_ptr^.param_assign_stmts_ptr :=
                            assign_stmt_ptr;
                        end;
                    end;

                  {*********************************}
                  { insert statement at end of list }
                  {*********************************}
                  if (last_stmt_ptr = nil) then
                    begin
                      stmt_ptr := new_stmt_ptr;
                      last_stmt_ptr := new_stmt_ptr;
                    end
                  else
                    begin
                      last_stmt_ptr^.next := new_stmt_ptr;
                      last_stmt_ptr := new_stmt_ptr;
                    end;
                end;
            end;

          task_ptr := task_ptr^.next;
        end;
    end; {while}
end; {procedure Match_tasks}


procedure Add_last_decl(new_decl_ptr: decl_ptr_type;
  var decl_ptr: decl_ptr_type;
  var last_decl_ptr: decl_ptr_type);
begin
  if (new_decl_ptr <> nil) then
    begin
      if (last_decl_ptr <> nil) then
        begin
          last_decl_ptr^.next := new_decl_ptr;
          last_decl_ptr := new_decl_ptr;
        end
      else
        begin
          decl_ptr := new_decl_ptr;
          last_decl_ptr := new_decl_ptr;
        end;
    end;
end; {procedure Add_last_decl}


function New_implicit_arg_decl: decl_ptr_type;
var
  id: string_type;
  decl_ptr: decl_ptr_type;
  expr_ptr, dim_expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type;
  counter: integer;
begin
  id := 'main args';
  decl_attributes_ptr := New_decl_attributes(data_decl_attributes,
    char_type_attributes_ptr, nil);
  Make_implicit_new_id(id, expr_ptr, expr_attributes_ptr, decl_attributes_ptr);

  dim_expr_ptr := nil;
  for counter := 1 to 2 do
    begin
      dim_expr_ptr := New_array_decl_dim(dim_expr_ptr, expr_attributes_ptr);
      dim_expr_ptr^.dim_bounds_list_ptr := New_array_bounds_list;
      Add_array_bounds(dim_expr_ptr^.dim_bounds_list_ptr, New_array_bounds);
      Dim_array_decl_attributes(expr_attributes_ptr, decl_attributes_ptr, 1);
    end;

  decl_ptr := New_data_decl(expr_ptr, expr_attributes_ptr, nil);
  decl_ptr^.data_decl.init_expr_ptr := dim_expr_ptr;

  New_implicit_arg_decl := decl_ptr;
end; {function New_implicit_arg_decl}


{************************************}
{ routines to parse program listings }
{************************************}


function New_AST(implicit_args: boolean): syntax_tree_ptr_type;
var
  syntax_tree_ptr: syntax_tree_ptr_type;
begin
  syntax_tree_ptr := New_syntax_tree(root_tree);

  {*******************************}
  { create command line arguments }
  {*******************************}
  if implicit_args then
    syntax_tree_ptr^.implicit_decls_ptr := New_implicit_arg_decl;

  {*******************}
  { create base class }
  {*******************}
  if syntax_tree_ptr^.implicit_decls_ptr <> nil then
    Init_base_class(syntax_tree_ptr^.implicit_decls_ptr^.next)
  else
    Init_base_class(syntax_tree_ptr^.implicit_decls_ptr);

  New_AST := syntax_tree_ptr;
end; {function New_AST}


procedure Parse_main_decls(var syntax_tree_ptr: syntax_tree_ptr_type;
  task_ptr: task_ptr_type);
begin
  Parse_includes(syntax_tree_ptr^.root_includes_ptr);
  Parse_decls(syntax_tree_ptr^.decls_ptr, nil);

  if parsing_ok then
    begin
      if next_token.kind <> eof_tok then
        begin
          Parse_error;
          writeln('Expected end of file or more declarations here.');
          error_reported := true;
        end;

      if parsing_ok then
        Match_tasks(syntax_tree_ptr^.stmts_ptr, task_ptr);
    end;

  {************************}
  { an indeterminate error }
  {************************}
  if parsing_ok then
    begin
      if decl_problems then
        begin
          syntax_tree_ptr := nil;
          parsing_ok := false;
        end;
    end
  else
    begin
      syntax_tree_ptr := nil;
      if not error_reported then
        Parse_error;
      error_reported := true;
    end;

  if parsing_ok then
    begin
      {*******************************}
      { compute addresses and offsets }
      {*******************************}
      Optimize_AST(syntax_tree_ptr);
      Find_addrs(syntax_tree_ptr);

      {*****************************}
      { remove forward declarations }
      {*****************************}
      if do_remove_unused_decls then
        Remove_forward_tree_decls(syntax_tree_ptr, false);
    end
  else
    syntax_tree_ptr := nil;
end; {procedure Parse_main_decls}


procedure Init_AST(syntax_tree_ptr: syntax_tree_ptr_type);
begin
  {**************************}
  { create new include table }
  {**************************}
  include_file_count := Add_include(Get_file_name);

  {*************************}
  { get first token of file }
  {*************************}
  Get_next_token;

  {**************************************************}
  { include optional native smpl configuration files }
  {**************************************************}
  if do_default_includes then
    Parse_include_file(syntax_tree_ptr^.implicit_includes_ptr, 'sage_includes',
      true);
end; {procedure Init_AST}


function Parse_program(pedantic, optimize, implicit_args: boolean):
  syntax_tree_ptr_type;
var
  syntax_tree_ptr: syntax_tree_ptr_type;
  task_ptr: task_ptr_type;
begin
  syntax_tree_ptr := New_AST(implicit_args);
  Init_AST(syntax_tree_ptr);

  {*******************}
  { set parsing flags }
  {*******************}
  do_report_unused_decls := pedantic;
  do_remove_unused_decls := optimize;

  {*********************************}
  { parse main header: do <tasks> ; }
  {*********************************}
  Parse_main_header(task_ptr);

  {****************************}
  { parse header: do <tasks> ; }
  {****************************}
  Parse_main_decls(syntax_tree_ptr, task_ptr);

  Parse_program := syntax_tree_ptr;
end; {function Parse_program}


function Parse_fragment(pedantic, optimize, implicit_args: boolean):
  syntax_tree_ptr_type;
var
  syntax_tree_ptr: syntax_tree_ptr_type;
  task_ptr: task_ptr_type;
begin
  syntax_tree_ptr := New_AST(implicit_args);
  Init_AST(syntax_tree_ptr);

  {*******************}
  { set parsing flags }
  {*******************}
  do_report_unused_decls := pedantic;
  do_remove_unused_decls := optimize;

  {*************************************}
  { parse optional header: do <tasks> ; }
  {*************************************}
  if next_token.kind = do_tok then
    Parse_main_header(task_ptr)
  else
    task_ptr := nil;

  {*************************}
  { parse main declarations }
  {*************************}
  if parsing_ok then
    Parse_main_decls(syntax_tree_ptr, task_ptr);

  Parse_fragment := syntax_tree_ptr;
end; {function Parse_fragment}


end.
