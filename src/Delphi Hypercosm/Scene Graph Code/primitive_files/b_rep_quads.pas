unit b_rep_quads;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            b_rep_quads                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The b_rep_prims module builds the b_rep data            }
{       structures for the primitive quadric objects.           }
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
  b_rep, grid_prims;


var
  grid_ptr: grid_ptr_type;


  {*****************}
  { b rep utilities }
  {*****************}
procedure Free_faceted_quads;
procedure Grid_to_face_geometry(grid_ptr: grid_ptr_type);
procedure Force_free_surface(var surface_ptr: surface_ptr_type);


{********************}
{ quadric primitives }
{********************}
function Sphere_b_rep(umin, umax: real;
  vmin, vmax: real): surface_ptr_type;
function Cylinder_b_rep(umin, umax: real): surface_ptr_type;
function Cone_b_rep(inner_radius: real;
  umin, umax: real): surface_ptr_type;
function Paraboloid_b_rep(umin, umax: real): surface_ptr_type;
function Hyperboloid1_b_rep(inner_radius: real;
  umin, umax: real): surface_ptr_type;
function Hyperboloid2_b_rep(eccentricity: real;
  umin, umax: real): surface_ptr_type;


implementation
uses
  vectors, binormals, trans, geometry, make_b_rep, grid_quads, mesh_prims;


{*******************************************************}
{                self-similar primitives                }
{*******************************************************}
{       These primitives can be transformed from        }
{       one instance to any other another instance      }
{       with a simple linear transformation:            }
{                                                       }
{           disk, sphere, cylinder, paraboloid,         }
{               plane, triangle, block,                 }
{*******************************************************}


{*******************************************************}
{               non self-similar primitives             }
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
  {***********************}
  { self-similar quadrics }
  {***********************}
  unit_sphere_ptr, unit_cylinder_ptr: surface_ptr_type;
  unit_cone_ptr, unit_paraboloid_ptr: surface_ptr_type;


procedure Grid_to_face_geometry(grid_ptr: grid_ptr_type);
var
  width, height: integer;
  next_width, next_height: integer;
  point1, point2, point3, point4: vector_type;
  binormal: binormal_type;
begin
  {**************}
  { create faces }
  {**************}
  for height := 0 to (grid_ptr^.height - 1) do
    begin
      for width := 0 to (grid_ptr^.width - 1) do
        begin
          {******************}
          { calculate normal }
          {******************}
          next_height := (height + 1) mod (grid_ptr^.height + 1);
          next_width := (width + 1) mod (grid_ptr^.width + 1);
          point1 := grid_ptr^.point_array_ptr^[width, height];
          point2 := grid_ptr^.point_array_ptr^[width, next_height];
          point3 := grid_ptr^.point_array_ptr^[next_width, next_height];
          point4 := grid_ptr^.point_array_ptr^[next_width, height];
          binormal.x_axis := Vector_difference(point3, point1);
          binormal.y_axis := Vector_difference(point2, point4);
          Make_face_geometry(Binormal_to_normal(binormal));
        end;
    end;
end; {procedure Grid_to_face_geometry}


procedure Grid_to_reverse_face_geometry(grid_ptr: grid_ptr_type);
var
  width, height: integer;
  next_width, next_height: integer;
  point1, point2, point3, point4: vector_type;
  binormal: binormal_type;
begin
  {**************}
  { create faces }
  {**************}
  for height := 0 to (grid_ptr^.height - 1) do
    begin
      for width := 0 to (grid_ptr^.width - 1) do
        begin
          {******************}
          { calculate normal }
          {******************}
          next_height := (height + 1) mod (grid_ptr^.height + 1);
          next_width := (width + 1) mod (grid_ptr^.width + 1);
          point1 := grid_ptr^.point_array_ptr^[width, height];
          point2 := grid_ptr^.point_array_ptr^[width, next_height];
          point3 := grid_ptr^.point_array_ptr^[next_width, next_height];
          point4 := grid_ptr^.point_array_ptr^[next_width, height];
          binormal.x_axis := Vector_difference(point1, point3);
          binormal.y_axis := Vector_difference(point2, point4);
          Make_face_geometry(Binormal_to_normal(binormal));
        end;
    end;
