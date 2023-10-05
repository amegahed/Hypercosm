unit trans;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               trans                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The transform module provides data structs and          }
{       routines for transforming between different 3d          }
{       coordinate frames. The coord frames may be stretched    }
{       or skewed and will allow any linear transformation.     }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  vectors, binormals, rays;


type
  trans_type = record
    origin, x_axis, y_axis, z_axis: vector_type;
  end; {trans_type}


var
  unit_trans: trans_type;
  null_trans: trans_type;


{*************}
{ constructor }
{*************}
function To_trans(origin, x_axis, y_axis, z_axis: vector_type): trans_type;

{*************}
{ conversions }
{*************}
function Vector_to_trans(origin, z_axis: vector_type): trans_type;

{*************}
{ comparisons }
{*************}
function Equal_trans(trans1, trans2: trans_type): boolean;

{*****************}
{ transformations }
{*****************}
procedure Transform_vector(var vector: vector_type;
  trans: trans_type);
procedure Transform_point(var point: vector_type;
  trans: trans_type);
procedure Transform_binormal(var binormal: binormal_type;
  trans: trans_type);
procedure Transform_ray(var ray: ray_type;
  trans: trans_type);
procedure Transform_trans(var trans: trans_type;
  source_trans: trans_type);

{************************************}
{ inverse and normal transformations }
{************************************}
function Inverse_trans(trans: trans_type): trans_type;
function Normal_trans(trans: trans_type): trans_type;

{*************}
{ diagnostics }
{*************}
procedure Write_trans(trans: trans_type);


implementation


const
  small = 1E-6;


{**************}
{ constructors }
{**************}


function To_trans(origin, x_axis, y_axis, z_axis: vector_type): trans_type;
var
  trans: trans_type;
begin
  trans.origin := origin;
  trans.x_axis := x_axis;
  trans.y_axis := y_axis;
  trans.z_axis := z_axis;
  To_trans := trans;
end; {function To_trans}


{*************}
{ conversions }
{*************}


function Vector_to_trans(origin, z_axis: vector_type): trans_type;
var
  trans: trans_type;
begin
  trans.origin := origin;

  if Equal_vector(z_axis, zero_vector) then
    begin
      trans.x_axis := x_vector;
      trans.y_axis := y_vector;
      trans.z_axis := Vector_scale(z_vector, small);
    end
  else
    begin
      trans.z_axis := z_axis;
      with trans do
        begin
          if (abs(z_axis.y) > small) or (abs(z_axis.z) > small) then
            {************************************}
            { z_axis is not parallel to x_vector }
            {************************************}
            x_axis := Normalize(Perpendicular(x_vector, z_axis))
          else
            {********************************}
            { z_axis is parallel to x_vector }
            {********************************}
            x_axis := Normalize(Perpendicular(y_vector, z_axis));

          y_axis := Normalize(Cross_product(z_axis, x_axis));
        end;
    end;
  Vector_to_trans := trans;
end; {function Vector_to_trans}


{*************}
{ comparisons }
{*************}


function Equal_trans(trans1, trans2: trans_type): boolean;
var
  temp: boolean;
begin
  temp := false;
  if Equal_vector(trans1.origin, trans2.origin) then
    if Equal_vector(trans1.x_axis, trans2.x_axis) then
      if Equal_vector(trans1.y_axis, trans2.y_axis) then
        if Equal_vector(trans1.z_axis, trans2.z_axis) then
          temp := true;
  Equal_trans := temp;
end; {function Equal_trans}


{*****************}
{ transformations }
{*****************}


procedure Transform_vector(var vector: vector_type;
  trans: trans_type);
var
  temp: vector_type;
