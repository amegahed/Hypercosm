unit decl_attributes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           decl_attributes             3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the attributes and which are       }
{       used to describe variables and types used by the        }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, new_memory, hashtables, symbol_tables, type_attributes, addr_types;


type
  decl_attributes_kind_type = (data_decl_attributes, type_decl_attributes,
    field_decl_attributes);


  forward_decl_ref_type = ptr_type;


  {******************************************************}
  { Attributes are created for each declaration of a new }
  { type or variable. The attributes reflect the data    }
  { type and storage class as well as the nesting and    }
  { and the indices of the variables in memory.          }
  {******************************************************}
  decl_attributes_ptr_type = ^decl_attributes_type;
  decl_attributes_type = record

    {*******************************}
    { links to active or free lists }
    {*******************************}
    prev, next: decl_attributes_ptr_type;

    {*****************************************************}
    { syntax tree declaration which uses these attributes }
    {*****************************************************}
    decl_ref: forward_decl_ref_type;

    {*****************}
    { type attributes }
    {*****************}
    base_type_attributes_ref, type_attributes_ptr: type_attributes_ptr_type;
    dimensions: integer;
    id_ptr: id_ptr_type;

    {********************}
    { storage attributes }
    {********************}
    static: boolean; { decl's stack allocation }
    dynamic: boolean; { decl's heap allocation  }
    native: boolean; { non user defined decls  }

    {**********************}
    { semantics attributes }
    {**********************}
    forward: boolean; { actual decl follows     }
    abstract: boolean; { implementation follows  }
    final: boolean; { variability of value    }
    immutable: boolean; { derefed variability     }

    final_reference: boolean;
    implicit_reference: boolean;

    {*********************************************}
    { flags for finding unreferenced declarations }
    {*********************************************}
    used, reported: boolean;

    {********************************************}
    { size of declaration's scope, if it has one }
    {********************************************}
    scope_size: stack_index_type;

    {******************************************}
    { attributes of parent scope's declaration }
    {******************************************}
    scope_decl_attributes_ptr: decl_attributes_ptr_type;

    {***********************}
    { addressing attributes }
    {***********************}
    case kind: decl_attributes_kind_type of

      data_decl_attributes, type_decl_attributes: (
        stack_index: stack_index_type;
        static_level: integer;
        );

      field_decl_attributes: (
        field_index: heap_index_type;
        );
  end; {decl_attributes_type}


var
  {****************************}
  { lists of active attributes }
  {****************************}
  active_decl_attributes_list: decl_attributes_ptr_type;


{*************************************}
{ routines for declaration attributes }
{*************************************}
function New_decl_attributes(kind: decl_attributes_kind_type;
  base_type_attributes_ptr: type_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type): decl_attributes_ptr_type;
function Copy_decl_attributes(decl_attributes_ptr: decl_attributes_ptr_type):
  decl_attributes_ptr_type;
procedure Free_decl_attributes(var decl_attributes_ptr:
  decl_attributes_ptr_type);

{************************************************************}
{ routines to access declaration attributes from identifiers }
{************************************************************}
procedure Set_id_decl_attributes(id_ptr: id_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
function Get_id_decl_attributes(id_ptr: id_ptr_type): decl_attributes_ptr_type;

{********************************************}
{ routines to retreive names from attributes }
{********************************************}
function Get_decl_attributes_name(decl_attributes_ptr:
  decl_attributes_ptr_type): string_type;

{***********************************************}
{ diagnostic routines to write out active lists }
{***********************************************}
procedure Write_active_decl_attributes;

{****************************************}
{ routine to write out enumerated values }
{****************************************}
procedure Write_decl_attributes_kind(kind: decl_attributes_kind_type);

{****************************************}
{ miscillaneous decl attributes routines }
{****************************************}
procedure Free_all_decl_attributes;


implementation
uses
  errors;


const
  verbose = false;


const
  block_size = 512;
  memory_alert = false;


type
  {************************}
  { block allocation types }
  {************************}
  decl_attributes_block_ptr_type = ^decl_attributes_block_type;
  decl_attributes_block_type = record
    block: array[0..block_size] of decl_attributes_type;
    next: decl_attributes_block_ptr_type;
  end;


var
  {**************}
  { active lists }
  {**************}
  last_active_decl_attributes_ptr: decl_attributes_ptr_type;

  {************}
  { free lists }
  {************}
  decl_attributes_free_list: decl_attributes_ptr_type;

  {****************************}
  { block allocation variables }
  {****************************}
  decl_attributes_block_list: decl_attributes_block_ptr_type;
  decl_attributes_counter: longint;


{*************************************}
{ routines for declaration attributes }
{*************************************}


procedure Init_decl_attributes(kind: decl_attributes_kind_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
begin
  decl_attributes_ptr^.kind := kind;
  with decl_attributes_ptr^ do
    begin
      decl_ref := nil;
      id_ptr := nil;

      {********************}
      { storage attributes }
      {********************}
      static := false; { decl's stack allocation }
      dynamic := true; { decl's heap allocation  }
      native := false; { non user defined decls  }

      {**********************}
      { semantics attributes }
      {**********************}
      forward := false; { actual decl follows     }
      abstract := false; { implementation follows  }
      final := false; { variability of value    }
      immutable := false; { derefed variability     }

      final_reference := false;
      implicit_reference := false;

      {*********************************************}
      { flags for finding unreferenced declarations }
      {*********************************************}
      used := false;
      reported := false;

      {********************************************}
      { size of declaration's scope, if it has one }
      {********************************************}
      scope_size := 0;

      {******************************************}
      { attributes of parent scope's declaration }
      {******************************************}
      scope_decl_attributes_ptr := nil;

      {***********************}
      { addressing attributes }
      {***********************}
      case kind of

        data_decl_attributes, type_decl_attributes:
          begin
            stack_index := 1;
            static_level := 0;
          end;

        field_decl_attributes:
          field_index := 1;

      end; {case}
    end; {with}
end; {procedure Init_decl_attributes}


function New_decl_attributes(kind: decl_attributes_kind_type;
  base_type_attributes_ptr: type_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type): decl_attributes_ptr_type;
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  decl_attributes_block_ptr: decl_attributes_block_ptr_type;
  index: integer;
begin
  {************************************}
  { get decl attributes from free list }
  {************************************}
  if decl_attributes_free_list <> nil then
    begin
      decl_attributes_ptr := decl_attributes_free_list;
      decl_attributes_free_list := decl_attributes_free_list^.next;
    end
  else
    begin
      index := decl_attributes_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new decl attributes block');
          new(decl_attributes_block_ptr);
          decl_attributes_block_ptr^.next := decl_attributes_block_list;
          decl_attributes_block_list := decl_attributes_block_ptr;
        end;
      decl_attributes_ptr := @decl_attributes_block_list^.block[index];
      decl_attributes_counter := decl_attributes_counter + 1;
    end;

  {****************************}
  { initialize decl attributes }
  {****************************}
  Init_decl_attributes(kind, decl_attributes_ptr);

  if type_attributes_ptr = nil then
    type_attributes_ptr := base_type_attributes_ptr;

  if type_attributes_ptr <> nil then
    begin
      decl_attributes_ptr^.base_type_attributes_ref := base_type_attributes_ptr;
      decl_attributes_ptr^.type_attributes_ptr := type_attributes_ptr;
      decl_attributes_ptr^.dimensions := Get_data_abs_dims(type_attributes_ptr);
    end;

  {***************************}
  { add to end of active list }
  {***************************}
  if last_active_decl_attributes_ptr <> nil then
    begin
      last_active_decl_attributes_ptr^.next := decl_attributes_ptr;
      decl_attributes_ptr^.prev := last_active_decl_attributes_ptr;
      last_active_decl_attributes_ptr := decl_attributes_ptr;
      decl_attributes_ptr^.next := nil;
    end
  else
    begin
      active_decl_attributes_list := decl_attributes_ptr;
      last_active_decl_attributes_ptr := decl_attributes_ptr;
      decl_attributes_ptr^.prev := nil;
      decl_attributes_ptr^.next := nil;
    end;

  New_decl_attributes := decl_attributes_ptr;
end; {function New_decl_attributes}


function Copy_decl_attributes(decl_attributes_ptr: decl_attributes_ptr_type):
  decl_attributes_ptr_type;
var
  copy_attributes_ptr: decl_attributes_ptr_type;
  next, prev: decl_attributes_ptr_type;
begin
  if decl_attributes_ptr <> nil then
    begin
      with decl_attributes_ptr^ do
        copy_attributes_ptr := New_decl_attributes(kind,
          base_type_attributes_ref, type_attributes_ptr);

      {****************************************}
      { copy all fields except for link fields }
      {****************************************}
      next := copy_attributes_ptr^.next;
      prev := copy_attributes_ptr^.prev;
      copy_attributes_ptr^ := decl_attributes_ptr^;
      copy_attributes_ptr^.next := next;
      copy_attributes_ptr^.prev := prev;
    end
  else
    copy_attributes_ptr := nil;

  Copy_decl_attributes := copy_attributes_ptr;
end; {function Copy_decl_attributes}


procedure Free_decl_attributes(var decl_attributes_ptr:
  decl_attributes_ptr_type);
begin
  if decl_attributes_ptr <> nil then
    begin
      {*******************************}
      { link neighbors in active list }
      {*******************************}
      if decl_attributes_ptr^.prev <> nil then
        decl_attributes_ptr^.prev^.next := decl_attributes_ptr^.next
      else
        active_decl_attributes_list := decl_attributes_ptr^.next;

      if decl_attributes_ptr^.next <> nil then
        decl_attributes_ptr^.next^.prev := decl_attributes_ptr^.prev
      else
        last_active_decl_attributes_ptr := decl_attributes_ptr^.prev;

      {**********************************}
      { reset decl backpointer reference }
      {**********************************}
      decl_attributes_ptr^.decl_ref := nil;

      {****************************}
      { free associated identifier }
      {****************************}
      Free_hashtable_entry(decl_attributes_ptr^.id_ptr);

      {**********************************}
      { add decl attributes to free list }
      {**********************************}
      decl_attributes_ptr^.prev := nil;
      decl_attributes_ptr^.next := decl_attributes_free_list;
      decl_attributes_free_list := decl_attributes_ptr;
      decl_attributes_ptr := nil;
    end;
end; {procedure Free_decl_attributes}


procedure Dispose_decl_attributes(var decl_attributes_ptr:
  decl_attributes_ptr_type);
var
  temp: decl_attributes_ptr_type;
begin
  while decl_attributes_ptr <> nil do
    begin
      temp := decl_attributes_ptr;
      decl_attributes_ptr := decl_attributes_ptr^.next;
      dispose(temp);
    end;
end; {procedure Dispose_decl_attributes}


{************************************************}
{ routines to access attributes from identifiers }
{************************************************}


procedure Set_id_decl_attributes(id_ptr: id_ptr_type;
  decl_attributes_ptr: decl_attributes_ptr_type);
begin
  id_ptr^.value := id_value_type(decl_attributes_ptr);
end; {procedure Set_id_decl_attributes}


function Get_id_decl_attributes(id_ptr: id_ptr_type): decl_attributes_ptr_type;
begin
  if id_ptr <> nil then
    Get_id_decl_attributes := decl_attributes_ptr_type(id_ptr^.value)
  else
    Get_id_decl_attributes := nil;
end; {function Get_id_attributes}


{********************************************}
{ routines to retreive names from attributes }
{********************************************}


function Get_decl_attributes_name(decl_attributes_ptr:
  decl_attributes_ptr_type): string_type;
var
  str: string_type;
begin
  if decl_attributes_ptr <> nil then
    begin
      if decl_attributes_ptr^.kind <> type_decl_attributes then
        Get_decl_attributes_name := Get_id_name(decl_attributes_ptr^.id_ptr)
      else
        begin
          str := Get_id_name(decl_attributes_ptr^.id_ptr);
          str := Change_str_suffix(str, ' type', '');
          Get_decl_attributes_name := str;
        end;
    end
  else
    Get_decl_attributes_name := '?';
end; {function Get_decl_attributes_name}


{***********************************************}
{ diagnostic routines to write out active lists }
{***********************************************}


procedure Write_active_decl_attributes;
var
  decl_attributes_ptr: decl_attributes_ptr_type;
  index: integer;
begin
  index := 1;
  decl_attributes_ptr := active_decl_attributes_list;
  while decl_attributes_ptr <> nil do
    begin
      write(index: 1, ') ');
      writeln(Get_decl_attributes_name(decl_attributes_ptr));
      decl_attributes_ptr := decl_attributes_ptr^.next;
      index := index + 1;
    end;
end; {procedure Write_active_decl_attributes}


{****************************************}
{ routine to write out enumerated values }
{****************************************}


procedure Write_decl_attributes_kind(kind: decl_attributes_kind_type);
begin
  case kind of
    data_decl_attributes:
      write('data_decl_attributes');
    field_decl_attributes:
      write('field_decl_attributes');
    type_decl_attributes:
      write('type_decl_attributes');
  end; {case}
end; {procedure Write_decl_attributes_kind}


{****************************************}
{ miscillaneous decl attributes routines }
{****************************************}


procedure Dispose_decl_attributes_blocks(var decl_attributes_block_ptr:
  decl_attributes_block_ptr_type);
var
  temp: decl_attributes_block_ptr_type;
begin
  while decl_attributes_block_ptr <> nil do
    begin
      temp := decl_attributes_block_ptr;
      decl_attributes_block_ptr := decl_attributes_block_ptr^.next;
      dispose(temp);
    end;
end; {procedure Dispose_decl_attributes_blocks}


{***************************************}
{ dispose of all declaration attributes }
{ on both the free and active lists     }
{***************************************}


procedure Free_all_decl_attributes;
begin
  Dispose_decl_attributes_blocks(decl_attributes_block_list);
  decl_attributes_counter := 0;
  active_decl_attributes_list := nil;
  decl_attributes_free_list := nil;
  last_active_decl_attributes_ptr := nil;
end; {procedure Free_all_decl_attributes}


initialization
  {**************}
  { active lists }
  {**************}
  active_decl_attributes_list := nil;
  last_active_decl_attributes_ptr := nil;

  {************}
  { free lists }
  {************}
  decl_attributes_free_list := nil;

  {****************************}
  { block allocation variables }
  {****************************}
  decl_attributes_block_list := nil;
  decl_attributes_counter := 0;
end.
