unit scan;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm                scan                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The scan module is used to scan the pixels of the       }
{       screen in a variety of different ways.                  }
{                                                               }
{       The resulting picture will be the same in all cases,    }
{       but the order that the pixels are drawn is different.   }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, vectors, vectors2, colors, pixels, raytrace, drawable,
  pixel_color_buffer;


{**************************************************}
{ routines to scan images using different patterns }
{**************************************************}
procedure Linear_raytrace(drawable: drawable_type;
  pixel_color_buffer_ptr: pixel_color_buffer_ptr_type;
  scene_ptr: ray_object_inst_ptr_type);
procedure Ordered_raytrace(drawable: drawable_type;
  pixel_color_buffer_ptr: pixel_color_buffer_ptr_type;
  scene_ptr: ray_object_inst_ptr_type;
  incremental: boolean);
procedure Random_raytrace(drawable: drawable_type;
  pixel_color_buffer_ptr: pixel_color_buffer_ptr_type;
  scene_ptr: ray_object_inst_ptr_type;
  incremental: boolean);

procedure Raytrace_to_file(scene_ptr: ray_object_inst_ptr_type;
  file_name: string_type);

{*******************************************}
{ routines exported to use the raytracing   }
{ primitive operation in other applications }
{*******************************************}
procedure Set_scanning(scene_ptr: ray_object_inst_ptr_type);
function Trace_pixel(pixel: pixel_type): color_type;
function Trace_subpixel(point2: vector2_type): color_type;


implementation
uses
  errors, new_memory, constants, rays, trans, coord_axes, pixel_colors, project,
  eye, state_vars, object_attr, coord_stack, coords, intersect, normals,
  walk_voxels, luxels, make_boxels, seek_boxels, eval_shaders, system_events;


var
  scene_object_ptr: ray_object_inst_ptr_type;

  {******************************}
  { transformations to and from  }
  { world coords from eye coords }
  {******************************}
  eye_coords: coord_axes_type;
  left_eye_coords: coord_axes_type;
  right_eye_coords: coord_axes_type;
  min_pixel_size: integer;


procedure Set_scanning(scene_ptr: ray_object_inst_ptr_type);
var
  x, y, diagonal: real;
  pixel_size: integer;
begin
  {********************}
  { initialize globals }
  {********************}
  if (stereo_seperation = 0) then
    eye_coords := Trans_to_axes(eye_trans)
  else
    begin
      left_eye_coords := Trans_to_axes(left_eye_trans);
      right_eye_coords := Trans_to_axes(right_eye_trans);
    end;
  scene_object_ptr := scene_ptr;
  Set_lighting_mode(two_sided);
  Set_camera_to_world(eye_coords);

  {
  if antialiasing and (supersamples <> 0) then
    Set_ss_mode(ss_on)
  else
    Set_ss_mode(ss_off);
  }

  x := (current_projection_ptr^.projection_size.h /
    current_projection_ptr^.pixel_aspect_ratio);
  y := current_projection_ptr^.projection_size.v;
  diagonal := sqrt((x * x) + (y * y));
  pixel_size := Trunc(diagonal * min_feature_size) + 1;

  {******************************************}
  { make min pixel size nearest power of 2   }
  { to actual pixel size for block rendering }
  {******************************************}
  min_pixel_size := 1;
  while (min_pixel_size * 2 < pixel_size) do
    min_pixel_size := min_pixel_size * 2;
end; {procedure Set_scanning}


function Shade_primary_ray(ray: ray_type;
  t: real;
  obj: hierarchical_object_type): color_type;
var
  color: color_type;
  object_ptr: ray_object_inst_ptr_type;
  global_point, local_point: vector_type;
  coord_stack_ptr, normal_stack_ptr: coord_stack_ptr_type;
  shader_axes, normal_shader_axes: coord_axes_type;
  normal, direction: vector_type;
  shader_height: integer;
  distance: real;
