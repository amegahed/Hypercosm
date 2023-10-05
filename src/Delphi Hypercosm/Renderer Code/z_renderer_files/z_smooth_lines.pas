unit z_smooth_lines;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           z_smooth_lines              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the basic routines for scan        }
{       converting smooth shaded lines.                         }
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
procedure Gouraud_shade_z_line(z_renderer: z_renderer_type);
procedure Gouraud_shade_z_thick_line(z_renderer: z_renderer_type;
  thickness: real);


implementation
uses
  errors, constants, vectors, vectors2, colors, pixels, project,
  viewports, z_vertices, z_pipeline, z_screen_clip, z_clip, z_buffer,
  parity_buffer, renderable, z_flat_lines, z_smooth_polygons, scan_conversion;


function Z_sign(i: integer): integer;
var
  temp: integer;
begin
  if (i >= 0) then
    temp := 1
  else
    temp := -1;
  Z_sign := temp;
end; {function Z_sign}


procedure Gouraud_shade_line(z_renderer: z_renderer_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type);
var
  x, x1, x2: integer;
  y, y1, y2: integer;
  z, z1, z2: real;
  color, color1, color2: color_type;
  dx, dy, sx, sy, temp: integer;
  dzdx, dzdy: real;
  dcdx, dcdy: color_type;
  interchange: boolean;
  pixel: pixel_type;
  error: integer;
  i: integer;
  z_ptr: z_ptr_type;
begin
  {**********************}
  { Gouraud shade a line }
  {**********************}
  x1 := round(z_vertex_ptr1^.point.x);
  y1 := round(z_vertex_ptr1^.point.y);
  z1 := z_vertex_ptr1^.point.z;
  color1 := z_vertex_ptr1^.color;

  x2 := round(z_vertex_ptr2^.point.x);
  y2 := round(z_vertex_ptr2^.point.y);
  z2 := z_vertex_ptr2^.point.z;
  color2 := z_vertex_ptr2^.color;

  x := x1;
  y := y1;
  z := z1;
  color := color1;
  dx := abs(x2 - x1);
  dy := abs(y2 - y1);
  sx := Z_sign(x2 - x1);
  sy := Z_sign(y2 - y1);

  if dx <> 0 then
    begin
      dzdx := (z2 - z1) / dx;
      dcdx := Intensify_color(Contrast_color(color2, color1), 1 / dx);
    end
  else
    begin
      dzdx := 0;
      dcdx := black_color;
    end;

  if dy <> 0 then
    begin
      dzdy := (z2 - z1) / dy;
      dcdy := Intensify_color(Contrast_color(color2, color1), 1 / dy);
    end
  else
    begin
      dzdy := 0;
      dcdy := black_color;
    end;

  {*********************************}
  { interchange dx and dy depending }
  { on the slope of the line        }
  {*********************************}
  if (dy > dx) then
    begin
      temp := dx;
      dx := dy;
      dy := temp;
      interchange := true;
    end
  else
    interchange := false;

  {************************************}
  { initialize error term to           }
  { compensate for a nonzero intercept }
  {************************************}
  error := (2 * dy) - dx;

  {***********}
  { main loop }
  {***********}
  for i := 0 to dx do
    begin
      z_ptr := Index_z_buffer(z_renderer.z_buffer_ptr, To_pixel(x, y));
      if (z <= z_ptr^) then
        begin
          pixel.h := x;
          pixel.v := y;
          z_renderer.drawable.Set_color(color);
          z_renderer.drawable.Draw_pixel(pixel);
          z_ptr^ := z;
        end;

      while (error > 0) do
        begin
          if interchange then
            begin
              x := x + sx;
            end
          else
            begin
              y := y + sy;
            end;
          error := error - (2 * dx);
        end;

      if interchange then
        begin
          y := y + sy;
          z := z + dzdy;
          color := Mix_color(color, dcdy);
        end
      else
        begin
          x := x + sx;
          z := z + dzdx;
          color := Mix_color(color, dcdx);
        end;
      error := error + (2 * dy);
    end;
end; {procedure Gouraud_shade_line}


procedure Gouraud_shade_set_parity_line(z_renderer: z_renderer_type;
  z_vertex_ptr1, z_vertex_ptr2:
  z_vertex_ptr_type);
