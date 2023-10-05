unit isofaces;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              isofaces                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module builds the faces of the polygonal data      }
{       structures for the volume objects. These are then       }
{       used to construct the b rep.                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface


uses
  polymeshes, volumes, isosurfaces, isovertices, isoedges;


{******************************}
{ make capping faces of volume }
{******************************}
procedure Make_xy_faces(mesh_ptr: mesh_ptr_type;
  orientation: boolean;
  height: integer;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type;
  lattice_ptr: lattice_ptr_type);
procedure Make_yz_faces(mesh_ptr: mesh_ptr_type;
  orientation: boolean;
  length: integer;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type;
  lattice_ptr: lattice_ptr_type);
procedure Make_xz_faces(mesh_ptr: mesh_ptr_type;
  orientation: boolean;
  width: integer;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type;
  lattice_ptr: lattice_ptr_type);


implementation


const
  {**********************************************}
  { If the isosurface shares vertices with the   }
  { capping faces, then surface will be smoothed }
  { at the junction.                             }
  {**********************************************}
  share_vertices = false;
  memory_alert = false;


type
  {************************************}
  { types used to create capping faces }
  {************************************}
  vertex_offset_type = array[0..4] of longint;
  edge_offset_type = array[0..4] of longint;
  face_vertex_array_type = array[0..4] of vertex_index_type;
  face_edge_array_type = array[0..4] of edge_index_type;


var
  {****************************************}
  { arrays used to construct capping faces }
  {****************************************}
  vertex_offset: vertex_offset_type;
  edge_offset: edge_offset_type;
  face_offset: vertex_offset_type;
  cap_offset: vertex_offset_type;


procedure Init_offsets;
var
  counter: integer;
begin
  for counter := 0 to 4 do
    begin
      vertex_offset[counter] := 0;
      edge_offset[counter] := 0;
      face_offset[counter] := 0;
      cap_offset[counter] := 0;
    end;
end; {procedure Init_offsets}


  {***************}
  { capping faces }
  {***************}


procedure Make_capping_face(mesh_ptr: mesh_ptr_type;
  orientation: boolean;
  vertex_ptr: vertex_index_ptr_type;
  edge_ptr: edge_index_ptr_type;
  vertex_index_ptr: vertex_index_ptr_type);
var
  vertex_index: face_vertex_array_type;
  edge_index: face_edge_array_type;
  lattice_index: face_vertex_array_type;
  done, found: boolean;
  start_index, counter: integer;
  index1, index2: integer;
  vertex, vertex1, vertex2: integer;
begin
  vertex_index[0] := vertex_index_ptr_type(longint(vertex_ptr) +
    vertex_offset[0])^;
  vertex_index[1] := vertex_index_ptr_type(longint(vertex_ptr) +
    vertex_offset[1])^;
  vertex_index[2] := vertex_index_ptr_type(longint(vertex_ptr) +
    vertex_offset[2])^;
  vertex_index[3] := vertex_index_ptr_type(longint(vertex_ptr) +
    vertex_offset[3])^;

  {**********************}
  { find starting vertex }
  {**********************}
  start_index := 0;
  done := false;
  found := false;
  while not (done or found) do
    begin
      if vertex_index[start_index] <> 0 then
        found := true
      else if start_index = 3 then
        done := true
      else
        start_index := start_index + 1;
    end;

  if found then
    begin
      {*****************}
      { create new face }
      {*****************}
      Add_mesh_face(mesh_ptr, orientation);

      edge_index[0] := edge_index_ptr_type(longint(edge_ptr) + edge_offset[0])^;
      edge_index[1] := edge_index_ptr_type(longint(edge_ptr) + edge_offset[1])^;
      edge_index[2] := -edge_index_ptr_type(longint(edge_ptr) +
        edge_offset[2])^;
      edge_index[3] := -edge_index_ptr_type(longint(edge_ptr) +
        edge_offset[3])^;

      if share_vertices then
        begin
          lattice_index[0] := vertex_index_ptr_type(longint(vertex_index_ptr) +
            face_offset[0])^;
          lattice_index[1] := vertex_index_ptr_type(longint(vertex_index_ptr) +
            face_offset[1])^;
          lattice_index[2] := vertex_index_ptr_type(longint(vertex_index_ptr) +
            face_offset[2])^;
          lattice_index[3] := vertex_index_ptr_type(longint(vertex_index_ptr) +
            face_offset[3])^;
        end
      else
        begin
          lattice_index[0] := vertex_index_ptr_type(longint(vertex_ptr) +
            cap_offset[0])^;
          lattice_index[1] := vertex_index_ptr_type(longint(vertex_ptr) +
            cap_offset[1])^;
          lattice_index[2] := vertex_index_ptr_type(longint(vertex_ptr) +
            cap_offset[2])^;
          lattice_index[3] := vertex_index_ptr_type(longint(vertex_ptr) +
            cap_offset[3])^;
        end;

      vertex := 0;
      for counter := 0 to 3 do
        begin
          index1 := (start_index + counter) mod 4;
          index2 := (start_index + counter + 1) mod 4;

          vertex1 := vertex_index[index1];
          vertex2 := vertex_index[index2];

          if (vertex1 <> 0) then
            begin
              if (vertex2 <> 0) then
                begin
                  {*********************************}
                  { both vertices are inside volume }
                  {*********************************}
                  Add_mesh_edge_index(mesh_ptr, edge_index[index1]);
                end
              else
                begin
                  {**********************************************}
                  { vertex1 is inside volume, vertex2 is outside }
                  {**********************************************}
                  Add_mesh_edge_index(mesh_ptr, edge_index[index1]);
                  vertex := lattice_index[index1];
                end;
            end
          else
            begin
              if (vertex2 <> 0) then
                begin
                  {**********************************************}
                  { vertex1 is outside volume, vertex2 is inside }
                  {**********************************************}
                  vertex2 := lattice_index[index1];
                  Add_mesh_edge(mesh_ptr, vertex, vertex2);
                  edge_counter := edge_counter + 1;
                  Add_mesh_edge_index(mesh_ptr, edge_counter);
                  Add_mesh_edge_index(mesh_ptr, edge_index[index1]);
                end
              else
                begin
                  {**********************************}
                  { both vertices are outside volume }
                  {**********************************}
                end;
            end;

        end;
    end;
end; {procedure Make_capping_face}


procedure Make_xy_faces(mesh_ptr: mesh_ptr_type;
  orientation: boolean;
  height: integer;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type;
  lattice_ptr: lattice_ptr_type);
var
  x_counter, y_counter: integer;
  x_vertex_ptr, y_vertex_ptr: vertex_index_ptr_type;
  x_edge_ptr, y_edge_ptr: edge_index_ptr_type;
  x_index_ptr, y_index_ptr: vertex_index_ptr_type;
  vertex_index_ptr: vertex_index_ptr_type;
begin
  {**********************}
  { go to correct height }
  {**********************}
  vertex_index_ptr := lattice_ptr^.vertex_index_ptr;
  vertex_index_ptr := vertex_index_ptr_type(longint(vertex_index_ptr) +
    (lattice_ptr^.multiplier3 * (height - 1)));

  {*********************************************}
  { compute offsets for navigating vertex array }
  {*********************************************}
  with vertex_array_ptr^ do
    begin
      vertex_offset[0] := 0;
      vertex_offset[1] := multiplier1;
      vertex_offset[2] := multiplier1 + multiplier2;
      vertex_offset[3] := multiplier2;
    end;

  {*******************************************}
  { compute offsets for navigating edge array }
  {*******************************************}
  with edge_array_ptr^ do
    begin
      edge_offset[0] := 0;
      edge_offset[1] := multiplier1 + multiplier3;
      edge_offset[2] := multiplier2;
      edge_offset[3] := multiplier3;
    end;

  if share_vertices then
    begin
      {****************************************}
      { compute offsets for navigating lattice }
      {****************************************}
      with lattice_ptr^ do
        begin
          face_offset[0] := 0;
          face_offset[1] := multiplier4 + multiplier1;
          face_offset[2] := multiplier2;
          face_offset[3] := multiplier4;
        end;
    end
  else
    begin
      {*********************************************}
      { compute offsets for navigating vertex array }
      {*********************************************}
      with vertex_array_ptr^ do
        begin
          cap_offset[0] := multiplier3;
          cap_offset[1] := multiplier1 + (multiplier3 * 2);
          cap_offset[2] := multiplier2 + multiplier3;
          cap_offset[3] := (multiplier3 * 2);
        end;
    end;

  y_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  y_edge_ptr := edge_array_ptr^.edge_index_ptr;
  y_index_ptr := vertex_index_ptr;

  for y_counter := 1 to (edge_array_ptr^.width - 1) do
    begin

      {****************}
      { start next row }
      {****************}
      x_vertex_ptr := y_vertex_ptr;
      x_edge_ptr := y_edge_ptr;
      x_index_ptr := y_index_ptr;

      for x_counter := 1 to (edge_array_ptr^.length - 1) do
        begin
          Make_capping_face(mesh_ptr, orientation, x_vertex_ptr, x_edge_ptr,
            x_index_ptr);

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
end; {procedure Make_xy_faces}


procedure Make_yz_faces(mesh_ptr: mesh_ptr_type;
  orientation: boolean;
  length: integer;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type;
  lattice_ptr: lattice_ptr_type);
var
  y_counter, z_counter: integer;
  y_vertex_ptr, z_vertex_ptr: vertex_index_ptr_type;
  y_edge_ptr, z_edge_ptr: edge_index_ptr_type;
  y_index_ptr, z_index_ptr: vertex_index_ptr_type;
  vertex_index_ptr: vertex_index_ptr_type;
begin
  {**********************}
  { go to correct length }
  {**********************}
  vertex_index_ptr := lattice_ptr^.vertex_index_ptr;
  vertex_index_ptr := vertex_index_ptr_type(longint(vertex_index_ptr) +
    (lattice_ptr^.multiplier1 * (length - 1)));

  {*********************************************}
  { compute offsets for navigating vertex array }
  {*********************************************}
  with vertex_array_ptr^ do
    begin
      vertex_offset[0] := 0;
      vertex_offset[1] := multiplier1;
      vertex_offset[2] := multiplier1 + multiplier2;
      vertex_offset[3] := multiplier2;
    end;

  {*******************************************}
  { compute offsets for navigating edge array }
  {*******************************************}
  with edge_array_ptr^ do
    begin
      edge_offset[0] := 0;
      edge_offset[1] := multiplier1 + multiplier3;
      edge_offset[2] := multiplier2;
      edge_offset[3] := multiplier3;
    end;

  if share_vertices then
    begin
      {****************************************}
      { compute offsets for navigating lattice }
      {****************************************}
      with lattice_ptr^ do
        begin
          face_offset[0] := multiplier4;
          face_offset[1] := (multiplier4 * 2) + multiplier2;
          face_offset[2] := multiplier4 + multiplier3;
          face_offset[3] := (multiplier4 * 2);
        end;
    end
  else
    begin
      {*********************************************}
      { compute offsets for navigating vertex array }
      {*********************************************}
      with vertex_array_ptr^ do
        begin
          cap_offset[0] := multiplier3;
          cap_offset[1] := multiplier1 + (multiplier3 * 2);
          cap_offset[2] := multiplier2 + multiplier3;
          cap_offset[3] := (multiplier3 * 2);
        end;
    end;

  z_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  z_edge_ptr := edge_array_ptr^.edge_index_ptr;
  z_index_ptr := vertex_index_ptr;

  for z_counter := 1 to (edge_array_ptr^.width - 1) do
    begin

      {****************}
      { start next row }
      {****************}
      y_vertex_ptr := z_vertex_ptr;
      y_edge_ptr := z_edge_ptr;
      y_index_ptr := z_index_ptr;

      for y_counter := 1 to (edge_array_ptr^.length - 1) do
        begin
          Make_capping_face(mesh_ptr, orientation, y_vertex_ptr, y_edge_ptr,
            y_index_ptr);

          {*******************}
          { go to next column }
          {*******************}
          y_vertex_ptr := vertex_index_ptr_type(longint(y_vertex_ptr) +
            vertex_array_ptr^.multiplier1);
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
end; {procedure Make_yz_faces}


procedure Make_xz_faces(mesh_ptr: mesh_ptr_type;
  orientation: boolean;
  width: integer;
  edge_array_ptr: edge_array_ptr_type;
  vertex_array_ptr: vertex_array_ptr_type;
  lattice_ptr: lattice_ptr_type);
var
  x_counter, z_counter: integer;
  x_vertex_ptr, z_vertex_ptr: vertex_index_ptr_type;
  x_edge_ptr, z_edge_ptr: edge_index_ptr_type;
  x_index_ptr, z_index_ptr: vertex_index_ptr_type;
  vertex_index_ptr: vertex_index_ptr_type;
begin
  {*********************}
  { go to correct width }
  {*********************}
  vertex_index_ptr := lattice_ptr^.vertex_index_ptr;
  vertex_index_ptr := vertex_index_ptr_type(longint(vertex_index_ptr) +
    (lattice_ptr^.multiplier2 * (width - 1)));

  {*********************************************}
  { compute offsets for navigating vertex array }
  {*********************************************}
  with vertex_array_ptr^ do
    begin
      vertex_offset[0] := 0;
      vertex_offset[1] := multiplier1;
      vertex_offset[2] := multiplier1 + multiplier2;
      vertex_offset[3] := multiplier2;
    end;

  {*******************************************}
  { compute offsets for navigating edge array }
  {*******************************************}
  with edge_array_ptr^ do
    begin
      edge_offset[0] := 0;
      edge_offset[1] := multiplier1 + multiplier3;
      edge_offset[2] := multiplier2;
      edge_offset[3] := multiplier3;
    end;

  if share_vertices then
    begin
      {****************************************}
      { compute offsets for navigating lattice }
      {****************************************}
      with lattice_ptr^ do
        begin
          face_offset[0] := 0;
          face_offset[1] := (multiplier4 * 2) + multiplier1;
          face_offset[2] := multiplier3;
          face_offset[3] := (multiplier4 * 2);
        end;
    end
  else
    begin
      {*********************************************}
      { compute offsets for navigating vertex array }
      {*********************************************}
      with vertex_array_ptr^ do
        begin
          cap_offset[0] := multiplier3;
          cap_offset[1] := multiplier1 + (multiplier3 * 2);
          cap_offset[2] := multiplier2 + multiplier3;
          cap_offset[3] := (multiplier3 * 2);
        end;
    end;

  z_vertex_ptr := vertex_array_ptr^.vertex_index_ptr;
  z_edge_ptr := edge_array_ptr^.edge_index_ptr;
  z_index_ptr := vertex_index_ptr;

  for z_counter := 1 to (edge_array_ptr^.width - 1) do
    begin

      {****************}
      { start next row }
      {****************}
      x_vertex_ptr := z_vertex_ptr;
      x_edge_ptr := z_edge_ptr;
      x_index_ptr := z_index_ptr;

      for x_counter := 1 to (edge_array_ptr^.length - 1) do
        begin
          Make_capping_face(mesh_ptr, orientation, x_vertex_ptr, x_edge_ptr,
            x_index_ptr);

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
end; {procedure Make_xz_faces}


initialization
  Init_offsets;
end.
