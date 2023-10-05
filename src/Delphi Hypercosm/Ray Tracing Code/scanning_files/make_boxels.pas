unit make_boxels;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             make_boxels               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is used to create the screen space          }
{       ray tracing data structure.                             }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  trans, coord_axes, raytrace, pixels, drawable;


type
  primary_object_ptr_type = ^primary_object_type;
  primary_object_type = record
    {*****************************************}
    { copy of object extracted from hierarchy }
    {*****************************************}
    object_ptr: ray_object_inst_ptr_type;

    {***********************************}
    { corresponding object in hierarchy }
    {***********************************}
    obj: hierarchical_object_type;

    {***************************}
    { distance to nearest point }
    {***************************}
    distance: real;

    next: primary_object_ptr_type;
  end; {primary_object_type record}


  boxel_entry_ptr_type = ^boxel_entry_type;
  boxel_entry_type = record
    primary_object_ptr: primary_object_ptr_type;
    next: boxel_entry_ptr_type;
  end; {boxel_entry_type record}


  boxel_entry_ref_type = ^boxel_entry_ptr_type;


var
  boxel_width, boxel_height: integer;
  boxels_made: boolean;
  scene_axes: coord_axes_type;
  infinite_primary_list: primary_object_ptr_type;


procedure Make_boxel_space(size: pixel_type;
  drawable: drawable_type;
  scene_ptr: ray_object_inst_ptr_type;
  scene_trans: trans_type);
procedure Free_boxel_space;
function Index_boxel_array(h, v: integer): boxel_entry_ref_type;


implementation
uses
  errors, new_memory, constants, vectors, vectors2, colors,
  screen_clip, extents, bounds, project, viewports, visibility,
  coord_stack, geometry, topology, b_rep, xform_b_rep, objects, object_attr,
  z_vertices, z_pipeline, z_screen_clip, z_clip, b_rep_prims, show_lines;


const
  block_size = 512;
  memory_alert = false;


  {**************************************}
  { complex objects with a projection    }
  { which occupies more than this amount }
  { of screen space will be broken down  }
  {**************************************}
const
  max_primary_size = 0.5;


type
  primary_object_block_ptr_type = ^primary_object_block_type;
  boxel_entry_block_ptr_type = ^boxel_entry_block_type;

  primary_object_block_type = array[0..block_size] of primary_object_type;
  boxel_entry_block_type = array[0..block_size] of boxel_entry_type;


  {******************************}
  { scan conversion data structs }
  {******************************}
  boxel_edge_ptr_type = ^boxel_edge_type;
  boxel_edge_type = record

    {***************************************}
    { x, z = the projection of the vertex   }
    {***************************************}
    x, x_increment: real;
    z, z_increment: real;

    y_max: integer;
    next: boxel_edge_ptr_type;
  end; {boxel_edge_type}

  {****************************************}
  { dynamically allocated boxel edge table }
  {****************************************}
  boxel_edge_table_type = boxel_edge_ptr_type;
  boxel_edge_table_ptr_type = ^boxel_edge_table_type;


var
  {**************************}
  { resolution of boxel grid }
  {**************************}
  h_boxels, v_boxels: integer;
  boxel_array_ptr: boxel_entry_ptr_type;

  {**************************}
  { miscillaneous free lists }
  {**************************}
  primary_object_free_list: primary_object_ptr_type;
  boxel_entry_free_list: boxel_entry_ptr_type;

  primary_object_block_ptr: primary_object_block_ptr_type;
  boxel_entry_block_ptr: boxel_entry_block_ptr_type;

  primary_object_counter: integer;
  boxel_entry_counter: integer;

  {*********}
  { globals }
  {*********}
  primary_object_list: primary_object_ptr_type;
  unit_square_ptr: surface_ptr_type;
  unit_cube_ptr: surface_ptr_type;
  global_primary_ptr: primary_object_ptr_type;

  {****************************************}
  { stack for object to eye transformation }
  {****************************************}
  coord_stack_ptr: coord_stack_ptr_type;
  normal_stack_ptr: coord_stack_ptr_type;

  {*********************************}
  { variables for maintaining the   }
  { edge table and active edge list }
  { used in scan conversion.        }
  {*********************************}
  boxel_y_min, boxel_y_max: integer;
  boxel_edge_table_ptr: boxel_edge_table_ptr_type;
  boxel_active_edge_list: boxel_edge_ptr_type;
  boxel_edge_free_list: boxel_edge_ptr_type;


{*************************************}
{ functions to access dynamic buffers }
{*************************************}


function Index_boxel_array(h, v: integer): boxel_entry_ref_type;
var
  offset: longint;
begin
  offset := (longint(h) + (longint(v) * longint(h_boxels + 1))) *
    sizeof(boxel_entry_ptr_type);
  Index_boxel_array := boxel_entry_ref_type(longint(boxel_array_ptr) + offset);
end; {function Index_boxel_array}


function Index_boxel_edge_table(index: integer): boxel_edge_table_ptr_type;
var
  offset: longint;
begin
  offset := (longint(boxel_edge_table_ptr) + longint(index) *
    sizeof(boxel_edge_table_type));
  Index_boxel_edge_table := boxel_edge_table_ptr_type(offset);
end; {function Index_boxel_edge_table}


{******************************************************}
{ routines to allocate and deallocate boxel structures }
{******************************************************}


function New_primary_object: primary_object_ptr_type;
var
  primary_object_ptr: primary_object_ptr_type;
  index: integer;
begin
  {***********************************}
  { get primary object from free list }
  {***********************************}
  if (primary_object_free_list <> nil) then
    begin
      primary_object_ptr := primary_object_free_list;
      primary_object_free_list := primary_object_ptr^.next;
    end
  else
    begin
      index := primary_object_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new primary object');
          new(primary_object_block_ptr);
        end;

      primary_object_ptr := @primary_object_block_ptr^[index];
      primary_object_counter := primary_object_counter + 1;
    end;

  {***************************}
  { initialize primary object }
  {***************************}
  with primary_object_ptr^ do
    begin
      object_ptr := nil;
      next := nil;
    end;

  New_primary_object := primary_object_ptr;
end; {function New_primary_object}


procedure Free_primary_object(var primary_object_ptr: primary_object_ptr_type);
begin
  {************************************************}
  { free ray object copy but not its shared fields }
  {************************************************}
  Free_ray_object_copy(primary_object_ptr^.object_ptr);

  {*********************************}
  { add primary object to free list }
  {*********************************}
  primary_object_ptr^.next := primary_object_free_list;
  primary_object_free_list := primary_object_ptr;
  primary_object_ptr := nil;
end; {procedure Free_primary_object}


