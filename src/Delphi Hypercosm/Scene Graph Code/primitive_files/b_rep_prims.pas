unit b_rep_prims;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            b_rep_prims                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The b_rep_prims module builds the b_rep data            }
{       structures for the primitive objects.                   }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


{***************************************************************}
{       These routines return b_rep surfaces of primitives      }
{       that are aligned with thier axis oriented along the     }
{       z axis and scaled so that they fit inside a unit cube.  }
{       (-1 to 1) on x, y, and z.                               }
{***************************************************************}


interface
uses
  vectors, b_rep, polygons, polymeshes, volumes;


procedure Free_faceted_b_reps;

{*******************}
{ planar primitives }
{*******************}
function Plane_b_rep: surface_ptr_type;
function Disk_b_rep(umin, umax: real): surface_ptr_type;
function Ring_b_rep(inner_radius: real;
  umin, umax: real): surface_ptr_type;
function Triangle_b_rep: surface_ptr_type;
function Parallelogram_b_rep: surface_ptr_type;
function Polygon_b_rep(polygon_ptr: polygon_ptr_type): surface_ptr_type;

{***********************}
{ non-planar primitives }
{***********************}
function Torus_b_rep(inner_radius: real;
  umin, umax: real;
  vmin, vmax: real): surface_ptr_type;
function Block_b_rep: surface_ptr_type;
function Shaded_triangle_b_rep(normal1, normal2, normal3: vector_type):
  surface_ptr_type;
function Shaded_polygon_b_rep(shaded_polygon_ptr: shaded_polygon_ptr_type):
  surface_ptr_type;
function Mesh_b_rep(mesh_ptr: mesh_ptr_type;
  smoothing, mending, closed, checking: boolean): surface_ptr_type;
function Blob_b_rep(metaball_ptr: metaball_ptr_type;
  threshold: real;
  dimensions: vector_type): surface_ptr_type;

{************************}
{ non-surface primitives }
{************************}
function Point_b_rep(points_ptr: points_ptr_type): surface_ptr_type;
function Line_b_rep(lines_ptr: lines_ptr_type): surface_ptr_type;
function Volume_b_rep(volume_ptr: volume_ptr_type): surface_ptr_type;


implementation
uses
  extents, geometry, topology, make_b_rep, grid_quads, grid_prims, mesh_prims,
  meshes, b_rep_quads, isomeshes;


const
  debug = false;


  {*******************************************************}
  {                 self-similar primitives               }
  {*******************************************************}
  {       These primitives can be transformed from        }
  {       one instance to any other another instance      }
  {       with a simple linear transformation:            }
  {                                                       }
  {           disk, sphere, cylinder, paraboloid,         }
  {                plane, triangle, block,                }
  {*******************************************************}


  {*******************************************************}
  {              non self-similar primitives              }
  {*******************************************************}
  {       These primitives can not be transformed from    }
  {       one instance to any other another instance      }
  {       with a simple linear transformation:            }
  {                                                       }
  {       ring, cone, hyperboloid1, hyperboloid2, torus   }
  {                                                       }
  {       For these objects, new geometry must be         }
  {       generated for each instance. They do,           }
  {       however, share the same topology.               }
  {*******************************************************}
var
  {*************************}
  { self-similar primitives }
  {*************************}
  unit_plane_ptr, unit_block_ptr: surface_ptr_type;
  unit_triangle_ptr, unit_parallelogram_ptr: surface_ptr_type;
  unit_disk_ptr: surface_ptr_type;


  {*******************}
  { planar primitives }
  {*******************}


function Plane_b_rep: surface_ptr_type;
var
  width, height: integer;
  normal, texture: vector_type;
  u_axis, v_axis: vector_type;
begin
  if (unit_plane_ptr = nil) then
    begin
      unit_plane_ptr := New_surface(self_similar, open_surface, smooth_shading);
      unit_plane_ptr^.topology_ptr := Plane_topology;

      {***************}
      { make geometry }
      {***************}
      unit_plane_ptr^.geometry_ptr := Make_geometry;
      Grid_plane(grid_ptr);

      {*********************}
      { make point geometry }
      {*********************}
      for height := 0 to grid_ptr^.height do
        for width := 0 to grid_ptr^.width do
          Make_point_geometry(grid_ptr^.point_array_ptr^[width, height]);

      {**********************}
      { make vertex geometry }
      {**********************}
      for height := 0 to grid_ptr^.height do
        for width := 0 to grid_ptr^.width do
          begin
            normal := grid_ptr^.normal_array_ptr^[width, height];
            texture := grid_ptr^.texture_array_ptr^[width, height];
            u_axis := grid_ptr^.u_axis_array_ptr^[width, height];
            v_axis := grid_ptr^.v_axis_array_ptr^[width, height];
            Make_vertex_geometry(normal, texture, u_axis, v_axis);
          end;

      {********************}
      { make face geometry }
      {********************}
      Grid_to_face_geometry(grid_ptr);

      {*************************}
      { set mesh geometry flags }
      {*************************}
      with unit_plane_ptr^.geometry_ptr^.geometry_info do
        begin
          face_normals_avail := true;
          vertex_normals_avail := true;
          vertex_vectors_avail := true;
        end;
    end;

  Plane_b_rep := unit_plane_ptr;
