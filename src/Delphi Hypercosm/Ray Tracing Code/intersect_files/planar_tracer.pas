unit planar_tracer;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           planar_tracer               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is used to find intersections between       }
{       rays and planar primitives.                             }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, rays, trans, triangles, polygons, raytrace;


var
  last_ray_normal_interpolation: interpolation_type;
  last_ray_texture_interpolation: interpolation_type;
  last_ray_u_axis_interpolation: interpolation_type;
  last_ray_v_axis_interpolation: interpolation_type;
  last_ray_normal: vector_type;


function Plane_intersection(ray: ray_type;
  tmin, tmax: real): real;
function Disk_intersection(ray: ray_type;
  tmin, tmax: real;
  umin, umax: real): real;
function Ring_intersection(ray: ray_type;
  tmin, tmax: real;
  inner_radius: real;
  umin, umax: real): real;
function Triangle_intersection(ray: ray_type;
  tmin, tmax: real): real;
function Parallelogram_intersection(ray: ray_type;
  tmin, tmax: real): real;
function Polygon_triangle_intersection(ray: ray_type;
  tmin, tmax: real;
  triangle_ptr: triangle_ptr_type): real;
function Polygon_intersection(ray: ray_type;
  tmin, tmax: real;
  polygon_vertex_ptr: polygon_vertex_ptr_type): real;


implementation
uses
  constants, binormals, coord_axes, quadric_tracer;


{*******************}
{ planar primitives }
{*******************}


function Plane_intersection(ray: ray_type;
  tmin, tmax: real): real;
var
  t: real;
begin
  if (abs(ray.direction.z) < tiny) then
    {**************************}
    { ray is parallel to plane }
    {**************************}
    t := infinity
  else
    begin
      t := -(ray.location.z / ray.direction.z);
      if (t < tmin) or (t > tmax) then
        {*********************************}
        { intersection is behind observer }
        {*********************************}
        t := infinity;
    end;
  Plane_intersection := t;
end; {function Plane_intersection}


function Disk_intersection(ray: ray_type;
  tmin, tmax: real;
  umin, umax: real): real;
var
  t: real;
  point: vector_type;
begin
  if (abs(ray.direction.z) < tiny) then
    {**************************}
    { ray is parallel to plane }
    {**************************}
    t := infinity
  else
    begin
      t := -(ray.location.z / ray.direction.z);
      if (t < tmin) or (t > tmax) then
        {*********************************}
        { intersection is behind observer }
        {*********************************}
        t := infinity
      else if (sqr(ray.location.x + (t * ray.direction.x)) + sqr(ray.location.y
        + (t * ray.direction.y)) > 1) then
        t := infinity;
    end;

  {*********************}
  { check sweep surface }
  {*********************}
  if (t <> infinity) then
    if (umin <> 0) or (umax <> 360) then
      begin
        point := Vector_sum(ray.location, Vector_scale(ray.direction, t));
        if not Longitude_ok(point.x, point.y, umin, umax) then
          t := infinity;
      end;

  Disk_intersection := t;
end; {function Disk_intersection}


function Ring_intersection(ray: ray_type;
  tmin, tmax: real;
  inner_radius: real;
  umin, umax: real): real;
var
  t, d: real;
  point: vector_type;
begin
  if (abs(ray.direction.z) < tiny) then
    {**************************}
    { ray is parallel to plane }
    {**************************}
    t := infinity
  else
    begin
      t := -(ray.location.z / ray.direction.z);
      if (t < tmin) or (t > tmax) then
        {*********************************}
        { intersection is behind observer }
        {*********************************}
        t := infinity
      else
        begin
          d := (sqr(ray.location.x + (t * ray.direction.x)) + sqr(ray.location.y
            + (t * ray.direction.y)));
          if (d > 1.0) or (d < sqr(inner_radius)) then
            t := infinity;
        end;
    end;

  {*********************}
  { check sweep surface }
  {*********************}
  if (t <> infinity) then
    if (umin <> 0) or (umax <> 360) then
      begin
        point := Vector_sum(ray.location, Vector_scale(ray.direction, t));
        if not Longitude_ok(point.x, point.y, umin, umax) then
          t := infinity;
      end;

  Ring_intersection := t;
end; {function Ring_intersection}


function Triangle_intersection(ray: ray_type;
  tmin, tmax: real): real;
var
  x, y: real;
  t: real;
begin
  if (abs(ray.direction.z) < tiny) then
    {**************************}
    { ray is parallel to plane }
    {**************************}
    t := infinity
  else
    begin
      t := -(ray.location.z / ray.direction.z);
      if (t < tmin) or (t > tmax) then
        {*********************************}
        { intersection is behind observer }
        {*********************************}
        t := infinity
      else
        begin
          {*************************************}
          { project intersection point to plane }
          {*************************************}
          x := ray.location.x + (t * ray.direction.x);
          y := ray.location.y + (t * ray.direction.y);

          {************************}
          { bounding triangle test }
          {************************}
          if ((x <= -1) or (y <= -1) or (y >= -x)) then
            t := infinity;
        end;
    end;
  Triangle_intersection := t;
