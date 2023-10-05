unit proximity;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             proximity                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to find closest and       }
{       farthest points in bounds.                              }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, trans, bounds;


{****************************************************************************}
{ routines for finding the closest and farthest vertices in bounding squares }
{****************************************************************************}
function Closest_bounding_square_vertex(bounding_square: bounding_square_type;
  var closest_distance: real): vector_type;
function Farthest_bounding_square_vertex(bounding_square: bounding_square_type;
  var farthest_distance: real): vector_type;
function Closest_bounding_square_vertex_in_direction(bounding_square:
  bounding_square_type;
  direction: vector_type;
  var closest_distance: real): vector_type;
function Farthest_bounding_square_vertex_in_direction(bounding_square:
  bounding_square_type;
  direction: vector_type;
  var farthest_distance: real): vector_type;

{**************************************************************************}
{ routines for finding the closest and farthest vertices in bounding boxes }
{**************************************************************************}
function Closest_bounding_box_vertex(bounding_box: bounding_box_type;
  var closest_distance: real): vector_type;
function Farthest_bounding_box_vertex(bounding_box: bounding_box_type;
  var farthest_distance: real): vector_type;
function Closest_bounding_box_vertex_in_direction(bounding_box:
  bounding_box_type;
  direction: vector_type;
  var closest_distance: real): vector_type;
function Farthest_bounding_box_vertex_in_direction(bounding_box:
  bounding_box_type;
  direction: vector_type;
  var farthest_distance: real): vector_type;

{******************************************************************}
{ routines for finding the closest and farthest vertices in bounds }
{******************************************************************}
function Closest_bounds_vertex(bounds: bounding_type;
  var closest_distance: real): vector_type;
function Farthest_bounds_vertex(bounds: bounding_type;
  var farthest_distance: real): vector_type;
function Closest_bounds_vertex_in_direction(bounds: bounding_type;
  direction: vector_type;
  var closest_distance: real): vector_type;
function Farthest_bounds_vertex_in_direction(bounds: bounding_type;
  direction: vector_type;
  var farthest_distance: real): vector_type;

{****************************************************************}
{ routines for finding the closest and farthest points in bounds }
{****************************************************************}
function Closest_bounds_point(bounds: bounding_type;
  trans: trans_type;
  var closest_distance: real): vector_type;
function Closest_bounds_point_in_direction(bounds: bounding_type;
  trans: trans_type;
  direction: vector_type;
  var closest_distance: real): vector_type;


implementation
uses
  constants, extents, rays;


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
          if (new_t < t) and (new_t > 0) then
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
          if (new_t < t) and (new_t > 0) then
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
          if (new_t < t) and (new_t > 0) then
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
          if (new_t < t) and (new_t > 0) then
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
          if (new_t < t) and (new_t > 0) then
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
          if (new_t < t) and (new_t > 0) then
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


{****************************************************************************}
{ routines for finding the closest and farthest vertices in bounding squares }
{****************************************************************************}


function Closest_bounding_square_vertex(bounding_square: bounding_square_type;
  var closest_distance: real): vector_type;
var
  vertex: vector_type;
  distance_squared: real;
  counter1, counter2: extent_type;
  closest_vertex: vector_type;
  first: boolean;
begin
  first := true;
  for counter1 := left to right do
    for counter2 := front to back do
      begin
        vertex := bounding_square[counter1, counter2];
        distance_squared := Dot_product(vertex, vertex);
        if (distance_squared < closest_distance) or first then
          begin
            closest_distance := distance_squared;
            closest_vertex := vertex;
            first := false;
          end;
      end;

  closest_distance := sqrt(closest_distance);
  Closest_bounding_square_vertex := closest_vertex;
end; {function Closest_bounding_square_vertex}


function Farthest_bounding_square_vertex(bounding_square: bounding_square_type;
  var farthest_distance: real): vector_type;
var
  vertex: vector_type;
  distance_squared: real;
  counter1, counter2: extent_type;
  farthest_vertex: vector_type;
  first: boolean;
