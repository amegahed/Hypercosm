unit phong_hider;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            phong_hider                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module draws a phong shaded rendering of objects   }
{       from the viewing data structs in hidden line mode.      }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  trans_stack, state_vars, b_rep;


{*************************************************}
{ routines for Phong shading and drawing surfaces }
{*************************************************}
procedure Phong_hide_surface(surface_ptr: surface_ptr_type;
  outline_kind: outline_kind_type;
  trans_stack_ptr: trans_stack_ptr_type;
  clipping: boolean);


implementation
uses
  colors, vectors, trans, coord_axes, video, display, eye, project,
  geometry, topology, object_attr, coord_stack, xform_b_rep, z_pipeline,
  z_buffer, z_polygons, z_lines, z_clip, z_triangles, z_hardware, z_phong,
  clip_planes, hidden_lines, render_lines, coords, shade_b_rep, meshes;


procedure Transform_surface_vectors;
var
  trans: trans_type;
  prim_height: integer;
  object_height: integer;
  counter: integer;
begin
  {*************************************************}
  { create transformation from primitive to surface }
  {*************************************************}
  trans := unit_trans;
  object_height := shader_stack_height;
  prim_height := Coord_stack_height(coord_stack_ptr);

  {*********************}
  { primitive to object }
  {*********************}
  for counter := prim_height downto (object_height + 1) do
    Transform_trans_from_axes(trans, coord_stack_ptr^.stack[counter]);

  {******************}
  { object to shader }
  {******************}
  Transform_trans_to_axes(trans, shader_axes);

  {****************************************************}
  { transform u_axis and v_axis vectors at each vertex }
  {****************************************************}
  Transform_uv_axis_geometry(trans);
end; {procedure Transform_surface_vectors}


procedure Calculate_face_normals(surface_ptr: surface_ptr_type);
var
  vertex_ptr: vertex_ptr_type;
  face_ptr: face_ptr_type;
  point, normal: vector_type;
  point_data_ptr: point_data_ptr_type;
  face_data_ptr: face_data_ptr_type;
begin
  face_ptr := surface_ptr^.topology_ptr^.face_ptr;
  while (face_ptr <> nil) do
    begin
      {*******************************}
      { calculate front facing normal }
      {*******************************}
      vertex_ptr :=
        face_ptr^.cycle_ptr^.directed_edge_ptr^.edge_ptr^.vertex_ptr1;
      point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
      point := point_data_ptr^.trans_point;
      face_data_ptr := Get_face_data(face_ptr^.index);
      normal := face_data_ptr^.trans_normal;
      face_data_ptr^.trans_normal := Vector_away(normal, Vector_difference(point,
        eye_point));
      face_ptr := face_ptr^.next;
    end;
end; {procedure Calculate_face_normals}


procedure Calculate_vertex_normals(surface_ptr: surface_ptr_type);
var
  vertex_ptr: vertex_ptr_type;
  vertex_data_ptr: vertex_data_ptr_type;
begin
  vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
  while (vertex_ptr <> nil) do
    begin
      {***************************************}
      { compute front and back facing normals }
      {***************************************}
      vertex_data_ptr := Get_vertex_data(vertex_ptr^.index);
      vertex_data_ptr^.back_normal := vertex_data_ptr^.trans_normal;
      vertex_data_ptr^.front_normal :=
        Vector_reverse(vertex_data_ptr^.trans_normal);
      vertex_ptr := vertex_ptr^.next;
    end;
end; {procedure Calculate_vertex_normals}


