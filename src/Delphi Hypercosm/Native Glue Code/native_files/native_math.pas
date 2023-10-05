unit native_math;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            native_math                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The primitive data needed by the interpreter is found   }
{       by its index on the stack (its order of declaration)    }
{       so that the identifiers which stand for this data       }
{       may be changed without recompiling the code.            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings;


type
  {***************************************************************}
  {                     native math data kinds                    }
  {***************************************************************}
  native_math_data_kind_type = integer;


  {***************************************************************}
  {                    native math method kinds                   }
  {***************************************************************}
  native_math_method_kind_type = (

    {************************}
    { trigonometry functions }
    {************************}
    native_sin, native_cos, native_tan,

    {*********************************}
    { inverse trigonometric functions }
    {*********************************}
    native_asin, native_acos, native_atan,

    {*******************************}
    { native logarithminc functions }
    {*******************************}
    native_ln, native_exp,

    {************************}
    { native noise functions }
    {************************}
    native_noise1, native_noise2, native_noise, native_vnoise1, native_vnoise2,
    native_vnoise,

    {**********************************}
    { native type conversion functions }
    {**********************************}
    native_trunc, native_round, native_chr, native_ord, native_real,
    native_imag);


{*******************************************************}
{ routines to match native data and method kind by name }
{*******************************************************}
function Found_native_math_data_by_name(name: string_type;
  var kind: native_math_data_kind_type): boolean;
function Found_native_math_method_by_name(name: string_type;
  var kind: native_math_method_kind_type): boolean;

{************************************************}
{ routines to query native data and method kinds }
{************************************************}
function Native_math_data_number: integer;
function Native_math_method_number: integer;


implementation
uses
  hashtables;


var
  native_data_table_ptr: hashtable_ptr_type;
  native_method_table_ptr: hashtable_ptr_type;


{*******************************************************}
{ routines to match native data and method kind by name }
{*******************************************************}


function Found_native_math_data_by_name(name: string_type;
  var kind: native_math_data_kind_type): boolean;
var
  found: boolean;
  value: hashtable_value_type;
begin
  if Found_hashtable_value_by_key(native_data_table_ptr, value, name) then
    begin
      kind := native_math_data_kind_type(value);
      found := true;
    end
  else
    found := false;

  Found_native_math_data_by_name := found;
end; {function Found_native_math_data_by_name}


function Found_native_math_method_by_name(name: string_type;
  var kind: native_math_method_kind_type): boolean;
var
  found: boolean;
  value: hashtable_value_type;
begin
  if Found_hashtable_value_by_key(native_method_table_ptr, value, name) then
    begin
      kind := native_math_method_kind_type(value);
      found := true;
    end
  else
    found := false;

  Found_native_math_method_by_name := found;
end; {function Found_native_math_method_by_name}


{************************************************}
{ routines to query native data and method kinds }
{************************************************}


function Native_math_data_number: integer;
begin
  Native_math_data_number := 0;
end; {function Native_math_data_number}


function Native_math_method_number: integer;
begin
  Native_math_method_number := ord(native_imag) + 1;
end; {function Native_math_method_number}


initialization
  native_data_table_ptr := New_hashtable;
  native_method_table_ptr := New_hashtable;

  {************************}
  { trigonometry functions }
  {************************}
  Enter_hashtable(native_method_table_ptr, 'sin', ord(native_sin));
  Enter_hashtable(native_method_table_ptr, 'cos', ord(native_cos));
  Enter_hashtable(native_method_table_ptr, 'tan', ord(native_tan));

  {*********************************}
  { inverse trigonometric functions }
  {*********************************}
  Enter_hashtable(native_method_table_ptr, 'asin', ord(native_asin));
  Enter_hashtable(native_method_table_ptr, 'acos', ord(native_acos));
  Enter_hashtable(native_method_table_ptr, 'atan', ord(native_atan));

  {*******************************}
  { native logarithminc functions }
  {*******************************}
  Enter_hashtable(native_method_table_ptr, 'ln', ord(native_ln));
  Enter_hashtable(native_method_table_ptr, 'exp', ord(native_exp));

  {************************}
  { native noise functions }
  {************************}
  Enter_hashtable(native_method_table_ptr, 'noise1', ord(native_noise1));
  Enter_hashtable(native_method_table_ptr, 'noise2', ord(native_noise2));
  Enter_hashtable(native_method_table_ptr, 'noise', ord(native_noise));
  Enter_hashtable(native_method_table_ptr, 'vnoise1', ord(native_vnoise1));
  Enter_hashtable(native_method_table_ptr, 'vnoise2', ord(native_vnoise2));
  Enter_hashtable(native_method_table_ptr, 'vnoise', ord(native_vnoise));

  {**********************************}
  { native type conversion functions }
  {**********************************}
  Enter_hashtable(native_method_table_ptr, 'trunc', ord(native_trunc));
  Enter_hashtable(native_method_table_ptr, 'round', ord(native_round));
  Enter_hashtable(native_method_table_ptr, 'chr', ord(native_chr));
  Enter_hashtable(native_method_table_ptr, 'ord', ord(native_ord));
  Enter_hashtable(native_method_table_ptr, 'real', ord(native_real));
  Enter_hashtable(native_method_table_ptr, 'imag', ord(native_imag));
end.
