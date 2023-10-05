unit uv_mapping;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             uv_mapping                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module provides support for texture mapping        }
{       operations.                                             }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, raytrace;


function Find_uv_mapping(object_ptr: ray_object_inst_ptr_type;
  local_point: vector_type): vector_type;


implementation
uses
  constants, trigonometry, objects;


function Longitude(point: vector_type): real;
begin
  with point do
    Longitude := Atan2(y, x) * radians_to_degrees;
end; {function Longitude}


function Lattitude(point: vector_type): real;
begin
  with point do
    Lattitude := arctan(z / sqrt(x * x + y * y)) * radians_to_degrees;
end; {function Lattitude}


function Find_uv_mapping(object_ptr: ray_object_inst_ptr_type;
  local_point: vector_type): vector_type;
var
  mapping: vector_type;
  x, y, z, e, r: real;
begin
  with object_ptr^ do
    case kind of

      {********************}
      { quadric primitives }
      {********************}

      sphere:
        begin
          mapping.x := (Longitude(local_point) - umin) / (umax - umin);
          mapping.y := (Lattitude(local_point) - vmin) / (vmax - vmin);
          mapping.z := 1;
        end;

      cylinder:
        begin
          mapping.x := (Longitude(local_point) - umin) / (umax - umin);
          mapping.y := (local_point.z + 1) / 2;
          mapping.z := 1;
        end;

      cone:
        begin
          mapping.x := (Longitude(local_point) - umin) / (umax - umin);
          mapping.y := (local_point.z + 1) / 2;
          mapping.z := 1;
        end;

      paraboloid:
        begin
          mapping.x := (Longitude(local_point) - umin) / (umax - umin);
          mapping.y := 1 - sqrt(1 - ((local_point.z + 1) / 2));
          mapping.z := 1;
        end;

      hyperboloid1:
        begin
          mapping.x := (Longitude(local_point) - umin) / (umax - umin);
          mapping.y := (local_point.z + 1) / 2;
          mapping.z := 1;
        end;

      hyperboloid2:
        begin
          mapping.x := (Longitude(local_point) - umin) / (umax - umin);
          z := local_point.z;
          e := eccentricity;
          r := sqrt((sqr(((1 - z) / 2) + e) - sqr(e)) / ((2 * e) + 1));
          mapping.y := (1 - r);
          mapping.z := 1;
        end;

      {*******************}
      { planar primitives }
      {*******************}

      plane:
        begin
          mapping.x := local_point.x - Trunc(local_point.x);
          if (mapping.x < 0) then
            mapping.x := mapping.x + 1;
          mapping.y := local_point.y - Trunc(local_point.y);
          if (mapping.y < 0) then
            mapping.y := mapping.y + 1;
          mapping.z := 1;
        end;

      disk:
        begin
          mapping.x := (Longitude(local_point) - umin) / (umax - umin);
          r := sqrt(sqr(local_point.x) + sqr(local_point.y));
          mapping.y := (1 - r);
          mapping.z := 1;
        end;

      ring:
        begin
          mapping.x := (Longitude(local_point) - umin) / (umax - umin);
          r := sqrt(sqr(local_point.x) + sqr(local_point.y));
          mapping.y := 1 - (r - inner_radius) / (1 - inner_radius);
          mapping.z := 1;
        end;

      triangle:
        begin
          mapping.x := (local_point.x + 1) / 2;
          mapping.y := (local_point.y + 1) / 2;
          mapping.z := 1;
        end;

      parallelogram:
        begin
          mapping.x := (local_point.x + 1) / 2;
          mapping.y := (local_point.y + 1) / 2;
          mapping.z := 1;
        end;

      flat_polygon:
        begin
          mapping := Interpolate(ray_mesh_data_ptr^.texture_interpolation);
        end;

      {***********************}
      { non-planar primitives }
      {***********************}

      torus:
        begin
          mapping.x := (Longitude(local_point) - umin) / (umax - umin);
          y := local_point.z * inner_radius;
          r := sqrt(sqr(local_point.x) + sqr(local_point.y));
          x := r - (1 - inner_radius);
          local_point.x := x;
          local_point.y := y;
          mapping.y := (Longitude(local_point) - vmin) / (vmax - vmin);
          mapping.z := 1;
        end;

      block:
        begin
          if abs(local_point.x) > abs(local_point.z) then
            begin
              {********}
              { x or y }
              {********}
              if abs(local_point.x) > abs(local_point.y) then
                begin
                  if (local_point.x > 0) then
                    begin
                      {************}
                      { right face }
                      {************}
                      mapping.x := (local_point.y + 1) / 2;
                      mapping.y := (local_point.z + 1) / 2;
                    end
                  else
                    begin
                      {***********}
                      { left face }
                      {***********}
                      mapping.x := (1 - local_point.y) / 2;
                      mapping.y := (local_point.z + 1) / 2;
                    end;
                end
              else
                begin
                  if (local_point.y > 0) then
                    begin
                      {***********}
                      { back face }
                      {***********}
                      mapping.x := (1 - local_point.x) / 2;
                      mapping.y := (local_point.z + 1) / 2;
                    end
                  else
                    begin
                      {************}
                      { front face }
                      {************}
                      mapping.x := (local_point.x + 1) / 2;
                      mapping.y := (local_point.z + 1) / 2;
                    end;
                end;
            end
          else
            begin
              {********}
              { y or z }
              {********}
              if abs(local_point.y) > abs(local_point.z) then
                begin
                  if (local_point.y > 0) then
                    begin
                      {***********}
                      { back face }
                      {***********}
                      mapping.x := (1 - local_point.x) / 2;
                      mapping.y := (local_point.z + 1) / 2;
                    end
                  else
                    begin
                      {************}
                      { front face }
                      {************}
                      mapping.x := (local_point.x + 1) / 2;
                      mapping.y := (local_point.z + 1) / 2;
                    end;
                end
              else
                begin
                  if (local_point.z > 0) then
                    begin
                      {**********}
                      { top face }
                      {**********}
                      mapping.x := (local_point.x + 1) / 2;
                      mapping.y := (local_point.y + 1) / 2;
                    end
                  else
                    begin
                      {*************}
                      { bottom face }
                      {*************}
                      mapping.x := (1 - local_point.x) / 2;
                      mapping.y := (1 - local_point.y) / 2;
                    end;
                end;
            end;
          mapping.z := 1;
        end;

      shaded_triangle:
        begin
          mapping.x := (local_point.x + 1) / 2;
          mapping.y := (local_point.y + 1) / 2;
          mapping.z := 1;
        end;

      shaded_polygon:
        begin
          mapping := Interpolate(ray_mesh_data_ptr^.texture_interpolation);
        end;

      mesh:
        begin
          mapping := Interpolate(ray_mesh_data_ptr^.texture_interpolation);
        end;

      blob:
        begin
          mapping := local_point;
        end;

      {************************}
      { non-surface primitives }
      {************************}
      points, lines:
        ;

      volume:
        begin
          mapping := Interpolate(ray_mesh_data_ptr^.texture_interpolation);
        end;

      {*********************}
      { clipping primitives }
      {*********************}
      clipping_plane:
        begin
          mapping.x := local_point.x - Trunc(local_point.x);
          if (mapping.x < 0) then
            mapping.x := mapping.x + 1;
          mapping.y := local_point.y - Trunc(local_point.y);
          if (mapping.y < 0) then
            mapping.y := mapping.y + 1;
          mapping.z := 1;
        end;

      {*********************}
      { lighting primitives }
      {*********************}
      distant_light, point_light, spot_light:
        ;

      complex_object:
        ;

    end;

  Find_uv_mapping := mapping;
end; {procedure Find_uv_mapping}


end.
