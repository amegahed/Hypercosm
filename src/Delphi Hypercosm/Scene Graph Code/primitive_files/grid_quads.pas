unit grid_quads;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             grid_quads                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The grid module builds a grid representation of         }
{       the geometry of quadric primitives. This is used        }
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
  grid_prims;


{**********}
{ quadrics }
{**********}
procedure Grid_sphere(grid_ptr: grid_ptr_type;
  umin, umax: real;
  vmin, vmax: real);
procedure Grid_cylinder(grid_ptr: grid_ptr_type;
  umin, umax: real);
procedure Grid_cone(grid_ptr: grid_ptr_type;
  inner_radius: real;
  umin, umax: real);
procedure Grid_paraboloid(grid_ptr: grid_ptr_type;
  umin, umax: real);
procedure Grid_hyperboloid1(grid_ptr: grid_ptr_type;
  inner_radius: real;
  umin, umax: real);
procedure Grid_hyperboloid2(grid_ptr: grid_ptr_type;
  eccentricity: real;
  umin, umax: real);


implementation
uses
  trigonometry, vectors;


procedure Grid_sphere(grid_ptr: grid_ptr_type;
  umin, umax: real;
  vmin, vmax: real);
var
  width, height: integer;
  vector: vector_type;
  z, r, u, v: real;
  cos_u, sin_u: real;
