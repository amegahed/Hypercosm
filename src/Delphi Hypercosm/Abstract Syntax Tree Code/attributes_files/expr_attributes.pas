unit expr_attributes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           expr_attributes             3d       }
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
  strings, new_memory, hashtables, symbol_tables, type_attributes,
  decl_attributes;


type
  forward_expr_ref_type = ptr_type;


  {******************************************************}
  { Attributes are also created for each instance of a   }
  { variable. The attributes reflect the context where   }
  { the reference to the variable occurs in the program. }
  {******************************************************}
  expr_attributes_kind_type = (variable_attributes_kind, value_attributes_kind);


  expr_attributes_ptr_type = ^expr_attributes_type;
  expr_attributes_type = record

    {*******************************}
    { links to active or free lists }
    {*******************************}
    prev, next: expr_attributes_ptr_type;

    {****************************************************}
    { syntax tree expression which uses these attributes }
    {****************************************************}
    expr_ref: forward_expr_ref_type;
    alias_type_attributes_ptr, type_attributes_ptr: type_attributes_ptr_type;
    decl_attributes_ptr: decl_attributes_ptr_type;

    {******************************************************}
    {                    array attributes                  }
    {******************************************************}
    { if dimensions > 0, then we have an array. If the     }
    { number of dimensions = the number of dimensions      }
    { in the type attributes field, then we are dealing w/ }
    { a complete array with its own dope vector and memory }
    { allocation.  If the number of dimensions is less     }
    { than the number listed in the attributes field, then }
    { we are dealing with a portion of an array. A sub     }
    { array may be copied to or from but may not be        }
    { assigned to another array because that would violate }
    { the memory layout that is used for its parent array. }
    {******************************************************}
    dimensions: integer; { dimensions of array inst }

    case kind: expr_attributes_kind_type of

      variable_attributes_kind: (

        {********************}
        { scoping attributes }
        {********************}
        explicit_static, explicit_global, explicit_member: boolean;
        );

      value_attributes_kind: (
        );
  end; {expr_attributes_type}


var
  {****************************}
  { lists of active attributes }
  {****************************}
  active_expr_attributes_list: expr_attributes_ptr_type;


{************************************}
{ routines for expression attributes }
{************************************}
function New_variable_expr_attributes(decl_attributes_ptr:
  decl_attributes_ptr_type): expr_attributes_ptr_type;
function New_value_expr_attributes(type_attributes_ptr:
  type_attributes_ptr_type): expr_attributes_ptr_type;
function Copy_expr_attributes(expr_attributes_ptr: expr_attributes_ptr_type):
  expr_attributes_ptr_type;
procedure Free_expr_attributes(var expr_attributes_ptr:
  expr_attributes_ptr_type);

{********************************************}
{ routines to retreive names from attributes }
{********************************************}
function Get_expr_attributes_name(expr_attributes_ptr:
  expr_attributes_ptr_type): string_type;

{***********************************************}
{ diagnostic routines to write out active lists }
{***********************************************}
procedure Write_active_expr_attributes;

{****************************************}
{ routine to write out enumerated values }
{****************************************}
procedure Write_expr_attributes_kind(kind: expr_attributes_kind_type);

{*********************************************}
{ miscillaneous expression attribute routines }
{*********************************************}
procedure Free_all_expr_attributes;


implementation
uses
  errors;


const
  block_size = 512;
  memory_alert = false;


type
  {************************}
  { block allocation types }
  {************************}
  expr_attributes_block_ptr_type = ^expr_attributes_block_type;
  expr_attributes_block_type = record
    block: array[0..block_size] of expr_attributes_type;
    next: expr_attributes_block_ptr_type;
  end;


var
  {**************}
  { active lists }
  {**************}
  last_active_expr_attributes_ptr: expr_attributes_ptr_type;

  {************}
  { free lists }
  {************}
  expr_attributes_free_list: expr_attributes_ptr_type;

  {****************************}
  { block allocation variables }
  {****************************}
  expr_attributes_block_list: expr_attributes_block_ptr_type;
  expr_attributes_counter: longint;


{************************************}
{ routines for expression attributes }
{************************************}


procedure Init_expr_attributes(kind: expr_attributes_kind_type;
  expr_attributes_ptr: expr_attributes_ptr_type);
begin
  expr_attributes_ptr^.kind := kind;
  with expr_attributes_ptr^ do
    begin
      {**********************************}
      { initialize expression attributes }
      {**********************************}
      expr_ref := nil;
      alias_type_attributes_ptr := nil;
      type_attributes_ptr := nil;
      decl_attributes_ptr := nil;
      dimensions := 0;

      case kind of

        variable_attributes_kind:
          begin
            {*******************************}
            { initialize scoping attributes }
            {*******************************}
            explicit_static := false;
            explicit_global := false;
            explicit_member := false;
          end;

        value_attributes_kind:
          begin
          end;

      end; {case}
    end; {with}
