unit triangles;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             triangles                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{      This module divides polygons into triangles so           }
{      that they may be properly textured.                      }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  trans, geometry, topology, b_rep;


type
  triangle_ptr_type = ^triangle_type;
  triangle_type = record
    trans: trans_type;

    vertex_ptr1: vertex_ptr_type;
    vertex_ptr2: vertex_ptr_type;
    vertex_ptr3: vertex_ptr_type;

    vertex_geometry_ptr1: vertex_geometry_ptr_type;
    vertex_geometry_ptr2: vertex_geometry_ptr_type;
    vertex_geometry_ptr3: vertex_geometry_ptr_type;

    {************************************************}
    { the face pointer poins back to the original    }
    { face which created the triangle so that when   }
    { secondary rays are fired, we can avoid hitting }
    { the same face which the ray originated.        }
    {************************************************}
    face_ptr: face_ptr_type;
    face_geometry_ptr: face_geometry_ptr_type;

    next: triangle_ptr_type;
  end;


function Triangulated_face(face_ptr: face_ptr_type): triangle_ptr_type;
function Triangulated_mesh(surface_ptr: surface_ptr_type): triangle_ptr_type;
procedure Free_triangles(var triangle_ptr: triangle_ptr_type);
procedure Write_triangle(triangle_ptr: triangle_ptr_type);
procedure Write_triangles(triangle_ptr: triangle_ptr_type);


implementation
uses
  new_memory, trigonometry, vectors, vectors2;


const
  block_size = 512;
  memory_alert = false;


type
  triangle_block_ptr_type = ^triangle_block_type;
  triangle_block_type = array[0..block_size] of triangle_type;


  polygon_vertex_ptr_type = ^polygon_vertex_type;
  polygon_vertex_type = record
    vertex_ptr: vertex_ptr_type;

    {*******************************}
    { fields used for triangulation }
    {*******************************}
    convex: boolean;
    direction: vector2_type;

    {**************************************}
    { projection of vertex - triangulation }
    { algorithm must operate in 2d space.  }
    {**************************************}
    point: vector2_type;

    next: polygon_vertex_ptr_type;
  end;


  polygon_ptr_type = ^polygon_type;
  polygon_type = record
    vertices: integer;
    normal: vector_type;
    first, last: polygon_vertex_ptr_type;
    orientation: boolean;

    {***************************************}
    { this is used to create triangles with }
    { pointers back to their creator faces  }
    {***************************************}
    face_ptr: face_ptr_type;

    next: polygon_ptr_type;
  end;

  {*************************************}
  { which axis to project polygon along }
  {*************************************}
  axis_projection_type = (project_x, project_y, project_z);


var
  triangle_counter: integer;
  triangle_free_list: triangle_ptr_type;
  triangle_block_ptr: triangle_block_ptr_type;

  polygon_vertex_free_list: polygon_vertex_ptr_type;
  polygon_free_list: polygon_ptr_type;


  {***********************************}
  { routines for allocating triangles }
  {***********************************}


procedure Init_triangle(triangle_ptr: triangle_ptr_type;
  vertex_ptr1, vertex_ptr2, vertex_ptr3: vertex_ptr_type;
  face_ptr: face_ptr_type);
var
  point1, point2, point3: vector_type;
begin
  triangle_ptr^.next := nil;

  {*********************************************}
  { initialize triangle topological information }
  {*********************************************}
  triangle_ptr^.vertex_ptr1 := vertex_ptr1;
  triangle_ptr^.vertex_ptr2 := vertex_ptr2;
  triangle_ptr^.vertex_ptr3 := vertex_ptr3;
  triangle_ptr^.face_ptr := face_ptr;

  {*******************************************}
  { initialize triangle geometric information }
  {*******************************************}
  triangle_ptr^.vertex_geometry_ptr1 := vertex_ptr1^.vertex_geometry_ptr;
  triangle_ptr^.vertex_geometry_ptr2 := vertex_ptr2^.vertex_geometry_ptr;
  triangle_ptr^.vertex_geometry_ptr3 := vertex_ptr3^.vertex_geometry_ptr;
  triangle_ptr^.face_geometry_ptr := face_ptr^.face_geometry_ptr;

  {***********************************}
  { construct triangle transformation }
  {***********************************}
  point1 := vertex_ptr1^.point_ptr^.point_geometry_ptr^.point;
  point2 := vertex_ptr2^.point_ptr^.point_geometry_ptr^.point;
  point3 := vertex_ptr3^.point_ptr^.point_geometry_ptr^.point;

  with triangle_ptr^.trans do
    begin
      origin := point2;
      x_axis := Vector_difference(point3, point2);
      y_axis := Vector_difference(point1, point2);
      z_axis := Cross_product(x_axis, y_axis);
    end;
  triangle_ptr^.trans := Inverse_trans(triangle_ptr^.trans);
end; {procedure Init_triangle}


