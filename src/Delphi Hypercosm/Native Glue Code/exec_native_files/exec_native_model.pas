unit exec_native_model;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          exec_native_model            3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is responsible for executing native         }
{       modelling methods.                                      }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  native_model, objects;


var
  native_object_inst_ptr: object_inst_ptr_type;


  {************************************************************}
  { routine to switch between and execute native model methods }
  {************************************************************}
procedure Exec_native_model_method(kind: native_model_method_kind_type);


implementation
uses
  vectors, trans, trans_stack, colors, state_vars, polygons, polymeshes,
  volumes, init_prims, object_attr, attr_stack, addr_types, get_params,
  get_stack_data, get_heap_data, op_stacks, array_limits, assign_native_model,
  interpreter;


{***************************}
{ transformation primitives }
{***************************}


procedure Eval_trans_level;
begin
  Push_integer_operand(Trans_stack_height(model_trans_stack_ptr) - 1);
end; {procedure Eval_trans_level}


procedure Eval_transform_point;
var
  param_index: stack_index_type;
  point: vector_type;
  trans: trans_type;
  height: integer;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  point := Get_vector_param(param_index);

  if model_trans_stack_ptr^.height >= 1 then
    begin
      height := Trans_stack_height(model_trans_stack_ptr) - 1;
      trans := Inverse_trans(model_trans_stack_ptr^.stack[height]);
      Transform_point(point, trans);
    end;

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_vector_operand(point);
end; {procedure Eval_transform_point}


procedure Eval_transform_vector;
var
  param_index: stack_index_type;
  vector: vector_type;
  trans: trans_type;
  height: integer;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  vector := Get_vector_param(param_index);

  if model_trans_stack_ptr^.height >= 1 then
    begin
      height := Trans_stack_height(model_trans_stack_ptr) - 1;
      trans := Inverse_trans(model_trans_stack_ptr^.stack[height]);
      Transform_vector(vector, trans);
    end;

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_vector_operand(vector);
end; {procedure Eval_transform_vector}


{********************}
{ quadric primitives }
{********************}


function Exec_sphere: object_inst_ptr_type;
var
  param_index: stack_index_type;
  center: vector_type;
  radius: real;
  umin, umax: real;
  vmin, vmax: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  center := Get_vector_param(param_index);
  radius := Get_scalar_param(param_index);
  umin := Get_scalar_param(param_index);
  umax := Get_scalar_param(param_index);
  vmin := Get_scalar_param(param_index);
  vmax := Get_scalar_param(param_index);

  {**************************}
  { get global default color }
  {**************************}
  sphere_color := Get_global_color(native_sphere_color_index);

  Exec_sphere := Init_sphere(center, radius, umin, umax, vmin, vmax);
end; {function Exec_sphere}


function Exec_cylinder: object_inst_ptr_type;
var
  param_index: stack_index_type;
  end1: vector_type;
  end2: vector_type;
  radius: real;
  umin, umax: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  end1 := Get_vector_param(param_index);
  end2 := Get_vector_param(param_index);
  radius := Get_scalar_param(param_index);
  umin := Get_scalar_param(param_index);
  umax := Get_scalar_param(param_index);

  {**************************}
  { get global default color }
  {**************************}
  cylinder_color := Get_global_color(native_cylinder_color_index);

  Exec_cylinder := Init_cylinder(end1, end2, radius, umin, umax);
end; {function Exec_cylinder}


function Exec_cone: object_inst_ptr_type;
var
  param_index: stack_index_type;
  end1: vector_type;
  end2: vector_type;
  radius1: real;
  radius2: real;
  umin, umax: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  end1 := Get_vector_param(param_index);
  end2 := Get_vector_param(param_index);
  radius1 := Get_scalar_param(param_index);
  radius2 := Get_scalar_param(param_index);
  umin := Get_scalar_param(param_index);
  umax := Get_scalar_param(param_index);

  {**************************}
  { get global default color }
  {**************************}
  cone_color := Get_global_color(native_cone_color_index);

  Exec_cone := Init_cone(end1, end2, radius1, radius2, umin, umax);
end; {function Exec_cone}


function Exec_paraboloid: object_inst_ptr_type;
var
  param_index: stack_index_type;
  top: vector_type;
  base: vector_type;
  radius: real;
  umin, umax: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  top := Get_vector_param(param_index);
  base := Get_vector_param(param_index);
  radius := Get_scalar_param(param_index);
  umin := Get_scalar_param(param_index);
  umax := Get_scalar_param(param_index);

  {**************************}
  { get global default color }
  {**************************}
  paraboloid_color := Get_global_color(native_paraboloid_color_index);

  Exec_paraboloid := Init_paraboloid(top, base, radius, umin, umax);