begin
  Make_trig_tables;
  if (umin > umax) then
    umin := umin - 360;

  if (umin = 0) and (umax = 360) then
    begin
      {*******************************}
      { complete surface in longitude }
      {*******************************}
      if (vmin = -90) and (vmax = 90) then
        begin
          {*******************************}
          { complete surface in lattitude }
          {*******************************}
          grid_ptr^.width := grid_facets * 2;
          grid_ptr^.height := grid_facets;
          grid_ptr^.h_wraparound := true;
          grid_ptr^.v_wraparound := true;

          for height := 0 to grid_ptr^.height do
            begin
              z := -cosine[height];
              r := sine[height];
              for width := 0 to grid_ptr^.width do
                begin
                  {****************}
                  { geometric data }
                  {****************}
                  vector.x := r * cosine[width];
                  vector.y := r * sine[width];
                  vector.z := z;
                  grid_ptr^.point_array_ptr^[width, height] := vector;
                  grid_ptr^.normal_array_ptr^[width, height] := vector;

                  {**************}
                  { texture data }
                  {**************}
                  vector.x := longitude[width];
                  vector.y := lattitude[height];
                  vector.z := 1;
                  grid_ptr^.texture_array_ptr^[width, height] := vector;
                  vector.x := -sine[width];
                  vector.y := cosine[width];
                  vector.z := 0;
                  grid_ptr^.u_axis_array_ptr^[width, height] := vector;
                  vector.x := -z * cosine[width];
                  vector.y := -z * sine[width];
                  vector.z := r;
                  grid_ptr^.v_axis_array_ptr^[width, height] := vector;
                end;
            end;
        end
      else
        begin
          {******************************}
          { partial surface in lattitude }
          {******************************}
          grid_ptr^.width := grid_facets * 2;
          grid_ptr^.height := grid_facets;
          grid_ptr^.h_wraparound := true;
          grid_ptr^.v_wraparound := false;

          vmin := (90 + vmin) * degrees_to_radians;
          vmax := (90 + vmax) * degrees_to_radians;

          for height := 0 to grid_ptr^.height do
            begin
              v := vmin + (vmax - vmin) * (height / grid_ptr^.height);
              z := -cos(v);
              r := sin(v);
              for width := 0 to grid_ptr^.width do
                begin
                  {****************}
                  { geometric data }
                  {****************}
                  vector.x := r * cosine[width];
                  vector.y := r * sine[width];
                  vector.z := z;
                  grid_ptr^.point_array_ptr^[width, height] := vector;
                  grid_ptr^.normal_array_ptr^[width, height] := vector;

                  {**************}
                  { texture data }
                  {**************}
                  vector.x := longitude[width];
                  vector.y := lattitude[height];
                  vector.z := 1;
                  grid_ptr^.texture_array_ptr^[width, height] := vector;
                  vector.x := -sine[width];
                  vector.y := cosine[width];
                  vector.z := 0;
                  grid_ptr^.u_axis_array_ptr^[width, height] := vector;
                  vector.x := -z * cosine[width];
                  vector.y := -z * sine[width];
                  vector.z := r;
                  grid_ptr^.v_axis_array_ptr^[width, height] := vector;
                end;
            end;
        end;
    end
  else
    begin
      {******************************}
      { partial surface in longitude }
      {******************************}
      if (vmin = -90) and (vmax = 90) then
        begin
          {*******************************}
          { complete surface in lattitude }
          {*******************************}
          grid_ptr^.width := grid_facets * 2;
          grid_ptr^.height := grid_facets;
          grid_ptr^.h_wraparound := false;
          grid_ptr^.v_wraparound := true;

          umin := umin * degrees_to_radians;
          umax := umax * degrees_to_radians;

          for height := 0 to grid_ptr^.height do
            begin
              z := -cosine[height];
              r := sine[height];
              for width := 0 to grid_ptr^.width do
                begin
                  u := umin + (umax - umin) * (width / grid_ptr^.width);
                  cos_u := cos(u);
                  sin_u := sin(u);

                  {****************}
                  { geometric data }
                  {****************}
                  vector.x := r * cos_u;
                  vector.y := r * sin_u;
                  vector.z := z;
                  grid_ptr^.point_array_ptr^[width, height] := vector;
                  grid_ptr^.normal_array_ptr^[width, height] := vector;

                  {**************}
                  { texture data }
                  {**************}
                  vector.x := longitude[width];
                  vector.y := lattitude[height];
                  vector.z := 1;
                  grid_ptr^.texture_array_ptr^[width, height] := vector;
                  vector.x := -sin_u;
                  vector.y := cos_u;
                  vector.z := 0;
                  grid_ptr^.u_axis_array_ptr^[width, height] := vector;
                  vector.x := -z * cos_u;
                  vector.y := -z * sin_u;
                  vector.z := r;
                  grid_ptr^.v_axis_array_ptr^[width, height] := vector;
                end;
            end;
        end
      else
        begin
          {******************************}
          { partial surface in lattitude }
          {******************************}
          grid_ptr^.width := grid_facets * 2;
          grid_ptr^.height := grid_facets;
          grid_ptr^.h_wraparound := false;
          grid_ptr^.v_wraparound := false;

          umin := umin * degrees_to_radians;
          umax := umax * degrees_to_radians;

          vmin := (90 + vmin) * degrees_to_radians;
          vmax := (90 + vmax) * degrees_to_radians;

          for height := 0 to grid_ptr^.height do
            begin
              v := vmin + (vmax - vmin) * (height / grid_ptr^.height);
              z := -cos(v);
              r := sin(v);
              for width := 0 to grid_ptr^.width do
                begin
                  u := umin + (umax - umin) * (width / grid_ptr^.width);
                  cos_u := cos(u);
                  sin_u := sin(u);

                  {****************}
                  { geometric data }
                  {****************}
                  vector.x := r * cos(u);
                  vector.y := r * sin(u);
                  vector.z := z;
                  grid_ptr^.point_array_ptr^[width, height] := vector;
                  grid_ptr^.normal_array_ptr^[width, height] := vector;

                  {**************}
                  { texture data }
                  {**************}
                  vector.x := longitude[width];
                  vector.y := lattitude[height];
                  vector.z := 1;
                  grid_ptr^.texture_array_ptr^[width, height] := vector;
                  vector.x := -sin_u;
                  vector.y := cos_u;
                  vector.z := 0;
                  grid_ptr^.u_axis_array_ptr^[width, height] := vector;
                  vector.x := -z * cos_u;
                  vector.y := -z * sin_u;
                  vector.z := r;
                  grid_ptr^.v_axis_array_ptr^[width, height] := vector;
                end;
            end;
        end;
    end;
end; {procedure Grid_sphere}


procedure Grid_cylinder(grid_ptr: grid_ptr_type;
  umin, umax: real);
