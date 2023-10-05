unit walk_voxels;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            walk_voxels                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The walk_voxels module is used to traverse the          }
{       spatial database used for raytracing.                   }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  rays, trans, coord_axes, coord_stack, object_attr, raytrace;


var
  ray_originates_from_object: boolean;


  {*******************************}
  { hierarchical object utilities }
  {*******************************}
function Same_hierarchical_object(object1, object2: hierarchical_object_type):
  boolean;
procedure Convert_hierarchical_object(obj: hierarchical_object_type;
  var object_ptr: ray_object_inst_ptr_type);
procedure Transform_hierarchical_object(obj: hierarchical_object_type;
  var object_ptr: ray_object_inst_ptr_type);
procedure Create_coord_stack(obj: hierarchical_object_type;
  var coord_stack_ptr: coord_stack_ptr_type;
  var normal_stack_ptr: coord_stack_ptr_type;
  var shader_height: integer;
  var shader_axes: coord_axes_type;
  var normal_shader_axes: coord_axes_type);

{***********************}
{ intersection routines }
{***********************}
function Primary_ray_intersection(ray: ray_type;
  tmin, tmax: real;
  var obj: hierarchical_object_type): real;
function Secondary_ray_intersection(ray: ray_type;
  tmin, tmax: real;
  var obj: hierarchical_object_type;
  var source_object: hierarchical_object_type): real;
function Shadow_ray_intersection(ray: ray_type;
  tmin, tmax: real;
  var obj: hierarchical_object_type;
  var source_object: hierarchical_object_type): real;

{******************************}
{ object intersection routines }
{******************************}
function Object_intersection(ray: ray_type;
  tmin, tmax: real;
  var obj: hierarchical_object_type): real;


implementation
uses
  new_memory, constants, vectors, extents, objects, planar_tracer, intersect;


const
  memory_alert = false;


var
  originating_object: hierarchical_object_type;


  {*******************************************}
  { when transforming hierarchical objects to }
  { objects, a temporary object is needed to  }
  { store the instance of the object.         }
  {*******************************************}
  global_object_ptr: ray_object_inst_ptr_type;
  global_coord_stack_ptr: coord_stack_ptr_type;
  global_normal_stack_ptr: coord_stack_ptr_type;


{*******************************}
{ hierarchical object utilities }
{*******************************}


function Same_transform_stack(stack1, stack2: transform_stack_type): boolean;
var
  equal: boolean;
  counter: integer;
begin
  if (stack1.depth <> stack2.depth) then
    equal := false
  else
    begin
      equal := true;
      counter := stack1.depth;
      while (counter > 0) and equal do
        begin
          if (stack1.stack[counter] <> stack2.stack[counter]) then
            equal := false
          else
            counter := counter - 1;
        end;
    end;
  Same_transform_stack := equal;
end; {function Same_transform_stack}


function Same_hierarchical_object(object1, object2: hierarchical_object_type):
  boolean;
var
  equal: boolean;
begin
  if (object1.object_ptr <> object2.object_ptr) then
    equal := false
  else
    equal := Same_transform_stack(object1.transform_stack,
      object2.transform_stack);
  Same_hierarchical_object := equal;
end; {function Same_hierarchical_object}


procedure Convert_hierarchical_object(obj: hierarchical_object_type;
  var object_ptr: ray_object_inst_ptr_type);
var
  counter: integer;
  attributes: object_attributes_type;
begin
  object_ptr := global_object_ptr;
  object_ptr^ := obj.object_ptr^;

  attributes := obj.object_ptr^.attributes;
  if (obj.transform_stack.depth > 0) then
    for counter := obj.transform_stack.depth downto 1 do
      begin
        {***************************}
        { pop new context off stack }
        {***************************}
        Apply_object_attributes(attributes,
          obj.transform_stack.stack[counter]^.attributes);
      end;
  object_ptr^.attributes := attributes;
end; {procedure Convert_hierarchical_object}


procedure Transform_hierarchical_object(obj: hierarchical_object_type;
  var object_ptr: ray_object_inst_ptr_type);
var
  depth: integer;
  coord_axes: coord_axes_type;
  attributes: object_attributes_type;
  complex_object_ptr: ray_object_inst_ptr_type;
  done, coord_axes_are_global: boolean;
  local_transform_cache: transform_cache_type;
