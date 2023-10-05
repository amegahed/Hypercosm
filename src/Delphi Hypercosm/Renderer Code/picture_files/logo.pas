unit logo;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm                logo                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module draws the soon to be famous logo:           }
{                                                               }
{                   /-------------------------\                 }
{                   |        |         __     |                 }
{                   |       -O-        /|     |                 }
{                   |        | \      /       |                 }
{                   |           \    /        |                 }
{                   |            \  /         |                 }
{                   |             \/          |                 }
{                   \-------------------------/                 }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface


var
  logo_antialiased: boolean;


procedure Init_logo;
procedure Draw_logo;


implementation
uses
  constants, trigonometry, vectors2, trans2, colors, pixels, display, antialias;


const
  drawing_size = 100;


type
  drawing_kind_type = (move, draw, line, rect, change_color);
  drawing_type = record
    case kind: drawing_kind_type of
      move, draw: (
        pixel: pixel_type;
        );
      line, rect: (
        pixel1, pixel2: pixel_type;
        );
      change_color: (
        color: color_type;
        );
  end;


var
  logo_initialized: boolean;
  logo_width: integer;
  logo_height: integer;
  drawing_number: integer;
  drawing_array: array[1..drawing_size] of drawing_type;


procedure Init_logo;
begin
  logo_initialized := false;
  logo_antialiased := false;
end; {procedure Init_logo}


procedure Display_logo;
var
  counter: integer;
begin
  for counter := 1 to drawing_number do
    with drawing_array[counter] do
      case kind of

        move:
          Move_to(pixel);

        draw:
          Line_to(pixel);

        line:
          Draw_line(pixel1, pixel2);

        rect:
          Draw_rect(pixel1, pixel2);

        change_color:
          Set_color(color);

      end; {case}
end; {procedure Display_logo}


procedure Display_antialiased_logo;
var
  counter: integer;
  previous_pixel: pixel_type;
begin
  for counter := 1 to drawing_number do
    with drawing_array[counter] do
      case kind of

        move:
          previous_pixel := pixel;

        draw:
          begin
            Antialias_line(previous_pixel, pixel);
            previous_pixel := pixel;
          end;

        line:
          Antialias_line(pixel1, pixel2);

        rect:
          Draw_rect(pixel1, pixel2);

        change_color:
          Set_color(color);

      end; {case}
end; {procedure Display_antialiased_logo}


procedure Set_logo_color(new_color: color_type);
begin
  drawing_number := drawing_number + 1;
  with drawing_array[drawing_number] do
    begin
      kind := change_color;
      color := new_color;
    end;
end; {procedure Set_logo_color}


function Vector_to_pixel(vertex: vector2_type): pixel_type;
var
  pixel: pixel_type;
begin
  pixel.h := window_center.h + Trunc(vertex.x * window_size.h / 2);
  pixel.v := window_center.v - Trunc(vertex.y * window_size.v / 2);
  Vector_to_pixel := pixel;
end; {function Vector_to_pixel}


procedure Plot_2d_line(X1, Y1, X2, Y2: real;
  trans: trans2_type);
var
  vertex1, vertex2: vector2_type;
begin
  vertex1.x := X1;
  vertex1.y := Y1;
  vertex2.x := X2;
  vertex2.y := Y2;
  Transform_point2(vertex1, trans);
  Transform_point2(vertex2, trans);

  drawing_number := drawing_number + 1;
  with drawing_array[drawing_number] do
    begin
      kind := line;
      pixel1 := Vector_to_pixel(vertex1);
      pixel2 := Vector_to_pixel(vertex2);
    end;
  {Draw_line(pixel1, pixel2);}
end; {procedure Plot_2d_line}


procedure Draw_logo_rect(X1, Y1, X2, Y2: real;
  trans: trans2_type);
var
  vertex1, vertex2: vector2_type;
