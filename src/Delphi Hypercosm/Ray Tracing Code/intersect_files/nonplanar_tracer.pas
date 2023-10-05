unit nonplanar_tracer;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          nonplanar_tracer             3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is used to find intersections between       }
{       rays and non_planar primitives.                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  rays, triangles, polygons, objects, raytrace, quadric_tracer;


function Unit_cube_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type): real;

function Shaded_triangle_intersection(ray: ray_type;
  tmin, tmax: real;
  triangle_normal_ptr: triangle_normal_ptr_type): real;

function Shaded_polygon_triangle_intersection(ray: ray_type;
  tmin, tmax: real;
  triangle_ptr: triangle_ptr_type): real;

function Shaded_polygon_intersection(ray: ray_type;
  tmin, tmax: real;
  shaded_polygon_vertex_ptr: shaded_polygon_vertex_ptr_type): real;


implementation
uses
  constants, vectors, binormals, trans, coord_axes, planar_tracer;


function Unit_cube_back_face_intersection(ray: ray_type;
  tmin, tmax: real): real;
var
  point: vector_type;
  t, new_t: real;
begin
  t := infinity;

  if (ray.direction.x <> 0) then
    begin
      if (ray.direction.x > 0) then
        new_t := (1 - ray.location.x) / ray.direction.x
      else
        new_t := (-1 - ray.location.x) / ray.direction.x;
      if (new_t > tmin) and (new_t < tmax) then
        begin
          point.y := ray.location.y + ray.direction.y * new_t;
          if (abs(point.y) < 1) then
            begin
              point.z := ray.location.z + ray.direction.z * new_t;
              if (abs(point.z) < 1) then
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
      if (new_t > tmin) and (new_t < tmax) then
        begin
          point.x := ray.location.x + ray.direction.x * new_t;
          if (abs(point.x) < 1) then
            begin
              point.z := ray.location.z + ray.direction.z * new_t;
              if (abs(point.z) < 1) then
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
      if (new_t > tmin) and (new_t < tmax) then
        begin
          point.x := ray.location.x + ray.direction.x * new_t;
          if (abs(point.x) < 1) then
            begin
              point.y := ray.location.y + ray.direction.y * new_t;
              if (abs(point.y) < 1) then
                t := new_t;
            end;
        end;
    end;

  Unit_cube_back_face_intersection := t;
end; {function Unit_cube_back_face_intersection}


function Unit_cube_front_face_intersection(ray: ray_type;
  tmin, tmax: real): real;
var
  point: vector_type;
  t, new_t: real;
begin
  t := infinity;

  if (ray.direction.x <> 0) then
    begin
      if (ray.direction.x < 0) then
        new_t := (1 - ray.location.x) / ray.direction.x
      else
        new_t := (-1 - ray.location.x) / ray.direction.x;
      if (new_t > tmin) and (new_t < tmax) then
        begin
          point.y := ray.location.y + ray.direction.y * new_t;
          if (abs(point.y) < 1) then
            begin
              point.z := ray.location.z + ray.direction.z * new_t;
              if (abs(point.z) < 1) then
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
      if (new_t > tmin) and (new_t < tmax) then
        begin
          point.x := ray.location.x + ray.direction.x * new_t;
          if (abs(point.x) < 1) then
            begin
              point.z := ray.location.z + ray.direction.z * new_t;
              if (abs(point.z) < 1) then
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
      if (new_t > tmin) and (new_t < tmax) then
        begin
          point.x := ray.location.x + ray.direction.x * new_t;
          if (abs(point.x) < 1) then
            begin
              point.y := ray.location.y + ray.direction.y * new_t;
              if (abs(point.y) < 1) then
                t := new_t;
            end;
        end;
    end;

  Unit_cube_front_face_intersection := t;
end; {function Unit_cube_front_face_intersection}


function Unit_cube_second_intersection(ray: ray_type;
  tmin, tmax: real): real;
var
  x, y, z: real;
  point: vector_type;
  t, new_t: real;
begin
  t := infinity;
  x := abs(ray.location.x);
  y := abs(ray.location.y);
  z := abs(ray.location.z);

  if (ray.direction.x <> 0) and ((x < y) or (x < z)) then
    begin
      if (ray.direction.x > 0) then
        new_t := (1 - ray.location.x) / ray.direction.x
      else
        new_t := (-1 - ray.location.x) / ray.direction.x;
      if (new_t > tmin) and (new_t < tmax) then
        begin
          point.y := ray.location.y + ray.direction.y * new_t;
          if (abs(point.y) < 1) then
            begin
              point.z := ray.location.z + ray.direction.z * new_t;
              if (abs(point.z) < 1) then
                t := new_t;
            end;
        end;
    end;
  if (ray.direction.y <> 0) and ((y < x) or (y < z)) then
    begin
      if (ray.direction.y > 0) then
        new_t := (1 - ray.location.y) / ray.direction.y
      else
        new_t := (-1 - ray.location.y) / ray.direction.y;
      if (new_t > tmin) and (new_t < tmax) then
        begin
          point.x := ray.location.x + ray.direction.x * new_t;
          if (abs(point.x) < 1) then
            begin
              point.z := ray.location.z + ray.direction.z * new_t;
              if (abs(point.z) < 1) then
                t := new_t;
            end;
        end;
    end;
  if (ray.direction.z <> 0) and ((z < x) or (z < y)) then
    begin
      if (ray.direction.z > 0) then
        new_t := (1 - ray.location.z) / ray.direction.z
      else
        new_t := (-1 - ray.location.z) / ray.direction.z;
      if (new_t > tmin) and (new_t < tmax) then
        begin
          point.x := ray.location.x + ray.direction.x * new_t;
          if (abs(point.x) < 1) then
            begin
              point.y := ray.location.y + ray.direction.y * new_t;
              if (abs(point.y) < 1) then
                t := new_t;
            end;
        end;
    end;

  Unit_cube_second_intersection := t;