function New_boxel_entry: boxel_entry_ptr_type;
var
  boxel_entry_ptr: boxel_entry_ptr_type;
  index: integer;
begin
  {********************************}
  { get boxel entry from free list }
  {********************************}
  if (boxel_entry_free_list <> nil) then
    begin
      boxel_entry_ptr := boxel_entry_free_list;
      boxel_entry_free_list := boxel_entry_ptr^.next;
    end
  else
    begin
      index := boxel_entry_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new boxel entry block');
          new(boxel_entry_block_ptr);
        end;

      boxel_entry_ptr := @boxel_entry_block_ptr^[index];
      boxel_entry_counter := boxel_entry_counter + 1;
    end;

  {************************}
  { initialize boxel_entry }
  {************************}
  with boxel_entry_ptr^ do
    begin
      next := nil;
    end;

  New_boxel_entry := boxel_entry_ptr;
end; {function New_boxel_entry}


procedure Free_boxel_entry(var boxel_entry_ptr: boxel_entry_ptr_type);
begin
  {******************************}
  { add boxel entry to free list }
  {******************************}
  boxel_entry_ptr^.next := boxel_entry_free_list;
  boxel_entry_free_list := boxel_entry_ptr;
  boxel_entry_ptr := nil;
end; {procedure Free_boxel_entry}


function New_boxel_array(width, height: integer): boxel_entry_ptr_type;
var
  boxel_array_size: longint;
  boxel_array_ptr: boxel_entry_ptr_type;
begin
  {**********************}
  { allocate boxel array }
  {**********************}
  boxel_array_size := longint(width + 1) * longint(height + 1);
  boxel_array_size := boxel_array_size * sizeof(boxel_entry_ptr_type);

  if memory_alert then
    writeln('allocating new boxel array');
  boxel_array_ptr := boxel_entry_ptr_type(New_ptr(boxel_array_size));

  New_boxel_array := boxel_array_ptr;
end; {function New_boxel_array}


function New_boxel_edge_table(height: integer): boxel_edge_table_ptr_type;
var
  boxel_edge_table_size: longint;
  boxel_edge_table_ptr: boxel_edge_table_ptr_type;
begin
  {***************************}
  { allocate boxel edge table }
  {***************************}
  boxel_edge_table_size := longint(height + 1) * sizeof(boxel_edge_table_type);

  if memory_alert then
    writeln('allocating new boxel edge table');
  boxel_edge_table_ptr :=
    boxel_edge_table_ptr_type(New_ptr(boxel_edge_table_size));

  New_boxel_edge_table := boxel_edge_table_ptr;
end; {function New_boxel_edge_table}


{************************************}
{ routines to create primary objects }
{************************************}


function Perpendicular_parallelogram_distance(point: vector_type;
  vertex, vector1, vector2: vector_type): real;
var
  normal: vector_type;
  trans: trans_type;
  coord_axes: coord_axes_type;
  distance: real;
begin
  distance := infinity;

  {************************************}
  { create coord axes of parallelogram }
  {************************************}
  normal := Normalize(Cross_product(vector1, vector2));
  trans.origin := vertex;
  trans.x_axis := vector1;
  trans.y_axis := vector2;
  trans.z_axis := normal;
  coord_axes := Trans_to_axes(trans);

  {********************************************}
  { transform point to coords of parallelogram }
  {********************************************}
  Transform_point_to_axes(point, coord_axes);

  {*******************************}
  { if point is above unit square }
  {*******************************}
  if (point.x > 0) and (point.x < 1) then
    if (point.y > 0) and (point.y < 1) then
      distance := abs(point.z);

  Perpendicular_parallelogram_distance := distance;
end; {function Perpendicular_parallelogram_distance}


function Primary_distance(bounds: bounding_type;
  coord_axes: coord_axes_type): real;
var
  distance, temp: real;
  counter1, counter2, counter3: extent_type;
  point, vertex, vector1, vector2: vector_type;
begin
  distance := infinity;
  point := zero_vector;

  if (bounds.bounding_kind = non_planar_bounds) then
    begin
      vertex := point;
      Transform_point_to_axes(vertex, coord_axes);
      if Point_in_extent_box(vertex, unit_extent_box) then
        distance := 0;
    end;

  {*************************************************}
  { point outside of bounds - find minimum distance }
  {*************************************************}
  if (distance <> 0) then
    with bounds do
      case bounding_kind of

        planar_bounds:
          begin
            {***********************************}
            { find closest distance to vertices }
            {***********************************}
            for counter1 := left to right do
              for counter2 := front to back do
                begin
                  temp := Vector_length(bounding_square[counter1, counter2]);
                  if (temp < distance) then
                    distance := temp;
                end;

            {**********************************************}
            { find perpendicular distance to parallelogram }
            {**********************************************}
            vertex := bounding_square[left, front];
            vector1 := Vector_difference(bounding_square[right, front], vertex);
            vector2 := Vector_difference(bounding_square[left, back], vertex);
            temp := Perpendicular_parallelogram_distance(point, vertex, vector1,
              vector2);
            if (temp < distance) then
              distance := temp;
          end;

        non_planar_bounds:
          begin
            {***********************************}
            { find closest distance to vertices }
            {***********************************}
            for counter1 := left to right do
              for counter2 := front to back do
                for counter3 := bottom to top do
                  begin
                    temp := Vector_length(bounding_box[counter1, counter2,
                      counter3]);
                    if (temp < distance) then
                      distance := temp;
                  end;

            {******************************************}
            { find perpendicular distance to left face }
            {******************************************}
            vertex := bounding_box[left, front, bottom];
            vector1 := Vector_difference(bounding_box[left, back, bottom],
              vertex);
            vector2 := Vector_difference(bounding_box[left, front, top],
              vertex);
            temp := Perpendicular_parallelogram_distance(point, vertex, vector1,
              vector2);
            if (temp < distance) then
              distance := temp;

            {*******************************************}
            { find perpendicular distance to right face }
            {*******************************************}
            vertex := bounding_box[right, front, bottom];
            vector1 := Vector_difference(bounding_box[right, back, bottom],
              vertex);
            vector2 := Vector_difference(bounding_box[right, front, top],
              vertex);
            temp := Perpendicular_parallelogram_distance(point, vertex, vector1,
              vector2);
            if (temp < distance) then
              distance := temp;

            {*******************************************}
            { find perpendicular distance to front face }
            {*******************************************}
            vertex := bounding_box[left, front, bottom];
            vector1 := Vector_difference(bounding_box[right, front, bottom],
              vertex);
            vector2 := Vector_difference(bounding_box[left, front, top],
              vertex);
            temp := Perpendicular_parallelogram_distance(point, vertex, vector1,
              vector2);
            if (temp < distance) then
              distance := temp;

            {******************************************}
            { find perpendicular distance to back face }
            {******************************************}
            vertex := bounding_box[left, back, bottom];
            vector1 := Vector_difference(bounding_box[right, back, bottom],
              vertex);
            vector2 := Vector_difference(bounding_box[left, back, top], vertex);
            temp := Perpendicular_parallelogram_distance(point, vertex, vector1,
              vector2);
            if (temp < distance) then
              distance := temp;

            {********************************************}
            { find perpendicular distance to bottom face }
            {********************************************}
            vertex := bounding_box[left, front, bottom];
            vector1 := Vector_difference(bounding_box[right, front, bottom],
              vertex);
            vector2 := Vector_difference(bounding_box[left, back, bottom],
              vertex);
            temp := Perpendicular_parallelogram_distance(point, vertex, vector1,
              vector2);
            if (temp < distance) then
              distance := temp;

            {*****************************************}
            { find perpendicular distance to top face }
            {*****************************************}
            vertex := bounding_box[left, front, top];
            vector1 := Vector_difference(bounding_box[right, front, top],
              vertex);
            vector2 := Vector_difference(bounding_box[left, back, top], vertex);
            temp := Perpendicular_parallelogram_distance(point, vertex, vector1,
              vector2);
            if (temp < distance) then
              distance := temp;
          end;

        infinite_planar_bounds, infinite_non_planar_bounds:
          distance := 0;

      end; {case}
  Primary_distance := distance;
