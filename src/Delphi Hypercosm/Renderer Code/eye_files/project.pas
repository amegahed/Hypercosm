unit project;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              project                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The projection module provides routines for             }
{       projecting 3d coords to 2d or eye coords and            }
{       routines for projecting 2d coords to rays.              }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings, vectors, vectors2, rays, trans, pixels, screen_boxes;


type
  {***********************************}
  { linear: orthographic, perspective }
  { nonlinear: fisheye, panoramic     }
  {***********************************}
  projection_kind_type = (orthographic, perspective, fisheye, panoramic);


  projection_ptr_type = ^projection_type;
  projection_type = record

    {***********************}
    { projection attributes }
    {***********************}
    kind: projection_kind_type;
    field_of_view: real;
    screen_box: screen_box_type;
    pixel_aspect_ratio: real;

    {**************************}
    { derived screen constants }
    {**************************}
    projection_size: pixel_type;
    projection_center: vector2_type;

    {******************************}
    { derived projection constants }
    {******************************}
    projection_constant: real;
    projection_plane_distance: real;

    next: projection_ptr_type;
  end; {projection_type}


var
  current_projection_ptr: projection_ptr_type;


{************************************************}
{ set projection using size of display region in }
{ pixels and the region's physical aspect ratio  }
{************************************************}
function New_projection(kind: projection_kind_type;
  field_of_view: real;
  screen_box: screen_box_type;
  pixel_aspect_ratio: real): projection_ptr_type;
procedure Free_projection(var projection_ptr: projection_ptr_type);

{*******************************************************}
{                         3D to 2D                      }
{*******************************************************}
{           these are the projections used in           }
{             wireframe and z buffer modes.             }
{*******************************************************}
function Project_point_to_pixel(point: vector_type): pixel_type;
function Project_point_to_point2(point: vector_type): vector2_type;
function Project_point_to_point(point: vector_type): vector_type;

{*******************************************************}
{                         2D to 3D                      }
{*******************************************************}
{      these are the projections used in raytracing     }
{*******************************************************}
function Project_pixel_to_ray(pixel: pixel_type): ray_type;
function Project_point2_to_ray(point: vector2_type): ray_type;

{*******************************************************}
{                     2D + depth to 3D                  }
{*******************************************************}
{      these are the projections used in Phong          }
{       shading to go from a pixel + the depth          }
{       in the z buffer to a ray which can be used      }
{       to get back the space coords for shading.       }
{*******************************************************}
function Project_point_to_ray(point: vector_type): ray_type;
function Reverse_project_point_to_point(point: vector_type): vector_type;

{*****************************************************}
{            screen coords to display coords          }
{*****************************************************}
function Screen_to_display(point: vector_type): vector_type;
function Display_to_screen(point: vector_type): vector_type;

{**************************}
{ routines to manage enums }
{**************************}
procedure Write_projection_kind(kind: projection_kind_type);
function Projection_kind_to_str(kind: projection_kind_type): string_type;


implementation
uses
  math, errors, new_memory, trigonometry;


const
  memory_alert = false;


var
  projection_free_list: projection_ptr_type;


{************************************************}
{ set projection using size of display region in }
{ pixels and the region's physical aspect ratio  }
{************************************************}


procedure Init_projection(projection_ptr: projection_ptr_type;
  kind: projection_kind_type;
  field_of_view: real;
  screen_box: screen_box_type;
  pixel_aspect_ratio: real);
var
  h, v: real;
  diagonal: real;
begin
  projection_ptr^.kind := kind;
  projection_ptr^.field_of_view := field_of_view;
  projection_ptr^.screen_box := screen_box;
  projection_ptr^.pixel_aspect_ratio := pixel_aspect_ratio;
  projection_ptr^.next := nil;

  with projection_ptr^ do
    begin
      {**************************}
      { compute screen constants }
      {**************************}
      projection_size.h := screen_box.max.h - screen_box.min.h;
      projection_size.v := screen_box.max.v - screen_box.min.v;
      projection_center.x := (screen_box.min.h + screen_box.max.h) / 2;
      projection_center.y := (screen_box.min.v + screen_box.max.v) / 2;

      {******************************}
      { compute projection constants }
      {******************************}
      if pixel_aspect_ratio <> 0 then
        begin
          h := projection_size.h / pixel_aspect_ratio;
          v := projection_size.v;
          diagonal := sqrt(sqr(h) + sqr(v));

          case kind of
            orthographic:
              begin
                projection_constant := field_of_view / diagonal;
              end;
            perspective:
              begin
                projection_plane_distance := (diagonal / 2) /
                  abs(tan(field_of_view / 2 * degrees_to_radians));
                projection_constant := projection_plane_distance;
              end;
            fisheye:
              begin
                projection_plane_distance := (diagonal / 2) /
                  abs(tan(field_of_view / 2 * degrees_to_radians));
                projection_constant := field_of_view * degrees_to_radians /
                  diagonal;
              end;
            panoramic:
              begin
                projection_plane_distance := projection_size.h /
                  pixel_aspect_ratio / (field_of_view * degrees_to_radians);
                projection_constant := projection_size.h / pixel_aspect_ratio /
                  (field_of_view * degrees_to_radians);
              end;

          end; {case}
        end
      else
        Error('Invalid aspect ratio.');
    end; {with}
end; {procedure Init_projection}


function New_projection(kind: projection_kind_type;
  field_of_view: real;
  screen_box: screen_box_type;
  pixel_aspect_ratio: real): projection_ptr_type;
var
  projection_ptr: projection_ptr_type;
begin
  {***********************************}
  { get new projection from free list }
  {***********************************}
  if projection_free_list <> nil then
    begin
      projection_ptr := projection_free_list;
      projection_free_list := projection_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new projection');
      new(projection_ptr);
    end;

  {***********************}
  { initialize projection }
  {***********************}
  Init_projection(projection_ptr, kind, field_of_view, screen_box,
    pixel_aspect_ratio);

  New_projection := projection_ptr;
end; {function New_projection}


procedure Free_projection(var projection_ptr: projection_ptr_type);
begin
  {*****************************}
  { add projection to free list }
  {*****************************}
  projection_ptr^.next := projection_free_list;
  projection_free_list := projection_ptr;
  projection_ptr := nil;
end; {procedure Free_projection}


{****************************************}
{ routines for projecting point to pixel }
{****************************************}


function Orthographic_point_to_pixel(point: vector_type): pixel_type;
var
  pixel: pixel_type;
begin
  with current_projection_ptr^ do
    begin
      pixel.h := Trunc(projection_center.x + point.x * pixel_aspect_ratio /
        projection_constant);
      pixel.v := Trunc(projection_center.y - point.z / projection_constant);
    end;

  Orthographic_point_to_pixel := pixel;
end; {function Orthographic_point_to_pixel}


function Perspective_point_to_pixel(point: vector_type): pixel_type;
var
  pixel: pixel_type;
begin
  if (point.y = 0) then
    point.y := 1;

  with current_projection_ptr^ do
    begin
      pixel.h := Trunc(projection_center.x + point.x / point.y *
        pixel_aspect_ratio * projection_constant);
      pixel.v := Trunc(projection_center.y - point.z / point.y *
        projection_constant);
    end;

  Perspective_point_to_pixel := pixel;
end; {function Perspective_point_to_pixel}


function Fisheye_point_to_pixel(point: vector_type): pixel_type;
var
  pixel: pixel_type;
  d, th: real;
begin
  d := sqrt((point.x * point.x) + (point.z * point.z));

  if (point.y = 0) then
    th := pi / 2
  else
    begin
      th := arctan(d / point.y);
      if (th < 0) then
        th := th + pi;
    end;

  with current_projection_ptr^ do
    if (d <> 0) then
      begin
        pixel.h := Trunc(projection_center.x + point.x / d * th *
          pixel_aspect_ratio / projection_constant);
        pixel.v := Trunc(projection_center.y - point.z / d * th /
          projection_constant);
      end
    else
      begin
        pixel.h := Trunc(projection_center.x);
        pixel.v := Trunc(projection_center.y);
      end;

  Fisheye_point_to_pixel := pixel;
end; {function Fisheye_point_to_pixel}


function Panoramic_point_to_pixel(point: vector_type): pixel_type;
var
  pixel: pixel_type;
  d, th: real;
begin
  d := sqrt((point.x * point.x) + (point.y * point.y));

  if (point.y = 0) then
    begin
      if point.x > 0 then
        th := pi / 2
      else
        th := -pi / 2;
    end
  else
    begin
      th := arctan(point.x / point.y);
      if (point.y < 0) then
        begin
          if point.x > 0 then
            th := th + pi
          else
            th := th - pi;
        end;
    end;

  with current_projection_ptr^ do
    if (d <> 0) then
      begin
        pixel.h := Trunc(projection_center.x + th * projection_constant *
          pixel_aspect_ratio);
        pixel.v := Trunc(projection_center.y - point.z / d *
          projection_plane_distance);
      end
    else
      begin
        pixel.h := Trunc(projection_center.x);
        pixel.v := Trunc(projection_center.y);
      end;

  Panoramic_point_to_pixel := pixel;
end; {function Panoramic_point_to_pixel}


function Project_point_to_pixel(point: vector_type): pixel_type;
var
  pixel: pixel_type;
begin
  case current_projection_ptr^.kind of
    orthographic:
      pixel := Orthographic_point_to_pixel(point);
    perspective:
      pixel := Perspective_point_to_pixel(point);
    fisheye:
      pixel := Fisheye_point_to_pixel(point);
    panoramic:
      pixel := Panoramic_point_to_pixel(point);
  end; {case}

  Project_point_to_pixel := pixel;
end; {function Project_point_to_pixel}


{*****************************************}
{ routines for projecting point to point2 }
{*****************************************}


function Orthographic_point_to_point2(point: vector_type): vector2_type;
var
  vector: vector2_type;
begin
  with current_projection_ptr^ do
    begin
      vector.x := projection_center.x + (point.x * pixel_aspect_ratio /
        projection_constant);
      vector.y := projection_center.y - (point.z / projection_constant);
    end;

  Orthographic_point_to_point2 := vector;
end; {function Orthographic_point_to_point2}


function Perspective_point_to_point2(point: vector_type): vector2_type;
var
  vector: vector2_type;
begin
  if (point.y = 0) then
    point.y := 1;

  with current_projection_ptr^ do
    begin
      vector.x := projection_center.x + (point.x / point.y * pixel_aspect_ratio
        * projection_constant);
      vector.y := projection_center.y - (point.z / point.y *
        projection_constant);
    end;

  Perspective_point_to_point2 := vector;
end; {function Perspective_point_to_point2}


function Fisheye_point_to_point2(point: vector_type): vector2_type;
var
  vector: vector2_type;
  d, th: real;
begin
  d := sqrt((point.x * point.x) + (point.z * point.z));

  if (point.y = 0) then
    th := pi / 2
  else
    begin
      th := arctan(d / point.y);
      if (th < 0) then
        th := th + pi;
    end;

  with current_projection_ptr^ do
    if (d <> 0) then
      begin
        vector.x := projection_center.x + (point.x / d * th * pixel_aspect_ratio
          / projection_constant);
        vector.y := projection_center.y - (point.z / d * th /
          projection_constant);
      end
    else
      vector := projection_center;

  Fisheye_point_to_point2 := vector;
end; {function Fisheye_point_to_point2}


function Panoramic_point_to_point2(point: vector_type): vector2_type;
var
  vector: vector2_type;
  d, th: real;
begin
  d := sqrt((point.x * point.x) + (point.y * point.y));

  if (point.y = 0) then
    begin
      if point.x > 0 then
        th := pi / 2
      else
        th := -pi / 2;
    end
  else
    begin
      th := arctan(point.x / point.y);
      if (point.y < 0) then
        begin
          if point.x > 0 then
            th := th + pi
          else
            th := th - pi;
        end;
    end;

  with current_projection_ptr^ do
    if (d <> 0) then
      begin
        vector.x := projection_center.x + (th * projection_constant *
          pixel_aspect_ratio);
        vector.y := projection_center.y - (point.z / d *
          projection_plane_distance);
      end
    else
      vector := projection_center;

  Panoramic_point_to_point2 := vector;
end; {function Panoramic_point_to_point2}


function Project_point_to_point2(point: vector_type): vector2_type;
var
  vector: vector2_type;
begin
  case current_projection_ptr^.kind of
    orthographic:
      vector := Orthographic_point_to_point2(point);
    perspective:
      vector := Perspective_point_to_point2(point);
    fisheye:
      vector := Fisheye_point_to_point2(point);
    panoramic:
      vector := Panoramic_point_to_point2(point);
  end; {case}

  Project_point_to_point2 := vector;
end; {function Project_point_to_point2}


{****************************************}
{ routines for projecting point to point }
{****************************************}


function Orthographic_point_to_point(point: vector_type): vector_type;
var
  vector: vector_type;
begin
  with current_projection_ptr^ do
    begin
      vector.x := projection_center.x + (point.x * pixel_aspect_ratio /
        projection_constant);
      vector.y := projection_center.y - (point.z / projection_constant);
      vector.z := point.y;
    end;

  Orthographic_point_to_point := vector;
end; {function Orthographic_point_to_point}


function Perspective_point_to_point(point: vector_type): vector_type;
var
  vector: vector_type;
begin
  if (point.y = 0) then
    point.y := 1;

  with current_projection_ptr^ do
    begin
      vector.x := projection_center.x + (point.x / point.y * pixel_aspect_ratio
        * projection_constant);
      vector.y := projection_center.y - (point.z / point.y *
        projection_constant);
      vector.z := -1 / point.y;
    end;

  Perspective_point_to_point := vector;
end; {function Perspective_point_to_point}


function Fisheye_point_to_point(point: vector_type): vector_type;
var
  vector: vector_type;
  d, th: real;
begin
  d := sqrt((point.x * point.x) + (point.z * point.z));

  if (point.y = 0) then
    th := pi / 2
  else
    begin
      th := arctan(d / point.y);
      if (th < 0) then
        th := th + pi;
    end;

  with current_projection_ptr^ do
    if (d <> 0) then
      begin
        vector.x := projection_center.x + (point.x / d * th * pixel_aspect_ratio
          / projection_constant);
        vector.y := projection_center.y - (point.z / d * th /
          projection_constant);
        vector.z := -1 / Vector_length(point);
      end
    else
      begin
        vector.x := projection_center.x;
        vector.y := projection_center.y;
        vector.z := -1 / Vector_length(point);
      end;

  Fisheye_point_to_point := vector;
end; {function Fisheye_point_to_point}


function Panoramic_point_to_point(point: vector_type): vector_type;
var
  vector: vector_type;
  d, th: real;
begin
  d := sqrt((point.x * point.x) + (point.y * point.y));

  if (point.y = 0) then
    begin
      if point.x > 0 then
        th := pi / 2
      else
        th := -pi / 2;
    end
  else
    begin
      th := arctan(point.x / point.y);
      if (point.y < 0) then
        begin
          if point.x > 0 then
            th := th + pi
          else
            th := th - pi;
        end;
    end;

  with current_projection_ptr^ do
    if (d <> 0) then
      begin
        vector.x := projection_center.x + (th * projection_constant *
          pixel_aspect_ratio);
        vector.y := projection_center.y - (point.z / d *
          projection_plane_distance);
        vector.z := -1 / d;
      end
    else
      begin
        vector.x := projection_center.x;
        vector.y := projection_center.y;
        vector.z := -1 / abs(point.z);
      end;

  Panoramic_point_to_point := vector;
end; {function Panoramic_point_to_point}


function Project_point_to_point(point: vector_type): vector_type;
var
  vector: vector_type;
begin
  case current_projection_ptr^.kind of
    orthographic:
      vector := Orthographic_point_to_point(point);
    perspective:
      vector := Perspective_point_to_point(point);
    fisheye:
      vector := Fisheye_point_to_point(point);
    panoramic:
      vector := Panoramic_point_to_point(point);
  end; {case}

  Project_point_to_point := vector;
end; {function Project_point_to_point}


{***************************************}
{ routines for projecting pixel to ray  }
{***************************************}


function Orthographic_pixel_to_ray(pixel: pixel_type): ray_type;
var
  ray: ray_type;
begin
  with current_projection_ptr^ do
    begin
      ray.location.x := (pixel.h - projection_center.x) * projection_constant /
        pixel_aspect_ratio;
      ray.location.z := (projection_center.y - pixel.v) * projection_constant;
      ray.location.y := 0.0;
      ray.direction := y_vector;
    end;

  Orthographic_pixel_to_ray := ray;
end; {function Orthographic_pixel_to_ray}


function Perspective_pixel_to_ray(pixel: pixel_type): ray_type;
var
  ray: ray_type;
begin
  with current_projection_ptr^ do
    begin
      ray.location := zero_vector; {ray starts at origin}
      ray.direction.x := (pixel.h - projection_center.x) / pixel_aspect_ratio;
      ray.direction.z := (projection_center.y - pixel.v);
      ray.direction.y := projection_constant;
    end;

  Perspective_pixel_to_ray := ray;
end; {function Perspective_pixel_to_ray}


function Fisheye_pixel_to_ray(pixel: pixel_type): ray_type;
var
  ray: ray_type;
  d, angle: real;
begin
  with current_projection_ptr^ do
    begin
      ray.location := zero_vector; {ray starts at origin}
      ray.direction.x := (pixel.h - projection_center.x) / pixel_aspect_ratio;
      ray.direction.z := (projection_center.y - pixel.v);
      ray.direction.y := 0.0;
      d := Vector_length(ray.direction);
      angle := d * projection_constant;
      if (angle <> 0.0) then
        ray.direction.y := d * cos(angle) / sin(angle)
      else
        ray.direction.y := 1.0;
    end;

  Fisheye_pixel_to_ray := ray;
end; {function Fisheye_pixel_to_ray}


function Panoramic_pixel_to_ray(pixel: pixel_type): ray_type;
var
  ray: ray_type;
  angle: real;
begin
  with current_projection_ptr^ do
    begin
      ray.location := zero_vector; {ray starts at origin}
      angle := (pixel.h - projection_center.x) / pixel_aspect_ratio /
        projection_constant;
      ray.direction.x := sin(angle);
      ray.direction.y := cos(angle);
      ray.direction.z := (projection_center.y - pixel.v) / projection_constant;
    end;

  Panoramic_pixel_to_ray := ray;
end; {function Panoramic_pixel_to_ray}


function Project_pixel_to_ray(pixel: pixel_type): ray_type;
var
  ray: ray_type;
begin
  case current_projection_ptr^.kind of
    orthographic:
      ray := Orthographic_pixel_to_ray(pixel);
    perspective:
      ray := Perspective_pixel_to_ray(pixel);
    fisheye:
      ray := Fisheye_pixel_to_ray(pixel);
    panoramic:
      ray := Panoramic_pixel_to_ray(pixel);
  end; {case}

  Project_pixel_to_ray := ray;
end; {function Project_pixel_to_ray}


{****************************************}
{ routines for projecting point2 to ray  }
{****************************************}


function Orthographic_point2_to_ray(point: vector2_type): ray_type;
var
  ray: ray_type;
begin
  with current_projection_ptr^ do
    begin
      ray.direction := y_vector;
      ray.location.x := point.x * projection_constant / pixel_aspect_ratio;
      ray.location.z := point.y * projection_constant;
      ray.location.y := 0.0;
    end;

  Orthographic_point2_to_ray := ray;
end; {function Orthographic_point2_to_ray}


function Perspective_point2_to_ray(point: vector2_type): ray_type;
var
  ray: ray_type;
begin
  with current_projection_ptr^ do
    begin
      ray.location := zero_vector; {ray starts at origin}
      ray.direction.x := point.x / pixel_aspect_ratio;
      ray.direction.z := point.y;
      ray.direction.y := projection_constant;
    end;

  Perspective_point2_to_ray := ray;
end; {function Perspective_point2_to_ray}


function Fisheye_point2_to_ray(point: vector2_type): ray_type;
var
  ray: ray_type;
  d, angle: real;
begin
  with current_projection_ptr^ do
    begin
      ray.location := zero_vector; {ray starts at origin}
      ray.direction.x := point.x / pixel_aspect_ratio;
      ray.direction.z := point.y;
      ray.direction.y := 0.0;
      d := Vector_length(ray.direction);
      angle := d * projection_constant;
      if (angle <> 0.0) then
        ray.direction.y := d * cos(angle) / sin(angle)
      else
        ray.direction.y := 1.0;
    end;

  Fisheye_point2_to_ray := ray;
end; {function Fisheye_point2_to_ray}


function Panoramic_point2_to_ray(point: vector2_type): ray_type;
var
  ray: ray_type;
  angle: real;
begin
  with current_projection_ptr^ do
    begin
      ray.location := zero_vector; {ray starts at origin}
      angle := point.x / pixel_aspect_ratio / projection_constant;
      ray.direction.x := sin(angle);
      ray.direction.y := cos(angle);
      ray.direction.z := point.y / projection_constant;
    end;

  Panoramic_point2_to_ray := ray;
end; {function Panoramic_point2_to_ray}


function Project_point2_to_ray(point: vector2_type): ray_type;
var
  ray: ray_type;
begin
  case current_projection_ptr^.kind of
    orthographic:
      ray := Orthographic_point2_to_ray(point);
    perspective:
      ray := Perspective_point2_to_ray(point);
    fisheye:
      ray := Fisheye_point2_to_ray(point);
    panoramic:
      ray := Panoramic_point2_to_ray(point);
  end; {case}

  Project_point2_to_ray := ray;
end; {function Project_point2_to_ray}


{*******************************************}
{ routines for projecting a point to a ray  }
{*******************************************}


function Orthographic_point_to_ray(point: vector_type): ray_type;
var
  ray: ray_type;
begin
  with current_projection_ptr^ do
    begin
      ray.direction := Vector_scale(y_vector, point.z);
      ray.location.x := point.x * projection_constant / pixel_aspect_ratio;
      ray.location.z := point.y * projection_constant;
      ray.location.y := 0.0;
    end;

  Orthographic_point_to_ray := ray;
end; {function Orthographic_point_to_ray}


function Perspective_point_to_ray(point: vector_type): ray_type;
var
  ray: ray_type;
begin
  with current_projection_ptr^ do
    begin
      ray.location := zero_vector; {ray starts at origin}
      ray.direction.x := point.x / pixel_aspect_ratio / projection_constant;
      ray.direction.z := point.y / projection_constant;
      ray.direction.y := 1;
      ray.direction := Vector_scale(ray.direction, -1 / point.z);
    end;

  Perspective_point_to_ray := ray;
end; {function Perspective_point_to_ray}


function Fisheye_point_to_ray(point: vector_type): ray_type;
var
  ray: ray_type;
  d, angle: real;
begin
  with current_projection_ptr^ do
    begin
      ray.location := zero_vector; {ray starts at origin}
      ray.direction.x := point.x / pixel_aspect_ratio;
      ray.direction.z := point.y;
      ray.direction.y := 0.0;
      d := Vector_length(ray.direction);
      angle := d * projection_constant;
      if (angle <> 0.0) then
        ray.direction.y := d * cos(angle) / sin(angle)
      else
        ray.direction.y := 1.0;
      ray.direction := Vector_scale(ray.direction, -1 / ray.direction.y /
        point.z);
    end;

  Fisheye_point_to_ray := ray;
end; {function Fisheye_point_to_ray}


function Panoramic_point_to_ray(point: vector_type): ray_type;
var
  ray: ray_type;
  angle: real;
begin
  with current_projection_ptr^ do
    begin
      ray.location := zero_vector; {ray starts at origin}
      angle := point.x / pixel_aspect_ratio / projection_constant;
      ray.direction.x := sin(angle);
      ray.direction.y := cos(angle);
      ray.direction.z := point.y / projection_constant;
      ray.direction := Vector_scale(ray.direction, -1 / ray.direction.y /
        point.z);
    end;

  Panoramic_point_to_ray := ray;
end; {function Panoramic_point_to_ray}


function Project_point_to_ray(point: vector_type): ray_type;
var
  ray: ray_type;
begin
  case current_projection_ptr^.kind of
    orthographic:
      ray := Orthographic_point_to_ray(point);
    perspective:
      ray := Perspective_point_to_ray(point);
    fisheye:
      ray := Fisheye_point_to_ray(point);
    panoramic:
      ray := Panoramic_point_to_ray(point);
  end; {case}

  Project_point_to_ray := ray;
end; {function Project_point_to_ray}


function Reverse_project_point_to_point(point: vector_type): vector_type;
var
  ray: ray_type;
begin
  ray := Project_point_to_ray(point);
  Reverse_project_point_to_point := Vector_sum(ray.location, ray.direction);
end; {function Reverse_project_point_to_point}


{*****************************************************}
{            screen coords to display coords          }
{*****************************************************}


function Screen_to_display(point: vector_type): vector_type;
begin
  with current_projection_ptr^ do
    begin
      point.x := point.x * projection_size.h;
      point.y := (1 - point.y) * projection_size.v;
    end;

  Screen_to_display := point;
end; {function Screen_to_display}


function Display_to_screen(point: vector_type): vector_type;
begin
  with current_projection_ptr^ do
    begin
      point.x := point.x / projection_size.h;
      point.y := 1 - (point.y / projection_size.v);
    end;

  Display_to_screen := point;
end; {function Display_to_screen}


{**************************}
{ routines to manage enums }
{**************************}


procedure Write_projection_kind(kind: projection_kind_type);
begin
  write(Projection_kind_to_str(kind));
end; {procedure Write_projection_kind}


function Projection_kind_to_str(kind: projection_kind_type): string_type;
var
  str: string_type;
begin
  case kind of
    orthographic:
      str := 'orthographic';
    perspective:
      str := 'perspective';
    fisheye:
      str := 'fisheye';
    panoramic:
      str := 'panoramic';
  end; {kind}

  Projection_kind_to_str := str;
end; {function Projection_kind_to_str}


initialization
  projection_free_list := nil;
end.