end; {function Exec_paraboloid}


function Exec_hyperboloid1: object_inst_ptr_type;
var
  param_index: stack_index_type;
  end1: vector_type;
  end2: vector_type;
  radius1: real;
  radius2: real;
  umin, umax: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  end1 := Get_vector_param(param_index);
  end2 := Get_vector_param(param_index);
  radius1 := Get_scalar_param(param_index);
  radius2 := Get_scalar_param(param_index);
  umin := Get_scalar_param(param_index);
  umax := Get_scalar_param(param_index);

  {**************************}
  { get global default color }
  {**************************}
  hyperboloid1_color := Get_global_color(native_hyperboloid1_color_index);

  Exec_hyperboloid1 := Init_hyperboloid1(end1, end2, radius1, radius2, umin,
    umax);
end; {function Exec_hyperboloid1}


function Exec_hyperboloid2: object_inst_ptr_type;
var
  param_index: stack_index_type;
  top: vector_type;
  base: vector_type;
  radius: real;
  eccentricity: real;
  umin, umax: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  top := Get_vector_param(param_index);
  base := Get_vector_param(param_index);
  radius := Get_scalar_param(param_index);
  eccentricity := Get_scalar_param(param_index);
  umin := Get_scalar_param(param_index);
  umax := Get_scalar_param(param_index);

  {**************************}
  { get global default color }
  {**************************}
  hyperboloid2_color := Get_global_color(native_hyperboloid2_color_index);

  Exec_hyperboloid2 := Init_hyperboloid2(top, base, radius, eccentricity, umin,
    umax);
end; {function Exec_hyperboloid2}


{*******************}
{ planar primitives }
{*******************}


function Exec_plane: object_inst_ptr_type;
var
  param_index: stack_index_type;
  origin: vector_type;
  normal: vector_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  origin := Get_vector_param(param_index);
  normal := Get_vector_param(param_index);

  {**************************}
  { get global default color }
  {**************************}
  plane_color := Get_global_color(native_plane_color_index);

  Exec_plane := Init_plane(origin, normal);
end; {function Exec_plane}


function Exec_disk: object_inst_ptr_type;
var
  param_index: stack_index_type;
  center: vector_type;
  normal: vector_type;
  radius: real;
  umin, umax: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  center := Get_vector_param(param_index);
  normal := Get_vector_param(param_index);
  radius := Get_scalar_param(param_index);
  umin := Get_scalar_param(param_index);
  umax := Get_scalar_param(param_index);

  {**************************}
  { get global default color }
  {**************************}
  disk_color := Get_global_color(native_disk_color_index);

  Exec_disk := Init_disk(center, normal, radius, umin, umax);
end; {function Exec_disk}


function Exec_ring: object_inst_ptr_type;
var
  param_index: stack_index_type;
  center: vector_type;
  normal: vector_type;
  inner_radius: real;
  outer_radius: real;
  umin, umax: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  center := Get_vector_param(param_index);
  normal := Get_vector_param(param_index);
  inner_radius := Get_scalar_param(param_index);
  outer_radius := Get_scalar_param(param_index);
  umin := Get_scalar_param(param_index);
  umax := Get_scalar_param(param_index);

  {**************************}
  { get global default color }
  {**************************}
  ring_color := Get_global_color(native_ring_color_index);

  Exec_ring := Init_ring(center, normal, inner_radius, outer_radius, umin,
    umax);
end; {function Exec_ring}


function Exec_triangle: object_inst_ptr_type;
var
  param_index: stack_index_type;
  vertex1: vector_type;
  vertex2: vector_type;
  vertex3: vector_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  vertex1 := Get_vector_param(param_index);
  vertex2 := Get_vector_param(param_index);
  vertex3 := Get_vector_param(param_index);

  {**************************}
  { get global default color }
  {**************************}
  triangle_color := Get_global_color(native_triangle_color_index);

  Exec_triangle := Init_triangle(vertex1, vertex2, vertex3);
end; {function Exec_triangle}


function Exec_parallelogram: object_inst_ptr_type;
var
  param_index: stack_index_type;
  vertex: vector_type;
  side1: vector_type;
  side2: vector_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  vertex := Get_vector_param(param_index);
  side1 := Get_vector_param(param_index);
  side2 := Get_vector_param(param_index);

  {**************************}
  { get global default color }
  {**************************}
  parallelogram_color := Get_global_color(native_parallelogram_color_index);

  Exec_parallelogram := Init_parallelogram(vertex, side1, side2);
