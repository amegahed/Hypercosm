unit polygons;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              polygons                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{      The polygons module builds the geometry data structs     }
{      for the polygonal objects.                               }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors;


type
  {**********************}
  { polygon data structs }
  {**********************}
  polygon_vertex_ptr_type = ^polygon_vertex_type;
  polygon_vertex_type = record
    point: vector_type;
    texture: vector_type;
    next: polygon_vertex_ptr_type;
  end; {polygon_vertex_type}

  polygon_ptr_type = ^polygon_type;
  polygon_type = record
    vertices: integer;
    vertex_ptr: polygon_vertex_ptr_type;
    next: polygon_ptr_type;
  end;


  {*****************************}
  { shaded polygon data structs }
  {*****************************}
  shaded_polygon_vertex_ptr_type = ^shaded_polygon_vertex_type;
  shaded_polygon_vertex_type = record
    point: vector_type;
    normal: vector_type;
    texture: vector_type;
    next: shaded_polygon_vertex_ptr_type;
  end; {shaded_polygon_vertex_type}

  shaded_polygon_ptr_type = ^shaded_polygon_type;
  shaded_polygon_type = record
    vertices: integer;
    vertex_ptr: shaded_polygon_vertex_ptr_type;
    next: shaded_polygon_ptr_type;
  end;


  {********************}
  { point data structs }
  {********************}
  point_vertex_ptr_type = ^point_vertex_type;
  point_vertex_type = record
    point: vector_type;
    next: point_vertex_ptr_type;
  end; {point_vertex_type}

  points_ptr_type = ^points_type;
  points_type = record
    vertices: integer;
    vertex_ptr: point_vertex_ptr_type;
    next: points_ptr_type;
  end; {points_type}


  {*******************}
  { line data structs }
  {*******************}
  line_vertex_ptr_type = ^line_vertex_type;
  line_vertex_type = record
    point: vector_type;
    next: line_vertex_ptr_type;
  end; {line_vertex_type}

  lines_ptr_type = ^lines_type;
  lines_type = record
    vertices: integer;
    vertex_ptr: line_vertex_ptr_type;
    next: lines_ptr_type;
  end; {lines_type}


  {********************************************************}
  { these routines are used to create an intermediate data }
  { structure which holds the geometric information about  }
  { the tessellated primitives but without the topology.   }
  {********************************************************}


{********************************}
{ routines for creating polygons }
{********************************}
function New_polygon: polygon_ptr_type;
procedure Add_polygon_vertex(polygon_ptr: polygon_ptr_type;
  point, texture: vector_type);
procedure Free_polygon(var polygon_ptr: polygon_ptr_type);

{***************************************}
{ routines for creating shaded polygons }
{***************************************}
function New_shaded_polygon: shaded_polygon_ptr_type;
procedure Add_shaded_polygon_vertex(shaded_polygon_ptr: shaded_polygon_ptr_type;
  point, normal, texture: vector_type);
procedure Free_shaded_polygon(var shaded_polygon_ptr: shaded_polygon_ptr_type);

{******************************}
{ routines for creating points }
{******************************}
function New_points: points_ptr_type;
procedure Add_point_vertex(points_ptr: points_ptr_type;
  point: vector_type);
procedure Free_points(var points_ptr: points_ptr_type);

{*****************************}
{ routines for creating lines }
{*****************************}
function New_lines: lines_ptr_type;
procedure Add_line_vertex(lines_ptr: lines_ptr_type;
  point: vector_type);
procedure Free_lines(var lines_ptr: lines_ptr_type);


implementation
uses
  new_memory;


const
  memory_alert = false;


var
  {******************************************}
  { free lists for polygons, shaded_polygons }
  {******************************************}
  polygon_free_list: polygon_ptr_type;
  polygon_vertex_free_list: polygon_vertex_ptr_type;
  shaded_polygon_free_list: shaded_polygon_ptr_type;
  shaded_polygon_vertex_free_list: shaded_polygon_vertex_ptr_type;

  {******************************}
  { free lists for points, lines }
  {******************************}
  points_free_list: points_ptr_type;
  point_vertex_free_list: point_vertex_ptr_type;
  lines_free_list: lines_ptr_type;
  line_vertex_free_list: line_vertex_ptr_type;


{********************************}
{ routines for creating polygons }
{********************************}


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

  {********************}
  { initialize polygon }
  {********************}
  polygon_ptr^.vertices := 0;
  polygon_ptr^.vertex_ptr := nil;
  polygon_ptr^.next := nil;

  New_polygon := polygon_ptr;
end; {function New_polygon}


function New_polygon_vertex: polygon_vertex_ptr_type;
var
  vertex_ptr: polygon_vertex_ptr_type;
