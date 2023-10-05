unit isovertices;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            isovertices                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module builds the vertices of the polygonal        }
{       data structures for the volume objects. These are       }
{       then used to construct the b rep.                       }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  polymeshes, volumes, isosurfaces;


type
  {***********************************************************}
  { This array is used to index the vertices created on the   }
  { capping faces of the volume. This array can be visualized }
  { as 2 2D arrays, one for the vertices which are coincident }
  { with the density vertices and one for the vertices which  }
  { are coincident with the lattice vertices.                 }
  {***********************************************************}
  vertex_array_ptr_type = ^vertex_array_type;
  vertex_array_type = record
    length, width, height: integer;
    multiplier1, multiplier2, multiplier3: longint;
    vertex_index_ptr: vertex_index_ptr_type;
    next: vertex_array_ptr_type;
  end; {vertex_array_type}


function New_vertex_array(length, width, height: integer):
  vertex_array_ptr_type;
procedure Init_vertex_array(vertex_array_ptr: vertex_array_ptr_type);
function Index_vertex_array(vertex_array_ptr: vertex_array_ptr_type;
  length, width, height: integer): vertex_index_ptr_type;
procedure Free_vertex_array(var vertex_array_ptr: vertex_array_ptr_type);


{******************************}
{ make xy vertices and lattice }
{******************************}
procedure Make_xy_vertices(mesh_ptr: mesh_ptr_type;
  z: real;
  height: integer;
  vertex_array_ptr: vertex_array_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  volume_ptr: volume_ptr_type);
procedure Make_xy_lattice(mesh_ptr: mesh_ptr_type;
  z: real;
  height: integer;
  vertex_array_ptr: vertex_array_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  volume_ptr: volume_ptr_type);

{******************************}
{ make yz vertices and lattice }
{******************************}
procedure Make_yz_vertices(mesh_ptr: mesh_ptr_type;
  x: real;
  length: integer;
  vertex_array_ptr: vertex_array_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  volume_ptr: volume_ptr_type);
procedure Make_yz_lattice(mesh_ptr: mesh_ptr_type;
  x: real;
  length: integer;
  vertex_array_ptr: vertex_array_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  volume_ptr: volume_ptr_type);

{******************************}
{ make xz vertices and lattice }
{******************************}
procedure Make_xz_vertices(mesh_ptr: mesh_ptr_type;
  y: real;
  width: integer;
  vertex_array_ptr: vertex_array_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  volume_ptr: volume_ptr_type);
procedure Make_xz_lattice(mesh_ptr: mesh_ptr_type;
  y: real;
  width: integer;
  vertex_array_ptr: vertex_array_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  volume_ptr: volume_ptr_type);


{****************************************}
{ routines to write vertex array structs }
{****************************************}
procedure Write_vertex_array(vertex_array_ptr: vertex_array_ptr_type);


implementation
uses
  new_memory, vectors, cubes;


const
  {**********************************************}
  { If the isosurface shares vertices with the   }
  { capping faces, then surface will be smoothed }
  { at the junction.                             }
  {**********************************************}
  share_vertices = false;
  memory_alert = false;


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


var
  {************}
  { free lists }
  {************}
  vertex_array_free_list: vertex_array_ptr_type;


{********************************************}
{ routines to allocate and free vertex array }
{********************************************}


function New_vertex_array(length, width, height: integer):
  vertex_array_ptr_type;
var
  vertex_array_size: longint;
  vertex_array_ptr: vertex_array_ptr_type;
begin
  {*********************************}
  { get vertex array from free list }
  {*********************************}
  if (vertex_array_free_list <> nil) then
    begin
      vertex_array_ptr := vertex_array_free_list;
      vertex_array_free_list := vertex_array_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new vertex array');
      new(vertex_array_ptr);
    end;

  {*************************}
  { initialize vertex array }
  {*************************}
  vertex_array_ptr^.length := length;
  vertex_array_ptr^.width := width;
  vertex_array_ptr^.height := height;
  vertex_array_ptr^.next := nil;

  {*********************}
  { compute multipliers }
  {*********************}
  with vertex_array_ptr^ do
    begin
      multiplier1 := sizeof(vertex_index_type);
      multiplier2 := longint(length) * multiplier1;
      multiplier3 := longint(width) * multiplier2;
    end;

  {***********************}
  { allocate vertex array }
  {***********************}
  vertex_array_size := longint(length + 1) * longint(width + 1) * longint(height
    + 1);
  vertex_array_size := vertex_array_size * sizeof(vertex_index_type);

  if memory_alert then
    writeln('allocating new vertex array');
  vertex_array_ptr^.vertex_index_ptr :=
    vertex_index_ptr_type(New_ptr(vertex_array_size));

  New_vertex_array := vertex_array_ptr;
end; {function New_vertex_array}


procedure Init_vertex_array(vertex_array_ptr: vertex_array_ptr_type);
var
  index_ptr: vertex_index_ptr_type;
  vertex_array_size, counter: longint;
begin
  index_ptr := vertex_array_ptr^.vertex_index_ptr;
  with vertex_array_ptr^ do
    vertex_array_size := length * width * height;
  for counter := 1 to vertex_array_size do
    begin
      index_ptr^ := 0;
      index_ptr := vertex_index_ptr_type(longint(index_ptr) +
        vertex_array_ptr^.multiplier1);
    end;
end; {procedure Init_vertex_array}


function Index_vertex_array(vertex_array_ptr: vertex_array_ptr_type;
  length, width, height: integer): vertex_index_ptr_type;
var
  offset: longint;
begin
  offset := longint(length) * vertex_array_ptr^.multiplier1;
  offset := offset + longint(width) * vertex_array_ptr^.multiplier2;
  offset := offset + longint(height) * vertex_array_ptr^.multiplier3;
  Index_vertex_array :=
    vertex_index_ptr_type(longint(vertex_array_ptr^.vertex_index_ptr) + offset);
end; {function Index_vertex_array}


procedure Free_vertex_array(var vertex_array_ptr: vertex_array_ptr_type);
begin
  Free_ptr(ptr_type(vertex_array_ptr^.vertex_index_ptr));

  vertex_array_ptr^.next := vertex_array_free_list;
  vertex_array_free_list := vertex_array_ptr;
  vertex_array_ptr := nil;
end; {procedure Free_vertex_array}


{**************************************}
{ routines for making capping surfaces }
{**************************************}


{******************************}
{ make xy vertices and lattice }
{******************************}


procedure Make_xy_vertices(mesh_ptr: mesh_ptr_type;
  z: real;
  height: integer;
  vertex_array_ptr: vertex_array_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  volume_ptr: volume_ptr_type);
