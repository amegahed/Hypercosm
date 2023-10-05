unit gouraud_shader;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            gouraud_shader             3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module draws a gouraud shaded rendering of         }
{       objects from the viewing data structs.                  }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  trans_stack, state_vars, b_rep, renderable;


{***************************************************}
{ routines for Gouraud shading and drawing surfaces }
{***************************************************}
procedure Gouraud_shade_surface(renderable: polygon_renderable_type;
  surface_ptr: surface_ptr_type;
  outline_kind: outline_kind_type;
  trans_stack_ptr: trans_stack_ptr_type;
  clipping, texturing: boolean);


implementation
uses
  SysUtils,
  colors, vectors, trans, project, geometry, topology, xform_b_rep, clip_planes,
  z_clip, hidden_lines, render_lines, coords, shade_b_rep, meshes, flat_shader;


{***************************************************************}
{           Gouraud shading partially visible surfaces          }
{***************************************************************}


procedure Gouraud_shade_faces(renderable: polygon_renderable_type;
  face_ptr: face_ptr_type);
var
  vertex_ptr: vertex_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  face_data_ptr: face_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
  vertex_data_ptr: vertex_data_ptr_type;
  vertex_normal_kind: vertex_normal_kind_type;
  point, face_normal: vector_type;
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
          point_data_ptr :=
            Get_point_data(face_ptr^.cycle_ptr^.directed_edge_ptr^.edge_ptr^.point_ptr1^.index);
          point := point_data_ptr^.trans_point;
          face_normal := Vector_towards(face_normal, point);

          {**************}
          { draw polygon }
          {**************}
          renderable.Begin_polygon;
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

                  {vertex_geometry_ptr := Get_vertex_geometry(vertex_ptr^.index);}
                  vertex_geometry_ptr := vertex_ptr^.vertex_geometry_ptr;
                  vertex_data_ptr := Get_vertex_data(vertex_ptr^.index);
                  point_data_ptr :=
                    Get_point_data(vertex_ptr^.point_ptr^.index);
                  vertex_normal_kind := vertex_geometry_ptr^.vertex_normal_kind;

                  with vertex_ptr^ do
                    if (point_data_ptr^.surface_visibility = silhouette_edge)
                      and (vertex_normal_kind = two_sided_vertex) then
                      begin
                        {************************************************}
                        { if face is front facing, then use front facing }
                        { color for vertex, else use back facing color   }
                        {************************************************}
                        if Same_direction(vertex_data_ptr^.trans_normal,
                          face_normal) then
                          renderable.Set_color(vertex_data_ptr^.back_color)
                        else
                          renderable.Set_color(vertex_data_ptr^.front_color);
                      end
                    else
                      begin
                        {*************************************************}
                        { not a silhouette vertex, use front facing color }
                        {*************************************************}
                        renderable.Set_color(vertex_data_ptr^.front_color);
                      end;

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
end; {procedure Gouraud_shade_faces}


procedure Gouraud_shade_edges(renderable: line_renderable_type;
  edge_ptr: edge_ptr_type);
var
  vertex_data_ptr: vertex_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  while (edge_ptr <> nil) do
    begin
      renderable.Begin_line;

      {***********************}
      { send data for vertex1 }
      {***********************}
      vertex_data_ptr := Get_vertex_data(edge_ptr^.vertex_ptr1^.index);
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr1^.index);
      renderable.Set_color(vertex_data_ptr^.front_color);
      renderable.Add_vertex(point_data_ptr^.trans_point);

      {***********************}
      { send data for vertex2 }
      {***********************}
      vertex_data_ptr := Get_vertex_data(edge_ptr^.vertex_ptr2^.index);
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr2^.index);
      renderable.Set_color(vertex_data_ptr^.front_color);
      renderable.Add_vertex(point_data_ptr^.trans_point);

      renderable.Draw_line;
      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Gouraud_shade_edges}


procedure Gouraud_shade_vertices(renderable: point_renderable_type;
  vertex_ptr: vertex_ptr_type);
var
  vertex_data_ptr: vertex_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  renderable.Begin_points;
  while (vertex_ptr <> nil) do
    begin
      vertex_data_ptr := Get_vertex_data(vertex_ptr^.index);
      point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
      renderable.Set_color(vertex_data_ptr^.front_color);
      renderable.Add_vertex(point_data_ptr^.trans_point);
      vertex_ptr := vertex_ptr^.next;
    end;
  renderable.Draw_points;
