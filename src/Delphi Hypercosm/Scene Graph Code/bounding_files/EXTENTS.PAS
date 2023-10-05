unit extents;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              extents                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to implement some         }
{       simple axis aligned bounding tests.                     }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, vectors2, rays, rays2, trans, trans2, coord_axes;


type
  {**************************}
  { axis aligned - 'extents' }
  {**************************}
  { x_axis is left to right  }
  { y_axis is front to back  }
  { z_axis is bottom to top  }
  {**************************}
  extent_type = (left, right, front, back, bottom, top);
  extent_square_type = array[left..back] of real;
  extent_box_type = array[extent_type] of real;


var
  zero_extent_square: extent_square_type;
  unit_extent_square: extent_square_type;

  zero_extent_box: extent_box_type;
  unit_extent_box: extent_box_type;


function Opposite_extent(extent: extent_type): extent_type;

{**************************************}
{ routines for creating extent squares }
{**************************************}
procedure Init_extent_square(var extent_square: extent_square_type);
procedure Extend_extent_square_to_point(var extent_square: extent_square_type;
  point: vector2_type);
procedure Extend_extent_square_to_extent_square(var extent_square:
  extent_square_type;
  extent_square2: extent_square_type);

{************************************}
{ routines for creating extent boxes }
{************************************}
procedure Init_extent_box(var extent_box: extent_box_type);
procedure Extend_extent_box_to_point(var extent_box: extent_box_type;
  point: vector_type);
procedure Extend_extent_box_to_extent_box(var extent_box: extent_box_type;
  extent_box2: extent_box_type);

{**************************************}
{ routines for querying extent squares }
{**************************************}
function Extent_square_center(extent_square: extent_square_type): vector2_type;
function Extent_square_dimensions(extent_square: extent_square_type):
  vector2_type;
function Extent_square_trans(extent_square: extent_square_type): trans2_type;
function Extent_square_intersection(ray: ray2_type;
  extent_square: extent_square_type): real;

{************************************}
{ routines for querying extent boxes }
{************************************}
function Extent_box_center(extent_box: extent_box_type): vector_type;
function Extent_box_dimensions(extent_box: extent_box_type): vector_type;
function Extent_box_trans(extent_box: extent_box_type): trans_type;
function Extent_box_intersection(ray: ray_type;
  extent_box: extent_box_type): real;

{***************************************}
{ routines for comparing extent squares }
{***************************************}
function Null_extent_square(extent_square: extent_square_type): boolean;
function Disjoint_extent_squares(extent_square1: extent_square_type;
  extent_square2: extent_square_type): boolean;
function Point_in_extent_square(point: vector2_type;
  extent_square: extent_square_type): boolean;
function Line_in_extent_square(point1, point2: vector2_type;
  extent_square: extent_square_type): boolean;

{*************************************}
{ routines for comparing extent boxes }
{*************************************}
function Null_extent_box(extent_box: extent_box_type): boolean;
function Disjoint_extent_boxes(extent_box1: extent_box_type;
  extent_box2: extent_box_type): boolean;
function Point_in_extent_box(point: vector_type;
  extent_box: extent_box_type): boolean;
function Line_in_extent_box(point1, point2: vector_type;
  extent_box: extent_box_type): boolean;
function Plane_in_extent_box(coord_axes: coord_axes_type;
  extent_box: extent_box_type): boolean;

{******************************}
{ routines for writing extents }
{******************************}
procedure Write_extent(extent: extent_type);
procedure Write_extent_square(extent_square: extent_square_type);
procedure Write_extent_box(extent_box: extent_box_type);


implementation
uses
  constants;


{***********************************************}
{ routines for initializing unit extent squares }
{***********************************************}


procedure Init_zero_extent_square(var extent_square: extent_square_type);
begin
  extent_square[left] := 0;
  extent_square[right] := 0;

  extent_square[front] := 0;
  extent_square[back] := 0;
end; {procedure Init_zero_extent_square}


procedure Init_unit_extent_square(var extent_square: extent_square_type);
begin
  extent_square[left] := -1;
  extent_square[right] := 1;

  extent_square[front] := -1;
  extent_square[back] := 1;
end; {procedure Init_unit_extent_square}


{***********************************************}
{ routines for initializing unit extent squares }
{***********************************************}


