unit normals;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              normals                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The normals module is used to find surface normals      }
{       of the ray tracing objects.                             }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, raytrace;


function Find_surface_normal(object_ptr: ray_object_inst_ptr_type;
  local_point: vector_type): vector_type;
procedure Find_surface_vectors(object_ptr: ray_object_inst_ptr_type;
  local_point, local_normal: vector_type;
  var u_axis, v_axis: vector_type);


implementation
uses
  volumes, objects;


function Find_surface_normal(object_ptr: ray_object_inst_ptr_type;
  local_point: vector_type): vector_type;
var
  normal: vector_type;
  r, e: real;
  metaball_ptr: metaball_ptr_type;
  point: vector_type;
  factor: real;
begin
  case object_ptr^.kind of

    {********************}
    { quadric primitives }
    {********************}

    sphere:
      begin
        normal := local_point;
      end;

    cylinder:
      begin
        normal.x := local_point.x;
        normal.y := local_point.y;
        normal.z := 0;
      end;

    cone:
      begin
        r := object_ptr^.inner_radius;
        normal.x := local_point.x;
        normal.y := local_point.y;
        normal.z := (1 + (r - 1) * ((local_point.z + 1) / 2)) * (1 - r) / 2;
      end;

    paraboloid:
      begin
        normal.x := local_point.x;
        normal.y := local_point.y;
        normal.z := 0.25;
      end;

    hyperboloid1:
      begin
        r := object_ptr^.inner_radius;
        normal.x := local_point.x;
        normal.y := local_point.y;
        normal.z := -(r * r - 1.0) / 8.0 * (1.0 - local_point.z);
      end;

    hyperboloid2:
      begin
        e := object_ptr^.eccentricity;
        normal.x := local_point.x;
        normal.y := local_point.y;
        normal.z := SQR((1.0 - local_point.z) / 2.0 + e) / (4.0 * e + 2.0);
      end;

    {*******************}
    { planar primitives }
    {*******************}

    plane, disk, ring, triangle, parallelogram, flat_polygon:
      begin
        normal := z_vector;
      end;

    {***********************}
    { non-planar primitives }
    {***********************}

    torus:
      begin
        r := object_ptr^.inner_radius;
        normal.x := local_point.x;
        normal.y := local_point.y;
        normal.z := 0;
        local_point.z := local_point.z * r;
        normal := Vector_scale(Normalize(normal), 1 - r);
        normal := Vector_difference(local_point, normal);
        normal.z := normal.z * r;
      end;

    block:
      begin
        if abs(local_point.x) > abs(local_point.z) then
          begin
            {********}
            { x or y }
            {********}
            if abs(local_point.x) > abs(local_point.y) then
              normal := x_vector
            else
              normal := y_vector;
          end
        else
          begin
            {********}
            { y or z }
            {********}
            if abs(local_point.y) > abs(local_point.z) then
              normal := y_vector
            else
              normal := z_vector;
          end;
      end;

    shaded_triangle:
      begin
        normal := Interpolate(object_ptr^.triangle_interpolation_ptr^);
      end;

    shaded_polygon:
      begin
        normal :=
          Interpolate(object_ptr^.ray_mesh_data_ptr^.normal_interpolation);
      end;

    mesh:
      begin
        if not object_ptr^.smoothing then
          normal := object_ptr^.ray_mesh_data_ptr^.mesh_normal
        else
          normal :=
            Interpolate(object_ptr^.ray_mesh_data_ptr^.normal_interpolation);
      end;

    blob:
      begin
        normal := zero_vector;
        metaball_ptr := object_ptr^.metaball_ptr;
        local_point := Vector_scale2(local_point, object_ptr^.dimensions);

        while (metaball_ptr <> nil) do
          begin
            point := Vector_difference(local_point, metaball_ptr^.center);
            r := Dot_product(point, point);
            with metaball_ptr^ do
              begin
                if (r < radius_squared) then
                  begin
                    factor := -2.0 * (2.0 * c4 * r + c2);
                    normal := Vector_sum(normal, Vector_scale(point, factor));
                  end;
              end;

            metaball_ptr := metaball_ptr^.next;
          end;
      end;

    {************************}
    { non_surface primitives }
    {************************}
    points, lines:
      begin
        normal := z_vector;
      end;

    volume:
      begin
        if not object_ptr^.volume_ptr^.smoothing then
          normal := object_ptr^.ray_mesh_data_ptr^.mesh_normal
        else
          normal :=
            Interpolate(object_ptr^.ray_mesh_data_ptr^.normal_interpolation);
      end;

  end; {case statement}

  Find_surface_normal := normal;