end; {procedure Init_expr_attributes}


function New_expr_attributes(kind: expr_attributes_kind_type):
  expr_attributes_ptr_type;
var
  expr_attributes_ptr: expr_attributes_ptr_type;
  expr_attributes_block_ptr: expr_attributes_block_ptr_type;
  index: integer;
begin
  {************************************}
  { get expr attributes from free list }
  {************************************}
  if expr_attributes_free_list <> nil then
    begin
      expr_attributes_ptr := expr_attributes_free_list;
      expr_attributes_free_list := expr_attributes_free_list^.next;
    end
  else
    begin
      index := expr_attributes_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new expr attributes block');
          new(expr_attributes_block_ptr);
          expr_attributes_block_ptr^.next := expr_attributes_block_list;
          expr_attributes_block_list := expr_attributes_block_ptr;
        end;
      expr_attributes_ptr := @expr_attributes_block_list^.block[index];
      expr_attributes_counter := expr_attributes_counter + 1;
    end;

  {**********************************}
  { initialize expression attributes }
  {**********************************}
  Init_expr_attributes(kind, expr_attributes_ptr);

  {***************************}
  { add to end of active list }
  {***************************}
  if last_active_expr_attributes_ptr <> nil then
    begin
      last_active_expr_attributes_ptr^.next := expr_attributes_ptr;
      expr_attributes_ptr^.prev := last_active_expr_attributes_ptr;
      last_active_expr_attributes_ptr := expr_attributes_ptr;
      expr_attributes_ptr^.next := nil;
    end
  else
    begin
      active_expr_attributes_list := expr_attributes_ptr;
      last_active_expr_attributes_ptr := expr_attributes_ptr;
      expr_attributes_ptr^.prev := nil;
      expr_attributes_ptr^.next := nil;
    end;

  New_expr_attributes := expr_attributes_ptr;
end; {function New_expr_attributes}


function New_variable_expr_attributes(decl_attributes_ptr:
  decl_attributes_ptr_type): expr_attributes_ptr_type;
var
  expr_attributes_ptr: expr_attributes_ptr_type;
  type_attributes_ptr: type_attributes_ptr_type;
begin
  expr_attributes_ptr := New_expr_attributes(variable_attributes_kind);
  type_attributes_ptr := decl_attributes_ptr^.type_attributes_ptr;

  {********************************************************}
  { assign declaration attributes to expression attributes }
  {********************************************************}
  expr_attributes_ptr^.decl_attributes_ptr := decl_attributes_ptr;
  expr_attributes_ptr^.alias_type_attributes_ptr := type_attributes_ptr;
  expr_attributes_ptr^.type_attributes_ptr :=
    Unalias_type_attributes(type_attributes_ptr);
  expr_attributes_ptr^.dimensions := Get_data_abs_dims(type_attributes_ptr);

  {*******************}
  { touch declaration }
  {*******************}
  decl_attributes_ptr^.used := true;

  New_variable_expr_attributes := expr_attributes_ptr;
end; {function New_variable_expr_attributes}


function New_value_expr_attributes(type_attributes_ptr:
  type_attributes_ptr_type): expr_attributes_ptr_type;
var
  expr_attributes_ptr: expr_attributes_ptr_type;
begin
  expr_attributes_ptr := New_expr_attributes(value_attributes_kind);

  {******************************}
  { assign expression attributes }
  {******************************}
  expr_attributes_ptr^.alias_type_attributes_ptr := type_attributes_ptr;
  expr_attributes_ptr^.type_attributes_ptr :=
    Unalias_type_attributes(type_attributes_ptr);
  expr_attributes_ptr^.dimensions := Get_data_abs_dims(type_attributes_ptr);

  New_value_expr_attributes := expr_attributes_ptr;
end; {function New_value_expr_attributes}


function Copy_expr_attributes(expr_attributes_ptr: expr_attributes_ptr_type):
  expr_attributes_ptr_type;
var
  copy_attributes_ptr: expr_attributes_ptr_type;
  next, prev: expr_attributes_ptr_type;
begin
  if expr_attributes_ptr <> nil then
    begin
      copy_attributes_ptr := New_expr_attributes(expr_attributes_ptr^.kind);

      {****************************************}
      { copy all fields except for link fields }
      {****************************************}
      next := copy_attributes_ptr^.next;
      prev := copy_attributes_ptr^.prev;
      copy_attributes_ptr^ := expr_attributes_ptr^;
      copy_attributes_ptr^.next := next;
      copy_attributes_ptr^.prev := prev;
    end
  else
    copy_attributes_ptr := nil;

  Copy_expr_attributes := copy_attributes_ptr;
