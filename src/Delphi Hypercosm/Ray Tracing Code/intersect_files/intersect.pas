unit intersect;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             intersect                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The intersect module is the heart of the ray tracer     }
{       and is used to find intersections between rays and      }
{       primitive objects.                                      }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  rays, trans, raytrace;


var
  closest_local_ray: ray_type;
  closest_t: real;


{***********************************************}
{ closest intersection is used for primary rays }
{ and secondary rays for objects which dont     }
{ shadow or reflect themselves.                 }
{***********************************************}
function Closest_intersection(ray: ray_type;
  tmin, tmax: real;
  object_ptr: ray_object_inst_ptr_type): real;

{**********************************************}
{ second closest intersection is used for self }
{ shadowing and self-reflecting objects        }
{**********************************************}
function Second_closest_intersection(ray: ray_type;
  tmin, tmax: real;
  object_ptr: ray_object_inst_ptr_type): real;

{**********************************************}
{ returns the span through the convex clipping }
{ region which the ray intersects.             }
{**********************************************}
procedure Find_clipping_span(var ray: ray_type;
  var tmin, tmax: real;
  object_ptr: ray_object_inst_ptr_type);


implementation
uses
  constants, vectors, binormals, vectors2, rays2, trans2, coord_axes, project,
  polygons, objects, quadric_tracer, quartic_tracer, planar_tracer,
  nonplanar_tracer, tri_tracer, mesh_tracer;


const
  memory_alert = false;


  {********************************************}
  { do we want to renormalize the ray on a per }
  { primitive basis - more accurate and less   }
  { sensitive to dynamic range but expensive.  }
  {********************************************}
  renormalize = false;


function Closest_point_on_ray2(ray: ray2_type;
  point: vector2_type): real;
var
  point1: vector2_type;
  temp: real;
  t: real;
begin
  {*********************************}
  { return the closest point on the }
  { line to the specified point.    }
  {*********************************}
  point1 := Vector2_difference(ray.location, point);

  {*************************************}
  { for line with endpoints, p1, p2:    }
  { line = p1 + v*t where v = (p2 - p1) }
  { dist to origin, d = (p1 + v * t)^2  }
  { d = p1^2 + 2*p1*v*t + v^2*t^2       }
  { dd/dt = v*p1*v + 2*v^2*t = 0        }
  {                                     }
  { dd/dt = 0 because at the closest    }
  { point, the distance will reach a    }
  { local minimum and the change in     }
  { distance will momentarily be 0.     }
  {                                     }
  { 0 = (p1*v) + (v*v)*t                }
  { t = -(p1*v) / (v*v)                 }
  {*************************************}
  temp := Dot_product2(ray.direction, ray.direction);
  t := -Dot_product2(point1, ray.direction) / temp;

  Closest_point_on_ray2 := t;
end; {function Closest_point_on_ray2}


function Closest_point_on_ray(ray: ray_type;
  point: vector_type): real;
var
  point1: vector_type;
  temp: real;
  t: real;
begin
  {*********************************}
  { return the closest point on the }
  { line to the specified point.    }
  {*********************************}
  point1 := Vector_difference(ray.location, point);

  {*************************************}
  { for line with endpoints, p1, p2:    }
  { line = p1 + v*t where v = (p2 - p1) }
  { dist to origin, d = (p1 + v * t)^2  }
  { d = p1^2 + 2*p1*v*t + v^2*t^2       }
  { dd/dt = v*p1*v + 2*v^2*t = 0        }
  {                                     }
  { dd/dt = 0 because at the closest    }
  { point, the distance will reach a    }
  { local minimum and the change in     }
  { distance will momentarily be 0.     }
  {                                     }
  { 0 = (p1*v) + (v*v)*t                }
  { t = -(p1*v) / (v*v)                 }
  {*************************************}
  temp := Dot_product(ray.direction, ray.direction);
  t := -Dot_product(point1, ray.direction) / temp;

  Closest_point_on_ray := t;
end; {function Closest_point_on_ray}


{************************}
{ non-surface primitives }
{************************}


function Point_intersection(ray: ray_type;
  tmin, tmax: real;
  point_vertex_ptr: point_vertex_ptr_type;
  original_ray: ray_type;
  point_axes: coord_axes_type): real;
var
  follow: point_vertex_ptr_type;
  vector1, vector2, vector: vector2_type;
  point1, point2: vector_type;
  t, new_t: real;
  binormal: binormal_type;
  trans: trans_type;
  ray_axes: coord_axes_type;
  size: real;
