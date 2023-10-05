unit z_polygons;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             z_polygons                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the basic routines for scan        }
{       converting polygons.                                    }
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
procedure End_z_polygon(z_renderer: z_renderer_type);


implementation
uses
  new_memory, constants, vectors, pixels, colors, project, viewports,
  z_vertices, z_pipeline, z_clip, z_triangles, z_buffer, parity_buffer,
  scan_conversion, renderable;


var
  z_polygon_kind: z_vertex_list_kind_type;


procedure Add_z_edge(z_polygon_ptr: z_polygon_ptr_type;
  z_renderer: z_renderer_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type);
var
  z_edge_ptr: z_edge_ptr_type;
  point1, point2: vector_type;
  z_table_ptr: z_edge_table_ptr_type;
  color1, color2: color_type;
  normal1, normal2: vector_type;
  vertex1, vertex2: vector_type;
  texture1, texture2: vector_type;
  u_axis1, u_axis2: vector_type;
  v_axis1, v_axis2: vector_type;
  edge_vector: vector_type;
  edge_y_min, edge_y_max: integer;
  z_vertex_ptr: z_vertex_ptr_type;
  y_inverse, y_offset: real;
begin
  {****************************}
  { update z buffer screen box }
  {****************************}
  Update_z_screen_box(z_renderer.z_buffer_ptr^.screen_box,
    z_vertex_ptr1^.point);

  {**************************}
  { update parity screen box }
  {**************************}
  if z_renderer.parity_buffer_ptr <> nil then
    Update_z_screen_box(z_renderer.parity_buffer_ptr^.screen_box,
      z_vertex_ptr1^.point);

  {************************************************}
  { make vertex1 the one with the smallest y coord }
  {************************************************}
  if (z_vertex_ptr1^.point.y > z_vertex_ptr2^.point.y) then
    begin
      z_vertex_ptr := z_vertex_ptr1;
      z_vertex_ptr1 := z_vertex_ptr2;
      z_vertex_ptr2 := z_vertex_ptr;
    end;

  {********************}
  { find edge vertices }
  {********************}
  point1 := z_vertex_ptr1^.point;
  point2 := z_vertex_ptr2^.point;

  {********************}
  { find vertical span }
  {********************}
  edge_y_min := Trunc(point1.y);
  edge_y_max := Trunc(point2.y) - 1;

  if (edge_y_min <= edge_y_max) then
    begin
      {*******************************}
      { create new edge in edge table }
      {*******************************}
      z_edge_ptr := New_z_edge;

      {*******************}
      { initialize z edge }
      {*******************}
      z_edge_ptr^.y_max := edge_y_max;
      edge_vector := Vector_difference(point2, point1);
      y_inverse := 1 / edge_vector.y;

      {**********************************************}
      { adjust x,z intercepts to accout for snapping }
      { the y coord to an integer scanline.          }
      {**********************************************}
      y_offset := (edge_y_min - point1.y + 1);

      {*******************************************}
      { compute x and z increments and intercepts }
      {*******************************************}
      z_edge_ptr^.x_increment := edge_vector.x * y_inverse;
      z_edge_ptr^.z_increment := edge_vector.z * y_inverse;
      z_edge_ptr^.x := point1.x + (z_edge_ptr^.x_increment * y_offset);
      z_edge_ptr^.z := point1.z + (z_edge_ptr^.z_increment * y_offset);

      if z_polygon_ptr^.kind = Gouraud_z_kind then
        begin
          {******************}
          { find edge colors }
          {******************}
          color1 := z_vertex_ptr1^.color;
          color2 := z_vertex_ptr2^.color;

          {*************************************************}
          { compute color or normal increment and intercept }
          {*************************************************}
          z_edge_ptr^.color_increment := Intensify_color(Contrast_color(color2,
            color1), y_inverse);
          z_edge_ptr^.color := Mix_color(color1,
            Intensify_color(z_edge_ptr^.color_increment, y_offset));
        end

      else if z_polygon_ptr^.kind = Phong_z_kind then
        begin
          {*******************}
          { find edge normals }
          {*******************}
          normal1 := z_vertex_ptr1^.normal;
          normal2 := z_vertex_ptr2^.normal;

          {****************************************}
          { compute normal increment and intercept }
          {****************************************}
          z_edge_ptr^.normal_increment :=
            Vector_scale(Vector_difference(normal2, normal1),
            y_inverse);
          z_edge_ptr^.normal := Vector_sum(normal1,
            Vector_scale(z_edge_ptr^.normal_increment,
            y_offset));

          {****************************************************}
          { these values are interpolated in perspective space }
          { by divideding by z after the interpolation so they }
          { must be multiplied by z here to compensate.        }
          {****************************************************}
          texture1 := Vector_scale(z_vertex_ptr1^.texture, point1.z);
          texture2 := Vector_scale(z_vertex_ptr2^.texture, point2.z);
          vertex1 := Vector_scale(z_vertex_ptr1^.vertex, point1.z);
          vertex2 := Vector_scale(z_vertex_ptr2^.vertex, point2.z);

          {****************************************************}
          { these values are interpolated in screen space like }
          { the normal so no premultiplication by z is needed. }
          {****************************************************}
          u_axis1 := z_vertex_ptr1^.u_axis;
          u_axis2 := z_vertex_ptr2^.u_axis;
          v_axis1 := z_vertex_ptr1^.v_axis;
          v_axis2 := z_vertex_ptr2^.v_axis;

          {*****************************************}
          { compute texture increment and intercept }
          {*****************************************}
          z_edge_ptr^.texture_increment :=
            Vector_scale(Vector_difference(texture2, texture1),
            y_inverse);
          z_edge_ptr^.texture := Vector_sum(texture1,
            Vector_scale(z_edge_ptr^.texture_increment, y_offset));

          {***************************************************}
          { compute world coordinates increment and intercept }
          {***************************************************}
          z_edge_ptr^.vertex_increment :=
            Vector_scale(Vector_difference(vertex2, vertex1),
            y_inverse);
          z_edge_ptr^.vertex := Vector_sum(vertex1,
            Vector_scale(z_edge_ptr^.vertex_increment,
            y_offset));

          {********************************************************}
          { compute parametric coordinates increment and intercept }
          {********************************************************}
          z_edge_ptr^.u_axis_increment :=
            Vector_scale(Vector_difference(u_axis2, u_axis1),
            y_inverse);
          z_edge_ptr^.v_axis_increment :=
            Vector_scale(Vector_difference(v_axis2, v_axis1),
            y_inverse);
          z_edge_ptr^.u_axis := Vector_sum(u_axis1,
            Vector_scale(z_edge_ptr^.u_axis_increment,
            y_offset));
          z_edge_ptr^.v_axis := Vector_sum(v_axis1,
            Vector_scale(z_edge_ptr^.v_axis_increment,
            y_offset));
        end;

      {************************}
      { add edge to edge table }
      {************************}
      z_table_ptr := Index_z_edge_table(z_renderer.z_edge_table_ptr, edge_y_min);
      z_edge_ptr^.next := z_table_ptr^;
      z_table_ptr^ := z_edge_ptr;

      {********************************}
      { update polygon y_min and y_max }
      {********************************}
      if (edge_y_min < z_renderer.y_min) then
        z_renderer.y_min := edge_y_min;
      if (z_edge_ptr^.y_max > z_renderer.y_max) then
        z_renderer.y_max := z_edge_ptr^.y_max;
    end;
