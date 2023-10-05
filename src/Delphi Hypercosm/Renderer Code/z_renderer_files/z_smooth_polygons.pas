unit z_smooth_polygons;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          z_smooth_polygons            3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the basic routines for scan        }
{       converting smooth shaded polygons.                      }
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
procedure Gouraud_shade_z_polygon(z_renderer: z_renderer_type);


implementation
uses
  new_memory, constants, vectors, pixels, colors, project, viewports,
  z_vertices, z_pipeline, z_clip, z_triangles, z_buffer, parity_buffer,
  scan_conversion, z_polygons, renderable, z_flat_polygons;


{*******************************************************}
{            creating pixel sampled polygons            }
{*******************************************************}
{       To insure that we activate only pixels          }
{       whose centers are covered by the specified      }
{       polygon, we must obey the following rules:      }
{                                                       }
{       To find the minimum and maximum scanlines       }
{       affected by a polygon, we must correctly        }
{       determine which scanlines are affected by       }
{       each edge. To do this, apply the following      }
{       rules to the y coords:                          }
{                                                       }
{       If fractional y coords:                         }
{       * ceil to find the lowest scanline affected     }
{       * trunc to find the highest scanline affected.  }
{                                                       }
{       If integer y coords:                            }
{       * count scanline as exterior if we are          }
{         looking for the lowest scanline affected.     }
{       * count scanline as interior if we are          }
{         looking for the highest scanline affected.    }
{                                                       }
{       In addition to determining the right vertical   }
{       span of pixels affected by an edge, we must     }
{       determine the correct span of pixels to         }
{       cover in the horizontal direction between       }
{       two consecutive edge intersections:             }
{                                                       }
{       if the edge intersections are fractional:       }
{       fractional:                                     }
{       * ceil to find left intersections               }
{       * trunc to find right intersections             }
{                                                       }
{       if the edge intersections are integer:          }
{       * count left intersections as                   }
{         exterior to the polygon                       }
{       * count right intersections as                  }
{         interior to the polygon                       }
{                                                       }
{       This process can be summed up as:               }
{       * to find the lower integer coord of a span,    }
{         trunc and add 1.                              }
{       * to find the higher integer coord of a span,   }
{         trunc                                         }
{*******************************************************}


procedure Gouraud_shade_span(z_renderer: z_renderer_type;
  scanline: integer;
  z_edge_list: z_edge_ptr_type);
var
  min, max, counter: integer;
  dz, dx, x_offset: real;
  z, z_increment: real;
  color1, color2: color_type;
  color, color_increment: color_type;
  z_ptr: z_ptr_type;
begin
  {***********************************}
  { find first and last pixel in span }
  {***********************************}
  min := Trunc(z_edge_list^.x);
  max := Trunc(z_edge_list^.next^.x) - 1;

  if min <= max then
    begin
      {**********************}
      { find span increments }
      {**********************}
      dz := (z_edge_list^.next^.z - z_edge_list^.z);
      dx := (z_edge_list^.next^.x - z_edge_list^.x);
      color1 := z_edge_list^.color;
      color2 := z_edge_list^.next^.color;
      if (dx <> 0) then
        begin
          z_increment := dz / dx;
          color_increment := Intensify_color(Contrast_color(color2, color1), 1 /
            dx);
        end
      else
        begin
          z_increment := 0;
          color_increment := black_color;
        end;

      {*****************************}
      { snap to first pixel in span }
      {*****************************}
      x_offset := (min - z_edge_list^.x) + 1;
      z := z_edge_list^.z + (z_increment * x_offset);
      color := Mix_color(color1, Intensify_color(color_increment, x_offset));
      z_ptr := Index_z_buffer(z_renderer.z_buffer_ptr, To_pixel(min, scanline));

      {*****************************}
      { loop through pixels in span }
      {*****************************}
      counter := min;
      while (counter <= max) do
        begin
          if (z <= z_ptr^) then
            begin
              {**************************}
              { find end of visible span }
              {**************************}
              min := counter;
              z_renderer.drawable.Set_color(color);
              while (z <= z_ptr^) and (counter <= max) do
                begin
                  z_ptr^ := z;
                  counter := counter + 1;
                  z := z + z_increment;
                  z_ptr := z_ptr_type(longint(z_ptr) + sizeof(z_type));
                end;
              color := Mix_color(color, Intensify_color(color_increment, (counter
                - min)));
              z_renderer.drawable.Draw_span(min, counter, scanline, color);
            end
          else
            begin
              {****************************}
              { find end of invisible span }
              {****************************}
              min := counter;
              while (z > z_ptr^) and (counter <= max) do
                begin
                  counter := counter + 1;
                  z := z + z_increment;
                  z_ptr := z_ptr_type(longint(z_ptr) + sizeof(z_type));
                end;
              color := Mix_color(color, Intensify_color(color_increment, (counter
                - min)));
            end;
        end; {pixels in span}
    end; {if}
