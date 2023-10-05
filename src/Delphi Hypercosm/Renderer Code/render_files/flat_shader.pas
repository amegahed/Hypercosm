unit flat_shader;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            flat_shader                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module draws a flat shaded rendering of objects    }
{       from the viewing data structs.                          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  trans_stack, state_vars, b_rep, renderable;


{************************************************}
{ routines for flat shading and drawing surfaces }
{************************************************}
procedure Flat_shade_surface(renderable: polygon_renderable_type;
  surface_ptr: surface_ptr_type;
  outline_kind: outline_kind_type;
  trans_stack_ptr: trans_stack_ptr_type;
  clipping, texturing: boolean);


implementation
uses
  SysUtils,
  colors, vectors, trans, project, geometry, topology, xform_b_rep, clip_planes,
  z_clip, hidden_lines, render_lines, coords, shade_b_rep, meshes;


{***************************************************************}
{            flat shading partially visible surfaces            }
{***************************************************************}


procedure Flat_shade_faces(renderable: polygon_renderable_type;
  face_ptr: face_ptr_type);
var
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  face_data_ptr: face_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  while face_ptr <> nil do
    begin
      face_data_ptr := Get_face_data(face_ptr^.index);

      {*********************************}
      { draw only front facing polygons }
      {*********************************}
      if (face_data_ptr^.front_facing) then
        begin
          renderable.Set_color(face_data_ptr^.color);
          renderable.Begin_polygon;
          cycle_ptr := face_ptr^.cycle_ptr;

          while (cycle_ptr <> nil) do
            begin
              directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
              while (directed_edge_ptr <> nil) do
                begin
                  with directed_edge_ptr^ do
                    if orientation then
                      point_data_ptr :=
                        Get_point_data(edge_ptr^.point_ptr1^.index)
                    else
                      point_data_ptr :=
                        Get_point_data(edge_ptr^.point_ptr2^.index);

                  renderable.Add_vertex(point_data_ptr^.trans_point);
                  directed_edge_ptr := directed_edge_ptr^.next;
                end;

              cycle_ptr := cycle_ptr^.next;
              if (cycle_ptr <> nil) then
                renderable.Begin_hole;
            end;

          renderable.Draw_polygon;
        end;
      face_ptr := face_ptr^.next;
    end;
end; {procedure Flat_shade_faces}


procedure Flat_shade_edges(renderable: line_renderable_type;
  edge_ptr: edge_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
begin
  Set_z_line_color(renderable, edge_color);
  while (edge_ptr <> nil) do
    begin
      renderable.Begin_line;

      {***********************}
      { send data for vertex1 }
      {***********************}
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr1^.index);
      renderable.Add_vertex(point_data_ptr^.trans_point);

      {***********************}
      { send data for vertex2 }
      {***********************}
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr2^.index);
      renderable.Add_vertex(point_data_ptr^.trans_point);

      renderable.Draw_line;
      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Flat_shade_edges}


