program interpreter_test;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm       Welcome to Hypercosm!           3d       }
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
  exec_array_assigns in '..\Interpreter Code\interpreter_files\exec_array_assigns.pas',
  exec_assigns in '..\Interpreter Code\interpreter_files\exec_assigns.pas',
  exec_data_decls in '..\Interpreter Code\interpreter_files\exec_data_decls.pas',
  exec_decls in '..\Interpreter Code\interpreter_files\exec_decls.pas',
  exec_instructs in '..\Interpreter Code\interpreter_files\exec_instructs.pas',
  exec_methods in '..\Interpreter Code\interpreter_files\exec_methods.pas',
  exec_stmts in '..\Interpreter Code\interpreter_files\exec_stmts.pas',
  exec_structs in '..\Interpreter Code\interpreter_files\exec_structs.pas',
  interpreter in '..\Interpreter Code\interpreter_files\interpreter.pas',
  arrays in '..\Abstract Syntax Tree Code\syntax_tree_files\arrays.pas',
  code_decls in '..\Abstract Syntax Tree Code\syntax_tree_files\code_decls.pas',
  decls in '..\Abstract Syntax Tree Code\syntax_tree_files\decls.pas',
  exprs in '..\Abstract Syntax Tree Code\syntax_tree_files\exprs.pas',
  instructs in '..\Abstract Syntax Tree Code\syntax_tree_files\instructs.pas',
  stmts in '..\Abstract Syntax Tree Code\syntax_tree_files\stmts.pas',
  syntax_trees in '..\Abstract Syntax Tree Code\syntax_tree_files\syntax_trees.pas',
  type_decls in '..\Abstract Syntax Tree Code\syntax_tree_files\type_decls.pas',
  new_memory in '..\Nonportable Code\system_files\new_memory.pas',
  complex_numbers in '..\Common Code\math_files\complex_numbers.pas',
  constants in '..\Common Code\math_files\constants.pas',
  math_utils in '..\Common Code\math_files\math_utils.pas',
  trigonometry in '..\Common Code\math_files\trigonometry.pas',
  vectors in '..\Common Code\vector_files\vectors.pas',
  data_types in '..\Abstract Syntax Tree Code\type_files\data_types.pas',
  addr_types in '..\Abstract Syntax Tree Code\type_files\addr_types.pas',
  errors in '..\Nonportable Code\system_files\errors.pas',
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
  strings in '..\Common Code\basic_files\strings.pas',
  chars in '..\Common Code\basic_files\chars.pas',
  hashtables in '..\Common Code\basic_files\hashtables.pas',
  code_types in '..\Abstract Syntax Tree Code\type_files\code_types.pas',
  string_structs in '..\Common Code\basic_files\string_structs.pas',
  string_io in '..\Common Code\basic_files\string_io.pas',
  array_limits in '..\Runtime Code\heap_files\array_limits.pas',
  get_data in '..\Runtime Code\heap_files\get_data.pas',
  get_heap_data in '..\Runtime Code\heap_files\get_heap_data.pas',
  handles in '..\Runtime Code\heap_files\handles.pas',
  heaps in '..\Runtime Code\heap_files\heaps.pas',
  memrefs in '..\Runtime Code\heap_files\memrefs.pas',
  query_data in '..\Runtime Code\heap_files\query_data.pas',
  set_data in '..\Runtime Code\heap_files\set_data.pas',
  set_heap_data in '..\Runtime Code\heap_files\set_heap_data.pas',
  load_operands in '..\Runtime Code\operand_stack_files\load_operands.pas',
  op_stacks in '..\Runtime Code\operand_stack_files\op_stacks.pas',
  store_operands in '..\Runtime Code\operand_stack_files\store_operands.pas',
  data in '..\Runtime Code\stack_files\data.pas',
  get_params in '..\Runtime Code\stack_files\get_params.pas',
  get_stack_data in '..\Runtime Code\stack_files\get_stack_data.pas',
  params in '..\Runtime Code\stack_files\params.pas',
  set_stack_data in '..\Runtime Code\stack_files\set_stack_data.pas',
  stacks in '..\Runtime Code\stack_files\stacks.pas',
  colors in '..\Common Code\display_files\colors.pas',
  make_arrays in '..\Abstract Syntax Tree Code\make_AST_files\make_arrays.pas',
  make_code_decls in '..\Abstract Syntax Tree Code\make_AST_files\make_code_decls.pas',
  make_decls in '..\Abstract Syntax Tree Code\make_AST_files\make_decls.pas',
  make_exprs in '..\Abstract Syntax Tree Code\make_AST_files\make_exprs.pas',
  make_instructs in '..\Abstract Syntax Tree Code\make_AST_files\make_instructs.pas',
  make_stmts in '..\Abstract Syntax Tree Code\make_AST_files\make_stmts.pas',
  make_syntax_trees in '..\Abstract Syntax Tree Code\make_AST_files\make_syntax_trees.pas',
  make_type_decls in '..\Abstract Syntax Tree Code\make_AST_files\make_type_decls.pas',
  deref_arrays in '..\Interpreter Code\eval_array_files\deref_arrays.pas',
  eval_expr_arrays in '..\Interpreter Code\eval_array_files\eval_expr_arrays.pas',
  eval_limits in '..\Interpreter Code\eval_array_files\eval_limits.pas',
  eval_new_arrays in '..\Interpreter Code\eval_array_files\eval_new_arrays.pas',
  eval_row_arrays in '..\Interpreter Code\eval_array_files\eval_row_arrays.pas',
  eval_subranges in '..\Interpreter Code\eval_array_files\eval_subranges.pas',
  set_elements in '..\Interpreter Code\eval_array_files\set_elements.pas',
  eval_addrs in '..\Interpreter Code\eval_expr_files\eval_addrs.pas',
  eval_arrays in '..\Interpreter Code\eval_expr_files\eval_arrays.pas',
  eval_booleans in '..\Interpreter Code\eval_expr_files\eval_booleans.pas',
  eval_chars in '..\Interpreter Code\eval_expr_files\eval_chars.pas',
  eval_integers in '..\Interpreter Code\eval_expr_files\eval_integers.pas',
  eval_references in '..\Interpreter Code\eval_expr_files\eval_references.pas',
  eval_scalars in '..\Interpreter Code\eval_expr_files\eval_scalars.pas',
  eval_structs in '..\Interpreter Code\eval_expr_files\eval_structs.pas',
  addressing in '..\Abstract Syntax Tree Code\process_AST_files\addressing.pas',
  array_assigns in '..\Abstract Syntax Tree Code\process_AST_files\array_assigns.pas',
  array_expr_assigns in '..\Abstract Syntax Tree Code\process_AST_files\array_expr_assigns.pas',
  expr_subtrees in '..\Abstract Syntax Tree Code\process_AST_files\expr_subtrees.pas',
  implicit_stmts in '..\Abstract Syntax Tree Code\process_AST_files\implicit_stmts.pas',
  struct_assigns in '..\Abstract Syntax Tree Code\process_AST_files\struct_assigns.pas',
  subranges in '..\Abstract Syntax Tree Code\process_AST_files\subranges.pas',
  type_assigns in '..\Abstract Syntax Tree Code\process_AST_files\type_assigns.pas',
  compare_codes in '..\Abstract Syntax Tree Code\compare_attr_files\compare_codes.pas',
  compare_decls in '..\Abstract Syntax Tree Code\compare_attr_files\compare_decls.pas',
  compare_exprs in '..\Abstract Syntax Tree Code\compare_attr_files\compare_exprs.pas',
  compare_types in '..\Abstract Syntax Tree Code\compare_attr_files\compare_types.pas',
  native_glue in '..\Native Glue Code\native_dummy_files\native_glue.pas',
  exec_native in '..\Native Glue Code\exec_native_dummy_files\exec_native.pas',
  exec_graphics in '..\Native Glue Code\exec_graphics_dummy_files\exec_graphics.pas',
  exec_objects in '..\Native Glue Code\exec_graphics_dummy_files\exec_objects.pas',
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
  file_stack in '..\Common Code\basic_files\file_stack.pas',
  text_files in '..\Nonportable Code\system_files\text_files.pas';


