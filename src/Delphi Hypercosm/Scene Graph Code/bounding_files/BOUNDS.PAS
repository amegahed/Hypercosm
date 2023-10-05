unit bounds;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               bounds                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to implement some         }
{       simple non axis aligned bounding tests.                 }
{                                                               }
{       There are two types of bounding regions:                }
{       1) axis-aligned - 'extents'                             }
{       2) un-axis-aligned - 'bounds'                           }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, trans, coord_axes, extents;


type
  {***************************************}
  { planar and nonplanar bounding regions }
  {***************************************}
  bounding_square_type = array[left..right, front..back] of vector_type;
  bounding_box_type = array[left..right, front..back, bottom..top] of
    vector_type;

  {************************************}
  { general unaligned bounding regions }
  {************************************}
  bounding_kind_type = (null_bounds, planar_bounds, non_planar_bounds,
    infinite_planar_bounds, infinite_non_planar_bounds);
  bounding_kind_set_type = set of bounding_kind_type;

  bounding_ptr_type = ^bounding_type;
  bounding_type = record
    case bounding_kind: bounding_kind_type of

      planar_bounds: (
        bounding_square: bounding_square_type
        );

      non_planar_bounds: (
        bounding_box: bounding_box_type
        );

      null_bounds, infinite_planar_bounds, infinite_non_planar_bounds: (
        );

  end; {bounding_type}


var
  zero_bounding_square: bounding_square_type;
  unit_bounding_square: bounding_square_type;

  zero_bounding_box: bounding_box_type;
  unit_bounding_box: bounding_box_type;

  finite_bounding_kinds: bounding_kind_set_type;
  infinite_bounding_kinds: bounding_kind_set_type;


  {****************************************}
  { routines for creating bounding squares }
  {****************************************}
procedure Make_bounding_square_from_trans(var bounding_square:
  bounding_square_type;
  trans: trans_type);

{**************************************}
{ routines for creating bounding boxes }
{**************************************}
procedure Make_bounding_box_from_extent_box(var bounding_box: bounding_box_type;
  extent_box: extent_box_type);
procedure Make_bounding_box_from_trans(var bounding_box: bounding_box_type;
  trans: trans_type);

{******************************}
{ routines for creating bounds }
{******************************}
function To_finite_bounding_kind(bounding_kind: bounding_kind_type):
  bounding_kind_type;
function To_infinite_bounding_kind(bounding_kind: bounding_kind_type):
  bounding_kind_type;
procedure Make_bounds(var bounds: bounding_type;
  bounding_kind: bounding_kind_type;
  trans: trans_type);

{************************************************}
{ routines for creating extent boxes from bounds }
{************************************************}
procedure Extend_extent_box_to_bounding_square(var extent_box: extent_box_type;
  bounding_square: bounding_square_type);
procedure Extend_extent_box_to_bounding_box(var extent_box: extent_box_type;
  bounding_box: bounding_box_type);
procedure Extend_extent_box_to_bounds(var extent_box: extent_box_type;
  bounds: bounding_type);

{********************************************}
{ routines for transforming bounding squares }
{********************************************}
procedure Transform_bounding_square(var bounding_square: bounding_square_type;
  trans: trans_type);
procedure Transform_bounding_square_from_axes(var bounding_square:
  bounding_square_type;
  coord_axes: coord_axes_type);
procedure Transform_bounding_square_to_axes(var bounding_square:
  bounding_square_type;
  coord_axes: coord_axes_type);

{******************************************}
{ routines for transforming bounding boxes }
{******************************************}
procedure Transform_bounding_box(var bounding_box: bounding_box_type;
  trans: trans_type);
procedure Transform_bounding_box_from_axes(var bounding_box: bounding_box_type;
  coord_axes: coord_axes_type);
procedure Transform_bounding_box_to_axes(var bounding_box: bounding_box_type;
  coord_axes: coord_axes_type);

{**********************************}
{ routines for transforming bounds }
{**********************************}
function Bounds_to_trans(bounds: bounding_type): trans_type;
procedure Transform_bounds(var bounds: bounding_type;
  trans: trans_type);
procedure Transform_bounds_from_axes(var bounds: bounding_type;
  coord_axes: coord_axes_type);
procedure Transform_bounds_to_axes(var bounds: bounding_type;
  coord_axes: coord_axes_type);

{*******************************************}
{ routines for comparing bounds and extents }
{*******************************************}
function Bounds_contained_by_extent_box(bounds: bounding_type;
  extent_box: extent_box_type): boolean;
function Bounds_surround_extent_box(bounds: bounding_type;
  extent_box: extent_box_type): boolean;
function Bounds_in_extent_box(bounds: bounding_type;
  coord_axes: coord_axes_type;
  extent_box: extent_box_type): boolean;