end; {function Unit_cube_second_intersection}


function Unit_cube_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type): real;
var
  t, t1, t2: real;
begin
  t := 0;

  case intersection of
    closest:
      begin
        t1 := Unit_cube_back_face_intersection(ray, tmin, tmax);
        t2 := Unit_cube_front_face_intersection(ray, tmin, tmax);

        if (t1 < t2) then
          t := t1
        else
          t := t2;
      end;

    second_closest:
      begin
        {t := Unit_cube_back_face_intersection(ray, tmin + tiny, tmax);}
        t := Unit_cube_second_intersection(ray, tmin, tmax);
      end;
  end; {case}

  Unit_cube_intersection := t;
end; {function Unit_cube_intersection}


function Shaded_triangle_intersection(ray: ray_type;
  tmin, tmax: real;
  triangle_normal_ptr: triangle_normal_ptr_type): real;
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
            t := infinity
          else
            begin
              {***************************}
              { save normal interpolation }
              {***************************}
              with last_ray_normal_interpolation do
                begin
                  left_vector1 := triangle_normal_ptr^.normal3;
                  left_vector2 := triangle_normal_ptr^.normal1;
                  left_t := (-y / 2.0) + 0.5;

                  right_vector1 := triangle_normal_ptr^.normal3;
                  right_vector2 := triangle_normal_ptr^.normal2;
                  right_t := left_t;

                  t := x / left_t;
                end;
            end;
        end;
    end;
  Shaded_triangle_intersection := t;
end; {function Shaded_triangle_intersection}


function Shaded_polygon_triangle_intersection(ray: ray_type;
  tmin, tmax: real;
  triangle_ptr: triangle_ptr_type): real;
var
  original_ray: ray_type;
  texture1, texture2, texture3: vector_type;
  normal1, normal2, normal3: vector_type;
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
                  { save normal interpolation }
                  {***************************}
                  normal1 :=
                    triangle_ptr^.vertex_ptr1^.vertex_geometry_ptr^.normal;
                  normal2 :=
                    triangle_ptr^.vertex_ptr2^.vertex_geometry_ptr^.normal;
                  normal3 :=
                    triangle_ptr^.vertex_ptr3^.vertex_geometry_ptr^.normal;

                  with last_ray_normal_interpolation do
                    begin
                      left_vector1 := normal2;
                      left_vector2 := normal1;
                      left_t := y;
                      right_vector1 := normal3;
                      right_vector2 := normal1;
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

                  with last_ray_u_axis_interpolation do
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

  Shaded_polygon_triangle_intersection := t;
end; {function Shaded_polygon_triangle_intersection}


function Shaded_polygon_intersection(ray: ray_type;
  tmin, tmax: real;
  shaded_polygon_vertex_ptr: shaded_polygon_vertex_ptr_type): real;
var
  binormal: binormal_type;
  trans: trans_type;
  coord_axes: coord_axes_type;
  follow: shaded_polygon_vertex_ptr_type;
  first_vertex, vertex1, vertex2: vector_type;
  first_vertex_ptr, vertex_ptr1, vertex_ptr2: shaded_polygon_vertex_ptr_type;
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
  vertex1 := shaded_polygon_vertex_ptr^.point;
  vertex_ptr1 := shaded_polygon_vertex_ptr;
  Transform_point_to_axes(vertex1, coord_axes);
  first_vertex := vertex1;
  first_vertex_ptr := vertex_ptr1;

  {***********************}
  { point in polygon test }
  {***********************}
  follow := shaded_polygon_vertex_ptr;
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

                  {**************************************************}
                  { save right edge normal interpolation information }
                  {**************************************************}
                  last_ray_normal_interpolation.right_vector1 :=
                    vertex_ptr1^.normal;
                  last_ray_normal_interpolation.right_vector2 :=
                    vertex_ptr2^.normal;
                  last_ray_normal_interpolation.right_t := t;

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

                  {*************************************************}
                  { save left edge normal interpolation information }
                  {*************************************************}
                  last_ray_normal_interpolation.left_vector1 :=
                    vertex_ptr1^.normal;
                  last_ray_normal_interpolation.left_vector2 :=
                    vertex_ptr2^.normal;
                  last_ray_normal_interpolation.left_t := t;

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
      last_ray_normal_interpolation.t := x;
      last_ray_texture_interpolation.t := x;
      last_ray_u_axis_interpolation.t := x;
      last_ray_v_axis_interpolation.t := x;

      t := left.z + (right.z - left.z) * x;
      if (t < tmin) or (t > tmax) then
        t := infinity;
    end
  else
    t := infinity;

  Shaded_polygon_intersection := t;
end; {function Shaded_polygon_intersection}


end.
