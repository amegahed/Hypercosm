unit grid_prims;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             grid_prims                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The grid module builds a grid representation of         }
{       the geometry of curved primitives. This is used         }
{       to build the b rep structure.                           }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


{***************************************************************}
{       These routines return grids of surfaces of primitives   }
{       that are aligned with thier axis oriented along the     }
{       z axis and scaled so that they fit inside a unit cube.  }
{       (-1 to 1) on x, y, and z.                               }
{***************************************************************}


interface
uses
  vectors;


const
  max_facets = 32;
  min_facets = 4;
  max_grid_size = max_facets * 2;


type
  vector_array_ptr_type = ^vector_array_type;
  vector_array_type = array[0..max_grid_size, 0..max_grid_size] of vector_type;

  grid_ptr_type = ^grid_type;
  grid_type = record
    width, height: integer;
    h_wraparound: boolean;
    v_wraparound: boolean;
    point_array_ptr: vector_array_ptr_type;
    normal_array_ptr: vector_array_ptr_type;
    texture_array_ptr: vector_array_ptr_type;
    u_axis_array_ptr: vector_array_ptr_type;
    v_axis_array_ptr: vector_array_ptr_type;
  end; {grid_type}


  {*************************}
  { trig lookup table stuff }
  {*************************}
type
  lookup_table_type = array[0..max_grid_size] of real;


var
  sine, cosine: lookup_table_type;
  longitude, lattitude: lookup_table_type;
  reverse_lattitude: lookup_table_type;
  grid_facets: integer;


  {*******************************}
  { routines for allocating grids }
  {*******************************}
function New_grid: grid_ptr_type;
procedure Dispose_grid(var grid_ptr: grid_ptr_type);
procedure Write_grid(grid_ptr: grid_ptr_type);

{***************************************}
{ routines for controlling tessellation }
{***************************************}
procedure Set_facets(number: integer);
function Get_facets: integer;
procedure Make_trig_tables;

{*******************}
{ planar primitives }
{*******************}
procedure Grid_plane(grid_ptr: grid_ptr_type);
procedure Grid_disk(grid_ptr: grid_ptr_type;
  umin, umax: real);
procedure Grid_ring(grid_ptr: grid_ptr_type;
  inner_radius: real;
  umin, umax: real);

{***********************}
{ non-planar primitives }
{***********************}
procedure Grid_torus(grid_ptr: grid_ptr_type;
  inner_radius: real;
  umin, umax: real;
  vmin, vmax: real);


implementation
uses
  new_memory, trigonometry;


{*******************************************************}
{                  partial primitives                   }
{*******************************************************}
{       It is possible to specify that portions         }
{       of surfaces be created by giving them a         }
{       min and max in the u, v parameters.             }
{       If we create a partial surface, then lookup     }
{       tables can not be used for the trig fuctions.   }
{*******************************************************}


const
  memory_alert = false;


var
  lookup_table_size: integer;


procedure Make_trig_tables;
var
  counter: integer;
begin
  if (lookup_table_size <> grid_facets) then
    begin
      for counter := 0 to grid_facets * 2 do
        begin
          longitude[counter] := counter / (grid_facets * 2);
          lattitude[counter] := counter / grid_facets;
          reverse_lattitude[counter] := 1 - lattitude[counter];
          sine[counter] := sin(pi * counter / grid_facets);
          cosine[counter] := cos(pi * counter / grid_facets);
        end;
      lookup_table_size := grid_facets;
    end;
end; {procedure Make_trig_tables}


procedure Set_facets(number: integer);
begin
  if (number < 1) then
    number := 1
  else if (number > max_facets) then
    number := max_facets;

  if (number <> grid_facets) then
    begin
      grid_facets := number;
      Make_trig_tables;
    end
  else
    begin
      grid_facets := number;
    end;
end; {procedure Set_facets}


function Get_facets: integer;
begin
  Get_facets := grid_facets;
end; {procedure Get_facets}


