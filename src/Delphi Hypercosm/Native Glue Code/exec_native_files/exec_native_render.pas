unit exec_native_render;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm         exec_native_render            3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is responsible for executing native         }
{       rendering methods.                                      }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  native_render;


{****************************************************************}
{ routine to switch between and execute native rendering methods }
{****************************************************************}
procedure Exec_native_render_method(kind: native_render_method_kind_type);


implementation
uses
  constants, strings, vectors, vectors2, rays, trans, pixels, colors,
  pixel_colors, images, state_vars, addr_types, data_types, code_types, exprs,
  stmts, code_decls, image_files, textures, object_attr, coords, shading,
  physics, lighting, luxels, get_data, get_params, get_heap_data, set_heap_data,
  op_stacks, assign_native_render, eval_lights, eval_shaders, interpreter;


var
  object_stmt_ptr: stmt_ptr_type;
  object_code_ptr: code_ptr_type;

  picture_stmt_ptr: stmt_ptr_type;
  picture_code_ptr: code_ptr_type;


{*******************}
{ shader primitives }
{*******************}


function Shader_coord_kind_to_coord_kind(kind: shader_coord_kind_type):
  coord_kind_type;
var
  coord_kind: coord_kind_type;
begin
  case kind of
    display_shader:
      coord_kind := display_coords;
    screen_shader:
      coord_kind := screen_coords;
    camera_shader:
      coord_kind := camera_coords;
    world_shader:
      coord_kind := world_coords;
    local_shader:
      coord_kind := shader_coords;
    surface_shader:
      coord_kind := surface_coords;
    parametric_shader:
      coord_kind := parametric_coords;
  else
    coord_kind := parametric_coords;
  end;

  Shader_coord_kind_to_coord_kind := coord_kind;
end; {function Shader_coord_kind_to_coord_kind}


procedure Eval_location;
var
  param_index: stack_index_type;
  shader_coord_kind: shader_coord_kind_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  shader_coord_kind :=
    shader_coord_kind_index_array[Get_integer_param(param_index)];

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_vector_operand(Get_location(Shader_coord_kind_to_coord_kind(shader_coord_kind)));
end; {procedure Eval_location}


procedure Eval_normal;
var
  param_index: stack_index_type;
  shader_coord_kind: shader_coord_kind_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  shader_coord_kind :=
    shader_coord_kind_index_array[Get_integer_param(param_index)];

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_vector_operand(Get_normal(Shader_coord_kind_to_coord_kind(shader_coord_kind)));
end; {procedure Eval_normal}


procedure Eval_direction;
var
  param_index: stack_index_type;
  shader_coord_kind: shader_coord_kind_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  shader_coord_kind :=
    shader_coord_kind_index_array[Get_integer_param(param_index)];

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_vector_operand(Get_direction(Shader_coord_kind_to_coord_kind(shader_coord_kind)));
end; {procedure Eval_direction}


procedure Eval_distance;
begin
  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_scalar_operand(Get_distance);
end; {procedure Eval_distance}


{******************************************}
{ displacement and bump mapping primitives }
{******************************************}


procedure Exec_set_location;
var
  param_index: stack_index_type;
  shader_coord_kind: shader_coord_kind_type;
  location: vector_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  shader_coord_kind :=
    shader_coord_kind_index_array[Get_integer_param(param_index)];
  location := Get_vector_param(param_index);

  Inval_location;
  Set_location(location, Shader_coord_kind_to_coord_kind(shader_coord_kind));
end; {procedure Exec_set_location}


procedure Exec_set_normal;
var
  param_index: stack_index_type;
  shader_coord_kind: shader_coord_kind_type;
  normal: vector_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  shader_coord_kind :=
    shader_coord_kind_index_array[Get_integer_param(param_index)];
  normal := Get_vector_param(param_index);

  Inval_normal;
  Set_normal(normal, Shader_coord_kind_to_coord_kind(shader_coord_kind));
end; {procedure Exec_set_normal}


