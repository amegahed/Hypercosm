unit lit_attributes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           lit_attributes              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the attributes and which are       }
{       used to describe literal values used by the             }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  expr_attributes;


type
  literal_attributes_kind_type = (scalar_attributes, double_attributes,
    complex_attributes, vector_attributes);
  literal_attributes_ptr_type = ^literal_attributes_type;
  literal_attributes_type = record

    {*******************************}
    { links to active or free lists }
    {*******************************}
    prev, next: literal_attributes_ptr_type;

    {****************************************************}
    { syntax tree expression which uses these attributes }
    {****************************************************}
    expr_ref: forward_expr_ref_type;

    case kind: literal_attributes_kind_type of
      scalar_attributes: (
        scalar_decimal_places: integer;
        scalar_exponential_notation: boolean;
        );

      double_attributes: (
        double_decimal_places: integer;
        double_exponential_notation: boolean;
        );

      complex_attributes: (
        a_decimal_places: integer;
        b_decimal_places: integer;
        a_exponential_notation: boolean;
        b_exponential_notation: boolean;
        );

      vector_attributes: (
        x_decimal_places: integer;
        y_decimal_places: integer;
        z_decimal_places: integer;
        x_exponential_notation: boolean;
        y_exponential_notation: boolean;
        z_exponential_notation: boolean;
        );
  end; {literal_attributes_type}


var
  {****************************}
  { lists of active attributes }
  {****************************}
  active_literal_attributes_list: literal_attributes_ptr_type;


{*********************************}
{ routines for literal attributes }
{*********************************}
function New_literal_attributes(kind: literal_attributes_kind_type):
  literal_attributes_ptr_type;
function Copy_literal_attributes(literal_attributes_ptr:
  literal_attributes_ptr_type): literal_attributes_ptr_type;
procedure Free_literal_attributes(var literal_attributes_ptr:
  literal_attributes_ptr_type);

{****************************************}
{ routine to write out enumerated values }
{****************************************}
procedure Write_literal_attributes_kind(kind: literal_attributes_kind_type);

{******************************************}
{ miscillaneous literal attribute routines }
{******************************************}
procedure Free_all_literal_attributes;


implementation
uses
  errors, new_memory;


const
  block_size = 512;
  memory_alert = false;


type
  {************************}
  { block allocation types }
  {************************}
  literal_attributes_block_ptr_type = ^literal_attributes_block_type;
  literal_attributes_block_type = record
    block: array[0..block_size] of literal_attributes_type;
    next: literal_attributes_block_ptr_type;
  end;


var
  {**************}
  { active lists }
  {**************}
  last_active_literal_attributes_ptr: literal_attributes_ptr_type;

  {************}
  { free lists }
  {************}
  literal_attributes_free_list: literal_attributes_ptr_type;

  {****************************}
  { block allocation variables }
  {****************************}
  literal_attributes_block_list: literal_attributes_block_ptr_type;
  literal_attributes_counter: longint;


{*********************************}
{ routines for literal attributes }
{*********************************}


procedure Init_literal_attributes(kind: literal_attributes_kind_type;
  literal_attributes_ptr: literal_attributes_ptr_type);
begin
  literal_attributes_ptr^.kind := kind;
  with literal_attributes_ptr^ do
    case kind of

      scalar_attributes:
        begin
          scalar_decimal_places := 0;
          scalar_exponential_notation := false;
        end;

      double_attributes:
        begin
          double_decimal_places := 0;
          double_exponential_notation := false;
        end;

      complex_attributes:
        begin
          a_decimal_places := 0;
          b_decimal_places := 0;
          a_exponential_notation := false;
          b_exponential_notation := false;
        end;

      vector_attributes:
        begin
          x_decimal_places := 0;
          y_decimal_places := 0;
          z_decimal_places := 0;
          x_exponential_notation := false;
          y_exponential_notation := false;
          z_exponential_notation := false;
        end;

    end; {case}
end; {procedure Init_literal_attributes}


function New_literal_attributes(kind: literal_attributes_kind_type):
  literal_attributes_ptr_type;
var
  literal_attributes_ptr: literal_attributes_ptr_type;
  literal_attributes_block_ptr: literal_attributes_block_ptr_type;
  index: integer;
