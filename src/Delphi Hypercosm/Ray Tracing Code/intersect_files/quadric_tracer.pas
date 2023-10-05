unit quadric_tracer;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           quadric_tracer              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is used to find intersections between       }
{       rays and quadric primitives.                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  constants, trigonometry, vectors, rays, trans;


type
  intersection_type = (closest, second_closest);


function Sphere_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  umin, umax: real;
  vmin, vmax: real): real;
function Cylinder_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  umin, umax: real): real;
function Cone_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  inner_radius: real;
  umin, umax: real): real;
function Paraboloid_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  umin, umax: real): real;
function Hyperboloid1_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  inner_radius: real;
  umin, umax: real): real;
function Hyperboloid2_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  eccentricity: real;
  umin, umax: real): real;

function Longitude_ok(x, y: real;
  umin, umax: real): boolean;
function Lattitude_ok(x, y, z: real;
  vmin, vmax: real): boolean;


implementation


const
  table_size = 512;
  memory_alert = false;


type
  tangent_table_type = array[0..table_size] of real;


var
  tangent_table: tangent_table_type;


procedure Init_tangent_table;
var
  counter: integer;
  slope, angle: real;
begin
  for counter := 0 to table_size do
    begin
      slope := counter / table_size;
      angle := arctan(slope) * radians_to_degrees;
      tangent_table[counter] := angle;
    end;
end; {procedure Init_tangent_table}


procedure Write_intersection(intersection: intersection_type);
begin
  case intersection of
    closest:
      write('closest');
    second_closest:
      write('second_closest');
  end;
end; {procedure Write_intersection}


{***************************************}
{ fast trig routines for quadric sweeps }
{***************************************}


function Fast_arctan(y, x: real): real;
var
  angle, slope: real;
  sign_X, sign_Y: boolean;
  abs_X, abs_Y: real;
begin
  sign_X := x > 0;
  sign_Y := y > 0;

  if sign_X then
    abs_X := x
  else
    abs_X := -x;
  if sign_Y then
    abs_Y := y
  else
    abs_Y := -y;

  if (sign_X = sign_Y) then
    begin
      {*************************************}
      { positive slope - angle from 0 to 90 }
      {*************************************}
      if (abs_X > abs_Y) then
        begin
          {***********}
          { slope < 1 }
          {***********}
          slope := abs_Y / abs_X;
          if (slope >= 0) and (slope <= 1) then
            angle := tangent_table[Trunc(slope * table_size)]
          else
            angle := 0;
        end
      else
        begin
          {***********}
          { slope > 1 }
          {***********}
          slope := abs_X / abs_Y;
          if (slope >= 0) and (slope <= 1) then
            angle := 90 - tangent_table[Trunc(slope * table_size)]
          else
            angle := 0;
        end;
    end
  else
    begin
      {**************************************}
      { negative slope - angle from 0 to -90 }
      {**************************************}
      if (abs_X > abs_Y) then
        begin
          {***********}
          { slope < 1 }
          {***********}
          slope := abs_Y / abs_X;
          if (slope >= 0) and (slope <= 1) then
            angle := -tangent_table[Trunc(slope * table_size)]
          else
            angle := 0;
        end
      else
        begin
          {***********}
          { slope > 1 }
          {***********}
          slope := abs_X / abs_Y;
          if (slope >= 0) and (slope <= 1) then
            angle := tangent_table[Trunc(slope * table_size)] - 90
          else
            angle := 0;
        end;
    end;
  Fast_arctan := angle;
end; {function Fast_arctan}


function Fast_atan(y, x: real): real;
var
  TH: real;
begin
  if (x <> 0) then
    begin
      TH := Fast_arctan(y, x);
      if (x <= 0) then
        TH := TH + 180;
      if (TH < 0) then
        TH := TH + 360;
    end
  else
    begin
      if (y >= 0) then
        TH := 90
      else
        TH := 270;
    end;
  Fast_atan := TH;
end; {function Fast_atan}


function Longitude_ok(x, y: real;
  umin, umax: real): boolean;
