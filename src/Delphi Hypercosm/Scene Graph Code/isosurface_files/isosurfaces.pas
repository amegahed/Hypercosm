unit isosurfaces;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             isosurfaces               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to aid in the             }
{       construction of isosurfaces through a volume.           }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  cubes, volumes, polymeshes;


type
  direction_type = boolean;


  {*****************************************}
  { dynamically allocated arrays of indices }
  { are used to index vertices and edges    }
  {*****************************************}
  vertex_index_ptr_type = ^vertex_index_type;
  vertex_index_type = integer;

  edge_index_ptr_type = ^edge_index_type;
  edge_index_type = integer;


  {*********************************************}
  { array of polarities tell if the density at  }
  { each vertex is above or below the threshold }
  {*********************************************}
  polarity_array_ptr_type = ^polarity_array_type;
  polarity_array_type = record
    length, width, height: integer;
    multiplier1, multiplier2, multiplier3: longint;
    polarity_ptr: polarity_ptr_type;
    next: polarity_array_ptr_type;
  end; {polarity_array_type}


  {*******************************************************}
  { The lattice is a 4D array used to index the vertices  }
  { created where the isosurface intersects the integer   }
  { grid planes. This array can be visualized as an array }
  { of 3 3D arrays, one 3D array for the edges in each of }
  { the cardinal x, y, and z directions.                  }
  {*******************************************************}
  lattice_ptr_type = ^lattice_type;
  lattice_type = record
    length, width, height, level: integer;
    multiplier1, multiplier2, multiplier3, multiplier4: longint;
    vertex_index_ptr: vertex_index_ptr_type;
    next: lattice_ptr_type;
  end; {lattice_type}


var
  vertex_counter: integer;
  edge_counter: integer;
  face_counter: integer;

  {**********************************}
  { offsets used to navigate lattice }
  {**********************************}
  lattice_offset: array[0..12] of longint;


{****************************************}
{ routines for creating polarity structs }
{****************************************}
function New_polarity_array(length, width, height: integer):
  polarity_array_ptr_type;
function Index_polarity_array(polarity_array_ptr: polarity_array_ptr_type;
  length, width, height: integer): polarity_ptr_type;
procedure Free_polarity_array(var polarity_array_ptr: polarity_array_ptr_type);
procedure Make_volume_polarity(volume_ptr: volume_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type);

{***************************************}
{ routines for creating lattice structs }
{***************************************}
function New_lattice(length, width, height, level: integer): lattice_ptr_type;
function Index_lattice(lattice_ptr: lattice_ptr_type;
  length, width, height, level: integer): vertex_index_ptr_type;
procedure Free_lattice(var lattice_ptr: lattice_ptr_type);
procedure Make_volume_vertices(volume_ptr: volume_ptr_type;
  mesh_ptr: mesh_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  lattice_ptr: lattice_ptr_type);
procedure Make_volume_faces(mesh_ptr: mesh_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  lattice_ptr: lattice_ptr_type);


implementation
uses
  new_memory, vectors;


{**************************************************************}
{    algorithm for finding an isosurface through a volume       }
{**************************************************************}
{       The volume is represented by a regular grid with        }
{       density values at each vertex.  Each cube in the        }
{       volume is a volume element, or voxel.                   }
{                                                               }
{       To find an isosurface through the volume, we find       }
{       where the isosurface intersects each edge in the        }
{       regular grid by linear interpolation. When we have      }
{       the edge intersections of each voxel, we connect        }
{       the new vertices that are formed together to create     }
{       partitioning surfaces through each voxel. Together,     }
{       these partitions will form the isosurface.              }
{                                                               }
{       In order to quickly create the isosurface topology,     }
{       we note that there are only 256 possible types of       }
{       voxels (inside or outside at each vertex = 2^8 = 256)   }
{       so there are only 256 different ways to partition       }
{       the voxel.                                              }
{**************************************************************}


const
  block_size = 256;
  memory_alert = false;


type
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
  edge_node_block_ptr_type = ^edge_node_block_type;
  edge_node_block_type = record
    edge_node_array: array[0..block_size] of edge_node_type;
    next: edge_node_block_ptr_type;
  end;


var
  {************}
  { free lists }
  {************}
  polarity_array_free_list: polarity_array_ptr_type;
  lattice_free_list: lattice_ptr_type;
  edge_node_free_list: edge_node_ptr_type;


  {************************************}
  { array used to find duplicate edges }
  {************************************}
  edge_node_array_ptr: edge_node_array_ptr_type;
  edge_node_block_ptr: edge_node_block_ptr_type;
  edge_node_block_list: edge_node_block_ptr_type;
  edge_node_counter: integer;


{***********************************************}
{ routines to allocate and free polarity arrays }
{***********************************************}


function New_polarity_array(length, width, height: integer):
  polarity_array_ptr_type;
var
  polarity_array_size: longint;
  polarity_array_ptr: polarity_array_ptr_type;
begin
  {***********************************}
  { get polarity_array from free list }
  {***********************************}
  if (polarity_array_free_list <> nil) then
    begin
      polarity_array_ptr := polarity_array_free_list;
      polarity_array_free_list := polarity_array_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new polarity array');
      new(polarity_array_ptr);
    end;

  {***************************}
  { initialize polarity array }
  {***************************}
  polarity_array_ptr^.length := length;
  polarity_array_ptr^.width := width;
  polarity_array_ptr^.height := height;
  polarity_array_ptr^.next := nil;

  {*********************}
  { compute multipliers }
  {*********************}
  with polarity_array_ptr^ do
    begin
      multiplier1 := sizeof(polarity_type);
      multiplier2 := longint(length) * multiplier1;
      multiplier3 := longint(width) * multiplier2;
    end;

  {*************************}
  { allocate polarity array }
  {*************************}
  polarity_array_size := longint(length + 1) * longint(width + 1) *
    longint(height + 1);
  polarity_array_size := polarity_array_size * sizeof(polarity_type);

  if memory_alert then
    writeln('allocating new polarity array');
  polarity_array_ptr^.polarity_ptr :=
    polarity_ptr_type(New_ptr(polarity_array_size));

  New_polarity_array := polarity_array_ptr;
end; {function New_polarity_array}


function Index_polarity_array(polarity_array_ptr: polarity_array_ptr_type;
  length, width, height: integer): polarity_ptr_type;
var
  offset: longint;
begin
  offset := longint(length) * polarity_array_ptr^.multiplier1;
  offset := offset + longint(width) * polarity_array_ptr^.multiplier2;
  offset := offset + longint(height) * polarity_array_ptr^.multiplier3;
  Index_polarity_array :=
    polarity_ptr_type(longint(polarity_array_ptr^.polarity_ptr) + offset);
