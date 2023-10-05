unit vectors;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              vectors                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module has the basic 3d vector declarations        }
{       and operations.                                         }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
type
  vector_type = record
    x, y, z: real;
  end; {vector_type}


var
  zero_vector, unit_vector, x_vector, y_vector, z_vector: vector_type;
  neg_unit_vector, neg_x_vector, neg_y_vector, neg_z_vector: vector_type;


{********************}
{ vector constructor }
{********************}
function To_vector(x, y, z: real): vector_type;

{********************}
{ vector comparisons }
{********************}
function Null_vector(vector: vector_type): boolean;
function Tiny_vector(vector: vector_type): boolean;
function Equal_vector(vector1, vector2: vector_type): boolean;
function Same_direction(vector1, vector2: vector_type): boolean;

{******************}
{ vector operators }
{******************}
function Vector_sum(vector1, vector2: vector_type): vector_type;
function Vector_difference(vector1, vector2: vector_type): vector_type;
function Vector_scale(vector: vector_type;
  scalar: real): vector_type;
function Vector_scale2(vector1, vector2: vector_type): vector_type;
function Vector_divide(vector1, vector2: vector_type): vector_type;
function Dot_product(vector1, vector2: vector_type): real;
function Cross_product(vector1, vector2: vector_type): vector_type;
function Vector_length(vector: vector_type): real;
function Normalize(vector: vector_type): vector_type;
function Parallel(vector1, vector2: vector_type): vector_type;
function Perpendicular(vector1, vector2: vector_type): vector_type;
function Determinant(vector1, vector2, vector3: vector_type): real;
function Vector_reverse(vector: vector_type): vector_type;
function Vector_towards(vector1, vector2: vector_type): vector_type;
function Vector_away(vector1, vector2: vector_type): vector_type;
function Vector_clamp(vector, min, max: vector_type): vector_type;
function Vector_snap(vector1, vector2: vector_type): vector_type;

{********************}
{ vector diagnostics }
{********************}
function Vector_ok(vector: vector_type): boolean;
procedure Write_vector(vector: vector_type);


implementation
uses
  constants;


{********************}
{ vector constructor }
{********************}


function To_vector(x, y, z: real): vector_type;
var
  vector: vector_type;
begin
  vector.x := x;
  vector.y := y;
  vector.z := z;
  To_vector := vector;
end; {function To_vector}


{********************}
{ vector comparisons }
{********************}


function Null_vector(vector: vector_type): boolean;
var
  null: boolean;
begin
  if (vector.x <> 0) then
    null := false
  else if (vector.y <> 0) then
    null := false
  else if (vector.z <> 0) then
    null := false
  else
    null := true;

  Null_vector := null;
end; {function Null_vector}


function Tiny_vector(vector: vector_type): boolean;
var
  is_tiny: boolean;
begin
  if (abs(vector.x) > tiny) then
    is_tiny := false
  else if (abs(vector.y) > tiny) then
    is_tiny := false
  else if (abs(vector.z) > tiny) then
    is_tiny := false
  else
    is_tiny := true;

  Tiny_vector := is_tiny;
end; {function Tiny_vector}


function Equal_vector(vector1, vector2: vector_type): boolean;
var
  equal: boolean;
begin
  if (vector1.x <> vector2.x) then
    equal := false
  else if (vector1.y <> vector2.y) then
    equal := false
  else if (vector1.z <> vector2.z) then
    equal := false
  else
    equal := true;

  Equal_vector := equal;
end; {function Equal_vector}


function Same_direction(vector1, vector2: vector_type): boolean;
begin
  {*******************************************}
  { returns whether vector1 and vector2 point }
  { in the same direction within 180 degrees  }
  {*******************************************}
  Same_direction := Dot_product(vector1, vector2) > 0;
end; {function Same_direction}


{******************}
{ vector operators }
{******************}


function Vector_sum(vector1, vector2: vector_type): vector_type;
begin
  vector1.x := vector1.x + vector2.x;
  vector1.y := vector1.y + vector2.y;
  vector1.z := vector1.z + vector2.z;
  Vector_sum := vector1;
end; {function Vector_sum}


function Vector_difference(vector1, vector2: vector_type): vector_type;
begin
  vector1.x := vector1.x - vector2.x;
  vector1.y := vector1.y - vector2.y;
  vector1.z := vector1.z - vector2.z;
  Vector_difference := vector1;
end; {function Vector_difference}


function Vector_scale(vector: vector_type;
  scalar: real): vector_type;
begin
  vector.x := vector.x * scalar;
  vector.y := vector.y * scalar;
  vector.z := vector.z * scalar;
  Vector_scale := vector;
end; {function Vector_scale}


function Vector_scale2(vector1, vector2: vector_type): vector_type;
begin
  vector1.x := vector1.x * vector2.x;
  vector1.y := vector1.y * vector2.y;
  vector1.z := vector1.z * vector2.z;
  Vector_scale2 := vector1;
end; {function Vector_scale2}


function Vector_divide(vector1, vector2: vector_type): vector_type;
begin
  vector1.x := vector1.x / vector2.x;
  vector1.y := vector1.y / vector2.y;
  vector1.z := vector1.z / vector2.z;
  Vector_divide := vector1;
end; {function Vector_divide}


function Dot_product(vector1, vector2: vector_type): real;
begin
  Dot_product := ((vector1.x * vector2.x) + (vector1.y * vector2.y) + (vector1.z
    * vector2.z));
end; {function Dot_product}


function Cross_product(vector1, vector2: vector_type): vector_type;
var
  vector: vector_type;