var
  ok: boolean;
  angle: real;
begin
  {*****************}
  { check longitude }
  {*****************}
  if (umin = 0) and (umax = 360) then
    ok := true
  else
    begin
      angle := Fast_atan(y, x);
      if (umin < umax) then
        ok := (angle >= umin) and (angle <= umax)
      else
        ok := (angle >= umin) or (angle <= umax);
    end;
  Longitude_ok := ok;
end; {function Longitude_ok}


function Lattitude_ok(x, y, z: real;
  vmin, vmax: real): boolean;
var
  ok: boolean;
  angle, distance: real;
begin
  {*****************}
  { check lattitude }
  {*****************}
  if (vmin = -90) and (vmax = 90) then
    ok := true
  else
    begin
      distance := sqrt((x * x) + (y * y));
      if (distance <> 0) then
        angle := Fast_arctan(z, distance)
      else
        begin
          if (z > 0) then
            angle := 90
          else
            angle := -90;
        end;
      ok := (angle >= vmin) and (angle <= vmax);
    end;
  Lattitude_ok := ok;
end; {function Lattitude_ok}


{**************************************************}
{ routines to select the proper intersection given }
{ the 2 candidates given by the quadratic equation }
{**************************************************}


function Select_spherical(t1, t2: real;
  ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  umin, umax: real;
  vmin, vmax: real): real;
var
  point: vector_type;
  t: real;
begin
  t := 0;

  {*****************************}
  { choose correct intersection }
  {*****************************}
  case intersection of

    closest:
      begin
        {**************************}
        { invalidate intersections }
        {**************************}
        if (t1 < tmin) or (t1 > tmax) then
          t1 := infinity;
        if (t2 < tmin) or (t2 > tmax) then
          t2 := infinity;

        {*********************}
        { check sweep surface }
        {*********************}
        if (umin <> 0) or (umax <> 360) or (vmin <> -90) or (vmax <> 90) then
          begin
            if (t1 <> infinity) then
              begin
                point := Vector_sum(ray.location, Vector_scale(ray.direction,
                  t1));
                if not Longitude_ok(point.x, point.y, umin, umax) then
                  t1 := infinity
                else if not Lattitude_ok(point.x, point.y, point.z, vmin, vmax)
                  then
                  t1 := infinity;
              end;

            if (t2 <> infinity) then
              begin
                point := Vector_sum(ray.location, Vector_scale(ray.direction,
                  t2));
                if not Longitude_ok(point.x, point.y, umin, umax) then
                  t2 := infinity
                else if not Lattitude_ok(point.x, point.y, point.z, vmin, vmax)
                  then
                  t2 := infinity;
              end;
          end;

        {********}
        { select }
        {********}
        if (t1 < t2) then
          t := t1
        else
          t := t2;
      end;

    second_closest:
      begin
        {********}
        { select }
        {********}
        if abs(t1) > abs(t2) then
          t := t1
        else
          t := t2;

        {*************************}
        { invalidate intersection }
        {*************************}
        if (t < tmin) or (t > tmax) then
          t := infinity
        else
          {*********************}
          { check sweep surface }
          if (umin <> 0) or (umax <> 360) or (vmin <>
            -90) or (vmax <> 90) then
            begin
              if (t <> infinity) then
                begin
                  point := Vector_sum(ray.location, Vector_scale(ray.direction,
                    t));
                  if not Longitude_ok(point.x, point.y, umin, umax) then
                    t := infinity
                  else if not Lattitude_ok(point.x, point.y, point.z, vmin, vmax)
                    then
                    t := infinity;
                end;
            end;
      end;
  end; {case}

  Select_spherical := t;
end; {function Select_spherical}


function Select_cylindrical(t1, t2: real;
  ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  umin, umax: real): real;
var
  point: vector_type;
  t, z: real;