end; {function Index_polarity_array}


procedure Free_polarity_array(var polarity_array_ptr: polarity_array_ptr_type);
begin
  Free_ptr(ptr_type(polarity_array_ptr^.polarity_ptr));

  polarity_array_ptr^.next := polarity_array_free_list;
  polarity_array_free_list := polarity_array_ptr;
  polarity_array_ptr := nil;
end; {procedure Free_polarity_array}


{****************************************}
{ routines to allocate and free lattices }
{****************************************}


procedure Init_edge_offsets(lattice_ptr: lattice_ptr_type);
var
  multiplier1, multiplier2, multiplier3, multiplier4: longint;
begin
  {************************************************}
  { this routines maps the edge indices to offsets }
  { to find the correct vertex in the lattice.     }
  {************************************************}

  {*************************************************}
  { initialize multipliers used to navigate lattice }
  {*************************************************}
  { multiplier1 = go to next edge in x direction    }
  { multiplier2 = go to next edge in y direction    }
  { multiplier3 = go to next edge in z direction    }
  { multiplier4 = go to next dimension of edge      }
  { ex. go to edges oriented in x direction to      }
  {     edges oriented in y direction etc.          }
  {*************************************************}
  multiplier1 := lattice_ptr^.multiplier1;
  multiplier2 := lattice_ptr^.multiplier2;
  multiplier3 := lattice_ptr^.multiplier3;
  multiplier4 := lattice_ptr^.multiplier4;

  {**************}
  { bottom edges }
  {**************}
  lattice_offset[1] := 0;
  lattice_offset[2] := multiplier1 + multiplier4;
  lattice_offset[3] := multiplier2;
  lattice_offset[4] := multiplier4;

  {***********}
  { top edges }
  {***********}
  lattice_offset[5] := lattice_offset[1] + multiplier3;
  lattice_offset[6] := lattice_offset[2] + multiplier3;
  lattice_offset[7] := lattice_offset[3] + multiplier3;
  lattice_offset[8] := lattice_offset[4] + multiplier3;

  {************}
  { side edges }
  {************}
  lattice_offset[9] := (multiplier4 * 2);
  lattice_offset[10] := (multiplier4 * 2) + multiplier1;
  lattice_offset[11] := (multiplier4 * 2) + multiplier1 + multiplier2;
  lattice_offset[12] := (multiplier4 * 2) + multiplier2;
end; {procedure Init_edge_offsets}


function New_lattice(length, width, height, level: integer): lattice_ptr_type;
var
  lattice_size: longint;
  lattice_ptr: lattice_ptr_type;
begin
  {****************************}
  { get lattice from free list }
  {****************************}
  if (lattice_free_list <> nil) then
    begin
      lattice_ptr := lattice_free_list;
      lattice_free_list := lattice_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new lattice');
      new(lattice_ptr);
    end;

  {********************}
  { initialize lattice }
  {********************}
  lattice_ptr^.length := length;
  lattice_ptr^.width := width;
  lattice_ptr^.height := height;
  lattice_ptr^.level := level;
  lattice_ptr^.next := nil;

  {*********************}
  { compute multipliers }
  {*********************}
  with lattice_ptr^ do
    begin
      multiplier1 := sizeof(vertex_index_type);
      multiplier2 := longint(length) * multiplier1;
      multiplier3 := longint(width) * multiplier2;
      multiplier4 := longint(height) * multiplier3;
    end;
  Init_edge_offsets(lattice_ptr);

  {******************}
  { allocate lattice }
  {******************}
  lattice_size := longint(length + 1) * longint(width + 1) * longint(height +
    1);
  lattice_size := lattice_size * longint(level + 1) * sizeof(vertex_index_type);

  if memory_alert then
    writeln('allocating new lattice');
  lattice_ptr^.vertex_index_ptr := vertex_index_ptr_type(New_ptr(lattice_size));

  New_lattice := lattice_ptr;
end; {function New_lattice}


function Index_lattice(lattice_ptr: lattice_ptr_type;
  length, width, height, level: integer): vertex_index_ptr_type;
var
  offset: longint;
begin
  offset := longint(length) * lattice_ptr^.multiplier1;
  offset := offset + longint(width) * lattice_ptr^.multiplier2;
  offset := offset + longint(height) * lattice_ptr^.multiplier3;
  offset := offset + longint(level) * lattice_ptr^.multiplier4;
  Index_lattice := vertex_index_ptr_type(longint(lattice_ptr^.vertex_index_ptr)
    + offset);
end; {function Index_lattice}


procedure Free_lattice(var lattice_ptr: lattice_ptr_type);
begin
  Free_ptr(ptr_type(lattice_ptr^.vertex_index_ptr));

  lattice_ptr^.next := lattice_free_list;
  lattice_free_list := lattice_ptr;
  lattice_ptr := nil;
end; {procedure Free_lattice}


{***********************************************}
{ routines to initialize duplicate edge structs }
{***********************************************}


function New_edge_node(vertex, edge: integer): edge_node_ptr_type;
var
  edge_node_ptr: edge_node_ptr_type;
begin
  if (edge_node_counter mod block_size) = 0 then
    begin
      if (edge_node_block_ptr = nil) then
        begin
          {****************************}
          { make first edge node block }
          {****************************}
          if memory_alert then
            writeln('allocating new edge node block');
          new(edge_node_block_list);
          edge_node_block_ptr := edge_node_block_list;
          edge_node_block_ptr^.next := nil;
        end
      else
        begin
          if (edge_node_block_ptr^.next = nil) then
            begin
              {**************************}
              { make new edge node block }
              {**************************}
              if memory_alert then
                writeln('allocating new edge node block');
              new(edge_node_block_ptr^.next);
              edge_node_block_ptr^.next^.next := nil;
            end;
          edge_node_block_ptr := edge_node_block_ptr^.next;
        end;
    end;

  edge_node_ptr := @edge_node_block_ptr^.edge_node_array[edge_node_counter mod
    block_size];
  edge_node_counter := edge_node_counter + 1;

  {**********************}
  { initialize edge node }
  {**********************}
  edge_node_ptr^.vertex := vertex;
  edge_node_ptr^.edge := edge;
  edge_node_ptr^.next := nil;

  New_edge_node := edge_node_ptr;
end; {function New_edge_node}


function New_edge_node2(vertex, edge: integer): edge_node_ptr_type;
var
  edge_node_ptr: edge_node_ptr_type;