end; {function Primary_distance}


function Make_primary_object(object_ptr: ray_object_inst_ptr_type;
  transform_stack: transform_stack_type;
  attributes: object_attributes_type;
  shader_axes: coord_axes_type;
  normal_shader_axes: coord_axes_type): primary_object_ptr_type;
var
  primary_object_ptr: primary_object_ptr_type;
  trans: trans_type;
begin
  primary_object_ptr := New_primary_object;
  primary_object_ptr^.object_ptr := New_ray_object_inst;

  {**************************}
  { make hierarchical object }
  {**************************}
  primary_object_ptr^.obj.object_ptr := object_ptr;
  primary_object_ptr^.obj.transform_stack := transform_stack;

  {***************************************}
  { copy object ptr to new copy of object }
  {***************************************}
  primary_object_ptr^.object_ptr^ := object_ptr^;
  object_ptr := primary_object_ptr^.object_ptr;

  {***************************}
  { initialize new ray object }
  {***************************}
  object_ptr^.attributes := attributes;
  object_ptr^.shader_axes := shader_axes;
  object_ptr^.normal_shader_axes := normal_shader_axes;
  object_ptr^.next := nil;

  Get_coord_stack(coord_stack_ptr, object_ptr^.coord_axes);
  Get_coord_stack(normal_stack_ptr, object_ptr^.normal_coord_axes);

  {***************************}
  { distance to nearest point }
  {***************************}
  trans := Axes_to_trans(object_ptr^.coord_axes);
  Make_bounds(object_ptr^.bounds, object_ptr^.bounds.bounding_kind, trans);
  primary_object_ptr^.distance := Primary_distance(object_ptr^.bounds,
    object_ptr^.coord_axes);

  {***************************************}
  { transform object back to world coords }
  {***************************************}
  {Transform_axes_to_axes(object_ptr^.coord_axes, scene_axes);}
  {Transform_axes_to_axes(object_ptr^.normal_coord_axes, scene_axes);}

  Make_primary_object := primary_object_ptr;
end; {function Make_primary_object}


{******************************************}
{ routines to create boxel data structures }
{******************************************}


procedure Draw_boxel(drawable: drawable_type;
  width, height: integer);
var
  pixel1, pixel2: pixel_type;
  block_exists: boolean;
begin
  pixel1.h := width * boxel_width;
  pixel1.v := height * boxel_height;
  pixel2.h := pixel1.h + boxel_width;
  pixel2.v := pixel1.v + boxel_height;

  Clip_block_to_screen_box(pixel1, pixel2, block_exists,
    current_projection_ptr^.screen_box);

  {**********}
  { draw box }
  {**********}
  drawable.Draw_rect(pixel1, pixel2);
end; {procedure Draw_boxel}


procedure Make_boxel_entry(primary_object_ptr: primary_object_ptr_type;
  h_index, v_index: integer);
var
  boxel_entry_ref_ptr: boxel_entry_ref_type;
  boxel_entry_ptr: boxel_entry_ptr_type;
  previous, next: boxel_entry_ptr_type;
  found, already_there: boolean;
begin
  boxel_entry_ref_ptr := Index_boxel_array(h_index, v_index);

  {********************************}
  { find where to insert into list }
  {********************************}
  previous := nil;
  next := boxel_entry_ref_ptr^;
  found := false;
  while (next <> nil) and not found do
    begin
      if (primary_object_ptr^.distance > next^.primary_object_ptr^.distance)
        then
        begin
          previous := next;
          next := next^.next;
        end
      else
        begin
          {*****************************}
          { found where to insert entry }
          {*****************************}
          found := true;
        end;
    end;

  {**************************************************}
  { check that primary object is not already in list }
  {**************************************************}
  already_there := false;
  if (next <> nil) then
    if next^.primary_object_ptr = primary_object_ptr then
      already_there := true;

  if not already_there then
    begin
      {****************************}
      { initialize new boxel entry }
      {****************************}
      boxel_entry_ptr := New_boxel_entry;
      boxel_entry_ptr^.primary_object_ptr := primary_object_ptr;
      boxel_entry_ptr^.next := nil;

      if (previous = nil) then
        begin
          {************************}
          { insert at head of list }
          {************************}
          boxel_entry_ptr^.next := boxel_entry_ref_ptr^;
          boxel_entry_ref_ptr^ := boxel_entry_ptr;
        end
      else
        begin
          {*********************************}
          { insert in middle or end of list }
          {*********************************}
          previous^.next := boxel_entry_ptr;
          boxel_entry_ptr^.next := next;
        end;
    end;
end; {procedure Make_boxel_entry}


{***********************}
{ boxel scan conversion }
{***********************}


procedure Sort_boxel_edges(var boxel_edge_ptr: boxel_edge_ptr_type);
var
  list1, list2, temp: boxel_edge_ptr_type;
