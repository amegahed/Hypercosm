unit exec_native_collision;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm        exec_native_collision          3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines for evaluating            }
{       native functions.                                       }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  native_collision;


{*******************************************************************}
{ routine to switch between and evaluate native collision functions }
{*******************************************************************}
procedure Exec_native_collision_method(kind: native_collision_method_kind_type);


implementation
uses
  constants, vectors, vectors2, rays, trans, coord_axes, eye, project,
  addr_types, code_types, exprs, stmts, code_decls, trans_stack, state_vars,
  grid_prims, objects, raytrace, viewing, precalc, preview, anim, coords,
  make_voxels, collision, walk_voxels, params, get_params, set_stack_data,
  op_stacks, assign_native_model, assign_native_render, exec_objects,
  exec_graphics, exec_stmts;


var
  object_stmt_ptr: stmt_ptr_type;
  picture_stmt_ptr: stmt_ptr_type;


{********************************}
{ collision detection primitives }
{********************************}


function Begin_local_object_group: object_decl_ptr_type;
var
  object_decl_ptr: object_decl_ptr_type;
begin
  Begin_object_group(0);
  Name_object_group('<implicit>');
  Push_object_stack(nil);

  {************************}
  { initialize model trans }
  {************************}
  Get_trans_data;
  Push_trans_stack(model_trans_stack_ptr);
  Set_trans_stack(model_trans_stack_ptr, unit_trans);
  Put_trans_data;

  {*************************}
  { initialize shader trans }
  {*************************}
  Push_trans_stack(shader_trans_stack_ptr);
  Set_trans_stack(shader_trans_stack_ptr, unit_trans);
  Put_shader_trans_data;

  object_decl_ptr := New_object;
  Begin_local_object_group := object_decl_ptr;
end; {procedure Begin_local_object_group}


procedure End_local_object_group(object_decl_ptr: object_decl_ptr_type);
begin
  End_object;

  {********************************}
  { return to previous model trans }
  {********************************}
  Pop_trans_stack(model_trans_stack_ptr);
  Put_trans_data;

  {*********************************}
  { return to previous shader trans }
  {*********************************}
  Pop_trans_stack(shader_trans_stack_ptr);
  Put_shader_trans_data;

  {********************************************}
  { scale transformation to size of new object }
  {********************************************}
  Inst_geom_object(object_decl_ptr, unit_trans);
  Pop_object_stack;

  End_object_group;
  Update_params;
end; {function End_local_object_group}


function Find_object_hits_object(code_ptr1, code_ptr2: code_ptr_type;
  static_link1, static_link2: stack_index_type;
  var location, normal: vector_type): boolean;
var
  object_decl_ptr: object_decl_ptr_type;
  view_object_ptr1, view_object_ptr2: view_object_inst_ptr_type;
  scene_axes: coord_axes_type;
  hit: boolean;
  temp: integer;
begin
  {**************************}
  { create necessary objects }
  {**************************}
  Set_facets(facets);

  object_decl_ptr := Begin_local_object_group;

  {*********************}
  { instantiate object1 }
  {*********************}
  object_stmt_ptr^.stmt_code_ref := forward_code_ref_type(code_ptr1);
  code_ptr1^.decl_static_link := static_link1;
  Interpret_stmt(object_stmt_ptr);

  {*********************}
  { instantiate object2 }
  {*********************}
  object_stmt_ptr^.stmt_code_ref := forward_code_ref_type(code_ptr2);
  code_ptr2^.decl_static_link := static_link2;
  Interpret_stmt(object_stmt_ptr);

  End_local_object_group(object_decl_ptr);

  {************************************}
  { make necessary ray tracing structs }
  {************************************}
  temp := min_object_complexity;
  min_object_complexity := 0;
  Make_precalc;
  Make_preview;
  min_object_complexity := temp;

  Make_voxel_space(nil, raytracing_decls_ptr, eye_trans);
  Next_object_group;

  {***********************}
  { make object instances }
  {***********************}
  view_object_ptr1 := viewing_scene_ptr^.object_decl_ptr^.sub_object_ptr;
  view_object_ptr1^.ray_object_ptr :=
    raytracing_scene_ptr^.object_decl_ptr^.sub_object_ptr;
  view_object_ptr2 := view_object_ptr1^.next;
  view_object_ptr2^.ray_object_ptr := view_object_ptr1^.ray_object_ptr^.next;

  {*******************************}
  { check for object intersection }
  {*******************************}
  scene_axes := raytracing_scene_ptr^.object_decl_ptr^.coord_axes;
  Transform_axes_from_axes(view_object_ptr1^.ray_object_ptr^.coord_axes,
    scene_axes);
  Transform_axes_from_axes(view_object_ptr2^.ray_object_ptr^.coord_axes,
    scene_axes);
  hit := Object_hits_object(view_object_ptr1, view_object_ptr2, location,
    normal);

  {***********************************}
  { remove record of of local objects }
  {***********************************}
  Free_method_decl_data(code_data_ptr_type(code_ptr1^.code_data_ptr)^.object_decl_id);
  Free_method_decl_data(code_data_ptr_type(code_ptr2^.code_data_ptr)^.object_decl_id);

  Find_object_hits_object := hit;
