unit z_phong_lines;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            z_phong_lines              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is responsible for phong shading            }
{       lines.                                                  }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  z_renderer;


{**********************************}
{ Phong shading drawing primitives }
{**********************************}
procedure Phong_shade_z_line(z_renderer: z_renderer_type);
procedure Phong_shade_z_thick_line(z_renderer: z_renderer_type;
  thickness: real);


implementation
uses
  vectors, pixels, eye, z_vertices, z_pipeline, z_buffer, z_polygons,
  shade_b_rep, scan_conversion, parity_buffer, renderable;


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


procedure Phong_shade_line(z_renderer: z_renderer_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type);
var
  x, x1, x2: integer;
  y, y1, y2: integer;
  z, z1, z2: real;
  normal, normal1, normal2: vector_type;
  vertex, vertex1, vertex2: vector_type;
  texture, texture1, texture2: vector_type;
  u_axis, u_axis1, u_axis2: vector_type;
  v_axis, v_axis1, v_axis2: vector_type;

  dzdx, dzdy: real;
  dndx, dndy: vector_type;
  dpdx, dpdy: vector_type;
  dtdx, dtdy: vector_type;
  dudx, dudy: vector_type;
  dvdx, dvdy: vector_type;

  location, point, direction: vector_type;
  distance: real;

  dx, dy, sx, sy, temp: integer;
  interchange: boolean;
  pixel: pixel_type;
  error: integer;
  i: integer;
  z_ptr: z_ptr_type;
begin
  {********************}
  { phong shade a line }
  {********************}
  x1 := Round(z_vertex_ptr1^.point.x);
  y1 := Round(z_vertex_ptr1^.point.y);
  z1 := z_vertex_ptr1^.point.z;
  normal1 := z_vertex_ptr1^.normal;
  vertex1 := z_vertex_ptr1^.vertex;
  texture1 := z_vertex_ptr1^.texture;
  u_axis1 := z_vertex_ptr1^.u_axis;
  v_axis1 := z_vertex_ptr1^.v_axis;

  x2 := Round(z_vertex_ptr2^.point.x);
  y2 := Round(z_vertex_ptr2^.point.y);
  z2 := z_vertex_ptr2^.point.z;
  normal2 := z_vertex_ptr2^.normal;
  vertex2 := z_vertex_ptr2^.vertex;
  texture2 := z_vertex_ptr2^.texture;
  u_axis2 := z_vertex_ptr2^.u_axis;
  v_axis2 := z_vertex_ptr2^.v_axis;

  x := x1;
  y := y1;
  z := z1;
  normal := normal1;
  vertex := vertex1;
  texture := texture1;
  u_axis := u_axis1;
  v_axis := v_axis1;

  dx := abs(x2 - x1);
  dy := abs(y2 - y1);
  sx := Z_sign(x2 - x1);
  sy := Z_sign(y2 - y1);

  if dx <> 0 then
    begin
      dzdx := (z2 - z1) / dx;
      dndx := Vector_scale(Vector_difference(normal2, normal1), 1 / dx);
      dpdx := Vector_scale(Vector_difference(vertex2, vertex1), 1 / dx);
      dtdx := Vector_scale(Vector_difference(texture2, texture1), 1 / dx);
      dudx := Vector_scale(Vector_difference(u_axis2, u_axis1), 1 / dx);
      dvdx := Vector_scale(Vector_difference(v_axis2, v_axis1), 1 / dx);
    end
  else
    begin
      dzdx := 0;
      dndx := zero_vector;
      dpdx := zero_vector;
      dtdx := zero_vector;
      dudx := zero_vector;
      dvdx := zero_vector;
    end;

  if dy <> 0 then
    begin
      dzdy := (z2 - z1) / dy;
      dndy := Vector_scale(Vector_difference(normal2, normal1), 1 / dy);
      dpdy := Vector_scale(Vector_difference(vertex2, vertex1), 1 / dy);
      dtdy := Vector_scale(Vector_difference(texture2, texture1), 1 / dy);
      dudy := Vector_scale(Vector_difference(u_axis2, u_axis1), 1 / dy);
      dvdy := Vector_scale(Vector_difference(v_axis2, v_axis1), 1 / dy);
    end
  else
    begin
      dzdy := 0;
      dndy := zero_vector;
      dpdy := zero_vector;
      dtdy := zero_vector;
      dudy := zero_vector;
      dvdy := zero_vector;
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
          {*********************************}
          { compute data required by shader }
          {*********************************}
          location := Vector_scale(vertex, 1 / z);
          point := Vector_scale(texture, 1 / z);
          location := vertex;
          point := texture;

          direction := Vector_difference(location, eye_point);
          distance := Vector_length(direction);
          direction := Vector_scale(direction, 1 / distance);

          z_renderer.drawable.Set_color(Shade_edge_point(location, normal, direction, point, u_axis,
            v_axis, distance));
          pixel.h := x;
          pixel.v := y;
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
          normal := Vector_sum(normal, dndy);
          vertex := Vector_sum(vertex, dpdy);
          texture := Vector_sum(texture, dtdy);
          u_axis := Vector_sum(u_axis, dudy);
          v_axis := Vector_sum(v_axis, dvdy);
        end
      else
        begin
          x := x + sx;
          z := z + dzdx;
          normal := Vector_sum(normal, dndx);
          vertex := Vector_sum(vertex, dpdx);
          texture := Vector_sum(texture, dtdx);
          u_axis := Vector_sum(u_axis, dudx);
          v_axis := Vector_sum(v_axis, dvdx);
        end;
      error := error + (2 * dy);
    end;