begin
  if t = infinity then
    color := background_color
  else
    begin
      {***************************************}
      { calculate point and normal of surface }
      {***************************************}
      global_point := Vector_sum(ray.location, Vector_scale(ray.direction, t));
      local_point := Vector_sum(closest_local_ray.location,
        Vector_scale(closest_local_ray.direction, t));
      normal := Find_surface_normal(obj.object_ptr, local_point);

      {*******************}
      { calculate shading }
      {*******************}
      Convert_hierarchical_object(obj, object_ptr);
      Create_coord_stack(obj, coord_stack_ptr, normal_stack_ptr, shader_height,
        shader_axes, normal_shader_axes);
      Set_coord_stack_data(coord_stack_ptr, normal_stack_ptr, shader_height);
      Set_shader_to_object(shader_axes, normal_shader_axes);
      Set_ray_object(object_ptr);
      Set_lighting_mode(two_sided);

      direction := Normalize(Vector_difference(global_point, eye_point));
      distance := t;

      {*****************************}
      { set data required by shader }
      {*****************************}
      Inval_coords;
      Set_location(global_point, world_coords);
      Set_location(local_point, primitive_coords);
      Set_normal(normal, primitive_coords);
      Set_direction(direction, world_coords);
      Set_distance(distance);

      {*****************}
      { evaluate shader }
      {*****************}
      Set_lighting_point(global_point);
      color := Eval_surface_color(object_ptr^.attributes, obj);
    end;

  Shade_primary_ray := color;
end; {function Shade_primary_ray}


function Trace_primary_ray(ray: ray_type): color_type;
var
  t: real;
  obj: hierarchical_object_type;
begin
  ray.direction := Normalize(ray.direction);
  t := Primary_ray_intersection(ray, tiny, infinity, obj);
  Trace_primary_ray := Shade_primary_ray(ray, t, obj);
end; {function Shade_primary_ray}


function Trace_stereo(ray: ray_type): color_type;
var
  color: color_type;
  left_ray, right_ray: ray_type;
  left_ray_color, right_ray_color: color_type;
begin
  {************************}
  { transform ray from eye }
  { coords to world coords }
  {************************}
  left_ray := ray;
  Transform_point_to_axes(left_ray.location, left_eye_coords);
  Transform_vector_to_axes(left_ray.direction, left_eye_coords);

  right_ray := ray;
  Transform_point_to_axes(right_ray.location, right_eye_coords);
  Transform_vector_to_axes(right_ray.direction, right_eye_coords);

  Set_camera_to_world(left_eye_coords);
  left_ray_color := Filter_color(Trace_primary_ray(left_ray), left_color);

  Set_camera_to_world(right_eye_coords);
  right_ray_color := Filter_color(Trace_primary_ray(right_ray), right_color);

  {*************************************}
  { mix colors from left and right eyes }
  {*************************************}
  color := Mix_color(left_ray_color, right_ray_color);

  Trace_stereo := color;
end; {function Trace_stereo}


function Trace_subpixel(point2: vector2_type): color_type;
var
  color: color_type;
  ray: ray_type;
  obj: hierarchical_object_type;
  t: real;
begin
  if (boxels_made) then
    begin
      t := Trace_boxel_subpixel(point2, ray, tiny, infinity, obj);
      color := Shade_primary_ray(ray, t, obj);
    end
  else
    begin
      {*******************************************}
      { transform point to window centered coords }
      {*******************************************}
      point2.x := (point2.x - current_projection_ptr^.projection_center.x);
      point2.y := (current_projection_ptr^.projection_center.y - point2.y);

      {*************************}
      { project subpixel to ray }
      {*************************}
      ray := Project_point2_to_ray(point2);

      if stereo_seperation = 0 then
        begin
          {************************}
          { transform ray from eye }
          { coords to world coords }
          {************************}
          Transform_point_to_axes(ray.location, eye_coords);
          Transform_vector_to_axes(ray.direction, eye_coords);

          {***********}
          { trace ray }
          {***********}
          color := Trace_primary_ray(ray);
        end
      else
        color := Trace_stereo(ray);
    end;

  Trace_subpixel := color;
end; {function Trace_subpixel}


function Trace_pixel(pixel: pixel_type): color_type;
var
  color: color_type;
  point2: vector2_type;
  ray: ray_type;
  obj: hierarchical_object_type;
  t: real;
