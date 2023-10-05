unit flat_hider;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             flat_hider                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module draws a hidden line rendering of objects    }
{       from the viewing data structs in flat shaded mode.      }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  trans_stack, state_vars, b_rep;


{************************************************}
{ routines for flat shading and drawing surfaces }
{************************************************}
procedure Flat_hide_surface(surface_ptr: surface_ptr_type;
  outline_kind: outline_kind_type;
  trans_stack_ptr: trans_stack_ptr_type;
  clipping: boolean);


implementation
uses
  colors, vectors, trans, video, display, project, geometry, topology,
  xform_b_rep, z_pipeline, z_buffer, z_polygons, z_lines, z_textures,
  clip_planes, hidden_lines, render_lines, coords, shade_b_rep, meshes;


{***************************************************************}
{             flat shading partially visible surfaces           }
{***************************************************************}


procedure Flat_hide_faces(face_ptr: face_ptr_type);
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
          {*******************************}
          { draw masking edges of polygon }
          {*******************************}
          Clear_parity_buffer;
          Set_parity_mode(set_parity);
          Draw_face_mask(face_ptr);
          Set_parity_mode(not_parity);

          {****************}
          { set fill color }
          {****************}
          if render_mode <> hidden_line_mode then
            Set_z_color(face_data_ptr^.color)
          else
            Set_z_color(background_color);

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
end; {procedure Flat_hide_faces}


procedure Flat_hide_edges(edge_ptr: edge_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
begin
  Set_z_line_color(edge_color);
  while (edge_ptr <> nil) do
    begin
      Begin_z_line;

      {***********************}
      { send data for vertex1 }
      {***********************}
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr1^.index);
      Add_z_vertex(point_data_ptr^.trans_point);

      {***********************}
      { send data for vertex2 }
      {***********************}
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr2^.index);
      Add_z_vertex(point_data_ptr^.trans_point);

      Draw_z_line;
      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Flat_hide_edges}


procedure Flat_hide_points(point_ptr: point_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
begin
  Set_z_line_color(edge_color);
  Begin_z_points;
  while (point_ptr <> nil) do
    begin
      point_data_ptr := Get_point_data(point_ptr^.index);
      Add_z_vertex(point_data_ptr^.trans_point);
      point_ptr := point_ptr^.next;
    end;
  Draw_z_points;
end; {procedure Flat_hide_points}


procedure Flat_hide_b_rep(surface_ptr: surface_ptr_type);
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
    Flat_hide_faces(face_ptr)
  else
    begin
      {************}
      { draw edges }
      {************}
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      if (edge_ptr <> nil) then
        Flat_hide_edges(edge_ptr)
      else
        begin
          {*************}
          { draw points }
          {*************}
          point_ptr := surface_ptr^.topology_ptr^.point_ptr;
          if (point_ptr <> nil) then
            Flat_hide_points(point_ptr);
        end;
    end;

  Update_window;
end; {procedure Flat_hide_b_rep}


{***************************************************************}
{         flat shading partially visible textured surfaces      }
{***************************************************************}


procedure Flat_hide_textured_faces(face_ptr: face_ptr_type);
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
          {*******************************}
          { draw masking edges of polygon }
          {*******************************}
          Clear_parity_buffer;
          Set_parity_mode(set_parity);
          Draw_face_mask(face_ptr);
          Set_parity_mode(not_parity);

          {****************}
          { set fill color }
          {****************}
          if render_mode <> hidden_line_mode then
            Set_z_color(face_data_ptr^.color)
          else
            Set_z_color(background_color);

          Begin_z_polygon;
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

                  Set_z_texture(vertex_geometry_ptr^.texture);
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
end; {procedure Flat_hide_textured_faces}


procedure Flat_hide_textured_edges(edge_ptr: edge_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  Set_z_line_color(edge_color);
  while (edge_ptr <> nil) do
    begin
      Begin_z_line;

      {***********************}
      { send data for vertex1 }
      {***********************}
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr1^.index);
      vertex_geometry_ptr := edge_ptr^.vertex_ptr1^.vertex_geometry_ptr;
      Set_z_texture(vertex_geometry_ptr^.texture);
      Add_z_vertex(point_data_ptr^.trans_point);

      {***********************}
      { send data for vertex2 }
      {***********************}
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr2^.index);
      vertex_geometry_ptr := edge_ptr^.vertex_ptr2^.vertex_geometry_ptr;
      Set_z_texture(vertex_geometry_ptr^.texture);
      Add_z_vertex(point_data_ptr^.trans_point);

      Draw_z_line;
      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Flat_hide_textured_edges}