function New_triangle(vertex_ptr1, vertex_ptr2, vertex_ptr3: vertex_ptr_type;
  face_ptr: face_ptr_type): triangle_ptr_type;
var
  triangle_ptr: triangle_ptr_type;
  index: integer;
begin
  {*****************************}
  { get triangle from free list }
  {*****************************}
  if (triangle_free_list <> nil) then
    begin
      triangle_ptr := triangle_free_list;
      triangle_free_list := triangle_ptr^.next;
    end
  else
    begin
      index := triangle_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new triangle block');
          new(triangle_block_ptr);
        end;
      triangle_ptr := @triangle_block_ptr^[index];
      triangle_counter := triangle_counter + 1;
    end;

  {*********************}
  { initialize triangle }
  {*********************}
  Init_triangle(triangle_ptr, vertex_ptr1, vertex_ptr2, vertex_ptr3, face_ptr);

  New_triangle := triangle_ptr;
end; {function New_triangle}


procedure Free_triangles(var triangle_ptr: triangle_ptr_type);
var
  follow: triangle_ptr_type;
begin
  follow := triangle_ptr;
  while (follow <> nil) do
    begin
      triangle_ptr := follow;
      follow := follow^.next;

      {***************************}
      { add triangle to free list }
      {***************************}
      triangle_ptr^.next := triangle_free_list;
      triangle_free_list := triangle_ptr;
      triangle_ptr := nil;
    end;
end; {procedure Free_triangles}


{***************************************}
{ routines for creating polygons which  }
{ are used internally for triangulation }
{***************************************}


function New_polygon: polygon_ptr_type;
var
  polygon_ptr: polygon_ptr_type;
begin
  {****************************}
  { get polygon from free list }
  {****************************}
  if (polygon_free_list <> nil) then
    begin
      polygon_ptr := polygon_free_list;
      polygon_free_list := polygon_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new polygon');
      new(polygon_ptr);
    end;

  {*********************}
  { initialize triangle }
  {*********************}
  polygon_ptr^.vertices := 0;
  polygon_ptr^.first := nil;
  polygon_ptr^.last := nil;
  polygon_ptr^.next := nil;

  New_polygon := polygon_ptr;
end; {function New_polygon}


function New_polygon_vertex: polygon_vertex_ptr_type;
var
  polygon_vertex_ptr: polygon_vertex_ptr_type;
begin
  {***********************************}
  { get polygon vertex from free list }
  {***********************************}
  if (polygon_vertex_free_list <> nil) then
    begin
      polygon_vertex_ptr := polygon_vertex_free_list;
      polygon_vertex_free_list := polygon_vertex_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new polygon vertex');
      new(polygon_vertex_ptr);
    end;

  {***************************}
  { initialize polygon vertex }
  {***************************}
  polygon_vertex_ptr^.vertex_ptr := nil;
  polygon_vertex_ptr^.next := nil;

  New_polygon_vertex := polygon_vertex_ptr;
end; {function New_polygon_vertex}


procedure Add_polygon_vertex(polygon_ptr: polygon_ptr_type;
  vertex_ptr: vertex_ptr_type);
var
  polygon_vertex_ptr: polygon_vertex_ptr_type;
begin
  polygon_ptr^.vertices := polygon_ptr^.vertices + 1;
  polygon_vertex_ptr := New_polygon_vertex;
  polygon_vertex_ptr^.vertex_ptr := vertex_ptr;

  if polygon_ptr^.last <> nil then
    begin
      polygon_ptr^.last^.next := polygon_vertex_ptr;
      polygon_ptr^.last := polygon_vertex_ptr;
    end
  else
    begin
      polygon_ptr^.first := polygon_vertex_ptr;
      polygon_ptr^.last := polygon_vertex_ptr;
    end;
end; {procedure Add_polygon_vertex}


function Copy_polygon_vertex(polygon_vertex_ptr: polygon_vertex_ptr_type):
  polygon_vertex_ptr_type;
var
  new_vertex_ptr: polygon_vertex_ptr_type;
begin
  new_vertex_ptr := New_polygon_vertex;
  new_vertex_ptr^ := polygon_vertex_ptr^;
  new_vertex_ptr^.next := nil;
  Copy_polygon_vertex := new_vertex_ptr;
end; {function Copy_polygon_vertex}


procedure Free_polygon_vertex(var polygon_vertex_ptr: polygon_vertex_ptr_type);
begin
  {*********************************}
  { add polygon vertex to free list }
  {*********************************}
  polygon_vertex_ptr^.next := polygon_vertex_free_list;
  polygon_vertex_free_list := polygon_vertex_ptr;
  polygon_vertex_ptr := nil;
end; {procedure Free_polygon_vertex}