begin
  {*********************************}
  { Merge_sort edges on incresing x }
  {*********************************}
  if (boxel_edge_ptr <> nil) then
    if (boxel_edge_ptr^.next <> nil) then
      {********************}
      { at least two edges }
      {********************}
      begin
        {*****************************}
        { divide edges into two lists }
        {*****************************}
        list1 := nil;
        list2 := nil;
        while (boxel_edge_ptr <> nil) do
          begin
            {*******************}
            { add edge to list1 }
            {*******************}
            temp := boxel_edge_ptr;
            boxel_edge_ptr := boxel_edge_ptr^.next;
            temp^.next := list1;
            list1 := temp;

            {*******************}
            { add edge to list2 }
            {*******************}
            if (boxel_edge_ptr <> nil) then
              begin
                temp := boxel_edge_ptr;
                boxel_edge_ptr := boxel_edge_ptr^.next;
                temp^.next := list2;
                list2 := temp;
              end;
          end; {while}

        Sort_boxel_edges(list1);
        Sort_boxel_edges(list2);

        {*************}
        { merge lists }
        {*************}
        boxel_edge_ptr := nil;

        {*****************************}
        { temp points to tail of list }
        {*****************************}
        temp := nil;
        while (list1 <> nil) and (list2 <> nil) do
          begin
            if (list1^.x < list2^.x) then
              begin
                {**********************************}
                { add edge from list1 to edge list }
                {**********************************}
                if (temp = nil) then
                  begin
                    boxel_edge_ptr := list1;
                    temp := list1;
                    list1 := list1^.next;
                  end
                else
                  begin
                    temp^.next := list1;
                    temp := list1;
                    list1 := list1^.next;
                  end;
              end
            else
              begin
                {**********************************}
                { add edge from list2 to edge list }
                {**********************************}
                if (temp = nil) then
                  begin
                    boxel_edge_ptr := list2;
                    temp := list2;
                    list2 := list2^.next;
                  end
                else
                  begin
                    temp^.next := list2;
                    temp := list2;
                    list2 := list2^.next;
                  end;
              end;
          end; {while}
        if (temp <> nil) then
          begin
            if (list1 = nil) then
              temp^.next := list2
            else
              temp^.next := list1;
          end;
      end;
end; {Sort_boxel_edges}


function New_boxel_edge: boxel_edge_ptr_type;
var
  boxel_edge_ptr: boxel_edge_ptr_type;
begin
  {***********************************}
  { get new boxel edge from free list }
  {***********************************}
  if (boxel_edge_free_list <> nil) then
    begin
      boxel_edge_ptr := boxel_edge_free_list;
      boxel_edge_free_list := boxel_edge_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new boxel edge');
      new(boxel_edge_ptr);
    end;

  New_boxel_edge := boxel_edge_ptr;
end; {function New_boxel_edge}


procedure Add_boxel_edge(z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type);
var
  boxel_edge_ptr: boxel_edge_ptr_type;
  point1, point2: vector_type;
  boxel_table_ptr: boxel_edge_table_ptr_type;
  edge_vector: vector_type;
  edge_y_min, edge_y_max: integer;
  z_vertex_ptr: z_vertex_ptr_type;
  y_inverse, y_offset: real;
begin
  {************************************************}
  { make vertex1 the one with the smallest y coord }
  {************************************************}
  if (z_vertex_ptr1^.point.y > z_vertex_ptr2^.point.y) then
    begin
      z_vertex_ptr := z_vertex_ptr1;
      z_vertex_ptr1 := z_vertex_ptr2;
      z_vertex_ptr2 := z_vertex_ptr;
    end;

  point1 := z_vertex_ptr1^.point;
  point2 := z_vertex_ptr2^.point;

  edge_y_min := Trunc(point1.y + 1);
  edge_y_max := Trunc(point2.y + 1) - 1;

  if (edge_y_min <= edge_y_max) then
    begin
      boxel_edge_ptr := New_boxel_edge;

      {***********************}
      { initialize boxel edge }
      {***********************}
      boxel_edge_ptr^.y_max := edge_y_max;
      edge_vector := Vector_difference(point2, point1);
      y_inverse := 1 / edge_vector.y;

      {*****************}
      { projected point }
      {*****************}
      boxel_edge_ptr^.x_increment := edge_vector.x * y_inverse;
      boxel_edge_ptr^.z_increment := edge_vector.z * y_inverse;

      {**********************************************}
      { adjust x,z intercepts to accout for snapping }
      { the y coord to an integer scanline.      }
      {**********************************************}
      y_offset := (edge_y_min - point1.y);

      {*****************}
      { projected point }
      {*****************}
      boxel_edge_ptr^.x := point1.x + (boxel_edge_ptr^.x_increment * y_offset);
      boxel_edge_ptr^.z := point1.z + (boxel_edge_ptr^.z_increment * y_offset);

      {************************}
      { add edge to edge table }
      {************************}
      boxel_table_ptr := Index_boxel_edge_table(edge_y_min);
      boxel_edge_ptr^.next := boxel_table_ptr^;
      boxel_table_ptr^ := boxel_edge_ptr;

      {********************************}
      { update polygon y_min and y_max }
      {********************************}
      if (edge_y_min < boxel_y_min) then
        boxel_y_min := edge_y_min;
      if (boxel_edge_ptr^.y_max > boxel_y_max) then
        boxel_y_max := boxel_edge_ptr^.y_max;
    end;
end; {procedure Add_boxel_edge}


procedure End_boxel_polygon;
var
  counter: integer;
  boxel_table_ptr: boxel_edge_table_ptr_type;
  boxel_edge_ptr, temp: boxel_edge_ptr_type;
  z_vertex_ptr1, z_vertex_ptr2: z_vertex_ptr_type;
  follow: z_polygon_ptr_type;
begin
  {*************************************************}
  { return edges from previous polygon to free list }
  {*************************************************}
  for counter := boxel_y_min to boxel_y_max do
    begin
      boxel_table_ptr := Index_boxel_edge_table(counter);
      boxel_edge_ptr := boxel_table_ptr^;
      while (boxel_edge_ptr <> nil) do
        begin
          {*****************************}
          { add boxel edge to free list }
          {*****************************}
          temp := boxel_edge_ptr;
          boxel_edge_ptr := boxel_edge_ptr^.next;
          temp^.next := boxel_edge_free_list;
          boxel_edge_free_list := temp;
        end;
    end;

  boxel_y_min := maxint;
  boxel_y_max := -1;

  {******************************************}
  { enter edges of new polygon to edge table }
  {******************************************}
  follow := z_polygon_list;
  while follow <> nil do
    begin
      if (follow^.first <> nil) then
        begin
          z_vertex_ptr1 := follow^.first;
          if (z_vertex_ptr1^.next <> nil) then
            begin
              z_vertex_ptr2 := z_vertex_ptr1^.next;
              while (z_vertex_ptr2 <> nil) do
                begin
                  Add_boxel_edge(z_vertex_ptr1, z_vertex_ptr2);
                  z_vertex_ptr1 := z_vertex_ptr2;
                  z_vertex_ptr2 := z_vertex_ptr2^.next;
                end;
              Add_boxel_edge(z_vertex_ptr1, follow^.first);
            end;
        end;
      follow := follow^.next;
    end;

  {***********************************************}
  { go through the edge table from y_min to y_max }
  { and sort the edges by their x component       }
  {***********************************************}
  if (boxel_y_min < boxel_y_max) then
    for counter := boxel_y_min to boxel_y_max do
      begin
        boxel_table_ptr := Index_boxel_edge_table(counter);
        Sort_boxel_edges(boxel_table_ptr^);
      end;

  {*****************************************}
  { return vertices of polygon to free list }
  {*****************************************}
  Free_z_vertex_list(z_polygon_list);