begin
  {***************************************}
  { get literal attributes from free list }
  {***************************************}
  if literal_attributes_free_list <> nil then
    begin
      literal_attributes_ptr := literal_attributes_free_list;
      literal_attributes_free_list := literal_attributes_free_list^.next;
    end
  else
    begin
      index := literal_attributes_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new literal attributes block');
          new(literal_attributes_block_ptr);
          literal_attributes_block_ptr^.next := literal_attributes_block_list;
          literal_attributes_block_list := literal_attributes_block_ptr;
        end;
      literal_attributes_ptr := @literal_attributes_block_list^.block[index];
      literal_attributes_counter := literal_attributes_counter + 1;
    end;

  {*******************************}
  { initialize literal attributes }
  {*******************************}
  Init_literal_attributes(kind, literal_attributes_ptr);

  {***************************}
  { add to end of active list }
  {***************************}
  if last_active_literal_attributes_ptr <> nil then
    begin
      last_active_literal_attributes_ptr^.next := literal_attributes_ptr;
      literal_attributes_ptr^.prev := last_active_literal_attributes_ptr;
      last_active_literal_attributes_ptr := literal_attributes_ptr;
      literal_attributes_ptr^.next := nil;
    end
  else
    begin
      active_literal_attributes_list := literal_attributes_ptr;
      last_active_literal_attributes_ptr := literal_attributes_ptr;
      literal_attributes_ptr^.prev := nil;
      literal_attributes_ptr^.next := nil;
    end;

  New_literal_attributes := literal_attributes_ptr;
end; {function New_literal_attributes}


function Copy_literal_attributes(literal_attributes_ptr:
  literal_attributes_ptr_type): literal_attributes_ptr_type;
var
  copy_attributes_ptr: literal_attributes_ptr_type;
  next: literal_attributes_ptr_type;
begin
  if literal_attributes_ptr <> nil then
    begin
      copy_attributes_ptr :=
        New_literal_attributes(literal_attributes_ptr^.kind);

      {****************************************}
      { copy all fields except for link fields }
      {****************************************}
      next := copy_attributes_ptr^.next;
      copy_attributes_ptr^ := literal_attributes_ptr^;
      copy_attributes_ptr^.next := next;
    end
  else
    copy_attributes_ptr := nil;

  Copy_literal_attributes := copy_attributes_ptr;
end; {function Copy_literal_attributes}


procedure Free_literal_attributes(var literal_attributes_ptr:
  literal_attributes_ptr_type);
begin
  if literal_attributes_ptr <> nil then
    begin
      {*************************************}
      { add literal attributes to free list }
      {*************************************}
      literal_attributes_ptr^.next := literal_attributes_free_list;
      literal_attributes_free_list := literal_attributes_ptr;
      literal_attributes_ptr := nil;
    end;
end; {procedure Free_literal_attributes}


procedure Dispose_literal_attributes(var literal_attributes_ptr:
  literal_attributes_ptr_type);
var
  temp: literal_attributes_ptr_type;
begin
  while literal_attributes_ptr <> nil do
    begin
      temp := literal_attributes_ptr;
      literal_attributes_ptr := literal_attributes_ptr^.next;
      dispose(temp);
    end;
end; {procedure Dispose_literal_attributes}


{****************************************}
{ routine to write out enumerated values }
{****************************************}


procedure Write_literal_attributes_kind(kind: literal_attributes_kind_type);
begin
  case kind of
    scalar_attributes:
      write('scalar_attributes');
    double_attributes:
      write('double_attributes');
    complex_attributes:
      write('complex_attributes');
    vector_attributes:
      write('vector_attributes');
  end; {case}
end; {procedure Write_literal_attributes_kind}


{******************************************}
{ miscillaneous literal attribute routines }
{******************************************}


procedure Dispose_literal_attributes_blocks(var literal_attributes_block_ptr:
  literal_attributes_block_ptr_type);
var
  temp: literal_attributes_block_ptr_type;
begin
  while literal_attributes_block_ptr <> nil do
    begin
      temp := literal_attributes_block_ptr;
      literal_attributes_block_ptr := literal_attributes_block_ptr^.next;
      dispose(temp);
    end;
end; {procedure Dispose_literal_attributes_blocks}


{**************************************}
{ dispose of all expression attributes }
{ on both the free and active lists    }
{**************************************}


procedure Free_all_literal_attributes;
begin
  Dispose_literal_attributes_blocks(literal_attributes_block_list);

  literal_attributes_counter := 0;
  active_literal_attributes_list := nil;
  literal_attributes_free_list := nil;
  last_active_literal_attributes_ptr := nil;
end; {procedure Free_all_literal_attributes}


initialization
  {**************}
  { active lists }
  {**************}
  active_literal_attributes_list := nil;
  last_active_literal_attributes_ptr := nil;

  {************}
  { free lists }
  {************}
  literal_attributes_free_list := nil;

  {****************************}
  { block allocation variables }
  {****************************}
  literal_attributes_block_list := nil;
  literal_attributes_counter := 0;
end.