end; {function Triangle_intersection}


function Parallelogram_intersection(ray: ray_type;
  tmin, tmax: real): real;
var
  x, y: real;
  t: real;
begin
  if (abs(ray.direction.z) < tiny) then
    {**************************}
    { ray is parallel to plane }
    {**************************}
    t := infinity
  else
    begin
      t := -(ray.location.z / ray.direction.z);
      if (t < tmin) or (t > tmax) then
        {*********************************}
        { intersection is behind observer }
        {*********************************}
        t := infinity
      else
        begin
          {*************************************}
          { project intersection point to plane }
          {*************************************}
          x := ray.location.x + (t * ray.direction.x);
          y := ray.location.y + (t * ray.direction.y);

          {*******************}
          { bounding box test }
          {*******************}
          if ((x <= -1) or (x >= 1) or (y <= -1) or (y >= 1)) then
            t := infinity;
        end;
    end;
  Parallelogram_intersection := t;
end; {function Parallelogram_intersection}


function Polygon_triangle_intersection(ray: ray_type;
  tmin, tmax: real;
  triangle_ptr: triangle_ptr_type): real;
var
  original_ray: ray_type;
  texture1, texture2, texture3: vector_type;
  u_axis1, u_axis2, u_axis3: vector_type;
  v_axis1, v_axis2, v_axis3: vector_type;
  x, y: real;
  t, interpolation_t: real;
begin
  t := infinity;
  original_ray := ray;

  while (triangle_ptr <> nil) and (t = infinity) do
    begin
      ray := original_ray;
      Transform_ray(ray, triangle_ptr^.trans);

      if (abs(ray.direction.z) < tiny) then
        {**************************}
        { ray is parallel to plane }
        {**************************}
        t := infinity
      else
        begin
          t := -(ray.location.z / ray.direction.z);
          if (t < tmin) or (t > tmax) then
            {*********************************}
            { intersection is behind observer }
            {*********************************}
            t := infinity
          else
            begin
              {*************************************}
              { project intersection point to plane }
              {*************************************}
              x := ray.location.x + (t * ray.direction.x);
              y := ray.location.y + (t * ray.direction.y);

              {************************}
              { bounding triangle test }
              {************************}
              if (x < 0) or (y < 0) or (x + y > 1) then
                t := infinity
              else
                begin
                  interpolation_t := x / (1 - y);

                  {****************************}
                  { save texture interpolation }
                  {****************************}
                  texture1 :=
                    triangle_ptr^.vertex_ptr1^.vertex_geometry_ptr^.texture;
                  texture2 :=
                    triangle_ptr^.vertex_ptr2^.vertex_geometry_ptr^.texture;
                  texture3 :=
                    triangle_ptr^.vertex_ptr3^.vertex_geometry_ptr^.texture;

                  with last_ray_texture_interpolation do
                    begin
                      left_vector1 := texture2;
                      left_vector2 := texture1;
                      left_t := y;
                      right_vector1 := texture3;
                      right_vector2 := texture1;
                      right_t := y;
                      t := interpolation_t;
                    end;

                  {***************************}
                  { save u_axis interpolation }
                  {***************************}
                  u_axis1 :=
                    triangle_ptr^.vertex_ptr1^.vertex_geometry_ptr^.u_axis;
                  u_axis2 :=
                    triangle_ptr^.vertex_ptr2^.vertex_geometry_ptr^.u_axis;
                  u_axis3 :=
                    triangle_ptr^.vertex_ptr3^.vertex_geometry_ptr^.u_axis;

                  with last_ray_u_axis_interpolation do
                    begin
                      left_vector1 := u_axis2;
                      left_vector2 := u_axis1;
                      left_t := y;
                      right_vector1 := u_axis3;
                      right_vector2 := u_axis1;
                      right_t := y;
                      t := interpolation_t;
                    end;

                  {***************************}
                  { save v_axis interpolation }
                  {***************************}
                  v_axis1 :=
                    triangle_ptr^.vertex_ptr1^.vertex_geometry_ptr^.v_axis;
                  v_axis2 :=
                    triangle_ptr^.vertex_ptr2^.vertex_geometry_ptr^.v_axis;
                  v_axis3 :=
                    triangle_ptr^.vertex_ptr3^.vertex_geometry_ptr^.v_axis;

                  with last_ray_v_axis_interpolation do
                    begin
                      left_vector1 := v_axis2;
                      left_vector2 := v_axis1;
                      left_t := y;
                      right_vector1 := v_axis3;
                      right_vector2 := v_axis1;
                      right_t := y;
                      t := interpolation_t;
                    end;

                end;
            end;
        end;

      triangle_ptr := triangle_ptr^.next;
    end;

  Polygon_triangle_intersection := t;