begin
  {************************************************}
  { vector := Sum(Scale(trans.x_axis, vector.x),   }
  {           Sum(Scale(trans.y_axis, vector.y),   }
  {               Scale(trans.z_axis, vector.z))); }
  {************************************************}

  temp := zero_vector;

  {********}
  { x_axis }
  {********}
  temp.x := temp.x + trans.x_axis.x * vector.x;
  temp.y := temp.y + trans.x_axis.y * vector.x;
  temp.z := temp.z + trans.x_axis.z * vector.x;

  {********}
  { y_axis }
  {********}
  temp.x := temp.x + trans.y_axis.x * vector.y;
  temp.y := temp.y + trans.y_axis.y * vector.y;
  temp.z := temp.z + trans.y_axis.z * vector.y;

  {********}
  { z_axis }
  {********}
  temp.x := temp.x + trans.z_axis.x * vector.z;
  temp.y := temp.y + trans.z_axis.y * vector.z;
  temp.z := temp.z + trans.z_axis.z * vector.z;

  vector := temp;
end; {procedure Transform_vector}


procedure Transform_point(var point: vector_type;
  trans: trans_type);
var
  temp: vector_type;
begin
  {********************************************}
  { point := Sum(trans.origin,                 }
  {          Sum(Scale(trans.x_axis, point.x), }
  {          Sum(Scale(trans.y_axis, point.y) ,}
  {          Scale(trans.z_axis, point.z))));  }
  {********************************************}

  temp := trans.origin;

  {********}
  { x_axis }
  {********}
  temp.x := temp.x + trans.x_axis.x * point.x;
  temp.y := temp.y + trans.x_axis.y * point.x;
  temp.z := temp.z + trans.x_axis.z * point.x;

  {********}
  { y_axis }
  {********}
  temp.x := temp.x + trans.y_axis.x * point.y;
  temp.y := temp.y + trans.y_axis.y * point.y;
  temp.z := temp.z + trans.y_axis.z * point.y;

  {********}
  { z_axis }
  {********}
  temp.x := temp.x + trans.z_axis.x * point.z;
  temp.y := temp.y + trans.z_axis.y * point.z;
  temp.z := temp.z + trans.z_axis.z * point.z;

  point := temp;
end; {procedure Transform_point}


procedure Transform_binormal(var binormal: binormal_type;
  trans: trans_type);
begin
  Transform_vector(binormal.x_axis, trans);
  Transform_vector(binormal.y_axis, trans);
end; {procedure Transform_normal}


procedure Transform_ray(var ray: ray_type;
  trans: trans_type);
begin
  Transform_point(ray.location, trans);
  Transform_vector(ray.direction, trans);
end; {procedure Transform_ray}


procedure Transform_trans(var trans: trans_type;
  source_trans: trans_type);
begin
  Transform_point(trans.origin, source_trans);
  Transform_vector(trans.x_axis, source_trans);
  Transform_vector(trans.y_axis, source_trans);
  Transform_vector(trans.z_axis, source_trans);
end; {procedure Transform_trans}


{*************************}
{ inverse transformations }
{*************************}


procedure Check_trans(var trans: trans_type);
var
  null_x, null_y, null_z: boolean;
  binormal: binormal_type;
begin
  with trans do
    begin
      null_x := Dot_product(x_axis, x_axis) < small;
      null_y := Dot_product(y_axis, y_axis) < small;
      null_z := Dot_product(z_axis, z_axis) < small;

      if null_x and null_y and null_z then
        begin
          {***********************}
          { 3 way degenerate axes }
          {***********************}
          x_axis := To_vector(small, 0, 0);
          y_axis := To_vector(0, small, 0);
          z_axis := To_vector(0, 0, small);
        end
      else
        begin
          {***********************}
          { 2 way degenerate axes }
          {***********************}
          if (null_x and null_y) then
            begin
              binormal := Normal_to_binormal(z_axis);
              x_axis := Vector_scale(binormal.x_axis, small);
              y_axis := Vector_scale(binormal.y_axis, small);
            end
          else if (null_y and null_z) then
            begin
              binormal := Normal_to_binormal(x_axis);
              y_axis := Vector_scale(binormal.x_axis, small);
              z_axis := Vector_scale(binormal.y_axis, small);
            end
          else if (null_x and null_z) then
            begin
              binormal := Normal_to_binormal(y_axis);
              x_axis := Vector_scale(binormal.x_axis, small);
              z_axis := Vector_scale(binormal.y_axis, small);
            end
          else
            {***********************}
            { 1 way degenerate axes }
            if null_x then
              begin
                x_axis := Vector_scale(Cross_product(y_axis, z_axis), small);
              end
            else if null_y then
              begin
                y_axis := Vector_scale(Cross_product(x_axis, z_axis), small);
              end
            else if null_z then
              begin
                z_axis := Vector_scale(Cross_product(x_axis, y_axis), small);
              end;
        end;
    end; {with}
