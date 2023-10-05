unit isomeshes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             isomeshes                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module builds the polygonal data structures for    }
{       the volume (isosurface) objects. These are then used    }
{       to construct the b rep.                                 }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface


uses
  polymeshes, volumes;


{***********************************}
{ routines for tessellating volumes }
{***********************************}
function Volume_to_mesh(volume_ptr: volume_ptr_type): mesh_ptr_type;


implementation
uses
  cubes, isosurfaces, isovertices, isoedges, isofaces;


const
  {**********************************************}
  { If the isosurface shares vertices with the   }
  { capping faces, then surface will be smoothed }
  { at the junction.                             }
  {**********************************************}
  share_vertices = false;
  memory_alert = false;


procedure Make_capping_faces(mesh_ptr: mesh_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  lattice_ptr: lattice_ptr_type;
  volume_ptr: volume_ptr_type);
var
  vertex_array_ptr: vertex_array_ptr_type;
  edge_array_ptr: edge_array_ptr_type;
  length, width, height: integer;
begin
  length := polarity_array_ptr^.length;
  width := polarity_array_ptr^.width;
  height := polarity_array_ptr^.height;

  {******************************}
  { smooth joints between        }
  { isosurface and capping face  }
  {******************************}

  if share_vertices then
    begin
      {**********************}
      { bottom and top faces }
      {**********************}
      vertex_array_ptr := New_vertex_array(length, width, 2);
      edge_array_ptr := New_edge_array(length, width, 2);

      Make_xy_vertices(mesh_ptr, -1.0, 1, vertex_array_ptr, polarity_array_ptr,
        volume_ptr);
      Make_xy_lattice_edges(mesh_ptr, 1, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);
      Make_xy_faces(mesh_ptr, false, 1, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);
      Make_xy_vertices(mesh_ptr, 1.0, height, vertex_array_ptr,
        polarity_array_ptr, volume_ptr);
      Make_xy_lattice_edges(mesh_ptr, height, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);
      Make_xy_faces(mesh_ptr, true, height, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);

      Free_vertex_array(vertex_array_ptr);
      Free_edge_array(edge_array_ptr);

      {**********************}
      { left and right faces }
      {**********************}
      vertex_array_ptr := New_vertex_array(width, height, 2);
      edge_array_ptr := New_edge_array(width, height, 2);

      Make_yz_vertices(mesh_ptr, -1.0, 1, vertex_array_ptr, polarity_array_ptr,
        volume_ptr);
      Make_yz_lattice_edges(mesh_ptr, 1, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);
      Make_yz_faces(mesh_ptr, true, 1, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);
      Make_yz_vertices(mesh_ptr, 1.0, length, vertex_array_ptr,
        polarity_array_ptr, volume_ptr);
      Make_yz_lattice_edges(mesh_ptr, length, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);
      Make_yz_faces(mesh_ptr, false, length, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);

      Free_vertex_array(vertex_array_ptr);
      Free_edge_array(edge_array_ptr);

      {**********************}
      { front and back faces }
      {**********************}
      vertex_array_ptr := New_vertex_array(length, height, 2);
      edge_array_ptr := New_edge_array(length, height, 2);

      Make_xz_vertices(mesh_ptr, -1.0, 1, vertex_array_ptr, polarity_array_ptr,
        volume_ptr);
      Make_xz_lattice_edges(mesh_ptr, 1, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);
      Make_xz_faces(mesh_ptr, false, 1, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);
      Make_xz_vertices(mesh_ptr, 1.0, width, vertex_array_ptr,
        polarity_array_ptr, volume_ptr);
      Make_xz_lattice_edges(mesh_ptr, width, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);
      Make_xz_faces(mesh_ptr, true, width, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);

      Free_vertex_array(vertex_array_ptr);
      Free_edge_array(edge_array_ptr);
    end

      {******************************}
      { don't smooth joints between  }
      { isosurface and capping faces }
      {******************************}

  else
    begin
      {**********************}
      { bottom and top faces }
      {**********************}
      vertex_array_ptr := New_vertex_array(length, width, 3);
      edge_array_ptr := New_edge_array(length, width, 2);

      Make_xy_vertices(mesh_ptr, -1.0, 1, vertex_array_ptr, polarity_array_ptr,
        volume_ptr);
      Make_xy_lattice(mesh_ptr, -1.0, 1, vertex_array_ptr, polarity_array_ptr,
        volume_ptr);
      Make_xy_edges(mesh_ptr, edge_array_ptr, vertex_array_ptr);
      Make_xy_faces(mesh_ptr, false, 1, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);
      Make_xy_vertices(mesh_ptr, 1.0, height, vertex_array_ptr,
        polarity_array_ptr, volume_ptr);
      Make_xy_lattice(mesh_ptr, 1.0, height, vertex_array_ptr,
        polarity_array_ptr, volume_ptr);
      Make_xy_edges(mesh_ptr, edge_array_ptr, vertex_array_ptr);
      Make_xy_faces(mesh_ptr, true, height, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);

      Free_vertex_array(vertex_array_ptr);
      Free_edge_array(edge_array_ptr);

      {**********************}
      { front and back faces }
      {**********************}
      vertex_array_ptr := New_vertex_array(length, height, 3);
      edge_array_ptr := New_edge_array(length, height, 2);

      Make_xz_vertices(mesh_ptr, -1.0, 1, vertex_array_ptr, polarity_array_ptr,
        volume_ptr);
      Make_xz_lattice(mesh_ptr, -1.0, 1, vertex_array_ptr, polarity_array_ptr,
        volume_ptr);
      Make_xz_edges(mesh_ptr, edge_array_ptr, vertex_array_ptr);
      Make_xz_faces(mesh_ptr, true, 1, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);
      Make_xz_vertices(mesh_ptr, 1.0, width, vertex_array_ptr,
        polarity_array_ptr, volume_ptr);
      Make_xz_lattice(mesh_ptr, 1.0, width, vertex_array_ptr,
        polarity_array_ptr, volume_ptr);
      Make_xz_edges(mesh_ptr, edge_array_ptr, vertex_array_ptr);
      Make_xz_faces(mesh_ptr, false, width, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);

      Free_vertex_array(vertex_array_ptr);
      Free_edge_array(edge_array_ptr);

      {**********************}
      { left and right faces }
      {**********************}
      vertex_array_ptr := New_vertex_array(width, height, 3);
      edge_array_ptr := New_edge_array(width, height, 2);

      Make_yz_vertices(mesh_ptr, -1.0, 1, vertex_array_ptr, polarity_array_ptr,
        volume_ptr);
      Make_yz_lattice(mesh_ptr, -1.0, 1, vertex_array_ptr, polarity_array_ptr,
        volume_ptr);
      Make_yz_edges(mesh_ptr, edge_array_ptr, vertex_array_ptr);
      Make_yz_faces(mesh_ptr, false, 1, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);
      Make_yz_vertices(mesh_ptr, 1.0, length, vertex_array_ptr,
        polarity_array_ptr, volume_ptr);
      Make_yz_lattice(mesh_ptr, 1.0, length, vertex_array_ptr,
        polarity_array_ptr, volume_ptr);
      Make_yz_edges(mesh_ptr, edge_array_ptr, vertex_array_ptr);
      Make_yz_faces(mesh_ptr, true, length, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);

      Free_vertex_array(vertex_array_ptr);
      Free_edge_array(edge_array_ptr);
    end;
end; {procedure Make_capping_faces}


procedure Make_isogon(mesh_ptr: mesh_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  lattice_ptr: lattice_ptr_type;
  volume_ptr: volume_ptr_type);
var
  vertex_array_ptr: vertex_array_ptr_type;
  edge_array_ptr: edge_array_ptr_type;
  length, width, height: integer;
begin
  length := polarity_array_ptr^.length;
  width := polarity_array_ptr^.width;
  height := polarity_array_ptr^.height;

  if (length = 1) then
    begin
      {*******************}
      { left / right face }
      {*******************}
      vertex_array_ptr := New_vertex_array(width, height, 3);
      edge_array_ptr := New_edge_array(width, height, 2);

      Make_yz_vertices(mesh_ptr, 0.0, 1, vertex_array_ptr, polarity_array_ptr,
        volume_ptr);
      Make_yz_lattice(mesh_ptr, 0.0, 1, vertex_array_ptr, polarity_array_ptr,
        volume_ptr);
      Make_yz_edges(mesh_ptr, edge_array_ptr, vertex_array_ptr);
      Make_yz_faces(mesh_ptr, true, 1, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);

      Free_vertex_array(vertex_array_ptr);
      Free_edge_array(edge_array_ptr);
    end

  else if (width = 1) then
    begin
      {*******************}
      { front / back face }
      {*******************}
      vertex_array_ptr := New_vertex_array(length, height, 3);
      edge_array_ptr := New_edge_array(length, height, 2);

      Make_xz_vertices(mesh_ptr, 0.0, 1, vertex_array_ptr, polarity_array_ptr,
        volume_ptr);
      Make_xz_lattice(mesh_ptr, 0.0, 1, vertex_array_ptr, polarity_array_ptr,
        volume_ptr);
      Make_xz_edges(mesh_ptr, edge_array_ptr, vertex_array_ptr);
      Make_xz_faces(mesh_ptr, true, 1, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);

      Free_vertex_array(vertex_array_ptr);
      Free_edge_array(edge_array_ptr);
    end

  else if (height = 1) then
    begin
      {*******************}
      { bottom / top face }
      {*******************}
      vertex_array_ptr := New_vertex_array(length, width, 3);
      edge_array_ptr := New_edge_array(length, width, 2);

      Make_xy_vertices(mesh_ptr, 0.0, 1, vertex_array_ptr, polarity_array_ptr,
        volume_ptr);
      Make_xy_lattice(mesh_ptr, 0.0, 1, vertex_array_ptr, polarity_array_ptr,
        volume_ptr);
      Make_xy_edges(mesh_ptr, edge_array_ptr, vertex_array_ptr);
      Make_xy_faces(mesh_ptr, true, 1, edge_array_ptr, vertex_array_ptr,
        lattice_ptr);

      Free_vertex_array(vertex_array_ptr);
      Free_edge_array(edge_array_ptr);
    end;
end; {procedure Make_isogon}


function Volume_to_mesh(volume_ptr: volume_ptr_type): mesh_ptr_type;
var
  length, width, height: integer;
  mesh_ptr: mesh_ptr_type;
  polarity_array_ptr: polarity_array_ptr_type;
  lattice_ptr: lattice_ptr_type;
begin
  {*****************}
  { create new mesh }
  {*****************}
  mesh_ptr := New_mesh;

  if (volume_ptr <> nil) then
    if (volume_ptr^.density_array_ptr <> nil) then
      begin
        length := volume_ptr^.density_array_ptr^.length;
        width := volume_ptr^.density_array_ptr^.width;
        height := volume_ptr^.density_array_ptr^.height;

        vertex_counter := 0;
        edge_counter := 0;
        face_counter := 0;

        {***********************}
        { create polarity array }
        {***********************}
        {write('making polarity array...');}
        polarity_array_ptr := New_polarity_array(length, width, height);
        Make_volume_polarity(volume_ptr, polarity_array_ptr);
        {writeln('done.');}

        {*****************}
        { create vertices }
        {*****************}
        lattice_ptr := New_lattice(length, width, height, 3);
        {write('making vertices...');}
        Make_volume_vertices(volume_ptr, mesh_ptr, polarity_array_ptr,
          lattice_ptr);
        {writeln('done.');}
        {writeln(vertex_counter : 1, ' vertices created');}

        if (length > 1) and (width > 1) and (height > 1) then
          begin
            {***********************************************}
            { initialize voxel tessellations, if neccessary }
            {***********************************************}
            Make_cubes;

            {*******************}
            { tessellate voxels }
            {*******************}
            {write('making faces...');}
            Make_volume_faces(mesh_ptr, polarity_array_ptr, lattice_ptr);
            {writeln('done.');}
            {writeln(edge_counter : 1, ' edges created');}
            {writeln(face_counter : 1, ' faces created');}

            if volume_ptr^.capping then
              begin
                {write('making capping faces...');}
                Make_capping_faces(mesh_ptr, polarity_array_ptr, lattice_ptr,
                  volume_ptr);
                {writeln('done.');}
              end;
          end
        else
          begin
            {**********************}
            { isolines and isogons }
            {**********************}
            if volume_ptr^.capping then
              Make_isogon(mesh_ptr, polarity_array_ptr, lattice_ptr,
                volume_ptr);
          end;

        {******************************}
        { free auxilliary data structs }
        {******************************}
        Free_polarity_array(polarity_array_ptr);
        Free_lattice(lattice_ptr);
      end;

  Volume_to_mesh := mesh_ptr;
end; {function Volume_to_mesh}


end.
