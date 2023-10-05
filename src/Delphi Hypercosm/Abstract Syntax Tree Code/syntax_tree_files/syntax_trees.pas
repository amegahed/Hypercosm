unit syntax_trees;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            syntax_trees               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The syntax_trees module defines all of the trees        }
{       used in the abstract syntax tree, the internal          }
{       representation of the code which is used by the         }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, stmts, decls;


{***************************************************************}
{           Simulation / Modelling Programming Language         }
{                   SMPL (pronounced 'simple')                  }
{***************************************************************}
{                          syntax_trees                         }
{***************************************************************}


type
  syntax_tree_kind_type = (

    {****************************}
    { root of entire syntax tree }
    {****************************}
    root_tree,

    {*******************************}
    { declarations from other files }
    {*******************************}
    include_tree);


type
  {******************************************************}
  { Note:                                                }
  { the names 'expr_ptr', 'stmt_ptr' and 'decl_ptr' are  }
  { intentionally not used as fields so that they may be }
  { used as locals inside of a 'with decl_ptr^' block.   }
  {                                                      }
  { Otherwise be wary of 'with decl_ptr^' blocks because }
  { the decl node has so many fields that an identifier  }
  { clash may easily cause a misunderstanding not found  }
  { by the compiler.                                     }
  {******************************************************}
  syntax_tree_ptr_type = ^syntax_tree_type;
  syntax_tree_type = record
    next: syntax_tree_ptr_type;

    case kind: syntax_tree_kind_type of

      {****************************}
      { root of entire syntax tree }
      {****************************}
      root_tree: (
        root_frame_size: integer;
        implicit_decls_ptr: decl_ptr_type;
        implicit_includes_ptr: syntax_tree_ptr_type;
        root_includes_ptr: syntax_tree_ptr_type;
        decls_ptr: decl_ptr_type;
        stmts_ptr: stmt_ptr_type;
        );

      {*******************************}
      { declarations from other files }
      {*******************************}
      include_tree: (
        include_index: integer;
        includes_ptr: syntax_tree_ptr_type;
        include_decls_ptr: decl_ptr_type;
        );
  end; {syntax_tree_type}


{*******************************************************}
{ routines for allocating and initializing syntax trees }
{*******************************************************}
function New_syntax_tree(kind: syntax_tree_kind_type): syntax_tree_ptr_type;
procedure Init_syntax_tree(syntax_tree_ptr: syntax_tree_ptr_type;
  kind: syntax_tree_kind_type);
function Copy_syntax_tree(syntax_tree_ptr: syntax_tree_ptr_type):
  syntax_tree_ptr_type;
function Copy_syntax_trees(syntax_tree_ptr: syntax_tree_ptr_type):
  syntax_tree_ptr_type;
procedure Free_syntax_tree(var syntax_tree_ptr: syntax_tree_ptr_type);
procedure Free_syntax_trees(var syntax_tree_ptr: syntax_tree_ptr_type);
function Syntax_tree_count: longint;

{******************************************}
{ routines for dealing with include tables }
{******************************************}
function Add_include(file_name: string_type): integer;
function Get_include(index: integer): string_type;
function Found_include(file_name: string_type): boolean;
function Get_includes: integer;

{***********************************}
{ routines for writing syntax trees }
{***********************************}
procedure Write_syntax_tree_kind(kind: syntax_tree_kind_type);


implementation
uses
  new_memory, hashtables, symbol_tables, code_types, comments, code_attributes,
  type_attributes, lit_attributes, expr_attributes, stmt_attributes,
  decl_attributes, arrays, exprs, instructs, code_decls, type_decls;


const
  block_size = 512;
  memory_alert = false;
  verbose = false;


type
  {************************}
  { block allocation types }
  {************************}
  syntax_tree_block_ptr_type = ^syntax_tree_block_type;
  syntax_tree_block_type = array[0..block_size] of syntax_tree_type;


var
  {************}
  { free lists }
  {************}
  syntax_tree_free_list: syntax_tree_ptr_type;

  {****************************}
  { block allocation variables }
  {****************************}
  syntax_tree_block_ptr: syntax_tree_block_ptr_type;
  syntax_tree_counter: longint;

  {*****************************}
  { hashtable for include files }
  {*****************************}
  include_table_ptr: hashtable_ptr_type;


{************************************************}
{ routines to unlink attributes from syntax tree }
{************************************************}


procedure Reset_decls_attributes(decl_attributes_ptr: decl_attributes_ptr_type);
var
  decl_ptr: decl_ptr_type;
begin
  while decl_attributes_ptr <> nil do
    begin
      decl_ptr := decl_ptr_type(decl_attributes_ptr^.decl_ref);
      if decl_ptr <> nil then
        Set_decl_attributes(decl_ptr, nil);
      decl_attributes_ptr := decl_attributes_ptr^.next;
    end;