procedure Flat_hide_textured_vertices(vertex_ptr: vertex_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  Set_z_line_color(edge_color);
  Begin_z_points;
  while (vertex_ptr <> nil) do
    begin
      point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
      vertex_geometry_ptr := vertex_ptr^.vertex_geometry_ptr;
      Set_z_texture(vertex_geometry_ptr^.texture);
      Add_z_vertex(point_data_ptr^.trans_point);
      vertex_ptr := vertex_ptr^.next;
    end;
  Draw_z_points;
end; {procedure Flat_hide_textured_vertices}


procedure Flat_hide_textured_b_rep(surface_ptr: surface_ptr_type);
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
    Flat_hide_textured_faces(face_ptr)
  else
    begin
      {************}
      { draw edges }
      {************}
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      if (edge_ptr <> nil) then
        Flat_hide_textured_edges(edge_ptr)
      else
        begin
          {***************}
          { draw vertices }
          {***************}
          vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
          if (vertex_ptr <> nil) then
            Flat_hide_textured_vertices(vertex_ptr);
        end;
    end;

  Update_window;
end; {procedure Flat_hide_textured_b_rep}


{***************************************************************}
{            flat shading completely visible surfaces           }
{***************************************************************}


procedure Flat_hide_visible_faces(face_ptr: face_ptr_type);
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
          {*******************************}
          { draw masking edges of polygon }
          {*******************************}
          Clear_parity_buffer;
          Set_parity_mode(set_parity);
          Draw_visible_face_mask(face_ptr);
          Set_parity_mode(not_parity);

          {****************}
          { set fill color }
          {****************}
          if render_mode <> hidden_line_mode then
            Set_z_color(face_data_ptr^.color)
          else
            Set_z_color(background_color);

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
end; {procedure Flat_hide_visible_faces}


procedure Flat_hide_visible_edges(edge_ptr: edge_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
begin
  Set_z_line_color(edge_color);
  while (edge_ptr <> nil) do
    begin
      Begin_z_line;

      {***********************}
      { send data for vertex1 }
      {***********************}
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr1^.index);
      Add_z_vertex(point_data_ptr^.vector);

      {***********************}
      { send data for vertex2 }
      {***********************}
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr2^.index);
      Add_z_vertex(point_data_ptr^.vector);

      Draw_z_line;
      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Flat_hide_visible_edges}


procedure Flat_hide_visible_points(point_ptr: point_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
begin
  Set_z_line_color(edge_color);
  Begin_z_points;
  while (point_ptr <> nil) do
    begin
      point_data_ptr := Get_point_data(point_ptr^.index);
      Add_z_vertex(point_data_ptr^.vector);
      point_ptr := point_ptr^.next;
    end;
  Draw_z_points;
end; {procedure Flat_hide_visible_points}


procedure Flat_hide_visible_b_rep(surface_ptr: surface_ptr_type);
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
    Flat_hide_visible_faces(face_ptr)
  else
    begin
      {************}
      { draw edges }
      {************}
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      if (edge_ptr <> nil) then
        Flat_hide_visible_edges(edge_ptr)
      else
        begin
          {*************}
          { draw points }
          {*************}
          point_ptr := surface_ptr^.topology_ptr^.point_ptr;
          if (point_ptr <> nil) then
            Flat_hide_visible_points(point_ptr);
        end;
    end;

  Update_window;
end; {procedure Flat_hide_visible_b_rep}


{***************************************************************}
{       flat shading completely visible textured surfaces       }
{***************************************************************}


procedure Flat_hide_visible_textured_faces(face_ptr: face_ptr_type);
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
          {*******************************}
          { draw masking edges of polygon }
          {*******************************}
          Clear_parity_buffer;
          Set_parity_mode(set_parity);
          Draw_visible_face_mask(face_ptr);
          Set_parity_mode(not_parity);

          {****************}
          { set fill color }
          {****************}
          if render_mode <> hidden_line_mode then
            Set_z_color(face_data_ptr^.color)
          else
            Set_z_color(background_color);

          Begin_z_polygon;
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

                  Set_z_texture(vertex_geometry_ptr^.texture);
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
end; {procedure Flat_hide_visible_textured_faces}


procedure Flat_hide_visible_textured_edges(edge_ptr: edge_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  Set_z_line_color(edge_color);
  while (edge_ptr <> nil) do
    begin
      Begin_z_line;

      {***********************}
      { send data for vertex1 }
      {***********************}
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr1^.index);
      vertex_geometry_ptr := edge_ptr^.vertex_ptr1^.vertex_geometry_ptr;
      Set_z_texture(vertex_geometry_ptr^.texture);
      Add_z_vertex(point_data_ptr^.vector);

      {***********************}
      { send data for vertex2 }
      {***********************}
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr2^.index);
      vertex_geometry_ptr := edge_ptr^.vertex_ptr2^.vertex_geometry_ptr;
      Set_z_texture(vertex_geometry_ptr^.texture);
      Add_z_vertex(point_data_ptr^.vector);

      Draw_z_line;
      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Flat_hide_visible_textured_edges}


