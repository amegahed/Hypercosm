unit type_attributes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           type_attributes             3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the attributes and descriptors     }
{       of data types which are used by the interpreter.        }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, symbol_tables, code_attributes;


type
  type_kind_type = (

    {*************************}
    { uninitialized data type }
    {*************************}
    type_error,

    {****************************}
    { primitive enumerated types }
    {****************************}
    type_boolean, type_char,

    {**************************}
    { primitive integral types }
    {**************************}
    type_byte, type_short, type_integer, type_long,

    {************************}
    { primitive scalar types }
    {************************}
    type_scalar, type_double, type_complex, type_vector,

    {********************}
    { user defined types }
    {********************}
    type_enum, type_alias, type_array, type_struct, type_class,
    type_class_alias,

    {*************************}
    { user defined code types }
    {*************************}
    type_code,

    {***************************}
    { references to other types }
    {***************************}
    type_reference);


  {*******************************************************}
  { The type attributes is an internal representation of  }
  { the type of a variable. This includes the size of the }
  { variable in memory and for complex types, the fields  }
  { or local variables and other related information.     }
  {*******************************************************}
  type_attributes_ptr_type = ^type_attributes_type;
  type_attributes_ref_ptr_type = ^type_attributes_ref_type;


  type_attributes_ref_type = record
    type_attributes_ptr: type_attributes_ptr_type;
    next: type_attributes_ref_ptr_type;
  end; {type_attributes_ref_type}


  type_attributes_type = record
    id_ptr: id_ptr_type;
    next: type_attributes_ptr_type;

    {*************************************}
    { compile time allocation information }
    {*************************************}
    static: boolean;
    size: integer;

    case kind: type_kind_type of

      {**********************}
      { primitive data types }
      {**********************}
      type_error,

      {****************************}
      { primitive enumerated types }
      {****************************}
      type_boolean, type_char,

      {**************************}
      { primitive integral types }
      {**************************}
      type_byte, type_short, type_integer, type_long,

      {************************}
      { primitive scalar types }
      {************************}
      type_scalar, type_double, type_complex, type_vector: (
        );

      {*************************}
      { user defined data types }
      {*************************}
      type_enum: (
        enum_table_ptr: symbol_table_ptr_type;
        );
      type_alias: (
        alias_type_attributes_ptr: type_attributes_ptr_type;
        );
      type_array: (
        {******************************}
        { relative sub array type info }
        {  (relative to element type)  }
        {******************************}
        relative_dimensions: integer;
        element_type_attributes_ptr: type_attributes_ptr_type;

        {******************************}
        { absolute sum array type info }
        {    (relative to base type)   }
        {******************************}
        absolute_dimensions: integer;
        base_type_attributes_ptr: type_attributes_ptr_type;
        );
      type_struct: (
        field_table_ptr: symbol_table_ptr_type
        );
      type_class, type_class_alias: (
        parent_type_attributes_ptr: type_attributes_ptr_type;
        interface_type_attributes_ptr: type_attributes_ref_ptr_type;
        class_alias_type_attributes_ptr: type_attributes_ptr_type;

        public_table_ptr: symbol_table_ptr_type;
        private_table_ptr: symbol_table_ptr_type;
        protected_table_ptr: symbol_table_ptr_type;
        );
      type_code: (
        code_attributes_ptr: code_attributes_ptr_type;
        );
      type_reference: (
        reference_type_attributes_ptr: type_attributes_ptr_type;
        );
  end; {type_attributes_type}


type
  type_kind_set_type = set of type_kind_type;


var
  {********************}
  { sets of type kinds }
  {********************}
  primitive_type_kinds, enum_type_kinds: type_kind_set_type;
  integer_type_kinds, scalar_type_kinds, math_type_kinds: type_kind_set_type;
  structured_type_kinds, class_type_kinds: type_kind_set_type;
  reference_type_kinds, complex_type_kinds: type_kind_set_type;


{*******************************************}
{ routines for allocating and freeing types }
{*******************************************}
function New_type_attributes(kind: type_kind_type;
  static: boolean): type_attributes_ptr_type;
procedure Free_type_attributes(var type_attributes_ptr:
  type_attributes_ptr_type);