begin
  t := 0;

  {*****************************}
  { choose correct intersection }
  {*****************************}
  case intersection of

    closest:
      begin
        {**************************}
        { invalidate intersections }
        {**************************}

        {*********************************************}
        { an intersection is not valid if it is above }
        { the top or below the bottom of the object.  }
        {*********************************************}
        if (t1 < tmin) or (t1 > tmax) then
          t1 := infinity
        else
          begin
            z := ray.location.z + (ray.direction.z * t1);
            if (z < -1) or (z > 1) then
              t1 := infinity;
          end;

        if (t2 < tmin) or (t2 > tmax) then
          t2 := infinity
        else
          begin
            z := ray.location.z + (ray.direction.z * t2);
            if (z < -1) or (z > 1) then
              t2 := infinity;
          end;

        {*********************}
        { check sweep surface }
        {*********************}
        if (umin <> 0) or (umax <> 360) then
          begin
            if (t1 <> infinity) then
              begin
                point := Vector_sum(ray.location, Vector_scale(ray.direction,
                  t1));
                if not Longitude_ok(point.x, point.y, umin, umax) then
                  t1 := infinity;
              end;

            if (t2 <> infinity) then
              begin
                point := Vector_sum(ray.location, Vector_scale(ray.direction,
                  t2));
                if not Longitude_ok(point.x, point.y, umin, umax) then
                  t2 := infinity;
              end;
          end;

        {********}
        { select }
        {********}
        if (t1 < t2) then
          t := t1
        else
          t := t2;
      end;

    second_closest:
      begin
        {********}
        { select }
        {********}
        if abs(t1) > abs(t2) then
          t := t1
        else
          t := t2;

        {*************************}
        { invalidate intersection }
        {*************************}

        {*********************************************}
        { an intersection is not valid if it is above }
        { the top or below the bottom of the object.  }
        {*********************************************}
        if (t < tmin) or (t > tmax) then
          t := infinity
        else
          begin
            z := ray.location.z + (ray.direction.z * t);
            if (z < -1) or (z > 1) then
              t := infinity;
          end;

        {*********************}
        { check sweep surface }
        {*********************}
        if (umin <> 0) or (umax <> 360) then
          begin
            if (t <> infinity) then
              begin
                point := Vector_sum(ray.location, Vector_scale(ray.direction,
                  t));
                if not Longitude_ok(point.x, point.y, umin, umax) then
                  t := infinity;
              end;
          end;
      end;
  end; {case}

  Select_cylindrical := t;
end; {function Select_cylindrical}


{********************}
{ quadric primitives }
{********************}


function Sphere_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  umin, umax: real;
  vmin, vmax: real): real;
var
  qa, qb, qc: real; { terms of quadratic equation                   }
  qd: real; { discrimanent of quadradic equation            }
  t1, t2: real; { the 2 intersections; t1=t2 if ray is tangent. }
  t: real; { parametric location of the intersection point }
begin
  qa := Dot_product(ray.direction, ray.direction);
  qb := 2.0 * Dot_product(ray.location, ray.direction);
  qc := Dot_product(ray.location, ray.location) - 1.0;
  qd := qb * qb - 4 * qa * qc;
  if (qd < 0) then
    t := infinity
  else
    begin
      {***********************************************}
      { find closest intersection which is not behind }
      { the ray origin - find the smallest positive t }
      {***********************************************}
      qd := sqrt(qd);
      qa := 2 * qa;

      {***********************}
      { the two intersections }
      {***********************}
      t1 := (-qb - qd) / qa;
      t2 := (-qb + qd) / qa;

      {*****************************}
      { select correct intersection }
      {*****************************}
      t := Select_spherical(t1, t2, ray, tmin, tmax, intersection, umin, umax,
        vmin, vmax);
    end; {else}

  Sphere_intersection := t;
end; {function Sphere_intersection}


function Cylinder_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  umin, umax: real): real;
var
  qa, qb, qc: real; { coefficients of quadratic equation            }
  qd: real; { discriminant of quadratic equation            }
  t1, t2: real; { the 2 intersections; t1=t2 if ray is tangent. }
  t: real; { parametric location of the intersection point }