end; {procedure End_boxel_polygon}


procedure Boxelize_pixel(drawable: drawable_type;
  pixel: pixel_type);
begin
  Make_boxel_entry(global_primary_ptr, pixel.h, pixel.v);
  if draw_voxels then
    Draw_boxel(drawable, pixel.h, pixel.v);
end; {procedure Boxelize_pixel}


procedure Boxelize_scanline(drawable: drawable_type;
  scanline: integer;
  boxel_edge_list: boxel_edge_ptr_type);
var
  min, max, counter: integer;
  pixel: pixel_type;
begin
  {*********************}
  { boxelize a scanline }
  {*********************}
  while (boxel_edge_list <> nil) do
    if (boxel_edge_list^.next = nil) then
      boxel_edge_list := nil
    else
      begin
        min := Trunc(boxel_edge_list^.x + 1);
        boxel_edge_list := boxel_edge_list^.next;
        max := Trunc(boxel_edge_list^.x);

        counter := min;
        while (counter <= max) do
          begin
            {******************}
            { make boxel entry }
            {******************}
            pixel.h := counter;
            pixel.v := scanline;
            Boxelize_pixel(drawable, pixel);
            counter := counter + 1;
          end;
        boxel_edge_list := boxel_edge_list^.next;
      end;
end; {procedure Boxelize_scanline}


procedure Boxelize_polygon(drawable: drawable_type);
var
  counter: integer;
  boxel_edge_ptr, last_boxel_edge_ptr: boxel_edge_ptr_type;
  boxel_table_ptr: boxel_edge_table_ptr_type;
  fore, aft, temp: boxel_edge_ptr_type;
begin
  if (boxel_y_max >= boxel_y_min) then
    for counter := boxel_y_min to boxel_y_max do
      begin
        {***********************************}
        { move entering edges from the edge }
        { table into the active edge table  }
        {***********************************}
        boxel_table_ptr := Index_boxel_edge_table(counter);
        boxel_edge_ptr := boxel_table_ptr^;

        if boxel_edge_ptr <> nil then
          begin
            last_boxel_edge_ptr := boxel_edge_ptr;
            while last_boxel_edge_ptr^.next <> nil do
              last_boxel_edge_ptr := last_boxel_edge_ptr^.next;

            last_boxel_edge_ptr^.next := boxel_active_edge_list;
            boxel_active_edge_list := boxel_edge_ptr;

            boxel_table_ptr^ := nil;
          end;

        {**********************************************************}
        { An edge sort must be done here instead inside above loop }
        { because of degenerate 'bowtie' polygons which introduce  }
        { false vertices which change the ordering of the edges.   }
        {**********************************************************}
        Sort_boxel_edges(boxel_active_edge_list);

        {****************************}
        { render this span of pixels }
        {****************************}
        Boxelize_scanline(drawable, counter, boxel_active_edge_list);

        {********************************************}
        { remove leaving edges from active edge list }
        {********************************************}
        fore := boxel_active_edge_list;
        aft := fore;
        while (fore <> nil) do
          begin
            if (fore^.y_max = counter) then
              begin
                {***********************}
                { remove edge from list }
                {***********************}
                if (fore = aft) then
                  begin
                    boxel_active_edge_list := fore^.next;
                    temp := fore;
                    fore := boxel_active_edge_list;
                    aft := fore;
                  end
                else
                  begin
                    aft^.next := fore^.next;
                    temp := fore;
                    fore := aft^.next;
                  end;
                {***********************}
                { add edge to free list }
                {***********************}
                temp^.next := boxel_edge_free_list;
                boxel_edge_free_list := temp;
              end
            else
              begin
                {*****************}
                { advance pointer }
                {*****************}
                if (fore <> aft) then
                  aft := fore;
                fore := fore^.next;
              end;
          end;

        {************************************}
        { increment values for next scanline }
        {************************************}
        boxel_edge_ptr := boxel_active_edge_list;
        while (boxel_edge_ptr <> nil) do
          begin
            boxel_edge_ptr^.x := boxel_edge_ptr^.x +
              boxel_edge_ptr^.x_increment;
            boxel_edge_ptr^.z := boxel_edge_ptr^.z +
              boxel_edge_ptr^.z_increment;
            boxel_edge_ptr := boxel_edge_ptr^.next;
          end;
      end;
end; {procedure Boxelize_polygon}


procedure Project_to_boxels(z_polygon_ptr: z_polygon_ptr_type);
var
  z_vertex_ptr: z_vertex_ptr_type;
begin
  z_vertex_ptr := z_polygon_ptr^.first;
  while (z_vertex_ptr <> nil) do
    begin
      {*****************************}
      { project point to boxel grid }
      {*****************************}
      z_vertex_ptr^.point.x := (z_vertex_ptr^.point.x / boxel_width - 0.5);
      z_vertex_ptr^.point.y := (z_vertex_ptr^.point.y / boxel_height - 0.5);
      z_vertex_ptr := z_vertex_ptr^.next;
    end;
end; {procedure Project_to_boxels}


procedure Boxelize_thick_line(drawable: drawable_type;
  vector1, vector2: vector_type);
var
  vector: vector2_type;
  offset1, offset2: vector_type;
  vertex1, vertex2, vertex3, vertex4: vector_type;
var
  thickness: real;
  dx, dy, slope: real;
