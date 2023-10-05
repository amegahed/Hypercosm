unit isoedges;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             isoedges                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module builds the edges of the polygonal data      }
{       structures for the volume objects.  These are then      }
{       used to construct the b rep.                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  polymeshes, isosurfaces, isovertices;


type
  {******************************************************}
  { This array is used to index the edges which are made }
  { on the capping faces of the volume. This array can   }
  { be visualized as 2 2D arrays, one 2D array for the   }
  { edges in each of the cardinal x and y directions.    }
  {******************************************************}
  edge_array_ptr_type = ^edge_array_type;
  edge_array_type = record
    length, width, height: integer;
    multiplier1, multiplier2, multiplier3: longint;
    edge_index_ptr: edge_index_ptr_type;
    next: edge_array_ptr_type;
  end; {edge_array_type}


  {*****************************************************}
  { These data structs used to find duplicate edges. An }
  { array is made which is big enough to have one entry }
  { for each vertex which is created. Each element is a }
  { pointer to a list of edge nodes, which contain the  }
  { other vertex and edge index. An edge node is made   }
  { for each edge which begins with the fist vertex.    }
  {*****************************************************}
  edge_node_ptr_type = ^edge_node_type;
  edge_node_type = record
    vertex: integer;
    edge: integer;
    next: edge_node_ptr_type;
  end; {edge_node_type}
  edge_node_array_ptr_type = ^edge_node_ptr_type;


function New_edge_array(length, width, height: integer): edge_array_ptr_type;
procedure Init_edge_array(edge_array_ptr: edge_array_ptr_type);
function Index_edge_array(edge_array_ptr: edge_array_ptr_type;
  length, width, height: integer): edge_index_ptr_type;
procedure Free_edge_array(var edge_array_ptr: edge_array_ptr_type);


{**********************************}
{ make xy edges and lattices edges }
{**********************************}
procedure Make_xy_edges(mesh_ptr: mesh_ptr_type;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type);
procedure Make_xy_lattice_edges(mesh_ptr: mesh_ptr_type;
  height: integer;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type;
  lattice_ptr: lattice_ptr_type);

{**********************************}
{ make yz edges and lattices edges }
{**********************************}
procedure Make_yz_edges(mesh_ptr: mesh_ptr_type;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type);
procedure Make_yz_lattice_edges(mesh_ptr: mesh_ptr_type;
  length: integer;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type;
  lattice_ptr: lattice_ptr_type);

{**********************************}
{ make xz edges and lattices edges }
{**********************************}
procedure Make_xz_edges(mesh_ptr: mesh_ptr_type;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type);
procedure Make_xz_lattice_edges(mesh_ptr: mesh_ptr_type;
  width: integer;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type;
  lattice_ptr: lattice_ptr_type);


{**************************************}
{ routines to write edge array structs }
{**************************************}
procedure Write_edge_array(edge_array_ptr: edge_array_ptr_type);


implementation
uses
  new_memory;


const
  {**********************************************}
  { If the isosurface shares vertices with the   }
  { capping faces, then surface will be smoothed }
  { at the junction.                             }
  {**********************************************}
  share_vertices = false;
  memory_alert = false;


var
  {************}
  { free lists }
  {************}
  edge_array_free_list: edge_array_ptr_type;


{******************************************}
{ routines to allocate and free edge array }
{******************************************}


function New_edge_array(length, width, height: integer): edge_array_ptr_type;
var
  edge_array_size: longint;
  edge_array_ptr: edge_array_ptr_type;
begin
  {*******************************}
  { get edge array from free list }
  {*******************************}
  if (edge_array_free_list <> nil) then
    begin
      edge_array_ptr := edge_array_free_list;
      edge_array_free_list := edge_array_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new edge array');
      new(edge_array_ptr);
    end;

  {***********************}
  { initialize edge array }
  {***********************}
  edge_array_ptr^.length := length;
  edge_array_ptr^.width := width;
  edge_array_ptr^.height := height;
  edge_array_ptr^.next := nil;

  {*********************}
  { compute multipliers }
  {*********************}
  with edge_array_ptr^ do
    begin
      multiplier1 := sizeof(vertex_index_type);
      multiplier2 := longint(length) * multiplier1;
      multiplier3 := longint(width) * multiplier2;
    end;

  {*********************}
  { allocate edge array }
  {*********************}
  edge_array_size := longint(length + 1) * longint(width + 1);
  edge_array_size := edge_array_size * longint(height + 1) *
    sizeof(edge_index_type);

  if memory_alert then
    writeln('allocating new edge array');
  edge_array_ptr^.edge_index_ptr :=
    edge_index_ptr_type(New_ptr(edge_array_size));

  New_edge_array := edge_array_ptr;
end; {function New_edge_array}


procedure Init_edge_array(edge_array_ptr: edge_array_ptr_type);
var
  index_ptr: edge_index_ptr_type;
  edge_array_size, counter: longint;
begin
  index_ptr := edge_array_ptr^.edge_index_ptr;
  with edge_array_ptr^ do
    edge_array_size := length * width * height;
  for counter := 1 to edge_array_size do
    begin
      index_ptr^ := 0;
      index_ptr := edge_index_ptr_type(longint(index_ptr) +
        edge_array_ptr^.multiplier1);
    end;
end; {procedure Init_edge_array}


function Index_edge_array(edge_array_ptr: edge_array_ptr_type;
  length, width, height: integer): edge_index_ptr_type;
var
  offset: longint;
begin
  offset := longint(length) * edge_array_ptr^.multiplier1;
  offset := offset + longint(width) * edge_array_ptr^.multiplier2;
  offset := offset + longint(height) * edge_array_ptr^.multiplier3;
  Index_edge_array := edge_index_ptr_type(longint(edge_array_ptr^.edge_index_ptr)
    + offset);
end; {function Index_edge_array}


procedure Free_edge_array(var edge_array_ptr: edge_array_ptr_type);
begin
  Free_ptr(ptr_type(edge_array_ptr^.edge_index_ptr));

  edge_array_ptr^.next := edge_array_free_list;
  edge_array_free_list := edge_array_ptr;
  edge_array_ptr := nil;
end; {procedure Free_edge_array}


{**********************************}
{ make xy edges and lattices edges }
{**********************************}


procedure Make_xy_edges(mesh_ptr: mesh_ptr_type;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type);
var
  x_counter, y_counter: integer;
  x_vertex_ptr, y_vertex_ptr: vertex_index_ptr_type;
  x_edge_ptr, y_edge_ptr: edge_index_ptr_type;
  vertex1, vertex2: integer;
  index_ptr: vertex_index_ptr_type;
  offset: longint;
begin
  {***********************}
  { make horizontal edges }
  {***********************}

  y_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  y_edge_ptr := edge_array_ptr^.edge_index_ptr;
  offset := vertex_array_ptr^.multiplier3;

  for y_counter := 1 to edge_array_ptr^.width do
    begin

      {*******************}
      { start next column }
      {*******************}
      x_vertex_ptr := y_vertex_ptr;
      x_edge_ptr := y_edge_ptr;

      for x_counter := 1 to (edge_array_ptr^.length - 1) do
        begin
          {**********************}
          { make horizontal edge }
          {**********************}
          vertex1 := x_vertex_ptr^;
          index_ptr := x_vertex_ptr;
          x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
            vertex_array_ptr^.multiplier1);
          vertex2 := x_vertex_ptr^;

          if (vertex1 <> 0) then
            begin
              if (vertex2 <> 0) then
                begin
                  {*********************************}
                  { both vertices are inside volume }
                  {*********************************}
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  x_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************************}
                  { vertex1 is inside volume, vertex2 is outside }
                  {**********************************************}
                  vertex2 := vertex_index_ptr_type(longint(index_ptr) +
                    offset)^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  x_edge_ptr^ := edge_counter;
                end;
            end
          else
            begin
              if (vertex2 <> 0) then
                begin
                  {**********************************************}
                  { vertex1 is outside volume, vertex2 is inside }
                  {**********************************************}
                  vertex1 := vertex_index_ptr_type(longint(index_ptr) +
                    offset)^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  x_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************}
                  { both vertices are outside volume }
                  {**********************************}
                  x_edge_ptr^ := 0;
                end;
            end;

          {*******************}
          { go to next column }
          {*******************}
          x_edge_ptr := edge_index_ptr_type(longint(x_edge_ptr) +
            edge_array_ptr^.multiplier1);
        end;

      {****************}
      { go to next row }
      {****************}
      y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
        vertex_array_ptr^.multiplier2);
      y_edge_ptr := edge_index_ptr_type(longint(y_edge_ptr) +
        edge_array_ptr^.multiplier2);
    end;

  {*********************}
  { make vertical edges }
  {*********************}

  x_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  x_edge_ptr := edge_array_ptr^.edge_index_ptr;
  x_edge_ptr := edge_index_ptr_type(longint(x_edge_ptr) +
    edge_array_ptr^.multiplier3);
  offset := vertex_array_ptr^.multiplier3 * 2;

  for x_counter := 1 to edge_array_ptr^.length do
    begin

      {*******************}
      { start next column }
      {*******************}
      y_vertex_ptr := x_vertex_ptr;
      y_edge_ptr := x_edge_ptr;

      for y_counter := 1 to (edge_array_ptr^.width - 1) do
        begin
          {**********************}
          { make horizontal edge }
          {**********************}
          vertex1 := y_vertex_ptr^;
          index_ptr := y_vertex_ptr;
          y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          vertex2 := y_vertex_ptr^;

          if (vertex1 <> 0) then
            begin
              if (vertex2 <> 0) then
                begin
                  {*********************************}
                  { both vertices are inside volume }
                  {*********************************}
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  y_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************************}
                  { vertex1 is inside volume, vertex2 is outside }
                  {**********************************************}
                  vertex2 := vertex_index_ptr_type(longint(index_ptr) +
                    offset)^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  y_edge_ptr^ := edge_counter;
                end;
            end
          else
            begin
              if (vertex2 <> 0) then
                begin
                  {**********************************************}
                  { vertex1 is outside volume, vertex2 is inside }
                  {**********************************************}
                  vertex1 := vertex_index_ptr_type(longint(index_ptr) +
                    offset)^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  y_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************}
                  { both vertices are outside volume }
                  {**********************************}
                  y_edge_ptr^ := 0;
                end;
            end;

          {*******************}
          { go to next column }
          {*******************}
          y_edge_ptr := edge_index_ptr_type(longint(y_edge_ptr) +
            edge_array_ptr^.multiplier2);
        end;

      {****************}
      { go to next row }
      {****************}
      x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
        vertex_array_ptr^.multiplier1);
      x_edge_ptr := edge_index_ptr_type(longint(x_edge_ptr) +
        edge_array_ptr^.multiplier1);
    end;