procedure Flat_shade_points(renderable: point_renderable_type;
  point_ptr: point_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
begin
  Set_z_line_color(renderable, edge_color);
  renderable.Begin_points;
  while (point_ptr <> nil) do
    begin
      point_data_ptr := Get_point_data(point_ptr^.index);
      renderable.Add_vertex(point_data_ptr^.trans_point);
      point_ptr := point_ptr^.next;
    end;
  renderable.Draw_points;
end; {procedure Flat_shade_points}


procedure Flat_shade_b_rep(renderable: polygon_renderable_type;
  surface_ptr: surface_ptr_type);
var
  face_ptr: face_ptr_type;
  edge_ptr: edge_ptr_type;
  point_ptr: point_ptr_type;
begin
  {****************************************}
  { clip and project individual z polygons }
  {****************************************}
  Enable_z_clipping;

  {************}
  { draw faces }
  {************}
  face_ptr := surface_ptr^.topology_ptr^.face_ptr;
  if face_ptr <> nil then
    Flat_shade_faces(renderable, face_ptr)
  else
    begin
      {************}
      { draw edges }
      {************}
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      if (edge_ptr <> nil) then
        Flat_shade_edges(renderable, edge_ptr)
      else
        begin
          {*************}
          { draw points }
          {*************}
          point_ptr := surface_ptr^.topology_ptr^.point_ptr;
          if (point_ptr <> nil) then
            Flat_shade_points(renderable, point_ptr);
        end;
    end;
end; {procedure Flat_shade_b_rep}


{***************************************************************}
{        flat shading partially visible textured surfaces       }
{***************************************************************}


procedure Flat_shade_textured_faces(renderable: polygon_renderable_type;
  face_ptr: face_ptr_type);
var
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  face_data_ptr: face_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  while face_ptr <> nil do
    begin
      face_data_ptr := Get_face_data(face_ptr^.index);

      {*********************************}
      { draw only front facing polygons }
      {*********************************}
      if (face_data_ptr^.front_facing) then
        begin
          renderable.Set_color(face_data_ptr^.color);
          renderable.Begin_polygon;
          cycle_ptr := face_ptr^.cycle_ptr;

          while (cycle_ptr <> nil) do
            begin
              directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
              while (directed_edge_ptr <> nil) do
                begin
                  with directed_edge_ptr^ do
                    if orientation then
                      begin
                        point_data_ptr :=
                          Get_point_data(edge_ptr^.point_ptr1^.index);
                        vertex_geometry_ptr :=
                          edge_ptr^.vertex_ptr1^.vertex_geometry_ptr;
                      end
                    else
                      begin
                        point_data_ptr :=
                          Get_point_data(edge_ptr^.point_ptr2^.index);
                        vertex_geometry_ptr :=
                          edge_ptr^.vertex_ptr2^.vertex_geometry_ptr;
                      end;

                  renderable.Set_texture(vertex_geometry_ptr^.texture);
                  renderable.Add_vertex(point_data_ptr^.trans_point);
                  directed_edge_ptr := directed_edge_ptr^.next;
                end;

              cycle_ptr := cycle_ptr^.next;
              if (cycle_ptr <> nil) then
                renderable.Begin_hole;
            end;

          renderable.Draw_polygon;
        end;
      face_ptr := face_ptr^.next;
    end;
end; {procedure Flat_shade_textured_faces}


procedure Flat_shade_textured_edges(renderable: line_renderable_type;
  edge_ptr: edge_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  Set_z_line_color(renderable, edge_color);
  while (edge_ptr <> nil) do
    begin
      renderable.Begin_line;

      {***********************}
      { send data for vertex1 }
      {***********************}
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr1^.index);
      vertex_geometry_ptr := edge_ptr^.vertex_ptr1^.vertex_geometry_ptr;
      renderable.Set_texture(vertex_geometry_ptr^.texture);
      renderable.Add_vertex(point_data_ptr^.trans_point);

      {***********************}
      { send data for vertex2 }
      {***********************}
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr2^.index);
      vertex_geometry_ptr := edge_ptr^.vertex_ptr2^.vertex_geometry_ptr;
      renderable.Set_texture(vertex_geometry_ptr^.texture);
      renderable.Add_vertex(point_data_ptr^.trans_point);

      renderable.Draw_line;
      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Flat_shade_textured_edges}


