unit cast_literals;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           cast_literals               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The casting module contains routines to cast            }
{       literal expressions from one type to another.           }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  type_attributes, expr_attributes, exprs, tokens;


{*********************************************}
{ literal integer to integer casting routines }
{*********************************************}
procedure Cast_byte_literal_to_short(expr_ptr: expr_ptr_type);
procedure Cast_short_literal_to_integer(expr_ptr: expr_ptr_type);
procedure Cast_integer_literal_to_long(expr_ptr: expr_ptr_type);

{********************************************}
{ literal integer to scalar casting routines }
{********************************************}
procedure Cast_integer_literal_to_scalar(expr_ptr: expr_ptr_type);
procedure Cast_long_literal_to_scalar(expr_ptr: expr_ptr_type);
procedure Cast_long_literal_to_double(expr_ptr: expr_ptr_type);

{*******************************************}
{ literal scalar to scalar casting routines }
{*******************************************}
procedure Cast_scalar_literal_to_double(expr_ptr: expr_ptr_type);
procedure Cast_scalar_literal_to_complex(expr_ptr: expr_ptr_type);


implementation
uses
  complex_numbers, data_types, lit_attributes, typechecker;


{*********************************************}
{ literal integer to integer casting routines }
{*********************************************}


procedure Cast_byte_literal_to_short(expr_ptr: expr_ptr_type);
var
  short_val: short_type;
begin
  {**********************************}
  { cast byte literal to short value }
  {**********************************}
  short_val := expr_ptr^.byte_val;

  {*************************************}
  { create new short literal expression }
  {*************************************}
  expr_ptr^.kind := short_lit;
  expr_ptr^.short_val := short_val;
end; {procedure Cast_byte_literal_to_short}


procedure Cast_short_literal_to_integer(expr_ptr: expr_ptr_type);
var
  integer_val: integer_type;
begin
  {*************************************}
  { cast short literal to integer value }
  {*************************************}
  integer_val := expr_ptr^.short_val;

  {***************************************}
  { create new integer literal expression }
  {***************************************}
  expr_ptr^.kind := integer_lit;
  expr_ptr^.integer_val := integer_val;
end; {procedure Cast_short_literal_to_integer}


procedure Cast_integer_literal_to_long(expr_ptr: expr_ptr_type);
var
  long_val: long_type;
begin
  {************************************}
  { cast integer literal to long value }
  {************************************}
  long_val := expr_ptr^.integer_val;

  {************************************}
  { create new long literal expression }
  {************************************}
  expr_ptr^.kind := long_lit;
  expr_ptr^.long_val := long_val;
end; {procedure Cast_integer_literal_to_long}


{********************************************}
{ literal integer to scalar casting routines }
{********************************************}


procedure Cast_integer_literal_to_scalar(expr_ptr: expr_ptr_type);
var
  scalar_val: scalar_type;
begin
  {**************************************}
  { cast integer literal to scalar value }
  {**************************************}
  scalar_val := expr_ptr^.integer_val;

  {**************************************}
  { create new scalar literal expression }
  {**************************************}
  expr_ptr^.kind := scalar_lit;
  expr_ptr^.scalar_val := scalar_val;
  Set_literal_attributes(expr_ptr, New_literal_attributes(scalar_attributes));
end; {procedure Cast_integer_literal_to_scalar}


procedure Cast_long_literal_to_scalar(expr_ptr: expr_ptr_type);
var
  scalar_val: scalar_type;
begin
  {***********************************}
  { cast long literal to scalar value }
  {***********************************}
  scalar_val := expr_ptr^.long_val;

  {**************************************}
  { create new scalar literal expression }
  {**************************************}
  expr_ptr^.kind := scalar_lit;
  expr_ptr^.scalar_val := scalar_val;
  Set_literal_attributes(expr_ptr, New_literal_attributes(scalar_attributes));
end; {procedure Cast_long_literal_to_scalar}


procedure Cast_long_literal_to_double(expr_ptr: expr_ptr_type);
var
  double_val: double_type;
begin
  {***********************************}
  { cast long literal to double value }
  {***********************************}
  double_val := expr_ptr^.long_val;

  {**************************************}
  { create new double literal expression }
  {**************************************}
  expr_ptr^.kind := double_lit;
  expr_ptr^.double_val := double_val;
  Set_literal_attributes(expr_ptr, New_literal_attributes(double_attributes));
end; {procedure Cast_long_literal_to_double}


{*******************************************}
{ literal scalar to scalar casting routines }
{*******************************************}


procedure Cast_scalar_attributes_to_double(literal_attributes_ptr:
  literal_attributes_ptr_type);
var
  decimal_places: integer;
  exponential_notation: boolean;
begin
  {***********************}
  { get scalar attributes }
  {***********************}
  decimal_places := literal_attributes_ptr^.scalar_decimal_places;
  exponential_notation := literal_attributes_ptr^.scalar_exponential_notation;

  {***********************}
  { set double attributes }
  {***********************}
  literal_attributes_ptr^.kind := double_attributes;
  literal_attributes_ptr^.double_decimal_places := decimal_places;
  literal_attributes_ptr^.double_exponential_notation := exponential_notation;
end; {procedure Cast_scalar_attributes_to_double}


procedure Cast_scalar_literal_to_double(expr_ptr: expr_ptr_type);
var
  double_val: double_type;
  double_attributes_ptr: literal_attributes_ptr_type;
begin
  {*************************************}
  { cast scalar literal to double value }
  {*************************************}
  double_val := expr_ptr^.scalar_val;
  double_attributes_ptr := expr_ptr^.scalar_attributes_ptr;
  Cast_scalar_attributes_to_double(double_attributes_ptr);

  {**************************************}
  { create new double literal expression }
  {**************************************}
  expr_ptr^.kind := double_lit;
  expr_ptr^.double_val := double_val;
  expr_ptr^.double_attributes_ptr := double_attributes_ptr;
end; {procedure Cast_scalar_literal_to_double}


procedure Cast_scalar_attributes_to_complex(literal_attributes_ptr:
  literal_attributes_ptr_type);
var
  decimal_places: integer;
  exponential_notation: boolean;
begin
  {***********************}
  { get scalar attributes }
  {***********************}
  decimal_places := literal_attributes_ptr^.scalar_decimal_places;
  exponential_notation := literal_attributes_ptr^.scalar_exponential_notation;

  {************************}
  { set complex attributes }
  {************************}
  literal_attributes_ptr^.kind := complex_attributes;
  literal_attributes_ptr^.a_decimal_places := decimal_places;
  literal_attributes_ptr^.b_decimal_places := 0;
  literal_attributes_ptr^.a_exponential_notation := exponential_notation;
  literal_attributes_ptr^.b_exponential_notation := false;
end; {procedure Cast_scalar_attributes_to_complex}


procedure Cast_scalar_literal_to_complex(expr_ptr: expr_ptr_type);
var
  complex_val: complex_type;
  complex_attributes_ptr: literal_attributes_ptr_type;
begin
  {**************************************}
  { cast scalar literal to complex value }
  {**************************************}
  complex_val := Complex(expr_ptr^.scalar_val);
  complex_attributes_ptr := expr_ptr^.scalar_attributes_ptr;
  Cast_scalar_attributes_to_complex(complex_attributes_ptr);

  {***************************************}
  { create new complex literal expression }
  {***************************************}
  expr_ptr^.kind := complex_lit;
  expr_ptr^.complex_val := complex_val;
  expr_ptr^.complex_attributes_ptr := complex_attributes_ptr;
end; {procedure Cast_scalar_literal_to_complex}


end.