begin
  {***********************************}
  { get polygon vertex from free list }
  {***********************************}
  if (polygon_vertex_free_list <> nil) then
    begin
      vertex_ptr := polygon_vertex_free_list;
      polygon_vertex_free_list := polygon_vertex_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new polygon vertex');
      new(vertex_ptr);
    end;

  {***************************}
  { initialize polygon vertex }
  {***************************}
  vertex_ptr^.next := nil;

  New_polygon_vertex := vertex_ptr;
end; {function New_polygon_vertex}


procedure Add_polygon_vertex(polygon_ptr: polygon_ptr_type;
  point, texture: vector_type);
var
  vertex_ptr: polygon_vertex_ptr_type;
begin
  vertex_ptr := New_polygon_vertex;
  vertex_ptr^.point := point;
  vertex_ptr^.texture := texture;
  vertex_ptr^.next := polygon_ptr^.vertex_ptr;
  polygon_ptr^.vertex_ptr := vertex_ptr;
  polygon_ptr^.vertices := polygon_ptr^.vertices + 1;
end; {function Add_polygon_vertex}


procedure Free_polygon(var polygon_ptr: polygon_ptr_type);
var
  follow, vertex_ptr: polygon_vertex_ptr_type;
begin
  {***********************}
  { free polygon vertices }
  {***********************}
  follow := polygon_ptr^.vertex_ptr;
  while (follow <> nil) do
    begin
      vertex_ptr := follow;
      follow := follow^.next;
      vertex_ptr^.next := polygon_vertex_free_list;
      polygon_vertex_free_list := vertex_ptr;
    end;

  {**************************}
  { add polygon to free list }
  {**************************}
  polygon_ptr^.next := polygon_free_list;
  polygon_free_list := polygon_ptr;
  polygon_ptr := nil;
end; {procedure Free_polygon}



{***************************************}
{ routines for creating shaded polygons }
{***************************************}


function New_shaded_polygon: shaded_polygon_ptr_type;
var
  shaded_polygon_ptr: shaded_polygon_ptr_type;
begin
  {***********************************}
  { get shaded polygon from free list }
  {***********************************}
  if (shaded_polygon_free_list <> nil) then
    begin
      shaded_polygon_ptr := shaded_polygon_free_list;
      shaded_polygon_free_list := shaded_polygon_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new shaded polygon');
      new(shaded_polygon_ptr);
    end;

  {***************************}
  { initialize shaded polygon }
  {***************************}
  shaded_polygon_ptr^.vertices := 0;
  shaded_polygon_ptr^.vertex_ptr := nil;
  shaded_polygon_ptr^.next := nil;

  New_shaded_polygon := shaded_polygon_ptr;
end; {function New_shaded_polygon}


function New_shaded_polygon_vertex: shaded_polygon_vertex_ptr_type;
var
  vertex_ptr: shaded_polygon_vertex_ptr_type;
begin
  {******************************************}
  { get shaded polygon vertex from free list }
  {******************************************}
  if (shaded_polygon_vertex_free_list <> nil) then
    begin
      vertex_ptr := shaded_polygon_vertex_free_list;
      shaded_polygon_vertex_free_list := shaded_polygon_vertex_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new shaded polygon vertex');
      new(vertex_ptr);
    end;

  {**********************************}
  { initialize shaded polygon vertex }
  {**********************************}
  vertex_ptr^.next := nil;

  New_shaded_polygon_vertex := vertex_ptr;
end; {function New_shaded_polygon_vertex}


procedure Add_shaded_polygon_vertex(shaded_polygon_ptr: shaded_polygon_ptr_type;
  point, normal, texture: vector_type);
var
  vertex_ptr: shaded_polygon_vertex_ptr_type;
begin
  vertex_ptr := New_shaded_polygon_vertex;
  vertex_ptr^.point := point;
  vertex_ptr^.normal := normal;
  vertex_ptr^.texture := texture;
  vertex_ptr^.next := shaded_polygon_ptr^.vertex_ptr;
  shaded_polygon_ptr^.vertex_ptr := vertex_ptr;
  shaded_polygon_ptr^.vertices := shaded_polygon_ptr^.vertices + 1;
end; {function Add_shaded_polygon_vertex}


procedure Free_shaded_polygon(var shaded_polygon_ptr: shaded_polygon_ptr_type);
var
  follow, vertex_ptr: shaded_polygon_vertex_ptr_type;
begin
  {******************************}
  { free shaded polygon vertices }
  {******************************}
  follow := shaded_polygon_ptr^.vertex_ptr;
  while (follow <> nil) do
    begin
      vertex_ptr := follow;
      follow := follow^.next;
      vertex_ptr^.next := shaded_polygon_vertex_free_list;
      shaded_polygon_vertex_free_list := vertex_ptr;
    end;

  {*********************************}
  { add shaded_polygon to free list }
  {*********************************}
  shaded_polygon_ptr^.next := shaded_polygon_free_list;
  shaded_polygon_free_list := shaded_polygon_ptr;
  shaded_polygon_ptr := nil;
end; {procedure Free_shaded_polygon}


{******************************}
{ routines for creating points }
{******************************}