begin
  first := true;
  for counter1 := left to right do
    for counter2 := front to back do
      begin
        vertex := bounding_square[counter1, counter2];
        distance_squared := Dot_product(vertex, vertex);
        if (distance_squared > farthest_distance) or first then
          begin
            farthest_distance := distance_squared;
            farthest_vertex := vertex;
            first := false;
          end;
      end;

  farthest_distance := sqrt(farthest_distance);
  Farthest_bounding_square_vertex := farthest_vertex;
end; {function Farthest_bounding_square_vertex}


function Closest_bounding_square_vertex_in_direction(bounding_square:
  bounding_square_type;
  direction: vector_type;
  var closest_distance: real): vector_type;
var
  vertex: vector_type;
  distance: real;
  counter1, counter2: extent_type;
  closest_vertex: vector_type;
  first: boolean;
begin
  direction := Normalize(direction);
  first := true;
  for counter1 := left to right do
    for counter2 := front to back do
      begin
        vertex := bounding_square[counter1, counter2];
        distance := Dot_product(vertex, direction);
        if distance < 0 then
          distance := 0;
        if (distance < closest_distance) or first then
          begin
            closest_distance := distance;
            closest_vertex := vertex;
            first := false;
          end;
      end;

  Closest_bounding_square_vertex_in_direction := closest_vertex;
end; {Closest_bounding_square_vertex_in_direction}


function Farthest_bounding_square_vertex_in_direction(bounding_square:
  bounding_square_type;
  direction: vector_type;
  var farthest_distance: real): vector_type;
var
  vertex: vector_type;
  distance: real;
  counter1, counter2: extent_type;
  farthest_vertex: vector_type;
  first: boolean;
begin
  direction := Normalize(direction);
  first := true;
  for counter1 := left to right do
    for counter2 := front to back do
      begin
        vertex := bounding_square[counter1, counter2];
        distance := Dot_product(vertex, direction);
        if (distance > farthest_distance) or first then
          begin
            farthest_distance := distance;
            farthest_vertex := vertex;
            first := false;
          end;
      end;

  Farthest_bounding_square_vertex_in_direction := farthest_vertex;
end; {function Farthest_bounding_square_vertex_in_direction}


{**************************************************************************}
{ routines for finding the closest and farthest vertices in bounding boxes }
{**************************************************************************}


function Closest_bounding_box_vertex(bounding_box: bounding_box_type;
  var closest_distance: real): vector_type;
var
  vertex: vector_type;
  distance_squared: real;
  counter1, counter2, counter3: extent_type;
  closest_vertex: vector_type;
  first: boolean;
begin
  first := true;
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        begin
          vertex := bounding_box[counter1, counter2, counter3];
          distance_squared := Dot_product(vertex, vertex);
          if (distance_squared < closest_distance) or first then
            begin
              closest_distance := distance_squared;
              closest_vertex := vertex;
              first := false;
            end;
        end;

  closest_distance := sqrt(closest_distance);
  Closest_bounding_box_vertex := closest_vertex;
end; {function Closest_bounding_box_vertex}


function Farthest_bounding_box_vertex(bounding_box: bounding_box_type;
  var farthest_distance: real): vector_type;
var
  vertex: vector_type;
  distance_squared: real;
  counter1, counter2, counter3: extent_type;
  farthest_vertex: vector_type;
  first: boolean;
begin
  first := true;
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        begin
          vertex := bounding_box[counter1, counter2, counter3];
          distance_squared := Dot_product(vertex, vertex);
          if (distance_squared > farthest_distance) or first then
            begin
              farthest_distance := distance_squared;
              farthest_vertex := vertex;
              first := false;
            end;
        end;

  farthest_distance := sqrt(farthest_distance);
  Farthest_bounding_box_vertex := farthest_vertex;
end; {function Farthest_bounding_box_vertex}


function Closest_bounding_box_vertex_in_direction(bounding_box:
  bounding_box_type;
  direction: vector_type;
  var closest_distance: real): vector_type;
var
  vertex: vector_type;
  distance: real;
  counter1, counter2, counter3: extent_type;
  closest_vertex: vector_type;
  first: boolean;
begin
  direction := Normalize(direction);
  first := true;
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        begin
          vertex := bounding_box[counter1, counter2, counter3];
          distance := Dot_product(vertex, direction);
          if distance < 0 then
            distance := 0;
          if (distance < closest_distance) or first then
            begin
              closest_distance := distance;
              closest_vertex := vertex;
              first := false;
            end;
        end;

  Closest_bounding_box_vertex_in_direction := closest_vertex;