end; {function Plane_b_rep}


function Disk_b_rep(umin, umax: real): surface_ptr_type;
var
  surface_ptr: surface_ptr_type;
  width, height: integer;
  normal, texture: vector_type;
  u_axis, v_axis: vector_type;
begin
  if (umin = 0) and (umax = 360) then
    begin
      {******************}
      { complete surface }
      {******************}
      if (unit_disk_ptr = nil) then
        begin
          surface_ptr := New_surface(self_similar, open_surface,
            smooth_shading);
          surface_ptr^.topology_ptr := Disk_topology;
          unit_disk_ptr := surface_ptr;

          {***************}
          { make geometry }
          {***************}
          surface_ptr^.geometry_ptr := Make_geometry;
          Grid_disk(grid_ptr, umin, umax);

          {*********************}
          { make point geometry }
          {*********************}
          Make_point_geometry(grid_ptr^.point_array_ptr^[0, 0]);
          for width := 0 to (grid_ptr^.width - 1) do
            Make_point_geometry(grid_ptr^.point_array_ptr^[width, 1]);

          {**********************}
          { make vertex geometry }
          {**********************}
          for height := 0 to grid_ptr^.height do
            for width := 0 to grid_ptr^.width do
              begin
                normal := grid_ptr^.normal_array_ptr^[width, height];
                texture := grid_ptr^.texture_array_ptr^[width, height];
                u_axis := grid_ptr^.u_axis_array_ptr^[width, height];
                v_axis := grid_ptr^.v_axis_array_ptr^[width, height];
                Make_vertex_geometry(normal, texture, u_axis, v_axis);
              end;

          {********************}
          { make face geometry }
          {********************}
          Grid_to_face_geometry(grid_ptr);
        end
      else
        surface_ptr := unit_disk_ptr;
    end
  else
    begin
      {*****************}
      { partial surface }
      {*****************}
      surface_ptr := New_surface(topo_similar, open_surface, smooth_shading);
      surface_ptr^.topology_ptr := Disk_sweep_topology;

      {***************}
      { make geometry }
      {***************}
      surface_ptr^.geometry_ptr := Make_geometry;
      Grid_disk(grid_ptr, umin, umax);

      {*********************}
      { make point geometry }
      {*********************}
      Make_point_geometry(grid_ptr^.point_array_ptr^[0, 0]);
      for width := 0 to grid_ptr^.width do
        Make_point_geometry(grid_ptr^.point_array_ptr^[width, 1]);

      {**********************}
      { make vertex geometry }
      {**********************}
      for height := 0 to grid_ptr^.height do
        for width := 0 to grid_ptr^.width do
          begin
            normal := grid_ptr^.normal_array_ptr^[width, height];
            texture := grid_ptr^.texture_array_ptr^[width, height];
            u_axis := grid_ptr^.u_axis_array_ptr^[width, height];
            v_axis := grid_ptr^.v_axis_array_ptr^[width, height];
            Make_vertex_geometry(normal, texture, u_axis, v_axis);
          end;

      {********************}
      { make face geometry }
      {********************}
      Grid_to_face_geometry(grid_ptr);
    end;

  {*************************}
  { set mesh geometry flags }
  {*************************}
  with surface_ptr^.geometry_ptr^.geometry_info do
    begin
      face_normals_avail := true;
      vertex_normals_avail := true;
      vertex_vectors_avail := true;
    end;

  Disk_b_rep := surface_ptr;
end; {function Disk_b_rep}


function Ring_b_rep(inner_radius: real;
  umin, umax: real): surface_ptr_type;
var
  surface_ptr: surface_ptr_type;
  width, height: integer;
  normal, texture: vector_type;
  u_axis, v_axis: vector_type;