var
  x_counter, y_counter: integer;
  x_polarity_ptr, y_polarity_ptr: polarity_ptr_type;
  x_vertex_ptr, y_vertex_ptr: vertex_index_ptr_type;
  x_point_ptr, y_point_ptr: vector_ptr_type;
  point_array_ptr: point_array_ptr_type;
  vector, increment: vector_type;
begin
  {***************************}
  { make vertices on xy plane }
  {***************************}
  point_array_ptr := volume_ptr^.point_array_ptr;

  if (point_array_ptr = nil) then
    begin
      {*************************************}
      { make capping vertices for unit cube }
      {*************************************}
      increment := zero_vector;
      if (polarity_array_ptr^.length > 1) then
        increment.x := 2 / (polarity_array_ptr^.length - 1);
      if (polarity_array_ptr^.width > 1) then
        increment.y := 2 / (polarity_array_ptr^.width - 1);
      if (polarity_array_ptr^.height > 1) then
        increment.z := 2 / (polarity_array_ptr^.height - 1);
      vector.z := z;

      y_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      y_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
      vector.y := -1;

      {**********************}
      { go to correct height }
      {**********************}
      y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
        polarity_array_ptr^.multiplier3 * (height - 1));

      for y_counter := 1 to vertex_array_ptr^.width do
        begin

          {****************}
          { start next row }
          {****************}
          x_polarity_ptr := y_polarity_ptr;
          x_vertex_ptr := y_vertex_ptr;

          for x_counter := 0 to (vertex_array_ptr^.length - 1) do
            begin

              if (x_polarity_ptr^ = above) then
                begin
                  {***************************************}
                  { density inside volume - create vertex }
                  {***************************************}
                  vector.x := (x_counter * increment.x) - 1;
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  x_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {**********************************************}
                  { density outside volume - don't create vertex }
                  {**********************************************}
                  x_vertex_ptr^ := 0;
                end;

              {*******************}
              { go to next column }
              {*******************}
              x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
                polarity_array_ptr^.multiplier1);
              x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
                vertex_array_ptr^.multiplier1);
            end;

          {****************}
          { go to next row }
          {****************}
          y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
            polarity_array_ptr^.multiplier2);
          y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          vector.y := vector.y + increment.y;
        end;
    end

  else
    begin
      {***********************************************}
      { make capping vertices for user defined volume }
      {***********************************************}
      y_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      y_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
      y_point_ptr := point_array_ptr^.point_ptr;

      {**********************}
      { go to correct height }
      {**********************}
      y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
        polarity_array_ptr^.multiplier3 * (height - 1));
      y_point_ptr := vector_ptr_type(longint(y_point_ptr) +
        point_array_ptr^.multiplier3 * (height - 1));

      for y_counter := 1 to vertex_array_ptr^.width do
        begin

          {****************}
          { start next row }
          {****************}
          x_polarity_ptr := y_polarity_ptr;
          x_vertex_ptr := y_vertex_ptr;
          x_point_ptr := y_point_ptr;

          for x_counter := 0 to (vertex_array_ptr^.length - 1) do
            begin

              if (x_polarity_ptr^ = above) then
                begin
                  {***************************************}
                  { density inside volume - create vertex }
                  {***************************************}
                  vector := x_point_ptr^;
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  x_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {**********************************************}
                  { density outside volume - don't create vertex }
                  {**********************************************}
                  x_vertex_ptr^ := 0;
                end;

              {*******************}
              { go to next column }
              {*******************}
              x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
                polarity_array_ptr^.multiplier1);
              x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
                vertex_array_ptr^.multiplier1);
              x_point_ptr := vector_ptr_type(longint(x_point_ptr) +
                point_array_ptr^.multiplier1);
            end;

          {****************}
          { go to next row }
          {****************}
          y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
            polarity_array_ptr^.multiplier2);
          y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          y_point_ptr := vector_ptr_type(longint(y_point_ptr) +
            point_array_ptr^.multiplier2);
        end;
    end;

end; {procedure Make_xy_vertices}


procedure Make_xy_lattice(mesh_ptr: mesh_ptr_type;
  z: real;
  height: integer;
  vertex_array_ptr: vertex_array_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  volume_ptr: volume_ptr_type);
var
  x_counter, y_counter: integer;
  x_polarity_ptr, y_polarity_ptr: polarity_ptr_type;
  x_vertex_ptr, y_vertex_ptr: vertex_index_ptr_type;
  x_density_ptr, y_density_ptr: density_ptr_type;
  x_point_ptr, y_point_ptr: vector_ptr_type;

  density1, density2, factor: real;
  polarity_ptr1, polarity_ptr2: polarity_ptr_type;
  density_ptr1, density_ptr2: density_ptr_type;
  point_ptr1, point_ptr2: vector_ptr_type;

  density_array_ptr: density_array_ptr_type;
  point_array_ptr: point_array_ptr_type;
  vector, increment: vector_type;
