unit collision;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             collision                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains various routines used in           }
{       collision detection and other environment sensing       }
{       functions.                                              }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, rays, trans, viewing, raytrace;


function Object_hits_object(view_object_ptr1: view_object_inst_ptr_type;
  view_object_ptr2: view_object_inst_ptr_type;
  var point, normal: vector_type): boolean;
procedure Find_ray_object_intersection(var ray: ray_type;
  obj: hierarchical_object_type;
  t: real);
function Closest_to_point_on_object(view_object_inst_ptr:
  view_object_inst_ptr_type;
  point: vector_type): vector_type;
function Closest_to_plane_on_object(view_object_inst_ptr:
  view_object_inst_ptr_type;
  point, normal: vector_type): vector_type;


implementation
uses
  constants, trans_stack, coord_axes, coord_stack, coords, geometry, topology,
  b_rep, xform_b_rep, normals, intersect, walk_voxels;


var
  trans_stack_ptr: trans_stack_ptr_type;

  {****************}
  { proximity data }
  {****************}
  closest_point: vector_type;
  closest_distance: real;

  {**************************}
  { collision detection data }
  {**************************}
  collision_found: boolean;
  collision_point: vector_type;
  collision_normal: vector_type;


  {**************************************************}
  { routine to find point and normal of intersection }
  {**************************************************}


procedure Find_ray_object_intersection(var ray: ray_type;
  obj: hierarchical_object_type;
  t: real);
var
  coord_stack_ptr, normal_stack_ptr: coord_stack_ptr_type;
  global_point, local_point, normal: vector_type;
  object_ptr: ray_object_inst_ptr_type;
  shader_height: integer;
begin
  {***************************************}
  { calculate point and normal of surface }
  {***************************************}
  global_point := Vector_sum(ray.location, Vector_scale(ray.direction, t));
  local_point := Vector_sum(closest_local_ray.location,
    Vector_scale(closest_local_ray.direction, t));
  normal := Find_surface_normal(obj.object_ptr, local_point);

  {**************************}
  { calculate transformation }
  {**************************}
  shader_height := 1;
  Convert_hierarchical_object(obj, object_ptr);
  Create_coord_stack(obj, coord_stack_ptr, normal_stack_ptr, shader_height,
    unit_axes, unit_axes);
  Set_coord_stack_data(coord_stack_ptr, normal_stack_ptr, shader_height);
  Set_ray_object(object_ptr);

  {***************************************}
  { compute intersection in global coords }
  {***************************************}
  Inval_coords;
  Set_normal(normal, primitive_coords);

  ray.location := global_point;
  ray.direction := Vector_away(Get_normal(world_coords), ray.direction);
end; {procedure Find_ray_object_intersection}


{********************************}
{ collision detection primitives }
{********************************}


procedure Find_edge_collision(edge_ptr: edge_ptr_type;
  obj: hierarchical_object_type);
var
  point_data_ptr1, point_data_ptr2: point_data_ptr_type;
  point1, point2: vector_type;
  ray: ray_type;
  t: real;
begin
  point_data_ptr1 := Get_point_data(edge_ptr^.point_ptr1^.index);
  point_data_ptr2 := Get_point_data(edge_ptr^.point_ptr2^.index);
  point1 := point_data_ptr1^.trans_point;
  point2 := point_data_ptr2^.trans_point;
  ray.location := point1;
  ray.direction := Vector_difference(point2, point1);

  closest_t := infinity;
  t := Object_intersection(ray, tiny, infinity, obj);

  if (t > 0) and (t < 1) then
    begin
      collision_found := true;
      Find_ray_object_intersection(ray, obj, t);
      collision_point := ray.location;
      collision_normal := ray.direction;
    end;
end; {procedure Find_edge_collision}


procedure Find_surface_collision(surface_ptr: surface_ptr_type;
  trans: trans_type;
  ray_object_ptr: ray_object_inst_ptr_type);
var
  edge_ptr: edge_ptr_type;
  obj: hierarchical_object_type;
begin
  {***************************}
  { bind geometry to topology }
  {***************************}
  Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);

  {********************************}
  { init auxilliary rendering data }
  {********************************}
  Init_point_data(surface_ptr);

  {************************}
  { transform local coords }
  {************************}
  Transform_point_geometry(trans);

  obj.object_ptr := ray_object_ptr;
  obj.transform_stack.depth := 0;

  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  while (edge_ptr <> nil) and not collision_found do
    begin
      Find_edge_collision(edge_ptr, obj);
      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Find_surface_collision}


procedure Find_collision(object_ptr: view_object_inst_ptr_type;
  ray_object_ptr: ray_object_inst_ptr_type);
var
  trans: trans_type;
  sub_object_ptr: view_object_inst_ptr_type;
  surface_ptr: surface_ptr_type;