procedure Free_polygon(var polygon_ptr: polygon_ptr_type);
begin
  {***************************}
  { add vertices to free list }
  {***************************}
  if (polygon_ptr^.last <> nil) then
    begin
      polygon_ptr^.last^.next := polygon_vertex_free_list;
      polygon_vertex_free_list := polygon_ptr^.first;
    end;

  {**************************}
  { add polygon to free list }
  {**************************}
  polygon_ptr^.next := polygon_free_list;
  polygon_free_list := polygon_ptr;
  polygon_ptr := nil;
end; {procedure Free_polygon}


function Polygon_to_triangle(polygon_vertex_ptr1: polygon_vertex_ptr_type;
  polygon_vertex_ptr2: polygon_vertex_ptr_type;
  polygon_vertex_ptr3: polygon_vertex_ptr_type;
  face_ptr: face_ptr_type): triangle_ptr_type;
var
  vertex_ptr1: vertex_ptr_type;
  vertex_ptr2: vertex_ptr_type;
  vertex_ptr3: vertex_ptr_type;
begin
  vertex_ptr1 := polygon_vertex_ptr1^.vertex_ptr;
  vertex_ptr2 := polygon_vertex_ptr2^.vertex_ptr;
  vertex_ptr3 := polygon_vertex_ptr3^.vertex_ptr;
  Polygon_to_triangle := New_triangle(vertex_ptr1, vertex_ptr2, vertex_ptr3,
    face_ptr);
end; {function Polygon_to_triangle}


{***************************************}
{ routines for performing triangulation }
{***************************************}


function Triangulated_quad(polygon_ptr: polygon_ptr_type): triangle_ptr_type;
var
  vertex_ptr1, vertex_ptr2, vertex_ptr3: polygon_vertex_ptr_type;
  triangle_ptr1: triangle_ptr_type;
  triangle_ptr2: triangle_ptr_type;
  face_ptr: face_ptr_type;
begin
  {******************************}
  { create triangles which point }
  { back to their original face. }
  {******************************}
  face_ptr := polygon_ptr^.face_ptr;

  {******************************}
  { triangle1 - vertices 1, 2, 3 }
  {******************************}
  vertex_ptr1 := polygon_ptr^.first;
  vertex_ptr2 := vertex_ptr1^.next;
  vertex_ptr3 := vertex_ptr2^.next;
  triangle_ptr1 := Polygon_to_triangle(vertex_ptr1, vertex_ptr2, vertex_ptr3,
    face_ptr);

  {******************************}
  { triangle2 - vertices 3, 4, 1 }
  {******************************}
  vertex_ptr1 := vertex_ptr3;
  vertex_ptr2 := vertex_ptr1^.next;
  vertex_ptr3 := polygon_ptr^.first;
  triangle_ptr2 := Polygon_to_triangle(vertex_ptr1, vertex_ptr2, vertex_ptr3,
    face_ptr);

  {***************************}
  { replace quad by triangles }
  {***************************}
  triangle_ptr1^.next := triangle_ptr2;
  Triangulated_quad := triangle_ptr1;
end; {procedure Triangulated_quad}


function Vector_to_vector2(vector: vector_type): vector2_type;
var
  v: vector2_type;
begin
  v.x := vector.x;
  v.y := vector.y;
  Vector_to_vector2 := v;
end; {function Vector_to_vector2}


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

  if (temp2 <> 0) then
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


function Edge_intersection(vertex_ptr: polygon_vertex_ptr_type;
  vertex_ptr1, vertex_ptr2: polygon_vertex_ptr_type): boolean;
var
  follow: polygon_vertex_ptr_type;
  point1, point2, point3, point4: vector2_type;
  t1, t2: real;
  intersection, done: boolean;
  inclusive: boolean;
begin
  point1 := vertex_ptr1^.point;
  point2 := vertex_ptr2^.point;

  {****************************************}
  { if first vertex is concave, then count }
  { intersections at endpoints as valid.   }
  {****************************************}
  inclusive := not vertex_ptr1^.convex;

  follow := vertex_ptr;
  done := (follow = nil);
  intersection := false;

  while not done do
    begin
      if (follow <> vertex_ptr1) then
        if (follow <> vertex_ptr2) then
          if (follow^.next <> vertex_ptr1) then
            if (follow^.next <> vertex_ptr2) then
              begin
                point3 := follow^.point;
                point4 := follow^.next^.point;

                if Line_intersection(point1, point2, point3, point4, t1, t2,
                  inclusive) then
                  begin
                    intersection := true;
                    done := true;
                  end;
              end;

      if not done then
        begin
          follow := follow^.next;
          done := (follow = vertex_ptr);
        end;
    end;

  Edge_intersection := intersection;
end; {function Edge_intersection}


procedure Project_polygon_vertices(polygon_ptr: polygon_ptr_type);
var
  x, y, z: real;
  axis_projection: axis_projection_type;
  polygon_vertex_ptr: polygon_vertex_ptr_type;