procedure Save_global_vertices(point_ptr: point_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
begin
  while (point_ptr <> nil) do
    begin
      {**********************************}
      { copy trans point to global field }
      {**********************************}
      point_data_ptr := Get_point_data(point_ptr^.index);
      with point_data_ptr^ do
        global_point := trans_point;
      point_ptr := point_ptr^.next;
    end;
end; {procedure Save_global_vertices}


{***************************************************************}
{              filling partially visible surfaces               }
{***************************************************************}


procedure Fill_faces(face_ptr: face_ptr_type);
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
          {****************************}
          { draw mask edges of polygon }
          {****************************}
          Clear_parity_buffer;
          Set_parity_mode(set_parity);
          Draw_face_edges(face_ptr);
          Set_parity_mode(not_parity);

          Begin_z_polygon;
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

                  Add_z_vertex(point_data_ptr^.trans_point);
                  directed_edge_ptr := directed_edge_ptr^.next;
                end;
              cycle_ptr := cycle_ptr^.next;
              if (cycle_ptr <> nil) then
                Begin_z_hole;
            end;

          Draw_z_polygon;
          Draw_face_silhouette(face_ptr);
        end;
      face_ptr := face_ptr^.next;
    end;
end; {procedure Fill_faces}


{***************************************************************}
{           Phong shading partially visible surfaces            }
{***************************************************************}


procedure Phong_z_vertex(vertex_ptr: vertex_ptr_type;
  shading: surface_shading_type;
  face_normal: vector_type);
var
  vertex_geometry_ptr: vertex_geometry_ptr_type;
  vertex_data_ptr: vertex_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  {vertex_geometry_ptr := Get_vertex_geometry(vertex_ptr^.index);}
  vertex_geometry_ptr := vertex_ptr^.vertex_geometry_ptr;
  vertex_data_ptr := Get_vertex_data(vertex_ptr^.index);
  point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);

  {************************************************}
  { if face is front facing, then use front facing }
  { normal for vertex, else use back facing normal }
  {************************************************}
  with vertex_data_ptr^ do
    if (shading = smooth_shading) then
      begin
        if Same_direction(trans_normal, face_normal) then
          Set_z_normal(front_normal)
        else
          Set_z_normal(back_normal);
      end;

  with vertex_geometry_ptr^ do
    begin
      Set_z_texture(texture);
      with vertex_data_ptr^ do
        Set_z_vectors(trans_u_axis, trans_v_axis);
    end;

  with point_data_ptr^ do
    begin
      Set_z_vertex(global_point);
      Add_z_vertex(trans_point);
    end;
end; {procedure Phong_z_vertex}


procedure Phong_hide_faces(face_ptr: face_ptr_type;
  shading: surface_shading_type);
var
  vertex_ptr: vertex_ptr_type;
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  face_normal, point: vector_type;
  face_data_ptr: face_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  while (face_ptr <> nil) do
    begin
      face_data_ptr := Get_face_data(face_ptr^.index);

      {*********************************}
      { draw only front facing polygons }
      {*********************************}
      if (face_data_ptr^.front_facing) then
        begin
          {**********************************}
          { compute front facing face normal }
          {**********************************}
          face_normal := face_data_ptr^.trans_normal;
          vertex_ptr :=
            face_ptr^.cycle_ptr^.directed_edge_ptr^.edge_ptr^.vertex_ptr1;
          point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
          point := point_data_ptr^.trans_point;
          face_normal := Vector_towards(face_normal, point);

          {*****************************************}
          { set ptrs to avoid self shadowing meshes }
          {*****************************************}
          hierarchical_obj.mesh_face_ptr := face_ptr;
          hierarchical_obj.mesh_point_ptr := nil;

          {****************************}
          { draw mask edges of polygon }
          {****************************}
          Clear_parity_buffer;
          Set_parity_mode(set_parity);
          Draw_face_mask(face_ptr);
          Set_parity_mode(not_parity);

          {**************}
          { draw polygon }
          {**************}
          Begin_z_polygon;
          Set_z_normal(face_data_ptr^.trans_normal);
          cycle_ptr := face_ptr^.cycle_ptr;
          while (cycle_ptr <> nil) do
            begin
              directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
              while (directed_edge_ptr <> nil) do
                begin
                  if directed_edge_ptr^.orientation then
                    vertex_ptr := directed_edge_ptr^.edge_ptr^.vertex_ptr1
                  else
                    vertex_ptr := directed_edge_ptr^.edge_ptr^.vertex_ptr2;

                  Phong_z_vertex(vertex_ptr, shading, face_normal);
                  directed_edge_ptr := directed_edge_ptr^.next;
                end;
              cycle_ptr := cycle_ptr^.next;
            end;

          End_z_polygon;
          Phong_z_polygon;
          Draw_face_silhouette(face_ptr);
        end;

      face_ptr := face_ptr^.next;
    end;
