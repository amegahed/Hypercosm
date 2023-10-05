unit shade_b_rep;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            shade_b_rep                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is used to shade the surfaces of an         }
{       object using the b rep data structs.                    }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  colors, vectors, trans, coord_axes, coord_stack, topology, b_rep, object_attr,
  raytrace;


var
  eye_to_world, world_to_eye: trans_type;
  coord_stack_ptr: coord_stack_ptr_type;
  normal_stack_ptr: coord_stack_ptr_type;
  shader_axes, normal_shader_axes: coord_axes_type;
  hierarchical_obj: hierarchical_object_type;
  attributes: object_attributes_type;
  shader_stack_height: integer;


procedure Shade_b_rep_faces(surface_ptr: surface_ptr_type);
procedure Shade_b_rep_edges(surface_ptr: surface_ptr_type);
procedure Shade_b_rep_vertices(surface_ptr: surface_ptr_type);
procedure Shade_b_rep_vertex(vertex_ptr: vertex_ptr_type);

function Shade_point(point, normal: vector_type;
  direction, texture: vector_type;
  u_axis, v_axis: vector_type;
  distance: real): color_type;
function Shade_edge_point(point, normal: vector_type;
  direction, texture: vector_type;
  u_axis, v_axis: vector_type;
  distance: real): color_type;


implementation
uses
  constants, eye, geometry, xform_b_rep, coords, luxels, eval_shaders;


function Front_facing_normal(normal, direction: vector_type): boolean;
begin
  Front_facing_normal := Dot_product(normal, direction) < tiny;
end; {Front_facing_normal}


function Forward_facing_normal(normal, direction: vector_type): vector_type;
var
  parallel_component: vector_type;
  factor: real;
begin
  factor := Dot_product(normal, direction);
  if factor > 0 then
    begin
      {****************************************************}
      { The normal and vector from origin to point are in  }
      { the same direction, therefore, normal points away. }
      { To remidy the sitution, subtract the portion of    }
      { the normal parallel to the direction to the point. }
      {****************************************************}
      parallel_component := Vector_scale(normal, factor / Dot_product(direction,
        direction));
      normal := Vector_difference(normal, parallel_component);
    end;

  Forward_facing_normal := normal;
end; {function Forward_facing_normal}


procedure Find_oriented_normals(normal, direction: vector_type;
  var front_normal, back_normal: vector_type);
var
  parallel_component: vector_type;
  factor: real;
begin
  factor := Dot_product(normal, direction);
  parallel_component := Vector_scale(direction, factor);

  if factor > 0 then
    begin
      {****************************************************}
      { The normal and vector from origin to point are in  }
      { the same direction, therefore, normal points away. }
      { To remidy the sitution, subtract the portion of    }
      { the normal parallel to the direction to the point. }
      {****************************************************}
      back_normal := Vector_reverse(normal);
      front_normal := Vector_difference(normal, parallel_component);
    end
  else
    begin
      front_normal := normal;
      back_normal := Vector_reverse(Vector_difference(normal,
        parallel_component));
    end;
end; {function Find_oriented_normals}


