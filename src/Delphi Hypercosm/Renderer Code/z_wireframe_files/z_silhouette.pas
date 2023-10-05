unit z_silhouette;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            z_silhouette               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module draws a silhouette rendering of objects     }
{       from the viewing data structs.                          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  trans_stack, state_vars, b_rep, renderable;


procedure Silhouette_z_surface(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type;
  edge_orientation: edge_orientation_type;
  trans_stack_ptr: trans_stack_ptr_type;
  clipping: boolean);


implementation
uses
  SysUtils,
  vectors, trans, project, geometry, topology, xform_b_rep, object_attr,
  drawable, z_pipeline, z_clip, z_buffer, coords, lighting, shade_b_rep,
  render_lines, meshes, z_pointplot;


procedure Transform_silhouette_points(surface_ptr: surface_ptr_type;
  trans: trans_type);
var
  point_ptr: point_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  if (surface_ptr^.topology_ptr^.perimeter_vertices) then
    begin
      {**********************}
      { transform all points }
      {**********************}
      Transform_point_geometry(trans);
    end
  else
    begin
      {*************************************}
      { transform only those points which   }
      { belong to real or silhouette edges. }
      {*************************************}
      point_ptr := surface_ptr^.topology_ptr^.point_ptr;
      while (point_ptr <> nil) do
        begin
          point_data_ptr := Get_point_data(point_ptr^.index);
          if point_ptr^.real_point or (point_data_ptr^.surface_visibility =
            silhouette_edge) then
            Transform_point(point_data_ptr^.trans_point, trans);
          point_ptr := point_ptr^.next;
        end;
    end;
end; {procedure Transform_silhouette_points}


procedure Transform_silhouette_vertices(surface_ptr: surface_ptr_type;
  trans: trans_type);
var
  vertex_ptr: vertex_ptr_type;
  vertex_data_ptr: vertex_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  if (surface_ptr^.topology_ptr^.perimeter_vertices) then
    begin
      {**********************}
      { transform all points }
      {**********************}
      Transform_vertex_geometry(trans);
    end
  else
    begin
      {*************************************}
      { transform only those points which   }
      { belong to real or silhouette edges. }
      {*************************************}
      vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
      while (vertex_ptr <> nil) do
        begin
          point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
          if vertex_ptr^.point_ptr^.real_point or
            (point_data_ptr^.surface_visibility = silhouette_edge) then
            begin
              vertex_data_ptr := Get_vertex_data(vertex_ptr^.index);
              with vertex_data_ptr^ do
                begin
                  Transform_vector(trans_normal, trans);
                  trans_normal := Normalize(trans_normal);
                end;
            end;
          vertex_ptr := vertex_ptr^.next;
        end;
    end;
end; {procedure Transform_silhouette_vertices}


procedure Shade_silhouette_edges(surface_ptr: surface_ptr_type);
var
  vertex_ptr: vertex_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  if attributes.valid[edge_shader_attributes] then
    if (surface_ptr^.topology_ptr^.perimeter_vertices) then
      begin
        {******************}
        { shade all points }
        {******************}
        vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
        while (vertex_ptr <> nil) do
          begin
            Shade_b_rep_vertex(vertex_ptr);
            vertex_ptr := vertex_ptr^.next;
          end;
      end
    else
      begin
        {*************************************}
        { shade only those points which       }
        { belong to real or silhouette edges. }
        {*************************************}
        vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
        while (vertex_ptr <> nil) do
          begin
            point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
            if vertex_ptr^.point_ptr^.real_point or
              (point_data_ptr^.surface_visibility = silhouette_edge) then
              Shade_b_rep_vertex(vertex_ptr);
            vertex_ptr := vertex_ptr^.next;
          end;
      end;
end; {procedure Shade_silhouette_edges}


procedure Project_silhouette_points(surface_ptr: surface_ptr_type);
var
  point_ptr: point_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  if (surface_ptr^.topology_ptr^.perimeter_vertices) then
    begin
      {********************}
      { project all points }
      {********************}
      point_ptr := surface_ptr^.topology_ptr^.point_ptr;
      while (point_ptr <> nil) do
        begin
          point_data_ptr := Get_point_data(point_ptr^.index);
          with point_data_ptr^ do
            vector := Project_point_to_point(trans_point);
          point_ptr := point_ptr^.next;
        end;
    end
  else
    begin
      {*************************************}
      { transform only those points which   }
      { belong to real or silhouette edges. }
      {*************************************}
      point_ptr := surface_ptr^.topology_ptr^.point_ptr;
      while (point_ptr <> nil) do
        begin
          point_data_ptr := Get_point_data(point_ptr^.index);
          if point_ptr^.real_point or (point_data_ptr^.surface_visibility =
            silhouette_edge) then
            with point_data_ptr^ do
              vector := Project_point_to_point(trans_point);
          point_ptr := point_ptr^.next;
        end;
    end;
end; {procedure Project_silhouette_points}


{***************************************************************}
{      Routines for silhouetting partially visible surfaces     }
{***************************************************************}


procedure Silhouette_b_rep(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type);
var
  edge_ptr: edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
  {****************************************}
  { clip and project individual z polygons }
  {****************************************}
  Enable_z_clipping;

  {***********************}
  { draw silhouette edges }
  {***********************}
  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  if (edge_ptr <> nil) then
    begin
      {************}
      { draw edges }
      {************}
      while (edge_ptr <> nil) do
        begin
          edge_data_ptr := Get_edge_data(edge_ptr^.index);
          if (edge_ptr^.edge_kind = real_edge) or
            (edge_data_ptr^.surface_visibility = silhouette_edge) then
            if (edge_ptr^.edge_kind <> duplicate_edge) then
              Render_line(renderable, edge_ptr^.vertex_ptr1, edge_ptr^.vertex_ptr2);
          edge_ptr := edge_ptr^.next;
        end;
    end
  else
    Pointplot_b_rep(renderable, surface_ptr);
end; {procedure Silhouette_b_rep}


procedure Silhouette_front_b_rep(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type);
var
  edge_ptr: edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
  {****************************************}
  { clip and project individual z polygons }
  {****************************************}
  Enable_z_clipping;

  {***********************}
  { draw silhouette edges }
  {***********************}
  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  if (edge_ptr <> nil) then
    begin
      {************}
      { draw edges }
      {************}
      while (edge_ptr <> nil) do
        begin
          edge_data_ptr := Get_edge_data(edge_ptr^.index);
          if (edge_ptr^.edge_kind = real_edge) or
            (edge_data_ptr^.surface_visibility = silhouette_edge) then
            if (edge_data_ptr^.surface_visibility <> back_facing) then
              if (edge_ptr^.edge_kind <> duplicate_edge) then
                Render_line(renderable, edge_ptr^.vertex_ptr1, edge_ptr^.vertex_ptr2);
          edge_ptr := edge_ptr^.next;
        end;
    end
  else
    Pointplot_b_rep(renderable, surface_ptr);
end; {procedure Silhouette_front_b_rep}


{***************************************************************}
{      Routines for silhouetting completely visible surfaces    }
{***************************************************************}


procedure Silhouette_visible_b_rep(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type);
var
  edge_ptr: edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
  {******************************************}
  { project entire mesh and disable clipping }
  {******************************************}
  Project_silhouette_points(surface_ptr);
  Disable_z_clipping;

  {***********************}
  { draw silhouette edges }
  {***********************}
  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  if (edge_ptr <> nil) then
    begin
      {************}
      { draw edges }
      {************}
      while (edge_ptr <> nil) do
        begin
          edge_data_ptr := Get_edge_data(edge_ptr^.index);
          if (edge_ptr^.edge_kind = real_edge) or
            (edge_data_ptr^.surface_visibility = silhouette_edge) then
            if (edge_ptr^.edge_kind <> duplicate_edge) then
              Render_visible_line(renderable, edge_ptr^.vertex_ptr1, edge_ptr^.vertex_ptr2);
          edge_ptr := edge_ptr^.next;
        end;
    end
  else
    Pointplot_visible_b_rep(renderable, surface_ptr);
end; {procedure Silhouette_visible_b_rep}


procedure Silhouette_visible_front_b_rep(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type);
var
  edge_ptr: edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
  {******************************************}
  { project entire mesh and disable clipping }
  {******************************************}
  Project_silhouette_points(surface_ptr);
  Disable_z_clipping;

  {***********************}
  { draw silhouette edges }
  {***********************}
  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  if (edge_ptr <> nil) then
    begin
      {************}
      { draw edges }
      {************}
      while (edge_ptr <> nil) do
        begin
          edge_data_ptr := Get_edge_data(edge_ptr^.index);
          if (edge_ptr^.edge_kind = real_edge) or
            (edge_data_ptr^.surface_visibility = silhouette_edge) then
            if (edge_data_ptr^.surface_visibility <> back_facing) then
              if (edge_ptr^.edge_kind <> duplicate_edge) then
                Render_visible_line(renderable, edge_ptr^.vertex_ptr1,
                  edge_ptr^.vertex_ptr2);
          edge_ptr := edge_ptr^.next;
        end;
    end
  else
    Pointplot_visible_b_rep(renderable, surface_ptr);
end; {procedure Silhouette_visible_front_b_rep}


{***************************************************************}
{               Routines for silhouetting surfaces              }
{***************************************************************}


procedure Silhouette_z_surface(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type;
  edge_orientation: edge_orientation_type;
  trans_stack_ptr: trans_stack_ptr_type;
  clipping: boolean);
var
  trans: trans_type;
  ditherable: ditherable_type;
  smooth_shadeable: smooth_shadeable_type;
begin
  if Supports(renderable, ditherable_type, ditherable) then
    ditherable.Set_dither_mode(false);

  if attributes.valid[edge_shader_attributes] then
    begin
      Set_lighting_mode(two_sided);
      if Supports(renderable, smooth_shadeable_type, smooth_shadeable) then
        smooth_shadeable.Set_shading_mode(smooth_shading_mode);
    end
  else
    Set_z_line_color(renderable, attributes.color);

  {***************************}
  { bind geometry to topology }
  {***************************}
  Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);
  Bind_face_geometry(surface_ptr, surface_ptr^.geometry_ptr);

  {************************************}
  { allocate auxilliary rendering data }
  {************************************}
  Init_point_data(surface_ptr);
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

  if attributes.valid[edge_shader_attributes] then
    begin
      Init_vertex_data(surface_ptr);
      Bind_vertex_geometry(surface_ptr, surface_ptr^.geometry_ptr);

      {************************************}
      { calculate lighting in world coords }
      {************************************}
      Push_trans_stack(trans_stack_ptr);
      Set_trans_mode(premultiply_trans);
      Transform_trans_stack(trans_stack_ptr, eye_to_world);
      Set_trans_mode(postmultiply_trans);
      Get_trans_stack(trans_stack_ptr, trans);
      Transform_silhouette_points(surface_ptr, trans);
      Transform_silhouette_vertices(surface_ptr, trans);
      Shade_silhouette_edges(surface_ptr);
      Pop_trans_stack(trans_stack_ptr);

      {**************************************}
      { transform world coords to eye coords }
      {**************************************}
      Transform_silhouette_points(surface_ptr, world_to_eye);
    end
  else
    begin
      {**************************************}
      { transform local coords to eye coords }
      {**************************************}
      Get_trans_stack(trans_stack_ptr, trans);
      Transform_silhouette_points(surface_ptr, trans);
    end;

  case edge_orientation of

    full_edges:
      begin
        {****************************************************}
        { traverse b rep structure and draw silhouette edges }
        {****************************************************}
        if clipping then
          Silhouette_b_rep(renderable, surface_ptr)
        else
          Silhouette_visible_b_rep(renderable, surface_ptr);
      end;

    front_edges:
      begin
        {**********************************************************}
        { traverse b rep structure and draw front silhouette edges }
        {**********************************************************}
        if clipping then
          Silhouette_front_b_rep(renderable, surface_ptr)
        else
          Silhouette_visible_front_b_rep(renderable, surface_ptr);
      end;
  end; {case}
end;


end.