end; {function Exec_parallelogram}


function Exec_polygon: object_inst_ptr_type;
var
  param_index: stack_index_type;
  polygon_ptr, first_polygon_ptr, hole_ptr: polygon_ptr_type;
  point, texture, previous_point: vector_type;
  first_point, first_texture: vector_type;
  counter: integer;
  new_cycle: boolean;
  vertex_handle, texture_handle: handle_type;
  vertex_index, texture_index: heap_index_type;
  vertex_num, texture_num: heap_index_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  vertex_handle := Get_handle_param(param_index);
  texture_handle := Get_handle_param(param_index);

  {***************************}
  { get array sizes from heap }
  {***************************}
  vertex_num := Array_num(vertex_handle, 0);
  texture_num := Array_num(texture_handle, 0);

  {*******************}
  { check array sizes }
  {*******************}
  if (texture_num <> 0) then
    if (texture_num <> vertex_num) then
      Runtime_error('Polygon texture points must equal number of vertices.');

  {******************}
  { make new polygon }
  {******************}
  polygon_ptr := New_polygon;
  first_polygon_ptr := polygon_ptr;

  if (vertex_num <> 0) then
    begin
      {**************************}
      { get index data from heap }
      {**************************}
      vertex_index := Get_handle_heap_index(vertex_handle, 1);
      if (texture_num <> 0) then
        texture_index := Get_handle_heap_index(texture_handle, 1)
      else
        texture_index := 0;

      {***************}
      { make vertices }
      {***************}
      new_cycle := true;

      for counter := 1 to vertex_num do
        begin
          point := Get_handle_vector(vertex_handle, vertex_index);
          vertex_index := vertex_index + 3;

          {**********************}
          { get optional texture }
          {**********************}
          if (texture_num <> 0) then
            begin
              texture := Get_handle_vector(texture_handle, texture_index);
              texture_index := texture_index + 3;
            end
          else
            texture := point;

          if new_cycle then
            begin
              {*******************}
              { save first vertex }
              {*******************}
              first_point := point;
              first_texture := texture;
              previous_point := point;
              new_cycle := false;

              {*************}
              { create hole }
              {*************}
              if (counter > 1) then
                begin
                  hole_ptr := New_polygon;
                  polygon_ptr^.next := hole_ptr;
                  polygon_ptr := hole_ptr;
                end;
            end
          else if not Equal_vector(point, previous_point) then
            begin
              if Equal_vector(point, first_point) then
                begin
                  {*******************}
                  { end current cycle }
                  {*******************}
                  new_cycle := true;

                  {*********************************************}
                  { add first point of polygon if not duplicate }
                  {*********************************************}
                  if not Equal_vector(first_point, previous_point) then
                    Add_polygon_vertex(polygon_ptr, first_point, first_texture);
                end
              else
                begin
                  {*******************}
                  { create new vertex }
                  {*******************}
                  previous_point := point;
                  Add_polygon_vertex(polygon_ptr, point, texture);
                  new_cycle := false;
                end;
            end;
        end;

      {**********************************}
      { add first point if not duplicate }
      {**********************************}
      if not new_cycle then
        Add_polygon_vertex(polygon_ptr, first_point, first_texture);
    end;

  {**************************}
  { get global default color }
  {**************************}
  polygon_color := Get_global_color(native_polygon_color_index);

  Exec_polygon := Init_polygon(first_polygon_ptr);
end; {function Exec_polygon}


{***********************}
{ non-planar primitives }
{***********************}


function Exec_torus: object_inst_ptr_type;
var
  param_index: stack_index_type;
  center: vector_type;
  normal: vector_type;
  inner_radius: real;
  outer_radius: real;
  umin, umax: real;
  vmin, vmax: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  center := Get_vector_param(param_index);
  normal := Get_vector_param(param_index);
  inner_radius := Get_scalar_param(param_index);
  outer_radius := Get_scalar_param(param_index);
  umin := Get_scalar_param(param_index);
  umax := Get_scalar_param(param_index);
  vmin := Get_scalar_param(param_index);
  vmax := Get_scalar_param(param_index);

  {**************************}
  { get global default color }
  {**************************}
  torus_color := Get_global_color(native_torus_color_index);

  Exec_torus := Init_torus(center, normal, inner_radius, outer_radius, umin,
    umax, vmin, vmax);
end; {function Exec_torus}


