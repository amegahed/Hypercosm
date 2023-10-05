unit rays;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               rays                    3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The rays module provides data structs and routines      }
{       for describing 3 dimensional rays.                      }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  vectors;


type
  ray_type = record
    location, direction: vector_type;
  end; {ray_type}


  {**************}
  { constructors }
  {**************}
function To_ray(location, direction: vector_type): ray_type;

{*************}
{ comparisons }
{*************}
function Equal_rays(ray1, ray2: ray_type): boolean;


implementation


{**************}
{ constructors }
{**************}


function To_ray(location, direction: vector_type): ray_type;
var
  ray: ray_type;
begin
  ray.location := location;
  ray.direction := direction;
  To_ray := ray;
end; {function To_ray}


{*************}
{ comparisons }
{*************}


function Equal_rays(ray1, ray2: ray_type): boolean;
var
  equal: boolean;
begin
  if not Equal_vector(ray1.location, ray2.location) then
    equal := false
  else if not Equal_vector(ray1.direction, ray2.direction) then
    equal := false
  else
    equal := true;

  Equal_rays := equal;
end; {function Equal_rays}


end.