var
  file_name: string_type;


procedure Run;
var
  syntax_tree_ptr: syntax_tree_ptr_type;
  argument_list_ptr: string_list_ptr_type;
begin
  {****************************}
  { set command line arguments }
  {****************************}
  argument_list_ptr := nil;
  Add_string_to_list(Str_to_string('argument3'), argument_list_ptr);
  Add_string_to_list(Str_to_string('argument2'), argument_list_ptr);
  Add_string_to_list(Str_to_string('argument1'), argument_list_ptr);

  {********************************}
  { assemble syntax tree from file }
  {********************************}
  writeln('Assembling ', file_name, '.');
  syntax_tree_ptr := Assemble;

  {********************************************************}
  { assemble auxilliary debugging information if available }
  {********************************************************}
  {file_name := Change_str_suffix(file_name, '.sgvm', '.sgdb');}
  {if Open_file(file_name) then}
  {begin}
  {Assemble_debug;}
  {Close_file;}
  {end;}

  {*****************}
  { interpret files }
  {*****************}
  writeln('Running...');
  Interpret(syntax_tree_ptr, argument_list_ptr, 8192);
end; {procedure Run}


begin {main}
  file_name := 'interface_bug2.hcvm.txt';
  Open_next_file(file_name);
  Run;
  Close_all_files;
  readln;
end.

 