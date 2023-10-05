unit z_triangles;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            z_triangles                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module divides polygons into triangles so that     }
{       they may be properly Gouraud and Phong shaded.          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  z_vertices;


procedure Remove_z_holes(z_polygon_list: z_polygon_ptr_type;
  z_hole_list: z_polygon_ptr_type);
procedure Convexify_z_polygons(z_polygon_list: z_polygon_ptr_type);
procedure Triangulate_z_polygons(z_polygon_list: z_polygon_ptr_type);


implementation
uses
  trigonometry, vectors, vectors2, pixels, colors, drawable;


procedure Triangulate_z_quad(z_polygon_ptr: z_polygon_ptr_type);
var
  triangle_ptr1: z_polygon_ptr_type;
  triangle_ptr2: z_polygon_ptr_type;
  z_vertex_ptr: z_vertex_ptr_type;
begin
  {******************************}
  { triangle1 - vertices 1, 2, 3 }
  {******************************}
  triangle_ptr1 := New_z_vertex_list(z_polygon_ptr^.kind, z_polygon_ptr^.color,
    z_polygon_ptr^.textured);
  z_vertex_ptr := z_polygon_ptr^.first;
  Add_new_z_vertex(triangle_ptr1, z_vertex_ptr^);
  z_vertex_ptr := z_vertex_ptr^.next;
  Add_new_z_vertex(triangle_ptr1, z_vertex_ptr^);
  z_vertex_ptr := z_vertex_ptr^.next;
  Add_new_z_vertex(triangle_ptr1, z_vertex_ptr^);

  {******************************}
  { triangle2 - vertices 3, 4, 1 }
  {******************************}
  triangle_ptr2 := New_z_vertex_list(z_polygon_ptr^.kind, z_polygon_ptr^.color,
    z_polygon_ptr^.textured);
  Add_new_z_vertex(triangle_ptr2, z_vertex_ptr^);
  z_vertex_ptr := z_vertex_ptr^.next;
  Add_new_z_vertex(triangle_ptr2, z_vertex_ptr^);
  z_vertex_ptr := z_polygon_ptr^.first;
  Add_new_z_vertex(triangle_ptr2, z_vertex_ptr^);

  {***************************}
  { replace quad by triangles }
  {***************************}
  triangle_ptr2^.next := z_polygon_ptr^.next;
  z_polygon_ptr^.next := triangle_ptr2;
  Swap_z_vertex_lists(z_polygon_ptr, triangle_ptr1);
  Free_z_vertex_list(triangle_ptr1);
end; {procedure Triangulate_z_quad}


procedure Triangulate_z_quad2(z_polygon_ptr: z_polygon_ptr_type);
var
  z_vertex_ptr: z_vertex_ptr_type;
  z_vertex_ptr1, z_vertex_ptr2, z_vertex_ptr3, z_vertex_ptr4: z_vertex_ptr_type;
begin
  {************************}
  { original quad vertices }
  {************************}
  z_vertex_ptr1 := z_polygon_ptr^.first;
  z_vertex_ptr2 := z_vertex_ptr1^.next;
  z_vertex_ptr3 := z_vertex_ptr2^.next;
  z_vertex_ptr4 := z_vertex_ptr3^.next;

  {*************************************}
  { add copy of vertex 1 after vertex 3 }
  {*************************************}
  z_vertex_ptr := New_z_vertex;
  z_vertex_ptr^ := z_vertex_ptr1^;
  z_vertex_ptr^.next := z_vertex_ptr4;
  z_vertex_ptr3^.next := z_vertex_ptr;

  {*************************************}
  { add copy of vertex 3 after vertex 4 }
  {*************************************}
  z_vertex_ptr := New_z_vertex;
  z_vertex_ptr^ := z_vertex_ptr3^;
  z_vertex_ptr^.next := nil;
  z_vertex_ptr4^.next := z_vertex_ptr;
end; {procedure Triangulage_z_quad2}


function Vector_to_vector2(vector: vector_type): vector2_type;
var
  v: vector2_type;
begin
  v.x := vector.x;
  v.y := vector.y;
  Vector_to_vector2 := v;
end; {function Vector_to_vector2}


procedure Mark_vertex(drawable: drawable_type;
  point: vector2_type);
const
  size = 5;
var
  pixel, pixel1, pixel2: pixel_type;
begin
  pixel.h := Trunc(point.x);
  pixel.v := Trunc(point.y);

  pixel1.h := pixel.h + size;
  pixel1.v := pixel.v + size;
  drawable.Move_to(pixel1);
  pixel2.h := pixel.h - size;
  pixel2.v := pixel.v - size;
  drawable.Line_to(pixel2);
  pixel1.h := pixel.h + size;
  pixel1.v := pixel.v - size;
  drawable.Move_to(pixel1);
  pixel2.h := pixel.h - size;
  pixel2.v := pixel.v + size;
  drawable.Line_to(pixel2);
end; {procedure Mark_vertex}


procedure Mark_z_vertex(drawable: drawable_type;
  z_vertex_ptr: z_vertex_ptr_type);
begin
  if z_vertex_ptr^.convex then
    drawable.Set_color(white_color)
  else
    drawable.Set_color(red_color);

  Mark_vertex(drawable, Vector_to_vector2(z_vertex_ptr^.point));
end; {procedure Mark_z_vertex}


procedure Mark_z_vertices(drawable: drawable_type;
  z_vertex_ptr: z_vertex_ptr_type);
var
  follow: z_vertex_ptr_type;
  done: boolean;
begin
  follow := z_vertex_ptr;
  done := (follow = nil);

  while not done do
    begin
      Mark_z_vertex(drawable, follow);
      follow := follow^.next;
      done := (follow = z_vertex_ptr);
    end;
end; {procedure Mark_z_vertices}


procedure Mark_line(drawable: drawable_type;
  point1, point2: vector2_type);
var
  pixel: pixel_type;
begin
  pixel.h := Trunc(point1.x);
  pixel.v := Trunc(point1.y);
  drawable.Move_to(pixel);
  pixel.h := Trunc(point2.x);
  pixel.v := Trunc(point2.y);
  drawable.Line_to(pixel);
end; {procedure Mark_z_line}


procedure Mark_line_intersection(drawable: drawable_type;
  point1, point2: vector2_type;
  point3, point4: vector2_type;
  t1, t2: real);
var
  point: vector2_type;
begin
  drawable.Set_color(green_color);

  {************}
  { draw lines }
  {************}
  Mark_line(drawable, point1, point2);
  Mark_line(drawable, point3, point4);

  {**************************}
  { draw intersection points }
  {**************************}
  point := Vector2_sum(point1, Vector2_scale(Vector2_difference(point2, point1),
    t1));
  Mark_vertex(drawable, point);

  point := Vector2_sum(point3, Vector2_scale(Vector2_difference(point4, point3),
    t2));
  Mark_vertex(drawable, point);
end; {procedure Mark_line_intersection}


function Line_intersection(point1, point2: vector2_type;
  point3, point4: vector2_type;
  var t1, t2: real;
  inclusive: boolean): boolean;
var
  vector1, vector2, vector3: vector2_type;
  temp1, temp2: real;
  x, y: real;
  intersection: boolean;
begin
  vector1 := Vector2_difference(point2, point1);
  vector2 := Vector2_difference(point4, point3);
  vector3 := Vector2_difference(point1, point3);

  temp1 := (vector2.x * vector3.y) - (vector2.y * vector3.x);
  temp2 := (vector1.x * vector2.y) - (vector1.y * vector2.x);

  if (temp1 <> 0) and (temp2 <> 0) then
    begin
      {*******************************************}
      { non parallel (intersecting) line segments }
      {*******************************************}
      t1 := temp1 / temp2;

      if abs(vector2.x) > abs(vector2.y) then
        begin
          {*****************}
          { horizontal line }
          {*****************}
          x := point1.x + (vector1.x * t1);
          t2 := (x - point3.x) / vector2.x;
        end
      else
        begin
          {***************}
          { vertical line }
          {***************}
          y := point1.y + (vector1.y * t1);
          t2 := (y - point3.y) / vector2.y;
        end;

      intersection := true;

      if (inclusive) then
        begin
          {**********************************}
          { count intersections at endpoints }
          {**********************************}
          if (t1 < 0) or (t1 > 1) then
            intersection := false
          else if (t2 < 0) or (t2 > 1) then
            intersection := false;
        end
      else
        begin
          {****************************************}
          { don't count intersections at endpoints }
          {****************************************}
          if (t1 <= 0) or (t1 >= 1) then
            intersection := false
          else if (t2 <= 0) or (t2 >= 1) then
            intersection := false;
        end;
    end
  else
    begin
      {************************}
      { parallel line segments }
      {************************}
      t1 := 0;
      t2 := 0;
      intersection := false;
    end;

  Line_intersection := intersection;
end; {function Line_intersection}


function Edge_intersection(z_vertex_ptr: z_vertex_ptr_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type): boolean;
var
  follow: z_vertex_ptr_type;
  point1, point2, point3, point4: vector2_type;
  t1, t2: real;
  intersection, done: boolean;
  inclusive: boolean;
begin
  point1 := Vector_to_vector2(z_vertex_ptr1^.point);
  point2 := Vector_to_vector2(z_vertex_ptr2^.point);

  {****************************************}
  { if first vertex is concave, then count }
  { intersections at endpoints as valid.   }
  {****************************************}
  inclusive := not z_vertex_ptr1^.convex;

  follow := z_vertex_ptr;
  done := (follow = nil);
  intersection := false;

  while not done do
    begin
      if (follow <> z_vertex_ptr1) then
        if (follow <> z_vertex_ptr2) then
          if (follow^.next <> z_vertex_ptr1) then
            if (follow^.next <> z_vertex_ptr2) then
              begin
                point3 := Vector_to_vector2(follow^.point);
                point4 := Vector_to_vector2(follow^.next^.point);

                if Line_intersection(point1, point2, point3, point4, t1, t2,
                  inclusive) then
                  begin
                    intersection := true;
                    done := true;
                    {Mark_line_intersection(point1, point2, point3, point4, t1, t2);}
                  end;
              end;

      if not done then
        begin
          follow := follow^.next;
          done := (follow = z_vertex_ptr);
        end;
    end;

  Edge_intersection := intersection;
end; {function Edge_intersection}


procedure Orient_z_polygon(z_polygon_ptr: z_polygon_ptr_type);
var
  z_vertex_ptr, next: z_vertex_ptr_type;
  angle, left_angle, right_angle: real;
  x, y, direction_length: real;
  v1, v2: vector2_type;
  done: boolean;
begin
  {********************************}
  { make list of vertices circular }
  {********************************}
  z_polygon_ptr^.last^.next := z_polygon_ptr^.first;

  {***************************}
  { compute direction vectors }
  {***************************}
  z_vertex_ptr := z_polygon_ptr^.first;
  done := (z_vertex_ptr = nil);
  while not done do
    begin
      next := z_vertex_ptr^.next;
      v1 := Vector_to_vector2(next^.point);
      v2 := Vector_to_vector2(z_vertex_ptr^.point);
      z_vertex_ptr^.direction := Vector2_difference(v1, v2);
      direction_length := Vector2_length(z_vertex_ptr^.direction);
      if (direction_length <> 0) then
        z_vertex_ptr^.direction := Vector2_scale(z_vertex_ptr^.direction, 1 /
          direction_length);
      z_vertex_ptr := next;
      done := (z_vertex_ptr = z_polygon_ptr^.first);
    end;

  {****************************************************}
  { determine whether each vertex is convex or concave }
  {****************************************************}
  left_angle := 0;
  right_angle := 0;
  z_vertex_ptr := z_polygon_ptr^.first;
  done := (z_vertex_ptr = nil);

  while not done do
    begin
      next := z_vertex_ptr^.next;
      v1 := z_vertex_ptr^.direction;
      v2 := next^.direction;

      x := Dot_product2(v1, v2);
      y := Cross_product2(v1, v2);

      {***********************}
      { compute angle of turn }
      {***********************}
      if (x > 1) then
        x := 1;
      if (x < -1) then
        x := -1;
      angle := acos(x);

      if (y > 0) then
        begin
          {****************}
          { add left turns }
          {****************}
          left_angle := left_angle + angle;
        end
      else
        begin
          {*****************}
          { add right turns }
          {*****************}
          right_angle := right_angle + angle;
        end;

      next^.convex := y > 0;
      z_vertex_ptr := next;
      done := (z_vertex_ptr = z_polygon_ptr^.first);
    end;

  {***********************************************}
  { the convexity test depends upon the clockwise }
  { / counterclockwise orientation of the polygon }
  {***********************************************}
  z_polygon_ptr^.orientation := (left_angle > right_angle);

  if not z_polygon_ptr^.orientation then
    begin
      z_vertex_ptr := z_polygon_ptr^.first;
      done := (z_vertex_ptr = nil);
      while not done do
        begin
          z_vertex_ptr^.convex := not z_vertex_ptr^.convex;
          z_vertex_ptr := z_vertex_ptr^.next;
          done := (z_vertex_ptr = z_polygon_ptr^.first);
        end;
    end;

  {************************************}
  { make list of vertices non-circular }
  {************************************}
  z_polygon_ptr^.last^.next := nil;
end; {procedure Orient_z_polygon}


procedure Triangulate_z_poly(z_polygon_ptr: z_polygon_ptr_type);
var
  z_vertex_ptr, prev, start: z_vertex_ptr_type;
  triangle_ptr, triangle_list: z_polygon_ptr_type;
  z_vertex_ptr1, z_vertex_ptr2, z_vertex_ptr3: z_vertex_ptr_type;
  found_triangle, done: boolean;
  v1, v2: vector2_type;
  angle: real;
begin
  {*******************************************************}
  { find orientation of polygon and convexity of vertices }
  {*******************************************************}
  Orient_z_polygon(z_polygon_ptr);

  {********************************}
  { make list of vertices circular }
  {********************************}
  z_polygon_ptr^.last^.next := z_polygon_ptr^.first;

  {****************************}
  { show convexity of vertices }
  {****************************}
  {Mark_z_vertices(z_polygon_ptr^.first);}

  {*********************}
  { triangulate polygon }
  {*********************}
  z_vertex_ptr := z_polygon_ptr^.first;
  prev := z_polygon_ptr^.last;
  done := (z_vertex_ptr = nil);
  triangle_list := nil;
  start := z_vertex_ptr;

  {*******************************************}
  { create triangles where vertex1 is concave }
  {*******************************************}
  while not done do
    begin
      z_vertex_ptr1 := z_vertex_ptr;
      z_vertex_ptr2 := z_vertex_ptr1^.next;
      z_vertex_ptr3 := z_vertex_ptr2^.next;

      if (z_vertex_ptr3^.next = z_vertex_ptr1) then
        {***********************}
        { polygon is a triangle }
        {***********************}
        done := true
      else
        begin
          triangle_ptr := nil;
          found_triangle := (not z_vertex_ptr1^.convex) and
            (z_vertex_ptr2^.convex);

          if found_triangle then
            if not Edge_intersection(z_vertex_ptr, z_vertex_ptr1, z_vertex_ptr3)
              then
              begin
                {*********************}
                { create new triangle }
                {*********************}
                start := z_vertex_ptr;
                triangle_ptr := New_z_vertex_list(z_polygon_ptr^.kind,
                  z_polygon_ptr^.color, z_polygon_ptr^.textured);
                Add_new_z_vertex(triangle_ptr, z_vertex_ptr1^);
                Add_new_z_vertex(triangle_ptr, z_vertex_ptr2^);
                Add_new_z_vertex(triangle_ptr, z_vertex_ptr3^);
                triangle_ptr^.next := triangle_list;
                triangle_list := triangle_ptr;

                {*********************************}
                { show triangles as we build them }
                {*********************************}
                {Preview_z_polygons(triangle_ptr);}
                {Show_window;}
                {readln;}

                {***********************************}
                { remove middle vertex from polygon }
                {***********************************}
                Free_z_vertex(z_vertex_ptr2);
                z_vertex_ptr1^.next := z_vertex_ptr3;

                {*******************************}
                { compute new direction vectors }
                {*******************************}
                v1 := Vector_to_vector2(z_vertex_ptr3^.point);
                v2 := Vector_to_vector2(z_vertex_ptr1^.point);
                z_vertex_ptr1^.direction := Normalize2(Vector2_difference(v1,
                  v2));

                {*************************}
                { compute new convexities }
                {*************************}
                v1 := prev^.direction;
                v2 := z_vertex_ptr1^.direction;
                angle := Cross_product2(v1, v2);

                if z_polygon_ptr^.orientation then
                  z_vertex_ptr1^.convex := (angle > 0)
                else
                  z_vertex_ptr1^.convex := (angle < 0);
                {Mark_z_vertex(z_vertex_ptr1);}

                v1 := z_vertex_ptr1^.direction;
                v2 := z_vertex_ptr3^.direction;
                angle := Cross_product2(v1, v2);

                if z_polygon_ptr^.orientation then
                  z_vertex_ptr3^.convex := (angle > 0)
                else
                  z_vertex_ptr3^.convex := (angle < 0);
                {Mark_z_vertex(z_vertex_ptr3);}
              end;

          if (triangle_ptr = nil) then
            begin
              {**************************}
              { new edge was not created }
              {**************************}
              prev := z_vertex_ptr;
              z_vertex_ptr := z_vertex_ptr^.next;
              done := (z_vertex_ptr = start);
            end;
        end;
    end;

  {*********************}
  { triangulate polygon }
  {*********************}
  z_polygon_ptr^.first := z_vertex_ptr;
  z_polygon_ptr^.last := prev;

  done := (z_vertex_ptr = nil);
  start := z_vertex_ptr;

  {*******************************************}
  { create triangles where vertex3 is concave }
  {*******************************************}
  while not done do
    begin
      z_vertex_ptr1 := z_vertex_ptr;
      z_vertex_ptr2 := z_vertex_ptr1^.next;
      z_vertex_ptr3 := z_vertex_ptr2^.next;

      if (z_vertex_ptr3^.next = z_vertex_ptr1) then
        {***********************}
        { polygon is a triangle }
        {***********************}
        done := true
      else
        begin
          triangle_ptr := nil;
          found_triangle := (z_vertex_ptr2^.convex) and (not
            z_vertex_ptr3^.convex);

          if found_triangle then
            if not Edge_intersection(z_vertex_ptr, z_vertex_ptr1, z_vertex_ptr3)
              then
              begin
                {*********************}
                { create new triangle }
                {*********************}
                start := z_vertex_ptr;
                triangle_ptr := New_z_vertex_list(z_polygon_ptr^.kind,
                  z_polygon_ptr^.color, z_polygon_ptr^.textured);
                Add_new_z_vertex(triangle_ptr, z_vertex_ptr1^);
                Add_new_z_vertex(triangle_ptr, z_vertex_ptr2^);
                Add_new_z_vertex(triangle_ptr, z_vertex_ptr3^);
                triangle_ptr^.next := triangle_list;
                triangle_list := triangle_ptr;

                {*********************************}
                { show triangles as we build them }
                {*********************************}
                {Preview_z_polygons(triangle_ptr);}
                {Show_window;}
                {readln;}

                {***********************************}
                { remove middle vertex from polygon }
                {***********************************}
                Free_z_vertex(z_vertex_ptr2);
                z_vertex_ptr1^.next := z_vertex_ptr3;

                {*******************************}
                { compute new direction vectors }
                {*******************************}
                v1 := Vector_to_vector2(z_vertex_ptr3^.point);
                v2 := Vector_to_vector2(z_vertex_ptr1^.point);
                z_vertex_ptr1^.direction := Normalize2(Vector2_difference(v1,
                  v2));

                {*************************}
                { compute new convexities }
                {*************************}
                v1 := prev^.direction;
                v2 := z_vertex_ptr1^.direction;
                angle := Cross_product2(v1, v2);

                if z_polygon_ptr^.orientation then
                  z_vertex_ptr1^.convex := (angle > 0)
                else
                  z_vertex_ptr1^.convex := (angle < 0);
                {Mark_z_vertex(z_vertex_ptr1);}

                v1 := z_vertex_ptr1^.direction;
                v2 := z_vertex_ptr3^.direction;
                angle := Cross_product2(v1, v2);

                if z_polygon_ptr^.orientation then
                  z_vertex_ptr3^.convex := (angle > 0)
                else
                  z_vertex_ptr3^.convex := (angle < 0);
                {Mark_z_vertex(z_vertex_ptr3);}
              end;

          if (triangle_ptr = nil) then
            begin
              {**************************}
              { new edge was not created }
              {**************************}
              prev := z_vertex_ptr;
              z_vertex_ptr := z_vertex_ptr^.next;
              done := (z_vertex_ptr = start);
            end;
        end;
    end;

  {***********************************}
  { break up remaining convex polygon }
  {***********************************}

  done := false;
  while not done do
    begin
      z_vertex_ptr1 := z_vertex_ptr;
      z_vertex_ptr2 := z_vertex_ptr1^.next;
      z_vertex_ptr3 := z_vertex_ptr2^.next;

      if (z_vertex_ptr3^.next = z_vertex_ptr1) then
        begin
          {************************************}
          { make list of vertices non-circular }
          {************************************}
          z_polygon_ptr^.first := z_vertex_ptr1;
          z_polygon_ptr^.last := z_vertex_ptr3;
          z_vertex_ptr3^.next := nil;
          done := true;
        end
      else
        begin
          {*********************}
          { create new triangle }
          {*********************}
          triangle_ptr := New_z_vertex_list(z_polygon_ptr^.kind,
            z_polygon_ptr^.color, z_polygon_ptr^.textured);
          Add_new_z_vertex(triangle_ptr, z_vertex_ptr1^);
          Add_new_z_vertex(triangle_ptr, z_vertex_ptr2^);
          Add_new_z_vertex(triangle_ptr, z_vertex_ptr3^);
          triangle_ptr^.next := triangle_list;
          triangle_list := triangle_ptr;

          {***********************************}
          { remove middle vertex from polygon }
          {***********************************}
          Free_z_vertex(z_vertex_ptr2);
          z_vertex_ptr1^.next := z_vertex_ptr3;
        end;
    end;

  {************************************}
  { make list of vertices non-circular }
  {************************************}
  z_polygon_ptr^.first := z_vertex_ptr;
  z_polygon_ptr^.last := prev;
  prev^.next := nil;

  {*****************************************}
  { add remaining poly to list of triangles }
  {*****************************************}
  z_polygon_ptr^.vertices := 3;
  z_polygon_ptr^.next := triangle_list;
end; {procedure Triangulate_z_poly}


procedure Triangulate_z_polygon(z_polygon_ptr: z_polygon_ptr_type);
begin
  with z_polygon_ptr^ do
    begin
      if (vertices > 3) then
        if (vertices = 4) then
          begin
            {***************************}
            { triangulate quadrilateral }
            {***************************}
            Triangulate_z_quad(z_polygon_ptr);
          end
        else
          begin
            {*****************************}
            { triangulate general polygon }
            {*****************************}
            Triangulate_z_poly(z_polygon_ptr);
          end;
    end;
end; {procedure Triangulate_z_polygon}


procedure Triangulate_z_polygons(z_polygon_list: z_polygon_ptr_type);
var
  follow, next: z_polygon_ptr_type;
begin
  follow := z_polygon_list;
  while (follow <> nil) do
    begin
      next := follow^.next;
      Triangulate_z_polygon(follow);
      follow := next;
    end;
end; {procedure Triangulate_z_polygons}


{************************************}
{ routines for convexifying polygons }
{************************************}


procedure Convexify_z_poly(z_polygon_ptr: z_polygon_ptr_type);
var
  z_vertex_ptr, prev, start: z_vertex_ptr_type;
  triangle_ptr, triangle_list: z_polygon_ptr_type;
  z_vertex_ptr1, z_vertex_ptr2, z_vertex_ptr3: z_vertex_ptr_type;
  found_triangle, done: boolean;
  v1, v2: vector2_type;
  angle: real;
begin
  {*******************************************************}
  { find orientation of polygon and convexity of vertices }
  {*******************************************************}
  Orient_z_polygon(z_polygon_ptr);

  {********************************}
  { make list of vertices circular }
  {********************************}
  z_polygon_ptr^.last^.next := z_polygon_ptr^.first;

  {****************************}
  { show convexity of vertices }
  {****************************}
  {Mark_z_vertices(z_polygon_ptr^.first);}

  {*********************}
  { triangulate polygon }
  {*********************}
  z_vertex_ptr := z_polygon_ptr^.first;
  prev := z_polygon_ptr^.last;
  done := (z_vertex_ptr = nil);
  triangle_list := nil;
  start := z_vertex_ptr;

  {*******************************************}
  { create triangles where vertex1 is concave }
  {*******************************************}
  while not done do
    begin
      z_vertex_ptr1 := z_vertex_ptr;
      z_vertex_ptr2 := z_vertex_ptr1^.next;
      z_vertex_ptr3 := z_vertex_ptr2^.next;

      if (z_vertex_ptr3^.next = z_vertex_ptr1) then
        {***********************}
        { polygon is a triangle }
        {***********************}
        done := true
      else
        begin
          triangle_ptr := nil;
          found_triangle := (not z_vertex_ptr1^.convex) and
            (z_vertex_ptr2^.convex);

          if found_triangle then
            if not Edge_intersection(z_vertex_ptr, z_vertex_ptr1, z_vertex_ptr3)
              then
              begin
                {*********************}
                { create new triangle }
                {*********************}
                start := z_vertex_ptr;
                triangle_ptr := New_z_vertex_list(z_polygon_ptr^.kind,
                  z_polygon_ptr^.color, z_polygon_ptr^.textured);
                Add_new_z_vertex(triangle_ptr, z_vertex_ptr1^);
                Add_new_z_vertex(triangle_ptr, z_vertex_ptr2^);
                Add_new_z_vertex(triangle_ptr, z_vertex_ptr3^);
                triangle_ptr^.next := triangle_list;
                triangle_list := triangle_ptr;

                {*********************************}
                { show triangles as we build them }
                {*********************************}
                {Preview_z_polygons(triangle_ptr);}
                {Show_window;}
                {readln;}

                {***********************************}
                { remove middle vertex from polygon }
                {***********************************}
                Free_z_vertex(z_vertex_ptr2);
                z_vertex_ptr1^.next := z_vertex_ptr3;
                z_polygon_ptr^.vertices := z_polygon_ptr^.vertices - 1;

                {*******************************}
                { compute new direction vectors }
                {*******************************}
                v1 := Vector_to_vector2(z_vertex_ptr3^.point);
                v2 := Vector_to_vector2(z_vertex_ptr1^.point);
                z_vertex_ptr1^.direction := Normalize2(Vector2_difference(v1,
                  v2));

                {*************************}
                { compute new convexities }
                {*************************}
                v1 := prev^.direction;
                v2 := z_vertex_ptr1^.direction;
                angle := Cross_product2(v1, v2);

                if z_polygon_ptr^.orientation then
                  z_vertex_ptr1^.convex := (angle > 0)
                else
                  z_vertex_ptr1^.convex := (angle < 0);
                {Mark_z_vertex(z_vertex_ptr1);}

                v1 := z_vertex_ptr1^.direction;
                v2 := z_vertex_ptr3^.direction;
                angle := Cross_product2(v1, v2);

                if z_polygon_ptr^.orientation then
                  z_vertex_ptr3^.convex := (angle > 0)
                else
                  z_vertex_ptr3^.convex := (angle < 0);
                {Mark_z_vertex(z_vertex_ptr3);}
              end;

          if (triangle_ptr = nil) then
            begin
              {**************************}
              { new edge was not created }
              {**************************}
              prev := z_vertex_ptr;
              z_vertex_ptr := z_vertex_ptr^.next;
              done := (z_vertex_ptr = start);
            end;
        end;
    end;

  {*******************}
  { convexify polygon }
  {*******************}
  z_polygon_ptr^.first := z_vertex_ptr;
  z_polygon_ptr^.last := prev;

  done := (z_vertex_ptr = nil);
  start := z_vertex_ptr;

  {*******************************************}
  { create triangles where vertex3 is concave }
  {*******************************************}
  while not done do
    begin
      z_vertex_ptr1 := z_vertex_ptr;
      z_vertex_ptr2 := z_vertex_ptr1^.next;
      z_vertex_ptr3 := z_vertex_ptr2^.next;

      if (z_vertex_ptr3^.next = z_vertex_ptr1) then
        {***********************}
        { polygon is a triangle }
        {***********************}
        done := true
      else
        begin
          triangle_ptr := nil;
          found_triangle := (z_vertex_ptr2^.convex) and (not
            z_vertex_ptr3^.convex);

          if found_triangle then
            if not Edge_intersection(z_vertex_ptr, z_vertex_ptr1, z_vertex_ptr3)
              then
              begin
                {*********************}
                { create new triangle }
                {*********************}
                start := z_vertex_ptr;
                triangle_ptr := New_z_vertex_list(z_polygon_ptr^.kind,
                  z_polygon_ptr^.color, z_polygon_ptr^.textured);
                Add_new_z_vertex(triangle_ptr, z_vertex_ptr1^);
                Add_new_z_vertex(triangle_ptr, z_vertex_ptr2^);
                Add_new_z_vertex(triangle_ptr, z_vertex_ptr3^);
                triangle_ptr^.next := triangle_list;
                triangle_list := triangle_ptr;

                {*********************************}
                { show triangles as we build them }
                {*********************************}
                {Preview_z_polygons(triangle_ptr);}
                {Show_window;}
                {readln;}

                {***********************************}
                { remove middle vertex from polygon }
                {***********************************}
                Free_z_vertex(z_vertex_ptr2);
                z_vertex_ptr1^.next := z_vertex_ptr3;
                z_polygon_ptr^.vertices := z_polygon_ptr^.vertices - 1;

                {*******************************}
                { compute new direction vectors }
                {*******************************}
                v1 := Vector_to_vector2(z_vertex_ptr3^.point);
                v2 := Vector_to_vector2(z_vertex_ptr1^.point);
                z_vertex_ptr1^.direction := Normalize2(Vector2_difference(v1,
                  v2));

                {*************************}
                { compute new convexities }
                {*************************}
                v1 := prev^.direction;
                v2 := z_vertex_ptr1^.direction;
                angle := Cross_product2(v1, v2);

                if z_polygon_ptr^.orientation then
                  z_vertex_ptr1^.convex := (angle > 0)
                else
                  z_vertex_ptr1^.convex := (angle < 0);
                {Mark_z_vertex(z_vertex_ptr1);}

                v1 := z_vertex_ptr1^.direction;
                v2 := z_vertex_ptr3^.direction;
                angle := Cross_product2(v1, v2);

                if z_polygon_ptr^.orientation then
                  z_vertex_ptr3^.convex := (angle > 0)
                else
                  z_vertex_ptr3^.convex := (angle < 0);
                {Mark_z_vertex(z_vertex_ptr3);}
              end;

          if (triangle_ptr = nil) then
            begin
              {**************************}
              { new edge was not created }
              {**************************}
              prev := z_vertex_ptr;
              z_vertex_ptr := z_vertex_ptr^.next;
              done := (z_vertex_ptr = start);
            end;
        end;
    end;

  {************************************}
  { make list of vertices non-circular }
  {************************************}
  z_polygon_ptr^.first := z_vertex_ptr;
  z_polygon_ptr^.last := prev;
  prev^.next := nil;

  {*****************************************}
  { add remaining poly to list of triangles }
  {*****************************************}
  z_polygon_ptr^.next := triangle_list;
end; {procedure Convexify_z_poly}


procedure Convexify_z_polygon(z_polygon_ptr: z_polygon_ptr_type);
begin
  with z_polygon_ptr^ do
    begin
      if (vertices > 3) then
        if (vertices = 4) then
          begin
            {**************************************}
            { triangulate quadrilateral because we }
            { can not guarantee that it is convex  }
            {**************************************}
            Triangulate_z_quad(z_polygon_ptr);
          end
        else
          begin
            {***************************}
            { convexify general polygon }
            {***************************}
            Convexify_z_poly(z_polygon_ptr);
          end;
    end;
end; {procedure Convexify_z_polygon}


procedure Convexify_z_polygons(z_polygon_list: z_polygon_ptr_type);
var
  follow, next: z_polygon_ptr_type;
begin
  follow := z_polygon_list;
  while (follow <> nil) do
    begin
      next := follow^.next;
      Convexify_z_polygon(follow);
      follow := next;
    end;
end; {procedure Convexify_z_polygons}


{*****************************************************************}
{ routines for removing holes from polygon prior to triangulation }
{*****************************************************************}


procedure Reverse_z_polygon(z_polygon_ptr: z_polygon_ptr_type);
var
  first, last, follow: z_vertex_ptr_type;
  z_vertex_ptr, z_vertex_list: z_vertex_ptr_type;
begin
  first := z_polygon_ptr^.first;
  last := z_polygon_ptr^.last;

  z_vertex_list := nil;
  follow := z_polygon_ptr^.first;
  while (follow <> nil) do
    begin
      z_vertex_ptr := follow;
      follow := follow^.next;
      z_vertex_ptr^.next := z_vertex_list;
      z_vertex_list := z_vertex_ptr;
    end;

  z_polygon_ptr^.first := last;
  z_polygon_ptr^.last := first;

  z_polygon_ptr^.orientation := not z_polygon_ptr^.orientation;
end; {procedure Reverse_z_polygon}


procedure Link_z_hole(z_polygon_ptr: z_polygon_ptr_type);
var
  z_hole_ptr: z_polygon_ptr_type;
  next, prev: z_vertex_ptr_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
  new_z_vertex_ptr: z_vertex_ptr_type;
  cycle_ptr: z_polygon_ptr_type;
  found, done, intersection: boolean;
begin
  {*****************************************************}
  { find first vertex of polygon that connects with     }
  { first vertex of hole without intersecting any edges }
  {*****************************************************}
  next := z_polygon_ptr^.first;
  prev := z_polygon_ptr^.last;

  z_hole_ptr := z_polygon_ptr^.next;

  found := false;
  done := false;
  while (not found) and (not done) do
    begin
      {********************************************************}
      { check for edge intersection with all cycles of polygon }
      {********************************************************}
      intersection := false;
      cycle_ptr := z_polygon_ptr;
      while (cycle_ptr <> nil) and not intersection do
        begin
          z_vertex_ptr1 := z_hole_ptr^.first;
          z_vertex_ptr2 := next;

          intersection := Edge_intersection(cycle_ptr^.first, z_vertex_ptr1,
            z_vertex_ptr2);
          cycle_ptr := cycle_ptr^.next;
        end;

      if not intersection then
        found := true
      else
        begin
          prev := next;
          next := next^.next;
          if next = z_polygon_ptr^.first then
            done := true;
        end;
    end;

  if found then
    begin
      {*******************************************}
      { link hole to cycle of surrounding polygon }
      {*******************************************}
      new_z_vertex_ptr := Copy_z_vertex(next);
      prev^.next := new_z_vertex_ptr;
      new_z_vertex_ptr^.next := z_hole_ptr^.first;
      z_hole_ptr^.last^.next := Copy_z_vertex(z_hole_ptr^.first);
      z_hole_ptr^.last := z_hole_ptr^.last^.next;
      z_hole_ptr^.last^.next := next;
      z_polygon_ptr^.vertices := z_polygon_ptr^.vertices + z_hole_ptr^.vertices
        + 2;

      {*******************************}
      { link vertices back to polygon }
      {*******************************}
      z_polygon_ptr^.first := prev^.next;
      z_polygon_ptr^.last := prev;

      {***************************}
      { remove vertices from hole }
      {***************************}
      z_hole_ptr^.first := nil;
      z_hole_ptr^.last := nil;
      z_polygon_ptr^.next := z_hole_ptr^.next;
      Free_z_vertex_list(z_hole_ptr);
    end
  else
    begin
      {***************************************************}
      { hole cannot be connected because the connection   }
      { will intersect another hole, so move hole to back }
      { of list and connect other holes first.            }
      {***************************************************}
      z_polygon_ptr^.next := z_hole_ptr^.next;
      while (z_polygon_ptr^.next <> nil) do
        z_polygon_ptr := z_polygon_ptr^.next;
      z_polygon_ptr^.next := z_hole_ptr;
    end;
end; {procedure Link_z_hole}


procedure Remove_z_holes(z_polygon_list: z_polygon_ptr_type;
  z_hole_list: z_polygon_ptr_type);
var
  z_polygon_ptr: z_polygon_ptr_type;
begin
  if (z_hole_list <> nil) then
    begin
      {**********************}
      { add holes to polygon }
      {**********************}
      z_polygon_list^.next := z_hole_list;

      {***********************************}
      { compute orientation of each cycle }
      {***********************************}
      z_polygon_ptr := z_polygon_list;
      while (z_polygon_ptr <> nil) do
        begin
          Orient_z_polygon(z_polygon_ptr);
          z_polygon_ptr := z_polygon_ptr^.next;
        end;

      {************************************************}
      { make orientation of all holes opposite polygon }
      {************************************************}
      z_polygon_ptr := z_polygon_list^.next;
      while (z_polygon_ptr <> nil) do
        begin
          if (z_polygon_ptr^.orientation = z_polygon_list^.orientation) then
            Reverse_z_polygon(z_polygon_ptr);
          z_polygon_ptr := z_polygon_ptr^.next;
        end;

      {********************************}
      { make list of vertices circular }
      {********************************}
      z_polygon_ptr := z_polygon_list;
      while (z_polygon_ptr <> nil) do
        begin
          z_polygon_ptr^.last^.next := z_polygon_ptr^.first;
          z_polygon_ptr := z_polygon_ptr^.next;
        end;

      {***********************}
      { link holes to polygon }
      {***********************}
      z_polygon_ptr := z_polygon_list;
      while (z_polygon_ptr^.next <> nil) do
        Link_z_hole(z_polygon_ptr);

      {************************************}
      { make list of vertices non-circular }
      {************************************}
      z_polygon_list^.last^.next := nil;
    end;
end; {procedure Remove_z_holes}


end.