end; {procedure Check_trans}


function Inverse_trans(trans: trans_type): trans_type;
var
  inverse: trans_type;
  d: real;
  x_basis, y_basis, z_basis: vector_type;
  original_trans: trans_type;
  temp: vector_type;
begin
  original_trans := trans;

  if Null_vector(trans.x_axis) then
    trans.x_axis := Cross_product(trans.y_axis, trans.z_axis);
  if Null_vector(trans.y_axis) then
    trans.y_axis := Cross_product(trans.z_axis, trans.y_axis);
  if Null_vector(trans.z_axis) then
    trans.z_axis := Cross_product(trans.x_axis, trans.y_axis);

  {********************************}
  { compute inverse transformation }
  {********************************}
  x_basis := Cross_product(trans.y_axis, trans.z_axis);
  y_basis := Cross_product(trans.z_axis, trans.x_axis);
  z_basis := Cross_product(trans.x_axis, trans.y_axis);

  d := Determinant(trans.x_axis, trans.y_axis, trans.z_axis);
  if d <> 0 then
    begin
      d := 1 / d;
      x_basis := Vector_scale(x_basis, d);
      y_basis := Vector_scale(y_basis, d);
      z_basis := Vector_scale(z_basis, d);
    end;

  inverse.origin := Vector_reverse(trans.origin);
  temp.x := Dot_product(inverse.origin, x_basis);
  temp.y := Dot_product(inverse.origin, y_basis);
  temp.z := Dot_product(inverse.origin, z_basis);
  inverse.origin := temp;

  inverse.x_axis.x := x_basis.x;
  inverse.x_axis.y := y_basis.x;
  inverse.x_axis.z := z_basis.x;

  inverse.y_axis.x := x_basis.y;
  inverse.y_axis.y := y_basis.y;
  inverse.y_axis.z := z_basis.y;

  inverse.z_axis.x := x_basis.z;
  inverse.z_axis.y := y_basis.z;
  inverse.z_axis.z := z_basis.z;

  Inverse_trans := inverse;
end; {function Inverse_trans}


function Normal_trans(trans: trans_type): trans_type;
var
  x_normal, y_normal, z_normal: vector_type;
begin
  x_normal := Cross_product(trans.y_axis, trans.z_axis);
  y_normal := Cross_product(trans.z_axis, trans.x_axis);
  z_normal := Cross_product(trans.x_axis, trans.y_axis);

  if Null_vector(x_normal) then
    x_normal := trans.x_axis;
  if Null_vector(y_normal) then
    y_normal := trans.y_axis;
  if Null_vector(z_normal) then
    z_normal := trans.z_axis;

  trans.origin := zero_vector;
  trans.x_axis := x_normal;
  trans.y_axis := y_normal;
  trans.z_axis := z_normal;
  Normal_trans := trans;
end; {function Normal_trans}


{*************}
{ diagnostics }
{*************}


procedure Write_trans(trans: trans_type);
begin
  with trans do
    begin
      writeln('trans with');
      with origin do
        writeln('origin = ', x, y, z);
      with x_axis do
        writeln('x_axis = ', x, y, z);
      with y_axis do
        writeln('y_axis = ', x, y, z);
      with z_axis do
        writeln('z_axis = ', x, y, z);
    end;
end; {procedure Write_trans}


initialization
  unit_trans := To_trans(zero_vector, x_vector, y_vector, z_vector);
  null_trans := To_trans(zero_vector, zero_vector, zero_vector, zero_vector);
end.
