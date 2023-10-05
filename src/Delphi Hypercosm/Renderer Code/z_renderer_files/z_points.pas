unit z_points;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             z_points                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the basic routines for scan        }
{       converting points.                                      }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  z_renderer;


{******************}
{ drawing routines }
{******************}
procedure Draw_z_points(z_renderer: z_renderer_type);


implementation
uses
  errors, constants, vectors, vectors2, colors, pixels, project,
  viewports, z_vertices, z_pipeline, z_screen_clip, z_clip,
  z_buffer, parity_buffer, scan_conversion;


procedure Draw_z_points(z_renderer: z_renderer_type);
var
  z_vertex_ptr: z_vertex_ptr_type;
  h, v: integer;
  z: real;
  pixel: pixel_type;
  z_ptr: z_ptr_type;
begin
  {*************************}
  { clip and project points }
  {*************************}
  if z_clipping_enabled then
    Clip_and_project_z_point(z_point_list, current_viewport_ptr,
      current_projection_ptr);

  z_vertex_ptr := z_point_list^.first;
  while (z_vertex_ptr <> nil) do
    begin
      with z_vertex_ptr^ do
        begin
          {****************************}
          { update z buffer screen box }
          {****************************}
          Update_z_screen_box(z_renderer.z_buffer_ptr^.screen_box, point);

          {*********************************}
          { update parity buffer screen box }
          {*********************************}
          if z_renderer.parity_buffer_ptr <> nil then
            Update_z_screen_box(z_renderer.parity_buffer_ptr^.screen_box, point);

          {****************}
          { z buffer point }
          {****************}
          h := Trunc(point.x);
          v := Trunc(point.y);
          z := point.z;
          z_ptr := Index_z_buffer(z_renderer.z_buffer_ptr, To_pixel(h, v));
          if (z < z_ptr^) then
            begin
              pixel.h := h;
              pixel.v := v;
              z_renderer.drawable.Set_color(color);
              z_renderer.drawable.Draw_pixel(pixel);
              z_ptr^ := z;
            end;
        end;
      z_vertex_ptr := z_vertex_ptr^.next;
    end;
  Free_z_vertex_list(z_point_list);
end; {procedure Draw_z_points}


end.