end; {function Find_surface_normal}


{***************}
{ frame mapping }
{***************}


procedure Find_surface_vectors(object_ptr: ray_object_inst_ptr_type;
  local_point, local_normal: vector_type;
  var u_axis, v_axis: vector_type);
begin
  case object_ptr^.kind of

    {********************}
    { quadric primitives }
    {********************}

    sphere:
      begin
        u_axis.x := -local_point.y;
        u_axis.y := local_point.x;
        u_axis.z := 0;
        v_axis := Cross_product(local_normal, u_axis)
      end;

    cylinder:
      begin
        u_axis.x := -local_point.y;
        u_axis.y := local_point.x;
        u_axis.z := 0;
        v_axis := z_vector;
      end;

    cone, paraboloid, hyperboloid1, hyperboloid2:
      begin
        u_axis.x := -local_point.y;
        u_axis.y := local_point.x;
        u_axis.z := 0;
        v_axis := Cross_product(local_normal, u_axis);
      end;

    {*******************}
    { planar primitives }
    {*******************}

    plane, triangle, parallelogram:
      begin
        u_axis := x_vector;
        v_axis := y_vector;
      end;

    disk, ring:
      begin
        u_axis.x := -local_point.y;
        u_axis.y := local_point.x;
        u_axis.z := 0;
        v_axis.x := -u_axis.y;
        v_axis.y := u_axis.x;
        v_axis.z := 0;
      end;

    flat_polygon:
      with object_ptr^.ray_mesh_data_ptr^ do
        begin
          u_axis := Interpolate(u_axis_interpolation);
          v_axis := Interpolate(v_axis_interpolation);
        end;

    {***********************}
    { non-planar primitives }
    {***********************}

    torus:
      begin
        u_axis.x := -local_point.y;
        u_axis.y := local_point.x;
        u_axis.z := 0;
        v_axis := Cross_product(local_normal, u_axis);
      end;

    block:
      begin
        if (local_normal.x <> 0) or (local_normal.y <> 0) then
          begin
            {********************************}
            { left, right, front, back sides }
            {********************************}
            u_axis := Cross_product(local_normal, z_vector);
            v_axis := z_vector;
          end
        else
          begin
            {**********************}
            { bottom and top sides }
            {**********************}
            u_axis := x_vector;
            v_axis := Cross_product(local_normal, x_vector);
          end;
      end;

    shaded_triangle:
      begin
        u_axis := x_vector;
        v_axis := y_vector;
      end;

    shaded_polygon:
      with object_ptr^.ray_mesh_data_ptr^ do
        begin
          u_axis := Interpolate(u_axis_interpolation);
          v_axis := Interpolate(v_axis_interpolation);
        end;

    mesh:
      with object_ptr^.ray_mesh_data_ptr^ do
        begin
          u_axis := Interpolate(u_axis_interpolation);
          v_axis := Interpolate(v_axis_interpolation);
        end;

    blob:
      begin
        u_axis.x := -local_point.y;
        u_axis.y := local_point.x;
        u_axis.z := 0;
        v_axis := Cross_product(local_normal, u_axis);
      end;

    {************************}
    { non_surface primitives }
    {************************}
    points, lines:
      begin
        u_axis := x_vector;
        v_axis := y_vector;
      end;

    volume:
      with object_ptr^.ray_mesh_data_ptr^ do
        begin
          u_axis := Interpolate(u_axis_interpolation);
          v_axis := Interpolate(v_axis_interpolation);
        end;

  end; {case statement}
end; {procedure Find_surface_vectors}


end.