var
  x, x1, x2: integer;
  y, y1, y2: integer;
  z, z1, z2: real;
  color, color1, color2: color_type;
  dx, dy, sx, sy, temp: integer;
  dzdx, dzdy: real;
  dcdx, dcdy: color_type;
  interchange: boolean;
  pixel: pixel_type;
  error: integer;
  i: integer;
  z_ptr: z_ptr_type;
  parity_ptr: parity_ptr_type;
begin
  {**********************************************************************}
  { Gouraud shade line where the parity buffer is not set and set parity }
  {**********************************************************************}
  x1 := round(z_vertex_ptr1^.point.x);
  y1 := round(z_vertex_ptr1^.point.y);
  z1 := z_vertex_ptr1^.point.z;
  color1 := z_vertex_ptr1^.color;

  x2 := round(z_vertex_ptr2^.point.x);
  y2 := round(z_vertex_ptr2^.point.y);
  z2 := z_vertex_ptr2^.point.z;
  color2 := z_vertex_ptr2^.color;

  x := x1;
  y := y1;
  z := z1;
  color := color1;
  dx := abs(x2 - x1);
  dy := abs(y2 - y1);
  sx := Z_sign(x2 - x1);
  sy := Z_sign(y2 - y1);

  if dx <> 0 then
    begin
      dzdx := (z2 - z1) / dx;
      dcdx := Intensify_color(Contrast_color(color2, color1), 1 / dx);
    end
  else
    begin
      dzdx := 0;
      dcdx := black_color;
    end;

  if dy <> 0 then
    begin
      dzdy := (z2 - z1) / dy;
      dcdy := Intensify_color(Contrast_color(color2, color1), 1 / dy);
    end
  else
    begin
      dzdy := 0;
      dcdy := black_color;
    end;

  {*********************************}
  { interchange dx and dy depending }
  { on the slope of the line        }
  {*********************************}
  if (dy > dx) then
    begin
      temp := dx;
      dx := dy;
      dy := temp;
      interchange := true;
    end
  else
    interchange := false;

  {************************************}
  { initialize error term to           }
  { compensate for a nonzero intercept }
  {************************************}
  error := (2 * dy) - dx;

  {***********}
  { main loop }
  {***********}
  for i := 0 to dx do
    begin
      z_ptr := Index_z_buffer(z_renderer.z_buffer_ptr, To_pixel(x, y));
      parity_ptr := Index_parity_buffer(z_renderer.parity_buffer_ptr, To_pixel(x, y));

      if (z <= z_ptr^) and (not parity_ptr^) then
        begin
          pixel.h := x;
          pixel.v := y;
          z_renderer.drawable.Set_color(color);
          z_renderer.drawable.Draw_pixel(pixel);
          z_ptr^ := z;
        end;
      parity_ptr^ := not parity_ptr^;

      while (error > 0) do
        begin
          if interchange then
            begin
              x := x + sx;
            end
          else
            begin
              y := y + sy;
            end;
          error := error - (2 * dx);
        end;

      if interchange then
        begin
          y := y + sy;
          z := z + dzdy;
          color := Mix_color(color, dcdy);
        end
      else
        begin
          x := x + sx;
          z := z + dzdx;
          color := Mix_color(color, dcdx);
        end;
      error := error + (2 * dy);
    end;
end; {procedure Gouraud_shade_set_parity_line}


procedure Gouraud_shade_not_parity_line(z_renderer: z_renderer_type;
  z_vertex_ptr1, z_vertex_ptr2:
  z_vertex_ptr_type);
var
  x, x1, x2: integer;
  y, y1, y2: integer;
  z, z1, z2: real;
  color, color1, color2: color_type;
  dx, dy, sx, sy, temp: integer;
  dzdx, dzdy: real;
  dcdx, dcdy: color_type;
  interchange: boolean;
  pixel: pixel_type;
  error: integer;
  i: integer;
  z_ptr: z_ptr_type;
  parity_ptr: parity_ptr_type;