{******************************************}
{ routines for writing bounding structures }
{******************************************}
procedure Write_bounding_square(bounding_square: bounding_square_type);
procedure Write_bounding_box(bounding_box: bounding_box_type);
procedure Write_bounding_kind(bounding_kind: bounding_kind_type);
procedure Write_bounds(bounds: bounding_type);


implementation
uses
  constants;


{*************************************************}
{ routines for initializing unit bounding squares }
{*************************************************}


procedure Init_zero_bounding_square(var bounding_square: bounding_square_type);
begin
  bounding_square[left, front] := zero_vector;
  bounding_square[left, back] := zero_vector;

  bounding_square[right, front] := zero_vector;
  bounding_square[right, back] := zero_vector;
end; {procedure Init_zero_bounding_square}


procedure Init_unit_bounding_square(var bounding_square: bounding_square_type);
begin
  bounding_square[left, front] := To_vector(-1, -1, 0);
  bounding_square[left, back] := To_vector(-1, 1, 0);

  bounding_square[right, front] := To_vector(1, -1, 0);
  bounding_square[right, back] := To_vector(1, 1, 0);
end; {procedure Init_unit_bounding_square}


{***********************************************}
{ routines for initializing unit bounding boxes }
{***********************************************}


procedure Init_zero_bounding_box(var bounding_box: bounding_box_type);
begin
  bounding_box[left, front, bottom] := zero_vector;
  bounding_box[left, back, bottom] := zero_vector;

  bounding_box[right, front, bottom] := zero_vector;
  bounding_box[right, back, bottom] := zero_vector;

  bounding_box[left, front, top] := zero_vector;
  bounding_box[left, back, top] := zero_vector;

  bounding_box[right, front, top] := zero_vector;
  bounding_box[right, back, top] := zero_vector;
end; {procedure Init_zero_bounding_box}


procedure Init_unit_bounding_box(var bounding_box: bounding_box_type);
begin
  bounding_box[left, front, bottom] := To_vector(-1, -1, -1);
  bounding_box[left, back, bottom] := To_vector(-1, 1, -1);

  bounding_box[right, front, bottom] := To_vector(1, -1, -1);
  bounding_box[right, back, bottom] := To_vector(1, 1, -1);

  bounding_box[left, front, top] := To_vector(-1, -1, 1);
  bounding_box[left, back, top] := To_vector(-1, 1, 1);

  bounding_box[right, front, top] := To_vector(1, -1, 1);
  bounding_box[right, back, top] := To_vector(1, 1, 1);
end; {procedure Init_unit_bounding_box}


{****************************************}
{ routines for creating bounding squares }
{****************************************}


procedure Make_bounding_square_from_trans(var bounding_square:
  bounding_square_type;
  trans: trans_type);
var
  counter1, counter2: extent_type;
  point: vector_type;
begin
  with trans do
    for counter1 := left to right do
      for counter2 := front to back do
        begin
          point := origin;
          if (counter1 = right) then
            point := Vector_sum(point, x_axis)
          else
            point := Vector_difference(point, x_axis);
          if (counter2 = back) then
            point := Vector_sum(point, y_axis)
          else
            point := Vector_difference(point, y_axis);

          bounding_square[counter1, counter2] := point;
        end;
end; {procedure Make_bounding_square_from_trans}


{**************************************}
{ routines for creating bounding boxes }
{**************************************}


procedure Make_bounding_box_from_extent_box(var bounding_box: bounding_box_type;
  extent_box: extent_box_type);
var
  counter1, counter2, counter3: extent_type;
  point: vector_type;
begin
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        begin
          point.x := extent_box[counter1];
          point.y := extent_box[counter2];
          point.z := extent_box[counter3];
          bounding_box[counter1, counter2, counter3] := point;
        end;
end; {procedure Make_bounding_box_from_extent_box}


procedure Make_bounding_box_from_trans(var bounding_box: bounding_box_type;
  trans: trans_type);
var
  counter1, counter2, counter3: extent_type;
  point: vector_type;
begin
  with trans do
    for counter1 := left to right do
      for counter2 := front to back do
        for counter3 := bottom to top do
          begin
            point := origin;
            if (counter1 = right) then
              point := Vector_sum(point, x_axis)
            else
              point := Vector_difference(point, x_axis);
            if (counter2 = back) then
              point := Vector_sum(point, y_axis)
            else
              point := Vector_difference(point, y_axis);
            if (counter3 = top) then
              point := Vector_sum(point, z_axis)
            else
              point := Vector_difference(point, z_axis);

            bounding_box[counter1, counter2, counter3] := point;
          end;
end; {procedure Make_bounding_box_from_trans}


