unit native_system;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           native_system               3d       }
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
  {                 native system enumerated kinds                }
  {***************************************************************}
  mouse_coord_kind_type = (raster_mouse, screen_mouse);


  {***************************************************************}
  {                    native system data kinds                   }
  {***************************************************************}
  native_system_data_kind_type = integer;


  {***************************************************************}
  {                   native system method kinds                  }
  {***************************************************************}
  native_system_method_kind_type = (

    {*****************}
    { screen geometry }
    {*****************}
    native_screen_width, native_screen_height,

    {*********************}
    { graphics primitives }
    {*********************}
    native_open_window, native_close_window, native_clear_window,
    native_update_window,

    {********************}
    { drawing primitives }
    {********************}
    native_set_color, native_draw_line, native_draw_rect,

    {******************}
    { mouse primitives }
    {******************}
    native_get_mouse, native_mouse_down,

    {*********************}
    { keyboard_primitives }
    {*********************}
    native_get_key, native_key_down, native_key_to_char, native_char_to_key,

    {******************}
    { image primitives }
    {******************}
    native_new_image, native_get_color_image, native_free_image,

    {******************}
    { sound primitives }
    {******************}
    native_beep, native_new_sound, native_play_sound, native_start_sound,
    native_stop_sound, native_free_sound,

    {*****************}
    { time primitives }
    {*****************}
    native_get_time,

    {**********************}
    { interface primitives }
    {**********************}
    native_show_text, native_hide_text, native_set_url, native_set_status,
    native_system_command);


var
  {****************************************************}
  { arrays for converting integers to enumerated types }
  {****************************************************}
  mouse_coord_kind_index_array: array[1..2] of mouse_coord_kind_type;


{*******************************************************}
{ routines to match native data and method kind by name }
{*******************************************************}
function Found_native_system_data_by_name(name: string_type;
  var kind: native_system_data_kind_type): boolean;
function Found_native_system_method_by_name(name: string_type;
  var kind: native_system_method_kind_type): boolean;

{************************************************}
{ routines to query native data and method kinds }
{************************************************}
function Native_system_data_number: integer;
function Native_system_method_number: integer;


implementation
uses
  hashtables;


var
  native_data_table_ptr: hashtable_ptr_type;
  native_method_table_ptr: hashtable_ptr_type;


{*******************************************************}
{ routines to match native data and method kind by name }
{*******************************************************}


function Found_native_system_data_by_name(name: string_type;
  var kind: native_system_data_kind_type): boolean;
var
  found: boolean;
  value: hashtable_value_type;
begin
  if Found_hashtable_value_by_key(native_data_table_ptr, value, name) then
    begin
      kind := native_system_data_kind_type(value);
      found := true;
    end
  else
    found := false;

  Found_native_system_data_by_name := found;
end; {function Found_native_system_data_by_name}


function Found_native_system_method_by_name(name: string_type;
  var kind: native_system_method_kind_type): boolean;
var
  found: boolean;
  value: hashtable_value_type;
begin
  if Found_hashtable_value_by_key(native_method_table_ptr, value, name) then
    begin
      kind := native_system_method_kind_type(value);
      found := true;
    end
  else
    found := false;

  Found_native_system_method_by_name := found;
end; {function Found_native_system_method_by_name}


{************************************************}
{ routines to query native data and method kinds }
{************************************************}


function Native_system_data_number: integer;
begin
  Native_system_data_number := 0;
end; {function Native_system_data_number}


function Native_system_method_number: integer;
begin
  Native_system_method_number := ord(native_system_command) + 1;
end; {function Native_system_method_number}


initialization
  native_data_table_ptr := New_hashtable;
  native_method_table_ptr := New_hashtable;

  {*************************************************************}
  { display, screen, camera, global, local, surface, parametric }
  {*************************************************************}
  mouse_coord_kind_index_array[1] := raster_mouse;
  mouse_coord_kind_index_array[2] := screen_mouse;

  {*****************}
  { screen geometry }
  {*****************}
  Enter_hashtable(native_method_table_ptr, 'screen_width',
    ord(native_screen_width));
  Enter_hashtable(native_method_table_ptr, 'screen_height',
    ord(native_screen_height));

  {*********************}
  { graphics primitives }
  {*********************}
  Enter_hashtable(native_method_table_ptr, 'window new',
    ord(native_open_window));
  Enter_hashtable(native_method_table_ptr, 'window close',
    ord(native_close_window));
  Enter_hashtable(native_method_table_ptr, 'window clear',
    ord(native_clear_window));
  Enter_hashtable(native_method_table_ptr, 'window update',
    ord(native_update_window));

  {********************}
  { drawing primitives }
  {********************}
  Enter_hashtable(native_method_table_ptr, 'window set_color',
    ord(native_set_color));
  Enter_hashtable(native_method_table_ptr, 'window line',
    ord(native_draw_line));
  Enter_hashtable(native_method_table_ptr, 'window rect',
    ord(native_draw_rect));

  {******************}
  { mouse primitives }
  {******************}
  Enter_hashtable(native_method_table_ptr, 'get_mouse', ord(native_get_mouse));
  Enter_hashtable(native_method_table_ptr, 'mouse_down',
    ord(native_mouse_down));

  {*********************}
  { keyboard primitives }
  {*********************}
  Enter_hashtable(native_method_table_ptr, 'get_key', ord(native_get_key));
  Enter_hashtable(native_method_table_ptr, 'key_down', ord(native_key_down));
  Enter_hashtable(native_method_table_ptr, 'key_to_char',
    ord(native_key_to_char));
  Enter_hashtable(native_method_table_ptr, 'char_to_key',
    ord(native_char_to_key));

  {******************}
  { image primitives }
  {******************}
  Enter_hashtable(native_method_table_ptr, 'image new', ord(native_new_image));
  Enter_hashtable(native_method_table_ptr, 'image get_color',
    ord(native_get_color_image));
  Enter_hashtable(native_method_table_ptr, 'image free',
    ord(native_free_image));

  {******************}
  { sound primitives }
  {******************}
  Enter_hashtable(native_method_table_ptr, 'beep', ord(native_beep));
  Enter_hashtable(native_method_table_ptr, 'sound new', ord(native_new_sound));
  Enter_hashtable(native_method_table_ptr, 'sound play',
    ord(native_play_sound));
  Enter_hashtable(native_method_table_ptr, 'sound start',
    ord(native_start_sound));
  Enter_hashtable(native_method_table_ptr, 'sound stop',
    ord(native_stop_sound));
  Enter_hashtable(native_method_table_ptr, 'sound free',
    ord(native_free_sound));

  {*****************}
  { time primitives }
  {*****************}
  Enter_hashtable(native_method_table_ptr, 'get_time', ord(native_get_time));

  {**********************}
  { interface primitives }
  {**********************}
  Enter_hashtable(native_method_table_ptr, 'show_text', ord(native_show_text));
  Enter_hashtable(native_method_table_ptr, 'hide_text', ord(native_hide_text));
  Enter_hashtable(native_method_table_ptr, 'set_url', ord(native_set_url));
  Enter_hashtable(native_method_table_ptr, 'set_status',
    ord(native_set_status));
  Enter_hashtable(native_method_table_ptr, 'system',
    ord(native_system_command));
end.