begin
  vector.x := (vector1.y * vector2.z) - (vector1.z * vector2.y);
  vector.y := (vector1.z * vector2.x) - (vector1.x * vector2.z);
  vector.z := (vector1.x * vector2.y) - (vector1.y * vector2.x);
  Cross_product := vector;
end; {function Cross_product}


function Vector_length(vector: vector_type): real;
begin
  with vector do
    Vector_length := sqrt((x * x) + (y * y) + (z * z));
end; {function Vector_length}


function Normalize(vector: vector_type): vector_type;
var
  factor, length: real;
begin
  {******************************************}
  { Return a vector in the same direction as }
  { the original vector but with length = 1  }
  {******************************************}
  with vector do
    begin
      factor := Dot_product(vector, vector);
      if (factor > 0) then
        begin
          length := sqrt(factor);
          x := x / length;
          y := y / length;
          z := z / length;
        end
      else
        vector := z_vector;
    end;
  Normalize := vector;
end; {function Normalize}


function Parallel(vector1, vector2: vector_type): vector_type;
var
  denominator: real;
begin
  {*********************************}
  { Return the component of vector1 }
  { that is parallel to vector2     }
  {*********************************}
  denominator := Dot_product(vector2, vector2);
  if denominator > tiny then
    Parallel := Vector_scale(vector2, Dot_product(vector1, vector2) /
      denominator)
  else
    Parallel := vector1;
end; {function Parallel}


function Perpendicular(vector1, vector2: vector_type): vector_type;
begin
  {**********************************}
  { Return the component of vector1  }
  { that is perpendicular to vector2 }
  {**********************************}
  Perpendicular := Vector_difference(vector1, Parallel(vector1, vector2));
end; {function Perpendicular}


function Determinant(vector1, vector2, vector3: vector_type): real;
var
  x_components, y_components, z_components: vector_type;
begin
  with x_components do
    begin
      x := vector1.x;
      y := vector2.x;
      z := vector3.x;
    end;
  with y_components do
    begin
      x := vector1.y;
      y := vector2.y;
      z := vector3.y;
    end;
  with z_components do
    begin
      x := vector1.z;
      y := vector2.z;
      z := vector3.z;
    end;
  Determinant := Dot_product(x_components, Cross_product(y_components,
    z_components));
end; {function Determinant}


function Vector_reverse(vector: vector_type): vector_type;
begin
  vector.x := -vector.x;
  vector.y := -vector.y;
  vector.z := -vector.z;
  Vector_reverse := vector;
end; {function Vector_reverse}


function Vector_towards(vector1, vector2: vector_type): vector_type;
begin
  {********************************************}
  { if vector1 points in the same direction as }
  { vector2 within 180 degrees, then we return }
  { vector1, otherwise return reverse vector1  }
  {********************************************}
  if Dot_product(vector1, vector2) < 0 then
    begin
      vector1.x := -vector1.x;
      vector1.y := -vector1.y;
      vector1.z := -vector1.z;
    end;
  Vector_towards := vector1;
end; {function Vector_towards}


function Vector_away(vector1, vector2: vector_type): vector_type;
begin
  {********************************************}
  { if vector1 points in the same direction as }
  { vector2 within 180 degrees, then we return }
  { reverse vector1, otherwise return vector1  }
  {********************************************}
  if Dot_product(vector1, vector2) > 0 then
    begin
      vector1.x := -vector1.x;
      vector1.y := -vector1.y;
      vector1.z := -vector1.z;
    end;
  Vector_away := vector1;
end; {function Vector_away}


function Snap(x, y: double): double;
begin
  Snap := Round(x / y) * y;
end; {function Snap}


function Clamp(x, min, max: double): double;
begin
  if (x < min) then
    x := min;
  if (x > max) then
    x := max;
  Clamp := x;
end; {function Clamp}


function Vector_clamp(vector, min, max: vector_type): vector_type;
begin
  vector.x := Clamp(vector.x, min.x, max.x);
  vector.y := Clamp(vector.y, min.y, max.y);
  vector.z := Clamp(vector.z, min.z, max.z);
  Vector_clamp := vector;
end; {function Vector_clamp}


function Vector_snap(vector1, vector2: vector_type): vector_type;
begin
  vector1.x := Snap(vector1.x, vector2.x);
  vector1.y := Snap(vector1.y, vector2.y);
  vector1.z := Snap(vector1.z, vector2.z);
  Vector_snap := vector1;
end; {function Vector_snap}


{********************}
{ vector diagnostics }
{********************}


function Vector_ok(vector: vector_type): boolean;
var
  ok: boolean;
begin
  ok := true;
  with vector do
    if not ((x >= 0) or (x < 0)) then
      ok := false
    else
      begin
        if not ((y >= 0) or (y < 0)) then
          ok := false
        else
          begin
            if not ((z >= 0) or (z < 0)) then
              ok := false
          end;
      end;
  Vector_ok := ok;
end; {function Vector_ok}


procedure Write_vector(vector: vector_type);
begin
  write(vector.x: 4: 4, ' ');
  write(vector.y: 4: 4, ' ');
  write(vector.z: 4: 4);
end; {procedure Write_vector}


initialization
  zero_vector := To_vector(0, 0, 0);
  unit_vector := To_vector(1, 1, 1);

  x_vector := To_vector(1, 0, 0);
  y_vector := To_vector(0, 1, 0);
  z_vector := To_vector(0, 0, 1);

  neg_unit_vector := To_vector(-1, -1, -1);
  neg_x_vector := To_vector(-1, 0, 0);
  neg_y_vector := To_vector(0, -1, 0);
  neg_z_vector := To_vector(0, 0, -1);
end.
