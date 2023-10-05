unit topology;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              topology                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{      The topology data structs are used to hold the           }
{      topological component of the b reps.                     }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, geometry;


type
  point_ptr_type = ^point_type;
  vertex_ptr_type = ^vertex_type;
  edge_ptr_type = ^edge_type;
  face_ptr_type = ^face_type;


  edge_ref_ptr_type = ^edge_ref_type;
  edge_ref_type = record
    edge_ptr: edge_ptr_type;
    next: edge_ref_ptr_type;
  end; {edge_ref_type}


  face_ref_ptr_type = ^face_ref_type;
  face_ref_type = record
    face_ptr: face_ptr_type;
    touched: boolean;
    next: face_ref_ptr_type;
  end; {face_ref_type}


  {***********************}
  { point data structures }
  {***********************}
  point_type = record
    point_geometry_ptr: point_geometry_ptr_type;
    edge_list: edge_ref_ptr_type;
    real_point: boolean;
    pseudo_point: boolean;
    index: integer;
    next: point_ptr_type;
  end; {point_type record}


  {************************}
  { vertex data structures }
  {************************}
  vertex_type = record
    vertex_geometry_ptr: vertex_geometry_ptr_type;
    face_list: face_ref_ptr_type;
    point_ptr: point_ptr_type;
    index: integer;
    next: vertex_ptr_type;
  end; {vertex_type}


  {**********************}
  { edge data structures }
  {**********************}
  edge_kind_type = (real_edge, pseudo_edge, fake_edge, duplicate_edge);
  edge_type = record
    edge_geometry_ptr: edge_geometry_ptr_type;
    point_ptr1, point_ptr2: point_ptr_type;
    vertex_ptr1, vertex_ptr2: vertex_ptr_type;
    edge_kind: edge_kind_type;

    {***********************************************}
    { if edge_kind = duplicate_edge, then we need a }
    { pointer to the edge which this one duplicates }
    { so it can know its correct face neighbors.    }
    {***********************************************}
    duplicate_edge_ptr: edge_ptr_type;
    face_list: face_ref_ptr_type;
    index: integer;
    next: edge_ptr_type;
  end; {edge_type}


  {**********************}
  { face data structures }
  {**********************}
  directed_edge_ptr_type = ^directed_edge_type;
  cycle_ptr_type = ^cycle_type;


  directed_edge_type = record
    orientation: boolean;
    edge_ptr: edge_ptr_type;
    cycle_ptr: cycle_ptr_type;
    next: directed_edge_ptr_type;
  end; {directed_edge_type}


  cycle_type = record
    directed_edge_ptr: directed_edge_ptr_type;
    face_ptr: face_ptr_type;
    next: cycle_ptr_type;
  end; {cycle_type}


  face_type = record
    cycle_ptr: cycle_ptr_type;
    face_geometry_ptr: face_geometry_ptr_type;
    index: integer;
    next: face_ptr_type;
  end; {face_type}


  topology_ptr_type = ^topology_type;
  topology_type = record
    point_ptr: point_ptr_type;
    vertex_ptr: vertex_ptr_type;
    edge_ptr: edge_ptr_type;
    face_ptr: face_ptr_type;

    last_point_ptr: point_ptr_type;
    last_vertex_ptr: vertex_ptr_type;
    last_edge_ptr: edge_ptr_type;
    last_face_ptr: face_ptr_type;

    point_number: integer;
    vertex_number: integer;
    edge_number: integer;
    face_number: integer;
    edge_ref_number: longint;
    face_ref_number: longint;
    directed_edge_number: longint;
    cycle_number: longint;

    {******************************************************}
    { this tells if all the vertices of the surface are on }
    { the perimeter edges of the surface, as in cylinders, }
    { blocks, and polygons verses surfaces with vertices   }
    { that don't belong to any edge such as spheres, etc.  }
    { This flag speeds up finding the silhouette vertices. }
    {******************************************************}
    perimeter_vertices: boolean;

    reference_count: integer;
    next: topology_ptr_type;
  end; {topology_type}


  {********************}
  { topology interface }
  {********************}
function New_topology: topology_ptr_type;
function Copy_topology(topology_ptr: topology_ptr_type): topology_ptr_type;
procedure Free_topology(var topology_ptr: topology_ptr_type);

{*****************************************}
{ routines to write out stats on topology }
{*****************************************}
procedure Report_topology(topology_ptr: topology_ptr_type);
procedure Inspect_topology(topology_ptr: topology_ptr_type);

{*********************************************************}
{ routines to allocate and initialize topology components }
{*********************************************************}
function New_point: point_ptr_type;
function New_vertex: vertex_ptr_type;
function New_edge: edge_ptr_type;
function New_edge_ref: edge_ref_ptr_type;
function New_face_ref: face_ref_ptr_type;
function New_directed_edge: directed_edge_ptr_type;
function New_cycle: cycle_ptr_type;
function New_face: face_ptr_type;

{**********************************}
{ routines to write out enum types }
{**********************************}
procedure Write_edge_kind(edge_kind: edge_kind_type);


implementation
uses
  new_memory;


const
  block_size = 512;
  memory_alert = false;


type
  {**********************************}
  { allocate blocks of these objects }
  { to speed memory allocation.      }
  {**********************************}

  {**********************}
  { topology data blocks }
  {**********************}
  point_block_ptr_type = ^point_block_type;
  vertex_block_ptr_type = ^vertex_block_type;
  edge_block_ptr_type = ^edge_block_type;
  edge_ref_block_ptr_type = ^edge_ref_block_type;
  face_ref_block_ptr_type = ^face_ref_block_type;
  directed_edge_block_ptr_type = ^directed_edge_block_type;
  cycle_block_ptr_type = ^cycle_block_type;
  face_block_ptr_type = ^face_block_type;

  point_block_type = array[0..block_size] of point_type;
  vertex_block_type = array[0..block_size] of vertex_type;
  edge_block_type = array[0..block_size] of edge_type;
  edge_ref_block_type = array[0..block_size] of edge_ref_type;
  face_ref_block_type = array[0..block_size] of face_ref_type;
  directed_edge_block_type = array[0..block_size] of directed_edge_type;
  cycle_block_type = array[0..block_size] of cycle_type;
  face_block_type = array[0..block_size] of face_type;


var
  topology_free_list: topology_ptr_type;

  {*********************}
  { topology free lists }
  {*********************}
  point_free_list: point_ptr_type;
  vertex_free_list: vertex_ptr_type;
  edge_free_list: edge_ptr_type;
  edge_ref_free_list: edge_ref_ptr_type;
  face_ref_free_list: face_ref_ptr_type;
  directed_edge_free_list: directed_edge_ptr_type;
  cycle_free_list: cycle_ptr_type;
  face_free_list: face_ptr_type;

  {*********************************}
  { ptrs and counters used in block }
  { allocation of b rep components  }
  {*********************************}

  {***************************************}
  { topology data block ptrs and counters }
  {***************************************}
  point_block_ptr: point_block_ptr_type;
  vertex_block_ptr: vertex_block_ptr_type;
  edge_block_ptr: edge_block_ptr_type;
  edge_ref_block_ptr: edge_ref_block_ptr_type;
  face_ref_block_ptr: face_ref_block_ptr_type;
  directed_edge_block_ptr: directed_edge_block_ptr_type;
  cycle_block_ptr: cycle_block_ptr_type;
  face_block_ptr: face_block_ptr_type;

  point_counter: longint;
  vertex_counter: longint;
  edge_counter: longint;
  edge_ref_counter: longint;
  face_ref_counter: longint;
  directed_edge_counter: longint;
  cycle_counter: longint;
  face_counter: longint;


procedure Init_topology_node(topology_ptr: topology_ptr_type);
begin
  with topology_ptr^ do
    begin
      point_ptr := nil;
      vertex_ptr := nil;
      edge_ptr := nil;
      face_ptr := nil;

      last_point_ptr := nil;
      last_vertex_ptr := nil;
      last_edge_ptr := nil;
      last_face_ptr := nil;

      point_number := 0;
      vertex_number := 0;
      edge_number := 0;
      face_number := 0;
      edge_ref_number := 0;
      face_ref_number := 0;
      directed_edge_number := 0;
      cycle_number := 0;

      perimeter_vertices := false;
      reference_count := 1;
      next := nil;
    end;
end; {procedure Init_topology_node}


function New_topology: topology_ptr_type;
var
  topology_ptr: topology_ptr_type;
begin
  {*****************************}
  { get topology from free list }
  {*****************************}
  if (topology_free_list <> nil) then
    begin
      topology_ptr := topology_free_list;
      topology_free_list := topology_ptr^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new topology');
      new(topology_ptr);
    end;

  {*********************}
  { initialize topology }
  {*********************}
  Init_topology_node(topology_ptr);

  New_topology := topology_ptr;
end; {function New_topology}


function Copy_topology(topology_ptr: topology_ptr_type): topology_ptr_type;
begin
  topology_ptr^.reference_count := topology_ptr^.reference_count + 1;
  Copy_topology := topology_ptr;
end; {function Copy_topology}


{*******************}
{ topology elements }
{*******************}


function New_point: point_ptr_type;
var
  point_ptr: point_ptr_type;
  index: integer;
begin
  {**************************}
  { get point from free list }
  {**************************}
  if (point_free_list <> nil) then
    begin
      point_ptr := point_free_list;
      point_free_list := point_ptr^.next;
    end
  else
    begin
      index := point_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new point block');
          new(point_block_ptr);
        end;
      point_ptr := @point_block_ptr^[index];
      point_counter := point_counter + 1;
    end;

  {******************}
  { initialize point }
  {******************}
  with point_ptr^ do
    begin
      real_point := false;
      pseudo_point := false;
      point_geometry_ptr := nil;
      edge_list := nil;
      index := 0;
      next := nil;
    end;

  New_point := point_ptr;
end; {function New_point}


function New_vertex: vertex_ptr_type;
var
  vertex_ptr: vertex_ptr_type;
  index: integer;
begin
  {***************************}
  { get vertex from free list }
  {***************************}
  if (vertex_free_list <> nil) then
    begin
      vertex_ptr := vertex_free_list;
      vertex_free_list := vertex_ptr^.next;
    end
  else
    begin
      index := vertex_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new vertex block');
          new(vertex_block_ptr);
        end;
      vertex_ptr := @vertex_block_ptr^[index];
      vertex_counter := vertex_counter + 1;
    end;

  {*******************}
  { initialize vertex }
  {*******************}
  with vertex_ptr^ do
    begin
      vertex_geometry_ptr := nil;
      face_list := nil;
      point_ptr := nil;
      index := 0;
      next := nil;
    end;

  New_vertex := vertex_ptr;
end; {function New_vertex}


function New_edge: edge_ptr_type;
var
  edge_ptr: edge_ptr_type;
  index: integer;
begin
  {*************************}
  { get edge from free list }
  {*************************}
  if (edge_free_list <> nil) then
    begin
      edge_ptr := edge_free_list;
      edge_free_list := edge_ptr^.next;
    end
  else
    begin
      index := edge_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new edge block');
          new(edge_block_ptr);
        end;
      edge_ptr := @edge_block_ptr^[index];
      edge_counter := edge_counter + 1;
    end;

  {*****************}
  { initialize edge }
  {*****************}
  with edge_ptr^ do
    begin
      edge_geometry_ptr := nil;
      vertex_ptr1 := nil;
      vertex_ptr2 := nil;
      face_list := nil;
      index := 0;
      next := nil;
    end;

  New_edge := edge_ptr;
end; {function New_edge}


function New_edge_ref: edge_ref_ptr_type;
var
  edge_ref_ptr: edge_ref_ptr_type;
  index: integer;
begin
  {*****************************}
  { get edge_ref from free list }
  {*****************************}
  if (edge_ref_free_list <> nil) then
    begin
      edge_ref_ptr := edge_ref_free_list;
      edge_ref_free_list := edge_ref_ptr^.next;
    end
  else
    begin
      index := edge_ref_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new edge ref block');
          new(edge_ref_block_ptr);
        end;
      edge_ref_ptr := @edge_ref_block_ptr^[index];
      edge_ref_counter := edge_ref_counter + 1;
    end;

  {*********************}
  { initialize edge ref }
  {*********************}
  with edge_ref_ptr^ do
    begin
      edge_ptr := nil;
      next := nil;
    end;

  New_edge_ref := edge_ref_ptr;
end; {function New_edge_ref}


function New_face_ref: face_ref_ptr_type;
var
  face_ref_ptr: face_ref_ptr_type;
  index: integer;
begin
  {*****************************}
  { get face ref from free list }
  {*****************************}
  if (face_ref_free_list <> nil) then
    begin
      face_ref_ptr := face_ref_free_list;
      face_ref_free_list := face_ref_ptr^.next;
    end
  else
    begin
      index := face_ref_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new face ref block');
          new(face_ref_block_ptr);
        end;
      face_ref_ptr := @face_ref_block_ptr^[index];
      face_ref_counter := face_ref_counter + 1;
    end;

  {*********************}
  { initialize face ref }
  {*********************}
  with face_ref_ptr^ do
    begin
      face_ptr := nil;
      touched := false;
      next := nil;
    end;

  New_face_ref := face_ref_ptr;
end; {function New_face_ref}


function New_directed_edge: directed_edge_ptr_type;
var
  directed_edge_ptr: directed_edge_ptr_type;
  index: integer;
begin
  {**********************************}
  { get directed edge from free list }
  {**********************************}
  if (directed_edge_free_list <> nil) then
    begin
      directed_edge_ptr := directed_edge_free_list;
      directed_edge_free_list := directed_edge_ptr^.next;
    end
  else
    begin
      index := directed_edge_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new directed edge block');
          new(directed_edge_block_ptr);
        end;
      directed_edge_ptr := @directed_edge_block_ptr^[index];
      directed_edge_counter := directed_edge_counter + 1;
    end;

  {**************************}
  { initialize directed edge }
  {**************************}
  with directed_edge_ptr^ do
    begin
      edge_ptr := nil;
      cycle_ptr := nil;
      next := nil;
    end;

  New_directed_edge := directed_edge_ptr;
end; {function New_directed_edge}


function New_cycle: cycle_ptr_type;
var
  cycle_ptr: cycle_ptr_type;
  index: integer;
begin
  {**************************}
  { get cycle from free list }
  {**************************}
  if (cycle_free_list <> nil) then
    begin
      cycle_ptr := cycle_free_list;
      cycle_free_list := cycle_ptr^.next;
    end
  else
    begin
      index := cycle_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new cycle block');
          new(cycle_block_ptr);
        end;
      cycle_ptr := @cycle_block_ptr^[index];
      cycle_counter := cycle_counter + 1;
    end;

  {******************}
  { initialize cycle }
  {******************}
  with cycle_ptr^ do
    begin
      directed_edge_ptr := nil;
      face_ptr := nil;
      next := nil;
    end;

  New_cycle := cycle_ptr;
end; {function New_cycle}


function New_face: face_ptr_type;
var
  face_ptr: face_ptr_type;
  index: integer;
begin
  {*************************}
  { get face from free list }
  {*************************}
  if (face_free_list <> nil) then
    begin
      face_ptr := face_free_list;
      face_free_list := face_ptr^.next;
    end
  else
    begin
      index := face_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new face block');
          new(face_block_ptr);
        end;
      face_ptr := @face_block_ptr^[index];
      face_counter := face_counter + 1;
    end;

  {*****************}
  { initialize face }
  {*****************}
  with face_ptr^ do
    begin
      face_geometry_ptr := nil;
      cycle_ptr := nil;
      index := 0;
      next := nil;
    end;

  New_face := face_ptr;
end; {function New_face}


{***************************}
{ routines to free topology }
{***************************}


procedure Free_edge_refs(var edge_refs_ptr: edge_ref_ptr_type);
var
  first_edge_ref_ptr, last_edge_ref_ptr: edge_ref_ptr_type;
begin
  if edge_refs_ptr <> nil then
    begin
      first_edge_ref_ptr := edge_refs_ptr;
      last_edge_ref_ptr := nil;

      while edge_refs_ptr <> nil do
        begin
          last_edge_ref_ptr := edge_refs_ptr;
          edge_refs_ptr := edge_refs_ptr^.next;
        end;

      last_edge_ref_ptr^.next := edge_ref_free_list;
      edge_ref_free_list := first_edge_ref_ptr;
    end;
end; {procedure Free_edge_refs}


procedure Free_face_refs(var face_refs_ptr: face_ref_ptr_type);
var
  first_face_ref_ptr, last_face_ref_ptr: face_ref_ptr_type;
begin
  if face_refs_ptr <> nil then
    begin
      first_face_ref_ptr := face_refs_ptr;
      last_face_ref_ptr := nil;

      while face_refs_ptr <> nil do
        begin
          last_face_ref_ptr := face_refs_ptr;
          face_refs_ptr := face_refs_ptr^.next;
        end;

      last_face_ref_ptr^.next := face_ref_free_list;
      face_ref_free_list := first_face_ref_ptr;
    end;
end; {procedure Free_face_refs}


procedure Free_points(var points_ptr: point_ptr_type);
var
  first_point_ptr, last_point_ptr: point_ptr_type;
begin
  if points_ptr <> nil then
    begin
      first_point_ptr := points_ptr;
      last_point_ptr := nil;

      while points_ptr <> nil do
        begin
          Free_edge_refs(points_ptr^.edge_list);
          last_point_ptr := points_ptr;
          points_ptr := points_ptr^.next;
        end;

      last_point_ptr^.next := point_free_list;
      point_free_list := first_point_ptr;
    end;
end; {procedure Free_points}


procedure Free_vertices(var vertices_ptr: vertex_ptr_type);
var
  first_vertex_ptr, last_vertex_ptr: vertex_ptr_type;
begin
  if vertices_ptr <> nil then
    begin
      first_vertex_ptr := vertices_ptr;
      last_vertex_ptr := nil;

      while vertices_ptr <> nil do
        begin
          Free_face_refs(vertices_ptr^.face_list);
          last_vertex_ptr := vertices_ptr;
          vertices_ptr := vertices_ptr^.next;
        end;

      last_vertex_ptr^.next := vertex_free_list;
      vertex_free_list := first_vertex_ptr;
    end;
end; {procedure Free_vertices}


procedure Free_edges(var edges_ptr: edge_ptr_type);
var
  first_edge_ptr, last_edge_ptr: edge_ptr_type;
begin
  if edges_ptr <> nil then
    begin
      first_edge_ptr := edges_ptr;
      last_edge_ptr := nil;

      while edges_ptr <> nil do
        begin
          Free_face_refs(edges_ptr^.face_list);
          last_edge_ptr := edges_ptr;
          edges_ptr := edges_ptr^.next;
        end;

      last_edge_ptr^.next := edge_free_list;
      edge_free_list := first_edge_ptr;
    end;
end; {procedure Free_edges}


procedure Free_directed_edges(directed_edges_ptr: directed_edge_ptr_type);
var
  first_directed_edge_ptr, last_directed_edge_ptr: directed_edge_ptr_type;
begin
  if directed_edges_ptr <> nil then
    begin
      first_directed_edge_ptr := directed_edges_ptr;
      last_directed_edge_ptr := nil;

      while directed_edges_ptr <> nil do
        begin
          last_directed_edge_ptr := directed_edges_ptr;
          directed_edges_ptr := directed_edges_ptr^.next;
        end;

      last_directed_edge_ptr^.next := directed_edge_free_list;
      directed_edge_free_list := first_directed_edge_ptr;
    end;
end; {procedure Free_directed_edges}


procedure Free_cycles(var cycles_ptr: cycle_ptr_type);
var
  first_cycle_ptr, last_cycle_ptr: cycle_ptr_type;
begin
  if cycles_ptr <> nil then
    begin
      first_cycle_ptr := cycles_ptr;
      last_cycle_ptr := nil;

      while cycles_ptr <> nil do
        begin
          Free_directed_edges(cycles_ptr^.directed_edge_ptr);
          last_cycle_ptr := cycles_ptr;
          cycles_ptr := cycles_ptr^.next;
        end;

      last_cycle_ptr^.next := cycle_free_list;
      cycle_free_list := first_cycle_ptr;
    end;
end; {procedure Free_cycles}


procedure Free_faces(var faces_ptr: face_ptr_type);
var
  first_face_ptr, last_face_ptr: face_ptr_type;
begin
  if faces_ptr <> nil then
    begin
      first_face_ptr := faces_ptr;
      last_face_ptr := nil;

      while faces_ptr <> nil do
        begin
          Free_cycles(faces_ptr^.cycle_ptr);
          last_face_ptr := faces_ptr;
          faces_ptr := faces_ptr^.next;
        end;

      last_face_ptr^.next := face_free_list;
      face_free_list := first_face_ptr;
    end;
end; {procedure Free_faces}


procedure Free_topology(var topology_ptr: topology_ptr_type);
begin
  if topology_ptr <> nil then
    begin
      topology_ptr^.reference_count := topology_ptr^.reference_count - 1;

      if topology_ptr^.reference_count = 0 then
        begin
          Free_points(topology_ptr^.point_ptr);
          Free_vertices(topology_ptr^.vertex_ptr);
          Free_edges(topology_ptr^.edge_ptr);
          Free_faces(topology_ptr^.face_ptr);

          {***************}
          { free topology }
          {***************}
          topology_ptr^.next := topology_free_list;
          topology_free_list := topology_ptr;
          topology_ptr := nil;
        end;
    end;
end; {procedure Free_topology}


procedure Free_report_topology(var topology_ptr: topology_ptr_type);
const
  verbose = true;
var
  {**********}
  { pointers }
  {**********}
  point_ptr, last_point_ptr: point_ptr_type;
  vertex_ptr, last_vertex_ptr: vertex_ptr_type;
  edge_ptr, last_edge_ptr: edge_ptr_type;
  cycle_ptr, last_cycle_ptr: cycle_ptr_type;
  face_ptr, last_face_ptr: face_ptr_type;
  edge_ref_ptr, last_edge_ref_ptr: edge_ref_ptr_type;
  face_ref_ptr, last_face_ref_ptr: face_ref_ptr_type;
  directed_edge_ptr, last_directed_edge_ptr: directed_edge_ptr_type;

  {**********}
  { counters }
  {**********}
  freed_points, freed_vertices, freed_edges, freed_faces: integer;
  freed_edge_refs, freed_face_refs: integer;
  freed_cycles, freed_directed_edges: integer;
begin
  if (topology_ptr <> nil) then
    begin
      {*********************}
      { initialize counters }
      {*********************}
      freed_points := 0;
      freed_vertices := 0;
      freed_edges := 0;
      freed_faces := 0;
      freed_edge_refs := 0;
      freed_face_refs := 0;
      freed_cycles := 0;
      freed_directed_edges := 0;

      if verbose then
        begin
          writeln('topology claims:');
          Report_topology(topology_ptr);
          writeln;
          writeln('inspection reveals:');
          Inspect_topology(topology_ptr);
          writeln;
        end;

      topology_ptr^.reference_count := topology_ptr^.reference_count - 1;
      if topology_ptr^.reference_count = 0 then
        begin
          {*************}
          { free points }
          {*************}
          if (topology_ptr^.point_ptr <> nil) then
            begin
              point_ptr := topology_ptr^.point_ptr;
              last_point_ptr := nil;
              while (point_ptr <> nil) do
                begin
                  {****************}
                  { free edge list }
                  {****************}
                  if (point_ptr^.edge_list <> nil) then
                    begin
                      edge_ref_ptr := point_ptr^.edge_list;
                      last_edge_ref_ptr := nil;
                      while (edge_ref_ptr <> nil) do
                        begin
                          last_edge_ref_ptr := edge_ref_ptr;
                          edge_ref_ptr := edge_ref_ptr^.next;
                          freed_edge_refs := freed_edge_refs + 1;
                        end;
                      last_edge_ref_ptr^.next := edge_ref_free_list;
                      edge_ref_free_list := point_ptr^.edge_list;
                      point_ptr^.edge_list := nil;
                    end;
                  last_point_ptr := point_ptr;
                  point_ptr := point_ptr^.next;
                  freed_points := freed_points + 1;
                end;
              last_point_ptr^.next := point_free_list;
              point_free_list := topology_ptr^.point_ptr;
              topology_ptr^.point_ptr := nil;
            end;

          {***************}
          { free vertices }
          {***************}
          if (topology_ptr^.vertex_ptr <> nil) then
            begin
              vertex_ptr := topology_ptr^.vertex_ptr;
              last_vertex_ptr := nil;
              while (vertex_ptr <> nil) do
                begin
                  last_vertex_ptr := vertex_ptr;
                  vertex_ptr := vertex_ptr^.next;
                  freed_vertices := freed_vertices + 1;
                end;
              last_vertex_ptr^.next := vertex_free_list;
              vertex_free_list := topology_ptr^.vertex_ptr;
              topology_ptr^.vertex_ptr := nil;
            end;

          {************}
          { free edges }
          {************}
          if (topology_ptr^.edge_ptr <> nil) then
            begin
              edge_ptr := topology_ptr^.edge_ptr;
              last_edge_ptr := nil;
              while (edge_ptr <> nil) do
                begin
                  {****************}
                  { free face list }
                  {****************}
                  if (edge_ptr^.face_list <> nil) then
                    begin
                      face_ref_ptr := edge_ptr^.face_list;
                      last_face_ref_ptr := nil;
                      while (face_ref_ptr <> nil) do
                        begin
                          last_face_ref_ptr := face_ref_ptr;
                          face_ref_ptr := face_ref_ptr^.next;
                          freed_face_refs := freed_face_refs + 1;
                        end;
                      last_face_ref_ptr^.next := face_ref_free_list;
                      face_ref_free_list := edge_ptr^.face_list;
                      edge_ptr^.face_list := nil;
                    end;
                  last_edge_ptr := edge_ptr;
                  edge_ptr := edge_ptr^.next;
                  freed_edges := freed_edges + 1;
                end;
              last_edge_ptr^.next := edge_free_list;
              edge_free_list := topology_ptr^.edge_ptr;
              topology_ptr^.edge_ptr := nil;
            end;

          {************}
          { free faces }
          {************}
          if (topology_ptr^.face_ptr <> nil) then
            begin
              face_ptr := topology_ptr^.face_ptr;
              last_face_ptr := nil;
              while (face_ptr <> nil) do
                begin
                  {*************}
                  { free cycles }
                  {*************}
                  if (face_ptr^.cycle_ptr <> nil) then
                    begin
                      cycle_ptr := face_ptr^.cycle_ptr;
                      last_cycle_ptr := nil;
                      while (cycle_ptr <> nil) do
                        begin
                          {*********************}
                          { free directed edges }
                          {*********************}
                          if (cycle_ptr^.directed_edge_ptr <> nil) then
                            begin
                              directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
                              last_directed_edge_ptr := nil;
                              while (directed_edge_ptr <> nil) do
                                begin
                                  last_directed_edge_ptr := directed_edge_ptr;
                                  directed_edge_ptr := directed_edge_ptr^.next;
                                  freed_directed_edges := freed_directed_edges +
                                    1;
                                end;
                              last_directed_edge_ptr^.next :=
                                directed_edge_free_list;
                              directed_edge_free_list :=
                                cycle_ptr^.directed_edge_ptr;
                              cycle_ptr^.directed_edge_ptr := nil;
                            end;
                          last_cycle_ptr := cycle_ptr;
                          cycle_ptr := cycle_ptr^.next;
                          freed_cycles := freed_cycles + 1;
                        end;
                      last_cycle_ptr^.next := cycle_free_list;
                      cycle_free_list := face_ptr^.cycle_ptr;
                      face_ptr^.cycle_ptr := nil;
                    end;
                  last_face_ptr := face_ptr;
                  face_ptr := face_ptr^.next;
                  freed_faces := freed_faces + 1;
                end;
              last_face_ptr^.next := face_free_list;
              face_free_list := topology_ptr^.face_ptr;
              topology_ptr^.face_ptr := nil;
            end;

          writeln('freed topology:');
          writeln('freed points = ', freed_points: 1);
          writeln('freed vertices = ', freed_vertices: 1);
          writeln('freed edges = ', freed_edges: 1);
          writeln('freed faces = ', freed_faces: 1);
          writeln('freed edge refs = ', freed_edge_refs: 1);
          writeln('freed face refs = ', freed_face_refs: 1);
          writeln('freed cycles = ', freed_cycles: 1);
          writeln('freed directed edges = ', freed_directed_edges: 1);

          {***************}
          { free topology }
          {***************}
          topology_ptr^.next := topology_free_list;
          topology_free_list := topology_ptr;
          topology_ptr := nil;
        end;
    end;
end; {procedure Free_report_topology}


procedure Inspect_topology(topology_ptr: topology_ptr_type);
var
  {**********}
  { pointers }
  {**********}
  point_ptr: point_ptr_type;
  vertex_ptr: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  face_ptr: face_ptr_type;
  edge_ref_ptr: edge_ref_ptr_type;
  face_ref_ptr: face_ref_ptr_type;
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;

  {**********}
  { counters }
  {**********}
  point_counter, vertex_counter, edge_counter, face_counter: integer;
  edge_ref_counter, face_ref_counter: integer;
  cycle_counter, directed_edge_counter: integer;
begin
  if (topology_ptr <> nil) then
    begin
      {*********************}
      { initialize counters }
      {*********************}
      point_counter := 0;
      vertex_counter := 0;
      edge_counter := 0;
      face_counter := 0;
      edge_ref_counter := 0;
      face_ref_counter := 0;
      cycle_counter := 0;
      directed_edge_counter := 0;

      {**************}
      { count points }
      {**************}
      point_ptr := topology_ptr^.point_ptr;
      while (point_ptr <> nil) do
        begin
          {*****************}
          { count edge refs }
          {*****************}
          if (point_ptr^.edge_list <> nil) then
            begin
              edge_ref_ptr := point_ptr^.edge_list;
              while (edge_ref_ptr <> nil) do
                begin
                  edge_ref_ptr := edge_ref_ptr^.next;
                  edge_ref_counter := edge_ref_counter + 1;
                end;
            end;
          point_ptr := point_ptr^.next;
          point_counter := point_counter + 1;
        end;

      {****************}
      { count vertices }
      {****************}
      vertex_ptr := topology_ptr^.vertex_ptr;
      while (vertex_ptr <> nil) do
        begin
          vertex_ptr := vertex_ptr^.next;
          vertex_counter := vertex_counter + 1;
        end;

      {*************}
      { count edges }
      {*************}
      edge_ptr := topology_ptr^.edge_ptr;
      while (edge_ptr <> nil) do
        begin
          {*****************}
          { count face refs }
          {*****************}
          face_ref_ptr := edge_ptr^.face_list;
          while (face_ref_ptr <> nil) do
            begin
              face_ref_ptr := face_ref_ptr^.next;
              face_ref_counter := face_ref_counter + 1;
            end;
          edge_ptr := edge_ptr^.next;
          edge_counter := edge_counter + 1;
        end;

      {*************}
      { count faces }
      {*************}
      face_ptr := topology_ptr^.face_ptr;
      while (face_ptr <> nil) do
        begin
          {**************}
          { count cycles }
          {**************}
          cycle_ptr := face_ptr^.cycle_ptr;
          while (cycle_ptr <> nil) do
            begin
              {**********************}
              { count directed edges }
              {**********************}
              directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
              while (directed_edge_ptr <> nil) do
                begin
                  directed_edge_ptr := directed_edge_ptr^.next;
                  directed_edge_counter := directed_edge_counter + 1;
                end;
              cycle_ptr := cycle_ptr^.next;
              cycle_counter := cycle_counter + 1;
            end;
          face_ptr := face_ptr^.next;
          face_counter := face_counter + 1;
        end;

      writeln('number of points = ', point_counter: 1);
      writeln('number of vertices = ', vertex_counter: 1);
      writeln('number of edges = ', edge_counter: 1);
      writeln('number of faces = ', face_counter: 1);
      writeln('number of edge refs = ', edge_ref_counter: 1);
      writeln('number of face refs = ', face_ref_counter: 1);
      writeln('number of cycles = ', cycle_counter: 1);
      writeln('number of directed edges = ', directed_edge_counter: 1);
    end
  else
    writeln('nil topology');
end; {procedure Inspect_topology}


procedure Report_topology(topology_ptr: topology_ptr_type);
begin
  if topology_ptr <> nil then
    begin
      with topology_ptr^ do
        begin
          writeln('number of points = ', point_number: 1);
          writeln('number of vertices = ', vertex_number: 1);
          writeln('number of edges = ', edge_number: 1);
          writeln('number of faces = ', face_number: 1);
          writeln('number of edge refs = ', edge_ref_number: 1);
          writeln('number of face refs = ', face_ref_number: 1);
          writeln('number of cycles = ', cycle_number: 1);
          writeln('number of directed edges = ', directed_edge_number: 1);
        end;
    end
  else
    writeln('nil topology');
end; {procedure Report_topology}


procedure Write_edge_kind(edge_kind: edge_kind_type);
begin
  case edge_kind of
    real_edge:
      write('real_edge');
    pseudo_edge:
      write('pseudo_edge');
    fake_edge:
      write('fake_edge');
    duplicate_edge:
      write('duplicate_edge');
  end;
end; {procedure Write_edge_kind}


initialization
  {***********************}
  { initialize free lists }
  {***********************}
  topology_free_list := nil;

  point_free_list := nil;
  vertex_free_list := nil;
  edge_free_list := nil;
  edge_ref_free_list := nil;
  face_ref_free_list := nil;
  directed_edge_free_list := nil;
  cycle_free_list := nil;
  face_free_list := nil;

  {********************************}
  { initialize vars used in block  }
  { allocation of b rep components }
  {********************************}
  vertex_counter := 0;
  edge_counter := 0;
  edge_ref_counter := 0;
  face_ref_counter := 0;
  directed_edge_counter := 0;
  cycle_counter := 0;
  face_counter := 0;

  vertex_block_ptr := nil;
  edge_block_ptr := nil;
  edge_ref_block_ptr := nil;
  face_ref_block_ptr := nil;
  directed_edge_block_ptr := nil;
  cycle_block_ptr := nil;
  face_block_ptr := nil;
end.