function Exec_block: object_inst_ptr_type;
var
  param_index: stack_index_type;
  vertex: vector_type;
  side1: vector_type;
  side2: vector_type;
  side3: vector_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  vertex := Get_vector_param(param_index);
  side1 := Get_vector_param(param_index);
  side2 := Get_vector_param(param_index);
  side3 := Get_vector_param(param_index);

  {**************************}
  { get global default color }
  {**************************}
  block_color := Get_global_color(native_block_color_index);

  Exec_block := Init_block(vertex, side1, side2, side3);
end; {function Exec_block}


function Exec_shaded_triangle: object_inst_ptr_type;
var
  param_index: stack_index_type;
  vertex1: vector_type;
  vertex2: vector_type;
  vertex3: vector_type;
  normal1: vector_type;
  normal2: vector_type;
  normal3: vector_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  vertex1 := Get_vector_param(param_index);
  vertex2 := Get_vector_param(param_index);
  vertex3 := Get_vector_param(param_index);
  normal1 := Get_vector_param(param_index);
  normal2 := Get_vector_param(param_index);
  normal3 := Get_vector_param(param_index);

  {**************************}
  { get global default color }
  {**************************}
  shaded_triangle_color := Get_global_color(native_shaded_triangle_color_index);

  Exec_shaded_triangle := Init_shaded_triangle(vertex1, vertex2, vertex3,
    normal1, normal2, normal3);
end; {function Exec_shaded_triangle}


function Exec_shaded_polygon: object_inst_ptr_type;
var
  param_index: stack_index_type;
  polygon_ptr, first_polygon_ptr, hole_ptr: shaded_polygon_ptr_type;
  point, normal, texture, previous_point: vector_type;
  first_point, first_normal, first_texture: vector_type;
  counter: integer;
  new_cycle: boolean;
  vertex_handle, normal_handle, texture_handle: handle_type;
  vertex_index, normal_index, texture_index: heap_index_type;
  vertex_num, normal_num, texture_num: heap_index_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  vertex_handle := Get_handle_param(param_index);
  normal_handle := Get_handle_param(param_index);
  texture_handle := Get_handle_param(param_index);

  {***************************}
  { get array sizes from heap }
  {***************************}
  vertex_num := Array_num(vertex_handle, 0);
  normal_num := Array_num(normal_handle, 0);
  texture_num := Array_num(texture_handle, 0);

  {*******************}
  { check array sizes }
  {*******************}
  if (normal_num <> vertex_num) then
    Runtime_error('Shaded polygon normals must equal number of vertices.');

  if (texture_num <> 0) then
    if (texture_num <> vertex_num) then
      Runtime_error('Polygon texture points must equal number of vertices.');

  {*************************}
  { make new shaded polygon }
  {*************************}
  polygon_ptr := New_shaded_polygon;
  first_polygon_ptr := polygon_ptr;

  if (vertex_num <> 0) then
    begin
      {**************************}
      { get index data from heap }
      {**************************}
      vertex_index := Get_handle_heap_index(vertex_handle, 1);
      normal_index := Get_handle_heap_index(normal_handle, 1);
      if (texture_num <> 0) then
        texture_index := Get_handle_heap_index(texture_handle, 1)
      else
        texture_index := 0;

      {***************}
      { make vertices }
      {***************}
      new_cycle := true;

      for counter := 1 to vertex_num do
        begin
          point := Get_handle_vector(vertex_handle, vertex_index);
          vertex_index := vertex_index + 3;
          normal := Get_handle_vector(normal_handle, normal_index);
          normal_index := normal_index + 3;

          {**********************}
          { get optional texture }
          {**********************}
          if (texture_num <> 0) then
            begin
              texture := Get_handle_vector(texture_handle, texture_index);
              texture_index := texture_index + 3;
            end
          else
            texture := point;

          if new_cycle then
            begin
              {*******************}
              { save first vertex }
              {*******************}
              first_point := point;
              first_normal := normal;
              first_texture := texture;
              previous_point := point;
              new_cycle := false;

              {*************}
              { create hole }
              {*************}
              if (counter > 1) then
                begin
                  hole_ptr := New_shaded_polygon;
                  polygon_ptr^.next := hole_ptr;
                  polygon_ptr := hole_ptr;
                end;
            end
          else if not Equal_vector(point, previous_point) then
            begin
              if Equal_vector(point, first_point) then
                begin
                  {*******************}
                  { end current cycle }
                  {*******************}
                  new_cycle := true;

                  {*********************************************}
                  { add first point of polygon if not duplicate }
                  {*********************************************}
                  if not Equal_vector(first_point, previous_point) then
                    Add_shaded_polygon_vertex(polygon_ptr, first_point,
                      first_normal, first_texture);
                end
              else
                begin
                  {*******************}
                  { create new vertex }
                  {*******************}
                  previous_point := point;
                  Add_shaded_polygon_vertex(polygon_ptr, point, normal,
                    texture);
                  new_cycle := false;
                end;
            end;
        end;

      {**********************************}
      { add first point if not duplicate }
      {**********************************}
      if not new_cycle then
        Add_shaded_polygon_vertex(polygon_ptr, first_point, first_normal,
          first_texture);
    end;

  {**************************}
  { get global default color }
  {**************************}
  shaded_polygon_color := Get_global_color(native_shaded_polygon_color_index);

  Exec_shaded_polygon := Init_shaded_polygon(first_polygon_ptr);