begin
  qa := (ray.direction.x * ray.direction.x) + (ray.direction.y *
    ray.direction.y);
  qb := ((ray.direction.x * ray.location.x) + (ray.direction.y * ray.location.y))
    * 2.0;
  qc := (ray.location.x * ray.location.x) + (ray.location.y * ray.location.y) -
    1.0;
  qd := qb * qb - 4 * qa * qc;
  if (qd < 0) then
    t := infinity
  else
    begin
      {***********************************************}
      { find closest intersection which is not behind }
      { the ray origin - find the smallest positive t }
      {***********************************************}
      qd := sqrt(qd);
      qa := 2 * qa;

      {***********************}
      { the two intersections }
      {***********************}
      t1 := (-qb - qd) / qa;
      t2 := (-qb + qd) / qa;

      {*****************************}
      { select correct intersection }
      {*****************************}
      t := Select_cylindrical(t1, t2, ray, tmin, tmax, intersection, umin,
        umax);
    end; {else}

  Cylinder_intersection := t;
end; {function Cylinder_intersection}


function Cone_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  inner_radius: real;
  umin, umax: real): real;
var
  qa, qb, qc: real; { coefficients of quadratic equation            }
  qd: real; { discriminant of quadratic equation            }
  t1, t2: real; { the 2 intersections; t1=t2 if ray is tangent. }
  t: real; { parametric location of the intersection point }
  k, k_squared: real; { slope factor                                  }
begin
  k := (inner_radius - 1.0) / 2.0;
  k_squared := k * k;
  qa := (ray.direction.x * ray.direction.x) + (ray.direction.y * ray.direction.y)
    - (ray.direction.z * ray.direction.z * k_squared);
  qb := ((ray.direction.x * ray.location.x) + (ray.direction.y * ray.location.y)
    - (ray.direction.z * (ray.location.z + 1.0) * k_squared) - (ray.direction.z
      *
    k)) * 2.0;
  qc := (ray.location.x * ray.location.x) + (ray.location.y * ray.location.y) -
    ((ray.location.z + 1.0) * (ray.location.z + 1.0) * k_squared) - (2.0 * k *
    (ray.location.z + 1.0)) - 1.0;
  qd := qb * qb - 4 * qa * qc;
  if (qd < 0) then
    t := infinity
  else
    begin
      {***********************************************}
      { find closest intersection which is not behind }
      { the ray origin - find the smallest positive t }
      {***********************************************}
      qd := sqrt(qd);
      qa := 2 * qa;

      {***********************}
      { the two intersections }
      {***********************}
      t1 := (-qb - qd) / qa;
      t2 := (-qb + qd) / qa;

      {*****************************}
      { select correct intersection }
      {*****************************}
      t := Select_cylindrical(t1, t2, ray, tmin, tmax, intersection, umin,
        umax);
    end;

  Cone_intersection := t;
end; {function Cone_intersection}


function Paraboloid_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  umin, umax: real): real;
var
  qa, qb, qc: real; { coefficients of quadratic equation            }
  qd: real; { discriminant of quadratic equation            }
  t1, t2: real; { the 2 intersections; t1=t2 if ray is tangent. }
  t: real; { parametric location of the intersection point }
begin
  qa := (ray.direction.x * ray.direction.x) + (ray.direction.y *
    ray.direction.y);
  qb := ((ray.direction.x * ray.location.x) + (ray.direction.y * ray.location.y))
    * 2.0 + (ray.direction.z / 2.0);
  qc := (ray.location.x * ray.location.x) + (ray.location.y * ray.location.y) -
    (1.0 - ray.location.z) / 2.0;
  qd := qb * qb - 4 * qa * qc;
  if (qd < 0) then
    t := infinity
  else
    begin
      {***********************************************}
      { find closest intersection which is not behind }
      { the ray origin - find the smallest positive t }
      {***********************************************}
      qd := sqrt(qd);
      qa := 2 * qa;

      {***********************}
      { the two intersections }
      {***********************}
      t1 := (-qb - qd) / qa;
      t2 := (-qb + qd) / qa;

      {*****************************}
      { select correct intersection }
      {*****************************}
      t := Select_cylindrical(t1, t2, ray, tmin, tmax, intersection, umin,
        umax);
    end;

  Paraboloid_intersection := t;
