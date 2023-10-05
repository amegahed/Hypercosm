unit mouse_input;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            mouse_input                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the interface to the mouse         }
{       hardware (mouse and keyboard). Most porting changes     }
{       will be here and in the video and files modules.        }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  pixels;


type
  mouse_state_ptr_type = ^mouse_state_type;
  mouse_state_type = record
    mouse_location: pixel_type;
    button_state: array[1..2] of boolean;
  end; {mouse_state_type}


  {*************************}
  { mouse polling functions }
  {*************************}
function Get_mouse: pixel_type;
function Mouse_down(button_number: integer): boolean;


implementation
uses
  video;


{*************************}
{ mouse polling functions }
{*************************}


function Get_mouse: pixel_type;
var
  pixel: pixel_type;
begin
  if current_window <> nil then
    pixel := current_window.mouse_state.mouse_location
  else
    pixel := null_pixel;

  Get_mouse := pixel;
end; {procedure Get_mouse}


function Mouse_down(button_number: integer): boolean;
var
  state: boolean;
begin
  if current_window <> nil then
    begin
      if (button_number = 1) then
        state := current_window.mouse_state.button_state[1] and (not
          current_window.mouse_state.button_state[2])
      else if (button_number = 2) then
        state := current_window.mouse_state.button_state[1] and
          current_window.mouse_state.button_state[2]
      else if (button_number = 3) then
        state := current_window.mouse_state.button_state[2] and (not
          current_window.mouse_state.button_state[1])
      else
        state := false;
    end
  else
    state := false;

  Mouse_down := state;
end; {procedure Mouse_down}


end.

