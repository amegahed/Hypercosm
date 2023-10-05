unit z_phong_polygons;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          z_phong_polygons             3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is responsible for phong shading            }
{       polygons.                                               }
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
procedure Phong_shade_z_polygon(z_renderer: z_renderer_type);


implementation
uses
  vectors, pixels, eye, z_vertices, z_pipeline, z_buffer, z_polygons,
  shade_b_rep, scan_conversion, parity_buffer, renderable;


procedure Phong_shade_span(z_renderer: z_renderer_type;
  scanline: integer;
  z_edge_list: z_edge_ptr_type);
var
  min, max: integer;
  dz, dx, x_offset, distance: real;
  normal1, normal2: vector_type;
  vertex1, vertex2: vector_type;
  texture1, texture2: vector_type;
  u_axis1, u_axis2: vector_type;
  v_axis1, v_axis2: vector_type;

  z, z_increment: real;
  normal, normal_increment: vector_type;
  vertex, vertex_increment: vector_type;
  texture, texture_increment: vector_type;
  u_axis, u_axis_increment: vector_type;
  v_axis, v_axis_increment: vector_type;

  location, direction, point: vector_type;
  pixel: pixel_type;
  z_ptr: z_ptr_type;
begin
  {************************************}
  { find first and last pixels in span }
  {************************************}
  min := Trunc(z_edge_list^.x);
  max := Trunc(z_edge_list^.next^.x) - 1;

  if min <= max then
    begin
      {**********************}
      { find span increments }
      {**********************}
      dz := (z_edge_list^.next^.z - z_edge_list^.z);
      dx := (z_edge_list^.next^.x - z_edge_list^.x);
      normal1 := z_edge_list^.normal;
      normal2 := z_edge_list^.next^.normal;
      vertex1 := z_edge_list^.vertex;
      vertex2 := z_edge_list^.next^.vertex;
      texture1 := z_edge_list^.texture;
      texture2 := z_edge_list^.next^.texture;
      u_axis1 := z_edge_list^.u_axis;
      u_axis2 := z_edge_list^.next^.u_axis;
      v_axis1 := z_edge_list^.v_axis;
      v_axis2 := z_edge_list^.next^.v_axis;

      if (dx <> 0) then
        begin
          z_increment := dz / dx;
          normal_increment := Vector_scale(Vector_difference(normal2, normal1), 1
            / dx);
          vertex_increment := Vector_scale(Vector_difference(vertex2, vertex1), 1
            / dx);
          texture_increment := Vector_scale(Vector_difference(texture2,
            texture1), 1 / dx);
          u_axis_increment := Vector_scale(Vector_difference(u_axis2, u_axis1), 1
            / dx);
          v_axis_increment := Vector_scale(Vector_difference(v_axis2, v_axis1), 1
            / dx);
        end
      else
        begin
          z_increment := 0;
          normal_increment := zero_vector;
          vertex_increment := zero_vector;
          texture_increment := zero_vector;
          u_axis_increment := zero_vector;
          v_axis_increment := zero_vector;
        end;

      {*********************************}
      { snap to first pixel in scanline }
      {*********************************}
      x_offset := (min - z_edge_list^.x) + 1;
      z := z_edge_list^.z + (z_increment * x_offset);
      normal := Vector_sum(normal1, Vector_scale(normal_increment, x_offset));
      vertex := Vector_sum(vertex1, Vector_scale(vertex_increment, x_offset));
      texture := Vector_sum(texture1, Vector_scale(texture_increment,
        x_offset));
      u_axis := Vector_sum(u_axis1, Vector_scale(u_axis_increment, x_offset));
      v_axis := Vector_sum(v_axis1, Vector_scale(v_axis_increment, x_offset));

      {*********************************}
      { loop through pixels in scanline }
      {*********************************}
      pixel.h := min;
      pixel.v := scanline;
      z_ptr := Index_z_buffer(z_renderer.z_buffer_ptr, To_pixel(min, scanline));
      while (pixel.h <= max) do
        begin
          if (z <= z_ptr^) then
            begin
              {*********************************}
              { compute data required by shader }
              {*********************************}
              location := Vector_scale(vertex, 1 / z);
              point := Vector_scale(texture, 1 / z);
              direction := Vector_difference(location, eye_point);
              distance := Vector_length(direction);
              direction := Vector_scale(direction, 1 / distance);

              z_renderer.drawable.Set_color(Shade_point(location, normal, direction, point, u_axis,
                v_axis, distance));
              z_renderer.drawable.Draw_pixel(pixel);
              z_ptr^ := z;
            end;

          {******************************}
          { go to next pixel in scanline }
          {******************************}
          pixel.h := pixel.h + 1;
          z := z + z_increment;
          normal := Vector_sum(normal, normal_increment);
          vertex := Vector_sum(vertex, vertex_increment);
          texture := Vector_sum(texture, texture_increment);
          u_axis := Vector_sum(u_axis, u_axis_increment);
          v_axis := Vector_sum(v_axis, v_axis_increment);

          z_ptr := z_ptr_type(longint(z_ptr) + sizeof(z_type));
        end; {pixels in span}
    end; {if}
