unit vectors2;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              vectors2                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module has the basic 2d vector declarations        }
{       and operations.                                         }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
type
  vector2_type = record
    x, y: real;
  end; {vector2_type}


var
  zero_vector2, unit_vector2, x_vector2, y_vector2: vector2_type;


{********************}
{ vector constructor }
{********************}
function To_vector2(x, y: real): vector2_type;

{********************}
{ vector comparisons }
{********************}
function Null_vector2(vector: vector2_type): boolean;
function Tiny_vector2(vector: vector2_type): boolean;
function Equal_vector2(vector1, vector2: vector2_type): boolean;
function Same_direction2(vector1, vector2: vector2_type): boolean;

{******************}
{ vector operators }
{******************}
function Vector2_sum(vector1, vector2: vector2_type): vector2_type;
function Vector2_difference(vector1, vector2: vector2_type): vector2_type;
function Vector2_scale(vector: vector2_type;
  scalar: real): vector2_type;
function Vector2_scale2(vector1, vector2: vector2_type): vector2_type;
function Dot_product2(vector1, vector2: vector2_type): real;
function Cross_product2(vector1, vector2: vector2_type): real;
function Vector2_length(vector: vector2_type): real;
function Normalize2(vector: vector2_type): vector2_type;
function Parallel2(vector1, vector2: vector2_type): vector2_type;
function Perpendicular2(vector1, vector2: vector2_type): vector2_type;
function Self_perpendicular2(vector: vector2_type): vector2_type;
function Determinant2(vector1, vector2: vector2_type): real;
function Vector2_reverse(vector: vector2_type): vector2_type;
function Vector2_towards(vector1, vector2: vector2_type): vector2_type;
function Vector2_away(vector1, vector2: vector2_type): vector2_type;

{********************}
{ vector diagnostics }
{********************}
function Vector2_ok(vector: vector2_type): boolean;
procedure Write_vector2(vector: vector2_type);


implementation
uses
  constants;


{********************}
{ vector constructor }
{********************}


function To_vector2(x, y: real): vector2_type;
var
  vector: vector2_type;
begin
  vector.x := x;
  vector.y := y;
  To_vector2 := vector;
end; {function To_vector2}


{********************}
{ vector comparisons }
{********************}


function Null_vector2(vector: vector2_type): boolean;
var
  null: boolean;
begin
  if (vector.x <> 0) then
    null := false
  else if (vector.y <> 0) then
    null := false
  else
    null := true;

  Null_vector2 := null;
end; {function Null_vector2}


function Tiny_vector2(vector: vector2_type): boolean;
var
  is_tiny: boolean;
begin
  if (abs(vector.x) > tiny) then
    is_tiny := false
  else if (abs(vector.y) > tiny) then
    is_tiny := false
  else
    is_tiny := true;

  Tiny_vector2 := is_tiny;
end; {function Tiny_vector2}


function Equal_vector2(vector1, vector2: vector2_type): boolean;
var
  equal: boolean;
begin
  if (vector1.x <> vector2.x) then
    equal := false
  else if (vector1.y <> vector2.y) then
    equal := false
  else
    equal := true;

  Equal_vector2 := equal;
end; {function Equal_vector2}


function Same_direction2(vector1, vector2: vector2_type): boolean;
begin
  {*******************************************}
  { returns whether vector1 and vector2 point }
  { in the same direction within 180 degrees  }
  {*******************************************}
  Same_direction2 := Dot_product2(vector1, vector2) > 0;
end; {function Same_direction2}


{******************}
{ vector operators }
{******************}


function Vector2_sum(vector1, vector2: vector2_type): vector2_type;
begin
  vector1.x := vector1.x + vector2.x;
  vector1.y := vector1.y + vector2.y;
  Vector2_sum := vector1;
end; {function Vector2_sum}


function Vector2_difference(vector1, vector2: vector2_type): vector2_type;
begin
  vector1.x := vector1.x - vector2.x;
  vector1.y := vector1.y - vector2.y;
  Vector2_difference := vector1;
end; {function Vector2_difference}


function Vector2_scale(vector: vector2_type;
  scalar: real): vector2_type;
