unit stmt_attributes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           stmt_attributes             3d       }
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
  new_memory, decl_attributes;


type
  forward_stmt_ref_type = ptr_type;


  {********************************************************}
  { Attributes are created for each method call in order   }
  { to reflect the dynamic nesting context of parameters   }
  { and any other variables referenced inside of the call. }
  {********************************************************}
  stmt_attributes_ptr_type = ^stmt_attributes_type;
  stmt_attributes_type = record

    {*******************************}
    { links to active or free lists }
    {*******************************}
    prev, next: stmt_attributes_ptr_type;

    {***************************************************}
    { syntax tree statement which uses these attributes }
    {***************************************************}
    stmt_ref: forward_stmt_ref_type;

    {***********************************}
    { statement declaration atttributes }
    {***********************************}
    decl_attributes_ptr: decl_attributes_ptr_type;

    {******************************}
    { nesting level of method call }
    {******************************}
    dynamic_level: integer;
  end; {stmt_attributes_type}


var
  {****************************}
  { lists of active attributes }
  {****************************}
  active_stmt_attributes_list: stmt_attributes_ptr_type;


{***********************************}
{ routines for statement attributes }
{***********************************}
function New_stmt_attributes(decl_attributes_ptr: decl_attributes_ptr_type):
  stmt_attributes_ptr_type;
function Copy_stmt_attributes(stmt_attributes_ptr: stmt_attributes_ptr_type):
  stmt_attributes_ptr_type;
procedure Free_stmt_attributes(var stmt_attributes_ptr:
  stmt_attributes_ptr_type);

{********************************************}
{ miscillaneous statement attribute routines }
{********************************************}
procedure Free_all_stmt_attributes;


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
  stmt_attributes_block_ptr_type = ^stmt_attributes_block_type;
  stmt_attributes_block_type = record
    block: array[0..block_size] of stmt_attributes_type;
    next: stmt_attributes_block_ptr_type;
  end;


var
  {**************}
  { active lists }
  {**************}
  last_active_stmt_attributes_ptr: stmt_attributes_ptr_type;

  {************}
  { free lists }
  {************}
  stmt_attributes_free_list: stmt_attributes_ptr_type;

  {****************************}
  { block allocation variables }
  {****************************}
  stmt_attributes_block_list: stmt_attributes_block_ptr_type;
  stmt_attributes_counter: longint;


{***********************************}
{ routines for statement attributes }
{***********************************}


function New_stmt_attributes(decl_attributes_ptr: decl_attributes_ptr_type):
  stmt_attributes_ptr_type;
var
  stmt_attributes_ptr: stmt_attributes_ptr_type;
  stmt_attributes_block_ptr: stmt_attributes_block_ptr_type;
  index: integer;
begin
  {************************************}
  { get stmt attributes from free list }
  {************************************}
  if stmt_attributes_free_list <> nil then
    begin
      stmt_attributes_ptr := stmt_attributes_free_list;
      stmt_attributes_free_list := stmt_attributes_free_list^.next;
    end
  else
    begin
      index := stmt_attributes_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new stmt attributes block');
          new(stmt_attributes_block_ptr);
          stmt_attributes_block_ptr^.next := stmt_attributes_block_list;
          stmt_attributes_block_list := stmt_attributes_block_ptr;
        end;
      stmt_attributes_ptr := @stmt_attributes_block_list^.block[index];
      stmt_attributes_counter := stmt_attributes_counter + 1;
    end;

  {************************}
  { assign stmt attributes }
  {************************}
  stmt_attributes_ptr^.decl_attributes_ptr := decl_attributes_ptr;

  {****************************}
  { initialize stmt attributes }
  {****************************}
  with stmt_attributes_ptr^ do
    begin
      stmt_ref := nil;
      dynamic_level := 0;
    end; {with}

  {***************************}
  { add to end of active list }
  {***************************}
  if last_active_stmt_attributes_ptr <> nil then
    begin
      last_active_stmt_attributes_ptr^.next := stmt_attributes_ptr;
      stmt_attributes_ptr^.prev := last_active_stmt_attributes_ptr;
      last_active_stmt_attributes_ptr := stmt_attributes_ptr;
      stmt_attributes_ptr^.next := nil;
    end
  else
    begin
      active_stmt_attributes_list := stmt_attributes_ptr;
      last_active_stmt_attributes_ptr := stmt_attributes_ptr;
      stmt_attributes_ptr^.prev := nil;
      stmt_attributes_ptr^.next := nil;
    end;

  New_stmt_attributes := stmt_attributes_ptr;