procedure Exec_set_direction;
var
  param_index: stack_index_type;
  shader_coord_kind: shader_coord_kind_type;
  direction: vector_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  shader_coord_kind :=
    shader_coord_kind_index_array[Get_integer_param(param_index)];
  direction := Get_vector_param(param_index);

  Inval_direction;
  Set_direction(direction, Shader_coord_kind_to_coord_kind(shader_coord_kind));
end; {procedure Exec_set_direction}


procedure Exec_set_distance;
var
  param_index: stack_index_type;
  distance: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  distance := Get_scalar_param(param_index);

  Inval_distance;
  Set_distance(distance);
end; {procedure Exec_set_distance}


{*************************}
{ illumination primitives }
{*************************}


procedure Eval_light_number;
var
  number: integer;
begin
  number := 0;

  if rendering then
    case ray_kind of
      shadow_ray:
        number := 0;
      shader_ray:
        number := Get_light_number;
    end
  else
    Runtime_error('Can not call a shader directly.');

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_integer_operand(number);
end; {procedure Eval_light_number}


procedure Eval_light_direction;
var
  param_index: stack_index_type;
  light_ptr: light_ptr_type;
  location, direction: vector_type;
  index: integer;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  index := Get_integer_param(param_index);

  if rendering then
    case ray_kind of
      shadow_ray:
        direction := zero_vector;
      shader_ray:
        begin
          location := Get_location(world_coords);
          light_ptr := Index_light(index);
          direction := Get_light_direction(light_ptr, location);
        end;
    end {case}
  else
    Runtime_error('Can not call a shader directly.');

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_vector_operand(direction);
end; {procedure Eval_light_direction}


procedure Eval_light_intensity;
var
  param_index: stack_index_type;
  light_ptr: light_ptr_type;
  location, normal: vector_type;
  light: color_type;
  index: integer;
  do_shadows: boolean;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  index := Get_integer_param(param_index);

  if rendering then
    case ray_kind of

      shadow_ray:
        light := black_color;

      shader_ray:
        begin
          location := Get_location(world_coords);
          normal := Get_normal(world_coords);
          light_ptr := Index_light(index);

          if current_attributes.valid[shadow_attributes] then
            do_shadows := shadows and current_attributes.shadows
          else
            do_shadows := shadows;

          if Get_light_shadows(light_ptr) and do_shadows then
            light := Get_shadow_light_intensity(light_ptr, location)
          else
            light := Get_light_intensity(light_ptr, location);
        end;

    end {case}
  else
    Runtime_error('Can not call a shader directly.');

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_color_operand(light);
end; {procedure Eval_light_intensity}


{*********************}
{ lighting primitives }
{*********************}


procedure Eval_diffuse;
begin
  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_color_operand(Diffuse_illumination(current_attributes));
end; {procedure Eval_diffuse}


procedure Eval_specular;
var
  param_index: stack_index_type;
  specularity: real;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  specularity := Get_scalar_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_color_operand(Specular_illumination(current_attributes, specularity));
end; {procedure Eval_specular}


{************************}
{ ray tracing primitives }
{************************}


procedure Eval_ray_inside;
begin
  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_boolean_operand(ray_inside);
end; {procedure Eval_ray_inside}


procedure Eval_shadow_ray;
begin
  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_boolean_operand(ray_kind = shadow_ray);
end; {procedure Eval_shadow_ray}


procedure Eval_reflection_level;
begin
  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_integer_operand(reflection_level);
end; {procedure Eval_reflection_level}


procedure Eval_refraction_level;
begin
  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_integer_operand(refraction_level);
end; {procedure Eval_refraction_level}


procedure Eval_reflect;
var
  param_index: stack_index_type;
  color: color_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  color := Get_color_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_color_operand(Reflected_ray_color(color));
end; {procedure Eval_reflect}


procedure Eval_refract;
var
  param_index: stack_index_type;
  index_of_refraction: real;
  color: color_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  index_of_refraction := Get_scalar_param(param_index);
  color := Get_color_param(param_index);

  {************************************}
  { push return value to operand stack }
  {************************************}
  Push_color_operand(Refracted_ray_color(index_of_refraction, color));
end; {procedure Eval_refract}


{****************************}
{ texture mapping primitives }
{****************************}