function New_grid: grid_ptr_type;
var
  grid_ptr: grid_ptr_type;
begin
  if memory_alert then
    writeln('allocating new grid ');
  new(grid_ptr);

  new(grid_ptr^.point_array_ptr);
  new(grid_ptr^.normal_array_ptr);
  new(grid_ptr^.texture_array_ptr);
  new(grid_ptr^.u_axis_array_ptr);
  new(grid_ptr^.v_axis_array_ptr);

  New_grid := grid_ptr;
end; {function New_grid}


procedure Dispose_grid(var grid_ptr: grid_ptr_type);
begin
  dispose(grid_ptr^.point_array_ptr);
  grid_ptr^.point_array_ptr := nil;

  dispose(grid_ptr^.normal_array_ptr);
  grid_ptr^.normal_array_ptr := nil;

  dispose(grid_ptr^.texture_array_ptr);
  grid_ptr^.texture_array_ptr := nil;

  dispose(grid_ptr);
  grid_ptr := nil;
end; {procedure Dispose_grid}


procedure Write_grid(grid_ptr: grid_ptr_type);
var
  width, height: integer;
begin
  writeln('grid width = ', grid_ptr^.width);
  writeln('grid height = ', grid_ptr^.height);
  writeln('grid h wraparound = ', grid_ptr^.h_wraparound);
  writeln('grid v wraparound = ', grid_ptr^.v_wraparound);

  {*******************}
  { write grid points }
  {*******************}
  for width := 0 to grid_ptr^.width do
    for height := 0 to grid_ptr^.height do
      begin
        with grid_ptr^.point_array_ptr^[width, height] do
          begin
            write('grid point[', width: 1, ', ', height: 1, ' = ');
            writeln(x: 3: 3, ', ', y: 3: 3, ', ', z: 3: 3);
          end;
      end;

  {********************}
  { write grid normals }
  {********************}
  for width := 0 to grid_ptr^.width do
    for height := 0 to grid_ptr^.height do
      begin
        with grid_ptr^.normal_array_ptr^[width, height] do
          begin
            write('grid normal[', width: 1, ', ', height: 1, ' = ');
            writeln(x: 3: 3, ', ', y: 3: 3, ', ', z: 3: 3);
          end;
      end;
end; {procedure Write_grid}


{*******************}
{ planar primitives }
{*******************}


procedure Grid_plane(grid_ptr: grid_ptr_type);
var
  width, height: integer;
  vector: vector_type;
begin
  grid_ptr^.width := grid_facets * 2;
  grid_ptr^.height := grid_facets * 2;
  grid_ptr^.h_wraparound := false;
  grid_ptr^.v_wraparound := false;

  for width := 0 to grid_ptr^.width do
    for height := 0 to grid_ptr^.height do
      begin
        {****************}
        { geometric data }
        {****************}
        vector.x := (width / grid_ptr^.width * 2) - 1;
        vector.y := (height / grid_ptr^.height * 2) - 1;
        vector.z := 0;
        grid_ptr^.point_array_ptr^[width, height] := vector;
        grid_ptr^.normal_array_ptr^[width, height] := z_vector;

        {**************}
        { texture data }
        {**************}
        vector.x := longitude[width];
        vector.y := longitude[height];
        vector.z := 1;
        grid_ptr^.texture_array_ptr^[width, height] := vector;
        grid_ptr^.u_axis_array_ptr^[width, height] := x_vector;
        grid_ptr^.v_axis_array_ptr^[width, height] := y_vector;
      end;
end; {procedure Grid_plane}


procedure Grid_disk(grid_ptr: grid_ptr_type;
  umin, umax: real);
var
  width: integer;
  vector: vector_type;
  u: real;
  cos_u, sin_u: real;
