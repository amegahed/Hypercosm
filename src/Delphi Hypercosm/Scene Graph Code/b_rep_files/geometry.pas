unit geometry;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              geometry                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{      The geometry data structs are used to hold the           }
{      geometrical component of the b reps.                     }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors;


type
  {*************************************************}
  { at severe points of inflection on the surface   }
  { we can't simply have the vertex normals face    }
  { toward the face normal because the face normals }
  { won't all point in the same direction as the    }
  { vertex normal.  For these vertices, we must     }
  { use the same normal to shade all of the faces.  }
  {*************************************************}
  vertex_normal_kind_type = (one_sided_vertex, two_sided_vertex);


  point_geometry_ptr_type = ^point_geometry_type;
  point_geometry_type = record
    {*********************}
    { point geometry data }
    {*********************}
    point: vector_type;

    next: point_geometry_ptr_type;
  end; {point_geometry_type}


  vertex_geometry_ptr_type = ^vertex_geometry_type;
  vertex_geometry_type = record
    {**********************}
    { vertex geometry data }
    {**********************}
    normal: vector_type;
    vertex_normal_kind: vertex_normal_kind_type;
    texture: vector_type;
    u_axis: vector_type;
    v_axis: vector_type;

    next: vertex_geometry_ptr_type;
  end; {vertex_geometry_type}


  edge_geometry_ptr_type = ^edge_geometry_type;
  edge_geometry_type = record
    {********************}
    { edge geometry data }
    {********************}
    u_gradient: vector_type;
    v_gradient: vector_type;

    next: edge_geometry_ptr_type;
  end; {edge_geometry_type}


  face_geometry_ptr_type = ^face_geometry_type;
  face_geometry_type = record
    {********************}
    { face geometry data }
    {********************}
    normal: vector_type;

    next: face_geometry_ptr_type;
  end; {face_geometry_type}


  geometry_info_type = record
    vertex_normals_avail: boolean;
    vertex_vectors_avail: boolean;
    edge_gradients_avail: boolean;
    face_normals_avail: boolean;
  end; {geometry_info_type}


  geometry_ptr_type = ^geometry_type;
  geometry_type = record
    {****************}
    { geometry lists }
    {****************}
    point_geometry_ptr: point_geometry_ptr_type;
    last_point_geometry_ptr: point_geometry_ptr_type;

    vertex_geometry_ptr: vertex_geometry_ptr_type;
    last_vertex_geometry_ptr: vertex_geometry_ptr_type;

    edge_geometry_ptr: edge_geometry_ptr_type;
    last_edge_geometry_ptr: edge_geometry_ptr_type;

    face_geometry_ptr: face_geometry_ptr_type;
    last_face_geometry_ptr: face_geometry_ptr_type;

    {*********************************}
    { auxilliary geometry information }
    {*********************************}
    geometry_info: geometry_info_type;

    next: geometry_ptr_type;
  end; {geometry_type}


function New_geometry: geometry_ptr_type;
procedure Free_geometry(var geometry_ptr: geometry_ptr_type);

{****************************************}
{ routines to create geometry components }
{****************************************}
function New_point_geometry: point_geometry_ptr_type;
function New_vertex_geometry: vertex_geometry_ptr_type;
function New_edge_geometry: edge_geometry_ptr_type;
function New_face_geometry: face_geometry_ptr_type;

{**************************************}
{ routines to free geometry components }
{**************************************}
procedure Free_point_geometry(var point_geometry_ptr: point_geometry_ptr_type);
procedure Free_vertex_geometry(var vertex_geometry_ptr:
  vertex_geometry_ptr_type);
procedure Free_edge_geometry(var edge_geometry_ptr: edge_geometry_ptr_type);
procedure Free_face_geometry(var face_geometry_ptr: face_geometry_ptr_type);

{*******************************************}
{ routines to free geometry component lists }
{*******************************************}
procedure Free_geometry_points(geometry_ptr: geometry_ptr_type);
procedure Free_geometry_vertices(geometry_ptr: geometry_ptr_type);
procedure Free_geometry_edges(geometry_ptr: geometry_ptr_type);
procedure Free_geometry_faces(geometry_ptr: geometry_ptr_type);

{******************************}
{ routines to inspect geometry }
{******************************}
procedure Inspect_geometry(geometry_ptr: geometry_ptr_type);
function Num_geometry_points(point_geometry_ptr: point_geometry_ptr_type):
  integer;
function Num_geometry_vertices(vertex_geometry_ptr: vertex_geometry_ptr_type):
  integer;
function Num_geometry_edges(edge_geometry_ptr: edge_geometry_ptr_type):
  integer;
function Num_geometry_faces(face_geometry_ptr: face_geometry_ptr_type):
  integer;

{**********************************}
{ routines to write geometry enums }
{**********************************}
procedure Write_vertex_normal_kind(kind: vertex_normal_kind_type);


implementation
uses
  errors, new_memory;


const
  block_size = 512;
  memory_alert = false;


type
  {**********************************}
  { allocate blocks of these objects }
  { to speed memory allocation.      }
  {**********************************}

  {**********************}
  { geometry data blocks }
  {**********************}
  point_geometry_block_ptr_type = ^point_geometry_block_type;
  vertex_geometry_block_ptr_type = ^vertex_geometry_block_type;
  edge_geometry_block_ptr_type = ^edge_geometry_block_type;
  face_geometry_block_ptr_type = ^face_geometry_block_type;

  point_geometry_block_type = array[0..block_size] of point_geometry_type;
  vertex_geometry_block_type = array[0..block_size] of vertex_geometry_type;
  edge_geometry_block_type = array[0..block_size] of edge_geometry_type;
  face_geometry_block_type = array[0..block_size] of face_geometry_type;


var
  geometry_free_list: geometry_ptr_type;

  {*********************}
  { geometry free lists }
  {*********************}
  point_geometry_free_list: point_geometry_ptr_type;
  vertex_geometry_free_list: vertex_geometry_ptr_type;
  edge_geometry_free_list: edge_geometry_ptr_type;
  face_geometry_free_list: face_geometry_ptr_type;

  {*********************************}
  { ptrs and counters used in block }
  { allocation of b rep components  }
  {*********************************}

  {***************************************}
  { geometry data block ptrs and counters }
  {***************************************}
  point_geometry_block_ptr: point_geometry_block_ptr_type;
  vertex_geometry_block_ptr: vertex_geometry_block_ptr_type;
  edge_geometry_block_ptr: edge_geometry_block_ptr_type;
  face_geometry_block_ptr: face_geometry_block_ptr_type;

  point_geometry_counter: integer;
  vertex_geometry_counter: integer;
  edge_geometry_counter: integer;
  face_geometry_counter: integer;


procedure Init_geometry_info(var geometry_info: geometry_info_type);
begin
  with geometry_info do
    begin
      vertex_normals_avail := false;
      vertex_vectors_avail := false;
      edge_gradients_avail := false;
      face_normals_avail := false;
    end;
end; {procedure Init_geometry_info}


procedure Init_geometry_node(geometry_ptr: geometry_ptr_type);
begin
  with geometry_ptr^ do
    begin
      {***************************}
      { initialize geometry lists }
      {***************************}
      point_geometry_ptr := nil;
      last_point_geometry_ptr := nil;

      vertex_geometry_ptr := nil;
      last_vertex_geometry_ptr := nil;

      edge_geometry_ptr := nil;
      last_edge_geometry_ptr := nil;

      face_geometry_ptr := nil;
      last_face_geometry_ptr := nil;

      {********************************************}
      { initialize auxilliary geometry information }
      {********************************************}
      Init_geometry_info(geometry_info);

      next := nil;
    end;
end; {procedure Init_geometry_node}


function New_geometry: geometry_ptr_type;
var
  geometry_ptr: geometry_ptr_type;
begin
  {*****************************}
  { get geometry from free list }
  {*****************************}
  if (geometry_free_list <> nil) then
    begin
      geometry_ptr := geometry_free_list;
      geometry_free_list := geometry_ptr^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new geometry');
      new(geometry_ptr);
    end;

  {*********************}
  { initialize geometry }
  {*********************}
  Init_geometry_node(geometry_ptr);

  New_geometry := geometry_ptr;
end; {function New_geometry}


{*******************}
{ geometry elements }
{*******************}


function New_point_geometry: point_geometry_ptr_type;
var
  point_geometry_ptr: point_geometry_ptr_type;
  index: integer;
begin
  {***********************************}
  { get point geometry from free list }
  {***********************************}
  if (point_geometry_free_list <> nil) then
    begin
      point_geometry_ptr := point_geometry_free_list;
      point_geometry_free_list := point_geometry_ptr^.next;
    end
  else
    begin
      index := point_geometry_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new point geometry');
          new(point_geometry_block_ptr);
        end;
      point_geometry_ptr := @point_geometry_block_ptr^[index];
      point_geometry_counter := point_geometry_counter + 1;
    end;

  {***************************}
  { initialize point geometry }
  {***************************}
  point_geometry_ptr^.next := nil;

  New_point_geometry := point_geometry_ptr;
end; {function New_point_geometry}


function New_vertex_geometry: vertex_geometry_ptr_type;
var
  vertex_geometry_ptr: vertex_geometry_ptr_type;
  index: integer;
begin
  {************************************}
  { get vertex geometry from free list }
  {************************************}
  if (vertex_geometry_free_list <> nil) then
    begin
      vertex_geometry_ptr := vertex_geometry_free_list;
      vertex_geometry_free_list := vertex_geometry_ptr^.next;
    end
  else
    begin
      index := vertex_geometry_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new vertex geometry');
          new(vertex_geometry_block_ptr);
        end;
      vertex_geometry_ptr := @vertex_geometry_block_ptr^[index];
      vertex_geometry_counter := vertex_geometry_counter + 1;
    end;

  {****************************}
  { initialize vertex geometry }
  {****************************}
  vertex_geometry_ptr^.next := nil;
  vertex_geometry_ptr^.vertex_normal_kind := two_sided_vertex;

  New_vertex_geometry := vertex_geometry_ptr;
end; {function New_vertex_geometry}


function New_edge_geometry: edge_geometry_ptr_type;
var
  edge_geometry_ptr: edge_geometry_ptr_type;
  index: integer;
begin
  {**********************************}
  { get edge geometry from free list }
  {**********************************}
  if (edge_geometry_free_list <> nil) then
    begin
      edge_geometry_ptr := edge_geometry_free_list;
      edge_geometry_free_list := edge_geometry_ptr^.next;
    end
  else
    begin
      index := edge_geometry_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new edge geometry');
          new(edge_geometry_block_ptr);
        end;
      edge_geometry_ptr := @edge_geometry_block_ptr^[index];
      edge_geometry_counter := edge_geometry_counter + 1;
    end;

  {**************************}
  { initialize edge geometry }
  {**************************}
  edge_geometry_ptr^.next := nil;
  edge_geometry_ptr^.u_gradient := zero_vector;
  edge_geometry_ptr^.v_gradient := zero_vector;

  New_edge_geometry := edge_geometry_ptr;
end; {function New_edge_geometry}


function New_face_geometry: face_geometry_ptr_type;
var
  face_geometry_ptr: face_geometry_ptr_type;
  index: integer;
begin
  {**********************************}
  { get face geometry from free list }
  {**********************************}
  if (face_geometry_free_list <> nil) then
    begin
      face_geometry_ptr := face_geometry_free_list;
      face_geometry_free_list := face_geometry_ptr^.next;
    end
  else
    begin
      index := face_geometry_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new face geometry');
          new(face_geometry_block_ptr);
        end;
      face_geometry_ptr := @face_geometry_block_ptr^[index];
      face_geometry_counter := face_geometry_counter + 1;
    end;

  {**************************}
  { initialize face geometry }
  {**************************}
  face_geometry_ptr^.next := nil;

  New_face_geometry := face_geometry_ptr;
end; {function New_face_geometry}


{**************************************}
{ routines to free geometry components }
{**************************************}


procedure Free_point_geometry(var point_geometry_ptr: point_geometry_ptr_type);
begin
  point_geometry_ptr^.next := point_geometry_free_list;
  point_geometry_free_list := point_geometry_ptr;
  point_geometry_ptr := nil;
end; {procedure Free_point_geometry}


procedure Free_vertex_geometry(var vertex_geometry_ptr:
  vertex_geometry_ptr_type);
begin
  vertex_geometry_ptr^.next := vertex_geometry_free_list;
  vertex_geometry_free_list := vertex_geometry_ptr;
  vertex_geometry_ptr := nil;
end; {procedure Free_vertex_geometry}


procedure Free_edge_geometry(var edge_geometry_ptr: edge_geometry_ptr_type);
begin
  edge_geometry_ptr^.next := edge_geometry_free_list;
  edge_geometry_free_list := edge_geometry_ptr;
  edge_geometry_ptr := nil;
end; {procedure Free_edge_geometry}


procedure Free_face_geometry(var face_geometry_ptr: face_geometry_ptr_type);
begin
  face_geometry_ptr^.next := face_geometry_free_list;
  face_geometry_free_list := face_geometry_ptr;
  face_geometry_ptr := nil;
end; {procedure Free_face_geometry}


{*******************************************}
{ routines to free geometry component lists }
{*******************************************}


procedure Free_geometry_points(geometry_ptr: geometry_ptr_type);
begin
  {*********************************}
  { add point geometry to free list }
  {*********************************}
  if (geometry_ptr^.point_geometry_ptr <> nil) then
    begin
      geometry_ptr^.last_point_geometry_ptr^.next := point_geometry_free_list;
      point_geometry_free_list := geometry_ptr^.point_geometry_ptr;
      geometry_ptr^.point_geometry_ptr := nil;
      geometry_ptr^.last_point_geometry_ptr := nil;
    end;
end; {procedure Free_geometry_points}


procedure Free_geometry_vertices(geometry_ptr: geometry_ptr_type);
begin
  {**********************************}
  { add vertex geometry to free list }
  {**********************************}
  if (geometry_ptr^.vertex_geometry_ptr <> nil) then
    begin
      geometry_ptr^.last_vertex_geometry_ptr^.next := vertex_geometry_free_list;
      vertex_geometry_free_list := geometry_ptr^.vertex_geometry_ptr;
      geometry_ptr^.vertex_geometry_ptr := nil;
      geometry_ptr^.last_vertex_geometry_ptr := nil;
    end;
end; {procedure Free_geometry_vertices}


procedure Free_geometry_edges(geometry_ptr: geometry_ptr_type);
begin
  {********************************}
  { add edge geometry to free list }
  {********************************}
  if (geometry_ptr^.edge_geometry_ptr <> nil) then
    begin
      geometry_ptr^.last_edge_geometry_ptr^.next := edge_geometry_free_list;
      edge_geometry_free_list := geometry_ptr^.edge_geometry_ptr;
      geometry_ptr^.edge_geometry_ptr := nil;
      geometry_ptr^.last_edge_geometry_ptr := nil;
    end;
end; {procedure Free_geometry_edges}


procedure Free_geometry_faces(geometry_ptr: geometry_ptr_type);
begin
  {********************************}
  { add face geometry to free list }
  {********************************}
  if (geometry_ptr^.face_geometry_ptr <> nil) then
    begin
      geometry_ptr^.last_face_geometry_ptr^.next := face_geometry_free_list;
      face_geometry_free_list := geometry_ptr^.face_geometry_ptr;
      geometry_ptr^.face_geometry_ptr := nil;
      geometry_ptr^.last_face_geometry_ptr := nil;
    end;
end; {procedure Free_geometry_faces}


procedure Free_geometry(var geometry_ptr: geometry_ptr_type);
begin
  if (geometry_ptr <> nil) then
    begin
      {**************************}
      { free geometry components }
      {**************************}
      Free_geometry_points(geometry_ptr);
      Free_geometry_vertices(geometry_ptr);
      Free_geometry_edges(geometry_ptr);
      Free_geometry_faces(geometry_ptr);

      {***************************}
      { add geometry to free list }
      {***************************}
      geometry_ptr^.next := geometry_free_list;
      geometry_free_list := geometry_ptr;
      geometry_ptr := nil;
    end;
end; {procedure Free_geometry}


{***********************************************}
{ routines to find the length of geometry lists }
{***********************************************}


function Num_geometry_points(point_geometry_ptr: point_geometry_ptr_type):
  integer;
var
  point_number: integer;
begin
  {**************}
  { count points }
  {**************}
  point_number := 0;
  while (point_geometry_ptr <> nil) do
    begin
      point_number := point_number + 1;
      point_geometry_ptr := point_geometry_ptr^.next;
    end;

  Num_geometry_points := point_number;
end; {function Num_geometry_points}


function Num_geometry_vertices(vertex_geometry_ptr: vertex_geometry_ptr_type):
  integer;
var
  vertex_number: integer;
begin
  {****************}
  { count vertices }
  {****************}
  vertex_number := 0;
  while (vertex_geometry_ptr <> nil) do
    begin
      vertex_number := vertex_number + 1;
      vertex_geometry_ptr := vertex_geometry_ptr^.next;
    end;

  Num_geometry_vertices := vertex_number;
end; {function Num_geometry_vertices}


function Num_geometry_edges(edge_geometry_ptr: edge_geometry_ptr_type): integer;
var
  edge_number: integer;
begin
  {*************}
  { count edges }
  {*************}
  edge_number := 0;
  while (edge_geometry_ptr <> nil) do
    begin
      edge_number := edge_number + 1;
      edge_geometry_ptr := edge_geometry_ptr^.next;
    end;

  Num_geometry_edges := edge_number;
end; {function Num_geometry_edges}


function Num_geometry_faces(face_geometry_ptr: face_geometry_ptr_type): integer;
var
  face_number: integer;
begin
  {*************}
  { count faces }
  {*************}
  face_number := 0;
  while (face_geometry_ptr <> nil) do
    begin
      face_number := face_number + 1;
      face_geometry_ptr := face_geometry_ptr^.next;
    end;

  Num_geometry_faces := face_number;
end; {function Num_geometry_faces}


procedure Inspect_geometry(geometry_ptr: geometry_ptr_type);
begin
  if (geometry_ptr <> nil) then
    begin
      writeln('number of point geometries = ',
        Num_geometry_points(geometry_ptr^.point_geometry_ptr));
      writeln('number of vertex geometries = ',
        Num_geometry_vertices(geometry_ptr^.vertex_geometry_ptr));
      writeln('number of edge geometries = ',
        Num_geometry_edges(geometry_ptr^.edge_geometry_ptr));
      writeln('number of face geometries = ',
        Num_geometry_faces(geometry_ptr^.face_geometry_ptr));
    end
  else
    writeln('nil geometry');
end; {procedure Inspect_geometry}


procedure Write_vertex_normal_kind(kind: vertex_normal_kind_type);
begin
  case kind of
    one_sided_vertex:
      write('one_sided_vertex');
    two_sided_vertex:
      write('two_sided_vertex');
  end;
end; {procedure Write_vertex_normal_kind}


initialization
  {***********************}
  { initialize free lists }
  {***********************}
  geometry_free_list := nil;
  point_geometry_free_list := nil;
  vertex_geometry_free_list := nil;
  edge_geometry_free_list := nil;
  face_geometry_free_list := nil;

  {********************************}
  { initialize vars used in block  }
  { allocation of b rep components }
  {********************************}
  point_geometry_counter := 0;
  vertex_geometry_counter := 0;
  edge_geometry_counter := 0;
  face_geometry_counter := 0;

  point_geometry_block_ptr := nil;
  vertex_geometry_block_ptr := nil;
  edge_geometry_block_ptr := nil;
  face_geometry_block_ptr := nil;
end.