{*********************************************************}
{ routines for allocating and freeing references to types }
{*********************************************************}
function New_type_attributes_ref(type_attributes_ptr: type_attributes_ptr_type):
  type_attributes_ref_ptr_type;
procedure Free_type_attributes_ref(var type_attributes_ref_ptr:
  type_attributes_ref_ptr_type);

{*********************************}
{ routines to create type aliases }
{*********************************}
function New_alias_type_attributes(type_attributes_ptr:
  type_attributes_ptr_type): type_attributes_ptr_type;
function Unalias_type_attributes(type_attributes_ptr: type_attributes_ptr_type):
  type_attributes_ptr_type;

{*************************************}
{ routines for creating derived types }
{*************************************}
function New_reference_type_attributes(type_attributes_ptr:
  type_attributes_ptr_type): type_attributes_ptr_type;
function Deref_type_attributes(type_attributes_ptr: type_attributes_ptr_type):
  type_attributes_ptr_type;

{*****************************}
{ array dimensioning routines }
{*****************************}
procedure Dim_type_attributes(var type_attributes_ptr: type_attributes_ptr_type;
  dimensions: integer);
procedure Dim_base_type_attributes(var type_attributes_ptr:
  type_attributes_ptr_type;
  dimensions: integer);
function Base_type_attributes(type_attributes_ptr: type_attributes_ptr_type):
  type_attributes_ptr_type;

{*************************}
{ array querying routines }
{*************************}
function Get_data_abs_dims(type_attributes_ptr: type_attributes_ptr_type):
  integer;
function Get_data_rel_dims(type_attributes_ptr: type_attributes_ptr_type):
  integer;

{****************************************************************}
{ routine to query data type for its declared name or properties }
{****************************************************************}
function Get_type_attributes_name(type_attributes_ptr:
  type_attributes_ptr_type): string_type;

{**************************************}
{ routines to write miscillaneous info }
{**************************************}
procedure Write_type_kind(kind: type_kind_type);
procedure Write_type_attributes(type_attributes_ptr: type_attributes_ptr_type);

{****************************************}
{ miscillaneous type attributes routines }
{****************************************}
procedure Free_all_type_attributes;


implementation
uses
  errors, new_memory, code_types;


const
  block_size = 512;
  memory_alert = false;


type
  {************************}
  { block allocation types }
  {************************}
  type_attributes_block_ptr_type = ^type_attributes_block_type;
  type_attributes_block_type = record
    block: array[0..block_size] of type_attributes_type;
    next: type_attributes_block_ptr_type;
  end;

  type_attributes_ref_block_ptr_type = ^type_attributes_ref_block_type;
  type_attributes_ref_block_type = record
    block: array[0..block_size] of type_attributes_ref_type;
    next: type_attributes_ref_block_ptr_type;
  end;


var
  {************}
  { free lists }
  {************}
  type_attributes_free_list: type_attributes_ptr_type;
  type_attributes_ref_free_list: type_attributes_ref_ptr_type;

  {****************************}
  { block allocation variables }
  {****************************}
  type_attributes_block_list: type_attributes_block_ptr_type;
  type_attributes_ref_block_list: type_attributes_ref_block_ptr_type;

  type_attributes_counter: longint;
  type_attributes_ref_counter: longint;


procedure Init_data_sets;
begin
  primitive_type_kinds := [type_boolean..type_vector];
  enum_type_kinds := [type_boolean, type_char, type_enum];

  integer_type_kinds := [type_byte..type_long];
  scalar_type_kinds := [type_scalar, type_double, type_complex, type_vector];
  math_type_kinds := integer_type_kinds + scalar_type_kinds;

  structured_type_kinds := [type_struct, type_class];
  class_type_kinds := [type_class, type_class_alias];

  reference_type_kinds := [type_array, type_struct, type_class];
  complex_type_kinds := [type_enum..type_code];
end; {procedure Init_data_sets}


{*******************************************}
{ routines for allocating and freeing types }
{*******************************************}


function New_type_attributes(kind: type_kind_type;
  static: boolean): type_attributes_ptr_type;
var
  type_attributes_ptr: type_attributes_ptr_type;
  type_attributes_block_ptr: type_attributes_block_ptr_type;
  index: integer;
