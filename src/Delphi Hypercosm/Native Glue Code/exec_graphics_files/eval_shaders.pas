unit eval_shaders;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            eval_shaders               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines for evaluating            }
{       primitive shaders.                                      }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  rays, trans, colors, materials, object_attr, raytrace;


{***********************************************}
{ routines for general surface color evaluation }
{***********************************************}
function Eval_surface_color(attributes: object_attributes_type;
  source_obj: hierarchical_object_type): color_type;

{**************************************************}
{ routines for particular surface color evaluation }
{**************************************************}
function Eval_shader_color(shader_ptr: shader_ptr_type;
  source_obj: hierarchical_object_type): color_type;
function Eval_material_color(material_ptr: material_ptr_type;
  source_obj: hierarchical_object_type): color_type;
function Eval_lambertian_color(color: color_type;
  source_obj: hierarchical_object_type): color_type;

{***************************************}
{ functions employing shader evaluation }
{***************************************}
function Trace_secondary_ray(var ray: ray_type;
  Tmin, Tmax: real;
  source_obj: hierarchical_object_type): color_type;


implementation
uses
  constants, math_utils, vectors, coord_axes, stmts, coord_stack, eye,
  state_vars, coords, walk_voxels, intersect, physics, normals, shading, luxels,
  get_stack_data, set_stack_data, op_stacks, assign_native_render, eval_lights,
  exec_stmts;


const
  debug = true;


  {***********************************************}
  { routines for general surface color evaluation }
  {***********************************************}


function Eval_surface_color(attributes: object_attributes_type;
  source_obj: hierarchical_object_type): color_type;
var
  color: color_type;
begin
  current_attributes := attributes;
  current_source_obj := source_obj;

  if attributes.shader_ptr <> shader_ptr_type(nil) then
    color := Eval_shader_color(attributes.shader_ptr, source_obj)
  else if attributes.material_ptr <> nil then
    color := Eval_material_color(attributes.material_ptr, source_obj)
  else
    color := Eval_lambertian_color(attributes.color, source_obj);

  Eval_surface_color := color;
end; {function Eval_surface_color}


{**************************************************}
{ routines for particular surface color evaluation }
{**************************************************}


function Eval_shader_color(shader_ptr: shader_ptr_type;
  source_obj: hierarchical_object_type): color_type;
var
  distance: real;
  color: color_type;
begin
  if refraction_level = 0 then
    begin
      shader_t := 0;
      ray_inside := false;
      shader_tmax := infinity;
    end;

  current_source_obj := source_obj;
  Interpret_stmt(stmt_ptr_type(shader_ptr));
  color := Pop_color_operand;

  {***********}
  { apply fog }
  {***********}
  if (fog_factor <> 0) then
    begin
      distance := Get_distance;
      color := Fog(color, background_color, distance, fog_factor);
    end;

  Eval_shader_color := color;
end; {function Eval_shader_color}


function Eval_material_color(material_ptr: material_ptr_type;
  source_obj: hierarchical_object_type): color_type;
var
  color, illumination, highlight: color_type;
  location: vector_type;
  distance: real;
begin
  case ray_kind of

    shadow_ray:
      color := black_color;

    shader_ray:
      begin
        {***************************}
        { simple lambertian shading }
        {***************************}
        if not Equal_color(material_ptr^.diffuse, black_color) then
          begin
            illumination := Diffuse_illumination(current_attributes);
            color := Filter_color(illumination, material_ptr^.diffuse);
          end
        else
          color := black_color;

        {*********************}
        { specular highlights }
        {*********************}
        if material_ptr^.specular_power <> 0 then
          begin
            highlight := Specular_illumination(current_attributes,
              material_ptr^.specular_power);
            color := Mix_color(color, Filter_color(highlight,
              material_ptr^.specular));
          end;

        {**********************}
        { specular reflections }
        {**********************}
        if not Equal_color(material_ptr^.reflected, black_color) then
          begin
            current_source_obj := source_obj;
            color := Mix_color(color,
              Reflected_ray_color(material_ptr^.reflected));
          end;

        {*************************}
        { transmitted refractions }
        {*************************}
        if not Equal_color(material_ptr^.transmitted, black_color) then
          begin
            current_source_obj := source_obj;
            color := Mix_color(color, Refracted_ray_color(1,
              material_ptr^.transmitted));
          end;

        {***************}
        { ambient color }
        {***************}
        if not Equal_color(material_ptr^.ambient, black_color) then
          color := Mix_color(color, Filter_color(ambient_color,
            material_ptr^.ambient));

        {****************}
        { emissive color }
        {****************}
        if not Equal_color(material_ptr^.emissive, black_color) then
          color := Mix_color(color, material_ptr^.emissive);

        {***********}
        { apply fog }
        {***********}
        if (fog_factor <> 0) then
          begin
            location := Get_location(world_coords);
            distance := Vector_length(Vector_difference(eye_point, location));
            color := Fog(color, background_color, distance, fog_factor);
          end;
      end;

  end; {case}

  Eval_material_color := color;
