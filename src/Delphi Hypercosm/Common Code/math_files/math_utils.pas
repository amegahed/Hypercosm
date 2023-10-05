unit math_utils;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            math_utils                 3d       }
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


{***********************}
{ exponential functions }
{***********************}
function Power(base, exponent: double): double;
function Logarithm(x, base: double): double;
function Cube_root(x: double): double;
function Scalar_power(base, exponent: double): double;
function Integer_power(base, exponent: longint): longint;

{*************************}
{ random number functions }
{*************************}
procedure Init_rnd(initial_seed: integer);
function Rnd: double;

{******************}
{ scalar functions }
{******************}
function Sign(x: double): integer;
function Fmod(x, y: double): double;
function Snap(x, y: double): double;
function Clamp(x, min, max: double): double;
function Real_ok(r: double): boolean;

{*******************}
{ integer functions }
{*******************}
function Even(i: integer): boolean;
function Odd(i: integer): boolean;
function Integer_ok(i: integer): boolean;


implementation


var
  seed: integer;


  {***********************}
  { exponential functions }
  {***********************}


function Power(base, exponent: double): double;
begin
  if (base = 0) then
    Power := 0
  else
    Power := exp(exponent * ln(base));
end; {function Power}


function Logarithm(x, base: double): double;
begin
  Logarithm := ln(x) / ln(base);
end; {function Logarithm}


function Cube_root(x: double): double;
begin
  if (x = 0) then
    Cube_root := 0
  else
    begin
      if (x < 0) then
        Cube_root := -exp(1.0 / 3.0 * ln(-x))
      else
        Cube_root := exp(1.0 / 3.0 * ln(x));
    end;
end; {function Cube_root}


function Scalar_power(base, exponent: double): double;
begin
  if (base = 0) then
    Scalar_power := 0
  else
    begin
      if (exponent - Trunc(exponent) = 0) then
        begin
          {***************************************}
          { integral power - base may be negative }
          {***************************************}
          if (base < 0) then
            begin
              if Trunc(exponent) mod 2 = 0 then
                {************}
                { even power }
                {************}
                Scalar_power := exp(exponent * ln(abs(base)))
              else
                {***********}
                { odd power }
                {***********}
                Scalar_power := -exp(exponent * ln(abs(base)))
            end
          else
            Scalar_power := exp(exponent * ln(base));
        end
      else
        begin
          {*********************************************}
          { fractional power - base may not be negative }
          {*********************************************}
          Scalar_power := exp(exponent * ln(base));
        end;
    end;
end; {function Scalar_power}


function Integer_power(base, exponent: longint): longint;
var
  count, val: longint;
begin
  val := 1;
  for count := 1 to exponent do
    val := val * base;
  Integer_power := val;
end; {function Integer_power}


{*************************}
{ random number functions }
{*************************}


procedure Init_rnd(initial_seed: integer);
begin
  seed := initial_seed;
end; {procedure Init_rnd}


function Rnd: double;
const
  multiplier = 25173;
  increment = 13849;
  modulus = 65536;
begin
  seed := (multiplier * seed + increment) mod modulus;
  Rnd := seed / modulus;
end; {function Rnd}


{******************}
{ scalar functions }
{******************}


function Sign(x: double): integer;
var
  temp: integer;
begin
  if (x > 0) then
    temp := 1
  else if (x = 0) then
    temp := 0
  else
    temp := -1;
  Sign := temp;
end; {function Sign}


function Trunc(x: double): integer;
begin
  Trunc := trunc(x);
end; {function Trunc}


function Round(x: double): integer;
begin
  if (x >= 0) then
    Round := Trunc(x + 0.5)
  else
    Round := Trunc(x - 0.5);
end; {function Round}


function Fmod(x, y: double): double;
begin
  Fmod := x - (trunc(x / y) * y);
end; {function Fmod}


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


function Real_ok(r: double): boolean;
begin
  if ((r >= 0) or (r < 0)) then
    Real_ok := true
  else
    Real_ok := false
end; {function Real_ok}


{*******************}
{ integer functions }
{*******************}


function Even(i: integer): boolean;
begin
  Even := (i mod 2 = 0);
end; {function Even}


function Odd(i: integer): boolean;
begin
  Odd := (i mod 2 <> 0);
end; {function Odd}


function Integer_ok(i: integer): boolean;
begin
  if ((i >= 0) or (i < 0)) then
    Integer_ok := true
  else
    Integer_ok := false
end; {function Integer_ok}


end.