begin
  vertex1.x := X1;
  vertex1.y := Y1;
  vertex2.x := X2;
  vertex2.y := Y2;
  Transform_point2(vertex1, trans);
  Transform_point2(vertex2, trans);

  drawing_number := drawing_number + 1;
  with drawing_array[drawing_number] do
    begin
      kind := rect;
      pixel1 := Vector_to_pixel(vertex1);
      pixel2 := Vector_to_pixel(vertex2);
    end;
  {Draw_line(pixel1, pixel2);}
end; {procedure Draw_logo_rect}


procedure Draw_2d_to(x, y: real;
  trans: trans2_type);
var
  vertex: vector2_type;
begin
  vertex.x := x;
  vertex.y := y;
  Transform_point2(vertex, trans);

  drawing_number := drawing_number + 1;
  with drawing_array[drawing_number] do
    begin
      kind := draw;
      pixel := Vector_to_pixel(vertex);
    end;
  {Line_to(pixel);}
end; {procedure Draw_2d_to}


procedure Move_2d_to(x, y: real;
  trans: trans2_type);
var
  vertex: vector2_type;
begin
  vertex.x := x;
  vertex.y := y;
  Transform_point2(vertex, trans);

  drawing_number := drawing_number + 1;
  with drawing_array[drawing_number] do
    begin
      kind := move;
      pixel := Vector_to_pixel(vertex);
    end;
  {Move_to(pixel);}
end; {procedure Move_2d_to}


function Intersect(point1, direction1: vector2_type;
  point2, direction2: vector2_type): vector2_type;
var
  diff, point: vector2_type;
  t: real;
begin
  diff := Vector2_difference(point2, point1);
  t := ((direction1.y * diff.x) - (direction1.x * diff.y)) / ((direction1.x *
    direction2.y) - (direction1.y * direction2.x));
  point := Vector2_sum(point1, Vector2_scale(direction1, t));
  Intersect := point;
end; {function Intersect}


procedure Draw_arc(X1, Y1, X2, Y2, X3, Y3: real;
  trans: trans2_type;
  steps: integer);
var
  point1, point2, point3: vector2_type;
  bisector1, bisector2: vector2_type;
  direction1, direction2: vector2_type;
  center: vector2_type;
  angle, start_angle, end_angle, step_angle, radius: real;
  counter: integer;