end; {procedure Add_z_edge}


procedure Write_z_vertex(z_vertex_ptr: z_vertex_ptr_type);
const
  write_z_color = false;
begin
  with z_vertex_ptr^ do
    begin
      writeln('z vertex = ', Trunc(point.x): 1, ', ', Trunc(point.y): 1);

      if write_z_color then
        begin
          write('z color = ');
          Write_color(color);
          writeln;
        end;
    end;
end; {procedure Write_z_vertex}


procedure Add_z_edges(z_polygon_ptr: z_polygon_ptr_type;
  z_renderer: z_renderer_type);
var
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
begin
  if (z_polygon_ptr^.first <> nil) then
    begin
      z_vertex_ptr1 := z_polygon_ptr^.first;
      z_vertex_ptr2 := z_vertex_ptr1^.next;

      while (z_vertex_ptr2 <> nil) do
        begin
          Add_z_edge(z_polygon_ptr, z_renderer, z_vertex_ptr1, z_vertex_ptr2);
          z_vertex_ptr1 := z_vertex_ptr2;
          z_vertex_ptr2 := z_vertex_ptr2^.next;
        end;

      Add_z_edge(z_polygon_ptr, z_renderer, z_vertex_ptr1,
        z_polygon_ptr^.first);
    end;
end; {procedure Add_z_edges}


procedure Prep_z_polygon(z_renderer: z_renderer_type);
begin
  {************************************}
  { connect polygon holes to perimeter }
  {************************************}
  Remove_z_holes(z_polygon_list, z_hole_list);

  {**************************}
  { clip and project polygon }
  {**************************}
  if z_clipping_enabled then
    Clip_and_project_z_polygon(z_polygon_list, current_viewport_ptr,
      current_projection_ptr);

  {**************************}
  { convexify, if neccessary }
  {**************************}
  if z_renderer.shading_mode <> flat_shading_mode then
    Convexify_z_polygons(z_polygon_list);

  {*******************************}
  { set flat shaded polygon color }
  {*******************************}
  if (z_polygon_list <> nil) then
    if (z_polygon_list^.kind = flat_z_kind) then
      z_renderer.drawable.Set_color(z_polygon_list^.color);
end; {procedure Prep_z_polygon}


procedure End_z_polygon(z_renderer: z_renderer_type);
var
  counter: integer;
  z_edge_ptr, temp: z_edge_ptr_type;
  z_polygon_ptr: z_polygon_ptr_type;
begin
  Prep_z_polygon(z_renderer);

  {*************************************************}
  { return edges from previous polygon to free list }
  {*************************************************}
  for counter := z_renderer.y_min to z_renderer.y_max do
    begin
      z_edge_ptr := Index_z_edge_table(z_renderer.z_edge_table_ptr, counter)^;
      while (z_edge_ptr <> nil) do
        begin
          {*************************}
          { add z edge to free list }
          {*************************}
          temp := z_edge_ptr;
          z_edge_ptr := z_edge_ptr^.next;
          Free_z_edge(temp);
        end;
    end;

  z_renderer.y_min := maxint;
  z_renderer.y_max := -1;

  {******************************************}
  { enter edges of new polygon to edge table }
  {******************************************}
  z_polygon_ptr := z_polygon_list;
  while z_polygon_ptr <> nil do
    begin
      Add_z_edges(z_polygon_ptr, z_renderer);
      z_polygon_ptr := z_polygon_ptr^.next;
    end;

  {***********************************************}
  { go through the edge table from y_min to y_max }
  { and sort the edges by their x component       }
  {***********************************************}
  if (z_renderer.y_min < z_renderer.y_max) then
    for counter := z_renderer.y_min to z_renderer.y_max do
      Sort_z_edges(Index_z_edge_table(z_renderer.z_edge_table_ptr, counter)^);

  {*****************************************}
  { return vertices of polygon to free list }
  {*****************************************}
  z_polygon_kind := z_polygon_list^.kind;
  Free_z_vertex_lists(z_polygon_list);
end; {procedure End_z_polygon}


end.

