unit polymeshes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             polymeshes                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{      The polymeshes module builds the geometry data structs   }
{      for the polygonal meshe objects.                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors;


type
  {*******************}
  { mesh data structs }
  {*******************}
  mesh_vertex_ptr_type = ^mesh_vertex_type;
  mesh_vertex_type = record
    point: vector_type;
    normal: vector_type;
    texture: vector_type;
    next: mesh_vertex_ptr_type;
  end; {mesh_vertex_type}

  mesh_edge_ptr_type = ^mesh_edge_type;
  mesh_edge_type = record
    vertex1, vertex2: integer;
    next: mesh_edge_ptr_type;
  end; {mesh_edge_type}

  mesh_edge_index_ptr_type = ^mesh_edge_index_type;
  mesh_edge_index_type = record
    index: integer;
    next: mesh_edge_index_ptr_type;
  end; {mesh_edge_index_type}

  mesh_face_ptr_type = ^mesh_face_type;
  mesh_face_type = record
    orientation: boolean;
    edges: integer;
    edge_index_ptr: mesh_edge_index_ptr_type;
    last_edge_index_ptr: mesh_edge_index_ptr_type;
    next: mesh_face_ptr_type;
  end; {mesh_face_type}

  mesh_ptr_type = ^mesh_type;
  mesh_type = record
    vertices: integer;
    edges: integer;
    faces: integer;

    vertex_ptr: mesh_vertex_ptr_type;
    edge_ptr: mesh_edge_ptr_type;
    face_ptr: mesh_face_ptr_type;

    last_vertex_ptr: mesh_vertex_ptr_type;
    last_edge_ptr: mesh_edge_ptr_type;
    last_face_ptr: mesh_face_ptr_type;
    next: mesh_ptr_type;
  end; {mesh_type}


  {********************************************************}
  { these routines are used to create an intermediate data }
  { structure which holds the geometric information about  }
  { the tessellated primitives but without the topology.   }
  {********************************************************}


{************************************************}
{ routines for creating meshes and smooth meshes }
{************************************************}
function New_mesh: mesh_ptr_type;
procedure Add_mesh_vertex(mesh_ptr: mesh_ptr_type;
  point, normal, texture: vector_type);
procedure Add_mesh_edge(mesh_ptr: mesh_ptr_type;
  vertex1, vertex2: integer);
procedure Add_mesh_face(mesh_ptr: mesh_ptr_type;
  orientation: boolean);
procedure Add_mesh_edge_index(mesh_ptr: mesh_ptr_type;
  index: integer);
procedure Free_mesh(var mesh_ptr: mesh_ptr_type);
function Same_mesh(mesh_ptr1, mesh_ptr2: mesh_ptr_type): boolean;
function Same_mesh_topology(mesh_ptr1, mesh_ptr2: mesh_ptr_type): boolean;


implementation
uses
  new_memory;


const
  block_size = 512;
  memory_alert = false;


type
  {************************}
  { block allocation types }
  {************************}
  mesh_vertex_block_ptr_type = ^mesh_vertex_block_type;
  mesh_edge_block_ptr_type = ^mesh_edge_block_type;
  mesh_face_block_ptr_type = ^mesh_face_block_type;
  mesh_edge_index_block_ptr_type = ^mesh_edge_index_block_type;

  mesh_vertex_block_type = array[0..block_size] of mesh_vertex_type;
  mesh_edge_block_type = array[0..block_size] of mesh_edge_type;
  mesh_face_block_type = array[0..block_size] of mesh_face_type;
  mesh_edge_index_block_type = array[0..block_size] of mesh_edge_index_type;


var
  {***********************}
  { free lists for meshes }
  {***********************}
  mesh_free_list: mesh_ptr_type;
  mesh_vertex_free_list: mesh_vertex_ptr_type;
  mesh_edge_free_list: mesh_edge_ptr_type;
  mesh_face_free_list: mesh_face_ptr_type;
  mesh_edge_index_free_list: mesh_edge_index_ptr_type;

  {****************************}
  { block allocation variables }
  {****************************}
  mesh_vertex_block_ptr: mesh_vertex_block_ptr_type;
  mesh_edge_block_ptr: mesh_edge_block_ptr_type;
  mesh_face_block_ptr: mesh_face_block_ptr_type;
  mesh_edge_index_block_ptr: mesh_edge_index_block_ptr_type;

  mesh_vertex_counter: longint;
  mesh_edge_counter: longint;
  mesh_face_counter: longint;
  mesh_edge_index_counter: longint;


{************************************************}
{ routines for creating meshes and smooth meshes }
{************************************************}


function New_mesh: mesh_ptr_type;
var
  mesh_ptr: mesh_ptr_type;
begin
  {*************************}
  { get mesh from free list }
  {*************************}
  if (mesh_free_list <> nil) then
    begin
      mesh_ptr := mesh_free_list;
      mesh_free_list := mesh_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new mesh');
      new(mesh_ptr);
    end;

  {*****************}
  { initialize mesh }
  {*****************}
  with mesh_ptr^ do
    begin
      vertices := 0;
      edges := 0;
      faces := 0;
      vertex_ptr := nil;
      edge_ptr := nil;
      face_ptr := nil;
      last_vertex_ptr := nil;
      last_edge_ptr := nil;
      last_face_ptr := nil;
      next := nil;
    end;

  New_mesh := mesh_ptr;
end; {function New_mesh}


function New_mesh_vertex: mesh_vertex_ptr_type;
var
  mesh_vertex_ptr: mesh_vertex_ptr_type;
  index: integer;
begin
  {********************************}
  { get mesh vertex from free list }
  {********************************}
  if (mesh_vertex_free_list <> nil) then
    begin
      mesh_vertex_ptr := mesh_vertex_free_list;
      mesh_vertex_free_list := mesh_vertex_free_list^.next;
    end
  else
    begin
      index := mesh_vertex_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new mesh vertex block');
          new(mesh_vertex_block_ptr);
        end;
      mesh_vertex_ptr := @mesh_vertex_block_ptr^[index];
      mesh_vertex_counter := mesh_vertex_counter + 1;
    end;

  {************************}
  { initialize mesh vertex }
  {************************}
  mesh_vertex_ptr^.next := nil;

  New_mesh_vertex := mesh_vertex_ptr;
end; {function New_mesh_vertex}


procedure Add_mesh_vertex(mesh_ptr: mesh_ptr_type;
  point, normal, texture: vector_type);
var
  vertex_ptr: mesh_vertex_ptr_type;
begin
  vertex_ptr := New_mesh_vertex;
  vertex_ptr^.point := point;
  vertex_ptr^.normal := normal;
  vertex_ptr^.texture := texture;

  {***************************}
  { add vertex to end of list }
  {***************************}
  if (mesh_ptr^.last_vertex_ptr <> nil) then
    begin
      mesh_ptr^.last_vertex_ptr^.next := vertex_ptr;
      mesh_ptr^.last_vertex_ptr := vertex_ptr;
    end
  else
    begin
      mesh_ptr^.vertex_ptr := vertex_ptr;
      mesh_ptr^.last_vertex_ptr := vertex_ptr;
    end;

  mesh_ptr^.vertices := mesh_ptr^.vertices + 1;
end; {function Add_mesh_vertex}


function New_mesh_edge: mesh_edge_ptr_type;
var
  mesh_edge_ptr: mesh_edge_ptr_type;
  index: integer;
begin
  {******************************}
  { get mesh edge from free list }
  {******************************}
  if (mesh_edge_free_list <> nil) then
    begin
      mesh_edge_ptr := mesh_edge_free_list;
      mesh_edge_free_list := mesh_edge_free_list^.next;
    end
  else
    begin
      index := mesh_edge_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new mesh edge block');
          new(mesh_edge_block_ptr);
        end;
      mesh_edge_ptr := @mesh_edge_block_ptr^[index];
      mesh_edge_counter := mesh_edge_counter + 1;
    end;

  {**********************}
  { initialize mesh edge }
  {**********************}
  mesh_edge_ptr^.next := nil;

  New_mesh_edge := mesh_edge_ptr;
end; {function New_mesh_edge}


procedure Add_mesh_edge(mesh_ptr: mesh_ptr_type;
  vertex1, vertex2: integer);
var
  edge_ptr: mesh_edge_ptr_type;
begin
  edge_ptr := New_mesh_edge;
  edge_ptr^.vertex1 := vertex1;
  edge_ptr^.vertex2 := vertex2;

  {*************************}
  { add edge to end of list }
  {*************************}
  if (mesh_ptr^.last_edge_ptr <> nil) then
    begin
      mesh_ptr^.last_edge_ptr^.next := edge_ptr;
      mesh_ptr^.last_edge_ptr := edge_ptr;
    end
  else
    begin
      mesh_ptr^.edge_ptr := edge_ptr;
      mesh_ptr^.last_edge_ptr := edge_ptr;
    end;

  mesh_ptr^.edges := mesh_ptr^.edges + 1;
end; {function Add_mesh_edge}


function New_mesh_face(orientation: boolean): mesh_face_ptr_type;
var
  mesh_face_ptr: mesh_face_ptr_type;
  index: integer;
begin
  {******************************}
  { get mesh face from free list }
  {******************************}
  if (mesh_face_free_list <> nil) then
    begin
      mesh_face_ptr := mesh_face_free_list;
      mesh_face_free_list := mesh_face_free_list^.next;
    end
  else
    begin
      index := mesh_face_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new mesh face block');
          new(mesh_face_block_ptr);
        end;
      mesh_face_ptr := @mesh_face_block_ptr^[index];
      mesh_face_counter := mesh_face_counter + 1;
    end;

  {**********************}
  { initialize mesh face }
  {**********************}
  mesh_face_ptr^.edges := 0;
  mesh_face_ptr^.orientation := orientation;
  mesh_face_ptr^.edge_index_ptr := nil;
  mesh_face_ptr^.last_edge_index_ptr := nil;
  mesh_face_ptr^.next := nil;

  New_mesh_face := mesh_face_ptr;
end; {function New_mesh_face}


procedure Add_mesh_face(mesh_ptr: mesh_ptr_type;
  orientation: boolean);
var
  face_ptr: mesh_face_ptr_type;
begin
  face_ptr := New_mesh_face(orientation);

  {*************************}
  { add face to end of list }
  {*************************}
  if (mesh_ptr^.last_face_ptr <> nil) then
    begin
      mesh_ptr^.last_face_ptr^.next := face_ptr;
      mesh_ptr^.last_face_ptr := face_ptr;
    end
  else
    begin
      mesh_ptr^.face_ptr := face_ptr;
      mesh_ptr^.last_face_ptr := face_ptr;
    end;

  mesh_ptr^.faces := mesh_ptr^.faces + 1;
end; {function Add_mesh_face}


function New_mesh_edge_index: mesh_edge_index_ptr_type;
var
  mesh_edge_index_ptr: mesh_edge_index_ptr_type;
  index: integer;
begin
  {************************************}
  { get mesh edge_index from free list }
  {************************************}
  if (mesh_edge_index_free_list <> nil) then
    begin
      mesh_edge_index_ptr := mesh_edge_index_free_list;
      mesh_edge_index_free_list := mesh_edge_index_free_list^.next;
    end
  else
    begin
      index := mesh_edge_index_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new mesh edge index block');
          new(mesh_edge_index_block_ptr);
        end;
      mesh_edge_index_ptr := @mesh_edge_index_block_ptr^[index];
      mesh_edge_index_counter := mesh_edge_index_counter + 1;
    end;

  {****************************}
  { initialize mesh edge index }
  {****************************}
  mesh_edge_index_ptr^.next := nil;

  New_mesh_edge_index := mesh_edge_index_ptr;
end; {function New_mesh_edge_index}


procedure Add_mesh_edge_index(mesh_ptr: mesh_ptr_type;
  index: integer);
var
  edge_index_ptr: mesh_edge_index_ptr_type;
  face_ptr: mesh_face_ptr_type;
begin
  edge_index_ptr := New_mesh_edge_index;
  face_ptr := mesh_ptr^.last_face_ptr;

  if face_ptr^.orientation then
    begin
      {********************************}
      { add edge index to tail of list }
      {********************************}
      edge_index_ptr^.index := index;
      if (face_ptr^.last_edge_index_ptr <> nil) then
        begin
          face_ptr^.last_edge_index_ptr^.next := edge_index_ptr;
          face_ptr^.last_edge_index_ptr := edge_index_ptr;
        end
      else
        begin
          face_ptr^.edge_index_ptr := edge_index_ptr;
          face_ptr^.last_edge_index_ptr := edge_index_ptr;
        end;
    end
  else
    begin
      {********************************}
      { add edge index to head of list }
      {********************************}
      edge_index_ptr^.index := -index;
      edge_index_ptr^.next := face_ptr^.edge_index_ptr;
      face_ptr^.edge_index_ptr := edge_index_ptr;
      if (face_ptr^.last_edge_index_ptr = nil) then
        face_ptr^.last_edge_index_ptr := edge_index_ptr;
    end;

  face_ptr^.edges := face_ptr^.edges + 1;
end; {function Add_mesh_edge}


procedure Free_mesh(var mesh_ptr: mesh_ptr_type);
var
  mesh_face_ptr: mesh_face_ptr_type;
begin
  if mesh_ptr <> nil then
    begin
      {***************}
      { free vertices }
      {***************}
      if (mesh_ptr^.vertex_ptr <> nil) then
        begin
          mesh_ptr^.last_vertex_ptr^.next := mesh_vertex_free_list;
          mesh_vertex_free_list := mesh_ptr^.vertex_ptr;
        end;

      {************}
      { free edges }
      {************}
      if (mesh_ptr^.edge_ptr <> nil) then
        begin
          mesh_ptr^.last_edge_ptr^.next := mesh_edge_free_list;
          mesh_edge_free_list := mesh_ptr^.edge_ptr;
        end;

      {************}
      { free faces }
      {************}
      if (mesh_ptr^.face_ptr <> nil) then
        begin
          mesh_face_ptr := mesh_ptr^.face_ptr;
          while (mesh_face_ptr <> nil) do
            begin
              {*******************}
              { free edge indices }
              {*******************}
              with mesh_face_ptr^ do
                if (last_edge_index_ptr <> nil) then
                  begin
                    last_edge_index_ptr^.next := mesh_edge_index_free_list;
                    mesh_edge_index_free_list := edge_index_ptr;
                  end;
              mesh_face_ptr := mesh_face_ptr^.next;
            end;

          mesh_ptr^.last_face_ptr^.next := mesh_face_free_list;
          mesh_face_free_list := mesh_ptr^.face_ptr;
        end;

      {***********}
      { free mesh }
      {***********}
      mesh_ptr^.next := mesh_free_list;
      mesh_free_list := mesh_ptr;
      mesh_ptr := nil;
    end;
end; {procedure Free_mesh}


function Same_mesh_vertices(vertex_ptr1, vertex_ptr2: mesh_vertex_ptr_type):
  boolean;
var
  same: boolean;
begin
  same := true;

  while same and (vertex_ptr1 <> nil) and (vertex_ptr2 <> nil) do
    begin
      if not Equal_vector(vertex_ptr1^.point, vertex_ptr2^.point) then
        same := false
      else if not Equal_vector(vertex_ptr1^.texture, vertex_ptr2^.texture) then
        same := false
      else
        begin
          vertex_ptr1 := vertex_ptr1^.next;
          vertex_ptr2 := vertex_ptr2^.next;
        end;
    end;

  Same_mesh_vertices := (vertex_ptr1 = nil) and (vertex_ptr2 = nil);
end; {function Same_mesh_vertices}


function Same_mesh_edges(edge_ptr1, edge_ptr2: mesh_edge_ptr_type): boolean;
var
  same: boolean;
begin
  same := true;

  while same and (edge_ptr1 <> nil) and (edge_ptr2 <> nil) do
    begin
      if edge_ptr1^.vertex1 <> edge_ptr2^.vertex1 then
        same := false
      else if edge_ptr1^.vertex2 <> edge_ptr2^.vertex2 then
        same := false
      else
        begin
          edge_ptr1 := edge_ptr1^.next;
          edge_ptr2 := edge_ptr2^.next;
        end;
    end;

  Same_mesh_edges := (edge_ptr1 = nil) and (edge_ptr2 = nil);
end; {function Same_mesh_edges}


function Same_mesh_faces(face_ptr1, face_ptr2: mesh_face_ptr_type): boolean;
var
  same: boolean;
  edge_index_ptr1, edge_index_ptr2: mesh_edge_index_ptr_type;
begin
  same := face_ptr1^.orientation = face_ptr2^.orientation;
  if same then
    same := face_ptr1^.edges = face_ptr2^.edges;

  edge_index_ptr1 := face_ptr1^.edge_index_ptr;
  edge_index_ptr2 := face_ptr2^.edge_index_ptr;
  while same and (edge_index_ptr1 <> nil) and (edge_index_ptr2 <> nil) do
    begin
      if edge_index_ptr1^.index <> edge_index_ptr2^.index then
        same := false
      else
        begin
          edge_index_ptr1 := edge_index_ptr1^.next;
          edge_index_ptr2 := edge_index_ptr2^.next;
        end;
    end;

  Same_mesh_faces := same and (edge_index_ptr1 = nil) and (edge_index_ptr2 =
    nil);
end; {function Same_mesh_faces}


function Same_mesh(mesh_ptr1, mesh_ptr2: mesh_ptr_type): boolean;
var
  same: boolean;
begin
  if mesh_ptr1 = mesh_ptr2 then
    same := true
  else if mesh_ptr1 = nil then
    same := false
  else if mesh_ptr2 = nil then
    same := false
  else if mesh_ptr1^.vertices <> mesh_ptr2^.vertices then
    same := false
  else if mesh_ptr1^.edges <> mesh_ptr2^.edges then
    same := false
  else if mesh_ptr1^.faces <> mesh_ptr2^.faces then
    same := false
  else if not Same_mesh_vertices(mesh_ptr1^.vertex_ptr, mesh_ptr2^.vertex_ptr)
    then
    same := false
  else if not Same_mesh_edges(mesh_ptr1^.edge_ptr, mesh_ptr2^.edge_ptr) then
    same := false
  else if not Same_mesh_faces(mesh_ptr1^.face_ptr, mesh_ptr2^.face_ptr) then
    same := false
  else
    same := true;

  Same_mesh := same;
end; {function Same_mesh}


function Same_mesh_topology(mesh_ptr1, mesh_ptr2: mesh_ptr_type): boolean;
var
  same: boolean;
begin
  if mesh_ptr1^.vertices <> mesh_ptr2^.vertices then
    same := false
  else if mesh_ptr1^.edges <> mesh_ptr2^.edges then
    same := false
  else if mesh_ptr1^.faces <> mesh_ptr2^.faces then
    same := false
  else if not Same_mesh_edges(mesh_ptr1^.edge_ptr, mesh_ptr2^.edge_ptr) then
    same := false
  else if not Same_mesh_faces(mesh_ptr1^.face_ptr, mesh_ptr2^.face_ptr) then
    same := false
  else
    same := true;

  Same_mesh_topology := same;
end; {function Same_mesh_topology}


initialization
  {***********************}
  { initialize free lists }
  {***********************}
  mesh_free_list := nil;
  mesh_vertex_free_list := nil;
  mesh_edge_free_list := nil;
  mesh_face_free_list := nil;
  mesh_edge_index_free_list := nil;

  {***************************************}
  { initialize block allocation variables }
  {***************************************}
  mesh_vertex_block_ptr := nil;
  mesh_edge_block_ptr := nil;
  mesh_face_block_ptr := nil;
  mesh_edge_index_block_ptr := nil;

  mesh_vertex_counter := 0;
  mesh_edge_counter := 0;
  mesh_face_counter := 0;
  mesh_edge_index_counter := 0;
end.
