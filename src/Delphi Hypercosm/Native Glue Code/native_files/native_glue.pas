unit native_glue;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            native_glue                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{	This module is used to glue native code to              }
{	interpreter code.					}
{								}
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


{*******************************************************}
{ routines to match native data and method kind by name }
{*******************************************************}
function Found_native_data_by_name(name: string_type;
  var index: integer): boolean;
function Found_native_method_by_name(name: string_type;
  var index: integer): boolean;


implementation
uses
  native_math, native_system, native_model, native_render, native_collision;


function Found_native_data_by_name(name: string_type;
  var index: integer): boolean;
var
  found: boolean;
  native_math_data_kind: native_math_data_kind_type;
  native_system_data_kind: native_system_data_kind_type;
  native_model_data_kind: native_model_data_kind_type;
  native_render_data_kind: native_render_data_kind_type;
  native_collision_data_kind: native_collision_data_kind_type;
begin
  index := 0;
  found := false;

  {************************}
  { check native math data }
  {************************}
  if not found then
    if Found_native_math_data_by_name(name, native_math_data_kind) then
      begin
        index := index + ord(native_math_data_kind);
        found := true;
      end
    else
      index := index + Native_math_data_number;

  {**************************}
  { check native system data }
  {**************************}
  if not found then
    if Found_native_system_data_by_name(name, native_system_data_kind) then
      begin
        index := index + ord(native_system_data_kind);
        found := true;
      end
    else
      index := index + Native_system_data_number;

  {*************************}
  { check native model data }
  {*************************}
  if not found then
    if Found_native_model_data_by_name(name, native_model_data_kind) then
      begin
        index := index + ord(native_model_data_kind);
        found := true;
      end
    else
      index := index + Native_model_data_number;

  {**************************}
  { check native render data }
  {**************************}
  if not found then
    if Found_native_render_data_by_name(name, native_render_data_kind) then
      begin
        index := index + ord(native_render_data_kind);
        found := true;
      end
    else
      index := index + Native_render_data_number;

  {*****************************}
  { check native collision data }
  {*****************************}
  if not found then
    if Found_native_collision_data_by_name(name, native_collision_data_kind)
      then
      begin
        index := index + ord(native_collision_data_kind);
        found := true;
      end
    else
      index := index + Native_collision_data_number;

  if not found then
    index := 0;

  Found_native_data_by_name := found;
end; {function Found_native_data_by_name}


{***************************************}
{ routines to match method kind by name }
{***************************************}


function Found_native_method_by_name(name: string_type;
  var index: integer): boolean;
var
  found: boolean;
  native_math_method_kind: native_math_method_kind_type;
  native_system_method_kind: native_system_method_kind_type;
  native_model_method_kind: native_model_method_kind_type;
  native_render_method_kind: native_render_method_kind_type;
  native_collision_method_kind: native_collision_method_kind_type;
begin
  index := 0;
  found := false;

  {**************************}
  { check native math method }
  {**************************}
  if not found then
    if Found_native_math_method_by_name(name, native_math_method_kind) then
      begin
        index := index + ord(native_math_method_kind);
        found := true;
      end
    else
      index := index + Native_math_method_number;

  {****************************}
  { check native system method }
  {****************************}
  if not found then
    if Found_native_system_method_by_name(name, native_system_method_kind) then
      begin
        index := index + ord(native_system_method_kind);
        found := true;
      end
    else
      index := index + Native_system_method_number;

  {***************************}
  { check native model method }
  {***************************}
  if not found then
    if Found_native_model_method_by_name(name, native_model_method_kind) then
      begin
        index := index + ord(native_model_method_kind);
        found := true;
      end
    else
      index := index + Native_model_method_number;

  {****************************}
  { check native render method }
  {****************************}
  if not found then
    if Found_native_render_method_by_name(name, native_render_method_kind) then
      begin
        index := index + ord(native_render_method_kind);
        found := true;
      end
    else
      index := index + Native_render_method_number;

  {*******************************}
  { check native collision method }
  {*******************************}
  if not found then
    if Found_native_collision_method_by_name(name, native_collision_method_kind)
      then
      begin
        index := index + ord(native_collision_method_kind);
        found := true;
      end
    else
      index := index + Native_collision_method_number;

  if not found then
    index := 0;

  Found_native_method_by_name := found;
end; {function Found_native_method_by_name}


end.
