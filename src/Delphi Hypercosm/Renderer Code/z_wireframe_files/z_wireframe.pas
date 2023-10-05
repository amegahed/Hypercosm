unit z_wireframe;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            z_wireframe                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module draws a wireframe rendering of objects      }
{       from the viewing data structs.                          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  trans_stack, state_vars, b_rep, renderable;


procedure Wireframe_z_surface(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type;
  edge_orientation: edge_orientation_type;
  trans_stack_ptr: trans_stack_ptr_type;
  clipping: boolean);


implementation
uses
  trans, video, project, topology, xform_b_rep, object_attr, coords, lighting,
  shade_b_rep, render_lines, meshes, z_clip, z_pointplot;


{***************************************************************}
{       Routines for wireframing partially visible surfaces     }
{***************************************************************}


procedure Wireframe_b_rep(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type);
var
  edge_ptr: edge_ptr_type;
begin
  {****************************************}
  { clip and project individual z polygons }
  {****************************************}
  Enable_z_clipping;

  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  if (edge_ptr <> nil) then
    begin
      {************}
      { draw edges }
      {************}
      while (edge_ptr <> nil) do
        begin
          if (edge_ptr^.edge_kind <> duplicate_edge) then
            Render_line(renderable, edge_ptr^.vertex_ptr1, edge_ptr^.vertex_ptr2);
          edge_ptr := edge_ptr^.next;
        end;
    end
  else
    Pointplot_b_rep(renderable, surface_ptr);
end; {procedure Wireframe_b_rep}


procedure Wireframe_front_b_rep(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type);
var
  edge_ptr: edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
  {****************************************}
  { clip and project individual z polygons }
  {****************************************}
  Enable_z_clipping;

  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  if (edge_ptr <> nil) then
    begin
      {************}
      { draw edges }
      {************}
      while (edge_ptr <> nil) do
        begin
          edge_data_ptr := Get_edge_data(edge_ptr^.index);
          if (edge_data_ptr^.surface_visibility <> back_facing) then
            if (edge_ptr^.edge_kind <> duplicate_edge) then
              Render_line(renderable, edge_ptr^.vertex_ptr1, edge_ptr^.vertex_ptr2);
          edge_ptr := edge_ptr^.next;
        end;
    end
  else
    Pointplot_b_rep(renderable, surface_ptr);
end; {procedure Wireframe_front_b_rep}


{***************************************************************}
{      Routines for wireframing completely visible surfaces     }
{***************************************************************}


procedure Wireframe_visible_b_rep(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type);
var
  edge_ptr: edge_ptr_type;
begin
  {******************************************}
  { project entire mesh and disable clipping }
  {******************************************}
  Project_points_to_points;
  Disable_z_clipping;

  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  if (edge_ptr <> nil) then
    begin
      {************}
      { draw edges }
      {************}
      while (edge_ptr <> nil) do
        begin
          if (edge_ptr^.edge_kind <> duplicate_edge) then
            Render_visible_line(renderable, edge_ptr^.vertex_ptr1, edge_ptr^.vertex_ptr2);
          edge_ptr := edge_ptr^.next;
        end;
    end
  else
    Pointplot_b_rep(renderable, surface_ptr);
end; {procedure Wireframe_visible_b_rep}


procedure Wireframe_visible_front_b_rep(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type);
var
  edge_ptr: edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
  {******************************************}
  { project entire mesh and disable clipping }
  {******************************************}
  Project_points_to_points;
  Disable_z_clipping;

  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  if (edge_ptr <> nil) then
    begin
      {************}
      { draw edges }
      {************}
      while (edge_ptr <> nil) do
        begin
          edge_data_ptr := Get_edge_data(edge_ptr^.index);
          if (edge_data_ptr^.surface_visibility <> back_facing) then
            if (edge_ptr^.edge_kind <> duplicate_edge) then
              Render_visible_line(renderable, edge_ptr^.vertex_ptr1, edge_ptr^.vertex_ptr2);
          edge_ptr := edge_ptr^.next;
        end;
    end
  else
    Pointplot_b_rep(renderable, surface_ptr);
end; {procedure Wireframe_visible_front_b_rep}


{***************************************************************}
{               Routines for wireframing surfaces               }
{***************************************************************}


procedure Wireframe_z_surface(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type;
  edge_orientation: edge_orientation_type;
  trans_stack_ptr: trans_stack_ptr_type;
  clipping: boolean);
var
  trans: trans_type;
begin
  // Set_video_dither(false);

  if attributes.valid[edge_shader_attributes] then
    begin
      Set_lighting_mode(two_sided);
      // Set_z_mode(Gouraud_z_mode);
    end
  else
    Set_z_line_color(renderable, attributes.color);

  if attributes.valid[edge_shader_attributes] then
    begin
      {***************************}
      { bind geometry to topology }
      {***************************}
      Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);
      Bind_vertex_geometry(surface_ptr, surface_ptr^.geometry_ptr);

      {************************************}
      { allocate auxilliary rendering data }
      {************************************}
      Init_point_data(surface_ptr);
      Init_vertex_data(surface_ptr);
    end
  else
    begin
      {***************************}
      { bind geometry to topology }
      {***************************}
      Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);

      {************************************}
      { allocate auxilliary rendering data }
      {************************************}
      Init_point_data(surface_ptr);
    end;

  {*****************}
  { find silhouette }
  {*****************}
  if edge_orientation = front_edges then
    begin
      {***************************}
      { bind geometry to topology }
      {***************************}
      Bind_face_geometry(surface_ptr, surface_ptr^.geometry_ptr);

      {********************************}
      { init auxilliary rendering data }
      {********************************}
      Init_edge_data(surface_ptr);
      Init_face_data(surface_ptr);

      {***********************}
      { compute mesh geometry }
      {***********************}
      if not surface_ptr^.geometry_ptr^.geometry_info.face_normals_avail then
        Find_mesh_face_normals(surface_ptr);

      {*********************************}
      { find silhouette in local coords }
      {*********************************}
      Get_trans_stack(trans_stack_ptr, trans);
      Find_face_visibility(surface_ptr, trans);
      Find_silhouette(surface_ptr);
    end;

  {**************************************}
  { transform surface to eye coordinates }
  {**************************************}
  if attributes.valid[edge_shader_attributes] then
    begin
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
      {**************************************}
      { transform local coords to eye coords }
      {**************************************}
      Get_trans_stack(trans_stack_ptr, trans);
      Transform_point_geometry(trans);
    end;

  case edge_orientation of

    full_edges:
      begin
        {*********************************************}
        { traverse b rep structure and draw all edges }
        {*********************************************}
        if clipping then
          Wireframe_b_rep(renderable, surface_ptr)
        else
          Wireframe_visible_b_rep(renderable, surface_ptr);
      end;

    front_edges:
      begin
        {***************************************************}
        { traverse b rep structure and draw all front edges }
        {***************************************************}
        if clipping then
          Wireframe_front_b_rep(renderable, surface_ptr)
        else
          Wireframe_visible_front_b_rep(renderable, surface_ptr);
      end;
  end; {case}
end; {procedure Wireframe_z_surface}


end.
