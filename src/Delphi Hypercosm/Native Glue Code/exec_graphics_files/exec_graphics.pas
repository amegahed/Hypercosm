unit exec_graphics;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            exec_graphics              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is responsible for the execution of         }
{       methods described by the abstract syntax tree.          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, video, renderer, pixel_color_buffer;


type
  {***********************************}
  { auxilliary syntax tree data nodes }
  {***********************************}
  code_data_ptr_type = ^code_data_type;
  code_data_type = record

    video_window: video_window_type;
    renderer: renderer_type;
    pixel_color_buffer_ptr: pixel_color_buffer_ptr_type;

    object_decl_id: integer;
    picture_decl_id: integer;
    picture_number: integer;

    next: code_data_ptr_type;
  end; {code_data_type}


var
  object_decl_count, picture_decl_count: integer;


{**********************************************************************}
{ routines for sending object attributes to and from interpreter stack }
{**********************************************************************}
procedure Get_model_context;
procedure Put_model_context;

{*******************************}
{ routines for creating objects }
{*******************************}
procedure Init_model_context;

procedure Begin_model_context;
procedure End_model_context;

procedure Save_model_context;
procedure Restore_model_context;

{********************************}
{ procedures for executing anims }
{********************************}
procedure Begin_anim_context;
procedure End_anim_context;

{**********************************}
{ procedures for executing shaders }
{**********************************}
function Shaders_ok: boolean;
function Get_current_color: vector_type;

{***********************************}
{ procedures for executing pictures }
{***********************************}
procedure Open_picture_window(code_data_ptr: code_data_ptr_type);
procedure Render_picture_window(code_data_ptr: code_data_ptr_type);

{******************************************************}
{ routines for allocating and freeing auxilliary nodes }
{******************************************************}
function New_code_data: code_data_ptr_type;
procedure Free_code_data(var code_data_ptr: code_data_ptr_type);


implementation
uses
  errors, new_memory, strings, string_io, trans, trans_stack, colors,
  images, image_files, display_lists, vector_graphics_files, object_attr,
  attr_stack, state_vars, objects, anim, pictures, data, stacks, set_stack_data,
  get_stack_data, assign_native_model, assign_native_render, system_events,
  select_video, interpreter;


const
  debug = false;
  memory_alert = false;


var
  {*********************************}
  { free lists for auxilliary nodes }
  {*********************************}
  code_data_free_list: code_data_ptr_type;

  {*******************}
  { auxilliary stacks }
  {*******************}
  save_model_trans_stack_ptr: trans_stack_ptr_type;
  save_shader_trans_stack_ptr: trans_stack_ptr_type;
  save_model_attr_stack_ptr: attributes_stack_ptr_type;


{******************************************}
{ routines for allocating auxilliary nodes }
{******************************************}


function New_code_data: code_data_ptr_type;
var
  code_data_ptr: code_data_ptr_type;
begin
  {******************************}
  { get code data from free list }
  {******************************}
  if (code_data_free_list <> nil) then
    begin
      code_data_ptr := code_data_free_list;
      code_data_free_list := code_data_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new code data');
      new(code_data_ptr);
    end;

  {**********************}
  { initialize code data }
  {**********************}
  with code_data_ptr^ do
    begin
      video_window := nil;
      renderer := nil;
      object_decl_id := object_decl_count;
      picture_decl_id := picture_decl_count;
      picture_number := 0;
      next := nil;
    end;

  New_code_data := code_data_ptr;
end; {function New_code_data}


{***************************************}
{ routines for freeing auxilliary nodes }
{***************************************}


procedure Free_code_data(var code_data_ptr: code_data_ptr_type);
begin
  {****************************}
  { add code data to free list }
  {****************************}
  code_data_ptr^.next := code_data_free_list;
  code_data_free_list := code_data_ptr;
  code_data_ptr := nil;
end; {procedure Free_code_data}


{**********************************************************************}
{ routines for sending object attributes to and from interpreter stack }
{**********************************************************************}


procedure Get_model_context;
begin
  Get_trans_data;
  Get_shader_trans_data;
  Get_attributes_data;
end; {procedure Get_model_context}


procedure Put_model_context;
begin
  Put_trans_data;
  Put_shader_trans_data;
  Put_attributes_data;
end; {procedure Put_model_context}


{*******************************}
{ routines for creating objects }
{*******************************}


procedure Init_model_context;
begin
  Set_trans_stack(model_trans_stack_ptr, unit_trans);
  Set_trans_stack(shader_trans_stack_ptr, unit_trans);
  Set_attributes_stack(model_attr_stack_ptr, null_attributes);

  Put_model_context;
end; {procedure Init_model_context}


procedure Begin_model_context;
begin
  Get_model_context;

  Push_trans_stack(model_trans_stack_ptr);
  Push_trans_stack(shader_trans_stack_ptr);
  Push_attributes_stack(model_attr_stack_ptr);
end; {procedure Begin_model_context}


procedure End_model_context;
begin
  Pop_trans_stack(model_trans_stack_ptr);
  Pop_trans_stack(shader_trans_stack_ptr);
  Pop_attributes_stack(model_attr_stack_ptr);

  Put_model_context;
end; {procedure End_model_context}


procedure Save_model_context;
var
  model_trans, shader_trans: trans_type;
  attributes: object_attributes_type;
begin
  Get_model_context;

  Get_trans_stack(model_trans_stack_ptr, model_trans);
  Get_trans_stack(shader_trans_stack_ptr, shader_trans);
  Get_attributes_stack(model_attr_stack_ptr, attributes);

  Push_trans_stack(save_model_trans_stack_ptr);
  Push_trans_stack(save_shader_trans_stack_ptr);
  Push_attributes_stack(save_model_attr_stack_ptr);

  Set_trans_stack(save_model_trans_stack_ptr, model_trans);
  Set_trans_stack(save_shader_trans_stack_ptr, shader_trans);
  Set_attributes_stack(save_model_attr_stack_ptr, attributes);
end; {procedure Save_model_context}


procedure Restore_model_context;
var
  model_trans, shader_trans: trans_type;
  attributes: object_attributes_type;
begin
  Get_trans_stack(save_model_trans_stack_ptr, model_trans);
  Get_trans_stack(save_shader_trans_stack_ptr, shader_trans);
  Get_attributes_stack(save_model_attr_stack_ptr, attributes);

  Pop_trans_stack(save_model_trans_stack_ptr);
  Pop_trans_stack(save_shader_trans_stack_ptr);
  Pop_attributes_stack(save_model_attr_stack_ptr);

  Set_trans_stack(model_trans_stack_ptr, model_trans);
  Set_trans_stack(shader_trans_stack_ptr, shader_trans);
  Set_attributes_stack(model_attr_stack_ptr, attributes);

  Put_model_context;
end; {procedure Restore_model_context}


{********************************}
{ procedures for executing anims }
{********************************}


procedure Begin_anim_context;
begin
  animating := true;
  frame_number := starting_frame_number;

  if native_frame_number_index <> 0 then
    Set_global_integer(native_frame_number_index, frame_number);
end; {procedure Begin_anim_context}


procedure End_anim_context;
begin
  animating := false;
end; {procedure End_anim_context}


{**********************************}
{ procedures for executing shaders }
{**********************************}


function Shaders_ok: boolean;
begin
  Shaders_ok := rendering;
end; {function Shaders_ok}


function Get_current_color: vector_type;
var
  color: vector_type;
  data: data_type;
begin
  if native_color_index <> 0 then
    begin
      data := Get_global_stack(native_color_index);

      if data.kind <> error_data then
        color := Get_global_vector(native_color_index)
      else
        color := zero_vector;
    end
  else
    color := zero_vector;

  Get_current_color := color;
end; {function Get_current_color}


{***********************************}
{ procedures for executing pictures }
{***********************************}


procedure Open_picture_window(code_data_ptr: code_data_ptr_type);
begin
  {***************************************************}
  { Open or switch windows - A window must be opened  }
  { before scene is interpreted so that statements in }
  { the body know about the window size and placement }
  { so that the window relative mouse functions work  }
  { properly.                                         }
  {***************************************************}
  Get_picture_data;

  if debug then
    begin
      Write_attributes_data;
      Write_picture_data;
    end;

  if code_data_ptr^.video_window <> nil then
    begin
      {*****************}
      { activate window }
      {*****************}
      code_data_ptr^.video_window.Activate;
    end
  else
    begin
      {***********************************}
      { create appropriate type of window }
      {***********************************}
      code_data_ptr^.video_window := Select_new_window([does_color]);

      {**********************}
      { actually open window }
      {**********************}
      code_data_ptr^.video_window.Open(new_window_name, new_window_size,
        new_window_placement);

      {**************}
      { clear window }
      {**************}
      code_data_ptr^.video_window.Set_color(black_color);
      code_data_ptr^.video_window.Clear;
    end;
end; {procedure Open_picture_window}


procedure Render_picture_window(code_data_ptr: code_data_ptr_type);
var
  name: string_type;
  image_ptr: image_ptr_type;
begin
  with code_data_ptr^ do
    Draw_picture(video_window, renderer, pixel_color_buffer_ptr);

  {**********************}
  { save image to a file }
  {**********************}
  if save_pictures then
    begin
      {*************************************************}
      { get name of picture from native global variable }
      {*************************************************}
      name := image_file_name;
      if (frame_number > 0) then
        Append_str_to_str(Integer_to_str(frame_number), name);

      {******************************}
      { save image in current format }
      {******************************}
      if file_format <> pict_format then
        begin
          // image_ptr := Get_display_image;
          case file_format of
            raw_format:
              Save_raw_image(name, image_ptr);
            targa_format:
              Save_targa_image(name, image_ptr);
          end; // case
          Free_image(image_ptr);
        end
      else
        Save_pict_image(name, Get_display_list);
    end;

  {************************}
  { increment frame number }
  {************************}
  if animating then
    begin
      frame_number := frame_number + 1;
      Set_global_integer(native_frame_number_index, frame_number);
    end;

  Next_object_group;

  {*********************}
  { check system events }
  {*********************}
  Check_system_events;
  if finished then
    Shut_down;
end; {procedure Render_picture_window}


initialization
  object_decl_count := 0;
  picture_decl_count := 0;
  code_data_free_list := nil;

  {************************}
  { init auxilliary stacks }
  {************************}
  save_model_trans_stack_ptr := New_trans_stack;
  save_shader_trans_stack_ptr := New_trans_stack;
  save_model_attr_stack_ptr := New_attributes_stack;
end.

