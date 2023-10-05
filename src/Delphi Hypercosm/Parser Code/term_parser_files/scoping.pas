unit scoping;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              scoping                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The scoping module provides a method of keeping         }
{       track of identifiers in language with multiple          }
{       scoping levels.                                         }
{                                                               }
{       The scoping rules are as they are with most languages,  }
{       where the nearest scope is searched first followed      }
{       by the enclosing scopes in the order from nearest       }
{       to farthest.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, symbol_tables, decl_attributes, stmt_attributes, scope_stacks;


{***************************************************************}
{                       The scoping system                      }
{***************************************************************}
{                                                               }
{       The scoping system employs three scope stacks:          }
{                                                               }
{              1)               2)               3)             }
{       |-------------|  |-------------|  |-------------|       }
{       |     The     |  |     The     |  |     The     |       }
{       |    static   |<-|   dynamic   |<-|    local    |       }
{       | scope stack |  | scope stack |  | scope stack |       }
{       |-------------|  |-------------|  |-------------|       }
{                                                               }
{                                                               }
{       1) The static scope stack:                              }
{       --------------------------                              }
{       This is the last scope stack searched, contains         }
{       identifiers which are statically declared, such as      }
{       local variables, types, and structure members.          }
{       This is the only scope stack which may be used to       }
{       store new identifiers. The other scope stacks are       }
{       used for reference scopes only.                         }
{                                                               }
{       2) The dynamic scope stack:                             }
{       ---------------------------                             }
{       This is scope stack is used to contain parameters       }
{       and declarations which are referenced inside of a       }
{       method call.  Dynamic scopes are reference scopes       }
{       meaning that they may be used to reference things       }
{       which have been previously declared in a static         }
{       scope, but new identifiers may not be stored from       }
{       inside of a method call.  Also, dynamic scopes are      }
{       always chain scopes, meaning that they do not hide      }
{       static declarations which are declared underneath.      }
{                                                               }
{       3) The local scope stack:                               }
{       -------------------------                               }
{       This scope stack is used for referencing fields of      }
{       a structure or class.  The local stack may not be       }
{       used to store identifiers, only to referenence them     }
{       and all local scopes are final, meaning that they       }
{       hide any scope under them.                              }
{                                                               }
{***************************************************************}


{*******************************************************************}
{ the static scope stack is used for declaring and referencing data }
{*******************************************************************}
procedure Push_static_scope(scope_decl_attributes_ptr:
  decl_attributes_ptr_type);
procedure Pop_static_scope;

{********************************************************}
{ the dynamic scope stack is used for passing parameters }
{********************************************************}
procedure Push_dynamic_scope(scope_stmt_attributes_ptr:
  stmt_attributes_ptr_type);
procedure Pop_dynamic_scope;

{*********************************************************}
{ the local scope stack is used for referencing data only }
{*********************************************************}
procedure Push_local_scope(scope_decl_attributes_ptr: decl_attributes_ptr_type);
procedure Pop_local_scope;

{****************************************************}
{ routines to add symbol tables to the current scope }
{****************************************************}
procedure Push_prev_scope(symbol_table_ptr: symbol_table_ptr_type);
procedure Push_post_scope(symbol_table_ptr: symbol_table_ptr_type);
procedure Pop_prev_scope;
procedure Pop_post_scope;

