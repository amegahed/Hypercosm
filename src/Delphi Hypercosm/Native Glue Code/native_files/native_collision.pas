unit native_collision;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          native_collision             3d       }
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
  {                  native collision data kinds                  }
  {***************************************************************}
  native_collision_data_kind_type = integer;


  {***************************************************************}
  {                  native collision method kinds                }
  {***************************************************************}
  native_collision_method_kind_type = (

    {********************************}
    { collision detection primitives }
    {********************************}
    native_object_hits_object, native_ray_hits_object,

    {**********************}
    { proximity primitives }
    {**********************}
    native_closest_to_point, native_closest_to_plane,

    {***********************}
    { ray casting primitive }
    {***********************}
    native_project_ray);


{*******************************************************}
{ routines to match native data and method kind by name }
{*******************************************************}
function Found_native_collision_data_by_name(name: string_type;
  var kind: native_collision_data_kind_type): boolean;
function Found_native_collision_method_by_name(name: string_type;
  var kind: native_collision_method_kind_type): boolean;

{************************************************}
{ routines to query native data and method kinds }
{************************************************}
function Native_collision_data_number: integer;
function Native_collision_method_number: integer;


implementation
uses
  hashtables;


var
  native_data_table_ptr: hashtable_ptr_type;
  native_method_table_ptr: hashtable_ptr_type;


{*******************************************************}
{ routines to match native data and method kind by name }
{*******************************************************}


function Found_native_collision_data_by_name(name: string_type;
  var kind: native_collision_data_kind_type): boolean;
var
  found: boolean;
  value: hashtable_value_type;
begin
  if Found_hashtable_value_by_key(native_data_table_ptr, value, name) then
    begin
      kind := native_collision_data_kind_type(value);
      found := true;
    end
  else
    found := false;

  Found_native_collision_data_by_name := found;
end; {function Found_native_collision_data_by_name}


function Found_native_collision_method_by_name(name: string_type;
  var kind: native_collision_method_kind_type): boolean;
var
  found: boolean;
  value: hashtable_value_type;
begin
  if Found_hashtable_value_by_key(native_method_table_ptr, value, name) then
    begin
      kind := native_collision_method_kind_type(value);
      found := true;
    end
  else
    found := false;

  Found_native_collision_method_by_name := found;
end; {function Found_native_collision_method_by_name}


{************************************************}
{ routines to query native data and method kinds }
{************************************************}


function Native_collision_data_number: integer;
begin
  Native_collision_data_number := 0;
end; {function Native_collision_data_number}


function Native_collision_method_number: integer;
begin
  Native_collision_method_number := ord(native_project_ray) + 1;
end; {function Native_collision_method_number}


initialization
  native_data_table_ptr := New_hashtable;
  native_method_table_ptr := New_hashtable;

  {********************************}
  { collision detection primitives }
  {********************************}
  Enter_hashtable(native_method_table_ptr, 'shape_hits_shape',
    ord(native_object_hits_object));
  Enter_hashtable(native_method_table_ptr, 'ray_hits_shape',
    ord(native_ray_hits_object));

  {**********************}
  { proximity primitives }
  {**********************}
  Enter_hashtable(native_method_table_ptr, 'closest_to_point',
    ord(native_closest_to_point));
  Enter_hashtable(native_method_table_ptr, 'closest_to_plane',
    ord(native_closest_to_plane));

  {***********************}
  { ray casting primitive }
  {***********************}
  Enter_hashtable(native_method_table_ptr, 'project', ord(native_project_ray));
end.