end; {procedure Reset_decls_attributes}


procedure Reset_stmts_attributes(stmt_attributes_ptr: stmt_attributes_ptr_type);
var
  stmt_ptr: stmt_ptr_type;
begin
  while stmt_attributes_ptr <> nil do
    begin
      stmt_ptr := stmt_ptr_type(stmt_attributes_ptr^.stmt_ref);
      if stmt_ptr <> nil then
        Set_stmt_attributes(stmt_ptr, nil);
      stmt_attributes_ptr := stmt_attributes_ptr^.next;
    end;
end; {procedure Reset_stmts_attributes}


procedure Reset_exprs_attributes(expr_attributes_ptr: expr_attributes_ptr_type);
var
  expr_ptr: expr_ptr_type;
begin
  while expr_attributes_ptr <> nil do
    begin
      expr_ptr := expr_ptr_type(expr_attributes_ptr^.expr_ref);
      if expr_ptr <> nil then
        Set_expr_attributes(expr_ptr, nil);
      expr_attributes_ptr := expr_attributes_ptr^.next;
    end;
end; {procedure Reset_exprs_attributes}


procedure Reset_literals_attributes(literal_attributes_ptr:
  literal_attributes_ptr_type);
var
  expr_ptr: expr_ptr_type;
begin
  while literal_attributes_ptr <> nil do
    begin
      expr_ptr := expr_ptr_type(literal_attributes_ptr^.expr_ref);
      if expr_ptr <> nil then
        Set_literal_attributes(expr_ptr, nil);
      literal_attributes_ptr := literal_attributes_ptr^.next;
    end;
end; {procedure Reset_literals_attributes}


{***********************************************************}
{ routine for freeing all auxilliary syntax tree attributes }
{***********************************************************}


procedure Free_syntax_tree_attributes;
begin
  {************************************}
  { unlink attributes from syntax tree }
  {************************************}
  Reset_decls_attributes(active_decl_attributes_list);
  Reset_stmts_attributes(active_stmt_attributes_list);
  Reset_exprs_attributes(active_expr_attributes_list);
  Reset_literals_attributes(active_literal_attributes_list);

  {***********************************}
  { free attributes and related nodes }
  {***********************************}
  Free_all_hashtables;
  Free_all_symbol_tables;
  Free_all_code_attributes;
  Free_all_type_attributes;
  Free_all_decl_attributes;
  Free_all_stmt_attributes;
  Free_all_expr_attributes;
end; {procedure Free_syntax_tree_attributes}


{******************************************}
{ routines for dealing with include tables }
{******************************************}


function Add_include(file_name: string_type): integer;
var
  index: integer;
begin
  index := Hashtable_entries(include_table_ptr) + 1;
  Enter_hashtable(include_table_ptr, file_name, index);
  Add_include := index;
end; {function Add_include}


function Get_include(index: integer): string_type;
var
  key: string_type;
begin
  if Found_hashtable_key_by_value(include_table_ptr, key, index) then
    Get_include := key
  else
    Get_include := '?';
end; {function Get_include}


function Found_include(file_name: string_type): boolean;
var
  index: hashtable_value_type;
begin
  Found_include := Found_hashtable_value_by_key(include_table_ptr, index,
    file_name);
end; {function Found_include}


function Get_includes: integer;
begin
  Get_includes := Hashtable_entries(include_table_ptr);
end; {function Get_includes}


procedure Init_syntax_tree(syntax_tree_ptr: syntax_tree_ptr_type;
  kind: syntax_tree_kind_type);
begin
  {********************}
  { init common fields }
  {********************}
  syntax_tree_ptr^.kind := kind;
  syntax_tree_ptr^.next := nil;

  {**********************}
  { init specific fields }
  {**********************}
  with syntax_tree_ptr^ do
    case kind of

      {****************************}
      { root of entire syntax tree }
      {****************************}
      root_tree:
        begin
          root_frame_size := 0;
          implicit_decls_ptr := nil;
          implicit_includes_ptr := nil;
          root_includes_ptr := nil;
          decls_ptr := nil;
          stmts_ptr := nil;
        end;

      {*******************************}
      { declarations from other files }
      {*******************************}
      include_tree:
        begin
          include_index := 0;
          includes_ptr := nil;
          include_decls_ptr := nil;
        end;

    end; {case}
end; {procedure Init_syntax_tree}


function New_syntax_tree(kind: syntax_tree_kind_type): syntax_tree_ptr_type;
var
  syntax_tree_ptr: syntax_tree_ptr_type;
  index: integer;