begin
  dx := abs(vector2.x - vector1.x);
  dy := abs(vector2.y - vector1.y);

  if (dx <> 0) or (dy <> 0) then
    begin
      if (dx > dy) then
        slope := dy / dx
      else
        slope := dx / dy;
    end
  else
    begin
      slope := 0;
    end;

  {*************************************************}
  { thickness = thickness line must be to cover the }
  { center of all squares which intersect the line  }
  {*************************************************}
  thickness := sqrt(1 + slope) / 2 * (boxel_width);

  vector.x := vector2.x - vector1.x;
  vector.y := vector2.y - vector1.y;

  if (vector.x <> 0) or (vector.y <> 0) then
    vector := Vector2_scale(Normalize2(vector), thickness);

  offset1.x := vector.x;
  offset1.y := vector.y;
  offset1.z := 0;
  offset2.x := -vector.y;
  offset2.y := vector.x;
  offset2.z := 0;

  {***************************}
  { add perpendicular offsets }
  {***************************}
  vertex1 := Vector_difference(vector1, offset2);
  vertex2 := Vector_sum(vector1, offset2);
  vertex3 := Vector_sum(vector2, offset2);
  vertex4 := Vector_difference(vector2, offset2);

  {**********************}
  { add parallel offsets }
  {**********************}
  vertex1 := Vector_difference(vertex1, offset1);
  vertex2 := Vector_difference(vertex2, offset1);
  vertex3 := Vector_sum(vertex3, offset1);
  vertex4 := Vector_sum(vertex4, offset1);

  Begin_z_polygon;
  Add_z_vertex(vertex1);
  Add_z_vertex(vertex2);
  Add_z_vertex(vertex3);
  Add_z_vertex(vertex4);
  Clip_z_polygon_to_screen_box(z_polygon_list,
    current_projection_ptr^.screen_box);

  if draw_voxels then
    Preview_z_vertex_lists(drawable, z_polygon_list);

  Project_to_boxels(z_polygon_list);
  End_boxel_polygon;
  Boxelize_polygon(drawable);

  {End_z_polygon;}
  {Draw_z_polygon;}
end; {procedure Boxelize_thick_line}


procedure Boxelize_z_polygon_edges(drawable: drawable_type;
  z_polygon_ptr: z_polygon_ptr_type);
var
  z_vertex_ptr: z_vertex_ptr_type;
  point1, point2: vector_type;
begin
  z_vertex_ptr := z_polygon_ptr^.first;
  if z_vertex_ptr <> nil then
    begin
      while (z_vertex_ptr^.next <> nil) do
        begin
          point1 := z_vertex_ptr^.point;
          point2 := z_vertex_ptr^.next^.point;
          Boxelize_thick_line(drawable, point1, point2);
          z_vertex_ptr := z_vertex_ptr^.next;

          {Update_window;}
          {readln;}
        end;
      point1 := z_vertex_ptr^.point;
      point2 := z_polygon_ptr^.first^.point;
      Boxelize_thick_line(drawable, point1, point2);
    end;
end; {procedure Boxelize_z_polygon_edges}


procedure Boxelize_z_polygon(drawable: drawable_type);
var
  z_polygon_ptr: z_polygon_ptr_type;
begin
  {End_z_polygon;}
  {Draw_z_polygon;}

  {*************************}
  { draw outline of polygon }
  {*************************}
  if draw_voxels then
    Preview_z_vertex_lists(drawable, z_polygon_list);

  {************************************}
  { save copy of polygon for its edges }
  {************************************}
  z_polygon_ptr := Copy_z_vertex_list(z_polygon_list);

  {**********************************}
  { project z polygon to boxel space }
  {**********************************}
  Project_to_boxels(z_polygon_list);

  {**********************}
  { pixel sample polygon }
  {**********************}
  End_boxel_polygon;
  Boxelize_polygon(drawable);
  {Update_window;}
  {readln;}

  {************************}
  { boxelize polygon edges }
  {************************}
  Boxelize_z_polygon_edges(drawable, z_polygon_ptr);
  Free_z_vertex_list(z_polygon_ptr);
  {Update_window;}
  {readln;}

  drawable.Update;
end; {procedure Boxelize_z_polygon}


{****************************}
{ routines to boxelize faces }
{****************************}


procedure Boxelize_face(drawable: drawable_type;
  face_ptr: face_ptr_type);
var
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  face_data_ptr: face_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  face_data_ptr := Get_face_data(face_ptr^.index);

  {*********************************}
  { draw only front facing polygons }
  {*********************************}
  if (face_data_ptr^.front_facing) then
    begin
      {**************}
      { draw polygon }
      {**************}
      Begin_z_polygon;
      cycle_ptr := face_ptr^.cycle_ptr;
      while (cycle_ptr <> nil) do
        begin
          directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
          while (directed_edge_ptr <> nil) do
            begin
              with directed_edge_ptr^ do
                if orientation then
                  point_data_ptr := Get_point_data(edge_ptr^.point_ptr1^.index)
                else
                  point_data_ptr := Get_point_data(edge_ptr^.point_ptr2^.index);
              Add_z_vertex(point_data_ptr^.trans_point);
              directed_edge_ptr := directed_edge_ptr^.next;
            end;
          cycle_ptr := cycle_ptr^.next;
        end;

      {**************************}
      { clip and project polygon }
      {**************************}
      Clip_and_project_z_polygon(z_polygon_list, current_viewport_ptr,
        current_projection_ptr);
      Boxelize_z_polygon(drawable);
    end;
end; {procedure Boxelize_face}


procedure Boxelize_visible_face(drawable: drawable_type;
  face_ptr: face_ptr_type);
var
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  face_data_ptr: face_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  face_data_ptr := Get_face_data(face_ptr^.index);

  {*********************************}
  { draw only front facing polygons }
  {*********************************}
  if (face_data_ptr^.front_facing) then
    begin
      {**************}
      { draw polygon }
      {**************}
      Begin_z_polygon;
      cycle_ptr := face_ptr^.cycle_ptr;
      while (cycle_ptr <> nil) do
        begin
          directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
          while (directed_edge_ptr <> nil) do
            begin
              with directed_edge_ptr^ do
                if orientation then
                  point_data_ptr := Get_point_data(edge_ptr^.point_ptr1^.index)
                else
                  point_data_ptr := Get_point_data(edge_ptr^.point_ptr2^.index);
              Add_z_vertex(point_data_ptr^.vector);
              directed_edge_ptr := directed_edge_ptr^.next;
            end;
          cycle_ptr := cycle_ptr^.next;
        end;
      Boxelize_z_polygon(drawable);
    end;
end; {procedure Boxelize_visible_face}


{******************************}
{ routines to boxelize a b rep }
{******************************}


procedure Boxelize_b_rep(drawable: drawable_type;
  surface_ptr: surface_ptr_type);
var
  face_ptr: face_ptr_type;
begin
  face_ptr := surface_ptr^.topology_ptr^.face_ptr;
  if (face_ptr <> nil) then
    begin
      {***************}
      { draw polygons }
      {***************}
      while (face_ptr <> nil) do
        begin
          Boxelize_face(drawable, face_ptr);
          face_ptr := face_ptr^.next;
        end;
    end;