procedure Init_zero_extent_box(var extent_box: extent_box_type);
begin
  extent_box[left] := 0;
  extent_box[right] := 0;

  extent_box[front] := 0;
  extent_box[back] := 0;

  extent_box[bottom] := 0;
  extent_box[top] := 0;
end; {procedure Init_zero_extent_box}


procedure Init_unit_extent_box(var extent_box: extent_box_type);
begin
  extent_box[left] := -1;
  extent_box[right] := 1;

  extent_box[front] := -1;
  extent_box[back] := 1;

  extent_box[bottom] := -1;
  extent_box[top] := 1;
end; {procedure Init_unit_extent_box}


{************************}
{ extents initialization }
{************************}


function Opposite_extent(extent: extent_type): extent_type;
begin
  case extent of
    left:
      extent := right;
    right:
      extent := left;
    front:
      extent := back;
    back:
      extent := front;
    bottom:
      extent := top;
    top:
      extent := bottom;
  end; {case}

  Opposite_extent := extent;
end; {function Opposite_extent}


{**************************************}
{ routines for creating extent squares }
{**************************************}


procedure Init_extent_square(var extent_square: extent_square_type);
begin
  extent_square[left] := infinity;
  extent_square[right] := -infinity;

  extent_square[front] := infinity;
  extent_square[back] := -infinity;
end; {procedure Init_extent_square}


procedure Extend_extent_square_to_point(var extent_square: extent_square_type;
  point: vector2_type);
begin
  if (point.x < extent_square[left]) then
    extent_square[left] := point.x;
  if (point.x > extent_square[right]) then
    extent_square[right] := point.x;

  if (point.y < extent_square[front]) then
    extent_square[front] := point.y;
  if (point.y > extent_square[back]) then
    extent_square[back] := point.y;
end; {procedure Extend_extent_square_to_point}


procedure Extend_extent_square_to_extent_square(var extent_square:
  extent_square_type;
  extent_square2: extent_square_type);
begin
  if not Null_extent_square(extent_square2) then
    begin
      if extent_square2[left] < extent_square[left] then
        extent_square[left] := extent_square2[left];
      if extent_square2[right] > extent_square[right] then
        extent_square[right] := extent_square2[right];

      if extent_square2[front] < extent_square[front] then
        extent_square[front] := extent_square2[front];
      if extent_square2[back] > extent_square[back] then
        extent_square[back] := extent_square2[back];
    end;
end; {procedure Extend_extent_square_to_extent_square}


{************************************}
{ routines for creating extent boxes }
{************************************}


procedure Init_extent_box(var extent_box: extent_box_type);
begin
  extent_box[left] := infinity;
  extent_box[right] := -infinity;

  extent_box[front] := infinity;
  extent_box[back] := -infinity;

  extent_box[bottom] := infinity;
  extent_box[top] := -infinity;
end; {procedure Init_extent_box}


procedure Extend_extent_box_to_point(var extent_box: extent_box_type;
  point: vector_type);
begin
  if (point.x < extent_box[left]) then
    extent_box[left] := point.x;
  if (point.x > extent_box[right]) then
    extent_box[right] := point.x;

  if (point.y < extent_box[front]) then
    extent_box[front] := point.y;
  if (point.y > extent_box[back]) then
    extent_box[back] := point.y;

  if (point.z < extent_box[bottom]) then
    extent_box[bottom] := point.z;
  if (point.z > extent_box[top]) then
    extent_box[top] := point.z;
end; {procedure Extend_extent_box_to_point}


procedure Extend_extent_box_to_extent_box(var extent_box: extent_box_type;
  extent_box2: extent_box_type);
begin
  if not Null_extent_box(extent_box2) then
    begin
      if extent_box2[left] < extent_box[left] then
        extent_box[left] := extent_box2[left];
      if extent_box2[right] > extent_box[right] then
        extent_box[right] := extent_box2[right];

      if extent_box2[front] < extent_box[front] then
        extent_box[front] := extent_box2[front];
      if extent_box2[back] > extent_box[back] then
        extent_box[back] := extent_box2[back];

      if extent_box2[bottom] < extent_box[bottom] then
        extent_box[bottom] := extent_box2[bottom];
      if extent_box2[top] > extent_box[top] then
        extent_box[top] := extent_box2[top];
    end;
end; {procedure Extend_extent_box_to_extent_box}


{**************************************}
{ routines for querying extent squares }
{**************************************}


function Extent_square_center(extent_square: extent_square_type): vector2_type;
var
  center: vector2_type;
