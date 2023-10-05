unit exec_native;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             exec_native               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is responsible for executing native         }
{       procedures and assignments                              }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  addr_types;


{************************************************}
{ set indices to execute native data assignments }
{************************************************}
procedure Set_native_data_index(native_index: integer;
  stack_index: stack_index_type);

{*********************************************************}
{ routine to switch between and execute native methods }
{*********************************************************}
procedure Exec_native_method(native_index: integer);


implementation
uses
  errors, objects, native_math, native_system, native_model, native_render,
  native_collision, assign_native_model, assign_native_render, exec_native_math,
  exec_native_system, exec_native_model, exec_native_render,
  exec_native_collision;


{************************************************}
{ set indices to execute native data assignments }
{************************************************}


procedure Set_native_data_index(native_index: integer;
  stack_index: stack_index_type);
var
  done: boolean;
begin
  done := false;

  {****************************}
  { check for native math data }
  {****************************}
  if not done then
    if native_index < Native_math_data_number then
      begin
        Error('Found invalid native data.');
        done := true;
      end
    else
      native_index := native_index - Native_math_data_number;

  {******************************}
  { check for native system data }
  {******************************}
  if not done then
    if native_index < Native_system_data_number then
      begin
        Error('Found invalid native data.');
        done := true;
      end
    else
      native_index := native_index - Native_system_data_number;

  {*****************************}
  { check for native model data }
  {*****************************}
  if not done then
    if native_index < Native_model_data_number then
      begin
        Set_native_model_data_index(native_model_data_kind_type(native_index),
          stack_index);
        done := true;
      end
    else
      native_index := native_index - Native_model_data_number;

  {******************************}
  { check for native render data }
  {******************************}
  if not done then
    if native_index < Native_render_data_number then
      begin
        Set_native_render_data_index(native_render_data_kind_type(native_index),
          stack_index);
        done := true;
      end
    else
      native_index := native_index - Native_render_data_number;

  {*********************************}
  { check for native collision data }
  {*********************************}
  if not done then
    if native_index < Native_collision_data_number then
      begin
        Error('Found invalid native data.');
      end
    else
      Error('Found invalid native data.');
end; {procedure Set_native_data_index}


{******************************************************}
{ routine to switch between and execute native methods }
{******************************************************}


procedure Exec_native_method(native_index: integer);
var
  done: boolean;
begin
  done := false;

  {******************************}
  { check for native math method }
  {******************************}
  if not done then
    if native_index < Native_math_method_number then
      begin
        Exec_native_math_method(native_math_method_kind_type(native_index));
        done := true;
      end
    else
      native_index := native_index - Native_math_method_number;

  {********************************}
  { check for native system method }
  {********************************}
  if not done then
    if native_index < Native_system_method_number then
      begin
        Exec_native_system_method(native_system_method_kind_type(native_index));
        done := true;
      end
    else
      native_index := native_index - Native_system_method_number;

  {*******************************}
  { check for native model method }
  {*******************************}
  if not done then
    if native_index < Native_model_method_number then
      begin
        Exec_native_model_method(native_model_method_kind_type(native_index));
        done := true;
      end
    else
      native_index := native_index - Native_model_method_number;

  {********************************}
  { check for native render method }
  {********************************}
  if not done then
    if native_index < Native_render_method_number then
      begin
        Exec_native_render_method(native_render_method_kind_type(native_index));
        done := true;
      end
    else
      native_index := native_index - Native_render_method_number;

  {***********************************}
  { check for native collision method }
  {***********************************}
  if not done then
    if native_index < Native_collision_method_number then
      begin
        Exec_native_collision_method(native_collision_method_kind_type(native_index));
      end
    else
      Error('Found invalid native method.');
end; {procedure Exec_native_method}


end.