procedure Flat_shade_textured_vertices(renderable: point_renderable_type;
  vertex_ptr: vertex_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  Set_z_line_color(renderable, edge_color);
  renderable.Begin_points;
  while (vertex_ptr <> nil) do
    begin
      point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
      vertex_geometry_ptr := vertex_ptr^.vertex_geometry_ptr;
      renderable.Set_texture(vertex_geometry_ptr^.texture);
      renderable.Add_vertex(point_data_ptr^.trans_point);
      vertex_ptr := vertex_ptr^.next;
    end;
  renderable.Draw_points;
end; {procedure Flat_shade_textured_vertices}


procedure Flat_shade_textured_b_rep(renderable: polygon_renderable_type;
  surface_ptr: surface_ptr_type);
var
  face_ptr: face_ptr_type;
  edge_ptr: edge_ptr_type;
  vertex_ptr: vertex_ptr_type;
begin
  {****************************************}
  { clip and project individual z polygons }
  {****************************************}
  Enable_z_clipping;

  {************}
  { draw faces }
  {************}
  face_ptr := surface_ptr^.topology_ptr^.face_ptr;
  if face_ptr <> nil then
    Flat_shade_textured_faces(renderable, face_ptr)
  else
    begin
      {************}
      { draw edges }
      {************}
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      if (edge_ptr <> nil) then
        Flat_shade_textured_edges(renderable, edge_ptr)
      else
        begin
          {***************}
          { draw vertices }
          {***************}
          vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
          if (vertex_ptr <> nil) then
            Flat_shade_textured_vertices(renderable, vertex_ptr);
        end;
    end;
end; {procedure Flat_shade_textured_b_rep}


{***************************************************************}
{            flat shading completely visible surfaces           }
{***************************************************************}


procedure Flat_shade_visible_faces(renderable: polygon_renderable_type;
  face_ptr: face_ptr_type);
var
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  face_data_ptr: face_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  while face_ptr <> nil do
    begin
      face_data_ptr := Get_face_data(face_ptr^.index);

      {*********************************}
      { draw only front facing polygons }
      {*********************************}
      if (face_data_ptr^.front_facing) then
        begin
          renderable.Set_color(face_data_ptr^.color);
          renderable.Begin_polygon;
          cycle_ptr := face_ptr^.cycle_ptr;

          while (cycle_ptr <> nil) do
            begin
              directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
              while (directed_edge_ptr <> nil) do
                begin
                  with directed_edge_ptr^ do
                    if orientation then
                      point_data_ptr :=
                        Get_point_data(edge_ptr^.point_ptr1^.index)
                    else
                      point_data_ptr :=
                        Get_point_data(edge_ptr^.point_ptr2^.index);

                  renderable.Add_vertex(point_data_ptr^.vector);
                  directed_edge_ptr := directed_edge_ptr^.next;
                end;

              cycle_ptr := cycle_ptr^.next;
              if (cycle_ptr <> nil) then
                renderable.Begin_hole;
            end;

          renderable.Draw_polygon;
        end;
      face_ptr := face_ptr^.next;
    end;
end; {procedure Flat_shade_visible_faces}


procedure Flat_shade_visible_edges(renderable: line_renderable_type;
  edge_ptr: edge_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
begin
  Set_z_line_color(renderable, edge_color);
  while (edge_ptr <> nil) do
    begin
      renderable.Begin_line;

      {***********************}
      { send data for vertex1 }
      {***********************}
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr1^.index);
      renderable.Add_vertex(point_data_ptr^.vector);

      {***********************}
      { send data for vertex2 }
      {***********************}
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr2^.index);
      renderable.Add_vertex(point_data_ptr^.vector);

      renderable.Draw_line;
      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Flat_shade_visible_edges}