end; {function Exec_shaded_polygon}


function Exec_mesh: object_inst_ptr_type;
var
  param_index: stack_index_type;
  smoothing, mending, closed: boolean;
  counter, index: integer;
  mesh_ptr: mesh_ptr_type;
  point, normal, texture: vector_type;
  vertex1, vertex2: integer;
  vertex_handle, edge_handle, face_handle, normal_handle, texture_handle:
  handle_type;
  vertex_index, edge_index, face_index, normal_index, texture_index:
  heap_index_type;
  vertex_num, edge_num, face_num, normal_num, texture_num: heap_index_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  vertex_handle := Get_handle_param(param_index);
  edge_handle := Get_handle_param(param_index);
  face_handle := Get_handle_param(param_index);
  normal_handle := Get_handle_param(param_index);
  texture_handle := Get_handle_param(param_index);
  smoothing := Get_boolean_param(param_index);
  mending := Get_boolean_param(param_index);
  closed := Get_boolean_param(param_index);

  {***************************}
  { get array sizes from heap }
  {***************************}
  vertex_num := Array_num(vertex_handle, 0);
  edge_num := Array_num(edge_handle, 0);
  face_num := Array_num(face_handle, 0);
  texture_num := Array_num(texture_handle, 0);
  normal_num := Array_num(normal_handle, 0);

  {*******************}
  { check array sizes }
  {*******************}
  if Array_num(edge_handle, 1) <> 2 then
    Runtime_error('Mesh edge array must be [.., 1..2].');

  if (texture_num <> 0) then
    if (texture_num <> vertex_num) then
      Runtime_error('Mesh texture points must equal number of vertices.');

  if (normal_num <> 0) then
    if (normal_num <> vertex_num) then
      Runtime_error('Mesh normals must equal number of vertices.');

  {*****************}
  { create new mesh }
  {*****************}
  mesh_ptr := New_mesh;

  if (vertex_num <> 0) then
    begin
      {**************}
      { add vertices }
      {**************}
      vertex_index := Get_handle_heap_index(vertex_handle, 1);
      if (normal_num <> 0) then
        normal_index := Get_handle_heap_index(normal_handle, 1)
      else
        normal_index := 0;
      if (texture_num <> 0) then
        texture_index := Get_handle_heap_index(texture_handle, 1)
      else
        texture_index := 0;

      for counter := 1 to vertex_num do
        begin
          point := Get_handle_vector(vertex_handle, vertex_index);
          vertex_index := vertex_index + 3;

          {*********************}
          { get optional normal }
          {*********************}
          if (normal_num <> 0) then
            begin
              normal := Get_handle_vector(normal_handle, normal_index);
              normal_index := normal_index + 3;
            end
          else
            normal := zero_vector;

          {**********************}
          { get optional texture }
          {**********************}
          if (texture_num <> 0) then
            begin
              texture := Get_handle_vector(texture_handle, texture_index);
              texture_index := texture_index + 3;
            end
          else
            texture := point;

          Add_mesh_vertex(mesh_ptr, point, normal, texture);
        end;

      {***********}
      { add edges }
      {***********}
      if (edge_num <> 0) then
        begin
          edge_index := Get_handle_heap_index(edge_handle, 1);
          for counter := 0 to (edge_num - 1) do
            begin
              vertex1 := Get_handle_integer(edge_handle, edge_index + (counter *
                2));
              vertex2 := Get_handle_integer(edge_handle, edge_index + (counter *
                2) + 1);
              Add_mesh_edge(mesh_ptr, vertex1, vertex2);
            end;
        end;

      {***********}
      { add faces }
      {***********}
      if (face_num <> 0) then
        begin
          face_index := Get_handle_heap_index(face_handle, 1);
          Add_mesh_face(mesh_ptr, true);
          for counter := 0 to (face_num - 1) do
            begin
              index := Get_handle_integer(face_handle, face_index + counter);
              if (index = 0) then
                begin
                  if (counter <> (face_num - 1)) then
                    begin
                      Add_mesh_face(mesh_ptr, true);
                    end;
                end
              else
                begin
                  {************************}
                  { add edge index to face }
                  {************************}
                  Add_mesh_edge_index(mesh_ptr, index);
                end;
            end;
        end;
    end;

  {**************************}
  { get global default color }
  {**************************}
  mesh_color := Get_global_color(native_mesh_color_index);

  Exec_mesh := Init_mesh(mesh_ptr, smoothing, mending, closed);