procedure Flat_hide_visible_textured_vertices(vertex_ptr: vertex_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  Set_z_line_color(edge_color);
  Begin_z_points;
  while (vertex_ptr <> nil) do
    begin
      point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
      vertex_geometry_ptr := vertex_ptr^.vertex_geometry_ptr;
      Set_z_texture(vertex_geometry_ptr^.texture);
      Add_z_vertex(point_data_ptr^.vector);
      vertex_ptr := vertex_ptr^.next;
    end;
  Draw_z_points;
end; {procedure Flat_hide_visible_textured_vertices}


procedure Flat_hide_visible_textured_b_rep(surface_ptr: surface_ptr_type);
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
    Flat_hide_visible_textured_faces(face_ptr)
  else
    begin
      {************}
      { draw edges }
      {************}
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      if (edge_ptr <> nil) then
        Flat_hide_visible_textured_edges(edge_ptr)
      else
        begin
          {***************}
          { draw vertices }
          {***************}
          vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
          if (vertex_ptr <> nil) then
            Flat_hide_visible_textured_vertices(vertex_ptr);
        end;
    end;

  Update_window;
end; {procedure Flat_hide_visible_textured_b_rep}


{***************************************************************}
{                     flat shading surfaces                     }
{***************************************************************}


procedure Flat_hide_surface(surface_ptr: surface_ptr_type;
  outline_kind: outline_kind_type;
  trans_stack_ptr: trans_stack_ptr_type;
  clipping: boolean);
var
  trans: trans_type;
begin
  Set_video_dither(true);
  Set_lighting_mode(two_sided);
  Set_z_mode(flat_z_mode);

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
  if not surface_ptr^.geometry_ptr^.vertex_vectors_avail then
    Find_mesh_uv_vectors(surface_ptr);

  {********************************}
  { init auxilliary rendering data }
  {********************************}
  Init_point_data(surface_ptr);
  Init_face_data(surface_ptr);

  {**********************************}
    { find front and back facing polys }
    {**********************************}
  Get_trans_stack(trans_stack_ptr, trans);
  Find_face_visibility(surface_ptr, trans);

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
  if attributes.render_mode <> hidden_line_mode then
    begin
      Shade_b_rep_faces(surface_ptr);
      Shade_b_rep_edges(surface_ptr);
    end;

  {**************************************}
  { transform world coords to eye coords }
  {**************************************}
  Transform_point_geometry(world_to_eye);

  {***********************************}
  { traverse and scan convert surface }
  {***********************************}
  if clipping then
    begin
      if Get_current_z_texture <> nil then
        Flat_hide_textured_b_rep(surface_ptr)
      else
        Flat_hide_b_rep(surface_ptr)
    end
  else
    begin
      if Get_current_z_texture <> nil then
        Flat_hide_visible_textured_b_rep(surface_ptr)
      else
        Flat_hide_visible_b_rep(surface_ptr);
    end;
end; {procedure Flat_hide_surface}


end. {module flat_hider}