end; {function Polygon_triangle_intersection}


function Polygon_intersection(ray: ray_type;
  tmin, tmax: real;
  polygon_vertex_ptr: polygon_vertex_ptr_type): real;
var
  binormal: binormal_type;
  trans: trans_type;
  coord_axes: coord_axes_type;
  follow: polygon_vertex_ptr_type;
  first_vertex, vertex1, vertex2: vector_type;
  first_vertex_ptr, vertex_ptr1, vertex_ptr2: polygon_vertex_ptr_type;
  intersection: boolean;
  left, right: vector_type;
  count: integer;
  t, x: real;
begin
  {*************************************************************}
  { this polygon test differs from the previous one because     }
  { it uses the straight geometric definition of the polygon    }
  { instead of the triangulated one. In order for this to work, }
  { we must do the point in polygon test in the reference frame }
  { of the ray to handle non-coplanar polygons.                 }
  {*************************************************************}

  {***************************************}
  { compute transformation to axes of ray }
  {***************************************}
  binormal := Normal_to_binormal(ray.direction);
  trans.origin := ray.location;
  trans.x_axis := binormal.x_axis;
  trans.y_axis := binormal.y_axis;
  trans.z_axis := ray.direction;
  coord_axes := Trans_to_axes(trans);

  right.x := infinity;
  left.x := -infinity;
  count := 0;
  vertex1 := polygon_vertex_ptr^.point;
  vertex_ptr1 := polygon_vertex_ptr;
  Transform_point_to_axes(vertex1, coord_axes);
  first_vertex := vertex1;
  first_vertex_ptr := vertex_ptr1;

  {***********************}
  { point in polygon test }
  {***********************}
  follow := polygon_vertex_ptr;
  while (follow <> nil) do
    begin
      follow := follow^.next;
      if (follow <> nil) then
        begin
          vertex2 := follow^.point;
          vertex_ptr2 := follow;
          Transform_point_to_axes(vertex2, coord_axes);
        end
      else
        begin
          vertex2 := first_vertex;
          vertex_ptr2 := first_vertex_ptr;
        end;

      {*******************************************}
      { look for intersection with horizontal ray }
      {*******************************************}
      intersection := (vertex1.y < 0) and (vertex2.y > 0);
      if not intersection then
        intersection := (vertex1.y > 0) and (vertex2.y < 0);

      if intersection then
        begin
          {****************************}
          { compute intersection point }
          {****************************}
          t := vertex1.y / (vertex1.y - vertex2.y);
          x := vertex1.x + (vertex2.x - vertex1.x) * t;

          {******************}
          { increment parity }
          {******************}
          if x > 0 then
            count := count + 1;

          {******************************}
          { update left and right bounds }
          {******************************}
          if (x > 0) then
            begin
              if (x < right.x) then
                begin
                  right.x := x;
                  right.y := 0;
                  right.z := vertex1.z + (vertex2.z - vertex1.z) * t;

                  {***************************************************}
                  { save right edge texture interpolation information }
                  {***************************************************}
                  last_ray_texture_interpolation.right_vector1 :=
                    vertex_ptr1^.texture;
                  last_ray_texture_interpolation.right_vector2 :=
                    vertex_ptr2^.texture;
                  last_ray_texture_interpolation.right_t := t;
                end;
            end
          else
            begin
              if (x > left.x) then
                begin
                  left.x := x;
                  left.y := 0;
                  left.z := vertex1.z + (vertex2.z - vertex1.z) * t;

                  {**************************************************}
                  { save left edge texture interpolation information }
                  {**************************************************}
                  last_ray_texture_interpolation.left_vector1 :=
                    vertex_ptr1^.texture;
                  last_ray_texture_interpolation.left_vector2 :=
                    vertex_ptr2^.texture;
                  last_ray_texture_interpolation.left_t := t;
                end;
            end; {update bounds}
        end; {if intersection}

      {************************}
      { update previous vertex }
      {************************}
      vertex1 := vertex2;
      vertex_ptr1 := vertex_ptr2;
    end; {while}

  {****************************************}
  { if odd parity, then intersection found }
  {****************************************}
  if (count mod 2 = 1) then
    begin
      x := left.x / (left.x - right.x);

      {************************************}
      { save information on interpolating  }
      { between the right and left edges.  }
      {************************************}
      last_ray_texture_interpolation.t := x;
      last_ray_u_axis_interpolation.t := x;
      last_ray_v_axis_interpolation.t := x;

      t := left.z + (right.z - left.z) * x;
      if (t < tmin) or (t > tmax) then
        t := infinity;
    end
  else
    t := infinity;

  Polygon_intersection := t;
end; {function Polygon_intersection}


end.
