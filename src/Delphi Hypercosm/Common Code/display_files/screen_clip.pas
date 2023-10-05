unit screen_clip;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            screen_clip                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to perform two            }
{       dimensional clipping with the window.                   }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  pixels, screen_boxes;


procedure Clip_line_to_screen_box(var pixel1, pixel2: pixel_type;
  var line_exists: boolean;
  screen_box: screen_box_type);
procedure Clip_block_to_screen_box(var pixel1, pixel2: pixel_type;
  var block_exists: boolean;
  screen_box: screen_box_type);


implementation


type
  edge_type = (left_edge, right_edge, bottom_edge, top_edge);
  clip_code_type = set of edge_type;


procedure Top(var a1, b1, dx, dy: integer;
  max: integer);
begin
  a1 := a1 + (dx * (max - b1)) div dy;
  b1 := max;
end; {procedure Top}


procedure Bottom(var a1, b1, dx, dy: integer;
  min: integer);
begin
  a1 := a1 + (-(dx * (b1 - min)) div dy);
  b1 := min
end; {procedure Bottom}


procedure Right(var a1, b1, dx, dy: integer;
  max: integer);
begin
  b1 := b1 + (dy * (max - a1)) div dx;
  a1 := max;
end; {procedure Right}


procedure Left(var a1, b1, dx, dy: integer;
  min: integer);
begin
  b1 := b1 + (-(dy * (a1 - min)) div dx);
  a1 := min;
end; {procedure Left}


procedure Set_clip_code(var clip_code: clip_code_type;
  pixel, min, max: pixel_type);
begin
  clip_code := [];

  if (pixel.h < min.h) then
    clip_code := clip_code + [left_edge];

  if (pixel.h > max.h) then
    clip_code := clip_code + [right_edge];

  if (pixel.v < min.v) then
    clip_code := clip_code + [bottom_edge];

  if (pixel.v > max.v) then
    clip_code := clip_code + [top_edge];
end; {procedure Set_clip_code}


procedure Clip_line_to_screen_box(var pixel1, pixel2: pixel_type;
  var line_exists: boolean;
  screen_box: screen_box_type);
var
  a1, b1, a2, b2, dx, dy: integer;
  clip_code1, clip_code2: clip_code_type;
  clip_union, clip_intersection: clip_code_type;
  min, max: pixel_type;
begin
  a1 := pixel1.h;
  b1 := pixel1.v;
  a2 := pixel2.h;
  b2 := pixel2.v;

  min := screen_box.min;
  max.h := screen_box.max.h - 1;
  max.v := screen_box.max.v - 1;

  Set_clip_code(clip_code1, pixel1, min, max);
  Set_clip_code(clip_code2, pixel2, min, max);
  clip_union := clip_code1 + clip_code2;
  clip_intersection := clip_code1 * clip_code2;

  if (clip_union = []) then
    begin
      {*************************}
      { line completely visible }
      {*************************}
      line_exists := true;
    end
  else if (clip_intersection = []) then
    begin
      {***************************}
      { line is partially visible }
      {***************************}
      dx := a2 - a1;
      dy := b2 - b1;

      if (a1 < min.h) then
        Left(a1, b1, dx, dy, min.h)
      else if (a1 > max.h) then
        Right(a1, b1, dx, dy, max.h);

      if (b1 < min.v) then
        Bottom(a1, b1, dx, dy, min.v)
      else if (b1 > max.v) then
        Top(a1, b1, dx, dy, max.v);

      if (a2 < min.h) then
        Left(a2, b2, dx, dy, min.h)
      else if (a2 > max.h) then
        Right(a2, b2, dx, dy, max.h);

      if (b2 < min.v) then
        Bottom(a2, b2, dx, dy, min.v)
      else if (b2 > max.v) then
        Top(a2, b2, dx, dy, max.v);

      pixel1.h := a1;
      pixel1.v := b1;
      pixel2.h := a2;
      pixel2.v := b2;

      {**********************}
      { recompute clip codes }
      {**********************}
      Set_clip_code(clip_code1, pixel1, min, max);
      Set_clip_code(clip_code2, pixel2, min, max);
      clip_union := clip_code1 + clip_code2;
      line_exists := (clip_union = []);
    end
  else
    begin
      {******************************}
      { line is completely invisible }
      {******************************}
      line_exists := false;
    end;
end; {procedure Clip_line_to_screen_box}


function Clip_line_to_edge(denominator, numerator: integer;
  var t_entering, t_leaving: real;
  edge: edge_type;
  var entering_edge, leaving_edge: edge_type): boolean;
var
  t: real;
  line_exists: boolean;
begin
  line_exists := true;

  if (denominator > 0) then
    begin
      {****************************}
      { an 'entering' intersection }
      {****************************}
      t := numerator / denominator;

      if (t > t_leaving) then
        {***************************************}
        { entering and leaving points crossover }
        {***************************************}
        line_exists := false
      else if (t > t_entering) then
        begin
          {**************************}
          { found new entering point }
          {**************************}
          t_entering := t;
          entering_edge := edge;
        end;
    end
  else if (denominator < 0) then
    begin
      {**************************}
      { a 'leaving' intersection }
      {**************************}
      t := numerator / denominator;

      if (t < t_entering) then
        {***************************************}
        { entering and leaving points crossover }
        {***************************************}
        line_exists := false
      else if (t < t_leaving) then
        begin
          {*************************}
          { found new leaving point }
          {*************************}
          t_leaving := t;
          leaving_edge := edge;
        end;
    end
  else if (numerator > 0) then
    begin
      {*****************************}
      { line on the outside of edge }
      {*****************************}
      line_exists := false;
    end;

  Clip_line_to_edge := line_exists;