begin
  {***********************************}
  { make lattice vertices on xy plane }
  {***********************************}
  density_array_ptr := volume_ptr^.density_array_ptr;
  point_array_ptr := volume_ptr^.point_array_ptr;

  if (point_array_ptr = nil) then
    begin
      {*************************************}
      { make lattice vertices for unit cube }
      {*************************************}
      increment := zero_vector;
      if (polarity_array_ptr^.length > 1) then
        increment.x := 2 / (polarity_array_ptr^.length - 1);
      if (polarity_array_ptr^.width > 1) then
        increment.y := 2 / (polarity_array_ptr^.width - 1);
      if (polarity_array_ptr^.height > 1) then
        increment.z := 2 / (polarity_array_ptr^.height - 1);
      vector.z := z;

      {**********************************}
      { make horizontal lattice vertices }
      {**********************************}

      y_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      y_density_ptr := density_array_ptr^.density_ptr;
      y_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;

      {**********************}
      { go to correct height }
      {**********************}
      y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
        polarity_array_ptr^.multiplier3 * (height - 1));
      y_density_ptr := density_ptr_type(longint(y_density_ptr) +
        density_array_ptr^.multiplier3 * (height - 1));
      y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
        vertex_array_ptr^.multiplier3);
      vector.y := -1;

      for y_counter := 1 to vertex_array_ptr^.width do
        begin

          {****************}
          { start next row }
          {****************}
          x_polarity_ptr := y_polarity_ptr;
          x_density_ptr := y_density_ptr;
          x_vertex_ptr := y_vertex_ptr;

          for x_counter := 0 to (vertex_array_ptr^.length - 2) do
            begin

              {*******************}
              { go to next column }
              {*******************}
              polarity_ptr1 := x_polarity_ptr;
              density_ptr1 := x_density_ptr;

              x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
                polarity_array_ptr^.multiplier1);
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
                  factor := (volume_ptr^.threshold - density1) / (density2 -
                    density1);
                  vector.x := (x_counter + factor) * increment.x - 1;
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  x_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {***********************}
                  { no new vertex created }
                  {***********************}
                  x_vertex_ptr^ := 0;
                end;

              x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
                vertex_array_ptr^.multiplier1);
            end;

          {****************}
          { go to next row }
          {****************}
          y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
            polarity_array_ptr^.multiplier2);
          y_density_ptr := density_ptr_type(longint(y_density_ptr) +
            density_array_ptr^.multiplier2);
          y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          vector.y := vector.y + increment.y;
        end;

      {********************************}
      { make vertical lattice vertices }
      {********************************}

      x_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      x_density_ptr := density_array_ptr^.density_ptr;
      x_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;

      {**********************}
      { go to correct height }
      {**********************}
      x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
        polarity_array_ptr^.multiplier3 * (height - 1));
      x_density_ptr := density_ptr_type(longint(x_density_ptr) +
        density_array_ptr^.multiplier3 * (height - 1));
      x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
        vertex_array_ptr^.multiplier3 * 2);
      vector.x := -1;

      for x_counter := 1 to vertex_array_ptr^.length do
        begin

          {*******************}
          { start next column }
          {*******************}
          y_polarity_ptr := x_polarity_ptr;
          y_density_ptr := x_density_ptr;
          y_vertex_ptr := x_vertex_ptr;

          for y_counter := 0 to (vertex_array_ptr^.width - 2) do
            begin

              {****************}
              { go to next row }
              {****************}
              polarity_ptr1 := y_polarity_ptr;
              density_ptr1 := y_density_ptr;

              y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
                polarity_array_ptr^.multiplier2);
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
                  factor := (volume_ptr^.threshold - density1) / (density2 -
                    density1);
                  vector.y := (y_counter + factor) * increment.y - 1;
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  y_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {***********************}
                  { no new vertex created }
                  {***********************}
                  y_vertex_ptr^ := 0;
                end;

              y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
                vertex_array_ptr^.multiplier2);
            end;

          {*******************}
          { go to next column }
          {*******************}
          x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
            polarity_array_ptr^.multiplier1);
          x_density_ptr := density_ptr_type(longint(x_density_ptr) +
            density_array_ptr^.multiplier1);
          x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
            vertex_array_ptr^.multiplier1);
          vector.x := vector.x + increment.x;
        end;
    end

  else
    begin
      {***********************************************}
      { make lattice vertices for user defined volume }
      {***********************************************}

      {**********************************}
      { make horizontal lattice vertices }
      {**********************************}

      y_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      y_density_ptr := density_array_ptr^.density_ptr;
      y_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
      y_point_ptr := point_array_ptr^.point_ptr;

      {**********************}
      { go to correct height }
      {**********************}
      y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
        polarity_array_ptr^.multiplier3 * (height - 1));
      y_density_ptr := density_ptr_type(longint(y_density_ptr) +
        density_array_ptr^.multiplier3 * (height - 1));
      y_point_ptr := vector_ptr_type(longint(y_point_ptr) +
        point_array_ptr^.multiplier3 * (height - 1));
      y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
        vertex_array_ptr^.multiplier3);

      for y_counter := 1 to vertex_array_ptr^.width do
        begin

          {****************}
          { start next row }
          {****************}
          x_polarity_ptr := y_polarity_ptr;
          x_density_ptr := y_density_ptr;
          x_vertex_ptr := y_vertex_ptr;
          x_point_ptr := y_point_ptr;

          for x_counter := 0 to (vertex_array_ptr^.length - 2) do
            begin

              {*******************}
              { go to next column }
              {*******************}
              polarity_ptr1 := x_polarity_ptr;
              density_ptr1 := x_density_ptr;
              point_ptr1 := x_point_ptr;

              x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
                polarity_array_ptr^.multiplier1);
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
                  factor := (volume_ptr^.threshold - density1) / (density2 -
                    density1);
                  vector := Vector_sum(Vector_scale(point_ptr1^, 1 - factor),
                    Vector_scale(point_ptr2^, factor));
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  x_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {***********************}
                  { no new vertex created }
                  {***********************}
                  x_vertex_ptr^ := 0;
                end;

              x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
                vertex_array_ptr^.multiplier1);
            end;

          {****************}
          { go to next row }
          {****************}
          y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
            polarity_array_ptr^.multiplier2);
          y_density_ptr := density_ptr_type(longint(y_density_ptr) +
            density_array_ptr^.multiplier2);
          y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          y_point_ptr := vector_ptr_type(longint(y_point_ptr) +
            point_array_ptr^.multiplier2);
        end;

      {********************************}
      { make vertical lattice vertices }
      {********************************}

      x_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      x_density_ptr := density_array_ptr^.density_ptr;
      x_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
      x_point_ptr := point_array_ptr^.point_ptr;

      {**********************}
      { go to correct height }
      {**********************}
      x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
        polarity_array_ptr^.multiplier3 * (height - 1));
      x_density_ptr := density_ptr_type(longint(x_density_ptr) +
        density_array_ptr^.multiplier3 * (height - 1));
      x_point_ptr := vector_ptr_type(longint(x_point_ptr) +
        point_array_ptr^.multiplier3 * (height - 1));
      x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
        vertex_array_ptr^.multiplier3 * 2);

      for x_counter := 1 to vertex_array_ptr^.length do
        begin

          {*******************}
          { start next column }
          {*******************}
          y_polarity_ptr := x_polarity_ptr;
          y_density_ptr := x_density_ptr;
          y_vertex_ptr := x_vertex_ptr;
          y_point_ptr := x_point_ptr;

          for y_counter := 0 to (vertex_array_ptr^.width - 2) do
            begin

              {****************}
              { go to next row }
              {****************}
              polarity_ptr1 := y_polarity_ptr;
              density_ptr1 := y_density_ptr;
              point_ptr1 := y_point_ptr;

              y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
                polarity_array_ptr^.multiplier2);
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
                  factor := (volume_ptr^.threshold - density1) / (density2 -
                    density1);
                  vector := Vector_sum(Vector_scale(point_ptr1^, 1 - factor),
                    Vector_scale(point_ptr2^, factor));
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  y_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {***********************}
                  { no new vertex created }
                  {***********************}
                  y_vertex_ptr^ := 0;
                end;

              y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
                vertex_array_ptr^.multiplier2);
            end;

          {*******************}
          { go to next column }
          {*******************}
          x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
            polarity_array_ptr^.multiplier1);
          x_density_ptr := density_ptr_type(longint(x_density_ptr) +
            density_array_ptr^.multiplier1);
          x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
            vertex_array_ptr^.multiplier1);
          x_point_ptr := vector_ptr_type(longint(x_point_ptr) +
            point_array_ptr^.multiplier1);
        end;
    end;