end; {procedure Grid_to_reverse_face_geometry}


procedure Grid_to_face_geometry2(grid_ptr: grid_ptr_type);
var
  width, height: integer;
  next_width, next_height: integer;
  point1, point2, point3, point4: vector_type;
  binormal: binormal_type;
begin
  {**************}
  { create faces }
  {**************}
  for height := (grid_ptr^.height - 1) downto 0 do
    begin
      for width := 0 to (grid_ptr^.width - 1) do
        begin
          {******************}
          { calculate normal }
          {******************}
          next_height := (height + 1) mod (grid_ptr^.height + 1);
          next_width := (width + 1) mod (grid_ptr^.width + 1);
          point1 := grid_ptr^.point_array_ptr^[width, height];
          point2 := grid_ptr^.point_array_ptr^[width, next_height];
          point3 := grid_ptr^.point_array_ptr^[next_width, next_height];
          point4 := grid_ptr^.point_array_ptr^[next_width, height];
          binormal.x_axis := Vector_difference(point3, point1);
          binormal.y_axis := Vector_difference(point2, point4);
          Make_face_geometry(Binormal_to_normal(binormal));
        end;
    end;
end; {procedure Grid_to_face_geometry2}


procedure Grid_to_reverse_face_geometry2(grid_ptr: grid_ptr_type);
var
  width, height: integer;
  next_width, next_height: integer;
  point1, point2, point3, point4: vector_type;
  binormal: binormal_type;
begin
  {**************}
  { create faces }
  {**************}
  for height := (grid_ptr^.height - 1) downto 0 do
    begin
      for width := 0 to (grid_ptr^.width - 1) do
        begin
          {******************}
          { calculate normal }
          {******************}
          next_height := (height + 1) mod (grid_ptr^.height + 1);
          next_width := (width + 1) mod (grid_ptr^.width + 1);
          point1 := grid_ptr^.point_array_ptr^[width, height];
          point2 := grid_ptr^.point_array_ptr^[width, next_height];
          point3 := grid_ptr^.point_array_ptr^[next_width, next_height];
          point4 := grid_ptr^.point_array_ptr^[next_width, height];
          binormal.x_axis := Vector_difference(point1, point3);
          binormal.y_axis := Vector_difference(point2, point4);
          Make_face_geometry(Binormal_to_normal(binormal));
        end;
    end;
end; {procedure Grid_to_reverse_face_geometry2}


{********************}
{ quadric primitives }
{********************}


function Sphere_b_rep(umin, umax: real;
  vmin, vmax: real): surface_ptr_type;
var
  surface_ptr: surface_ptr_type;
  width, height: integer;
  normal, texture: vector_type;
  u_axis, v_axis: vector_type;