begin
  {******************************}
  { get edge node from free list }
  {******************************}
  if (edge_node_free_list <> nil) then
    begin
      edge_node_ptr := edge_node_free_list;
      edge_node_free_list := edge_node_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new edge node');
      new(edge_node_ptr);
    end;

  {**********************}
  { initialize edge node }
  {**********************}
  edge_node_ptr^.vertex := vertex;
  edge_node_ptr^.edge := edge;
  edge_node_ptr^.next := nil;

  New_edge_node2 := edge_node_ptr;
end; {function New_edge_node}


procedure Free_edge_node(var edge_node_ptr: edge_node_ptr_type);
begin
  edge_node_ptr^.next := edge_node_free_list;
  edge_node_free_list := edge_node_ptr;
  edge_node_ptr := nil;
end; {procedure Free_edge_node}


function New_edge_node_array: edge_node_array_ptr_type;
var
  edge_node_array_size: longint;
  edge_node_array_ptr: edge_node_array_ptr_type;
  edge_node_addr: longint;
  counter: integer;
  size: integer;
begin
  size := vertex_counter;

  if (size <> 0) then
    begin
      {**************************}
      { allocate edge node array }
      {**************************}
      edge_node_array_size := (size + 1) * sizeof(edge_node_ptr_type);
      if memory_alert then
        writeln('allocating new edge node array');
      edge_node_array_ptr :=
        edge_node_array_ptr_type(New_ptr(edge_node_array_size));

      {****************************}
      { initialize edge node array }
      {****************************}
      edge_node_addr := longint(edge_node_array_ptr);
      for counter := 1 to (size + 1) do
        begin
          edge_node_array_ptr_type(edge_node_addr)^ := nil;
          edge_node_addr := edge_node_addr + sizeof(edge_node_ptr_type);
        end;
    end
  else
    begin
      edge_node_array_ptr := nil;
    end;

  New_edge_node_array := edge_node_array_ptr;
end; {function New_edge_node_array}


function Index_edge_node_array(edge_node_array_ptr: edge_node_array_ptr_type;
  index: integer): edge_node_array_ptr_type;
var
  edge_node_addr: longint;
begin
  edge_node_addr := longint(edge_node_array_ptr) + (index - 1) *
    sizeof(edge_node_ptr_type);
  Index_edge_node_array := edge_node_array_ptr_type(edge_node_addr);
end; {function Index_edge_node_array}


procedure Free_edge_node_array(var edge_node_array_ptr:
  edge_node_array_ptr_type);
var
  size: integer;
begin
  size := vertex_counter;

  if (size <> 0) then
    begin
      {********************************}
      { return edge nodes to free list }
      {********************************}
      edge_node_counter := 0;
      edge_node_block_ptr := edge_node_block_list;
    end;

  if (edge_node_array_ptr <> nil) then
    Free_ptr(ptr_type(edge_node_array_ptr));
end; {procedure Free_edge_node_array}


procedure Free_edge_node_array2(var edge_node_array_ptr:
  edge_node_array_ptr_type);
var
  counter: integer;
  edge_node_addr: longint;
  edge_node_ptr, last_edge_node_ptr: edge_node_ptr_type;
  size: integer;
begin
  size := vertex_counter;

  if (size <> 0) then
    begin
      {********************************}
      { return edge nodes to free list }
      {********************************}
      edge_node_addr := longint(edge_node_array_ptr);
      for counter := 1 to vertex_counter do
        begin
          edge_node_ptr := edge_node_array_ptr_type(edge_node_addr)^;
          edge_node_addr := edge_node_addr + sizeof(edge_node_ptr_type);

          if (edge_node_ptr <> nil) then
            begin
              last_edge_node_ptr := edge_node_ptr;
              while (last_edge_node_ptr^.next <> nil) do
                last_edge_node_ptr := last_edge_node_ptr^.next;

              last_edge_node_ptr^.next := edge_node_free_list;
              edge_node_free_list := edge_node_ptr;
            end;
        end;
    end;

  if (edge_node_array_ptr <> nil) then
    Free_ptr(ptr_type(edge_node_array_ptr));
end; {procedure Free_edge_node_array}


{************************************}
{ routines to convert volume to mesh }
{************************************}


procedure Make_volume_polarity(volume_ptr: volume_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type);
var
  x_counter, y_counter, z_counter: integer;
  x_density_ptr, y_density_ptr, z_density_ptr: density_ptr_type;
  x_polarity_ptr, y_polarity_ptr, z_polarity_ptr: polarity_ptr_type;
  length, width, height: integer;
  density_array_ptr: density_array_ptr_type;
begin
  density_array_ptr := volume_ptr^.density_array_ptr;
  length := density_array_ptr^.length;
  width := density_array_ptr^.width;
  height := density_array_ptr^.height;

  {****************************************************}
  { visit each vertex and compare density to threshold }
  {****************************************************}
  z_density_ptr := density_array_ptr^.density_ptr;
  z_polarity_ptr := polarity_array_ptr^.polarity_ptr;

  for z_counter := 1 to height do
    begin

      {******************}
      { start next layer }
      {******************}
      y_density_ptr := z_density_ptr;
      y_polarity_ptr := z_polarity_ptr;

      for y_counter := 1 to width do
        begin

          {****************}
          { start next row }
          {****************}
          x_density_ptr := y_density_ptr;
          x_polarity_ptr := y_polarity_ptr;

          for x_counter := 1 to length do
            begin
              {**********************}
              { compare to threshold }
              {**********************}
              if x_density_ptr^ < volume_ptr^.threshold then
                x_polarity_ptr^ := below
              else
                x_polarity_ptr^ := above;

              {*******************}
              { go to next column }
              {*******************}
              x_density_ptr := density_ptr_type(longint(x_density_ptr) +
                density_array_ptr^.multiplier1);
              x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
                polarity_array_ptr^.multiplier1);
            end;

          {****************}
          { go to next row }
          {****************}
          y_density_ptr := density_ptr_type(longint(y_density_ptr) +
            density_array_ptr^.multiplier2);
          y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
            polarity_array_ptr^.multiplier2);
        end;

      {******************}
      { go to next layer }
      {******************}
      z_density_ptr := density_ptr_type(longint(z_density_ptr) +
        density_array_ptr^.multiplier3);
      z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
        polarity_array_ptr^.multiplier3);
    end;
end; {procedure Make_volume_polarity}


procedure Make_volume_vertices(volume_ptr: volume_ptr_type;
  mesh_ptr: mesh_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  lattice_ptr: lattice_ptr_type);