begin
  if (umin = 0) and (umax = 360) then
    begin
      {******************}
      { complete surface }
      {******************}
      surface_ptr := New_surface(topo_similar, open_surface, smooth_shading);
      surface_ptr^.topology_ptr := Ring_topology;

      {***************}
      { make geometry }
      {***************}
      surface_ptr^.geometry_ptr := Make_geometry;
      Grid_ring(grid_ptr, inner_radius, umin, umax);

      {*********************}
      { make point geometry }
      {*********************}
      for height := 0 to grid_ptr^.height do
        for width := 0 to (grid_ptr^.width - 1) do
          Make_point_geometry(grid_ptr^.point_array_ptr^[width, height]);

      {**********************}
      { make vertex geometry }
      {**********************}
      for height := 0 to grid_ptr^.height do
        for width := 0 to grid_ptr^.width do
          begin
            normal := grid_ptr^.normal_array_ptr^[width, height];
            texture := grid_ptr^.texture_array_ptr^[width, height];
            u_axis := grid_ptr^.u_axis_array_ptr^[width, height];
            v_axis := grid_ptr^.v_axis_array_ptr^[width, height];
            Make_vertex_geometry(normal, texture, u_axis, v_axis);
          end;

      {********************}
      { make face geometry }
      {********************}
      Grid_to_face_geometry(grid_ptr);
    end
  else
    begin
      {*****************}
      { partial surface }
      {*****************}
      surface_ptr := New_surface(topo_similar, open_surface, smooth_shading);
      surface_ptr^.topology_ptr := Ring_sweep_topology;

      {***************}
      { make geometry }
      {***************}
      surface_ptr^.geometry_ptr := Make_geometry;
      Grid_ring(grid_ptr, inner_radius, umin, umax);

      {*********************}
      { make point geometry }
      {*********************}
      for height := 0 to grid_ptr^.height do
        for width := 0 to grid_ptr^.width do
          Make_point_geometry(grid_ptr^.point_array_ptr^[width, height]);

      {**********************}
      { make vertex geometry }
      {**********************}
      for height := 0 to grid_ptr^.height do
        for width := 0 to grid_ptr^.width do
          begin
            normal := grid_ptr^.normal_array_ptr^[width, height];
            texture := grid_ptr^.texture_array_ptr^[width, height];
            u_axis := grid_ptr^.u_axis_array_ptr^[width, height];
            v_axis := grid_ptr^.v_axis_array_ptr^[width, height];
            Make_vertex_geometry(normal, texture, u_axis, v_axis);
          end;

      {********************}
      { make face geometry }
      {********************}
      Grid_to_face_geometry(grid_ptr);
    end;

  {*************************}
  { set mesh geometry flags }
  {*************************}
  with surface_ptr^.geometry_ptr^.geometry_info do
    begin
      face_normals_avail := true;
      vertex_normals_avail := true;
      vertex_vectors_avail := true;
    end;

  Ring_b_rep := surface_ptr;
end; {function Ring_b_rep}


function Triangle_b_rep: surface_ptr_type;
begin
  if (unit_triangle_ptr = nil) then
    begin
      unit_triangle_ptr := New_surface(self_similar, open_surface,
        smooth_shading);
      unit_triangle_ptr^.topology_ptr := Triangle_topology;
      unit_triangle_ptr^.geometry_ptr := Make_geometry;

      {*********************}
      { make point geometry }
      {*********************}
      Make_point_geometry(To_vector(-1, -1, 0));
      Make_point_geometry(To_vector(1, -1, 0));
      Make_point_geometry(To_vector(-1, 1, 0));

      {**********************}
      { make vertex geometry }
      {**********************}
      Make_vertex_geometry(z_vector, To_vector(0, 0, 1), x_vector, y_vector);
      Make_vertex_geometry(z_vector, To_vector(1, 0, 1), x_vector, y_vector);
      Make_vertex_geometry(z_vector, To_vector(0, 1, 1), x_vector, y_vector);

      {********************}
      { make face geometry }
      {********************}
      Make_face_geometry(To_vector(0, 0, 1));

      {*************************}
      { set mesh geometry flags }
      {*************************}
      with unit_triangle_ptr^.geometry_ptr^.geometry_info do
        begin
          face_normals_avail := true;
          vertex_normals_avail := true;
          vertex_vectors_avail := true;
        end;
    end;

  Triangle_b_rep := unit_triangle_ptr;
end; {function Triangle_b_rep}


