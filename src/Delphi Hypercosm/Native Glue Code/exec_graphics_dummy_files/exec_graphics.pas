unit exec_graphics;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           exec_graphics               3d       }
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
  vectors;


type
  {***********************************}
  { auxilliary syntax tree data nodes }
  {***********************************}
  code_data_ptr_type = ^code_data_type;
  code_data_type = record
    object_decl_id: integer;
    picture_decl_id: integer;
    picture_number: integer;
    window_id: integer;
    z_buffer_id: integer;
    scan_buffer_id: integer;
    parity_buffer_id: integer;
    next: code_data_ptr_type;
  end; {code_data_type}


var
  object_decl_count, picture_decl_count: integer;


procedure Init_exec_graphics;

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


procedure Init_exec_graphics;
begin
end; {procedure Init_exec_graphics}


{**********************************************************************}
{ routines for sending object attributes to and from interpreter stack }
{**********************************************************************}


procedure Get_model_context;
begin
end; {procedure Get_model_context}


procedure Put_model_context;
begin
end; {procedure Put_model_context}


{*******************************}
{ routines for creating objects }
{*******************************}


procedure Init_model_context;
begin
end; {procedure Init_model_context}


procedure Begin_model_context;
begin
end; {procedure Begin_model_context}


procedure End_model_context;
begin
end; {procedure End_model_context}


procedure Save_model_context;
begin
end; {procedure Save_model_context}


procedure Restore_model_context;
begin
end; {procedure Restore_model_context}


{********************************}
{ procedures for executing anims }
{********************************}


procedure Begin_anim_context;
begin
end; {procedure Begin_anim_context}


procedure End_anim_context;
begin
end; {procedure End_anim_context}


{**********************************}
{ procedures for executing shaders }
{**********************************}


function Shaders_ok: boolean;
begin
  Shaders_ok := false;
end; {function Shaders_ok}


function Get_current_color: vector_type;
begin
  Get_current_color := zero_vector;
end; {function Get_current_color}


{***********************************}
{ procedures for executing pictures }
{***********************************}


procedure Open_picture_window(code_data_ptr: code_data_ptr_type);
begin
end; {procedure Open_picture_window}


procedure Render_picture_window(code_data_ptr: code_data_ptr_type);
begin
end; {procedure Render_picture_window}


{******************************************************}
{ routines for allocating and freeing auxilliary nodes }
{******************************************************}


function New_code_data: code_data_ptr_type;
begin
  New_code_data := nil;
end; {function New_code_data}


procedure Free_code_data(var code_data_ptr: code_data_ptr_type);
begin
end; {procedure Free_code_data}


end. {module exec_graphics}