end; {function Exec_mesh}


function Exec_blob: object_inst_ptr_type;
var
  param_index: stack_index_type;
  center: vector_type;
  radius, strength, threshold: real;
  metaball_list, metaball_ptr: metaball_ptr_type;
  counter: integer;
  center_handle, radius_handle, strength_handle: handle_type;
  center_index, radius_index, strength_index: heap_index_type;
  center_num, radius_num, strength_num: heap_index_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  center_handle := Get_handle_param(param_index);
  radius_handle := Get_handle_param(param_index);
  strength_handle := Get_handle_param(param_index);
  threshold := Get_scalar_param(param_index);

  {***************************}
  { get array sizes from heap }
  {***************************}
  center_num := Array_num(center_handle, 0);
  radius_num := Array_num(radius_handle, 0);
  strength_num := Array_num(strength_handle, 0);

  {*******************}
  { check array sizes }
  {*******************}
  if (radius_num <> 0) then
    if (radius_num <> center_num) then
      Runtime_error('Blob radii must equal number of centers.');
  if (strength_num <> 0) then
    if (strength_num <> center_num) then
      Runtime_error('Blob strengths must equal number of centers.');

  {******************}
  { create metaballs }
  {******************}
  metaball_list := nil;

  if (center_num > 0) then
    begin
      center_index := Get_handle_heap_index(center_handle, 1);
      if (radius_num <> 0) then
        radius_index := Get_handle_heap_index(radius_handle, 1)
      else
        radius_index := 0;
      if (strength_num <> 0) then
        strength_index := Get_handle_heap_index(strength_handle, 1)
      else
        strength_index := 0;

      for counter := 0 to (center_num - 1) do
        begin
          center := Get_handle_vector(center_handle, center_index + counter);

          if radius_num <> 0 then
            radius := Get_handle_scalar(radius_handle, radius_index + counter)
          else
            radius := 1;

          if strength_num <> 0 then
            strength := Get_handle_scalar(strength_handle, strength_index +
              counter)
          else
            strength := 1;

          metaball_ptr := New_metaball(center, radius, strength);
          metaball_ptr^.next := metaball_list;
          metaball_list := metaball_ptr;
        end;
    end;

  {**************************}
  { get global default color }
  {**************************}
  blob_color := Get_global_color(native_blob_color_index);

  Exec_blob := Init_blob(metaball_list, threshold);
end; {function Exec_blob}


{************************}
{ non-surface primitives }
{************************}


function Exec_points: object_inst_ptr_type;
var
  param_index: stack_index_type;
  points_ptr: points_ptr_type;
  vertex: vector_type;
  counter: integer;
  vertex_handle: handle_type;
  vertex_index: heap_index_type;
  vertex_num: heap_index_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  vertex_handle := Get_handle_param(param_index);

  {***************************}
  { get array sizes from heap }
  {***************************}
  vertex_num := Array_num(vertex_handle, 0);
  if (vertex_num <> 0) then
    begin
      points_ptr := New_points;

      {***************************}
      { get vertex data from heap }
      {***************************}
      vertex_index := Get_handle_heap_index(vertex_handle, 1);
      for counter := 1 to vertex_num do
        begin
          vertex := Get_handle_vector(vertex_handle, vertex_index);
          vertex_index := vertex_index + 3;
          Add_point_vertex(points_ptr, vertex);
        end;
    end
  else
    points_ptr := nil;

  {**************************}
  { get global default color }
  {**************************}
  point_color := Get_global_color(native_point_color_index);

  Exec_points := Init_points(points_ptr);
end; {function Exec_points}