function Parallelogram_b_rep: surface_ptr_type;
begin
  if (unit_parallelogram_ptr = nil) then
    begin
      unit_parallelogram_ptr := New_surface(self_similar, open_surface,
        smooth_shading);
      unit_parallelogram_ptr^.topology_ptr := Parallelogram_topology;
      unit_parallelogram_ptr^.geometry_ptr := Make_geometry;

      {*********************}
      { make point geometry }
      {*********************}
      Make_point_geometry(To_vector(-1, -1, 0));
      Make_point_geometry(To_vector(1, -1, 0));
      Make_point_geometry(To_vector(1, 1, 0));
      Make_point_geometry(To_vector(-1, 1, 0));

      {**********************}
      { make vertex geometry }
      {**********************}
      Make_vertex_geometry(z_vector, To_vector(0, 0, 1), x_vector, y_vector);
      Make_vertex_geometry(z_vector, To_vector(1, 0, 1), x_vector, y_vector);
      Make_vertex_geometry(z_vector, To_vector(1, 1, 1), x_vector, y_vector);
      Make_vertex_geometry(z_vector, To_vector(0, 1, 1), x_vector, y_vector);

      {********************}
      { make face geometry }
      {********************}
      Make_face_geometry(To_vector(0, 0, 1));

      {*************************}
      { set mesh geometry flags }
      {*************************}
      with unit_parallelogram_ptr^.geometry_ptr^.geometry_info do
        begin
          face_normals_avail := true;
          vertex_normals_avail := true;
          vertex_vectors_avail := true;
        end;
    end;

  Parallelogram_b_rep := unit_parallelogram_ptr;
end; {function Parallelogram_b_rep}


function Polygon_b_rep(polygon_ptr: polygon_ptr_type): surface_ptr_type;
var
  surface_ptr: surface_ptr_type;
  vertex_ptr: polygon_vertex_ptr_type;
begin
  {***************}
  { make topology }
  {***************}
  with polygon_ptr^ do
    if (vertices = 3) and (next = nil) then
      begin
        surface_ptr := New_surface(topo_similar, open_surface, smooth_shading);
        surface_ptr^.topology_ptr := Triangle_topology
      end
    else if (vertices = 4) and (next = nil) then
      begin
        surface_ptr := New_surface(topo_similar, open_surface, smooth_shading);
        surface_ptr^.topology_ptr := Parallelogram_topology
      end
    else
      begin
        surface_ptr := New_surface(dissimilar, open_surface, smooth_shading);
        surface_ptr^.topology_ptr := Polygon_topology(polygon_ptr);
      end;

  {***************}
  { make geometry }
  {***************}
  surface_ptr^.geometry_ptr := Make_geometry;

  while (polygon_ptr <> nil) do
    begin
      vertex_ptr := polygon_ptr^.vertex_ptr;
      while (vertex_ptr <> nil) do
        begin
          with vertex_ptr^ do
            begin
              {*********************}
              { make point geometry }
              {*********************}
              Make_point_geometry(point);

              {**********************}
              { make vertex geometry }
              {**********************}
              Make_vertex_geometry(z_vector, texture, x_vector, y_vector);
            end;
          vertex_ptr := vertex_ptr^.next;
        end;
      polygon_ptr := polygon_ptr^.next;
    end;

  {********************}
  { make face geometry }
  {********************}
  Make_face_geometry(z_vector);

  {*************************}
  { set mesh geometry flags }
  {*************************}
  with surface_ptr^.geometry_ptr^.geometry_info do
    begin
      face_normals_avail := true;
      vertex_normals_avail := true;
      vertex_vectors_avail := false;
    end;

  Polygon_b_rep := surface_ptr;
end; {function Polygon_b_rep}


{***********************}
{ non_planar primitives }
{***********************}


function Torus_b_rep(inner_radius: real;
  umin, umax: real;
  vmin, vmax: real): surface_ptr_type;
var
  surface_ptr: surface_ptr_type;
  width, height: integer;
  max_width, max_height: integer;
  normal, texture: vector_type;
  u_axis, v_axis: vector_type;
