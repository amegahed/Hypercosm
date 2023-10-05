unit debugger;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             debugger                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The debugger module defines all of the auxilliary       }
{       symbolic information used in the mnemonic assembly      }
{       code, the external representation of the code which     }
{       is used by the interpreter.                             }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface


{*********************************************************}
{ routines to assemble debugging info from assembly codes }
{*********************************************************}
procedure Assemble_debug;

{************************************************************}
{ routines to disassemble debugging info into assembly codes }
{************************************************************}
procedure Disassemble_debug(var outfile: text);


implementation
uses
  errors, strings, hashtables, symbol_tables, decl_attributes, exprs, stmts,
  decls, code_decls, type_decls, syntax_trees, asms, asm_stmts, asm_decls;


const
  {*****************************************************}
  { Every decl has an associated decl info because the  }
  { attributes are needed for addressing, so the decl   }
  { indices may be implicit.  Every stmt, however, does }
  { not have a stmt info associated with it, so the     }
  { explicit stmt indices are necessary to associate    }
  { each stmt info with its proper stmt.                }
  {*****************************************************}
  implicit_decl_indices = false;
  implicit_stmt_indices = false;


  {*********************************************************}
  { routines to assemble debugging info from assembly codes }
  {*********************************************************}


procedure Assemble_debug;
var
  includes, counter: integer;
  decl_count, stmt_count: integer;
  decl_ptr: decl_ptr_type;
  stmt_ptr: stmt_ptr_type;
  decl_info_ptr: decl_info_ptr_type;
  stmt_info_ptr: stmt_info_ptr_type;
  name: string_type;
begin
  {******************************************}
  { assemble debugging information for files }
  {******************************************}
  includes := Assemble_integer;
  for counter := 1 to includes do
    begin
      Match_whitespace;
      Add_include(Assemble_name);
    end;

  {*************************************************}
  { assemble debugging information for declarations }
  {*************************************************}
  Match_whitespace;
  decl_count := Assemble_long;
  for counter := 1 to decl_count do
    begin
      Match_whitespace;

      {*********************}
      { assemble decl index }
      {*********************}
      if implicit_decl_indices then
        decl_ptr := Ref_asm_decl(counter)
      else
        decl_ptr := Ref_asm_decl(Assemble_index);

      {********************}
      { assemble decl info }
      {********************}
      decl_info_ptr := New_decl_info;
      decl_info_ptr^.line_number := Assemble_integer;
      decl_info_ptr^.file_number := Assemble_integer;
      name := Assemble_name;
      if name <> '' then
        with decl_info_ptr^ do
          begin
            decl_attributes_ptr := New_decl_attributes(data_decl_attributes,
              nil, nil);
            decl_attributes_ptr^.id_ptr := New_hashtable_entry(name,
              id_value_type(decl_attributes_ptr));
          end;
      Set_decl_info(decl_ptr, decl_info_ptr);
    end;

  {***********************************************}
  { assemble debugging information for statements }
  {***********************************************}
  Match_whitespace;
  stmt_count := Assemble_long;
  for counter := 1 to stmt_count do
    begin
      Match_whitespace;

      {*********************}
      { assemble stmt index }
      {*********************}
      if implicit_stmt_indices then
        stmt_ptr := Ref_asm_stmt(counter)
      else
        stmt_ptr := Ref_asm_stmt(Assemble_index);

      {********************}
      { assemble stmt info }
      {********************}
      stmt_info_ptr := New_stmt_info;
      stmt_info_ptr^.line_number := Assemble_integer;
      Set_stmt_info(stmt_ptr, stmt_info_ptr);
    end;
end; {procedure Assemble_debug}


{************************************************************}
{ routines to disassemble debugging info into assembly codes }
{************************************************************}


procedure Disassemble_debug(var outfile: text);
var
  counter: integer;
  decl_info_ptr: decl_info_ptr_type;
  stmt_info_ptr: stmt_info_ptr_type;
  decl_ptr: decl_ptr_type;
  stmt_ptr: stmt_ptr_type;
  // decl_index, stmt_index: asm_index_type;
begin
  {*********************************************}
  { disassemble debugging information for files }
  {*********************************************}
  Disassemble_integer(outfile, Get_includes);
  Disassemble_newline(outfile);
  for counter := 1 to Get_includes do
    begin
      Disassemble_name(outfile, Get_include(counter));
      Disassemble_newline(outfile);
    end;

  {****************************************************}
  { disassemble debugging information for declarations }
  {****************************************************}
  Disassemble_long(outfile, Decl_info_count);
  Disassemble_newline(outfile);
  decl_info_ptr := active_decl_info_list;
  // decl_index := 1;
  while decl_info_ptr <> nil do
    begin
      {************************}
      { disassemble decl index }
      {************************}
      decl_ptr := decl_ptr_type(decl_info_ptr^.decl_ref);

      {
      if implicit_decl_indices then
        begin
          if decl_ptr^.decl_index <> decl_index then
            Error('Found declaration out of order.');
        end
      else
        Disassemble_index(outfile, decl_ptr^.decl_index);
      }
      Disassemble_index(outfile, decl_ptr^.decl_index);

      {***********************}
      { disassemble decl info }
      {***********************}
      Disassemble_integer(outfile, decl_info_ptr^.line_number);
      Disassemble_integer(outfile, decl_info_ptr^.file_number);
      if decl_info_ptr^.decl_attributes_ptr <> nil then
        Disassemble_name(outfile,
          Get_decl_attributes_name(decl_info_ptr^.decl_attributes_ptr));
      Disassemble_newline(outfile);

      {********************************}
      { go to next decl in active list }
      {********************************}
      decl_info_ptr := decl_info_ptr^.next;
      // decl_index := decl_index + 1;
    end;

  {**************************************************}
  { disassemble debugging information for statements }
  {**************************************************}
  Disassemble_long(outfile, Stmt_info_count);
  Disassemble_newline(outfile);
  stmt_info_ptr := active_stmt_info_list;
  // stmt_index := 1;
  while stmt_info_ptr <> nil do
    begin
      {************************}
      { disassemble stmt index }
      {************************}
      stmt_ptr := stmt_ptr_type(stmt_info_ptr^.stmt_ref);

      {
      if implicit_stmt_indices then
        begin
          if stmt_ptr^.stmt_index <> stmt_index then
            Error('Found statement out of order.');
        end
      else
        Disassemble_index(outfile, stmt_ptr^.stmt_index);
      }
      Disassemble_index(outfile, stmt_ptr^.stmt_index);

      {***********************}
      { disassemble stmt info }
      {***********************}
      Disassemble_integer(outfile, stmt_info_ptr^.line_number);
      Disassemble_newline(outfile);

      {********************************}
      { go to next stmt in active list }
      {********************************}
      stmt_info_ptr := stmt_info_ptr^.next;
      // stmt_index := stmt_index + 1;
    end;
end; {procedure Disassemble_debug}


end.