end; {procedure Boxelize_b_rep}


procedure Boxelize_visible_b_rep(drawable: drawable_type;
  surface_ptr: surface_ptr_type);
var
  face_ptr: face_ptr_type;
  point_ptr: point_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  {*************************************}
  { project eye coords to screen coords }
  {*************************************}
  point_ptr := surface_ptr^.topology_ptr^.point_ptr;
  while (point_ptr <> nil) do
    begin
      point_data_ptr := Get_point_data(point_ptr^.index);
      with point_data_ptr^ do
        vector := Project_point_to_point(trans_point);
      point_ptr := point_ptr^.next;
    end;

  face_ptr := surface_ptr^.topology_ptr^.face_ptr;
  if (face_ptr <> nil) then
    begin
      {***************}
      { draw polygons }
      {***************}
      while (face_ptr <> nil) do
        begin
          Boxelize_visible_face(drawable, face_ptr);
          face_ptr := face_ptr^.next;
        end;
    end;
end; {procedure Boxelize_visible_b_rep}


{********************************}
{ routines to boxelize a surface }
{********************************}


procedure Boxelize_surface(drawable: drawable_type;
  surface_ptr: surface_ptr_type;
  visible: boolean);
var
  coord_axes: coord_axes_type;
begin
  {***************************}
  { bind geometry to topology }
  {***************************}
  Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);
  Bind_vertex_geometry(surface_ptr, surface_ptr^.geometry_ptr);
  Bind_face_geometry(surface_ptr, surface_ptr^.geometry_ptr);

  {********************************}
  { init auxilliary rendering data }
  {********************************}
  Init_point_data(surface_ptr);
  Init_face_data(surface_ptr);

  {******************************************}
  { if convex, then remove back-facing polys }
  {******************************************}
  case surface_ptr^.closure of
    open_surface:
      Set_front_facing_flags(surface_ptr);

    closed_surface:
      begin
        Get_coord_stack(coord_stack_ptr, coord_axes);
        Find_face_visibility(surface_ptr, Axes_to_trans(coord_axes));
      end;
  end;

  {**************************************}
  { transform local coords to eye coords }
  {**************************************}
  Get_coord_stack(coord_stack_ptr, coord_axes);
  Transform_point_geometry(Axes_to_trans(coord_axes));

  if visible then
    Boxelize_visible_b_rep(drawable, surface_ptr)
  else
    Boxelize_b_rep(drawable, surface_ptr);
end; {procedure Boxelize_surface}


{***************************************}
{ routines to boxelize a primary object }
{***************************************}


procedure Boxelize_primary(drawable: drawable_type;
  primary_object_ptr: primary_object_ptr_type;
  visible: boolean);
begin
  Set_line_color(drawable, primary_object_ptr^.object_ptr^.attributes.color);
  global_primary_ptr := primary_object_ptr;

  with primary_object_ptr^.object_ptr^.bounds do
    if bounding_kind in [planar_bounds, non_planar_bounds] then
      case bounding_kind of

        planar_bounds:
          Boxelize_surface(drawable, unit_square_ptr, visible);

        non_planar_bounds:
          Boxelize_surface(drawable, unit_cube_ptr, visible);

      end; {case}
end; {procedure Boxelize_primary}


procedure Boxelize_sub_objects(drawable: drawable_type;
  object_ptr: ray_object_inst_ptr_type;
  visibility: visibility_type;
  transform_stack: transform_stack_type;
  attributes: object_attributes_type;
  shader_axes: coord_axes_type;
  normal_shader_axes: coord_axes_type);
var
  bounds: bounding_type;
  bounds_trans: trans_type;
  coord_axes: coord_axes_type;
  new_attributes: object_attributes_type;
  sub_object_ptr: ray_object_inst_ptr_type;
  detail_visible, infinite, clipped: boolean;
  primary_object_ptr: primary_object_ptr_type;
begin
  {********************************}
  { transform object to eye coords }
  {********************************}
  Push_coord_stack(coord_stack_ptr);
  Transform_coord_stack(coord_stack_ptr, object_ptr^.coord_axes);
  Push_coord_stack(normal_stack_ptr);
  Transform_coord_stack(normal_stack_ptr, object_ptr^.normal_coord_axes);
  Get_coord_stack(coord_stack_ptr, coord_axes);

  bounds_trans := Axes_to_trans(coord_axes);

  {********************************}
  { calculate visibility of object }
  {********************************}
  if (object_ptr^.bounds.bounding_kind in [infinite_planar_bounds,
    infinite_non_planar_bounds]) then
    visibility := partially_visible
  else if (visibility <> completely_visible) then
    begin
      Make_bounds(bounds, object_ptr^.bounds.bounding_kind, bounds_trans);
      visibility := Bounds_visibility(bounds, bounds_trans,
        current_viewport_ptr);
    end;

  if (visibility <> completely_invisible) then
    begin
      {*********************************}
      { calculate visibility of details }
      {*********************************}
      detail_visible := true;
      if Visual_size(object_ptr^.bounds.bounding_kind, bounds_trans,
        current_projection_ptr) < max_primary_size then
        detail_visible := false;

      {*************************}
      { assign color and shader }
      {*************************}
      new_attributes := object_ptr^.attributes;
      Apply_object_attributes(new_attributes, attributes);

      if object_ptr^.attributes.shader_ptr <> shader_ptr_type(nil) then
        begin
          shader_axes := object_ptr^.shader_axes;
          normal_shader_axes := object_ptr^.normal_shader_axes;
        end;

      {*********************************************}
      { do not individually boxelize the subobjects }
      { of a clipped complex object.								}
      {*********************************************}
      if (object_ptr^.kind = complex_object) then
        clipped := (object_ptr^.object_decl_ptr^.clipping_plane_ptr <> nil)
      else
        clipped := false;

      {*************}
      { draw object }
      {*************}
      if (not detail_visible) or clipped or (object_ptr^.kind <> complex_object)
        then
        begin
          {******************}
          { primitive object }
          {******************}
          primary_object_ptr := Make_primary_object(object_ptr, transform_stack,
            new_attributes, shader_axes, normal_shader_axes);

          if (object_ptr^.kind <> complex_object) then
            infinite := object_ptr^.bounds.bounding_kind in
              [infinite_planar_bounds, infinite_non_planar_bounds]
          else
            infinite := object_ptr^.object_decl_ptr^.infinite;

          if infinite then
            begin
              {*************************************}
              { add infinte planes to seperate list }
              {*************************************}
              primary_object_ptr^.next := infinite_primary_list;
              infinite_primary_list := primary_object_ptr;
            end
          else
            begin
              {****************************}
              { add primary object to list }
              {****************************}
              primary_object_ptr^.next := primary_object_list;
              primary_object_list := primary_object_ptr;

              {***********************************}
              { add primary object to boxel space }
              {***********************************}
              Boxelize_primary(drawable, primary_object_ptr, (visibility = completely_visible))
            end;
        end
      else
        begin
          {****************}
          { complex object }
          {****************}
          transform_stack.depth := transform_stack.depth + 1;
          transform_stack.stack[transform_stack.depth] := object_ptr;

          sub_object_ptr := object_ptr^.object_decl_ptr^.sub_object_ptr;
          while sub_object_ptr <> nil do
            begin
              Boxelize_sub_objects(drawable, sub_object_ptr, visibility, transform_stack,
                new_attributes, shader_axes, normal_shader_axes);
              sub_object_ptr := sub_object_ptr^.next;
            end;
        end;
      drawable.Update;
    end;

  Pop_coord_stack(coord_stack_ptr);
  Pop_coord_stack(normal_stack_ptr);
