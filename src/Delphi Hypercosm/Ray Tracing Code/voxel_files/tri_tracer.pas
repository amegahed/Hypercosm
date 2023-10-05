unit tri_tracer;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             tri_tracer                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The tri_tracer module is used to traverse the           }
{       spatial database used for raytracing of triangles       }
{       and find the one intersected.                           }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, rays, trans, raytrace;


function Triangle_mesh_intersection(ray: ray_type;
  tmin, tmax: real;
  triangle_voxel_ptr: triangle_voxel_ptr_type;
  var normal: vector_type;
  var texture_interpolation: interpolation_type;
  var u_axis_interpolation: interpolation_type;
  var v_axis_interpolation: interpolation_type): real;
function Smooth_triangle_mesh_intersection(ray: ray_type;
  tmin, tmax: real;
  triangle_voxel_ptr: triangle_voxel_ptr_type;
  var normal_interpolation: interpolation_type;
  var texture_interpolation: interpolation_type;
  var u_axis_interpolation: interpolation_type;
  var v_axis_interpolation: interpolation_type): real;


implementation
uses
  constants, extents, topology, triangles;


function Leaf_voxel(triangle_voxel_ptr: triangle_voxel_ptr_type;
  point: vector_type): triangle_voxel_ptr_type;
var
  center: vector_type;
  length, width, height: extent_type;
begin
  {*********************************************}
  { find the leaf subvoxel containing the point }
  {*********************************************}
  while (triangle_voxel_ptr^.subdivided) do
    begin
      center := Extent_box_center(triangle_voxel_ptr^.extent_box);
      if (point.x < center.x) then
        length := left
      else
        length := right;
      if (point.y < center.y) then
        width := front
      else
        width := back;
      if (point.z < center.z) then
        height := bottom
      else
        height := top;
      triangle_voxel_ptr := triangle_voxel_ptr^.subvoxel_ptr[length, width,
        height];
    end;
  Leaf_voxel := triangle_voxel_ptr;
end; {function Leaf_voxel}


function Next_voxel(triangle_voxel_ptr: triangle_voxel_ptr_type;
  ray: ray_type): triangle_voxel_ptr_type;
var
  t, new_t: real;
  next, temp: extent_type;
  point: vector_type;
begin
  t := infinity;
  next := left;

  if (ray.direction.x <> 0) then
    begin
      if (ray.direction.x < 0) then
        begin
          t := (triangle_voxel_ptr^.extent_box[left] - ray.location.x) /
            ray.direction.x;
          next := left;
        end
      else
        begin
          t := (triangle_voxel_ptr^.extent_box[right] - ray.location.x) /
            ray.direction.x;
          next := right;
        end;
    end;

  if (ray.direction.y <> 0) then
    begin
      if (ray.direction.y < 0) then
        begin
          new_t := (triangle_voxel_ptr^.extent_box[front] - ray.location.y) /
            ray.direction.y;
          temp := front;
        end
      else
        begin
          new_t := (triangle_voxel_ptr^.extent_box[back] - ray.location.y) /
            ray.direction.y;
          temp := back;
        end;
      if (new_t < t) then
        begin
          t := new_t;
          next := temp;
        end;
    end;

  if (ray.direction.z <> 0) then
    begin
      if (ray.direction.z < 0) then
        begin
          new_t := (triangle_voxel_ptr^.extent_box[bottom] - ray.location.z) /
            ray.direction.z;
          temp := bottom;
        end
      else
        begin
          new_t := (triangle_voxel_ptr^.extent_box[top] - ray.location.z) /
            ray.direction.z;
          temp := top;
        end;
      if (new_t < t) then
        begin
          t := new_t;
          next := temp;
        end;
    end;

  triangle_voxel_ptr := triangle_voxel_ptr^.neighbor_voxel_ptr[next];
  if (triangle_voxel_ptr <> nil) then
    if (triangle_voxel_ptr^.subdivided) then
      begin
        point := Vector_sum(ray.location, Vector_scale(ray.direction, t));
        triangle_voxel_ptr := Leaf_voxel(triangle_voxel_ptr, point);
      end;

  Next_voxel := triangle_voxel_ptr;
end; {procedure Next_voxel}