procedure Exec_new_texture;
var
  param_index: stack_index_type;
  memref, image_memref: memref_type;
  interpolation, mipmapping, wraparound: boolean;
  image_ptr: image_ptr_type;
  texture_ptr: texture_ptr_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  memref := Get_memref_param(param_index);
  image_memref := Get_memref_param(param_index);
  interpolation := Get_boolean_param(param_index);
  mipmapping := Get_boolean_param(param_index);
  wraparound := Get_boolean_param(param_index);

  {**************************************}
  { get native image from image instance }
  {**************************************}
  if image_memref <> 0 then
    begin
      image_ptr := image_ptr_type(Get_memref_long(image_memref, 2));
      texture_ptr := New_texture(image_ptr, interpolation, mipmapping,
        wraparound);
    end
  else
    texture_ptr := nil;

  {**************************************}
  { store window data in object instance }
  {**************************************}
  Set_memref_long(memref, 2, long_type(texture_ptr));
end; {procedure Exec_new_texture}


procedure Exec_free_texture;
var
  param_index: stack_index_type;
  memref: memref_type;
  texture_ptr: texture_ptr_type;
begin
  {**********************}
  { get local parameters }
  {**********************}
  param_index := 1;
  memref := Get_memref_param(param_index);

  {*********************}
  { free native texture }
  {*********************}
  texture_ptr := texture_ptr_type(Get_memref_long(memref, 2));
  Free_texture(texture_ptr);
end; {procedure Exec_free_texture}


{****************************************************************}
{ routine to switch between and execute native rendering methods }
{****************************************************************}


procedure Exec_native_render_method(kind: native_render_method_kind_type);
begin
  case kind of

    {*******************}
    { shader primitives }
    {*******************}
    native_location:
      Eval_location;
    native_normal:
      Eval_normal;
    native_direction:
      Eval_direction;
    native_distance:
      Eval_distance;

    {******************************************}
    { displacement and bump mapping primitives }
    {******************************************}
    native_set_location:
      Exec_set_location;
    native_set_normal:
      Exec_set_normal;
    native_set_direction:
      Exec_set_direction;
    native_set_distance:
      Exec_set_distance;

    {*************************}
    { illumination primitives }
    {*************************}
    native_light_number:
      Eval_light_number;
    native_light_direction:
      Eval_light_direction;
    native_light_intensity:
      Eval_light_intensity;

    {*********************}
    { lighting primitives }
    {*********************}
    native_diffuse:
      Eval_diffuse;
    native_specular:
      Eval_specular;

    {************************}
    { ray tracing primitives }
    {************************}
    native_ray_inside:
      Eval_ray_inside;
    native_shadow_ray:
      Eval_shadow_ray;
    native_reflection_level:
      Eval_reflection_level;
    native_refraction_level:
      Eval_refraction_level;
    native_reflect:
      Eval_reflect;
    native_refract:
      Eval_refract;

    {****************************}
    { texture mapping primitives }
    {****************************}
    native_new_texture:
      Exec_new_texture;
    native_free_texture:
      Exec_free_texture;
  end; {case}
end; {procedure Exec_native_render_method}


initialization
  {********************}
  { create object code }
  {********************}
  object_code_ptr := New_code(object_code, nil);
  object_code_ptr^.decl_kind := proto_decl;

  {********************}
  { create object stmt }
  {********************}
  object_stmt_ptr := New_stmt(proto_method_stmt);
  object_stmt_ptr^.stmt_name_ptr := New_expr(local_identifier);
  object_stmt_ptr^.stmt_name_ptr^.stack_index := 1;
  object_stmt_ptr^.stmt_code_ref := forward_code_ref_type(object_code_ptr);

  {*********************}
  { create picture code }
  {*********************}
  picture_code_ptr := New_code(picture_code, nil);
  picture_code_ptr^.decl_kind := proto_decl;

  {*********************}
  { create picture stmt }
  {*********************}
  picture_stmt_ptr := New_stmt(proto_method_stmt);
  picture_stmt_ptr^.stmt_name_ptr := New_expr(local_identifier);
  picture_stmt_ptr^.stmt_name_ptr^.stack_index := 1;
  picture_stmt_ptr^.stmt_code_ref := forward_code_ref_type(picture_code_ptr);
end.