begin
  {*********************************************************}
  { Gouraud shade a line where the parity buffer is not set }
  {*********************************************************}
  x1 := round(z_vertex_ptr1^.point.x);
  y1 := round(z_vertex_ptr1^.point.y);
  z1 := z_vertex_ptr1^.point.z;
  color1 := z_vertex_ptr1^.color;

  x2 := round(z_vertex_ptr2^.point.x);
  y2 := round(z_vertex_ptr2^.point.y);
  z2 := z_vertex_ptr2^.point.z;
  color2 := z_vertex_ptr2^.color;

  x := x1;
  y := y1;
  z := z1;
  color := color1;
  dx := abs(x2 - x1);
  dy := abs(y2 - y1);
  sx := Z_sign(x2 - x1);
  sy := Z_sign(y2 - y1);

  if dx <> 0 then
    begin
      dzdx := (z2 - z1) / dx;
      dcdx := Intensify_color(Contrast_color(color2, color1), 1 / dx);
    end
  else
    begin
      dzdx := 0;
      dcdx := black_color;
    end;

  if dy <> 0 then
    begin
      dzdy := (z2 - z1) / dy;
      dcdy := Intensify_color(Contrast_color(color2, color1), 1 / dy);
    end
  else
    begin
      dzdy := 0;
      dcdy := black_color;
    end;

  {*********************************}
  { interchange dx and dy depending }
  { on the slope of the line        }
  {*********************************}
  if (dy > dx) then
    begin
      temp := dx;
      dx := dy;
      dy := temp;
      interchange := true;
    end
  else
    interchange := false;

  {************************************}
  { initialize error term to           }
  { compensate for a nonzero intercept }
  {************************************}
  error := (2 * dy) - dx;

  {***********}
  { main loop }
  {***********}
  for i := 0 to dx do
    begin
      z_ptr := Index_z_buffer(z_renderer.z_buffer_ptr, To_pixel(x, y));
      parity_ptr := Index_parity_buffer(z_renderer.parity_buffer_ptr, To_pixel(x, y));

      if (z <= z_ptr^) and (not parity_ptr^) then
        begin
          pixel.h := x;
          pixel.v := y;
          z_renderer.drawable.Set_color(color);
          z_renderer.drawable.Draw_pixel(pixel);
          z_ptr^ := z;
        end;

      while (error > 0) do
        begin
          if interchange then
            begin
              x := x + sx;
            end
          else
            begin
              y := y + sy;
            end;
          error := error - (2 * dx);
        end;

      if interchange then
        begin
          y := y + sy;
          z := z + dzdy;
          color := Mix_color(color, dcdy);
        end
      else
        begin
          x := x + sx;
          z := z + dzdx;
          color := Mix_color(color, dcdx);
        end;
      error := error + (2 * dy);
    end;
end; {procedure Gouraud_shade_not_parity_line}


procedure Gouraud_shade_z_line(z_renderer: z_renderer_type);
var
  z_line_ptr: z_line_ptr_type;
  z_vertex_ptr: z_vertex_ptr_type;
begin
  if z_line_list <> nil then
    if z_line_list^.kind = flat_z_kind then
      Flat_shade_z_line(z_renderer)
    else
      begin
        {***********************}
        { clip and project line }
        {***********************}
        if z_clipping_enabled then
          Clip_and_project_z_line(z_line_list, current_viewport_ptr,
            current_projection_ptr);

        {************}
        { draw lines }
        {************}
        z_line_ptr := z_line_list;
        while (z_line_ptr <> nil) do
          begin
            z_vertex_ptr := z_line_ptr^.first;
            while (z_vertex_ptr <> nil) do
              begin
                {****************************}
                { update z buffer screen box }
                {****************************}
                Update_z_screen_box(z_renderer.z_buffer_ptr^.screen_box,
                  z_vertex_ptr^.point);

                {*********************************}
                { update parity buffer screen box }
                {*********************************}
                if z_renderer.parity_buffer_ptr <> nil then
                  Update_z_screen_box(z_renderer.parity_buffer_ptr^.screen_box,
                    z_vertex_ptr^.point);

                z_vertex_ptr := z_vertex_ptr^.next;
              end;

            z_vertex_ptr := z_line_ptr^.first;
            if z_vertex_ptr <> nil then
              while (z_vertex_ptr^.next <> nil) do
                begin
                  case z_renderer.parity_mode of
                    no_parity:
                      Gouraud_shade_line(z_renderer, z_vertex_ptr, z_vertex_ptr^.next);
                    set_parity:
                      Gouraud_shade_set_parity_line(z_renderer, z_vertex_ptr,
                        z_vertex_ptr^.next);
                    not_parity:
                      Gouraud_shade_not_parity_line(z_renderer, z_vertex_ptr,
                        z_vertex_ptr^.next);
                  end; {case}
                  z_vertex_ptr := z_vertex_ptr^.next;
                end;

            z_line_ptr := z_line_ptr^.next;
          end;

        {***************************}
        { return lines to free list }
        {***************************}
        z_line_ptr := z_line_list;
        while z_line_ptr <> nil do
          begin
            z_line_list := z_line_ptr;
            z_line_ptr := z_line_ptr^.next;
            Free_z_vertex_list(z_line_list);
          end;
      end;
