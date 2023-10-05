unit string_io;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             string_io                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{        This module implements the string conversion           }
{        functions.                                             }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  strings, vectors;


{****************************************}
{ numeric to string conversion functions }
{****************************************}
function Integer_to_str(i: longint): string_type;
function Scalar_to_str(value: real;
  decimal_places: integer;
  exponential_notation: boolean): string_type;
function Double_to_str(value: double;
  decimal_places: integer;
  exponential_notation: boolean): string_type;
function Vector_to_str(vector: vector_type;
  decimal_places: integer;
  exponential_notation: boolean;
  use_commas: boolean): string_type;

{****************************************}
{ string to numeric conversion functions }
{****************************************}
function Str_to_integer(str: string_type): longint;
function Str_to_scalar(str: string_type): real;
function Str_to_double(str: string_type): double;
function Str_to_vector(str: string_type): vector_type;


implementation
uses
  chars;


{****************************************}
{ numeric to string conversion functions }
{****************************************}


function Integer_to_str(i: longint): string_type;
var
  negative: boolean;
  str: string_type;
  s: string_type;
  c: char;
begin
  if i = 0 then
    str := '0'
  else
    begin
      str := '';

      if (i < 0) then
        begin
          i := -i;
          negative := true;
        end
      else
        negative := false;

      while (i > 0) do
        begin
          c := chr(ord('0') + i mod 10);
          s := c;
          str := concat(str, s);
          i := i div 10;
        end;

      str := Reverse_str(str);
      if negative then
        str := concat('-', str);
    end;

  Integer_to_str := str;
end; {function Integer_to_str}


function Digits_to_str(value: longint;
  decimal_places: integer): string_type;
var
  size: longint;
  counter, digit: integer;
  str: string;
begin
  if value < 0 then
    begin
      str := '-';
      value := -value;
    end
  else
    str := '';

  if decimal_places = 0 then
    begin
      size := value;
      decimal_places := 0;
      while (size <> 0) do
        begin
          size := size div 10;
          decimal_places := decimal_places + 1;
        end;
      if decimal_places = 0 then
        decimal_places := 1;
    end;

  size := 1;
  for counter := 1 to decimal_places do
    size := size * 10;

  for counter := 1 to decimal_places do
    begin
      size := size div 10;
      digit := value div size;
      str := concat(str, Char_to_str(chr(ord('0') + digit mod 10)));
      value := value - (digit * size);
    end;

  Digits_to_str := str;
end; {function Digits_to_str}


function Fraction_to_str(fraction: double;
  decimal_places: integer): string_type;
var
  str: string;
  counter, digit: integer;
begin
  str := '';

  for counter := 1 to decimal_places do
    begin
      fraction := fraction * 10;
      digit := trunc(fraction);
      str := concat(str, chr(ord('0') + digit mod 10));
      fraction := fraction - digit;
    end;

  Fraction_to_str := str;
end; {function Fraction_to_str}


function Scalar_to_str(value: real;
  decimal_places: integer;
  exponential_notation: boolean): string_type;
const
  precision = 8;
var
  whole_part, size: longint;
  counter, exponent: integer;
  fractional_part, fudge, new_value: double;
  str: string;
begin
  str := '';
  exponent := 0;

  if (value <> 0) then
    begin
      new_value := abs(value);

      {********************}
      { values less than 1 }
      {********************}
      if new_value < 1 then
        begin
          while new_value < 1 do
            begin
              exponent := exponent - 1;
              new_value := new_value * 10;
            end;
        end

          {***********************}
          { values greater than 1 }
          {***********************}
      else
        begin
          while new_value >= 10 do
            begin
              exponent := exponent + 1;
              new_value := new_value / 10;
            end;
        end;

      {***********************************************}
      { shift to exponential notation when neccessary }
      {***********************************************}
      if abs(exponent) > precision then
        begin
          decimal_places := precision;
          exponential_notation := true;
          if value < 0 then
            value := -new_value
          else
            value := new_value;
        end;
    end;

  size := 1;
  for counter := 1 to decimal_places do
    size := size * 10;

  if value < 0 then
    begin
      str := concat(str, '-');
      value := -value;
    end;

  fudge := 1 / (2 * (size + 1));
  whole_part := trunc(value + fudge);
  if (whole_part <> 0) or (decimal_places = 0) then
    str := concat(str, Digits_to_str(whole_part, 0));

  if decimal_places > 0 then
    begin
      str := concat(str, '.');
      fractional_part := value - whole_part;
      str := concat(str, Fraction_to_str(fractional_part, decimal_places));
    end;

  if exponential_notation then
    begin
      str := concat(str, 'E');
      str := concat(str, Digits_to_str(exponent, 0));
    end;

  Scalar_to_str := str;
