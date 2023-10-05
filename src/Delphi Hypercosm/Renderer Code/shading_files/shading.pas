unit shading;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              shading                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The shading module is used to keep track of data        }
{       used by the shading language.                           }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, colors, object_attr, topology, raytrace;


type
  {*******************}
  { shader state info }
  {*******************}
  ray_kind_type = (shader_ray, shadow_ray);


var
  {*****************}
  { ray tree height }
  {*****************}
  reflection_level: integer;
  refraction_level: integer;

  {***********************************************************}
  { these values indicate the state that a shader is executed }
  { in. They are needed to indicate the origin of the ray so  }
  { objects don't shadow themselves and the weight of the ray }
  { so unimportant ray trees are terminated quickly. Also the }
  { height of the stack prevents the possibility of infinite  }
  { recursion and stack overflow, such as between two mirrors }
  {***********************************************************}
  shader_stack_ptr: integer;
  current_source_obj: hierarchical_object_type;
  current_attributes: object_attributes_type;
  current_ray_weight: color_type;
  ray_kind: ray_kind_type;
  shader_t, shader_tmax: real;


{*******************************************************}
{ routines to save and restore the current shader state }
{*******************************************************}
procedure Save_shader_state;
procedure Restore_shader_state;

{***********************************}
{ routines for tracing shading rays }
{***********************************}
function Reflected_ray_color(color: color_type): color_type;
function Refracted_ray_color(index_of_refraction: real;
  color: color_type): color_type;

{*********************}
{ diagnostic routines }
{*********************}
procedure Write_ray_kind(ray_kind: ray_kind_type);


implementation
uses
  errors, constants, rays, state_vars, coords, physics, eval_shaders;


const
  shader_stack_size = 256;


type
  {*************************}
  { shader stack data types }
  {*************************}


  shader_data_type = record
    {***********************}
    { global shading coords }
    {***********************}
    location: vector_type;
    normal: vector_type;
    direction: vector_type;
    distance: real;

    {************************************}
    { misc data needed before firing ray }
    {************************************}
    source_obj: hierarchical_object_type;
    source_face_ptr: face_ptr_type;
    source_point_ptr: point_ptr_type;
    ray_weight: color_type;
    ray_kind: ray_kind_type;
    ray_inside: boolean;
    shader_t, shader_tmax: real;
  end;


  shader_stack_ptr_type = ^shader_stack_type;
  shader_stack_type = array[1..shader_stack_size] of shader_data_type;


var
  shader_stack: shader_stack_ptr_type;


procedure Save_shader_state;
begin
  if (shader_stack_ptr < shader_stack_size) then
    begin
      {****************}
      { shading coords }
      {****************}
      shader_stack^[shader_stack_ptr].location := Get_location(world_coords);
      shader_stack^[shader_stack_ptr].normal := Get_normal(world_coords);
      shader_stack^[shader_stack_ptr].direction := Get_direction(world_coords);
      shader_stack^[shader_stack_ptr].distance := Get_distance;

      {************************************}
      { misc data needed before firing ray }
      {************************************}
      shader_stack^[shader_stack_ptr].ray_kind := ray_kind;
      shader_stack^[shader_stack_ptr].ray_weight := current_ray_weight;
      shader_stack^[shader_stack_ptr].source_obj := current_source_obj;
      shader_stack^[shader_stack_ptr].source_face_ptr := source_face_ptr;
      shader_stack^[shader_stack_ptr].source_point_ptr := source_point_ptr;
      shader_stack^[shader_stack_ptr].ray_inside := ray_inside;
      shader_stack^[shader_stack_ptr].shader_t := shader_t;
      shader_stack^[shader_stack_ptr].shader_tmax := shader_tmax;
      shader_stack_ptr := shader_stack_ptr + 1;
    end
  else
    Error('shader stack overflow');
end; {procedure Save_shader_state}


procedure Restore_shader_state;
begin
  if (shader_stack_ptr > 0) then
    begin
      shader_stack_ptr := shader_stack_ptr - 1;

      {****************}
      { shading coords }
      {****************}
      Inval_coords;
      Set_location(shader_stack^[shader_stack_ptr].location, world_coords);
      Set_normal(shader_stack^[shader_stack_ptr].normal, world_coords);
      Set_direction(shader_stack^[shader_stack_ptr].direction, world_coords);
      Set_distance(shader_stack^[shader_stack_ptr].distance);

      {************************************}
      { misc data needed before firing ray }
      {************************************}
      ray_kind := shader_stack^[shader_stack_ptr].ray_kind;
      current_ray_weight := shader_stack^[shader_stack_ptr].ray_weight;
      current_source_obj := shader_stack^[shader_stack_ptr].source_obj;
      source_face_ptr := shader_stack^[shader_stack_ptr].source_face_ptr;
      source_point_ptr := shader_stack^[shader_stack_ptr].source_point_ptr;
      ray_inside := shader_stack^[shader_stack_ptr].ray_inside;
      shader_t := shader_stack^[shader_stack_ptr].shader_t;
      shader_tmax := shader_stack^[shader_stack_ptr].shader_tmax;
    end
  else
    Error('shader stack underflow');
end; {procedure Restore_shader_state}


{***********************************}
{ routines for tracing shading rays }
{***********************************}


function Reflected_ray_color(color: color_type): color_type;
var
  reflected_color: color_type;
  do_reflections: boolean;
  location, normal, direction: vector_type;
  ray: ray_type;
begin
  if rendering then
    case ray_kind of

      shadow_ray:
        reflected_color := black_color;

      shader_ray:
        begin
          if (shader_stack_ptr = 1) then
            current_ray_weight := white_color;
          Save_shader_state;

          {****************************}
          { compute current ray weight }
          {****************************}
          current_ray_weight := Filter_color(current_ray_weight, color);

          {*****************************}
          { find color of reflected ray }
          {*****************************}
          reflected_color := background_color;

          if current_attributes.valid[reflection_attributes] then
            do_reflections := reflections and current_attributes.reflections
          else
            do_reflections := reflections;

          if do_reflections then
            if reflection_level < max_reflections then
              if Color_brightness_squared(current_ray_weight) >
                min_ray_weight_squared then
                begin
                  {***********************}
                  { compute reflected ray }
                  {***********************}
                  location := Get_location(world_coords);
                  normal := Get_normal(world_coords);
                  direction := Get_direction(world_coords);

                  ray.location := location;
                  ray.direction := Reflect(direction, normal);

                  {*********************}
                  { trace reflected ray }
                  {*********************}
                  reflection_level := reflection_level + 1;
                  reflected_color := Trace_secondary_ray(ray, tiny, shader_tmax,
                    current_source_obj);
                  reflection_level := reflection_level - 1;
                end;

          reflected_color := Filter_color(reflected_color, color);
          Restore_shader_state;
        end;
    end
  else
    reflected_color := black_color;

  Reflected_ray_color := reflected_color;
end; {function Reflected_ray_color}


function Refracted_ray_color(index_of_refraction: real;
  color: color_type): color_type;
var
  refracted_color: color_type;
  do_refractions: boolean;
  location, normal, direction: vector_type;
  ray: ray_type;
  ray_length: real;
begin
  if rendering then
    begin
      if (shader_stack_ptr = 1) then
        current_ray_weight := white_color;
      Save_shader_state;

      {****************************}
      { compute current ray weight }
      {****************************}
      current_ray_weight := Filter_color(current_ray_weight, color);

      {*****************************}
      { find color of refracted ray }
      {*****************************}
      refracted_color := background_color;

      if current_attributes.valid[refraction_attributes] then
        do_refractions := refractions and current_attributes.refractions
      else
        do_refractions := refractions;

      if do_refractions then
        if refraction_level < max_refractions then
          if Color_brightness_squared(current_ray_weight) >
            min_ray_weight_squared then
            begin
              {***********************}
              { compute refracted ray }
              {***********************}
              location := Get_location(world_coords);
              normal := Get_normal(world_coords);
              direction := Get_direction(world_coords);

              ray.location := location;
              ray.direction := direction;

              {*********************}
              { trace refracted ray }
              {*********************}
              refraction_level := refraction_level + 1;

              case ray_kind of

                shadow_ray:
                  begin
                    shader_tmax := shader_tmax - shader_t;
                    ray_inside := not ray_inside;
                  end;

                shader_ray:
                  begin
                    if (index_of_refraction <> 1) then
                      begin
                        ray_length := Vector_length(ray.direction);
                        ray.direction := Refract(ray.direction, normal,
                          index_of_refraction);
                        ray.direction := Vector_scale(Normalize(ray.direction),
                          ray_length);
                      end
                    else
                      ray_inside := not ray_inside;
                  end;

              end; {case}

              refracted_color := Trace_secondary_ray(ray, tiny, shader_tmax,
                current_source_obj);
              refraction_level := refraction_level - 1;
            end;

      refracted_color := Filter_color(refracted_color, color);
      Restore_shader_state;
    end
  else
    refracted_color := black_color;

  Refracted_ray_color := refracted_color;
end; {function Refracted_ray_color}


{*********************}
{ diagnostic routines }
{*********************}


procedure Write_ray_kind(ray_kind: ray_kind_type);
begin
  case ray_kind of
    shadow_ray:
      write('shadow_ray');
    shader_ray:
      write('shader_ray');
  end; {case}
end; {procedure Write_ray_kind}


initialization
  {*******************}
  { init shader stack }
  {*******************}
  new(shader_stack);
  shader_stack_ptr := 1;
  ray_kind := shader_ray;

  reflection_level := 0;
  refraction_level := 0;

  Init_hierarchical_obj(current_source_obj);
  current_ray_weight := white_color;
  shader_t := 0;
  shader_tmax := infinity;
end.