begin
  if (umin = 0) and (umax = 360) then
    begin
      {*******************************}
      { complete surface in longitude }
      {*******************************}
      if (vmin = -90) and (vmax = 90) then
        begin
          {*****************}
          { sphere topology }
          {*****************}
          if (unit_sphere_ptr = nil) then
            begin
              surface_ptr := New_surface(self_similar, closed_surface,
                smooth_shading);
              surface_ptr^.topology_ptr := Sphere_topology;
              unit_sphere_ptr := surface_ptr;

              {***************}
              { make geometry }
              {***************}
              surface_ptr^.geometry_ptr := Make_geometry;
              Grid_sphere(grid_ptr, umin, umax, vmin, vmax);

              {*********************}
              { make point geometry }
              {*********************}
              Make_point_geometry(grid_ptr^.point_array_ptr^[0, 0]);
              for height := 1 to (grid_ptr^.height - 1) do
                for width := 0 to (grid_ptr^.width - 1) do
                  Make_point_geometry(grid_ptr^.point_array_ptr^[width,
                    height]);
              Make_point_geometry(grid_ptr^.point_array_ptr^[0,
                grid_ptr^.height]);

              {**********************}
              { make vertex geometry }
              {**********************}
              for width := 0 to (grid_ptr^.width - 1) do
                begin
                  normal := grid_ptr^.normal_array_ptr^[width, 0];
                  texture := grid_ptr^.texture_array_ptr^[width, 0];
                  u_axis := grid_ptr^.u_axis_array_ptr^[width, 0];
                  v_axis := grid_ptr^.v_axis_array_ptr^[width, 0];
                  Make_vertex_geometry(normal, texture, u_axis, v_axis);
                end;
              for height := 1 to (grid_ptr^.height - 1) do
                for width := 0 to grid_ptr^.width do
                  begin
                    normal := grid_ptr^.normal_array_ptr^[width, height];
                    texture := grid_ptr^.texture_array_ptr^[width, height];
                    u_axis := grid_ptr^.u_axis_array_ptr^[width, height];
                    v_axis := grid_ptr^.v_axis_array_ptr^[width, height];
                    Make_vertex_geometry(normal, texture, u_axis, v_axis);
                  end;
              for width := 0 to (grid_ptr^.width - 1) do
                begin
                  normal := grid_ptr^.normal_array_ptr^[width,
                    grid_ptr^.height];
                  texture := grid_ptr^.texture_array_ptr^[width,
                    grid_ptr^.height];
                  u_axis := grid_ptr^.u_axis_array_ptr^[width,
                    grid_ptr^.height];
                  v_axis := grid_ptr^.v_axis_array_ptr^[width,
                    grid_ptr^.height];
                  Make_vertex_geometry(normal, texture, u_axis, v_axis);
                end;

              {********************}
              { make face geometry }
              {********************}
              Grid_to_face_geometry(grid_ptr);
            end
          else
            surface_ptr := unit_sphere_ptr;
        end
      else if (vmin = -90) then
        begin
          {*********************}
          { paraboloid topology }
          {*********************}
          surface_ptr := New_surface(topo_similar, open_surface,
            smooth_shading);
          surface_ptr^.topology_ptr := Paraboloid_topology;
          surface_ptr^.geometry_ptr := Make_geometry;
          Grid_sphere(grid_ptr, umin, umax, vmin, vmax);

          {*********************}
          { make point geometry }
          {*********************}
          Make_point_geometry(grid_ptr^.point_array_ptr^[0, 0]);
          for height := 1 to grid_ptr^.height do
            for width := 0 to (grid_ptr^.width - 1) do
              Make_point_geometry(grid_ptr^.point_array_ptr^[width, height]);

          {**********************}
          { make vertex geometry }
          {**********************}
          for width := 0 to (grid_ptr^.width - 1) do
            begin
              normal := grid_ptr^.normal_array_ptr^[width, 0];
              texture := grid_ptr^.texture_array_ptr^[width, 0];
              u_axis := grid_ptr^.u_axis_array_ptr^[width, 0];
              v_axis := grid_ptr^.v_axis_array_ptr^[width, 0];
              Make_vertex_geometry(normal, texture, u_axis, v_axis);
            end;
          for height := 1 to grid_ptr^.height do
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
      else if (vmax = 90) then
        begin
          {*********************}
          { paraboloid topology }
          {*********************}
          surface_ptr := New_surface(topo_similar, open_surface,
            smooth_shading);
          surface_ptr^.topology_ptr := Paraboloid_topology;
          surface_ptr^.geometry_ptr := Make_geometry;
          Grid_sphere(grid_ptr, umin, umax, vmin, vmax);

          {*********************}
          { make point geometry }
          {*********************}
          Make_point_geometry(grid_ptr^.point_array_ptr^[0, grid_ptr^.height]);
          for height := (grid_ptr^.height - 1) downto 0 do
            for width := 0 to (grid_ptr^.width - 1) do
              Make_point_geometry(grid_ptr^.point_array_ptr^[width, height]);

          {**********************}
          { make vertex geometry }
          {**********************}
          for width := 0 to (grid_ptr^.width - 1) do
            begin
              normal := grid_ptr^.normal_array_ptr^[width, grid_ptr^.height];
              texture := grid_ptr^.texture_array_ptr^[width, grid_ptr^.height];
              u_axis := grid_ptr^.u_axis_array_ptr^[width, grid_ptr^.height];
              v_axis := grid_ptr^.v_axis_array_ptr^[width, grid_ptr^.height];
              Make_vertex_geometry(normal, texture, u_axis, v_axis);
            end;
          for height := (grid_ptr^.height - 1) downto 0 do
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
          Grid_to_face_geometry2(grid_ptr);
        end
      else
        begin
          {***********************}
          { hyperboloid1 topology }
          {***********************}
          surface_ptr := New_surface(topo_similar, open_surface,
            smooth_shading);
          surface_ptr^.topology_ptr := Hyperboloid1_topology;
          surface_ptr^.geometry_ptr := Make_geometry;
          Grid_sphere(grid_ptr, umin, umax, vmin, vmax);

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
        end;
    end
  else
    begin
      {******************************}
      { partial surface in longitude }
      {******************************}
      if (vmin = -90) and (vmax = 90) then
        begin
          {***********************}
          { sphere sweep topology }
          {***********************}
          surface_ptr := New_surface(topo_similar, open_surface,
            smooth_shading);
          surface_ptr^.topology_ptr := Sphere_sweep_topology;

          {***************}
          { make geometry }
          {***************}
          surface_ptr^.geometry_ptr := Make_geometry;
          Grid_sphere(grid_ptr, umin, umax, vmin, vmax);

          {*********************}
          { make point geometry }
          {*********************}
          Make_point_geometry(grid_ptr^.point_array_ptr^[0, 0]);
          for height := 1 to (grid_ptr^.height - 1) do
            for width := 0 to grid_ptr^.width do
              Make_point_geometry(grid_ptr^.point_array_ptr^[width, height]);
          Make_point_geometry(grid_ptr^.point_array_ptr^[0, grid_ptr^.height]);

          {**********************}
          { make vertex geometry }
          {**********************}
          for width := 0 to (grid_ptr^.width - 1) do
            begin
              normal := grid_ptr^.normal_array_ptr^[width, 0];
              texture := grid_ptr^.texture_array_ptr^[width, 0];
              u_axis := grid_ptr^.u_axis_array_ptr^[width, 0];
              v_axis := grid_ptr^.v_axis_array_ptr^[width, 0];
              Make_vertex_geometry(normal, texture, u_axis, v_axis);
            end;
          for height := 1 to (grid_ptr^.height - 1) do
            for width := 0 to grid_ptr^.width do
              begin
                normal := grid_ptr^.normal_array_ptr^[width, height];
                texture := grid_ptr^.texture_array_ptr^[width, height];
                u_axis := grid_ptr^.u_axis_array_ptr^[width, height];
                v_axis := grid_ptr^.v_axis_array_ptr^[width, height];
                Make_vertex_geometry(normal, texture, u_axis, v_axis);
              end;
          for width := 0 to (grid_ptr^.width - 1) do
            begin
              normal := grid_ptr^.normal_array_ptr^[width, grid_ptr^.height];
              texture := grid_ptr^.texture_array_ptr^[width, grid_ptr^.height];
              u_axis := grid_ptr^.u_axis_array_ptr^[width, grid_ptr^.height];
              v_axis := grid_ptr^.v_axis_array_ptr^[width, grid_ptr^.height];
              Make_vertex_geometry(normal, texture, u_axis, v_axis);
            end;

          {********************}
          { make face geometry }
          {********************}
          Grid_to_face_geometry(grid_ptr);
        end
      else if (vmin = -90) then
        begin
          {***************************}
          { paraboloid sweep topology }
          {***************************}
          surface_ptr := New_surface(topo_similar, open_surface,
            smooth_shading);
          surface_ptr^.topology_ptr := Paraboloid_sweep_topology;

          {***************}
          { make geometry }
          {***************}
          surface_ptr^.geometry_ptr := Make_geometry;
          Grid_sphere(grid_ptr, umin, umax, vmin, vmax);

          {*********************}
          { make point geometry }
          {*********************}
          Make_point_geometry(grid_ptr^.point_array_ptr^[0, 0]);
          for height := 1 to grid_ptr^.height do
            for width := 0 to grid_ptr^.width do
              Make_point_geometry(grid_ptr^.point_array_ptr^[width, height]);

          {**********************}
          { make vertex geometry }
          {**********************}
          for width := 0 to (grid_ptr^.width - 1) do
            begin
              normal := grid_ptr^.normal_array_ptr^[width, 0];
              texture := grid_ptr^.texture_array_ptr^[width, 0];
              u_axis := grid_ptr^.u_axis_array_ptr^[width, 0];
              v_axis := grid_ptr^.v_axis_array_ptr^[width, 0];
              Make_vertex_geometry(normal, texture, u_axis, v_axis);
            end;
          for height := 1 to grid_ptr^.height do
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
      else if (vmax = 90) then
        begin
          {***************************}
          { paraboloid sweep topology }
          {***************************}
          surface_ptr := New_surface(topo_similar, open_surface,
            smooth_shading);
          surface_ptr^.topology_ptr := Paraboloid_sweep_topology;

          {***************}
          { make geometry }
          {***************}
          surface_ptr^.geometry_ptr := Make_geometry;
          Grid_sphere(grid_ptr, umin, umax, vmin, vmax);

          {*********************}
          { make point geometry }
          {*********************}
          Make_point_geometry(grid_ptr^.point_array_ptr^[0, grid_ptr^.height]);
          for height := (grid_ptr^.height - 1) downto 0 do
            for width := 0 to grid_ptr^.width do
              Make_point_geometry(grid_ptr^.point_array_ptr^[width, height]);

          {**********************}
          { make vertex geometry }
          {**********************}
          for width := 0 to (grid_ptr^.width - 1) do
            begin
              normal := grid_ptr^.normal_array_ptr^[width, grid_ptr^.height];
              texture := grid_ptr^.texture_array_ptr^[width, grid_ptr^.height];
              u_axis := grid_ptr^.u_axis_array_ptr^[width, grid_ptr^.height];
              v_axis := grid_ptr^.v_axis_array_ptr^[width, grid_ptr^.height];
              Make_vertex_geometry(normal, texture, u_axis, v_axis);
            end;
          for height := (grid_ptr^.height - 1) downto 0 do
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
          Grid_to_face_geometry2(grid_ptr);
        end
      else
        begin
          {*****************************}
          { hyperboloid1 sweep topology }
          {*****************************}
          surface_ptr := New_surface(topo_similar, open_surface,
            smooth_shading);
          surface_ptr^.topology_ptr := Hyperboloid1_sweep_topology;

          {***************}
          { make geometry }
          {***************}
          surface_ptr^.geometry_ptr := Make_geometry;
          Grid_sphere(grid_ptr, umin, umax, vmin, vmax);

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

  Sphere_b_rep := surface_ptr;