begin
  center.x := (extent_square[left] + extent_square[right]) / 2.0;
  center.y := (extent_square[front] + extent_square[back]) / 2.0;
  Extent_square_center := center;
end; {function Extent_square_center}


function Extent_square_dimensions(extent_square: extent_square_type):
  vector2_type;
var
  dimensions: vector2_type;
begin
  dimensions.x := (extent_square[right] - extent_square[left]);
  dimensions.y := (extent_square[back] - extent_square[front]);
  Extent_square_dimensions := dimensions;
end; {function Extent_square_dimensions}


function Extent_square_trans(extent_square: extent_square_type): trans2_type;
var
  trans: trans2_type;
begin
  if not Null_extent_square(extent_square) then
    begin
      trans.origin.x := (extent_square[left] + extent_square[right]) / 2;
      trans.origin.y := (extent_square[front] + extent_square[back]) / 2;

      trans.x_axis.x := (extent_square[right] - extent_square[left]) / 2;
      trans.x_axis.y := 0;

      trans.y_axis.y := (extent_square[back] - extent_square[front]) / 2;
      trans.y_axis.x := 0;
    end
  else
    trans := null_trans2;

  Extent_square_trans := trans;
end; {function Extent_square_trans}


{************************************}
{ routines for querying extent boxes }
{************************************}


function Extent_box_center(extent_box: extent_box_type): vector_type;
var
  center: vector_type;
begin
  center.x := (extent_box[left] + extent_box[right]) / 2.0;
  center.y := (extent_box[front] + extent_box[back]) / 2.0;
  center.z := (extent_box[bottom] + extent_box[top]) / 2.0;
  Extent_box_center := center;
end; {function Extent_box_center}


function Extent_box_dimensions(extent_box: extent_box_type): vector_type;
var
  dimensions: vector_type;
begin
  dimensions.x := (extent_box[right] - extent_box[left]);
  dimensions.y := (extent_box[back] - extent_box[front]);
  dimensions.z := (extent_box[top] - extent_box[bottom]);
  Extent_box_dimensions := dimensions;
end; {function Extent_box_dimensions}


function Extent_box_trans(extent_box: extent_box_type): trans_type;
var
  trans: trans_type;
begin
  if not Null_extent_box(extent_box) then
    begin
      trans.origin.x := (extent_box[left] + extent_box[right]) / 2;
      trans.origin.y := (extent_box[front] + extent_box[back]) / 2;
      trans.origin.z := (extent_box[bottom] + extent_box[top]) / 2;

      trans.x_axis.x := (extent_box[right] - extent_box[left]) / 2;
      trans.x_axis.y := 0;
      trans.x_axis.z := 0;

      trans.y_axis.y := (extent_box[back] - extent_box[front]) / 2;
      trans.y_axis.x := 0;
      trans.y_axis.z := 0;

      trans.z_axis.z := (extent_box[top] - extent_box[bottom]) / 2;
      trans.z_axis.x := 0;
      trans.z_axis.y := 0;
    end
  else
    trans := null_trans;

  Extent_box_trans := trans;
end; {function Extent_box_trans}


{***************************************}
{ routines for comparing extent squares }
{***************************************}


function Null_extent_square(extent_square: extent_square_type): boolean;
var
  null_extents: boolean;
begin
  if extent_square[left] > extent_square[right] then
    null_extents := true
  else if extent_square[front] > extent_square[back] then
    null_extents := true
  else
    null_extents := false;

  Null_extent_square := null_extents;
end; {function Null_extent_square}


function Disjoint_extent_squares(extent_square1: extent_square_type;
  extent_square2: extent_square_type): boolean;
var
  disjoint: boolean;
begin
  disjoint := false;

  {*******************}
  { compare x extents }
  {*******************}
  if (extent_square1[left] > extent_square2[right]) then
    disjoint := true
  else if (extent_square2[left] > extent_square1[right]) then
    disjoint := true

    {*******************}
    { compare y extents }
    {*******************}
  else if (extent_square1[front] > extent_square2[back]) then
    disjoint := true
  else if (extent_square2[front] > extent_square1[back]) then
    disjoint := true;

  Disjoint_extent_squares := disjoint;
end; {function Disjoint_extent_squares}


function Point_in_extent_square(point: vector2_type;
  extent_square: extent_square_type): boolean;
var
  inside: boolean;
