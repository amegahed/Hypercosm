unit scope_stacks;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            scope_stacks               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The scope_stack module provides a method of keeping     }
{       track of identifiers in language with multiple scoping  }
{       levels.                                                 }
{                                                               }
{       The scoping rules are as they are with most languages,  }
{       where the nearest scope is searched first followed      }
{       by the enclosing scopes in the order from nearest to    }
{       farthest.                                               }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, symbol_tables, decl_attributes, stmt_attributes;


type
  symbol_table_ref_ptr_type = ^symbol_table_ref_type;
  symbol_table_ref_type = record
    symbol_table_ptr: symbol_table_ptr_type;
    prev, next: symbol_table_ref_ptr_type;
  end; {symbol_table_ref_type}


  {*******************************************************************}
  { declaration scopes may be used to store new identifiers whereas   }
  { reference scopes may be used only to find previously declared ids }
  {*******************************************************************}
type
  scope_kind_type = (declaration_scope, reference_scope);
  scope_link_kind_type = (chain_scope, final_scope);


  scope_info_type = record
    scope_kind: scope_kind_type;
    link_kind: scope_link_kind_type;
    decl_attributes_ptr: decl_attributes_ptr_type;
    stmt_attributes_ptr: stmt_attributes_ptr_type;
  end; {scope_info_type}


  scope_ptr_type = ^scope_type;
  scope_type = record
    scope_info: scope_info_type;

    first_table_ptr: symbol_table_ref_ptr_type;
    last_table_ptr: symbol_table_ref_ptr_type;

    next: scope_ptr_type;
  end;


  scope_stack_ptr_type = ^scope_stack_type;
  scope_stack_type = record
    height: integer;

    first_scope_ptr: scope_ptr_type;
    last_scope_ptr: scope_ptr_type;

    next: scope_stack_ptr_type;
  end; {scope_stack_type}


{********************************************}
{ routines to allocate and free scope stacks }
{********************************************}
function New_scope_stack: scope_stack_ptr_type;
procedure Free_scope_stack(var scope_stack_ptr: scope_stack_ptr_type);

{**************************************}
{ routines to allocate and free scopes }
{**************************************}
function New_scope(scope_info: scope_info_type): scope_ptr_type;
procedure Free_scope(var scope_ptr: scope_ptr_type);

{***************************************************}
{ routines to push and pop scopes from scope stacks }
{***************************************************}
procedure Push_scope_stack(scope_stack_ptr: scope_stack_ptr_type;
  scope_ptr: scope_ptr_type);
function Pop_scope_stack(scope_stack_ptr: scope_stack_ptr_type): scope_ptr_type;

{******************************************}
{ routines to add symbol tables to a scope }
{******************************************}
procedure Push_prev_scope_table(scope_ptr: scope_ptr_type;
  symbol_table_ptr: symbol_table_ptr_type);
procedure Push_post_scope_table(scope_ptr: scope_ptr_type;
  symbol_table_ptr: symbol_table_ptr_type);
function Pop_prev_scope_table(scope_ptr: scope_ptr_type): symbol_table_ptr_type;
function Pop_post_scope_table(scope_ptr: scope_ptr_type): symbol_table_ptr_type;