end; {procedure Make_xy_lattice}


{******************************}
{ make yz vertices and lattice }
{******************************}

procedure Make_yz_vertices(mesh_ptr: mesh_ptr_type;
  x: real;
  length: integer;
  vertex_array_ptr: vertex_array_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  volume_ptr: volume_ptr_type);
var
  y_counter, z_counter: integer;
  y_polarity_ptr, z_polarity_ptr: polarity_ptr_type;
  y_vertex_ptr, z_vertex_ptr: vertex_index_ptr_type;
  y_point_ptr, z_point_ptr: vector_ptr_type;
  point_array_ptr: point_array_ptr_type;
  vector, increment: vector_type;
begin
  {***************************}
  { make vertices on yz plane }
  {***************************}
  point_array_ptr := volume_ptr^.point_array_ptr;

  if (point_array_ptr = nil) then
    begin
      {*************************************}
      { make capping vertices for unit cube }
      {*************************************}
      increment := zero_vector;
      if (polarity_array_ptr^.length > 1) then
        increment.x := 2 / (polarity_array_ptr^.length - 1);
      if (polarity_array_ptr^.width > 1) then
        increment.y := 2 / (polarity_array_ptr^.width - 1);
      if (polarity_array_ptr^.height > 1) then
        increment.z := 2 / (polarity_array_ptr^.height - 1);
      vector.x := x;

      z_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      z_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
      vector.z := -1;

      {**********************}
      { go to correct length }
      {**********************}
      z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
        polarity_array_ptr^.multiplier1 * (length - 1));

      for z_counter := 1 to vertex_array_ptr^.width do
        begin

          {****************}
          { start next row }
          {****************}
          y_polarity_ptr := z_polarity_ptr;
          y_vertex_ptr := z_vertex_ptr;

          for y_counter := 0 to (vertex_array_ptr^.length - 1) do
            begin

              if (y_polarity_ptr^ = above) then
                begin
                  {***************************************}
                  { density inside volume - create vertex }
                  {***************************************}
                  vector.y := (y_counter * increment.y) - 1;
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  y_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {**********************************************}
                  { density outside volume - don't create vertex }
                  {**********************************************}
                  y_vertex_ptr^ := 0;
                end;

              {*******************}
              { go to next column }
              {*******************}
              y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
                polarity_array_ptr^.multiplier2);
              y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
                vertex_array_ptr^.multiplier1);
            end;

          {****************}
          { go to next row }
          {****************}
          z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
            polarity_array_ptr^.multiplier3);
          z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          vector.z := vector.z + increment.z;
        end;
    end

  else
    begin
      {***********************************************}
      { make capping vertices for user defined volume }
      {***********************************************}
      z_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      z_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
      z_point_ptr := point_array_ptr^.point_ptr;

      {**********************}
      { go to correct length }
      {**********************}
      z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
        polarity_array_ptr^.multiplier1 * (length - 1));
      z_point_ptr := vector_ptr_type(longint(z_point_ptr) +
        point_array_ptr^.multiplier1 * (length - 1));

      for z_counter := 1 to vertex_array_ptr^.width do
        begin

          {****************}
          { start next row }
          {****************}
          y_polarity_ptr := z_polarity_ptr;
          y_vertex_ptr := z_vertex_ptr;
          y_point_ptr := z_point_ptr;

          for y_counter := 0 to (vertex_array_ptr^.length - 1) do
            begin

              if (y_polarity_ptr^ = above) then
                begin
                  {***************************************}
                  { density inside volume - create vertex }
                  {***************************************}
                  vector := y_point_ptr^;
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  y_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {**********************************************}
                  { density outside volume - don't create vertex }
                  {**********************************************}
                  y_vertex_ptr^ := 0;
                end;

              {*******************}
              { go to next column }
              {*******************}
              y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
                polarity_array_ptr^.multiplier2);
              y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
                vertex_array_ptr^.multiplier1);
              y_point_ptr := vector_ptr_type(longint(y_point_ptr) +
                point_array_ptr^.multiplier2);
            end;

          {****************}
          { go to next row }
          {****************}
          z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
            polarity_array_ptr^.multiplier3);
          z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          z_point_ptr := vector_ptr_type(longint(z_point_ptr) +
            point_array_ptr^.multiplier3);
        end;
    end;

end; {procedure Make_yz_vertices}


procedure Make_yz_lattice(mesh_ptr: mesh_ptr_type;
  x: real;
  length: integer;
  vertex_array_ptr: vertex_array_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  volume_ptr: volume_ptr_type);
var
  y_counter, z_counter: integer;
  y_polarity_ptr, z_polarity_ptr: polarity_ptr_type;
  y_vertex_ptr, z_vertex_ptr: vertex_index_ptr_type;
  y_density_ptr, z_density_ptr: density_ptr_type;
  y_point_ptr, z_point_ptr: vector_ptr_type;

  density1, density2, factor: real;
  polarity_ptr1, polarity_ptr2: polarity_ptr_type;
  density_ptr1, density_ptr2: density_ptr_type;
  point_ptr1, point_ptr2: vector_ptr_type;

  density_array_ptr: density_array_ptr_type;
  point_array_ptr: point_array_ptr_type;
  vector, increment: vector_type;
