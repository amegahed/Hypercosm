unit roots;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               roots                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module has routines for finding the roots of       }
{       polynomial equations.                                   }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface


type
  {*************************************}
  {             quadric roots:          }
  {          ax^2 + bx + c  = 0         }
  {*************************************}
  quadric_coeff_type = array[0..2] of double;
  quadric_root_type = array[0..1] of double;

  {*************************************}
  {             cubic roots:            }
  {      ax^3 + bx^2 + cx + d = 0       }
  {*************************************}
  cubic_coeff_type = array[0..3] of double;
  cubic_root_type = array[0..2] of double;

  {*************************************}
  {            quartic roots:           }
  {   ax^4 + bx^3 + cx^3 + dx + e = 0   }
  {*************************************}
  quartic_coeff_type = array[0..4] of double;
  quartic_root_type = array[0..3] of double;


  {************************}
  { root finding functions }
  {************************}
function Quadric_roots(coeff: quadric_coeff_type;
  var root: quadric_root_type): integer;
function Cubic_roots(coeff: cubic_coeff_type;
  var root: cubic_root_type): integer;
function Quartic_roots(coeff: quartic_coeff_type;
  var root: quartic_root_type): integer;


implementation
uses
  trigonometry, math_utils;


const
  epsilon = 1E-10;


function Quadric_roots(coeff: quadric_coeff_type;
  var root: quadric_root_type): integer;
var
  p, q, discriminant: double;
  roots: integer;
begin
  {***********************************************}
  { convert to normalized form: x^2 + p*x + q = 0 }
  {***********************************************}
  p := coeff[1] / (2.0 * coeff[2]);
  q := coeff[0] / coeff[2];
  discriminant := sqr(p) - q;

  if (abs(discriminant) < epsilon) then
    begin
      {*********************}
      { number of roots = 1 }
      {*********************}
      root[0] := -p;
      roots := 1;
    end
  else if (discriminant > 0) then
    begin
      {*********************}
      { number of roots = 2 }
      {*********************}
      discriminant := sqrt(discriminant);
      root[0] := discriminant - p;
      root[1] := -discriminant - p;
      roots := 2;
    end
  else
    roots := 0;

  Quadric_roots := roots;
end; {function Quadric_roots}


function Cubic_roots(coeff: cubic_coeff_type;
  var root: cubic_root_type): integer;
var
  a, b, c: double;
  a_squared, p, q: double;
  p_cubed, discriminant: double;
  phi, t, u, v: double;
  roots, counter: integer;