end; {function Copy_expr_attributes}


procedure Free_expr_attributes(var expr_attributes_ptr:
  expr_attributes_ptr_type);
begin
  if expr_attributes_ptr <> nil then
    begin
      {*******************************}
      { link neighbors in active list }
      {*******************************}
      if expr_attributes_ptr^.prev <> nil then
        expr_attributes_ptr^.prev^.next := expr_attributes_ptr^.next
      else
        active_expr_attributes_list := expr_attributes_ptr^.next;

      if expr_attributes_ptr^.next <> nil then
        expr_attributes_ptr^.next^.prev := expr_attributes_ptr^.prev
      else
        last_active_expr_attributes_ptr := expr_attributes_ptr^.prev;

      {**********************************}
      { reset expr backpointer reference }
      {**********************************}
      expr_attributes_ptr^.expr_ref := nil;

      {**********************************}
      { add expr attributes to free list }
      {**********************************}
      expr_attributes_ptr^.prev := nil;
      expr_attributes_ptr^.next := expr_attributes_free_list;
      expr_attributes_free_list := expr_attributes_ptr;
      expr_attributes_ptr := nil;
    end;
end; {procedure Free_expr_attributes}


procedure Dispose_expr_attributes(var expr_attributes_ptr:
  expr_attributes_ptr_type);
var
  temp: expr_attributes_ptr_type;
begin
  while expr_attributes_ptr <> nil do
    begin
      temp := expr_attributes_ptr;
      expr_attributes_ptr := expr_attributes_ptr^.next;
      dispose(temp);
    end;
end; {procedure Dispose_expr_attributes}


{********************************************}
{ routines to retreive names from attributes }
{********************************************}


function Get_expr_attributes_name(expr_attributes_ptr:
  expr_attributes_ptr_type): string_type;
begin
  if expr_attributes_ptr <> nil then
    case expr_attributes_ptr^.kind of

      value_attributes_kind:
        Get_expr_attributes_name :=
          Get_type_attributes_name(expr_attributes_ptr^.type_attributes_ptr);

      variable_attributes_kind:
        Get_expr_attributes_name :=
          Get_decl_attributes_name(expr_attributes_ptr^.decl_attributes_ptr);

    end
  else
    Get_expr_attributes_name := '?';
end; {function Get_expr_attributes_name}


{***********************************************}
{ diagnostic routines to write out active lists }
{***********************************************}


procedure Write_active_expr_attributes;
var
  expr_attributes_ptr: expr_attributes_ptr_type;
  index: integer;
begin
  index := 1;
  expr_attributes_ptr := active_expr_attributes_list;
  while expr_attributes_ptr <> nil do
    begin
      if expr_attributes_ptr^.decl_attributes_ptr <> nil then
        begin
          write(index: 1, ') ');
          writeln(Get_expr_attributes_name(expr_attributes_ptr));
        end;
      expr_attributes_ptr := expr_attributes_ptr^.next;
      index := index + 1;
    end;
end; {procedure Write_active_expr_attributes}


{****************************************}
{ routine to write out enumerated values }
{****************************************}


procedure Write_expr_attributes_kind(kind: expr_attributes_kind_type);
begin
  case kind of
    variable_attributes_kind:
      write('variable_attributes');
    value_attributes_kind:
      write('value_attributes');
  end; {case}
end; {procedure Write_expr_attributes_kind}


{*********************************************}
{ miscillaneous expression attribute routines }
{*********************************************}


procedure Dispose_expr_attributes_blocks(var expr_attributes_block_ptr:
  expr_attributes_block_ptr_type);
var
  temp: expr_attributes_block_ptr_type;
begin
  while expr_attributes_block_ptr <> nil do
    begin
      temp := expr_attributes_block_ptr;
      expr_attributes_block_ptr := expr_attributes_block_ptr^.next;
      dispose(temp);
    end;
end; {procedure Dispose_expr_attributes_blocks}


{**************************************}
{ dispose of all expression attributes }
{ on both the free and active lists    }
{**************************************}


procedure Free_all_expr_attributes;
begin
  Dispose_expr_attributes_blocks(expr_attributes_block_list);

  expr_attributes_counter := 0;
  active_expr_attributes_list := nil;
  expr_attributes_free_list := nil;
  last_active_expr_attributes_ptr := nil;
end; {procedure Free_all_expr_attributes}


initialization
  {**************}
  { active lists }
  {**************}
  active_expr_attributes_list := nil;
  last_active_expr_attributes_ptr := nil;

  {************}
  { free lists }
  {************}
  expr_attributes_free_list := nil;

  {****************************}
  { block allocation variables }
  {****************************}
  expr_attributes_block_list := nil;
  expr_attributes_counter := 0;
end.
