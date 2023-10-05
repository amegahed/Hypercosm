unit noise;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               noise                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains noise routines to be used for      }
{       textures.                                               }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  vectors;


{************************************************}
{ 1, 2, and 3 dimensional scalar noise functions }
{************************************************}
function Noise1(x: real): real;
function Noise2(x, y: real): real;
function Noise3(vector: vector_type): real;

{************************************************}
{ 1, 2, and 3 dimensional vector noise functions }
{************************************************}
function Noise_vector1(x: real): vector_type;
function Noise_vector2(x, y: real): vector_type;
function Noise_vector3(vector: vector_type): vector_type;


implementation
uses
  Windows;


{************************}
{ table of prime numbers }
{ for number generation  }
{************************}
const
  prime_size = 64;


type
  multiplier_type = longlong;
  increment_type = longlong;
  modulus_type = longlong;


var
  primes: array[0..prime_size] of longint;


{************************************************}
{ 1, 2, and 3 dimensional scalar noise functions }
{************************************************}


function Integer_to_random1(i: longint): real;
var
  multiplier: multiplier_type;
  increment: increment_type;
  modulus: modulus_type;
begin
  if (i < 0) then
    i := primes[-i mod prime_size];

  multiplier := primes[i mod prime_size];
  increment := primes[multiplier mod prime_size];
  modulus := primes[increment mod prime_size];
  i := (multiplier * i + increment) mod modulus;
  Integer_to_random1 := abs(i / modulus);
end; {function Integer_to_random1}


function Integer_to_random2(i, j: longint): real;
var
  multiplier: multiplier_type;
  increment: increment_type;
  modulus: modulus_type;
begin
  if (i < 0) then
    i := primes[-i mod prime_size];
  if (j < 0) then
    j := primes[-j mod prime_size];

  multiplier := primes[i mod prime_size];
  increment := primes[multiplier mod prime_size];
  modulus := primes[j mod prime_size];
  i := (multiplier * i + increment) mod modulus;
  Integer_to_random2 := abs(i / modulus);
end; {function Integer_to_random2}


function Integer_to_random3(i, j, k: longint): real;
var
  multiplier: multiplier_type;
  increment: increment_type;
  modulus: modulus_type;
begin
  if (i < 0) then
    i := primes[-i mod prime_size];
  if (j < 0) then
    j := primes[-j mod prime_size];
  if (k < 0) then
    k := primes[-k mod prime_size];

  multiplier := primes[i mod prime_size];
  increment := primes[j mod prime_size];
  modulus := primes[k mod prime_size];
  i := (multiplier * i + increment) mod modulus;
  Integer_to_random3 := abs(i / modulus);
end; {function Integer_to_random3}


function Noise1(x: real): real;
var
  i: array[1..2] of longint;
  r: array[1..2] of real;
  r1, r2: real;
begin
  {******************************}
  { find span on integer lattice }
  {******************************}
  if (x < 0) then
    begin
      i[1] := Trunc(x - 1);
      i[2] := Trunc(x);
    end
  else
    begin
      i[1] := Trunc(x);
      i[2] := Trunc(x + 1);
    end;

  {******************************************}
  { compute random values on integer lattice }
  {******************************************}
  r[1] := Integer_to_random1(i[1]);
  r[2] := Integer_to_random1(i[2]);

  {****************************}
  { interpolate in x dimension }
  {****************************}
  r1 := r[1] * (i[2] - x);
  r2 := r[2] * (x - i[1]);

  Noise1 := r1 + r2;
end; {function Noise1}


function Noise2(x, y: real): real;
var
  i: array[1..2, 1..2] of integer;
  r: array[1..2, 1..2] of real;
  x_counter, y_counter: integer;
  ix, iy: integer;
  r1, r2: real;
begin
  {*****************************}
  { find box on integer lattice }
  {*****************************}
  if (x < 0) then
    begin
      i[1, 1] := Trunc(x - 1);
      i[1, 2] := Trunc(x);
    end
  else
    begin
      i[1, 1] := Trunc(x);
      i[1, 2] := Trunc(x + 1);
    end;

  if (y < 0) then
    begin
      i[2, 1] := Trunc(y - 1);
      i[2, 2] := Trunc(y);
    end
  else
    begin
      i[2, 1] := Trunc(y);
      i[2, 2] := Trunc(y + 1);
    end;

  {******************************************}
  { compute random values on integer lattice }
  {******************************************}
  for y_counter := 1 to 2 do
    for x_counter := 1 to 2 do
      begin
        ix := i[1][x_counter];
        iy := i[2][y_counter];
        r[x_counter, y_counter] := Integer_to_random2(ix, iy);
      end;

  {***********************************************}
  { interpolate between points on integer lattice }
  {***********************************************}
  for y_counter := 1 to 2 do
    begin
      {****************************}
      { interpolate in x dimension }
      {****************************}
      r1 := r[1, y_counter] * (i[1, 2] - x);
      r2 := r[2, y_counter] * (x - i[1, 1]);
      r[1, y_counter] := r1 + r2;
    end;

  {****************************}
  { interpolate in y dimension }
  {****************************}
  r1 := r[1, 1] * (i[2, 2] - y);
  r2 := r[1, 2] * (y - i[2, 1]);

  Noise2 := r1 + r2;