end; {procedure Make_xy_edges}


procedure Make_xy_lattice_edges(mesh_ptr: mesh_ptr_type;
  height: integer;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type;
  lattice_ptr: lattice_ptr_type);
var
  x_counter, y_counter: integer;
  x_vertex_ptr, y_vertex_ptr: vertex_index_ptr_type;
  x_edge_ptr, y_edge_ptr: edge_index_ptr_type;
  x_index_ptr, y_index_ptr: vertex_index_ptr_type;
  vertex1, vertex2: integer;
begin
  {***********************}
  { make horizontal edges }
  {***********************}

  y_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  y_edge_ptr := edge_array_ptr^.edge_index_ptr;
  y_index_ptr := lattice_ptr^.vertex_index_ptr;

  {********************************}
  { go to correct height and level }
  {********************************}
  y_index_ptr := vertex_index_ptr_type(longint(y_index_ptr) +
    (lattice_ptr^.multiplier3 * (height - 1)));

  for y_counter := 1 to edge_array_ptr^.width do
    begin

      {*******************}
      { start next column }
      {*******************}
      x_vertex_ptr := y_vertex_ptr;
      x_edge_ptr := y_edge_ptr;
      x_index_ptr := y_index_ptr;

      for x_counter := 1 to (edge_array_ptr^.length - 1) do
        begin
          {**********************}
          { make horizontal edge }
          {**********************}
          vertex1 := x_vertex_ptr^;
          x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
            vertex_array_ptr^.multiplier1);
          vertex2 := x_vertex_ptr^;

          if (vertex1 <> 0) then
            begin
              if (vertex2 <> 0) then
                begin
                  {*********************************}
                  { both vertices are inside volume }
                  {*********************************}
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  x_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************************}
                  { vertex1 is inside volume, vertex2 is outside }
                  {**********************************************}
                  vertex2 := x_index_ptr^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  x_edge_ptr^ := edge_counter;
                end;
            end
          else
            begin
              if (vertex2 <> 0) then
                begin
                  {**********************************************}
                  { vertex1 is outside volume, vertex2 is inside }
                  {**********************************************}
                  vertex1 := x_index_ptr^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  x_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************}
                  { both vertices are outside volume }
                  {**********************************}
                  x_edge_ptr^ := 0;
                end;
            end;

          {*******************}
          { go to next column }
          {*******************}
          x_edge_ptr := edge_index_ptr_type(longint(x_edge_ptr) +
            edge_array_ptr^.multiplier1);
          x_index_ptr := vertex_index_ptr_type(longint(x_index_ptr) +
            lattice_ptr^.multiplier1);
        end;

      {****************}
      { go to next row }
      {****************}
      y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
        vertex_array_ptr^.multiplier2);
      y_edge_ptr := edge_index_ptr_type(longint(y_edge_ptr) +
        edge_array_ptr^.multiplier2);
      y_index_ptr := vertex_index_ptr_type(longint(y_index_ptr) +
        lattice_ptr^.multiplier2);
    end;

  {*********************}
  { make vertical edges }
  {*********************}

  x_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  x_edge_ptr := edge_array_ptr^.edge_index_ptr;
  x_index_ptr := lattice_ptr^.vertex_index_ptr;
  x_edge_ptr := edge_index_ptr_type(longint(x_edge_ptr) +
    edge_array_ptr^.multiplier3);

  {********************************}
  { go to correct height and level }
  {********************************}
  x_index_ptr := vertex_index_ptr_type(longint(x_index_ptr) +
    (lattice_ptr^.multiplier3 * (height - 1)));
  x_index_ptr := vertex_index_ptr_type(longint(x_index_ptr) +
    lattice_ptr^.multiplier4);

  for x_counter := 1 to edge_array_ptr^.length do
    begin

      {*******************}
      { start next column }
      {*******************}
      y_vertex_ptr := x_vertex_ptr;
      y_edge_ptr := x_edge_ptr;
      y_index_ptr := x_index_ptr;

      for y_counter := 1 to (edge_array_ptr^.width - 1) do
        begin
          {**********************}
          { make horizontal edge }
          {**********************}
          vertex1 := y_vertex_ptr^;
          y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          vertex2 := y_vertex_ptr^;

          if (vertex1 <> 0) then
            begin
              if (vertex2 <> 0) then
                begin
                  {*********************************}
                  { both vertices are inside volume }
                  {*********************************}
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  y_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************************}
                  { vertex1 is inside volume, vertex2 is outside }
                  {**********************************************}
                  vertex2 := y_index_ptr^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  y_edge_ptr^ := edge_counter;
                end;
            end
          else
            begin
              if (vertex2 <> 0) then
                begin
                  {**********************************************}
                  { vertex1 is outside volume, vertex2 is inside }
                  {**********************************************}
                  vertex1 := y_index_ptr^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  y_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************}
                  { both vertices are outside volume }
                  {**********************************}
                  y_edge_ptr^ := 0;
                end;
            end;

          {*******************}
          { go to next column }
          {*******************}
          y_edge_ptr := edge_index_ptr_type(longint(y_edge_ptr) +
            edge_array_ptr^.multiplier2);
          y_index_ptr := vertex_index_ptr_type(longint(y_index_ptr) +
            lattice_ptr^.multiplier2);
        end;

      {****************}
      { go to next row }
      {****************}
      x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
        vertex_array_ptr^.multiplier1);
      x_edge_ptr := edge_index_ptr_type(longint(x_edge_ptr) +
        edge_array_ptr^.multiplier1);
      x_index_ptr := vertex_index_ptr_type(longint(x_index_ptr) +
        lattice_ptr^.multiplier1);
    end;