begin
  {***********************************}
  { make lattice vertices on yz plane }
  {***********************************}
  density_array_ptr := volume_ptr^.density_array_ptr;
  point_array_ptr := volume_ptr^.point_array_ptr;

  if (point_array_ptr = nil) then
    begin
      {*************************************}
      { make lattice vertices for unit cube }
      {*************************************}
      increment := zero_vector;
      if (polarity_array_ptr^.length > 1) then
        increment.x := 2 / (polarity_array_ptr^.length - 1);
      if (polarity_array_ptr^.width > 1) then
        increment.y := 2 / (polarity_array_ptr^.width - 1);
      if (polarity_array_ptr^.height > 1) then
        increment.z := 2 / (polarity_array_ptr^.height - 1);
      vector.x := x;

      {**********************************}
      { make horizontal lattice vertices }
      {**********************************}

      z_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      z_density_ptr := density_array_ptr^.density_ptr;
      z_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;

      {**********************}
      { go to correct length }
      {**********************}
      z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
        polarity_array_ptr^.multiplier1 * (length - 1));
      z_density_ptr := density_ptr_type(longint(z_density_ptr) +
        density_array_ptr^.multiplier1 * (length - 1));
      z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
        vertex_array_ptr^.multiplier3);
      vector.z := -1;

      for z_counter := 1 to vertex_array_ptr^.width do
        begin

          {****************}
          { start next row }
          {****************}
          y_polarity_ptr := z_polarity_ptr;
          y_density_ptr := z_density_ptr;
          y_vertex_ptr := z_vertex_ptr;

          for y_counter := 0 to (vertex_array_ptr^.length - 2) do
            begin

              {*******************}
              { go to next column }
              {*******************}
              polarity_ptr1 := y_polarity_ptr;
              density_ptr1 := y_density_ptr;

              y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
                polarity_array_ptr^.multiplier2);
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
                  factor := (volume_ptr^.threshold - density1) / (density2 -
                    density1);
                  vector.y := (y_counter + factor) * increment.y - 1;
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  y_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {***********************}
                  { no new vertex created }
                  {***********************}
                  y_vertex_ptr^ := 0;
                end;

              y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
                vertex_array_ptr^.multiplier1);
            end;

          {****************}
          { go to next row }
          {****************}
          z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
            polarity_array_ptr^.multiplier3);
          z_density_ptr := density_ptr_type(longint(z_density_ptr) +
            density_array_ptr^.multiplier3);
          z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          vector.z := vector.z + increment.z;
        end;

      {********************************}
      { make vertical lattice vertices }
      {********************************}

      y_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      y_density_ptr := density_array_ptr^.density_ptr;
      y_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;

      {**********************}
      { go to correct length }
      {**********************}
      y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
        polarity_array_ptr^.multiplier1 * (length - 1));
      y_density_ptr := density_ptr_type(longint(y_density_ptr) +
        density_array_ptr^.multiplier1 * (length - 1));
      y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
        vertex_array_ptr^.multiplier3 * 2);
      vector.y := -1;

      for y_counter := 1 to vertex_array_ptr^.length do
        begin

          {****************}
          { start next row }
          {****************}
          z_polarity_ptr := y_polarity_ptr;
          z_density_ptr := y_density_ptr;
          z_vertex_ptr := y_vertex_ptr;

          for z_counter := 0 to (vertex_array_ptr^.width - 2) do
            begin

              {*******************}
              { go to next column }
              {*******************}
              polarity_ptr1 := z_polarity_ptr;
              density_ptr1 := z_density_ptr;

              z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
                polarity_array_ptr^.multiplier3);
              z_density_ptr := density_ptr_type(longint(z_density_ptr) +
                density_array_ptr^.multiplier3);

              polarity_ptr2 := z_polarity_ptr;
              density_ptr2 := z_density_ptr;

              if (polarity_ptr1^ <> polarity_ptr2^) then
                begin
                  {********************}
                  { compute new vertex }
                  {********************}
                  density1 := density_ptr1^;
                  density2 := density_ptr2^;
                  factor := (volume_ptr^.threshold - density1) / (density2 -
                    density1);
                  vector.z := (z_counter + factor) * increment.z - 1;
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  z_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {***********************}
                  { no new vertex created }
                  {***********************}
                  z_vertex_ptr^ := 0;
                end;

              z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
                vertex_array_ptr^.multiplier2);
            end;

          {****************}
          { go to next row }
          {****************}
          y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
            polarity_array_ptr^.multiplier2);
          y_density_ptr := density_ptr_type(longint(y_density_ptr) +
            density_array_ptr^.multiplier2);
          y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
            vertex_array_ptr^.multiplier1);
          vector.y := vector.y + increment.y;
        end;
    end

  else
    begin
      {***********************************************}
      { make lattice vertices for user defined volume }
      {***********************************************}

      {**********************************}
      { make horizontal lattice vertices }
      {**********************************}

      z_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      z_density_ptr := density_array_ptr^.density_ptr;
      z_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
      z_point_ptr := point_array_ptr^.point_ptr;

      {**********************}
      { go to correct length }
      {**********************}
      z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
        polarity_array_ptr^.multiplier1 * (length - 1));
      z_density_ptr := density_ptr_type(longint(z_density_ptr) +
        density_array_ptr^.multiplier1 * (length - 1));
      z_point_ptr := vector_ptr_type(longint(z_point_ptr) +
        point_array_ptr^.multiplier1 * (length - 1));
      z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
        vertex_array_ptr^.multiplier3);

      for z_counter := 1 to vertex_array_ptr^.width do
        begin

          {****************}
          { start next row }
          {****************}
          y_polarity_ptr := z_polarity_ptr;
          y_density_ptr := z_density_ptr;
          y_vertex_ptr := z_vertex_ptr;
          y_point_ptr := z_point_ptr;

          for y_counter := 0 to (vertex_array_ptr^.length - 2) do
            begin

              {*******************}
              { go to next column }
              {*******************}
              polarity_ptr1 := y_polarity_ptr;
              density_ptr1 := y_density_ptr;
              point_ptr1 := y_point_ptr;

              y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
                polarity_array_ptr^.multiplier2);
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
                  factor := (volume_ptr^.threshold - density1) / (density2 -
                    density1);
                  vector := Vector_sum(Vector_scale(point_ptr1^, 1 - factor),
                    Vector_scale(point_ptr2^, factor));
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  y_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {***********************}
                  { no new vertex created }
                  {***********************}
                  y_vertex_ptr^ := 0;
                end;

              y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
                vertex_array_ptr^.multiplier1);
            end;

          {****************}
          { go to next row }
          {****************}
          z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
            polarity_array_ptr^.multiplier3);
          z_density_ptr := density_ptr_type(longint(z_density_ptr) +
            density_array_ptr^.multiplier3);
          z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          z_point_ptr := vector_ptr_type(longint(z_point_ptr) +
            point_array_ptr^.multiplier3);
        end;

      {********************************}
      { make vertical lattice vertices }
      {********************************}

      y_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      y_density_ptr := density_array_ptr^.density_ptr;
      y_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
      y_point_ptr := point_array_ptr^.point_ptr;

      {**********************}
      { go to correct length }
      {**********************}
      y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
        polarity_array_ptr^.multiplier1 * (length - 1));
      y_density_ptr := density_ptr_type(longint(y_density_ptr) +
        density_array_ptr^.multiplier1 * (length - 1));
      y_point_ptr := vector_ptr_type(longint(y_point_ptr) +
        point_array_ptr^.multiplier1 * (length - 1));
      y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
        vertex_array_ptr^.multiplier3 * 2);

      for y_counter := 1 to vertex_array_ptr^.length do
        begin

          {****************}
          { start next row }
          {****************}
          z_polarity_ptr := y_polarity_ptr;
          z_density_ptr := y_density_ptr;
          z_vertex_ptr := y_vertex_ptr;
          z_point_ptr := y_point_ptr;

          for z_counter := 0 to (vertex_array_ptr^.width - 2) do
            begin

              {*******************}
              { go to next column }
              {*******************}
              polarity_ptr1 := z_polarity_ptr;
              density_ptr1 := z_density_ptr;
              point_ptr1 := z_point_ptr;

              z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
                polarity_array_ptr^.multiplier3);
              z_density_ptr := density_ptr_type(longint(z_density_ptr) +
                density_array_ptr^.multiplier3);
              z_point_ptr := vector_ptr_type(longint(z_point_ptr) +
                point_array_ptr^.multiplier3);

              polarity_ptr2 := z_polarity_ptr;
              density_ptr2 := z_density_ptr;
              point_ptr2 := z_point_ptr;

              if (polarity_ptr1^ <> polarity_ptr2^) then
                begin
                  {********************}
                  { compute new vertex }
                  {********************}
                  density1 := density_ptr1^;
                  density2 := density_ptr2^;
                  factor := (volume_ptr^.threshold - density1) / (density2 -
                    density1);
                  vector := Vector_sum(Vector_scale(point_ptr1^, 1 - factor),
                    Vector_scale(point_ptr2^, factor));
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  z_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {***********************}
                  { no new vertex created }
                  {***********************}
                  z_vertex_ptr^ := 0;
                end;

              z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
                vertex_array_ptr^.multiplier2);
            end;

          {****************}
          { go to next row }
          {****************}
          y_polarity_ptr := polarity_ptr_type(longint(y_polarity_ptr) +
            polarity_array_ptr^.multiplier2);
          y_density_ptr := density_ptr_type(longint(y_density_ptr) +
            density_array_ptr^.multiplier2);
          y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
            vertex_array_ptr^.multiplier1);
          y_point_ptr := vector_ptr_type(longint(y_point_ptr) +
            point_array_ptr^.multiplier2);
        end;
    end;