end; {function Noise2}


function Noise3(vector: vector_type): real;
var
  x, y, z: real;
  i: array[1..3, 1..2] of integer;
  r: array[1..2, 1..2, 1..2] of real;
  x_counter, y_counter, z_counter: integer;
  ix, iy, iz: integer;
  r1, r2: real;
begin
  x := vector.x;
  y := vector.y;
  z := vector.z;

  {*****************************}
  { find box on integer lattice }
  {*****************************}
  if (x < 0) then
    begin
      i[1, 1] := Trunc(x - 1);
      i[1, 2] := Trunc(x);
    end
  else
    begin
      i[1, 1] := Trunc(x);
      i[1, 2] := Trunc(x + 1);
    end;

  if (y < 0) then
    begin
      i[2, 1] := Trunc(y - 1);
      i[2, 2] := Trunc(y);
    end
  else
    begin
      i[2, 1] := Trunc(y);
      i[2, 2] := Trunc(y + 1);
    end;

  if (z < 0) then
    begin
      i[3, 1] := Trunc(z - 1);
      i[3, 2] := Trunc(z);
    end
  else
    begin
      i[3, 1] := Trunc(z);
      i[3, 2] := Trunc(z + 1);
    end;

  {******************************************}
  { compute random values on integer lattice }
  {******************************************}
  for z_counter := 1 to 2 do
    for y_counter := 1 to 2 do
      for x_counter := 1 to 2 do
        begin
          ix := i[1][x_counter];
          iy := i[2][y_counter];
          iz := i[3][z_counter];
          r[x_counter, y_counter, z_counter] := Integer_to_random3(ix, iy, iz);
        end;

  {***********************************************}
  { interpolate between points on integer lattice }
  {***********************************************}
  for z_counter := 1 to 2 do
    begin
      for y_counter := 1 to 2 do
        begin
          {****************************}
          { interpolate in x dimension }
          {****************************}
          r1 := r[1, y_counter, z_counter] * (i[1, 2] - x);
          r2 := r[2, y_counter, z_counter] * (x - i[1, 1]);
          r[1, y_counter, z_counter] := r1 + r2;
        end;

      {****************************}
      { interpolate in y dimension }
      {****************************}
      r1 := r[1, 1, z_counter] * (i[2, 2] - y);
      r2 := r[1, 2, z_counter] * (y - i[2, 1]);
      r[1, 1, z_counter] := r1 + r2;
    end;

  {****************************}
  { interpolate in z dimension }
  {****************************}
  r1 := r[1, 1, 1] * (i[3, 2] - z);
  r2 := r[1, 1, 2] * (z - i[3, 1]);

  Noise3 := r1 + r2;
end; {function Noise3}


{************************************************}
{ 1, 2, and 3 dimensional vector noise functions }
{************************************************}


function Integer_to_random_vector1(i: longint): vector_type;
var
  multiplier: multiplier_type;
  increment: increment_type;
  modulus: modulus_type;
  x, y, z: modulus_type;
  vector: vector_type;
begin
  if (i < 0) then
    i := primes[-i mod prime_size];

  multiplier := primes[i mod prime_size];
  increment := primes[multiplier mod prime_size];
  modulus := primes[increment mod prime_size];

  x := (multiplier * i + increment) mod modulus;
  y := (multiplier * x + increment) mod modulus;
  z := (multiplier * y + increment) mod modulus;

  vector.x := abs(x / modulus);
  vector.y := abs(y / modulus);
  vector.z := abs(z / modulus);
  Integer_to_random_vector1 := vector;
end; {function Integer_to_random_vector1}


function Integer_to_random_vector2(i, j: longint): vector_type;
var
  multiplier: multiplier_type;
  increment: increment_type;
  modulus: modulus_type;
  x, y, z: modulus_type;
  vector: vector_type;