begin
  {********************************************}
  { begin with primitive object's local coords }
  {********************************************}
  object_ptr := global_object_ptr;
  object_ptr^ := obj.object_ptr^;
  local_transform_cache := obj.object_ptr^.transform_cache;

  if (obj.transform_stack.depth > 0) then
    begin
      if Same_transform_stack(obj.transform_stack,
        local_transform_cache.transform_stack) then
        begin
          {*****************************}
          { primitive's global coords   }
          { and shader are in the cache }
          {*****************************}
          object_ptr^.coord_axes := local_transform_cache.global_coord_axes;
          object_ptr^.attributes := local_transform_cache.global_attributes;
        end
      else
        {*****************************}
        { primitive's global coords   }
        { and shader are not in cache }
        {*****************************}
        begin
          {*****************************************************}
          { we must transform the primitive to its global coord }
          { axes. To do this, we start at the top of the stack  }
          { and apply each new transformation. If we find that  }
          { one of the complex objects has its cache set, then  }
          { we can transform right to global coords.            }
          {*****************************************************}
          depth := obj.transform_stack.depth;
          done := false;
          while (depth >= 1) and not done do
            begin
              complex_object_ptr := obj.transform_stack.stack[depth];
              depth := depth - 1;
              obj.transform_stack.depth := depth;

              coord_axes_are_global := false;
              {local_transform_cache := complex_object_ptr^.transform_cache;}

              if (depth > 0) then
                if Same_transform_stack(obj.transform_stack,
                  local_transform_cache.transform_stack) then
                  coord_axes_are_global := true;

              if coord_axes_are_global then
                begin
                  {*********************************}
                  { transformation to global coords }
                  {*********************************}
                  done := true;
                  coord_axes := local_transform_cache.global_coord_axes;
                  attributes := local_transform_cache.global_attributes;
                end
              else
                begin
                  {*****************************************}
                  { transformation to next context on stack }
                  {*****************************************}
                  coord_axes := complex_object_ptr^.coord_axes;
                  attributes := complex_object_ptr^.attributes;
                end;

              {***********************************}
              { apply transformation to primitive }
              {***********************************}
              Transform_axes_from_axes(object_ptr^.coord_axes, coord_axes);

              {********************************************************}
              { apply complex object's surface attributes to primitive }
              {********************************************************}
              Apply_object_attributes(object_ptr^.attributes, attributes);
            end; {while}

          {*****************************************}
          { put newly transformed object into cache }
          {*****************************************}
          {with obj.object_ptr^.transform_cache do}
          with local_transform_cache do
            begin
              transform_stack := obj.transform_stack;
              global_coord_axes := object_ptr^.coord_axes;
              {global_attributes := object_ptr^.attributes;}
            end;
        end; {transforming primitive to global coords}
    end;
end; {procedure Transform_hierarchical_object}


procedure Create_coord_stack(obj: hierarchical_object_type;
  var coord_stack_ptr: coord_stack_ptr_type;
  var normal_stack_ptr: coord_stack_ptr_type;
  var shader_height: integer;
  var shader_axes: coord_axes_type;
  var normal_shader_axes: coord_axes_type);
var
  counter: integer;
  object_inst_ptr: ray_object_inst_ptr_type;
begin
  shader_height := 0;
  shader_axes := unit_axes;
  normal_shader_axes := unit_axes;

  coord_stack_ptr := global_coord_stack_ptr;
  Reset_coord_stack(coord_stack_ptr);

  normal_stack_ptr := global_normal_stack_ptr;
  Reset_coord_stack(normal_stack_ptr);

  {******************************************************}
  { push transformations of aggregate objects along path }
  {******************************************************}
  for counter := 1 to obj.transform_stack.depth do
    begin
      object_inst_ptr := obj.transform_stack.stack[counter];

      if (object_inst_ptr^.attributes.shader_ptr <> shader_ptr_type(nil)) then
        {if (shader_height = 0) then}
        begin
          shader_height := counter;
          shader_axes := object_inst_ptr^.shader_axes;
          normal_shader_axes := object_inst_ptr^.normal_shader_axes;
        end;

      Push_coord_stack(coord_stack_ptr);
      Set_coord_stack(coord_stack_ptr, object_inst_ptr^.coord_axes);

      Push_coord_stack(normal_stack_ptr);
      Set_coord_stack(normal_stack_ptr, object_inst_ptr^.normal_coord_axes);
    end;

  {***********************************}
  { push transformations of primitive }
  {***********************************}
  Push_coord_stack(coord_stack_ptr);
  Set_coord_stack(coord_stack_ptr, obj.object_ptr^.coord_axes);

  Push_coord_stack(normal_stack_ptr);
  Set_coord_stack(normal_stack_ptr, obj.object_ptr^.normal_coord_axes);

  if (obj.object_ptr^.attributes.shader_ptr <> shader_ptr_type(nil)) then
    begin
      shader_height := obj.transform_stack.depth + 1;
      shader_axes := obj.object_ptr^.shader_axes;
      normal_shader_axes := obj.object_ptr^.normal_shader_axes;
    end;
end; {procedure Create_coord_stack}


{***********************}
{ intersection routines }
{***********************}


function Leaf_voxel(voxel_ptr: voxel_ptr_type;
  point: vector_type): voxel_ptr_type;
var
  center: vector_type;
  length, width, height: extent_type;
begin
  {*********************************************}
  { find the leaf subvoxel containing the point }
  {*********************************************}
  while (voxel_ptr^.subdivided) do
    begin
      center := Extent_box_center(voxel_ptr^.extent_box);
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
      voxel_ptr := voxel_ptr^.subvoxel_ptr[length, width, height];
    end;
  Leaf_voxel := voxel_ptr;
end; {function Leaf_voxel}


function Next_voxel(voxel_ptr: voxel_ptr_type;
  ray: ray_type): voxel_ptr_type;
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
          t := (voxel_ptr^.extent_box[left] - ray.location.x) / ray.direction.x;
          next := left;
        end
      else
        begin
          t := (voxel_ptr^.extent_box[right] - ray.location.x) /
            ray.direction.x;
          next := right;
        end;
    end;

  if (ray.direction.y <> 0) then
    begin
      if (ray.direction.y < 0) then
        begin
          new_t := (voxel_ptr^.extent_box[front] - ray.location.y) /
            ray.direction.y;
          temp := front;
        end
      else
        begin
          new_t := (voxel_ptr^.extent_box[back] - ray.location.y) /
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
          new_t := (voxel_ptr^.extent_box[bottom] - ray.location.z) /
            ray.direction.z;
          temp := bottom;
        end
      else
        begin
          new_t := (voxel_ptr^.extent_box[top] - ray.location.z) /
            ray.direction.z;
          temp := top;
        end;
      if (new_t < t) then
        begin
          t := new_t;
          next := temp;
        end;
    end;

  voxel_ptr := voxel_ptr^.neighbor_voxel_ptr[next];
  if (voxel_ptr <> nil) then
    if (voxel_ptr^.subdivided) then
      begin
        point := Vector_sum(ray.location, Vector_scale(ray.direction, t));
        voxel_ptr := Leaf_voxel(voxel_ptr, point);
      end;

  Next_voxel := voxel_ptr;
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


function Primitive_intersection(ray: ray_type;
  tmin, tmax: real;
  var obj: hierarchical_object_type): real;
var
  t: real;
  source_object: boolean;
begin
  source_object := false;
  if ray_originates_from_object then
    if Same_hierarchical_object(obj, originating_object) then
      source_object := true;

  {*****************************}
  { avoid self shadowing meshes }
  {*****************************}
  if source_object then
    begin
      source_face_ptr := originating_object.mesh_face_ptr;
      source_point_ptr := originating_object.mesh_point_ptr;
      t := Second_closest_intersection(ray, tmin, tmax, obj.object_ptr);
      obj.mesh_face_ptr := target_face_ptr;
      obj.mesh_point_ptr := nil;
    end
  else
    begin
      source_face_ptr := nil;
      source_point_ptr := nil;
      t := Closest_intersection(ray, tmin, tmax, obj.object_ptr);
      obj.mesh_face_ptr := target_face_ptr;
      obj.mesh_point_ptr := nil;
    end;

  Primitive_intersection := t;
end; {function Primitive_intersection}


function Voxel_space_intersection(ray: ray_type;
  tmin, tmax: real;
  voxel_ptr: voxel_ptr_type;
  var obj, temp_object: hierarchical_object_type): real;
var
  t, new_t: real;
  point: vector_type;
  found, found_hit: boolean;
  follow: object_ref_ptr_type;
  new_object: hierarchical_object_type;
begin
  found := false;
  t := tmax;

  while ((voxel_ptr <> nil) and (not found)) do
    begin
      {***********************************************}
      { find nearest intersection of objects in voxel }
      {***********************************************}
      found_hit := false;
      follow := voxel_ptr^.object_ref_ptr;
      while (follow <> nil) do
        begin
          new_object := temp_object;
          new_object.object_ptr := follow^.object_ptr;
          new_t := Object_intersection(ray, tmin, t, new_object);
          if (new_t < t) then
            begin
              t := new_t;
              obj := new_object;
              found_hit := true;
            end;
          follow := follow^.next;
        end; {while loop}

      {**************************************}
      { find if we have a valid intersection }
      {**************************************}
      if found_hit then
        begin
          point := Vector_sum(ray.location, Vector_scale(ray.direction, t));
          if Point_in_extent_box(point, voxel_ptr^.extent_box) then
            found := true
          else
            voxel_ptr := Next_voxel(voxel_ptr, ray);
        end
      else
        voxel_ptr := Next_voxel(voxel_ptr, ray);
    end; {while loop}

  {***********************}
  { no intersection found }
  {***********************}
  if (t = tmax) then
    t := infinity;

  Voxel_space_intersection := t;
end; {function Voxel_space_intersection}


function Sequential_intersection(ray: ray_type;
  tmin, tmax: real;
  var obj, temp_object: hierarchical_object_type): real;
var
  t, new_t: real;
  new_object: hierarchical_object_type;
  object_ptr: ray_object_inst_ptr_type;
begin
  t := tmax;
  object_ptr := obj.object_ptr^.object_decl_ptr^.sub_object_ptr;
  while (object_ptr <> nil) do
    begin
      new_object := temp_object;
      new_object.object_ptr := object_ptr;
      new_t := Object_intersection(ray, tmin, t, new_object);
      if (new_t < t) then
        begin
          t := new_t;
          obj := new_object;
        end;
      object_ptr := object_ptr^.next;
    end;

  {***********************}
  { no intersection found }
  {***********************}
  if (t = tmax) then
    t := infinity;

  Sequential_intersection := t;
end; {function Sequential_intersection}


function Complex_object_intersection(ray: ray_type;
  tmin, tmax: real;
  var obj: hierarchical_object_type): real;
var
  voxel_ptr: voxel_ptr_type;
  object_ptr: ray_object_inst_ptr_type;
  new_object, temp_object: hierarchical_object_type;
  t, new_t: real;
  point: vector_type;
  inside_object: boolean;
  ray_hits_object: boolean;
begin
  Transform_point_to_axes(ray.location, obj.object_ptr^.coord_axes);
  Transform_vector_to_axes(ray.direction, obj.object_ptr^.coord_axes);

  {**********************************}
  { find if ray starts inside object }
  {**********************************}
  point := ray.location;
  inside_object := false;
  if (abs(point.x) <= 1) then
    if (abs(point.y) <= 1) then
      if (abs(point.z) <= 1) then
        inside_object := true;

  {*************************}
  { find if ray hits object }
  {*************************}
  ray_hits_object := true;
  if not inside_object then
    if (Voxel_intersection(ray, point) = infinity) then
      ray_hits_object := false;

  {*****************************************************}
  { compute bounds on region defined by clipping planes }
  {*****************************************************}
  if obj.object_ptr^.object_decl_ptr^.clipping_plane_ptr <> nil then
    Find_clipping_span(ray, tmin, tmax,
      obj.object_ptr^.object_decl_ptr^.clipping_plane_ptr);

  {**************}
  { check object }
  {**************}
  t := tmax;
  temp_object := obj;
  object_ptr := obj.object_ptr;

  {********************************}
  { push transformation onto stack }
  {********************************}
  with temp_object do
    begin
      transform_stack.depth := transform_stack.depth + 1;
      transform_stack.stack[transform_stack.depth] := obj.object_ptr;
    end;

  {************************************}
  { find intersection with sub objects }
  {************************************}
  if (tmin < tmax) then
    begin
      if (ray_hits_object) or (object_ptr^.object_decl_ptr^.infinite) then
        begin
          if obj.object_ptr^.object_decl_ptr^.voxel_space_ptr <> nil then
            begin
              {*************************}
              { walk ray through voxels }
              {*************************}
              voxel_ptr := obj.object_ptr^.object_decl_ptr^.voxel_space_ptr;
              voxel_ptr := Leaf_voxel(voxel_ptr, point);
              t := Voxel_space_intersection(ray, tmin, t, voxel_ptr, obj,
                temp_object);
            end
          else
            begin
              {*****************************}
              { sequentially search objects }
              {*****************************}
              t := Sequential_intersection(ray, tmin, t, obj, temp_object);
            end;
        end; {complex_object intersection}

      {***************************}
      { check for infinite planes }
      {***************************}
      if object_ptr^.object_decl_ptr^.infinite then
        begin
          object_ptr := object_ptr^.object_decl_ptr^.sub_object_ptr;
          while (object_ptr <> nil) do
            begin
              if object_ptr^.kind = plane then
                begin
                  new_object := temp_object;
                  new_object.object_ptr := object_ptr;
                  new_t := Primitive_intersection(ray, tmin, t, new_object);
                  if (new_t < t) then
                    begin
                      t := new_t;
                      obj := new_object;
                    end;
                end;
              object_ptr := object_ptr^.next;
            end;
        end;
    end;

  {***********************}
  { no intersection found }
  {***********************}
  if (t = tmax) then
    t := infinity;

  Complex_object_intersection := t;
end; {function Complex_object_intersection}


function Object_intersection(ray: ray_type;
  tmin, tmax: real;
  var obj: hierarchical_object_type): real;
const
  interpolated_prims = [flat_polygon, shaded_triangle, shaded_polygon, mesh,
    volume];
var
  t: real;
  mailbox_hit: boolean;
begin
  mailbox_hit := false;
  with obj.object_ptr^ do
    if Equal_vector(ray.direction, mailbox.ray.direction) then
      if Equal_vector(ray.location, mailbox.ray.location) then
        mailbox_hit := true;

  with obj.object_ptr^ do
    if mailbox_hit then
      begin
        t := mailbox.t;
        obj := mailbox.primitive_object;
      end
    else
      begin
        if (obj.object_ptr^.kind <> complex_object) then
          begin
            t := Primitive_intersection(ray, tmin, tmax, obj);
            if (t <> infinity) then
              begin
                {***********************************}
                { save data to compute normal later }
                {***********************************}
                with obj.object_ptr^ do
                  if kind in interpolated_prims then
                    case kind of
                      flat_polygon:
                        begin
                          ray_mesh_data_ptr^.texture_interpolation :=
                            last_ray_texture_interpolation;
                          ray_mesh_data_ptr^.u_axis_interpolation :=
                            last_ray_u_axis_interpolation;
                          ray_mesh_data_ptr^.v_axis_interpolation :=
                            last_ray_v_axis_interpolation;
                        end;

                      shaded_polygon:
                        begin
                          ray_mesh_data_ptr^.normal_interpolation :=
                            last_ray_normal_interpolation;
                          ray_mesh_data_ptr^.texture_interpolation :=
                            last_ray_texture_interpolation;
                          ray_mesh_data_ptr^.u_axis_interpolation :=
                            last_ray_u_axis_interpolation;
                          ray_mesh_data_ptr^.v_axis_interpolation :=
                            last_ray_v_axis_interpolation;
                        end;

                      shaded_triangle:
                        begin
                          triangle_interpolation_ptr^ :=
                            last_ray_normal_interpolation;
                        end;

                      mesh:
                        begin
                          if not smoothing then
                            begin
                              ray_mesh_data_ptr^.mesh_normal := last_ray_normal;
                              ray_mesh_data_ptr^.texture_interpolation :=
                                last_ray_texture_interpolation;
                              ray_mesh_data_ptr^.u_axis_interpolation :=
                                last_ray_u_axis_interpolation;
                              ray_mesh_data_ptr^.v_axis_interpolation :=
                                last_ray_v_axis_interpolation;
                            end
                          else
                            begin
                              ray_mesh_data_ptr^.normal_interpolation :=
                                last_ray_normal_interpolation;
                              ray_mesh_data_ptr^.texture_interpolation :=
                                last_ray_texture_interpolation;
                              ray_mesh_data_ptr^.u_axis_interpolation :=
                                last_ray_u_axis_interpolation;
                              ray_mesh_data_ptr^.v_axis_interpolation :=
                                last_ray_v_axis_interpolation;
                            end;
                        end;

                      volume:
                        begin
                          if not volume_ptr^.smoothing then
                            begin
                              ray_mesh_data_ptr^.mesh_normal := last_ray_normal;
                              ray_mesh_data_ptr^.texture_interpolation :=
                                last_ray_texture_interpolation;
                              ray_mesh_data_ptr^.u_axis_interpolation :=
                                last_ray_u_axis_interpolation;
                              ray_mesh_data_ptr^.v_axis_interpolation :=
                                last_ray_v_axis_interpolation;
                            end
                          else
                            begin
                              ray_mesh_data_ptr^.normal_interpolation :=
                                last_ray_normal_interpolation;
                              ray_mesh_data_ptr^.texture_interpolation :=
                                last_ray_texture_interpolation;
                              ray_mesh_data_ptr^.u_axis_interpolation :=
                                last_ray_u_axis_interpolation;
                              ray_mesh_data_ptr^.v_axis_interpolation :=
                                last_ray_v_axis_interpolation;
                            end;
                        end;

                    end; {case}
              end;
          end
        else
          t := Complex_object_intersection(ray, tmin, tmax, obj);

        {******************************}
        { save intersection in mailbox }
        {******************************}
        mailbox.t := t;
        mailbox.ray := ray;
        mailbox.primitive_object := obj;
      end;

  {*****************}
  { no intersection }
  {*****************}
  if (t = tmax) then
    t := infinity;

  Object_intersection := t;
end; {function Object_intersection}


function Shadow_ray_intersection(ray: ray_type;
  tmin, tmax: real;
  var obj: hierarchical_object_type;
  var source_object: hierarchical_object_type): real;
var
  follow: ray_object_inst_ptr_type;
  t, new_t: real;
  new_object: hierarchical_object_type;
begin
  t := tmax;
  closest_t := infinity;

  {*******************}
  { set source object }
  {*******************}
  ray_originates_from_object := true;
  originating_object := source_object;

  follow := raytracing_scene_ptr;
  while (follow <> nil) do
    if (follow^.kind = plane) then
      follow := follow^.next
    else
      begin
        new_object.object_ptr := follow;
        new_object.transform_stack.depth := 0;
        new_t := Object_intersection(ray, tmin, t, new_object);
        if (new_t < t) then
          begin
            t := new_t;
            obj := new_object;
          end;
        follow := follow^.next;
      end;

  {*****************}
  { no intersection }
  {*****************}
  if (t = tmax) then
    t := infinity;

  Shadow_ray_intersection := t;
end; {function Shadow_ray_intersection}


function Secondary_ray_intersection(ray: ray_type;
  tmin, tmax: real;
  var obj: hierarchical_object_type;
  var source_object: hierarchical_object_type): real;
var
  follow: ray_object_inst_ptr_type;
  t, new_t: real;
  new_object: hierarchical_object_type;
begin
  t := tmax;
  closest_t := infinity;

  {*******************}
  { set source object }
  {*******************}
  ray_originates_from_object := true;
  originating_object := source_object;

  follow := raytracing_scene_ptr;
  while (follow <> nil) do
    begin
      new_object.object_ptr := follow;
      new_object.transform_stack.depth := 0;
      new_t := Object_intersection(ray, tmin, t, new_object);
      if (new_t < t) then
        begin
          t := new_t;
          obj := new_object;
        end;
      follow := follow^.next;
    end;

  {*****************}
  { no intersection }
  {*****************}
  if (t = tmax) then
    t := infinity;

  Secondary_ray_intersection := t;
end; {function Secondary_ray_intersection}


function Primary_ray_intersection(ray: ray_type;
  tmin, tmax: real;
  var obj: hierarchical_object_type): real;
var
  follow: ray_object_inst_ptr_type;
  t, new_t: real;
  new_object: hierarchical_object_type;
begin
  t := tmax;
  closest_t := infinity;

  ray_originates_from_object := false;
  source_face_ptr := nil;
  source_point_ptr := nil;

  follow := raytracing_scene_ptr;
  while (follow <> nil) do
    begin
      new_object.object_ptr := follow;
      new_object.transform_stack.depth := 0;
      new_object.mesh_face_ptr := nil;
      new_t := Object_intersection(ray, tmin, t, new_object);
      if (new_t < t) then
        begin
          t := new_t;
          obj := new_object;
        end;
      follow := follow^.next;
    end;

  {*****************}
  { no intersection }
  {*****************}
  if (t = tmax) then
    t := infinity;

  Primary_ray_intersection := t;
end; {function Primary_ray_intersection}


initialization
  if memory_alert then
    writeln('allocating new global object');
  new(global_object_ptr);

  global_coord_stack_ptr := New_coord_stack;
  global_normal_stack_ptr := New_coord_stack;
  Init_hierarchical_obj(originating_object);
end.