end; {function Eval_material_color}


function Eval_lambertian_color(color: color_type;
  source_obj: hierarchical_object_type): color_type;
var
  location: vector_type;
  illumination: color_type;
  distance: real;
begin
  case ray_kind of

    shadow_ray:
      color := black_color;

    shader_ray:
      begin
        current_source_obj := source_obj;
        illumination := Diffuse_illumination(current_attributes);

        {***************************}
        { simple lambertian shading }
        {***************************}
        color := Filter_color(color, Mix_color(illumination, ambient_color));

        {***********}
        { apply fog }
        {***********}
        if (fog_factor <> 0) then
          begin
            location := Get_location(world_coords);
            distance := Vector_length(Vector_difference(eye_point, location));
            color := Fog(color, background_color, distance, fog_factor);
          end;
      end;

  end; {case}

  Eval_lambertian_color := color;
end; {function Eval_lambertian_color}


{***************************************}
{ functions employing shader evaluation }
{***************************************}


function Trace_secondary_ray(var ray: ray_type;
  Tmin, Tmax: real;
  source_obj: hierarchical_object_type): color_type;
var
  color: color_type;
  obj: hierarchical_object_type;
  object_ptr: ray_object_inst_ptr_type;
  global_point, local_point, normal: vector_type;
  coord_stack_ptr, normal_stack_ptr: coord_stack_ptr_type;
  shader_axes, normal_shader_axes: coord_axes_type;
  previous_lighting_mode: lighting_mode_type;
  shader_height: integer;
  t: real;
begin
  t := Secondary_ray_intersection(ray, Tmin, Tmax, obj, source_obj);
  if t = infinity then
    begin
      case ray_kind of
        shadow_ray:
          color := current_ray_weight;
        shader_ray:
          color := background_color;
      end;
    end
  else
    begin
      {***************************************}
      { calculate point and normal of surface }
      {***************************************}
      global_point := Vector_sum(ray.location, Vector_scale(ray.direction, t));
      local_point := Vector_sum(closest_local_ray.location,
        Vector_scale(closest_local_ray.direction, t));
      normal := Find_surface_normal(obj.object_ptr, local_point);
      shader_t := t;

      {*******************}
      { calculate shading }
      {*******************}
      Inval_coords;
      previous_lighting_mode := Get_lighting_mode;
      Convert_hierarchical_object(obj, object_ptr);
      Create_coord_stack(obj, coord_stack_ptr, normal_stack_ptr, shader_height,
        shader_axes, normal_shader_axes);
      Set_coord_stack_data(coord_stack_ptr, normal_stack_ptr, shader_height);
      Set_shader_to_object(shader_axes, normal_shader_axes);
      Set_ray_object(object_ptr);
      Set_lighting_mode(two_sided);

      {*****************************}
      { set data required by shader }
      {*****************************}
      Set_location(global_point, world_coords);
      Set_location(local_point, primitive_coords);
      Set_normal(normal, primitive_coords);
      Set_direction(ray.direction, world_coords);
      Set_distance(t);

      {*****************}
      { evaluate shader }
      {*****************}
      if ray_kind = shader_ray then
        Set_lighting_point(global_point);
      color := Eval_surface_color(object_ptr^.attributes, obj);
      Set_lighting_mode(previous_lighting_mode);
    end;

  Trace_secondary_ray := color;
end; {function Trace_secondary_ray}


end.