{*****************************************************}
{ routines to enter and retreive symbols from a scope }
{*****************************************************}
procedure Enter_scope(scope_ptr: scope_ptr_type;
  name: string_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
procedure Set_scope(decl_attributes_ptr: decl_attributes_ptr_type;
  scope_ptr: scope_ptr_type);
function Search_scope(scope_ptr: scope_ptr_type;
  name: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type): boolean;


implementation
uses
  errors, new_memory;


const
  memory_alert = false;


var
  {************}
  { free lists }
  {************}
  symbol_table_ref_free_list: symbol_table_ref_ptr_type;
  scope_free_list: scope_ptr_type;
  scope_stack_free_list: scope_stack_ptr_type;


{*************************************************}
{ routines to allocate and free symbol table refs }
{*************************************************}


function New_symbol_table_ref(symbol_table_ptr: symbol_table_ptr_type):
  symbol_table_ref_ptr_type;
var
  symbol_table_ref_ptr: symbol_table_ref_ptr_type;
begin
  {*************************************}
  { get symbol table ref from free list }
  {*************************************}
  if (symbol_table_ref_free_list <> nil) then
    begin
      symbol_table_ref_ptr := symbol_table_ref_free_list;
      symbol_table_ref_free_list := symbol_table_ref_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new symbol table ref');
      new(symbol_table_ref_ptr);
    end;

  {*****************************}
  { initialize symbol table ref }
  {*****************************}
  symbol_table_ref_ptr^.symbol_table_ptr := symbol_table_ptr;
  symbol_table_ref_ptr^.next := nil;
  symbol_table_ref_ptr^.prev := nil;

  New_symbol_table_ref := symbol_table_ref_ptr;
end; {function New_symbol_table_ref}


procedure Free_symbol_table_ref(var symbol_table_ref_ptr:
  symbol_table_ref_ptr_type);
begin
  if symbol_table_ref_ptr <> nil then
    begin
      {***********************************}
      { add symbol table ref to free list }
      {***********************************}
      symbol_table_ref_ptr^.next := symbol_table_ref_free_list;
      symbol_table_ref_free_list := symbol_table_ref_ptr;
      symbol_table_ref_ptr := nil;
    end;
end; {procedure Free_symbol_table_ref}


{**************************************}
{ routines to allocate and free scopes }
{**************************************}


function New_scope(scope_info: scope_info_type): scope_ptr_type;
var
  scope_ptr: scope_ptr_type;
begin
  {**************************}
  { get scope from free list }
  {**************************}
  if (scope_free_list <> nil) then
    begin
      scope_ptr := scope_free_list;
      scope_free_list := scope_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new scope');
      new(scope_ptr);
    end;

  {******************}
  { initialize scope }
  {******************}
  scope_ptr^.scope_info := scope_info;
  with scope_ptr^ do
    begin
      first_table_ptr := nil;
      last_table_ptr := nil;
      next := nil;
    end;

  New_scope := scope_ptr;
end; {function New_scope}


procedure Free_scope(var scope_ptr: scope_ptr_type);
var
  symbol_table_ref_ptr: symbol_table_ref_ptr_type;
begin
  if scope_ptr <> nil then
    begin
      {********************}
      { free symbol tables }
      {********************}
      while scope_ptr^.first_table_ptr <> nil do
        begin
          symbol_table_ref_ptr := scope_ptr^.first_table_ptr;
          scope_ptr^.first_table_ptr := symbol_table_ref_ptr^.next;
          Free_symbol_table_ref(symbol_table_ref_ptr);
        end;
      scope_ptr^.last_table_ptr := nil;

      {************************}
      { add scope to free list }
      {************************}
      scope_ptr^.next := scope_free_list;
      scope_free_list := scope_ptr;
      scope_ptr := nil;
    end;
end; {procedure Free_scope}


{********************************************}
{ routines to allocate and free scope stacks }
{********************************************}

function New_scope_stack: scope_stack_ptr_type;
var
  scope_stack_ptr: scope_stack_ptr_type;
begin
  {********************************}
  { get scope stack from free list }
  {********************************}
  if (scope_stack_free_list <> nil) then
    begin
      scope_stack_ptr := scope_stack_free_list;
      scope_stack_free_list := scope_stack_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new scope stack');
      new(scope_stack_ptr);
    end;

  {************************}
  { initialize scope stack }
  {************************}
  scope_stack_ptr^.height := 0;
  scope_stack_ptr^.first_scope_ptr := nil;
  scope_stack_ptr^.last_scope_ptr := nil;

  New_scope_stack := scope_stack_ptr;
end; {function New_scope_stack}


procedure Free_scope_stack(var scope_stack_ptr: scope_stack_ptr_type);
var
  scope_ptr: scope_ptr_type;
begin
  if scope_stack_ptr <> nil then
    begin
      {*************}
      { free scopes }
      {*************}
      while scope_stack_ptr^.first_scope_ptr <> nil do
        begin
          scope_ptr := scope_stack_ptr^.first_scope_ptr;
          scope_stack_ptr^.first_scope_ptr :=
            scope_stack_ptr^.first_scope_ptr^.next;
          Free_scope(scope_ptr);
        end;
      scope_stack_ptr^.last_scope_ptr := nil;

      {******************************}
      { add scope stack to free list }
      {******************************}
      scope_stack_ptr^.next := scope_stack_free_list;
      scope_stack_free_list := scope_stack_ptr;
      scope_stack_ptr := nil;
    end;
end; {procedure Free_scope_stack}


{***************************************************}
{ routines to push and pop scopes from scope stacks }
{***************************************************}


procedure Push_scope_stack(scope_stack_ptr: scope_stack_ptr_type;
  scope_ptr: scope_ptr_type);
begin
  if scope_ptr <> nil then
    begin
      {****************************}
      { add to front of scope list }
      {****************************}
      scope_ptr^.next := scope_stack_ptr^.first_scope_ptr;
      scope_stack_ptr^.first_scope_ptr := scope_ptr;
      scope_stack_ptr^.height := scope_stack_ptr^.height + 1;

      if scope_stack_ptr^.last_scope_ptr = nil then
        scope_stack_ptr^.last_scope_ptr := scope_ptr;
    end
  else
    Error('can not push nil scope');
end; {procedure Push_scope_stack}


function Pop_scope_stack(scope_stack_ptr: scope_stack_ptr_type): scope_ptr_type;
var
  scope_ptr: scope_ptr_type;
begin
  if (scope_stack_ptr^.first_scope_ptr <> nil) then
    begin
      {*********************************}
      { remove from front of scope list }
      {*********************************}
      scope_ptr := scope_stack_ptr^.first_scope_ptr;
      scope_stack_ptr^.first_scope_ptr := scope_ptr^.next;
      scope_stack_ptr^.height := scope_stack_ptr^.height - 1;

      if scope_stack_ptr^.first_scope_ptr = nil then
        scope_stack_ptr^.last_scope_ptr := nil;
    end
  else
    begin
      Error('scope stack underflow');
      scope_ptr := nil;
    end;

  Pop_scope_stack := scope_ptr;
end; {function Pop_scope_stack}


{******************************************}
{ routines to add symbol tables to a scope }
{******************************************}


procedure Push_prev_scope_table(scope_ptr: scope_ptr_type;
  symbol_table_ptr: symbol_table_ptr_type);
var
  symbol_table_ref_ptr: symbol_table_ref_ptr_type;
begin
  if scope_ptr <> nil then
    if symbol_table_ptr <> nil then
      begin
        symbol_table_ref_ptr := New_symbol_table_ref(symbol_table_ptr);

        {**************************************}
        { add to head of list of symbol tables }
        {**************************************}
        if scope_ptr^.first_table_ptr <> nil then
          begin
            scope_ptr^.first_table_ptr^.prev := symbol_table_ref_ptr;
            symbol_table_ref_ptr^.next := scope_ptr^.first_table_ptr;
            scope_ptr^.first_table_ptr := symbol_table_ref_ptr;
          end
        else
          begin
            scope_ptr^.first_table_ptr := symbol_table_ref_ptr;
            scope_ptr^.last_table_ptr := symbol_table_ref_ptr;
          end;
      end
    else
      Error('can not push a nil scope table');
end; {procedure Push_prev_scope_table}


procedure Push_post_scope_table(scope_ptr: scope_ptr_type;
  symbol_table_ptr: symbol_table_ptr_type);
var
  symbol_table_ref_ptr: symbol_table_ref_ptr_type;
begin
  if scope_ptr <> nil then
    if symbol_table_ptr <> nil then
      begin
        symbol_table_ref_ptr := New_symbol_table_ref(symbol_table_ptr);

        {**************************************}
        { add to tail of list of symbol tables }
        {**************************************}
        if scope_ptr^.last_table_ptr <> nil then
          begin
            symbol_table_ref_ptr^.prev := scope_ptr^.last_table_ptr;
            scope_ptr^.last_table_ptr^.next := symbol_table_ref_ptr;
            scope_ptr^.last_table_ptr := symbol_table_ref_ptr;
          end
        else
          begin
            scope_ptr^.first_table_ptr := symbol_table_ref_ptr;
            scope_ptr^.last_table_ptr := symbol_table_ref_ptr;
          end;
      end
    else
      Error('can not push a nil scope table');
end; {procedure Push_post_scope_table}


function Pop_prev_scope_table(scope_ptr: scope_ptr_type): symbol_table_ptr_type;
var
  symbol_table_ptr: symbol_table_ptr_type;
  symbol_table_ref_ptr: symbol_table_ref_ptr_type;
begin
  symbol_table_ptr := nil;

  if scope_ptr <> nil then
    if scope_ptr^.first_table_ptr <> nil then
      begin
        symbol_table_ref_ptr := scope_ptr^.first_table_ptr;
        scope_ptr^.first_table_ptr := scope_ptr^.first_table_ptr^.next;

        symbol_table_ptr := symbol_table_ref_ptr^.symbol_table_ptr;
        Free_symbol_table_ref(symbol_table_ref_ptr);

        if scope_ptr^.first_table_ptr = nil then
          scope_ptr^.last_table_ptr := nil;
      end
    else
      Error('scope symbol table underflow error')
  else
    Error('can not pop a nil scope table');

  Pop_prev_scope_table := symbol_table_ptr;
end; {function Pop_prev_scope_table}


function Pop_post_scope_table(scope_ptr: scope_ptr_type): symbol_table_ptr_type;
var
  symbol_table_ptr: symbol_table_ptr_type;
  symbol_table_ref_ptr: symbol_table_ref_ptr_type;
begin
  symbol_table_ptr := nil;

  if scope_ptr <> nil then
    if scope_ptr^.last_table_ptr <> nil then
      begin
        symbol_table_ref_ptr := scope_ptr^.last_table_ptr;
        scope_ptr^.last_table_ptr := scope_ptr^.last_table_ptr^.prev;

        symbol_table_ptr := symbol_table_ref_ptr^.symbol_table_ptr;
        Free_symbol_table_ref(symbol_table_ref_ptr);

        if scope_ptr^.last_table_ptr = nil then
          scope_ptr^.first_table_ptr := nil;
      end
    else
      Error('scope symbol table underflow error')
  else
    Error('can not pop a nil scope table');

  Pop_post_scope_table := symbol_table_ptr;
end; {function Pop_post_scope_table}


{*****************************************************}
{ routines to enter and retreive symbols from a scope }
{*****************************************************}


procedure Set_scope(decl_attributes_ptr: decl_attributes_ptr_type;
  scope_ptr: scope_ptr_type);
begin
  {***************************************************}
  { store scope attributes in identifier's attributes }
  {***************************************************}
  decl_attributes_ptr^.scope_decl_attributes_ptr :=
    scope_ptr^.scope_info.decl_attributes_ptr;
end; {procedure Set_scope}


procedure Enter_scope(scope_ptr: scope_ptr_type;
  name: string_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
var
  symbol_table_ptr: symbol_table_ptr_type;
begin
  {**************************}
  { store id in symbol table }
  {**************************}
  if scope_ptr <> nil then
    if scope_ptr^.scope_info.scope_kind <> reference_scope then
      if scope_ptr^.first_table_ptr <> nil then
        begin
          symbol_table_ptr := scope_ptr^.first_table_ptr^.symbol_table_ptr;
          decl_attributes_ptr^.id_ptr := Enter_id(symbol_table_ptr, name,
            id_value_type(decl_attributes_ptr));
          Set_scope(decl_attributes_ptr, scope_ptr);
        end
      else
        Error('can not enter symbols into a nil scope table')
    else
      Error('can not enter symbols in a reference scope')
  else
    Error('can not enter symbols into a nil scope');
end; {procedure Enter_scope}


function Search_scope(scope_ptr: scope_ptr_type;
  name: string_type;
  var decl_attributes_ptr: decl_attributes_ptr_type): boolean;
var
  symbol_table_ref_ptr: symbol_table_ref_ptr_type;
  id_ptr: id_ptr_type;
  found: boolean;
begin
  found := false;

  {*****************************************}
  { search scope and its list of sub scopes }
  {*****************************************}
  if scope_ptr <> nil then
    begin
      symbol_table_ref_ptr := scope_ptr^.first_table_ptr;
      while (symbol_table_ref_ptr <> nil) and not found do
        begin
          found := Found_id_by_name(symbol_table_ref_ptr^.symbol_table_ptr,
            id_ptr, name);

          if found then
            decl_attributes_ptr :=
              decl_attributes_ptr_type(Get_id_value(id_ptr));

          symbol_table_ref_ptr := symbol_table_ref_ptr^.next;
        end;
    end;

  Search_scope := found;
end; {function Search_scope}


initialization
  {***********************}
  { initialize free lists }
  {***********************}
  symbol_table_ref_free_list := nil;
  scope_free_list := nil;
  scope_stack_free_list := nil;
end.