{******************************}
{ routines for creating bounds }
{******************************}


function To_finite_bounding_kind(bounding_kind: bounding_kind_type):
  bounding_kind_type;
begin
  case bounding_kind of

    infinite_planar_bounds:
      bounding_kind := planar_bounds;

    infinite_non_planar_bounds:
      bounding_kind := non_planar_bounds;

    null_bounds, planar_bounds, non_planar_bounds:
      ; {do nothing}

  end; {case}

  To_finite_bounding_kind := bounding_kind;
end; {function To_finite_bounding_kind}


function To_infinite_bounding_kind(bounding_kind: bounding_kind_type):
  bounding_kind_type;
begin
  case bounding_kind of

    planar_bounds:
      bounding_kind := infinite_planar_bounds;

    non_planar_bounds:
      bounding_kind := infinite_non_planar_bounds;

    null_bounds, infinite_planar_bounds, infinite_non_planar_bounds:
      ; {do nothing}

  end; {case}

  To_infinite_bounding_kind := bounding_kind;
end; {function To_infinite_bounding_kind}


procedure Make_bounds(var bounds: bounding_type;
  bounding_kind: bounding_kind_type;
  trans: trans_type);
begin
  bounds.bounding_kind := bounding_kind;
  case bounding_kind of

    planar_bounds:
      Make_bounding_square_from_trans(bounds.bounding_square, trans);

    non_planar_bounds:
      Make_bounding_box_from_trans(bounds.bounding_box, trans);

    null_bounds, infinite_planar_bounds, infinite_non_planar_bounds:
      ; {do nothing}

  end; {case}
end; {procedure Make_bounds}


{************************************************}
{ routines for creating extent boxes from bounds }
{************************************************}


procedure Extend_extent_box_to_bounding_square(var extent_box: extent_box_type;
  bounding_square: bounding_square_type);
var
  counter1, counter2: extent_type;
begin
  for counter1 := left to right do
    for counter2 := front to back do
      Extend_extent_box_to_point(extent_box, bounding_square[counter1,
        counter2]);
end; {procedure Extend_extent_box_to_bounding_square}


procedure Extend_extent_box_to_bounding_box(var extent_box: extent_box_type;
  bounding_box: bounding_box_type);
var
  counter1, counter2, counter3: extent_type;
begin
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        Extend_extent_box_to_point(extent_box, bounding_box[counter1, counter2,
          counter3]);
end; {procedure Extend_extent_box_to_bounding_box}


procedure Extend_extent_box_to_bounds(var extent_box: extent_box_type;
  bounds: bounding_type);
begin
  if bounds.bounding_kind in [planar_bounds, non_planar_bounds] then
    case bounds.bounding_kind of

      planar_bounds:
        Extend_extent_box_to_bounding_square(extent_box,
          bounds.bounding_square);

      non_planar_bounds:
        Extend_extent_box_to_bounding_box(extent_box, bounds.bounding_box);

    end; {case}
end; {procedure Extend_extent_box_to_bounds}


{**********************************}
{ routines for transforming bounds }
{**********************************}


function Bounds_to_trans(bounds: bounding_type): trans_type;
var
  trans: trans_type;
begin
  with bounds do
    case bounding_kind of

      planar_bounds:
        begin
          trans.x_axis := Vector_scale(Vector_difference(bounding_square[right,
            front],
              bounding_square[left, front]), 0.5);
          trans.y_axis := Vector_scale(Vector_difference(bounding_square[left,
            back],
              bounding_square[left, front]), 0.5);
          trans.z_axis := Cross_product(trans.x_axis, trans.y_axis);
          trans.origin := Vector_scale(Vector_sum(bounding_square[left, front],
            bounding_square[right, back]), 0.5);
        end;

      non_planar_bounds:
        begin
          trans.x_axis := Vector_scale(Vector_difference(bounding_box[right,
            front, bottom],
              bounding_box[left, front, bottom]), 0.5);
          trans.y_axis := Vector_scale(Vector_difference(bounding_box[left,
            back, bottom],
              bounding_box[left, front, bottom]), 0.5);
          trans.z_axis := Vector_scale(Vector_difference(bounding_box[left,
            front, top],
              bounding_box[left, front, bottom]), 0.5);
          trans.origin := Vector_scale(Vector_sum(bounding_box[left, front,
            bottom],
              bounding_box[right, back, top]), 0.5);
        end;

      null_bounds, infinite_planar_bounds, infinite_non_planar_bounds:
        trans := null_trans;

    end; {case}

  Bounds_to_trans := trans;
end; {function Bounds_to_trans}


{********************************************}
{ routines for transforming bounding squares }
{********************************************}


