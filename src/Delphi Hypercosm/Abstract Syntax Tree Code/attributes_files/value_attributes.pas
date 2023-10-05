unit value_attributes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          value_attributes             3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the attributes and which are       }
{       used to describe primitive values used by the           }
{       interpreter.                                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  type_attributes, expr_attributes;


var
  {***************************************}
  { primitive value expression attributes }
  {***************************************}
  boolean_value_attributes_ptr: expr_attributes_ptr_type;
  char_value_attributes_ptr: expr_attributes_ptr_type;

  byte_value_attributes_ptr: expr_attributes_ptr_type;
  short_value_attributes_ptr: expr_attributes_ptr_type;

  integer_value_attributes_ptr: expr_attributes_ptr_type;
  long_value_attributes_ptr: expr_attributes_ptr_type;

  scalar_value_attributes_ptr: expr_attributes_ptr_type;
  double_value_attributes_ptr: expr_attributes_ptr_type;

  complex_value_attributes_ptr: expr_attributes_ptr_type;
  vector_value_attributes_ptr: expr_attributes_ptr_type;

  {*****************************************}
  { polymorphic value expression attributes }
  {*****************************************}
  typeless_value_attributes_ptr: expr_attributes_ptr_type;

  {**************************************************}
  { primitive structured value expression attributes }
  {**************************************************}
  string_value_attributes_ptr: expr_attributes_ptr_type;
  string_array_value_attributes_ptr: expr_attributes_ptr_type;


{***************************************************}
{ routines to create new expression attributes or a }
 { reference to primitive type expression attributes }
{***************************************************}
function Get_prim_value_attributes(kind: type_kind_type):
  expr_attributes_ptr_type;


implementation
uses
  errors, prim_attributes;


{***************************************************}
{ routines to create new expression attributes or a }
{ reference to primitive type expression attributes }
{***************************************************}


function Get_prim_value_attributes(kind: type_kind_type):
  expr_attributes_ptr_type;
var
  expr_attributes_ptr: expr_attributes_ptr_type;
begin
  expr_attributes_ptr := nil;
  
  case kind of

    type_boolean:
      expr_attributes_ptr := boolean_value_attributes_ptr;
    type_char:
      expr_attributes_ptr := char_value_attributes_ptr;

    type_byte:
      expr_attributes_ptr := byte_value_attributes_ptr;
    type_short:
      expr_attributes_ptr := short_value_attributes_ptr;

    type_integer:
      expr_attributes_ptr := integer_value_attributes_ptr;
    type_long:
      expr_attributes_ptr := long_value_attributes_ptr;

    type_scalar:
      expr_attributes_ptr := scalar_value_attributes_ptr;
    type_double:
      expr_attributes_ptr := double_value_attributes_ptr;

    type_complex:
      expr_attributes_ptr := complex_value_attributes_ptr;
    type_vector:
      expr_attributes_ptr := vector_value_attributes_ptr;
  end; {case}

  Get_prim_value_attributes := expr_attributes_ptr;
end; {function Get_prim_value_attributes}


initialization
  {***********************************************}
  { init attributes of primitive type expressions }
  {***********************************************}
  boolean_value_attributes_ptr :=
    New_value_expr_attributes(boolean_type_attributes_ptr);
  char_value_attributes_ptr :=
    New_value_expr_attributes(char_type_attributes_ptr);

  byte_value_attributes_ptr :=
    New_value_expr_attributes(byte_type_attributes_ptr);
  short_value_attributes_ptr :=
    New_value_expr_attributes(short_type_attributes_ptr);

  integer_value_attributes_ptr :=
    New_value_expr_attributes(integer_type_attributes_ptr);
  long_value_attributes_ptr :=
    New_value_expr_attributes(long_type_attributes_ptr);

  scalar_value_attributes_ptr :=
    New_value_expr_attributes(scalar_type_attributes_ptr);
  double_value_attributes_ptr :=
    New_value_expr_attributes(double_type_attributes_ptr);

  complex_value_attributes_ptr :=
    New_value_expr_attributes(complex_type_attributes_ptr);
  vector_value_attributes_ptr :=
    New_value_expr_attributes(vector_type_attributes_ptr);

  {********************************************}
  { init attributes of polymorphic expressions }
  {********************************************}
  typeless_value_attributes_ptr := New_value_expr_attributes(nil);

  {**********************************************************}
  { init attributes of primitive structured type expressions }
  {**********************************************************}
  string_value_attributes_ptr :=
    New_value_expr_attributes(string_type_attributes_ptr);
  string_array_value_attributes_ptr :=
    New_value_expr_attributes(string_array_type_attributes_ptr);


finalization
  {***********************************************}
  { free attributes of primitive type expressions }
  {***********************************************}
  Free_expr_attributes(boolean_value_attributes_ptr);
  Free_expr_attributes(char_value_attributes_ptr);

  Free_expr_attributes(byte_value_attributes_ptr);
  Free_expr_attributes(short_value_attributes_ptr);

  Free_expr_attributes(integer_value_attributes_ptr);
  Free_expr_attributes(long_value_attributes_ptr);

  Free_expr_attributes(scalar_value_attributes_ptr);
  Free_expr_attributes(double_value_attributes_ptr);

  Free_expr_attributes(complex_value_attributes_ptr);
  Free_expr_attributes(vector_value_attributes_ptr);

  {********************************************}
  { free attributes of polymorphic expressions }
  {********************************************}
  Free_expr_attributes(typeless_value_attributes_ptr);

  {**********************************************************}
  { free attributes of primitive structured type expressions }
  {**********************************************************}
  Free_expr_attributes(string_value_attributes_ptr);
  Free_expr_attributes(string_array_value_attributes_ptr);
end.