end; {procedure Phong_shade_span}


procedure Phong_shade_scanline(z_renderer: z_renderer_type;
  scanline: integer);
var
  z_edge_list: z_edge_ptr_type;
begin
  z_edge_list := z_renderer.z_active_edge_list;
  while (z_edge_list <> nil) do
    begin
      Phong_shade_span(z_renderer, scanline, z_edge_list);

      {*****************************}
      { go to next span in scanline }
      {*****************************}
      z_edge_list := z_edge_list^.next^.next;
    end;
end; {procedure Phong_shade_scanline}


procedure Phong_shade_set_parity_span(z_renderer: z_renderer_type;
  scanline: integer;
  z_edge_list: z_edge_ptr_type);
var
  min, max: integer;
  dz, dx, x_offset, distance: real;
  normal1, normal2: vector_type;
  vertex1, vertex2: vector_type;
  texture1, texture2: vector_type;
  u_axis1, u_axis2: vector_type;
  v_axis1, v_axis2: vector_type;

  z, z_increment: real;
  normal, normal_increment: vector_type;
  vertex, vertex_increment: vector_type;
  texture, texture_increment: vector_type;
  u_axis, u_axis_increment: vector_type;
  v_axis, v_axis_increment: vector_type;

  location, direction, point: vector_type;
  pixel: pixel_type;
  z_ptr: z_ptr_type;
  parity_ptr: parity_ptr_type;