begin
  vector.x := vector.x * scalar;
  vector.y := vector.y * scalar;
  Vector2_scale := vector;
end; {function Vector2_scale}


function Vector2_scale2(vector1, vector2: vector2_type): vector2_type;
begin
  vector1.x := vector1.x * vector2.x;
  vector1.y := vector1.y * vector2.y;
  Vector2_scale2 := vector1;
end; {function Vector2_scale2}


function Dot_product2(vector1, vector2: vector2_type): real;
begin
  Dot_product2 := (vector1.x * vector2.x) + (vector1.y * vector2.y);
end; {function Dot_product2}


function Cross_product2(vector1, vector2: vector2_type): real;
begin
  Cross_product2 := (vector1.x * vector2.y) - (vector1.y * vector2.x);
end; {function Cross_product2}


function Vector2_length(vector: vector2_type): real;
begin
  with vector do
    Vector2_length := sqrt(x * x + y * y);
end; {function Vector2_length}


function Normalize2(vector: vector2_type): vector2_type;
var
  length: real;
begin
  with vector do
    begin
      length := sqrt(x * x + y * y);
      x := x / length;
      y := y / length;
    end;
  Normalize2 := vector;
end; {function Normalize2}


function Parallel2(vector1, vector2: vector2_type): vector2_type;
begin
  {*********************************}
  { Return the component of vector1 }
  { that is parallel to vector2     }
  {*********************************}
  Parallel2 := Vector2_scale(vector2, Dot_product2(vector1, vector2) /
    Dot_product2(vector2, vector2));
end; {function Parallel2}


function Perpendicular2(vector1, vector2: vector2_type): vector2_type;
begin
  {**********************************}
  { Return the component of vector1  }
  { that is perpendicular to vector2 }
  {**********************************}
  Perpendicular2 := Vector2_difference(vector1, Parallel2(vector1, vector2));
end; {function Perpendicular2}


function Self_perpendicular2(vector: vector2_type): vector2_type;
var
  temp: vector2_type;
begin
  temp.x := vector.y;
  temp.y := -vector.x;
  Self_perpendicular2 := temp;
end; {function Self_perpendicular2}


function Determinant2(vector1, vector2: vector2_type): real;
begin
  Determinant2 := vector1.x * vector2.y - vector1.y * vector2.x;
end; {function Determinant2}


function Vector2_reverse(vector: vector2_type): vector2_type;
begin
  vector.x := -vector.x;
  vector.y := -vector.y;
  Vector2_reverse := vector;
end; {function Vector2_reverse}


function Vector2_towards(vector1, vector2: vector2_type): vector2_type;
begin
  {********************************************}
  { if vector1 points in the same direction as }
  { vector2 within 180 degrees, then we return }
  { vector1, otherwise return reverse vector1  }
  {********************************************}
  if Dot_product2(vector1, vector2) < 0 then
    begin
      vector1.x := -vector1.x;
      vector1.y := -vector1.y;
    end;
  Vector2_towards := vector1;
end; {function Vector2_towards}


function Vector2_away(vector1, vector2: vector2_type): vector2_type;
begin
  {********************************************}
  { if vector1 points in the same direction as }
  { vector2 within 180 degrees, then we return }
  { reverse vector1, otherwise return vector1  }
  {********************************************}
  if Dot_product2(vector1, vector2) > 0 then
    begin
      vector1.x := -vector1.x;
      vector1.y := -vector1.y;
    end;
  Vector2_away := vector1;
end; {function Vector2_away}


{********************}
{ vector diagnostics }
{********************}


function Vector2_ok(vector: vector2_type): boolean;
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
      end;
  Vector2_ok := ok;
end; {function Vector2_ok}


procedure Write_vector2(vector: vector2_type);
begin
  write(vector.x: 4);
  write(vector.y: 4);
end; {procedure Write_vector2}


initialization
  zero_vector2 := To_vector2(0, 0);
  unit_vector2 := To_vector2(1, 1);

  x_vector2 := To_vector2(1, 0);
  y_vector2 := To_vector2(0, 1);
end.
