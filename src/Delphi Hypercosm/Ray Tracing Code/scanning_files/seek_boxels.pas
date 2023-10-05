unit seek_boxels;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            seek_boxels                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is used to search the screen space          }
{       ray tracing data structure.                             }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors2, rays, pixels, raytrace;


function Trace_boxel_pixel(pixel: pixel_type;
  var ray: ray_type;
  tmin, tmax: real;
  var obj: hierarchical_object_type): real;
function Trace_boxel_subpixel(point2: vector2_type;
  var ray: ray_type;
  tmin, tmax: real;
  var obj: hierarchical_object_type): real;


implementation
uses
  constants, vectors, coord_axes, project, objects, make_boxels,
  intersect, walk_voxels;


function Primary_object_intersection(ray: ray_type;
  tmin, tmax: real;
  primary_object_ptr: primary_object_ptr_type;
  var obj: hierarchical_object_type): real;
var
  t: real;
  depth: integer;
begin
  {************************************************}
  { construct hierarchical object for intersection }
  {************************************************}
  obj.object_ptr := primary_object_ptr^.object_ptr;
  obj.transform_stack := primary_object_ptr^.obj.transform_stack;

  t := Object_intersection(ray, tmin, tmax, obj);

  {***********************************************}
  { return hierarchical object from ray hierarchy }
  {***********************************************}
  if (t <> infinity) then
    begin
      if (primary_object_ptr^.object_ptr^.kind <> complex_object) then
        begin
          {******************}
          { primitive object }
          {******************}
          obj.object_ptr := primary_object_ptr^.obj.object_ptr;
          obj.transform_stack := primary_object_ptr^.obj.transform_stack;
        end
      else
        begin
          {****************}
          { complex object }
          {****************}
          depth := primary_object_ptr^.obj.transform_stack.depth + 1;
          obj.transform_stack.stack[depth] :=
            primary_object_ptr^.obj.object_ptr;
        end;
    end;

  Primary_object_intersection := t;
end; {function Primary_object_intersection}


function Trace_boxel_pixel(pixel: pixel_type;
  var ray: ray_type;
  tmin, tmax: real;
  var obj: hierarchical_object_type): real;
var
  primary_object_ptr: primary_object_ptr_type;
  boxel_entry_ptr: boxel_entry_ptr_type;
  new_obj: hierarchical_object_type;
  boxel_pixel: pixel_type;
  done: boolean;
  t, new_t: real;
begin
  {*********************************}
  { transform pixel to boxel coords }
  {*********************************}
  boxel_pixel.h := pixel.h div boxel_width;
  boxel_pixel.v := pixel.v div boxel_height;
  t := infinity;

  {********************************}
  { prepare for intersection tests }
  {********************************}
  boxel_entry_ptr := Index_boxel_array(boxel_pixel.h, boxel_pixel.v)^;
  if (boxel_entry_ptr <> nil) or (infinite_primary_list <> nil) then
    begin
      {**********************}
      { project pixel to ray }
      {**********************}
      ray := Project_pixel_to_ray(pixel);
      ray.direction := Normalize(ray.direction);
      {Transform_ray_to_axes(ray, scene_axes);}

      closest_t := infinity;
      ray_originates_from_object := false;
      source_face_ptr := nil;
      source_point_ptr := nil;
    end;

  {************************}
  { check objects in boxel }
  {************************}
  done := false;
  while (boxel_entry_ptr <> nil) and not done do
    begin
      primary_object_ptr := boxel_entry_ptr^.primary_object_ptr;
      {if (primary_object_ptr^.distance > t) then}
      if false then
        done := true
      else
        begin
          new_t := Primary_object_intersection(ray, tmin, tmax,
            primary_object_ptr, new_obj);
          if (new_t < t) then
            begin
              t := new_t;
              obj := new_obj;
            end;
          boxel_entry_ptr := boxel_entry_ptr^.next;
        end;
    end;

  {***********************}
  { check infinite planes }
  {***********************}
  primary_object_ptr := infinite_primary_list;
  while (primary_object_ptr <> nil) do
    begin
      new_t := Primary_object_intersection(ray, tmin, tmax, primary_object_ptr,
        new_obj);
      if (new_t < t) then
        begin
          t := new_t;
          obj := new_obj;
        end;
      primary_object_ptr := primary_object_ptr^.next;
    end;

  {*****************************************}
  { we're going to need the ray for shading }
  {*****************************************}
  if (t <> infinity) then
    Transform_ray_to_axes(ray, scene_axes);

  Trace_boxel_pixel := t;
end; {function Trace_boxel_pixel}


function Trace_boxel_subpixel(point2: vector2_type;
  var ray: ray_type;
  tmin, tmax: real;
  var obj: hierarchical_object_type): real;
var
  primary_object_ptr: primary_object_ptr_type;
  boxel_entry_ptr: boxel_entry_ptr_type;
  new_obj: hierarchical_object_type;
  pixel, boxel_pixel: pixel_type;
  done: boolean;
  t, new_t: real;
begin
  {*********************}
  { find display coords }
  {*********************}
  pixel.h := Trunc(point2.x);
  pixel.v := Trunc(point2.y);

  {*******************************}
  { convert pixel to boxel coords }
  {*******************************}
  boxel_pixel.h := pixel.h div boxel_width;
  boxel_pixel.v := pixel.v div boxel_height;
  t := infinity;

  {********************************}
  { prepare for intersection tests }
  {********************************}
  boxel_entry_ptr := Index_boxel_array(boxel_pixel.h, boxel_pixel.v)^;
  if (boxel_entry_ptr <> nil) or (infinite_primary_list <> nil) then
    begin
      {*******************************************}
      { transform point to window centered coords }
      {*******************************************}
      point2.x := (point2.x - current_projection_ptr^.projection_center.x);
      point2.y := (current_projection_ptr^.projection_center.y - point2.y);

      {**********************}
      { project point to ray }
      {**********************}
      ray := Project_point2_to_ray(point2);
      ray.direction := Normalize(ray.direction);
      {Transform_ray_to_axes(ray, scene_axes);}

      closest_t := infinity;
      ray_originates_from_object := false;
      source_face_ptr := nil;
      source_point_ptr := nil;
    end;

  {************************}
  { check objects in boxel }
  {************************}
  done := false;
  while (boxel_entry_ptr <> nil) and not done do
    begin
      primary_object_ptr := boxel_entry_ptr^.primary_object_ptr;
      {if (primary_object_ptr^.distance > t) then}
      if false then
        done := true
      else
        begin
          new_t := Primary_object_intersection(ray, tmin, tmax,
            primary_object_ptr, new_obj);
          if (new_t < t) then
            begin
              t := new_t;
              obj := new_obj;
            end;
          boxel_entry_ptr := boxel_entry_ptr^.next;
        end;
    end;

  {***********************}
  { check infinite planes }
  {***********************}
  primary_object_ptr := infinite_primary_list;
  while (primary_object_ptr <> nil) do
    begin
      new_t := Primary_object_intersection(ray, tmin, tmax, primary_object_ptr,
        new_obj);
      if (new_t < t) then
        begin
          t := new_t;
          obj := new_obj;
        end;
      primary_object_ptr := primary_object_ptr^.next;
    end;

  {*****************************************}
  { we're going to need the ray for shading }
  {*****************************************}
  if (t <> infinity) then
    Transform_ray_to_axes(ray, scene_axes);

  Trace_boxel_subpixel := t;
end; {function Trace_boxel_subpixel}


end.