begin
  {************************************}
  { find first and last pixels in span }
  {************************************}
  min := Trunc(z_edge_list^.x);
  max := Trunc(z_edge_list^.next^.x) - 1;

  if min <= max then
    begin
      {**********************}
      { find span increments }
      {**********************}
      dz := (z_edge_list^.next^.z - z_edge_list^.z);
      dx := (z_edge_list^.next^.x - z_edge_list^.x);
      normal1 := z_edge_list^.normal;
      normal2 := z_edge_list^.next^.normal;
      vertex1 := z_edge_list^.vertex;
      vertex2 := z_edge_list^.next^.vertex;
      texture1 := z_edge_list^.texture;
      texture2 := z_edge_list^.next^.texture;
      u_axis1 := z_edge_list^.u_axis;
      u_axis2 := z_edge_list^.next^.u_axis;
      v_axis1 := z_edge_list^.v_axis;
      v_axis2 := z_edge_list^.next^.v_axis;

      if (dx <> 0) then
        begin
          z_increment := dz / dx;
          normal_increment := Vector_scale(Vector_difference(normal2, normal1), 1
            / dx);
          vertex_increment := Vector_scale(Vector_difference(vertex2, vertex1), 1
            / dx);
          texture_increment := Vector_scale(Vector_difference(texture2,
            texture1), 1 / dx);
          u_axis_increment := Vector_scale(Vector_difference(u_axis2, u_axis1), 1
            / dx);
          v_axis_increment := Vector_scale(Vector_difference(v_axis2, v_axis1), 1
            / dx);
        end
      else
        begin
          z_increment := 0;
          normal_increment := zero_vector;
          vertex_increment := zero_vector;
          texture_increment := zero_vector;
          u_axis_increment := zero_vector;
          v_axis_increment := zero_vector;
        end;

      {*****************************}
      { snap to first pixel in span }
      {*****************************}
      x_offset := (min - z_edge_list^.x) + 1;
      z := z_edge_list^.z + (z_increment * x_offset);
      normal := Vector_sum(normal1, Vector_scale(normal_increment, x_offset));
      vertex := Vector_sum(vertex1, Vector_scale(vertex_increment, x_offset));
      texture := Vector_sum(texture1, Vector_scale(texture_increment,
        x_offset));
      u_axis := Vector_sum(u_axis1, Vector_scale(u_axis_increment, x_offset));
      v_axis := Vector_sum(v_axis1, Vector_scale(v_axis_increment, x_offset));

      {*****************************}
      { loop through pixels in span }
      {*****************************}
      pixel.h := min;
      pixel.v := scanline;
      z_ptr := Index_z_buffer(z_renderer.z_buffer_ptr, To_pixel(min, scanline));
      parity_ptr := Index_parity_buffer(z_renderer.parity_buffer_ptr, To_pixel(min, scanline));
      while (pixel.h <= max) do
        begin
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

              z_renderer.drawable.Set_color(Shade_point(location, normal, direction, point, u_axis,
                v_axis, distance));
              z_renderer.drawable.Draw_pixel(pixel);
              z_ptr^ := z;
            end;

          {******************************}
          { go to next pixel in scanline }
          {******************************}
          parity_ptr^ := not parity_ptr^;
          pixel.h := pixel.h + 1;
          z := z + z_increment;
          normal := Vector_sum(normal, normal_increment);
          vertex := Vector_sum(vertex, vertex_increment);
          texture := Vector_sum(texture, texture_increment);
          u_axis := Vector_sum(u_axis, u_axis_increment);
          v_axis := Vector_sum(v_axis, v_axis_increment);

          z_ptr := z_ptr_type(longint(z_ptr) + sizeof(z_type));
          parity_ptr := parity_ptr_type(longint(parity_ptr) +
            sizeof(parity_type));
        end; {pixels in span}
    end; {if}
end; {procedure Phong_shade_set_parity_span}


procedure Phong_shade_set_parity_scanline(z_renderer: z_renderer_type;
  scanline: integer);
var
  z_edge_list: z_edge_ptr_type;
begin
  {******************************************************************}
  { shade scanline where the parity buffer is not set and set parity }
  {******************************************************************}
  z_edge_list := z_renderer.z_active_edge_list;
  while (z_edge_list <> nil) do
    begin
      Phong_shade_set_parity_span(z_renderer, scanline, z_edge_list);

      {*****************************}
      { go to next span in scanline }
      {*****************************}
      z_edge_list := z_edge_list^.next^.next;
    end;
end; {procedure Phong_shade_set_parity_scanline}


procedure Phong_shade_not_parity_span(z_renderer: z_renderer_type;
  scanline: integer;
  z_edge_list: z_edge_ptr_type);
var
  min, max: integer;
  dz, dx, x_offset, distance: real;
  normal1, normal2: vector_type;
  vertex1, vertex2: vector_type;
  texture1, texture2: vector_type;
  u_axis1, u_axis2: vector_type;
  v_axis1, v_axis2: vector_type;

  z, z_increment: real;
  normal, normal_increment: vector_type;
  vertex, vertex_increment: vector_type;
  texture, texture_increment: vector_type;
  u_axis, u_axis_increment: vector_type;
  v_axis, v_axis_increment: vector_type;

  location, direction, point: vector_type;
  pixel: pixel_type;
  z_ptr: z_ptr_type;
  parity_ptr: parity_ptr_type;