begin
  inside := false;
  if (point.x >= extent_square[left]) then
    if (point.x <= extent_square[right]) then
      if (point.y >= extent_square[front]) then
        if (point.y <= extent_square[back]) then
          inside := true;

  Point_in_extent_square := inside;
end; {function Point_in_extent_square}


function Extent_square_intersection(ray: ray2_type;
  extent_square: extent_square_type): real;
var
  side: extent_type;
  t, new_t: real;
  point: vector2_type;
begin
  {**********************************************}
  { find intersection between ray and extent box }
  {**********************************************}
  t := infinity;
  for side := left to top do
    if (side = left) or (side = right) then
      begin
        if (ray.direction.x <> 0) then
          begin
            new_t := (extent_square[side] - ray.location.x) / ray.direction.x;
            if (new_t < t) and (new_t > 0) then
              begin
                point := Vector2_sum(ray.location, Vector2_scale(ray.direction,
                  new_t));
                if (point.y >= extent_square[front]) and (point.y <=
                  extent_square[back]) then
                  t := new_t;
              end;
          end;
      end
    else if (side = front) or (side = back) then
      begin
        if (ray.direction.y <> 0) then
          begin
            new_t := (extent_square[side] - ray.location.y) / ray.direction.y;
            if (new_t < t) and (new_t > 0) then
              begin
                point := Vector2_sum(ray.location, Vector2_scale(ray.direction,
                  new_t));
                if (point.x >= extent_square[left]) and (point.x <=
                  extent_square[right]) then
                  t := new_t;
              end;
          end;
      end;

  Extent_square_intersection := t;
end; {function Extent_square_intersection}


function Line_in_extent_square(point1, point2: vector2_type;
  extent_square: extent_square_type): boolean;
var
  ray: ray2_type;
  t: real;
  inside: boolean;
begin
  ray.location := point1;
  ray.direction := Vector2_difference(point2, point1);
  t := Extent_square_intersection(ray, extent_square);

  if (t > (-tiny)) and (t < (1 + tiny)) then
    inside := true
  else
    inside := false;

  Line_in_extent_square := inside;
end; {function Line_in_extent_square}


{*************************************}
{ routines for comparing extent boxes }
{*************************************}


function Null_extent_box(extent_box: extent_box_type): boolean;
var
  null_extents: boolean;
begin
  if extent_box[left] > extent_box[right] then
    null_extents := true
  else if extent_box[front] > extent_box[back] then
    null_extents := true
  else if extent_box[bottom] > extent_box[top] then
    null_extents := true
  else
    null_extents := false;

  Null_extent_box := null_extents;
end; {function Null_extent_box}


function Disjoint_extent_boxes(extent_box1: extent_box_type;
  extent_box2: extent_box_type): boolean;
var
  disjoint: boolean;
begin
  disjoint := false;

  {*******************}
  { compare x extents }
  {*******************}
  if (extent_box1[left] > extent_box2[right]) then
    disjoint := true
  else if (extent_box2[left] > extent_box1[right]) then
    disjoint := true

    {*******************}
    { compare y extents }
    {*******************}
  else if (extent_box1[front] > extent_box2[back]) then
    disjoint := true
  else if (extent_box2[front] > extent_box1[back]) then
    disjoint := true

    {*******************}
    { compare z extents }
    {*******************}
  else if (extent_box1[bottom] > extent_box2[top]) then
    disjoint := true
  else if (extent_box2[bottom] > extent_box1[top]) then
    disjoint := true;

  Disjoint_extent_boxes := disjoint;
end; {function Disjoint_extent_boxes}


function Point_in_extent_box(point: vector_type;
  extent_box: extent_box_type): boolean;
var
  inside: boolean;
begin
  inside := false;
  if (point.x >= extent_box[left]) then
    if (point.x <= extent_box[right]) then
      if (point.y >= extent_box[front]) then
        if (point.y <= extent_box[back]) then
          if (point.z >= extent_box[bottom]) then
            if (point.z <= extent_box[top]) then
              inside := true;

  Point_in_extent_box := inside;
end; {function Point_in_extent_box}


function Extent_box_intersection(ray: ray_type;
  extent_box: extent_box_type): real;
var
  side: extent_type;
  t, new_t: real;
  point: vector_type;
