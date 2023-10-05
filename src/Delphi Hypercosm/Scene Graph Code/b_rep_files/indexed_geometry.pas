unit indexed_geometry;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          indexed_geometry             3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{      The geometry data structs are used to hold the           }
{      indexed geometrical component of the b reps.             }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  geometry;


type
  indexed_geometry_ptr_type = ^indexed_geometry_type;
  indexed_geometry_type = record
    point_number: integer;
    vertex_number: integer;
    edge_number: integer;
    face_number: integer;

    point_geometry_table_ptr: point_geometry_ptr_type;
    vertex_geometry_table_ptr: vertex_geometry_ptr_type;
    edge_geometry_table_ptr: edge_geometry_ptr_type;
    face_geometry_table_ptr: face_geometry_ptr_type;

    next: indexed_geometry_ptr_type;
  end; {indexed_geometry_type}


function New_indexed_geometry(var geometry_ptr: geometry_ptr_type):
  indexed_geometry_ptr_type;
procedure Free_indexed_geometry(var indexed_geometry_ptr:
  indexed_geometry_ptr_type);

{***************************************}
{ routines to index geometry components }
{***************************************}
function Index_point_geometry(indexed_geometry_ptr:
  indexed_geometry_ptr_type;
  point_index: integer): point_geometry_ptr_type;
function Index_vertex_geometry(indexed_geometry_ptr:
  indexed_geometry_ptr_type;
  vertex_index: integer): vertex_geometry_ptr_type;
function Index_edge_geometry(indexed_geometry_ptr:
  indexed_geometry_ptr_type;
  edge_index: integer): edge_geometry_ptr_type;
function Index_face_geometry(indexed_geometry_ptr:
  indexed_geometry_ptr_type;
  face_index: integer): face_geometry_ptr_type;


implementation
uses
  errors, new_memory;


const
  memory_alert = false;


var
  indexed_geometry_free_list: indexed_geometry_ptr_type;


{********************************************************}
{ routines to create geometry tables from geometry lists }
{********************************************************}


function New_point_geometry_table(point_geometry_ptr: point_geometry_ptr_type;
  var point_number: integer): point_geometry_ptr_type;
var
  size: longint;
  point_geometry_table_ptr: point_geometry_ptr_type;
  next_point_geometry_ptr: point_geometry_ptr_type;
begin
  point_number := Num_geometry_points(point_geometry_ptr);

  {*****************************************}
  { allocate space for point geometry table }
  {*****************************************}
  if (point_number > 0) then
    begin
      size := sizeof(point_geometry_type) * point_number;
      if memory_alert then
        writeln('allocating new point geometry table');
      point_geometry_table_ptr := point_geometry_ptr_type(New_ptr(size));
    end
  else
    point_geometry_table_ptr := nil;

  {*********************************************}
  { copy point geometry data from list to table }
  {*********************************************}
  while (point_geometry_ptr <> nil) do
    begin
      point_geometry_table_ptr^ := point_geometry_ptr^;
      next_point_geometry_ptr :=
        point_geometry_ptr_type(longint(point_geometry_table_ptr) +
        sizeof(point_geometry_type));

      if (point_geometry_ptr^.next <> nil) then
        point_geometry_table_ptr^.next := next_point_geometry_ptr
      else
        point_geometry_table_ptr^.next := nil;

      point_geometry_table_ptr := next_point_geometry_ptr;
      point_geometry_ptr := point_geometry_ptr^.next;
    end;

  New_point_geometry_table := point_geometry_table_ptr;
end; {function New_point_geometry_table}


function New_vertex_geometry_table(vertex_geometry_ptr: vertex_geometry_ptr_type;
  var vertex_number: integer): vertex_geometry_ptr_type;
var
  size: longint;
  vertex_geometry_table_ptr: vertex_geometry_ptr_type;
  next_vertex_geometry_ptr: vertex_geometry_ptr_type;