begin
  if kind <> type_error then
    begin
      {************************************}
      { get type attributes from free list }
      {************************************}
      if type_attributes_free_list <> nil then
        begin
          type_attributes_ptr := type_attributes_free_list;
          type_attributes_free_list := type_attributes_free_list^.next;
        end
      else
        begin
          index := type_attributes_counter mod block_size;
          if (index = 0) then
            begin
              if memory_alert then
                writeln('allocating new type attributes block');
              new(type_attributes_block_ptr);
              type_attributes_block_ptr^.next := type_attributes_block_list;
              type_attributes_block_list := type_attributes_block_ptr;
            end;
          type_attributes_ptr := @type_attributes_block_list^.block[index];
          type_attributes_counter := type_attributes_counter + 1;
        end;

      {****************************}
      { initialize type attributes }
      {****************************}
      type_attributes_ptr^.id_ptr := nil;
      type_attributes_ptr^.kind := kind;
      type_attributes_ptr^.next := nil;

      {************************************************}
      { initialize compile time allocation information }
      {************************************************}
      type_attributes_ptr^.static := static;

      {************************************************}
      { initialize compile time auxilliary information }
      {************************************************}
      with type_attributes_ptr^ do
        begin
          {***********************}
          { initialize size field }
          {***********************}
          if kind in [type_complex, type_vector, type_code, type_reference] then
            case kind of
              type_complex, type_code, type_reference:
                size := 2;
              type_vector:
                size := 3;
            end
          else
            size := 1;

          {*************************}
          { initialize other fields }
          {*************************}
          if kind in [type_enum, type_alias, type_array, type_struct,
            type_class, type_class_alias] then
            case kind of

              type_enum:
                enum_table_ptr := nil;

              type_alias:
                alias_type_attributes_ptr := nil;

              type_array:
                begin
                  element_type_attributes_ptr := nil;
                  relative_dimensions := 1;
                  absolute_dimensions := 1;
                end;

              type_struct:
                field_table_ptr := nil;

              type_class, type_class_alias:
                begin
                  parent_type_attributes_ptr := nil;
                  interface_type_attributes_ptr := nil;
                  class_alias_type_attributes_ptr := nil;
                  public_table_ptr := nil;
                  private_table_ptr := nil;
                  protected_table_ptr := nil;
                end;

            end; {case}
        end;
    end
  else
    type_attributes_ptr := nil;

  New_type_attributes := type_attributes_ptr;
end; {function New_type_attributes}


procedure Free_type_attributes(var type_attributes_ptr:
  type_attributes_ptr_type);
begin
  {**********************************}
  { add type attributes to free list }
  {**********************************}
  type_attributes_ptr^.next := type_attributes_free_list;
  type_attributes_free_list := type_attributes_ptr;
  type_attributes_ptr := nil;
end; {procedure Free_type_attributes}


{*********************************************************}
{ routines for allocating and freeing references to types }
{*********************************************************}


function New_type_attributes_ref(type_attributes_ptr: type_attributes_ptr_type):
  type_attributes_ref_ptr_type;
var
  type_attributes_ref_ptr: type_attributes_ref_ptr_type;
  type_attributes_ref_block_ptr: type_attributes_ref_block_ptr_type;
  index: integer;
begin
  {****************************************}
  { get type attributes ref from free list }
  {****************************************}
  if type_attributes_ref_free_list <> nil then
    begin
      type_attributes_ref_ptr := type_attributes_ref_free_list;
      type_attributes_ref_free_list := type_attributes_ref_free_list^.next;
    end
  else
    begin
      index := type_attributes_ref_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new type attributes ref block');
          new(type_attributes_ref_block_ptr);
          type_attributes_ref_block_ptr^.next := type_attributes_ref_block_list;
          type_attributes_ref_block_list := type_attributes_ref_block_ptr;
        end;
      type_attributes_ref_ptr := @type_attributes_ref_block_list^.block[index];
      type_attributes_ref_counter := type_attributes_ref_counter + 1;
    end;

  {********************************}
  { initialize type attributes ref }
  {********************************}
  type_attributes_ref_ptr^.type_attributes_ptr := type_attributes_ptr;
  type_attributes_ref_ptr^.next := nil;

  New_type_attributes_ref := type_attributes_ref_ptr;
end; {function New_type_attributes_ref}


procedure Free_type_attributes_ref(var type_attributes_ref_ptr:
  type_attributes_ref_ptr_type);