end; {procedure Gouraud_shade_vertices}


procedure Gouraud_shade_b_rep(renderable: polygon_renderable_type;
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
    Gouraud_shade_faces(renderable, face_ptr)
  else
    begin
      {************}
      { draw edges }
      {************}
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      if (edge_ptr <> nil) then
        Gouraud_shade_edges(renderable, edge_ptr)
      else
        begin
          {***************}
          { draw vertices }
          {***************}
          vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
          if (vertex_ptr <> nil) then
            Gouraud_shade_vertices(renderable, vertex_ptr);
        end;
    end;
end; {procedure Gouraud_shade_b_rep}


{***************************************************************}
{       Gouraud shading partially visible textured surfaces     }
{***************************************************************}


procedure Gouraud_shade_textured_faces(renderable: polygon_renderable_type;
  face_ptr: face_ptr_type);
var
  vertex_ptr: vertex_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  face_data_ptr: face_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
  vertex_data_ptr: vertex_data_ptr_type;
  vertex_normal_kind: vertex_normal_kind_type;
  point, face_normal: vector_type;
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
          point_data_ptr :=
            Get_point_data(face_ptr^.cycle_ptr^.directed_edge_ptr^.edge_ptr^.point_ptr1^.index);
          point := point_data_ptr^.trans_point;
          face_normal := Vector_towards(face_normal, point);

          {**************}
          { draw polygon }
          {**************}
          renderable.Begin_polygon;
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

                  {vertex_geometry_ptr := Get_vertex_geometry(vertex_ptr^.index);}
                  vertex_geometry_ptr := vertex_ptr^.vertex_geometry_ptr;
                  vertex_data_ptr := Get_vertex_data(vertex_ptr^.index);
                  point_data_ptr :=
                    Get_point_data(vertex_ptr^.point_ptr^.index);
                  vertex_normal_kind := vertex_geometry_ptr^.vertex_normal_kind;

                  with vertex_ptr^ do
                    if (point_data_ptr^.surface_visibility = silhouette_edge)
                      and (vertex_normal_kind = two_sided_vertex) then
                      begin
                        {************************************************}
                        { if face is front facing, then use front facing }
                        { color for vertex, else use back facing color   }
                        {************************************************}
                        if Same_direction(vertex_data_ptr^.trans_normal,
                          face_normal) then
                          renderable.Set_color(vertex_data_ptr^.back_color)
                        else
                          renderable.Set_color(vertex_data_ptr^.front_color);
                      end
                    else
                      begin
                        {*************************************************}
                        { not a silhouette vertex, use front facing color }
                        {*************************************************}
                        renderable.Set_color(vertex_data_ptr^.front_color);
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
end; {procedure Gouraud_shade_textured_faces}


procedure Gouraud_shade_textured_edges(renderable: polygon_renderable_type;
  edge_ptr: edge_ptr_type);
var
  vertex_data_ptr: vertex_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  while (edge_ptr <> nil) do
    begin
      renderable.Begin_line;

      {***********************}
      { send data for vertex1 }
      {***********************}
      vertex_data_ptr := Get_vertex_data(edge_ptr^.vertex_ptr1^.index);
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr1^.index);
      vertex_geometry_ptr := edge_ptr^.vertex_ptr1^.vertex_geometry_ptr;
      renderable.Set_color(vertex_data_ptr^.front_color);
      renderable.Set_texture(vertex_geometry_ptr^.texture);
      renderable.Add_vertex(point_data_ptr^.trans_point);

      {***********************}
      { send data for vertex2 }
      {***********************}
      vertex_data_ptr := Get_vertex_data(edge_ptr^.vertex_ptr2^.index);
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr2^.index);
      vertex_geometry_ptr := edge_ptr^.vertex_ptr2^.vertex_geometry_ptr;
      renderable.Set_color(vertex_data_ptr^.front_color);
      renderable.Set_texture(vertex_geometry_ptr^.texture);
      renderable.Add_vertex(point_data_ptr^.trans_point);

      renderable.Draw_line;
      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Gouraud_shade_textured_edges}