end; {procedure Make_yz_lattice}


{******************************}
{ make xz vertices and lattice }
{******************************}

procedure Make_xz_vertices(mesh_ptr: mesh_ptr_type;
  y: real;
  width: integer;
  vertex_array_ptr: vertex_array_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  volume_ptr: volume_ptr_type);
var
  x_counter, z_counter: integer;
  x_polarity_ptr, z_polarity_ptr: polarity_ptr_type;
  x_vertex_ptr, z_vertex_ptr: vertex_index_ptr_type;
  x_point_ptr, z_point_ptr: vector_ptr_type;
  point_array_ptr: point_array_ptr_type;
  vector, increment: vector_type;
begin
  {***************************}
  { make vertices on xz plane }
  {***************************}
  point_array_ptr := volume_ptr^.point_array_ptr;

  if (point_array_ptr = nil) then
    begin
      {*************************************}
      { make capping vertices for unit cube }
      {*************************************}
      increment := zero_vector;
      if (polarity_array_ptr^.length > 1) then
        increment.x := 2 / (polarity_array_ptr^.length - 1);
      if (polarity_array_ptr^.width > 1) then
        increment.y := 2 / (polarity_array_ptr^.width - 1);
      if (polarity_array_ptr^.height > 1) then
        increment.z := 2 / (polarity_array_ptr^.height - 1);
      vector.y := y;

      z_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      z_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
      vector.z := -1;

      {**********************}
      { go to correct length }
      {**********************}
      z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
        polarity_array_ptr^.multiplier2 * (width - 1));

      for z_counter := 1 to vertex_array_ptr^.width do
        begin

          {****************}
          { start next row }
          {****************}
          x_polarity_ptr := z_polarity_ptr;
          x_vertex_ptr := z_vertex_ptr;

          for x_counter := 0 to (vertex_array_ptr^.length - 1) do
            begin

              if (x_polarity_ptr^ = above) then
                begin
                  {***************************************}
                  { density inside volume - create vertex }
                  {***************************************}
                  vector.x := (x_counter * increment.x) - 1;
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  x_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {**********************************************}
                  { density outside volume - don't create vertex }
                  {**********************************************}
                  x_vertex_ptr^ := 0;
                end;

              {*******************}
              { go to next column }
              {*******************}
              x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
                polarity_array_ptr^.multiplier1);
              x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
                vertex_array_ptr^.multiplier1);
            end;

          {****************}
          { go to next row }
          {****************}
          z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
            polarity_array_ptr^.multiplier3);
          z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          vector.z := vector.z + increment.z;
        end;
    end

  else
    begin
      {***********************************************}
      { make capping vertices for user defined volume }
      {***********************************************}
      z_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      z_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
      z_point_ptr := point_array_ptr^.point_ptr;

      {**********************}
      { go to correct length }
      {**********************}
      z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
        polarity_array_ptr^.multiplier2 * (width - 1));
      z_point_ptr := vector_ptr_type(longint(z_point_ptr) +
        point_array_ptr^.multiplier2 * (width - 1));

      for z_counter := 1 to vertex_array_ptr^.width do
        begin

          {****************}
          { start next row }
          {****************}
          x_polarity_ptr := z_polarity_ptr;
          x_vertex_ptr := z_vertex_ptr;
          x_point_ptr := z_point_ptr;

          for x_counter := 0 to (vertex_array_ptr^.length - 1) do
            begin

              if (x_polarity_ptr^ = above) then
                begin
                  {***************************************}
                  { density inside volume - create vertex }
                  {***************************************}
                  vector := x_point_ptr^;
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  x_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {**********************************************}
                  { density outside volume - don't create vertex }
                  {**********************************************}
                  x_vertex_ptr^ := 0;
                end;

              {*******************}
              { go to next column }
              {*******************}
              x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
                polarity_array_ptr^.multiplier1);
              x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
                vertex_array_ptr^.multiplier1);
              x_point_ptr := vector_ptr_type(longint(x_point_ptr) +
                point_array_ptr^.multiplier1);
            end;

          {****************}
          { go to next row }
          {****************}
          z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
            polarity_array_ptr^.multiplier3);
          z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          z_point_ptr := vector_ptr_type(longint(z_point_ptr) +
            point_array_ptr^.multiplier3);
        end;
    end;

end; {procedure Make_xz_vertices}


procedure Make_xz_lattice(mesh_ptr: mesh_ptr_type;
  y: real;
  width: integer;
  vertex_array_ptr: vertex_array_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  volume_ptr: volume_ptr_type);
