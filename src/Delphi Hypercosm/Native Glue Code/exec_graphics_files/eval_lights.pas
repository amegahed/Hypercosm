unit eval_lights;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            eval_lights                3d       }
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
  colors, vectors, object_attr, lighting;


{*********************************}
{ routines for computing lighting }
{*********************************}
function Diffuse_illumination(attributes: object_attributes_type): color_type;
function Specular_illumination(attributes: object_attributes_type;
  specularity: real): color_type;

{***************************************}
{ functions employing shader evaluation }
{***************************************}
function Get_shadow_light_intensity(light_ptr: light_ptr_type;
  location: vector_type): color_type;


implementation
uses
  constants, math_utils, rays, trans, coord_axes, stmts, coord_stack, eye,
  state_vars, coords, raytrace, walk_voxels, intersect, physics, normals,
  shading, luxels, get_stack_data, set_stack_data, op_stacks,
  assign_native_render, eval_shaders;


const
  debug = true;


function Trace_shadow_ray(ray: ray_type;
  light: color_type;
  distance: real): color_type;
var
  ambient_color: color_type;
begin
  {********************************************}
  { set ambient color to black for shadow rays }
  {********************************************}
  ambient_color := Get_global_color(native_ambient_color_index);
  Set_global_color(native_ambient_color_index, black_color);

  Save_shader_state;
  ray_kind := shadow_ray;
  current_ray_weight := light;
  light := Trace_secondary_ray(ray, tiny, distance, current_source_obj);
  Restore_shader_state;

  {***********************}
  { restore ambient color }
  {***********************}
  Set_global_color(native_ambient_color_index, ambient_color);

  Trace_shadow_ray := light;
end; {function Trace_shadow_ray}


function Get_shadow_light_intensity(light_ptr: light_ptr_type;
  location: vector_type): color_type;
var
  ray: ray_type;
  distance: real;
  direction: vector_type;
  intensity: color_type;
begin
  if (light_ptr <> nil) then
    begin
      if light_ptr^.light_cache.shadow_intensity_found then
        begin
          {********************************}
          { lookup cached shadow intensity }
          {********************************}
          intensity := light_ptr^.light_cache.shadow_intensity;
        end
      else
        begin
          {*********************************************}
          { compute intensity before shadow attenuation }
          {*********************************************}
          intensity := Get_light_intensity(light_ptr, location);

          {******************}
          { trace shadow ray }
          {******************}
          direction := Get_light_direction(light_ptr, location);
          distance := Get_light_distance(light_ptr, location);

          ray.location := location;
          ray.direction := direction;
          intensity := Trace_shadow_ray(ray, intensity, distance);

          {*****************}
          { cache intensity }
          {*****************}
          light_ptr^.light_cache.shadow_intensity_found := true;
          light_ptr^.light_cache.shadow_intensity := intensity;
        end;
    end
  else
    intensity := black_color;

  Get_shadow_light_intensity := intensity;
end; {function Get_shadow_light_intensity}


function Diffuse_illumination(attributes: object_attributes_type): color_type;
var
  location, normal: vector_type;
  intensity, illumination: color_type;
  flux: real;
  counter: integer;
  do_shadows: boolean;
  light_ptr: light_ptr_type;
begin
  location := Get_location(world_coords);
  normal := Get_normal(world_coords);

  {***************************************}
  { find sum illumination from all lights }
  {***************************************}
  if attributes.valid[shadow_attributes] then
    do_shadows := shadows and attributes.shadows
  else
    do_shadows := shadows;

  illumination := black_color;
  for counter := 1 to Get_light_number do
    begin
      light_ptr := Index_light(counter);
      flux := Dot_product(normal, Get_light_direction(light_ptr, location));
      if flux > 0 then
        begin
          if Get_light_shadows(light_ptr) and do_shadows then
            intensity := Get_shadow_light_intensity(light_ptr, location)
          else
            intensity := Get_light_intensity(light_ptr, location);
          illumination := Mix_color(illumination, Intensify_color(intensity,
            flux));
        end;
    end;

  Diffuse_illumination := illumination;
end; {function Diffuse_illumination}


function Specular_illumination(attributes: object_attributes_type;
  specularity: real): color_type;
var
  mirror_direction: vector_type;
  location, normal: vector_type;
  direction, light_direction: vector_type;
  intensity, illumination: color_type;
  alpha, flux: real;
  counter: integer;
  do_shadows: boolean;
  light_ptr: light_ptr_type;
begin
  location := Get_location(world_coords);
  normal := Get_normal(world_coords);
  direction := Get_direction(world_coords);

  {***************************************}
  { find sum illumination from all lights }
  {***************************************}
  if attributes.valid[shadow_attributes] then
    do_shadows := shadows and attributes.shadows
  else
    do_shadows := shadows;

  mirror_direction := Reflect(direction, normal);

  illumination := black_color;
  for counter := 1 to Get_light_number do
    begin
      light_ptr := Index_light(counter);
      light_direction := Get_light_direction(light_ptr, location);
      flux := Dot_product(normal, light_direction);
      alpha := Dot_product(light_direction, mirror_direction);

      if (flux > 0) and (alpha > 0) then
        begin
          if Get_light_shadows(light_ptr) and do_shadows then
            intensity := Get_shadow_light_intensity(light_ptr, location)
          else
            intensity := Get_light_intensity(light_ptr, location);

          flux := flux * Power(alpha, specularity);
          illumination := Mix_color(illumination, Intensify_color(intensity,
            flux));
        end;
    end;

  Specular_illumination := illumination;
end; {function Specular_illumination}


end.
