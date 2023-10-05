unit complex_numbers;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          complex_numbers              3d       }
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


type
  complex_type = record
    a, b: real;
  end; {complex_type}


  {*********************}
  { complex constructor }
  {*********************}
function To_complex(a, b: real): complex_type;

{*********************}
{ complex comparisons }
{*********************}
function Equal_complex(c1, c2: complex_type): boolean;

{*******************}
{ complex operators }
{*******************}
function Complex(a: real): complex_type;
function Complex_sum(c1, c2: complex_type): complex_type;
function Complex_difference(c1, c2: complex_type): complex_type;
function Complex_product(c1, c2: complex_type): complex_type;
function Complex_ratio(c1, c2: complex_type): complex_type;
function Complex_negation(c: complex_type): complex_type;
function Complex_scale(c: complex_type;
  s: real): complex_type;
function Complex_sqr(c: complex_type): complex_type;
function Complex_sqrt(c: complex_type): complex_type;
function Complex_abs(c: complex_type): real;
function Complex_real(c: complex_type): real;
function Complex_imag(c: complex_type): real;
function Complex_root(c: complex_type;
  n: integer): complex_type;

{*********************}
{ complex diagnostics }
{*********************}
function Complex_ok(c: complex_type): boolean;
procedure Write_complex(c: complex_type);


implementation
uses
  constants, math_utils, trigonometry;


{*********************}
{ complex constructor }
{*********************}


function To_complex(a, b: real): complex_type;
var
  c: complex_type;
begin
  c.a := a;
  c.b := b;
  To_complex := c;
end; {function To_complex}


{*********************}
{ complex comparisons }
{*********************}


function Equal_complex(c1, c2: complex_type): boolean;
var
  temp: boolean;
begin
  temp := false;
  if (c1.a = c2.a) then
    if (c1.b = c2.b) then
      temp := true;
  Equal_complex := temp;
end; {function Equal_complex}


{*******************}
{ complex operators }
{*******************}


function Complex(a: real): complex_type;
begin
  Complex.a := a;
  Complex.b := 0;
end; {function Complex}


function Complex_sum(c1, c2: complex_type): complex_type;
var
  sum: complex_type;
begin
  sum.a := c1.a + c2.a;
  sum.b := c1.b + c2.b;
  Complex_sum := sum;
end; {function Complex_sum}


function Complex_difference(c1, c2: complex_type): complex_type;
begin
  Complex_difference.a := c1.a - c2.a;
  Complex_difference.b := c1.b - c2.b;
end; {function Complex_difference}


function Complex_product(c1, c2: complex_type): complex_type;
begin
  Complex_product.a := (c1.a * c2.a) - (c1.b * c2.b);
  Complex_product.b := (c1.a * c2.b) + (c1.b * c2.a);
end; {function Complex_product}


function Complex_ratio(c1, c2: complex_type): complex_type;
var
  temp: real;
begin
  temp := sqr(c2.a) + sqr(c2.b);
  Complex_ratio.a := ((c1.a * c2.a) + (c1.b * c2.b)) / temp;
  Complex_ratio.b := ((c1.b * c2.a) - (c1.a * c2.b)) / temp;
end; {function Complex_ratio}


function Complex_negation(c: complex_type): complex_type;
begin
  Complex_negation.a := -c.a;
  Complex_negation.b := -c.b;
end; {function Complex_negation}


function Complex_scale(c: complex_type;
  s: real): complex_type;
begin
  Complex_scale.a := c.a * s;
  Complex_scale.b := c.b * s;
end; {function Complex_scale}


function Complex_sqrt(c: complex_type): complex_type;
var
  r, th: real;
begin
  th := Atan2(c.b, c.a);
  r := sqrt(sqrt(sqr(c.a) + sqr(c.b)));
  Complex_sqrt.a := r * cos(th / 2);
  Complex_sqrt.b := r * sin(th / 2);
end; {function Complex_sqrt}


function Complex_sqr(c: complex_type): complex_type;
begin
  Complex_sqr.a := (c.a * c.a) - (c.b * c.b);
  Complex_sqr.b := (c.a * c.b) + (c.b * c.a);
end; {function Complex_sqr}


function Complex_abs(c: complex_type): real;
begin
  Complex_abs := sqrt(sqr(c.a) + sqr(c.b));
end; {function Complex_abs}


function Complex_real(c: complex_type): real;
begin
  Complex_real := c.a;
end; {function Complex_real}


function Complex_imag(c: complex_type): real;
begin
  Complex_imag := c.b;
end; {function Complex_imag}


function Complex_root(c: complex_type;
  n: integer): complex_type;
var
  r, th: real;
begin
  r := sqrt(sqr(c.a) + sqr(c.b));

  if (c.a <> 0) then
    begin
      th := arctan(c.b / c.a);
      if (c.a < 0) then
        th := th + pi;
    end
  else
    begin
      if (c.a > 0) then
        th := half_pi
      else
        th := -half_pi;
    end;

  r := Power(r, 1 / n);
  th := th / n;

  if (th = 0) then
    begin
      Complex_root.a := r;
      Complex_root.b := 0;
    end
  else if (th = pi) then
    begin
      Complex_root.a := -r;
      Complex_root.b := 0;
    end
  else
    begin
      Complex_root.a := r * cos(th);
      Complex_root.b := r * sin(th);
    end;
end; {function Complex_root}


{*********************}
{ complex diagnostics }
{*********************}


procedure Write_complex(c: complex_type);
begin
  write(c.a: 4: 4, '+', c.b: 4: 4, 'i');
end; {procedure Write_complex}


function Complex_ok(c: complex_type): boolean;
var
  ok: boolean;
begin
  ok := true;
  with c do
    if not ((a >= 0) or (a < 0)) then
      ok := false
    else
      begin
        if not ((b >= 0) or (b < 0)) then
          ok := false
      end;
  Complex_ok := ok;
end; {function Complex_ok}


end.