begin
  if antialiasing then
    begin
      {*************************}
      { jitter for antialiasing }
      {*************************}
      // point2 := Subpixel_placement(pixel, 1);
    end;

  if (boxels_made) then
    begin
      {***********************}
      { trace ray from boxels }
      {***********************}
      if antialiasing then
        t := Trace_boxel_subpixel(point2, ray, tiny, infinity, obj)
      else
        t := Trace_boxel_pixel(pixel, ray, tiny, infinity, obj);
      color := Shade_primary_ray(ray, t, obj);
    end
  else
    begin
      if (antialiasing = false) then
        begin
          {**********************}
          { project pixel to ray }
          {**********************}
          ray := Project_pixel_to_ray(pixel);
        end
      else
        begin
          {*************************}
          { project subpixel to ray }
          {*************************}

          {*******************************************}
          { transform point to window centered coords }
          {*******************************************}
          point2.x := (point2.x - current_projection_ptr^.projection_center.x);
          point2.y := (current_projection_ptr^.projection_center.y - point2.y);

          {*************************}
          { project subpixel to ray }
          {*************************}
          ray := Project_point2_to_ray(point2);
        end;

      if stereo_seperation = 0 then
        begin
          {************************}
          { transform ray from eye }
          { coords to world coords }
          {************************}
          Transform_point_to_axes(ray.location, eye_coords);
          Transform_vector_to_axes(ray.direction, eye_coords);

          {***********}
          { trace ray }
          {***********}
          color := Trace_primary_ray(ray);
        end
      else
        color := Trace_stereo(ray);
    end;

  Trace_pixel := color;
end; {function Trace_pixel}


function Supersample_pixel(pixel: pixel_type): color_type;
var
  color: color_type;
  counter: integer;
  point2: vector2_type;
begin
  // color := Pixel_color_to_color(Get_pixel_color(pixel));
  for counter := 2 to supersamples do
    begin
      // point2 := Subpixel_placement(pixel, counter);
      color := Mix_color(color, Trace_subpixel(point2));
    end;
  Supersample_pixel := Intensify_color(color, 1 / supersamples);
end; {function Supersample_pixel}


procedure Clip_block(var pixel1, pixel2: pixel_type;
  min, max: pixel_type);
begin
  Clip_pixel(pixel1, min, max);
  Clip_pixel(pixel2, min, max);
end; {procedure Clip_block}


procedure Supersample;
var
  h_counter, v_counter: integer;
  pixel: pixel_type;
begin
  writeln('supersampling');
  {*******************************************}
  { find which pixels need to be supersampled }
  {*******************************************}
  // Find_ss_pixels;
  {Display_ss_pixels;}

  {******************************************}
  { supersample using pixels as first sample }
  {******************************************}
  for v_counter := 0 to current_projection_ptr^.projection_size.v do
    begin
      for h_counter := 0 to current_projection_ptr^.projection_size.h do
        begin
          pixel.h := h_counter;
          pixel.v := v_counter;

          {
          if Supersampling_required(pixel) then
            begin
              Set_color(Supersample_pixel(pixel));
              Draw_pixel(pixel);
              Update_window;
            end;
          }
        end;
    end;
end; {Supersample}


procedure Linear_raytrace(drawable: drawable_type;
  pixel_color_buffer_ptr: pixel_color_buffer_ptr_type;
  scene_ptr: ray_object_inst_ptr_type);
var
  h, v: integer;
  pixel: pixel_type;
  min, max, center: pixel_type;
  blocks, start: pixel_type;
  pixel1, pixel2: pixel_type;
  color: color_type;
  previous_color, new_color: pixel_color_type;
