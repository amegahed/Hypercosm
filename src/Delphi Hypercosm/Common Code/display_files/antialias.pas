unit antialias;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             antialias                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the basic routines for drawing     }
{       antialiased primitives.                                 }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  pixels;


procedure Init_antialias;
procedure Clear_antialias;
procedure Antialias_line(pixel1, pixel2: pixel_type);


implementation
uses
  new_memory, constants, colors, pixel_colors, screen_boxes, display;


const
  memory_alert = false;


type
  alpha_buffer_type = real;
  alpha_buffer_ptr_type = ^alpha_buffer_type;


  {***************************************************}
  { to perform antialiasing of overlapping lines,     }
  { we must choose a method of how to composite them. }
  {***************************************************}
  alpha_mode_type = (alpha_max, alpha_blend);


var
  alpha_buffer_ptr: alpha_buffer_ptr_type;
  alpha_screen_box: screen_box_type;

  {******************}
  { compositing mode }
  {******************}
  alpha_mode: alpha_mode_type;
  background_alpha: real;


procedure Init_antialias;
begin
  {****************************}
  { initialize buffer pointers }
  {****************************}
  alpha_buffer_ptr := nil;
  alpha_mode := alpha_blend;

  if false then
    if (alpha_mode = alpha_blend) then
      begin
        {******************************}
        { need to get pixel values out }
        { of frame buffer to antialias }
        {******************************}
        Set_raster_save_mode(save_on);
      end;
end; {procedure Init_antialias}


{*****************************}
{ routines to show screen_box }
{*****************************}


procedure Draw_screen_box(screen_box: screen_box_type);
var
  pixel: pixel_type;
begin
  with screen_box do
    begin
      pixel := min;
      Move_to(pixel);
      pixel.h := max.h;
      Line_to(pixel);
      pixel.v := max.v;
      Line_to(pixel);
      pixel.h := min.h;
      Line_to(pixel);
      pixel.v := min.v;
      Line_to(pixel);
    end;
end; {procedure Draw_screen_box}


{*********************************************}
{ routines to allocate and clear alpha buffer }
{*********************************************}


function Index_alpha_buffer(alpha_buffer_ptr: alpha_buffer_ptr_type;
  h, v: integer): alpha_buffer_ptr_type;
var
  offset: longint;
begin
  offset := (longint(h) + (longint(v) * longint(window_size.h + 1))) *
    sizeof(alpha_buffer_type);
  Index_alpha_buffer := alpha_buffer_ptr_type(longint(alpha_buffer_ptr) +
    offset);
end; {function Index_alpha_buffer}


procedure Clear_alpha_buffer(clear_alpha: real);
var
  H_counter, V_counter: integer;
  alpha_buffer_size: longint;
  alpha: real;
begin
  {*********************************************}
  { Clear_alpha_buffer uses the screen box to   }
  { clear only that portion of the alpha buffer }
  { which was modified in the last frame.       }
  {*********************************************}
  background_alpha := clear_alpha;
  alpha := -1;

  {***********************}
  { allocate alpha buffer }
  {***********************}
  if alpha_buffer_ptr = nil then
    begin
      alpha_buffer_size := longint(window_size.h + 1) * longint(window_size.v +
        1);
      alpha_buffer_size := alpha_buffer_size * sizeof(alpha_buffer_type);

      if memory_alert then
        writeln('allocating alpha buffer');
      alpha_buffer_ptr := alpha_buffer_ptr_type(New_ptr(alpha_buffer_size));

      {************************************}
      { initialize alpha buffer screen box }
      {************************************}
      with alpha_screen_box do
        begin
          min.h := 0;
          min.v := 0;
          max.h := window_size.h;
          max.v := window_size.v;
        end;
    end;

  {****************************************}
  { clip alpha buffer screen box to window }
  {****************************************}
  with alpha_screen_box do
    begin
      if (min.h < 0) then
        min.h := 0;
      if (min.v < 0) then
        min.v := 0;
      if (max.h > window_size.h) then
        max.h := window_size.h;
      if (max.v > window_size.v) then
        max.v := window_size.v;
    end;

  {Set_color(unit_vector);}
  {Write_screen_box(alpha_screen_box);}
  {Draw_screen_box(alpha_screen_box);}

  {********************************************************}
  { if alpha buffer screen box set then clear alpha buffer }
  {********************************************************}
  with alpha_screen_box do
    if (min.h < max.h) then
      if (min.v < max.v) then
        begin
          {********************}
          { clear alpha buffer }
          {********************}
          for V_counter := min.v to max.v do
            for H_counter := min.h to max.h do
              Index_alpha_buffer(alpha_buffer_ptr, H_counter, V_counter)^ :=
                alpha;

          {*******************************}
          { reset alpha buffer screen box }
          {*******************************}
          min.h := maxint;
          min.v := maxint;
          max.h := -1;
          max.v := -1;
        end;
end; {procedure Clear_alpha_buffer}


function Get_alpha(v, h: integer): real;
var
  alpha: real;
begin
  alpha := Index_alpha_buffer(alpha_buffer_ptr, h, v)^;
  if (alpha = -1) then
    alpha := background_alpha;
  Get_alpha := alpha;
end; {function Get_alpha}


procedure Clear_antialias;
begin
  case alpha_mode of
    alpha_max:
      begin
        Clear_alpha_buffer(0.5);
      end;
    alpha_blend:
      begin
        {Clear_window;}
      end;
  end;
end; {procedure Clear_antialias}


function Sign(i: integer): integer;
var
  temp: integer;