end; {procedure Make_xy_lattice_edges}


{**********************************}
{ make yz edges and lattices edges }
{**********************************}


procedure Make_yz_edges(mesh_ptr: mesh_ptr_type;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type);
var
  y_counter, z_counter: integer;
  y_vertex_ptr, z_vertex_ptr: vertex_index_ptr_type;
  y_edge_ptr, z_edge_ptr: edge_index_ptr_type;
  vertex1, vertex2: integer;
  index_ptr: vertex_index_ptr_type;
  offset: longint;
begin
  {***********************}
  { make horizontal edges }
  {***********************}

  z_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  z_edge_ptr := edge_array_ptr^.edge_index_ptr;
  offset := vertex_array_ptr^.multiplier3;

  for z_counter := 1 to edge_array_ptr^.width do
    begin

      {******************}
      { start next layer }
      {******************}
      y_vertex_ptr := z_vertex_ptr;
      y_edge_ptr := z_edge_ptr;

      for y_counter := 1 to (edge_array_ptr^.length - 1) do
        begin
          {**********************}
          { make horizontal edge }
          {**********************}
          vertex1 := y_vertex_ptr^;
          index_ptr := y_vertex_ptr;
          y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
            vertex_array_ptr^.multiplier1);
          vertex2 := y_vertex_ptr^;

          if (vertex1 <> 0) then
            begin
              if (vertex2 <> 0) then
                begin
                  {*********************************}
                  { both vertices are inside volume }
                  {*********************************}
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  y_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************************}
                  { vertex1 is inside volume, vertex2 is outside }
                  {**********************************************}
                  vertex2 := vertex_index_ptr_type(longint(index_ptr) +
                    offset)^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  y_edge_ptr^ := edge_counter;
                end;
            end
          else
            begin
              if (vertex2 <> 0) then
                begin
                  {**********************************************}
                  { vertex1 is outside volume, vertex2 is inside }
                  {**********************************************}
                  vertex1 := vertex_index_ptr_type(longint(index_ptr) +
                    offset)^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  y_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************}
                  { both vertices are outside volume }
                  {**********************************}
                  y_edge_ptr^ := 0;
                end;
            end;

          {*******************}
          { go to next column }
          {*******************}
          y_edge_ptr := edge_index_ptr_type(longint(y_edge_ptr) +
            edge_array_ptr^.multiplier1);
        end;

      {****************}
      { go to next row }
      {****************}
      z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
        vertex_array_ptr^.multiplier2);
      z_edge_ptr := edge_index_ptr_type(longint(z_edge_ptr) +
        edge_array_ptr^.multiplier2);
    end;

  {*********************}
  { make vertical edges }
  {*********************}

  y_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  y_edge_ptr := edge_array_ptr^.edge_index_ptr;
  y_edge_ptr := edge_index_ptr_type(longint(y_edge_ptr) +
    edge_array_ptr^.multiplier3);
  offset := vertex_array_ptr^.multiplier3 * 2;

  for y_counter := 1 to edge_array_ptr^.length do
    begin

      {*******************}
      { start next column }
      {*******************}
      z_vertex_ptr := y_vertex_ptr;
      z_edge_ptr := y_edge_ptr;

      for z_counter := 1 to (edge_array_ptr^.width - 1) do
        begin
          {**********************}
          { make horizontal edge }
          {**********************}
          vertex1 := z_vertex_ptr^;
          index_ptr := z_vertex_ptr;
          z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          vertex2 := z_vertex_ptr^;

          if (vertex1 <> 0) then
            begin
              if (vertex2 <> 0) then
                begin
                  {*********************************}
                  { both vertices are inside volume }
                  {*********************************}
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  z_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************************}
                  { vertex1 is inside volume, vertex2 is outside }
                  {**********************************************}
                  vertex2 := vertex_index_ptr_type(longint(index_ptr) +
                    offset)^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  z_edge_ptr^ := edge_counter;
                end;
            end
          else
            begin
              if (vertex2 <> 0) then
                begin
                  {**********************************************}
                  { vertex1 is outside volume, vertex2 is inside }
                  {**********************************************}
                  vertex1 := vertex_index_ptr_type(longint(index_ptr) +
                    offset)^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  z_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************}
                  { both vertices are outside volume }
                  {**********************************}
                  z_edge_ptr^ := 0;
                end;
            end;

          {******************}
          { go to next layer }
          {******************}
          z_edge_ptr := edge_index_ptr_type(longint(z_edge_ptr) +
            edge_array_ptr^.multiplier2);
        end;

      {****************}
      { go to next row }
      {****************}
      y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
        vertex_array_ptr^.multiplier1);
      y_edge_ptr := edge_index_ptr_type(longint(y_edge_ptr) +
        edge_array_ptr^.multiplier1);
    end;