procedure Flat_shade_visible_points(renderable: point_renderable_type;
  point_ptr: point_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
begin
  Set_z_line_color(renderable, edge_color);
  renderable.Begin_points;
  while (point_ptr <> nil) do
    begin
      point_data_ptr := Get_point_data(point_ptr^.index);
      renderable.Add_vertex(point_data_ptr^.vector);
      point_ptr := point_ptr^.next;
    end;
  renderable.Draw_points;
end; {procedure Flat_shade_visible_points}


procedure Flat_shade_visible_b_rep(renderable: polygon_renderable_type;
  surface_ptr: surface_ptr_type);
var
  face_ptr: face_ptr_type;
  edge_ptr: edge_ptr_type;
  point_ptr: point_ptr_type;
begin
  {******************************************}
  { project entire mesh and disable clipping }
  {******************************************}
  Project_points_to_points;
  Disable_z_clipping;

  {************}
  { draw faces }
  {************}
  face_ptr := surface_ptr^.topology_ptr^.face_ptr;
  if face_ptr <> nil then
    Flat_shade_visible_faces(renderable, face_ptr)
  else
    begin
      {************}
      { draw edges }
      {************}
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      if (edge_ptr <> nil) then
        Flat_shade_visible_edges(renderable, edge_ptr)
      else
        begin
          {*************}
          { draw points }
          {*************}
          point_ptr := surface_ptr^.topology_ptr^.point_ptr;
          if (point_ptr <> nil) then
            Flat_shade_visible_points(renderable, point_ptr);
        end;
    end;
end; {procedure Flat_shade_visible_b_rep}


{***************************************************************}
{        flat shading completely visible textured surfaces      }
{***************************************************************}


procedure Flat_shade_visible_textured_faces(renderable: polygon_renderable_type;
  face_ptr: face_ptr_type);
var
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  face_data_ptr: face_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  while face_ptr <> nil do
    begin
      face_data_ptr := Get_face_data(face_ptr^.index);

      {*********************************}
      { draw only front facing polygons }
      {*********************************}
      if (face_data_ptr^.front_facing) then
        begin
          renderable.Set_color(face_data_ptr^.color);
          renderable.Begin_polygon;
          cycle_ptr := face_ptr^.cycle_ptr;

          while (cycle_ptr <> nil) do
            begin
              directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
              while (directed_edge_ptr <> nil) do
                begin
                  with directed_edge_ptr^ do
                    if orientation then
                      begin
                        point_data_ptr :=
                          Get_point_data(edge_ptr^.point_ptr1^.index);
                        vertex_geometry_ptr :=
                          edge_ptr^.vertex_ptr1^.vertex_geometry_ptr;
                      end
                    else
                      begin
                        point_data_ptr :=
                          Get_point_data(edge_ptr^.point_ptr2^.index);
                        vertex_geometry_ptr :=
                          edge_ptr^.vertex_ptr2^.vertex_geometry_ptr;
                      end;

                  renderable.Set_texture(vertex_geometry_ptr^.texture);
                  renderable.Add_vertex(point_data_ptr^.vector);
                  directed_edge_ptr := directed_edge_ptr^.next;
                end;

              cycle_ptr := cycle_ptr^.next;
              if (cycle_ptr <> nil) then
                renderable.Begin_hole;
            end;

          renderable.Draw_polygon;
        end;
      face_ptr := face_ptr^.next;
    end;
end; {procedure Flat_shade_visible_textured_faces}


procedure Flat_shade_visible_textured_edges(renderable: line_renderable_type;
  edge_ptr: edge_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  Set_z_line_color(renderable, edge_color);
  while (edge_ptr <> nil) do
    begin
      renderable.Begin_line;

      {***********************}
      { send data for vertex1 }
      {***********************}
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr1^.index);
      vertex_geometry_ptr := edge_ptr^.vertex_ptr1^.vertex_geometry_ptr;
      renderable.Set_texture(vertex_geometry_ptr^.texture);
      renderable.Add_vertex(point_data_ptr^.vector);

      {***********************}
      { send data for vertex2 }
      {***********************}
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr2^.index);
      vertex_geometry_ptr := edge_ptr^.vertex_ptr2^.vertex_geometry_ptr;
      renderable.Set_texture(vertex_geometry_ptr^.texture);
      renderable.Add_vertex(point_data_ptr^.vector);

      renderable.Draw_line;
      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Flat_shade_visible_textured_edges}


