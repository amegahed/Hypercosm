unit z_hardware;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            z_hardware                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{      This module contains routines to access the z buffer     }
{      hardware on machines which support it. Otherwise,        }
{      the sofware z-buffer routines which are found in         }
{      the z_buffer module will be used instead.                }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface


var
  use_z_hardware: boolean;


procedure Init_z_hardware;
procedure Clear_fast_z_buffer;

{*******************************}
{ z hardware drawing primitives }
{*******************************}
procedure Draw_fast_z_polygon;
procedure Draw_fast_z_line;
procedure Draw_fast_z_thick_line(thickness: real);
procedure Draw_fast_z_points;

{**********************************************}
{ routine for setting the range of z values to }
{ to the depth range for integer z buffers.    }
{**********************************************}
procedure Set_fast_z_buffer_range(z_near, z_far: real);


implementation
uses
  constants, vectors, vectors2, pixels, project, viewports, z_vertices,
  z_pipeline, z_triangles, z_clip;


procedure Init_z_hardware;
begin
  use_z_hardware := false;
end; {procedure Init_z_hardware}


procedure Clear_fast_z_buffer;
begin
end; {procedure Clear_fast_z_buffer}


{*******************************}
{ z hardware drawing primitives }
{*******************************}


procedure Draw_fast_z_polygon;
var
  z_polygon_ptr: z_polygon_ptr_type;
  z_vertex_ptr: z_vertex_ptr_type;
begin
  {************************************}
  { connect polygon holes to perimeter }
  {************************************}
  Remove_z_holes(z_polygon_list, z_hole_list);

  {**************************}
  { clip and project polygon }
  {**************************}
  if z_clipping_enabled then
    Clip_and_project_z_polygon(z_polygon_list, current_viewport_ptr,
      current_projection_ptr);

  {***********************}
  { traverse polygon list }
  {***********************}
  z_polygon_ptr := z_polygon_list;
  while z_polygon_ptr <> nil do
    begin
      z_vertex_ptr := z_polygon_ptr^.first;
      while (z_vertex_ptr <> nil) do
        begin
          z_vertex_ptr := z_vertex_ptr^.next;
        end;
      z_polygon_ptr := z_polygon_ptr^.next;
    end;

  {*******************}
  { free polygon list }
  {*******************}
  Free_z_vertex_lists(z_polygon_list);
end; {procedure Draw_fast_z_polygon}


procedure Draw_fast_z_line;
var
  z_line_ptr: z_polygon_ptr_type;
  z_vertex_ptr: z_vertex_ptr_type;
begin
  {***********************}
  { clip and project line }
  {***********************}
  if z_clipping_enabled then
    Clip_and_project_z_line(z_line_list, current_viewport_ptr,
      current_projection_ptr);

  {********************}
  { traverse line list }
  {********************}
  z_line_ptr := z_line_list;
  while z_line_ptr <> nil do
    begin
      z_vertex_ptr := z_line_ptr^.first;
      while (z_vertex_ptr <> nil) do
        begin
          z_vertex_ptr := z_vertex_ptr^.next;
        end;
      z_line_ptr := z_line_ptr^.next;
    end;

  {****************}
  { free line list }
  {****************}
  Free_z_vertex_lists(z_line_list);
end; {procedure Draw_fast_z_line}


procedure Draw_fast_z_thick_line(thickness: real);
begin
  thickness := 0;
end; {procedure Draw_fast_z_thick_line}


procedure Draw_fast_z_points;
var
  z_point_ptr: z_polygon_ptr_type;
  z_vertex_ptr: z_vertex_ptr_type;
begin
  {*********************}
  { traverse point list }
  {*********************}
  z_point_ptr := z_point_list;
  while z_point_ptr <> nil do
    begin
      z_vertex_ptr := z_point_ptr^.first;
      while (z_vertex_ptr <> nil) do
        begin
          z_vertex_ptr := z_vertex_ptr^.next;
        end;
      z_point_ptr := z_point_ptr^.next;
    end;

  {*****************}
  { free point list }
  {*****************}
  Free_z_vertex_lists(z_point_list);
end; {procedure Draw_fast_z_points}


{**********************************************}
{ routine for setting the range of z values to }
{ to the depth range for integer z buffers.    }
{**********************************************}


procedure Set_fast_z_buffer_range(z_near, z_far: real);
begin
  z_near := 0;
  z_far := 0;
end; {Set_fast_z_buffer_range}


end. {module z_hardware}