end; {procedure Phong_hide_faces}


procedure Phong_hide_edges(edge_ptr: edge_ptr_type);
begin
  while (edge_ptr <> nil) do
    begin
      Begin_z_line;
      Phong_z_vertex(edge_ptr^.vertex_ptr1, smooth_shading, z_vector);
      Phong_z_vertex(edge_ptr^.vertex_ptr2, smooth_shading, z_vector);
      Phong_z_line;
      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Phong_hide_edges}


procedure Phong_hide_vertices(vertex_ptr: vertex_ptr_type);
begin
  Begin_z_points;
  while (vertex_ptr <> nil) do
    begin
      Phong_z_vertex(vertex_ptr, smooth_shading, z_vector);
      vertex_ptr := vertex_ptr^.next;
    end;
  Phong_z_points;
end; {procedure Phong_hide_vertices}


procedure Phong_hide_b_rep(surface_ptr: surface_ptr_type);
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
    begin
      {*************************************************}
      { first draw the polygon into z buffer using the  }
      { background color to avoid shading hidden pixels }
      {*************************************************}
      Set_video_dither(false);
      Set_z_color(background_color);
      Fill_faces(face_ptr);

      {*********************************************}
      { next draw the polygon into z buffer shading }
      { only the front facing (non hidden) surface. }
      {*********************************************}
      Set_video_dither(true);
      Phong_hide_faces(face_ptr, surface_ptr^.shading);
    end
  else
    begin
      {************}
      { draw edges }
      {************}
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      if (edge_ptr <> nil) then
        Phong_hide_edges(edge_ptr)
      else
        begin
          {***************}
          { draw vertices }
          {***************}
          vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
          if (vertex_ptr <> nil) then
            Phong_hide_vertices(vertex_ptr);
        end;
    end;
end; {procedure Phong_hide_b_rep}


{***************************************************************}
{              filling completely visible surfaces              }
{***************************************************************}


procedure Fill_visible_faces(face_ptr: face_ptr_type);
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
          {****************************}
          { draw mask edges of polygon }
          {****************************}
          Clear_parity_buffer;
          Set_parity_mode(set_parity);
          Draw_visible_face_mask(face_ptr);
          Set_parity_mode(not_parity);

          Begin_z_polygon;
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

                  Add_z_vertex(point_data_ptr^.vector);
                  directed_edge_ptr := directed_edge_ptr^.next;
                end;
              cycle_ptr := cycle_ptr^.next;
              if (cycle_ptr <> nil) then
                Begin_z_hole;
            end;

          Draw_z_polygon;
          Draw_visible_face_silhouette(face_ptr);
        end;
      face_ptr := face_ptr^.next;
    end;
end; {procedure Fill_visible_faces}


{***************************************************************}
{            Phong shading completely visible surfaces          }
{***************************************************************}


procedure Phong_z_visible_vertex(vertex_ptr: vertex_ptr_type;
  shading: surface_shading_type;
  face_normal: vector_type);
var
  vertex_geometry_ptr: vertex_geometry_ptr_type;
  vertex_data_ptr: vertex_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  {vertex_geometry_ptr := Get_vertex_geometry(vertex_ptr^.index);}
  vertex_geometry_ptr := vertex_ptr^.vertex_geometry_ptr;

  vertex_data_ptr := Get_vertex_data(vertex_ptr^.index);
  point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);

  {************************************************}
  { if face is front facing, then use front facing }
  { normal for vertex, else use back facing normal }
  {************************************************}
  with vertex_data_ptr^ do
    if (shading = smooth_shading) then
      begin
        if Same_direction(trans_normal, face_normal) then
          Set_z_normal(front_normal)
        else
          Set_z_normal(back_normal);
      end;

  with vertex_geometry_ptr^ do
    begin
      Set_z_texture(texture);
      with vertex_data_ptr^ do
        Set_z_vectors(trans_u_axis, trans_v_axis);
    end;

  with point_data_ptr^ do
    begin
      Set_z_vertex(global_point);
      Add_z_vertex(vector);
    end;