{******************************************************}
{ routines to add new identifiers to the current scope }
{******************************************************}
procedure Store_id(name: string_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
procedure Set_scope_decl_attributes(decl_attributes_ptr:
  decl_attributes_ptr_type;
  var scope_ptr: scope_ptr_type);

{*************************************************}
{ routines to find identifiers in the scope stack }
{*************************************************}
function Found_id(name: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  var stmt_attributes_ptr: stmt_attributes_ptr_type): boolean;
function Found_local_id(name: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  var stmt_attributes_ptr: stmt_attributes_ptr_type): boolean;
function Found_static_id(name: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  var stmt_attributes_ptr: stmt_attributes_ptr_type): boolean;
function Found_global_id(name: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  var stmt_attributes_ptr: stmt_attributes_ptr_type): boolean;
function Found_type_id(name: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  var stmt_attributes_ptr: stmt_attributes_ptr_type): boolean;

{*******************************************}
{ routines to report status of scope stacks }
{*******************************************}
function Get_static_scope_level: integer;
function Get_dynamic_scope_level: integer;
function Get_scope_decl_attributes: decl_attributes_ptr_type;
function Get_scope_stmt_attributes: stmt_attributes_ptr_type;


implementation
uses
  errors, make_decls;


var
  global_symbol_table_ptr: symbol_table_ptr_type;
  static_scope_stack_ptr: scope_stack_ptr_type;
  dynamic_scope_stack_ptr: scope_stack_ptr_type;
  local_scope_stack_ptr: scope_stack_ptr_type;


{********************************************}
{ static / dynamic level management routines }
{********************************************}


procedure Set_decl_static_level(decl_attributes_ptr: decl_attributes_ptr_type);
begin
  with decl_attributes_ptr^ do
    case kind of

      data_decl_attributes:
        begin
          if static or (scope_decl_attributes_ptr = nil) then
            static_level := 1
          else if scope_decl_attributes_ptr^.kind = type_decl_attributes then
            static_level := scope_decl_attributes_ptr^.static_level
          else
            static_level := scope_decl_attributes_ptr^.static_level + 1;
        end;

      type_decl_attributes, field_decl_attributes:
        decl_attributes_ptr^.static_level := 1;

    end;
end; {procedure Set_decl_static_level}


procedure Set_stmt_dynamic_level(stmt_attributes_ptr: stmt_attributes_ptr_type);
begin
  stmt_attributes_ptr^.dynamic_level := dynamic_scope_stack_ptr^.height + 1;
end; {procedure Set_stmt_dynamic_level}


{*******************************************************************}
{ the static scope stack is used for declaring and referencing data }
{*******************************************************************}


procedure Push_static_scope(scope_decl_attributes_ptr:
  decl_attributes_ptr_type);
var
  scope_info: scope_info_type;
  scope_ptr: scope_ptr_type;
begin
  scope_info.scope_kind := declaration_scope;
  scope_info.link_kind := chain_scope;
  scope_info.decl_attributes_ptr := scope_decl_attributes_ptr;
  scope_info.stmt_attributes_ptr := nil;

  scope_ptr := New_scope(scope_info);
  Push_scope_stack(static_scope_stack_ptr, scope_ptr);
end; {procedure Push_static_scope}


procedure Pop_static_scope;
var
  scope_ptr: scope_ptr_type;
begin
  scope_ptr := Pop_scope_stack(static_scope_stack_ptr);
  Free_scope(scope_ptr);
end; {procedure Pop_static_scope}


{********************************************************}
{ the dynamic scope stack is used for passing parameters }
{********************************************************}


procedure Push_dynamic_scope(scope_stmt_attributes_ptr:
  stmt_attributes_ptr_type);
var
  scope_info: scope_info_type;
  scope_ptr: scope_ptr_type;
begin
  scope_info.scope_kind := reference_scope;
  scope_info.link_kind := chain_scope;
  scope_info.decl_attributes_ptr := nil;
  scope_info.stmt_attributes_ptr := scope_stmt_attributes_ptr;
  Set_stmt_dynamic_level(scope_stmt_attributes_ptr);

  scope_ptr := New_scope(scope_info);
  Push_scope_stack(dynamic_scope_stack_ptr, scope_ptr);
end; {procedure Push_dynamic_scope}


procedure Pop_dynamic_scope;
var
  scope_ptr: scope_ptr_type;
begin
  scope_ptr := Pop_scope_stack(dynamic_scope_stack_ptr);
  Free_scope(scope_ptr);
end; {procedure Pop_dynamic_scope}


{*********************************************************}
{ the local scope stack is used for referencing data only }
{*********************************************************}


procedure Push_local_scope(scope_decl_attributes_ptr: decl_attributes_ptr_type);
var
  scope_info: scope_info_type;
  scope_ptr: scope_ptr_type;
begin
  scope_info.scope_kind := reference_scope;
  scope_info.link_kind := final_scope;
  scope_info.decl_attributes_ptr := scope_decl_attributes_ptr;
  scope_info.stmt_attributes_ptr := nil;

  scope_ptr := New_scope(scope_info);
  Push_scope_stack(local_scope_stack_ptr, scope_ptr);
end; {procedure Push_local_scope}


procedure Pop_local_scope;
var
  scope_ptr: scope_ptr_type;
begin
  scope_ptr := Pop_scope_stack(local_scope_stack_ptr);
  Free_scope(scope_ptr);
end; {procedure Pop_local_scope}


{****************************************************}
{ routines to add symbol tables to the current scope }
{****************************************************}


procedure Push_prev_scope(symbol_table_ptr: symbol_table_ptr_type);
begin
  if local_scope_stack_ptr^.height > 0 then
    Push_prev_scope_table(local_scope_stack_ptr^.first_scope_ptr,
      symbol_table_ptr)
  else if dynamic_scope_stack_ptr^.height > 0 then
    Push_prev_scope_table(dynamic_scope_stack_ptr^.first_scope_ptr,
      symbol_table_ptr)
  else
    Push_prev_scope_table(static_scope_stack_ptr^.first_scope_ptr,
      symbol_table_ptr);
end; {procedure Push_prev_scope}


procedure Push_post_scope(symbol_table_ptr: symbol_table_ptr_type);
begin
  if local_scope_stack_ptr^.height > 0 then
    Push_post_scope_table(local_scope_stack_ptr^.first_scope_ptr,
      symbol_table_ptr)
  else if dynamic_scope_stack_ptr^.height > 0 then
    Push_post_scope_table(dynamic_scope_stack_ptr^.first_scope_ptr,
      symbol_table_ptr)
  else
    Push_post_scope_table(static_scope_stack_ptr^.first_scope_ptr,
      symbol_table_ptr);
end; {procedure Push_post_scope}


procedure Pop_prev_scope;
begin
  if local_scope_stack_ptr^.height > 0 then
    Pop_prev_scope_table(local_scope_stack_ptr^.first_scope_ptr)
  else if dynamic_scope_stack_ptr^.height > 0 then
    Pop_prev_scope_table(dynamic_scope_stack_ptr^.first_scope_ptr)
  else
    Pop_prev_scope_table(static_scope_stack_ptr^.first_scope_ptr);
end; {procedure Pop_prev_scope}


procedure Pop_post_scope;
begin
  if local_scope_stack_ptr^.height > 0 then
    Pop_post_scope_table(local_scope_stack_ptr^.first_scope_ptr)
  else if dynamic_scope_stack_ptr^.height > 0 then
    Pop_post_scope_table(dynamic_scope_stack_ptr^.first_scope_ptr)
  else
    Pop_post_scope_table(static_scope_stack_ptr^.first_scope_ptr);
end; {procedure Pop_post_scope}


{*****************************}
{ identifier storage routines }
{*****************************}


procedure Store_id(name: string_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  scope_ptr: scope_ptr_type;
begin
  if local_scope_stack_ptr^.height <> 0 then
    Error('can not store ids in a local scope')
  else if dynamic_scope_stack_ptr^.height <> 0 then
    Error('can not store ids in a dynamic scope')
  else
    begin
      {***********************************************}
      { store id in first scope of static scope stack }
      {***********************************************}
      scope_ptr := static_scope_stack_ptr^.first_scope_ptr;
      Enter_scope(scope_ptr, name, decl_attributes_ptr);
      Set_decl_static_level(decl_attributes_ptr);
    end;
end; {function Store_id}


procedure Set_scope_decl_attributes(decl_attributes_ptr:
  decl_attributes_ptr_type;
  var scope_ptr: scope_ptr_type);
begin
  if local_scope_stack_ptr^.height <> 0 then
    Error('can not store ids in a local scope')
  else if dynamic_scope_stack_ptr^.height <> 0 then
    Error('can not store ids in a dynamic scope')
  else
    begin
      {***********************************************}
      { store id in first scope of static scope stack }
      {***********************************************}
      scope_ptr := static_scope_stack_ptr^.first_scope_ptr;
      Set_scope(decl_attributes_ptr, scope_ptr);
      Set_decl_static_level(decl_attributes_ptr);
    end;
end; {procedure Set_scope_decl_attributes}


{*******************************}
{ identifier retreival routines }
{*******************************}


function Found_id(name: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  var stmt_attributes_ptr: stmt_attributes_ptr_type): boolean;
var
  scope_ptr: scope_ptr_type;
  found, done: boolean;
begin
  found := false;
  done := false;

  {**************************}
  { search first local scope }
  {**************************}
  scope_ptr := local_scope_stack_ptr^.first_scope_ptr;
  if scope_ptr <> nil then
    begin
      found := Search_scope(scope_ptr, name, decl_attributes_ptr);
      done := true;
    end;

  {*****************************************}
  { search all dynamic scopes from top down }
  {*****************************************}
  if not (found or done) then
    begin
      scope_ptr := dynamic_scope_stack_ptr^.first_scope_ptr;
      while not (found or done) and (scope_ptr <> nil) do
        begin
          found := Search_scope(scope_ptr, name, decl_attributes_ptr);
          if scope_ptr^.scope_info.link_kind = final_scope then
            done := true;
          if not found then
            scope_ptr := scope_ptr^.next;
        end;
    end;

  {****************************************}
  { search all static scopes from top down }
  {****************************************}
  if not (found or done) then
    begin
      scope_ptr := static_scope_stack_ptr^.first_scope_ptr;
      while not (found or done) and (scope_ptr <> nil) do
        begin
          found := Search_scope(scope_ptr, name, decl_attributes_ptr);
          if scope_ptr^.scope_info.link_kind = final_scope then
            done := true;
          if not found then
            scope_ptr := scope_ptr^.next;
        end;
    end;

  {*************************}
  { return scope attributes }
  {*************************}
  if found then
    begin
      stmt_attributes_ptr := scope_ptr^.scope_info.stmt_attributes_ptr;
      Mark_decl_attributes(decl_attributes_ptr, true);
    end;

  Found_id := found;
end; {function Found_id}


function Found_static_id(name: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  var stmt_attributes_ptr: stmt_attributes_ptr_type): boolean;
var
  scope_ptr: scope_ptr_type;
  found, done: boolean;
begin
  found := false;
  done := false;

  {****************************************}
  { search all static scopes from top down }
  {****************************************}
  scope_ptr := static_scope_stack_ptr^.first_scope_ptr;
  while not (found or done) and (scope_ptr <> nil) do
    begin
      found := Search_scope(scope_ptr, name, decl_attributes_ptr);
      if scope_ptr^.scope_info.link_kind = final_scope then
        done := true;
      if not found then
        scope_ptr := scope_ptr^.next;
    end;

  {*************************}
  { return scope attributes }
  {*************************}
  if found then
    begin
      stmt_attributes_ptr := scope_ptr^.scope_info.stmt_attributes_ptr;
      Mark_decl_attributes(decl_attributes_ptr, true);
    end;

  Found_static_id := found;
end; {function Found_static_id}


function Found_global_id(name: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  var stmt_attributes_ptr: stmt_attributes_ptr_type): boolean;
var
  scope_ptr: scope_ptr_type;
  found: boolean;
begin
  found := false;

  scope_ptr := static_scope_stack_ptr^.last_scope_ptr;
  if scope_ptr <> nil then
    found := Search_scope(scope_ptr, name, decl_attributes_ptr);

  {*************************}
  { return scope attributes }
  {*************************}
  if found then
    begin
      stmt_attributes_ptr := scope_ptr^.scope_info.stmt_attributes_ptr;
      Mark_decl_attributes(decl_attributes_ptr, true);
    end;

  Found_global_id := found;
end; {function Found_global_id}


function Found_local_id(name: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  var stmt_attributes_ptr: stmt_attributes_ptr_type): boolean;
var
  scope_ptr: scope_ptr_type;
  found, done: boolean;
begin
  found := false;
  done := false;

  {**************************}
  { search first local scope }
  {**************************}
  scope_ptr := local_scope_stack_ptr^.first_scope_ptr;
  if scope_ptr <> nil then
    begin
      found := Search_scope(scope_ptr, name, decl_attributes_ptr);
      done := true;
    end;

  {***************************}
  { search first static scope }
  {***************************}
  if not (done or found) then
    begin
      scope_ptr := static_scope_stack_ptr^.first_scope_ptr;
      if scope_ptr <> nil then
        found := Search_scope(scope_ptr, name, decl_attributes_ptr);
    end;

  {*************************}
  { return scope attributes }
  {*************************}
  if found then
    begin
      stmt_attributes_ptr := scope_ptr^.scope_info.stmt_attributes_ptr;
      Mark_decl_attributes(decl_attributes_ptr, true);
    end;

  Found_local_id := found;
end; {function Found_local_id}


function Found_type_id(name: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type;
  var stmt_attributes_ptr: stmt_attributes_ptr_type): boolean;
var
  scope_ptr: scope_ptr_type;
  found: boolean;
begin
  {*********************************}
  { search all scopes from top down }
  { (not stopping at final scopes)  }
  {*********************************}
  found := false;

  {*****************************************}
  { search all dynamic scopes from top down }
  {*****************************************}
  scope_ptr := dynamic_scope_stack_ptr^.first_scope_ptr;
  while not found and (scope_ptr <> nil) do
    begin
      found := Search_scope(scope_ptr, name, decl_attributes_ptr);
      if not found then
        scope_ptr := scope_ptr^.next;
    end;

  {****************************************}
  { search all static scopes from top down }
  {****************************************}
  if not found then
    begin
      scope_ptr := static_scope_stack_ptr^.first_scope_ptr;
      while (not found) and (scope_ptr <> nil) do
        begin
          found := Search_scope(scope_ptr, name, decl_attributes_ptr);
          if not found then
            scope_ptr := scope_ptr^.next;
        end;
    end;

  {*************************}
  { return scope attributes }
  {*************************}
  if found then
    begin
      stmt_attributes_ptr := scope_ptr^.scope_info.stmt_attributes_ptr;
      Mark_decl_attributes(decl_attributes_ptr, true);
    end;

  Found_type_id := found;
end; {function Found_type_id}


{******************************************}
{ routines to report status of scope stack }
{******************************************}


function Get_static_scope_level: integer;
begin
  Get_static_scope_level := static_scope_stack_ptr^.height;
end; {function Static_scope_level}


function Get_dynamic_scope_level: integer;
begin
  Get_dynamic_scope_level := dynamic_scope_stack_ptr^.height;
end; {function Get_dynamic_scope_level}


function Get_scope_decl_attributes: decl_attributes_ptr_type;
var
  decl_attributes_ptr: decl_attributes_ptr_type;
begin
  with static_scope_stack_ptr^ do
    if first_scope_ptr <> nil then
      decl_attributes_ptr := first_scope_ptr^.scope_info.decl_attributes_ptr
    else
      decl_attributes_ptr := nil;

  Get_scope_decl_attributes := decl_attributes_ptr;
end; {function Get_scope_decl_attributes}


function Get_scope_stmt_attributes: stmt_attributes_ptr_type;
var
  stmt_attributes_ptr: stmt_attributes_ptr_type;
begin
  with dynamic_scope_stack_ptr^ do
    if first_scope_ptr <> nil then
      stmt_attributes_ptr := first_scope_ptr^.scope_info.stmt_attributes_ptr
    else
      stmt_attributes_ptr := nil;

  Get_scope_stmt_attributes := stmt_attributes_ptr;
end; {function Get_scope_stmt_attributes}


initialization
  {**************}
  { init globals }
  {**************}
  global_symbol_table_ptr := New_symbol_table;
  static_scope_stack_ptr := New_scope_stack;
  dynamic_scope_stack_ptr := New_scope_stack;
  local_scope_stack_ptr := New_scope_stack;

  {*******************}
  { init global scope }
  {*******************}
  Push_static_scope(nil);
  Push_prev_scope(global_symbol_table_ptr);
end.