begin
  {*******************************************************}
  { convert to normalized form: x^3 + a*x^2 + b*x + c = 0 }
  {*******************************************************}
  a := coeff[2] / coeff[3];
  b := coeff[1] / coeff[3];
  c := coeff[0] / coeff[3];

  {******************************************************}
  { substitute x = y - a / 3 to eliminate quadric term   }
  { and convert equation to this form: x^3 + p*x + q = 0 }
  {******************************************************}
  a_squared := a * a;
  p := 1.0 / 3.0 * (-1.0 / 3.0 * a_squared + b);
  q := 1.0 / 2.0 * (2.0 / 27.0 * a * a_squared - 1.0 / 3.0 * a * b + c);

  {*******************}
  { Cardano's formula }
  {*******************}
  p_cubed := p * p * p;
  discriminant := q * q + p_cubed;

  if (abs(discriminant) < epsilon) then
    begin
      if (abs(q) < epsilon) then
        begin
          {********************}
          { single triple root }
          {********************}
          root[0] := 0;
          roots := 1;
        end
      else
        begin
          {********************************}
          { one single and one double root }
          {********************************}
          u := Cube_root(-q);
          root[0] := 2 * u;
          root[1] := -u;
          roots := 2;
        end
    end
  else if (discriminant < 0) then
    begin
      {*************}
      { three roots }
      {*************}
      phi := 1.0 / 3.0 * Acos(-q / sqrt(-p_cubed));
      t := 2.0 * sqrt(-p);
      root[0] := t * cos(phi);
      root[1] := -t * cos(phi + pi / 3.0);
      root[2] := -t * cos(phi - pi / 3.0);
      roots := 3;
    end
  else
    begin
      {**********}
      { one root }
      {**********}
      discriminant := sqrt(discriminant);
      u := Cube_root(discriminant - q);
      v := -Cube_root(discriminant + q);
      root[0] := u + v;
      roots := 1;
    end;

  if (roots <> 0) then
    begin
      {**************}
      { resubstitute }
      {**************}
      u := 1.0 / 3.0 * a;
      for counter := 0 to roots - 1 do
        root[counter] := root[counter] - u;
    end;

  Cubic_roots := roots;
end; {function Cubic_roots}


function Quartic_roots(coeff: quartic_coeff_type;
  var root: quartic_root_type): integer;
var
  a, b, c, d, a_squared: double;
  p, q, r: double;
  quadric_coeff: quadric_coeff_type;
  quadric_root: quadric_root_type;
  cubic_coeff: cubic_coeff_type;
  cubic_root: cubic_root_type;
  u, v, z, temp: double;
  roots, counter: integer;
begin
  {***************************************************************}
  { convert to normalized form: x^4 + a*x^3 + b*x^2 + c*x + d = 0 }
  {***************************************************************}
  a := coeff[3] / coeff[4];
  b := coeff[2] / coeff[4];
  c := coeff[1] / coeff[4];
  d := coeff[0] / coeff[4];

  {**********************************************************}
  { substitute x = y - a / 4 to eliminate the cubic term and }
  { convert equation to this form: x^4 + p*x^2 + q*x + r = 0 }
  {**********************************************************}
  a_squared := a * a;
  p := -3.0 / 8.0 * a_squared + b;
  q := 1.0 / 8.0 * a_squared * a - 1.0 / 2.0 * a * b + c;
  r := -3.0 / 256.0 * a_squared * a_squared + 1.0 / 16.0 * a_squared * b - 1.0 /
    4.0 * a * c + d;

  if (abs(r) < epsilon) then
    begin
      {****************************************}
      { no absolute term: y(y^3 + p*y + q) = 0 }
      {****************************************}
      cubic_coeff[0] := q;
      cubic_coeff[1] := p;
      cubic_coeff[2] := 0;
      cubic_coeff[3] := 1;
      roots := Cubic_roots(cubic_coeff, cubic_root);
      root[0] := cubic_root[0];
      root[1] := cubic_root[1];
      root[2] := cubic_root[2];
      root[roots] := 0;
      roots := roots + 1;
    end
  else
    begin
      {***************************}
      { solve the resolvent cubic }
      {***************************}
      cubic_coeff[0] := 1.0 / 2.0 * r * p - 1.0 / 8.0 * q * q;
      cubic_coeff[1] := -r;
      cubic_coeff[2] := -1.0 / 2.0 * p;
      cubic_coeff[3] := 1;
      Cubic_roots(cubic_coeff, cubic_root);

      {*****************************}
      { build two quadric equations }
      {*****************************}
      z := cubic_root[0];
      u := z * z - r;
      v := 2.0 * z - p;

      if (abs(u) < epsilon) then
        u := 0;
      if (abs(v) < epsilon) then
        v := 0;

      if (u < 0) or (v < 0) then
        roots := 0
      else
        begin
          u := sqrt(u);
          v := sqrt(v);
          quadric_coeff[0] := z - u;
          if (q < 0) then
            quadric_coeff[1] := -v
          else
            quadric_coeff[1] := v;
          quadric_coeff[2] := 1;
          counter := Quadric_roots(quadric_coeff, quadric_root);
          root[0] := quadric_root[0];
          root[1] := quadric_root[1];
          quadric_coeff[0] := z + u;
          quadric_coeff[1] := -quadric_coeff[1];
          roots := counter + Quadric_roots(quadric_coeff, quadric_root);
          root[counter] := quadric_root[0];
          root[counter + 1] := quadric_root[1];
        end;
    end;
  if (roots <> 0) then
    begin
      {**************}
      { resubstitute }
      {**************}
      temp := 1.0 / 4.0 * a;
      for counter := 0 to roots - 1 do
        root[counter] := root[counter] - temp;
    end;

  Quartic_roots := roots;
end; {function Quartic_roots}


end.