begin
  {**********************************************}
  { find intersection between ray and extent box }
  {**********************************************}
  t := infinity;
  for side := left to top do
    if (side = left) or (side = right) then
      begin
        if (ray.direction.x <> 0) then
          begin
            new_t := (extent_box[side] - ray.location.x) / ray.direction.x;
            if (new_t < t) and (new_t > 0) then
              begin
                point := Vector_sum(ray.location, Vector_scale(ray.direction,
                  new_t));
                if (point.y >= extent_box[front]) and (point.y <=
                  extent_box[back]) and (point.z >= extent_box[bottom]) and
                  (point.z <= extent_box[top]) then
                  t := new_t;
              end;
          end;
      end
    else if (side = front) or (side = back) then
      begin
        if (ray.direction.y <> 0) then
          begin
            new_t := (extent_box[side] - ray.location.y) / ray.direction.y;
            if (new_t < t) and (new_t > 0) then
              begin
                point := Vector_sum(ray.location, Vector_scale(ray.direction,
                  new_t));
                if (point.x >= extent_box[left]) and (point.x <=
                  extent_box[right]) and (point.z >= extent_box[bottom]) and
                  (point.z <= extent_box[top]) then
                  t := new_t;
              end;
          end;
      end
    else if (side = bottom) or (side = top) then
      begin
        if (ray.direction.z <> 0) then
          begin
            new_t := (extent_box[side] - ray.location.z) / ray.direction.z;
            if (new_t < t) and (new_t > 0) then
              begin
                point := Vector_sum(ray.location, Vector_scale(ray.direction,
                  new_t));
                if (point.x >= extent_box[left]) and (point.x <=
                  extent_box[right]) and (point.y >= extent_box[front]) and
                  (point.y <= extent_box[back]) then
                  t := new_t;
              end;
          end;
      end;

  Extent_box_intersection := t;
end; {function Extent_box_intersection}


function Line_in_extent_box(point1, point2: vector_type;
  extent_box: extent_box_type): boolean;
var
  ray: ray_type;
  t: real;
  inside: boolean;
begin
  ray.location := point1;
  ray.direction := Vector_difference(point2, point1);
  t := Extent_box_intersection(ray, extent_box);

  if (t > (-tiny)) and (t < (1 + tiny)) then
    inside := true
  else
    inside := false;

  Line_in_extent_box := inside;
end; {function Line_in_extent_box}


function Plane_in_extent_box(coord_axes: coord_axes_type;
  extent_box: extent_box_type): boolean;
var
  above, below: boolean;
  counter1, counter2, counter3: extent_type;
  point: vector_type;
  inside: boolean;
begin
  inside := false;
  above := false;
  below := false;
  for counter1 := left to right do
    if not inside then
      for counter2 := front to back do
        if not inside then
          for counter3 := bottom to top do
            if not inside then
              begin
                point.x := extent_box[counter1];
                point.y := extent_box[counter2];
                point.z := extent_box[counter3];
                Transform_point_to_axes(point, coord_axes);
                if (point.z > 0) then
                  above := true
                else
                  below := true;
                if (above and below) then
                  inside := true;
              end;

  Plane_in_extent_box := inside;
end; {function Plane_in_extent_box}


{******************************}
{ routines for writing extents }
{******************************}


procedure Write_extent(extent: extent_type);
begin
  case extent of
    left:
      write('left');
    right:
      write('right');
    front:
      write('front');
    back:
      write('back');
    bottom:
      write('bottom');
    top:
      write('top');
  end;
end; {procedure Write_extent}


procedure Write_extent_square(extent_square: extent_square_type);
begin
  writeln('extent_square:');
  writeln('left = ', extent_square[left]);
  writeln('right = ', extent_square[right]);
  writeln('front = ', extent_square[front]);
  writeln('back = ', extent_square[back]);
end; {procedure Write_extent_square}


procedure Write_extent_box(extent_box: extent_box_type);
begin
  writeln('extent_box:');
  writeln('left = ', extent_box[left]);
  writeln('right = ', extent_box[right]);
  writeln('front = ', extent_box[front]);
  writeln('back = ', extent_box[back]);
  writeln('bottom = ', extent_box[bottom]);
  writeln('top = ', extent_box[top]);
end; {procedure Write_extent_box}


initialization
  Init_zero_extent_square(zero_extent_square);
  Init_unit_extent_square(unit_extent_square);

  Init_zero_extent_box(zero_extent_box);
  Init_unit_extent_box(unit_extent_box);
end.