end; {procedure Make_yz_edges}


procedure Make_yz_lattice_edges(mesh_ptr: mesh_ptr_type;
  length: integer;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type;
  lattice_ptr: lattice_ptr_type);
var
  y_counter, z_counter: integer;
  y_vertex_ptr, z_vertex_ptr: vertex_index_ptr_type;
  y_edge_ptr, z_edge_ptr: edge_index_ptr_type;
  y_index_ptr, z_index_ptr: vertex_index_ptr_type;
  vertex1, vertex2: integer;
begin
  {***********************}
  { make horizontal edges }
  {***********************}

  z_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  z_edge_ptr := edge_array_ptr^.edge_index_ptr;
  z_index_ptr := lattice_ptr^.vertex_index_ptr;

  {********************************}
  { go to correct length and level }
  {********************************}
  z_index_ptr := vertex_index_ptr_type(longint(z_index_ptr) +
    (lattice_ptr^.multiplier1 * (length - 1)));
  z_index_ptr := vertex_index_ptr_type(longint(z_index_ptr) +
    (lattice_ptr^.multiplier4));

  for z_counter := 1 to edge_array_ptr^.width do
    begin

      {******************}
      { start next layer }
      {******************}
      y_vertex_ptr := z_vertex_ptr;
      y_edge_ptr := z_edge_ptr;
      y_index_ptr := z_index_ptr;

      for y_counter := 1 to (edge_array_ptr^.length - 1) do
        begin
          {**********************}
          { make horizontal edge }
          {**********************}
          vertex1 := y_vertex_ptr^;
          y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
            vertex_array_ptr^.multiplier1);
          vertex2 := y_vertex_ptr^;

          if (vertex1 <> 0) then
            begin
              if (vertex2 <> 0) then
                begin
                  {*********************************}
                  { both vertices are inside volume }
                  {*********************************}
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  y_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************************}
                  { vertex1 is inside volume, vertex2 is outside }
                  {**********************************************}
                  vertex2 := y_index_ptr^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  y_edge_ptr^ := edge_counter;
                end;
            end
          else
            begin
              if (vertex2 <> 0) then
                begin
                  {**********************************************}
                  { vertex1 is outside volume, vertex2 is inside }
                  {**********************************************}
                  vertex1 := y_index_ptr^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  y_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************}
                  { both vertices are outside volume }
                  {**********************************}
                  y_edge_ptr^ := 0;
                end;
            end;

          {*******************}
          { go to next column }
          {*******************}
          y_edge_ptr := edge_index_ptr_type(longint(y_edge_ptr) +
            edge_array_ptr^.multiplier1);
          y_index_ptr := vertex_index_ptr_type(longint(y_index_ptr) +
            lattice_ptr^.multiplier2);
        end;

      {****************}
      { go to next row }
      {****************}
      z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
        vertex_array_ptr^.multiplier2);
      z_edge_ptr := edge_index_ptr_type(longint(z_edge_ptr) +
        edge_array_ptr^.multiplier2);
      z_index_ptr := vertex_index_ptr_type(longint(z_index_ptr) +
        lattice_ptr^.multiplier3);
    end;

  {*********************}
  { make vertical edges }
  {*********************}

  y_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  y_edge_ptr := edge_array_ptr^.edge_index_ptr;
  y_index_ptr := lattice_ptr^.vertex_index_ptr;
  y_edge_ptr := edge_index_ptr_type(longint(y_edge_ptr) +
    edge_array_ptr^.multiplier3);

  {********************************}
  { go to correct height and level }
  {********************************}
  y_index_ptr := vertex_index_ptr_type(longint(y_index_ptr) +
    (lattice_ptr^.multiplier1 * (length - 1)));
  y_index_ptr := vertex_index_ptr_type(longint(y_index_ptr) +
    (lattice_ptr^.multiplier4 * 2));

  for y_counter := 1 to edge_array_ptr^.length do
    begin

      {*******************}
      { start next column }
      {*******************}
      z_vertex_ptr := y_vertex_ptr;
      z_edge_ptr := y_edge_ptr;
      z_index_ptr := y_index_ptr;

      for z_counter := 1 to (edge_array_ptr^.width - 1) do
        begin
          {**********************}
          { make horizontal edge }
          {**********************}
          vertex1 := z_vertex_ptr^;
          z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          vertex2 := z_vertex_ptr^;

          if (vertex1 <> 0) then
            begin
              if (vertex2 <> 0) then
                begin
                  {*********************************}
                  { both vertices are inside volume }
                  {*********************************}
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  z_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************************}
                  { vertex1 is inside volume, vertex2 is outside }
                  {**********************************************}
                  vertex2 := z_index_ptr^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  z_edge_ptr^ := edge_counter;
                end;
            end
          else
            begin
              if (vertex2 <> 0) then
                begin
                  {**********************************************}
                  { vertex1 is outside volume, vertex2 is inside }
                  {**********************************************}
                  vertex1 := z_index_ptr^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  z_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************}
                  { both vertices are outside volume }
                  {**********************************}
                  z_edge_ptr^ := 0;
                end;
            end;

          {******************}
          { go to next layer }
          {******************}
          z_edge_ptr := edge_index_ptr_type(longint(z_edge_ptr) +
            edge_array_ptr^.multiplier2);
          z_index_ptr := vertex_index_ptr_type(longint(z_index_ptr) +
            lattice_ptr^.multiplier3);
        end;

      {****************}
      { go to next row }
      {****************}
      y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
        vertex_array_ptr^.multiplier1);
      y_edge_ptr := edge_index_ptr_type(longint(y_edge_ptr) +
        edge_array_ptr^.multiplier1);
      y_index_ptr := vertex_index_ptr_type(longint(y_index_ptr) +
        lattice_ptr^.multiplier2);
    end;