begin
  {************************************************}
  { There's some obscure geometry theorem which    }
  { says that any three points determines a circle }
  { This routine draws an arc from the first to    }
  { the last of these three determining points.    }
  {************************************************}
  point1.x := X1;
  point1.y := Y1;
  point2.x := X2;
  point2.y := Y2;
  point3.x := X3;
  point3.y := Y3;

  bisector1 := Vector2_scale(Vector2_sum(point1, point2), 0.5);
  direction1 := Self_perpendicular2(Vector2_difference(point1, point2));
  bisector2 := Vector2_scale(Vector2_sum(point2, point3), 0.5);
  direction2 := Self_perpendicular2(Vector2_difference(point2, point3));
  center := Intersect(bisector1, direction1, bisector2, direction2);
  radius := Vector2_length(Vector2_difference(center, point1));

  start_angle := Atan2((point1.y - center.y), (point1.x - center.x));
  end_angle := Atan2((point3.y - center.y), (point3.x - center.x));

  if ((point1.y >= center.y) and (point3.y >= center.y)) or ((point1.y <=
    center.y) and (point3.y <= center.y)) then
    begin
      angle := end_angle - start_angle;
    end
  else
    begin
      if (point2.x >= 0) then
        begin
          {*******************}
          { quadrants 1 and 4 }
          {*******************}
          if (point1.y > 0) then
            angle := -(start_angle + (two_pi - end_angle))
          else
            angle := end_angle + (two_pi - start_angle);
        end
      else
        {*******************}
        { quadrants 2 and 3 }
        {*******************}
        angle := end_angle - start_angle;
    end;
  step_angle := angle / steps;

  angle := start_angle;
  point1.x := center.x + (cos(angle) * radius);
  point1.y := center.y + (sin(angle) * radius);
  Move_2d_to(point1.x, point1.y, trans);
  for counter := 1 to steps do
    begin
      angle := angle + step_angle;
      point1.x := center.x + (cos(angle) * radius);
      point1.y := center.y + (sin(angle) * radius);
      Draw_2d_to(point1.x, point1.y, trans);
    end;
end; {procedure Draw_arc}


procedure Draw_circle(trans: trans2_type;
  steps: integer);
var
  counter: integer;
  angle: real;
begin
  Move_2d_to(1, 0, trans);
  for counter := 1 to steps do
    begin
      angle := counter / steps * (2 * pi);
      Draw_2d_to(cos(angle), sin(angle), trans);
    end;
end; {procedure Draw_circle}


procedure Draw_A(trans: trans2_type);
begin
  Plot_2d_line(-1, -1, 0, 1, trans);
  Draw_2d_to(1, -1, trans);
  Plot_2d_line(-0.75, -0.5, 0.75, -0.5, trans);
end; {procedure Draw_A}


procedure Draw_R(trans: trans2_type);
var
  circle_axes: trans2_type;
begin
  Plot_2d_line(-1, 1, -1, -1, trans);
  Plot_2d_line(0, 0, 1, -1, trans);
  circle_axes.origin.x := 0;
  circle_axes.origin.y := 0.5;
  circle_axes.x_axis.x := 1;
  circle_axes.x_axis.y := 0;
  circle_axes.y_axis.x := 0;
  circle_axes.y_axis.y := 0.5;
  Transform_trans2(circle_axes, trans);
  Draw_circle(circle_axes, 18);
end; {procedure Draw_R}


procedure Draw_T(trans: trans2_type);
begin
  Plot_2d_line(-1, 1, 1, 1, trans);
  Plot_2d_line(0, 1, 0, -1, trans);
end; {procedure Draw_T}


procedure Draw_S(trans: trans2_type);
var
  val: real;
  a, b: real;
begin
  Plot_2d_line(-0.5, -1, 0.5, -1, trans);
  Plot_2d_line(0.5, 0.125, -0.5, 0.125, trans);
  Plot_2d_line(-0.5, 1, 0.5, 1, trans);
  a := 0.35;
  b := 1 - a;
  val := sin(pi / 4.0) * a;

  Draw_arc(0.5, -1, 1, -0.5, 0.5, 0.125, trans, 4);
  Draw_arc(-0.5, 0.125, -1, 0.5, -0.5, 1, trans, 4);

  { top serif }
  {Draw_arc(b, 1, b + val, b + val, 1, b, trans, 4);}

  { bottom serif }
  Draw_arc(-1, -b, -b - val, -b - val, -b, -1.0, trans, 3);
end; {procedure Draw_S}


procedure Draw_squiggle(trans: trans2_type);
const
  a = 0.65;
  b = 0.35;
  c = 0;
var
  val: real;
begin
  {Plot_2d_line(-0.5, -1, 0.5, -1, trans);}
  Plot_2d_line(0.5, c, -0.5, c, trans);
  {Plot_2d_line(-0.5, 1, 0.5, 1, trans);}
  val := sin(pi / 4.0) * a;

  {Draw_arc(-1, -b, -b - val, -b - val, -b, -1.0, trans, 2);}
  Draw_arc(0.5, -1, 1, -0.5, 0.5, c, trans, 4);
  Draw_arc(-0.5, c, -1, 0.5, -0.5, 1, trans, 4);
  {Draw_arc(b, 1, b + val, b + val, 1, b, trans, 4);}
end; {procedure Draw_squiggle}


procedure Draw_star(trans: trans2_type);
begin
  Plot_2d_line(-1, 0, 1, 0, trans);
  Plot_2d_line(0, -1, 0, 1, trans);
  Plot_2d_line(-1, -1, 1, 1, trans);
  Plot_2d_line(1, -1, -1, 1, trans);
end; {procedure Draw_star}


procedure Draw_C(trans: trans2_type);
const
  a = 0.6;
  b = 0.4;
begin
  Plot_2d_line(1, a, b, 1, trans);
  Plot_2d_line(b, 1, -b, 1, trans);
  Plot_2d_line(-b, 1, -1, a, trans);
  Plot_2d_line(-1, a, -1, -a, trans);
  Plot_2d_line(-1, -a, -b, -1, trans);
  Plot_2d_line(-b, -1, b, -1, trans);
  Plot_2d_line(b, -1, 1, -a, trans);
end; {procedure Draw_C}


procedure Draw_M(trans: trans2_type);
begin
  Plot_2d_line(-1, -1, -1, 1, trans);
  Plot_2d_line(-1, 1, 0, 0, trans);
  Plot_2d_line(0, 0, 1, 1, trans);
  Plot_2d_line(1, 1, 1, -1, trans);
end; {procedure Draw_M}


procedure Draw_box(trans: trans2_type);
begin
  Move_2d_to(-1, -1, trans);
  Draw_2d_to(1, -1, trans);
  Draw_2d_to(1, 1, trans);
  Draw_2d_to(-1, 1, trans);
  Draw_2d_to(-1, -1, trans);
end; {procedure Draw_box}


procedure Draw_ART_logo;
var
  logo_axes, trans: trans2_type;
begin
  logo_axes.origin.x := 0;
  logo_axes.origin.y := 0;
  logo_axes.x_axis.x := 0.8;
  logo_axes.x_axis.y := 0;
  logo_axes.y_axis.x := 0;
  logo_axes.y_axis.y := 0.8;

  logo_axes.origin.x := -0.85;
  logo_axes.origin.y := -0.85;
  logo_axes.x_axis.x := 0.1;
  logo_axes.x_axis.y := 0;
  logo_axes.y_axis.x := 0;
  logo_axes.y_axis.y := 0.1;

  Set_logo_color(black_color);
  Draw_logo_rect(-1, 1, 1, -1, logo_axes);

  Set_logo_color(white_color);
  Draw_box(logo_axes);

  logo_axes.origin.x := -0.85;
  logo_axes.origin.y := -0.85;
  logo_axes.x_axis.x := 0.095;
  logo_axes.x_axis.y := 0;
  logo_axes.y_axis.x := 0;
  logo_axes.y_axis.y := 0.095;
  Set_logo_color(white_color);
  Draw_circle(logo_axes, 12);

  {*******************************}
  { horizontal and vertical lines }
  {*******************************}
  Plot_2d_line(-1, 0, 1, 0, logo_axes);
  Plot_2d_line(0, 0, 0, 1, logo_axes);

  {*************************}
  { draw bouncing light ray }
  {*************************}
  Set_logo_color(yellow_color);
  Plot_2d_line(-0.5, 0.5, 0, 0, logo_axes);
  Plot_2d_line(0.5, 0.5, 0, 0, logo_axes);

  {*****************}
  { draw arrow head }
  {*****************}
  Plot_2d_line(0.5, 0.5, 0.3, 0.5, logo_axes);
  Plot_2d_line(0.5, 0.5, 0.5, 0.3, logo_axes);

  {*******************}
  { draw light source }
  {*******************}
  { trans.origin.x := -0.5; trans.origin.y := 0.5;}
  { trans.x_axis.x := 0.1; trans.x_axis.y := 0;}
  { trans.y_axis.x := 0; trans.y_axis.y := 0.1; }
  { Transform_axes_from_axes2(trans, logo_axes);}
  { Draw_circle(trans, 8);}
  { }
  Plot_2d_line(-0.35, 0.5, -0.65, 0.5, logo_axes);
  Plot_2d_line(-0.5, 0.65, -0.5, 0.35, logo_axes);
  Plot_2d_line(-0.4, 0.6, -0.6, 0.4, logo_axes);
  Plot_2d_line(-0.4, 0.4, -0.6, 0.6, logo_axes);

  {**************}
  { draw letters }
  {**************}
  Set_logo_color(red_color);
  trans.origin.x := -0.5;
  trans.origin.y := -0.4;
  trans.x_axis.x := 0.125;
  trans.x_axis.y := 0;
  trans.y_axis.x := 0;
  trans.y_axis.y := 0.2;
  Transform_trans2(trans, logo_axes);
  Draw_A(trans);

  Set_logo_color(green_color);
  trans.origin.x := 0;
  trans.origin.y := -0.4;
  trans.x_axis.x := 0.125;
  trans.x_axis.y := 0;
  trans.y_axis.x := 0;
  trans.y_axis.y := 0.2;
  Transform_trans2(trans, logo_axes);
  Draw_R(trans);

  Set_logo_color(blue_color);
  trans.origin.x := 0.5;
  trans.origin.y := -0.4;
  trans.x_axis.x := 0.125;
  trans.x_axis.y := 0;
  trans.y_axis.x := 0;
  trans.y_axis.y := 0.2;
  Transform_trans2(trans, logo_axes);
  Draw_T(trans);

  if false then
    begin
      Set_logo_color(red_color);
      trans.origin.x := -0.25;
      trans.origin.y := -0.4;
      trans.x_axis.x := 0.125;
      trans.x_axis.y := 0;
      trans.y_axis.x := 0;
      trans.y_axis.y := 0.2;
      Transform_trans2(trans, logo_axes);
      Draw_S(trans);

      Set_logo_color(green_color);
      trans.origin.x := 0.5;
      trans.origin.y := -0.4;
      trans.x_axis.x := 0.125;
      trans.x_axis.y := 0;
      trans.y_axis.x := 0;
      trans.y_axis.y := 0.2;
      Transform_trans2(trans, logo_axes);
      Draw_M(trans);
    end;
end; {procedure Draw_ART_logo}


procedure Draw_shazam_logo;
var
  logo_axes: trans2_type;
begin
  logo_axes.origin.x := 0;
  logo_axes.origin.y := 0;
  logo_axes.x_axis.x := 0.8;
  logo_axes.x_axis.y := 0;
  logo_axes.y_axis.x := 0;
  logo_axes.y_axis.y := 0.8;

  logo_axes.origin.x := -0.85;
  logo_axes.origin.y := -0.85;
  logo_axes.x_axis.x := 0.1;
  logo_axes.x_axis.y := 0;
  logo_axes.y_axis.x := 0;
  logo_axes.y_axis.y := 0.1;

  Set_logo_color(black_color);
  Draw_logo_rect(-1, 1, 1, -1, logo_axes);

  Set_logo_color(white_color);
  Draw_box(logo_axes);

  Set_logo_color(red_color);
  Draw_circle(logo_axes, 12);

  Set_logo_color(yellow_color);
  Move_2d_to(0.0, 0.8, logo_axes);
  Draw_2d_to(0.3, 0.8, logo_axes);
  Draw_2d_to(0.0, 0.2, logo_axes);
  Draw_2d_to(0.4, 0.2, logo_axes);
  Draw_2d_to(-0.3, -0.8, logo_axes);
  Draw_2d_to(0.0, 0.0, logo_axes);
  Draw_2d_to(-0.4, 0.0, logo_axes);
  Draw_2d_to(0.0, 0.8, logo_axes);
end; {procedure Draw_shazam_logo}


procedure Draw_MCM_logo;
var
  logo_axes, trans: trans2_type;
begin
  logo_axes.origin.x := 0;
  logo_axes.origin.y := 0;
  logo_axes.x_axis.x := 0.8;
  logo_axes.x_axis.y := 0;
  logo_axes.y_axis.x := 0;
  logo_axes.y_axis.y := 0.8;

  logo_axes.origin.x := -0.85;
  logo_axes.origin.y := -0.85;
  logo_axes.x_axis.x := 0.1;
  logo_axes.x_axis.y := 0;
  logo_axes.y_axis.x := 0;
  logo_axes.y_axis.y := 0.1;

  Set_logo_color(black_color);
  Draw_logo_rect(-1, 1, 1, -1, logo_axes);

  Set_logo_color(white_color);
  Draw_box(logo_axes);
  Plot_2d_line(-1, -(1 / 3), 1, -(1 / 3), logo_axes);

  {*************}
  { draw galaxy }
  {*************}
  Set_logo_color(cyan_color);
  trans.origin.x := 0;
  trans.origin.y := (1 / 3);
  trans.x_axis.x := 0.75 * 0.666;
  trans.x_axis.y := 0;
  trans.y_axis.x := 0;
  trans.y_axis.y := (2 / 3) * 0.666;
  Transform_trans2(trans, logo_axes);
  Draw_squiggle(trans);

  Set_logo_color(yellow_color);
  trans.origin.x := 0;
  trans.origin.y := (1 / 3);
  trans.x_axis.x := 0.1;
  trans.x_axis.y := 0;
  trans.y_axis.x := 0;
  trans.y_axis.y := 0.1;
  Transform_trans2(trans, logo_axes);
  Draw_circle(trans, 4);

  {************}
  { draw stars }
  {************}
  Set_logo_color(cyan_color);
  trans.origin.x := -0.5;
  trans.origin.y := (1 / 3) - 0.25;
  trans.x_axis.x := 0.1;
  trans.x_axis.y := 0;
  trans.y_axis.x := 0;
  trans.y_axis.y := 0.1;
  Transform_trans2(trans, logo_axes);
  Draw_star(trans);

  trans.origin.x := 0.5;
  trans.origin.y := (1 / 3) + 0.25;
  trans.x_axis.x := 0.1;
  trans.x_axis.y := 0;
  trans.y_axis.x := 0;
  trans.y_axis.y := 0.1;
  Transform_trans2(trans, logo_axes);
  Draw_star(trans);

  {**************}
  { draw letters }
  {**************}
  Set_logo_color(red_color);
  trans.origin.x := -0.5;
  trans.origin.y := -0.666;
  trans.x_axis.x := 0.125;
  trans.x_axis.y := 0;
  trans.y_axis.x := 0;
  trans.y_axis.y := 0.2;
  Transform_trans2(trans, logo_axes);
  Draw_M(trans);

  Set_logo_color(green_color);
  trans.origin.x := 0;
  trans.origin.y := -0.666;
  trans.x_axis.x := 0.125;
  trans.x_axis.y := 0;
  trans.y_axis.x := 0;
  trans.y_axis.y := 0.2;
  Transform_trans2(trans, logo_axes);
  Draw_C(trans);

  Set_logo_color(To_color(0, 0.5, 1));
  trans.origin.x := 0.5;
  trans.origin.y := -0.666;
  trans.x_axis.x := 0.125;
  trans.x_axis.y := 0;
  trans.y_axis.x := 0;
  trans.y_axis.y := 0.2;
  Transform_trans2(trans, logo_axes);
  Draw_M(trans);
end; {procedure Draw_MCM_logo}


procedure Draw_SST_logo;
var
  logo_axes, trans: trans2_type;
  aspect_ratio: real;
begin
  logo_axes.origin.x := 0;
  logo_axes.origin.y := 0;
  logo_axes.x_axis.x := 0.8;
  logo_axes.x_axis.y := 0;
  logo_axes.y_axis.x := 0;
  logo_axes.y_axis.y := 0.8;

  logo_axes.origin.x := -0.85;
  logo_axes.origin.y := -0.85;
  logo_axes.x_axis.x := 0.1;
  logo_axes.x_axis.y := 0;
  logo_axes.y_axis.x := 0;
  logo_axes.y_axis.y := 0.1;

  Set_logo_color(black_color);
  Draw_logo_rect(-1, 1, 1, -1, logo_axes);

  Set_logo_color(white_color);
  Draw_box(logo_axes);

  logo_axes.origin.x := -0.85;
  logo_axes.origin.y := -0.85;
  logo_axes.x_axis.x := 0.095;
  logo_axes.x_axis.y := 0;
  logo_axes.y_axis.x := 0;
  logo_axes.y_axis.y := 0.095;

  aspect_ratio := window_size.v / window_size.h;

  {*****************}
  { draw shock wave }
  {*****************}
  Set_logo_color(cyan_color);
  Plot_2d_line(-0.5, 0, 1.0, 1.0, logo_axes);
  Plot_2d_line(-0.5, 0, 1.0, -1.0, logo_axes);

  {********************}
  { draw sonic circles }
  {********************}
  Set_logo_color(red_color);
  trans.origin.x := 0 - 0.1;
  trans.origin.y := 0;
  trans.x_axis.x := 0.5 * 0.333 * aspect_ratio;
  trans.x_axis.y := 0;
  trans.y_axis.x := 0;
  trans.y_axis.y := 0.5 * (1 / 3);
  Transform_trans2(trans, logo_axes);
  Draw_circle(trans, 8);

  Set_logo_color(green_color);
  trans.origin.x := 0.333 - 0.1;
  trans.origin.y := 0;
  trans.x_axis.x := 0.5 * 0.666 * aspect_ratio;
  trans.x_axis.y := 0;
  trans.y_axis.x := 0;
  trans.y_axis.y := 0.5 * 0.666;
  Transform_trans2(trans, logo_axes);
  Draw_circle(trans, 8);

  Set_logo_color(To_color(0, 0.5, 1));
  trans.origin.x := 0.666 - 0.1;
  trans.origin.y := 0;
  trans.x_axis.x := 0.5 * aspect_ratio;
  trans.x_axis.y := 0;
  trans.y_axis.x := 0;
  trans.y_axis.y := 0.5;
  Transform_trans2(trans, logo_axes);
  Draw_circle(trans, 8);

  {********************}
  { draw vertical line }
  {********************}
  Set_logo_color(white_color);
  Plot_2d_line(-0.5, -1, -0.5, 1, logo_axes);

  {**************}
  { draw letters }
  {**************}
  Set_logo_color(red_color);
  trans.origin.x := -0.75;
  trans.origin.y := 0.666;
  trans.x_axis.x := 0.125;
  trans.x_axis.y := 0;
  trans.y_axis.x := 0;
  trans.y_axis.y := 0.2;
  Transform_trans2(trans, logo_axes);
  Draw_S(trans);

  Set_logo_color(green_color);
  trans.origin.x := -0.75;
  trans.origin.y := 0;
  trans.x_axis.x := 0.125;
  trans.x_axis.y := 0;
  trans.y_axis.x := 0;
  trans.y_axis.y := 0.2;
  Transform_trans2(trans, logo_axes);
  Draw_S(trans);

  Set_logo_color(cyan_color);
  trans.origin.x := -0.75;
  trans.origin.y := -0.666;
  trans.x_axis.x := 0.125;
  trans.x_axis.y := 0;
  trans.y_axis.x := 0;
  trans.y_axis.y := 0.2;
  Transform_trans2(trans, logo_axes);
  Draw_T(trans);
end; {procedure Draw_SST_logo}


procedure Draw_logo;
var
  window_changed: boolean;
begin
  window_changed := (logo_width <> window_size.h) or (logo_height <>
    window_size.v);

  if not logo_initialized or window_changed then
    begin
      drawing_number := 0;
      logo_initialized := true;
      logo_width := window_size.h;
      logo_height := window_size.v;

      {Draw_ART_logo; }
      {Draw_shazam_logo;}
      {Draw_MCM_logo;}
      {Draw_SST_logo;}

      Draw_SST_logo;
    end;

  if logo_antialiased then
    Display_antialiased_logo
  else
    Display_logo;
end; {procedure Draw_logo}


end. {module logo}