end; {function Closest_bounding_box_vertex_in_direction}


function Farthest_bounding_box_vertex_in_direction(bounding_box:
  bounding_box_type;
  direction: vector_type;
  var farthest_distance: real): vector_type;
var
  vertex: vector_type;
  distance: real;
  counter1, counter2, counter3: extent_type;
  farthest_vertex: vector_type;
  first: boolean;
begin
  direction := Normalize(direction);
  first := true;
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        begin
          vertex := bounding_box[counter1, counter2, counter3];
          distance := Dot_product(vertex, direction);
          if (distance > farthest_distance) or first then
            begin
              farthest_distance := distance;
              farthest_vertex := vertex;
              first := false;
            end;
        end;

  Farthest_bounding_box_vertex_in_direction := farthest_vertex;
end; {function Farthest_bounding_box_vertex_in_direction}


{******************************************************************}
{ routines for finding the closest and farthest vertices in bounds }
{******************************************************************}


function Closest_bounds_vertex(bounds: bounding_type;
  var closest_distance: real): vector_type;
var
  closest_vertex: vector_type;
begin
  if bounds.bounding_kind in [planar_bounds, non_planar_bounds] then
    case (bounds.bounding_kind) of

      planar_bounds:
        closest_vertex := Closest_bounding_square_vertex(bounds.bounding_square,
          closest_distance);

      non_planar_bounds:

        closest_vertex := Closest_bounding_box_vertex(bounds.bounding_box,
          closest_distance);

    end {case}
  else
    begin
      closest_vertex := zero_vector;
      closest_distance := 0;
    end;

  Closest_bounds_vertex := closest_vertex;
end; {function Closest_bounds_vertex}


function Farthest_bounds_vertex(bounds: bounding_type;
  var farthest_distance: real): vector_type;
var
  farthest_vertex: vector_type;
begin
  if bounds.bounding_kind in [planar_bounds, non_planar_bounds] then
    case (bounds.bounding_kind) of

      planar_bounds:
        farthest_vertex :=
          Farthest_bounding_square_vertex(bounds.bounding_square,
          farthest_distance);

      non_planar_bounds:
        farthest_vertex := Farthest_bounding_box_vertex(bounds.bounding_box,
          farthest_distance);

    end {case}
  else
    begin
      farthest_vertex := zero_vector;
      farthest_distance := 0;
    end;

  Farthest_bounds_vertex := farthest_vertex;
end; {function Farthest_bounds_vertex}


function Closest_bounds_vertex_in_direction(bounds: bounding_type;
  direction: vector_type;
  var closest_distance: real): vector_type;
var
  closest_vertex: vector_type;
begin
  if bounds.bounding_kind in [planar_bounds, non_planar_bounds] then
    case (bounds.bounding_kind) of

      planar_bounds:
        closest_vertex :=
          Closest_bounding_square_vertex_in_direction(bounds.bounding_square,
          direction, closest_distance);

      non_planar_bounds:

        closest_vertex :=
          Closest_bounding_box_vertex_in_direction(bounds.bounding_box,
            direction,
          closest_distance);

    end {case}
  else
    begin
      closest_vertex := zero_vector;
      closest_distance := 0;
    end;

  Closest_bounds_vertex_in_direction := closest_vertex;
end; {function Closest_bounds_vertex_in_direction}


function Farthest_bounds_vertex_in_direction(bounds: bounding_type;
  direction: vector_type;
  var farthest_distance: real): vector_type;
var
  farthest_vertex: vector_type;
begin
  if bounds.bounding_kind in [planar_bounds, non_planar_bounds] then
    case (bounds.bounding_kind) of

      planar_bounds:
        farthest_vertex :=
          Farthest_bounding_square_vertex_in_direction(bounds.bounding_square,
          direction, farthest_distance);

      non_planar_bounds:
        farthest_vertex :=
          Farthest_bounding_box_vertex_in_direction(bounds.bounding_box,
          direction, farthest_distance);

    end {case}
  else
    begin
      farthest_vertex := zero_vector;
      farthest_distance := 0;
    end;

  Farthest_bounds_vertex_in_direction := farthest_vertex;