var
  x_counter, y_counter, z_counter: integer;
  x_polarity_ptr, y_polarity_ptr, z_polarity_ptr: polarity_ptr_type;
  x_density_ptr, y_density_ptr, z_density_ptr: density_ptr_type;
  x_index_ptr, y_index_ptr, z_index_ptr: vertex_index_ptr_type;
  x_point_ptr, y_point_ptr, z_point_ptr: vector_ptr_type;

  polarity_ptr1, polarity_ptr2: polarity_ptr_type;
  density_ptr1, density_ptr2: density_ptr_type;
  density1, density2, factor: real;
  point_ptr1, point_ptr2: vector_ptr_type;

  vector, start, increment: vector_type;
  length, width, height: integer;
  density_array_ptr: density_array_ptr_type;
  point_array_ptr: point_array_ptr_type;
begin
  {*************************************************************}
  { vertices are formed along voxel edges wherever a transition }
  { in the volume density occurs where the density changes from }
  { below the threshold value to above the threshold value or   }
  { vice versa. The location of the new vertex is determined by }
  { linear interpolation.                                       }
  {*************************************************************}
  density_array_ptr := volume_ptr^.density_array_ptr;
  point_array_ptr := volume_ptr^.point_array_ptr;

  length := density_array_ptr^.length;
  width := density_array_ptr^.width;
  height := density_array_ptr^.height;

  increment.x := 0;
  increment.y := 0;
  increment.z := 0;

  if (length > 1) then
    increment.x := 2 / (length - 1);
  if (width > 1) then
    increment.y := 2 / (width - 1);
  if (height > 1) then
    increment.z := 2 / (height - 1);
  vertex_counter := 0;

  if (length <> 1) then
    start.x := -1
  else
    start.x := 0;

  if (width <> 1) then
    start.y := -1
  else
    start.y := 0;

  if (height <> 1) then
    start.z := -1
  else
    start.z := 0;

  if (point_array_ptr = nil) then
    begin
      {*****************************************}
      { create vertices for volume of unit cube }
      {*****************************************}

      {********************************************}
      { create vertices along edges in x direction }
      {********************************************}
      if (length <> 1) then
        begin
          z_polarity_ptr := polarity_array_ptr^.polarity_ptr;
          z_density_ptr := density_array_ptr^.density_ptr;
          z_index_ptr := lattice_ptr^.vertex_index_ptr;
          vector.z := start.z;

          for z_counter := 1 to height do
            begin

              {******************}
              { start next layer }
              {******************}
              y_polarity_ptr := z_polarity_ptr;
              y_density_ptr := z_density_ptr;
              y_index_ptr := z_index_ptr;
              vector.y := start.y;

              for y_counter := 1 to width do
                begin

                  {****************}
                  { start next row }
                  {****************}
                  x_polarity_ptr := y_polarity_ptr;
                  x_density_ptr := y_density_ptr;
                  x_index_ptr := y_index_ptr;

                  for x_counter := 0 to (length - 2) do
                    begin

                      {*******************}
                      { go to next column }
                      {*******************}
                      polarity_ptr1 := x_polarity_ptr;
                      density_ptr1 := x_density_ptr;

                      x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr)
                        + polarity_array_ptr^.multiplier1);
                      x_density_ptr := density_ptr_type(longint(x_density_ptr) +
                        density_array_ptr^.multiplier1);

                      polarity_ptr2 := x_polarity_ptr;
                      density_ptr2 := x_density_ptr;

                      if (polarity_ptr1^ <> polarity_ptr2^) then
                        begin
                          {********************}
                          { compute new vertex }
                          {********************}
                          density1 := density_ptr1^;
                          density2 := density_ptr2^;
                          factor := (volume_ptr^.threshold - density1) /
                            (density2 - density1);
                          vector.x := (x_counter + factor) * increment.x - 1;
                          Add_mesh_vertex(mesh_ptr, vector, zero_vector,
                            vector);
                          vertex_counter := vertex_counter + 1;
                          x_index_ptr^ := vertex_counter;
                        end
                      else
                        begin
                          {***********************}
                          { no new vertex created }
                          {***********************}
                          x_index_ptr^ := 0;
                        end;

                      x_index_ptr := vertex_index_ptr_type(longint(x_index_ptr)
                        + lattice_ptr^.multiplier1);
                    end;

                  {****************}
                  { go to next row }
                  {****************}
                  y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
                    polarity_array_ptr^.multiplier2);
                  y_density_ptr := density_ptr_type(longint(y_density_ptr) +
                    density_array_ptr^.multiplier2);
                  y_index_ptr := vertex_index_ptr_type(longint(y_index_ptr) +
                    lattice_ptr^.multiplier2);
                  vector.y := vector.y + increment.y;
                end;

              {******************}
              { go to next layer }
              {******************}
              z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
                polarity_array_ptr^.multiplier3);
              z_density_ptr := density_ptr_type(longint(z_density_ptr) +
                density_array_ptr^.multiplier3);
              z_index_ptr := vertex_index_ptr_type(longint(z_index_ptr) +
                lattice_ptr^.multiplier3);
              vector.z := vector.z + increment.z;
            end;
        end;

      {********************************************}
      { create vertices along edges in y direction }
      {********************************************}
      if (width <> 1) then
        begin
          z_polarity_ptr := polarity_array_ptr^.polarity_ptr;
          z_density_ptr := density_array_ptr^.density_ptr;
          z_index_ptr := lattice_ptr^.vertex_index_ptr;
          z_index_ptr := vertex_index_ptr_type(longint(z_index_ptr) +
            lattice_ptr^.multiplier4);
          vector.z := start.z;

          for z_counter := 1 to height do
            begin

              {******************}
              { start next layer }
              {******************}
              x_polarity_ptr := z_polarity_ptr;
              x_density_ptr := z_density_ptr;
              x_index_ptr := z_index_ptr;
              vector.x := start.x;

              for x_counter := 1 to length do
                begin

                  {*******************}
                  { start next column }
                  {*******************}
                  y_polarity_ptr := x_polarity_ptr;
                  y_density_ptr := x_density_ptr;
                  y_index_ptr := x_index_ptr;

                  for y_counter := 0 to (width - 2) do
                    begin

                      {****************}
                      { go to next row }
                      {****************}
                      polarity_ptr1 := y_polarity_ptr;
                      density_ptr1 := y_density_ptr;

                      y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr)
                        + polarity_array_ptr^.multiplier2);
                      y_density_ptr := density_ptr_type(longint(y_density_ptr) +
                        density_array_ptr^.multiplier2);

                      polarity_ptr2 := y_polarity_ptr;
                      density_ptr2 := y_density_ptr;

                      if (polarity_ptr1^ <> polarity_ptr2^) then
                        begin
                          {********************}
                          { compute new vertex }
                          {********************}
                          density1 := density_ptr1^;
                          density2 := density_ptr2^;
                          factor := (volume_ptr^.threshold - density1) /
                            (density2 - density1);
                          vector.y := (y_counter + factor) * increment.y - 1;
                          Add_mesh_vertex(mesh_ptr, vector, zero_vector,
                            vector);
                          vertex_counter := vertex_counter + 1;
                          y_index_ptr^ := vertex_counter;
                        end
                      else
                        begin
                          {***********************}
                          { no new vertex created }
                          {***********************}
                          y_index_ptr^ := 0;
                        end;

                      y_index_ptr := vertex_index_ptr_type(longint(y_index_ptr)
                        + lattice_ptr^.multiplier2);
                    end;

                  {*******************}
                  { go to next column }
                  {*******************}
                  x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
                    polarity_array_ptr^.multiplier1);
                  x_density_ptr := density_ptr_type(longint(x_density_ptr) +
                    density_array_ptr^.multiplier1);
                  x_index_ptr := vertex_index_ptr_type(longint(x_index_ptr) +
                    lattice_ptr^.multiplier1);
                  vector.x := vector.x + increment.x;
                end;

              {******************}
              { go to next layer }
              {******************}
              z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
                polarity_array_ptr^.multiplier3);
              z_density_ptr := density_ptr_type(longint(z_density_ptr) +
                density_array_ptr^.multiplier3);
              z_index_ptr := vertex_index_ptr_type(longint(z_index_ptr) +
                lattice_ptr^.multiplier3);
              vector.z := vector.z + increment.z;
            end;
        end;

      {********************************************}
      { create vertices along edges in z direction }
      {********************************************}
      if (height <> 1) then
        begin
          y_polarity_ptr := polarity_array_ptr^.polarity_ptr;
          y_density_ptr := density_array_ptr^.density_ptr;
          y_index_ptr := lattice_ptr^.vertex_index_ptr;
          y_index_ptr := vertex_index_ptr_type(longint(y_index_ptr) +
            lattice_ptr^.multiplier4 * 2);
          vector.y := start.y;

          for y_counter := 1 to width do
            begin

              {****************}
              { start next row }
              {****************}
              x_polarity_ptr := y_polarity_ptr;
              x_density_ptr := y_density_ptr;
              x_index_ptr := y_index_ptr;
              vector.x := start.x;

              for x_counter := 1 to length do
                begin

                  {*******************}
                  { start next column }
                  {*******************}
                  z_polarity_ptr := x_polarity_ptr;
                  z_density_ptr := x_density_ptr;
                  z_index_ptr := x_index_ptr;

                  for z_counter := 0 to (height - 2) do
                    begin

                      {******************}
                      { go to next layer }
                      {******************}
                      density_ptr1 := z_density_ptr;
                      polarity_ptr1 := z_polarity_ptr;

                      z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr)
                        + polarity_array_ptr^.multiplier3);
                      z_density_ptr := density_ptr_type(longint(z_density_ptr) +
                        density_array_ptr^.multiplier3);

                      density_ptr2 := z_density_ptr;
                      polarity_ptr2 := z_polarity_ptr;

                      if (polarity_ptr1^ <> polarity_ptr2^) then
                        begin
                          {********************}
                          { compute new vertex }
                          {********************}
                          density1 := density_ptr1^;
                          density2 := density_ptr2^;
                          factor := (volume_ptr^.threshold - density1) /
                            (density2 - density1);
                          vector.z := (z_counter + factor) * increment.z - 1;
                          Add_mesh_vertex(mesh_ptr, vector, zero_vector,
                            vector);
                          vertex_counter := vertex_counter + 1;
                          z_index_ptr^ := vertex_counter;
                        end
                      else
                        begin
                          {***********************}
                          { no new vertex created }
                          {***********************}
                          z_index_ptr^ := 0;
                        end;

                      z_index_ptr := vertex_index_ptr_type(longint(z_index_ptr)
                        + lattice_ptr^.multiplier3);
                    end;

                  {*******************}
                  { go to next column }
                  {*******************}
                  x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
                    polarity_array_ptr^.multiplier1);
                  x_density_ptr := density_ptr_type(longint(x_density_ptr) +
                    density_array_ptr^.multiplier1);
                  x_index_ptr := vertex_index_ptr_type(longint(x_index_ptr) +
                    lattice_ptr^.multiplier1);
                  vector.x := vector.x + increment.x;
                end;

              {****************}
              { go to next row }
              {****************}
              y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
                polarity_array_ptr^.multiplier2);
              y_density_ptr := density_ptr_type(longint(y_density_ptr) +
                density_array_ptr^.multiplier2);
              y_index_ptr := vertex_index_ptr_type(longint(y_index_ptr) +
                lattice_ptr^.multiplier2);
              vector.y := vector.y + increment.y;
            end;
        end;
    end

  else
    begin
      {*****************************************}
      { create vertices for user defined volume }
      {*****************************************}

      {********************************************}
      { create vertices along edges in x direction }
      {********************************************}
      if (length <> 1) then
        begin
          z_polarity_ptr := polarity_array_ptr^.polarity_ptr;
          z_density_ptr := density_array_ptr^.density_ptr;
          z_index_ptr := lattice_ptr^.vertex_index_ptr;
          z_point_ptr := point_array_ptr^.point_ptr;

          for z_counter := 1 to height do
            begin

              {******************}
              { start next layer }
              {******************}
              y_polarity_ptr := z_polarity_ptr;
              y_density_ptr := z_density_ptr;
              y_index_ptr := z_index_ptr;
              y_point_ptr := z_point_ptr;

              for y_counter := 1 to width do
                begin

                  {****************}
                  { start next row }
                  {****************}
                  x_polarity_ptr := y_polarity_ptr;
                  x_density_ptr := y_density_ptr;
                  x_index_ptr := y_index_ptr;
                  x_point_ptr := y_point_ptr;

                  for x_counter := 0 to (length - 2) do
                    begin

                      {*******************}
                      { go to next column }
                      {*******************}
                      polarity_ptr1 := x_polarity_ptr;
                      density_ptr1 := x_density_ptr;
                      point_ptr1 := x_point_ptr;

                      x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr)
                        + polarity_array_ptr^.multiplier1);
                      x_density_ptr := density_ptr_type(longint(x_density_ptr) +
                        density_array_ptr^.multiplier1);
                      x_point_ptr := vector_ptr_type(longint(x_point_ptr) +
                        point_array_ptr^.multiplier1);

                      polarity_ptr2 := x_polarity_ptr;
                      density_ptr2 := x_density_ptr;
                      point_ptr2 := x_point_ptr;

                      if (polarity_ptr1^ <> polarity_ptr2^) then
                        begin
                          {********************}
                          { compute new vertex }
                          {********************}
                          density1 := density_ptr1^;
                          density2 := density_ptr2^;
                          factor := (volume_ptr^.threshold - density1) /
                            (density2 - density1);
                          vector := Vector_sum(Vector_scale(point_ptr1^, 1 -
                            factor),
                            Vector_scale(point_ptr2^, factor));
                          Add_mesh_vertex(mesh_ptr, vector, zero_vector,
                            vector);
                          vertex_counter := vertex_counter + 1;
                          x_index_ptr^ := vertex_counter;
                        end
                      else
                        begin
                          {***********************}
                          { no new vertex created }
                          {***********************}
                          x_index_ptr^ := 0;
                        end;

                      x_index_ptr := vertex_index_ptr_type(longint(x_index_ptr)
                        + lattice_ptr^.multiplier1);
                    end;

                  {****************}
                  { go to next row }
                  {****************}
                  y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
                    polarity_array_ptr^.multiplier2);
                  y_density_ptr := density_ptr_type(longint(y_density_ptr) +
                    density_array_ptr^.multiplier2);
                  y_index_ptr := vertex_index_ptr_type(longint(y_index_ptr) +
                    lattice_ptr^.multiplier2);
                  y_point_ptr := vector_ptr_type(longint(y_point_ptr) +
                    point_array_ptr^.multiplier2);
                end;

              {******************}
              { go to next layer }
              {******************}
              z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
                polarity_array_ptr^.multiplier3);
              z_density_ptr := density_ptr_type(longint(z_density_ptr) +
                density_array_ptr^.multiplier3);
              z_index_ptr := vertex_index_ptr_type(longint(z_index_ptr) +
                lattice_ptr^.multiplier3);
              z_point_ptr := vector_ptr_type(longint(z_point_ptr) +
                point_array_ptr^.multiplier3);
            end;
        end;

      {********************************************}
      { create vertices along edges in y direction }
      {********************************************}
      if (width <> 1) then
        begin
          z_polarity_ptr := polarity_array_ptr^.polarity_ptr;
          z_density_ptr := density_array_ptr^.density_ptr;
          z_index_ptr := lattice_ptr^.vertex_index_ptr;
          z_index_ptr := vertex_index_ptr_type(longint(z_index_ptr) +
            lattice_ptr^.multiplier4);
          z_point_ptr := point_array_ptr^.point_ptr;

          for z_counter := 1 to height do
            begin

              {******************}
              { start next layer }
              {******************}
              x_polarity_ptr := z_polarity_ptr;
              x_density_ptr := z_density_ptr;
              x_index_ptr := z_index_ptr;
              x_point_ptr := z_point_ptr;

              for x_counter := 1 to length do
                begin

                  {*******************}
                  { start next column }
                  {*******************}
                  y_polarity_ptr := x_polarity_ptr;
                  y_density_ptr := x_density_ptr;
                  y_index_ptr := x_index_ptr;
                  y_point_ptr := x_point_ptr;

                  for y_counter := 0 to (width - 2) do
                    begin

                      {****************}
                      { go to next row }
                      {****************}
                      polarity_ptr1 := y_polarity_ptr;
                      density_ptr1 := y_density_ptr;
                      point_ptr1 := y_point_ptr;

                      y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr)
                        + polarity_array_ptr^.multiplier2);
                      y_density_ptr := density_ptr_type(longint(y_density_ptr) +
                        density_array_ptr^.multiplier2);
                      y_point_ptr := vector_ptr_type(longint(y_point_ptr) +
                        point_array_ptr^.multiplier2);

                      polarity_ptr2 := y_polarity_ptr;
                      density_ptr2 := y_density_ptr;
                      point_ptr2 := y_point_ptr;

                      if (polarity_ptr1^ <> polarity_ptr2^) then
                        begin
                          {********************}
                          { compute new vertex }
                          {********************}
                          density1 := density_ptr1^;
                          density2 := density_ptr2^;
                          factor := (volume_ptr^.threshold - density1) /
                            (density2 - density1);
                          vector := Vector_sum(Vector_scale(point_ptr1^, 1 -
                            factor),
                            Vector_scale(point_ptr2^, factor));
                          Add_mesh_vertex(mesh_ptr, vector, zero_vector,
                            vector);
                          vertex_counter := vertex_counter + 1;
                          y_index_ptr^ := vertex_counter;
                        end
                      else
                        begin
                          {***********************}
                          { no new vertex created }
                          {***********************}
                          y_index_ptr^ := 0;
                        end;

                      y_index_ptr := vertex_index_ptr_type(longint(y_index_ptr)
                        + lattice_ptr^.multiplier2);
                    end;

                  {*******************}
                  { go to next column }
                  {*******************}
                  x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
                    polarity_array_ptr^.multiplier1);
                  x_density_ptr := density_ptr_type(longint(x_density_ptr) +
                    density_array_ptr^.multiplier1);
                  x_index_ptr := vertex_index_ptr_type(longint(x_index_ptr) +
                    lattice_ptr^.multiplier1);
                  x_point_ptr := vector_ptr_type(longint(x_point_ptr) +
                    point_array_ptr^.multiplier1);
                end;

              {******************}
              { go to next layer }
              {******************}
              z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
                polarity_array_ptr^.multiplier3);
              z_density_ptr := density_ptr_type(longint(z_density_ptr) +
                density_array_ptr^.multiplier3);
              z_index_ptr := vertex_index_ptr_type(longint(z_index_ptr) +
                lattice_ptr^.multiplier3);
              z_point_ptr := vector_ptr_type(longint(z_point_ptr) +
                point_array_ptr^.multiplier3);
            end;
        end;

      {********************************************}
      { create vertices along edges in z direction }
      {********************************************}
      if (height <> 1) then
        begin
          y_polarity_ptr := polarity_array_ptr^.polarity_ptr;
          y_density_ptr := density_array_ptr^.density_ptr;
          y_index_ptr := lattice_ptr^.vertex_index_ptr;
          y_index_ptr := vertex_index_ptr_type(longint(y_index_ptr) +
            lattice_ptr^.multiplier4 * 2);
          y_point_ptr := point_array_ptr^.point_ptr;

          for y_counter := 1 to width do
            begin

              {****************}
              { start next row }
              {****************}
              x_polarity_ptr := y_polarity_ptr;
              x_density_ptr := y_density_ptr;
              x_index_ptr := y_index_ptr;
              x_point_ptr := y_point_ptr;

              for x_counter := 1 to length do
                begin

                  {*******************}
                  { start next column }
                  {*******************}
                  z_polarity_ptr := x_polarity_ptr;
                  z_density_ptr := x_density_ptr;
                  z_index_ptr := x_index_ptr;
                  z_point_ptr := x_point_ptr;

                  for z_counter := 0 to (height - 2) do
                    begin

                      {******************}
                      { go to next layer }
                      {******************}
                      density_ptr1 := z_density_ptr;
                      polarity_ptr1 := z_polarity_ptr;
                      point_ptr1 := z_point_ptr;

                      z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr)
                        + polarity_array_ptr^.multiplier3);
                      z_density_ptr := density_ptr_type(longint(z_density_ptr) +
                        density_array_ptr^.multiplier3);
                      z_point_ptr := vector_ptr_type(longint(z_point_ptr) +
                        point_array_ptr^.multiplier3);

                      density_ptr2 := z_density_ptr;
                      polarity_ptr2 := z_polarity_ptr;
                      point_ptr2 := z_point_ptr;

                      if (polarity_ptr1^ <> polarity_ptr2^) then
                        begin
                          {********************}
                          { compute new vertex }
                          {********************}
                          density1 := density_ptr1^;
                          density2 := density_ptr2^;
                          factor := (volume_ptr^.threshold - density1) /
                            (density2 - density1);
                          vector := Vector_sum(Vector_scale(point_ptr1^, 1 -
                            factor),
                            Vector_scale(point_ptr2^, factor));
                          Add_mesh_vertex(mesh_ptr, vector, zero_vector,
                            vector);
                          vertex_counter := vertex_counter + 1;
                          z_index_ptr^ := vertex_counter;
                        end
                      else
                        begin
                          {***********************}
                          { no new vertex created }
                          {***********************}
                          z_index_ptr^ := 0;
                        end;

                      z_index_ptr := vertex_index_ptr_type(longint(z_index_ptr)
                        + lattice_ptr^.multiplier3);
                    end;

                  {*******************}
                  { go to next column }
                  {*******************}
                  x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
                    polarity_array_ptr^.multiplier1);
                  x_density_ptr := density_ptr_type(longint(x_density_ptr) +
                    density_array_ptr^.multiplier1);
                  x_index_ptr := vertex_index_ptr_type(longint(x_index_ptr) +
                    lattice_ptr^.multiplier1);
                  x_point_ptr := vector_ptr_type(longint(x_point_ptr) +
                    point_array_ptr^.multiplier1);
                end;

              {****************}
              { go to next row }
              {****************}
              y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
                polarity_array_ptr^.multiplier2);
              y_density_ptr := density_ptr_type(longint(y_density_ptr) +
                density_array_ptr^.multiplier2);
              y_index_ptr := vertex_index_ptr_type(longint(y_index_ptr) +
                lattice_ptr^.multiplier2);
              y_point_ptr := vector_ptr_type(longint(y_point_ptr) +
                point_array_ptr^.multiplier2);
            end;
        end;

    end;
