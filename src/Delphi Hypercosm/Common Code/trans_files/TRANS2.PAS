unit trans2;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               trans2                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The transform module provides data structs and          }
{       routines for transforming between different 2d          }
{       coordinate frames. The coord frames may be stretched    }
{       or skewed and will allow any linear transformation.     }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  vectors2, rays2;


type
  trans2_type = record
    origin, x_axis, y_axis: vector2_type;
  end; {trans2_type}


var
  unit_trans2: trans2_type;
  null_trans2: trans2_type;


{*************}
{ constructor }
{*************}
function To_trans2(origin, x_axis, y_axis: vector2_type): trans2_type;

{*****************}
{ transformations }
{*****************}
procedure Transform_vector2(var vector: vector2_type;
  trans: trans2_type);
procedure Transform_point2(var point: vector2_type;
  trans: trans2_type);
procedure Transform_ray2(var ray: ray2_type;
  trans: trans2_type);
procedure Transform_trans2(var trans: trans2_type;
  source_trans: trans2_type);

{**************}
{ diagnositics }
{**************}
procedure Write_trans2(trans: trans2_type);


implementation


{*************}
{ constructor }
{*************}


function To_trans2(origin, x_axis, y_axis: vector2_type): trans2_type;
var
  trans2: trans2_type;
begin
  trans2.origin := origin;
  trans2.x_axis := x_axis;
  trans2.y_axis := y_axis;
  To_trans2 := trans2;
end; {function To_trans2}


{*****************}
{ transformations }
{*****************}


procedure Transform_vector2(var vector: vector2_type;
  trans: trans2_type);
var
  temp: vector2_type;
begin
  {*********************************************}
  { point := Sum(Scale(trans.x_axis, point.x),  }
  {          Scale(trans.Z_axis, point.y));     }
  {*********************************************}
  temp.x := trans.x_axis.x * vector.x + trans.y_axis.x * vector.y;
  temp.y := trans.x_axis.y * vector.x + trans.y_axis.y * vector.y;
  vector := temp;
end; {procedure Transform_vector2}


procedure Transform_point2(var point: vector2_type;
  trans: trans2_type);
var
  temp: vector2_type;
begin
  {**********************************************}
  { point := Sum(trans.origin,                   }
  {          Sum(Scale(trans.x_axis, point.x),   }
  {              Scale(trans.Z_axis, point.y))); }
  {**********************************************}
  temp.x := trans.origin.x + trans.x_axis.x * point.x + trans.y_axis.x *
    point.y;
  temp.y := trans.origin.y + trans.x_axis.y * point.x + trans.y_axis.y *
    point.y;
  point := temp;
end; {procedure Transform_point2}


procedure Transform_ray2(var ray: ray2_type;
  trans: trans2_type);
begin
  Transform_point2(ray.location, trans);
  Transform_vector2(ray.direction, trans);
end; {procedure Transform_ray2}


procedure Transform_trans2(var trans: trans2_type;
  source_trans: trans2_type);
begin
  Transform_point2(trans.origin, source_trans);
  Transform_vector2(trans.x_axis, source_trans);
  Transform_vector2(trans.y_axis, source_trans);
end; {procedure Transform_trans2}


{**************}
{ diagnositics }
{**************}


procedure Write_trans2(trans: trans2_type);
begin
  with trans do
    begin
      writeln('trans with');
      with origin do
        writeln('origin = ', x, y);
      with x_axis do
        writeln('x_axis = ', x, y);
      with y_axis do
        writeln('y_axis = ', x, y);
    end;
end; {procedure Write_trans2}


initialization
  unit_trans2 := To_trans2(zero_vector2, x_vector2, y_vector2);
  null_trans2 := To_trans2(zero_vector2, zero_vector2, zero_vector2);
end.