function Voxel_intersection(ray: ray_type;
  var point: vector_type): real;
var
  t, new_t, extent: real;
  new_point: vector_type;
begin
  t := infinity;
  if (ray.direction.x <> 0) then
    begin
      if (ray.direction.x < 0) then
        extent := 1
      else
        extent := -1;
      new_t := (extent - ray.location.x) / ray.direction.x;
      if (new_t < t) and (new_t >= 0) then
        begin
          new_point.y := ray.location.y + ray.direction.y * new_t;
          if (abs(new_point.y) <= 1) then
            begin
              new_point.z := ray.location.z + ray.direction.z * new_t;
              if (abs(new_point.z) <= 1) then
                begin
                  t := new_t;
                  point.x := extent;
                  point.y := new_point.y;
                  point.z := new_point.z;
                end;
            end;
        end;
    end; {x}

  if (ray.direction.y <> 0) then
    begin
      if (ray.direction.y < 0) then
        extent := 1
      else
        extent := -1;
      new_t := (extent - ray.location.y) / ray.direction.y;
      if (new_t < t) and (new_t >= 0) then
        begin
          new_point.x := ray.location.x + ray.direction.x * new_t;
          if (abs(new_point.x) <= 1) then
            begin
              new_point.z := ray.location.z + ray.direction.z * new_t;
              if (abs(new_point.z) <= 1) then
                begin
                  t := new_t;
                  point.x := new_point.x;
                  point.y := extent;
                  point.z := new_point.z;
                end;
            end;
        end;
    end; {y}

  if (ray.direction.z <> 0) then
    begin
      if (ray.direction.z < 0) then
        extent := 1
      else
        extent := -1;
      new_t := (extent - ray.location.z) / ray.direction.z;
      if (new_t < t) and (new_t >= 0) then
        begin
          new_point.x := ray.location.x + ray.direction.x * new_t;
          if (abs(new_point.x) <= 1) then
            begin
              new_point.y := ray.location.y + ray.direction.y * new_t;
              if (abs(new_point.y) <= 1) then
                begin
                  t := new_t;
                  point.x := new_point.x;
                  point.y := new_point.y;
                  point.z := extent;
                end;
            end;
        end;
    end; {z}

  Voxel_intersection := t;
end; {function Voxel_intersection}


function Mesh_triangle_intersection(ray: ray_type;
  triangle_ptr: triangle_ptr_type;
  var texture_interpolation: interpolation_type;
  var u_axis_interpolation: interpolation_type;
  var v_axis_interpolation: interpolation_type): real;
var
  texture1, texture2, texture3: vector_type;
  u_axis1, u_axis2, u_axis3: vector_type;
  v_axis1, v_axis2, v_axis3: vector_type;
  x, y: real;
  t, interpolation_t: real;
begin
  Transform_ray(ray, triangle_ptr^.trans);

  if (abs(ray.direction.z) < tiny) then
    {**************************}
    { ray is parallel to plane }
    {**************************}
    t := infinity
  else
    begin
      t := -(ray.location.z / ray.direction.z);
      if (t < tiny) then
        {*********************************}
        { intersection is behind observer }
        {*********************************}
        t := infinity
      else
        begin
          {*************************************}
          { project intersection point to plane }
          {*************************************}
          x := ray.location.x + (t * ray.direction.x);
          y := ray.location.y + (t * ray.direction.y);

          {************************}
          { bounding triangle test }
          {************************}
          if (x < 0) or (y < 0) or (x + y > 1) then
            t := infinity
          else
            begin
              interpolation_t := x / (1 - y);

              {****************************}
              { save texture interpolation }
              {****************************}
              texture1 :=
                triangle_ptr^.vertex_ptr1^.vertex_geometry_ptr^.texture;
              texture2 :=
                triangle_ptr^.vertex_ptr2^.vertex_geometry_ptr^.texture;
              texture3 :=
                triangle_ptr^.vertex_ptr3^.vertex_geometry_ptr^.texture;

              with texture_interpolation do
                begin
                  left_vector1 := texture2;
                  left_vector2 := texture1;
                  left_t := y;
                  right_vector1 := texture3;
                  right_vector2 := texture1;
                  right_t := y;
                  t := interpolation_t;
                end;

              {***************************}
              { save u_axis interpolation }
              {***************************}
              u_axis1 := triangle_ptr^.vertex_ptr1^.vertex_geometry_ptr^.u_axis;
              u_axis2 := triangle_ptr^.vertex_ptr2^.vertex_geometry_ptr^.u_axis;
              u_axis3 := triangle_ptr^.vertex_ptr3^.vertex_geometry_ptr^.u_axis;

              with u_axis_interpolation do
                begin
                  left_vector1 := u_axis2;
                  left_vector2 := u_axis1;
                  left_t := y;
                  right_vector1 := u_axis3;
                  right_vector2 := u_axis1;
                  right_t := y;
                  t := interpolation_t;
                end;

              {***************************}
              { save v_axis interpolation }
              {***************************}
              v_axis1 := triangle_ptr^.vertex_ptr1^.vertex_geometry_ptr^.v_axis;
              v_axis2 := triangle_ptr^.vertex_ptr2^.vertex_geometry_ptr^.v_axis;
              v_axis3 := triangle_ptr^.vertex_ptr3^.vertex_geometry_ptr^.v_axis;

              with v_axis_interpolation do
                begin
                  left_vector1 := v_axis2;
                  left_vector2 := v_axis1;
                  left_t := y;
                  right_vector1 := v_axis3;
                  right_vector2 := v_axis1;
                  right_t := y;
                  t := interpolation_t;
                end;

            end;
        end;
    end;

  Mesh_triangle_intersection := t;
