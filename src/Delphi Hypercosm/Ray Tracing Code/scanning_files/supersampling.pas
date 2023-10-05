unit supersampling;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            supersampling              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to supersample pixels.    }
{                                                               }
{       Before pixels are supersampled, an edge detection       }
{       algorithm is run to find the candidate pixels.          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  pixels, vectors2;


type
  ss_mode_type = (ss_on, ss_off);


procedure Init_supersampling;

procedure Set_ss_mode(mode: ss_mode_type);
function Get_ss_mode: ss_mode_type;
procedure Write_ss_mode(mode: ss_mode_type);

procedure Find_ss_pixels;
procedure Display_ss_pixels;

function Supersampling_required(pixel: pixel_type): boolean;
function Subpixel_placement(pixel: pixel_type;
  index: integer): vector2_type;


implementation
uses
  new_memory, vectors, colors, pixel_colors;


{*********************************************}
{ maximum difference in colors allowed before }
{ supersampling kicks in. (0 - 255 range)     }
{*********************************************}
const
  max_delta = 15;
  memory_alert = false;


type
  prime_type = array[1..16] of longint;


  ss_buffer_type = boolean;
  ss_buffer_ptr_type = ^ss_buffer_type;


var
  ss_buffer_ptr: ss_buffer_ptr_type;
  ss_mode: ss_mode_type;
  primes1x, primes1y: prime_type;
  primes2x, primes2y: prime_type;


procedure Set_ss_mode(mode: ss_mode_type);
var
  ss_buffer_size: longint;
begin
  {*******************************}
  { allocate supersampling buffer }
  {*******************************}
  ss_mode := mode;

  case mode of
    ss_on:
      begin
        if (ss_buffer_ptr = nil) then
          begin
            ss_buffer_size := longint(window_size.h + 1) * longint(window_size.v
              + 1);
            ss_buffer_size := ss_buffer_size * sizeof(ss_buffer_type);

            if memory_alert then
              writeln('allocating new supersampling buffer');
            ss_buffer_ptr := ss_buffer_ptr_type(New_ptr(ss_buffer_size));
          end;
      end;

    ss_off:
      begin
        if (ss_buffer_ptr <> nil) then
          Free_ptr(ptr_type(ss_buffer_ptr));
      end;
  end; {case}
end; {procedure Set_ss_mode}


function Get_ss_mode: ss_mode_type;
begin
  Get_ss_mode := ss_mode;
end; {function Get_ss_mode}


procedure Write_ss_mode(mode: ss_mode_type);
begin
  case mode of
    ss_on:
      write('ss_on');

    ss_off:
      write('ss_off');
  end;
end; {procedure Write_ss_mode}


function Index_ss_buffer(ss_buffer_ptr: ss_buffer_ptr_type;
  h, v: integer): ss_buffer_ptr_type;
var
  offset: longint;
begin
  offset := (longint(h) + (longint(v) * longint(window_size.h + 1))) *
    sizeof(ss_buffer_type);
  Index_ss_buffer := ss_buffer_ptr_type(longint(ss_buffer_ptr) + offset);
end; {function Index_ss_buffer}


procedure Display_ss_pixels;
var
  h_counter, v_counter: integer;
  pixel: pixel_type;
  ss_ptr: ss_buffer_ptr_type;
begin
  Set_color(black_color);
  Clear_window;

  Set_color(white_color);
  for v_counter := 0 to window_size.v do
    begin
      ss_ptr := Index_ss_buffer(ss_buffer_ptr, 0, v_counter);
      for h_counter := 0 to window_size.h do
        begin
          if ss_ptr^ then
            begin
              pixel.h := h_counter;
              pixel.v := v_counter;
              Draw_pixel(pixel);
            end;
          ss_ptr := ss_buffer_ptr_type(longint(ss_ptr) +
            sizeof(ss_buffer_type));
        end;
    end;
  Update_window;
end; {procedure Display_ss_pixels}


function Colors_different(color1, color2: pixel_color_type): boolean;
var
  different: boolean;
begin
  different := true;
  if (abs(color1.r - color2.r) < max_delta) then
    if (abs(color1.g - color2.g) < max_delta) then
      if (abs(color1.b - color2.b) < max_delta) then
        different := false;
  Colors_different := different;
end; {function Colors_different}


procedure Find_ss_pixels;
var
  h_counter, v_counter: integer;
  h_offset, v_offset: integer;
  color1, color2: pixel_color_type;
  done: boolean;
  ss_ptr: ss_buffer_ptr_type;
begin
  {*********************************}
  { initialize supersampling buffer }
  {*********************************}
  for v_counter := 0 to window_size.v do
    begin
      ss_ptr := Index_ss_buffer(ss_buffer_ptr, 0, v_counter);
      for h_counter := 0 to window_size.h do
        begin
          ss_ptr^ := false;
          ss_ptr := ss_buffer_ptr_type(longint(ss_ptr) +
            sizeof(ss_buffer_type));
        end;
    end;

  {************}
  { find edges }
  {************}
  for v_counter := 0 to window_size.v do
    for h_counter := 0 to window_size.h do
      begin
        color1 := Get_pixel_color(To_pixel(h_counter, v_counter));

        {*********************************************}
        { if pixel differs from any of its neighbors  }
        { by more than a certain amount in any of the }
        { components of the color, then supersample.  }
        {*********************************************}
        done := false;
        v_offset := -1;
        while (v_offset <= 1) and (not done) do
          begin
            h_offset := -1;
            while (h_offset <= 1) and (not done) do
              begin
                if (h_offset <> 0) or (v_offset <> 0) then
                  begin
                    color2 := Get_pixel_color(To_pixel(h_counter + h_offset,
                      v_counter + v_offset));
                    if Colors_different(color1, color2) then
                      begin
                        Index_ss_buffer(ss_buffer_ptr, h_counter, v_counter)^ :=
                          true;
                        done := true;
                      end;
                  end; {if}
                h_offset := h_offset + 1;
              end; {while}
            v_offset := v_offset + 1;
          end; {while}
      end; {for}
end; {procedure Find_ss_pixels}


{******************************************}
{ jittering routines for scattering rays   }
{ over a pseudorandom pattern in the pixel }
{******************************************}


function jitter1x(pixel: pixel_type): real;
var
  temp: longint;
begin
  temp := (pixel.h * 20323 + pixel.v * 19777) + 12345;
  jitter1x := (temp mod 70667) / 70667.0 * 0.42;
end; {function jitter1x}


function jitter1y(pixel: pixel_type): real;
var
  temp: longint;
begin
  temp := (pixel.h * 23003 + pixel.v * 13411) + 12345;
  jitter1y := (temp mod 70453) / 70729.0 * 0.42;
end; {function jitter1y}


function jitter2x(pixel: pixel_type;
  index: integer): real;
var
  temp: longint;
begin
  temp := (pixel.h * primes2x[index]) + (pixel.v * primes2y[index]);
  jitter2x := ((temp mod 70783) / 70783.0) * 0.98;
end; {function jitter2x}


function jitter2y(pixel: pixel_type;
  index: integer): real;
var
  temp: longint;
begin
  temp := (pixel.v * primes2x[index]) + (pixel.v * primes2y[index]);
  jitter2y := ((temp mod 70901) / 70901.0) * 0.98;
end; {function jitter2y}


procedure Init_primes;
begin
  {***************}
  { init primes1x }
  {***************}
  primes1x[1] := 93199;
  primes1x[2] := 212441;
  primes1x[3] := 138403;
  primes1x[4] := 96289;

  primes1x[5] := 120677;
  primes1x[6] := 139921;
  primes1x[7] := 163853;
  primes1x[8] := 55117;

  primes1x[9] := 261439;
  primes1x[10] := 15823;
  primes1x[11] := 97151;
  primes1x[12] := 203207;

  primes1x[13] := 192233;
  primes1x[14] := 178877;
  primes1x[15] := 142537;
  primes1x[16] := 204521;

  {***************}
  { init primes1y }
  {***************}
  primes1y[1] := 212411;
  primes1y[2] := 200201;
  primes1y[3] := 187987;
  primes1y[4] := 176089;

  primes1y[5] := 163853;
  primes1y[6] := 151729;
  primes1y[7] := 139921;
  primes1y[8] := 139921;

  primes1y[9] := 128203;
  primes1y[10] := 116471;
  primes1y[11] := 104759;
  primes1y[12] := 93199;

  primes1y[13] := 81839;
  primes1y[14] := 70667;
  primes1y[15] := 59377;
  primes1y[16] := 48623;

  {***************}
  { init primes2x }
  {***************}
  primes2x[1] := 54601;
  primes2x[2] := 66923;
  primes2x[3] := 79379;
  primes2x[4] := 92033;

  primes2x[5] := 104743;
  primes2x[6] := 117779;
  primes2x[7] := 130687;
  primes2x[8] := 143879;

  primes2x[9] := 157133;
  primes2x[10] := 170689;
  primes2x[11] := 184043;
  primes2x[12] := 197507;

  primes2x[13] := 210961;
  primes2x[14] := 224743;
  primes2x[15] := 238657;
  primes2x[16] := 143879;

  {***************}
  { init primes2y }
  {***************}
  primes2y[1] := 43913;
  primes2y[2] := 55949;
  primes2y[3] := 68219;
  primes2y[4] := 80657;

  primes2y[5] := 106243;
  primes2y[6] := 132257;
  primes2y[7] := 145459;
  primes2y[8] := 172169;

  primes2y[9] := 198839;
  primes2y[10] := 226267;
  primes2y[11] := 240139;
  primes2y[12] := 253823;

  primes2y[13] := 274583;
  primes2y[14] := 198437;
  primes2y[15] := 96857;
  primes2y[16] := 171233;
end; {procedure Init_primes}


function Supersampling_required(pixel: pixel_type): boolean;
begin
  {Supersampling_required := ss_buffer_ptr^[pixel.v, pixel.h];}
  Supersampling_required := Index_ss_buffer(ss_buffer_ptr, pixel.h, pixel.v)^;
end; {function Supersampling_required}


function Subpixel_placement(pixel: pixel_type;
  index: integer): vector2_type;
var
  vector: vector2_type;
begin
  if (index <= 4) then
    begin
      {*********************************************}
      { place first four rays in their own seperate }
      { quadrants of the pixel to avoid clustering. }
      {*********************************************}
      if (index = 1) then
        begin
          vector.x := pixel.h + (0.25) + jitter2x(pixel, index) * 0.25;
          vector.y := pixel.v + (0.25) + jitter2y(pixel, index) * 0.25;
        end
      else if (index = 2) then
        begin
          vector.x := pixel.h + (0.25) + jitter2x(pixel, index) * 0.25;
          vector.y := pixel.v + jitter2y(pixel, index) * 0.25;
        end
      else if (index = 3) then
        begin
          vector.x := pixel.h + jitter2x(pixel, index) * 0.25;
          vector.y := pixel.v + (0.25) + jitter2y(pixel, index) * 0.25;
        end
      else
        begin
          vector.x := pixel.h + jitter2x(pixel, index) * 0.25;
          vector.y := pixel.v + jitter2y(pixel, index) * 0.25;
        end;
    end
  else
    begin
      {*********************************************}
      { after four samples, scatter rays throughout }
      { the area covered by the pixel.              }
      {*********************************************}
      vector.x := pixel.h + jitter2x(pixel, index);
      vector.y := pixel.v + jitter2y(pixel, index);
    end;
  Subpixel_placement := vector;
end; {function Subpixel_placement}


procedure Init_supersampling;
begin
  ss_buffer_ptr := nil;
  ss_mode := ss_off;
  Init_primes;
end; {procedure Init_supersampling}


end. {module supersampling}
