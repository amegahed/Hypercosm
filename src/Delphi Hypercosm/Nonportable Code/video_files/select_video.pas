unit select_video;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            select_video               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module allows a user to select an appropriate	}
{	video implementation.                			}
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  video;


type
  video_capabilities_kind_type = (
    does_color, does_drawable3d, does_saveable);


  video_capabilities_type = set of video_capabilities_kind_type;


function Select_new_window(capabilities: video_capabilities_type):
  video_window_type;


implementation
uses
  gdi_video, opengl_video;


function Select_new_window(capabilities: video_capabilities_type):
  video_window_type;
var
  video_window: video_window_type;
begin
  if (does_saveable in capabilities) then
    video_window := nil
  else if (does_drawable3d in capabilities) or (does_color in capabilities) then
    video_window := opengl_window_type.Create
  else
    video_window := gdi_window_type.Create;

  Select_new_window := video_window;
end; {function Select_new_window}


end.