end; {function Mesh_triangle_intersection}


function Smooth_mesh_triangle_intersection(ray: ray_type;
  triangle_ptr: triangle_ptr_type;
  var normal_interpolation: interpolation_type;
  var texture_interpolation: interpolation_type;
  var u_axis_interpolation: interpolation_type;
  var v_axis_interpolation: interpolation_type): real;
var
  texture1, texture2, texture3: vector_type;
  normal1, normal2, normal3: vector_type;
  u_axis1, u_axis2, u_axis3: vector_type;
  v_axis1, v_axis2, v_axis3: vector_type;
  x, y: real;
  t, interpolation_t: real;
begin
  Transform_ray(ray, triangle_ptr^.trans);

  if (abs(ray.direction.z) < tiny) then
    {**************************}
    { ray is parallel to plane }
    {**************************}
    t := infinity
  else
    begin
      t := -(ray.location.z / ray.direction.z);
      if (t < tiny) then
        {*********************************}
        { intersection is behind observer }
        {*********************************}
        t := infinity
      else
        begin
          {*************************************}
          { project intersection point to plane }
          {*************************************}
          x := ray.location.x + (t * ray.direction.x);
          y := ray.location.y + (t * ray.direction.y);

          {************************}
          { bounding triangle test }
          {************************}
          if (x < 0) or (y < 0) or (x + y > 1) then
            t := infinity
          else
            begin
              interpolation_t := x / (1 - y);

              {****************************}
              { save texture interpolation }
              {****************************}
              texture1 := triangle_ptr^.vertex_geometry_ptr1^.texture;
              texture2 := triangle_ptr^.vertex_geometry_ptr2^.texture;
              texture3 := triangle_ptr^.vertex_geometry_ptr3^.texture;

              with texture_interpolation do
                begin
                  left_vector1 := texture2;
                  left_vector2 := texture1;
                  left_t := y;
                  right_vector1 := texture3;
                  right_vector2 := texture1;
                  right_t := y;
                  t := interpolation_t;
                end;

              {***************************}
              { save normal interpolation }
              {***************************}
              normal1 := triangle_ptr^.vertex_geometry_ptr1^.normal;
              normal2 := triangle_ptr^.vertex_geometry_ptr2^.normal;
              normal3 := triangle_ptr^.vertex_geometry_ptr3^.normal;

              with normal_interpolation do
                begin
                  left_vector1 := normal2;
                  left_vector2 := normal1;
                  left_t := y;
                  right_vector1 := normal3;
                  right_vector2 := normal1;
                  right_t := y;
                  t := interpolation_t;
                end;

              {***************************}
              { save u_axis interpolation }
              {***************************}
              u_axis1 := triangle_ptr^.vertex_geometry_ptr1^.u_axis;
              u_axis2 := triangle_ptr^.vertex_geometry_ptr2^.u_axis;
              u_axis3 := triangle_ptr^.vertex_geometry_ptr3^.u_axis;

              with u_axis_interpolation do
                begin
                  left_vector1 := u_axis2;
                  left_vector2 := u_axis1;
                  left_t := y;
                  right_vector1 := u_axis3;
                  right_vector2 := u_axis1;
                  right_t := y;
                  t := interpolation_t;
                end;

              {***************************}
              { save v_axis interpolation }
              {***************************}
              v_axis1 := triangle_ptr^.vertex_geometry_ptr1^.v_axis;
              v_axis2 := triangle_ptr^.vertex_geometry_ptr2^.v_axis;
              v_axis3 := triangle_ptr^.vertex_geometry_ptr3^.v_axis;

              with v_axis_interpolation do
                begin
                  left_vector1 := v_axis2;
                  left_vector2 := v_axis1;
                  left_t := y;
                  right_vector1 := v_axis3;
                  right_vector2 := v_axis1;
                  right_t := y;
                  t := interpolation_t;
                end;

            end;
        end;
    end;

  Smooth_mesh_triangle_intersection := t;