procedure Gouraud_shade_textured_vertices(renderable: line_renderable_type;
  vertex_ptr: vertex_ptr_type);
var
  vertex_data_ptr: vertex_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  renderable.Begin_points;
  while (vertex_ptr <> nil) do
    begin
      vertex_data_ptr := Get_vertex_data(vertex_ptr^.index);
      point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
      vertex_geometry_ptr := vertex_ptr^.vertex_geometry_ptr;
      renderable.Set_color(vertex_data_ptr^.front_color);
      renderable.Set_texture(vertex_geometry_ptr^.texture);
      renderable.Add_vertex(point_data_ptr^.trans_point);
      vertex_ptr := vertex_ptr^.next;
    end;
  renderable.Draw_points;
end; {procedure Gouraud_shade_textured_vertices}


procedure Gouraud_shade_textured_b_rep(renderable: polygon_renderable_type;
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
    Gouraud_shade_textured_faces(renderable, face_ptr)
  else
    begin
      {************}
      { draw edges }
      {************}
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      if (edge_ptr <> nil) then
        Gouraud_shade_textured_edges(renderable, edge_ptr)
      else
        begin
          {***************}
          { draw vertices }
          {***************}
          vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
          if (vertex_ptr <> nil) then
            Gouraud_shade_textured_vertices(renderable, vertex_ptr);
        end;
    end;
end; {procedure Gouraud_shade_textured_b_rep}


{***************************************************************}
{           Gouraud shading completely visible surfaces         }
{***************************************************************}


procedure Gouraud_shade_visible_faces(renderable: polygon_renderable_type;
  face_ptr: face_ptr_type);
var
  vertex_ptr: vertex_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  face_data_ptr: face_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
  vertex_data_ptr: vertex_data_ptr_type;
  vertex_normal_kind: vertex_normal_kind_type;
  point, face_normal: vector_type;
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
          point_data_ptr :=
            Get_point_data(face_ptr^.cycle_ptr^.directed_edge_ptr^.edge_ptr^.point_ptr1^.index);
          point := point_data_ptr^.trans_point;
          face_normal := Vector_towards(face_normal, point);

          {**************}
          { draw polygon }
          {**************}
          renderable.Begin_polygon;
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

                  {vertex_geometry_ptr := Get_vertex_geometry(vertex_ptr^.index);}
                  vertex_geometry_ptr := vertex_ptr^.vertex_geometry_ptr;
                  vertex_data_ptr := Get_vertex_data(vertex_ptr^.index);
                  point_data_ptr :=
                    Get_point_data(vertex_ptr^.point_ptr^.index);
                  vertex_normal_kind := vertex_geometry_ptr^.vertex_normal_kind;

                  with vertex_ptr^ do
                    if (point_data_ptr^.surface_visibility = silhouette_edge)
                      and (vertex_normal_kind = two_sided_vertex) then
                      begin
                        {************************************************}
                        { if face is front facing, then use front facing }
                        { color for vertex, else use back facing color   }
                        {************************************************}
                        if Same_direction(vertex_data_ptr^.trans_normal,
                          face_normal) then
                          renderable.Set_color(vertex_data_ptr^.back_color)
                        else
                          renderable.Set_color(vertex_data_ptr^.front_color);
                      end
                    else
                      begin
                        {*************************************************}
                        { not a silhouette vertex, use front facing color }
                        {*************************************************}
                        renderable.Set_color(vertex_data_ptr^.front_color);
                      end;

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
end; {procedure Gouraud_shade_visible_faces}


procedure Gouraud_shade_visible_edges(renderable: line_renderable_type;
  edge_ptr: edge_ptr_type);
var
  vertex_data_ptr: vertex_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  while (edge_ptr <> nil) do
    begin
      renderable.Begin_line;

      {***********************}
      { send data for vertex1 }
      {***********************}
      vertex_data_ptr := Get_vertex_data(edge_ptr^.vertex_ptr1^.index);
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr1^.index);
      renderable.Set_color(vertex_data_ptr^.front_color);
      renderable.Add_vertex(point_data_ptr^.vector);

      {***********************}
      { send data for vertex2 }
      {***********************}
      vertex_data_ptr := Get_vertex_data(edge_ptr^.vertex_ptr2^.index);
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr2^.index);
      renderable.Set_color(vertex_data_ptr^.front_color);
      renderable.Add_vertex(point_data_ptr^.vector);

      renderable.Draw_line;
      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Gouraud_shade_visible_edges}