end; {procedure Phong_z_visible_vertex}


procedure Phong_hide_visible_faces(face_ptr: face_ptr_type;
  shading: surface_shading_type);
var
  vertex_ptr: vertex_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  cycle_ptr: cycle_ptr_type;
  face_normal, point: vector_type;
  face_data_ptr: face_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  while (face_ptr <> nil) do
    begin
      face_data_ptr := Get_face_data(face_ptr^.index);

      {*********************************}
      { draw only front facing polygons }
      {*********************************}
      if (face_data_ptr^.front_facing) then
        begin
          {**********************************}
          { compute front facing face normal }
          {**********************************}
          face_normal := face_data_ptr^.trans_normal;
          vertex_ptr :=
            face_ptr^.cycle_ptr^.directed_edge_ptr^.edge_ptr^.vertex_ptr1;
          point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
          point := point_data_ptr^.trans_point;
          face_normal := Vector_towards(face_normal, point);

          {*****************************************}
          { set ptrs to avoid self shadowing meshes }
          {*****************************************}
          hierarchical_obj.mesh_face_ptr := face_ptr;
          hierarchical_obj.mesh_point_ptr := nil;

          {***********************}
          { draw edges of polygon }
          {***********************}
          Clear_parity_buffer;
          Set_parity_mode(set_parity);
          Draw_visible_face_mask(face_ptr);
          Set_parity_mode(not_parity);

          {**************}
          { draw polygon }
          {**************}
          Begin_z_polygon;
          Set_z_normal(face_data_ptr^.trans_normal);
          cycle_ptr := face_ptr^.cycle_ptr;
          while (cycle_ptr <> nil) do
            begin
              directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
              while (directed_edge_ptr <> nil) do
                begin
                  with directed_edge_ptr^ do
                    if orientation then
                      vertex_ptr := edge_ptr^.vertex_ptr1
                    else
                      vertex_ptr := edge_ptr^.vertex_ptr2;

                  Phong_z_visible_vertex(vertex_ptr, shading, face_normal);
                  directed_edge_ptr := directed_edge_ptr^.next;
                end;
              cycle_ptr := cycle_ptr^.next;
            end;

          End_z_polygon;
          Phong_z_polygon;
          Draw_visible_face_silhouette(face_ptr);
        end;

      face_ptr := face_ptr^.next;
    end;
end; {procedure Phong_hide_visible_faces}


procedure Phong_hide_visible_edges(edge_ptr: edge_ptr_type);
begin
  while (edge_ptr <> nil) do
    begin
      Begin_z_line;
      Phong_z_visible_vertex(edge_ptr^.vertex_ptr1, smooth_shading, z_vector);
      Phong_z_visible_vertex(edge_ptr^.vertex_ptr2, smooth_shading, z_vector);
      Phong_z_line;
      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Phong_hide_visible_edges}


procedure Phong_hide_visible_vertices(vertex_ptr: vertex_ptr_type);
begin
  Begin_z_points;
  while (vertex_ptr <> nil) do
    begin
      Phong_z_vertex(vertex_ptr, smooth_shading, z_vector);
      vertex_ptr := vertex_ptr^.next;
    end;
  Draw_z_points;
end; {procedure Phong_hide_visible_vertices}


procedure Phong_hide_visible_b_rep(surface_ptr: surface_ptr_type);
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
    begin
      {*************************************************}
      { first draw the polygon into z buffer using the  }
      { background color to avoid shading hidden pixels }
      {*************************************************}
      Set_video_dither(false);
      Set_z_color(background_color);
      Fill_visible_faces(face_ptr);

      {*********************************************}
      { next draw the polygon into z buffer shading }
      { only the front facing (non hidden) surface. }
      {*********************************************}
      Set_video_dither(true);
      Phong_hide_visible_faces(face_ptr, surface_ptr^.shading);
    end
  else
    begin
      {************}
      { draw edges }
      {************}
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      if (edge_ptr <> nil) then
        Phong_hide_visible_edges(edge_ptr)
      else
        begin
          {***************}
          { draw vertices }
          {***************}
          vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
          if (vertex_ptr <> nil) then
            Phong_hide_visible_vertices(vertex_ptr);
        end;
    end;

  Update_window;
