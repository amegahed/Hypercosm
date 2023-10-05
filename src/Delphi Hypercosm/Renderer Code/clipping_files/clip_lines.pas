unit clip_lines;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             clip_lines                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module provides routines for clipping lines        }
{       to a variety of simple regions.                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, clip_planes, clip_regions;


type
  line_type = record
    point1, point2: vector_type;
  end; {line_type}


  {********************************}
  { methods for constructing lines }
  {********************************}
function To_line(point1, point2: vector_type): line_type;

{***********************}
{ methods to clip lines }
{***********************}
procedure Clip_line_to_plane(var line: line_type;
  var clipped1, clipped2: boolean;
  var t: real;
  plane: plane_type);
procedure Clip_line_to_origin_plane(var line: line_type;
  var clipped1, clipped2: boolean;
  var t: real;
  normal: vector_type);
procedure Clip_line_to_frustrum(var line: line_type;
  var line_exists: boolean;
  var clipped1, clipped2: boolean;
  frustrum: frustrum_type);
procedure Clip_line_to_anti_frustrum(var line1, line2: line_type;
  var line1_exists, line2_exists: boolean;
  var clipped1, clipped2: boolean;
  frustrum: frustrum_type);
procedure Clip_line_to_region(var line: line_type;
  var clipped1, clipped2: boolean;
  var t: real;
  clipping_plane_ptr: clipping_plane_ptr_type);

{**************************************}
{ methods to tell if lines are clipped }
{**************************************}
function Plane_clips_line(plane: plane_type;
  line: line_type): boolean;
function Origin_plane_clips_line(normal: vector_type;
  line: line_type): boolean;
function Frustrum_clips_line(frustrum: frustrum_type;
  line: line_type): boolean;
function Anti_frustrum_clips_line(frustrum: frustrum_type;
  line: line_type): boolean;
function Region_clips_line(clipping_plane_ptr: clipping_plane_ptr_type;
  line: line_type): boolean;

{******************************************}
{ routines for writing line clipping types }
{******************************************}
procedure Write_line(line: line_type);


implementation
uses
  constants;


{********************************}
{ methods for constructing lines }
{********************************}


function To_line(point1, point2: vector_type): line_type;
var
  line: line_type;
begin
  line.point1 := point1;
  line.point2 := point2;
  To_line := line;
end; {function To_line}


{***********************}
{ methods to clip lines }
{***********************}


procedure Clip_line_to_plane(var line: line_type;
  var clipped1, clipped2: boolean;
  var t: real;
  plane: plane_type);
var
  normal_dot_point1: real;
  normal_dot_point2: real;
  direction: vector_type;
  normal_dot_direction: real;
begin
  normal_dot_point1 := Dot_product(plane.normal, Vector_difference(line.point1,
    plane.origin));
  normal_dot_point2 := Dot_product(plane.normal, Vector_difference(line.point2,
    plane.origin));

  clipped1 := normal_dot_point1 < tiny;
  clipped2 := normal_dot_point2 < tiny;

  if (clipped1 <> clipped2) then
    begin
      {***********************}
      { line has been clipped }
      {***********************}
      direction := Vector_difference(line.point2, line.point1);
      normal_dot_direction := Dot_product(plane.normal, direction);
      t := -normal_dot_point1 / normal_dot_direction;
      if clipped1 then
        line.point1 := Vector_sum(line.point1, Vector_scale(direction, t))
      else
        line.point2 := Vector_sum(line.point1, Vector_scale(direction, t));
    end;
end; {procedure Clip_line_to_plane}


procedure Clip_line_to_origin_plane(var line: line_type;
  var clipped1, clipped2: boolean;
  var t: real;
  normal: vector_type);
var
  normal_dot_point1: real;
  normal_dot_point2: real;
  direction: vector_type;
  normal_dot_direction: real;
begin
  normal_dot_point1 := Dot_product(normal, line.point1);
  normal_dot_point2 := Dot_product(normal, line.point2);

  clipped1 := normal_dot_point1 < tiny;
  clipped2 := normal_dot_point2 < tiny;

  if (clipped1 <> clipped2) then
    begin
      {***********************}
      { line has been clipped }
      {***********************}
      direction := Vector_difference(line.point2, line.point1);
      normal_dot_direction := Dot_product(normal, direction);
      t := -normal_dot_point1 / normal_dot_direction;
      if clipped1 then
        line.point1 := Vector_sum(line.point1, Vector_scale(direction, t))
      else
        line.point2 := Vector_sum(line.point1, Vector_scale(direction, t));
    end;
end; {procedure Clip_line_to_origin_plane}


procedure Clip_line_to_frustrum(var line: line_type;
  var line_exists: boolean;
  var clipped1, clipped2: boolean;
  frustrum: frustrum_type);
var
  c1, c2: boolean;
  t: real;
begin
  line_exists := true;
  clipped1 := false;
  clipped2 := false;
  Clip_line_to_origin_plane(line, c1, c2, t, frustrum.top_normal);
  if (c1) and (c2) then
    line_exists := false;
  if (c1) then
    clipped1 := true;
  if (c2) then
    clipped2 := true;

  if line_exists then
    begin
      Clip_line_to_origin_plane(line, c1, c2, t, frustrum.bottom_normal);
      if (c1) and (c2) then
        line_exists := false;
      if (c1) then
        clipped1 := true;
      if (c2) then
        clipped2 := true;
    end;

  if line_exists then
    begin
      Clip_line_to_origin_plane(line, c1, c2, t, frustrum.right_normal);
      if (c1) and (c2) then
        line_exists := false;
      if (c1) then
        clipped1 := true;
      if (c2) then
        clipped2 := true;
    end;

  if line_exists then
    begin
      Clip_line_to_origin_plane(line, c1, c2, t, frustrum.left_normal);
      if (c1) and (c2) then
        line_exists := false;
      if (c1) then
        clipped1 := true;
      if (c2) then
        clipped2 := true;
    end;
end; {procedure Clip_line_to_frustrum}


procedure Clip_line_to_anti_frustrum(var line1, line2: line_type;
  var line1_exists, line2_exists: boolean;
  var clipped1, clipped2: boolean;
  frustrum: frustrum_type);
var
  line_exists: boolean;
  line: line_type;
begin
  line := line1;
  line2 := line;
  Clip_line_to_frustrum(line, line_exists, clipped1, clipped2, frustrum);

  if line_exists then
    begin
      if (clipped1) then
        begin
          if (clipped2) then
            begin
              {***************************}
              { point1 and point2 clipped }
              {***************************}
              line1_exists := true;
              line1.point2 := line.point1;
              line2_exists := true;
              line2.point1 := line.point2;
            end
          else
            begin
              {*********************}
              { point1 clipped only }
              {*********************}
              line1_exists := true;
              line1.point2 := line.point1;
              line2_exists := false;
            end;
        end
      else
        begin
          if (clipped2) then
            begin
              {*********************}
              { point2 clipped only }
              {*********************}
              line1_exists := true;
              line1.point1 := line.point2;
              line2_exists := false;
            end
          else
            begin
              {**********************************************}
              { line_exists inside frustrum but neither end  }
              { point has been clipped so line is entirely   }
              { outside of anti-frustrum and none is visible }
              {**********************************************}
              line1_exists := false;
              line2_exists := false;
            end;
        end;
    end
  else
    begin
      {*********************************************}
      { no portion of line is in frustrum so entire }
      { portion of line must be in anti-frustrum    }
      {*********************************************}
      line1_exists := true;
      line2_exists := false;
    end;

  {*******************************************}
  { if an endpoint is visible in the frustrum }
  { then it is invisible in the anti-frustrum }
  {*******************************************}
  clipped1 := not clipped1;
  clipped2 := not clipped2;
end; {procedure Clip_line_to_anti_frustrum}


procedure Clip_line_to_region(var line: line_type;
  var clipped1, clipped2: boolean;
  var t: real;
  clipping_plane_ptr: clipping_plane_ptr_type);
begin
  clipped1 := false;
  clipped2 := false;
  while (clipping_plane_ptr <> nil) and not (clipped1 and clipped2) do
    begin
      Clip_line_to_plane(line, clipped1, clipped2, t,
        clipping_plane_ptr^.plane);
      clipping_plane_ptr := clipping_plane_ptr^.next;
    end;
end; {procedure Clip_line_to_region}


{**************************************}
{ methods to tell if lines are clipped }
{**************************************}


function Plane_clips_line(plane: plane_type;
  line: line_type): boolean;
var
  normal_dot_point1, normal_dot_point2: real;
  clipped1, clipped2: boolean;
begin
  normal_dot_point1 := Dot_product(plane.normal, Vector_difference(line.point1,
    plane.origin));
  normal_dot_point2 := Dot_product(plane.normal, Vector_difference(line.point2,
    plane.origin));

  clipped1 := normal_dot_point1 < tiny;
  clipped2 := normal_dot_point2 < tiny;

  Plane_clips_line := (clipped1 <> clipped2);
end; {function Plane_clips_line}


function Origin_plane_clips_line(normal: vector_type;
  line: line_type): boolean;
var
  normal_dot_point1, normal_dot_point2: real;
  clipped1, clipped2: boolean;
begin
  normal_dot_point1 := Dot_product(normal, line.point1);
  normal_dot_point2 := Dot_product(normal, line.point2);

  clipped1 := normal_dot_point1 < tiny;
  clipped2 := normal_dot_point2 < tiny;

  Origin_plane_clips_line := (clipped1 <> clipped2);
end; {function Origin_plane_clips_line}


function Frustrum_clips_line(frustrum: frustrum_type;
  line: line_type): boolean;
var
  clipped1, clipped2, line_exists: boolean;
begin
  Clip_line_to_frustrum(line, line_exists, clipped1, clipped2, frustrum);
  Frustrum_clips_line := (clipped1 or clipped2) and line_exists;
end; {function Frustrum_clips_line}


function Anti_frustrum_clips_line(frustrum: frustrum_type;
  line: line_type): boolean;
var
  line2: line_type;
  clipped1, clipped2, line1_exists, line2_exists: boolean;
begin
  Clip_line_to_anti_frustrum(line, line2, line1_exists, line2_exists, clipped1,
    clipped2, frustrum);
  Anti_frustrum_clips_line := clipped1 or clipped2 or not line1_exists or not
    line2_exists;
end; {function Anti_frustrum_clips_line}


function Region_clips_line(clipping_plane_ptr: clipping_plane_ptr_type;
  line: line_type): boolean;
var
  clipped: boolean;
begin
  clipped := false;
  while (clipping_plane_ptr <> nil) and not clipped do
    begin
      clipped := Plane_clips_line(clipping_plane_ptr^.plane, line);
      clipping_plane_ptr := clipping_plane_ptr^.next;
    end;
  Region_clips_line := clipped;
end; {function Region_clips_line}


{******************************************}
{ routines for writing line clipping types }
{******************************************}


procedure Write_line(line: line_type);
begin
  with line do
    begin
      with point1 do
        writeln('point1 = ', x, y, z);
      with point2 do
        writeln('point2 = ', x, y, z);
    end;
end; {procedure Write_line}


end.