begin
  {***************************************}
  { compute transformation to axes of ray }
  {***************************************}
  Transform_ray_from_axes(original_ray, point_axes);
  binormal := Normal_to_binormal(original_ray.direction);
  trans.origin := original_ray.location;
  trans.x_axis := Normalize(binormal.x_axis);
  trans.z_axis := Normalize(binormal.y_axis);
  trans.y_axis := Normalize(original_ray.direction);
  ray_axes := Trans_to_axes(trans);

  {*******************************************}
  { transform world coord trans to eye coords }
  {*******************************************}
  Transform_axes_to_axes(point_axes, ray_axes);

  t := tmax;
  follow := point_vertex_ptr;

  while (follow <> nil) do
    begin
      new_t := Closest_point_on_ray(ray, follow^.point);
      if (new_t > tmin) and (new_t < t) then
        begin
          {**************************************************}
          { project closest point on ray and point to screen }
          { and compare the distace of their projections     }
          {**************************************************}
          point1 := Vector_sum(ray.location, Vector_scale(ray.direction,
            new_t));
          point2 := follow^.point;

          {*************************}
          { transform to eye coords }
          {*************************}
          Transform_point_from_axes(point1, point_axes);
          Transform_point_from_axes(point2, point_axes);

          {***********************************************}
          { if closer than a half pixel then intersection }
          {***********************************************}
          vector1 := Project_point_to_point2(point1);
          vector2 := Project_point_to_point2(point2);
          vector := Vector2_difference(vector2, vector1);
          size := Dot_product2(vector, vector);
          if (size < 0.5) then
            begin
              t := new_t;
            end;
        end;
      follow := follow^.next;
    end;

  {***********************}
  { no intersection found }
  {***********************}
  if (t = tmax) then
    t := infinity;

  Point_intersection := t;
end; {function Point_intersection}


function Line_intersection(ray: ray_type;
  tmin, tmax: real;
  line_vertex_ptr: line_vertex_ptr_type;
  original_ray: ray_type;
  point_axes: coord_axes_type): real;
var
  line: ray2_type;
  follow: line_vertex_ptr_type;
  vertex1, vertex2: vector_type;
  trans_vertex1, trans_vertex2: vector_type;
  vector1, vector2, vector: vector2_type;
  point, point1, point2: vector_type;
  t, new_t, line_t: real;
  binormal: binormal_type;
  trans: trans_type;
  ray_axes, local_ray_axes: coord_axes_type;
  size: real;
begin
  {***************************************}
  { compute transformation to axes of ray }
  {***************************************}
  Transform_ray_from_axes(original_ray, point_axes);
  binormal := Normal_to_binormal(original_ray.direction);
  trans.origin := original_ray.location;
  trans.x_axis := Normalize(binormal.x_axis);
  trans.z_axis := Normalize(binormal.y_axis);
  trans.y_axis := Normalize(original_ray.direction);
  ray_axes := Trans_to_axes(trans);

  {*******************************************}
  { transform world coord trans to eye coords }
  {*******************************************}
  Transform_axes_to_axes(point_axes, ray_axes);

  {*********************************************}
  { compute transformation to axes of local ray }
  {*********************************************}
  binormal := Normal_to_binormal(ray.direction);
  trans.origin := ray.location;
  trans.x_axis := binormal.x_axis;
  trans.y_axis := binormal.y_axis;
  trans.z_axis := ray.direction;
  local_ray_axes := Trans_to_axes(trans);

  t := tmax;
  follow := line_vertex_ptr;

  vertex2 := follow^.point;
  trans_vertex2 := vertex2;
  Transform_point_to_axes(trans_vertex2, local_ray_axes);
  follow := follow^.next;

  while (follow <> nil) do
    begin
      vertex1 := vertex2;
      trans_vertex1 := trans_vertex2;

      vertex2 := follow^.point;
      trans_vertex2 := vertex2;
      Transform_point_to_axes(trans_vertex2, local_ray_axes);

      {*******************************************}
      { find where on line ray approaches closest }
      {*******************************************}
      line.location.x := trans_vertex1.x;
      line.location.y := trans_vertex1.y;
      line.direction.x := trans_vertex2.x - trans_vertex1.x;
      line.direction.y := trans_vertex2.y - trans_vertex1.y;
      line_t := Closest_point_on_ray2(line, zero_vector2);

      if (line_t > 0) and (line_t < 1) then
        begin
          {*******************************************}
          { find where on ray line approaches closest }
          {*******************************************}
          point := Vector_sum(vertex1, Vector_scale(Vector_difference(vertex2,
            vertex1), line_t));
          new_t := Closest_point_on_ray(ray, point);
          if (new_t > tmin) and (new_t < t) then
            begin
              {**************************************************}
              { project closest point on ray and point to screen }
              { and compare the distace of their projections     }
              {**************************************************}
              point1 := Vector_sum(ray.location, Vector_scale(ray.direction,
                new_t));
              point2 := point;

              {*************************}
              { transform to eye coords }
              {*************************}
              Transform_point_from_axes(point1, point_axes);
              Transform_point_from_axes(point2, point_axes);

              {***********************************************}
              { if closer than a half pixel then intersection }
              {***********************************************}
              vector1 := Project_point_to_point2(point1);
              vector2 := Project_point_to_point2(point2);
              vector := Vector2_difference(vector2, vector1);
              size := Dot_product2(vector, vector);
              if (size < 0.5) then
                begin
                  t := new_t;
                end;
            end;
        end;
      follow := follow^.next;
    end;

  {***********************}
  { no intersection found }
  {***********************}
  if (t = tmax) then
    t := infinity;

  Line_intersection := t;