begin
  vertex_number := Num_geometry_vertices(vertex_geometry_ptr);

  {******************************************}
  { allocate space for vertex geometry table }
  {******************************************}
  if (vertex_number > 0) then
    begin
      size := sizeof(vertex_geometry_type) * vertex_number;
      if memory_alert then
        writeln('allocating new vertex geometry table');
      vertex_geometry_table_ptr := vertex_geometry_ptr_type(New_ptr(size));
    end
  else
    vertex_geometry_table_ptr := nil;

  {**********************************************}
  { copy vertex geometry data from list to table }
  {**********************************************}
  while (vertex_geometry_ptr <> nil) do
    begin
      vertex_geometry_table_ptr^ := vertex_geometry_ptr^;
      next_vertex_geometry_ptr :=
        vertex_geometry_ptr_type(longint(vertex_geometry_table_ptr) +
        sizeof(vertex_geometry_type));

      if (vertex_geometry_ptr^.next <> nil) then
        vertex_geometry_table_ptr^.next := next_vertex_geometry_ptr
      else
        vertex_geometry_table_ptr^.next := nil;

      vertex_geometry_table_ptr := next_vertex_geometry_ptr;
      vertex_geometry_ptr := vertex_geometry_ptr^.next;
    end;

  New_vertex_geometry_table := vertex_geometry_table_ptr;
end; {function New_vertex_geometry_table}


function New_edge_geometry_table(edge_geometry_ptr: edge_geometry_ptr_type;
  var edge_number: integer): edge_geometry_ptr_type;
var
  size: longint;
  edge_geometry_table_ptr: edge_geometry_ptr_type;
  next_edge_geometry_ptr: edge_geometry_ptr_type;
begin
  edge_number := Num_geometry_edges(edge_geometry_ptr);

  {****************************************}
  { allocate space for edge geometry table }
  {****************************************}
  if (edge_number > 0) then
    begin
      size := sizeof(edge_geometry_type) * edge_number;
      if memory_alert then
        writeln('allocating new edge geometry table');
      edge_geometry_table_ptr := edge_geometry_ptr_type(New_ptr(size));
    end
  else
    edge_geometry_table_ptr := nil;

  {********************************************}
  { copy edge geometry data from list to table }
  {********************************************}
  while (edge_geometry_ptr <> nil) do
    begin
      edge_geometry_table_ptr^ := edge_geometry_ptr^;
      next_edge_geometry_ptr :=
        edge_geometry_ptr_type(longint(edge_geometry_table_ptr) +
        sizeof(edge_geometry_type));

      if (edge_geometry_ptr^.next <> nil) then
        edge_geometry_table_ptr^.next := next_edge_geometry_ptr
      else
        edge_geometry_table_ptr^.next := nil;

      edge_geometry_table_ptr := next_edge_geometry_ptr;
      edge_geometry_ptr := edge_geometry_ptr^.next;
    end;

  New_edge_geometry_table := edge_geometry_table_ptr;
end; {function New_edge_geometry_table}


function New_face_geometry_table(face_geometry_ptr: face_geometry_ptr_type;
  var face_number: integer): face_geometry_ptr_type;
var
  size: longint;
  face_geometry_table_ptr: face_geometry_ptr_type;
  next_face_geometry_ptr: face_geometry_ptr_type;
begin
  face_number := Num_geometry_faces(face_geometry_ptr);

  {****************************************}
  { allocate space for face geometry table }
  {****************************************}
  if (face_number > 0) then
    begin
      size := sizeof(face_geometry_type) * face_number;
      if memory_alert then
        writeln('allocating new face geometry table');
      face_geometry_table_ptr := face_geometry_ptr_type(New_ptr(size));
    end
  else
    face_geometry_table_ptr := nil;

  {********************************************}
  { copy face geometry data from list to table }
  {********************************************}
  while (face_geometry_ptr <> nil) do
    begin
      face_geometry_table_ptr^ := face_geometry_ptr^;
      next_face_geometry_ptr :=
        face_geometry_ptr_type(longint(face_geometry_table_ptr) +
        sizeof(face_geometry_type));

      if (face_geometry_ptr^.next <> nil) then
        face_geometry_table_ptr^.next := next_face_geometry_ptr
      else
        face_geometry_table_ptr^.next := nil;

      face_geometry_table_ptr := next_face_geometry_ptr;
      face_geometry_ptr := face_geometry_ptr^.next;
    end;

  New_face_geometry_table := face_geometry_table_ptr;
end; {function New_face_geometry_table}


{************************************************}
{ routines to allocated and free geometry tables }
{************************************************}


procedure Init_indexed_geometry(indexed_geometry_ptr: indexed_geometry_ptr_type;
  geometry_ptr: geometry_ptr_type);
