unit exec_native_system;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          exec_native_system           3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines for executing native      }
{       system methods.                                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  pixels, addr_types, native_system;


{****************************************************************}
{ routine to switch between and execute native system procedures }
{****************************************************************}
procedure Exec_native_system_method(kind: native_system_method_kind_type);

{*********************************************}
{ routines to access fields of a window class }
{*********************************************}
procedure Set_window_data(memref: memref_type;
  name_handle: handle_type;
  size, center: pixel_type;
  window_id: integer);
procedure Get_window_data(memref: memref_type;
  var name_handle: handle_type;
  var size, center: pixel_type;
  var window_id: integer);


implementation
uses
  vectors, strings, colors, video, select_video, set_stack_data, get_params,
  get_data, handles, get_heap_data, set_heap_data, op_stacks, mouse_input,
  keyboard_input, system_sounds, clock_time, images, image_files, data_types,
  pixel_colors, vectors2, system_interfaces;


{*******************}
{ screen primitives }
{*******************}


procedure Eval_screen_width;
begin
  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_integer_operand(Get_screen_size.h);
end; {procedure Eval_screen_width}


procedure Eval_screen_height;
begin
  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_integer_operand(Get_screen_size.v);
end; {procedure Eval_screen_height}


{*********************}
{ graphics primitives }
{*********************}


procedure Set_window_data(memref: memref_type;
  name_handle: handle_type;
  size, center: pixel_type;
  window_id: integer);
begin
  Set_memref_handle(memref, 2, Clone_handle(name_handle));
  Set_memref_integer(memref, 3, size.h);
  Set_memref_integer(memref, 4, size.v);
  Set_memref_integer(memref, 5, center.h);
  Set_memref_integer(memref, 6, center.v);
  Set_memref_integer(memref, 7, window_id);
end; {procedure Set_window_data}


procedure Get_window_data(memref: memref_type;
  var name_handle: handle_type;
  var size, center: pixel_type;
  var window_id: integer);
begin
  name_handle := Get_memref_handle(memref, 2);
  size.h := Get_memref_integer(memref, 3);
  size.v := Get_memref_integer(memref, 4);
  center.h := Get_memref_integer(memref, 5);
  center.v := Get_memref_integer(memref, 6);
  window_id := Get_memref_integer(memref, 7);
end; {procedure Get_window_data}


procedure Exec_open_window;
var
  param_index: stack_index_type;
  memref: memref_type;
  handle: handle_type;
  size, center: pixel_type;
  video_window: video_window_type;
  window_title: string_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  memref := Get_memref_param(param_index);
  handle := Get_handle_param(param_index);
  size.h := Get_integer_param(param_index);
  size.v := Get_integer_param(param_index);
  center.h := Get_integer_param(param_index);
  center.v := Get_integer_param(param_index);

  {***********************************}
  { create appropriate type of window }
  {***********************************}
  video_window := Select_new_window([]);

  {**********************}
  { actually open window }
  {**********************}
  window_title := Get_string(handle);
  video_window.Open(window_title, size, center);

  {**************************************}
  { store window data in object instance }
  {**************************************}
  Set_window_data(memref, handle, size, center, longint(video_window));
end; {procedure Exec_open_window}


procedure Exec_close_window;
var
  param_index: stack_index_type;
  memref: memref_type;
  video_window: video_window_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  memref := Get_memref_param(param_index);

  {********************************************}
  { get window id from struct and close window }
  {********************************************}
  video_window := video_window_type(Get_memref_long(memref, 7));
  video_window.Close;

  {**************************************}
  { store window data in object instance }
  {**************************************}
  Set_memref_integer(memref, 2, 0);
  Set_memref_integer(memref, 3, 0);
  Set_memref_integer(memref, 4, 0);
  Set_memref_integer(memref, 5, 0);
  Set_memref_handle(memref, 6, 0);
  Set_memref_integer(memref, 7, 0);
end; {procedure Exec_close_window}


procedure Exec_clear_window;
var
  param_index: stack_index_type;
  memref: memref_type;
  video_window: video_window_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  memref := Get_memref_param(param_index);

  {******************************************}
  { get window id from struct and set window }
  {******************************************}
  video_window := video_window_type(Get_memref_long(memref, 7));
  video_window.Clear;
end; {procedure Exec_clear_window}


procedure Exec_update_window;
var
  param_index: stack_index_type;
  memref: memref_type;
  video_window: video_window_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  memref := Get_memref_param(param_index);

  {*********************************************}
  { get window id from struct and update window }
  {*********************************************}
  video_window := video_window_type(Get_memref_long(memref, 7));
  video_window.Update;
end; {procedure Exec_update_window}


{********************}
{ drawing primitives }
{********************}


procedure Exec_set_color;
var
  param_index: stack_index_type;
  memref: memref_type;
  color: color_type;
  video_window: video_window_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  memref := Get_memref_param(param_index);
  color := Vector_to_color(Get_vector_param(param_index));

  {*****************************************}
  { get window id from struct and set color }
  {*****************************************}
  video_window := video_window_type(Get_memref_long(memref, 7));
  video_window.Set_color(color);
end; {procedure Exec_set_color}


procedure Exec_draw_line;
var
  param_index: stack_index_type;
  memref: memref_type;
  pixel1, pixel2: pixel_type;
  video_window: video_window_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  memref := Get_memref_param(param_index);
  pixel1.h := Get_integer_param(param_index);
  pixel1.v := Get_integer_param(param_index);
  pixel2.h := Get_integer_param(param_index);
  pixel2.v := Get_integer_param(param_index);

  {*****************************************}
  { get window id from struct and draw line }
  {*****************************************}
  video_window := video_window_type(Get_memref_integer(memref, 7));
  video_window.Draw_line(pixel1, pixel2);
end; {procedure Exec_draw_line}


procedure Exec_draw_rect;
var
  param_index: stack_index_type;
  memref: memref_type;
  pixel1, pixel2: pixel_type;
  video_window: video_window_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  memref := Get_memref_param(param_index);
  pixel1.h := Get_integer_param(param_index);
  pixel1.v := Get_integer_param(param_index);
  pixel2.h := Get_integer_param(param_index);
  pixel2.v := Get_integer_param(param_index);

  {*****************************************}
  { get window id from struct and draw rect }
  {*****************************************}
  video_window := video_window_type(Get_memref_long(memref, 7));
  video_window.Draw_rect(pixel1, pixel2);
end; {procedure Exec_draw_rect}


{******************}
{ mouse primitives }
{******************}


procedure Eval_get_mouse;
var
  param_index: stack_index_type;
  coord_kind: mouse_coord_kind_type;
  window_size: pixel_type;
  screen_size: pixel_type;
  pixel: pixel_type;
  x, y: real;
begin
  x := 0;
  y := 0;

  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  coord_kind := mouse_coord_kind_index_array[Get_integer_param(param_index)];

  if current_window <> nil then
    begin
      case coord_kind of

        raster_mouse:
          begin
            pixel := Get_mouse;
            x := pixel.h;
            y := pixel.v;
          end;

        screen_mouse:
          begin
            pixel := Get_mouse;
            x := pixel.h;
            y := pixel.v;

            window_size := current_window.Get_size;
            if (window_size.h <> 0) and (window_size.v <> 0) then
              begin
                {*****************}
                { scale to window }
                {*****************}
                x := (x / window_size.h) * 2 - 1;
                y := (y / window_size.v) * (-2) + 1;
              end
            else
              begin
                screen_size := Get_screen_size;
                if (screen_size.h <> 0) and (screen_size.v <> 0) then
                  begin
                    {**********************}
                    { scale to root window }
                    {**********************}
                    x := (x / screen_size.h) * 2 - 1;
                    y := (y / screen_size.v) * (-2) + 1;
                  end;
              end;
          end;

      end; {case}
    end
  else
    begin
      x := 0;
      y := 0;
    end;

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_vector_operand(To_vector(x, y, 0));
end; {procedure Eval_get_mouse}


procedure Eval_mouse_down;
var
  param_index: stack_index_type;
  button: integer;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  button := Get_integer_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_boolean_operand(Mouse_down(button));
end; {procedure Eval_mouse_down}


{*********************}
{ keyboard primitives }
{*********************}


procedure Eval_get_key;
begin
  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_integer_operand(Get_key);
end; {procedure Eval_get_key}


procedure Eval_key_down;
var
  param_index: stack_index_type;
  key: integer;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  key := Get_integer_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_boolean_operand(Key_down(key));
end; {procedure Eval_key_down}


procedure Eval_key_to_char;
var
  param_index: stack_index_type;
  key: integer;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  key := Get_integer_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_char_operand(Key_to_char(key));
end; {procedure Eval_key_to_char}


procedure Eval_char_to_key;
var
  param_index: stack_index_type;
  c: char;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  c := Get_char_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_integer_operand(Char_to_key(c));
end; {procedure Eval_char_to_key}


{******************}
{ image primitives }
{******************}


procedure Exec_new_image;
var
  param_index: stack_index_type;
  memref: memref_type;
  handle: handle_type;
  image_ptr: image_ptr_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  memref := Get_memref_param(param_index);
  handle := Get_handle_param(param_index);

  {*********************}
  { actually open image }
  {*********************}
  image_ptr := Load_image(Get_string(handle));

  {**************************************}
  { store window data in object instance }
  {**************************************}
  Set_memref_long(memref, 2, long_type(image_ptr));
end; {procedure Exec_new_image}


procedure Exec_get_color_image;
var
  param_index: stack_index_type;
  memref: memref_type;
  x, y: real;
  interpolation: boolean;
  pixel_color: pixel_color_type;
  image_ptr: image_ptr_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  memref := Get_memref_param(param_index);
  x := Get_scalar_param(param_index);
  y := Get_scalar_param(param_index);
  interpolation := Get_boolean_param(param_index);

  {**********************}
  { get color from image }
  {**********************}
  image_ptr := image_ptr_type(Get_memref_long(memref, 2));
  if interpolation then
    pixel_color := Interpolate_image_color(image_ptr, To_vector2(x, y))
  else
    pixel_color := Get_image_color(image_ptr, To_pixel(Trunc(x), Trunc(y)));

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_color_operand(Pixel_color_to_color(pixel_color));
end; {procedure Exec_get_color_image}


procedure Exec_free_image;
var
  param_index: stack_index_type;
  memref: memref_type;
  image_ptr: image_ptr_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  memref := Get_memref_param(param_index);

  {*******************}
  { free native image }
  {*******************}
  image_ptr := image_ptr_type(Get_memref_long(memref, 2));
  Free_image(image_ptr);
end; {procedure Exec_free_image}


{******************}
{ sound primitives }
{******************}


procedure Exec_beep;
begin
  Sound_beep;
end; {procedure Exec_beep}


procedure Exec_new_sound;
var
  param_index: stack_index_type;
  memref: memref_type;
  name: string_type;
  sound_ptr: sound_ptr_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  memref := Get_memref_param(param_index);
  name := Get_string_param(param_index);

  {******************}
  { create new sound }
  {******************}
  sound_ptr := Open_sound(name);

  {*************************************}
  { store sound data in object instance }
  {*************************************}
  Set_memref_long(memref, 2, longint(sound_ptr));
end; {procedure Exec_new_sound}


procedure Exec_play_sound;
var
  param_index: stack_index_type;
  memref: memref_type;
  sound_ptr: sound_ptr_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  memref := Get_memref_param(param_index);

  {***********************}
  { get sound from object }
  {***********************}
  sound_ptr := sound_ptr_type(Get_memref_long(memref, 2));
  Play_sound(sound_ptr);
end; {procedure Exec_play_sound}


procedure Exec_start_sound;
var
  param_index: stack_index_type;
  memref: memref_type;
  sound_ptr: sound_ptr_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  memref := Get_memref_param(param_index);

  {***********************}
  { get sound from object }
  {***********************}
  sound_ptr := sound_ptr_type(Get_memref_long(memref, 2));
  Start_sound(sound_ptr);
end; {procedure Exec_start_sound}


procedure Exec_stop_sound;
var
  param_index: stack_index_type;
  memref: memref_type;
  sound_ptr: sound_ptr_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  memref := Get_memref_param(param_index);

  {***********************}
  { get sound from object }
  {***********************}
  sound_ptr := sound_ptr_type(Get_memref_long(memref, 2));
  Stop_sound(sound_ptr);
end; {procedure Exec_stop_sound}


procedure Exec_free_sound;
var
  param_index: stack_index_type;
  memref: memref_type;
  sound_ptr: sound_ptr_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  memref := Get_memref_param(param_index);

  {***********************}
  { get sound from object }
  {***********************}
  sound_ptr := sound_ptr_type(Get_memref_long(memref, 2));
  Free_sound(sound_ptr);
end; {procedure Exec_free_sound}


{*****************}
{ time primitives }
{*****************}


procedure Eval_get_time;
var
  hours, minutes, seconds: real;
begin
  Get_time(hours, minutes, seconds);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_vector_operand(To_vector(hours, minutes, seconds));
end; {procedure Eval_get_time}


{**********************}
{ interface primitives }
{**********************}


procedure Exec_show_text;
begin
  {ShowText;}
end; {procedure Exec_show_text}


procedure Exec_hide_text;
begin
  {HideAll;}
end; {procedure Exec_hide_text}


procedure Exec_system;
var
  param_index: stack_index_type;
  message: string;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  message := Get_string_param(param_index);

  {*********************}
  { execute system call }
  {*********************}
  System_call(message);
end; {procedure Exec_system}


procedure Exec_set_url;
var
  param_index: stack_index_type;
  url: string;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  url := Get_string_param(param_index);

  {*********************}
  { execute system call }
  {*********************}
  Set_url(url);
end; {procedure Exec_set_url}


procedure Exec_set_status;
var
  param_index: stack_index_type;
  status: string;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  status := Get_string_param(param_index);

  {*********************}
  { execute system call }
  {*********************}
  Set_status(status);
end; {procedure Exec_set_url}


{****************************************************************}
{ routine to switch between and execute native system procedures }
{****************************************************************}


procedure Exec_native_system_method(kind: native_system_method_kind_type);
begin
  case kind of

    {*****************}
    { screen geometry }
    {*****************}
    native_screen_width:
      Eval_screen_width;
    native_screen_height:
      Eval_screen_height;

    {*********************}
    { graphics primitives }
    {*********************}
    native_open_window:
      Exec_open_window;
    native_close_window:
      Exec_close_window;
    native_clear_window:
      Exec_clear_window;
    native_update_window:
      Exec_update_window;

    {********************}
    { drawing primitives }
    {********************}
    native_set_color:
      Exec_set_color;
    native_draw_line:
      Exec_draw_line;
    native_draw_rect:
      Exec_draw_rect;

    {******************}
    { mouse primitives }
    {******************}
    native_get_mouse:
      Eval_get_mouse;
    native_mouse_down:
      Eval_mouse_down;

    {*********************}
    { keyboard_primitives }
    {*********************}
    native_get_key:
      Eval_get_key;
    native_key_down:
      Eval_key_down;
    native_key_to_char:
      Eval_key_to_char;
    native_char_to_key:
      Eval_char_to_key;

    {******************}
    { image primitives }
    {******************}
    native_new_image:
      Exec_new_image;
    native_get_color_image:
      Exec_get_color_image;
    native_free_image:
      Exec_free_image;

    {******************}
    { sound primitives }
    {******************}
    native_beep:
      Exec_beep;
    native_new_sound:
      Exec_new_sound;
    native_play_sound:
      Exec_play_sound;
    native_start_sound:
      Exec_start_sound;
    native_stop_sound:
      Exec_stop_sound;
    native_free_sound:
      Exec_free_sound;

    {*****************}
    { time primitives }
    {*****************}
    native_get_time:
      Eval_get_time;

    {**********************}
    { interface primitives }
    {**********************}
    native_show_text:
      Exec_show_text;
    native_hide_text:
      Exec_hide_text;
    native_set_url:
      Exec_set_url;
    native_set_status:
      Exec_set_status;
    native_system_command:
      Exec_system;

  end; {case}
end; {procedure Exec_native_system_method}


end.