begin
  {************************************}
  { find first and last pixels in span }
  {************************************}
  min := Trunc(z_edge_list^.x);
  max := Trunc(z_edge_list^.next^.x) - 1;

  if min <= max then
    begin
      {**********************}
      { find span increments }
      {**********************}
      dz := (z_edge_list^.next^.z - z_edge_list^.z);
      dx := (z_edge_list^.next^.x - z_edge_list^.x);
      normal1 := z_edge_list^.normal;
      normal2 := z_edge_list^.next^.normal;
      vertex1 := z_edge_list^.vertex;
      vertex2 := z_edge_list^.next^.vertex;
      texture1 := z_edge_list^.texture;
      texture2 := z_edge_list^.next^.texture;
      u_axis1 := z_edge_list^.u_axis;
      u_axis2 := z_edge_list^.next^.u_axis;
      v_axis1 := z_edge_list^.v_axis;
      v_axis2 := z_edge_list^.next^.v_axis;

      if (dx <> 0) then
        begin
          z_increment := dz / dx;
          normal_increment := Vector_scale(Vector_difference(normal2, normal1), 1
            / dx);
          vertex_increment := Vector_scale(Vector_difference(vertex2, vertex1), 1
            / dx);
          texture_increment := Vector_scale(Vector_difference(texture2,
            texture1), 1 / dx);
          u_axis_increment := Vector_scale(Vector_difference(u_axis2, u_axis1), 1
            / dx);
          v_axis_increment := Vector_scale(Vector_difference(v_axis2, v_axis1), 1
            / dx);
        end
      else
        begin
          z_increment := 0;
          normal_increment := zero_vector;
          vertex_increment := zero_vector;
          texture_increment := zero_vector;
          u_axis_increment := zero_vector;
          v_axis_increment := zero_vector;
        end;

      {*****************************}
      { snap to first pixel in span }
      {*****************************}
      x_offset := (min - z_edge_list^.x) + 1;
      z := z_edge_list^.z + (z_increment * x_offset);
      normal := Vector_sum(normal1, Vector_scale(normal_increment, x_offset));
      vertex := Vector_sum(vertex1, Vector_scale(vertex_increment, x_offset));
      texture := Vector_sum(texture1, Vector_scale(texture_increment,
        x_offset));
      u_axis := Vector_sum(u_axis1, Vector_scale(u_axis_increment, x_offset));
      v_axis := Vector_sum(v_axis1, Vector_scale(v_axis_increment, x_offset));

      {*****************************}
      { loop through pixels in span }
      {*****************************}
      pixel.h := min;
      pixel.v := scanline;
      z_ptr := Index_z_buffer(z_renderer.z_buffer_ptr, To_pixel(min, scanline));
      parity_ptr := Index_parity_buffer(z_renderer.parity_buffer_ptr, To_pixel(min, scanline));
      while (pixel.h <= max) do
        begin
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

              z_renderer.drawable.Set_color(Shade_point(location, normal, direction, point, u_axis,
                v_axis, distance));
              z_renderer.drawable.Draw_pixel(pixel);
              z_ptr^ := z;
            end;

          {**************************}
          { go to next pixel in span }
          {**************************}
          pixel.h := pixel.h + 1;
          z := z + z_increment;
          normal := Vector_sum(normal, normal_increment);
          vertex := Vector_sum(vertex, vertex_increment);
          texture := Vector_sum(texture, texture_increment);
          u_axis := Vector_sum(u_axis, u_axis_increment);
          v_axis := Vector_sum(v_axis, v_axis_increment);

          z_ptr := z_ptr_type(longint(z_ptr) + sizeof(z_type));
          parity_ptr := parity_ptr_type(longint(parity_ptr) +
            sizeof(parity_type));
        end; {pixels in span}
    end; {if}
end; {procedure Phong_shade_not_parity_span}


procedure Phong_shade_not_parity_scanline(z_renderer: z_renderer_type;
  scanline: integer);
var
  z_edge_list: z_edge_ptr_type;
begin
  {*****************************************************}
  { shade a scanline where the parity buffer is not set }
  {*****************************************************}
  z_edge_list := z_renderer.z_active_edge_list;
  while (z_edge_list <> nil) do
    begin
      Phong_shade_not_parity_span(z_renderer, scanline, z_edge_list);

      {*****************************}
      { go to next span in scanline }
      {*****************************}
      z_edge_list := z_edge_list^.next^.next;
    end;