begin
  {*************************************}
  { get syntax tree node from free list }
  {*************************************}
  if syntax_tree_free_list <> nil then
    begin
      syntax_tree_ptr := syntax_tree_free_list;
      syntax_tree_free_list := syntax_tree_free_list^.next;
    end
  else
    begin
      index := syntax_tree_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new syntax tree block');
          new(syntax_tree_block_ptr);
        end;
      syntax_tree_ptr := @syntax_tree_block_ptr^[index];
    end;

  {*******************************}
  { increment syntax tree counter }
  {*******************************}
  syntax_tree_counter := syntax_tree_counter + 1;

  {*****************************}
  { initialize syntax tree node }
  {*****************************}
  Init_syntax_tree(syntax_tree_ptr, kind);

  New_syntax_tree := syntax_tree_ptr;
end; {function New_syntax_tree}


function Syntax_tree_count: longint;
begin
  Syntax_tree_count := syntax_tree_counter;
end; {function Syntax_tree_count}


{********************************************************}
{ routines for copying syntax trees and associated nodes }
{********************************************************}


function Copy_syntax_tree(syntax_tree_ptr: syntax_tree_ptr_type):
  syntax_tree_ptr_type;
var
  new_syntax_tree_ptr: syntax_tree_ptr_type;
begin
  if (syntax_tree_ptr <> nil) then
    begin
      new_syntax_tree_ptr := New_syntax_tree(syntax_tree_ptr^.kind);
      new_syntax_tree_ptr^ := syntax_tree_ptr^;
      new_syntax_tree_ptr^.next := nil;
    end
  else
    new_syntax_tree_ptr := nil;

  Copy_syntax_tree := new_syntax_tree_ptr;
end; {function Copy_syntax_tree}


function Copy_syntax_trees(syntax_tree_ptr: syntax_tree_ptr_type):
  syntax_tree_ptr_type;
var
  new_syntax_tree_ptr: syntax_tree_ptr_type;
  first_syntax_tree_ptr, last_syntax_tree_ptr: syntax_tree_ptr_type;
begin
  first_syntax_tree_ptr := nil;
  last_syntax_tree_ptr := nil;

  while syntax_tree_ptr <> nil do
    begin
      new_syntax_tree_ptr := Copy_syntax_tree(syntax_tree_ptr);

      {*****************************************}
      { add new syntax tree node to end of list }
      {*****************************************}
      if (last_syntax_tree_ptr <> nil) then
        begin
          last_syntax_tree_ptr^.next := new_syntax_tree_ptr;
          last_syntax_tree_ptr := new_syntax_tree_ptr;
        end
      else
        begin
          first_syntax_tree_ptr := new_syntax_tree_ptr;
          last_syntax_tree_ptr := new_syntax_tree_ptr;
        end;

      syntax_tree_ptr := syntax_tree_ptr^.next;
    end;

  Copy_syntax_trees := first_syntax_tree_ptr;
end; {function Copy_syntax_trees}


{********************************************************}
{ routines for freeing syntax trees and associated nodes }
{********************************************************}


procedure Free_syntax_tree(var syntax_tree_ptr: syntax_tree_ptr_type);
begin
  if (syntax_tree_ptr <> nil) then
    begin
      {******************************}
      { add syntax tree to free list }
      {******************************}
      syntax_tree_ptr^.next := syntax_tree_free_list;
      syntax_tree_free_list := syntax_tree_ptr;
      syntax_tree_ptr := nil;

      {*******************************}
      { decrement syntax tree counter }
      {*******************************}
      syntax_tree_counter := syntax_tree_counter - 1;
    end;
end; {procedure Free_syntax_tree}


procedure Free_syntax_trees(var syntax_tree_ptr: syntax_tree_ptr_type);
var
  temp: syntax_tree_ptr_type;
begin
  while (syntax_tree_ptr <> nil) do
    begin
      temp := syntax_tree_ptr;
      syntax_tree_ptr := syntax_tree_ptr^.next;
      Free_syntax_tree(temp);
    end;
end; {procedure Free_syntax_trees}


{***********************************}
{ routines for writing syntax trees }
{***********************************}


procedure Write_syntax_tree_kind(kind: syntax_tree_kind_type);
begin
  case kind of

    root_tree:
      write('root_tree');
    include_tree:
      write('include_tree');

  end; {case}
end; {procedure Write_syntax_tree_kind}


initialization
  {***********************}
  { initialize free lists }
  {***********************}
  syntax_tree_free_list := nil;

  {***************************************}
  { initialize block allocation variables }
  {***************************************}
  syntax_tree_block_ptr := nil;
  syntax_tree_counter := 0;

  {****************************************}
  { initialize hashtable for include files }
  {****************************************}
  include_table_ptr := New_hashtable;
end.