begin
  Set_scanning(scene_ptr);

  if (min_pixel_size = 1) then
    begin
      for v := 0 to current_projection_ptr^.projection_size.v do
        begin
          for h := 0 to current_projection_ptr^.projection_size.h do
            begin
              pixel.h := h;
              pixel.v := v;
              color := Trace_pixel(pixel);
              drawable.Set_color(color);
              drawable.Draw_pixel(pixel);
            end;
          drawable.Update;
          Check_system_events;
          if finished then
            break;
        end;
    end
  else
    begin
      min.h := 0;
      min.v := 0;
      max.h := current_projection_ptr^.projection_size.h - 1;
      max.v := current_projection_ptr^.projection_size.v - 1;
      center.h := trunc(current_projection_ptr^.projection_center.x);
      center.v := trunc(current_projection_ptr^.projection_center.y);

      blocks.h := (center.h - min.h + min_pixel_size - 1) div min_pixel_size;
      blocks.v := (center.v - min.v + min_pixel_size - 1) div min_pixel_size;
      start.h := center.h - (blocks.h * min_pixel_size);
      start.v := center.v - (blocks.v * min_pixel_size);

      v := start.v;
      while (v < max.v) do
        begin
          h := start.h;
          while (h < max.h) do
            begin
              pixel1.h := h;
              pixel1.v := v;
              pixel2.h := h + min_pixel_size - 1;
              pixel2.v := v + min_pixel_size - 1;

              Clip_block(pixel1, pixel2, min, max);
              previous_color := Get_pixel_color_buffer(pixel_color_buffer_ptr, pixel1);
              color := Trace_pixel(pixel1);
              new_color := Color_to_pixel_color(color);
              if not Equal_pixel_color(new_color, previous_color) then
                begin
                  drawable.Set_color(color);
                  drawable.Fill_rect(pixel1, pixel2);
                  Set_pixel_color_buffer(pixel_color_buffer_ptr, pixel1, new_color);
                end;
              h := h + min_pixel_size;
            end;
          drawable.Update;
          Check_system_events;
          if finished then
            break;
          v := v + min_pixel_size;
        end;
    end;

  {********************************}
  { perform adaptive supersampling }
  {********************************}
  if antialiasing and (supersamples > 1) and (min_pixel_size = 1) then
    Supersample;
end; {Linear_raytrace}


procedure Ordered_raytrace(drawable: drawable_type;
  pixel_color_buffer_ptr: pixel_color_buffer_ptr_type;
  scene_ptr: ray_object_inst_ptr_type;
  incremental: boolean);
var
  screen_size, grid_size, size, previous_size: integer;
  min, max, center: pixel_type;
  start, blocks: pixel_type;
  h, v: integer;
  pixel1, pixel2, parent: pixel_type;
  color: color_type;
  previous_color, new_color: pixel_color_type;
  offset: pixel_type;
  h_parity, v_parity: boolean;