end; {procedure Gouraud_shade_span}


procedure Gouraud_shade_scanline(z_renderer: z_renderer_type;
  scanline: integer);
var
  z_edge_list: z_edge_ptr_type;
begin
  z_edge_list := z_renderer.z_active_edge_list;
  while (z_edge_list <> nil) do
    begin
      Gouraud_shade_span(z_renderer, scanline, z_edge_list);

      {*****************************}
      { go to next span in scanline }
      {*****************************}
      z_edge_list := z_edge_list^.next^.next;
    end; {spans in scanline}
end; {procedure Gouraud_shade_scanline}


procedure Gouraud_shade_set_parity_span(z_renderer: z_renderer_type;
  scanline: integer;
  z_edge_list: z_edge_ptr_type);
var
  min, max, counter: integer;
  dz, dx, x_offset: real;
  z, z_increment: real;
  color1, color2: color_type;
  color, color_increment: color_type;
  z_ptr: z_ptr_type;
  parity_ptr: parity_ptr_type;
begin
  {***********************************}
  { find first and last pixel in span }
  {***********************************}
  min := Trunc(z_edge_list^.x);
  max := Trunc(z_edge_list^.next^.x) - 1;

  if min <= max then
    begin
      {**********************}
      { find span increments }
      {**********************}
      dz := (z_edge_list^.next^.z - z_edge_list^.z);
      dx := (z_edge_list^.next^.x - z_edge_list^.x);
      color1 := z_edge_list^.color;
      color2 := z_edge_list^.next^.color;
      if (dx <> 0) then
        begin
          z_increment := dz / dx;
          color_increment := Intensify_color(Contrast_color(color2, color1), 1 /
            dx);
        end
      else
        begin
          z_increment := 0;
          color_increment := black_color;
        end;

      {*****************************}
      { snap to first pixel in span }
      {*****************************}
      x_offset := (min - z_edge_list^.x) + 1;
      z := z_edge_list^.z + (z_increment * x_offset);
      color := Mix_color(color1, Intensify_color(color_increment, x_offset));
      z_ptr := Index_z_buffer(z_renderer.z_buffer_ptr, To_pixel(min, scanline));
      parity_ptr := Index_parity_buffer(z_renderer.parity_buffer_ptr, To_pixel(min, scanline));

      {*****************************}
      { loop through pixels in span }
      {*****************************}
      counter := min;
      while (counter <= max) do
        begin
          if (z <= z_ptr^) then
            begin
              {**************************}
              { find end of visible span }
              {**************************}
              min := counter;
              z_renderer.drawable.Set_color(color);
              while (z <= z_ptr^) and (counter <= max) do
                begin
                  z_ptr^ := z;
                  parity_ptr^ := not parity_ptr^;
                  counter := counter + 1;
                  z := z + z_increment;
                  z_ptr := z_ptr_type(longint(z_ptr) + sizeof(z_type));
                  parity_ptr := parity_ptr_type(longint(parity_ptr) +
                    sizeof(parity_type));
                end;
              color := Mix_color(color, Intensify_color(color_increment, (counter
                - min)));
              z_renderer.drawable.Draw_span(min, counter, scanline, color);
            end
          else
            begin
              {****************************}
              { find end of invisible span }
              {****************************}
              min := counter;
              while (z > z_ptr^) and (counter <= max) do
                begin
                  counter := counter + 1;
                  z := z + z_increment;
                  z_ptr := z_ptr_type(longint(z_ptr) + sizeof(z_type));
                  parity_ptr := parity_ptr_type(longint(parity_ptr) +
                    sizeof(parity_type));
                end;
              color := Mix_color(color, Intensify_color(color_increment, (counter
                - min)));
            end;
        end; {pixels in span}
    end; {if}
end; {procedure Gouraud_shade_set_parity_span}