begin
  {**************************************}
  { add type attributes ref to free list }
  {**************************************}
  type_attributes_ref_ptr^.next := type_attributes_ref_free_list;
  type_attributes_ref_free_list := type_attributes_ref_ptr;
  type_attributes_ref_ptr := nil;
end; {procedure Free_type_attributes_ref}


{************************************}
{ routines for creating type aliases }
{************************************}


function New_alias_type_attributes(type_attributes_ptr:
  type_attributes_ptr_type): type_attributes_ptr_type;
var
  alias_type_attributes_ptr: type_attributes_ptr_type;
begin
  alias_type_attributes_ptr := New_type_attributes(type_alias,
    type_attributes_ptr^.static);
  alias_type_attributes_ptr^.size := type_attributes_ptr^.size;
  alias_type_attributes_ptr^.alias_type_attributes_ptr := type_attributes_ptr;

  New_alias_type_attributes := alias_type_attributes_ptr;
end; {function New_alias_type_attributes}


function Unalias_type_attributes(type_attributes_ptr: type_attributes_ptr_type):
  type_attributes_ptr_type;
var
  done: boolean;
begin
  done := false;
  while not done do
    begin
      if type_attributes_ptr <> nil then
        if type_attributes_ptr^.kind in [type_alias, type_class_alias] then
          case type_attributes_ptr^.kind of

            type_alias:
              type_attributes_ptr :=
                type_attributes_ptr^.alias_type_attributes_ptr;

            type_class_alias:
              type_attributes_ptr :=
                type_attributes_ptr^.class_alias_type_attributes_ptr;

          end {case}
        else
          done := true
      else
        done := true;
    end;

  Unalias_type_attributes := type_attributes_ptr;
end; {function Unalias_type_attributes}


{*************************************}
{ routines for creating derived types }
{*************************************}


function New_reference_type_attributes(type_attributes_ptr:
  type_attributes_ptr_type): type_attributes_ptr_type;
var
  reference_type_attributes_ptr: type_attributes_ptr_type;
begin
  reference_type_attributes_ptr := New_type_attributes(type_reference, false);
  reference_type_attributes_ptr^.reference_type_attributes_ptr :=
    type_attributes_ptr;

  New_reference_type_attributes := reference_type_attributes_ptr;
end; {function New_reference_type_attributes}


function Deref_type_attributes(type_attributes_ptr: type_attributes_ptr_type):
  type_attributes_ptr_type;
begin
  if type_attributes_ptr <> nil then
    if type_attributes_ptr^.kind = type_reference then
      type_attributes_ptr := type_attributes_ptr^.reference_type_attributes_ptr;

  Deref_type_attributes := type_attributes_ptr;
end; {function Deref_type_attributes}


{*****************************}
{ array dimensioning routines }
{*****************************}


procedure Dim_type_attributes(var type_attributes_ptr: type_attributes_ptr_type;
  dimensions: integer);
var
  array_type_attributes_ptr: type_attributes_ptr_type;
  unaliased_type_attributes_ptr: type_attributes_ptr_type;
begin
  array_type_attributes_ptr := New_type_attributes(type_array, false);
  array_type_attributes_ptr^.element_type_attributes_ptr := type_attributes_ptr;
  array_type_attributes_ptr^.relative_dimensions := dimensions;

  unaliased_type_attributes_ptr := Unalias_type_attributes(type_attributes_ptr);
  if (unaliased_type_attributes_ptr^.kind = type_array) then
    begin
      array_type_attributes_ptr^.base_type_attributes_ptr :=
        unaliased_type_attributes_ptr^.base_type_attributes_ptr;
      array_type_attributes_ptr^.absolute_dimensions :=
        unaliased_type_attributes_ptr^.absolute_dimensions + dimensions;
    end
  else
    begin
      array_type_attributes_ptr^.base_type_attributes_ptr :=
        unaliased_type_attributes_ptr;
      array_type_attributes_ptr^.absolute_dimensions := dimensions;
    end;

  type_attributes_ptr := array_type_attributes_ptr;
end; {procedure Dim_type_attributes}


procedure Dim_base_type_attributes(var type_attributes_ptr:
  type_attributes_ptr_type;
  dimensions: integer);
var
  array_type_attributes_ptr: type_attributes_ptr_type;
  follow: type_attributes_ptr_type;
  done: boolean;