end; {function Smooth_mesh_triangle_intersection}


function Plane_intersection(ray: ray_type;
  origin, normal: vector_type): real;
var
  temp: real;
  t: real;
begin
  temp := Dot_product(ray.direction, normal);
  if (temp = 0) then
    t := infinity
  else
    begin
      t := Dot_product(Vector_difference(origin, ray.location), normal) / temp;
      if (t < tiny) then
        t := infinity;
    end;
  Plane_intersection := t;
end; {function Plane_intersection}


function Point_in_triangle(point_ptr: point_ptr_type;
  triangle_ptr: triangle_ptr_type): boolean;
var
  in_triangle: boolean;
begin
  in_triangle := false;

  if (triangle_ptr^.vertex_ptr1^.point_ptr = point_ptr) then
    in_triangle := true
  else if (triangle_ptr^.vertex_ptr2^.point_ptr = point_ptr) then
    in_triangle := true
  else if (triangle_ptr^.vertex_ptr3^.point_ptr = point_ptr) then
    in_triangle := true;

  Point_in_triangle := in_triangle;
end; {function Point_in_triangle}


function Triangle_node_intersection(ray: ray_type;
  tmin, tmax: real;
  triangle_node_ptr: triangle_node_ptr_type;
  var texture_interpolation: interpolation_type;
  var u_axis_interpolation: interpolation_type;
  var v_axis_interpolation: interpolation_type): real;
var
  t: real;
  mailbox_hit: boolean;
begin
  mailbox_hit := false;
  if Equal_vector(ray.direction, triangle_node_ptr^.mesh_mailbox.ray.direction)
    then
    if Equal_vector(ray.location, triangle_node_ptr^.mesh_mailbox.ray.location)
      then
      mailbox_hit := true;

  if mailbox_hit then
    begin
      t := triangle_node_ptr^.mesh_mailbox.t;
    end
  else if Point_in_triangle(source_point_ptr, triangle_node_ptr^.triangle_ptr)
    then
    begin
      t := infinity;
    end
  else
    begin
      t := Mesh_triangle_intersection(ray, triangle_node_ptr^.triangle_ptr,
        texture_interpolation, u_axis_interpolation, v_axis_interpolation);
      if (t < tmin) or (t > tmax) then
        t := infinity;
      triangle_node_ptr^.mesh_mailbox.ray := ray;
      triangle_node_ptr^.mesh_mailbox.t := t;
    end;

  Triangle_node_intersection := t;
end; {function Triangle_node_intersection}


function Smooth_triangle_node_intersection(ray: ray_type;
  tmin, tmax: real;
  triangle_node_ptr: triangle_node_ptr_type;
  var normal_interpolation: interpolation_type;
  var texture_interpolation: interpolation_type;
  var u_axis_interpolation: interpolation_type;
  var v_axis_interpolation: interpolation_type): real;
var
  t: real;
  mailbox_hit: boolean;