begin
  Make_trig_tables;
  if (umin > umax) then
    umin := umin - 360;

  if (umin = 0) and (umax = 360) then
    begin
      {******************}
      { complete surface }
      {******************}
      grid_ptr^.width := grid_facets * 2;
      grid_ptr^.height := 1;
      grid_ptr^.h_wraparound := true;
      grid_ptr^.v_wraparound := false;

      for width := 0 to grid_ptr^.width do
        begin
          {****************}
          { geometric data }
          {****************}
          grid_ptr^.point_array_ptr^[width, 0] := zero_vector;
          grid_ptr^.normal_array_ptr^[width, 0] := z_vector;
          vector.x := cosine[width];
          vector.y := sine[width];
          vector.z := 0;
          grid_ptr^.point_array_ptr^[width, 1] := vector;
          grid_ptr^.normal_array_ptr^[width, 1] := z_vector;

          {**************}
          { texture data }
          {**************}
          vector.x := longitude[width];
          vector.y := 1;
          vector.z := 1;
          grid_ptr^.texture_array_ptr^[width, 0] := vector;
          vector.y := 0;
          grid_ptr^.texture_array_ptr^[width, 1] := vector;
          vector.x := -sine[width];
          vector.y := cosine[width];
          vector.z := 0;
          grid_ptr^.u_axis_array_ptr^[width, 0] := vector;
          grid_ptr^.u_axis_array_ptr^[width, 1] := vector;
          vector.x := -cosine[width];
          vector.y := -sine[width];
          vector.z := 0;
          grid_ptr^.v_axis_array_ptr^[width, 0] := vector;
          grid_ptr^.v_axis_array_ptr^[width, 1] := vector;
        end;
    end
  else
    begin
      {*****************}
      { partial surface }
      {*****************}
      grid_ptr^.width := grid_facets * 2;
      grid_ptr^.height := 1;
      grid_ptr^.h_wraparound := false;
      grid_ptr^.v_wraparound := false;

      umin := umin * degrees_to_radians;
      umax := umax * degrees_to_radians;

      for width := 0 to grid_ptr^.width do
        begin
          u := umin + (umax - umin) * (width / grid_ptr^.width);
          cos_u := cos(u);
          sin_u := sin(u);

          {****************}
          { geometric data }
          {****************}
          grid_ptr^.point_array_ptr^[width, 0] := zero_vector;
          grid_ptr^.normal_array_ptr^[width, 0] := z_vector;
          vector.x := cos_u;
          vector.y := sin_u;
          vector.z := 0;
          grid_ptr^.point_array_ptr^[width, 1] := vector;
          grid_ptr^.normal_array_ptr^[width, 1] := z_vector;

          {**************}
          { texture data }
          {**************}
          vector.x := longitude[width];
          vector.y := 1;
          vector.z := 1;
          grid_ptr^.texture_array_ptr^[width, 0] := vector;
          vector.y := 0;
          grid_ptr^.texture_array_ptr^[width, 1] := vector;
          vector.x := -sin_u;
          vector.y := cos_u;
          vector.z := 0;
          grid_ptr^.u_axis_array_ptr^[width, 0] := vector;
          grid_ptr^.u_axis_array_ptr^[width, 1] := vector;
          vector.x := -cos_u;
          vector.y := -sin_u;
          vector.z := 0;
          grid_ptr^.v_axis_array_ptr^[width, 0] := vector;
          grid_ptr^.v_axis_array_ptr^[width, 1] := vector;
        end; {for}
    end;
end; {procedure Grid_disk}


procedure Grid_ring(grid_ptr: grid_ptr_type;
  inner_radius: real;
  umin, umax: real);
var
  width: integer;
  vector: vector_type;
  u: real;
  cos_u, sin_u: real;