end; {procedure Make_yz_lattice_edges}


{**********************************}
{ make xz edges and lattices edges }
{**********************************}


procedure Make_xz_edges(mesh_ptr: mesh_ptr_type;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type);
var
  x_counter, z_counter: integer;
  x_vertex_ptr, z_vertex_ptr: vertex_index_ptr_type;
  x_edge_ptr, z_edge_ptr: edge_index_ptr_type;
  vertex1, vertex2: integer;
  index_ptr: vertex_index_ptr_type;
  offset: longint;
begin
  {***********************}
  { make horizontal edges }
  {***********************}

  z_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  z_edge_ptr := edge_array_ptr^.edge_index_ptr;
  offset := vertex_array_ptr^.multiplier3;

  for z_counter := 1 to edge_array_ptr^.width do
    begin

      {******************}
      { start next layer }
      {******************}
      x_vertex_ptr := z_vertex_ptr;
      x_edge_ptr := z_edge_ptr;

      for x_counter := 1 to (edge_array_ptr^.length - 1) do
        begin
          {**********************}
          { make horizontal edge }
          {**********************}
          vertex1 := x_vertex_ptr^;
          index_ptr := x_vertex_ptr;
          x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
            vertex_array_ptr^.multiplier1);
          vertex2 := x_vertex_ptr^;

          if (vertex1 <> 0) then
            begin
              if (vertex2 <> 0) then
                begin
                  {*********************************}
                  { both vertices are inside volume }
                  {*********************************}
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  x_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************************}
                  { vertex1 is inside volume, vertex2 is outside }
                  {**********************************************}
                  vertex2 := vertex_index_ptr_type(longint(index_ptr) +
                    offset)^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  x_edge_ptr^ := edge_counter;
                end;
            end
          else
            begin
              if (vertex2 <> 0) then
                begin
                  {**********************************************}
                  { vertex1 is outside volume, vertex2 is inside }
                  {**********************************************}
                  vertex1 := vertex_index_ptr_type(longint(index_ptr) +
                    offset)^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  x_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************}
                  { both vertices are outside volume }
                  {**********************************}
                  x_edge_ptr^ := 0;
                end;
            end;

          {*******************}
          { go to next column }
          {*******************}
          x_edge_ptr := edge_index_ptr_type(longint(x_edge_ptr) +
            edge_array_ptr^.multiplier1);
        end;

      {****************}
      { go to next row }
      {****************}
      z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
        vertex_array_ptr^.multiplier2);
      z_edge_ptr := edge_index_ptr_type(longint(z_edge_ptr) +
        edge_array_ptr^.multiplier2);
    end;

  {*********************}
  { make vertical edges }
  {*********************}

  x_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  x_edge_ptr := edge_array_ptr^.edge_index_ptr;
  x_edge_ptr := edge_index_ptr_type(longint(x_edge_ptr) +
    edge_array_ptr^.multiplier3);
  offset := edge_array_ptr^.multiplier3 * 2;

  for x_counter := 1 to edge_array_ptr^.length do
    begin

      {*******************}
      { start next column }
      {*******************}
      z_vertex_ptr := x_vertex_ptr;
      z_edge_ptr := x_edge_ptr;

      for z_counter := 1 to (edge_array_ptr^.width - 1) do
        begin
          {**********************}
          { make horizontal edge }
          {**********************}
          vertex1 := z_vertex_ptr^;
          index_ptr := z_vertex_ptr;
          z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          vertex2 := z_vertex_ptr^;

          if (vertex1 <> 0) then
            begin
              if (vertex2 <> 0) then
                begin
                  {*********************************}
                  { both vertices are inside volume }
                  {*********************************}
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  z_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************************}
                  { vertex1 is inside volume, vertex2 is outside }
                  {**********************************************}
                  vertex2 := vertex_index_ptr_type(longint(index_ptr) +
                    offset)^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  z_edge_ptr^ := edge_counter;
                end;
            end
          else
            begin
              if (vertex2 <> 0) then
                begin
                  {**********************************************}
                  { vertex1 is outside volume, vertex2 is inside }
                  {**********************************************}
                  vertex1 := vertex_index_ptr_type(longint(index_ptr) +
                    offset)^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  z_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************}
                  { both vertices are outside volume }
                  {**********************************}
                  z_edge_ptr^ := 0;
                end;
            end;

          {******************}
          { go to next layer }
          {******************}
          z_edge_ptr := edge_index_ptr_type(longint(z_edge_ptr) +
            edge_array_ptr^.multiplier2);
        end;

      {*******************}
      { go to next column }
      {*******************}
      x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
        vertex_array_ptr^.multiplier1);
      x_edge_ptr := edge_index_ptr_type(longint(x_edge_ptr) +
        edge_array_ptr^.multiplier1);
    end;