begin
  mailbox_hit := false;
  if Equal_vector(ray.direction, triangle_node_ptr^.mesh_mailbox.ray.direction)
    then
    if Equal_vector(ray.location, triangle_node_ptr^.mesh_mailbox.ray.location)
      then
      mailbox_hit := true;

  if mailbox_hit then
    begin
      {**************************************************}
      { mailbox does not contain interpolation therefore }
      { the closest interpolation must be maintained as  }
      { we advance the ray so we can retreive it when we }
      { find that our closest intersection is inside of  }
      { the current voxel that we are traversing.        }
      {**************************************************}
      t := triangle_node_ptr^.mesh_mailbox.t;
    end
  else if Point_in_triangle(source_point_ptr, triangle_node_ptr^.triangle_ptr)
    then
    begin
      t := infinity;
    end
  else
    begin
      t := Smooth_mesh_triangle_intersection(ray,
        triangle_node_ptr^.triangle_ptr, normal_interpolation,
        texture_interpolation, u_axis_interpolation, v_axis_interpolation);
      if (t < tmin) or (t > tmax) then
        t := infinity;
      triangle_node_ptr^.mesh_mailbox.ray := ray;
      triangle_node_ptr^.mesh_mailbox.t := t;
    end;

  Smooth_triangle_node_intersection := t;
end; {function Smooth_triangle_node_intersection}


function Triangle_mesh_intersection(ray: ray_type;
  tmin, tmax: real;
  triangle_voxel_ptr: triangle_voxel_ptr_type;
  var normal: vector_type;
  var texture_interpolation: interpolation_type;
  var u_axis_interpolation: interpolation_type;
  var v_axis_interpolation: interpolation_type): real;
var
  t, new_t: real;
  point: vector_type;
  found, found_hit: boolean;
  inside_voxels: boolean;
  ray_hits_voxels: boolean;
  follow: triangle_node_ref_ptr_type;
  triangle_node_ptr: triangle_node_ptr_type;
  new_texture_interpolation: interpolation_type;
  new_u_axis_interpolation: interpolation_type;
  new_v_axis_interpolation: interpolation_type;
begin
  t := infinity;
  point := ray.location;

  {***********************************}
  { find if ray starts in voxel space }
  {***********************************}
  inside_voxels := false;
  if (abs(point.x) <= 1) then
    if (abs(point.y) <= 1) then
      if (abs(point.z) <= 1) then
        inside_voxels := true;

  {******************************}
  { find if ray hits voxel space }
  {******************************}
  ray_hits_voxels := true;
  if not inside_voxels then
    if (Voxel_intersection(ray, point) = infinity) then
      ray_hits_voxels := false;

  {*******************}
  { check voxel space }
  {*******************}
  if (ray_hits_voxels) then
    begin
      triangle_voxel_ptr := Leaf_voxel(triangle_voxel_ptr, point);
      found := false;

      while ((triangle_voxel_ptr <> nil) and (not found)) do
        begin
          {***********************************************}
          { find nearest intersection of objects in voxel }
          {***********************************************}
          found_hit := false;
          follow := triangle_voxel_ptr^.triangle_node_ref_ptr;
          while (follow <> nil) do
            begin
              triangle_node_ptr := follow^.triangle_node_ptr;
              if (triangle_node_ptr^.triangle_ptr^.face_ptr <> source_face_ptr)
                then
                begin
                  {*********************************}
                  { send closest interpolation into }
                  { test in case of mailbox strike. }
                  {*********************************}
                  new_texture_interpolation := texture_interpolation;
                  new_t := Triangle_node_intersection(ray, tmin, tmax,
                    triangle_node_ptr, new_texture_interpolation,
                    new_u_axis_interpolation, new_v_axis_interpolation);
                  if (new_t < t) then
                    begin
                      normal :=
                        triangle_node_ptr^.triangle_ptr^.face_geometry_ptr^.normal;
                      texture_interpolation := new_texture_interpolation;
                      u_axis_interpolation := new_u_axis_interpolation;
                      v_axis_interpolation := new_v_axis_interpolation;
                      t := new_t;
                      found_hit := true;
                      target_face_ptr :=
                        triangle_node_ptr^.triangle_ptr^.face_ptr;
                    end;
                end;
              follow := follow^.next;
            end; {while loop}

          {**************************************}
          { find if we have a valid intersection }
          {**************************************}
          if found_hit then
            begin
              point := Vector_sum(ray.location, Vector_scale(ray.direction, t));
              if Point_in_extent_box(point, triangle_voxel_ptr^.extent_box) then
                found := true
              else
                triangle_voxel_ptr := Next_voxel(triangle_voxel_ptr, ray);
            end
          else
            triangle_voxel_ptr := Next_voxel(triangle_voxel_ptr, ray);
        end; {while loop}
    end; {triangle intersection}

  Triangle_mesh_intersection := t;
