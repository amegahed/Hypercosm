unit native_conversion;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          native_conversion            3d       }
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
  {                  native conversion data kinds                 }
  {***************************************************************}
  native_conversion_data_kind_type = integer;


  {***************************************************************}
  {                  native conversion method kinds               }
  {***************************************************************}
  native_conversion_method_kind_type = (

    {*************************************************}
    { routines for converting primitive types to data }
    {*************************************************}
    native_boolean_to_data, native_char_to_data, native_byte_to_data,
    native_short_to_data, native_integer_to_data, native_long_to_data,
    native_scalar_to_data, native_double_to_data,

    {*************************************************}
    { routines for converting data to primitive types }
    {*************************************************}
    native_data_to_boolean, native_data_to_char, native_data_to_byte,
    native_data_to_short, native_data_to_integer, native_data_to_long,
    native_data_to_scalar, native_data_to_double);


{*******************************************************}
{ routines to match native data and method kind by name }
{*******************************************************}
function Found_native_conversion_data_by_name(name: string_type;
  var kind: native_conversion_data_kind_type): boolean;
function Found_native_conversion_method_by_name(name: string_type;
  var kind: native_conversion_method_kind_type): boolean;

{************************************************}
{ routines to query native data and method kinds }
{************************************************}
function Native_conversion_data_number: integer;
function Native_conversion_method_number: integer;


implementation
uses
  hashtables;


var
  native_data_table_ptr: hashtable_ptr_type;
  native_method_table_ptr: hashtable_ptr_type;


{*******************************************************}
{ routines to match native data and method kind by name }
{*******************************************************}


function Found_native_conversion_data_by_name(name: string_type;
  var kind: native_conversion_data_kind_type): boolean;
var
  found: boolean;
  value: hashtable_value_type;
begin
  if Found_hashtable_value_by_key(native_data_table_ptr, value, name) then
    begin
      kind := native_conversion_data_kind_type(value);
      found := true;
    end
  else
    found := false;

  Found_native_conversion_data_by_name := found;
end; {function Found_native_conversion_data_by_name}


function Found_native_conversion_method_by_name(name: string_type;
  var kind: native_conversion_method_kind_type): boolean;
var
  found: boolean;
  value: hashtable_value_type;
begin
  if Found_hashtable_value_by_key(native_method_table_ptr, value, name) then
    begin
      kind := native_conversion_method_kind_type(value);
      found := true;
    end
  else
    found := false;

  Found_native_conversion_method_by_name := found;
end; {function Found_native_conversion_method_by_name}


{************************************************}
{ routines to query native data and method kinds }
{************************************************}


function Native_conversion_data_number: integer;
begin
  Native_conversion_data_number := 0;
end; {function Native_conversion_data_number}


function Native_conversion_method_number: integer;
begin
  Native_conversion_method_number := ord(native_data_to_double) + 1;
end; {function Native_conversion_method_number}


initialization
  native_data_table_ptr := New_hashtable;
  native_method_table_ptr := New_hashtable;

  {*************************************************}
  { routines for converting primitive types to data }
  {*************************************************}
  Enter_hashtable(native_method_table_ptr, 'boolean_to_data',
    ord(native_boolean_to_data));
  Enter_hashtable(native_method_table_ptr, 'char_to_data',
    ord(native_char_to_data));
  Enter_hashtable(native_method_table_ptr, 'byte_to_data',
    ord(native_byte_to_data));
  Enter_hashtable(native_method_table_ptr, 'short_to_data',
    ord(native_short_to_data));
  Enter_hashtable(native_method_table_ptr, 'integer_to_data',
    ord(native_integer_to_data));
  Enter_hashtable(native_method_table_ptr, 'long_to_data',
    ord(native_long_to_data));
  Enter_hashtable(native_method_table_ptr, 'scalar_to_data',
    ord(native_scalar_to_data));
  Enter_hashtable(native_method_table_ptr, 'double_to_data',
    ord(native_double_to_data));

  {*************************************************}
  { routines for converting data to primitive types }
  {*************************************************}
  Enter_hashtable(native_method_table_ptr, 'data_to_boolean',
    ord(native_data_to_boolean));
  Enter_hashtable(native_method_table_ptr, 'data_to_char',
    ord(native_data_to_char));
  Enter_hashtable(native_method_table_ptr, 'data_to_byte',
    ord(native_data_to_byte));
  Enter_hashtable(native_method_table_ptr, 'data_to_short',
    ord(native_data_to_short));
  Enter_hashtable(native_method_table_ptr, 'data_to_integer',
    ord(native_data_to_integer));
  Enter_hashtable(native_method_table_ptr, 'data_to_long',
    ord(native_data_to_long));
  Enter_hashtable(native_method_table_ptr, 'data_to_scalar',
    ord(native_data_to_scalar));
  Enter_hashtable(native_method_table_ptr, 'data_to_double',
    ord(native_data_to_double));
end.