begin
  type_attributes_ptr := Unalias_type_attributes(type_attributes_ptr);

  if (type_attributes_ptr^.kind <> type_array) then
    Dim_type_attributes(type_attributes_ptr, dimensions)
  else
    begin
      array_type_attributes_ptr := New_type_attributes(type_array, false);
      array_type_attributes_ptr^.element_type_attributes_ptr :=
        type_attributes_ptr^.base_type_attributes_ptr;
      array_type_attributes_ptr^.base_type_attributes_ptr :=
        type_attributes_ptr^.base_type_attributes_ptr;
      array_type_attributes_ptr^.relative_dimensions := dimensions;
      array_type_attributes_ptr^.absolute_dimensions := dimensions;

      {******************************************}
      { increase dimensions of all parent arrays }
      {******************************************}
      follow := type_attributes_ptr;
      done := false;
      while not done do
        begin
          follow^.absolute_dimensions := follow^.absolute_dimensions +
            dimensions;
          if (follow^.element_type_attributes_ptr <>
            type_attributes_ptr^.base_type_attributes_ptr) then
            follow := follow^.element_type_attributes_ptr
          else
            done := true;
        end;

      {********************************}
      { add to tail of array decl list }
      {********************************}
      follow^.element_type_attributes_ptr := array_type_attributes_ptr;
    end;
end; {procedure Dim_base_type_attributes}


function Base_type_attributes(type_attributes_ptr: type_attributes_ptr_type):
  type_attributes_ptr_type;
begin
  if type_attributes_ptr^.kind = type_array then
    type_attributes_ptr := type_attributes_ptr^.base_type_attributes_ptr;

  Base_type_attributes := type_attributes_ptr;
end; {function Base_type_attributes}


{*************************}
{ array querying routines }
{*************************}


function Get_data_abs_dims(type_attributes_ptr: type_attributes_ptr_type):
  integer;
var
  dimensions: integer;
begin
  type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);
  type_attributes_ptr := Unalias_type_attributes(type_attributes_ptr);

  if type_attributes_ptr <> nil then
    begin
      if type_attributes_ptr^.kind = type_array then
        dimensions := type_attributes_ptr^.absolute_dimensions
      else
        dimensions := 0;
    end
  else
    dimensions := 0;

  Get_data_abs_dims := dimensions;
end; {function Get_data_abs_dims}


function Get_data_rel_dims(type_attributes_ptr: type_attributes_ptr_type):
  integer;
var
  dimensions: integer;
begin
  type_attributes_ptr := Deref_type_attributes(type_attributes_ptr);
  type_attributes_ptr := Unalias_type_attributes(type_attributes_ptr);

  if type_attributes_ptr <> nil then
    begin
      if type_attributes_ptr^.kind = type_array then
        dimensions := type_attributes_ptr^.relative_dimensions
      else
        dimensions := 0;
    end
  else
    dimensions := 0;

  Get_data_rel_dims := dimensions;
end; {function Get_data_rel_dims}


{********************************************************}
{ routine to query type attributes for its declared name }
{********************************************************}


function Get_type_attributes_name(type_attributes_ptr:
  type_attributes_ptr_type): string_type;
begin
  if type_attributes_ptr <> nil then
    Get_type_attributes_name := Get_id_name(type_attributes_ptr^.id_ptr)
  else
    Get_type_attributes_name := '?';
end; {function Get_type_attributes_name}


{**************************************}
{ routines to write miscillaneous info }
{**************************************}


procedure Write_type_kind(kind: type_kind_type);
begin
  case kind of

    type_error:
      write('error');

    {*****************}
    { primitive types }
    {*****************}
    type_boolean:
      write('boolean');
    type_char:
      write('char');

    type_byte:
      write('byte');
    type_short:
      write('short');

    type_integer:
      write('integer');
    type_long:
      write('long');

    type_scalar:
      write('scalar');
    type_double:
      write('double');

    type_complex:
      write('complex');
    type_vector:
      write('vector');

    {********************}
    { user defined types }
    {********************}
    type_enum:
      write('enum');
    type_alias:
      write('alias');
    type_array:
      write('array');
    type_struct:
      write('struct');
    type_class:
      write('class');
    type_class_alias:
      write('class alias');

    {************}
    { code types }
    {************}
    type_code:
      write('code');

    {***************************}
    { references to other types }
    {***************************}
    type_reference:
      write('reference');
  end;