begin
  x := abs(polygon_ptr^.normal.x);
  y := abs(polygon_ptr^.normal.y);
  z := abs(polygon_ptr^.normal.z);

  axis_projection := project_x;
  if (y > x) then
    axis_projection := project_y;
  if (z > y) then
    axis_projection := project_z;

  case axis_projection of

    {**********************}
    { project along x axis }
    {**********************}
    project_x:
      begin
        polygon_vertex_ptr := polygon_ptr^.first;
        while (polygon_vertex_ptr <> nil) do
          begin
            with polygon_vertex_ptr^ do
              begin
                point.x := vertex_ptr^.point_ptr^.point_geometry_ptr^.point.y;
                point.y := vertex_ptr^.point_ptr^.point_geometry_ptr^.point.z;
              end;
            polygon_vertex_ptr := polygon_vertex_ptr^.next;
          end;
      end;

    {**********************}
    { project along y axis }
    {**********************}
    project_y:
      begin
        polygon_vertex_ptr := polygon_ptr^.first;
        while (polygon_vertex_ptr <> nil) do
          begin
            with polygon_vertex_ptr^ do
              begin
                point.x := vertex_ptr^.point_ptr^.point_geometry_ptr^.point.x;
                point.y := vertex_ptr^.point_ptr^.point_geometry_ptr^.point.z;
              end;
            polygon_vertex_ptr := polygon_vertex_ptr^.next;
          end;
      end;

    {**********************}
    { project along z axis }
    {**********************}
    project_z:
      begin
        polygon_vertex_ptr := polygon_ptr^.first;
        while (polygon_vertex_ptr <> nil) do
          begin
            with polygon_vertex_ptr^ do
              begin
                point.x := vertex_ptr^.point_ptr^.point_geometry_ptr^.point.x;
                point.y := vertex_ptr^.point_ptr^.point_geometry_ptr^.point.y;
              end;
            polygon_vertex_ptr := polygon_vertex_ptr^.next;
          end;
      end;

  end;
end; {procedure Project_polygon_vertices}


procedure Orient_polygon(polygon_ptr: polygon_ptr_type);
var
  vertex_ptr, next: polygon_vertex_ptr_type;
  angle, left_angle, right_angle: real;
  x, y, direction_length: real;
  v1, v2: vector2_type;
  done: boolean;
begin
  {********************************}
  { make list of vertices circular }
  {********************************}
  polygon_ptr^.last^.next := polygon_ptr^.first;

  {***************************}
  { compute direction vectors }
  {***************************}
  vertex_ptr := polygon_ptr^.first;
  done := (vertex_ptr = nil);
  while not done do
    begin
      next := vertex_ptr^.next;
      v1 := next^.point;
      v2 := vertex_ptr^.point;
      vertex_ptr^.direction := Vector2_difference(v1, v2);
      direction_length := Vector2_length(vertex_ptr^.direction);
      if (direction_length <> 0) then
        vertex_ptr^.direction := Vector2_scale(vertex_ptr^.direction, 1 /
          direction_length);
      vertex_ptr := next;
      done := (vertex_ptr = polygon_ptr^.first);
    end;

  {****************************************************}
  { determine whether each vertex is convex or concave }
  {****************************************************}
  left_angle := 0;
  right_angle := 0;
  vertex_ptr := polygon_ptr^.first;
  done := (vertex_ptr = nil);

  while not done do
    begin
      next := vertex_ptr^.next;
      v1 := vertex_ptr^.direction;
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
      vertex_ptr := next;
      done := (vertex_ptr = polygon_ptr^.first);
    end;

  {***********************************************}
  { the convexity test depends upon the clockwise }
  { / counterclockwise orientation of the polygon }
  {***********************************************}
  polygon_ptr^.orientation := (left_angle > right_angle);

  if not polygon_ptr^.orientation then
    begin
      vertex_ptr := polygon_ptr^.first;
      done := (vertex_ptr = nil);
      while not done do
        begin
          vertex_ptr^.convex := not vertex_ptr^.convex;
          vertex_ptr := vertex_ptr^.next;
          done := (vertex_ptr = polygon_ptr^.first);
        end;
    end;

  {************************************}
  { make list of vertices non-circular }
  {************************************}
  polygon_ptr^.last^.next := nil;
end; {procedure Orient_polygon}


function Triangulated_poly(polygon_ptr: polygon_ptr_type): triangle_ptr_type;
var
  face_ptr: face_ptr_type;
  vertex_ptr, prev, start: polygon_vertex_ptr_type;
  triangle_ptr, triangle_list: triangle_ptr_type;
  vertex_ptr1, vertex_ptr2, vertex_ptr3: polygon_vertex_ptr_type;
  found_triangle, done: boolean;
  v1, v2: vector2_type;
  angle: real;