end; {function Line_intersection}


function Max_component(vector: vector_type): real;
var
  max: real;
  y_component, z_component: real;
begin
  max := abs(vector.x);
  y_component := abs(vector.y);
  z_component := abs(vector.z);

  if (y_component > max) then
    max := y_component;
  if (z_component > max) then
    max := z_component;

  Max_component := max;
end; {function Max_component}


function Closest_intersection(ray: ray_type;
  tmin, tmax: real;
  object_ptr: ray_object_inst_ptr_type): real;
var
  t: real;
begin
  t := 0;

  {**********************************************}
  { transform point to local coords of primitive }
  {**********************************************}
  Transform_vector_to_axes(ray.direction, object_ptr^.coord_axes);
  Transform_point_to_axes(ray.location, object_ptr^.coord_axes);

  {*********************}
  { cheap normalization }
  {*********************}
  {
  if renormalize then
    begin
      max := Max_component(ray.direction);
      ray.direction := Vector_scale(ray.direction, 1 / max);
    end;
  }

  with object_ptr^ do
    if (ray_mesh_data_ptr <> nil) and (kind in curved_prims) then
      begin
        {********************************************************}
        { raytrace tessellated (non-triangulated) representation }
        {********************************************************}
        with ray_mesh_data_ptr^ do
          t := Fast_mesh_intersection(ray, tmin, tmax, mesh_voxel_ptr);
      end
    else
      begin
        {*******************************}
        { raytrace exact representation }
        {*******************************}
        case kind of

          complex_object:
            t := Unit_cube_intersection(ray, tmin, tmax, closest);

          {********************}
          { quadric primitives }
          {********************}

          sphere:
            t := Sphere_intersection(ray, tmin, tmax, closest, umin, umax, vmin,
              vmax);

          cylinder:
            t := Cylinder_intersection(ray, tmin, tmax, closest, umin, umax);

          cone:
            t := Cone_intersection(ray, tmin, tmax, closest, inner_radius, umin,
              umax);

          paraboloid:
            t := Paraboloid_intersection(ray, tmin, tmax, closest, umin, umax);

          hyperboloid1:
            t := Hyperboloid1_intersection(ray, tmin, tmax, closest,
              inner_radius, umin, umax);

          hyperboloid2:
            t := Hyperboloid2_intersection(ray, tmin, tmax, closest,
              eccentricity, umin, umax);

          {*******************}
          { planar primitives }
          {*******************}

          plane:
            t := Plane_intersection(ray, tmin, tmax);

          disk:
            t := Disk_intersection(ray, tmin, tmax, umin, umax);

          ring:
            t := Ring_intersection(ray, tmin, tmax, inner_radius, umin, umax);

          triangle:
            t := Triangle_intersection(ray, tmin, tmax);

          parallelogram:
            t := Parallelogram_intersection(ray, tmin, tmax);

          flat_polygon:
            t := Polygon_triangle_intersection(ray, tmin, tmax,
              ray_mesh_data_ptr^.triangle_ptr);

          {***********************}
          { non_planar primitives }
          {***********************}

          torus:
            t := Torus_intersection(ray, tmin, tmax, closest, inner_radius,
              umin, umax, vmin, vmax);

          block:
            t := Unit_cube_intersection(ray, tmin, tmax, closest);

          shaded_triangle:
            t := Shaded_triangle_intersection(ray, tmin, tmax,
              triangle_normal_ptr);

          shaded_polygon:
            t := Shaded_polygon_triangle_intersection(ray, tmin, tmax,
              ray_mesh_data_ptr^.triangle_ptr);

          mesh:
            begin
              with ray_mesh_data_ptr^ do
                if not smoothing then
                  t := Triangle_mesh_intersection(ray, tmin, tmax,
                    triangle_voxel_ptr, last_ray_normal,
                    last_ray_texture_interpolation,
                      last_ray_u_axis_interpolation,
                    last_ray_v_axis_interpolation)
                else
                  t := Smooth_triangle_mesh_intersection(ray, tmin, tmax,
                    triangle_voxel_ptr, last_ray_normal_interpolation,
                    last_ray_texture_interpolation,
                      last_ray_u_axis_interpolation,
                    last_ray_v_axis_interpolation);
            end;

          blob:
            t := Blob_intersection(ray, tmin, tmax, closest, metaball_ptr,
              threshold, dimensions);

          {************************}
          { non_surface primitives }
          {************************}

          points:
            {t := Point_intersection(ray, tmin, tmax, points_ptr^.vertex_ptr, ray, coord_axes);}
            t := infinity;

          lines:
            {t := Line_intersection(ray, tmin, tmax, lines_ptr^.vertex_ptr, ray, coord_axes);}
            t := infinity;

          volume:
            begin
              with ray_mesh_data_ptr^ do
                if not volume_ptr^.smoothing then
                  t := Triangle_mesh_intersection(ray, tmin, tmax,
                    triangle_voxel_ptr, last_ray_normal,
                    last_ray_texture_interpolation,
                      last_ray_u_axis_interpolation,
                    last_ray_v_axis_interpolation)
                else
                  t := Smooth_triangle_mesh_intersection(ray, tmin, tmax,
                    triangle_voxel_ptr, last_ray_normal_interpolation,
                    last_ray_texture_interpolation,
                      last_ray_u_axis_interpolation,
                    last_ray_v_axis_interpolation);
            end;

        end; {case statement}
      end;

  {*************}
  { renormalize }
  {*************}
  {
  if renormalize then
    begin
      if (t <> infinity) then
        t := t / max;
    end;
  }

  {************************************************}
  { store local coords of closest intersecting ray }
  {************************************************}
  if (t < closest_t) then
    begin
      closest_t := t;
      closest_local_ray := ray;
    end;

  Closest_intersection := t;
