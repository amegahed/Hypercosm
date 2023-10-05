unit pointplot;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             pointplot                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module draws a scatterplot rendering of objects    }
{       from the viewing data structs.                          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  colors, trans, b_rep, drawable;


procedure Pointplot_surface(drawable: drawable_type;
  surface_ptr: surface_ptr_type;
  trans: trans_type;
  color: color_type;
  clipping: boolean);


implementation
uses
  topology, xform_b_rep, show_lines, project;


procedure Pointplot_b_rep(drawable: drawable_type;
  surface_ptr: surface_ptr_type);
var
  point_ptr: point_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  point_ptr := surface_ptr^.topology_ptr^.point_ptr;
  while (point_ptr <> nil) do
    begin
      point_data_ptr := Get_point_data(point_ptr^.index);
      Show_point(drawable, point_data_ptr^.trans_point);
      point_ptr := point_ptr^.next;
    end;
end; {procedure Pointplot_b_rep}


procedure Pointplot_visible_b_rep(drawable: drawable_type;
  surface_ptr: surface_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
  counter: integer;
begin
  for counter := 0 to (surface_ptr^.topology_ptr^.point_number - 1) do
    begin
      point_data_ptr := Get_point_data(counter);
      drawable.Draw_pixel(Project_point_to_pixel(point_data_ptr^.trans_point));
    end;

  {
  point_ptr := surface_ptr^.topology_ptr^.point_ptr;
  while (point_ptr <> nil) do
    begin
      writeln('index = ', point_ptr^.index);
      point_data_ptr := Get_point_data(point_ptr^.index);
      drawable.Draw_pixel(Project_point_to_pixel(point_data_ptr^.trans_point));
      point_ptr := point_ptr^.next;
    end;
  }
end; {procedure Pointplot_visible_b_rep}


procedure Pointplot_surface(drawable: drawable_type;
  surface_ptr: surface_ptr_type;
  trans: trans_type;
  color: color_type;
  clipping: boolean);
begin
  Set_line_color(drawable, color);

  {***************************}
  { bind geometry to topology }
  {***************************}
  Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);

  {********************************}
  { init auxilliary rendering data }
  {********************************}
  Init_point_data(surface_ptr);

  {**************************************}
  { transform local coords to eye coords }
  {**************************************}
  Transform_point_geometry(trans);

  {***************************}
  { traverse and draw surface }
  {***************************}
  if clipping then
    Pointplot_b_rep(drawable, surface_ptr)
  else
    Pointplot_visible_b_rep(drawable, surface_ptr);
end; {procedure Pointplot_surface}


end.