end; {function Find_object_hits_object}


function Find_ray_hits_object(var ray: ray_type;
  code_ptr: code_ptr_type;
  static_link: stack_index_type): boolean;
var
  obj: hierarchical_object_type;
  object_decl_ptr: object_decl_ptr_type;
  t: real;
begin
  {**************************}
  { create necessary objects }
  {**************************}
  Set_facets(facets);
  object_decl_ptr := Begin_local_object_group;

  {********************}
  { instantiate object }
  {********************}
  object_stmt_ptr^.stmt_code_ref := forward_code_ref_type(code_ptr);
  code_ptr^.decl_static_link := static_link;
  Interpret_stmt(object_stmt_ptr);

  End_local_object_group(object_decl_ptr);

  {************************************}
  { make necessary ray tracing structs }
  {************************************}
  Make_precalc;
  Make_preview;
  Make_voxel_space(nil, raytracing_decls_ptr, eye_trans);
  Next_object_group;

  {***************************}
  { intersect ray with object }
  {***************************}
  t := Primary_ray_intersection(ray, tiny, infinity, obj);

  if (t <> infinity) then
    Find_ray_object_intersection(ray, obj, t);

  {***********************************}
  { remove record of of local objects }
  {***********************************}
  Free_method_decl_data(code_data_ptr_type(code_ptr^.code_data_ptr)^.object_decl_id);

  Find_ray_hits_object := (t <> infinity);
end; {function Find_ray_hits_object}


function Closest_point_to_point(point: vector_type;
  code_ptr: code_ptr_type;
  static_link: stack_index_type): vector_type;
var
  object_decl_ptr: object_decl_ptr_type;
begin
  {**************************}
  { create necessary objects }
  {**************************}
  Set_facets(facets);
  object_decl_ptr := Begin_local_object_group;

  {********************}
  { instantiate object }
  {********************}
  object_stmt_ptr^.stmt_code_ref := forward_code_ref_type(code_ptr);
  code_ptr^.decl_static_link := static_link;
  Interpret_stmt(object_stmt_ptr);

  End_local_object_group(object_decl_ptr);

  Make_preview;
  Next_object_group;
  point := Closest_to_point_on_object(viewing_scene_ptr, point);

  {***********************************}
  { remove record of of local objects }
  {***********************************}
  Free_method_decl_data(code_data_ptr_type(code_ptr^.code_data_ptr)^.object_decl_id);

  Closest_point_to_point := point;
end; {function Closest_point_to_point}


function Closest_point_to_plane(point, normal: vector_type;
  code_ptr: code_ptr_type;
  static_link: stack_index_type): vector_type;
var
  object_decl_ptr: object_decl_ptr_type;
begin
  {**************************}
  { create necessary objects }
  {**************************}
  Set_facets(facets);
  object_decl_ptr := Begin_local_object_group;

  {********************}
  { instantiate object }
  {********************}
  object_stmt_ptr^.stmt_code_ref := forward_code_ref_type(code_ptr);
  code_ptr^.decl_static_link := static_link;
  Interpret_stmt(object_stmt_ptr);

  End_local_object_group(object_decl_ptr);

  Make_preview;
  Next_object_group;
  point := Closest_to_plane_on_object(viewing_scene_ptr, point, normal);

  {***********************************}
  { remove record of of local objects }
  {***********************************}
  Free_method_decl_data(code_data_ptr_type(code_ptr^.code_data_ptr)^.object_decl_id);

  Closest_point_to_plane := point;
end; {function Closest_point_to_plane}


{********************************}
{ proximity detection primitives }
{********************************}


procedure Eval_object_hits_object;
var
  param_index: stack_index_type;
  code_ptr1, code_ptr2: code_ptr_type;
  static_link1, static_link2: stack_index_type;
  location_index, direction_index: stack_index_type;
  location, direction: vector_type;
  hit: boolean;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  code_ptr1 := code_ptr_type(Get_code_param(param_index));
  static_link1 := Get_stack_index_param(param_index);
  code_ptr2 := code_ptr_type(Get_code_param(param_index));
  static_link2 := Get_stack_index_param(param_index);
  location_index := param_index;
  param_index := param_index + 3;
  direction_index := param_index;
  param_index := param_index + 3;

  {****************************}
  { check for object collision }
  {****************************}
  hit := Find_object_hits_object(code_ptr1, code_ptr2, static_link1,
    static_link2, location, direction);

  {*****************************}
  { assign reference parameters }
  {*****************************}
  Set_local_vector(location_index, location);
  Set_local_vector(direction_index, direction);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_boolean_operand(hit);