end; {procedure Phong_shade_line}


procedure Phong_shade_set_parity_line(z_renderer: z_renderer_type;
  z_vertex_ptr1, z_vertex_ptr2:
  z_vertex_ptr_type);
var
  x, x1, x2: integer;
  y, y1, y2: integer;
  z, z1, z2: real;
  normal, normal1, normal2: vector_type;
  vertex, vertex1, vertex2: vector_type;
  texture, texture1, texture2: vector_type;
  u_axis, u_axis1, u_axis2: vector_type;
  v_axis, v_axis1, v_axis2: vector_type;

  dzdx, dzdy: real;
  dndx, dndy: vector_type;
  dpdx, dpdy: vector_type;
  dtdx, dtdy: vector_type;
  dudx, dudy: vector_type;
  dvdx, dvdy: vector_type;

  location, point, direction: vector_type;
  distance: real;

  dx, dy, sx, sy, temp: integer;
  interchange: boolean;
  pixel: pixel_type;
  error: integer;
  i: integer;
  z_ptr: z_ptr_type;
  parity_ptr: parity_ptr_type;
begin
  {********************************************************************}
  { Phong shade line where the parity buffer is not set and set parity }
  {********************************************************************}
  x1 := Round(z_vertex_ptr1^.point.x);
  y1 := Round(z_vertex_ptr1^.point.y);
  z1 := z_vertex_ptr1^.point.z;
  normal1 := z_vertex_ptr1^.normal;
  vertex1 := z_vertex_ptr1^.vertex;
  texture1 := z_vertex_ptr1^.texture;
  u_axis1 := z_vertex_ptr1^.u_axis;
  v_axis1 := z_vertex_ptr1^.v_axis;

  x2 := Round(z_vertex_ptr2^.point.x);
  y2 := Round(z_vertex_ptr2^.point.y);
  z2 := z_vertex_ptr2^.point.z;
  normal2 := z_vertex_ptr2^.normal;
  vertex2 := z_vertex_ptr2^.vertex;
  texture2 := z_vertex_ptr2^.texture;
  u_axis2 := z_vertex_ptr2^.u_axis;
  v_axis2 := z_vertex_ptr2^.v_axis;

  x := x1;
  y := y1;
  z := z1;
  normal := normal1;
  vertex := vertex1;
  texture := texture1;
  u_axis := u_axis1;
  v_axis := v_axis1;

  dx := abs(x2 - x1);
  dy := abs(y2 - y1);
  sx := Z_sign(x2 - x1);
  sy := Z_sign(y2 - y1);

  if dx <> 0 then
    begin
      dzdx := (z2 - z1) / dx;
      dndx := Vector_scale(Vector_difference(normal2, normal1), 1 / dx);
      dpdx := Vector_scale(Vector_difference(vertex2, vertex1), 1 / dx);
      dtdx := Vector_scale(Vector_difference(texture2, texture1), 1 / dx);
      dudx := Vector_scale(Vector_difference(u_axis2, u_axis1), 1 / dx);
      dvdx := Vector_scale(Vector_difference(v_axis2, v_axis1), 1 / dx);
    end
  else
    begin
      dzdx := 0;
      dndx := zero_vector;
      dpdx := zero_vector;
      dtdx := zero_vector;
      dudx := zero_vector;
      dvdx := zero_vector;
    end;

  if dy <> 0 then
    begin
      dzdy := (z2 - z1) / dy;
      dndy := Vector_scale(Vector_difference(normal2, normal1), 1 / dy);
      dpdy := Vector_scale(Vector_difference(vertex2, vertex1), 1 / dy);
      dtdy := Vector_scale(Vector_difference(texture2, texture1), 1 / dy);
      dudy := Vector_scale(Vector_difference(u_axis2, u_axis1), 1 / dy);
      dvdy := Vector_scale(Vector_difference(v_axis2, v_axis1), 1 / dy);
    end
  else
    begin
      dzdy := 0;
      dndy := zero_vector;
      dpdy := zero_vector;
      dtdy := zero_vector;
      dudy := zero_vector;
      dvdy := zero_vector;
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
          {*********************************}
          { compute data required by shader }
          {*********************************}
          location := Vector_scale(vertex, 1 / z);
          point := Vector_scale(texture, 1 / z);
          direction := Vector_difference(location, eye_point);
          distance := Vector_length(direction);
          direction := Vector_scale(direction, 1 / distance);

          z_renderer.drawable.Set_color(Shade_edge_point(location, normal, direction, point, u_axis,
            v_axis, distance));
          pixel.h := x;
          pixel.v := y;
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
          normal := Vector_sum(normal, dndy);
          vertex := Vector_sum(vertex, dpdy);
          texture := Vector_sum(texture, dtdy);
          u_axis := Vector_sum(u_axis, dudy);
          v_axis := Vector_sum(v_axis, dvdy);
        end
      else
        begin
          x := x + sx;
          z := z + dzdx;
          normal := Vector_sum(normal, dndx);
          vertex := Vector_sum(vertex, dpdx);
          texture := Vector_sum(texture, dtdx);
          u_axis := Vector_sum(u_axis, dudx);
          v_axis := Vector_sum(v_axis, dvdx);
        end;
      error := error + (2 * dy);
    end;