begin
  if (i >= 0) then
    temp := 1
  else
    temp := -1;
  Sign := temp;
end; {function Sign}


procedure Set_pixel(pixel: pixel_type;
  color: color_type;
  alpha: real);
begin
  with pixel do
    begin
      {*********************}
      { add colors together }
      {*********************}
      if (alpha > Get_alpha(v, h)) then
        begin
          Set_color(Intensify_color(color, alpha));
          Draw_pixel(pixel);
        end;
    end;
end; {procedure Set_pixel}


procedure Intensify_pixel(pixel: pixel_type;
  color: color_type;
  alpha: real);
var
  old_color: color_type;
  old_alpha: real;
begin
  with pixel do
    begin
      {*********************}
      { add colors together }
      {*********************}
      old_alpha := 1 - alpha;
      old_color := Pixel_color_to_color(Get_pixel_color(pixel));
      color := Mix_color(Intensify_color(color, alpha),
        Intensify_color(old_color, old_alpha));

      Set_color(color);
      Draw_pixel(pixel);
    end;
end; {procedure Intensify_pixel}


procedure Composite_pixel(pixel: pixel_type;
  color: color_type;
  distance: real);
var
  alpha: real;
begin
  distance := abs(distance);
  if (distance < 1) then
    begin
      {*******************}
      { apply cone filter }
      {*******************}
      {alpha := 1 - distance;}

      {*****************************************}
      { apply cone filter weighted to account   }
      { for non linear monitor response (gamma) }
      {*****************************************}
      alpha := 1 - (distance * distance);

      {*****************}
      { composite pixel }
      {*****************}
      case alpha_mode of
        alpha_max:
          begin
            Set_pixel(pixel, color, alpha);
          end;
        alpha_blend:
          begin
            Intensify_pixel(pixel, color, alpha);
          end;
      end; {case}
    end;
end; {procedure Composite_pixel}


procedure Antialias_line(pixel1, pixel2: pixel_type);
var
  x1, y1: integer;
  x2, y2: integer;
  x, y: integer;
  dx, dy, sx, sy, temp: integer;
  interchange: boolean;
  pixel: pixel_type;
  error: integer;
  i: integer;
  x_intercept, y_intercept: real;
  slope, factor, d: real;
  line_color, color: color_type;
  infinite_slope: boolean;
  xx, yy: real;
begin
  x1 := pixel1.h;
  y1 := pixel1.v;

  x2 := pixel2.h;
  y2 := pixel2.v;

  dx := abs(x2 - x1);
  dy := abs(y2 - y1);
  sx := Sign(x2 - x1);
  sy := Sign(y2 - y1);

  x := x1;
  y := y1;
  Update_screen_box(alpha_screen_box, pixel1);
  Update_screen_box(alpha_screen_box, pixel2);
  line_color := Get_color;

  {*********************************}
  { interchange dx and dy depending }
  { on the slope of the line        }
  {*********************************}
  if (dy > dx) then
    begin
      temp := dx;
      dx := dy;
      dy := temp;
      interchange := true;
    end
  else
    interchange := false;

  {************************************}
  { initialize error term to           }
  { compensate for a nonzero intercept }
  {************************************}
  error := (2 * dy) - dx;
  if (dy <> 0) then
    begin
      infinite_slope := false;
      slope := (dx / dy) * (sx / sy)
    end
  else
    infinite_slope := true;
  xx := dx;
  yy := dy;
  factor := sqrt(sqr(xx) + sqr(yy)) / dx;
  color := Get_color;

  {***********}
  { main loop }
  {***********}
  for i := 0 to dx do
    begin
      if interchange then
        begin
          {***************}
          { vertical line }
          {***************}
          if infinite_slope then
            x_intercept := x1
          else
            x_intercept := ((y - y1) / slope) + x1;

          {**************}
          { center pixel }
          {**************}
          pixel.h := x;
          pixel.v := y;
          d := (x_intercept - pixel.h) * factor;
          Composite_pixel(pixel, color, d);

          {************}
          { left pixel }
          {************}
          pixel.h := x - 1;
          d := (x_intercept - pixel.h) * factor;
          Composite_pixel(pixel, color, d);

          {*************}
          { right pixel }
          {*************}
          pixel.h := x + 1;
          d := (x_intercept - pixel.h) * factor;
          Composite_pixel(pixel, color, d);
        end
      else
        begin
          {*****************}
          { horizontal line }
          {*****************}
          if infinite_slope then
            y_intercept := y1
          else
            y_intercept := ((x - x1) / slope) + y1;

          {**************}
          { center pixel }
          {**************}
          pixel.h := x;
          pixel.v := y;
          d := (y_intercept - pixel.v) * factor;
          Composite_pixel(pixel, color, d);

          {***********}
          { top pixel }
          {***********}
          pixel.v := y - 1;
          d := (y_intercept - pixel.v) * factor;
          Composite_pixel(pixel, color, d);

          {**************}
          { bottom pixel }
          {**************}
          pixel.v := y + 1;
          d := (y_intercept - pixel.v) * factor;
          Composite_pixel(pixel, color, d);
        end;

      while (error > 0) do
        begin
          if interchange then
            begin
              x := x + sx;
            end
          else
            begin
              y := y + sy;
            end;
          error := error - (2 * dx);
        end;

      if interchange then
        begin
          y := y + sy;
        end
      else
        begin
          x := x + sx;
        end;
      error := error + (2 * dy);
    end;
  Set_color(line_color);
end; {procedure Antialias_line}


end. {module antialias}