begin
  if (umin = 0) and (umax = 360) and (vmin = 0) and (vmax = 360) then
    surface_ptr := New_surface(topo_similar, closed_surface, smooth_shading)
  else
    surface_ptr := New_surface(topo_similar, open_surface, smooth_shading);

  {***************}
  { make topology }
  {***************}
  if (umin = 0) and (umax = 360) then
    begin
      if (vmin = 0) and (vmax = 360) then
        surface_ptr^.topology_ptr := Torus_topology
      else
        surface_ptr^.topology_ptr := Torus_v_sweep_topology;
    end
  else
    begin
      if (vmin = 0) and (vmax = 360) then
        surface_ptr^.topology_ptr := Torus_u_sweep_topology
      else
        surface_ptr^.topology_ptr := Torus_uv_sweep_topology;
    end;

  {***************}
  { make geometry }
  {***************}
  surface_ptr^.geometry_ptr := Make_geometry;
  Grid_torus(grid_ptr, inner_radius, umin, umax, vmin, vmax);

  {*********************}
  { make point geometry }
  {*********************}
  max_width := grid_ptr^.width;
  max_height := grid_ptr^.height;
  if grid_ptr^.h_wraparound then
    max_width := max_width - 1;
  if grid_ptr^.v_wraparound then
    max_height := max_height - 1;

  for height := 0 to max_height do
    for width := 0 to max_width do
      Make_point_geometry(grid_ptr^.point_array_ptr^[width, height]);

  {**********************}
  { make vertex geometry }
  {**********************}
  for height := 0 to grid_ptr^.height do
    for width := 0 to grid_ptr^.width do
      begin
        normal := grid_ptr^.normal_array_ptr^[width, height];
        texture := grid_ptr^.texture_array_ptr^[width, height];
        u_axis := grid_ptr^.u_axis_array_ptr^[width, height];
        v_axis := grid_ptr^.v_axis_array_ptr^[width, height];
        Make_vertex_geometry(normal, texture, u_axis, v_axis);
      end;

  {********************}
  { make face geometry }
  {********************}
  Grid_to_face_geometry(grid_ptr);

  {*************************}
  { set mesh geometry flags }
  {*************************}
  with surface_ptr^.geometry_ptr^.geometry_info do
    begin
      face_normals_avail := true;
      vertex_normals_avail := true;
      vertex_vectors_avail := true;
    end;

  Torus_b_rep := surface_ptr;
end; {function Torus_b_rep}


function Block_b_rep: surface_ptr_type;
var
  normal: vector_type;
  u_axis, v_axis: vector_type;