end; {function Closest_intersection}


function Second_closest_intersection(ray: ray_type;
  tmin, tmax: real;
  object_ptr: ray_object_inst_ptr_type): real;
var
  t: real;
begin
  t := 0;

  {**********************************************}
  { transform point to local coords of primitive }
  {**********************************************}
  Transform_vector_to_axes(ray.direction, object_ptr^.coord_axes);
  Transform_point_to_axes(ray.location, object_ptr^.coord_axes);

  {*********************}
  { cheap normalization }
  {*********************}
  {
  if renormalize then
    begin
      max := Max_component(ray.direction);
      ray.direction := Vector_scale(ray.direction, 1 / max);
    end;
  }

  with object_ptr^ do
    if (ray_mesh_data_ptr <> nil) and (kind in curved_prims) then
      begin
        {********************************************************}
        { raytrace tessellated (non-triangulated) representation }
        {********************************************************}
        with ray_mesh_data_ptr^ do
          t := Fast_mesh_intersection(ray, tmin, tmax, mesh_voxel_ptr);
      end
    else
      begin
        {*******************************}
        { raytrace exact representation }
        {*******************************}
        case kind of

          complex_object:
            t := Unit_cube_intersection(ray, tmin, tmax, second_closest);

          {********************}
          { quadric primitives }
          {********************}

          sphere:
            t := Sphere_intersection(ray, tmin, tmax, second_closest, umin,
              umax, vmin, vmax);

          cylinder:
            t := Cylinder_intersection(ray, tmin, tmax, second_closest, umin,
              umax);

          cone:
            t := Cone_intersection(ray, tmin, tmax, second_closest,
              inner_radius, umin, umax);

          paraboloid:
            t := Paraboloid_intersection(ray, tmin, tmax, second_closest, umin,
              umax);

          hyperboloid1:
            t := Hyperboloid1_intersection(ray, tmin, tmax, second_closest,
              inner_radius, umin, umax);

          hyperboloid2:
            t := Hyperboloid2_intersection(ray, tmin, tmax, second_closest,
              eccentricity, umin, umax);

          {*******************}
          { planar primitives }
          {*******************}

          plane, disk, ring, triangle, parallelogram, flat_polygon:
            t := infinity;

          {***********************}
          { non_planar primitives }
          {***********************}

          torus:
            t := Torus_intersection(ray, tmin, tmax, second_closest,
              inner_radius, umin, umax, vmin, vmax);

          block:
            t := Unit_cube_intersection(ray, tmin, tmax, second_closest);

          shaded_triangle:
            t := infinity;

          shaded_polygon:
            t := infinity;

          mesh:
            begin
              with ray_mesh_data_ptr^ do
                if not smoothing then
                  t := Triangle_mesh_intersection(ray, tmin, tmax,
                    triangle_voxel_ptr, last_ray_normal,
                    last_ray_texture_interpolation,
                      last_ray_u_axis_interpolation,
                    last_ray_v_axis_interpolation)
                else
                  t := Smooth_triangle_mesh_intersection(ray, tmin, tmax,
                    triangle_voxel_ptr, last_ray_normal_interpolation,
                    last_ray_texture_interpolation,
                      last_ray_u_axis_interpolation,
                    last_ray_v_axis_interpolation);
            end;

          blob:
            t := Blob_intersection(ray, tmin, tmax, second_closest,
              metaball_ptr, threshold, dimensions);

          {************************}
          { non_surface primitives }
          {************************}

          points:
            {t := Point_intersection(ray, tmin, tmax, points_ptr^.vertex_ptr, ray, coord_axes);}
            t := infinity;

          lines:
            {t := Line_intersection(ray, tmin, tmax, lines_ptr^.vertex_ptr, ray, coord_axes);}
            t := infinity;

          volume:
            begin
              with ray_mesh_data_ptr^ do
                if not volume_ptr^.smoothing then
                  t := Triangle_mesh_intersection(ray, tmin, tmax,
                    triangle_voxel_ptr, last_ray_normal,
                    last_ray_texture_interpolation,
                      last_ray_u_axis_interpolation,
                    last_ray_v_axis_interpolation)
                else
                  t := Smooth_triangle_mesh_intersection(ray, tmin, tmax,
                    triangle_voxel_ptr, last_ray_normal_interpolation,
                    last_ray_texture_interpolation,
                      last_ray_u_axis_interpolation,
                    last_ray_v_axis_interpolation);
            end;

        end; {case statement}
      end;

  {*************}
  { renormalize }
  {*************}
  {
  if renormalize then
    begin
      if (t <> infinity) then
        t := t / max;
    end;
  }

  {************************************************}
  { store local coords of closest intersecting ray }
  {************************************************}
  if (t < closest_t) then
    begin
      closest_t := t;
      closest_local_ray := ray;
    end;

  Second_closest_intersection := t;