begin
  Set_scanning(scene_ptr);

  {********************************************}
  { grid must be the nearest power of 2 larger }
  { than the largest dimension of the screen.  }
  {********************************************}
  with current_projection_ptr^.projection_size do
    if (h > v) then
      screen_size := h
    else
      screen_size := v;
  grid_size := 1;
  while (grid_size < screen_size) do
    grid_size := grid_size * 2;
  size := grid_size div 2;

  min.h := 0;
  min.v := 0;
  max.h := current_projection_ptr^.projection_size.h - 1;
  max.v := current_projection_ptr^.projection_size.v - 1;
  center.h := max.h div 2;
  center.v := max.v div 2;

  if incremental then
    begin
      pixel1 := center;
      pixel2.h := center.h + min_pixel_size - 1;
      pixel2.v := center.v + min_pixel_size - 1;
    end
  else
    begin
      pixel1 := min;
      pixel2 := max;
    end;

  color := Trace_pixel(min);
  previous_color := Get_pixel_color_buffer(pixel_color_buffer_ptr, min);
  new_color := Color_to_pixel_color(color);
  if not Equal_pixel_color(new_color, previous_color) or not incremental then
    begin
      drawable.Set_color(color);
      drawable.Fill_rect(pixel1, pixel2);
      Set_pixel_color_buffer(pixel_color_buffer_ptr, pixel1, new_color);
    end;

  previous_size := size * 2;
  offset.h := center.h - size;
  offset.v := center.v - size;

  while (size >= min_pixel_size) do
    begin
      blocks.h := (center.h - min.h + size - 1) div size;
      blocks.v := (center.v - min.v + size - 1) div size;
      start.h := center.h - (blocks.h * size);
      start.v := center.v - (blocks.v * size);

      v := start.v;
      while (v < max.v) do
        begin
          v_parity := (v - offset.v) mod previous_size <> 0;
          h := start.h;
          while (h < max.h) do
            begin
              h_parity := (h - offset.h) mod previous_size <> 0;
              pixel1.h := h;
              pixel1.v := v;
              Clip_pixel(pixel1, min, max);

              if incremental then
                previous_color := Get_pixel_color_buffer(pixel_color_buffer_ptr, pixel1)
              else
                begin
                  parent.h := offset.h + ((h - offset.h) div previous_size) *
                    previous_size;
                  parent.v := offset.v + ((v - offset.v) div previous_size) *
                    previous_size;
                  Clip_pixel(parent, min, max);
                  previous_color := Get_pixel_color_buffer(pixel_color_buffer_ptr, parent);
                end;

              if h_parity or v_parity then
                begin
                  color := Trace_pixel(pixel1);

                  {*********************************}
                  { find if pixel needs to be drawn }
                  {*********************************}
                  new_color := Color_to_pixel_color(color);
                  if not Equal_pixel_color(new_color, previous_color) then
                    begin
                      if incremental then
                        begin
                          pixel2.h := h + min_pixel_size - 1;
                          pixel2.v := v + min_pixel_size - 1;
                        end
                      else
                        begin
                          pixel2.h := h + size - 1;
                          pixel2.v := v + size - 1;
                        end;

                      Clip_pixel(pixel2, min, max);
                      drawable.Set_color(color);
                      drawable.Fill_rect(pixel1, pixel2);
                    end;
                end
              else
                new_color := previous_color;
              Set_pixel_color_buffer(pixel_color_buffer_ptr, pixel1, new_color);
              h := h + size;
            end;
          drawable.Update;
          Check_system_events;
          if finished then
            break;
          v := v + size;
        end;

      previous_size := size;
      size := size div 2;
    end;

  {********************************}
  { perform adaptive supersampling }
  {********************************}
  if antialiasing and (supersamples > 1) and (min_pixel_size = 1) then
    Supersample;
end; {procedure Ordered_raytrace}


procedure Random_raytrace(drawable: drawable_type;
  pixel_color_buffer_ptr: pixel_color_buffer_ptr_type;
  scene_ptr: ray_object_inst_ptr_type;
  incremental: boolean);
const
  base = 4; {count in base 4}
var
  screen_size, grid_size: integer;
  digit, digits, digit_counter, counter, temp: integer;
  size_array: array[1..16] of integer;
  digit_string: array[1..16] of integer;
  min, max, center: pixel_type;
  h, v: integer;
  pixel1, pixel2, parent, offset: pixel_type;
  scanning_level: integer;
  done: boolean;
  color: color_type;
  previous_color, new_color: pixel_color_type;
  size, previous_size: integer;