function Exec_line: object_inst_ptr_type;
var
  param_index: stack_index_type;
  lines_ptr: lines_ptr_type;
  vertex: vector_type;
  counter: integer;
  vertex_handle: handle_type;
  vertex_index: heap_index_type;
  vertex_num: heap_index_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  vertex_handle := Get_handle_param(param_index);

  {***************************}
  { get array sizes from heap }
  {***************************}
  vertex_num := Array_num(vertex_handle, 0);
  if (vertex_num <> 0) then
    begin
      lines_ptr := New_lines;

      {***************************}
      { get vertex data from heap }
      {***************************}
      vertex_index := Get_handle_heap_index(vertex_handle, 1);
      for counter := 1 to vertex_num do
        begin
          vertex := Get_handle_vector(vertex_handle, vertex_index);
          vertex_index := vertex_index + 3;
          Add_line_vertex(lines_ptr, vertex);
        end;
    end
  else
    lines_ptr := nil;

  {**************************}
  { get global default color }
  {**************************}
  line_color := Get_global_color(native_line_color_index);

  Exec_line := Init_lines(lines_ptr);
end; {function Exec_line}


function Exec_volume: object_inst_ptr_type;
var
  param_index: stack_index_type;
  volume_ptr: volume_ptr_type;
  density_ptr: density_ptr_type;
  point_ptr: vector_ptr_type;
  volume_size, counter: longint;
  threshold: real;
  capping, smoothing: boolean;
  density_handle, vertex_handle: handle_type;
  density_index, vertex_index: handle_type;
  density_length, density_width, density_height: heap_index_type;
  vertex_length, vertex_width, vertex_height: heap_index_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  density_handle := Get_handle_param(param_index);
  vertex_handle := Get_handle_param(param_index);
  threshold := Get_scalar_param(param_index);
  capping := Get_boolean_param(param_index);
  smoothing := Get_boolean_param(param_index);

  {***************************}
  { get array sizes from heap }
  {***************************}
  density_length := Array_num(density_handle, 2);
  density_width := Array_num(density_handle, 1);
  density_height := Array_num(density_handle, 0);

  vertex_length := Array_num(vertex_handle, 2);
  vertex_width := Array_num(vertex_handle, 1);
  vertex_height := Array_num(vertex_handle, 0);

  {*******************}
  { check array sizes }
  {*******************}
  if (vertex_length <> 0) then
    if (vertex_length <> density_length) then
      Runtime_error('Volume vertex array length does not match density array length.');
  if (vertex_width <> 0) then
    if (vertex_width <> density_width) then
      Runtime_error('Volume vertex array width does not match density array width.');
  if (vertex_height <> 0) then
    if (vertex_height <> density_height) then
      Runtime_error('Volume vertex array height does not match density array height.');

  {************************************}
  { get volume density data from stack }
  {************************************}
  volume_size := density_length * density_width * density_height;
  volume_ptr := New_volume(threshold, capping, smoothing);
  if (volume_size <> 0) then
    begin
      volume_ptr^.density_array_ptr := New_density_array(density_length,
        density_width, density_height);
      density_ptr := volume_ptr^.density_array_ptr^.density_ptr;
      density_index := Get_handle_heap_index(density_handle, 1);
      for counter := 0 to (volume_size - 1) do
        begin
          density_ptr^ := Get_handle_scalar(density_handle, density_index +
            counter);
          density_ptr := density_ptr_type(longint(density_ptr) +
            sizeof(density_type));
        end;

      {***************************}
      { read optional vertex data }
      {***************************}
      if (vertex_handle <> 0) then
        begin
          volume_ptr^.point_array_ptr := New_point_array(vertex_length,
            vertex_width, vertex_height);
          point_ptr := volume_ptr^.point_array_ptr^.point_ptr;
          vertex_index := Get_handle_heap_index(vertex_handle, 1);
          for counter := 1 to volume_size do
            begin
              point_ptr^ := Get_handle_vector(vertex_handle, vertex_index);
              vertex_index := vertex_index + 3;
              point_ptr := vector_ptr_type(longint(point_ptr) +
                sizeof(vector_type));
            end;
        end;
    end;

  {**************************}
  { get global default color }
  {**************************}
  volume_color := Get_global_color(native_volume_color_index);

  Exec_volume := Init_volume(volume_ptr);
end; {function Exec_volume}


{*********************}
{ lighting primitives }
{*********************}


function Exec_distant_light: object_inst_ptr_type;
var
  param_index: stack_index_type;
  direction: vector_type;
  brightness: real;
  color: color_type;
  attributes: object_attributes_type;
  shadows: boolean;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  direction := Get_vector_param(param_index);
  brightness := Get_scalar_param(param_index);
  color := Get_color_param(param_index);
  shadows := Get_boolean_param(param_index);

  Get_attributes_stack(model_attr_stack_ptr, attributes);
  Set_color_attributes(attributes, color);
  Set_attributes_stack(model_attr_stack_ptr, attributes);

  Exec_distant_light := Init_distant_light(direction, brightness, shadows);
