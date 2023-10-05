unit assembler;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             assembler                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The assembler module defines all of the syntax trees    }
{       used in the mnemonic assembly code, the external        }
{       representation of the code which is used by the         }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  syntax_trees;


{*******************************************************}
{ routines to assemble syntax trees from assembly codes }
{*******************************************************}
function Assemble: syntax_tree_ptr_type;

{**********************************************************}
{ routines to disassemble syntax trees into assembly codes }
{**********************************************************}
procedure Disassemble(var outfile: text;
  syntax_tree_ptr: syntax_tree_ptr_type);


implementation
uses
  errors, strings, file_stack, hashtables, arrays, exprs, instructs, stmts,
  decls, code_decls, type_decls, asms, asm_bounds, asm_indices, asm_subranges,
  asm_exprs, asm_instructs, asm_stmts, asm_decls, asm_code_decls,
  asm_type_decls;


const
  verbose = false;


var
  version_string: string_type;


  {**********************}
  { forward declarations }
  {**********************}
procedure Disassemble_syntax_trees(var outfile: text;
  syntax_tree_ptr: syntax_tree_ptr_type);
  forward;


{*******************************************************}
{ routines to assemble syntax trees from assembly codes }
{*******************************************************}


function Assemble: syntax_tree_ptr_type;
var
  syntax_tree_ptr: syntax_tree_ptr_type;
  decl_count, code_count, type_count: asm_index_type;
  stmt_count, instruct_count: asm_index_type;
  expr_count: asm_index_type;
  array_bounds_count, array_bounds_list_count: asm_index_type;
  array_index_count, array_index_list_count: asm_index_type;
  array_subrange_count: asm_index_type;
  file_version_string: string_type;
begin
  {*************************}
  { read header information }
  {*************************}
  Match_string('Hypercosm');
  file_version_string := Assemble_string;
  Match_whitespace;

  {**********************}
  { check version number }
  {**********************}
  if file_version_string <> version_string then
    begin
      writeln('This Hypercosm file is version ', file_version_string);
      writeln('but this Hypercosm interpreter is version ', version_string,
        '.');
      Stop;
    end;

  {*************************************}
  { assemble node counts of syntax tree }
  {*************************************}
  Match_pseudo_mnemonic('bgn');
  decl_count := Assemble_long;
  code_count := Assemble_long;
  type_count := Assemble_long;
  stmt_count := Assemble_long;
  instruct_count := Assemble_long;
  expr_count := Assemble_long;

  {*************************************}
  { assemble counts of auxilliary nodes }
  {*************************************}
  array_bounds_count := Assemble_long;
  array_bounds_list_count := Assemble_long;
  array_index_count := Assemble_long;
  array_index_list_count := Assemble_long;
  array_subrange_count := Assemble_long;

  if verbose then
    begin
      {***********************************}
      { write number of syntax tree nodes }
      {***********************************}
      writeln('# of decls = ', decl_count: 1);
      writeln('# of code decls = ', code_count: 1);
      writeln('# of type decls = ', type_count: 1);
      writeln('# of stmts = ', stmt_count: 1);
      writeln('# of instructs = ', instruct_count: 1);
      writeln('# of exprs = ', expr_count: 1);

      {**************************************}
      { write number of auxilliary AST nodes }
      {**************************************}
      writeln('# of array bounds = ', array_bounds_count: 1);
      writeln('# of array bounds lists = ', array_bounds_list_count: 1);
      writeln('# of array indices = ', array_index_count: 1);
      writeln('# of array index lists = ', array_index_list_count: 1);
      writeln('# of array subranges = ', array_subrange_count: 1);
    end;

  {****************************}
  { allocate syntax tree nodes }
  {****************************}
  Make_new_asm_decls(decl_count);
  Make_new_asm_codes(code_count);
  Make_new_asm_types(type_count);
  Make_new_asm_stmts(stmt_count);
  Make_new_asm_instructs(instruct_count);
  Make_new_asm_exprs(expr_count);

  {*******************************}
  { allocate auxilliary AST nodes }
  {*******************************}
  Make_new_asm_array_bounds(array_bounds_count);
  Make_new_asm_array_bounds_lists(array_bounds_list_count);
  Make_new_asm_array_indices(array_index_count);
  Make_new_asm_array_index_lists(array_index_list_count);
  Make_new_asm_array_subranges(array_subrange_count);

  {**********************}
  { assemble syntax tree }
  {**********************}
  syntax_tree_ptr := New_syntax_tree(root_tree);
  with syntax_tree_ptr^ do
    begin
      root_frame_size := Assemble_integer;
      implicit_decls_ptr := Assemble_decls;
      decls_ptr := Assemble_decls;
      stmts_ptr := Assemble_stmts;
    end;

  Match_mnemonic('end');
  Assemble := syntax_tree_ptr;