end; {procedure Make_volume_vertices}


procedure Write_lattice_vertices(vertex_index_ptr: vertex_index_ptr_type);
var
  counter: integer;
  vertex_index: integer;
begin
  for counter := 1 to 12 do
    begin
      vertex_index := vertex_index_ptr_type(longint(vertex_index_ptr) +
        lattice_offset[counter])^;
      writeln('edge[', counter: 1, ']: vertex index = ', vertex_index);
    end;
end; {procedure Write_lattice_vertices}


function Find_voxel_polarity(polarity_array_ptr: polarity_array_ptr_type;
  polarity_ptr: polarity_ptr_type): voxel_polarity_type;
var
  multiplier0, multiplier1, multiplier2, multiplier3: longint;
  addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8: longint;
  voxel_polarity: voxel_polarity_type;
begin
  multiplier0 := longint(polarity_ptr);
  multiplier1 := polarity_array_ptr^.multiplier1;
  multiplier2 := polarity_array_ptr^.multiplier2;
  multiplier3 := polarity_array_ptr^.multiplier3;

  addr1 := multiplier0;
  addr2 := multiplier0 + multiplier1;
  addr3 := multiplier0 + multiplier1 + multiplier2;
  addr4 := multiplier0 + multiplier2;
  addr5 := addr1 + multiplier3;
  addr6 := addr2 + multiplier3;
  addr7 := addr3 + multiplier3;
  addr8 := addr4 + multiplier3;

  voxel_polarity[1] := polarity_ptr_type(addr1)^;
  voxel_polarity[2] := polarity_ptr_type(addr2)^;
  voxel_polarity[3] := polarity_ptr_type(addr3)^;
  voxel_polarity[4] := polarity_ptr_type(addr4)^;
  voxel_polarity[5] := polarity_ptr_type(addr5)^;
  voxel_polarity[6] := polarity_ptr_type(addr6)^;
  voxel_polarity[7] := polarity_ptr_type(addr7)^;
  voxel_polarity[8] := polarity_ptr_type(addr8)^;

  Find_voxel_polarity := voxel_polarity;