procedure Transform_bounding_square(var bounding_square: bounding_square_type;
  trans: trans_type);
var
  counter1, counter2: extent_type;
begin
  for counter1 := left to right do
    for counter2 := front to back do
      Transform_point(bounding_square[counter1, counter2], trans);
end; {procedure Transform_bounding_square}


procedure Transform_bounding_square_from_axes(var bounding_square:
  bounding_square_type;
  coord_axes: coord_axes_type);
var
  counter1, counter2: extent_type;
begin
  for counter1 := left to right do
    for counter2 := front to back do
      Transform_point_from_axes(bounding_square[counter1, counter2],
        coord_axes);
end; {procedure Transform_bounding_square_from_axes}


procedure Transform_bounding_square_to_axes(var bounding_square:
  bounding_square_type;
  coord_axes: coord_axes_type);
var
  counter1, counter2: extent_type;
begin
  for counter1 := left to right do
    for counter2 := front to back do
      Transform_point_to_axes(bounding_square[counter1, counter2], coord_axes);
end; {procedure Transform_bounding_square_to_axes}


{******************************************}
{ routines for transforming bounding boxes }
{******************************************}


procedure Transform_bounding_box(var bounding_box: bounding_box_type;
  trans: trans_type);
var
  counter1, counter2, counter3: extent_type;
begin
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        Transform_point(bounding_box[counter1, counter2, counter3], trans);
end; {procedure Transform_bounding_box}


procedure Transform_bounding_box_from_axes(var bounding_box: bounding_box_type;
  coord_axes: coord_axes_type);
var
  counter1, counter2, counter3: extent_type;
begin
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        Transform_point_from_axes(bounding_box[counter1, counter2, counter3],
          coord_axes);
end; {procedure Transform_bounding_box_from_axes}


procedure Transform_bounding_box_to_axes(var bounding_box: bounding_box_type;
  coord_axes: coord_axes_type);
var
  counter1, counter2, counter3: extent_type;
begin
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        Transform_point_to_axes(bounding_box[counter1, counter2, counter3],
          coord_axes);
end; {procedure Transform_bounding_box_to_axes}


{*******************************************************}
{ routines for transforming bounds from transformations }
{*******************************************************}


procedure Transform_bounds(var bounds: bounding_type;
  trans: trans_type);
begin
  case bounds.bounding_kind of

    null_bounds, infinite_planar_bounds, infinite_non_planar_bounds:
      ; {do nothing}

    planar_bounds:
      Transform_bounding_square(bounds.bounding_square, trans);

    non_planar_bounds:
      Transform_bounding_box(bounds.bounding_box, trans);

  end; {case}
end; {procedure Transform_bounds}


procedure Transform_bounds_from_axes(var bounds: bounding_type;
  coord_axes: coord_axes_type);
begin
  case bounds.bounding_kind of

    null_bounds, infinite_planar_bounds, infinite_non_planar_bounds:
      ; {do nothing}

    planar_bounds:
      Transform_bounding_square_from_axes(bounds.bounding_square, coord_axes);

    non_planar_bounds:
      Transform_bounding_box_from_axes(bounds.bounding_box, coord_axes);

  end; {case}
end; {procedure Transform_bounds_from_axes}


procedure Transform_bounds_to_axes(var bounds: bounding_type;
  coord_axes: coord_axes_type);
begin
  case bounds.bounding_kind of

    null_bounds, infinite_planar_bounds, infinite_non_planar_bounds:
      ; {do nothing}

    planar_bounds:
      Transform_bounding_square_to_axes(bounds.bounding_square, coord_axes);

    non_planar_bounds:
      Transform_bounding_box_to_axes(bounds.bounding_box, coord_axes);

  end; {case}
end; {procedure Transform_bounds_to_axes}


{*******************************************}
{ routines for comparing bounds and extents }
{*******************************************}


function Line_in_unit_square(point1, point2: vector_type): boolean;
var
  z_direction: real;
  x, y: real;
  in_square: boolean;
  t: real;
begin
  in_square := false;
  z_direction := point2.z - point1.z;
  if (z_direction <> 0) then
    begin
      t := (-point1.z) / z_direction;
      if (t > -tiny) and (t < (1 + tiny)) then
        begin {check to see if in unit square}
          x := point1.x + (t * (point2.x - point1.x));
          y := point1.y + (t * (point2.y - point1.y));
          if (x > -1) and (x < 1) and (y > -1) and (y < 1) then
            in_square := true;
        end;
    end;
  Line_in_unit_square := in_square;
end; {function Line_in_unit_square}


function Box_edges_in_unit_square(box: bounding_box_type): boolean;
var
  inside: boolean;