end; {function Exec_distant_light}


function Exec_point_light: object_inst_ptr_type;
var
  param_index: stack_index_type;
  brightness: real;
  color: color_type;
  attributes: object_attributes_type;
  shadows: boolean;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  brightness := Get_scalar_param(param_index);
  color := Get_color_param(param_index);
  shadows := Get_boolean_param(param_index);

  Get_attributes_stack(model_attr_stack_ptr, attributes);
  Set_color_attributes(attributes, color);
  Set_attributes_stack(model_attr_stack_ptr, attributes);

  Exec_point_light := Init_point_light(brightness, shadows);
end; {function Exec_point_light}


function Exec_spot_light: object_inst_ptr_type;
var
  param_index: stack_index_type;
  direction: vector_type;
  brightness: real;
  angle: real;
  color: color_type;
  attributes: object_attributes_type;
  shadows: boolean;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  direction := Get_vector_param(param_index);
  brightness := Get_scalar_param(param_index);
  angle := Get_scalar_param(param_index);
  color := Get_color_param(param_index);
  shadows := Get_boolean_param(param_index);

  Get_attributes_stack(model_attr_stack_ptr, attributes);
  Set_color_attributes(attributes, color);
  Set_attributes_stack(model_attr_stack_ptr, attributes);

  Exec_spot_light := Init_spot_light(direction, brightness, angle, shadows);
end; {function Exec_spot_light}


{*********************}
{ clipping primitives }
{*********************}


function Exec_clipping_plane: object_inst_ptr_type;
var
  param_index: stack_index_type;
  origin: vector_type;
  normal: vector_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  origin := Get_vector_param(param_index);
  normal := Get_vector_param(param_index);

  Exec_clipping_plane := Init_clipping_plane(origin, normal);
end; {function Exec_clipping_plane}


{************************************************************}
{ routine to switch between and execute native model methods }
{************************************************************}


procedure Exec_native_model_method(kind: native_model_method_kind_type);
begin
  case kind of

    {**********}
    { quadrics }
    {**********}
    native_sphere:
      native_object_inst_ptr := Exec_sphere;
    native_cylinder:
      native_object_inst_ptr := Exec_cylinder;
    native_cone:
      native_object_inst_ptr := Exec_cone;
    native_paraboloid:
      native_object_inst_ptr := Exec_paraboloid;
    native_hyperboloid1:
      native_object_inst_ptr := Exec_hyperboloid1;
    native_hyperboloid2:
      native_object_inst_ptr := Exec_hyperboloid2;

    {*******************}
    { planar primitives }
    {*******************}
    native_plane:
      native_object_inst_ptr := Exec_plane;
    native_disk:
      native_object_inst_ptr := Exec_disk;
    native_ring:
      native_object_inst_ptr := Exec_ring;
    native_triangle:
      native_object_inst_ptr := Exec_triangle;
    native_parallelogram:
      native_object_inst_ptr := Exec_parallelogram;
    native_polygon:
      native_object_inst_ptr := Exec_polygon;

    {***********************}
    { non-planar primitives }
    {***********************}
    native_torus:
      native_object_inst_ptr := Exec_torus;
    native_block:
      native_object_inst_ptr := Exec_block;
    native_shaded_triangle:
      native_object_inst_ptr := Exec_shaded_triangle;
    native_shaded_polygon:
      native_object_inst_ptr := Exec_shaded_polygon;
    native_mesh:
      native_object_inst_ptr := Exec_mesh;
    native_blob:
      native_object_inst_ptr := Exec_blob;

    {************************}
    { non-surface primitives }
    {************************}
    native_points:
      native_object_inst_ptr := Exec_points;
    native_line:
      native_object_inst_ptr := Exec_line;
    native_volume:
      native_object_inst_ptr := Exec_volume;

    {*********************}
    { clipping primitives }
    {*********************}
    native_clipping_plane:
      native_object_inst_ptr := Exec_clipping_plane;

    {*********************}
    { lighting primitives }
    {*********************}
    native_distant_light:
      native_object_inst_ptr := Exec_distant_light;
    native_point_light:
      native_object_inst_ptr := Exec_point_light;
    native_spot_light:
      native_object_inst_ptr := Exec_spot_light;

    {***********************************}
    { modeling transformation functions }
    {***********************************}
    native_trans_level:
      Eval_trans_level;
    native_transform_point:
      Eval_transform_point;
    native_transform_vector:
      Eval_transform_vector;

  end; {case}
end; {procedure Exec_native_model_method}


end.