end; {procedure Eval_object_hits_object}


procedure Eval_ray_hits_object;
var
  param_index: stack_index_type;
  code_ptr: code_ptr_type;
  static_link: stack_index_type;
  location_index, direction_index: stack_index_type;
  ray: ray_type;
  hit: boolean;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  ray.location := Get_vector_param(param_index);
  ray.direction := Get_vector_param(param_index);
  code_ptr := code_ptr_type(Get_code_param(param_index));
  static_link := Get_stack_index_param(param_index);
  location_index := param_index;
  param_index := param_index + 3;
  direction_index := param_index;
  param_index := param_index + 3;

  {**********************************}
  { check for ray / object collision }
  {**********************************}
  hit := Find_ray_hits_object(ray, code_ptr, static_link);

  {*****************************}
  { assign reference parameters }
  {*****************************}
  Set_local_vector(location_index, ray.location);
  Set_local_vector(direction_index, ray.direction);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_boolean_operand(hit);
end; {procedure Eval_ray_hits_object}


procedure Eval_closest_to_point;
var
  param_index: stack_index_type;
  code_ptr: code_ptr_type;
  static_link: stack_index_type;
  point: vector_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  point := Get_vector_param(param_index);
  code_ptr := code_ptr_type(Get_code_param(param_index));
  static_link := Get_stack_index_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_vector_operand(Closest_point_to_point(point, code_ptr, static_link));
end; {procedure Eval_closest_to_point}


procedure Eval_closest_to_plane;
var
  param_index: stack_index_type;
  code_ptr: code_ptr_type;
  static_link: stack_index_type;
  point, normal: vector_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  point := Get_vector_param(param_index);
  normal := Get_vector_param(param_index);
  code_ptr := code_ptr_type(Get_code_param(param_index));
  static_link := Get_stack_index_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_vector_operand(Closest_point_to_plane(point, normal, code_ptr,
    static_link));
end; {procedure Eval_closest_to_plane}


{***********************}
{ ray casting primitive }
{***********************}


procedure Eval_project_ray;
var
  param_index: stack_index_type;
  shader_coord_kind: shader_coord_kind_type;
  vector: vector_type;
  vector2: vector2_type;
  ray: ray_type;
  eye_axes: coord_axes_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  vector := Get_vector_param(param_index);
  shader_coord_kind :=
    shader_coord_kind_index_array[Get_integer_param(param_index)];

  if current_projection_ptr <> nil then
    begin
      case shader_coord_kind of
        display_shader:
          begin
            vector2.x := vector.x - current_projection_ptr^.projection_center.x;
            vector2.y := current_projection_ptr^.projection_center.y - vector.y;
            ray := Project_point2_to_ray(vector2);
          end;
        screen_shader:
          begin
            vector2.x := (vector.x * current_projection_ptr^.projection_size.h / 2);
            vector2.y := (vector.y * current_projection_ptr^.projection_size.v / 2);
            ray := Project_point2_to_ray(vector2);
          end;
      end;

      eye_axes := Trans_to_axes(eye_trans);
      Transform_vector_to_axes(ray.direction, eye_axes);
    end
  else
    ray.direction := zero_vector;

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_vector_operand(ray.direction);
end; {procedure Eval_project_ray}


{*******************************************************************}
{ routine to switch between and evaluate native collision functions }
{*******************************************************************}


procedure Exec_native_collision_method(kind: native_collision_method_kind_type);
begin
  case kind of

    {********************************}
    { collision detection primitives }
    {********************************}
    native_object_hits_object:
      Eval_object_hits_object;
    native_ray_hits_object:
      Eval_ray_hits_object;

    {********************************}
    { proximity detection primitives }
    {********************************}
    native_closest_to_point:
      Eval_closest_to_point;
    native_closest_to_plane:
      Eval_closest_to_plane;

    {***********************}
    { ray casting primitive }
    {***********************}
    native_project_ray:
      Eval_project_ray;

  end; {case}
end; {procedure Exec_native_collision_method}


initialization
  {********************}
  { create object stmt }
  {********************}
  object_stmt_ptr := New_stmt(static_method_stmt);
  object_stmt_ptr^.stmt_code_ref := nil;

  {*********************}
  { create picture stmt }
  {*********************}
  picture_stmt_ptr := New_stmt(static_method_stmt);
  picture_stmt_ptr^.stmt_code_ref := nil;
end.