procedure Shade_b_rep_face(face_ptr: face_ptr_type;
  face_data_ptr: face_data_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
  vertex_ptr: vertex_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
  point, normal: vector_type;
  direction, texture: vector_type;
  distance: real;
  u_axis, v_axis: vector_type;
begin
  vertex_ptr := face_ptr^.cycle_ptr^.directed_edge_ptr^.edge_ptr^.vertex_ptr1;
  point_data_ptr := Get_point_data(vertex_ptr^.point_ptr^.index);

  {vertex_geometry_ptr := Get_vertex_geometry(vertex_ptr^.index);}
  vertex_geometry_ptr := vertex_ptr^.vertex_geometry_ptr;

  point := point_data_ptr^.trans_point;
  normal := face_data_ptr^.trans_normal;
  u_axis := vertex_geometry_ptr^.u_axis;
  v_axis := vertex_geometry_ptr^.v_axis;

  {********************************}
  { set source of ray so mesh does }
  { not shadow or reflect itself.  }
  {********************************}
  hierarchical_obj.mesh_face_ptr := face_ptr;
  hierarchical_obj.mesh_point_ptr := vertex_ptr^.point_ptr;

  {*******************}
  { calculate shading }
  {*******************}
  Inval_coords;
  Set_coord_stack_data(coord_stack_ptr, normal_stack_ptr, shader_stack_height);
  Set_shader_to_object(shader_axes, normal_shader_axes);
  Set_surface_to_prim(u_axis, v_axis);
  Set_ray_object(hierarchical_obj.object_ptr);

  {*********************************}
  { compute data required by shader }
  {*********************************}
  direction := Vector_difference(point, eye_point);
  distance := Vector_length(direction);
  direction := Vector_scale(direction, 1 / distance);
  texture := vertex_geometry_ptr^.texture;

  {*****************************}
  { set data required by shader }
  {*****************************}
  Set_location(point, world_coords);
  Set_normal(normal, world_coords);
  Set_direction(direction, world_coords);
  Set_location(texture, parametric_coords);
  Set_distance(distance);

  {*****************}
  { evaluate shader }
  {*****************}
  Set_lighting_point(point);
  face_data_ptr^.color := Eval_surface_color(attributes, hierarchical_obj);
end; {procedure Shade_b_rep_face}


procedure Shade_b_rep_faces(surface_ptr: surface_ptr_type);
var
  face_ptr: face_ptr_type;
  face_data_ptr: face_data_ptr_type;
begin
  face_ptr := surface_ptr^.topology_ptr^.face_ptr;
  while (face_ptr <> nil) do
    begin
      {**********************************}
      { shade only front facing polygons }
      {**********************************}
      face_data_ptr := Get_face_data(face_ptr^.index);
      if (face_data_ptr^.front_facing) then
        Shade_b_rep_face(face_ptr, face_data_ptr);

      face_ptr := face_ptr^.next;
    end;
end; {procedure Shade_b_rep_faces}


procedure Shade_b_rep_edges(surface_ptr: surface_ptr_type);
var
  vertex_ptr: vertex_ptr_type;
begin
  if attributes.valid[edge_shader_attributes] then
    begin
      vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
      while (vertex_ptr <> nil) do
        begin
          Shade_b_rep_vertex(vertex_ptr);
          vertex_ptr := vertex_ptr^.next;
        end;
    end;
end; {procedure Shade_b_rep_edges}


procedure Shade_b_rep_face_vertex(vertex_ptr: vertex_ptr_type;
  point_data_ptr: point_data_ptr_type;
  face_data_ptr: face_data_ptr_type);
var
  vertex_geometry_ptr: vertex_geometry_ptr_type;
  vertex_data_ptr: vertex_data_ptr_type;
  point, normal, face_normal: vector_type;
  direction, texture: vector_type;
  distance, distance_squared: real;
  u_axis, v_axis: vector_type;
  vertex_normal_kind: vertex_normal_kind_type;
  front_normal, back_normal: vector_type;
begin
  {vertex_geometry_ptr := Get_vertex_geometry(vertex_ptr^.index);}
  vertex_geometry_ptr := vertex_ptr^.vertex_geometry_ptr;

  vertex_data_ptr := Get_vertex_data(vertex_ptr^.index);
  point := point_data_ptr^.trans_point;
  normal := vertex_data_ptr^.trans_normal;
  u_axis := vertex_geometry_ptr^.u_axis;
  v_axis := vertex_geometry_ptr^.v_axis;
  vertex_normal_kind := vertex_geometry_ptr^.vertex_normal_kind;

  {********************************}
  { set source of ray so mesh does }
  { not shadow or reflect itself.  }
  {********************************}
  hierarchical_obj.mesh_face_ptr := nil;
  hierarchical_obj.mesh_point_ptr := vertex_ptr^.point_ptr;

  {*********************************}
  { compute data required by shader }
  {*********************************}
  direction := Vector_difference(point, eye_point);
  distance_squared := Dot_product(direction, direction);
  distance := sqrt(distance_squared);
  direction := Vector_scale(direction, 1 / distance);
  texture := vertex_ptr^.vertex_geometry_ptr^.texture;

  {*****************}
  { evaluate shader }
  {*****************}
  if (point_data_ptr^.surface_visibility = silhouette_edge) and
    (vertex_normal_kind = two_sided_vertex) then
    begin
      Set_lighting_mode(one_sided);

      {************************************}
      { find front and back facing normals }
      {************************************}
      front_normal := normal;
      back_normal := Vector_reverse(normal);

      {**********************************}
      { calculate shading for front side }
      {**********************************}
      Inval_coords;
      Set_coord_stack_data(coord_stack_ptr, normal_stack_ptr,
        shader_stack_height);
      Set_shader_to_object(shader_axes, normal_shader_axes);
      Set_surface_to_prim(u_axis, v_axis);
      Set_ray_object(hierarchical_obj.object_ptr);

      {*****************************}
      { set data required by shader }
      {*****************************}
      Set_location(point, world_coords);
      Set_normal(front_normal, world_coords);
      Set_direction(direction, world_coords);
      Set_location(texture, parametric_coords);
      Set_distance(distance);

      {********************************}
      { evaluate shader for front side }
      {********************************}
      Set_lighting_point(point);
      vertex_data_ptr^.front_color := Eval_surface_color(attributes,
        hierarchical_obj);

      {*********************************}
      { calculate shading for back side }
      {*********************************}
      Inval_coords;
      Set_coord_stack_data(coord_stack_ptr, normal_stack_ptr,
        shader_stack_height);
      Set_shader_to_object(shader_axes, normal_shader_axes);
      Set_surface_to_prim(u_axis, v_axis);
      Set_ray_object(hierarchical_obj.object_ptr);

      {*****************************}
      { set data required by shader }
      {*****************************}
      Set_location(point, world_coords);
      Set_normal(back_normal, world_coords);
      Set_direction(direction, world_coords);
      Set_location(texture, parametric_coords);
      Set_distance(distance);

      {*******************************}
      { evaluate shader for back side }
      {*******************************}
      vertex_data_ptr^.back_color := Eval_surface_color(attributes,
        hierarchical_obj);
    end
  else
    begin
      {****************************}
      { orient normal towards face }
      {****************************}
      face_normal := face_data_ptr^.trans_normal;
      if not Front_facing_normal(face_normal, direction) then
        face_normal := Vector_reverse(face_normal);
      normal := Vector_towards(normal, face_normal);

      Set_lighting_mode(one_sided);

      {**********************************}
      { calculate shading for front side }
      {**********************************}
      Inval_coords;
      Set_coord_stack_data(coord_stack_ptr, normal_stack_ptr,
        shader_stack_height);
      Set_shader_to_object(shader_axes, normal_shader_axes);
      Set_surface_to_prim(u_axis, v_axis);
      Set_ray_object(hierarchical_obj.object_ptr);

      {*****************************}
      { set data required by shader }
      {*****************************}
      Set_location(point, world_coords);
      Set_normal(normal, world_coords);
      Set_direction(direction, world_coords);
      Set_location(texture, parametric_coords);
      Set_distance(distance);

      {********************************}
      { evaluate shader for front side }
      {********************************}
      Set_lighting_point(point);
      vertex_data_ptr^.front_color := Eval_surface_color(attributes,
        hierarchical_obj);
    end;
end; {procedure Shade_b_rep_face_vertex}


procedure Shade_b_rep_vertices(surface_ptr: surface_ptr_type);
var
  vertex_ptr: vertex_ptr_type;
  face_ptr: face_ptr_type;
  face_data_ptr: face_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
  shade_vertex: boolean;
begin
  vertex_ptr := surface_ptr^.topology_ptr^.vertex_ptr;
  while (vertex_ptr <> nil) do
    begin
      with vertex_ptr^ do
        begin
          point_data_ptr := Get_point_data(point_ptr^.index);
          if vertex_ptr^.face_list <> nil then
            begin
              face_ptr := vertex_ptr^.face_list^.face_ptr;
              face_data_ptr := Get_face_data(face_ptr^.index);

              if surface_ptr^.closure = open_surface then
                shade_vertex := true
              else
                begin
                  if point_ptr^.real_point or (point_data_ptr^.surface_visibility
                    = silhouette_edge) then
                    shade_vertex := true
                  else
                    shade_vertex := face_data_ptr^.front_facing;
                end;

              if shade_vertex then
                Shade_b_rep_face_vertex(vertex_ptr, point_data_ptr,
                  face_data_ptr);
            end;
        end;

      vertex_ptr := vertex_ptr^.next;
    end;
end; {procedure Shade_b_rep_vertices}


procedure Shade_b_rep_vertex(vertex_ptr: vertex_ptr_type);
var
  point_data_ptr: point_data_ptr_type;
  vertex_data_ptr: vertex_data_ptr_type;
  location, normal, direction: vector_type;
  texture, u_axis, v_axis: vector_type;
  distance: real;
begin
  {***********************}
  { retrieve shading data }
  {***********************}
  with vertex_ptr^ do
    begin
      point_data_ptr := Get_point_data(point_ptr^.index);
      vertex_data_ptr := Get_vertex_data(vertex_ptr^.index);
      location := point_data_ptr^.trans_point;
      normal := vertex_data_ptr^.trans_normal;
      texture := vertex_geometry_ptr^.texture;
      u_axis := vertex_geometry_ptr^.u_axis;
      v_axis := vertex_geometry_ptr^.v_axis;
    end;

  {**********************}
  { compute shading data }
  {**********************}
  direction := Vector_difference(location, eye_point);
  distance := Vector_length(direction);
  direction := Vector_scale(direction, 1 / distance);

  {*****************}
  { evaluate shader }
  {*****************}
  point_data_ptr^.color := Shade_edge_point(location, normal, direction,
    texture, u_axis, v_axis, distance);
end; {procedure Shade_b_rep_vertex}


function Shade_point(point, normal: vector_type;
  direction, texture: vector_type;
  u_axis, v_axis: vector_type;
  distance: real): color_type;
begin
  Inval_coords;
  Set_coord_stack_data(coord_stack_ptr, normal_stack_ptr, shader_stack_height);
  Set_shader_to_object(shader_axes, normal_shader_axes);
  Set_surface_to_shader(u_axis, v_axis);
  Set_ray_object(hierarchical_obj.object_ptr);

  {*****************************}
  { set data required by shader }
  {*****************************}
  Set_location(point, world_coords);
  Set_normal(normal, world_coords);
  Set_direction(direction, world_coords);
  Set_location(texture, parametric_coords);
  Set_distance(distance);

  {*****************}
  { evaluate shader }
  {*****************}
  Set_lighting_point(point);
  Shade_point := Eval_surface_color(attributes, hierarchical_obj);
end; {function Shade_point}


function Shade_edge_point(point, normal: vector_type;
  direction, texture: vector_type;
  u_axis, v_axis: vector_type;
  distance: real): color_type;
begin
  Inval_coords;
  Set_coord_stack_data(coord_stack_ptr, normal_stack_ptr, shader_stack_height);
  Set_shader_to_object(shader_axes, normal_shader_axes);
  Set_surface_to_shader(u_axis, v_axis);
  Set_ray_object(hierarchical_obj.object_ptr);

  {*****************************}
  { set data required by shader }
  {*****************************}
  Set_location(point, world_coords);
  Set_normal(normal, world_coords);
  Set_direction(direction, world_coords);
  Set_location(texture, parametric_coords);
  Set_distance(distance);

  {*****************}
  { evaluate shader }
  {*****************}
  Set_lighting_point(point);
  Shade_edge_point := Eval_surface_color(attributes, hierarchical_obj);
end; {function Shade_edge_point}


end.