var
  width, height: integer;
  vector: vector_type;
  z, u: real;
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

      for height := 0 to grid_ptr^.height do
        begin
          z := (height * 2) - 1;
          for width := 0 to grid_ptr^.width do
            begin
              {****************}
              { geometric data }
              {****************}
              vector.x := cosine[width];
              vector.y := sine[width];
              vector.z := z;
              grid_ptr^.point_array_ptr^[width, height] := vector;
              vector.z := 0;
              grid_ptr^.normal_array_ptr^[width, height] := vector;

              {**************}
              { texture data }
              {**************}
              vector.x := longitude[width];
              vector.y := height;
              vector.z := 1;
              grid_ptr^.texture_array_ptr^[width, height] := vector;
              vector.x := -sine[width];
              vector.y := cosine[width];
              vector.z := 0;
              grid_ptr^.u_axis_array_ptr^[width, height] := vector;
              grid_ptr^.v_axis_array_ptr^[width, height] := z_vector;
            end;
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

      for height := 0 to grid_ptr^.height do
        begin
          z := (height * 2) - 1;
          for width := 0 to grid_ptr^.width do
            begin
              u := umin + (umax - umin) * (width / grid_ptr^.width);
              cos_u := cos(u);
              sin_u := sin(u);

              {****************}
              { geometric data }
              {****************}
              vector.x := cos(u);
              vector.y := sin(u);
              vector.z := z;
              grid_ptr^.point_array_ptr^[width, height] := vector;
              vector.z := 0;
              grid_ptr^.normal_array_ptr^[width, height] := vector;

              {**************}
              { texture data }
              {**************}
              vector.x := longitude[width];
              vector.y := height;
              vector.z := 1;
              grid_ptr^.texture_array_ptr^[width, height] := vector;
              vector.x := -sin_u;
              vector.y := cos_u;
              vector.z := 0;
              grid_ptr^.u_axis_array_ptr^[width, height] := vector;
              grid_ptr^.v_axis_array_ptr^[width, height] := z_vector;
            end;
        end; {for}
    end;
end; {procedure Grid_cylinder}


procedure Grid_cone(grid_ptr: grid_ptr_type;
  inner_radius: real;
  umin, umax: real);
var
  width, height: integer;
  radius_difference: real;
  vector: vector_type;
  z, r, u: real;
  cos_u, sin_u: real;
begin
  Make_trig_tables;
  radius_difference := 1 - inner_radius;
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

      for height := 0 to grid_ptr^.height do
        begin
          z := (height * 2) - 1;
          r := (1 - (radius_difference * height / grid_ptr^.height));
          for width := 0 to grid_ptr^.width do
            begin
              {****************}
              { geometric data }
              {****************}
              vector.x := cosine[width] * r;
              vector.y := sine[width] * r;
              vector.z := z;
              grid_ptr^.point_array_ptr^[width, height] := vector;
              vector.x := cosine[width];
              vector.y := sine[width];
              vector.z := radius_difference / 2;
              grid_ptr^.normal_array_ptr^[width, height] := vector;

              {**************}
              { texture data }
              {**************}
              vector.x := longitude[width];
              vector.y := height;
              vector.z := 1;
              grid_ptr^.texture_array_ptr^[width, height] := vector;
              vector.x := -sine[width];
              vector.y := cosine[width];
              vector.z := 0;
              grid_ptr^.u_axis_array_ptr^[width, height] := vector;
              vector.x := -(radius_difference / 2) * cosine[width];
              vector.y := -(radius_difference / 2) * sine[width];
              vector.z := 1;
              grid_ptr^.v_axis_array_ptr^[width, height] := vector;
            end;
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

      for height := 0 to grid_ptr^.height do
        begin
          z := (height * 2) - 1;
          r := (1 - (radius_difference * height / grid_ptr^.height));
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
              vector.x := cos_u;
              vector.y := sin_u;
              vector.z := radius_difference / 2;
              grid_ptr^.normal_array_ptr^[width, height] := vector;

              {**************}
              { texture data }
              {**************}
              vector.x := longitude[width];
              vector.y := height;
              vector.z := 1;
              grid_ptr^.texture_array_ptr^[width, height] := vector;
              vector.x := -sin_u;
              vector.y := cos_u;
              vector.z := 0;
              grid_ptr^.u_axis_array_ptr^[width, height] := vector;
              vector.x := -(radius_difference / 2) * cos_u;
              vector.y := -(radius_difference / 2) * sin_u;
              vector.z := 1;
              grid_ptr^.v_axis_array_ptr^[width, height] := vector;
            end;
        end; {for}
    end;
end; {procedure Grid_cone}


procedure Grid_paraboloid(grid_ptr: grid_ptr_type;
  umin, umax: real);
