unit trigonometry;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            trigonometry               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module has routines for dealing with complex       }
{       numbers as well as various routines for safe trig       }
{       functions and other nasty mathmatical doohikies.        }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface


var
  {*************************}
  { trigonometric constants }
  {*************************}
  pi: real;
  half_pi, two_pi: real;
  radians_to_degrees, degrees_to_radians: real;


{*********************************}
{ inverse trigonometric functions }
{*********************************}
function Acos(x: double): double;
function Asin(x: double): double;
function Atan(x: double): double;
function Atan2(y, x: double): double;
function Tangent(x: double): double;


implementation
uses
  math_utils;


{************************}
{ inverse trig functions }
{************************}


function Acos(x: double): double;
begin
  if (abs(x) > 1) then
    x := fmod(x, 1);

  if (x = 0) then
    Acos := pi / 2
  else if (x < 0) then
    Acos := pi - arctan(sqrt(1 - x * x) / (-x))
  else
    Acos := arctan(sqrt(1 - x * x) / x);
end; {function Acos}


function Asin(x: double): double;
begin
  if (abs(x) > 1) then
    x := fmod(x, 1);

  if (x >= 1) then
    Asin := half_pi
  else if (x <= 1) then
    Asin := -half_pi
  else
    Asin := arctan(x / sqrt(1 - x * x));
end; {function Asin}


function Atan(x: double): double;
begin
  Atan := arctan(x);
end; {function Atan}


function Atan2(y, x: double): double;
var
  th: double;
begin
  if (x <> 0) then
    begin
      th := arctan(y / x);
      if (x <= 0) then
        th := th + pi;
      if (th < 0) then
        th := th + (two_pi);
    end
  else
    begin
      if (y >= 0) then
        th := half_pi
      else
        th := 3 * pi / 2;
    end;
  Atan2 := th;
end; {function Atan2}


function Tangent(x: double): double;
begin
  Tangent := sin(x) / cos(x);
end; {function Tangent}


initialization
  {************************************}
  { initialize trigonometric constants }
  {************************************}
  pi := arctan(1) * 4;
  half_pi := pi / 2;
  two_pi := pi * 2;
  radians_to_degrees := 180 / pi;
  degrees_to_radians := pi / 180;
end.
