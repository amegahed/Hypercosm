unit z_outline;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              z_outline                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module draws an outline rendering of objects       }
{       from the viewing data structs.                          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  trans_stack, state_vars, b_rep, renderable;


procedure Outline_z_surface(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type;
  edge_orientation: edge_orientation_type;
  outline_kind: outline_kind_type;
  trans_stack_ptr: trans_stack_ptr_type;
  clipping: boolean);


implementation
uses
  SysUtils,
  colors, vectors, trans, video, project, geometry, topology, xform_b_rep,
  object_attr, z_pipeline, z_clip, z_buffer, coords, drawable, renderer,
  lighting, shade_b_rep, render_lines, meshes, z_pointplot;


var
  weak_edge_color, bold_edge_color: color_type;


procedure Transform_outline_points(surface_ptr: surface_ptr_type;
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
      {***********************************************}
      { transform only those points which belong to   }
      { real or pseudo edges or to silhouette edges.  }
      {***********************************************}
      point_ptr := surface_ptr^.topology_ptr^.point_ptr;
      while (point_ptr <> nil) do
        begin
          point_data_ptr := Get_point_data(point_ptr^.index);
          if point_ptr^.real_point or point_ptr^.pseudo_point or
            (point_data_ptr^.surface_visibility = silhouette_edge) then
            Transform_point(point_data_ptr^.trans_point, trans);
          point_ptr := point_ptr^.next;
        end;
    end;
end; {procedure Transform_outline_points}


procedure Transform_outline_vertices(surface_ptr: surface_ptr_type;
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
      {***********************************************}
      { transform only those points which belong to   }
      { real or pseudo edges or to silhouette edges.  }
      {***********************************************}
      vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
      while (vertex_ptr <> nil) do
        begin
          point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
          if vertex_ptr^.point_ptr^.real_point or
            vertex_ptr^.point_ptr^.pseudo_point or
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
end; {procedure Transform_outline_vertices}


procedure Shade_outline_edges(surface_ptr: surface_ptr_type);
var
  vertex_ptr: vertex_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
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
      {***********************************************}
      { shade only those points which belong to       }
      { real edges, pseudo edges or silhouette edges. }
      {***********************************************}
      vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
      while (vertex_ptr <> nil) do
        begin
          point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
          if vertex_ptr^.point_ptr^.real_point or
            vertex_ptr^.point_ptr^.pseudo_point or
            (point_data_ptr^.surface_visibility = silhouette_edge) then
            Shade_b_rep_vertex(vertex_ptr);
          vertex_ptr := vertex_ptr^.next;
        end;
    end;
end; {procedure Shade_outline_edges}


procedure Project_outline_points(surface_ptr: surface_ptr_type);
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
      {***********************************************}
      { transform only those points which belong to   }
      { real edges, pseudo edges or silhouette edges. }
      {***********************************************}
      point_ptr := surface_ptr^.topology_ptr^.point_ptr;
      while (point_ptr <> nil) do
        begin
          point_data_ptr := Get_point_data(point_ptr^.index);
          if point_ptr^.real_point or point_ptr^.pseudo_point or
            (point_data_ptr^.surface_visibility = silhouette_edge) then
            with point_data_ptr^ do
              vector := Project_point_to_point(trans_point);
          point_ptr := point_ptr^.next;
        end;
    end;
end; {procedure Project_outline_points}


{***************************************************************}
{        Routines for outlining partially visible surfaces      }
{***************************************************************}


procedure Outline_b_rep(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type;
  outline_kind: outline_kind_type);
var
  edge_ptr: edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
  {****************************************}
  { clip and project individual z polygons }
  {****************************************}
  Enable_z_clipping;

  {******************************************************}
  { draw both front and back outline edges same strength }
  {******************************************************}
  case outline_kind of
    weak_outline:
      Set_z_line_color(renderable, weak_edge_color);
    bold_outline:
      Set_z_line_color(renderable, bold_edge_color);
  end;

  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  while (edge_ptr <> nil) do
    begin
      edge_data_ptr := Get_edge_data(edge_ptr^.index);
      if (edge_ptr^.edge_kind = pseudo_edge) then
        if (edge_data_ptr^.surface_visibility <> silhouette_edge) then
          Render_line(renderable, edge_ptr^.vertex_ptr1, edge_ptr^.vertex_ptr2);
      edge_ptr := edge_ptr^.next;
    end;

  {********************************}
  { draw real and silhouette edges }
  {********************************}
  Set_z_line_color(renderable, bold_edge_color);
  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  if (edge_ptr <> nil) then
    begin
      {************}
      { draw edges }
      {************}
      while (edge_ptr <> nil) do
        begin
          edge_data_ptr := Get_edge_data(edge_ptr^.index);
          if (edge_ptr^.edge_kind <> duplicate_edge) then
            if (edge_ptr^.edge_kind = real_edge) or
              (edge_data_ptr^.surface_visibility = silhouette_edge) then
              Render_line(renderable, edge_ptr^.vertex_ptr1, edge_ptr^.vertex_ptr2);
          edge_ptr := edge_ptr^.next;
        end;
    end
  else
    Pointplot_b_rep(renderable, surface_ptr);
end; {procedure Outline_b_rep}


procedure Outline_front_b_rep(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type;
  outline_kind: outline_kind_type);
var
  edge_ptr: edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
  {****************************************}
  { clip and project individual z polygons }
  {****************************************}
  Enable_z_clipping;

  {*****************************************************}
  { draw front and back outlines in different strengths }
  {*****************************************************}

  {*******************}
  { draw back outline }
  {*******************}
  if outline_kind <> weak_outline then
    begin
      Set_z_line_color(renderable, weak_edge_color);
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      while (edge_ptr <> nil) do
        begin
          edge_data_ptr := Get_edge_data(edge_ptr^.index);
          if (edge_data_ptr^.surface_visibility = back_facing) then
            if (edge_ptr^.edge_kind in [pseudo_edge, real_edge]) then
              Render_line(renderable, edge_ptr^.vertex_ptr1, edge_ptr^.vertex_ptr2);
          edge_ptr := edge_ptr^.next;
        end;
    end;

  {********************}
  { draw front outline }
  {********************}
  case outline_kind of
    weak_outline:
      Set_z_line_color(renderable, weak_edge_color);
    bold_outline:
      Set_z_line_color(renderable, bold_edge_color);
  end;

  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  while (edge_ptr <> nil) do
    begin
      edge_data_ptr := Get_edge_data(edge_ptr^.index);
      if (edge_data_ptr^.surface_visibility = front_facing) then
        if (edge_ptr^.edge_kind = pseudo_edge) then
          Render_line(renderable, edge_ptr^.vertex_ptr1, edge_ptr^.vertex_ptr2);
      edge_ptr := edge_ptr^.next;
    end;

  {********************************}
  { draw real and silhouette edges }
  {********************************}
  Set_z_line_color(renderable, bold_edge_color);
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
            if (edge_ptr^.edge_kind = real_edge) or
              (edge_data_ptr^.surface_visibility = silhouette_edge) then
              if (edge_ptr^.edge_kind <> duplicate_edge) then
                Render_line(renderable, edge_ptr^.vertex_ptr1, edge_ptr^.vertex_ptr2);
          edge_ptr := edge_ptr^.next;
        end;
    end
  else
    Pointplot_b_rep(renderable, surface_ptr);
end; {procedure Outline_front_b_rep}


{***************************************************************}
{       Routines for outlining completely visible surfaces      }
{***************************************************************}


procedure Outline_visible_b_rep(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type;
  outline_kind: outline_kind_type);
var
  edge_ptr: edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
  {******************************************}
  { project entire mesh and disable clipping }
  {******************************************}
  Project_outline_points(surface_ptr);
  Disable_z_clipping;

  {******************************************************}
  { draw both front and back outline edges same strength }
  {******************************************************}
  case outline_kind of
    weak_outline:
      Set_z_line_color(renderable, weak_edge_color);
    bold_outline:
      Set_z_line_color(renderable, bold_edge_color);
  end;

  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  while (edge_ptr <> nil) do
    begin
      edge_data_ptr := Get_edge_data(edge_ptr^.index);
      if (edge_ptr^.edge_kind = pseudo_edge) then
        if (edge_data_ptr^.surface_visibility <> silhouette_edge) then
          Render_visible_line(renderable, edge_ptr^.vertex_ptr1, edge_ptr^.vertex_ptr2);
      edge_ptr := edge_ptr^.next;
    end;

  {********************************}
  { draw real and silhouette edges }
  {********************************}
  Set_z_line_color(renderable, bold_edge_color);
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
end; {procedure Outline_visible_b_rep}


procedure Outline_visible_front_b_rep(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type;
  outline_kind: outline_kind_type);
var
  edge_ptr: edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
  {******************************************}
  { project entire mesh and disable clipping }
  {******************************************}
  Project_outline_points(surface_ptr);
  Disable_z_clipping;

  {*****************************************************}
  { draw front and back outlines in different strengths }
  {*****************************************************}

  {*******************}
  { draw back outline }
  {*******************}
  if outline_kind <> weak_outline then
    begin
      Set_z_line_color(renderable, weak_edge_color);
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      while (edge_ptr <> nil) do
        begin
          edge_data_ptr := Get_edge_data(edge_ptr^.index);
          if (edge_data_ptr^.surface_visibility = back_facing) then
            if (edge_ptr^.edge_kind in [pseudo_edge, real_edge]) then
              Render_visible_line(renderable, edge_ptr^.vertex_ptr1, edge_ptr^.vertex_ptr2);
          edge_ptr := edge_ptr^.next;
        end;
    end;

  {********************}
  { draw front outline }
  {********************}
  case outline_kind of
    weak_outline:
      Set_z_line_color(renderable, weak_edge_color);
    bold_outline:
      Set_z_line_color(renderable, bold_edge_color);
  end;

  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  while (edge_ptr <> nil) do
    begin
      edge_data_ptr := Get_edge_data(edge_ptr^.index);
      if (edge_ptr^.edge_kind = pseudo_edge) then
        if (edge_data_ptr^.surface_visibility = front_facing) then
          Render_visible_line(renderable, edge_ptr^.vertex_ptr1, edge_ptr^.vertex_ptr2);
      edge_ptr := edge_ptr^.next;
    end;

  {********************************}
  { draw real and silhouette edges }
  {********************************}
  Set_z_line_color(renderable, bold_edge_color);
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
            if (edge_ptr^.edge_kind = real_edge) or
              (edge_data_ptr^.surface_visibility = silhouette_edge) then
              if (edge_ptr^.edge_kind <> duplicate_edge) then
                Render_visible_line(renderable, edge_ptr^.vertex_ptr1,
                  edge_ptr^.vertex_ptr2);
          edge_ptr := edge_ptr^.next;
        end;
    end
  else
    Pointplot_visible_b_rep(renderable, surface_ptr);
end; {procedure Outline_visible_front_b_rep}


{***************************************************************}
{                Routines for outlining surfaces                }
{***************************************************************}


procedure Outline_z_surface(renderable: line_renderable_type;
  surface_ptr: surface_ptr_type;
  edge_orientation: edge_orientation_type;
  outline_kind: outline_kind_type;
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
    begin
      bold_edge_color := attributes.color;
      weak_edge_color := Intensify_color(Mix_color(attributes.color,
        background_color), 0.5);
    end;

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
      Bind_vertex_geometry(surface_ptr, surface_ptr^.geometry_ptr);
      Init_vertex_data(surface_ptr);

      {************************************}
      { calculate lighting in world coords }
      {************************************}
      Push_trans_stack(trans_stack_ptr);
      Set_trans_mode(premultiply_trans);
      Transform_trans_stack(trans_stack_ptr, eye_to_world);
      Set_trans_mode(postmultiply_trans);
      Get_trans_stack(trans_stack_ptr, trans);
      Transform_outline_points(surface_ptr, trans);
      Transform_outline_vertices(surface_ptr, trans);
      Shade_outline_edges(surface_ptr);
      Pop_trans_stack(trans_stack_ptr);

      {**************************************}
      { transform world coords to eye coords }
      {**************************************}
      Transform_outline_points(surface_ptr, world_to_eye);
    end
  else
    begin
      {**************************************}
      { transform local coords to eye coords }
      {**************************************}
      Get_trans_stack(trans_stack_ptr, trans);
      Transform_outline_points(surface_ptr, trans);
    end;

  case edge_orientation of

    full_edges:
      begin
        {*************************************************}
        { traverse b rep structure and draw outline edges }
        {*************************************************}
        if clipping then
          Outline_b_rep(renderable, surface_ptr, outline_kind)
        else
          Outline_visible_b_rep(renderable, surface_ptr, outline_kind);
      end;

    front_edges:
      begin
        {*******************************************************}
        { traverse b rep structure and draw front outline edges }
        {*******************************************************}
        if clipping then
          Outline_front_b_rep(renderable, surface_ptr, outline_kind)
        else
          Outline_visible_front_b_rep(renderable, surface_ptr, outline_kind);
      end;
  end; {case}
end;


end.