var
  width, height: integer;
  vector: vector_type;
  h, z, r, u: real;
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
      grid_ptr^.height := grid_facets;
      grid_ptr^.h_wraparound := true;
      grid_ptr^.v_wraparound := false;

      for height := 0 to grid_ptr^.height do
        begin
          h := 1 - sqr(height / grid_ptr^.height);
          z := (h * 2) - 1;
          r := height / grid_ptr^.height;
          for width := 0 to grid_ptr^.width do
            begin
              {****************}
              { geometric data }
              {****************}
              vector.x := r * cosine[width];
              vector.y := r * sine[width];
              vector.z := z;
              grid_ptr^.point_array_ptr^[width, height] := vector;
              vector.z := 0.25;
              grid_ptr^.normal_array_ptr^[width, height] := vector;

              {**************}
              { texture data }
              {**************}
              vector.x := longitude[width];
              vector.y := reverse_lattitude[height];
              vector.z := 1;
              grid_ptr^.texture_array_ptr^[width, height] := vector;
              vector.x := -sine[width];
              vector.y := cosine[width];
              vector.z := 0;
              grid_ptr^.u_axis_array_ptr^[width, height] := vector;
              vector.x := -cosine[width] * 0.25;
              vector.y := -sine[width] * 0.25;
              vector.z := r;
              grid_ptr^.v_axis_array_ptr^[width, height] := vector;
            end;
        end; {for}
    end
  else
    begin
      {*****************}
      { partial surface }
      {*****************}
      grid_ptr^.width := grid_facets * 2;
      grid_ptr^.height := grid_facets;
      grid_ptr^.h_wraparound := false;
      grid_ptr^.v_wraparound := false;

      umin := umin * degrees_to_radians;
      umax := umax * degrees_to_radians;

      for height := 0 to grid_ptr^.height do
        begin
          h := 1 - sqr(height / grid_ptr^.height);
          z := (h * 2) - 1;
          r := height / grid_ptr^.height;
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
              vector.z := 0.25;
              grid_ptr^.normal_array_ptr^[width, height] := vector;

              {**************}
              { texture data }
              {**************}
              vector.x := longitude[width];
              vector.y := reverse_lattitude[height];
              vector.z := 1;
              grid_ptr^.texture_array_ptr^[width, height] := vector;
              vector.x := -sin_u;
              vector.y := cos_u;
              vector.z := 0;
              grid_ptr^.u_axis_array_ptr^[width, height] := vector;
              vector.x := -cos_u * 0.25;
              vector.y := -sin_u * 0.25;
              vector.z := r;
              grid_ptr^.v_axis_array_ptr^[width, height] := vector;
            end;
        end; {for}
    end;
end; {procedure Grid_paraboloid}


procedure Grid_hyperboloid1(grid_ptr: grid_ptr_type;
  inner_radius: real;
  umin, umax: real);
var
  width, height: integer;
  vector: vector_type;
  z, h, r, r_squared, x: real;
  u, cos_u, sin_u: real;
begin
  Make_trig_tables;
  r_squared := inner_radius * inner_radius;
  if (umin > umax) then
    umin := umin - 360;

  if (umin = 0) and (umax = 360) then
    begin
      {******************}
      { complete surface }
      {******************}
      grid_ptr^.width := grid_facets * 2;
      grid_ptr^.height := grid_facets;
      grid_ptr^.h_wraparound := true;
      grid_ptr^.v_wraparound := false;

      for height := 0 to grid_ptr^.height do
        begin
          h := 1 - (height / grid_ptr^.height);
          z := (h * 2) - 1;
          r := sqrt((r_squared) + (sqr(1 - h) * (1 - r_squared)));

          for width := 0 to grid_ptr^.width do
            begin
              {****************}
              { geometric data }
              {****************}
              vector.x := cosine[width] * r;
              vector.y := sine[width] * r;
              vector.z := z;
              grid_ptr^.point_array_ptr^[width, height] := vector;
              if (inner_radius = 0) then
                begin
                  vector.x := cosine[width];
                  vector.y := sine[width];
                end;
              vector.z := (r_squared - 1.0) / 4.0 * (vector.z - 1.0);
              grid_ptr^.normal_array_ptr^[width, height] := vector;
              x := vector.z * 2;

              {**************}
              { texture data }
              {**************}
              vector.x := longitude[width];
              vector.y := reverse_lattitude[height];
              vector.z := 1;
              grid_ptr^.texture_array_ptr^[width, height] := vector;
              vector.x := -sine[width];
              vector.y := cosine[width];
              vector.z := 0;
              grid_ptr^.u_axis_array_ptr^[width, height] := vector;
              vector.x := -cosine[width] * x;
              vector.y := -sine[width] * x;
              vector.z := r;
              grid_ptr^.v_axis_array_ptr^[width, height] := vector;
            end;
        end; {for}
    end
  else
    begin
      {*****************}
      { partial surface }
      {*****************}
      grid_ptr^.width := grid_facets * 2;
      grid_ptr^.height := grid_facets;
      grid_ptr^.h_wraparound := false;
      grid_ptr^.v_wraparound := false;

      umin := umin * degrees_to_radians;
      umax := umax * degrees_to_radians;

      for height := 0 to grid_ptr^.height do
        begin
          h := 1 - (height / grid_ptr^.height);
          z := (h * 2) - 1;
          r := sqrt((r_squared) + (sqr(1 - h) * (1 - r_squared)));

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
              if (inner_radius = 0) then
                begin
                  vector.x := cos_u;
                  vector.y := sin_u;
                end;
              vector.z := (r_squared - 1.0) / 4.0 * (vector.z - 1.0);
              grid_ptr^.normal_array_ptr^[width, height] := vector;
              x := vector.z * 2;

              {**************}
              { texture data }
              {**************}
              vector.x := longitude[width];
              vector.y := reverse_lattitude[height];
              vector.z := 1;
              grid_ptr^.texture_array_ptr^[width, height] := vector;
              vector.x := -sin_u;
              vector.y := cos_u;
              vector.z := 0;
              grid_ptr^.u_axis_array_ptr^[width, height] := vector;
              vector.x := -cos_u * x;
              vector.y := -sin_u * x;
              vector.z := r;
              grid_ptr^.v_axis_array_ptr^[width, height] := vector;
            end;
        end; {for}
    end;