begin
  {********************************************}
  { if all edges fail to intersect square then }
  { inside = false otherwise inside = true     }
  {********************************************}
  inside := true;

  {***********}
  { top edges }
  {***********}
  if not Line_in_unit_square(box[right, front, top], box[right, back, top]) then
    if not Line_in_unit_square(box[right, back, top], box[left, back, top]) then
      if not Line_in_unit_square(box[left, back, top], box[left, front, top])
        then
        if not Line_in_unit_square(box[left, front, top], box[right, front, top])
          then
          {**************}
          { bottom edges }
          {**************}
          if not Line_in_unit_square(box[right, front, bottom], box[right, back,
            bottom]) then
            if not Line_in_unit_square(box[right, back, bottom], box[left, back,
              bottom]) then
              if not Line_in_unit_square(box[left, back, bottom], box[left,
                front, bottom]) then
                if not Line_in_unit_square(box[left, front, bottom], box[right,
                  front, bottom]) then
                  {************}
                  { side edges }
                  {************}
                  if not Line_in_unit_square(box[right, front, bottom],
                    box[right, front, top]) then
                    if not Line_in_unit_square(box[right, back, bottom],
                      box[right, back, top]) then
                      if not Line_in_unit_square(box[left, back, bottom],
                        box[left, back, top]) then
                        if not Line_in_unit_square(box[left, front, bottom],
                          box[left, front, top]) then
                          inside := false;

  Box_edges_in_unit_square := inside;
end; {function Box_edges_in_unit_square}


function Square_edges_in_extent_box(square: bounding_square_type;
  extent_box: extent_box_type): boolean;
var
  inside: boolean;
begin
  {*********************************************}
  { if all edges fail to intersect extent_box   }
  { then inside = false otherwise inside = true }
  {*********************************************}
  inside := true;
  if not Line_in_extent_box(square[right, front], square[right, back],
    extent_box) then
    if not Line_in_extent_box(square[right, back], square[left, back],
      extent_box) then
      if not Line_in_extent_box(square[left, back], square[left, front],
        extent_box) then
        if not Line_in_extent_box(square[left, front], square[right, front],
          extent_box) then
          inside := false;

  Square_edges_in_extent_box := inside;
end; {function Square_edges_in_extent_box}


function Box_edges_in_extent_box(box: bounding_box_type;
  extent_box: extent_box_type): boolean;
var
  inside: boolean;
begin
  {*********************************************}
  { if all edges fail to intersect extent_box   }
  { then inside = false otherwise inside = true }
  {*********************************************}
  inside := true;

  {***********}
  { top edges }
  {***********}
  if not Line_in_extent_box(box[right, front, top], box[right, back, top],
    extent_box) then
    if not Line_in_extent_box(box[right, back, top], box[left, back, top],
      extent_box) then
      if not Line_in_extent_box(box[left, back, top], box[left, front, top],
        extent_box) then
        if not Line_in_extent_box(box[left, front, top], box[right, front, top],
          extent_box) then
          {**************}
          { bottom edges }
          {**************}
          if not Line_in_extent_box(box[right, front, bottom], box[right, back,
            bottom], extent_box) then
            if not Line_in_extent_box(box[right, back, bottom], box[left, back,
              bottom], extent_box) then
              if not Line_in_extent_box(box[left, back, bottom], box[left,
                front, bottom], extent_box) then
                if not Line_in_extent_box(box[left, front, bottom], box[right,
                  front, bottom], extent_box) then
                  {************}
                  { side edges }
                  {************}
                  if not Line_in_extent_box(box[right, front, bottom],
                    box[right, front, top], extent_box) then
                    if not Line_in_extent_box(box[right, back, bottom],
                      box[right, back, top], extent_box) then
                      if not Line_in_extent_box(box[left, back, bottom],
                        box[left, back, top], extent_box) then
                        if not Line_in_extent_box(box[left, front, bottom],
                          box[left, front, top], extent_box) then
                          inside := false;
  Box_edges_in_extent_box := inside;
end; {function Box_edges_in_extent_box}


function Square_disjoint_from_extent_box(square: bounding_square_type;
  extent_box: extent_box_type): boolean;
var
  counter, counter1, counter2: extent_type;
  disjoint, side_disjoint: boolean;
  point: vector_type;