end; {function Find_voxel_polarity}


procedure Write_stored_edges(edge_node_array_ptr: edge_node_array_ptr_type;
  index: integer);
var
  edge_addr: longint;
  edge_node_ptr: edge_node_ptr_type;
begin
  edge_addr := longint(edge_node_array_ptr) + (index - 1) *
    sizeof(edge_node_ptr_type);
  edge_node_ptr := edge_node_ptr_type(edge_addr);

  writeln('edges at index = ', index: 1, ':');
  while (edge_node_ptr <> nil) do
    begin
      write('edge with v2 = ', edge_node_ptr^.vertex: 1);
      write(', index = ', edge_node_ptr^.edge: 1);
      writeln;
      edge_node_ptr := edge_node_ptr^.next;
    end;
end; {procedure Write_stored_edges}


procedure Make_voxel_polygon_edge(mesh_ptr: mesh_ptr_type;
  vertex1, vertex2: integer);
var
  edge_array_ptr, edge_array_ptr1: edge_node_array_ptr_type;
  edge_node_ptr: edge_node_ptr_type;
  edge_index: integer;
  found: boolean;
begin
  {******************************************}
  { look up edge index by first vertex index }
  {******************************************}
  found := false;
  edge_array_ptr := Index_edge_node_array(edge_node_array_ptr, vertex1);
  edge_array_ptr1 := edge_array_ptr;
  edge_node_ptr := edge_array_ptr^;
  edge_index := 0;

  while (edge_node_ptr <> nil) and not found do
    begin
      if (edge_node_ptr^.vertex = vertex2) then
        begin
          edge_index := edge_node_ptr^.edge;
          found := true;
        end
      else
        edge_node_ptr := edge_node_ptr^.next;
    end;

  {*******************************************}
  { look up edge index by second vertex index }
  {*******************************************}
  if not found then
    begin
      edge_array_ptr := Index_edge_node_array(edge_node_array_ptr, vertex2);
      edge_node_ptr := edge_array_ptr^;
      while (edge_node_ptr <> nil) and not found do
        begin
          if (edge_node_ptr^.vertex = vertex1) then
            begin
              edge_index := -edge_node_ptr^.edge;
              found := true;
            end
          else
            edge_node_ptr := edge_node_ptr^.next;
        end;
    end;

  {************************************}
  { create new edge and enter in table }
  {************************************}
  if not found then
    begin
      edge_counter := edge_counter + 1;
      edge_node_ptr := New_edge_node(vertex2, edge_counter);
      Add_mesh_edge(mesh_ptr, vertex1, vertex2);

      edge_node_ptr^.next := edge_array_ptr1^;
      edge_array_ptr1^ := edge_node_ptr;

      edge_index := edge_counter;
    end;

  {******************}
  { add edge to face }
  {******************}
  Add_mesh_edge_index(mesh_ptr, edge_index);

  {******************************************}
  { add edge without checking for duplicates }
  {******************************************}
  {edge_counter := edge_counter + 1;}
  {Add_mesh_edge(mesh_ptr, vertex1, vertex2);}
  {Add_mesh_edge_index(mesh_ptr, edge_counter);}