var
  x_counter, z_counter: integer;
  x_polarity_ptr, z_polarity_ptr: polarity_ptr_type;
  x_vertex_ptr, z_vertex_ptr: vertex_index_ptr_type;
  x_density_ptr, z_density_ptr: density_ptr_type;
  x_point_ptr, z_point_ptr: vector_ptr_type;

  density1, density2, factor: real;
  polarity_ptr1, polarity_ptr2: polarity_ptr_type;
  density_ptr1, density_ptr2: density_ptr_type;
  point_ptr1, point_ptr2: vector_ptr_type;

  density_array_ptr: density_array_ptr_type;
  point_array_ptr: point_array_ptr_type;
  vector, increment: vector_type;
begin
  {***************************}
  { make vertices on xz plane }
  {***************************}
  density_array_ptr := volume_ptr^.density_array_ptr;
  point_array_ptr := volume_ptr^.point_array_ptr;

  if (point_array_ptr = nil) then
    begin
      {*************************************}
      { make lattice vertices for unit cube }
      {*************************************}
      increment := zero_vector;
      if (polarity_array_ptr^.length > 1) then
        increment.x := 2 / (polarity_array_ptr^.length - 1);
      if (polarity_array_ptr^.width > 1) then
        increment.y := 2 / (polarity_array_ptr^.width - 1);
      if (polarity_array_ptr^.height > 1) then
        increment.z := 2 / (polarity_array_ptr^.height - 1);
      vector.y := y;

      {**********************************}
      { make horizontal lattice vertices }
      {**********************************}

      z_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      z_density_ptr := density_array_ptr^.density_ptr;
      z_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;

      {**********************}
      { go to correct length }
      {**********************}
      z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
        polarity_array_ptr^.multiplier2 * (width - 1));
      z_density_ptr := density_ptr_type(longint(z_density_ptr) +
        density_array_ptr^.multiplier2 * (width - 1));
      z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
        vertex_array_ptr^.multiplier3);
      vector.z := -1;

      for z_counter := 1 to vertex_array_ptr^.width do
        begin

          {****************}
          { start next row }
          {****************}
          x_polarity_ptr := z_polarity_ptr;
          x_density_ptr := z_density_ptr;
          x_vertex_ptr := z_vertex_ptr;

          for x_counter := 0 to (vertex_array_ptr^.length - 2) do
            begin

              {*******************}
              { go to next column }
              {*******************}
              polarity_ptr1 := x_polarity_ptr;
              density_ptr1 := x_density_ptr;

              x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
                polarity_array_ptr^.multiplier1);
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
                  factor := (volume_ptr^.threshold - density1) / (density2 -
                    density1);
                  vector.x := (x_counter + factor) * increment.x - 1;
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  x_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {***********************}
                  { no new vertex created }
                  {***********************}
                  x_vertex_ptr^ := 0;
                end;

              x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
                vertex_array_ptr^.multiplier1);
            end;

          {****************}
          { go to next row }
          {****************}
          z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
            polarity_array_ptr^.multiplier3);
          z_density_ptr := density_ptr_type(longint(z_density_ptr) +
            density_array_ptr^.multiplier3);
          z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          vector.z := vector.z + increment.z;
        end;

      {********************************}
      { make vertical lattice vertices }
      {********************************}

      x_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      x_density_ptr := density_array_ptr^.density_ptr;
      x_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;

      {**********************}
      { go to correct length }
      {**********************}
      x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
        polarity_array_ptr^.multiplier2 * (width - 1));
      x_density_ptr := density_ptr_type(longint(x_density_ptr) +
        density_array_ptr^.multiplier2 * (width - 1));
      x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
        vertex_array_ptr^.multiplier3 * 2);
      vector.x := -1;

      for x_counter := 1 to vertex_array_ptr^.length do
        begin

          {****************}
          { start next row }
          {****************}
          z_polarity_ptr := x_polarity_ptr;
          z_density_ptr := x_density_ptr;
          z_vertex_ptr := x_vertex_ptr;

          for z_counter := 0 to (vertex_array_ptr^.width - 2) do
            begin

              {*******************}
              { go to next column }
              {*******************}
              polarity_ptr1 := z_polarity_ptr;
              density_ptr1 := z_density_ptr;

              z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
                polarity_array_ptr^.multiplier3);
              z_density_ptr := density_ptr_type(longint(z_density_ptr) +
                density_array_ptr^.multiplier3);

              polarity_ptr2 := z_polarity_ptr;
              density_ptr2 := z_density_ptr;

              if (polarity_ptr1^ <> polarity_ptr2^) then
                begin
                  {********************}
                  { compute new vertex }
                  {********************}
                  density1 := density_ptr1^;
                  density2 := density_ptr2^;
                  factor := (volume_ptr^.threshold - density1) / (density2 -
                    density1);
                  vector.z := (z_counter + factor) * increment.z - 1;
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  z_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {***********************}
                  { no new vertex created }
                  {***********************}
                  z_vertex_ptr^ := 0;
                end;

              z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
                vertex_array_ptr^.multiplier2);
            end;

          {****************}
          { go to next row }
          {****************}
          x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
            polarity_array_ptr^.multiplier1);
          x_density_ptr := density_ptr_type(longint(x_density_ptr) +
            density_array_ptr^.multiplier1);
          x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
            vertex_array_ptr^.multiplier1);
          vector.x := vector.x + increment.x;
        end;
    end

  else
    begin
      {***********************************************}
      { make lattice vertices for user defined volume }
      {***********************************************}

      {**********************************}
      { make horizontal lattice vertices }
      {**********************************}

      z_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      z_density_ptr := density_array_ptr^.density_ptr;
      z_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
      z_point_ptr := point_array_ptr^.point_ptr;

      {**********************}
      { go to correct length }
      {**********************}
      z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
        polarity_array_ptr^.multiplier2 * (width - 1));
      z_density_ptr := density_ptr_type(longint(z_density_ptr) +
        density_array_ptr^.multiplier2 * (width - 1));
      z_point_ptr := vector_ptr_type(longint(z_point_ptr) +
        point_array_ptr^.multiplier2 * (width - 1));
      z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
        vertex_array_ptr^.multiplier3);

      for z_counter := 1 to vertex_array_ptr^.width do
        begin

          {****************}
          { start next row }
          {****************}
          x_polarity_ptr := z_polarity_ptr;
          x_density_ptr := z_density_ptr;
          x_vertex_ptr := z_vertex_ptr;
          x_point_ptr := z_point_ptr;

          for x_counter := 0 to (vertex_array_ptr^.length - 2) do
            begin

              {*******************}
              { go to next column }
              {*******************}
              polarity_ptr1 := x_polarity_ptr;
              density_ptr1 := x_density_ptr;
              point_ptr1 := x_point_ptr;

              x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
                polarity_array_ptr^.multiplier1);
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
                  factor := (volume_ptr^.threshold - density1) / (density2 -
                    density1);
                  vector := Vector_sum(Vector_scale(point_ptr1^, 1 - factor),
                    Vector_scale(point_ptr2^, factor));
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  x_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {***********************}
                  { no new vertex created }
                  {***********************}
                  x_vertex_ptr^ := 0;
                end;

              x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
                vertex_array_ptr^.multiplier1);
            end;

          {****************}
          { go to next row }
          {****************}
          z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
            polarity_array_ptr^.multiplier3);
          z_density_ptr := density_ptr_type(longint(z_density_ptr) +
            density_array_ptr^.multiplier3);
          z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
            vertex_array_ptr^.multiplier2);
          z_point_ptr := vector_ptr_type(longint(z_point_ptr) +
            point_array_ptr^.multiplier3);
        end;

      {********************************}
      { make vertical lattice vertices }
      {********************************}

      x_polarity_ptr := polarity_array_ptr^.polarity_ptr;
      x_density_ptr := density_array_ptr^.density_ptr;
      x_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
      x_point_ptr := point_array_ptr^.point_ptr;

      {**********************}
      { go to correct length }
      {**********************}
      x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
        polarity_array_ptr^.multiplier2 * (width - 1));
      x_density_ptr := density_ptr_type(longint(x_density_ptr) +
        density_array_ptr^.multiplier2 * (width - 1));
      x_point_ptr := vector_ptr_type(longint(x_point_ptr) +
        point_array_ptr^.multiplier2 * (width - 1));
      x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
        vertex_array_ptr^.multiplier3 * 2);

      for x_counter := 1 to vertex_array_ptr^.length do
        begin

          {****************}
          { start next row }
          {****************}
          z_polarity_ptr := x_polarity_ptr;
          z_density_ptr := x_density_ptr;
          z_vertex_ptr := x_vertex_ptr;
          z_point_ptr := x_point_ptr;

          for z_counter := 0 to (vertex_array_ptr^.width - 2) do
            begin

              {*******************}
              { go to next column }
              {*******************}
              polarity_ptr1 := z_polarity_ptr;
              density_ptr1 := z_density_ptr;
              point_ptr1 := z_point_ptr;

              z_polarity_ptr := polarity_ptr_type(longint(z_polarity_ptr) +
                polarity_array_ptr^.multiplier3);
              z_density_ptr := density_ptr_type(longint(z_density_ptr) +
                density_array_ptr^.multiplier3);
              z_point_ptr := vector_ptr_type(longint(z_point_ptr) +
                point_array_ptr^.multiplier3);

              polarity_ptr2 := z_polarity_ptr;
              density_ptr2 := z_density_ptr;
              point_ptr2 := z_point_ptr;

              if (polarity_ptr1^ <> polarity_ptr2^) then
                begin
                  {********************}
                  { compute new vertex }
                  {********************}
                  density1 := density_ptr1^;
                  density2 := density_ptr2^;
                  factor := (volume_ptr^.threshold - density1) / (density2 -
                    density1);
                  vector := Vector_sum(Vector_scale(point_ptr1^, 1 - factor),
                    Vector_scale(point_ptr2^, factor));
                  Add_mesh_vertex(mesh_ptr, vector, zero_vector, vector);
                  vertex_counter := vertex_counter + 1;
                  z_vertex_ptr^ := vertex_counter;
                end
              else
                begin
                  {***********************}
                  { no new vertex created }
                  {***********************}
                  z_vertex_ptr^ := 0;
                end;

              z_vertex_ptr := vertex_index_ptr_type(longint(z_vertex_ptr) +
                vertex_array_ptr^.multiplier2);
            end;

          {****************}
          { go to next row }
          {****************}
          x_polarity_ptr := polarity_ptr_type(longint(x_polarity_ptr) +
            polarity_array_ptr^.multiplier1);
          x_density_ptr := density_ptr_type(longint(x_density_ptr) +
            density_array_ptr^.multiplier1);
          x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
            vertex_array_ptr^.multiplier1);
          x_point_ptr := vector_ptr_type(longint(x_point_ptr) +
            point_array_ptr^.multiplier1);
        end;
    end;