end; {procedure Gouraud_shade_z_line}


procedure Gouraud_shade_z_thick_line_polygon(z_renderer: z_renderer_type;
  z_line_ptr: z_line_ptr_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
  thickness: real);
var
  vector1, vector2: vector_type;
  vector: vector2_type;
  offset1, offset2: vector_type;
  vertex1, vertex2, vertex3, vertex4: vector_type;
begin
  vector1 := z_vertex_ptr1^.point;
  vector2 := z_vertex_ptr2^.point;
  vector.x := vector2.x - vector1.x;
  vector.y := vector2.y - vector1.y;
  vector := Vector2_scale(Normalize2(vector), thickness);

  {**************************************}
  { compute polygon which surrounds line }
  {**************************************}
  offset1.x := vector.x;
  offset1.y := vector.y;
  offset1.z := 0;
  offset2.x := -vector.y;
  offset2.y := vector.x;
  offset2.z := 0;

  {***************************}
  { add perpendicular offsets }
  {***************************}
  vertex1 := Vector_difference(vector1, offset2);
  vertex2 := Vector_sum(vector1, offset2);
  vertex3 := Vector_sum(vector2, offset2);
  vertex4 := Vector_difference(vector2, offset2);

  {**********************}
  { add parallel offsets }
  {**********************}
  vertex1 := Vector_difference(vertex1, offset1);
  vertex2 := Vector_difference(vertex2, offset1);
  vertex3 := Vector_sum(vertex3, offset1);
  vertex4 := Vector_sum(vertex4, offset1);

  Begin_z_polygon;
  Set_z_color(z_vertex_ptr1^.color);
  Add_z_vertex(vertex1);
  Add_z_vertex(vertex2);
  Set_z_color(z_vertex_ptr2^.color);
  Add_z_vertex(vertex3);
  Add_z_vertex(vertex4);
  Clip_z_polygon_to_screen_box(z_polygon_list,
    current_projection_ptr^.screen_box);
  Gouraud_shade_z_polygon(z_renderer);
end; {procedure Gouraud_shade_z_thick_line_polygon}


procedure Gouraud_shade_z_thick_line(z_renderer: z_renderer_type;
  thickness: real);
var
  z_line_ptr: z_line_ptr_type;
  z_vertex_ptr: z_vertex_ptr_type;
begin
  if z_line_list <> nil then
    if z_line_list^.kind = flat_z_kind then
      Flat_shade_z_thick_line(z_renderer, thickness)
    else
      begin
        {***********************}
        { clip and project line }
        {***********************}
        if z_clipping_enabled then
          Clip_and_project_z_line(z_line_list, current_viewport_ptr,
            current_projection_ptr);

        {****************}
        { rasterize line }
        {****************}
        z_line_ptr := z_line_list;
        while (z_line_ptr <> nil) do
          begin
            z_vertex_ptr := z_line_ptr^.first;
            if z_vertex_ptr <> nil then
              while (z_vertex_ptr^.next <> nil) do
                begin
                  Gouraud_shade_z_thick_line_polygon(z_renderer, z_line_ptr, z_vertex_ptr,
                    z_vertex_ptr^.next, thickness);
                  z_vertex_ptr := z_vertex_ptr^.next;
                end;
            z_line_ptr := z_line_ptr^.next;
          end;
        Free_z_vertex_list(z_line_list);
      end;
end; {procedure Gouraud_shade_z_thick_line}


end.