end; {procedure Make_voxel_polygon_edge}


procedure Make_voxel_faces(mesh_ptr: mesh_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  polarity_ptr: polarity_ptr_type;
  vertex_index_ptr: vertex_index_ptr_type);
var
  voxel_polarity: voxel_polarity_type;
  voxel_polygon_ptr: voxel_polygon_ptr_type;
  voxel_vertex_ptr: voxel_vertex_ptr_type;
  index, first_edge, first_vertex, previous_vertex: integer;
  next_edge, next_vertex: integer;
begin
  {*********************}
  { find voxel polarity }
  {*********************}
  voxel_polarity := Find_voxel_polarity(polarity_array_ptr, polarity_ptr);

  {*******************************}
  { find tessellation from parity }
  {*******************************}
  index := Polarity_to_index(voxel_polarity);
  voxel_polygon_ptr := voxel_tessellation[index];

  {*************************************}
  { use tessellation to construct faces }
  {*************************************}
  while (voxel_polygon_ptr <> nil) do
    begin
      {********************}
      { make voxel polygon }
      {********************}
      Add_mesh_face(mesh_ptr, true);
      voxel_vertex_ptr := voxel_polygon_ptr^.vertex_ptr;
      face_counter := face_counter + 1;

      {*******************}
      { save first vertex }
      {*******************}
      first_edge := voxel_vertex_ptr^.edge;
      first_vertex := vertex_index_ptr_type(longint(vertex_index_ptr) +
        lattice_offset[first_edge])^;
      previous_vertex := first_vertex;

      voxel_vertex_ptr := voxel_vertex_ptr^.next;
      while (voxel_vertex_ptr <> nil) do
        begin
          {***************************}
          { get second vertex in edge }
          {***************************}
          next_edge := voxel_vertex_ptr^.edge;
          next_vertex := vertex_index_ptr_type(longint(vertex_index_ptr) +
            lattice_offset[next_edge])^;

          Make_voxel_polygon_edge(mesh_ptr, previous_vertex, next_vertex);
          previous_vertex := next_vertex;
          voxel_vertex_ptr := voxel_vertex_ptr^.next;
        end;

      {***************************}
      { connect with first vertex }
      {***************************}
      Make_voxel_polygon_edge(mesh_ptr, previous_vertex, first_vertex);

      voxel_polygon_ptr := voxel_polygon_ptr^.next;
    end;
