unit binormals;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             binormals                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The normals module provides data structs for            }
{       describing normals in 3 dimensional space.              }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  vectors;


type
  {*********************************************}
  { two vectors are needed to define the normal }
  { because normals do not transform from one   }
  { coordinate frame to another like vectors.   }
  {*********************************************}
  binormal_type = record
    x_axis, y_axis: vector_type;
  end; {binormal_type}


  {**************}
  { constructors }
  {**************}
function To_binormal(x_axis, y_axis: vector_type): binormal_type;

{*************}
{ conversions }
{*************}
function Normal_to_binormal(normal: vector_type): binormal_type;
function Binormal_to_normal(binormal: binormal_type): vector_type;

{*************}
{ comparisons }
{*************}
function Same_binormal(binormal1, binormal2: binormal_type): boolean;
function Equal_binormal(binormal1, binormal2: binormal_type): boolean;


implementation
uses
  constants;


{**************}
{ constructors }
{**************}


function To_binormal(x_axis, y_axis: vector_type): binormal_type;
var
  binormal: binormal_type;
begin
  binormal.x_axis := x_axis;
  binormal.y_axis := y_axis;
  To_binormal := binormal;
end; {function To_binormal}


{*************}
{ conversions }
{*************}


function Normal_to_binormal(normal: vector_type): binormal_type;
var
  binormal: binormal_type;
begin
  {************************************}
  { vector is not parallel to x_vector }
  {************************************}
  if (abs(normal.y) > tiny) or (abs(normal.z) > tiny) then
    binormal.x_axis := Perpendicular(x_vector, normal)

    {********************************}
    { vector is parallel to x_vector }
    {********************************}
  else if (abs(normal.x) > tiny) then
    binormal.x_axis := Perpendicular(y_vector, normal)

    {*************}
    { zero vector }
    {*************}
  else
    binormal.x_axis := x_vector;

  binormal.y_axis := Cross_product(binormal.x_axis, normal);

  Normal_to_binormal := binormal;
end; {function Normal_to_binormal}


function Binormal_to_normal(binormal: binormal_type): vector_type;
begin
  Binormal_to_normal := Normalize(Cross_product(binormal.x_axis,
    binormal.y_axis));
end; {function Binormal_to_normal}


{*************}
{ comparisons }
{*************}


function Same_binormal(binormal1, binormal2: binormal_type): boolean;
var
  same: boolean;
begin
  if not Equal_vector(binormal1.x_axis, binormal2.x_axis) then
    same := false
  else if not Equal_vector(binormal1.y_axis, binormal2.y_axis) then
    same := false
  else
    same := true;

  Same_binormal := same;
end; {function Same_binormal}


function Equal_binormal(binormal1, binormal2: binormal_type): boolean;
var
  normal1, normal2: vector_type;
begin
  normal1 := Binormal_to_normal(binormal1);
  normal2 := Binormal_to_normal(binormal2);
  Equal_binormal := Equal_vector(normal1, normal2);
end; {function Equal_binormal}


end.