function New_points: points_ptr_type;
var
  points_ptr: points_ptr_type;
begin
  {***************************}
  { get points from free list }
  {***************************}
  if (points_free_list <> nil) then
    begin
      points_ptr := points_free_list;
      points_free_list := points_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new points');
      new(points_ptr);
    end;

  {*******************}
  { initialize points }
  {*******************}
  points_ptr^.vertices := 0;
  points_ptr^.vertex_ptr := nil;
  points_ptr^.next := nil;

  New_points := points_ptr;
end; {function New_points}


function New_point_vertex: point_vertex_ptr_type;
var
  vertex_ptr: point_vertex_ptr_type;
begin
  {*********************************}
  { get point vertex from free list }
  {*********************************}
  if (point_vertex_free_list <> nil) then
    begin
      vertex_ptr := point_vertex_free_list;
      point_vertex_free_list := point_vertex_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new point vertex');
      new(vertex_ptr);
    end;

  {*************************}
  { initialize point vertex }
  {*************************}
  vertex_ptr^.next := nil;

  New_point_vertex := vertex_ptr;
end; {function New_point_vertex}


procedure Add_point_vertex(points_ptr: points_ptr_type;
  point: vector_type);
var
  vertex_ptr: point_vertex_ptr_type;
begin
  vertex_ptr := New_point_vertex;
  vertex_ptr^.point := point;
  vertex_ptr^.next := points_ptr^.vertex_ptr;
  points_ptr^.vertex_ptr := vertex_ptr;
  points_ptr^.vertices := points_ptr^.vertices + 1;
end; {function Add_point_vertex}


procedure Free_points(var points_ptr: points_ptr_type);
var
  follow, vertex_ptr: point_vertex_ptr_type;
begin
  {*********************}
  { free point vertices }
  {*********************}
  follow := points_ptr^.vertex_ptr;
  while (follow <> nil) do
    begin
      vertex_ptr := follow;
      follow := follow^.next;

      vertex_ptr^.next := point_vertex_free_list;
      point_vertex_free_list := vertex_ptr;
    end;

  {*************************}
  { add points to free list }
  {*************************}
  points_ptr^.next := points_free_list;
  points_free_list := points_ptr;
  points_ptr := nil;
end; {procedure Free_points}


{*****************************}
{ routines for creating lines }
{*****************************}


function New_lines: lines_ptr_type;
var
  lines_ptr: lines_ptr_type;
begin
  {**************************}
  { get lines from free list }
  {**************************}
  if (lines_free_list <> nil) then
    begin
      lines_ptr := lines_free_list;
      lines_free_list := lines_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new lines');
      new(lines_ptr);
    end;

  {******************}
  { initialize lines }
  {******************}
  lines_ptr^.vertices := 0;
  lines_ptr^.vertex_ptr := nil;
  lines_ptr^.next := nil;

  New_lines := lines_ptr;
end; {function New_lines}


function New_line_vertex: line_vertex_ptr_type;
var
  vertex_ptr: line_vertex_ptr_type;
begin
  {********************************}
  { get line vertex from free list }
  {********************************}
  if (line_vertex_free_list <> nil) then
    begin
      vertex_ptr := line_vertex_free_list;
      line_vertex_free_list := line_vertex_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new line vertex');
      new(vertex_ptr);
    end;

  {************************}
  { initialize line vertex }
  {************************}
  vertex_ptr^.next := nil;

  New_line_vertex := vertex_ptr;
end; {function New_line_vertex}


procedure Add_line_vertex(lines_ptr: lines_ptr_type;
  point: vector_type);
var
  vertex_ptr: line_vertex_ptr_type;
begin
  vertex_ptr := New_line_vertex;
  vertex_ptr^.point := point;
  vertex_ptr^.next := lines_ptr^.vertex_ptr;
  lines_ptr^.vertex_ptr := vertex_ptr;
  lines_ptr^.vertices := lines_ptr^.vertices + 1;
end; {function Add_line_vertex}


procedure Free_lines(var lines_ptr: lines_ptr_type);
var
  follow, vertex_ptr: line_vertex_ptr_type;
begin
  {********************}
  { free line vertices }
  {********************}
  follow := lines_ptr^.vertex_ptr;
  while (follow <> nil) do
    begin
      vertex_ptr := follow;
      follow := follow^.next;

      vertex_ptr^.next := line_vertex_free_list;
      line_vertex_free_list := vertex_ptr;
    end;

  {************************}
  { add lines to free list }
  {************************}
  lines_ptr^.next := lines_free_list;
  lines_free_list := lines_ptr;
  lines_ptr := nil;
end; {procedure Free_lines}


initialization
  polygon_free_list := nil;
  polygon_vertex_free_list := nil;
  shaded_polygon_free_list := nil;
  shaded_polygon_vertex_free_list := nil;

  points_free_list := nil;
  point_vertex_free_list := nil;
  lines_free_list := nil;
  line_vertex_free_list := nil;
end.