end; {function Assemble}


{**********************************************************}
{ routines to disassemble declarations into assembly codes }
{**********************************************************}


procedure Disassemble_syntax_tree(var outfile: text;
  syntax_tree_ptr: syntax_tree_ptr_type);
begin
  if syntax_tree_ptr <> nil then
    begin
      {**********************************}
      { disassemble syntax tree operands }
      {**********************************}
      with syntax_tree_ptr^ do
        case kind of

          {****************************}
          { root of entire syntax tree }
          {****************************}
          root_tree:
            begin
              Disassemble_integer(outfile, root_frame_size);
              Disassemble_decls(outfile, implicit_decls_ptr);
              Disassemble_syntax_trees(outfile, implicit_includes_ptr);
              Disassemble_syntax_trees(outfile, root_includes_ptr);
              Disassemble_decls(outfile, decls_ptr);
              Disassemble_stmts(outfile, stmts_ptr);
            end;

          {*******************************}
          { declarations from other files }
          {*******************************}
          include_tree:
            begin
              Disassemble_syntax_trees(outfile, includes_ptr);
              Disassemble_decl_list(outfile, include_decls_ptr);
            end;

        end; {case}
    end;
end; {procedure Disassemble_syntax_tree}


procedure Disassemble_syntax_trees(var outfile: text;
  syntax_tree_ptr: syntax_tree_ptr_type);
begin
  while (syntax_tree_ptr <> nil) do
    begin
      Disassemble_syntax_tree(outfile, syntax_tree_ptr);
      syntax_tree_ptr := syntax_tree_ptr^.next;
    end;
end; {procedure Disassemble_syntax_trees}


procedure Disassemble(var outfile: text;
  syntax_tree_ptr: syntax_tree_ptr_type);
begin
  if verbose then
    begin
      {***********************************}
      { write number of syntax tree nodes }
      {***********************************}
      writeln('# of decls = ', Decl_count: 1);
      writeln('# of code decls = ', Code_count: 1);
      writeln('# of type decls = ', Type_count: 1);
      writeln('# of stmts = ', Stmt_count: 1);
      writeln('# of instructs = ', Instruct_count: 1);
      writeln('# of exprs = ', Expr_count: 1);

      {**************************************}
      { write number of auxilliary AST nodes }
      {**************************************}
      writeln('# of array bounds = ', Array_bounds_count: 1);
      writeln('# of array bounds lists = ', Array_bounds_list_count: 1);
      writeln('# of array indices = ', Array_index_count: 1);
      writeln('# of array index lists = ', Array_index_list_count: 1);
      writeln('# of array subranges = ', Array_subrange_count: 1);
    end;

  {********************************}
  { disassemble header information }
  {********************************}
  Disassemble_string(outfile, 'Hypercosm');
  Disassemble_string(outfile, version_string);
  writeln(outfile);

  {****************************************}
  { disassemble node counts of syntax tree }
  {****************************************}
  Disassemble_pseudo_mnemonic(outfile, 'bgn');
  Disassemble_long(outfile, Decl_count);
  Disassemble_long(outfile, Code_count);
  Disassemble_long(outfile, Type_count);
  Disassemble_long(outfile, Stmt_count);
  Disassemble_long(outfile, Instruct_count);
  Disassemble_long(outfile, Expr_count);

  {************************************}
  { disassemble auxilliary node counts }
  {************************************}
  Disassemble_long(outfile, Array_bounds_count);
  Disassemble_long(outfile, Array_bounds_list_count);
  Disassemble_long(outfile, Array_index_count);
  Disassemble_long(outfile, Array_index_list_count);
  Disassemble_long(outfile, Array_subrange_count);

  {*************************}
  { disassemble syntax tree }
  {*************************}
  Disassemble_syntax_tree(outfile, syntax_tree_ptr);
  Disassemble_mnemonic(outfile, 'end');
end; {procedure Disassemble}


initialization
  version_string := '0.99';
end.