end; {procedure Make_voxel_faces}


procedure Make_volume_faces(mesh_ptr: mesh_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  lattice_ptr: lattice_ptr_type);
var
  x_counter, y_counter, z_counter: integer;
  x_polarity_ptr, y_polarity_ptr, z_polarity_ptr: polarity_ptr_type;
  x_index_ptr, y_index_ptr, z_index_ptr: vertex_index_ptr_type;
  length, width, height: integer;
begin
  {******************************************}
  { initialize array to find duplicate edges }
  {******************************************}
  edge_node_array_ptr := New_edge_node_array;

  {******************}
  { visit each voxel }
  {******************}
  edge_counter := 0;
  face_counter := 0;
  z_polarity_ptr := polarity_array_ptr^.polarity_ptr;
  z_index_ptr := lattice_ptr^.vertex_index_ptr;

  length := lattice_ptr^.length;
  width := lattice_ptr^.width;
  height := lattice_ptr^.height;

  if (length > 0) and (width > 0) and (height > 0) then
    begin
      for z_counter := 1 to height - 1 do
        begin

          {******************}
          { start next layer }
          {******************}
          y_polarity_ptr := z_polarity_ptr;
          y_index_ptr := z_index_ptr;

          for y_counter := 1 to width - 1 do
            begin

              {****************}
              { start next row }
              {****************}
              x_polarity_ptr := y_polarity_ptr;
              x_index_ptr := y_index_ptr;

              for x_counter := 1 to length - 1 do
                begin
                  Make_voxel_faces(mesh_ptr, polarity_array_ptr, x_polarity_ptr,
                    x_index_ptr);

                  {*******************}
                  { go to next column }
                  {*******************}
                  x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
                    polarity_array_ptr^.multiplier1);
                  x_index_ptr := vertex_index_ptr_type(longint(x_index_ptr) +
                    lattice_ptr^.multiplier1);
                end;

              {****************}
              { go to next row }
              {****************}
              y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
                polarity_array_ptr^.multiplier2);
              y_index_ptr := vertex_index_ptr_type(longint(y_index_ptr) +
                lattice_ptr^.multiplier2);
            end;

          {******************}
          { go to next layer }
          {******************}
          z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
            polarity_array_ptr^.multiplier3);
          z_index_ptr := vertex_index_ptr_type(longint(z_index_ptr) +
            lattice_ptr^.multiplier3);
        end;
    end;

  {******************************************}
  { dispose of array to find duplicate edges }
  {******************************************}
  Free_edge_node_array(edge_node_array_ptr);
end; {procedure Make_volume_faces}


initialization
  polarity_array_free_list := nil;
  lattice_free_list := nil;
  edge_node_free_list := nil;
  edge_node_array_ptr := nil;
  edge_node_block_ptr := nil;
  edge_node_counter := 0;
end.
