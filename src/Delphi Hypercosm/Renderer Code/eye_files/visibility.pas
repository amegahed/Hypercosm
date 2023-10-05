unit visibility;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             visibility                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is used to determine if a bounding          }
{       region is visible inside the viewing region.            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  trans, bounds, project, viewports;


type
  visibility_type = (completely_visible, completely_invisible,
    partially_visible);


function Bounds_visibility(bounds: bounding_type;
  bounds_trans: trans_type;
  viewport_ptr: viewport_ptr_type): visibility_type;
function Center_object(trans: trans_type;
  scene_trans: trans_type;
  projection_ptr: projection_ptr_type): trans_type;
function Visual_size(bounding_kind: bounding_kind_type;
  trans: trans_type;
  projection_ptr: projection_ptr_type): real;
procedure Write_visibility(visibility: visibility_type);


implementation
uses
  math, constants, trigonometry, vectors, vectors2, rays, coord_axes, extents,
  clip_planes, clip_regions, clip_lines;


type
  square_type = array[1..4] of vector2_type;
  projection_plane_type = (xy_plane, yz_plane, xz_plane);


function Unit_cube_intersection(ray: ray_type): real;
var
  point: vector_type;
  t, new_t: real;
  inside: boolean;
begin
  t := infinity;
  inside := false;
  if (abs(ray.location.y) < 1) then {y first because viewer}
    if (abs(ray.location.x) < 1) then {is at negative y}
      if (abs(ray.location.z) < 1) then
        inside := true;

  if inside then {ray originates inside block}
    begin
      if (ray.direction.x <> 0) then
        begin
          if (ray.direction.x > 0) then
            new_t := (1 - ray.location.x) / ray.direction.x
          else
            new_t := (-1 - ray.location.x) / ray.direction.x;
          if (new_t < t) and (new_t > tiny) then
            begin
              point.y := ray.location.y + ray.direction.y * new_t;
              if (abs(point.y) <= 1) then
                begin
                  point.z := ray.location.z + ray.direction.z * new_t;
                  if (abs(point.z) <= 1) then
                    t := new_t;
                end;
            end;
        end;
      if (ray.direction.y <> 0) then
        begin
          if (ray.direction.y > 0) then
            new_t := (1 - ray.location.y) / ray.direction.y
          else
            new_t := (-1 - ray.location.y) / ray.direction.y;
          if (new_t < t) and (new_t > tiny) then
            begin
              point.x := ray.location.x + ray.direction.x * new_t;
              if (abs(point.x) <= 1) then
                begin
                  point.z := ray.location.z + ray.direction.z * new_t;
                  if (abs(point.z) <= 1) then
                    t := new_t;
                end;
            end;
        end;
      if (ray.direction.z <> 0) then
        begin
          if (ray.direction.z > 0) then
            new_t := (1 - ray.location.z) / ray.direction.z
          else
            new_t := (-1 - ray.location.z) / ray.direction.z;
          if (new_t < t) and (new_t > tiny) then
            begin
              point.x := ray.location.x + ray.direction.x * new_t;
              if (abs(point.x) <= 1) then
                begin
                  point.y := ray.location.y + ray.direction.y * new_t;
                  if (abs(point.y) <= 1) then
                    t := new_t;
                end;
            end;
        end;
    end
  else {ray originates outside block}
    begin
      if (ray.direction.x <> 0) then
        begin
          if (ray.direction.x < 0) then
            new_t := (1 - ray.location.x) / ray.direction.x
          else
            new_t := (-1 - ray.location.x) / ray.direction.x;
          if (new_t < t) and (new_t > tiny) then
            begin
              point.y := ray.location.y + ray.direction.y * new_t;
              if (abs(point.y) <= 1) then
                begin
                  point.z := ray.location.z + ray.direction.z * new_t;
                  if (abs(point.z) <= 1) then
                    t := new_t;
                end;
            end;
        end;
      if (ray.direction.y <> 0) then
        begin
          if (ray.direction.y < 0) then
            new_t := (1 - ray.location.y) / ray.direction.y
          else
            new_t := (-1 - ray.location.y) / ray.direction.y;
          if (new_t < t) and (new_t > tiny) then
            begin
              point.x := ray.location.x + ray.direction.x * new_t;
              if (abs(point.x) <= 1) then
                begin
                  point.z := ray.location.z + ray.direction.z * new_t;
                  if (abs(point.z) <= 1) then
                    t := new_t;
                end;
            end;
        end;
      if (ray.direction.z <> 0) then
        begin
          if (ray.direction.z < 0) then
            new_t := (1 - ray.location.z) / ray.direction.z
          else
            new_t := (-1 - ray.location.z) / ray.direction.z;
          if (new_t < t) and (new_t > tiny) then
            begin
              point.x := ray.location.x + ray.direction.x * new_t;
              if (abs(point.x) <= 1) then
                begin
                  point.y := ray.location.y + ray.direction.y * new_t;
                  if (abs(point.y) <= 1) then
                    t := new_t;
                end;
            end;
        end;
    end;
  Unit_cube_intersection := t;
end; {function Unit_cube_intersection}


function Horizontal_ray_intersects_line(ray_origin: vector2_type;
  point1, point2: vector2_type): boolean;
var
  intersects, done: boolean;
  dx, dy: real;
  x_intersect: real;
begin
  intersects := false;
  done := false;

  {*********************************************}
  { first, check if ray_origin lies between the }
  { two endpoints in the vertical (y) direction }
  {*********************************************}
  if (point1.y < point2.y) then
    begin
      if (ray_origin.y < point1.y) or (ray_origin.y > point2.y) then
        done := true;
    end
  else
    begin
      if (ray_origin.y > point1.y) or (ray_origin.y < point2.y) then
        done := true;
    end;

  {*********************************************}
  { if the ray_origin does lie between the two  }
  { endpoints, then find the intersection.      }
  { If we assume that the ray travels to the    }
  { right, then the ray will intersect if the   }
  { intersection point is to the right of the   }
  { ray origin                                  }
  {*********************************************}
  if not done then
    begin
      dx := (point2.x - point1.x);
      dy := (point2.y - point1.y);
      x_intersect := ((ray_origin.y - point1.y) * (dx / dy)) + point1.x;
      intersects := (x_intersect > ray_origin.x)
    end;

  Horizontal_ray_intersects_line := intersects;
end; {function Horizontal_ray_intersects_line}


function Point_in_poly(point: vector2_type;
  square: square_type): boolean;
var
  count: integer;
begin
  {*******************************************}
  {           point in polygon test           }
  {*******************************************}
  { count the number of intersections that a  }
  { horizontal ray makes with the edges.      }
  { If the number is odd, then the point lies }
  { inside. If the number is even, outside.   }
  {*******************************************}
  count := 0;
  if Horizontal_ray_intersects_line(point, square[1], square[2]) then
    count := count + 1;
  if Horizontal_ray_intersects_line(point, square[2], square[3]) then
    count := count + 1;
  if Horizontal_ray_intersects_line(point, square[3], square[4]) then
    count := count + 1;
  if Horizontal_ray_intersects_line(point, square[4], square[1]) then
    count := count + 1;

  Point_in_poly := (count mod 2 = 1);
end; {function Point_in_poly}


function Project_point(vector: vector_type;
  projection_plane: projection_plane_type): vector2_type;
var
  vector2: vector2_type;
begin
  case projection_plane of
    yz_plane:
      begin
        {**********************}
        { project along x axis }
        {**********************}
        vector2.x := vector.y;
        vector2.y := vector.z;
      end;
    xz_plane:
      begin
        {**********************}
        { project along y axis }
        {**********************}
        vector2.x := vector.x;
        vector2.y := vector.z;
      end;
    xy_plane:
      begin
        {**********************}
        { project along z axis }
        {**********************}
        vector2.x := vector.x;
        vector2.y := vector.y;
      end;
  end; {case}
  Project_point := vector2;
end; {function Project_point}


function Project_square(var bounding_square: bounding_square_type;
  projection_plane: projection_plane_type): square_type;
var
  square: square_type;
begin
  case projection_plane of
    yz_plane:
      begin
        {**********************}
        { project along x axis }
        {**********************}
        square[1].x := bounding_square[left, front].y;
        square[1].y := bounding_square[left, front].z;

        square[2].x := bounding_square[right, front].y;
        square[2].y := bounding_square[right, front].z;

        square[3].x := bounding_square[right, back].y;
        square[3].y := bounding_square[right, back].z;

        square[4].x := bounding_square[left, back].y;
        square[4].y := bounding_square[left, back].z;
      end;

    xz_plane:
      begin
        {**********************}
        { project along y axis }
        {**********************}
        square[1].x := bounding_square[left, front].x;
        square[1].y := bounding_square[left, front].z;

        square[2].x := bounding_square[right, front].x;
        square[2].y := bounding_square[right, front].z;

        square[3].x := bounding_square[right, back].x;
        square[3].y := bounding_square[right, back].z;

        square[4].x := bounding_square[left, back].x;
        square[4].y := bounding_square[left, back].z;
      end;

    xy_plane:
      begin
        {**********************}
        { project along z axis }
        {**********************}
        square[1].x := bounding_square[left, front].x;
        square[1].y := bounding_square[left, front].y;

        square[2].x := bounding_square[right, front].x;
        square[2].y := bounding_square[right, front].y;

        square[3].x := bounding_square[right, back].x;
        square[3].y := bounding_square[right, back].y;

        square[4].x := bounding_square[left, back].x;
        square[4].y := bounding_square[left, back].y;
      end;
  end; {case}

  Project_square := square;
end; {function Project_square}


function Plane_intersection(normal: vector_type;
  ray: ray_type): real;
{***************************************}
{ this intersection test is specialized }
{ for planes at the origin.             }
{***************************************}
var
  temp: real;
  {**********************************}
  { parametric location of the       }
  { intersection point along the ray }
  {**********************************}
  t: real;
begin
  temp := Dot_product(ray.direction, normal);
  if (abs(temp) < tiny) then
    t := infinity {ray is parallel to plane}
  else
    begin
      t := Dot_product(ray.location, normal) / temp;
      if (t < tiny) then
        t := infinity;
    end;
  Plane_intersection := t;
end; {function Plane_intersection}


function Normal_to_projection_plane(normal: vector_type): projection_plane_type;
var
  projection_plane: projection_plane_type;
begin
  if abs(normal.x) > abs(normal.y) then
    begin
      if abs(normal.x) > abs(normal.z) then
        projection_plane := yz_plane
      else
        projection_plane := xy_plane;
    end
  else
    begin
      if abs(normal.y) > abs(normal.z) then
        projection_plane := xz_plane
      else
        projection_plane := xy_plane;
    end;
  Normal_to_projection_plane := projection_plane;
end; {function Normal_to_projection_plane}


function Square_clips_ray(var bounding_square: bounding_square_type;
  bounds_trans: trans_type;
  ray_direction: vector_type): boolean;
var
  ray: ray_type;
  normal: vector_type;
  projection_plane: projection_plane_type;
  square: square_type;
  vector: vector_type;
  vector2: vector2_type;
  t: real;
  clips: boolean;
begin
  normal := bounds_trans.z_axis;
  ray.location := bounds_trans.origin;
  ray.direction := ray_direction;
  t := Plane_intersection(normal, ray);

  if (t = infinity) then
    clips := false
  else
    begin
      projection_plane := Normal_to_projection_plane(normal);
      vector := Vector_scale(ray_direction, t);
      vector2 := Project_point(vector, projection_plane);
      square := Project_square(bounding_square, projection_plane);
      clips := Point_in_poly(vector2, square);
    end;
  Square_clips_ray := clips;
end; {function Square_clips_ray}


function Box_clips_ray(var bounds_trans: trans_type;
  ray_direction: vector_type): boolean;
var
  coord_axes: coord_axes_type;
  ray: ray_type;
  t: real;
begin
  ray.location := zero_vector;
  ray.direction := ray_direction;

  coord_axes := Trans_to_axes(bounds_trans);
  Transform_point_to_axes(ray.location, coord_axes);
  Transform_vector_to_axes(ray.direction, coord_axes);

  t := Unit_cube_intersection(ray);

  if (t <> infinity) then
    Box_clips_ray := true
  else
    Box_clips_ray := false;
end; {function Box_clips_ray}


function Axes_clips_ray(var coord_axes: coord_axes_type;
  ray_direction: vector_type): boolean;
var
  ray: ray_type;
  t: real;
begin
  ray.location := zero_vector;
  ray.direction := ray_direction;

  Transform_point_to_axes(ray.location, coord_axes);
  Transform_vector_to_axes(ray.direction, coord_axes);

  t := Unit_cube_intersection(ray);

  if (t <> infinity) then
    Axes_clips_ray := true
  else
    Axes_clips_ray := false;
end; {function Axes_clips_ray}


function Square_in_pyramid(var square: bounding_square_type;
  bounds_trans: trans_type;
  pyramid: pyramid_type): visibility_type;
var
  visibility: visibility_type;
begin
  {******************************************}
  {                  test #1                 }
  {            edge intersections            }
  {******************************************}
  { do any edges of pyramid intersect square }
  { or any edges of square intersect pyramid }
  {******************************************}

  {*************************}
  { square edges vs pyramid }
  {*************************}
  if Frustrum_clips_line(pyramid.frustrum, To_line(square[right, front],
    square[right, back])) then
    visibility := partially_visible
  else if Frustrum_clips_line(pyramid.frustrum, To_line(square[right, back],
    square[left, back])) then
    visibility := partially_visible
  else if Frustrum_clips_line(pyramid.frustrum, To_line(square[left, back],
    square[left, front])) then
    visibility := partially_visible
  else if Frustrum_clips_line(pyramid.frustrum, To_line(square[left, front],
    square[right, front])) then
    visibility := partially_visible

    {*************************}
    { pyramid edges vs square }
    {*************************}
  else if Square_clips_ray(square, bounds_trans, pyramid.bottom_right) then
    visibility := partially_visible
  else if Square_clips_ray(square, bounds_trans, pyramid.bottom_left) then
    visibility := partially_visible
  else if Square_clips_ray(square, bounds_trans, pyramid.top_right) then
    visibility := partially_visible
  else if Square_clips_ray(square, bounds_trans, pyramid.top_left) then
    visibility := partially_visible

    {******************************************}
    {                  test #2                 }
    {            point classification          }
    {******************************************}
    { is any point on square inside of pyramid }
    {******************************************}
  else if Point_in_frustrum(square[left, front], pyramid.frustrum) then
    visibility := completely_visible
  else
    visibility := completely_invisible;

  Square_in_pyramid := visibility;
end; {function Square_in_pyramid}


function Box_in_pyramid(var box: bounding_box_type;
  bounds_trans: trans_type;
  pyramid: pyramid_type): visibility_type;
var
  visibility: visibility_type;
  coord_axes: coord_axes_type;
begin
  {***************************************}
  {                 test #1               }
  {           edge intersections          }
  {***************************************}
  { do any edges of pyramid intersect box }
  { or any edges of box intersect pyramid }
  {***************************************}

  {**********************}
  { box edges vs pyramid }
  {**********************}

  {***********}
  { top edges }
  {***********}
  if Frustrum_clips_line(pyramid.frustrum, To_line(box[right, front, top],
    box[right, back, top])) then
    visibility := partially_visible
  else if Frustrum_clips_line(pyramid.frustrum, To_line(box[right, back, top],
    box[left, back, top])) then
    visibility := partially_visible
  else if Frustrum_clips_line(pyramid.frustrum, To_line(box[left, back, top],
    box[left, front, top])) then
    visibility := partially_visible
  else if Frustrum_clips_line(pyramid.frustrum, To_line(box[left, front, top],
    box[right, front, top])) then
    visibility := partially_visible

    {**************}
    { bottom edges }
    {**************}
  else if Frustrum_clips_line(pyramid.frustrum, To_line(box[right, front,
    bottom], box[right, back, bottom])) then
    visibility := partially_visible
  else if Frustrum_clips_line(pyramid.frustrum, To_line(box[right, back,
    bottom], box[left, back, bottom])) then
    visibility := partially_visible
  else if Frustrum_clips_line(pyramid.frustrum, To_line(box[left, back, bottom],
    box[left, front, bottom])) then
    visibility := partially_visible
  else if Frustrum_clips_line(pyramid.frustrum, To_line(box[left, front,
    bottom], box[right, front, bottom])) then
    visibility := partially_visible

    {************}
    { side edges }
    {************}
  else if Frustrum_clips_line(pyramid.frustrum, To_line(box[right, front,
    bottom], box[right, front, top])) then
    visibility := partially_visible
  else if Frustrum_clips_line(pyramid.frustrum, To_line(box[right, back,
    bottom], box[right, back, top])) then
    visibility := partially_visible
  else if Frustrum_clips_line(pyramid.frustrum, To_line(box[left, back, bottom],
    box[left, back, top])) then
    visibility := partially_visible
  else if Frustrum_clips_line(pyramid.frustrum, To_line(box[left, front,
    bottom], box[left, front, top])) then
    visibility := partially_visible

    {**********************}
    { pyramid edges vs box }
    {**********************}
  else
    begin
      coord_axes := Trans_to_axes(bounds_trans);
      if Axes_clips_ray(coord_axes, pyramid.bottom_right) then
        visibility := partially_visible
      else if Axes_clips_ray(coord_axes, pyramid.bottom_left) then
        visibility := partially_visible
      else if Axes_clips_ray(coord_axes, pyramid.top_right) then
        visibility := partially_visible
      else if Axes_clips_ray(coord_axes, pyramid.top_left) then
        visibility := partially_visible

        {***************************************}
        {                test #2                }
        {          point classification         }
        {***************************************}
        { is any point on box inside of pyramid }
        {***************************************}
      else if Point_in_frustrum(box[left, front, bottom], pyramid.frustrum) then
        visibility := completely_visible
      else
        visibility := completely_invisible;
    end;

  Box_in_pyramid := visibility;
end; {function Box_in_pyramid}


function Square_in_hemispace(square: bounding_square_type;
  plane: plane_type): visibility_type;
var
  square_point: vector_type;
  counter1, counter2: extent_type;
  points_inside: boolean;
  points_outside: boolean;
  visibility: visibility_type;
begin
  points_inside := false;
  points_outside := false;

  for counter1 := left to right do
    for counter2 := front to back do
      if not (points_inside and points_outside) then
        begin
          square_point := Vector_difference(square[counter1, counter2],
            plane.origin);
          if (Dot_product(square_point, plane.normal) > 0) then
            points_inside := true
          else
            points_outside := true;
        end;

  if points_inside and points_outside then
    visibility := partially_visible
  else if points_inside then
    visibility := completely_visible
  else
    visibility := completely_invisible;

  Square_in_hemispace := visibility;
end; {function Square_in_hemispace}


function Box_in_hemispace(box: bounding_box_type;
  plane: plane_type): visibility_type;
var
  box_point: vector_type;
  counter1, counter2, counter3: extent_type;
  points_inside: boolean;
  points_outside: boolean;
  visibility: visibility_type;
begin
  points_inside := false;
  points_outside := false;

  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        if not (points_inside and points_outside) then
          begin
            box_point := Vector_difference(box[counter1, counter2, counter3],
              plane.origin);
            if (Dot_product(box_point, plane.normal) > 0) then
              points_inside := true
            else
              points_outside := true;
          end;

  if points_inside and points_outside then
    visibility := partially_visible
  else if points_inside then
    visibility := completely_visible
  else
    visibility := completely_invisible;

  Box_in_hemispace := visibility;
end; {function Box_in_hemispace}


{*******************************************}
{ routines for finding visibility of bounds }
{*******************************************}


function Bounds_in_hemispace(bounds: bounding_type;
  plane: plane_type): visibility_type;
var
  visibility: visibility_type;
begin
  visibility := partially_visible;

  case bounds.bounding_kind of

    null_bounds:
      visibility := completely_visible;

    infinite_non_planar_bounds:
      visibility := partially_visible;

    infinite_planar_bounds:
      visibility := partially_visible;

    planar_bounds:
      visibility := Square_in_hemispace(bounds.bounding_square, plane);

    non_planar_bounds:
      visibility := Box_in_hemispace(bounds.bounding_box, plane);

  end; {case}

  Bounds_in_hemispace := visibility;
end; {function Bounds_in_hemispace}


function Bounds_in_pyramid(bounds: bounding_type;
  bounds_trans: trans_type;
  pyramid: pyramid_type): visibility_type;
var
  visibility: visibility_type;
begin
  visibility := partially_visible;

  case bounds.bounding_kind of

    null_bounds:
      visibility := completely_visible;

    infinite_non_planar_bounds:
      visibility := partially_visible;

    infinite_planar_bounds:
      visibility := partially_visible;

    planar_bounds:
      visibility := Square_in_pyramid(bounds.bounding_square, bounds_trans,
        pyramid);

    non_planar_bounds:
      visibility := Box_in_pyramid(bounds.bounding_box, bounds_trans, pyramid);

  end; {case}

  Bounds_in_pyramid := visibility;
end; {function Bounds_in_pyramid}


function Bounds_in_anti_pyramid(bounds: bounding_type;
  bounds_trans: trans_type;
  pyramid: pyramid_type): visibility_type;
var
  visibility: visibility_type;
begin
  visibility := Bounds_in_pyramid(bounds, bounds_trans, pyramid);

  if (visibility = completely_invisible) then
    visibility := completely_visible
  else if (visibility = completely_visible) then
    visibility := completely_invisible;

  Bounds_in_anti_pyramid := visibility;
end; {function Bounds_in_anti_pyramid}


function Bounds_in_ortho_region(bounds: bounding_type;
  ortho_region: ortho_region_type): visibility_type;
var
  visibility: visibility_type;
  complete_visibility: boolean;
begin
  complete_visibility := true;

  with ortho_region do
    begin
      {**************************}
      { test left clipping plane }
      {**************************}
      visibility := Bounds_in_hemispace(bounds, left_plane);
      if visibility <> completely_invisible then
        begin
          if visibility <> completely_visible then
            complete_visibility := false;

          {***************************}
          { test right clipping plane }
          {***************************}
          visibility := Bounds_in_hemispace(bounds, right_plane);
          if visibility <> completely_invisible then
            begin
              if visibility <> completely_visible then
                complete_visibility := false;

              {****************************}
              { test bottom clipping plane }
              {****************************}
              visibility := Bounds_in_hemispace(bounds, bottom_plane);
              if visibility <> completely_invisible then
                begin
                  if visibility <> completely_visible then
                    complete_visibility := false;

                  {*************************}
                  { test top clipping plane }
                  {*************************}
                  visibility := Bounds_in_hemispace(bounds, top_plane);
                  if visibility <> completely_invisible then
                    begin
                      if visibility <> completely_visible then
                        complete_visibility := false;

                      {*****************************}
                      { front / back clipping plane }
                      {*****************************}
                      visibility := Bounds_in_hemispace(bounds, eye_plane);
                      if visibility <> completely_invisible then
                        begin
                          if visibility <> completely_visible then
                            complete_visibility := false;

                          {**********}
                          { all done }
                          {**********}
                          if complete_visibility then
                            visibility := completely_visible
                          else
                            visibility := partially_visible;
                        end;
                    end;
                end;
            end;
        end;
    end;

  Bounds_in_ortho_region := visibility;
end; {function Bounds_in_ortho_region}


function Bounds_visibility(bounds: bounding_type;
  bounds_trans: trans_type;
  viewport_ptr: viewport_ptr_type): visibility_type;
var
  visibility: visibility_type;
begin
  visibility := partially_visible;

  with viewport_ptr^ do
    case kind of

      orthographic:
        visibility := Bounds_in_ortho_region(bounds, ortho_region);

      perspective:
        visibility := Bounds_in_pyramid(bounds, bounds_trans, clip_pyramid);

      fisheye:
        begin
          if convex then
            begin
              {*************************************}
              { field of view less than 180 degrees }
              {*************************************}
              visibility := Bounds_in_pyramid(bounds, bounds_trans,
                inner_pyramid);
              if (visibility = completely_invisible) then
                begin
                  if Bounds_in_pyramid(bounds, bounds_trans, outer_pyramid) <>
                    completely_invisible then
                    visibility := partially_visible;
                end;
            end
          else if not concave then
            begin
              {************************************}
              { field of view equal to 180 degrees }
              {************************************}
              visibility := Bounds_in_pyramid(bounds, bounds_trans,
                inner_pyramid);
              if (visibility = completely_invisible) then
                if Bounds_in_hemispace(bounds, To_plane(zero_vector, y_vector))
                  <> completely_invisible then
                  visibility := partially_visible;
            end
          else
            begin
              {****************************************}
              { field of view greater than 180 degrees }
              {****************************************}
              case inner_pyramid.frustrum.kind of
                pyramidal:
                  visibility := Bounds_in_pyramid(bounds, bounds_trans,
                    inner_pyramid);
                antipyramidal:
                  visibility := Bounds_in_hemispace(bounds,
                    To_plane(zero_vector, y_vector));
              end;
              if (visibility = completely_invisible) then
                if Bounds_in_anti_pyramid(bounds, bounds_trans, outer_pyramid)
                  <> completely_invisible then
                  visibility := partially_visible;
            end;
        end;

      panoramic:
        begin
          if convex then
            begin
              {*************************************}
              { field of view less than 180 degrees }
              {*************************************}
              visibility := Bounds_in_pyramid(bounds, bounds_trans,
                inner_pyramid);
              if (visibility = completely_invisible) then
                if Bounds_in_pyramid(bounds, bounds_trans, outer_pyramid) <>
                  completely_invisible then
                  visibility := partially_visible;
            end
          else if not concave then
            begin
              {************************************}
              { field of view equal to 180 degrees }
              {************************************}
              visibility := Bounds_in_pyramid(bounds, bounds_trans,
                inner_pyramid);
              if (visibility = completely_invisible) then
                if Bounds_in_hemispace(bounds, To_plane(zero_vector, y_vector))
                  = completely_invisible then
                  visibility := completely_invisible
                else
                  visibility := partially_visible;
            end
          else
            begin
              {****************************************}
              { field of view greater than 180 degrees }
              {****************************************}
              visibility := Bounds_in_pyramid(bounds, bounds_trans,
                inner_pyramid);
              if (visibility = completely_invisible) then
                if Bounds_in_anti_pyramid(bounds, bounds_trans, outer_pyramid)
                  <> completely_invisible then
                  visibility := partially_visible;
            end;
        end;
    end; {case}

  Bounds_visibility := visibility;
end; {function Bounds_visibility}


function Center_object(trans: trans_type;
  scene_trans: trans_type;
  projection_ptr: projection_ptr_type): trans_type;
var
  factor, angle: real;
  vector1, vector2, vector3: vector_type;
begin
  trans.origin := zero_vector;

  {**********************************}
  { transform object to scene coords }
  {**********************************}
  Transform_trans(trans, scene_trans);

  {***************************************}
  { now Vector_scale object to fit field of view }
  {***************************************}
  with trans do
    begin
      vector3 := Vector_sum(Vector_sum(x_axis, y_axis), z_axis);
      vector2 := Vector_difference(origin, vector3);
      vector1 := Vector_sum(origin, vector3);
    end;

  factor := 0;
  with projection_ptr^ do
    case kind of

      orthographic:
        begin
          {********************************************}
          { make object take up a fraction of the view }
          {********************************************}
          angle := sqrt(sqr(vector1.x - vector2.x) + sqr(vector1.z -
            vector2.z));
          factor := (field_of_view * 0.6) / angle;

          with trans do
            begin
              x_axis := Vector_scale(x_axis, factor);
              y_axis := Vector_scale(y_axis, factor);
              z_axis := Vector_scale(z_axis, factor);
            end;
        end;

      perspective, fisheye, panoramic:
        begin
          {************************************************}
          { set angle subtended by object in this position }
          {************************************************}
          angle := (field_of_view / 3) * (pi / 180.0);
          factor := Vector_length(vector3) / tan(angle);
        end;

    end; {case}

  with trans do
    begin
      origin.x := 0;
      origin.y := factor;
      origin.z := 0;
    end;

  Center_object := trans;
end; {function Center_object}


function Visual_size(bounding_kind: bounding_kind_type;
  trans: trans_type;
  projection_ptr: projection_ptr_type): real;
var
  size, distance: real;
  fraction: real;
begin
  fraction := 0;

  with trans do
    if (bounding_kind = planar_bounds) then
      size := Vector_length(Vector_sum(x_axis, y_axis))
    else if (bounding_kind = non_planar_bounds) then
      size := Vector_length(Vector_sum(Vector_sum(x_axis, y_axis), z_axis))
    else
      size := 0;

  with projection_ptr^ do
    case kind of

      orthographic:
        begin
          if bounding_kind in finite_bounding_kinds then
            fraction := size / field_of_view
          else
            fraction := 1;
        end;

      perspective, fisheye, panoramic:
        begin
          distance := Vector_length(trans.origin);
          if bounding_kind in finite_bounding_kinds then
            fraction := (2.0 * radians_to_degrees * ARCTAN(size / distance)) /
              field_of_view
          else
            fraction := 180.0 / field_of_view;
        end;

    end; {case}

  Visual_size := fraction;
end; {function Visual_size}


procedure Write_visibility(visibility: visibility_type);
begin
  case visibility of
    completely_visible:
      write('completely_visible');
    completely_invisible:
      write('completely_invisible');
    partially_visible:
      write('partially_visible');
  end;
end; {procedure Write_visibility}


end.