procedure Gouraud_shade_visible_vertices(renderable: point_renderable_type;
  vertex_ptr: vertex_ptr_type);
var
  vertex_data_ptr: vertex_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  renderable.Begin_points;
  while (vertex_ptr <> nil) do
    begin
      vertex_data_ptr := Get_vertex_data(vertex_ptr^.index);
      point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
      renderable.Set_color(vertex_data_ptr^.front_color);
      renderable.Add_vertex(point_data_ptr^.vector);
      vertex_ptr := vertex_ptr^.next;
    end;
  renderable.Draw_points;
end; {procedure Gouraud_shade_visible_vertices}


procedure Gouraud_shade_visible_b_rep(renderable: polygon_renderable_type;
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
    Gouraud_shade_visible_faces(renderable, face_ptr)
  else
    begin
      {************}
      { draw edges }
      {************}
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      if (edge_ptr <> nil) then
        Gouraud_shade_visible_edges(renderable, edge_ptr)
      else
        begin
          {***************}
          { draw vertices }
          {***************}
          vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
          if (vertex_ptr <> nil) then
            Gouraud_shade_visible_vertices(renderable, vertex_ptr);
        end;
    end;
end; {procedure Gouraud_shade_visible_b_rep}


{***************************************************************}
{     Gouraud shading completely visible textured surfaces      }
{***************************************************************}


procedure Gouraud_shade_visible_textured_faces(renderable: polygon_renderable_type;
  face_ptr: face_ptr_type);
var
  vertex_ptr: vertex_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  face_data_ptr: face_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
  vertex_data_ptr: vertex_data_ptr_type;
  vertex_normal_kind: vertex_normal_kind_type;
  point, face_normal: vector_type;
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
          point_data_ptr :=
            Get_point_data(face_ptr^.cycle_ptr^.directed_edge_ptr^.edge_ptr^.point_ptr1^.index);
          point := point_data_ptr^.trans_point;
          face_normal := Vector_towards(face_normal, point);

          {**************}
          { draw polygon }
          {**************}
          renderable.Begin_polygon;
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

                  {vertex_geometry_ptr := Get_vertex_geometry(vertex_ptr^.index);}
                  vertex_geometry_ptr := vertex_ptr^.vertex_geometry_ptr;
                  vertex_data_ptr := Get_vertex_data(vertex_ptr^.index);
                  point_data_ptr :=
                    Get_point_data(vertex_ptr^.point_ptr^.index);
                  vertex_normal_kind := vertex_geometry_ptr^.vertex_normal_kind;

                  with vertex_ptr^ do
                    if (point_data_ptr^.surface_visibility = silhouette_edge)
                      and (vertex_normal_kind = two_sided_vertex) then
                      begin
                        {************************************************}
                        { if face is front facing, then use front facing }
                        { color for vertex, else use back facing color   }
                        {************************************************}
                        if Same_direction(vertex_data_ptr^.trans_normal,
                          face_normal) then
                          renderable.Set_color(vertex_data_ptr^.back_color)
                        else
                          renderable.Set_color(vertex_data_ptr^.front_color);
                      end
                    else
                      begin
                        {*************************************************}
                        { not a silhouette vertex, use front facing color }
                        {*************************************************}
                        renderable.Set_color(vertex_data_ptr^.front_color);
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
end; {procedure Gouraud_shade_visible_textured_faces}


procedure Gouraud_shade_visible_textured_edges(renderable: line_renderable_type;
  edge_ptr: edge_ptr_type);
var
  vertex_data_ptr: vertex_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  while (edge_ptr <> nil) do
    begin
      renderable.Begin_line;

      {***********************}
      { send data for vertex1 }
      {***********************}
      vertex_data_ptr := Get_vertex_data(edge_ptr^.vertex_ptr1^.index);
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr1^.index);
      vertex_geometry_ptr := edge_ptr^.vertex_ptr1^.vertex_geometry_ptr;
      renderable.Set_color(vertex_data_ptr^.front_color);
      renderable.Set_texture(vertex_geometry_ptr^.texture);
      renderable.Set_vertex(point_data_ptr^.vector);

      {***********************}
      { send data for vertex2 }
      {***********************}
      vertex_data_ptr := Get_vertex_data(edge_ptr^.vertex_ptr2^.index);
      point_data_ptr := Get_point_data(edge_ptr^.point_ptr2^.index);
      vertex_geometry_ptr := edge_ptr^.vertex_ptr2^.vertex_geometry_ptr;
      renderable.Set_color(vertex_data_ptr^.front_color);
      renderable.Set_texture(vertex_geometry_ptr^.texture);
      renderable.Set_vertex(point_data_ptr^.vector);

      renderable.Draw_line;
      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Gouraud_shade_visible_textured_edges}