begin
  {******************************}
  { create triangles which point }
  { back to their original face. }
  {******************************}
  face_ptr := polygon_ptr^.face_ptr;

  {***********************************}
  { project all vertices to 2d coords }
  {***********************************}
  Project_polygon_vertices(polygon_ptr);

  {*******************************************************}
  { find orientation of polygon and convexity of vertices }
  {*******************************************************}
  Orient_polygon(polygon_ptr);

  {********************************}
  { make list of vertices circular }
  {********************************}
  polygon_ptr^.last^.next := polygon_ptr^.first;

  {*********************}
  { triangulate polygon }
  {*********************}
  vertex_ptr := polygon_ptr^.first;
  prev := polygon_ptr^.last;
  done := (vertex_ptr = nil);
  triangle_list := nil;
  start := vertex_ptr;

  {*******************************************}
  { create triangles where vertex1 is concave }
  {*******************************************}
  while not done do
    begin
      vertex_ptr1 := vertex_ptr;
      vertex_ptr2 := vertex_ptr1^.next;
      vertex_ptr3 := vertex_ptr2^.next;

      if (vertex_ptr3^.next = vertex_ptr1) then
        {***********************}
        { polygon is a triangle }
        {***********************}
        done := true
      else
        begin
          triangle_ptr := nil;
          found_triangle := (not vertex_ptr1^.convex) and (vertex_ptr2^.convex);

          if found_triangle then
            if not Edge_intersection(vertex_ptr, vertex_ptr1, vertex_ptr3) then
              begin
                {*********************}
                { create new triangle }
                {*********************}
                start := vertex_ptr;
                triangle_ptr := Polygon_to_triangle(vertex_ptr1, vertex_ptr2,
                  vertex_ptr3, face_ptr);
                triangle_ptr^.next := triangle_list;
                triangle_list := triangle_ptr;

                {***********************************}
                { remove middle vertex from polygon }
                {***********************************}
                Free_polygon_vertex(vertex_ptr2);
                vertex_ptr1^.next := vertex_ptr3;

                {*******************************}
                { compute new direction vectors }
                {*******************************}
                vertex_ptr1^.direction :=
                  Normalize2(Vector2_difference(vertex_ptr3^.point,
                  vertex_ptr1^.point));

                {*************************}
                { compute new convexities }
                {*************************}
                v1 := prev^.direction;
                v2 := vertex_ptr1^.direction;
                angle := Cross_product2(v1, v2);

                if polygon_ptr^.orientation then
                  vertex_ptr1^.convex := (angle > 0)
                else
                  vertex_ptr1^.convex := (angle < 0);

                v1 := vertex_ptr1^.direction;
                v2 := vertex_ptr3^.direction;
                angle := Cross_product2(v1, v2);

                if polygon_ptr^.orientation then
                  vertex_ptr3^.convex := (angle > 0)
                else
                  vertex_ptr3^.convex := (angle < 0);
              end;

          if (triangle_ptr = nil) then
            begin
              {**************************}
              { new edge was not created }
              {**************************}
              prev := vertex_ptr;
              vertex_ptr := vertex_ptr^.next;
              done := (vertex_ptr = start);
            end;
        end;
    end;

  {*********************}
  { triangulate polygon }
  {*********************}
  polygon_ptr^.first := vertex_ptr;
  polygon_ptr^.last := prev;

  done := (vertex_ptr = nil);
  start := vertex_ptr;

  {*******************************************}
  { create triangles where vertex3 is concave }
  {*******************************************}
  while not done do
    begin
      vertex_ptr1 := vertex_ptr;
      vertex_ptr2 := vertex_ptr1^.next;
      vertex_ptr3 := vertex_ptr2^.next;

      if (vertex_ptr3^.next = vertex_ptr1) then
        {***********************}
        { polygon is a triangle }
        {***********************}
        done := true
      else
        begin
          triangle_ptr := nil;
          found_triangle := (vertex_ptr2^.convex) and (not vertex_ptr3^.convex);

          if found_triangle then
            if not Edge_intersection(vertex_ptr, vertex_ptr1, vertex_ptr3) then
              begin
                {*********************}
                { create new triangle }
                {*********************}
                start := vertex_ptr;
                triangle_ptr := Polygon_to_triangle(vertex_ptr1, vertex_ptr2,
                  vertex_ptr3, face_ptr);
                triangle_ptr^.next := triangle_list;
                triangle_list := triangle_ptr;

                {***********************************}
                { remove middle vertex from polygon }
                {***********************************}
                Free_polygon_vertex(vertex_ptr2);
                vertex_ptr1^.next := vertex_ptr3;

                {*******************************}
                { compute new direction vectors }
                {*******************************}
                vertex_ptr1^.direction :=
                  Normalize2(Vector2_difference(vertex_ptr3^.point,
                  vertex_ptr1^.point));

                {*************************}
                { compute new convexities }
                {*************************}
                v1 := prev^.direction;
                v2 := vertex_ptr1^.direction;
                angle := Cross_product2(v1, v2);

                if polygon_ptr^.orientation then
                  vertex_ptr1^.convex := (angle > 0)
                else
                  vertex_ptr1^.convex := (angle < 0);
                {Mark_vertex(vertex_ptr1);}

                v1 := vertex_ptr1^.direction;
                v2 := vertex_ptr3^.direction;
                angle := Cross_product2(v1, v2);

                if polygon_ptr^.orientation then
                  vertex_ptr3^.convex := (angle > 0)
                else
                  vertex_ptr3^.convex := (angle < 0);
                {Mark_vertex(vertex_ptr3);}
              end;

          if (triangle_ptr = nil) then
            begin
              {**************************}
              { new edge was not created }
              {**************************}
              prev := vertex_ptr;
              vertex_ptr := vertex_ptr^.next;
              done := (vertex_ptr = start);
            end;
        end;
    end;

  {***********************************}
  { break up remaining convex polygon }
  {***********************************}
  done := false;
  while not done do
    begin
      vertex_ptr1 := vertex_ptr;
      vertex_ptr2 := vertex_ptr1^.next;
      vertex_ptr3 := vertex_ptr2^.next;

      if (vertex_ptr3^.next = vertex_ptr1) then
        begin
          {************************************}
          { make list of vertices non-circular }
          {************************************}
          polygon_ptr^.first := vertex_ptr1;
          polygon_ptr^.last := vertex_ptr3;
          vertex_ptr3^.next := nil;
          done := true;
        end
      else
        begin
          {*********************}
          { create new triangle }
          {*********************}
          triangle_ptr := Polygon_to_triangle(vertex_ptr1, vertex_ptr2,
            vertex_ptr3, face_ptr);
          triangle_ptr^.next := triangle_list;
          triangle_list := triangle_ptr;

          {***********************************}
          { remove middle vertex from polygon }
          {***********************************}
          Free_polygon_vertex(vertex_ptr2);
          vertex_ptr1^.next := vertex_ptr3;
        end;
    end;

  {************************************}
  { make list of vertices non-circular }
  {************************************}
  polygon_ptr^.first := vertex_ptr;
  polygon_ptr^.last := prev;
  prev^.next := nil;

  {*****************************************}
  { add remaining poly to list of triangles }
  {*****************************************}
  vertex_ptr1 := polygon_ptr^.first;
  vertex_ptr2 := vertex_ptr1^.next;
  vertex_ptr3 := vertex_ptr2^.next;

  triangle_ptr := Polygon_to_triangle(vertex_ptr1, vertex_ptr2, vertex_ptr3,
    face_ptr);
  triangle_ptr^.next := triangle_list;
  triangle_list := triangle_ptr;

  Triangulated_poly := triangle_list;
