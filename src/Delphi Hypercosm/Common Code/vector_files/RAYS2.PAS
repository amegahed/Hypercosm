unit rays2;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               rays2                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The rays module provides data structs and routines      }
{       for describing 2 dimensional rays.                      }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  vectors2;


type
  ray2_type = record
    location, direction: vector2_type;
  end; {ray2_type}


  {**************}
  { constructors }
  {**************}
function To_ray2(location, direction: vector2_type): ray2_type;

{*************}
{ comparisons }
{*************}
function Equal_rays2(ray1, ray2: ray2_type): boolean;


implementation


{**************}
{ constructors }
{**************}


function To_ray2(location, direction: vector2_type): ray2_type;
var
  ray: ray2_type;
begin
  ray.location := location;
  ray.direction := direction;
  To_ray2 := ray;
end; {function To_ray2}


{*************}
{ comparisons }
{*************}


function Equal_rays2(ray1, ray2: ray2_type): boolean;
var
  equal: boolean;
begin
  if not Equal_vector2(ray1.location, ray2.location) then
    equal := false
  else if not Equal_vector2(ray1.direction, ray2.direction) then
    equal := false
  else
    equal := true;

  Equal_rays2 := equal;
end; {function Equal_rays2}


end.