end; {procedure Phong_hide_visible_b_rep}


{***************************************************************}
{                     Phong shading surfaces                    }
{***************************************************************}


procedure Phong_hide_surface(surface_ptr: surface_ptr_type;
  outline_kind: outline_kind_type;
  trans_stack_ptr: trans_stack_ptr_type;
  clipping: boolean);
var
  trans: trans_type;
begin
  Set_video_dither(attributes.render_mode <> hidden_line_mode);
  Set_lighting_mode(one_sided);

  edge_color := attributes.color;
  case outline_kind of
    weak_outline:
      pseudo_edge_color := Intensify_color(attributes.color, 0.5);
    bold_outline:
      pseudo_edge_color := attributes.color;
  end;

  {*********************************}
  { set current geometry to surface }
  {*********************************}
  Set_geometry(surface_ptr^.geometry_ptr);

  {***************************}
  { bind geometry to topology }
  {***************************}
  Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);
  Bind_vertex_geometry(surface_ptr, surface_ptr^.geometry_ptr);
  Bind_face_geometry(surface_ptr, surface_ptr^.geometry_ptr);

  {***********************}
  { compute mesh geometry }
  {***********************}
  if not surface_ptr^.geometry_ptr^.face_normals_avail then
    Find_mesh_face_normals(surface_ptr);
  if not surface_ptr^.geometry_ptr^.vertex_normals_avail then
    Find_mesh_vertex_normals(surface_ptr);
  if not surface_ptr^.geometry_ptr^.vertex_vectors_avail then
    Find_mesh_uv_vectors(surface_ptr);

  {********************************}
  { init auxilliary rendering data }
  {********************************}
  Init_point_data(surface_ptr);
  Init_vertex_data(surface_ptr);
  Init_face_data(surface_ptr);

  {***********************************}
  { calculate normals in world coords }
  {***********************************}
  Push_trans_stack(trans_stack_ptr);
  Set_trans_mode(premultiply_trans);
  Transform_trans_stack(trans_stack_ptr, eye_to_world);
  Set_trans_mode(postmultiply_trans);
  Get_trans_stack(trans_stack_ptr, trans);
  Transform_point_geometry(trans);
  Transform_vertex_geometry(trans);
  Transform_face_geometry(trans);
  Pop_trans_stack(trans_stack_ptr);

  {***********************************************}
  { save global coords for use in texture mapping }
  {***********************************************}
  Save_global_vertices(surface_ptr^.topology_ptr^.point_ptr);

  {***************************************}
  { calculate uv vectors in shader coords }
  {***************************************}
  Transform_surface_vectors;

  {******************************}
  { compute front facing normals }
  {******************************}
  case surface_ptr^.shading of
    flat_shading:
      Calculate_face_normals(surface_ptr);
    smooth_shading:
      Calculate_vertex_normals(surface_ptr);
  end; {case}

  {******************************************}
  { if convex, then remove back-facing polys }
  {******************************************}
  if (surface_ptr^.closure = closed_surface) then
    begin
      Get_trans_stack(trans_stack_ptr, trans);
      Find_face_visibility(surface_ptr, trans);
    end;

  {*****************}
    { find silhouette }
    {*****************}
  Init_edge_data(surface_ptr);
  Find_silhouette(surface_ptr);

  {***********************************}
  { disable back face polygon culling }
  {***********************************}
  if (surface_ptr^.closure = open_surface) or (clipping_planes_ptr <> nil) then
    Set_front_facing_flags(surface_ptr);

  {**************************************}
  { transform world coords to eye coords }
  {**************************************}
  Transform_point_geometry(world_to_eye);
  Transform_vertex_geometry(world_to_eye);
  Transform_face_geometry(world_to_eye);

  {***********************************}
  { traverse and scan convert surface }
  {***********************************}
  if clipping then
    Phong_hide_b_rep(surface_ptr)
  else
    Phong_hide_visible_b_rep(surface_ptr);
end; {procedure Phong_hide_surface}


end. {module phong_hider}