begin
  if (unit_block_ptr = nil) then
    begin
      unit_block_ptr := New_surface(self_similar, closed_surface,
        smooth_shading);
      unit_block_ptr^.topology_ptr := Block_topology;
      unit_block_ptr^.geometry_ptr := Make_geometry;

      {*********************}
      { make point geometry }
      {*********************}
      Make_point_geometry(To_vector(-1, -1, -1));
      Make_point_geometry(To_vector(1, -1, -1));
      Make_point_geometry(To_vector(1, 1, -1));
      Make_point_geometry(To_vector(-1, 1, -1));
      Make_point_geometry(To_vector(-1, -1, 1));
      Make_point_geometry(To_vector(1, -1, 1));
      Make_point_geometry(To_vector(1, 1, 1));
      Make_point_geometry(To_vector(-1, 1, 1));

      {***********}
      { left face }
      {***********}
      normal := neg_x_vector;
      u_axis := neg_y_vector;
      v_axis := z_vector;
      Make_vertex_geometry(normal, To_vector(1, 0, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(1, 1, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(0, 1, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(0, 0, 1), u_axis, v_axis);

      {************}
      { right face }
      {************}
      normal := x_vector;
      u_axis := y_vector;
      v_axis := z_vector;
      Make_vertex_geometry(normal, To_vector(1, 0, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(1, 1, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(0, 1, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(0, 0, 1), u_axis, v_axis);

      {************}
      { front face }
      {************}
      normal := neg_y_vector;
      u_axis := x_vector;
      v_axis := z_vector;
      Make_vertex_geometry(normal, To_vector(1, 0, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(1, 1, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(0, 1, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(0, 0, 1), u_axis, v_axis);

      {***********}
      { back face }
      {***********}
      normal := y_vector;
      u_axis := neg_x_vector;
      v_axis := z_vector;
      Make_vertex_geometry(normal, To_vector(1, 0, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(1, 1, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(0, 1, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(0, 0, 1), u_axis, v_axis);

      {*************}
      { bottom face }
      {*************}
      normal := neg_z_vector;
      u_axis := x_vector;
      v_axis := neg_y_vector;
      Make_vertex_geometry(normal, To_vector(0, 0, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(1, 0, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(1, 1, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(0, 1, 1), u_axis, v_axis);

      {**********}
      { top face }
      {**********}
      normal := z_vector;
      u_axis := x_vector;
      v_axis := y_vector;
      Make_vertex_geometry(normal, To_vector(0, 0, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(1, 0, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(1, 1, 1), u_axis, v_axis);
      Make_vertex_geometry(normal, To_vector(0, 1, 1), u_axis, v_axis);

      {********************}
      { make face geometry }
      {********************}
      Make_face_geometry(neg_x_vector);
      Make_face_geometry(x_vector);
      Make_face_geometry(neg_y_vector);
      Make_face_geometry(y_vector);
      Make_face_geometry(neg_z_vector);
      Make_face_geometry(z_vector);

      {*************************}
      { set mesh geometry flags }
      {*************************}
      with unit_block_ptr^.geometry_ptr^.geometry_info do
        begin
          face_normals_avail := true;
          vertex_normals_avail := true;
          vertex_vectors_avail := true;
        end;
    end;

  Block_b_rep := unit_block_ptr;
end; {function Block_b_rep}


function Shaded_triangle_b_rep(normal1, normal2, normal3: vector_type):
  surface_ptr_type;
var
  surface_ptr: surface_ptr_type;
begin
  surface_ptr := New_surface(topo_similar, open_surface, smooth_shading);
  surface_ptr^.topology_ptr := Triangle_topology;
  surface_ptr^.geometry_ptr := Make_geometry;

  {*********************}
  { make point geometry }
  {*********************}
  Make_point_geometry(To_vector(-1, -1, 0));
  Make_point_geometry(To_vector(1, -1, 0));
  Make_point_geometry(To_vector(-1, 1, 0));

  {**********************}
  { make vertex geometry }
  {**********************}
  Make_vertex_geometry(normal1, To_vector(0, 0, 1), x_vector, y_vector);
  Make_vertex_geometry(normal2, To_vector(1, 0, 1), x_vector, y_vector);
  Make_vertex_geometry(normal3, To_vector(0, 1, 1), x_vector, y_vector);

  {********************}
  { make face geometry }
  {********************}
  Make_face_geometry(To_vector(0, 0, 1));

  {*************************}
  { set mesh geometry flags }
  {*************************}
  with surface_ptr^.geometry_ptr^.geometry_info do
    begin
      face_normals_avail := true;
      vertex_normals_avail := true;
      vertex_vectors_avail := true;
    end;

  Shaded_triangle_b_rep := surface_ptr;
end; {function Shaded_triangle_b_rep}


function Shaded_polygon_b_rep(shaded_polygon_ptr: shaded_polygon_ptr_type):
  surface_ptr_type;
var
  surface_ptr: surface_ptr_type;
  vertex_ptr: shaded_polygon_vertex_ptr_type;
begin
  {***************}
  { make topology }
  {***************}
  with shaded_polygon_ptr^ do
    if (vertices = 3) and (next = nil) then
      begin
        surface_ptr := New_surface(topo_similar, open_surface, smooth_shading);
        surface_ptr^.topology_ptr := Triangle_topology
      end
    else if (vertices = 4) and (next = nil) then
      begin
        surface_ptr := New_surface(topo_similar, open_surface, smooth_shading);
        surface_ptr^.topology_ptr := Parallelogram_topology
      end
    else
      begin
        surface_ptr := New_surface(dissimilar, open_surface, smooth_shading);
        surface_ptr^.topology_ptr :=
          Shaded_polygon_topology(shaded_polygon_ptr);
      end;

  {***************}
  { make geometry }
  {***************}
  surface_ptr^.geometry_ptr := Make_geometry;

  {********************************}
  { make point and vertex geometry }
  {********************************}
  while (shaded_polygon_ptr <> nil) do
    begin
      vertex_ptr := shaded_polygon_ptr^.vertex_ptr;
      while (vertex_ptr <> nil) do
        begin
          with vertex_ptr^ do
            begin
              Make_point_geometry(point);
              Make_vertex_geometry(normal, texture, x_vector, y_vector);
            end;
          vertex_ptr := vertex_ptr^.next;
        end;
      shaded_polygon_ptr := shaded_polygon_ptr^.next;
    end;

  {********************}
  { make face geometry }
  {********************}
  Make_face_geometry(z_vector);

  {*************************}
  { set mesh geometry flags }
  {*************************}
  with surface_ptr^.geometry_ptr^.geometry_info do
    begin
      face_normals_avail := true;
      vertex_normals_avail := true;
      vertex_vectors_avail := false;
    end;

  Shaded_polygon_b_rep := surface_ptr;
end; {function Shaded_polygon_b_rep}


function Mesh_b_rep(mesh_ptr: mesh_ptr_type;
  smoothing, mending, closed, checking: boolean): surface_ptr_type;
var
  surface_ptr: surface_ptr_type;
  surface_closure: surface_closure_type;
  vertex_ptr, vertex_ptr2: mesh_vertex_ptr_type;
  face_ptr: mesh_face_ptr_type;
  found: boolean;
begin
  if closed then
    surface_closure := closed_surface
  else
    surface_closure := open_surface;

  if smoothing then
    begin
      surface_ptr := New_surface(dissimilar, surface_closure, smooth_shading);
      surface_ptr^.topology_ptr := Mesh_topology(mesh_ptr, pseudo_edge,
        checking, mending);
      surface_ptr^.geometry_ptr := Make_geometry;
    end
  else
    begin
      surface_ptr := New_surface(dissimilar, surface_closure, flat_shading);
      surface_ptr^.topology_ptr := Mesh_topology(mesh_ptr, real_edge, checking,
        mending);
      surface_ptr^.geometry_ptr := Make_geometry;
    end;

  if debug then
    begin
      writeln('topology claims:');
      Report_topology(surface_ptr^.topology_ptr);
      writeln;
      writeln('inspection reveals:');
      Inspect_topology(surface_ptr^.topology_ptr);
      writeln;
    end;

  {********************************}
  { make point and vertex geometry }
  {********************************}
  vertex_ptr := mesh_ptr^.vertex_ptr;
  while (vertex_ptr <> nil) do
    begin
      {************************}
      { find coincident points }
      {************************}
      if mending then
        begin
          found := false;
          vertex_ptr2 := mesh_ptr^.vertex_ptr;

          while (vertex_ptr2 <> vertex_ptr) and not found do
            begin
              if Coincident_vertices(vertex_ptr^.point, vertex_ptr2^.point) then
                found := true
              else
                vertex_ptr2 := vertex_ptr2^.next;
            end;

          if not found then
            Make_point_geometry(vertex_ptr^.point);
        end
      else
        Make_point_geometry(vertex_ptr^.point);

      Make_vertex_geometry(vertex_ptr^.normal, vertex_ptr^.texture, x_vector,
        y_vector);
      vertex_ptr := vertex_ptr^.next;
    end;

  {********************}
  { make face geometry }
  {********************}
  face_ptr := mesh_ptr^.face_ptr;
  while (face_ptr <> nil) do
    begin
      Make_face_geometry(z_vector);
      face_ptr := face_ptr^.next;
    end;

  if mending then
    begin
      {**********************************}
      { Mend coincident points and edges }
      {**********************************}
      //Mend_surface(surface_ptr);
    end;

  if smoothing then
    begin
      {*******************************}
      { find real edges from topology }
      {*******************************}
      Find_mesh_real_edges(surface_ptr^.topology_ptr);
    end;

  {*************************}
  { set mesh geometry flags }
  {*************************}
  with surface_ptr^.geometry_ptr^.geometry_info do
    begin
      face_normals_avail := false;
      vertex_normals_avail := false;
      vertex_vectors_avail := false;
    end;

  Mesh_b_rep := surface_ptr;
end; {function Mesh_b_rep}


function Blob_b_rep(metaball_ptr: metaball_ptr_type;
  threshold: real;
  dimensions: vector_type): surface_ptr_type;
var
  mesh_ptr: mesh_ptr_type;
  volume_ptr: volume_ptr_type;
  surface_ptr: surface_ptr_type;
  metaball_list: metaball_ptr_type;
  metaball_extent_box: extent_box_type;
  metaball_surface_ptr: surface_ptr_type;
  point_geometry_ptr: point_geometry_ptr_type;
  facets: integer;
begin
  facets := Get_facets;
  volume_ptr := New_volume(threshold, false, true);
  volume_ptr^.density_array_ptr := New_density_array(facets * 2, facets * 2,
    facets * 2);
  metaball_list := metaball_ptr;
  surface_ptr := nil;

  while (metaball_ptr <> nil) do
    begin
      metaball_extent_box := Metaball_extents(metaball_ptr);

      {*************}
      { create mesh }
      {*************}
      Blob_to_volume(metaball_list, volume_ptr, metaball_extent_box);
      mesh_ptr := Volume_to_mesh(volume_ptr);
      metaball_surface_ptr := Mesh_b_rep(mesh_ptr, true, false, true, false);

      {********************************************************}
      { volume topologies are usually unique, so we don't need }
      { to keep around a record of them to identify duplicates }
      {********************************************************}
      Free_mesh_topology_link(mesh_ptr);
      Free_mesh(mesh_ptr);

      {*********************}
      { scale blob geometry }
      {*********************}
      point_geometry_ptr :=
        metaball_surface_ptr^.geometry_ptr^.point_geometry_ptr;
      while (point_geometry_ptr <> nil) do
        begin
          point_geometry_ptr^.point := Vector_sum(point_geometry_ptr^.point,
            metaball_ptr^.center);
          point_geometry_ptr^.point := Vector_divide(point_geometry_ptr^.point,
            dimensions);
          point_geometry_ptr := point_geometry_ptr^.next;
        end;

      {******************}
      { add mesh to list }
      {******************}
      metaball_surface_ptr^.next := surface_ptr;
      surface_ptr := metaball_surface_ptr;

      metaball_ptr := metaball_ptr^.next;
    end;

  {*************************}
  { free density data array }
  {*************************}
  Free_volume(volume_ptr);

  Blob_b_rep := surface_ptr;
end; {function Blob_b_rep}


{************************}
{ non-surface primitives }
{************************}


function Point_b_rep(points_ptr: points_ptr_type): surface_ptr_type;
var
  surface_ptr: surface_ptr_type;
  vertex_ptr: point_vertex_ptr_type;
begin
  surface_ptr := New_surface(dissimilar, open_surface, flat_shading);
  surface_ptr^.topology_ptr := Point_topology(points_ptr^.vertices);
  surface_ptr^.geometry_ptr := Make_geometry;

  {********************************}
  { make point and vertex geometry }
  {********************************}
  vertex_ptr := points_ptr^.vertex_ptr;
  while (vertex_ptr <> nil) do
    begin
      Make_point_geometry(vertex_ptr^.point);
      Make_vertex_geometry(z_vector, z_vector, x_vector, y_vector);
      vertex_ptr := vertex_ptr^.next;
    end;

  {*************************}
  { set mesh geometry flags }
  {*************************}
  with surface_ptr^.geometry_ptr^.geometry_info do
    begin
      face_normals_avail := true;
      vertex_normals_avail := true;
      vertex_vectors_avail := true;
    end;

  Point_b_rep := surface_ptr;
end; {function Point_b_rep}


function Line_b_rep(lines_ptr: lines_ptr_type): surface_ptr_type;
var
  surface_ptr: surface_ptr_type;
  vertex_ptr: line_vertex_ptr_type;
begin
  surface_ptr := New_surface(dissimilar, open_surface, flat_shading);
  surface_ptr^.topology_ptr := Line_topology(lines_ptr^.vertices);
  surface_ptr^.geometry_ptr := Make_geometry;

  {********************************}
  { make point and vertex geometry }
  {********************************}
  vertex_ptr := lines_ptr^.vertex_ptr;
  while (vertex_ptr <> nil) do
    begin
      Make_point_geometry(vertex_ptr^.point);
      Make_vertex_geometry(z_vector, z_vector, x_vector, y_vector);
      vertex_ptr := vertex_ptr^.next;
    end;

  {*************************}
  { set mesh geometry flags }
  {*************************}
  with surface_ptr^.geometry_ptr^.geometry_info do
    begin
      face_normals_avail := true;
      vertex_normals_avail := true;
      vertex_vectors_avail := true;
    end;

  Line_b_rep := surface_ptr;
end; {function Line_b_rep}


function Volume_b_rep(volume_ptr: volume_ptr_type): surface_ptr_type;
var
  mesh_ptr: mesh_ptr_type;
  surface_ptr: surface_ptr_type;
  closed: boolean;
begin
  mesh_ptr := Volume_to_mesh(volume_ptr);
  closed := volume_ptr^.capping;
  surface_ptr := Mesh_b_rep(mesh_ptr, volume_ptr^.smoothing, false, closed,
    false);

  {********************************************************}
  { volume topologies are usually unique, so we don't need }
  { to keep around a record of them to identify duplicates }
  {********************************************************}
  Free_mesh_topology_link(mesh_ptr);
  Free_mesh(mesh_ptr);

  Volume_b_rep := surface_ptr;
end; {function Volume_b_rep}


procedure Free_faceted_b_reps;
begin
  Free_faceted_topologies;
  Free_faceted_quads;

  Force_free_surface(unit_plane_ptr);
  Force_free_surface(unit_disk_ptr);
end; {procedure Free_faceted_b_reps}


initialization
  unit_plane_ptr := nil;
  unit_block_ptr := nil;
  unit_triangle_ptr := nil;
  unit_parallelogram_ptr := nil;
  unit_disk_ptr := nil;
end.