end; {procedure Phong_shade_not_parity_scanline}


procedure Phong_shade_z_polygon(z_renderer: z_renderer_type);
var
  counter: integer;
  z_edge_ptr, last_z_edge_ptr: z_edge_ptr_type;
  z_table_ptr: z_edge_table_ptr_type;
  fore, aft, temp: z_edge_ptr_type;
begin
  End_z_polygon(z_renderer);

  if (z_renderer.y_max >= z_renderer.y_min) then
    for counter := z_renderer.y_min to z_renderer.y_max do
      begin
        {***********************************}
        { move entering edges from the edge }
        { table into the active edge table  }
        {***********************************}
        z_table_ptr := Index_z_edge_table(z_renderer.z_edge_table_ptr, counter);
        z_edge_ptr := z_table_ptr^;

        if z_edge_ptr <> nil then
          begin
            last_z_edge_ptr := z_edge_ptr;
            while last_z_edge_ptr^.next <> nil do
              last_z_edge_ptr := last_z_edge_ptr^.next;

            last_z_edge_ptr^.next := z_renderer.z_active_edge_list;
            z_renderer.z_active_edge_list := z_edge_ptr;
            z_table_ptr^ := nil;
          end;

        {**********************************************************}
        { An edge sort must be done here instead inside above loop }
        { because of degenerate 'bowtie' polygons which introduce  }
        { false vertices which change the ordering of the edges.   }
        {**********************************************************}
        Sort_z_edges(z_renderer.z_active_edge_list);

        {****************************}
        { render this span of pixels }
        {****************************}
        case z_renderer.parity_mode of
          no_parity:
            Phong_shade_scanline(z_renderer, counter);
          set_parity:
            Phong_shade_set_parity_scanline(z_renderer, counter);
          not_parity:
            Phong_shade_not_parity_scanline(z_renderer, counter);
        end;

        {********************************************}
        { remove leaving edges from active edge list }
        {********************************************}
        fore := z_renderer.z_active_edge_list;
        aft := fore;
        while (fore <> nil) do
          begin
            if (fore^.y_max = counter) then
              begin
                {***********************}
                { remove edge from list }
                {***********************}
                if (fore = aft) then
                  begin
                    z_renderer.z_active_edge_list := fore^.next;
                    temp := fore;
                    fore := z_renderer.z_active_edge_list;
                    aft := fore;
                  end
                else
                  begin
                    aft^.next := fore^.next;
                    temp := fore;
                    fore := aft^.next;
                  end;
                {***********************}
                { add edge to free list }
                {***********************}
                Free_z_edge(temp);
              end
            else
              begin
                {*****************}
                { advance pointer }
                {*****************}
                if (fore <> aft) then
                  aft := fore;
                fore := fore^.next;
              end;
          end;

        {************************************}
        { increment values for next scanline }
        {************************************}
        z_edge_ptr := z_renderer.z_active_edge_list;
        while (z_edge_ptr <> nil) do
          begin
            z_edge_ptr^.x := z_edge_ptr^.x + z_edge_ptr^.x_increment;
            z_edge_ptr^.z := z_edge_ptr^.z + z_edge_ptr^.z_increment;
            z_edge_ptr^.normal := Vector_sum(z_edge_ptr^.normal,
              z_edge_ptr^.normal_increment);
            z_edge_ptr^.vertex := Vector_sum(z_edge_ptr^.vertex,
              z_edge_ptr^.vertex_increment);
            z_edge_ptr^.texture := Vector_sum(z_edge_ptr^.texture,
              z_edge_ptr^.texture_increment);
            z_edge_ptr^.u_axis := Vector_sum(z_edge_ptr^.u_axis,
              z_edge_ptr^.u_axis_increment);
            z_edge_ptr^.v_axis := Vector_sum(z_edge_ptr^.v_axis,
              z_edge_ptr^.v_axis_increment);
            z_edge_ptr := z_edge_ptr^.next;
          end;
      end;
end; {procedure Phong_shade_z_polygon}


end.