begin
  if (i < 0) then
    i := primes[-i mod prime_size];
  if (j < 0) then
    j := primes[-j mod prime_size];

  multiplier := primes[i mod prime_size];
  increment := primes[multiplier mod prime_size];
  modulus := primes[j mod prime_size];

  x := (multiplier * i + increment) mod modulus;
  y := (multiplier * x + increment) mod modulus;
  z := (multiplier * y + increment) mod modulus;

  vector.x := abs(x / modulus);
  vector.y := abs(y / modulus);
  vector.z := abs(z / modulus);
  Integer_to_random_vector2 := vector;
end; {function Integer_to_random_vector2}


function Integer_to_random_vector3(i, j, k: longint): vector_type;
var
  multiplier: multiplier_type;
  increment: increment_type;
  modulus: modulus_type;
  x, y, z: modulus_type;
  vector: vector_type;
begin
  if (i < 0) then
    i := primes[-i mod prime_size];
  if (j < 0) then
    j := primes[-j mod prime_size];
  if (k < 0) then
    k := primes[-k mod prime_size];

  multiplier := primes[i mod prime_size];
  increment := primes[j mod prime_size];
  modulus := primes[k mod prime_size];

  x := (multiplier * i + increment) mod modulus;
  y := (multiplier * x + increment) mod modulus;
  z := (multiplier * y + increment) mod modulus;

  vector.x := abs(x / modulus);
  vector.y := abs(y / modulus);
  vector.z := abs(z / modulus);
  Integer_to_random_vector3 := vector;
end; {function Integer_to_random_vector3}


function Noise_vector1(x: real): vector_type;
var
  i: array[1..2] of longint;
  v: array[1..2] of vector_type;
  v1, v2: vector_type;
begin
  {******************************}
  { find span on integer lattice }
  {******************************}
  if (x < 0) then
    begin
      i[1] := Trunc(x - 1);
      i[2] := Trunc(x);
    end
  else
    begin
      i[1] := Trunc(x);
      i[2] := Trunc(x + 1);
    end;

  {******************************************}
  { compute random values on integer lattice }
  {******************************************}
  v[1] := Integer_to_random_vector1(i[1]);
  v[2] := Integer_to_random_vector1(i[2]);

  {****************************}
  { interpolate in x dimension }
  {****************************}
  v1 := Vector_scale(v[1], (i[2] - x));
  v2 := Vector_scale(v[2], (x - i[1]));

  Noise_vector1 := Vector_sum(v1, v2);
end; {function Noise_vector1}


function Noise_vector2(x, y: real): vector_type;
var
  i: array[1..2, 1..2] of integer;
  v: array[1..2, 1..2] of vector_type;
  x_counter, y_counter: integer;
  ix, iy: integer;
  v1, v2: vector_type;
begin
  {*****************************}
  { find box on integer lattice }
  {*****************************}
  if (x < 0) then
    begin
      i[1, 1] := Trunc(x - 1);
      i[1, 2] := Trunc(x);
    end
  else
    begin
      i[1, 1] := Trunc(x);
      i[1, 2] := Trunc(x + 1);
    end;

  if (y < 0) then
    begin
      i[2, 1] := Trunc(y - 1);
      i[2, 2] := Trunc(y);
    end
  else
    begin
      i[2, 1] := Trunc(y);
      i[2, 2] := Trunc(y + 1);
    end;

  {******************************************}
  { compute random values on integer lattice }
  {******************************************}
  for y_counter := 1 to 2 do
    for x_counter := 1 to 2 do
      begin
        ix := i[1][x_counter];
        iy := i[2][y_counter];
        v[x_counter, y_counter] := Integer_to_random_vector2(ix, iy);
      end;

  {***********************************************}
  { interpolate between points on integer lattice }
  {***********************************************}
  for y_counter := 1 to 2 do
    begin
      {****************************}
      { interpolate in x dimension }
      {****************************}
      v1 := Vector_scale(v[1, y_counter], (i[1, 2] - x));
      v2 := Vector_scale(v[2, y_counter], (x - i[1, 1]));
      v[1, y_counter] := Vector_sum(v1, v2);
    end;

  {****************************}
  { interpolate in y dimension }
  {****************************}
  v1 := Vector_scale(v[1, 1], (i[2, 2] - y));
  v2 := Vector_scale(v[1, 2], (y - i[2, 1]));

  Noise_vector2 := Vector_sum(v1, v2);
end; {function Noise_vector2}


function Noise_vector3(vector: vector_type): vector_type;
var
  x, y, z: real;
  i: array[1..3, 1..2] of integer;
  v: array[1..2, 1..2, 1..2] of vector_type;
  x_counter, y_counter, z_counter: integer;
  ix, iy, iz: integer;
  v1, v2: vector_type;