end; {function Triangulated_poly}


{*****************************************************************}
{ routines for removing holes from polygon prior to triangulation }
{*****************************************************************}


procedure Reverse_polygon(polygon_ptr: polygon_ptr_type);
var
  first, last, follow: polygon_vertex_ptr_type;
  vertex_ptr, vertex_list: polygon_vertex_ptr_type;
begin
  first := polygon_ptr^.first;
  last := polygon_ptr^.last;

  vertex_list := nil;
  follow := polygon_ptr^.first;
  while (follow <> nil) do
    begin
      vertex_ptr := follow;
      follow := follow^.next;
      vertex_ptr^.next := vertex_list;
      vertex_list := vertex_ptr;
    end;

  polygon_ptr^.first := last;
  polygon_ptr^.last := first;

  polygon_ptr^.orientation := not polygon_ptr^.orientation;
end; {procedure Reverse_polygon}


procedure Link_hole(polygon_ptr: polygon_ptr_type);
var
  hole_ptr: polygon_ptr_type;
  next, prev: polygon_vertex_ptr_type;
  vertex_ptr1, vertex_ptr2: polygon_vertex_ptr_type;
  new_vertex_ptr: polygon_vertex_ptr_type;
  cycle_ptr: polygon_ptr_type;
  found, done, intersection: boolean;
