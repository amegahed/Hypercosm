unit z_pipeline;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             z_pipeline                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines for feeding polygonal     }
{       vertex data into the 3d 'pipeline'.                     }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, colors, z_vertices;


var
  {*********************}
  { z buffer primitives }
  {*********************}
  z_polygon_list: z_polygon_ptr_type;
  z_line_list: z_line_ptr_type;
  z_point_list: z_point_ptr_type;
  z_hole_list: z_hole_ptr_type;


{********************************************}
{ these functions set the vertex destination }
{********************************************}
procedure Begin_z_polygon;
procedure Begin_z_points;
procedure Begin_z_line;
procedure Begin_z_hole;

{**************************************************************}
{ these function set vertex properties before a vertex is sent }
{**************************************************************}
procedure Set_z_color(color: color_type);
procedure Set_z_texture(texture: vector_type);
procedure Set_z_normal(normal: vector_type);
procedure Set_z_vertex(vertex: vector_type);
procedure Set_z_vectors(u_axis, v_axis: vector_type);

{************************************************}
{ these functions store vertices in the pipeline }
{************************************************}
procedure Add_z_vertex(point: vector_type);


implementation


var
  {****************}
  { current vertex }
  {****************}
  vertex_point: vector_type;
  vertex_normal: vector_type;
  vertex_texture: vector_type;
  vertex_u_axis: vector_type;
  vertex_v_axis: vector_type;
  vertex_color: color_type;

  {***************************************************}
  { the vertex pipeline can empty out into either of  }
  { the polygon, line, point, or hole vertex lists.   }
  {***************************************************}
  z_pipeline_ptr: z_vertex_list_ptr_type;


{**********************************}
{ routines to construct z polygons }
{**********************************}


procedure Begin_z_polygon;
begin
  z_polygon_list := New_z_vertex_list(flat_z_kind, vertex_color, false);
  z_pipeline_ptr := z_polygon_list;
end; {procedure Begin_z_polygon}


procedure Begin_z_points;
begin
  z_point_list := New_z_vertex_list(flat_z_kind, vertex_color, false);
  z_pipeline_ptr := z_point_list;
end; {procedure Begin_z_points}


procedure Begin_z_line;
begin
  z_line_list := New_z_vertex_list(flat_z_kind, vertex_color, false);
  z_pipeline_ptr := z_line_list;
end; {procedure Begin_z_line}


procedure Begin_z_hole;
var
  z_hole_ptr: z_vertex_list_ptr_type;
begin
  z_hole_ptr := New_z_vertex_list(flat_z_kind, vertex_color, false);
  z_hole_ptr^.next := z_hole_list;
  z_hole_list := z_hole_ptr;
  z_pipeline_ptr := z_hole_list;
end; {procedure Begin_z_hole}


{**************************************************************}
{ these function set vertex properties before a vertex is sent }
{**************************************************************}


procedure Set_z_color(color: color_type);
begin
  if (z_pipeline_ptr <> nil) then
    z_pipeline_ptr^.kind := Gouraud_z_kind;
  vertex_color := Clip_color(color);
end; {procedure Set_z_color}


procedure Set_z_texture(texture: vector_type);
begin
  if (z_pipeline_ptr <> nil) then
    z_pipeline_ptr^.textured := true;
  vertex_texture := texture;
end; {procedure Set_z_texture}


procedure Set_z_normal(normal: vector_type);
begin
  if (z_pipeline_ptr <> nil) then
    z_pipeline_ptr^.kind := Phong_z_kind;
  vertex_normal := normal;
end; {procedure Set_z_normal}


procedure Set_z_vertex(vertex: vector_type);
begin
  vertex_point := vertex;
end; {procedure Set_z_vertex}


procedure Set_z_vectors(u_axis, v_axis: vector_type);
begin
  vertex_u_axis := u_axis;
  vertex_v_axis := v_axis;
end; {procedure Set_z_vectors}


{********************************}
{ routines for creating vertices }
{********************************}


procedure Add_z_vertex(point: vector_type);
var
  z_vertex_ptr: z_vertex_ptr_type;
begin
  {*******************}
  { initialize vertex }
  {*******************}
  z_vertex_ptr := New_z_vertex;
  z_vertex_ptr^.point := point;
  z_vertex_ptr^.normal := vertex_normal;
  z_vertex_ptr^.vertex := vertex_point;
  z_vertex_ptr^.texture := vertex_texture;
  z_vertex_ptr^.u_axis := vertex_u_axis;
  z_vertex_ptr^.v_axis := vertex_v_axis;
  z_vertex_ptr^.color := vertex_color;
  z_vertex_ptr^.next := nil;

  with z_pipeline_ptr^ do
    begin
      vertices := vertices + 1;
      if (first = nil) then
        begin
          first := z_vertex_ptr;
          last := z_vertex_ptr;
        end
      else
        begin
          last^.next := z_vertex_ptr;
          last := z_vertex_ptr;
        end;
    end
end; {procedure Add_z_vertex}


initialization
  {*******************************************}
  { initialize stuff for polygon construction }
  {*******************************************}
  z_polygon_list := nil;
  z_line_list := nil;
  z_point_list := nil;
  z_hole_list := nil;
  z_pipeline_ptr := nil;

  vertex_point := zero_vector;
  vertex_normal := zero_vector;
  vertex_texture := zero_vector;
  vertex_u_axis := x_vector;
  vertex_v_axis := y_vector;
  vertex_color := black_color;
end.