end; {procedure Make_xz_edges}


procedure Make_xz_lattice_edges(mesh_ptr: mesh_ptr_type;
  width: integer;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type;
  lattice_ptr: lattice_ptr_type);
var
  x_counter, z_counter: integer;
  x_vertex_ptr, z_vertex_ptr: vertex_index_ptr_type;
  x_edge_ptr, z_edge_ptr: edge_index_ptr_type;
  x_index_ptr, z_index_ptr: vertex_index_ptr_type;
  vertex1, vertex2: integer;
begin
  {***********************}
  { make horizontal edges }
  {***********************}

  z_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  z_edge_ptr := edge_array_ptr^.edge_index_ptr;
  z_index_ptr := lattice_ptr^.vertex_index_ptr;

  {********************************}
  { go to correct length and level }
  {********************************}
  z_index_ptr := vertex_index_ptr_type(longint(z_index_ptr) +
    (lattice_ptr^.multiplier2 * (width - 1)));

  for z_counter := 1 to edge_array_ptr^.width do
    begin

      {******************}
      { start next layer }
      {******************}
      x_vertex_ptr := z_vertex_ptr;
      x_edge_ptr := z_edge_ptr;
      x_index_ptr := z_index_ptr;

      for x_counter := 1 to (edge_array_ptr^.length - 1) do
        begin
          {**********************}
          { make horizontal edge }
          {**********************}
          vertex1 := x_vertex_ptr^;
          x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
            vertex_array_ptr^.multiplier1);
          vertex2 := x_vertex_ptr^;

          if (vertex1 <> 0) then
            begin
              if (vertex2 <> 0) then
                begin
                  {*********************************}
                  { both vertices are inside volume }
                  {*********************************}
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  x_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************************}
                  { vertex1 is inside volume, vertex2 is outside }
                  {**********************************************}
                  vertex2 := x_index_ptr^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  x_edge_ptr^ := edge_counter;
                end;
            end
          else
            begin
              if (vertex2 <> 0) then
                begin
                  {**********************************************}
                  { vertex1 is outside volume, vertex2 is inside }
                  {**********************************************}
                  vertex1 := x_index_ptr^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  x_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************}
                  { both vertices are outside volume }
                  {**********************************}
                  x_edge_ptr^ := 0;
                end;
            end;

          {*******************}
          { go to next column }
          {*******************}
          x_edge_ptr := edge_index_ptr_type(longint(x_edge_ptr) +
            edge_array_ptr^.multiplier1);
          x_index_ptr := vertex_index_ptr_type(longint(x_index_ptr) +
            lattice_ptr^.multiplier1);
        end;

      {****************}
      { go to next row }
      {****************}
      z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
        vertex_array_ptr^.multiplier2);
      z_edge_ptr := edge_index_ptr_type(longint(z_edge_ptr) +
        edge_array_ptr^.multiplier2);
      z_index_ptr := vertex_index_ptr_type(longint(z_index_ptr) +
        lattice_ptr^.multiplier3);
    end;

  {*********************}
  { make vertical edges }
  {*********************}

  x_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  x_edge_ptr := edge_array_ptr^.edge_index_ptr;
  x_index_ptr := lattice_ptr^.vertex_index_ptr;
  x_edge_ptr := edge_index_ptr_type(longint(x_edge_ptr) +
    edge_array_ptr^.multiplier3);

  {********************************}
  { go to correct height and level }
  {********************************}
  x_index_ptr := vertex_index_ptr_type(longint(x_index_ptr) +
    (lattice_ptr^.multiplier2 * (width - 1)));
  x_index_ptr := vertex_index_ptr_type(longint(x_index_ptr) +
    (lattice_ptr^.multiplier4 * 2));

  for x_counter := 1 to edge_array_ptr^.length do
    begin

      {*******************}
      { start next column }
      {*******************}
      z_vertex_ptr := x_vertex_ptr;
      z_edge_ptr := x_edge_ptr;
      z_index_ptr := x_index_ptr;

      for z_counter := 1 to (edge_array_ptr^.width - 1) do
        begin
          {**********************}
          { make horizontal edge }
          {**********************}
          vertex1 := z_vertex_ptr^;
          z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          vertex2 := z_vertex_ptr^;

          if (vertex1 <> 0) then
            begin
              if (vertex2 <> 0) then
                begin
                  {*********************************}
                  { both vertices are inside volume }
                  {*********************************}
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  z_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************************}
                  { vertex1 is inside volume, vertex2 is outside }
                  {**********************************************}
                  vertex2 := z_index_ptr^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  z_edge_ptr^ := edge_counter;
                end;
            end
          else
            begin
              if (vertex2 <> 0) then
                begin
                  {**********************************************}
                  { vertex1 is outside volume, vertex2 is inside }
                  {**********************************************}
                  vertex1 := z_index_ptr^;
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge(mesh_ptr, vertex1, vertex2);
                  z_edge_ptr^ := edge_counter;
                end
              else
                begin
                  {**********************************}
                  { both vertices are outside volume }
                  {**********************************}
                  z_edge_ptr^ := 0;
                end;
            end;

          {******************}
          { go to next layer }
          {******************}
          z_edge_ptr := edge_index_ptr_type(longint(z_edge_ptr) +
            edge_array_ptr^.multiplier2);
          z_index_ptr := vertex_index_ptr_type(longint(z_index_ptr) +
            lattice_ptr^.multiplier3);
        end;

      {*******************}
      { go to next column }
      {*******************}
      x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
        vertex_array_ptr^.multiplier1);
      x_edge_ptr := edge_index_ptr_type(longint(x_edge_ptr) +
        edge_array_ptr^.multiplier1);
      x_index_ptr := vertex_index_ptr_type(longint(x_index_ptr) +
        lattice_ptr^.multiplier1);
    end;