begin
  {*****************************************************}
  { find first vertex of polygon that connects with     }
  { first vertex of hole without intersecting any edges }
  {*****************************************************}
  next := polygon_ptr^.first;
  prev := polygon_ptr^.last;

  hole_ptr := polygon_ptr^.next;

  found := false;
  done := false;
  while (not found) and (not done) do
    begin
      {********************************************************}
      { check for edge intersection with all cycles of polygon }
      {********************************************************}
      intersection := false;
      cycle_ptr := polygon_ptr;
      while (cycle_ptr <> nil) and not intersection do
        begin
          vertex_ptr1 := hole_ptr^.first;
          vertex_ptr2 := next;

          intersection := Edge_intersection(cycle_ptr^.first, vertex_ptr1,
            vertex_ptr2);
          cycle_ptr := cycle_ptr^.next;
        end;

      if not intersection then
        found := true
      else
        begin
          prev := next;
          next := next^.next;
          if next = polygon_ptr^.first then
            done := true;
        end;
    end;

  if found then
    begin
      {*******************************************}
      { link hole to cycle of surrounding polygon }
      {*******************************************}
      new_vertex_ptr := Copy_polygon_vertex(next);
      prev^.next := new_vertex_ptr;
      new_vertex_ptr^.next := hole_ptr^.first;
      hole_ptr^.last^.next := Copy_polygon_vertex(hole_ptr^.first);
      hole_ptr^.last := hole_ptr^.last^.next;
      hole_ptr^.last^.next := next;
      polygon_ptr^.vertices := polygon_ptr^.vertices + hole_ptr^.vertices + 2;

      {*******************************}
      { link vertices back to polygon }
      {*******************************}
      polygon_ptr^.first := prev^.next;
      polygon_ptr^.last := prev;

      {***************************}
      { remove vertices from hole }
      {***************************}
      hole_ptr^.first := nil;
      hole_ptr^.last := nil;
      polygon_ptr^.next := hole_ptr^.next;
      Free_polygon(hole_ptr);
    end
  else
    begin
      {***************************************************}
      { hole cannot be connected because the connection   }
      { will intersect another hole, so move hole to back }
      { of list and connect other holes first.            }
      {***************************************************}
      polygon_ptr^.next := hole_ptr^.next;
      while (polygon_ptr^.next <> nil) do
        polygon_ptr := polygon_ptr^.next;
      polygon_ptr^.next := hole_ptr;
    end;
end; {procedure Link_hole}


procedure Remove_holes(polygon_list: polygon_ptr_type);
var
  polygon_ptr: polygon_ptr_type;
begin
  if (polygon_list^.next <> nil) then
    begin
      {***********************************}
      { compute orientation of each cycle }
      {***********************************}
      polygon_ptr := polygon_list;
      while (polygon_ptr <> nil) do
        begin
          Orient_polygon(polygon_ptr);
          polygon_ptr := polygon_ptr^.next;
        end;

      {************************************************}
      { make orientation of all holes opposite polygon }
      {************************************************}
      polygon_ptr := polygon_list^.next;
      while (polygon_ptr <> nil) do
        begin
          if (polygon_ptr^.orientation = polygon_list^.orientation) then
            Reverse_polygon(polygon_ptr);
          polygon_ptr := polygon_ptr^.next;
        end;

      {********************************}
      { make list of vertices circular }
      {********************************}
      polygon_ptr := polygon_list;
      while (polygon_ptr <> nil) do
        begin
          polygon_ptr^.last^.next := polygon_ptr^.first;
          polygon_ptr := polygon_ptr^.next;
        end;

      {***********************}
      { link holes to polygon }
      {***********************}
      polygon_ptr := polygon_list;
      while (polygon_ptr^.next <> nil) do
        Link_hole(polygon_ptr);

      {************************************}
      { make list of vertices non-circular }
      {************************************}
      polygon_list^.last^.next := nil;
    end;
end; {procedure Remove_holes}


{******************************************}
{ routines to create triangles from b reps }
{******************************************}


procedure Write_polygon(polygon_ptr: polygon_ptr_type);
var
  polygon_vertex_ptr: polygon_vertex_ptr_type;
begin
  writeln('polygon:');
  polygon_vertex_ptr := polygon_ptr^.first;
  while (polygon_vertex_ptr <> nil) do
    begin
      with polygon_vertex_ptr^.vertex_ptr^.point_ptr^.point_geometry_ptr^.point
        do
        writeln('point = ', x, y, z);
      polygon_vertex_ptr := polygon_vertex_ptr^.next;
    end;
end; {procedure Write_polygon}


procedure Write_triangle(triangle_ptr: triangle_ptr_type);
begin
  writeln('triangle:');
  with triangle_ptr^ do
    begin
      with vertex_ptr1^.point_ptr^.point_geometry_ptr^.point do
        writeln('point1 = ', x, y, z);
      with vertex_ptr2^.point_ptr^.point_geometry_ptr^.point do
        writeln('point2 = ', x, y, z);
      with vertex_ptr3^.point_ptr^.point_geometry_ptr^.point do
        writeln('point3 = ', x, y, z);
    end;
end; {procedure Write_triangle}


procedure Write_triangles(triangle_ptr: triangle_ptr_type);
begin
  while (triangle_ptr <> nil) do
    begin
      Write_triangle(triangle_ptr);
      triangle_ptr := triangle_ptr^.next;
    end;
end; {procedure Write_triangles}


function Face_to_polygon(face_ptr: face_ptr_type): polygon_ptr_type;
var
  polygon_ptr: polygon_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  cycle_ptr: cycle_ptr_type;
  hole_ptr, hole_list: polygon_ptr_type;
