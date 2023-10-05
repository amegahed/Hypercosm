unit parser;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               parser                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The parser module contains misc routines to aid         }
{       the parsing process.                                    }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  tokens;


type
  predict_set_type = set of token_kind_type;


var
  {******************************}
  { data and method predict sets }
  {******************************}
  primitive_predict_set, subprogram_predict_set, procedural_predict_set,
    functional_predict_set, data_predict_set: predict_set_type;

  {*************************}
  { expression predict sets }
  {*************************}
  scoping_predict_set, id_predict_set, antecedent_predict_set,
    id_expr_predict_set: predict_set_type;

  {**********************}
  { literal predict sets }
  {**********************}
  boolean_lit_predict_set, integer_lit_predict_set, scalar_lit_predict_set,
    reference_lit_predict_set, literal_predict_set: predict_set_type;

  {*************************}
  { relational predict sets }
  {*************************}
  num_rel_predict_set, sym_rel_predict_set, ref_rel_predict_set,
    rel_predict_set: predict_set_type;

  {************************************************}
  { array and structure dereferencing predict sets }
  {************************************************}
  deref_predict_set: predict_set_type;

  {***********************}
  { function predict sets }
  {***********************}
  array_fn_predict_set: predict_set_type;

  {******************************}
  { expression type predict sets }
  {******************************}
  integer_predict_set, scalar_predict_set, unit_predict_set: predict_set_type;

  {************************}
  { statement predict sets }
  {************************}
  initializer_predict_set, conditional_stmt_predict_set, loop_stmt_predict_set,
    scoping_stmt_predict_set, memory_stmt_predict_set, last_stmt_predict_set,
    io_stmt_predict_set: predict_set_type;

  {******************************}
  { statement group predict sets }
  {******************************}
  smpl_stmt_predict_set, stmt_predict_set, stmt_terminator_set:
    predict_set_type;

  {****************************}
  { data modifier predict sets }
  {****************************}
  storage_class_predict_set, access_level_predict_set,
    method_access_level_predict_set, member_access_level_predict_set,
    data_modifier_predict_set: predict_set_type;

  {******************************}
  { method modifier predict sets }
  {******************************}
  subprogram_modifier_predict_set, method_modifier_predict_set,
    forward_method_modifier_predict_set: predict_set_type;

  {*******************************}
  { data declaration predict sets }
  {*******************************}
  field_predict_set, data_decl_predict_set: predict_set_type;

  {**************************}
  { declaration predict sets }
  {**************************}
  simple_type_decl_predict_set, class_decl_predict_set, type_decl_predict_set,
    forward_method_predict_set, subprogram_decl_predict_set,
    method_decl_predict_set, decl_predict_set: predict_set_type;

  {**********************}
  { parsing status flags }
  {**********************}
  parsing_ok, error_reported, decl_problems: boolean;
  static_mode, global_mode, return_param_mode: boolean;

  {********************}
  { parsing mode flags }
  {********************}
  parsing_native_decls: boolean;
  parsing_param_decls, parsing_optional_param_decls: boolean;
  parsing_method_decls, parsing_member_decls: boolean;
  parsing_return_decls: boolean;
  parsing_param_values: boolean;

  {******************}
  { parsing counters }
  {******************}
  native_decl_count: integer;
  include_file_count: integer;
  current_file_index: integer;


procedure Parse_error;
procedure Parse_warning;


implementation
uses
  file_stack, scanner;