end; {procedure Grid_hyperboloid1}


procedure Grid_hyperboloid2(grid_ptr: grid_ptr_type;
  eccentricity: real;
  umin, umax: real);
var
  width, height: integer;
  vector: vector_type;
  z, h, r, u, x: real;
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
      grid_ptr^.height := grid_facets;
      grid_ptr^.h_wraparound := true;
      grid_ptr^.v_wraparound := false;

      for height := 0 to grid_ptr^.height do
        begin
          r := height / grid_ptr^.height;
          h := sqrt(sqr(eccentricity) + ((2 * eccentricity) + 1) * r * r) -
            eccentricity;
          z := 1 - (h * 2);
          for width := 0 to grid_ptr^.width do
            begin
              {****************}
              { geometric data }
              {****************}
              vector.x := cosine[width] * r;
              vector.y := sine[width] * r;
              vector.z := z;
              grid_ptr^.point_array_ptr^[width, height] := vector;
              vector.z := sqr(((vector.z + 1) / 2) + eccentricity) / ((4 *
                eccentricity) + 2);
              grid_ptr^.normal_array_ptr^[width, height] := vector;
              x := vector.z;

              {**************}
              { texture data }
              {**************}
              vector.x := longitude[width];
              vector.y := reverse_lattitude[height];
              vector.z := 1;
              grid_ptr^.texture_array_ptr^[width, height] := vector;
              vector.x := -sine[width];
              vector.y := cosine[width];
              vector.z := 0;
              grid_ptr^.u_axis_array_ptr^[width, height] := vector;
              vector.x := -cosine[width] * x;
              vector.y := -sine[width] * x;
              vector.z := r;
              grid_ptr^.v_axis_array_ptr^[width, height] := vector;
            end;
        end; {for}
    end
  else
    begin
      {*****************}
      { partial surface }
      {*****************}
      grid_ptr^.width := grid_facets * 2;
      grid_ptr^.height := grid_facets;
      grid_ptr^.h_wraparound := false;
      grid_ptr^.v_wraparound := false;

      umin := umin * degrees_to_radians;
      umax := umax * degrees_to_radians;

      for height := 0 to grid_ptr^.height do
        begin
          r := height / grid_ptr^.height;
          h := sqrt(sqr(eccentricity) + ((2 * eccentricity) + 1) * r * r) -
            eccentricity;
          z := 1 - (h * 2);
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
              vector.z := sqr(((vector.z + 1) / 2) + eccentricity) / ((4 *
                eccentricity) + 2);
              grid_ptr^.normal_array_ptr^[width, height] := vector;
              x := vector.z;

              {**************}
              { texture data }
              {**************}
              vector.x := longitude[width];
              vector.y := reverse_lattitude[height];
              vector.z := 1;
              grid_ptr^.texture_array_ptr^[width, height] := vector;
              vector.x := -sin_u;
              vector.y := cos_u;
              vector.z := 0;
              grid_ptr^.u_axis_array_ptr^[width, height] := vector;
              vector.x := -cos_u * x;
              vector.y := -sin_u * x;
              vector.z := r;
              grid_ptr^.v_axis_array_ptr^[width, height] := vector;
            end;
        end; {for}
    end;
end; {procedure Grid_hyperboloid2}


end.