begin
  polygon_ptr := New_polygon;
  polygon_ptr^.normal := face_ptr^.face_geometry_ptr^.normal;
  polygon_ptr^.face_ptr := face_ptr;

  directed_edge_ptr := face_ptr^.cycle_ptr^.directed_edge_ptr;
  while (directed_edge_ptr <> nil) do
    begin
      with directed_edge_ptr^ do
        if orientation then
          Add_polygon_vertex(polygon_ptr, edge_ptr^.vertex_ptr1)
        else
          Add_polygon_vertex(polygon_ptr, edge_ptr^.vertex_ptr2);
      directed_edge_ptr := directed_edge_ptr^.next;
    end;

  hole_list := nil;
  cycle_ptr := face_ptr^.cycle_ptr^.next;
  while (cycle_ptr <> nil) do
    begin
      hole_ptr := New_polygon;
      hole_ptr^.normal := face_ptr^.face_geometry_ptr^.normal;
      hole_ptr^.face_ptr := face_ptr;

      hole_ptr^.next := hole_list;
      hole_list := hole_ptr;

      directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
      while (directed_edge_ptr <> nil) do
        begin
          with directed_edge_ptr^ do
            if orientation then
              Add_polygon_vertex(hole_ptr, edge_ptr^.vertex_ptr1)
            else
              Add_polygon_vertex(hole_ptr, edge_ptr^.vertex_ptr2);
          directed_edge_ptr := directed_edge_ptr^.next;
        end;

      cycle_ptr := cycle_ptr^.next;
    end;

  {**********************}
  { add holes to polygon }
  {**********************}
  polygon_ptr^.next := hole_list;

  Face_to_polygon := polygon_ptr;
end; {function Face_to_polygon}


function Triangulated_face(face_ptr: face_ptr_type): triangle_ptr_type;
var
  polygon_ptr: polygon_ptr_type;
  triangle_ptr: triangle_ptr_type;
  vertex_ptr1, vertex_ptr2, vertex_ptr3: polygon_vertex_ptr_type;
begin
  polygon_ptr := Face_to_polygon(face_ptr);
  if (polygon_ptr^.next <> nil) then
    Remove_holes(polygon_ptr);

  with polygon_ptr^ do
    begin
      if (vertices = 3) then
        begin
          {*****************************}
          { convert polygon to triangle }
          {*****************************}
          vertex_ptr1 := polygon_ptr^.first;
          vertex_ptr2 := vertex_ptr1^.next;
          vertex_ptr3 := vertex_ptr2^.next;
          triangle_ptr := Polygon_to_triangle(vertex_ptr1, vertex_ptr2,
            vertex_ptr3, face_ptr);
        end
      else if (vertices = 4) then
        begin
          {***************************}
          { triangulate quadrilateral }
          {***************************}
          triangle_ptr := Triangulated_quad(polygon_ptr);
        end
      else if (vertices > 4) then
        begin
          {*****************************}
          { triangulate general polygon }
          {*****************************}
          Remove_holes(polygon_ptr);
          triangle_ptr := Triangulated_poly(polygon_ptr);
        end
      else
        begin
          {********************}
          { degenerate polygon }
          {********************}
          triangle_ptr := nil;
        end;
    end;

  {**********************************}
  { all done, free temporary polygon }
  {**********************************}
  Free_polygon(polygon_ptr);

  Triangulated_face := triangle_ptr;
end; {function Triangulated_face}


function Triangulated_mesh(surface_ptr: surface_ptr_type): triangle_ptr_type;
var
  triangle_ptr: triangle_ptr_type;
  new_triangle_ptr: triangle_ptr_type;
  last_triangle_ptr: triangle_ptr_type;
  face_ptr: face_ptr_type;
begin
  {***************************}
  { bind geometry to topology }
  {***************************}
  Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);
  Bind_vertex_geometry(surface_ptr, surface_ptr^.geometry_ptr);
  Bind_face_geometry(surface_ptr, surface_ptr^.geometry_ptr);

  {****************}
  { make triangles }
  {****************}
  triangle_ptr := nil;
  face_ptr := surface_ptr^.topology_ptr^.face_ptr;
  while (face_ptr <> nil) do
    begin
      new_triangle_ptr := Triangulated_face(face_ptr);
      face_ptr := face_ptr^.next;

      {***********************}
      { add triangles to list }
      {***********************}
      if new_triangle_ptr <> nil then
        begin
          last_triangle_ptr := new_triangle_ptr;
          while (last_triangle_ptr^.next <> nil) do
            last_triangle_ptr := last_triangle_ptr^.next;

          last_triangle_ptr^.next := triangle_ptr;
          triangle_ptr := new_triangle_ptr;
        end;
    end;

  Triangulated_mesh := triangle_ptr;
end; {function Triangulated_mesh}


initialization
  triangle_counter := 0;
  triangle_free_list := nil;
  triangle_block_ptr := nil;

  polygon_vertex_free_list := nil;
  polygon_free_list := nil;
end.