begin
  Make_trig_tables;
  if (umin > umax) then
    umin := umin - 360;

  if (umin = 0) and (umax = 360) then
    begin
      {******************}
      { complete surface }
      {******************}
      grid_ptr^.width := grid_facets * 2;
      grid_ptr^.height := 1;
      grid_ptr^.h_wraparound := true;
      grid_ptr^.v_wraparound := false;

      for width := 0 to grid_ptr^.width do
        begin
          {****************}
          { geometric data }
          {****************}
          vector.x := cosine[width];
          vector.y := sine[width];
          vector.z := 0;
          grid_ptr^.point_array_ptr^[width, 1] := vector;
          grid_ptr^.normal_array_ptr^[width, 1] := z_vector;

          vector.x := vector.x * inner_radius;
          vector.y := vector.y * inner_radius;
          grid_ptr^.point_array_ptr^[width, 0] := vector;
          grid_ptr^.normal_array_ptr^[width, 0] := z_vector;

          {**************}
          { texture data }
          {**************}
          vector.x := longitude[width];
          vector.y := 0;
          vector.z := 1;
          grid_ptr^.texture_array_ptr^[width, 1] := vector;
          vector.y := 1;
          grid_ptr^.texture_array_ptr^[width, 0] := vector;
          vector.x := -sine[width];
          vector.y := cosine[width];
          vector.z := 0;
          grid_ptr^.u_axis_array_ptr^[width, 0] := vector;
          grid_ptr^.u_axis_array_ptr^[width, 1] := vector;
          vector.x := -cosine[width];
          vector.y := -sine[width];
          vector.z := 0;
          grid_ptr^.v_axis_array_ptr^[width, 0] := vector;
          grid_ptr^.v_axis_array_ptr^[width, 1] := vector;
        end; {for}
    end
  else
    begin
      {*****************}
      { partial surface }
      {*****************}
      grid_ptr^.width := grid_facets * 2;
      grid_ptr^.height := 1;
      grid_ptr^.h_wraparound := false;
      grid_ptr^.v_wraparound := false;

      umin := umin * degrees_to_radians;
      umax := umax * degrees_to_radians;

      for width := 0 to grid_ptr^.width do
        begin
          u := umin + (umax - umin) * (width / grid_ptr^.width);
          cos_u := cos(u);
          sin_u := sin(u);

          {****************}
          { geometric data }
          {****************}
          vector.x := cos_u;
          vector.y := sin_u;
          vector.z := 0;
          grid_ptr^.point_array_ptr^[width, 1] := vector;
          grid_ptr^.normal_array_ptr^[width, 1] := z_vector;

          vector.x := vector.x * inner_radius;
          vector.y := vector.y * inner_radius;
          grid_ptr^.point_array_ptr^[width, 0] := vector;
          grid_ptr^.normal_array_ptr^[width, 0] := z_vector;

          {**************}
          { texture data }
          {**************}
          vector.x := longitude[width];
          vector.y := 0;
          vector.z := 1;
          grid_ptr^.texture_array_ptr^[width, 1] := vector;
          vector.y := 1;
          grid_ptr^.texture_array_ptr^[width, 0] := vector;
          vector.x := -sin_u;
          vector.y := cos_u;
          vector.z := 0;
          grid_ptr^.u_axis_array_ptr^[width, 0] := vector;
          grid_ptr^.u_axis_array_ptr^[width, 1] := vector;
          vector.x := -cos_u;
          vector.y := -sin_u;
          vector.z := 0;
          grid_ptr^.v_axis_array_ptr^[width, 0] := vector;
          grid_ptr^.v_axis_array_ptr^[width, 1] := vector;
        end; {for}
    end;
end; {procedure Grid_ring}


{***********************}
{ non-planar primitives }
{***********************}


procedure Grid_torus(grid_ptr: grid_ptr_type;
  inner_radius: real;
  umin, umax: real;
  vmin, vmax: real);
var
  width, height: integer;
  vector, normal: vector_type;
  z, r, u, v: real;
  cos_u, sin_u: real;
  cos_v, sin_v: real;
  inner_r_squared: real;
  center_radius: real;