end; {function Paraboloid_intersection}


function Hyperboloid1_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  inner_radius: real;
  umin, umax: real): real;
var
  qa, qb, qc: real; { coefficients of quadratic equation            }
  qd: real; { discriminant of quadratic equation            }
  t1, t2: real; { the 2 intersections; t1=t2 if ray is tangent. }
  t: real; { parametric location of the intersection point }
  temp1, temp2, temp3: real;
begin
  temp1 := inner_radius;
  temp2 := 1.0 - ray.location.z;
  temp3 := (temp1 * temp1 - 1.0) / 4.0;
  qa := (ray.direction.x * ray.direction.x) + (ray.direction.y * ray.direction.y)
    + (ray.direction.z * ray.direction.z) * temp3;
  qb := ((ray.direction.x * ray.location.x) + (ray.direction.y * ray.location.y)
    - (ray.direction.z * temp2 * temp3)) * 2.0;
  qc := (ray.location.x * ray.location.x) + (ray.location.y * ray.location.y) +
    (temp2 * temp2 * temp3) - (temp1 * temp1);
  qd := qb * qb - 4 * qa * qc;
  if (qd < 0) then
    t := infinity
  else
    begin
      {***********************************************}
      { find closest intersection which is not behind }
      { the ray origin - find the smallest positive t }
      {***********************************************}
      qd := sqrt(qd);
      qa := 2 * qa;

      {***********************}
      { the two intersections }
      {***********************}
      t1 := (-qb - qd) / qa;
      t2 := (-qb + qd) / qa;

      {*****************************}
      { select correct intersection }
      {*****************************}
      t := Select_cylindrical(t1, t2, ray, tmin, tmax, intersection, umin,
        umax);
    end;

  Hyperboloid1_intersection := t;
end; {function Hyperboloid1_intersection}


function Hyperboloid2_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  eccentricity: real;
  umin, umax: real): real;
var
  qa, qb, qc: real; { coefficients of quadratic equation            }
  qd: real; { discriminant of quadratic equation            }
  t1, t2: real; { the 2 intersections; t1=t2 if ray is tangent. }
  t: real; { parametric location of the intersection point }
  temp1, temp2, temp3: real;
begin
  temp1 := eccentricity;
  temp2 := 1.0 - ray.location.z;
  temp3 := 2.0 * temp1 + 1.0;
  qa := (ray.direction.x * ray.direction.x) + (ray.direction.y * ray.direction.y)
    - (ray.direction.z * ray.direction.z) / (4.0 * temp3);
  qb := ((ray.direction.x * ray.location.x) + (ray.direction.y * ray.location.y)
    + (ray.direction.z * temp2 / (4.0 * temp3))) * 2.0 + (temp1 * ray.direction.z
    / temp3);
  qc := (ray.location.x * ray.location.x) + (ray.location.y * ray.location.y) -
    (temp2 * temp2 / (4.0 * temp3)) - (temp1 * temp2 / temp3);
  qd := qb * qb - 4 * qa * qc;
  if (qd < 0) then
    t := infinity
  else
    begin
      {***********************************************}
      { find closest intersection which is not behind }
      { the ray origin - find the smallest positive t }
      {***********************************************}
      qd := sqrt(qd);
      qa := 2 * qa;

      {***********************}
      { the two intersections }
      {***********************}
      t1 := (-qb - qd) / qa;
      t2 := (-qb + qd) / qa;

      {*****************************}
      { select correct intersection }
      {*****************************}
      t := Select_cylindrical(t1, t2, ray, tmin, tmax, intersection, umin,
        umax);
    end;

  Hyperboloid2_intersection := t;
end; {function Hyperboloid2_intersection}


initialization
  Init_tangent_table;
end.