begin
  x := vector.x;
  y := vector.y;
  z := vector.z;

  {*****************************}
  { find box on integer lattice }
  {*****************************}
  if (x < 0) then
    begin
      i[1, 1] := Trunc(x - 1);
      i[1, 2] := Trunc(x);
    end
  else
    begin
      i[1, 1] := Trunc(x);
      i[1, 2] := Trunc(x + 1);
    end;

  if (y < 0) then
    begin
      i[2, 1] := Trunc(y - 1);
      i[2, 2] := Trunc(y);
    end
  else
    begin
      i[2, 1] := Trunc(y);
      i[2, 2] := Trunc(y + 1);
    end;

  if (z < 0) then
    begin
      i[3, 1] := Trunc(z - 1);
      i[3, 2] := Trunc(z);
    end
  else
    begin
      i[3, 1] := Trunc(z);
      i[3, 2] := Trunc(z + 1);
    end;

  {******************************************}
  { compute random values on integer lattice }
  {******************************************}
  for z_counter := 1 to 2 do
    for y_counter := 1 to 2 do
      for x_counter := 1 to 2 do
        begin
          ix := i[1][x_counter];
          iy := i[2][y_counter];
          iz := i[3][z_counter];
          v[x_counter, y_counter, z_counter] := Integer_to_random_vector3(ix,
            iy, iz);
        end;

  {***********************************************}
  { interpolate between points on integer lattice }
  {***********************************************}
  for z_counter := 1 to 2 do
    begin
      for y_counter := 1 to 2 do
        begin
          {****************************}
          { interpolate in x dimension }
          {****************************}
          v1 := Vector_scale(v[1, y_counter, z_counter], (i[1, 2] - x));
          v2 := Vector_scale(v[2, y_counter, z_counter], (x - i[1, 1]));
          v[1, y_counter, z_counter] := Vector_sum(v1, v2);
        end;

      {****************************}
      { interpolate in y dimension }
      {****************************}
      v1 := Vector_scale(v[1, 1, z_counter], (i[2, 2] - y));
      v2 := Vector_scale(v[1, 2, z_counter], (y - i[2, 1]));
      v[1, 1, z_counter] := Vector_sum(v1, v2);
    end;

  {****************************}
  { interpolate in z dimension }
  {****************************}
  v1 := Vector_scale(v[1, 1, 1], (i[3, 2] - z));
  v2 := Vector_scale(v[1, 1, 2], (z - i[3, 1]));

  Noise_vector3 := Vector_sum(v1, v2);
end; {function Noise_vector3}


initialization
  primes[0] := 93199;
  primes[1] := 212441;
  primes[2] := 138403;
  primes[3] := 96289;

  primes[4] := 120677;
  primes[5] := 139921;
  primes[6] := 163853;
  primes[7] := 55117;

  primes[8] := 261439;
  primes[9] := 15823;
  primes[10] := 97151;
  primes[11] := 203207;

  primes[12] := 192233;
  primes[13] := 178877;
  primes[14] := 142537;
  primes[15] := 204521;

  primes[16] := 212411;
  primes[17] := 200201;
  primes[18] := 187987;
  primes[19] := 176089;

  primes[20] := 163853;
  primes[21] := 151729;
  primes[22] := 139921;
  primes[23] := 139921;

  primes[24] := 128203;
  primes[25] := 116471;
  primes[26] := 104759;
  primes[27] := 93199;

  primes[28] := 81839;
  primes[29] := 70667;
  primes[30] := 59377;
  primes[31] := 48623;

  primes[32] := 54601;
  primes[33] := 66923;
  primes[34] := 79379;
  primes[35] := 92033;

  primes[36] := 104743;
  primes[37] := 117779;
  primes[38] := 130687;
  primes[39] := 143879;

  primes[40] := 157133;
  primes[41] := 170689;
  primes[42] := 184043;
  primes[43] := 197507;

  primes[44] := 210961;
  primes[45] := 224743;
  primes[46] := 238657;
  primes[47] := 143879;

  primes[48] := 43913;
  primes[49] := 55949;
  primes[50] := 68219;
  primes[51] := 80657;

  primes[52] := 106243;
  primes[53] := 132257;
  primes[54] := 145459;
  primes[55] := 172169;

  primes[56] := 198839;
  primes[57] := 226267;
  primes[58] := 240139;
  primes[59] := 253823;

  primes[60] := 274583;
  primes[61] := 198437;
  primes[62] := 96857;
  primes[63] := 171233;
end.