begin
  {******************}
  { transform object }
  {******************}
  Push_trans_stack(trans_stack_ptr);
  Transform_trans_stack(trans_stack_ptr, object_ptr^.trans);
  Get_trans_stack(trans_stack_ptr, trans);

  case object_ptr^.kind of
    {******************}
    { primitive object }
    {******************}
    view_object_prim:
      begin
        surface_ptr := object_ptr^.surface_ptr;
        while (surface_ptr <> nil) do
          begin
            Find_surface_collision(surface_ptr, trans, ray_object_ptr);
            surface_ptr := surface_ptr^.next;
          end;
      end;

    {****************}
    { complex object }
    {****************}
    view_object_decl:
      begin
        {******************}
        { draw sub objects }
        {******************}
        sub_object_ptr := object_ptr^.object_decl_ptr^.sub_object_ptr;
        while (sub_object_ptr <> nil) and not collision_found do
          begin
            Find_collision(sub_object_ptr, ray_object_ptr);
            sub_object_ptr := sub_object_ptr^.next;
          end; {while}
      end;
  end; {case}

  Pop_trans_stack(trans_stack_ptr);
end; {procedure Find_collision}


procedure Find_object_collision(view_object_ptr: view_object_inst_ptr_type;
  ray_object_ptr: ray_object_inst_ptr_type);
begin
  {************************}
  { initialize trans stack }
  {************************}
  trans_stack_ptr := New_trans_stack;
  Set_trans_mode(postmultiply_trans);
  Push_trans_stack(trans_stack_ptr);
  Set_trans_stack(trans_stack_ptr, unit_trans);

  collision_found := false;
  collision_point := zero_vector;
  collision_normal := zero_vector;
  Find_collision(view_object_ptr, ray_object_ptr);

  {******************}
  { free trans stack }
  {******************}
  Pop_trans_stack(trans_stack_ptr);
  Set_trans_mode(premultiply_trans);
  Free_trans_stack(trans_stack_ptr);
end; {procedure Find_object_collision}


function Object_hits_object(view_object_ptr1: view_object_inst_ptr_type;
  view_object_ptr2: view_object_inst_ptr_type;
  var point, normal: vector_type): boolean;
begin
  {***************************************************}
  { check edges of object1 against surface of object2 }
  {***************************************************}
  Find_object_collision(view_object_ptr1, view_object_ptr2^.ray_object_ptr);

  {***************************************************}
  { check edges of object2 against surface of object1 }
  {***************************************************}
  if not collision_found then
    Find_object_collision(view_object_ptr2, view_object_ptr1^.ray_object_ptr);

  if collision_found then
    begin
      point := collision_point;
      normal := collision_normal;
    end;

  Object_hits_object := collision_found;
end; {function Object_hits_object}


{*****************************************************}
{ routines to find closest point on object to a point }
{*****************************************************}


procedure Find_closest_surface_point_to_point(surface_ptr: surface_ptr_type;
  trans: trans_type;
  point: vector_type);
var
  vector: vector_type;
  distance: real;
  point_ptr: point_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  {***************************}
  { bind geometry to topology }
  {***************************}
  Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);

  {********************************}
  { init auxilliary rendering data }
  {********************************}
  Init_point_data(surface_ptr);

  {************************}
  { transform local coords }
  {************************}
  Transform_point_geometry(trans);

  point_ptr := surface_ptr^.topology_ptr^.point_ptr;
  while (point_ptr <> nil) do
    begin
      point_data_ptr := Get_point_data(point_ptr^.index);
      vector := Vector_difference(point_data_ptr^.trans_point, point);
      distance := Dot_product(vector, vector);
      if (distance < closest_distance) then
        begin
          closest_point := point_data_ptr^.trans_point;
          closest_distance := distance;
        end;
      point_ptr := point_ptr^.next;
    end;
end; {procedure Find_closest_surface_point_to_point}


procedure Find_closest_point_to_point(object_ptr: view_object_inst_ptr_type;
  point: vector_type);
var
  trans: trans_type;
  sub_object_ptr: view_object_inst_ptr_type;
  surface_ptr: surface_ptr_type;
begin
  {******************}
  { transform object }
  {******************}
  Push_trans_stack(trans_stack_ptr);
  Transform_trans_stack(trans_stack_ptr, object_ptr^.trans);
  Get_trans_stack(trans_stack_ptr, trans);

  case object_ptr^.kind of
    {******************}
    { primitive object }
    {******************}
    view_object_prim:
      begin
        surface_ptr := object_ptr^.surface_ptr;
        while (surface_ptr <> nil) do
          begin
            Find_closest_surface_point_to_point(surface_ptr, trans, point);
            surface_ptr := surface_ptr^.next;
          end;
      end;

    {****************}
    { complex object }
    {****************}
    view_object_decl:
      begin
        {******************}
        { draw sub objects }
        {******************}
        sub_object_ptr := object_ptr^.object_decl_ptr^.sub_object_ptr;
        while sub_object_ptr <> nil do
          begin
            Find_closest_point_to_point(sub_object_ptr, point);
            sub_object_ptr := sub_object_ptr^.next;
          end; {while}
      end;
  end; {case}

  Pop_trans_stack(trans_stack_ptr);
