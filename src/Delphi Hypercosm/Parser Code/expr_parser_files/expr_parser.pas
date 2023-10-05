unit expr_parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            expr_parser                3d       }
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


{****************************}
{ parse a general expression }
{****************************}
procedure Parse_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_unit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);

{**********************************************************}
{ parse an expression logically equivalent to a given type }
{**********************************************************}
procedure Parse_equal_expr(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_equal_unit(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);

{*************************************************************}
{ parse an expression structurally equivalent to a given type }
{*************************************************************}
procedure Parse_same_expr(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
procedure Parse_same_unit(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);

{***************************************************}
{ routines to check expression types and attributes }
{***************************************************}
procedure Check_equal_expr_types(expr_attributes_ptr1, expr_attributes_ptr2:
  expr_attributes_ptr_type);
procedure Check_same_expr_types(expr_attributes_ptr1, expr_attributes_ptr2:
  expr_attributes_ptr_type);
procedure Check_reference_attributes(expr_attributes_ptr:
  expr_attributes_ptr_type);


implementation
uses
  strings, type_attributes, code_attributes, decl_attributes, prim_attributes,
    value_attributes, compare_exprs, type_decls, make_exprs, tokens, tokenizer,
    parser, match_literals, term_parser, id_expr_parser, array_expr_parser,
    math_expr_parser, casting, operators, implicit_derefs, rel_expr_parser,
    limit_parser, cons_parser, data_parser;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}


{***************************************************************}
{                       simple expressions                      }
{***************************************************************}
{       <boolean_expr> ::= <expr>                               }
{       <char_expr> ::= <expr>                                  }
{       <integer_expr> ::= <math_expr>                          }
{       <scalar_expr> ::=  <math_expr>                          }
{       <complex_expr> ::= <math_expr>                          }
{       <vector_expr> ::=  <math_expr>                          }
{***************************************************************}


{***************************************************************}
{                       array expressions                       }
{***************************************************************}
{       <array_expr> ::= [ <exprs> ]                            }
{       <array_expr> ::= <array_id>                             }
{                                                               }
{       <array_id> ::= id <array_indices>                       }
{       <array_indices> ::= <array_index> <array_indices>       }
{       <array_index> ::=                                       }
{       <array_index> ::= [ <integer_expr> ]                    }
{                                                               }
{       <exprs> ::= <expr> <more_exprs>                         }
{       <more_exprs> ::= <expr> <more_exprs>                    }
{       <more_exprs> ::=                                        }
{***************************************************************}


{***************************************************************}
{                      boolean expressions                      }
{***************************************************************}
{       <expr> ::= <bool_term> <bool_expr_tail>                 }
{       <bool_expr_tail> ::= or <bool_term> <bool_expr_tail>    }
{                                                               }
{       <bool_term> ::= <rel_expr> <bool_term_tail>             }
{       <bool_term_tail> ::= and <rel_expr> <bool_term_tail>    }
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


{***************************************************************}
{                            terminals                          }
{***************************************************************}
{       <boolean> ::= <unit>                                    }
{       <char> ::= <unit>                                       }
{       <integer> ::= <unit>                                    }
{                                                               }
{       <scalar> ::= <number>                                   }
{       <complex> ::= <number>                                  }
{       <vector> ::= <number>                                   }
{                                                               }
{       <unit> ::= ( <expr> )                                   }
{       <unit> ::= - <unit>                                     }
{                                                               }
{       <unit> ::= id <array_indices> <struct_offsets>          }
{       <unit> ::= not <boolean>                                }
{       <unit> ::= true                                         }
{       <unit> ::= false                                        }
{       <unit> ::= string_lit                                   }
{       <unit> ::= integer_lit                                  }
{       <unit> ::= scalar_lit                                   }
{       <unit> ::= nil                                          }
{       <unit> ::= nothing                                      }
{                                                               }
{       <unit> ::= boolean_fn                                   }
{       <unit> ::= char_fn                                      }
{       <unit> ::= integer_fn                                   }
{       <unit> ::= scalar_fn                                    }
{                                                               }
{       <array_indices> ::= [ <integer_expr> ] <array_indices>  }
{       <array_indices> ::=                                     }
{                                                               }
{       <struct_offsets> ::= . id <struct_offsets>              }
{       <struct_offsets> ::=                                    }
{***************************************************************}


{***************************************************************}
{                        built in functions                     }
{***************************************************************}
{                                                               }
{       <char_fn>    ::= chr <integer>                          }
{       <integer_fn> ::= ord <char>                             }
{       <integer_fn> ::= trunc <integer>                        }
{       <integer_fn> ::= round <integer>                        }
{       <integer_fn> ::= sqr <integer>                          }
{       <integer_fn> ::= abs <integer>                          }
{       <integer_fn> ::= sign <integer>                         }
{                                                               }
{       <scalar_fn> ::= sin <scalar>                            }
{       <scalar_fn> ::= cos <scalar>                            }
{       <scalar_fn> ::= tan <scalar>                            }
{       <scalar_fn> ::= asin <scalar>                           }
{       <scalar_fn> ::= acos <scalar>                           }
{       <scalar_fn> ::= atan <scalar>                           }
{       <scalar_fn> ::= ln <scalar>                             }
{       <scalar_fn> ::= log <scalar>                            }
{       <scalar_fn> ::= exp <scalar>                            }
{       <scalar_fn> ::= sqr <scalar>                            }
{       <scalar_fn> ::= sqrt <scalar>                           }
{       <scalar_fn> ::= abs <scalar>                            }
{       <scalar_fn> ::= sign <scalar>                           }
{                                                               }
{       <scalar_fn> ::= noise <integer>                         }
{       <scalar_fn> ::= noise <scalar>                          }
{       <scalar_fn> ::= noise <complex>                         }
{       <scalar_fn> ::= noise <vector>                          }
{                                                               }
{       <scalar_fn> ::= smaller <scalar> <scalar>               }
{       <scalar_fn> ::= larger <scalar> <scalar>                }
{       <scalar_fn> ::= clamp <scalar> <scalar> <scalar>        }
{       <scalar_fn> ::= arctan <scalar> <scalar>                }
{                                                               }
{       <scalar_fn> ::= real <complex>                          }
{       <scalar_fn> ::= imag <complex>                          }
{       <scalar_fn> ::= abs <complex>                           }
{                                                               }
{       <complex_fn> ::= sqr <complex>                          }
{       <complex_fn> ::= sqrt <complex>                         }
{                                                               }
{       <vector_fn> ::= vnoise <integer>                        }
{       <vector_fn> ::= vnoise <scalar>                         }
{       <vector_fn> ::= vnoise <complex>                        }
{       <vector_fn> ::= vnoise <vector>                         }
{                                                               }
{       <flags> ::= <read_flag> <write_flag>                    }
{       <read_flag> ::= boolean                                 }
{       <write_flag> ::= boolean                                }
{***************************************************************}


{************************  productions  ************************}
{       <unit> ::= not <unit>                                   }
{***************************************************************}

procedure Parse_not(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if parsing_ok then
    begin
      Match(not_tok);
      expr_ptr := New_expr(not_op);

      {************************************}
      { first, try to parse a boolean unit }
      {************************************}
      expr_attributes_ptr := boolean_value_attributes_ptr;
      Parse_unit(expr_ptr^.operand_ptr, expr_attributes_ptr);
      Deref_expr(expr_ptr^.operand_ptr, expr_attributes_ptr);

      {*********************************************************}
      { if first term is not a boolean, then it must be part of }
      { a relational expression (a = b, a > b, a is b etc.)     }
      {*********************************************************}
      if parsing_ok then
        if expr_attributes_ptr <> nil then
          if expr_attributes_ptr^.type_attributes_ptr <>
            boolean_type_attributes_ptr then
            Parse_rel_expr_tail(expr_ptr^.operand_ptr, expr_attributes_ptr);

      {******************************}
      { return constant boolean type }
      {******************************}
      if parsing_ok then
        expr_attributes_ptr := boolean_value_attributes_ptr
      else
        begin
          expr_ptr := nil;
          expr_attributes_ptr := nil;
        end;
    end;
end; {procedure Parse_not}


{************************  productions  ************************}
{       <unit> ::= - <unit>                                     }
{***************************************************************}

procedure Parse_negation(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
const
  valid_kinds = [type_integer, type_scalar, type_complex, type_vector];
var
  operand_ptr: expr_ptr_type;
  operand_kind: type_kind_type;
  expr_kind: expr_kind_type;
begin
  if parsing_ok then
    begin
      Match(minus_tok);
      expr_attributes_ptr := scalar_value_attributes_ptr;
      Parse_unit(operand_ptr, expr_attributes_ptr);
      Deref_expr(operand_ptr, expr_attributes_ptr);

      if parsing_ok then
        begin
          if expr_attributes_ptr <> nil then
            operand_kind := expr_attributes_ptr^.type_attributes_ptr^.kind
          else
            operand_kind := type_error;

          if operand_kind in valid_kinds then
            begin
              case operand_kind of
                type_integer:
                  expr_kind := integer_negate;
                type_scalar:
                  expr_kind := scalar_negate;
                type_complex:
                  expr_kind := complex_negate;
                type_vector:
                  expr_kind := vector_negate;
              else
                expr_kind := error_expr;
              end; {case}

              expr_ptr := New_expr(expr_kind);
              expr_ptr^.operand_ptr := operand_ptr;
            end
          else
            begin
              Parse_error;
              writeln('Can not negate this type.');
              error_reported := true;

              Destroy_exprs(operand_ptr, true);
              expr_ptr := nil;
              expr_attributes_ptr := nil;
            end;
        end; {if parsing_ok}
    end {if parsing ok}
  else
    expr_ptr := nil;
end; {procedure Parse_negation}


procedure Parse_string_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if expr_attributes_ptr = nil then
    Parse_string_expr(expr_ptr, expr_attributes_ptr)
  else if expr_attributes_ptr^.dimensions = 0 then
    Match_char_lit(expr_ptr, expr_attributes_ptr)
  else
    Parse_string_expr(expr_ptr, expr_attributes_ptr);
end; {procedure Parse_string_lit}


procedure Parse_integer_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  expected_kind: type_kind_type;
begin
  if expr_attributes_ptr = nil then
    expected_kind := type_integer
  else
    begin
      expected_kind := expr_attributes_ptr^.type_attributes_ptr^.kind;
      if not (expected_kind in [type_byte, type_short, type_integer, type_long])
        then
        expected_kind := type_integer;
    end;

  case expected_kind of
    type_byte:
      Match_byte_lit(expr_ptr, expr_attributes_ptr);
    type_short:
      Match_short_lit(expr_ptr, expr_attributes_ptr);
    type_integer:
      Match_integer_lit(expr_ptr, expr_attributes_ptr);
    type_long:
      Match_long_lit(expr_ptr, expr_attributes_ptr);
  end; {case}
end; {procedure Parse_integer_lit}


procedure Parse_scalar_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  expected_kind: type_kind_type;
begin
  if expr_attributes_ptr = nil then
    expected_kind := type_scalar
  else
    begin
      expected_kind := expr_attributes_ptr^.type_attributes_ptr^.kind;
      if not (expected_kind in [type_scalar, type_double]) then
        expected_kind := type_scalar;
    end;

  case expected_kind of
    type_scalar:
      Match_scalar_lit(expr_ptr, expr_attributes_ptr);
    type_double:
      Match_double_lit(expr_ptr, expr_attributes_ptr);
  end; {case}
end; {procedure Parse_scalar_lit}


function New_nil_lit(kind: type_kind_type): expr_ptr_type;
var
  expr_ptr: expr_ptr_type;
begin
  case kind of

    type_enum:
      begin
        expr_ptr := New_expr(enum_lit);
        expr_ptr^.enum_val := 0;
      end;

    type_array:
      expr_ptr := New_expr(nil_array);

    type_struct, type_class:
      expr_ptr := New_expr(nil_struct);

    type_code:
      expr_ptr := New_expr(nil_proto);

    type_reference:
      expr_ptr := New_expr(nil_reference);

  else
    expr_ptr := nil;
  end; {case}

  New_nil_lit := expr_ptr;
end; {function New_nil_lit}


procedure Parse_nil_lit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  type_attributes_ptr: type_attributes_ptr_type;
begin
  Get_next_token;

  if expr_attributes_ptr <> nil then
    begin
      type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
      if type_attributes_ptr^.kind in [type_enum, type_array, type_struct,
        type_class, type_code, type_reference] then
        begin
          expr_attributes_ptr := typeless_value_attributes_ptr;
          expr_ptr := New_nil_lit(type_attributes_ptr^.kind);
        end
      else
        begin
          Parse_error;
          writeln('A variable of this type cannot be none.');
          error_reported := true;
        end;
    end
  else
    Parse_error;
end; {procedure Parse_nil_lit}


procedure Parse_some_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  operand_ptr: expr_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
begin
  Get_next_token;
  Parse_id_expr(operand_ptr, expr_attributes_ptr);
  Deref_expr(operand_ptr, expr_attributes_ptr);

  if parsing_ok then
    begin
      type_attributes_ptr := expr_attributes_ptr^.type_attributes_ptr;
      expr_attributes_ptr := boolean_value_attributes_ptr;

      if (not type_attributes_ptr^.static) or (type_attributes_ptr^.kind in
        [type_enum, type_code]) then
        case type_attributes_ptr^.kind of

          type_enum:
            begin
              expr_ptr := New_expr(integer_not_equal);
              expr_ptr^.left_operand_ptr := operand_ptr;
              expr_ptr^.right_operand_ptr := New_expr(enum_lit);
              expr_ptr^.right_operand_ptr^.enum_val := 0;
            end;

          type_array:
            begin
              expr_ptr := New_expr(array_ptr_not_equal);
              expr_ptr^.left_operand_ptr := operand_ptr;
              expr_ptr^.right_operand_ptr := New_expr(nil_array);
            end;

          type_struct, type_class:
            begin
              expr_ptr := New_expr(struct_ptr_not_equal);
              expr_ptr^.left_operand_ptr := operand_ptr;
              expr_ptr^.right_operand_ptr := New_expr(nil_struct);
            end;

          type_code:
            begin
              expr_ptr := New_expr(proto_not_equal);
              expr_ptr^.left_operand_ptr := operand_ptr;
              expr_ptr^.right_operand_ptr := New_expr(nil_proto);
            end;

        end {case}
      else
        begin
          Parse_error;
          writeln('A variable of this type is always some.');
          error_reported := true;
        end;
    end;
end; {procedure Parse_some_expr}


procedure Parse_struct_new_fn(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  type_ptr: type_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
begin
  Get_next_token;

  if parsing_ok then
    begin
      if next_token.kind = id_tok then
        begin
          next_token.kind := type_id_tok;
          Parse_data_type(type_attributes_ptr);
          type_ptr := Get_type_decl(type_attributes_ptr);
          Parse_explicit_struct_new(expr_ptr, expr_attributes_ptr, type_ptr);

          if parsing_ok then
            if expr_attributes_ptr = nil then
              begin
                expr_attributes_ptr :=
                  New_value_expr_attributes(type_attributes_ptr);
                Set_expr_attributes(expr_ptr, expr_attributes_ptr);
              end;
        end
      else
        begin
          Parse_error;
          writeln('Expected the name of a type here.');
          error_reported := true;
        end;
    end;
end; {procedure Parse_struct_new_fn}


{************************  productions  ************************}
{       <unit> ::= id                                           }
{       <unit> ::= not <unit>                                   }
{       <unit> ::= - <unit>                                     }
{                                                               }
{       <unit> ::= true                                         }
{       <unit> ::= false                                        }
{       <unit> ::= integer_lit                                  }
{       <unit> ::= scalar_lit                                   }
{       <unit> ::= array_expr                                   }
{       <unit> ::= nil                                          }
{                                                               }
{       <unit> ::= boolean_fn                                   }
{       <unit> ::= char_fn                                      }
{       <unit> ::= integer_fn                                   }
{       <unit> ::= scalar_fn                                    }
{       <unit> ::= new <type id>                                }
{***************************************************************}

procedure Parse_unit(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
var
  expected_kind: type_kind_type;
begin
  if parsing_ok then
    if next_token.kind in unit_predict_set then
      begin
        {**********************}
        { parse id expressions }
        {**********************}
        if next_token.kind in id_expr_predict_set then
          Parse_id_expr(expr_ptr, expr_attributes_ptr)

          {************************************}
          { parse unary operators or terminals }
          {************************************}
        else
          case next_token.kind of

            {*************************}
            { parse special functions }
            {*************************}
            min_tok, max_tok, num_tok:
              Parse_array_limit_fn(expr_ptr, expr_attributes_ptr);
            new_tok:
              Parse_struct_new_fn(expr_ptr, expr_attributes_ptr);

            {**************************}
            { unary negation operators }
            {**************************}
            not_tok:
              Parse_not(expr_ptr, expr_attributes_ptr);
            minus_tok:
              Parse_negation(expr_ptr, expr_attributes_ptr);

            {**********}
            { literals }
            {**********}
            true_tok, false_tok:
              Match_boolean_lit(expr_ptr, expr_attributes_ptr);

            {**************************}
            { char and string literals }
            {**************************}
            string_lit_tok:
              Parse_string_lit(expr_ptr, expr_attributes_ptr);

            {***********************}
            { mathematical literals }
            {***********************}
            integer_lit_tok:
              Parse_integer_lit(expr_ptr, expr_attributes_ptr);
            scalar_lit_tok:
              Parse_scalar_lit(expr_ptr, expr_attributes_ptr);

            {**************}
            { nil literals }
            {**************}
            none_tok:
              Parse_nil_lit(expr_ptr, expr_attributes_ptr);
            some_tok:
              Parse_some_expr(expr_ptr, expr_attributes_ptr);

            {******************}
            { array expressons }
            {******************}
            left_bracket_tok:
              Parse_array_expr(expr_ptr, expr_attributes_ptr);

            {***********************}
            { structure expressions }
            {***********************}
            less_than_tok:
              begin
                if expr_attributes_ptr <> nil then
                  expected_kind := expr_attributes_ptr^.type_attributes_ptr^.kind
                else
                  expected_kind := type_error;

                if expected_kind = type_struct then
                  Parse_struct_expr(expr_ptr, expr_attributes_ptr)
                else if not implicit_tuplets then
                  begin
                    Get_next_token;
                    expr_attributes_ptr := scalar_value_attributes_ptr;
                    Parse_unit(expr_ptr, expr_attributes_ptr);
                    Parse_vector_tail(expr_ptr, expr_attributes_ptr);
                    Match(greater_than_tok);
                  end;
              end;

            {*****************}
            { sub expressions }
            {*****************}
            left_paren_tok:
              begin
                Get_next_token;
                expr_attributes_ptr := nil;
                Parse_expr(expr_ptr, expr_attributes_ptr);
                Match(right_paren_tok);

                if parsing_ok then
                  begin
                    if expr_ptr^.expr_info_ptr = nil then
                      expr_ptr^.expr_info_ptr := New_expr_info;
                    expr_ptr^.expr_info_ptr^.explicit_expr := true;
                  end;
              end;
          end; {case}
      end

    else if not error_reported then
      begin
        {************************************}
        { take a shot at reporting the error }
        {************************************}
        if next_token.kind = quote_tok then
          begin
            Parse_error;
            writeln('Strings require double quotes: ".');
            error_reported := true;
          end
        else if next_token.kind = error_tok then
          begin
            Parse_error;
            writeln('This makes no sense.');
            error_reported := true;
          end
        else
          begin
            Parse_error;
            writeln('Expected an expression here.');
            error_reported := true;
          end;
      end;

  if not parsing_ok then
    expr_attributes_ptr := nil;
end; {procedure Parse_unit}


{************************  productions  ************************}
{       <bool_term_tail> ::= and <rel_expr> <bool_term_tail>    }
{***************************************************************}

procedure Parse_bool_term_tail(var expr_ptr: expr_ptr_type);
const
  predict_set = [and_tok];
var
  bool_term_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        Match(and_tok);

        {***********************************************}
        { parse expressions of the form: a > b and <> c }
        {***********************************************}
        if (next_token.kind in rel_predict_set) then
          begin
            Parse_rel_bool_term_tail(expr_ptr);
            expr_attributes_ptr := boolean_value_attributes_ptr;
          end
        else
          begin
            if next_token.kind = if_tok then
              begin
                Get_next_token;
                bool_term_ptr := New_expr(and_if_op);
              end
            else
              bool_term_ptr := New_expr(and_op);

            bool_term_ptr^.left_operand_ptr := expr_ptr;
            expr_attributes_ptr := boolean_value_attributes_ptr;
            Parse_rel_expr(bool_term_ptr^.right_operand_ptr,
              expr_attributes_ptr);
            expr_ptr := bool_term_ptr;
          end;

        if parsing_ok then
          if expr_attributes_ptr^.type_attributes_ptr <>
            boolean_type_attributes_ptr then
            begin
              Parse_error;
              writeln('Expected a boolean expression here.');
              error_reported := true;

              Destroy_exprs(expr_ptr, true);
              expr_attributes_ptr := nil;
            end;

        Parse_bool_term_tail(expr_ptr);
      end;
end; {procedure Parse_bool_term_tail}


{************************  productions  ************************}
{       <bool_term> ::= <rel_expr> <bool_term_tail>             }
{***************************************************************}

procedure Parse_bool_term(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if parsing_ok then
    begin
      Parse_rel_expr(expr_ptr, expr_attributes_ptr);

      if parsing_ok then
        if expr_attributes_ptr <> nil then
          if expr_attributes_ptr^.type_attributes_ptr =
            boolean_type_attributes_ptr then
            Parse_bool_term_tail(expr_ptr);
    end;
end; {procedure Parse_bool_term}


{************************  productions  ************************}
{       <boolean_expr_tail> ::= or <bool_term> <bool_expr_tail> }
{***************************************************************}

procedure Parse_bool_expr_tail(var expr_ptr: expr_ptr_type);
const
  predict_set = [or_tok];
var
  bool_expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type;
begin
  if parsing_ok then
    if next_token.kind in predict_set then
      begin
        Match(or_tok);

        {**********************************************}
        { parse expressions of the form: a > b or <> c }
        {**********************************************}
        if (next_token.kind in rel_predict_set) then
          begin
            Parse_rel_bool_expr_tail(expr_ptr);
            expr_attributes_ptr := boolean_value_attributes_ptr;
          end
        else
          begin
            if next_token.kind = if_tok then
              begin
                Get_next_token;
                bool_expr_ptr := New_expr(or_if_op);
              end
            else
              bool_expr_ptr := New_expr(or_op);

            bool_expr_ptr^.left_operand_ptr := expr_ptr;
            expr_attributes_ptr := boolean_value_attributes_ptr;
            Parse_bool_term(bool_expr_ptr^.right_operand_ptr,
              expr_attributes_ptr);
            expr_ptr := bool_expr_ptr;
          end;

        if parsing_ok then
          if expr_attributes_ptr^.type_attributes_ptr <>
            boolean_type_attributes_ptr then
            begin
              Parse_error;
              writeln('Expected a boolean expression here.');
              error_reported := true;

              Destroy_exprs(expr_ptr, true);
              expr_attributes_ptr := nil;
            end;

        Parse_bool_expr_tail(expr_ptr);
      end;
end; {procedure Parse_bool_expr_tail}


{************************  productions  ************************}
{       <expr> ::= <bool_term> <bool_expr_tail>                 }
{***************************************************************}

procedure Parse_expr(var expr_ptr: expr_ptr_type;
  var expr_attributes_ptr: expr_attributes_ptr_type);
begin
  if parsing_ok then
    begin
      Parse_bool_term(expr_ptr, expr_attributes_ptr);

      if parsing_ok then
        if expr_attributes_ptr <> nil then
          if expr_attributes_ptr^.type_attributes_ptr =
            boolean_type_attributes_ptr then
            Parse_bool_expr_tail(expr_ptr);
    end;
end; {procedure Parse_expr}


{******************************************************}
{ routines to parse an expression of a particular type }
{******************************************************}


procedure Write_type_error(expr_attributes_ptr1, expr_attributes_ptr2:
  expr_attributes_ptr_type);
var
  parameter_error, code_kind_error: boolean;
  code_attributes_ptr1, code_attributes_ptr2: code_attributes_ptr_type;
  type_attributes_ptr1, type_attributes_ptr2: type_attributes_ptr_type;
begin
  parameter_error := false;
  code_kind_error := false;

  if expr_attributes_ptr1^.type_attributes_ptr^.kind = type_code then
    if expr_attributes_ptr2^.type_attributes_ptr^.kind = type_code then
      begin
        code_attributes_ptr1 :=
          expr_attributes_ptr1^.type_attributes_ptr^.code_attributes_ptr;
        code_attributes_ptr2 :=
          expr_attributes_ptr2^.type_attributes_ptr^.code_attributes_ptr;
        if code_attributes_ptr1^.kind = code_attributes_ptr2^.kind then
          parameter_error := true
        else
          code_kind_error := true;
      end;

  if expr_attributes_ptr1^.dimensions <> expr_attributes_ptr2^.dimensions then
    begin
      {*******************************}
      { array dimensions do not match }
      {*******************************}
      type_attributes_ptr1 := expr_attributes_ptr1^.type_attributes_ptr;
      if type_attributes_ptr1^.kind = type_array then
        type_attributes_ptr1 := type_attributes_ptr1^.base_type_attributes_ptr;

      type_attributes_ptr2 := expr_attributes_ptr2^.type_attributes_ptr;
      if type_attributes_ptr2^.kind = type_array then
        type_attributes_ptr2 := type_attributes_ptr2^.base_type_attributes_ptr;

      write('Expected a ');
      write(expr_attributes_ptr1^.dimensions: 1, ' dimensional array of ');
      Write_type_attributes(type_attributes_ptr1);
      writeln;
      write('but found a ');
      write(expr_attributes_ptr2^.dimensions: 1, ' dimensional array of ');
      Write_type_attributes(type_attributes_ptr2);
      writeln('.');
    end

  else if parameter_error then
    begin
      {*************************}
      { parameters do not match }
      {*************************}
      write('Can not assign ');
      write(Quotate_str(Get_expr_attributes_name(expr_attributes_ptr2)));
      write(' to ');
      writeln(Quotate_str(Get_expr_attributes_name(expr_attributes_ptr1)));
      writeln('because their parameters do not match.');
    end

  else if code_kind_error then
    begin
      {*************************}
      { code kinds do not match }
      {*************************}
      write('Can not assign ');
      write(Quotate_str(Get_expr_attributes_name(expr_attributes_ptr2)));
      write(' to ');
      writeln(Quotate_str(Get_expr_attributes_name(expr_attributes_ptr1)));
      writeln('because they are of differing kinds.');
    end

  else
    begin
      {*************************}
      { base types do not match }
      {*************************}
      write('Expected an expression of ');
      Write_type_attributes(expr_attributes_ptr1^.type_attributes_ptr);
      writeln;

      write('but found an expression of ');
      Write_type_attributes(expr_attributes_ptr2^.type_attributes_ptr);
      writeln('.');
    end;
end; {procedure Write_type_error}


procedure Check_same_expr_types(expr_attributes_ptr1, expr_attributes_ptr2:
  expr_attributes_ptr_type);
begin
  if parsing_ok then
    begin
      {**********************************}
      { check for structural equivalence }
      {**********************************}
      if not Same_expr_attributes(expr_attributes_ptr1, expr_attributes_ptr2)
        then
        begin
          Parse_error;
          Write_type_error(expr_attributes_ptr1, expr_attributes_ptr2);
          error_reported := true;
        end;
    end;
end; {procedure Check_same_expr_types}


procedure Check_equal_expr_types(expr_attributes_ptr1, expr_attributes_ptr2:
  expr_attributes_ptr_type);
begin
  if parsing_ok then
    begin
      {*******************************}
      { check for logical equivalence }
      {*******************************}
      if not Equal_expr_attributes(expr_attributes_ptr1, expr_attributes_ptr2)
        then
        begin
          Parse_error;
          Write_type_error(expr_attributes_ptr1, expr_attributes_ptr2);
          error_reported := true;
        end;
    end;
end; {procedure Check_equal_expr_types}


procedure Check_reference_attributes(expr_attributes_ptr:
  expr_attributes_ptr_type);
var
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  if parsing_ok then
    case expr_attributes_ptr^.kind of

      variable_attributes_kind:
        begin
          decl_attributes_ptr := expr_attributes_ptr^.decl_attributes_ptr;

          {*********************************}
          { check for pointer compatibility }
          {*********************************}
          if decl_attributes_ptr^.final then
            begin
              Parse_error;
              writeln('Can not make a reference to a constant or final variable.');
              error_reported := true;
            end
          else if expr_attributes_ptr^.dimensions <> 0 then
            begin
              if expr_attributes_ptr^.dimensions <>
                expr_attributes_ptr^.type_attributes_ptr^.absolute_dimensions then
                begin
                  Parse_error;
                  writeln('Can not reference a sub portion of an array.');
                  error_reported := true;
                end;
            end;
        end;

      value_attributes_kind:
        begin
          if expr_attributes_ptr <> typeless_value_attributes_ptr then
            begin
              Parse_error;
              writeln('Can not make a reference to a literal or an expression.');
              error_reported := true;
            end;
        end;

    end; {case}
end; {procedure Check_reference_attributes}


{**********************************************************}
{ parse an expression logically equivalent to a given type }
{**********************************************************}


procedure Parse_equal_expr(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  new_expr_attributes_ptr: expr_attributes_ptr_type;
begin
  new_expr_attributes_ptr := expr_attributes_ptr;
  Parse_expr(expr_ptr, new_expr_attributes_ptr);

  if parsing_ok then
    begin
      {*************************************}
      { check types for logical equivalence }
      {*************************************}
      Deref_expr(expr_ptr, new_expr_attributes_ptr);
      Promote_expr(expr_ptr, new_expr_attributes_ptr, expr_attributes_ptr);
      Check_equal_expr_types(expr_attributes_ptr, new_expr_attributes_ptr);
    end; {if parsing_ok}
end; {procedure Parse_equal_expr}


procedure Parse_equal_unit(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  new_expr_attributes_ptr: expr_attributes_ptr_type;
begin
  new_expr_attributes_ptr := expr_attributes_ptr;
  Parse_unit(expr_ptr, new_expr_attributes_ptr);

  if parsing_ok then
    begin
      {*************************************}
      { check types for logical equivalence }
      {*************************************}
      Deref_expr(expr_ptr, new_expr_attributes_ptr);
      Promote_expr(expr_ptr, new_expr_attributes_ptr, expr_attributes_ptr);
      Check_equal_expr_types(expr_attributes_ptr, new_expr_attributes_ptr);
    end;
end; {procedure Parse_equal_unit}


{*************************************************************}
{ parse an expression structurally equivalent to a given type }
{*************************************************************}


procedure Parse_same_expr(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  new_expr_attributes_ptr: expr_attributes_ptr_type;
begin
  new_expr_attributes_ptr := expr_attributes_ptr;
  Parse_expr(expr_ptr, new_expr_attributes_ptr);

  if parsing_ok then
    begin
      {****************************************}
      { check types for structural equivalence }
      {****************************************}
      if new_expr_attributes_ptr^.type_attributes_ptr <> nil then
        begin
          if expr_attributes_ptr^.type_attributes_ptr^.kind = type_reference
            then
            begin
              Check_reference_attributes(new_expr_attributes_ptr);
              Reference_expr(expr_ptr, new_expr_attributes_ptr)
            end
          else
            Deref_expr(expr_ptr, new_expr_attributes_ptr);
        end;

      Check_same_expr_types(expr_attributes_ptr, new_expr_attributes_ptr);
    end;
end; {procedure Parse_same_expr}


procedure Parse_same_unit(var expr_ptr: expr_ptr_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
var
  new_expr_attributes_ptr: expr_attributes_ptr_type;
begin
  new_expr_attributes_ptr := expr_attributes_ptr;
  Parse_unit(expr_ptr, new_expr_attributes_ptr);

  if parsing_ok then
    begin
      {****************************************}
      { check types for structural equivalence }
      {****************************************}
      if new_expr_attributes_ptr^.type_attributes_ptr <> nil then
        begin
          if expr_attributes_ptr^.type_attributes_ptr^.kind = type_reference
            then
            begin
              Check_reference_attributes(new_expr_attributes_ptr);
              Reference_expr(expr_ptr, new_expr_attributes_ptr)
            end
          else
            Deref_expr(expr_ptr, new_expr_attributes_ptr);
        end;

      Check_same_expr_types(expr_attributes_ptr, new_expr_attributes_ptr);
    end;
end; {procedure Parse_same_unit}


end.
