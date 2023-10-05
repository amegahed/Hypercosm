unit exec_native_math;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          exec_native_math             3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines for executing native      }
{       math methods.                                           }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  native_math;


{***********************************************************}
{ routine to switch between and execute native math methods }
{***********************************************************}
procedure Exec_native_math_method(kind: native_math_method_kind_type);


implementation
uses
  trigonometry, complex_numbers, vectors, noise, addr_types, get_params,
  op_stacks;


{************************}
{ trigonometry functions }
{************************}


procedure Eval_sin;
var
  param_index: stack_index_type;
  x: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  x := Get_scalar_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_scalar_operand(sin(x * degrees_to_radians));
end; {procedure Eval_sin}


procedure Eval_cos;
var
  param_index: stack_index_type;
  x: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  x := Get_scalar_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_scalar_operand(cos(x * degrees_to_radians));
end; {procedure Eval_cos}


procedure Eval_tan;
var
  param_index: stack_index_type;
  x: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  x := Get_scalar_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_scalar_operand(Tangent(x * degrees_to_radians));
end; {procedure Eval_tan}


{*********************************}
{ inverse trigonometric functions }
{*********************************}


procedure Eval_asin;
var
  param_index: stack_index_type;
  x: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  x := Get_scalar_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_scalar_operand(Asin(x) * radians_to_degrees);
end; {procedure Eval_asin}


procedure Eval_acos;
var
  param_index: stack_index_type;
  x: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  x := Get_scalar_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_scalar_operand(Acos(x) * radians_to_degrees);
end; {procedure Eval_acos}


procedure Eval_atan;
var
  param_index: stack_index_type;
  x: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  x := Get_scalar_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_scalar_operand(Atan(x) * radians_to_degrees);
end; {procedure Eval_atan}


{*******************************}
{ native logarithminc functions }
{*******************************}


procedure Eval_ln;
var
  param_index: stack_index_type;
  x: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  x := Get_scalar_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_scalar_operand(ln(x));
end; {procedure Eval_ln}


procedure Eval_exp;
var
  param_index: stack_index_type;
  x: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  x := Get_scalar_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_scalar_operand(exp(x));
end; {procedure Eval_exp}


{************************}
{ native noise functions }
{************************}


procedure Eval_noise1;
var
  param_index: stack_index_type;
  x: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  x := Get_scalar_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_scalar_operand(Noise1(x));
end; {procedure Eval_noise1}


procedure Eval_noise2;
var
  param_index: stack_index_type;
  x, y: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  x := Get_scalar_param(param_index);
  y := Get_scalar_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_scalar_operand(Noise2(x, y));
end; {procedure Eval_noise2}


procedure Eval_noise;
var
  param_index: stack_index_type;
  v: vector_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  v := Get_vector_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_scalar_operand(Noise3(v));
end; {procedure Eval_noise}


procedure Eval_vnoise1;
var
  param_index: stack_index_type;
  x: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  x := Get_scalar_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_vector_operand(Noise_vector1(x));
end; {procedure Eval_vnoise1}


procedure Eval_vnoise2;
var
  param_index: stack_index_type;
  x, y: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  x := Get_scalar_param(param_index);
  y := Get_scalar_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_vector_operand(Noise_vector2(x, y));
end; {procedure Eval_vnoise2}


procedure Eval_vnoise;
var
  param_index: stack_index_type;
  v: vector_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  v := Get_vector_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_vector_operand(Noise_vector3(v));
end; {procedure Eval_vnoise}


{**********************************}
{ native type conversion functions }
{**********************************}


procedure Eval_trunc;
var
  param_index: stack_index_type;
  x: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  x := Get_scalar_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_integer_operand(Trunc(x));
end; {procedure Eval_trunc}


procedure Eval_round;
var
  param_index: stack_index_type;
  x: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  x := Get_scalar_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_integer_operand(Round(x));
end; {procedure Eval_round}


procedure Eval_chr;
var
  param_index: stack_index_type;
  i: integer;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  i := Get_integer_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_char_operand(chr(i));
end; {procedure Eval_chr}


procedure Eval_ord;
var
  param_index: stack_index_type;
  ch: char;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  ch := Get_char_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_integer_operand(ord(ch));
end; {procedure Eval_ord}


procedure Eval_real;
var
  param_index: stack_index_type;
  c: complex_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  c := Get_complex_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_scalar_operand(c.a);
end; {procedure Eval_real}


procedure Eval_imag;
var
  param_index: stack_index_type;
  c: complex_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  c := Get_complex_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_scalar_operand(c.b);
end; {procedure Eval_imag}


{***********************************************************}
{ routine to switch between and execute native math methods }
{***********************************************************}


procedure Exec_native_math_method(kind: native_math_method_kind_type);
begin
  case kind of

    {************************}
    { trigonometry functions }
    {************************}
    native_sin:
      Eval_sin;
    native_cos:
      Eval_cos;
    native_tan:
      Eval_tan;

    {*********************************}
    { inverse trigonometric functions }
    {*********************************}
    native_asin:
      Eval_asin;
    native_acos:
      Eval_acos;
    native_atan:
      Eval_atan;

    {******************************}
    { native logarithmic functions }
    {******************************}
    native_ln:
      Eval_ln;
    native_exp:
      Eval_exp;

    {************************}
    { native noise functions }
    {************************}
    native_noise1:
      Eval_noise1;
    native_noise2:
      Eval_noise2;
    native_noise:
      Eval_noise;
    native_vnoise1:
      Eval_vnoise1;
    native_vnoise2:
      Eval_vnoise2;
    native_vnoise:
      Eval_vnoise;

    {**********************************}
    { native type conversion functions }
    {**********************************}
    native_trunc:
      Eval_trunc;
    native_round:
      Eval_round;
    native_chr:
      Eval_chr;
    native_ord:
      Eval_ord;
    native_real:
      Eval_real;
    native_imag:
      Eval_imag;

  end; {case}
end; {procedure Exec_native_math_method}


end.