end; {function Farthest_bounds_vertex_in_direction}


{****************************************************************}
{ routines for finding the closest and farthest points in bounds }
{****************************************************************}


function Bounds_intersection(direction: vector_type;
  inverse_bounds_trans: trans_type): real;
var
  ray: ray_type;
begin
  ray := To_ray(zero_vector, direction);

  {****************************************}
  { transform ray to local space of bounds }
  {****************************************}
  Transform_ray(ray, inverse_bounds_trans);

  {*******************************************}
  { check for intersection in space of bounds }
  {*******************************************}
  Bounds_intersection := Unit_cube_intersection(ray);
end; {function Bounds_intersection}


function Closest_bounds_point(bounds: bounding_type;
  trans: trans_type;
  var closest_distance: real): vector_type;
var
  closest_point, direction: vector_type;
  inverse_bounds_trans: trans_type;
  t: real;
begin
  closest_point := Closest_bounds_vertex(bounds, closest_distance);
  inverse_bounds_trans := Inverse_trans(trans);

  {***********************************}
  { closest point may not be a vertex }
  {***********************************}
  inverse_bounds_trans := Inverse_trans(trans);

  {*************************}
  { check rays along x axis }
  {*************************}
  direction := Normalize(trans.x_axis);
  t := Bounds_intersection(direction, inverse_bounds_trans);
  if t <> infinity then
    if (t > 0) and (t < closest_distance) then
      begin
        closest_distance := t;
        closest_point := Vector_scale(direction, t);
      end;
  direction := Normalize(Vector_reverse(trans.x_axis));
  t := Bounds_intersection(direction, inverse_bounds_trans);
  if t <> infinity then
    if (t > 0) and (t < closest_distance) then
      begin
        closest_distance := t;
        closest_point := Vector_scale(direction, t);
      end;

  {*************************}
  { check rays along y axis }
  {*************************}
  direction := Normalize(trans.y_axis);
  t := Bounds_intersection(direction, inverse_bounds_trans);
  if t <> infinity then
    if (t > 0) and (t < closest_distance) then
      begin
        closest_distance := t;
        closest_point := Vector_scale(direction, t);
      end;
  direction := Normalize(Vector_reverse(trans.y_axis));
  t := Bounds_intersection(direction, inverse_bounds_trans);
  if t <> infinity then
    if (t > 0) and (t < closest_distance) then
      begin
        closest_distance := t;
        closest_point := Vector_scale(direction, t);
      end;

  {*************************}
  { check rays along z axis }
  {*************************}
  direction := Normalize(trans.z_axis);
  t := Bounds_intersection(direction, inverse_bounds_trans);
  if t <> infinity then
    if (t > 0) and (t < closest_distance) then
      begin
        closest_distance := t;
        closest_point := Vector_scale(direction, t);
      end;
  direction := Normalize(Vector_reverse(trans.z_axis));
  t := Bounds_intersection(direction, inverse_bounds_trans);
  if t <> infinity then
    if (t > 0) and (t < closest_distance) then
      begin
        closest_distance := t;
        closest_point := Vector_scale(direction, t);
      end;

  Closest_bounds_point := closest_point;
end; {function Closest_bounds_point}


function Closest_bounds_point_in_direction(bounds: bounding_type;
  trans: trans_type;
  direction: vector_type;
  var closest_distance: real): vector_type;
var
  closest_point: vector_type;
  inverse_bounds_trans: trans_type;
  t: real;
begin
  closest_point := Closest_bounds_vertex_in_direction(bounds, direction,
    closest_distance);

  {***********************************}
  { closest point may not be a vertex }
  {***********************************}
  inverse_bounds_trans := Inverse_trans(trans);

  {***************************}
  { check ray along direction }
  {***************************}
  direction := Normalize(direction);
  t := Bounds_intersection(direction, inverse_bounds_trans);
  if t <> infinity then
    if (t > 0) and (t < closest_distance) then
      begin
        closest_distance := t;
        closest_point := Vector_scale(direction, t);
      end;

  Closest_bounds_point_in_direction := closest_point;
end; {function Closest_bounds_point_in_direction}


end.