begin
  disjoint := false;

  {*******************************}
  { check each side of extent_box }
  {*******************************}
  for counter := left to top do
    if not disjoint then
      begin
        {*****************************}
        { check all corners of square }
        { against side of extent_box  }
        {*****************************}
        side_disjoint := true;
        for counter1 := left to right do
          if side_disjoint then
            for counter2 := front to back do
              if side_disjoint then
                begin
                  point := square[counter1, counter2];
                  case (counter) of
                    left:
                      if point.x >= extent_box[left] then
                        side_disjoint := false;
                    right:
                      if point.x <= extent_box[right] then
                        side_disjoint := false;
                    front:
                      if point.y >= extent_box[front] then
                        side_disjoint := false;
                    back:
                      if point.y <= extent_box[back] then
                        side_disjoint := false;
                    bottom:
                      if point.z >= extent_box[bottom] then
                        side_disjoint := false;
                    top:
                      if point.z <= extent_box[top] then
                        side_disjoint := false;
                  end; {case statement}
                end;
        {************************}
        { were all points tested }
        {************************}
        if side_disjoint then
          disjoint := true;
      end;
  Square_disjoint_from_extent_box := disjoint;
end; {function Square_disjoint_from_extent_box}


function Box_disjoint_from_extent_box(box: bounding_box_type;
  extent_box: extent_box_type): boolean;
var
  counter, counter1, counter2, counter3: extent_type;
  disjoint, side_disjoint: boolean;
  point: vector_type;
begin
  disjoint := false;

  {*******************************}
  { check each side of extent_box }
  {*******************************}
  for counter := left to top do
    if not disjoint then
      begin
        {****************************}
        { check all corners of box   }
        { against side of extent_box }
        {****************************}
        side_disjoint := true;
        for counter1 := left to right do
          if side_disjoint then
            for counter2 := front to back do
              if side_disjoint then
                for counter3 := bottom to top do
                  if side_disjoint then
                    begin
                      point := box[counter1, counter2, counter3];
                      case (counter) of
                        left:
                          if point.x >= extent_box[left] then
                            side_disjoint := false;
                        right:
                          if point.x <= extent_box[right] then
                            side_disjoint := false;
                        front:
                          if point.y >= extent_box[front] then
                            side_disjoint := false;
                        back:
                          if point.y <= extent_box[back] then
                            side_disjoint := false;
                        bottom:
                          if point.z >= extent_box[bottom] then
                            side_disjoint := false;
                        top:
                          if point.z <= extent_box[top] then
                            side_disjoint := false;
                      end; {case statement}
                    end;
        if side_disjoint then
          disjoint := true; {all points tested}
      end;
  Box_disjoint_from_extent_box := disjoint;
end; {function Box_disjoint_from_extent_box}


function Square_in_extent_box(square: bounding_square_type;
  coord_axes: coord_axes_type;
  extent_box: extent_box_type): boolean;
var
  inside, done: boolean;
  counter1, counter2, counter3: extent_type;
  extent_box_bounding_box: bounding_box_type;