end; {procedure Boxelize_sub_objects}


procedure Init_boxel_space(size: pixel_type);
var
  counter1, counter2: integer;
  boxel_table_ptr: boxel_edge_table_ptr_type;
  boxel_entry_ref_ptr: boxel_entry_ref_type;
  v_counter: integer;
begin
  {***********************************}
  { fix size of boxel array to screen }
  {***********************************}
  h_boxels := (size.h div boxel_width) + 1;
  v_boxels := (size.v div boxel_height) + 1;
  boxel_array_ptr := New_boxel_array(h_boxels, v_boxels);
  boxel_edge_table_ptr := New_boxel_edge_table(size.v);

  {************************}
  { initialize boxel array }
  {************************}
  for counter1 := 0 to h_boxels do
    for counter2 := 0 to v_boxels do
      begin
        boxel_entry_ref_ptr := Index_boxel_array(counter1, counter2);
        boxel_entry_ref_ptr^ := nil;
      end;

  {*****************************}
  { initialize boxel edge table }
  {*****************************}
  boxel_table_ptr := boxel_edge_table_ptr;
  for v_counter := 0 to size.v do
    begin
      boxel_table_ptr^ := nil;
      boxel_table_ptr := boxel_edge_table_ptr_type(longint(boxel_table_ptr) +
        sizeof(boxel_edge_table_type));
    end;
end; {procedure Init_boxel_space}


procedure Make_boxel_space(size: pixel_type;
  drawable: drawable_type;
  scene_ptr: ray_object_inst_ptr_type;
  scene_trans: trans_type);
var
  transform_stack: transform_stack_type;
begin
  if draw_voxels then
    begin
      Set_line_color(drawable, black_color);
      drawable.Clear;
      Set_line_color(drawable, white_color);
    end;

  coord_stack_ptr := New_coord_stack;
  normal_stack_ptr := New_coord_stack;
  Set_coord_mode(postmultiply_coords);

  unit_square_ptr := Parallelogram_b_rep;
  unit_cube_ptr := Block_b_rep;

  Init_boxel_space(size);
  infinite_primary_list := nil;
  transform_stack.depth := 0;

  Push_coord_stack(coord_stack_ptr);
  Push_coord_stack(normal_stack_ptr);

  scene_axes := Trans_to_axes(scene_trans);
  Transform_coord_stack(coord_stack_ptr, scene_axes);
  Transform_coord_stack(normal_stack_ptr, scene_axes);
  Boxelize_sub_objects(drawable, scene_ptr, partially_visible, transform_stack,
    null_attributes, unit_axes, unit_axes);
  Pop_coord_stack(coord_stack_ptr);
  Pop_coord_stack(normal_stack_ptr);

  Set_coord_mode(premultiply_coords);
  Free_coord_stack(coord_stack_ptr);
  Free_coord_stack(normal_stack_ptr);

  boxels_made := true;
  if draw_voxels then
    begin
      Set_line_color(drawable, black_color);
      drawable.Clear;
      Set_line_color(drawable, white_color);
    end;

  {******************************************************}
  { dispose of active edge table used in scan conversion }
  {******************************************************}
  if memory_alert then
    writeln('freeing boxel edge table');
  Free_ptr(ptr_type(boxel_edge_table_ptr));
end; {procedure Make_boxel_space}


procedure Free_boxel_space;
var
  primary_object_ptr: primary_object_ptr_type;
  boxel_entry_ref_ptr: boxel_entry_ref_type;
  boxel_entry_ptr, follow: boxel_entry_ptr_type;
  counter1, counter2: integer;
begin
  if boxels_made then
    begin
      {**********************}
      { free primary objects }
      {**********************}
      primary_object_ptr := primary_object_list;
      while (primary_object_ptr <> nil) do
        begin
          primary_object_list := primary_object_ptr;
          primary_object_ptr := primary_object_ptr^.next;
          Free_primary_object(primary_object_list);
        end;

      {**********************}
      { free infinite planes }
      {**********************}
      primary_object_ptr := infinite_primary_list;
      while (primary_object_ptr <> nil) do
        begin
          infinite_primary_list := primary_object_ptr;
          primary_object_ptr := primary_object_ptr^.next;
          Free_primary_object(infinite_primary_list);
        end;

      {********************}
      { free boxel entries }
      {********************}
      for counter1 := 0 to h_boxels do
        for counter2 := 0 to v_boxels do
          begin
            boxel_entry_ref_ptr := Index_boxel_array(counter1, counter2);
            boxel_entry_ptr := boxel_entry_ref_ptr^;

            {***********************}
            { free boxel entry list }
            {***********************}
            follow := boxel_entry_ptr;
            while (follow <> nil) do
              begin
                boxel_entry_ptr := follow;
                follow := follow^.next;
                Free_boxel_entry(boxel_entry_ptr);
              end;
          end;

      {*****************}
      { free boxel grid }
      {*****************}
      if memory_alert then
        writeln('freeing boxel array');
      Free_ptr(ptr_type(boxel_array_ptr));
    end;
end; {procedure Free_boxel_space}


initialization
  boxel_width := 8;
  boxel_height := 8;

  primary_object_free_list := nil;
  boxel_entry_free_list := nil;

  primary_object_block_ptr := nil;
  boxel_entry_block_ptr := nil;

  primary_object_counter := 0;
  boxel_entry_counter := 0;

  primary_object_list := nil;

  {**************************************}
  { initialize stuff for scan conversion }
  {**************************************}
  boxel_active_edge_list := nil;
  boxel_edge_free_list := nil;
  boxel_edge_table_ptr := nil;

  boxel_y_min := maxint;
  boxel_y_max := -1;
  boxels_made := false;
end.