end; {function Scalar_to_str}


function Double_to_str(value: double;
  decimal_places: integer;
  exponential_notation: boolean): string_type;
const
  precision = 16;
var
  whole_part, size: longint;
  counter, exponent: integer;
  fractional_part, fudge, new_value: double;
  str: string;
begin
  str := '';
  exponent := 0;

  if (value <> 0) then
    begin
      new_value := abs(value);

      {********************}
      { values less than 1 }
      {********************}
      if new_value < 1 then
        begin
          while new_value < 1 do
            begin
              exponent := exponent - 1;
              new_value := new_value * 10;
            end;
        end

          {***********************}
          { values greater than 1 }
          {***********************}
      else
        begin
          while new_value >= 10 do
            begin
              exponent := exponent + 1;
              new_value := new_value / 10;
            end;
        end;

      {***********************************************}
      { shift to exponential notation when neccessary }
      {***********************************************}
      if abs(exponent) > precision then
        begin
          decimal_places := precision;
          exponential_notation := true;
          if value < 0 then
            value := -new_value
          else
            value := new_value;
        end;
    end;

  size := 1;
  for counter := 1 to decimal_places do
    size := size * 10;

  if value < 0 then
    begin
      str := concat(str, '-');
      value := -value;
    end;

  fudge := 1 / (2 * (size + 1));
  whole_part := trunc(value + fudge);
  if (whole_part <> 0) or (decimal_places = 0) then
    str := concat(str, Digits_to_str(whole_part, 0));

  if decimal_places > 0 then
    begin
      str := concat(str, '.');
      fractional_part := value - whole_part;
      str := concat(str, Fraction_to_str(fractional_part, decimal_places));
    end;

  if exponential_notation then
    begin
      str := concat(str, 'E');
      str := concat(str, Digits_to_str(exponent, 0));
    end;

  Double_to_str := str;
end; {function Double_to_str}


function Vector_to_str(vector: vector_type;
  decimal_places: integer;
  exponential_notation: boolean;
  use_commas: boolean): string_type;
var
  x_str, y_str, z_str: string_type;
begin
  {*******************************}
  { convert components to strings }
  {*******************************}
  x_str := Scalar_to_str(vector.x, decimal_places, exponential_notation);
  y_str := Scalar_to_str(vector.y, decimal_places, exponential_notation);
  z_str := Scalar_to_str(vector.z, decimal_places, exponential_notation);

  {****************}
  { add separators }
  {****************}
  if use_commas then
    begin
      x_str := concat(x_str, ', ');
      y_str := concat(y_str, ' ');
    end
  else
    begin
      x_str := concat(x_str, ' ');
      y_str := concat(y_str, ' ');
    end;

  Vector_to_str := concat(x_str, concat(y_str, z_str));
end; {function Vector_to_str}


{****************************************}
{ string to numeric conversion functions }
{****************************************}


function Char_value(ch: char): integer;
begin
  Char_value := ord(ch) - ord('0');
end; {function Char_value}


function Substr_to_integer(str: string_type;
  var index: integer): longint;
var
  integer_total: longint;
  max_index: integer;
  negative, done: boolean;
  ch: char;
begin
  max_index := length(str);
  integer_total := 0;

  if (index <= max_index) then
    begin
      {*****************}
      { read minus sign }
      {*****************}
      if str[index] = '-' then
        begin
          negative := true;
          index := index + 1;
        end
      else
        negative := false;

      {*************}
      { read digits }
      {*************}
      done := false;
      while (index <= max_index) and (not done) do
        begin
          ch := str[index];
          if ch in digits then
            begin
              integer_total := (integer_total * 10) + Char_value(ch);
              index := index + 1;
            end
          else
            done := true;
        end;

      if negative then
        integer_total := -integer_total;
    end;

  Substr_to_integer := integer_total;
end; {function Substr_to_integer}


function Str_to_integer(str: string_type): longint;
var
  index: integer;
begin
  index := 1;
  Str_to_integer := Substr_to_integer(str, index);
end; {function Str_to_integer}


function Str_to_scalar(str: string_type): real;
var
  index, max_index, exponent: integer;
  fractional_total, coefficient: real;
  negative, negative_exponent: boolean;
  scalar_val: real;
  done: boolean;
  ch: char;