begin
  done := false;
  inside := false;

  {*******************************************************}
  { test #1 - are any corners of square inside extent_box }
  {*******************************************************}
  for counter1 := left to right do
    if not done then
      for counter2 := front to back do
        if not done then
          if Point_in_extent_box(square[counter1, counter2], extent_box) then
            begin
              inside := true;
              done := true;
            end;

  {**********************************************}
  { test #2 - are square and extent_box disjoint }
  {**********************************************}
  if not done then {continue testing}
    if Square_disjoint_from_extent_box(square, extent_box) then
      begin
        inside := false;
        done := true;
      end;

  {*******************************************************}
  { test #3 - do any edges of square intersect extent_box }
  {*******************************************************}
  if not done then {continue testing}
    if Square_edges_in_extent_box(square, extent_box) then
      begin
        inside := true;
        done := true;
      end;

  {*******************************************************}
  { test #4 - do any edges of extent_box intersect square }
  {*******************************************************}
  if not done then {continue testing}
    begin
      Make_bounding_box_from_extent_box(extent_box_bounding_box, extent_box);
      for counter1 := left to right do
        for counter2 := front to back do
          for counter3 := bottom to top do
            Transform_point_to_axes(extent_box_bounding_box[counter1, counter2,
              counter3], coord_axes);
      if Box_edges_in_unit_square(extent_box_bounding_box) then
        begin
          inside := true;
        end;
    end;

  Square_in_extent_box := inside;
end; {function Square_in_extent_box}


function Box_in_extent_box(box: bounding_box_type;
  coord_axes: coord_axes_type;
  extent_box: extent_box_type): boolean;
var
  inside, done: boolean;
  counter1, counter2, counter3: extent_type;
  point: vector_type;
  extent_box_bounding_box: bounding_box_type;
begin
  done := false;
  inside := false;

  {****************************************************}
  { test #1 - are any corners of box inside extent_box }
  {****************************************************}
  for counter1 := left to right do
    if not done then
      for counter2 := front to back do
        if not done then
          for counter3 := bottom to top do
            if not done then
              if Point_in_extent_box(box[counter1, counter2, counter3],
                extent_box) then
                begin
                  inside := true;
                  done := true;
                end;

  {*******************************************}
  { test #2 - are box and extent_box disjoint }
  {*******************************************}
  if not done then {continue testing}
    if Box_disjoint_from_extent_box(box, extent_box) then
      begin
        inside := false;
        done := true;
      end;

  {****************************************************}
  { test #3 - are any corners of extent_box inside box }
  {****************************************************}
  if not done then {continue testing}
    for counter1 := left to right do
      if not done then
        for counter2 := front to back do
          if not done then
            for counter3 := bottom to top do
              if not done then
                begin
                  point.x := extent_box[counter1];
                  point.y := extent_box[counter2];
                  point.z := extent_box[counter3];
                  Transform_point_to_axes(point, coord_axes);
                  if Point_in_extent_box(point, unit_extent_box) then
                    begin
                      inside := true;
                      done := true;
                    end
                  else
                    extent_box_bounding_box[counter1, counter2, counter3] :=
                      point;
                end;

  {****************************************************}
  { test #4 - do any edges of box intersect extent_box }
  {****************************************************}
  if not done then {continue testing}
    if Box_edges_in_extent_box(box, extent_box) then
      begin
        inside := true;
        done := true;
      end;

  {****************************************************}
  { test #5 - do any edges of extent_box intersect box }
  {****************************************************}
  if not done then {continue testing}
    if Box_edges_in_extent_box(extent_box_bounding_box, unit_extent_box) then
      begin
        inside := true;
      end;

  Box_in_extent_box := inside;
end; {function Box_in_extent_box}


function Bounds_in_extent_box(bounds: bounding_type;
  coord_axes: coord_axes_type;
  extent_box: extent_box_type): boolean;
var
  inside: boolean;
begin
  inside := false;

  case (bounds.bounding_kind) of

    null_bounds:
      inside := false;

    infinite_non_planar_bounds:
      inside := true;

    infinite_planar_bounds:
      inside := Plane_in_extent_box(coord_axes, extent_box);

    planar_bounds:
      inside := Square_in_extent_box(bounds.bounding_square, coord_axes,
        extent_box);

    non_planar_bounds:
      inside := Box_in_extent_box(bounds.bounding_box, coord_axes, extent_box);

  end; {case statement}

  Bounds_in_extent_box := inside;
end; {function Bounds_in_extent_box}


function Square_surrounds_extent_box(square: bounding_square_type;
  extent_box: extent_box_type): boolean;
var
  surrounding, done: boolean;
  counter, counter1, counter2: extent_type;
  point: vector_type;
begin
  surrounding := true;

  {*******************************}
  { check each face of extent_box }
  {*******************************}
  for counter := left to top do
    if surrounding then
      begin
        {*****************************}
        { check all corners of square }
        { against face of extent_box  }
        {*****************************}
        done := false;
        for counter1 := left to right do
          if not done then
            for counter2 := front to back do
              if not done then
                begin
                  point := square[counter1, counter2];
                  case (counter) of
                    left:
                      if point.x < extent_box[left] then
                        done := true;
                    right:
                      if point.x > extent_box[right] then
                        done := true;
                    front:
                      if point.y < extent_box[front] then
                        done := true;
                    back:
                      if point.y > extent_box[back] then
                        done := true;
                    bottom:
                      if point.z < extent_box[bottom] then
                        done := true;
                    top:
                      if point.z > extent_box[top] then
                        done := true;
                  end; {case statement}
                end;
        {************************}
        { were all points tested }
        {************************}
        if not done then
          surrounding := false;
      end;
  Square_surrounds_extent_box := surrounding;
end; {function Square_surrounds_extent_box}


function Box_surrounds_extent_box(box: bounding_box_type;
  extent_box: extent_box_type): boolean;
var
  surrounding, done: boolean;
  counter, counter1, counter2, counter3: extent_type;
  point: vector_type;
begin
  surrounding := true;

  {*******************************}
  { check each face of extent_box }
  {*******************************}
  for counter := left to top do
    if surrounding then
      begin
        {****************************}
        { check all corners of box   }
        { against face of extent_box }
        {****************************}
        done := false;
        for counter1 := left to right do
          if not done then
            for counter2 := front to back do
              if not done then
                for counter3 := bottom to top do
                  if not done then
                    begin
                      point := box[counter1, counter2, counter3];
                      case (counter) of
                        left:
                          if point.x < extent_box[left] then
                            done := true;
                        right:
                          if point.x > extent_box[right] then
                            done := true;
                        front:
                          if point.y < extent_box[front] then
                            done := true;
                        back:
                          if point.y > extent_box[back] then
                            done := true;
                        bottom:
                          if point.z < extent_box[bottom] then
                            done := true;
                        top:
                          if point.z > extent_box[top] then
                            done := true;
                      end; {case statement}
                    end;
        {************************}
        { were all points tested }
        {************************}
        if not done then
          surrounding := false;
      end;
  Box_surrounds_extent_box := surrounding;
end; {function Box_surrounds_extent_box}


function Bounds_surround_extent_box(bounds: bounding_type;
  extent_box: extent_box_type): boolean;
var
  surrounding: boolean;
begin
  surrounding := false;

  case (bounds.bounding_kind) of

    null_bounds:
      surrounding := false;

    infinite_planar_bounds, infinite_non_planar_bounds:
      surrounding := true;

    planar_bounds:
      surrounding := Square_surrounds_extent_box(bounds.bounding_square,
        extent_box);

    non_planar_bounds:
      surrounding := Box_surrounds_extent_box(bounds.bounding_box, extent_box);

  end; {case statement}

  Bounds_surround_extent_box := surrounding;
end; {function Bounds_surround_extent_box}


function Bounds_contained_by_extent_box(bounds: bounding_type;
  extent_box: extent_box_type): boolean;
var
  contained: boolean;
  counter1, counter2, counter3: extent_type;
begin
  contained := false;

  case (bounds.bounding_kind) of

    null_bounds:
      contained := true;

    infinite_planar_bounds, infinite_non_planar_bounds:
      contained := false;

    planar_bounds:
      begin
        contained := true;
        for counter1 := left to right do
          if contained then
            for counter2 := front to back do
              if contained then
                if not Point_in_extent_box(bounds.bounding_square[counter1,
                  counter2], extent_box) then
                  contained := false;
      end;

    non_planar_bounds:
      begin
        contained := true;
        for counter1 := left to right do
          if contained then
            for counter2 := front to back do
              if contained then
                for counter3 := bottom to top do
                  if contained then
                    if not Point_in_extent_box(bounds.bounding_box[counter1,
                      counter2, counter3], extent_box) then
                      contained := false;
      end;

  end; {case statement}

  Bounds_contained_by_extent_box := contained;
end; {function Bounds_contained_by_extent_box}


{******************************************}
{ routines for writing bounding structures }
{******************************************}


procedure Write_bounding_square(bounding_square: bounding_square_type);
var
  counter1, counter2: extent_type;
begin
  writeln('bounding_square:');
  for counter1 := left to right do
    for counter2 := front to back do
      begin
        Write_extent(counter1);
        write(', ');
        Write_extent(counter2);
        write(' = ');
        with bounding_square[counter1][counter2] do
          writeln(x: 4: 4, ' ', y: 4: 4, ' ', z: 4: 4);
      end;
end; {procedure Write_bounding_square}


procedure Write_bounding_box(bounding_box: bounding_box_type);
var
  counter1, counter2, counter3: extent_type;
begin
  writeln('bounding_box:');
  for counter1 := left to right do
    for counter2 := front to back do
      for counter3 := bottom to top do
        begin
          Write_extent(counter1);
          write(', ');
          Write_extent(counter2);
          write(', ');
          Write_extent(counter3);
          write(' = ');
          with bounding_box[counter1][counter2][counter3] do
            writeln(x: 4: 4, ' ', y: 4: 4, ' ', z: 4: 4);
        end;
end; {procedure Write_bounding_box}


procedure Write_bounding_kind(bounding_kind: bounding_kind_type);
begin
  case bounding_kind of

    null_bounds:
      write('null_bounds');

    planar_bounds:
      write('planar_bounds');

    non_planar_bounds:
      write('non_planar_bounds');

    infinite_planar_bounds:
      write('infinite_planar_bounds');

    infinite_non_planar_bounds:
      write('infinite_non_planar_bounds');

  end;
end; {procedure Write_bounding_kind}


procedure Write_bounds(bounds: bounding_type);
begin
  write('bounds:');

  write('bounding_kind = ');
  Write_bounding_kind(bounds.bounding_kind);
  writeln;

  case bounds.bounding_kind of

    planar_bounds:
      Write_bounding_square(bounds.bounding_square);

    non_planar_bounds:
      Write_bounding_box(bounds.bounding_box);

    null_bounds, infinite_planar_bounds, infinite_non_planar_bounds:
      ; {do nothing}

  end;
end; {procedure Write_bounds}


initialization
  Init_zero_bounding_square(zero_bounding_square);
  Init_unit_bounding_square(unit_bounding_square);

  Init_zero_bounding_box(zero_bounding_box);
  Init_unit_bounding_box(unit_bounding_box);

  finite_bounding_kinds := [planar_bounds, non_planar_bounds];
  infinite_bounding_kinds := [infinite_planar_bounds,
    infinite_non_planar_bounds];
end.

