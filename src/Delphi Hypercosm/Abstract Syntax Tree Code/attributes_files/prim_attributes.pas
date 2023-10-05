unit prim_attributes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           prim_attributes             3d       }
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
  type_attributes;


var
  {***************************}
  { primitive type attributes }
  {***************************}
  boolean_type_attributes_ptr: type_attributes_ptr_type;
  char_type_attributes_ptr: type_attributes_ptr_type;

  byte_type_attributes_ptr: type_attributes_ptr_type;
  short_type_attributes_ptr: type_attributes_ptr_type;

  integer_type_attributes_ptr: type_attributes_ptr_type;
  long_type_attributes_ptr: type_attributes_ptr_type;

  scalar_type_attributes_ptr: type_attributes_ptr_type;
  double_type_attributes_ptr: type_attributes_ptr_type;

  {************************************}
  { primitive compound type attributes }
  {************************************}
  complex_type_attributes_ptr: type_attributes_ptr_type;
  vector_type_attributes_ptr: type_attributes_ptr_type;

  {**************************************}
  { primitive structured type attributes }
  {**************************************}
  string_type_attributes_ptr: type_attributes_ptr_type;
  string_array_type_attributes_ptr: type_attributes_ptr_type;


{****************************************}
{ routines to reference a primitive type }
{****************************************}
function Get_prim_type_attributes(kind: type_kind_type):
  type_attributes_ptr_type;


implementation
uses
  symbol_tables;


var
  type_name_table_ptr: symbol_table_ptr_type;


procedure Init_type_attributes(var type_attributes_ptr:
  type_attributes_ptr_type;
  kind: type_kind_type;
  static: boolean;
  name: string);
begin
  type_attributes_ptr := New_type_attributes(kind, static);
  type_attributes_ptr^.kind := kind;
  type_attributes_ptr^.id_ptr := Enter_id(type_name_table_ptr, name, 0);
end; {procedure Init_type_attributes}


{****************************************}
{ routines to reference a primitive type }
{****************************************}


function Get_prim_type_attributes(kind: type_kind_type):
  type_attributes_ptr_type;
var
  type_attributes_ptr: type_attributes_ptr_type;
begin
  type_attributes_ptr := nil;

  case kind of

    {***************************}
    { primitive type attributes }
    {***************************}
    type_boolean:
      type_attributes_ptr := boolean_type_attributes_ptr;
    type_char:
      type_attributes_ptr := char_type_attributes_ptr;

    type_byte:
      type_attributes_ptr := byte_type_attributes_ptr;
    type_short:
      type_attributes_ptr := short_type_attributes_ptr;

    type_integer:
      type_attributes_ptr := integer_type_attributes_ptr;
    type_long:
      type_attributes_ptr := long_type_attributes_ptr;

    type_scalar:
      type_attributes_ptr := scalar_type_attributes_ptr;
    type_double:
      type_attributes_ptr := double_type_attributes_ptr;

    {************************************}
    { primitive compound type attributes }
    {************************************}
    type_complex:
      type_attributes_ptr := complex_type_attributes_ptr;
    type_vector:
      type_attributes_ptr := vector_type_attributes_ptr;

  end; {case}

  Get_prim_type_attributes := type_attributes_ptr;
end; {function Get_prim_type_attributes}


initialization
  type_name_table_ptr := New_symbol_table;

  {**************************************}
  { initialize primitive type attributes }
  {**************************************}
  Init_type_attributes(boolean_type_attributes_ptr, type_boolean, true,
    'boolean type');
  Init_type_attributes(char_type_attributes_ptr, type_char, true, 'char type');

  Init_type_attributes(byte_type_attributes_ptr, type_byte, true, 'byte type');
  Init_type_attributes(short_type_attributes_ptr, type_short, true,
    'short type');

  Init_type_attributes(integer_type_attributes_ptr, type_integer, true,
    'integer type');
  Init_type_attributes(long_type_attributes_ptr, type_long, true, 'long type');

  Init_type_attributes(scalar_type_attributes_ptr, type_scalar, true,
    'scalar type');
  Init_type_attributes(double_type_attributes_ptr, type_double, true,
    'double type');

  {***********************************************}
  { initialize primitive compound type attributes }
  {***********************************************}
  Init_type_attributes(complex_type_attributes_ptr, type_complex, true,
    'complex type');
  Init_type_attributes(vector_type_attributes_ptr, type_vector, true,
    'vector type');

  {*************************************************}
  { initialize primitive structured type attributes }
  {*************************************************}
  Init_type_attributes(string_type_attributes_ptr, type_char, true,
    'string type');
  Dim_type_attributes(string_type_attributes_ptr, 1);

  string_array_type_attributes_ptr := string_type_attributes_ptr;
  Dim_type_attributes(string_array_type_attributes_ptr, 1);

  Free_symbol_table(type_name_table_ptr, false);

finalization
  {********************************}
  { free primitive type attributes }
  {********************************}
  Free_type_attributes(boolean_type_attributes_ptr);
  Free_type_attributes(char_type_attributes_ptr);

  Free_type_attributes(byte_type_attributes_ptr);
  Free_type_attributes(short_type_attributes_ptr);

  Free_type_attributes(integer_type_attributes_ptr);
  Free_type_attributes(long_type_attributes_ptr);

  Free_type_attributes(scalar_type_attributes_ptr);
  Free_type_attributes(double_type_attributes_ptr);

  {*****************************************}
  { free primitive compound type attributes }
  {*****************************************}
  Free_type_attributes(complex_type_attributes_ptr);
  Free_type_attributes(vector_type_attributes_ptr);

  {*******************************************}
  { free primitive structured type attributes }
  {*******************************************}
  Free_type_attributes(string_type_attributes_ptr);
  Free_type_attributes(string_array_type_attributes_ptr);
end.