end; {function New_stmt_attributes}


function Copy_stmt_attributes(stmt_attributes_ptr: stmt_attributes_ptr_type):
  stmt_attributes_ptr_type;
var
  copy_attributes_ptr: stmt_attributes_ptr_type;
  next, prev: stmt_attributes_ptr_type;
begin
  if stmt_attributes_ptr <> nil then
    begin
      copy_attributes_ptr :=
        New_stmt_attributes(stmt_attributes_ptr^.decl_attributes_ptr);

      {****************************************}
      { copy all fields except for link fields }
      {****************************************}
      next := copy_attributes_ptr^.next;
      prev := copy_attributes_ptr^.prev;
      copy_attributes_ptr^ := stmt_attributes_ptr^;
      copy_attributes_ptr^.next := next;
      copy_attributes_ptr^.prev := prev;
    end
  else
    copy_attributes_ptr := nil;

  Copy_stmt_attributes := copy_attributes_ptr;
end; {function Copy_stmt_attributes}


procedure Free_stmt_attributes(var stmt_attributes_ptr:
  stmt_attributes_ptr_type);
begin
  if stmt_attributes_ptr <> nil then
    begin
      {*******************************}
      { link neighbors in active list }
      {*******************************}
      if stmt_attributes_ptr^.prev <> nil then
        stmt_attributes_ptr^.prev^.next := stmt_attributes_ptr^.next
      else
        active_stmt_attributes_list := stmt_attributes_ptr^.next;

      if stmt_attributes_ptr^.next <> nil then
        stmt_attributes_ptr^.next^.prev := stmt_attributes_ptr^.prev
      else
        last_active_stmt_attributes_ptr := stmt_attributes_ptr^.prev;

      {**********************************}
      { reset stmt backpointer reference }
      {**********************************}
      stmt_attributes_ptr^.stmt_ref := nil;

      {**********************************}
      { add stmt attributes to free list }
      {**********************************}
      stmt_attributes_ptr^.prev := nil;
      stmt_attributes_ptr^.next := stmt_attributes_free_list;
      stmt_attributes_free_list := stmt_attributes_ptr;
      stmt_attributes_ptr := nil;
    end;
end; {procedure Free_stmt_attributes}


procedure Dispose_stmt_attributes(var stmt_attributes_ptr:
  stmt_attributes_ptr_type);
var
  temp: stmt_attributes_ptr_type;
begin
  while stmt_attributes_ptr <> nil do
    begin
      temp := stmt_attributes_ptr;
      stmt_attributes_ptr := stmt_attributes_ptr^.next;
      dispose(temp);
    end;
end; {procedure Dispose_stmt_attributes}


{********************************************}
{ miscillaneous statement attribute routines }
{********************************************}


procedure Dispose_stmt_attributes_blocks(var stmt_attributes_block_ptr:
  stmt_attributes_block_ptr_type);
var
  temp: stmt_attributes_block_ptr_type;
begin
  while stmt_attributes_block_ptr <> nil do
    begin
      temp := stmt_attributes_block_ptr;
      stmt_attributes_block_ptr := stmt_attributes_block_ptr^.next;
      dispose(temp);
    end;
end; {procedure Dispose_stmt_attributes_blocks}


{***************************************}
{ dispose of all declaration attributes }
{ on both the free and active lists     }
{***************************************}


procedure Free_all_stmt_attributes;
begin
  Dispose_stmt_attributes_blocks(stmt_attributes_block_list);

  stmt_attributes_counter := 0;
  active_stmt_attributes_list := nil;
  stmt_attributes_free_list := nil;
  last_active_stmt_attributes_ptr := nil;
end; {procedure Free_all_stmt_attributes}


initialization
  {**************}
  { active lists }
  {**************}
  active_stmt_attributes_list := nil;
  last_active_stmt_attributes_ptr := nil;

  {************}
  { free lists }
  {************}
  stmt_attributes_free_list := nil;

  {****************************}
  { block allocation variables }
  {****************************}
  stmt_attributes_block_list := nil;
  stmt_attributes_counter := 0;
end.
