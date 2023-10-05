unit video;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               video                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the interface to the display       }
{       hardware. Most porting changes will be here.            }
{                                                               }
{       This is intended to be a one way interface because      }
{       we can't always rely on being able to get data back     }
{       from the videoframe buffer. If we wish to query the     }
{       display, then these types of functions must be          }
{       provided in the display module, where we can keep       }
{       our own copy of the frame buffer so that any type       }
{       of operation is possible.                               }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface


var
  {************************}
  { video screen variables }
  {************************}
  h_screen_size, v_screen_size: integer;
  h_screen_center, v_screen_center: integer;

  {************************}
  { video window variables }
  {************************}
  h_video_size, v_video_size: integer;
  h_video_center, v_video_center: integer;

  h_video_min, v_video_min: integer;
  h_video_max, v_video_max: integer;


{******************}
{ initialize video }
{******************}
procedure Init_video;

{****************************************}
{ routines to create and destroy windows }
{****************************************}
function Open_video_window(name: string;
  h_size, v_size: integer;
  h_center, v_center: integer): integer;
procedure Close_video_window(window_id: integer);

{********************************}
{ routines to manipulate windows }
{********************************}
procedure Set_video_window(window_id: integer);
function Get_video_window: integer;

{*****************************}
{ routines to set video modes }
{*****************************}
procedure Set_backing_store(state: boolean);

{************************}
{ color related routines }
{************************}
procedure Set_video_color(r, g, b: real);
procedure Set_video_dither(mode: boolean);
procedure Set_video_depth(depth: integer);
procedure Set_normal_color_selection;
procedure Set_dynamic_color_selection;

{******************}
{ drawing routines }
{******************}
procedure Move_to_video(h, v: integer);
procedure Draw_to_video(h, v: integer);
procedure Draw_video_pixel(h, v: integer);
procedure Draw_video_line(h1, v1, h2, v2: integer);
procedure Draw_video_h_line(h1, h2, v: integer);
procedure Draw_video_span(h1, h2, v: integer;
  r, g, b: real);
procedure Draw_video_rect(h1, v1, h2, v2: integer);
procedure Draw_video_frame;

{*************************}
{ window refresh routines }
{*************************}
procedure Clear_video_window;
procedure Update_video_window;
procedure Show_video_window;
procedure Restore_video_window;


implementation


{******************}
{ initialize video }
{******************}


procedure Init_video;
begin
end; {procedure Init_video}


{****************************************}
{ routines to create and destroy windows }
{****************************************}


function Open_video_window(name: string;
  h_size, v_size: integer;
  h_center, v_center: integer): integer;
begin
  Open_video_window := 0;
end; {procedure Open_video_window}


procedure Close_video_window(window_id: integer);
begin
end; {procedure Close_video_window}


{********************************}
{ routines to manipulate windows }
{********************************}


procedure Set_video_window(window_id: integer);
begin
end; {procedure Set_video_window}


function Get_video_window: integer;
begin
  Get_video_window := 0;
end; {function Get_video_window}


{*****************************}
{ routines to set video modes }
{*****************************}


procedure Set_backing_store(state: boolean);
begin
end; {procedure Set_backing_store}


{************************}
{ color related routines }
{************************}


procedure Set_video_color(r, g, b: real);
begin
end; {procedure Set_video_color}


procedure Set_video_dither(mode: boolean);
begin
end; {procedure Set_video_dither}


procedure Set_video_depth(depth: integer);
begin
end; {procedure Set_video_depth}


procedure Set_normal_color_selection;
begin
end; {procedure Set_normal_color_selection}


procedure Set_dynamic_color_selection;
begin
end; {procedure Set_dynamic_color_selection}


{******************}
{ drawing routines }
{******************}


procedure Update_screen_box(h, v: integer);
begin
end; {procedure Update_screen_box}


procedure Move_to_video(h, v: integer);
begin
end; {procedure Move_to_video}


procedure Draw_to_video(h, v: integer);
begin
end; {procedure Draw_to_video}


procedure Draw_video_pixel(h, v: integer);
begin
end; {procedure Draw_video_pixel}


procedure Draw_video_line(h1, v1, h2, v2: integer);
begin
end; {procedure Draw_line}


procedure Draw_video_h_line(h1, h2, v: integer);
begin
end; {procedure Draw_video_h_line}


procedure Draw_video_span(h1, h2, v: integer;
  r, g, b: real);
begin
end; {procedure Draw_video_span}


procedure Draw_video_rect(h1, v1, h2, v2: integer);
begin
end; {procedure Draw_video_rect}


procedure Draw_video_frame;
begin
end; {procedure Draw_video_frame}


{*************************}
{ window refresh routines }
{*************************}


procedure Clear_video_window;
begin
end; {procedure Clear_video_window}


procedure Restore_partial_video_window;
begin
end; {procedure Restore_partial_video_window}


procedure Update_video_window;
begin
end; {procedure Update_video_window}


procedure Show_video_window;
begin
end; {procedure Show_video_window}


procedure Restore_video_window;
begin
end; {procedure Restore_video_window}


procedure Save_video_window;
begin
end; {procedure Save_video_window}


end. {module video}