end; {function Sphere_b_rep}


function Cylinder_b_rep(umin, umax: real): surface_ptr_type;
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
      if (unit_cylinder_ptr = nil) then
        begin
          surface_ptr := New_surface(self_similar, open_surface,
            smooth_shading);
          surface_ptr^.topology_ptr := Cylinder_topology;
          unit_cylinder_ptr := surface_ptr;

          {***************}
          { make geometry }
          {***************}
          surface_ptr^.geometry_ptr := Make_geometry;
          Grid_cylinder(grid_ptr, umin, umax);

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
        surface_ptr := unit_cylinder_ptr;
    end
  else
    begin
      {*****************}
      { partial surface }
      {*****************}
      surface_ptr := New_surface(topo_similar, open_surface, smooth_shading);
      surface_ptr^.topology_ptr := Cylinder_sweep_topology;

      {***************}
      { make geometry }
      {***************}
      surface_ptr^.geometry_ptr := Make_geometry;
      Grid_cylinder(grid_ptr, umin, umax);

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

  Cylinder_b_rep := surface_ptr;
end; {function Cylinder_b_rep}


function Cone_b_rep(inner_radius: real;
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
      surface_ptr^.topology_ptr := Cylinder_topology;

      {***************}
      { make geometry }
      {***************}
      surface_ptr^.geometry_ptr := Make_geometry;
      Grid_cone(grid_ptr, inner_radius, umin, umax);

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
      surface_ptr^.topology_ptr := Cylinder_sweep_topology;

      {***************}
      { make geometry }
      {***************}
      surface_ptr^.geometry_ptr := Make_geometry;
      Grid_cone(grid_ptr, inner_radius, umin, umax);

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

  Cone_b_rep := surface_ptr;
end; {function Cone_b_rep}


function Paraboloid_b_rep(umin, umax: real): surface_ptr_type;
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
      if (unit_paraboloid_ptr = nil) then
        begin
          surface_ptr := New_surface(self_similar, open_surface,
            smooth_shading);
          surface_ptr^.topology_ptr := Paraboloid_topology;
          surface_ptr^.geometry_ptr := Make_geometry;
          Grid_paraboloid(grid_ptr, umin, umax);
          unit_paraboloid_ptr := surface_ptr;

          {*********************}
          { make point geometry }
          {*********************}
          Make_point_geometry(grid_ptr^.point_array_ptr^[0, 0]);
          for height := 1 to grid_ptr^.height do
            for width := 0 to (grid_ptr^.width - 1) do
              Make_point_geometry(grid_ptr^.point_array_ptr^[width, height]);

          {**********************}
          { make vertex geometry }
          {**********************}
          for width := 0 to (grid_ptr^.width - 1) do
            begin
              normal := grid_ptr^.normal_array_ptr^[width, 0];
              texture := grid_ptr^.texture_array_ptr^[width, 0];
              u_axis := grid_ptr^.u_axis_array_ptr^[width, 0];
              v_axis := grid_ptr^.v_axis_array_ptr^[width, 0];
              Make_vertex_geometry(normal, texture, u_axis, v_axis);
            end;
          for height := 1 to grid_ptr^.height do
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
          Grid_to_reverse_face_geometry(grid_ptr);
        end
      else
        surface_ptr := unit_paraboloid_ptr;
    end
  else
    begin
      {*****************}
      { partial surface }
      {*****************}
      surface_ptr := New_surface(topo_similar, open_surface, smooth_shading);
      surface_ptr^.topology_ptr := Paraboloid_sweep_topology;

      {***************}
      { make geometry }
      {***************}
      surface_ptr^.geometry_ptr := Make_geometry;
      Grid_paraboloid(grid_ptr, umin, umax);

      {*********************}
      { make point geometry }
      {*********************}
      Make_point_geometry(grid_ptr^.point_array_ptr^[0, 0]);
      for height := 1 to grid_ptr^.height do
        for width := 0 to grid_ptr^.width do
          Make_point_geometry(grid_ptr^.point_array_ptr^[width, height]);

      {**********************}
      { make vertex geometry }
      {**********************}
      for width := 0 to (grid_ptr^.width - 1) do
        begin
          normal := grid_ptr^.normal_array_ptr^[width, 0];
          texture := grid_ptr^.texture_array_ptr^[width, 0];
          u_axis := grid_ptr^.u_axis_array_ptr^[width, 0];
          v_axis := grid_ptr^.v_axis_array_ptr^[width, 0];
          Make_vertex_geometry(normal, texture, u_axis, v_axis);
        end;
      for height := 1 to grid_ptr^.height do
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
      Grid_to_reverse_face_geometry(grid_ptr);
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

  Paraboloid_b_rep := surface_ptr;
end; {function Paraboloid_b_rep}


function Hyperboloid1_b_rep(inner_radius: real;
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
      surface_ptr^.topology_ptr := Hyperboloid1_topology;

      {***************}
      { make geometry }
      {***************}
      surface_ptr^.geometry_ptr := Make_geometry;
      Grid_hyperboloid1(grid_ptr, inner_radius, umin, umax);

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
      Grid_to_reverse_face_geometry(grid_ptr);
    end
  else
    begin
      {*****************}
      { partial surface }
      {*****************}
      surface_ptr := New_surface(topo_similar, open_surface, smooth_shading);
      surface_ptr^.topology_ptr := Hyperboloid1_sweep_topology;

      {***************}
      { make geometry }
      {***************}
      surface_ptr^.geometry_ptr := Make_geometry;
      Grid_hyperboloid1(grid_ptr, inner_radius, umin, umax);

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
      Grid_to_reverse_face_geometry(grid_ptr);
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

  Hyperboloid1_b_rep := surface_ptr;
end; {function Hyperboloid1_b_rep}


function Hyperboloid2_b_rep(eccentricity: real;
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
      surface_ptr^.topology_ptr := Paraboloid_topology;

      {***************}
      { make geometry }
      {***************}
      surface_ptr^.geometry_ptr := Make_geometry;
      Grid_hyperboloid2(grid_ptr, eccentricity, umin, umax);

      {*********************}
      { make point geometry }
      {*********************}
      Make_point_geometry(grid_ptr^.point_array_ptr^[0, 0]);
      for height := 1 to grid_ptr^.height do
        for width := 0 to (grid_ptr^.width - 1) do
          Make_point_geometry(grid_ptr^.point_array_ptr^[width, height]);

      {**********************}
      { make vertex geometry }
      {**********************}
      for width := 0 to (grid_ptr^.width - 1) do
        begin
          normal := grid_ptr^.normal_array_ptr^[width, 0];
          texture := grid_ptr^.texture_array_ptr^[width, 0];
          u_axis := grid_ptr^.u_axis_array_ptr^[width, 0];
          v_axis := grid_ptr^.v_axis_array_ptr^[width, 0];
          Make_vertex_geometry(normal, texture, u_axis, v_axis);
        end;
      for height := 1 to grid_ptr^.height do
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
      Grid_to_reverse_face_geometry(grid_ptr);
    end
  else
    begin
      {*****************}
      { partial surface }
      {*****************}
      surface_ptr := New_surface(topo_similar, open_surface, smooth_shading);
      surface_ptr^.topology_ptr := Paraboloid_sweep_topology;

      {***************}
      { make geometry }
      {***************}
      surface_ptr^.geometry_ptr := Make_geometry;
      Grid_hyperboloid2(grid_ptr, eccentricity, umin, umax);

      {*********************}
      { make point geometry }
      {*********************}
      Make_point_geometry(grid_ptr^.point_array_ptr^[0, 0]);
      for height := 1 to grid_ptr^.height do
        for width := 0 to grid_ptr^.width do
          Make_point_geometry(grid_ptr^.point_array_ptr^[width, height]);

      {**********************}
      { make vertex geometry }
      {**********************}
      for width := 0 to (grid_ptr^.width - 1) do
        begin
          normal := grid_ptr^.normal_array_ptr^[width, 0];
          texture := grid_ptr^.texture_array_ptr^[width, 0];
          u_axis := grid_ptr^.u_axis_array_ptr^[width, 0];
          v_axis := grid_ptr^.v_axis_array_ptr^[width, 0];
          Make_vertex_geometry(normal, texture, u_axis, v_axis);
        end;
      for height := 1 to grid_ptr^.height do
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
      Grid_to_reverse_face_geometry(grid_ptr);
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

  Hyperboloid2_b_rep := surface_ptr;
end; {function Hyperboloid2_b_rep}


procedure Force_free_surface(var surface_ptr: surface_ptr_type);
begin
  if (surface_ptr <> nil) then
    begin
      surface_ptr^.kind := topo_similar;
      surface_ptr^.reference_count := 1;
      Free_surface(surface_ptr);
    end;
end; {procedure Force_free_surface}


procedure Free_faceted_quads;
begin
  Force_free_surface(unit_sphere_ptr);
  Force_free_surface(unit_cylinder_ptr);
  Force_free_surface(unit_cone_ptr);
  Force_free_surface(unit_paraboloid_ptr);
end; {procedure Free_faceted_quads}


initialization
  grid_ptr := New_grid;

  {*************************}
  { self-similar primitives }
  {*************************}
  unit_sphere_ptr := nil;
  unit_cylinder_ptr := nil;
  unit_cone_ptr := nil;
  unit_paraboloid_ptr := nil;
end.