end; {procedure Make_xz_lattice}


{****************************************}
{ routines to write vertex array structs }
{****************************************}


procedure Write_vertex_array(vertex_array_ptr: vertex_array_ptr_type);
var
  x_counter, y_counter: integer;
  x_vertex_ptr, y_vertex_ptr: vertex_index_ptr_type;
begin
  with vertex_array_ptr^ do
    writeln('vertex array(', length: 1, ' x ', width: 1, '):');

  writeln('grid vertices:');
  y_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  for y_counter := 1 to vertex_array_ptr^.width do
    begin
      x_vertex_ptr := y_vertex_ptr;
      for x_counter := 1 to vertex_array_ptr^.length do
        begin
          writeln('vertex(', x_counter: 1, ' ', y_counter: 1, ') = ',
            x_vertex_ptr^);
          x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
            vertex_array_ptr^.multiplier1);
        end;
      y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
        vertex_array_ptr^.multiplier2);
    end;

  writeln('horizontal lattice vertices:');
  y_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
    vertex_array_ptr^.multiplier3);
  for y_counter := 1 to vertex_array_ptr^.width do
    begin
      x_vertex_ptr := y_vertex_ptr;
      for x_counter := 1 to (vertex_array_ptr^.length - 1) do
        begin
          writeln('vertex(', x_counter: 1, ' ', y_counter: 1, ') = ',
            x_vertex_ptr^);
          x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
            vertex_array_ptr^.multiplier1);
        end;
      y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
        vertex_array_ptr^.multiplier2);
    end;

  writeln('vertical lattice vertices:');
  y_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
    vertex_array_ptr^.multiplier3 * 2);
  for y_counter := 1 to (vertex_array_ptr^.width - 1) do
    begin
      x_vertex_ptr := y_vertex_ptr;
      for x_counter := 1 to vertex_array_ptr^.length do
        begin
          writeln('vertex(', x_counter: 1, ' ', y_counter: 1, ') = ',
            x_vertex_ptr^);
          x_vertex_ptr := vertex_index_ptr_type(longint(x_vertex_ptr) +
            vertex_array_ptr^.multiplier1);
        end;
      y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
        vertex_array_ptr^.multiplier2);
    end;

end; {procedure Write_vertex_array}


initialization
  vertex_array_free_list := nil;
end.
