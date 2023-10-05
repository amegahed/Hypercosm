unit meshes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              meshes                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The meshes module builds the topology data structures   }
{       for the mesh primitive objects.                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, trans, topology, b_rep, polymeshes;


{************************}
{ mesh topology routines }
{************************}
function Mesh_topology(mesh_ptr: mesh_ptr_type;
  edge_kind: edge_kind_type;
  checking, mending: boolean): topology_ptr_type;
procedure Find_mesh_real_edges(topology_ptr: topology_ptr_type);

{********************************************************}
{ When mesh topologies are created, a record of their    }
{ correspondence is kept. This link must be broken when  }
{ either mesh or topology are no longer available.       }
{********************************************************}
procedure Free_mesh_topology_link(mesh_ptr: mesh_ptr_type);
procedure Free_topology_mesh_link(topology_ptr: topology_ptr_type);

{************************}
{ mesh geometry routines }
{************************}
procedure Unitize_mesh(surface_ptr: surface_ptr_type;
  var trans: trans_type);
procedure Find_mesh_face_normals(surface_ptr: surface_ptr_type);
procedure Find_mesh_vertex_normals(surface_ptr: surface_ptr_type);
procedure Find_mesh_uv_vectors(surface_ptr: surface_ptr_type);
function Coincident_vertices(vertex1, vertex2: vector_type): boolean;


implementation
uses
  errors, new_memory, constants, extents, geometry, make_b_rep;


const
  coincidence_d = 0.00001;
  vertex_index_block_size = 512;
  edge_index_block_size = 512;
  memory_alert = false;


type
  {************************************************}
  { linked chain of regularly sized blocks of ptrs }
  {************************************************}
  vertex_index_block_ptr_type = ^vertex_index_block_type;
  vertex_index_block_type = record
    ptr_array: array[0..vertex_index_block_size] of vertex_ptr_type;
    next: vertex_index_block_ptr_type;
  end; {vertex_index_block_type}

  edge_index_block_ptr_type = ^edge_index_block_type;
  edge_index_block_type = record
    ptr_array: array[0..edge_index_block_size] of edge_ptr_type;
    next: edge_index_block_ptr_type;
  end; {edge_index_block_type}

  {**********************************}
  { dynamically sized arrays of ptrs }
  {**********************************}
  vertex_index_ptr_type = ^vertex_ptr_type;
  edge_index_ptr_type = ^edge_ptr_type;

  {*******************************************************}
  { list of existing meshes and their topologies used to  }
  { share topologies for topologically identical meshes.  }
  {*******************************************************}
  mesh_topology_ptr_type = ^mesh_topology_type;
  mesh_topology_type = record
    mesh_ptr: mesh_ptr_type;
    topology_ptr: topology_ptr_type;
    next: mesh_topology_ptr_type;
  end; {mesh_topology_type}


var
  vertex_index_block_free_list: vertex_index_block_ptr_type;
  edge_index_block_free_list: edge_index_block_ptr_type;
  vertices: integer;
  edges: integer;
  coincidence_d_squared: real;
  mesh_topology_list: mesh_topology_ptr_type;
  mesh_topology_free_list: mesh_topology_ptr_type;


{************************************************}
{ routines to identify identical mesh topologies }
{************************************************}


function New_mesh_topology: mesh_topology_ptr_type;
var
  mesh_topology_ptr: mesh_topology_ptr_type;
begin
  {**********************************}
  { get mesh topology from free list }
  {**********************************}
  if (mesh_topology_free_list <> nil) then
    begin
      mesh_topology_ptr := mesh_topology_free_list;
      mesh_topology_free_list := mesh_topology_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new mesh topology');
      new(mesh_topology_ptr);
    end;

  {**************************}
  { initialize mesh topology }
  {**************************}
  mesh_topology_ptr^.mesh_ptr := nil;
  mesh_topology_ptr^.topology_ptr := nil;
  mesh_topology_ptr^.next := nil;

  New_mesh_topology := mesh_topology_ptr;
end; {function New_mesh_topology}


procedure Free_mesh_topology(var mesh_topology_ptr: mesh_topology_ptr_type);
begin
  {********************}
  { free mesh topology }
  {********************}
  mesh_topology_ptr^.next := mesh_topology_free_list;
  mesh_topology_free_list := mesh_topology_ptr;
  mesh_topology_ptr := nil;
end; {procedure Free_mesh_topology}


function Found_mesh_topology(mesh_ptr: mesh_ptr_type;
  var topology_ptr: topology_ptr_type): boolean;
var
  found: boolean;
  mesh_topology_ptr: mesh_topology_ptr_type;
begin
  mesh_topology_ptr := mesh_topology_list;
  found := false;

  while (mesh_topology_ptr <> nil) and not found do
    begin
      if Same_mesh_topology(mesh_topology_ptr^.mesh_ptr, mesh_ptr) then
        begin
          found := true;
          topology_ptr := mesh_topology_ptr^.topology_ptr;
        end
      else
        mesh_topology_ptr := mesh_topology_ptr^.next;
    end;

  Found_mesh_topology := found;
end; {function Found_mesh_topology}


procedure Make_mesh_topology_link(mesh_ptr: mesh_ptr_type;
  topology_ptr: topology_ptr_type);
var
  mesh_topology_ptr: mesh_topology_ptr_type;
begin
  if mesh_ptr <> nil then
    if topology_ptr <> nil then
      begin
        mesh_topology_ptr := New_mesh_topology;

        {*******************************}
        { initialize mesh topology link }
        {*******************************}
        mesh_topology_ptr^.mesh_ptr := mesh_ptr;
        mesh_topology_ptr^.topology_ptr := topology_ptr;

        {********************************}
        { add to mesh topology link list }
        {********************************}
        mesh_topology_ptr^.next := mesh_topology_list;
        mesh_topology_list := mesh_topology_ptr;
      end;
end; {procedure Make_mesh_topology_link}


procedure Free_mesh_topology_link(mesh_ptr: mesh_ptr_type);
var
  found: boolean;
  mesh_topology_ptr, prev: mesh_topology_ptr_type;
begin
  mesh_topology_ptr := mesh_topology_list;
  prev := nil;
  found := false;

  while (mesh_topology_ptr <> nil) and not found do
    begin
      if (mesh_topology_ptr^.mesh_ptr = mesh_ptr) then
        begin
          found := true;
        end
      else
        begin
          prev := mesh_topology_ptr;
          mesh_topology_ptr := mesh_topology_ptr^.next;
        end;
    end;

  if found then
    begin
      if prev <> nil then
        begin
          prev^.next := mesh_topology_ptr^.next;
          Free_mesh_topology(mesh_topology_ptr);
        end
      else
        begin
          mesh_topology_list := mesh_topology_list^.next;
          Free_mesh_topology(mesh_topology_ptr);
        end;
    end;
end; {procedure Free_mesh_topology_link}


procedure Free_topology_mesh_link(topology_ptr: topology_ptr_type);
var
  found: boolean;
  mesh_topology_ptr, prev: mesh_topology_ptr_type;
begin
  mesh_topology_ptr := mesh_topology_list;
  prev := nil;
  found := false;

  while (mesh_topology_ptr <> nil) and not found do
    begin
      if (mesh_topology_ptr^.topology_ptr = topology_ptr) then
        begin
          found := true;
        end
      else
        begin
          prev := mesh_topology_ptr;
          mesh_topology_ptr := mesh_topology_ptr^.next;
        end;
    end;

  if found then
    begin
      if prev <> nil then
        begin
          prev^.next := mesh_topology_ptr^.next;
          Free_mesh_topology(mesh_topology_ptr);
        end
      else
        begin
          mesh_topology_list := mesh_topology_list^.next;
          Free_mesh_topology(mesh_topology_ptr);
        end;
    end;
end; {procedure Free_topology_mesh_link}


{*******************************************}
{ routines to create topologies from meshes }
{*******************************************}


function New_vertex_index_block: vertex_index_block_ptr_type;
var
  vertex_index_block_ptr: vertex_index_block_ptr_type;
begin
  {***************************************}
  { get vertex_index_block from free list }
  {***************************************}
  if (vertex_index_block_free_list <> nil) then
    begin
      vertex_index_block_ptr := vertex_index_block_free_list;
      vertex_index_block_free_list := vertex_index_block_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new vertex index block');
      new(vertex_index_block_ptr);
    end;

  {*******************************}
  { initialize vertex index block }
  {*******************************}
  vertex_index_block_ptr^.next := nil;

  New_vertex_index_block := vertex_index_block_ptr;
end; {function New_vertex_index_block}


function New_edge_index_block: edge_index_block_ptr_type;
var
  edge_index_block_ptr: edge_index_block_ptr_type;
begin
  {*************************************}
  { get edge_index_block from free list }
  {*************************************}
  if (edge_index_block_free_list <> nil) then
    begin
      edge_index_block_ptr := edge_index_block_free_list;
      edge_index_block_free_list := edge_index_block_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new edge index block');
      new(edge_index_block_ptr);
    end;

  {*****************************}
  { initialize edge index block }
  {*****************************}
  edge_index_block_ptr^.next := nil;

  New_edge_index_block := edge_index_block_ptr;
end; {function New_edge_index_block}


function Index_vertex(vertex_index_block_ptr: vertex_index_block_ptr_type;
  index: integer): vertex_ptr_type;
var
  counter: integer;
  vertex_ptr: vertex_ptr_type;
begin
  if (index <= vertices) and (index > 0) then
    begin
      index := index - 1;
      for counter := 1 to index div vertex_index_block_size do
        vertex_index_block_ptr := vertex_index_block_ptr^.next;
      vertex_ptr := vertex_index_block_ptr^.ptr_array[index mod
        vertex_index_block_size];
    end
  else
    begin
      writeln('Error - illegal reference to mesh vertex ', index);
      vertex_ptr := nil;
    end;
  Index_vertex := vertex_ptr;
end; {function Index_vertex}


function Index_edge(edge_index_block_ptr: edge_index_block_ptr_type;
  index: integer): edge_ptr_type;
var
  counter: integer;
  edge_ptr: edge_ptr_type;
begin
  if (index <= edges) and (index > 0) then
    begin
      index := index - 1;
      for counter := 1 to index div edge_index_block_size do
        edge_index_block_ptr := edge_index_block_ptr^.next;
      edge_ptr := edge_index_block_ptr^.ptr_array[index mod
        edge_index_block_size];
    end
  else
    begin
      writeln('Error - illegal reference to mesh edge ', index);
      edge_ptr := nil;
    end;
  Index_edge := edge_ptr;
end; {function Index_edge}


{************************}
{ mesh topology routines }
{************************}


function Coincident_vertices(vertex1, vertex2: vector_type): boolean;
var
  vector: vector_type;
begin
  vector := Vector_difference(vertex2, vertex1);
  Coincident_vertices := (Dot_product(vector, vector) < coincidence_d_squared);
end; {function Coincident_vertices}


function Coincident_edges(vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type): boolean;
var
  same_edge, reverse_edge: boolean;
  point_ptr1, point_ptr2, point_ptr3, point_ptr4: point_ptr_type;
begin
  point_ptr1 := vertex_ptr1^.point_ptr;
  point_ptr2 := vertex_ptr2^.point_ptr;
  point_ptr3 := edge_ptr^.vertex_ptr1^.point_ptr;
  point_ptr4 := edge_ptr^.vertex_ptr2^.point_ptr;

  same_edge := (point_ptr1 = point_ptr3) and (point_ptr2 = point_ptr4);
  reverse_edge := (point_ptr1 = point_ptr4) and (point_ptr2 = point_ptr3);

  Coincident_edges := same_edge or reverse_edge;
end; {function Coincident_edges}


function Mesh_topology(mesh_ptr: mesh_ptr_type;
  edge_kind: edge_kind_type;
  checking, mending: boolean): topology_ptr_type;
var
  topology_ptr: topology_ptr_type;
  mesh_vertex_ptr, mesh_vertex_ptr2: mesh_vertex_ptr_type;
  mesh_edge_ptr: mesh_edge_ptr_type;
  mesh_edge_index_ptr: mesh_edge_index_ptr_type;
  mesh_face_ptr: mesh_face_ptr_type;
  point_ptr: point_ptr_type;
  vertex_ptr, vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  vertex1, vertex2: integer;
  edge_ptr: edge_ptr_type;

  vertex_array_size: longint;
  edge_array_size: longint;

  vertex_array_ptr, follow_vertex_ptr: vertex_index_ptr_type;
  edge_array_ptr, follow_edge_ptr: edge_index_ptr_type;
  found: boolean;
begin
  if not mending and Found_mesh_topology(mesh_ptr, topology_ptr) then
    topology_ptr := Copy_topology(topology_ptr)
  else
    begin
      topology_ptr := Make_topology;
      Make_mesh_topology_link(mesh_ptr, topology_ptr);

      {*************************}
      { allocate dynamic arrays }
      {*************************}
      vertex_array_size := longint(mesh_ptr^.vertices + 1) *
        sizeof(vertex_ptr_type);
      edge_array_size := longint(mesh_ptr^.edges + 1) * sizeof(edge_ptr_type);

      if memory_alert then
        writeln('allocating new vertex array');
      vertex_array_ptr := vertex_index_ptr_type(New_ptr(vertex_array_size));

      if memory_alert then
        writeln('allocating new edge array');
      edge_array_ptr := edge_index_ptr_type(New_ptr(edge_array_size));

      {***************}
      { make vertices }
      {***************}
      mesh_vertex_ptr := mesh_ptr^.vertex_ptr;
      follow_vertex_ptr := vertex_array_ptr;
      while (mesh_vertex_ptr <> nil) do
        begin
          follow_vertex_ptr := vertex_index_ptr_type(longint(follow_vertex_ptr)
            + sizeof(vertex_ptr_type));

          if mending then
            begin
              found := false;
              mesh_vertex_ptr2 := mesh_ptr^.vertex_ptr;
              vertex_ptr := topology_ptr^.vertex_ptr;

              while (mesh_vertex_ptr2 <> mesh_vertex_ptr) and not found do
                begin
                  if Coincident_vertices(mesh_vertex_ptr2^.point,
                    mesh_vertex_ptr^.point) then
                    found := true
                  else
                    begin
                      mesh_vertex_ptr2 := mesh_vertex_ptr2^.next;
                      vertex_ptr := vertex_ptr^.next;
                    end;
                end;

              if not found then
                point_ptr := Make_point_topology
              else
                point_ptr := vertex_ptr^.point_ptr;
            end
          else
            point_ptr := Make_point_topology;

          follow_vertex_ptr^ := Make_vertex_topology(point_ptr);
          mesh_vertex_ptr := mesh_vertex_ptr^.next;
        end;

      {************}
      { make edges }
      {************}
      if not checking then
        begin
          {**************************************}
          { make edges without checking validity }
          {**************************************}
          mesh_edge_ptr := mesh_ptr^.edge_ptr;
          follow_edge_ptr := edge_array_ptr;
          while (mesh_edge_ptr <> nil) do
            begin
              follow_edge_ptr := edge_index_ptr_type(longint(follow_edge_ptr) +
                sizeof(edge_ptr_type));
              vertex_ptr1 := vertex_index_ptr_type(longint(vertex_array_ptr) +
                mesh_edge_ptr^.vertex1 * sizeof(vertex_ptr_type))^;
              vertex_ptr2 := vertex_index_ptr_type(longint(vertex_array_ptr) +
                mesh_edge_ptr^.vertex2 * sizeof(vertex_ptr_type))^;
              follow_edge_ptr^ := Make_edge_topology(vertex_ptr1, vertex_ptr2,
                edge_kind, nil);
              mesh_edge_ptr := mesh_edge_ptr^.next;
            end;
        end
      else
        begin
          {*******************************}
          { make edges and check validity }
          {*******************************}
          mesh_edge_ptr := mesh_ptr^.edge_ptr;
          follow_edge_ptr := edge_array_ptr;
          while (mesh_edge_ptr <> nil) do
            begin
              vertex1 := mesh_edge_ptr^.vertex1;
              vertex2 := mesh_edge_ptr^.vertex2;

              if (vertex1 >= 1) then
                if (vertex1 <= mesh_ptr^.vertices) then
                  if (vertex2 >= 1) then
                    if (vertex2 <= mesh_ptr^.vertices) then
                      begin
                        follow_edge_ptr :=
                          edge_index_ptr_type(longint(follow_edge_ptr) +
                          sizeof(edge_ptr_type));
                        vertex_ptr1 :=
                          vertex_index_ptr_type(longint(vertex_array_ptr) +
                            vertex1
                          * sizeof(vertex_ptr_type))^;
                        vertex_ptr2 :=
                          vertex_index_ptr_type(longint(vertex_array_ptr) +
                            vertex2
                          * sizeof(vertex_ptr_type))^;

                        if mending then
                          begin
                            found := false;

                            edge_ptr := topology_ptr^.edge_ptr;
                            while (edge_ptr <> nil) and not found do
                              begin
                                if Coincident_edges(vertex_ptr1, vertex_ptr2,
                                  edge_ptr) then
                                  found := true
                                else
                                  edge_ptr := edge_ptr^.next;
                              end;

                            if found then
                              follow_edge_ptr^ :=
                                Make_edge_topology(vertex_ptr1, vertex_ptr2,
                                duplicate_edge, edge_ptr)
                            else
                              follow_edge_ptr^ :=
                                Make_edge_topology(vertex_ptr1, vertex_ptr2,
                                edge_kind, nil);
                          end
                        else
                          follow_edge_ptr^ := Make_edge_topology(vertex_ptr1,
                            vertex_ptr2, edge_kind, nil);
                      end
                    else
                      Error('mesh references nonexistent vertex.');

              mesh_edge_ptr := mesh_edge_ptr^.next;
            end;
        end;

      {************}
      { make faces }
      {************}
      if not checking then
        begin
          {**************************************}
          { make edges without checking validity }
          {**************************************}
          mesh_face_ptr := mesh_ptr^.face_ptr;
          while (mesh_face_ptr <> nil) do
            begin
              Make_face_topology;
              mesh_edge_index_ptr := mesh_face_ptr^.edge_index_ptr;
              while (mesh_edge_index_ptr <> nil) do
                begin
                  edge_ptr := edge_index_ptr_type(longint(edge_array_ptr) +
                    abs(mesh_edge_index_ptr^.index) * sizeof(edge_ptr_type))^;
                  if mesh_edge_index_ptr^.index > 0 then
                    Make_directed_edge(edge_ptr, true)
                  else
                    Make_directed_edge(edge_ptr, false);
                  mesh_edge_index_ptr := mesh_edge_index_ptr^.next;
                end;
              mesh_face_ptr := mesh_face_ptr^.next;
            end;
        end
      else
        begin
          {*******************************}
          { make edges and check validity }
          {*******************************}
          mesh_face_ptr := mesh_ptr^.face_ptr;
          while (mesh_face_ptr <> nil) do
            begin
              Make_face_topology;
              mesh_edge_index_ptr := mesh_face_ptr^.edge_index_ptr;
              while (mesh_edge_index_ptr <> nil) do
                begin
                  if (abs(mesh_edge_index_ptr^.index) >= 1) then
                    if (abs(mesh_edge_index_ptr^.index) <= mesh_ptr^.edges) then
                      begin
                        edge_ptr := edge_index_ptr_type(longint(edge_array_ptr)
                          + abs(mesh_edge_index_ptr^.index) *
                          sizeof(edge_ptr_type))^;
                        if mesh_edge_index_ptr^.index > 0 then
                          Make_directed_edge(edge_ptr, true)
                        else
                          Make_directed_edge(edge_ptr, false);
                      end
                    else
                      Error('mesh references nonexistent edge.');

                  mesh_edge_index_ptr := mesh_edge_index_ptr^.next;
                end;
              mesh_face_ptr := mesh_face_ptr^.next;
            end;
        end;

      {*****************************}
      { free vertex and edge arrays }
      {*****************************}
      Free_ptr(ptr_type(vertex_array_ptr));
      Free_ptr(ptr_type(edge_array_ptr));
    end;

  Mesh_topology := topology_ptr;
end; {function Mesh_topology}


function Mesh_topology2(mesh_ptr: mesh_ptr_type;
  edge_kind: edge_kind_type): topology_ptr_type;
var
  topology_ptr: topology_ptr_type;
  mesh_vertex_ptr: mesh_vertex_ptr_type;
  mesh_edge_ptr: mesh_edge_ptr_type;
  mesh_edge_index_ptr: mesh_edge_index_ptr_type;
  mesh_face_ptr: mesh_face_ptr_type;
  point_ptr: point_ptr_type;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  edge_ptr: edge_ptr_type;
  index: integer;
  vertex_index_block_ptr: vertex_index_block_ptr_type;
  last_vertex_index_block_ptr: vertex_index_block_ptr_type;
  edge_index_block_ptr: edge_index_block_ptr_type;
  last_edge_index_block_ptr: edge_index_block_ptr_type;
begin
  if Found_mesh_topology(mesh_ptr, topology_ptr) then
    topology_ptr := Copy_topology(topology_ptr)
  else
    begin
      topology_ptr := Make_topology;
      Make_mesh_topology_link(mesh_ptr, topology_ptr);

      {**************************************************************}
      { this implementation uses linked lists of constant sized      }
      { index blocks instead of a dynamic array for the index block  }
      {**************************************************************}
      vertex_index_block_ptr := nil;
      edge_index_block_ptr := nil;

      {***************}
      { make vertices }
      {***************}
      mesh_vertex_ptr := mesh_ptr^.vertex_ptr;
      vertices := 0;
      last_vertex_index_block_ptr := nil;
      while (mesh_vertex_ptr <> nil) do
        begin
          index := vertices mod vertex_index_block_size;
          if (index = 0) then
            begin
              {*******************************}
              { create new vertex index block }
              {*******************************}
              if (last_vertex_index_block_ptr <> nil) then
                begin
                  last_vertex_index_block_ptr^.next := New_vertex_index_block;
                  last_vertex_index_block_ptr :=
                    last_vertex_index_block_ptr^.next;
                end
              else
                begin
                  vertex_index_block_ptr := New_vertex_index_block;
                  last_vertex_index_block_ptr := vertex_index_block_ptr;
                end;
            end;
          point_ptr := Make_point_topology;
          last_vertex_index_block_ptr^.ptr_array[index] :=
            Make_vertex_topology(point_ptr);
          mesh_vertex_ptr := mesh_vertex_ptr^.next;
          vertices := vertices + 1;
        end;

      {************}
      { make edges }
      {************}
      mesh_edge_ptr := mesh_ptr^.edge_ptr;
      edges := 0;
      last_edge_index_block_ptr := nil;
      while (mesh_edge_ptr <> nil) do
        begin
          index := edges mod vertex_index_block_size;
          if (index = 0) then
            begin
              {*****************************}
              { create new edge index block }
              {*****************************}
              if (last_edge_index_block_ptr <> nil) then
                begin
                  last_edge_index_block_ptr^.next := New_edge_index_block;
                  last_edge_index_block_ptr := last_edge_index_block_ptr^.next;
                end
              else
                begin
                  edge_index_block_ptr := New_edge_index_block;
                  last_edge_index_block_ptr := edge_index_block_ptr;
                end;
            end;
          vertex_ptr1 := Index_vertex(vertex_index_block_ptr,
            mesh_edge_ptr^.vertex1);
          vertex_ptr2 := Index_vertex(vertex_index_block_ptr,
            mesh_edge_ptr^.vertex2);
          with last_edge_index_block_ptr^ do
            ptr_array[index] := Make_edge_topology(vertex_ptr1, vertex_ptr2,
              edge_kind, nil);
          mesh_edge_ptr := mesh_edge_ptr^.next;
          edges := edges + 1;
        end;

      {************}
      { make faces }
      {************}
      mesh_face_ptr := mesh_ptr^.face_ptr;
      while (mesh_face_ptr <> nil) do
        begin
          Make_face_topology;
          mesh_edge_index_ptr := mesh_face_ptr^.edge_index_ptr;
          while (mesh_edge_index_ptr <> nil) do
            begin
              edge_ptr := Index_edge(edge_index_block_ptr,
                abs(mesh_edge_index_ptr^.index));
              if mesh_edge_index_ptr^.index > 0 then
                Make_directed_edge(edge_ptr, true)
              else
                Make_directed_edge(edge_ptr, false);
              mesh_edge_index_ptr := mesh_edge_index_ptr^.next;
            end;
          mesh_face_ptr := mesh_face_ptr^.next;
        end;

      {***********************************}
      { return index blocks to free lists }
      {***********************************}
      if (last_vertex_index_block_ptr <> nil) then
        begin
          last_vertex_index_block_ptr^.next := vertex_index_block_free_list;
          vertex_index_block_free_list := vertex_index_block_ptr;
        end;

      if (last_edge_index_block_ptr <> nil) then
        begin
          last_edge_index_block_ptr^.next := edge_index_block_free_list;
          edge_index_block_free_list := edge_index_block_ptr;
        end;
    end;

  Mesh_topology2 := topology_ptr;
end; {function Mesh_topology2}


procedure Find_mesh_real_edges(topology_ptr: topology_ptr_type);
var
  edge_ptr: edge_ptr_type;
begin
  edge_ptr := topology_ptr^.edge_ptr;
  while (edge_ptr <> nil) do
    begin
      {**********************************}
      { if edge has less than 2 adjacent }
      { faces, then it is a real edge.   }
      {**********************************}
      if edge_ptr^.edge_kind <> duplicate_edge then
        begin
          if edge_ptr^.face_list = nil then
            edge_ptr^.edge_kind := real_edge
          else if edge_ptr^.face_list^.next = nil then
            edge_ptr^.edge_kind := real_edge;
        end;
      edge_ptr := edge_ptr^.next;
    end;
end; {procedure Find_mesh_real_edges}


{************************}
{ mesh geometry routines }
{************************}


procedure Extend_extent_box_to_surface(var extent_box: extent_box_type;
  surface_ptr: surface_ptr_type);
var
  point_geometry_ptr: point_geometry_ptr_type;
begin
  point_geometry_ptr := surface_ptr^.geometry_ptr^.point_geometry_ptr;
  while (point_geometry_ptr <> nil) do
    begin
      Extend_extent_box_to_point(extent_box, point_geometry_ptr^.point);
      point_geometry_ptr := point_geometry_ptr^.next;
    end;
end; {procedure Extend_extent_box_to_surface}


procedure Unitize_mesh(surface_ptr: surface_ptr_type;
  var trans: trans_type);
var
  follow: surface_ptr_type;
  point_geometry_ptr: point_geometry_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
  extent_box: extent_box_type;
  dimensions: vector_type;
begin
  {**************************************}
  { find max and min extents of vertices }
  {**************************************}
  Init_extent_box(extent_box);

  follow := surface_ptr;
  while (follow <> nil) do
    begin
      Extend_extent_box_to_surface(extent_box, follow);
      follow := follow^.next;
    end;
  trans := Extent_box_trans(extent_box);

  with trans do
    begin
      if x_axis.x < tiny then
        x_axis.x := tiny;
      if y_axis.y < tiny then
        y_axis.y := tiny;
      if z_axis.z < tiny then
        z_axis.z := tiny;
      dimensions.x := x_axis.x;
      dimensions.y := y_axis.y;
      dimensions.z := z_axis.z;
    end;

  {**********************************}
  { transform vertices to new coords }
  {**********************************}
  follow := surface_ptr;
  while (follow <> nil) do
    begin
      point_geometry_ptr := follow^.geometry_ptr^.point_geometry_ptr;
      while (point_geometry_ptr <> nil) do
        begin
          point_geometry_ptr^.point :=
            Vector_difference(point_geometry_ptr^.point,
            trans.origin);
          point_geometry_ptr^.point := Vector_divide(point_geometry_ptr^.point,
            dimensions);
          point_geometry_ptr := point_geometry_ptr^.next;
        end;
      follow := follow^.next;
    end;

  {****************************************}
  { transform vertex normals to new coords }
  {****************************************}
  follow := surface_ptr;
  while (follow <> nil) do
    begin
      vertex_geometry_ptr := follow^.geometry_ptr^.vertex_geometry_ptr;
      while (vertex_geometry_ptr <> nil) do
        begin
          vertex_geometry_ptr^.normal :=
            Vector_divide(vertex_geometry_ptr^.normal, dimensions);
          vertex_geometry_ptr := vertex_geometry_ptr^.next;
        end;
      follow := follow^.next;
    end;
end; {procedure Unitize_mesh}


procedure Find_simple_mesh_face_normals(surface_ptr: surface_ptr_type);
var
  geometry_ptr: geometry_ptr_type;
  topology_ptr: topology_ptr_type;
  face_ptr: face_ptr_type;
  face_geometry_ptr: face_geometry_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  point_ptr1, point_ptr2: point_ptr_type;
  point1, point2: vector_type;
  vector1, vector2: vector_type;
begin
  geometry_ptr := surface_ptr^.geometry_ptr;
  topology_ptr := surface_ptr^.topology_ptr;

  {***********************************}
  { compute face normal from vertices }
  {***********************************}
  face_ptr := topology_ptr^.face_ptr;
  while (face_ptr <> nil) do
    begin
      {face_geometry_ptr := Get_face_geometry(face_ptr^.index);}
      face_geometry_ptr := face_ptr^.face_geometry_ptr;
      directed_edge_ptr := face_ptr^.cycle_ptr^.directed_edge_ptr;

      {***********************************}
      { find normals from first two edges }
      {***********************************}
      if (directed_edge_ptr <> nil) then
        begin
          if (directed_edge_ptr^.orientation) then
            begin
              point_ptr1 := directed_edge_ptr^.edge_ptr^.point_ptr1;
              point_ptr2 := directed_edge_ptr^.edge_ptr^.point_ptr2;
            end
          else
            begin
              point_ptr1 := directed_edge_ptr^.edge_ptr^.point_ptr2;
              point_ptr2 := directed_edge_ptr^.edge_ptr^.point_ptr1;
            end;

          point1 := point_ptr1^.point_geometry_ptr^.point;
          point2 := point_ptr2^.point_geometry_ptr^.point;
          vector1 := Vector_difference(point2, point1);
          directed_edge_ptr := directed_edge_ptr^.next;

          if directed_edge_ptr <> nil then
            begin
              if (directed_edge_ptr^.orientation) then
                begin
                  point_ptr1 := directed_edge_ptr^.edge_ptr^.point_ptr1;
                  point_ptr2 := directed_edge_ptr^.edge_ptr^.point_ptr2;
                end
              else
                begin
                  point_ptr1 := directed_edge_ptr^.edge_ptr^.point_ptr2;
                  point_ptr2 := directed_edge_ptr^.edge_ptr^.point_ptr1;
                end;

              point1 := point_ptr1^.point_geometry_ptr^.point;
              point2 := point_ptr2^.point_geometry_ptr^.point;
              vector2 := Vector_difference(point2, point1);
              face_geometry_ptr^.normal := Normalize(Cross_product(vector1,
                vector2));
            end
          else
            face_geometry_ptr^.normal := z_vector;
        end
      else
        face_geometry_ptr^.normal := z_vector;

      face_ptr := face_ptr^.next;
    end;

  {************************}
  { set mesh geometry flag }
  {************************}
  geometry_ptr^.geometry_info.face_normals_avail := true;
end; {procedure Find_simple_mesh_face_normals}


procedure Find_mesh_face_normals(surface_ptr: surface_ptr_type);
var
  geometry_ptr: geometry_ptr_type;
  topology_ptr: topology_ptr_type;
  face_ptr: face_ptr_type;
  face_geometry_ptr: face_geometry_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  point_ptr1, point_ptr2: point_ptr_type;
  point1, point2, normal: vector_type;
  vector1, vector2, first_vector: vector_type;
begin
  geometry_ptr := surface_ptr^.geometry_ptr;
  topology_ptr := surface_ptr^.topology_ptr;

  {***********************************}
  { compute face normal from vertices }
  {***********************************}
  face_ptr := topology_ptr^.face_ptr;
  while (face_ptr <> nil) do
    begin
      {face_geometry_ptr := Get_face_geometry(face_ptr^.index);}
      face_geometry_ptr := face_ptr^.face_geometry_ptr;
      directed_edge_ptr := face_ptr^.cycle_ptr^.directed_edge_ptr;

      if (directed_edge_ptr <> nil) then
        begin
          if (directed_edge_ptr^.next <> nil) then
            begin
              {************************}
              { find point1 and point2 }
              {************************}
              if (directed_edge_ptr^.orientation) then
                begin
                  point_ptr1 := directed_edge_ptr^.edge_ptr^.point_ptr1;
                  point_ptr2 := directed_edge_ptr^.edge_ptr^.point_ptr2;
                end
              else
                begin
                  point_ptr1 := directed_edge_ptr^.edge_ptr^.point_ptr2;
                  point_ptr2 := directed_edge_ptr^.edge_ptr^.point_ptr1;
                end;

              {point1 := Get_point_geometry(point_ptr1^.index1)^.point;}
              {point2 := Get_point_geometry(point_ptr2^.index2)^.point;}
              point1 := point_ptr1^.point_geometry_ptr^.point;
              point2 := point_ptr2^.point_geometry_ptr^.point;
              vector2 := Vector_difference(point2, point1);
              first_vector := vector2;
              normal := zero_vector;

              while (directed_edge_ptr^.next <> nil) do
                begin
                  directed_edge_ptr := directed_edge_ptr^.next;

                  point1 := point2;
                  vector1 := vector2;

                  {*************}
                  { find point2 }
                  {*************}
                  if (directed_edge_ptr^.orientation) then
                    point_ptr2 := directed_edge_ptr^.edge_ptr^.point_ptr2
                  else
                    point_ptr2 := directed_edge_ptr^.edge_ptr^.point_ptr1;

                  {point2 := Get_point_geometry(point_ptr2^.index)^.point;}
                  point2 := point_ptr2^.point_geometry_ptr^.point;
                  vector2 := Vector_difference(point2, point1);
                  normal := Vector_sum(normal, Cross_product(vector1, vector2));
                end;

              normal := Vector_sum(normal, Cross_product(vector2,
                first_vector));
              normal := Normalize(normal);
              face_geometry_ptr^.normal := normal;
            end
          else
            face_geometry_ptr^.normal := z_vector;
        end
      else
        face_geometry_ptr^.normal := z_vector;

      face_ptr := face_ptr^.next;
    end;

  {************************}
  { set mesh geometry flag }
  {************************}
  geometry_ptr^.geometry_info.face_normals_avail := true;
end; {procedure Find_mesh_face_normals}


procedure Find_mesh_vertex_normals(surface_ptr: surface_ptr_type);
var
  geometry_ptr: geometry_ptr_type;
  topology_ptr: topology_ptr_type;
  vertex_normal_kind: vertex_normal_kind_type;
  face_geometry_ptr: face_geometry_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
  face_ref_ptr: face_ref_ptr_type;
  edge_ref_ptr: edge_ref_ptr_type;
  vertex_ptr: vertex_ptr_type;
  normal: vector_type;
  counter: integer;
begin
  geometry_ptr := surface_ptr^.geometry_ptr;
  topology_ptr := surface_ptr^.topology_ptr;

  {******************************************}
  { compute vertex normal by averaging the   }
  { normals of faces adjacent to the vertex. }
  {******************************************}
  vertex_ptr := topology_ptr^.vertex_ptr;
  while (vertex_ptr <> nil) do
    begin
      {vertex_geometry_ptr := Get_vertex_geometry(vertex_ptr^.index);}
      vertex_geometry_ptr := vertex_ptr^.vertex_geometry_ptr;

      if Equal_vector(vertex_geometry_ptr^.normal, zero_vector) then
        begin
          {*************************}
          { mark all adjacent faces }
          {*************************}
          edge_ref_ptr := vertex_ptr^.point_ptr^.edge_list;
          while (edge_ref_ptr <> nil) do
            begin
              face_ref_ptr := edge_ref_ptr^.edge_ptr^.face_list;
              while (face_ref_ptr <> nil) do
                begin
                  face_ref_ptr^.touched := false;
                  face_ref_ptr := face_ref_ptr^.next;
                end;
              edge_ref_ptr := edge_ref_ptr^.next;
            end;

          {*******************************}
          { add normals of adjacent faces }
          {*******************************}
          normal := zero_vector;
          counter := 0;
          edge_ref_ptr := vertex_ptr^.point_ptr^.edge_list;
          while (edge_ref_ptr <> nil) do
            begin
              face_ref_ptr := edge_ref_ptr^.edge_ptr^.face_list;
              while (face_ref_ptr <> nil) do
                begin
                  {face_geometry_ptr := Get_face_geometry(face_ref_ptr^.face_ptr^.index);}
                  face_geometry_ptr :=
                    face_ref_ptr^.face_ptr^.face_geometry_ptr;
                  if not face_ref_ptr^.touched then
                    begin
                      normal := Vector_sum(normal, face_geometry_ptr^.normal);
                      counter := counter + 1;
                      face_ref_ptr^.touched := true;
                    end;
                  face_ref_ptr := face_ref_ptr^.next;
                end;
              edge_ref_ptr := edge_ref_ptr^.next;
            end;

          {****************************}
          { rescale (normalize) normal }
          {****************************}
          if (counter <> 0) then
            normal := Vector_scale(normal, 1 / counter)
          else
            normal := z_vector;

          vertex_geometry_ptr^.normal := normal;
        end
      else
        vertex_geometry_ptr^.normal := Normalize(vertex_geometry_ptr^.normal);

      {**********************************************************}
      { check resulting normal against normals of adjacent faces }
      {**********************************************************}
      vertex_normal_kind := two_sided_vertex;
      edge_ref_ptr := vertex_ptr^.point_ptr^.edge_list;
      while (edge_ref_ptr <> nil) do
        begin
          face_ref_ptr := edge_ref_ptr^.edge_ptr^.face_list;
          while (face_ref_ptr <> nil) and (vertex_normal_kind = two_sided_vertex)
            do
            begin
              {face_geometry_ptr := Get_face_geometry(face_ref_ptr^.face_ptr^.index);}
              face_geometry_ptr := face_ref_ptr^.face_ptr^.face_geometry_ptr;
              if face_ref_ptr^.touched then
                begin
                  if not Same_direction(face_geometry_ptr^.normal, normal) then
                    vertex_normal_kind := one_sided_vertex;
                  face_ref_ptr^.touched := false;
                end;
              face_ref_ptr := face_ref_ptr^.next;
            end;
          edge_ref_ptr := edge_ref_ptr^.next;
        end;
      vertex_geometry_ptr^.vertex_normal_kind := vertex_normal_kind;

      vertex_ptr := vertex_ptr^.next;
    end;

  {************************}
  { set mesh geometry flag }
  {************************}
  geometry_ptr^.geometry_info.vertex_normals_avail := true;
end; {procedure Find_mesh_vertex_normals}


procedure Find_mesh_uv_vectors(surface_ptr: surface_ptr_type);
var
  geometry_ptr: geometry_ptr_type;
  topology_ptr: topology_ptr_type;
  edge_ptr: edge_ptr_type;
  vertex_ptr: vertex_ptr_type;
  edge_ref_ptr: edge_ref_ptr_type;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  vertex_geometry_ptr: vertex_geometry_ptr_type;
  vertex_geometry_ptr1, vertex_geometry_ptr2: vertex_geometry_ptr_type;
  point_geometry_ptr1, point_geometry_ptr2: point_geometry_ptr_type;
  edge_geometry_ptr: edge_geometry_ptr_type;
  vector1, vector2: vector_type;
  u_gradient, v_gradient: vector_type;
  u_axis, v_axis: vector_type;
begin
  geometry_ptr := surface_ptr^.geometry_ptr;
  topology_ptr := surface_ptr^.topology_ptr;

  {*************************************************************}
  { allocate edge geometry for texture gradient along each edge }
  {*************************************************************}
  edge_ptr := topology_ptr^.edge_ptr;
  while (edge_ptr <> nil) do
    begin
      edge_ptr^.edge_geometry_ptr := New_edge_geometry;
      edge_ptr := edge_ptr^.next;
    end;

  {************************************************}
  { first compute texture gradient along each edge }
  {************************************************}
  edge_ptr := topology_ptr^.edge_ptr;
  while (edge_ptr <> nil) do
    begin
      vertex_ptr1 := edge_ptr^.vertex_ptr1;
      vertex_ptr2 := edge_ptr^.vertex_ptr2;

      {vertex_geometry_ptr1 := Get_vertex_geometry(vertex_ptr1^.index);}
      {vertex_geometry_ptr2 := Get_vertex_geometry(vertex_ptr2^.index);}
      {point_geometry_ptr1 := Get_point_geometry(vertex_ptr1^.point_ptr^.index);}
      {point_geometry_ptr2 := Get_point_geometry(vertex_ptr2^.point_ptr^.index);}

      vertex_geometry_ptr1 := vertex_ptr1^.vertex_geometry_ptr;
      vertex_geometry_ptr2 := vertex_ptr2^.vertex_geometry_ptr;
      point_geometry_ptr1 := vertex_ptr1^.point_ptr^.point_geometry_ptr;
      point_geometry_ptr2 := vertex_ptr2^.point_ptr^.point_geometry_ptr;

      vector1 := Vector_difference(vertex_geometry_ptr2^.texture,
        vertex_geometry_ptr1^.texture);
      vector2 := Vector_difference(point_geometry_ptr2^.point,
        point_geometry_ptr1^.point);
      u_gradient := Vector_scale(vector2, vector1.x);
      v_gradient := Vector_scale(vector2, vector1.y);

      edge_geometry_ptr := edge_ptr^.edge_geometry_ptr;
      edge_geometry_ptr^.u_gradient := u_gradient;
      edge_geometry_ptr^.v_gradient := v_gradient;
      edge_ptr := edge_ptr^.next;
    end;

  {***********************************************}
  { average texture gradient of surrounding edges }
  {***********************************************}
  vertex_ptr := topology_ptr^.vertex_ptr;
  while (vertex_ptr <> nil) do
    begin
      {****************************************}
      { add texture gradient of adjacent edges }
      {****************************************}
      u_axis := zero_vector;
      v_axis := zero_vector;
      edge_ref_ptr := vertex_ptr^.point_ptr^.edge_list;

      while (edge_ref_ptr <> nil) do
        begin
          edge_geometry_ptr := edge_ref_ptr^.edge_ptr^.edge_geometry_ptr;
          u_axis := Vector_sum(u_axis, edge_geometry_ptr^.u_gradient);
          v_axis := Vector_sum(v_axis, edge_geometry_ptr^.v_gradient);
          edge_ref_ptr := edge_ref_ptr^.next;
        end;

      {vertex_geometry_ptr := Get_vertex_geometry(vertex_ptr^.index);}
      vertex_geometry_ptr := vertex_ptr^.vertex_geometry_ptr;
      vertex_geometry_ptr^.u_axis := u_axis;
      vertex_geometry_ptr^.v_axis := v_axis;

      vertex_ptr := vertex_ptr^.next;
    end;

  {********************}
  { free edge geometry }
  {********************}
  edge_ptr := topology_ptr^.edge_ptr;
  while (edge_ptr <> nil) do
    begin
      Free_edge_geometry(edge_ptr^.edge_geometry_ptr);
      edge_ptr := edge_ptr^.next;
    end;

  {************************}
  { set mesh geometry flag }
  {************************}
  geometry_ptr^.geometry_info.vertex_vectors_avail := true;
end; {procedure Find_mesh_uv_vectors}


initialization
  vertex_index_block_free_list := nil;
  edge_index_block_free_list := nil;
  vertices := 0;
  edges := 0;
  coincidence_d_squared := coincidence_d * coincidence_d;
  mesh_topology_list := nil;
  mesh_topology_free_list := nil;
end.