end; {procedure Phong_shade_set_parity_line}


procedure Phong_shade_not_parity_line(z_renderer: z_renderer_type;
  z_vertex_ptr1, z_vertex_ptr2:
  z_vertex_ptr_type);
var
  x, x1, x2: integer;
  y, y1, y2: integer;
  z, z1, z2: real;
  normal, normal1, normal2: vector_type;
  vertex, vertex1, vertex2: vector_type;
  texture, texture1, texture2: vector_type;
  u_axis, u_axis1, u_axis2: vector_type;
  v_axis, v_axis1, v_axis2: vector_type;

  dzdx, dzdy: real;
  dndx, dndy: vector_type;
  dpdx, dpdy: vector_type;
  dtdx, dtdy: vector_type;
  dudx, dudy: vector_type;
  dvdx, dvdy: vector_type;

  location, point, direction: vector_type;
  distance: real;

  dx, dy, sx, sy, temp: integer;
  interchange: boolean;
  pixel: pixel_type;
  error: integer;
  i: integer;
  z_ptr: z_ptr_type;
  parity_ptr: parity_ptr_type;
begin
  {*******************************************************}
  { Phong shade a line where the parity buffer is not set }
  {*******************************************************}
  x1 := Round(z_vertex_ptr1^.point.x);
  y1 := Round(z_vertex_ptr1^.point.y);
  z1 := z_vertex_ptr1^.point.z;
  normal1 := z_vertex_ptr1^.normal;
  vertex1 := z_vertex_ptr1^.vertex;
  texture1 := z_vertex_ptr1^.texture;
  u_axis1 := z_vertex_ptr1^.u_axis;
  v_axis1 := z_vertex_ptr1^.v_axis;

  x2 := Round(z_vertex_ptr2^.point.x);
  y2 := Round(z_vertex_ptr2^.point.y);
  z2 := z_vertex_ptr2^.point.z;
  normal2 := z_vertex_ptr2^.normal;
  vertex2 := z_vertex_ptr2^.vertex;
  texture2 := z_vertex_ptr2^.texture;
  u_axis2 := z_vertex_ptr2^.u_axis;
  v_axis2 := z_vertex_ptr2^.v_axis;

  x := x1;
  y := y1;
  z := z1;
  normal := normal1;
  vertex := vertex1;
  texture := texture1;
  u_axis := u_axis1;
  v_axis := v_axis1;

  dx := abs(x2 - x1);
  dy := abs(y2 - y1);
  sx := Z_sign(x2 - x1);
  sy := Z_sign(y2 - y1);

  if dx <> 0 then
    begin
      dzdx := (z2 - z1) / dx;
      dndx := Vector_scale(Vector_difference(normal2, normal1), 1 / dx);
      dpdx := Vector_scale(Vector_difference(vertex2, vertex1), 1 / dx);
      dtdx := Vector_scale(Vector_difference(texture2, texture1), 1 / dx);
      dudx := Vector_scale(Vector_difference(u_axis2, u_axis1), 1 / dx);
      dvdx := Vector_scale(Vector_difference(v_axis2, v_axis1), 1 / dx);
    end
  else
    begin
      dzdx := 0;
      dndx := zero_vector;
      dpdx := zero_vector;
      dtdx := zero_vector;
      dudx := zero_vector;
      dvdx := zero_vector;
    end;

  if dy <> 0 then
    begin
      dzdy := (z2 - z1) / dy;
      dndy := Vector_scale(Vector_difference(normal2, normal1), 1 / dy);
      dpdy := Vector_scale(Vector_difference(vertex2, vertex1), 1 / dy);
      dtdy := Vector_scale(Vector_difference(texture2, texture1), 1 / dy);
      dudy := Vector_scale(Vector_difference(u_axis2, u_axis1), 1 / dy);
      dvdy := Vector_scale(Vector_difference(v_axis2, v_axis1), 1 / dy);
    end
  else
    begin
      dzdy := 0;
      dndy := zero_vector;
      dpdy := zero_vector;
      dtdy := zero_vector;
      dudy := zero_vector;
      dvdy := zero_vector;
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
          {*********************************}
          { compute data required by shader }
          {*********************************}
          location := Vector_scale(vertex, 1 / z);
          point := Vector_scale(texture, 1 / z);
          direction := Vector_difference(location, eye_point);
          distance := Vector_length(direction);
          direction := Vector_scale(direction, 1 / distance);

          z_renderer.drawable.Set_color(Shade_edge_point(location, normal, direction, point, u_axis,
            v_axis, distance));
          pixel.h := x;
          pixel.v := y;
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
          normal := Vector_sum(normal, dndy);
          vertex := Vector_sum(vertex, dpdy);
          texture := Vector_sum(texture, dtdy);
          u_axis := Vector_sum(u_axis, dudy);
          v_axis := Vector_sum(v_axis, dvdy);
        end
      else
        begin
          x := x + sx;
          z := z + dzdx;
          normal := Vector_sum(normal, dndx);
          vertex := Vector_sum(vertex, dpdx);
          texture := Vector_sum(texture, dtdx);
          u_axis := Vector_sum(u_axis, dudx);
          v_axis := Vector_sum(v_axis, dvdx);
        end;
      error := error + (2 * dy);
    end;
end; {procedure Phong_shade_not_parity_line}


procedure Phong_shade_z_line(z_renderer: z_renderer_type);
var
  z_line_ptr: z_line_ptr_type;
  z_vertex_ptr: z_vertex_ptr_type;
begin
  {************}
  { draw lines }
  {************}
  z_line_ptr := z_line_list;
  while (z_line_ptr <> nil) do
    begin
      z_vertex_ptr := z_line_ptr^.first;
      if z_vertex_ptr <> nil then
        while (z_vertex_ptr^.next <> nil) do
          begin
            case z_renderer.parity_mode of
              no_parity:
                Phong_shade_line(z_renderer, z_vertex_ptr, z_vertex_ptr^.next);
              set_parity:
                Phong_shade_set_parity_line(z_renderer, z_vertex_ptr, z_vertex_ptr^.next);
              not_parity:
                Phong_shade_not_parity_line(z_renderer, z_vertex_ptr, z_vertex_ptr^.next);
            end;
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
end; {procedure Phong_shade_z_line}


procedure Phong_shade_z_thick_line(z_renderer: z_renderer_type;
  thickness: real);
begin
end; {procedure Phong_shade_z_thick_line}


end.