begin
  Make_trig_tables;
  inner_r_squared := inner_radius * inner_radius;
  center_radius := 1 - inner_radius;
  if (umin > umax) then
    umin := umin - 360;
  if (vmin > vmax) then
    vmin := vmin - 360;

  if (umin = 0) and (umax = 360) then
    begin
      {*******************************}
      { complete surface in longitude }
      {*******************************}
      if (vmin = 0) and (vmax = 360) then
        begin
          {*******************************}
          { complete surface in lattitude }
          {*******************************}
          grid_ptr^.width := grid_facets * 2;
          grid_ptr^.height := grid_facets * 2;
          grid_ptr^.h_wraparound := true;
          grid_ptr^.v_wraparound := true;

          for height := 0 to grid_ptr^.height do
            begin
              z := sine[height];
              r := center_radius + (cosine[height] * inner_radius);
              for width := 0 to grid_ptr^.width do
                begin
                  {****************}
                  { geometric data }
                  {****************}
                  vector.x := cosine[width] * r;
                  vector.y := sine[width] * r;
                  vector.z := z;
                  grid_ptr^.point_array_ptr^[width, height] := vector;
                  vector.x := vector.x - (cosine[width] * center_radius);
                  vector.y := vector.y - (sine[width] * center_radius);
                  vector.z := z * inner_r_squared;
                  grid_ptr^.normal_array_ptr^[width, height] := vector;
                  normal := vector;

                  {**************}
                  { texture data }
                  {**************}
                  vector.x := longitude[width];
                  vector.y := longitude[height];
                  vector.z := 1;
                  grid_ptr^.texture_array_ptr^[width, height] := vector;
                  vector.x := -sine[width];
                  vector.y := cosine[width];
                  vector.z := 0;
                  grid_ptr^.u_axis_array_ptr^[width, height] := vector;
                  vector.x := -cosine[width] * sine[height];
                  vector.y := -sine[width] * sine[height];
                  vector.z := cosine[height] / inner_radius;
                  grid_ptr^.v_axis_array_ptr^[width, height] := vector;
                end;
            end; {for}
        end
      else
        begin
          {******************************}
          { partial surface in lattitude }
          {******************************}
          grid_ptr^.width := grid_facets * 2;
          grid_ptr^.height := grid_facets * 2;
          grid_ptr^.h_wraparound := true;
          grid_ptr^.v_wraparound := false;

          vmin := vmin * degrees_to_radians;
          vmax := vmax * degrees_to_radians;

          for height := 0 to grid_ptr^.height do
            begin
              v := vmin + (vmax - vmin) * (height / grid_ptr^.height);
              cos_v := cos(v);
              sin_v := sin(v);
              z := sin_v;
              r := center_radius + (cos_v * inner_radius);
              for width := 0 to grid_ptr^.width do
                begin
                  {****************}
                  { geometric data }
                  {****************}
                  vector.x := cosine[width] * r;
                  vector.y := sine[width] * r;
                  vector.z := z;
                  grid_ptr^.point_array_ptr^[width, height] := vector;
                  vector.x := vector.x - (cosine[width] * center_radius);
                  vector.y := vector.y - (sine[width] * center_radius);
                  vector.z := z * inner_r_squared;
                  grid_ptr^.normal_array_ptr^[width, height] := vector;

                  {**************}
                  { texture data }
                  {**************}
                  vector.x := longitude[width];
                  vector.y := longitude[height];
                  vector.z := 1;
                  grid_ptr^.texture_array_ptr^[width, height] := vector;
                  vector.x := -sine[width];
                  vector.y := cosine[width];
                  vector.z := 0;
                  grid_ptr^.u_axis_array_ptr^[width, height] := vector;
                  vector.x := -cosine[width] * sin_v;
                  vector.y := -sine[width] * sin_v;
                  vector.z := cos_v / inner_radius;
                  grid_ptr^.v_axis_array_ptr^[width, height] := vector;
                end;
            end; {for}
        end;
    end
  else
    begin
      {******************************}
      { partial surface in longitude }
      {******************************}
      if (vmin = 0) and (vmax = 360) then
        begin
          {*******************************}
          { complete surface in lattitude }
          {*******************************}
          grid_ptr^.width := grid_facets * 2;
          grid_ptr^.height := grid_facets * 2;
          grid_ptr^.h_wraparound := false;
          grid_ptr^.v_wraparound := true;

          umin := umin * degrees_to_radians;
          umax := umax * degrees_to_radians;

          for height := 0 to grid_ptr^.height do
            begin
              z := sine[height];
              r := center_radius + (cosine[height] * inner_radius);
              for width := 0 to grid_ptr^.width do
                begin
                  u := umin + (umax - umin) * (width / grid_ptr^.width);
                  cos_u := cos(u);
                  sin_u := sin(u);

                  {****************}
                  { geometric data }
                  {****************}
                  vector.x := cos_u * r;
                  vector.y := sin_u * r;
                  vector.z := z;
                  grid_ptr^.point_array_ptr^[width, height] := vector;
                  vector.x := vector.x - (cos_u * center_radius);
                  vector.y := vector.y - (sin_u * center_radius);
                  vector.z := z * inner_r_squared;
                  grid_ptr^.normal_array_ptr^[width, height] := vector;

                  {**************}
                  { texture data }
                  {**************}
                  vector.x := longitude[width];
                  vector.y := longitude[height];
                  vector.z := 1;
                  grid_ptr^.texture_array_ptr^[width, height] := vector;
                  vector.x := -sin_u;
                  vector.y := cos_u;
                  vector.z := 0;
                  grid_ptr^.u_axis_array_ptr^[width, height] := vector;
                  vector.x := -cos_u * sine[height];
                  vector.y := -sin_u * sine[height];
                  vector.z := cosine[height] / inner_radius;
                  grid_ptr^.v_axis_array_ptr^[width, height] := vector;
                end;
            end; {for}
        end
      else
        begin
          {******************************}
          { partial surface in lattitude }
          {******************************}
          grid_ptr^.width := grid_facets * 2;
          grid_ptr^.height := grid_facets * 2;
          grid_ptr^.h_wraparound := false;
          grid_ptr^.v_wraparound := false;

          umin := umin * degrees_to_radians;
          umax := umax * degrees_to_radians;

          vmin := vmin * degrees_to_radians;
          vmax := vmax * degrees_to_radians;

          for height := 0 to grid_ptr^.height do
            begin
              v := vmin + (vmax - vmin) * (height / grid_ptr^.height);
              cos_v := cos(v);
              sin_v := sin(v);
              z := sin_v;
              r := center_radius + (cos_v * inner_radius);
              for width := 0 to grid_ptr^.width do
                begin
                  u := umin + (umax - umin) * (width / grid_ptr^.width);
                  cos_u := cos(u);
                  sin_u := sin(u);

                  {****************}
                  { geometric data }
                  {****************}
                  vector.x := cos_u * r;
                  vector.y := sin_u * r;
                  vector.z := z;
                  grid_ptr^.point_array_ptr^[width, height] := vector;
                  vector.x := vector.x - (cos_u * center_radius);
                  vector.y := vector.y - (sin_u * center_radius);
                  vector.z := z * inner_r_squared;
                  grid_ptr^.normal_array_ptr^[width, height] := vector;

                  {**************}
                  { texture data }
                  {**************}
                  vector.x := longitude[width];
                  vector.y := longitude[height];
                  vector.z := 1;
                  grid_ptr^.texture_array_ptr^[width, height] := vector;
                  vector.x := -sin_u;
                  vector.y := cos_u;
                  vector.z := 0;
                  grid_ptr^.u_axis_array_ptr^[width, height] := vector;
                  vector.x := -cos_u * sin_v;
                  vector.y := -sin_u * sin_v;
                  vector.z := cos_v / inner_radius;
                  grid_ptr^.v_axis_array_ptr^[width, height] := vector;
                end;
            end; {for}
        end;
    end;
end; {procedure Grid_torus}


initialization
  lookup_table_size := 0;
  grid_facets := 1;
end.