end; {procedure Write_type_kind}


procedure Write_type_attributes(type_attributes_ptr: type_attributes_ptr_type);
var
  counter: integer;
begin
  if type_attributes_ptr <> nil then
    case type_attributes_ptr^.kind of

      type_boolean..type_vector:
        Write_type_kind(type_attributes_ptr^.kind);

      type_enum:
        begin
          Write_type_kind(type_attributes_ptr^.kind);
          write(' ');
          write(Get_id_name(type_attributes_ptr^.id_ptr));
        end;

      type_alias:
        Write_type_attributes(type_attributes_ptr^.alias_type_attributes_ptr);

      type_array:
        begin
          write(Get_id_name(type_attributes_ptr^.base_type_attributes_ptr^.id_ptr));
          write(' array');
          while type_attributes_ptr <> nil do
            begin
              write('[');
              for counter := 1 to type_attributes_ptr^.relative_dimensions - 1
                do
                write(',');
              write(']');
              type_attributes_ptr := type_attributes_ptr^.next;
            end;
        end;

      type_struct:
        begin
          Write_type_kind(type_attributes_ptr^.kind);
          write(' ');
          write(Get_id_name(type_attributes_ptr^.id_ptr));
        end;

      type_class:
        begin
          Write_type_kind(type_attributes_ptr^.kind);
          write(' ');
          write(Get_id_name(type_attributes_ptr^.id_ptr));
        end;

      type_class_alias:
        Write_type_attributes(type_attributes_ptr^.class_alias_type_attributes_ptr);

      type_code:
        begin
          Write_code_kind(type_attributes_ptr^.code_attributes_ptr^.kind);
          write(' ');
          write(Get_id_name(type_attributes_ptr^.id_ptr));
        end;

      type_reference:
        begin
          Write_type_attributes(type_attributes_ptr^.reference_type_attributes_ptr);
          write(' reference');
        end;

    end {case}
  else
    write('nil reference');
end; {procedure Write_type_attributes}



procedure Dispose_type_attributes_blocks(var type_attributes_block_ptr:
  type_attributes_block_ptr_type);
var
  temp: type_attributes_block_ptr_type;
begin
  while (type_attributes_block_ptr <> nil) do
    begin
      temp := type_attributes_block_ptr;
      type_attributes_block_ptr := type_attributes_block_ptr^.next;
      dispose(temp);
    end;
end; {procedure Dispose_type_attributes_blocks}


procedure Dispose_type_attributes_ref_blocks(var type_attributes_ref_block_ptr:
  type_attributes_ref_block_ptr_type);
var
  temp: type_attributes_ref_block_ptr_type;
begin
  while (type_attributes_ref_block_ptr <> nil) do
    begin
      temp := type_attributes_ref_block_ptr;
      type_attributes_ref_block_ptr := type_attributes_ref_block_ptr^.next;
      dispose(temp);
    end;
end; {procedure Dispose_type_attributes_ref_blocks}


{****************************************}
{ miscillaneous type attributes routines }
{****************************************}


procedure Free_all_type_attributes;
begin
  {***********************}
  { initialize free lists }
  {***********************}
  type_attributes_free_list := nil;
  type_attributes_ref_free_list := nil;

  {***************************************}
  { initialize block allocation variables }
  {***************************************}
  type_attributes_block_list := nil;
  type_attributes_ref_block_list := nil;

  type_attributes_counter := 0;
  type_attributes_ref_counter := 0;

  {************************}
  { free up memory for all }
  {************************}
  Dispose_type_attributes_blocks(type_attributes_block_list);
  Dispose_type_attributes_ref_blocks(type_attributes_ref_block_list);
end; {procedure Free_all_type_attributes}


initialization
  Init_data_sets;

  {***********************}
  { initialize free lists }
  {***********************}
  type_attributes_free_list := nil;
  type_attributes_ref_free_list := nil;

  {***************************************}
  { initialize block allocation variables }
  {***************************************}
  type_attributes_block_list := nil;
  type_attributes_ref_block_list := nil;

  type_attributes_counter := 0;
  type_attributes_ref_counter := 0;
end.
