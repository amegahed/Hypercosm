unit physics;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              physics                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The physics module is used to compute the simulation    }
{       of various physical processes pertaining to the         }
{       behaivior of light rays.                                }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, colors;


var
  ray_inside: boolean;


function Reflect(direction: vector_type;
  normal: vector_type): vector_type;
function Refract(direction: vector_type;
  normal: vector_type;
  index_of_refraction: real): vector_type;
function Fresnel_reflectance(normal_reflectance: real;
  angle: real): real;
function Fog(color, fog_color: color_type;
  distance, fog_factor: real): color_type;


implementation
uses
  math, trigonometry;


function Reflect(direction: vector_type;
  normal: vector_type): vector_type;
var
  parallel_component: vector_type;
begin
  {*******************************************}
  { In reflection, the component of the light }
  { ray parallel to the normal reverses its   }
  { direction -  other component in unchanged }
  {*******************************************}
  parallel_component := Parallel(direction, normal);
  Reflect := Vector_sum(direction, Vector_scale(parallel_component, -2));
end; {function Reflect}


function Refract(direction: vector_type;
  normal: vector_type;
  index_of_refraction: real): vector_type;
var
  parallel_component, perpendicular_component: vector_type;
  length_of_parallel, length_of_perpendicular, scalar: real;
begin
  if index_of_refraction <> 1 then
    begin
      direction := Normalize(direction);

      {*******************************************}
      { component of ray perpendicular to surface }
      {*******************************************}
      length_of_perpendicular := Dot_product(direction, normal);
      perpendicular_component := Vector_scale(normal, length_of_perpendicular);
      length_of_perpendicular := abs(length_of_perpendicular);

      {**************************************}
      { component of ray parallel to surface }
      {**************************************}
      parallel_component := Vector_difference(direction,
        perpendicular_component);
      length_of_parallel := Vector_length(parallel_component);

      if (length_of_parallel = 0) then
        {*************************************************}
        { ray is perpendicular to surface - not refracted }
        {*************************************************}
        ray_inside := not (ray_inside)
      else
        begin
          if ray_inside then
            scalar := index_of_refraction * length_of_parallel
          else
            scalar := length_of_parallel / index_of_refraction;

          if (scalar >= 1) then
            begin
              {***************************}
              { total internal reflection }
              {***************************}
              direction := Reflect(direction, normal)
            end
          else
            begin
              {******************************}
              { no total internal reflection }
              {******************************}
              scalar := scalar / sqrt(1 - scalar * scalar);
              scalar := scalar * length_of_perpendicular / length_of_parallel;
              direction := Vector_sum(perpendicular_component,
                Vector_scale(parallel_component, scalar));
              ray_inside := not (ray_inside);
            end;
        end;
    end;

  Refract := direction;
end; {function Refract}


function Fresnel_reflectance(normal_reflectance: real;
  angle: real {angle of incidence}
  ): real;
var
  index_of_refraction: real;
  theta: real;
begin
  normal_reflectance := 0.99 * normal_reflectance;
  index_of_refraction := (1 + sqrt(normal_reflectance)) / (1 -
    sqrt(normal_reflectance));
  theta := Asin(sin(angle) / index_of_refraction);
  Fresnel_reflectance := ((sqr(sin(angle - theta)) / sqr(sin(angle + theta))) +
    (sqr(tan(angle - theta)) / sqr(tan(angle + theta)))) / 2.0;
end; {function Fresnel_reflectance}


function Fog(color, fog_color: color_type;
  distance, fog_factor: real): color_type;
var
  saturation: real;
begin
  if (fog_factor <> 0) then
    begin {apply fog}
      saturation := 1 / exp(distance / fog_factor); {exponential decay}
      color := Mix_color(Intensify_color(color, saturation),
        Intensify_color(fog_color, 1 - saturation));
    end;
  Fog := color;
end; {function Fog}


end.
