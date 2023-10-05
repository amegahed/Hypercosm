unit z_pointplot;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            z_pointplot                3d       }
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
  trans_stack, b_rep, renderable;


procedure Pointplot_z_surface(renderable: point_renderable_type;
  surface_ptr: surface_ptr_type;
  trans_stack_ptr: trans_stack_ptr_type;
  clipping: boolean);
procedure Pointplot_b_rep(renderable: point_renderable_type;
  surface_ptr: surface_ptr_type);
procedure Pointplot_visible_b_rep(renderable: point_renderable_type;
  surface_ptr: surface_ptr_type);


implementation
uses
  trans, video, project, topology, xform_b_rep, object_attr, coords, lighting,
  z_clip, z_points, shade_b_rep, render_lines;


{***************************************************************}
{     Routines for pointplotting partially visible surfaces     }
{***************************************************************}


procedure Pointplot_b_rep(renderable: point_renderable_type;
  surface_ptr: surface_ptr_type);
var
  point_ptr: point_ptr_type;
  point_data_ptr: point_data_ptr_type;
  shade_points: boolean;
begin
  shade_points := attributes.valid[edge_shader_attributes];

  {****************************************}
  { clip and project individual z polygons }
  {****************************************}
  Enable_z_clipping;

  renderable.Begin_points;
  point_ptr := surface_ptr^.topology_ptr^.point_ptr;
  while (point_ptr <> nil) do
    begin
      point_data_ptr := Get_point_data(point_ptr^.index);
      if shade_points then
        renderable.Set_color(point_data_ptr^.color);
      renderable.Add_vertex(point_data_ptr^.trans_point);
      point_ptr := point_ptr^.next;
    end;
  renderable.Draw_points;
end; {procedure Pointplot_b_rep}


{***************************************************************}
{    Routines for pointplotting completely visible surfaces     }
{***************************************************************}


procedure Pointplot_visible_b_rep(renderable: point_renderable_type;
  surface_ptr: surface_ptr_type);
var
  point_ptr: point_ptr_type;
  point_data_ptr: point_data_ptr_type;
  shade_points: boolean;
begin
  shade_points := attributes.valid[edge_shader_attributes];

  {******************************************}
  { project entire mesh and disable clipping }
  {******************************************}
  Project_points_to_points;
  Disable_z_clipping;

  renderable.Begin_points;
  point_ptr := surface_ptr^.topology_ptr^.point_ptr;
  while (point_ptr <> nil) do
    begin
      point_data_ptr := Get_point_data(point_ptr^.index);
      if shade_points then
        renderable.Set_color(point_data_ptr^.color);
      renderable.Add_vertex(point_data_ptr^.vector);
      point_ptr := point_ptr^.next;
    end;
  renderable.Draw_points;
end; {procedure Pointplot_visible_b_rep}


{***************************************************************}
{              Routines for pointplotting surfaces              }
{***************************************************************}


procedure Pointplot_z_surface(renderable: point_renderable_type;
  surface_ptr: surface_ptr_type;
  trans_stack_ptr: trans_stack_ptr_type;
  clipping: boolean);
var
  shade_points: boolean;
  trans: trans_type;
begin
  // Set_video_dither(false);

  if attributes.valid[edge_shader_attributes] then
    begin
      Set_lighting_mode(two_sided);
      // Set_z_mode(flat_z_mode);
    end
  else
    Set_z_line_color(renderable, attributes.color);

  shade_points := attributes.valid[edge_shader_attributes];

  if shade_points then
    begin
      {***************************}
      { bind geometry to topology }
      {***************************}
      Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);
      Bind_vertex_geometry(surface_ptr, surface_ptr^.geometry_ptr);

      {********************************}
      { init auxilliary rendering data }
      {********************************}
      Init_point_data(surface_ptr);
      Init_vertex_data(surface_ptr);

      {************************************}
      { calculate lighting in world coords }
      {************************************}
      Push_trans_stack(trans_stack_ptr);
      Set_trans_mode(premultiply_trans);
      Transform_trans_stack(trans_stack_ptr, eye_to_world);
      Set_trans_mode(postmultiply_trans);
      Get_trans_stack(trans_stack_ptr, trans);
      Transform_point_geometry(trans);
      Transform_vertex_geometry(trans);
      Shade_b_rep_edges(surface_ptr);
      Pop_trans_stack(trans_stack_ptr);

      {**************************************}
      { transform world coords to eye coords }
      {**************************************}
      Transform_point_geometry(world_to_eye);
    end
  else
    begin
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
      Get_trans_stack(trans_stack_ptr, trans);
      Transform_point_geometry(trans);
    end;

  {***********************************}
  { traverse and scan convert surface }
  {***********************************}
  if clipping then
    Pointplot_b_rep(renderable, surface_ptr)
  else
    Pointplot_visible_b_rep(renderable, surface_ptr);
end; {procedure Pointplot_z_surface}


end.