begin
  Set_scanning(scene_ptr);

  {********************************************}
  { grid must be the nearest power of 2 larger }
  { than the largest dimension of the screen.  }
  {********************************************}
  with current_projection_ptr^.projection_size do
    if (h > v) then
      screen_size := h
    else
      screen_size := v;
  grid_size := 1;
  digits := 0;
  while (grid_size < screen_size) do
    begin
      grid_size := grid_size * 2;
      digits := digits + 1;
    end;

  {*************************************************}
  { scattering the blocks in this pattern is like   }
  { counting in base 4 where the least significant  }
  { digits map to large screen offsets and the most }
  { significant digits map to small screen offsets. }
  {*************************************************}

  {*****************************************************}
  { size array maps place value to size of block offset }
  { we can handle screens up to 2^16 in width or height }
  {*****************************************************}

  {*************************}
  { initialize digit_string }
  {*************************}
  for counter := 1 to digits do
    digit_string[counter] := 0;

  {***********************}
  { initialize size array }
  {***********************}
  size_array[1] := grid_size div 2;
  for counter := 2 to digits do
    size_array[counter] := size_array[counter - 1] div 2;

  min.h := 0;
  min.v := 0;
  max.h := current_projection_ptr^.projection_size.h - 1;
  max.v := current_projection_ptr^.projection_size.v - 1;
  center.h := max.h div 2;
  center.v := max.v div 2;

  h := center.h - size_array[1];
  v := center.v - size_array[1];
  digit := 1;
  digit_counter := 1;
  digit_string[digit] := 0;
  scanning_level := 1;
  done := false;

  previous_size := grid_size * 2;
  size := grid_size;
  offset.h := center.h - size;
  offset.v := center.v - size;

  while (digit_counter <= digits) and not done do
    begin
      pixel1.h := h;
      pixel1.v := v;

      if incremental then
        begin
          pixel2.h := h + min_pixel_size - 1;
          pixel2.v := v + min_pixel_size - 1;
        end
      else
        begin
          pixel2.h := h + size - 1;
          pixel2.v := v + size - 1;
        end;

      if size_array[digit_counter] < min_pixel_size then
        done := true;

      {******************************************}
      { if pixel is at least partially in screen }
      {******************************************}
      if not ((pixel1.h > max.h) or (pixel2.h < min.h) or (pixel1.v > max.v) or
        (pixel2.v < min.v)) then
        begin
          Clip_block(pixel1, pixel2, min, max);

          if incremental then
            previous_color := Get_pixel_color_buffer(pixel_color_buffer_ptr, pixel1)
          else
            begin
              parent.h := offset.h + ((h - offset.h) div previous_size) *
                previous_size;
              parent.v := offset.v + ((v - offset.v) div previous_size) *
                previous_size;
              Clip_pixel(parent, min, max);
              previous_color := Get_pixel_color_buffer(pixel_color_buffer_ptr, parent);
            end;

          color := Trace_pixel(pixel1);
          new_color := Color_to_pixel_color(color);
          if not Equal_pixel_color(new_color, previous_color) or (scanning_level
            = 1) then
            begin
              drawable.Set_color(color);
              drawable.Fill_rect(pixel1, pixel2);
            end;

          Set_pixel_color_buffer(pixel_color_buffer_ptr, pixel1, new_color);
          drawable.Update;
          Check_system_events;
          if finished then
            break;
        end;

      temp := digit_string[digit];
      if (temp = 0) then
        h := h + size_array[digit]
      else if (temp = 1) then
        v := v + size_array[digit]
      else if (temp = 2) then
        h := h - size_array[digit]
      else if (temp = 3) then
        v := v - size_array[digit];
      digit_string[digit] := temp + 1;

      while (digit_string[digit] = base) do {carry}
        begin
          digit_string[digit] := 0;
          digit := digit + 1;
          if (digit > digit_counter) then
            begin
              digit_counter := digit;
              scanning_level := scanning_level + 1;
              previous_size := size;
              size := size_array[digit_counter];
            end;

          temp := digit_string[digit];
          if (temp = 0) then
            h := h + size_array[digit]
          else if (temp = 1) then
            v := v + size_array[digit]
          else if (temp = 2) then
            h := h - size_array[digit]
          else if (temp = 3) then
            v := v - size_array[digit];
          digit_string[digit] := temp + 1;
        end; {while}
      digit := 1;
    end; {while}

  {********************************}
  { perform adaptive supersampling }
  {********************************}
  if antialiasing and (supersamples > 1) and (min_pixel_size = 1) then
    Supersample;
end; {procedure Random_raytrace}


procedure Raytrace_to_file(scene_ptr: ray_object_inst_ptr_type;
  file_name: string_type);
var
  size: pixel_type;
  h_counter, v_counter: integer;
  color: color_type;
  pixel: pixel_type;
begin
  Set_scanning(scene_ptr);

  rewrite(output, file_name);
  { write(output, (window_size.h + 1) : 5, ' '); }
  { write(output, (window_size.v + 1) : 5, ' '); }

  size := current_projection_ptr^.projection_size;
  for v_counter := size.v div 2 downto -size.v div 2 do
    begin
      for h_counter := -size.h div 2 to size.h div 2 do
        begin
          pixel.h := h_counter;
          pixel.v := v_counter;
          color := Trace_pixel(pixel);
          { write(output, chr(Trunc(pixel_color.x * 255))); }
          { write(output, chr(Trunc(pixel_color.y * 255))); }
          { write(output, chr(Trunc(pixel_color.z * 255))); }
        end;
    end;
end; {procedure Raytrace_to_file}


end.