begin
  {********************************************}
  { create geometry tables from geometry lists }
  {********************************************}
  indexed_geometry_ptr^.point_geometry_table_ptr := New_point_geometry_table(
    geometry_ptr^.point_geometry_ptr, indexed_geometry_ptr^.point_number);
  indexed_geometry_ptr^.vertex_geometry_table_ptr := New_vertex_geometry_table(
    geometry_ptr^.vertex_geometry_ptr, indexed_geometry_ptr^.vertex_number);
  indexed_geometry_ptr^.edge_geometry_table_ptr := New_edge_geometry_table(
    geometry_ptr^.edge_geometry_ptr, indexed_geometry_ptr^.edge_number);
  indexed_geometry_ptr^.face_geometry_table_ptr := New_face_geometry_table(
    geometry_ptr^.face_geometry_ptr, indexed_geometry_ptr^.face_number);

  {*********************}
  { free geometry lists }
  {*********************}
  Free_geometry_points(geometry_ptr);
  Free_geometry_vertices(geometry_ptr);
  Free_geometry_edges(geometry_ptr);
  Free_geometry_faces(geometry_ptr);
end; {procedure Init_indexed_geometry}


function New_indexed_geometry(var geometry_ptr: geometry_ptr_type):
  indexed_geometry_ptr_type;
var
  indexed_geometry_ptr: indexed_geometry_ptr_type;
begin
  {*************************************}
  { get indexed geometry from free list }
  {*************************************}
  if (indexed_geometry_free_list <> nil) then
    begin
      indexed_geometry_ptr := indexed_geometry_free_list;
      indexed_geometry_free_list := indexed_geometry_ptr^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new indexed geometry');
      new(indexed_geometry_ptr);
    end;

  {*****************************}
  { initialize indexed geometry }
  {*****************************}
  Init_indexed_geometry(indexed_geometry_ptr, geometry_ptr);
  indexed_geometry_ptr^.next := nil;

  New_indexed_geometry := indexed_geometry_ptr;
end; {function New_indexed_geometry}


procedure Free_indexed_geometry(var indexed_geometry_ptr:
  indexed_geometry_ptr_type);
begin
  if (indexed_geometry_ptr <> nil) then
    begin
      {**********************}
      { free geometry tables }
      {**********************}
      Free_ptr(ptr_type(indexed_geometry_ptr^.point_geometry_table_ptr));
      Free_ptr(ptr_type(indexed_geometry_ptr^.vertex_geometry_table_ptr));
      Free_ptr(ptr_type(indexed_geometry_ptr^.edge_geometry_table_ptr));
      Free_ptr(ptr_type(indexed_geometry_ptr^.face_geometry_table_ptr));

      {***********************************}
      { add indexed geometry to free list }
      {***********************************}
      indexed_geometry_ptr^.next := indexed_geometry_free_list;
      indexed_geometry_free_list := indexed_geometry_ptr;
      indexed_geometry_ptr := nil;
    end;
end; {procedure Free_indexed_geometry}


{***************************************}
{ routines to index geometry components }
{***************************************}


function Index_point_geometry(indexed_geometry_ptr:
  indexed_geometry_ptr_type;
  point_index: integer): point_geometry_ptr_type;
var
  offset: longint;
begin
  offset := point_index * sizeof(point_geometry_type);
  Index_point_geometry := point_geometry_ptr_type(longint(indexed_geometry_ptr^.
    point_geometry_table_ptr) + offset);
end; {function Index_point_geometry}


function Index_vertex_geometry(indexed_geometry_ptr:
  indexed_geometry_ptr_type;
  vertex_index: integer): vertex_geometry_ptr_type;
var
  offset: longint;
begin
  offset := vertex_index * sizeof(vertex_geometry_type);
  Index_vertex_geometry := vertex_geometry_ptr_type(longint(indexed_geometry_ptr^.
    vertex_geometry_table_ptr) + offset);
end; {function Index_vertex_geometry}


function Index_edge_geometry(indexed_geometry_ptr:
  indexed_geometry_ptr_type;
  edge_index: integer): edge_geometry_ptr_type;
var
  offset: longint;
begin
  offset := edge_index * sizeof(edge_geometry_type);
  Index_edge_geometry := edge_geometry_ptr_type(longint(indexed_geometry_ptr^.
    edge_geometry_table_ptr) + offset);
end; {function Index_edge_geometry}


function Index_face_geometry(indexed_geometry_ptr:
  indexed_geometry_ptr_type;
  face_index: integer): face_geometry_ptr_type;
var
  offset: longint;
begin
  offset := face_index * sizeof(face_geometry_type);
  Index_face_geometry := face_geometry_ptr_type(longint(indexed_geometry_ptr^.
    face_geometry_table_ptr) + offset);
end; {function Index_face_geometry}


initialization
  indexed_geometry_free_list := nil;
end.