end; {procedure Make_xz_lattice_edges}


{**************************************}
{ routines to write edge array structs }
{**************************************}


procedure Write_edge_array(edge_array_ptr: edge_array_ptr_type);
var
  x_counter, y_counter: integer;
  x_edge_ptr, y_edge_ptr: edge_index_ptr_type;
begin
  with edge_array_ptr^ do
    writeln('edge array(', length: 1, ' x ', width: 1, '):');

  writeln('horizontal edges:');
  y_edge_ptr := edge_array_ptr^.edge_index_ptr;
  for y_counter := 1 to edge_array_ptr^.width do
    begin
      x_edge_ptr := y_edge_ptr;
      for x_counter := 1 to (edge_array_ptr^.length - 1) do
        begin
          writeln('edge(', x_counter: 1, ' ', y_counter: 1, ') = ',
            x_edge_ptr^);
          x_edge_ptr := edge_index_ptr_type(longint(x_edge_ptr) +
            edge_array_ptr^.multiplier1);
        end;
      y_edge_ptr := edge_index_ptr_type(longint(y_edge_ptr) +
        edge_array_ptr^.multiplier2);
    end;

  writeln('vertical edges:');
  x_edge_ptr := edge_array_ptr^.edge_index_ptr;
  for x_counter := 1 to edge_array_ptr^.length do
    begin
      y_edge_ptr := x_edge_ptr;
      for y_counter := 1 to (edge_array_ptr^.width - 1) do
        begin
          writeln('edge(', x_counter: 1, ' ', y_counter: 1, ') = ',
            x_edge_ptr^);
          y_edge_ptr := edge_index_ptr_type(longint(y_edge_ptr) +
            edge_array_ptr^.multiplier2);
        end;
      x_edge_ptr := edge_index_ptr_type(longint(x_edge_ptr) +
        edge_array_ptr^.multiplier1);
    end;
end; {procedure Write_edge_array}


initialization
  edge_array_free_list := nil;
end.