procedure Gouraud_shade_visible_textured_vertices(renderable: point_renderable_type;
  vertex_ptr: vertex_ptr_type);
var
  vertex_data_ptr: vertex_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  renderable.Begin_points;
  while (vertex_ptr <> nil) do
    begin
      vertex_data_ptr := Get_vertex_data(vertex_ptr^.index);
      point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);
      vertex_geometry_ptr := vertex_ptr^.vertex_geometry_ptr;
      renderable.Set_color(vertex_data_ptr^.front_color);
      renderable.Set_texture(vertex_geometry_ptr^.texture);
      renderable.Set_vertex(point_data_ptr^.vector);
      vertex_ptr := vertex_ptr^.next;
    end;
  renderable.Draw_points;
end; {procedure Gouraud_shade_visible_textured_vertices}


procedure Gouraud_shade_visible_textured_b_rep(renderable: polygon_renderable_type;
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
    Gouraud_shade_visible_textured_faces(renderable, face_ptr)
  else
    begin
      {************}
      { draw edges }
      {************}
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      if (edge_ptr <> nil) then
        Gouraud_shade_visible_textured_edges(renderable, edge_ptr)
      else
        begin
          {***************}
          { draw vertices }
          {***************}
          vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
          if (vertex_ptr <> nil) then
            Gouraud_shade_visible_textured_vertices(renderable, vertex_ptr);
        end;
    end;
end; {procedure Gouraud_shade_visible_textured_b_rep}


{***************************************************************}
{                    Gouraud shading surfaces                   }
{***************************************************************}


procedure Gouraud_shade_surface(renderable: polygon_renderable_type;
  surface_ptr: surface_ptr_type;
  outline_kind: outline_kind_type;
  trans_stack_ptr: trans_stack_ptr_type;
  clipping, texturing: boolean);
var
  trans: trans_type;
  smooth_shadeable: smooth_shadeable_type;
begin
  if (surface_ptr^.shading = flat_shading) or not Supports(renderable,
    smooth_shadeable_type, smooth_shadeable) then
    Flat_shade_surface(renderable, surface_ptr, outline_kind, trans_stack_ptr,
      clipping, texturing)
  else
    begin
      Set_lighting_mode(one_sided);
      smooth_shadeable.Set_shading_mode(smooth_shading_mode);

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
      if not surface_ptr^.geometry_ptr^.geometry_info.vertex_normals_avail then
        Find_mesh_vertex_normals(surface_ptr);
      if not surface_ptr^.geometry_ptr^.geometry_info.vertex_vectors_avail then
        Find_mesh_uv_vectors(surface_ptr);

      {********************************}
      { init auxilliary rendering data }
      {********************************}
      Init_point_data(surface_ptr);
      Init_vertex_data(surface_ptr);
      Init_edge_data(surface_ptr);
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
      if (surface_ptr^.closure = open_surface) or (clipping_planes_ptr <> nil)
        then
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
      Transform_vertex_geometry(trans);
      Transform_face_geometry(trans);
      Pop_trans_stack(trans_stack_ptr);

      {************************************}
      { calculate lighting in world coords }
      {************************************}
      Shade_b_rep_vertices(surface_ptr);

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
        begin
          if texturing then
            Gouraud_shade_textured_b_rep(renderable, surface_ptr)
          else
            Gouraud_shade_b_rep(renderable, surface_ptr)
        end
      else
        begin
          if texturing then
            Gouraud_shade_visible_textured_b_rep(renderable, surface_ptr)
          else
            Gouraud_shade_visible_b_rep(renderable, surface_ptr);
        end;
    end;
end; {procedure Gouraud_shade_surface}


end.