end; {function Clip_line_to_edge}


procedure Clip_line_to_screen_box2(var pixel1, pixel2: pixel_type;
  var line_exists: boolean;
  screen_box: screen_box_type);
var
  t_entering, t_leaving: real;
  entering_edge, leaving_edge: edge_type;
  min, max: pixel_type;
  delta: pixel_type;
begin
  delta.h := pixel2.h - pixel1.h;
  delta.v := pixel2.v - pixel1.v;

  if (delta.h = 0) and (delta.v = 0) then
    line_exists := Pixel_in_screen_box(pixel1, screen_box)
  else
    begin
      t_entering := 0;
      t_leaving := 1;
      line_exists := false;

      min := screen_box.min;
      max.h := screen_box.max.h - 1;
      max.v := screen_box.max.v - 1;

      {***********}
      { left edge }
      {***********}
      if Clip_line_to_edge(delta.h, (min.h - pixel1.h), t_entering, t_leaving,
        left_edge, entering_edge, leaving_edge) then

        {************}
        { right edge }
        {************}
        if Clip_line_to_edge(-delta.h, (pixel1.h - max.h), t_entering,
          t_leaving, right_edge, entering_edge, leaving_edge) then

          {*************}
          { bottom edge }
          {*************}
          if Clip_line_to_edge(delta.v, (min.v - pixel1.v), t_entering,
            t_leaving, bottom_edge, entering_edge, leaving_edge) then

            {**********}
            { top edge }
            {**********}
            if Clip_line_to_edge(-delta.v, (pixel1.v - max.v), t_entering,
              t_leaving, top_edge, entering_edge, leaving_edge) then
              begin
                line_exists := true;

                if (t_leaving < 1) then
                  begin
                    {************************************}
                    { compute new 'leaving' intersection }
                    {************************************}
                    case leaving_edge of
                      left_edge:
                        begin
                          pixel2.h := min.h;
                          pixel2.v := pixel1.v + Trunc(t_leaving * delta.v);
                        end;
                      right_edge:
                        begin
                          pixel2.h := max.h;
                          pixel2.v := pixel1.v + Trunc(t_leaving * delta.v);
                        end;
                      bottom_edge:
                        begin
                          pixel2.h := pixel1.h + Trunc(t_leaving * delta.h);
                          pixel2.v := min.v;
                        end;
                      top_edge:
                        begin
                          pixel2.h := pixel1.h + Trunc(t_leaving * delta.h);
                          pixel2.v := max.v;
                        end;
                    end;

                  end
                else if (t_entering > 0) then
                  begin
                    {*************************************}
                    { compute new 'entering' intersection }
                    {*************************************}
                    case entering_edge of
                      left_edge:
                        begin
                          pixel1.h := min.h;
                          pixel1.v := pixel1.v + round(t_entering * delta.v);
                        end;
                      right_edge:
                        begin
                          pixel1.h := max.h;
                          pixel1.v := pixel1.v + round(t_entering * delta.v);
                        end;
                      bottom_edge:
                        begin
                          pixel1.h := pixel1.h + round(t_entering * delta.h);
                          pixel1.v := min.v;
                        end;
                      top_edge:
                        begin
                          pixel1.h := pixel1.h + round(t_entering * delta.h);
                          pixel1.v := max.v;
                        end;
                    end;

                  end;
              end;
    end;
end; {procedure Clip_line_to_screen_box2}


procedure Clip_block_to_screen_box(var pixel1, pixel2: pixel_type;
  var block_exists: boolean;
  screen_box: screen_box_type);
var
  min, max: pixel_type;
begin
  min := screen_box.min;
  max := screen_box.max;
  block_exists := true;

  if (pixel1.h < min.h) then
    pixel1.h := min.h
  else if (pixel1.h > max.h) then
    pixel1.h := max.h;
  if (pixel2.h < min.h) then
    pixel2.h := min.h
  else if (pixel2.h > max.h) then
    pixel2.h := max.h;

  if (pixel1.v < min.v) then
    pixel1.v := min.v
  else if (pixel1.v > max.v) then
    pixel1.v := max.v;
  if (pixel2.v < min.v) then
    pixel2.v := min.v
  else if (pixel2.v > max.v) then
    pixel2.v := max.v;

  if (pixel1.h = pixel2.h) then
    begin
      if (pixel1.h = min.h) or (pixel1.h = max.h) then
        block_exists := false;
    end
  else if (pixel1.v = pixel2.v) then
    begin
      if (pixel1.v = min.v) or (pixel1.v = max.v) then
        block_exists := false;
    end;
end; {procedure Clip_block_to_screen_box}


end.
