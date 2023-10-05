program compiler_test;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm     Welcome to the Hypercosm!         3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       Yes, now you, the ignorant user, can also have all      }
{       the power and flexibility of the top secret research    }
{       tool used by the virtual reality professionals          }
{       galaxywide and the heavily guarded bastion of           }
{       Western technology and basic foundation of our          }
{       religion and fundamental world view:                    }
{                                                               }
{                        Project XJV52000,                      }
{                        Secret Code Name:                      }
{                   Turbo Squidmaster Pro 9000                  }
{                                                               }
{       Remember: if it doen't have shadows and reflections,    }
{       then it's not virtual reality.                          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


{$APPTYPE CONSOLE}


uses
  SysUtils,
  array_expr_parser in '..\Parser Code\array_parser_files\array_expr_parser.pas',
  array_parser in '..\Parser Code\array_parser_files\array_parser.pas',
  deref_parser in '..\Parser Code\array_parser_files\deref_parser.pas',
  dim_parser in '..\Parser Code\array_parser_files\dim_parser.pas',
  limit_parser in '..\Parser Code\array_parser_files\limit_parser.pas',
  subrange_parser in '..\Parser Code\array_parser_files\subrange_parser.pas',
  class_parser in '..\Parser Code\decl_parser_files\class_parser.pas',
  data_parser in '..\Parser Code\decl_parser_files\data_parser.pas',
  decl_parser in '..\Parser Code\decl_parser_files\decl_parser.pas',
  include_parser in '..\Parser Code\decl_parser_files\include_parser.pas',
  main_parser in '..\Parser Code\decl_parser_files\main_parser.pas',
  method_parser in '..\Parser Code\decl_parser_files\method_parser.pas',
  param_parser in '..\Parser Code\decl_parser_files\param_parser.pas',
  struct_parser in '..\Parser Code\decl_parser_files\struct_parser.pas',
  type_parser in '..\Parser Code\decl_parser_files\type_parser.pas',
  expr_parser in '..\Parser Code\expr_parser_files\expr_parser.pas',
  id_expr_parser in '..\Parser Code\expr_parser_files\id_expr_parser.pas',
  math_expr_parser in '..\Parser Code\expr_parser_files\math_expr_parser.pas',
  member_parser in '..\Parser Code\expr_parser_files\member_parser.pas',
  rel_expr_parser in '..\Parser Code\expr_parser_files\rel_expr_parser.pas',
  value_parser in '..\Parser Code\expr_parser_files\value_parser.pas',
  cast_literals in '..\Parser Code\parser_files\cast_literals.pas',
  casting in '..\Parser Code\parser_files\casting.pas',
  operators in '..\Parser Code\parser_files\operators.pas',
  optimizer in '..\Parser Code\parser_files\optimizer.pas',
  parser in '..\Parser Code\parser_files\parser.pas',
  scanner in '..\Parser Code\parser_files\scanner.pas',
  tokenizer in '..\Parser Code\parser_files\tokenizer.pas',
  tokens in '..\Parser Code\parser_files\tokens.pas',
  typechecker in '..\Parser Code\parser_files\typechecker.pas',
  assign_parser in '..\Parser Code\stmt_parser_files\assign_parser.pas',
  cons_parser in '..\Parser Code\stmt_parser_files\cons_parser.pas',
  instruct_parser in '..\Parser Code\stmt_parser_files\instruct_parser.pas',
  msg_parser in '..\Parser Code\stmt_parser_files\msg_parser.pas',
  stmt_parser in '..\Parser Code\stmt_parser_files\stmt_parser.pas',
  comment_parser in '..\Parser Code\term_parser_files\comment_parser.pas',
  field_parser in '..\Parser Code\term_parser_files\field_parser.pas',
  implicit_derefs in '..\Parser Code\term_parser_files\implicit_derefs.pas',
  match_literals in '..\Parser Code\term_parser_files\match_literals.pas',
  match_terms in '..\Parser Code\term_parser_files\match_terms.pas',
  scope_stacks in '..\Parser Code\term_parser_files\scope_stacks.pas',
  scoping in '..\Parser Code\term_parser_files\scoping.pas',
  term_parser in '..\Parser Code\term_parser_files\term_parser.pas',
  array_unparser in '..\Parser Code\unparser_files\array_unparser.pas',
  assign_unparser in '..\Parser Code\unparser_files\assign_unparser.pas',
  code_unparser in '..\Parser Code\unparser_files\code_unparser.pas',
  data_unparser in '..\Parser Code\unparser_files\data_unparser.pas',
  decl_unparser in '..\Parser Code\unparser_files\decl_unparser.pas',
  expr_unparser in '..\Parser Code\unparser_files\expr_unparser.pas',
  instruct_unparser in '..\Parser Code\unparser_files\instruct_unparser.pas',
  main_unparser in '..\Parser Code\unparser_files\main_unparser.pas',
  msg_unparser in '..\Parser Code\unparser_files\msg_unparser.pas',
  stmt_unparser in '..\Parser Code\unparser_files\stmt_unparser.pas',
  term_unparser in '..\Parser Code\unparser_files\term_unparser.pas',
  type_unparser in '..\Parser Code\unparser_files\type_unparser.pas',
  unparser in '..\Parser Code\unparser_files\unparser.pas',
  code_attributes in '..\Abstract Syntax Tree Code\attributes_files\code_attributes.pas',
  comments in '..\Abstract Syntax Tree Code\attributes_files\comments.pas',
  decl_attributes in '..\Abstract Syntax Tree Code\attributes_files\decl_attributes.pas',
  expr_attributes in '..\Abstract Syntax Tree Code\attributes_files\expr_attributes.pas',
  lit_attributes in '..\Abstract Syntax Tree Code\attributes_files\lit_attributes.pas',
  prim_attributes in '..\Abstract Syntax Tree Code\attributes_files\prim_attributes.pas',
  stmt_attributes in '..\Abstract Syntax Tree Code\attributes_files\stmt_attributes.pas',
  symbol_tables in '..\Abstract Syntax Tree Code\attributes_files\symbol_tables.pas',
  type_attributes in '..\Abstract Syntax Tree Code\attributes_files\type_attributes.pas',
  value_attributes in '..\Abstract Syntax Tree Code\attributes_files\value_attributes.pas',
  compare_codes in '..\Abstract Syntax Tree Code\compare_attr_files\compare_codes.pas',
  compare_decls in '..\Abstract Syntax Tree Code\compare_attr_files\compare_decls.pas',
  compare_exprs in '..\Abstract Syntax Tree Code\compare_attr_files\compare_exprs.pas',
  compare_types in '..\Abstract Syntax Tree Code\compare_attr_files\compare_types.pas',
  make_arrays in '..\Abstract Syntax Tree Code\make_AST_files\make_arrays.pas',
  make_code_decls in '..\Abstract Syntax Tree Code\make_AST_files\make_code_decls.pas',
  make_decls in '..\Abstract Syntax Tree Code\make_AST_files\make_decls.pas',
  make_exprs in '..\Abstract Syntax Tree Code\make_AST_files\make_exprs.pas',
  make_instructs in '..\Abstract Syntax Tree Code\make_AST_files\make_instructs.pas',
  make_stmts in '..\Abstract Syntax Tree Code\make_AST_files\make_stmts.pas',
  make_syntax_trees in '..\Abstract Syntax Tree Code\make_AST_files\make_syntax_trees.pas',
  make_type_decls in '..\Abstract Syntax Tree Code\make_AST_files\make_type_decls.pas',
  addressing in '..\Abstract Syntax Tree Code\process_AST_files\addressing.pas',
  array_assigns in '..\Abstract Syntax Tree Code\process_AST_files\array_assigns.pas',
  array_expr_assigns in '..\Abstract Syntax Tree Code\process_AST_files\array_expr_assigns.pas',
  expr_subtrees in '..\Abstract Syntax Tree Code\process_AST_files\expr_subtrees.pas',
  implicit_stmts in '..\Abstract Syntax Tree Code\process_AST_files\implicit_stmts.pas',
  struct_assigns in '..\Abstract Syntax Tree Code\process_AST_files\struct_assigns.pas',
  subranges in '..\Abstract Syntax Tree Code\process_AST_files\subranges.pas',
  type_assigns in '..\Abstract Syntax Tree Code\process_AST_files\type_assigns.pas',
  arrays in '..\Abstract Syntax Tree Code\syntax_tree_files\arrays.pas',
  code_decls in '..\Abstract Syntax Tree Code\syntax_tree_files\code_decls.pas',
  decls in '..\Abstract Syntax Tree Code\syntax_tree_files\decls.pas',
  exprs in '..\Abstract Syntax Tree Code\syntax_tree_files\exprs.pas',
  instructs in '..\Abstract Syntax Tree Code\syntax_tree_files\instructs.pas',
  stmts in '..\Abstract Syntax Tree Code\syntax_tree_files\stmts.pas',
  syntax_trees in '..\Abstract Syntax Tree Code\syntax_tree_files\syntax_trees.pas',
  type_decls in '..\Abstract Syntax Tree Code\syntax_tree_files\type_decls.pas',
  addr_types in '..\Abstract Syntax Tree Code\type_files\addr_types.pas',
  code_types in '..\Abstract Syntax Tree Code\type_files\code_types.pas',
  data_types in '..\Abstract Syntax Tree Code\type_files\data_types.pas',
  string_structs in '..\Common Code\basic_files\string_structs.pas',
  file_stack in '..\Common Code\basic_files\file_stack.pas',
  hashtables in '..\Common Code\basic_files\hashtables.pas',
  chars in '..\Common Code\basic_files\chars.pas',
  strings in '..\Common Code\basic_files\strings.pas',
  errors in '..\Nonportable Code\system_files\errors.pas',
  new_memory in '..\Nonportable Code\system_files\new_memory.pas',
  complex_numbers in '..\Common Code\math_files\complex_numbers.pas',
  constants in '..\Common Code\math_files\constants.pas',
  math_utils in '..\Common Code\math_files\math_utils.pas',
  trigonometry in '..\Common Code\math_files\trigonometry.pas',
  vectors in '..\Common Code\vector_files\vectors.pas',
  string_io in '..\Common Code\basic_files\string_io.pas',
  assembler in '..\Assembler Code\asm_files\assembler.pas',
  debugger in '..\Assembler Code\asm_files\debugger.pas',
  asm_bounds in '..\Assembler Code\asm_AST_files\asm_bounds.pas',
  asm_code_decls in '..\Assembler Code\asm_AST_files\asm_code_decls.pas',
  asm_decls in '..\Assembler Code\asm_AST_files\asm_decls.pas',
  asm_exprs in '..\Assembler Code\asm_AST_files\asm_exprs.pas',
  asm_indices in '..\Assembler Code\asm_AST_files\asm_indices.pas',
  asm_instructs in '..\Assembler Code\asm_AST_files\asm_instructs.pas',
  asm_stmts in '..\Assembler Code\asm_AST_files\asm_stmts.pas',
  asm_subranges in '..\Assembler Code\asm_AST_files\asm_subranges.pas',
  asm_type_decls in '..\Assembler Code\asm_AST_files\asm_type_decls.pas',
  asms in '..\Assembler Code\asm_AST_files\asms.pas',
  native_collision in '..\Native Glue Code\native_files\native_collision.pas',
  native_conversion in '..\Native Glue Code\native_files\native_conversion.pas',
  native_glue in '..\Native Glue Code\native_files\native_glue.pas',
  native_math in '..\Native Glue Code\native_files\native_math.pas',
  native_model in '..\Native Glue Code\native_files\native_model.pas',
  native_render in '..\Native Glue Code\native_files\native_render.pas',
  native_system in '..\Native Glue Code\native_files\native_system.pas',
  text_files in '..\Nonportable Code\system_files\text_files.pas',
  find_files in '..\Nonportable Code\system_files\find_files.pas',
  system_events in '..\Nonportable Code\system_files\system_events.pas';


const
  do_unparsing = false;
  do_debugging = true;
  do_implicit_args = true;
  do_optimizing = true;


var
  file_name, path: string_type;
  syntax_tree_ptr: syntax_tree_ptr_type;


procedure Compile(syntax_tree_ptr: syntax_tree_ptr_type);
var
  outfile_name: string_type;
  outfile: text;
begin
  {************************}
  { extract name from path }
  {************************}
  file_name := Get_file_name_from_path(file_name);
  file_name := Change_str_suffix(file_name, '.oma', '.omar');
  file_name := Change_str_suffix(file_name, '.OMA', '.omar');

  {*********************************}
  { disassemble syntax tree to file }
  {*********************************}
  outfile_name := Change_str_suffix(path + file_name, '.omar', '.hcvm.txt');
  rewrite(outfile, outfile_name);
  Disassemble(outfile, syntax_tree_ptr);
  close(outfile);

  {***********************************************}
  { disassemble auxilliary debugging info to file }
  {***********************************************}
  if do_debugging then
    begin
      outfile_name := Change_str_suffix(path + file_name, '.omar', '.hcdb.txt');
      rewrite(outfile, outfile_name);
      Disassemble_debug(outfile);
      close(outfile);
    end;
end; {procedure Compile}


procedure Parse;
const
  header_required = true;
  pedantic = true;
  test_args = false;
var
  optimize: boolean;
begin
  {************}
  { parse file }
  {************}
  optimize := do_optimizing and (not do_unparsing);

  {*****************************************************}
  { if unparsing only, then we don't need a main header }
  {*****************************************************}
  writeln('Parsing...');
  if do_unparsing then
    syntax_tree_ptr := Parse_fragment(pedantic, optimize, do_implicit_args)
  else
    syntax_tree_ptr := Parse_program(pedantic, optimize, do_implicit_args);

  {***************************************}
  { if parsed ok, then unparse or compile }
  {***************************************}
  if syntax_tree_ptr <> nil then
    begin
      writeln('Parsed ok.');

      if do_unparsing then
        begin
          {**************}
          { unparse file }
          {**************}
          writeln('Unparsing...');
          do_tabs := false;
          show_implicit := true;
          show_expr_addrs := false;
          show_decl_addrs := false;
          show_includes := true;
          if show_implicit then
            Make_implicit_free_stmts(syntax_tree_ptr);
          Unparse(output, syntax_tree_ptr);
        end
      else
        begin
          {**************}
          { compile file }
          {**************}
          write('Compiling...');
          Compile(syntax_tree_ptr);
          writeln('done.');
        end;
    end
  else
    writeln('Parse error!');
end; {procedure Parse}


procedure Compile_file(name: string_type);
begin
  file_name := name;
  writeln('compiling ', Quotate_str(file_name), '...');
  Open_next_file(file_name);
  Parse;
  Close_all_files;
end; {procedure Compile_file}


begin {main}
  path := Get_path_of_file(ParamStr(0));
  Add_path_to_search_path(path, search_path_ptr);

  if ParamCount <> 0 then
    Compile_file(ParamStr(1))
  else
    begin
      writeln('The compiler requires a file to operate on.');
      writeln('To run, drag and drop the desired file onto the compiler application.');
    end;

  readln;
end.