end; {function Second_closest_intersection}


procedure Find_clipping_span(var ray: ray_type;
  var tmin, tmax: real;
  object_ptr: ray_object_inst_ptr_type);
var
  origin, normal: vector_type;
  numerator, denominator: real;
  t, in_t, out_t: real;
begin
  in_t := tmin;
  out_t := tmax;

  while (object_ptr <> nil) and (in_t < out_t) do
    begin
      origin := object_ptr^.coord_axes.trans.origin;
      normal := object_ptr^.coord_axes.trans.z_axis;

      {**********************************************}
      { if plane normal faces away from us, then we  }
      { are outside the space, so compute T_in, else }
      { we are inside the space, so compute T_out.   }
      {**********************************************}
      numerator := Dot_product(Vector_difference(origin, ray.location), normal);
      denominator := Dot_product(ray.direction, normal);

      if (denominator <> 0) then
        begin
          t := numerator / denominator;

          if (numerator < 0) then
            begin
              {***************************}
              { we are outside the space, }
              { so compute new entering t }
              {***************************}
              if (t > in_t) then
                in_t := t
              else if (t < tmin) then
                in_t := infinity;
            end
          else
            begin
              {**************************}
              { we are inside the space, }
              { so compute new leaving t }
              {**************************}
              if (t < out_t) then
                out_t := t;
            end;
        end;

      object_ptr := object_ptr^.next;
    end;

  if (in_t < out_t) then
    begin
      if in_t > tmin then
        tmin := in_t;
      if out_t < tmax then
        tmax := out_t;
    end
  else
    tmin := infinity;
end; {procedure Find_clipping_span}


initialization
  closest_t := infinity;
  closest_local_ray.location := zero_vector;
  closest_local_ray.direction := zero_vector;
end.