procedure Init_predict_sets;
begin
  {******************************}
  { data and method predict sets }
  {******************************}
  primitive_predict_set := [boolean_tok..string_tok];
  subprogram_predict_set := [procedure_tok..anim_tok];
  procedural_predict_set := [procedure_tok, object_tok, picture_tok, anim_tok];
  functional_predict_set := [function_tok, shader_tok];
  data_predict_set := [type_id_tok] + primitive_predict_set;

  {*************************}
  { expression predict sets }
  {*************************}
  scoping_predict_set := [static_id_tok, global_tok];
  id_predict_set := [id_tok, static_id_tok, type_id_tok] + scoping_predict_set;
  antecedent_predict_set := [itself_tok, its_tok];
  id_expr_predict_set := id_predict_set + antecedent_predict_set;

  {**********************}
  { literal predict sets }
  {**********************}
  boolean_lit_predict_set := [true_tok, false_tok];
  integer_lit_predict_set := [left_paren_tok, integer_lit_tok, minus_tok];
  scalar_lit_predict_set := [left_paren_tok, integer_lit_tok, scalar_lit_tok,
    minus_tok];
  reference_lit_predict_set := [none_tok];
  literal_predict_set := boolean_lit_predict_set + reference_lit_predict_set +
    [string_lit_tok, integer_lit_tok, scalar_lit_tok];

  {*************************}
  { relational predict sets }
  {*************************}
  num_rel_predict_set := [greater_than_tok, less_than_tok, equal_tok,
    not_equal_tok, greater_equal_tok, less_equal_tok];
  sym_rel_predict_set := [is_tok, isnt_tok, does_tok, doesnt_tok];
  ref_rel_predict_set := [refers_tok];
  rel_predict_set := num_rel_predict_set + sym_rel_predict_set +
    ref_rel_predict_set;

  {************************************************}
  { array and structure dereferencing predict sets }
  {************************************************}
  deref_predict_set := [s_tok, left_bracket_tok, period_tok];

  {***********************}
  { function predict sets }
  {***********************}
  array_fn_predict_set := [min_tok, max_tok, num_tok];

  {******************************}
  { expression type predict sets }
  {******************************}
  integer_predict_set := id_expr_predict_set + integer_lit_predict_set +
    array_fn_predict_set;
  scalar_predict_set := integer_predict_set + scalar_lit_predict_set;
  unit_predict_set := id_expr_predict_set + literal_predict_set +
    array_fn_predict_set + [not_tok, minus_tok, left_paren_tok, left_bracket_tok,
    less_than_tok, some_tok, new_tok];

  {************************}
  { statement predict sets }
  {************************}
  initializer_predict_set := [equal_tok, is_tok, does_tok, refers_tok];
  conditional_stmt_predict_set := [if_tok, when_tok];
  loop_stmt_predict_set := [while_tok, for_tok, loop_tok];
  scoping_stmt_predict_set := [with_tok];
  memory_stmt_predict_set := [dim_tok, redim_tok, new_tok, renew_tok];
  last_stmt_predict_set := [break_tok, continue_tok, return_tok, answer_tok,
    exit_tok];
  io_stmt_predict_set := [read_tok, write_tok];

  {******************************}
  { statement group predict sets }
  {******************************}
  smpl_stmt_predict_set := conditional_stmt_predict_set + loop_stmt_predict_set
    + scoping_stmt_predict_set + memory_stmt_predict_set;
  stmt_predict_set := id_expr_predict_set + smpl_stmt_predict_set +
    io_stmt_predict_set + [left_paren_tok];
  stmt_terminator_set := [semi_colon_tok, right_paren_tok];

  {****************************}
  { data modifier predict sets }
  {****************************}
  storage_class_predict_set := [const_tok, static_tok, final_tok];
  access_level_predict_set := [public_tok, private_tok, protected_tok];
  method_access_level_predict_set := [public_tok, protected_tok];
  member_access_level_predict_set := [private_tok, public_tok];
  data_modifier_predict_set := storage_class_predict_set +
    access_level_predict_set;

  {******************************}
  { method modifier predict sets }
  {******************************}
  subprogram_modifier_predict_set := [forward_tok, native_tok, static_tok];
  method_modifier_predict_set := [void_tok, reference_tok] +
    subprogram_modifier_predict_set;
  forward_method_modifier_predict_set := method_modifier_predict_set -
    [forward_tok] + method_access_level_predict_set + [abstract_tok, final_tok];

  {*******************************}
  { data declaration predict sets }
  {*******************************}
  field_predict_set := data_predict_set + subprogram_predict_set;
  data_decl_predict_set := data_predict_set + data_modifier_predict_set;

  {**************************}
  { declaration predict sets }
  {**************************}
  simple_type_decl_predict_set := [enum_tok, type_tok, struct_tok, static_tok];
  class_decl_predict_set := [class_tok, abstract_tok, final_tok, static_tok,
    interface_tok];
  type_decl_predict_set := simple_type_decl_predict_set +
    class_decl_predict_set;
  forward_method_predict_set := subprogram_predict_set +
    forward_method_modifier_predict_set;
  subprogram_decl_predict_set := subprogram_predict_set +
    subprogram_modifier_predict_set;
  method_decl_predict_set := subprogram_decl_predict_set +
    method_modifier_predict_set;
  decl_predict_set := data_decl_predict_set + type_decl_predict_set +
    method_decl_predict_set;
end; {procedure Init_predict_sets}


procedure Parse_error;
begin
  write('Error in line #', Get_line_number: 1);
  write(', char #', Get_char_number: 1);
  writeln(' of "', Get_file_name, '":');

  Write_error_line;
  parsing_ok := false;
end; {procedure Parse_error}


procedure Parse_warning;
begin
  write('Warning in line #', Get_line_number: 1);
  write(', char #', Get_char_number: 1);
  writeln(' of "', Get_file_name, '":');
end; {procedure Parse_warning}


initialization
  Init_predict_sets;

  {*********************************}
  { initialize parsing status flags }
  {*********************************}
  parsing_ok := true;
  error_reported := false;
  decl_problems := false;
  static_mode := false;
  global_mode := false;
  return_param_mode := false;

  {*******************************}
  { initialize parsing mode flags }
  {*******************************}
  parsing_native_decls := false;
  parsing_param_decls := false;
  parsing_optional_param_decls := false;
  parsing_return_decls := false;
  parsing_method_decls := false;
  parsing_member_decls := false;
  parsing_param_values := false;

  {******************************}
  { initializer parsing counters }
  {******************************}
  native_decl_count := 0;
  include_file_count := 1;
  current_file_index := 1;
end.