end; {function Triangle_mesh_intersection}


function Smooth_triangle_mesh_intersection(ray: ray_type;
  tmin, tmax: real;
  triangle_voxel_ptr: triangle_voxel_ptr_type;
  var normal_interpolation: interpolation_type;
  var texture_interpolation: interpolation_type;
  var u_axis_interpolation: interpolation_type;
  var v_axis_interpolation: interpolation_type): real;
var
  t, new_t: real;
  point: vector_type;
  found, found_hit: boolean;
  inside_voxels: boolean;
  ray_hits_voxels: boolean;
  follow: triangle_node_ref_ptr_type;
  triangle_node_ptr: triangle_node_ptr_type;
  new_normal_interpolation: interpolation_type;
  new_texture_interpolation: interpolation_type;
  new_u_axis_interpolation: interpolation_type;
  new_v_axis_interpolation: interpolation_type;
begin
  t := infinity;
  point := ray.location;

  {***********************************}
  { find if ray starts in voxel space }
  {***********************************}
  inside_voxels := false;
  if (abs(point.x) <= 1) then
    if (abs(point.y) <= 1) then
      if (abs(point.z) <= 1) then
        inside_voxels := true;

  {******************************}
  { find if ray hits voxel space }
  {******************************}
  ray_hits_voxels := true;
  if not inside_voxels then
    if (Voxel_intersection(ray, point) = infinity) then
      ray_hits_voxels := false;

  {*******************}
  { check voxel space }
  {*******************}
  if (ray_hits_voxels) then
    begin
      triangle_voxel_ptr := Leaf_voxel(triangle_voxel_ptr, point);
      found := false;

      while ((triangle_voxel_ptr <> nil) and (not found)) do
        begin
          {***********************************************}
          { find nearest intersection of objects in voxel }
          {***********************************************}
          found_hit := false;
          follow := triangle_voxel_ptr^.triangle_node_ref_ptr;
          while (follow <> nil) do
            begin
              triangle_node_ptr := follow^.triangle_node_ptr;
              if (triangle_node_ptr^.triangle_ptr^.face_ptr <> source_face_ptr)
                then
                begin
                  {*********************************}
                  { send closest interpolation into }
                  { test in case of mailbox strike. }
                  {*********************************}
                  new_normal_interpolation := normal_interpolation;
                  new_texture_interpolation := texture_interpolation;
                  new_t := Smooth_triangle_node_intersection(ray, tmin, tmax,
                    triangle_node_ptr, new_normal_interpolation,
                    new_texture_interpolation, new_u_axis_interpolation,
                    new_v_axis_interpolation);
                  if (new_t < t) then
                    begin
                      t := new_t;
                      normal_interpolation := new_normal_interpolation;
                      texture_interpolation := new_texture_interpolation;
                      u_axis_interpolation := new_u_axis_interpolation;
                      v_axis_interpolation := new_v_axis_interpolation;
                      target_face_ptr :=
                        triangle_node_ptr^.triangle_ptr^.face_ptr;
                      found_hit := true;
                    end;
                end;
              follow := follow^.next;
            end; {while loop}

          {**************************************}
          { find if we have a valid intersection }
          {**************************************}
          if found_hit then
            begin
              point := Vector_sum(ray.location, Vector_scale(ray.direction, t));
              if Point_in_extent_box(point, triangle_voxel_ptr^.extent_box) then
                found := true
              else
                triangle_voxel_ptr := Next_voxel(triangle_voxel_ptr, ray);
            end
          else
            triangle_voxel_ptr := Next_voxel(triangle_voxel_ptr, ray);
        end; {while loop}
    end; {triangle intersection}

  Smooth_triangle_mesh_intersection := t;
end; {function Smooth_triangle_mesh_intersection}


end.