begin
  index := 1;
  max_index := length(str);
  scalar_val := 0;

  if (index <= max_index) then
    begin
      {*****************}
      { read minus sign }
      {*****************}
      if str[index] = '-' then
        begin
          negative := true;
          index := index + 1;
        end
      else
        negative := false;

      {***********************}
      { read integer mantissa }
      {***********************}
      scalar_val := Substr_to_integer(str, index);

      if (index <= max_index) then
        begin
          {**********************}
          { read fractional part }
          {**********************}
          if str[index] = '.' then
            begin
              index := index + 1;
              fractional_total := 0;
              coefficient := 0.1;
              done := false;

              while (index <= max_index) and (not done) do
                begin
                  ch := str[index];
                  if ch in digits then
                    begin
                      fractional_total := fractional_total + (coefficient *
                        Char_value(ch));
                      coefficient := coefficient / 10.0;
                      index := index + 1;
                    end
                  else
                    done := true;
                end;

              scalar_val := scalar_val + fractional_total;
            end;

          {***************}
          { read exponent }
          {***************}
          if (index <= max_index) then
            begin
              if (str[index] = 'E') or (str[index] = 'e') then
                begin
                  index := index + 1;

                  {*****************}
                  { read minus sign }
                  {*****************}
                  if str[index] = '-' then
                    begin
                      negative_exponent := true;
                      index := index + 1;
                    end
                  else
                    begin
                      negative_exponent := false;
                      if str[index] = '+' then
                        index := index + 1;
                    end;

                  {*************}
                  { read digits }
                  {*************}
                  done := false;
                  exponent := 0;
                  while (index <= max_index) and (not done) do
                    begin
                      ch := str[index];
                      if ch in digits then
                        begin
                          exponent := (exponent * 10) + Char_value(ch);
                          index := index + 1;
                        end
                      else
                        done := true;
                    end;

                  {*********************}
                  { compute coefficient }
                  {*********************}
                  coefficient := 1.0;
                  while (exponent > 0) do
                    begin
                      coefficient := coefficient * 10.0;
                      exponent := exponent - 1;
                    end;

                  {****************************}
                  { scale value by coefficient }
                  {****************************}
                  if negative_exponent then
                    scalar_val := scalar_val / coefficient
                  else
                    scalar_val := scalar_val * coefficient;
                end;
            end;
        end;

      if negative then
        scalar_val := -scalar_val;
    end;

  Str_to_scalar := scalar_val;
end; {function Str_to_scalar}


function Str_to_double(str: string_type): double;
var
  index, max_index, exponent: integer;
  fractional_total, coefficient: double;
  negative, negative_exponent: boolean;
  double_val: double;
  done: boolean;
  ch: char;
begin
  index := 1;
  max_index := length(str);
  double_val := 0;

  if (index <= max_index) then
    begin
      {*****************}
      { read minus sign }
      {*****************}
      if str[index] = '-' then
        begin
          negative := true;
          index := index + 1;
        end
      else
        negative := false;

      {***********************}
      { read integer mantissa }
      {***********************}
      double_val := Substr_to_integer(str, index);

      if (index <= max_index) then
        begin
          {**********************}
          { read fractional part }
          {**********************}
          if str[index] = '.' then
            begin
              index := index + 1;
              fractional_total := 0;
              coefficient := 0.1;
              done := false;

              while (index <= max_index) and (not done) do
                begin
                  ch := str[index];
                  if ch in digits then
                    begin
                      fractional_total := fractional_total + (coefficient *
                        Char_value(ch));
                      coefficient := coefficient / 10.0;
                      index := index + 1;
                    end
                  else
                    done := true;
                end;

              double_val := double_val + fractional_total;
            end;

          {***************}
          { read exponent }
          {***************}
          if (index <= max_index) then
            begin
              if (str[index] = 'E') or (str[index] = 'e') then
                begin
                  index := index + 1;

                  {*****************}
                  { read minus sign }
                  {*****************}
                  if str[index] = '-' then
                    begin
                      negative_exponent := true;
                      index := index + 1;
                    end
                  else
                    begin
                      negative_exponent := false;
                      if str[index] = '+' then
                        index := index + 1;
                    end;

                  {*************}
                  { read digits }
                  {*************}
                  done := false;
                  exponent := 0;
                  while (index <= max_index) and (not done) do
                    begin
                      ch := str[index];
                      if ch in digits then
                        begin
                          exponent := (exponent * 10) + Char_value(ch);
                          index := index + 1;
                        end
                      else
                        done := true;
                    end;

                  {*********************}
                  { compute coefficient }
                  {*********************}
                  coefficient := 1.0;
                  while (exponent > 0) do
                    begin
                      coefficient := coefficient * 10.0;
                      exponent := exponent - 1;
                    end;

                  {****************************}
                  { scale value by coefficient }
                  {****************************}
                  if negative_exponent then
                    double_val := double_val / coefficient
                  else
                    double_val := double_val * coefficient;
                end;
            end;
        end;

      if negative then
        double_val := -double_val;
    end;

  Str_to_double := double_val;
end; {function Str_to_double}


function Str_to_vector(str: string_type): vector_type;
begin
  str := '';
  Str_to_vector := zero_vector;
end; {function Str_to_vector}


end.