procedure Flat_shade_visible_textured_vertices(renderable: point_renderable_type;
  vertex_ptr: vertex_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  Set_z_line_color(renderable, edge_color);
  renderable.Begin_points;
  while (vertex_ptr <> nil) do
    begin
      point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
      vertex_geometry_ptr := vertex_ptr^.vertex_geometry_ptr;
      renderable.Set_texture(vertex_geometry_ptr^.texture);
      renderable.Add_vertex(point_data_ptr^.vector);
      vertex_ptr := vertex_ptr^.next;
    end;
  renderable.Draw_points;
end; {procedure Flat_shade_visible_textured_points}


procedure Flat_shade_visible_textured_b_rep(renderable: polygon_renderable_type;
  surface_ptr: surface_ptr_type);
var
  face_ptr: face_ptr_type;
  edge_ptr: edge_ptr_type;
  vertex_ptr: vertex_ptr_type;
begin
  {******************************************}
  { project entire mesh and disable clipping }
  {******************************************}
  Project_points_to_points;
  Disable_z_clipping;

  {************}
  { draw faces }
  {************}
  face_ptr := surface_ptr^.topology_ptr^.face_ptr;
  if face_ptr <> nil then
    Flat_shade_visible_textured_faces(renderable, face_ptr)
  else
    begin
      {************}
      { draw edges }
      {************}
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      if (edge_ptr <> nil) then
        Flat_shade_visible_textured_edges(renderable, edge_ptr)
      else
        begin
          {***************}
          { draw vertices }
          {***************}
          vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
          if (vertex_ptr <> nil) then
            Flat_shade_visible_textured_vertices(renderable, vertex_ptr);
        end;
    end;
end; {procedure Flat_shade_visible_textured_b_rep}


{***************************************************************}
{                     flat shading surfaces                     }
{***************************************************************}


procedure Flat_shade_surface(renderable: polygon_renderable_type;
  surface_ptr: surface_ptr_type;
  outline_kind: outline_kind_type;
  trans_stack_ptr: trans_stack_ptr_type;
  clipping, texturing: boolean);
var
  trans: trans_type;
  smooth_shadeable: smooth_shadeable_type;
begin
  Set_lighting_mode(two_sided);

  if Supports(renderable, smooth_shadeable_type, smooth_shadeable) then
    smooth_shadeable.Set_shading_mode(flat_shading_mode);

  edge_color := attributes.color;
  case outline_kind of
    weak_outline:
      pseudo_edge_color := Intensify_color(attributes.color, 0.5);
    bold_outline:
      pseudo_edge_color := attributes.color;
  end;

  {***************************}
  { bind geometry to topology }
  {***************************}
  Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);
  Bind_vertex_geometry(surface_ptr, surface_ptr^.geometry_ptr);
  Bind_face_geometry(surface_ptr, surface_ptr^.geometry_ptr);

  {***********************}
  { compute mesh geometry }
  {***********************}
  if not surface_ptr^.geometry_ptr^.geometry_info.face_normals_avail then
    Find_mesh_face_normals(surface_ptr);
  if not surface_ptr^.geometry_ptr^.geometry_info.vertex_vectors_avail then
    Find_mesh_uv_vectors(surface_ptr);

  {********************************}
  { init auxilliary rendering data }
  {********************************}
  Init_point_data(surface_ptr);
  Init_face_data(surface_ptr);

  {****************************************}
  { disable back face polygon culling if   }
  { concave or clipping planes are present }
  {****************************************}
  if (surface_ptr^.closure = open_surface) or (clipping_planes_ptr <> nil) then
    Set_front_facing_flags(surface_ptr)

    {***************************************}
    { if convex and no clipping planes are  }
    { present then remove back-facing polys }
    {***************************************}
  else
    begin
      Get_trans_stack(trans_stack_ptr, trans);
      Find_face_visibility(surface_ptr, trans);
    end;

  {****************************************}
  { transform local coords to world coords }
  {****************************************}
  Push_trans_stack(trans_stack_ptr);
  Set_trans_mode(premultiply_trans);
  Transform_trans_stack(trans_stack_ptr, eye_to_world);
  Set_trans_mode(postmultiply_trans);
  Get_trans_stack(trans_stack_ptr, trans);
  Transform_point_geometry(trans);
  Transform_face_geometry(trans);
  Pop_trans_stack(trans_stack_ptr);

  {************************************}
  { calculate lighting in world coords }
  {************************************}
  Shade_b_rep_faces(surface_ptr);

  {**************************************}
  { transform world coords to eye coords }
  {**************************************}
  Transform_point_geometry(world_to_eye);

  {***********************************}
  { traverse and scan convert surface }
  {***********************************}
  if clipping then
    begin
      if texturing then
        Flat_shade_textured_b_rep(renderable, surface_ptr)
      else
        Flat_shade_b_rep(renderable, surface_ptr)
    end
  else
    begin
      if texturing then
        Flat_shade_visible_textured_b_rep(renderable, surface_ptr)
      else
        Flat_shade_visible_b_rep(renderable, surface_ptr);
    end;
end; {procedure Flat_shade_surface}


end.