end; {procedure Find_closest_point_to_point}


function Closest_to_point_on_object(view_object_inst_ptr:
  view_object_inst_ptr_type;
  point: vector_type): vector_type;
begin
  {************************}
  { initialize trans stack }
  {************************}
  trans_stack_ptr := New_trans_stack;
  Set_trans_mode(postmultiply_trans);
  Push_trans_stack(trans_stack_ptr);
  Set_trans_stack(trans_stack_ptr, unit_trans);

  closest_point := zero_vector;
  closest_distance := infinity;
  Find_closest_point_to_point(view_object_inst_ptr, point);

  {******************}
  { free trans stack }
  {******************}
  Pop_trans_stack(trans_stack_ptr);
  Set_trans_mode(premultiply_trans);
  Free_trans_stack(trans_stack_ptr);

  Closest_to_point_on_object := closest_point;
end; {function Closest_to_point_on_object}


{*****************************************************}
{ routines to find closest point on object to a plane }
{*****************************************************}


procedure Find_closest_surface_point_to_plane(surface_ptr: surface_ptr_type;
  trans: trans_type;
  point, normal: vector_type);
var
  vector: vector_type;
  distance: real;
  point_ptr: point_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  {***************************}
  { bind geometry to topology }
  {***************************}
  Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);

  {********************************}
  { init auxilliary rendering data }
  {********************************}
  Init_point_data(surface_ptr);

  {************************}
  { transform local coords }
  {************************}
  Transform_point_geometry(trans);

  point_ptr := surface_ptr^.topology_ptr^.point_ptr;
  while (point_ptr <> nil) do
    begin
      point_data_ptr := Get_point_data(point_ptr^.index);
      vector := Vector_difference(point_data_ptr^.trans_point, point);
      distance := abs(Dot_product(vector, normal));
      if (distance < closest_distance) then
        begin
          closest_point := point_data_ptr^.trans_point;
          closest_distance := distance;
        end;
      point_ptr := point_ptr^.next;
    end;
end; {procedure Find_closest_surface_point_to_plane}


procedure Find_closest_point_to_plane(object_ptr: view_object_inst_ptr_type;
  point, normal: vector_type);
var
  trans: trans_type;
  sub_object_ptr: view_object_inst_ptr_type;
  surface_ptr: surface_ptr_type;
begin
  {******************}
  { transform object }
  {******************}
  Push_trans_stack(trans_stack_ptr);
  Transform_trans_stack(trans_stack_ptr, object_ptr^.trans);
  Get_trans_stack(trans_stack_ptr, trans);

  case object_ptr^.kind of
    {******************}
    { primitive object }
    {******************}
    view_object_prim:
      begin
        surface_ptr := object_ptr^.surface_ptr;
        while (surface_ptr <> nil) do
          begin
            Find_closest_surface_point_to_plane(surface_ptr, trans, point,
              normal);
            surface_ptr := surface_ptr^.next;
          end;
      end;

    {****************}
    { complex object }
    {****************}
    view_object_decl:
      begin
        {******************}
        { draw sub objects }
        {******************}
        sub_object_ptr := object_ptr^.object_decl_ptr^.sub_object_ptr;
        while sub_object_ptr <> nil do
          begin
            Find_closest_point_to_plane(sub_object_ptr, point, normal);
            sub_object_ptr := sub_object_ptr^.next;
          end; {while}
      end;
  end; {case}

  Pop_trans_stack(trans_stack_ptr);
end; {procedure Find_closest_point_to_plane}


function Closest_to_plane_on_object(view_object_inst_ptr:
  view_object_inst_ptr_type;
  point, normal: vector_type): vector_type;
begin
  {************************}
  { initialize trans stack }
  {************************}
  trans_stack_ptr := New_trans_stack;
  Set_trans_mode(postmultiply_trans);
  Push_trans_stack(trans_stack_ptr);
  Set_trans_stack(trans_stack_ptr, unit_trans);

  closest_point := zero_vector;
  closest_distance := infinity;
  Find_closest_point_to_plane(view_object_inst_ptr, point, normal);

  {******************}
  { free trans stack }
  {******************}
  Pop_trans_stack(trans_stack_ptr);
  Set_trans_mode(premultiply_trans);
  Free_trans_stack(trans_stack_ptr);

  Closest_to_plane_on_object := closest_point;
end; {function Closest_to_plane_on_object}


end.