procedure Gouraud_shade_set_parity_scanline(z_renderer: z_renderer_type;
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
      Gouraud_shade_set_parity_span(z_renderer, scanline, z_edge_list);

      {*****************************}
      { go to next span in scanline }
      {*****************************}
      z_edge_list := z_edge_list^.next^.next;
    end; {spans in scanline}
end; {procedure Gouraud_shade_set_parity_scanline}


procedure Gouraud_shade_not_parity_span(z_renderer: z_renderer_type;
  scanline: integer;
  z_edge_list: z_edge_ptr_type);
var
  min, max, counter: integer;
  dz, dx, x_offset: real;
  z, z_increment: real;
  color1, color2: color_type;
  color, color_increment: color_type;
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
      color1 := z_edge_list^.color;
      color2 := z_edge_list^.next^.color;
      if (dx <> 0) then
        begin
          z_increment := dz / dx;
          color_increment := Intensify_color(Contrast_color(color2, color1), 1 /
            dx);
        end
      else
        begin
          z_increment := 0;
          color_increment := black_color;
        end;

      {*****************************}
      { snap to first pixel in span }
      {*****************************}
      x_offset := (min - z_edge_list^.x) + 1;
      z := z_edge_list^.z + (z_increment * x_offset);
      color := Mix_color(color1, Intensify_color(color_increment, x_offset));
      z_ptr := Index_z_buffer(z_renderer.z_buffer_ptr, To_pixel(min, scanline));
      parity_ptr := Index_parity_buffer(z_renderer.parity_buffer_ptr, To_pixel(min, scanline));

      {*****************************}
      { loop through pixels in span }
      {*****************************}
      counter := min;
      while (counter <= max) do
        begin
          if (z <= z_ptr^) and (not parity_ptr^) then
            begin
              {**************************}
              { find end of visible span }
              {**************************}
              min := counter;
              z_renderer.drawable.Set_color(color);
              while (z <= z_ptr^) and (not parity_ptr^) and (counter <= max) do
                begin
                  z_ptr^ := z;
                  counter := counter + 1;
                  z := z + z_increment;
                  z_ptr := z_ptr_type(longint(z_ptr) + sizeof(z_type));
                  parity_ptr := parity_ptr_type(longint(parity_ptr) +
                    sizeof(parity_type));
                end;
              color := Mix_color(color, Intensify_color(color_increment, (counter
                - min)));
              z_renderer.drawable.Draw_span(min, counter, scanline, color);
            end
          else
            begin
              {****************************}
              { find end of invisible span }
              {****************************}
              min := counter;
              while ((z > z_ptr^) or (parity_ptr^)) and (counter <= max) do
                begin
                  counter := counter + 1;
                  z := z + z_increment;
                  z_ptr := z_ptr_type(longint(z_ptr) + sizeof(z_type));
                  parity_ptr := parity_ptr_type(longint(parity_ptr) +
                    sizeof(parity_type));
                end;
              color := Mix_color(color, Intensify_color(color_increment, (counter
                - min)));
            end;
        end; {pixels in span}
    end; {if}
end; {procedure Gouraud_shade_not_parity_span}


procedure Gouraud_shade_not_parity_scanline(z_renderer: z_renderer_type;
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
      Gouraud_shade_not_parity_span(z_renderer, scanline, z_edge_list);

      {*****************************}
      { go to next span in scanline }
      {*****************************}
      z_edge_list := z_edge_list^.next^.next;
    end; {spans in scanline}
end; {procedure Gouraud_shade_not_parity_scanline}


procedure Gouraud_shade_z_polygon(z_renderer: z_renderer_type);
var
  counter: integer;
  z_edge_ptr, last_z_edge_ptr: z_edge_ptr_type;
  z_table_ptr: z_edge_table_ptr_type;
  fore, aft, temp: z_edge_ptr_type;
begin
  if z_polygon_list <> nil then
    if z_polygon_list^.kind = flat_z_kind then
      Flat_shade_z_polygon(z_renderer)
    else
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
                  Gouraud_shade_scanline(z_renderer, counter);
                set_parity:
                  Gouraud_shade_set_parity_scanline(z_renderer, counter);
                not_parity:
                  Gouraud_shade_not_parity_scanline(z_renderer, counter);
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
                  z_edge_ptr^.color := Mix_color(z_edge_ptr^.color,
                    z_edge_ptr^.color_increment);
                  z_edge_ptr := z_edge_ptr^.next;
                end;
            end;
      end;
end; {procedure Gouraud_shade_z_polygon}


end.

