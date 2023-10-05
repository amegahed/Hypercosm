unit luxels;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               luxels                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The lighting module is used to build and access         }
{       the spatial lighting data structs used for shading.     }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, lighting;


{*****************************************************}
{ routines for creating the spatial lighting database }
{*****************************************************}
procedure Make_luxel_space;

{*****************************************************}
{ routine to initialize lights for a particular query }
{*****************************************************}
procedure Set_lighting_point(point: vector_type);

{*************************************************}
{ routines to query the spatial lighting database }
{*************************************************}
function Get_light_number: integer;
function Index_light(index: integer): light_ptr_type;


implementation
uses
  new_memory, extents;


const
  light_block_size = 16;
  memory_alert = false;
  max_luxels = 16;
  min_lights = 2;


  {********************************************************}
  { light refs are allocated in blocks to speed allocation }
  {********************************************************}
const
  block_size = 512;


type
  light_block_ptr_type = ^light_block_type;
  light_block_type = record
    ptr_array: array[1..light_block_size] of light_ptr_type;
    next: light_block_ptr_type;
  end; {light_block_type}


  {**********************************}
  { spatial lighting data structures }
  {**********************************}


  light_ref_ptr_type = ^light_ref_type;
  light_ref_type = record
    light_ptr: light_ptr_type;
    next: light_ref_ptr_type;
  end; {light_ref_type}


  {********************************}
  { block allocation of light refs }
  {********************************}
  light_ref_block_ptr_type = ^light_ref_block_type;
  light_ref_block_type = array[0..block_size] of light_ref_type;

  {*********************************************************}
  { luxel space array is an array of pointers to light refs }
  {*********************************************************}
  light_ref_ptr_ref_type = ^light_ref_ptr_type;

  luxel_array_ptr_type = ^luxel_array_type;
  luxel_array_type = record
    length, width, height: integer;
    multiplier1, multiplier2, multiplier3, elements: longint;
    light_ref_ptr: light_ref_ptr_ref_type;
    next: luxel_array_ptr_type;
  end; {luxel_array_type}


var
  luxel_array_free_list: luxel_array_ptr_type;

  light_ref_free_list: light_ref_ptr_type;
  light_ref_block_ptr: light_ref_block_ptr_type;
  light_ref_counter: integer;

  number_of_relevant_lights: integer;
  last_light_index: integer;
  last_light_ptr: light_ptr_type;

  light_block_free_list: light_block_ptr_type;
  first_light_block_ptr: light_block_ptr_type;
  last_light_block_ptr: light_block_ptr_type;

  lighting_extent_box: extent_box_type;
  lighting_dimensions: vector_type;

  x_luxels: integer;
  y_luxels: integer;
  z_luxels: integer;

  luxel_array_ptr: luxel_array_ptr_type;


{********************************************}
{ routines to create and destroy luxel space }
{********************************************}


function New_light_ref: light_ref_ptr_type;
var
  light_ref_ptr: light_ref_ptr_type;
  index: integer;
begin
  {******************************}
  { get light ref from free list }
  {******************************}
  if (light_ref_free_list <> nil) then
    begin
      light_ref_ptr := light_ref_free_list;
      light_ref_free_list := light_ref_free_list^.next;
    end
  else
    begin
      index := light_ref_counter mod block_size;
      if (index = 0) then
        begin
          if memory_alert then
            writeln('allocating new light ref block');
          new(light_ref_block_ptr);
        end;
      light_ref_ptr := @light_ref_block_ptr^[index];
      light_ref_counter := light_ref_counter + 1;
    end;

  {**********************}
  { initialize light ref }
  {**********************}
  light_ref_ptr^.light_ptr := nil;
  light_ref_ptr^.next := nil;

  New_light_ref := light_ref_ptr;
end; {function New_light_ref}


procedure Free_light_refs(var light_ref_ptr: light_ref_ptr_type);
var
  temp: light_ref_ptr_type;
begin
  while light_ref_ptr <> nil do
    begin
      temp := light_ref_ptr;
      light_ref_ptr := light_ref_ptr^.next;
      temp^.next := light_ref_free_list;
      light_ref_free_list := temp;
    end;
end; {procedure Free_light_refs}


procedure Add_light_ref(var light_ref_ptr: light_ref_ptr_type;
  light_ptr: light_ptr_type);
var
  new_light_ref_ptr: light_ref_ptr_type;
begin
  new_light_ref_ptr := New_light_ref;
  new_light_ref_ptr^.light_ptr := light_ptr;
  new_light_ref_ptr^.next := light_ref_ptr;
  light_ref_ptr := new_light_ref_ptr;
end; {procedure Add_light_ref}


procedure Init_light_refs(luxel_array_ptr: luxel_array_ptr_type);
var
  light_ref_ptr: light_ref_ptr_ref_type;
  counter: longint;
begin
  light_ref_ptr := luxel_array_ptr^.light_ref_ptr;
  for counter := 1 to luxel_array_ptr^.elements do
    begin
      light_ref_ptr^ := nil;
      light_ref_ptr := light_ref_ptr_ref_type(longint(light_ref_ptr) +
        sizeof(light_ref_ptr_type));
    end;
end; {procedure Init_light_refs}


procedure Init_luxel_array(luxel_array_ptr: luxel_array_ptr_type;
  length, width, height: integer);
var
  luxel_array_size: longint;
begin
  {************************}
  { initialize luxel array }
  {************************}
  luxel_array_ptr^.length := length;
  luxel_array_ptr^.width := width;
  luxel_array_ptr^.height := height;
  luxel_array_ptr^.next := nil;

  {*********************}
  { compute multipliers }
  {*********************}
  with luxel_array_ptr^ do
    begin
      multiplier1 := sizeof(light_ref_ptr_type);
      multiplier2 := longint(length) * multiplier1;
      multiplier3 := longint(width) * multiplier2;
    end;

  {**********************}
  { allocate luxel array }
  {**********************}
  luxel_array_ptr^.elements := longint(length + 1) * longint(width + 1) *
    longint(height + 1);
  luxel_array_size := luxel_array_ptr^.elements * sizeof(light_ref_ptr_type);

  if memory_alert then
    writeln('allocating new luxel array data');
  luxel_array_ptr^.light_ref_ptr :=
    light_ref_ptr_ref_type(New_ptr(luxel_array_size));

  {********************************}
  { initialize array of light refs }
  {********************************}
  Init_light_refs(luxel_array_ptr);
end; {procedure Init_luxel_array}


function New_luxel_array(length, width, height: integer): luxel_array_ptr_type;
var
  luxel_array_ptr: luxel_array_ptr_type;
begin
  {********************************}
  { get luxel array from free list }
  {********************************}
  if (luxel_array_free_list <> nil) then
    begin
      luxel_array_ptr := luxel_array_free_list;
      luxel_array_free_list := luxel_array_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new luxel array');
      new(luxel_array_ptr);
    end;

  {************************}
  { initialize luxel array }
  {************************}
  Init_luxel_array(luxel_array_ptr, length, width, height);

  New_luxel_array := luxel_array_ptr;
end; {function New_luxel_array}


function Index_luxel_array(luxel_array_ptr: luxel_array_ptr_type;
  length, width, height: integer): light_ref_ptr_ref_type;
var
  offset: longint;
begin
  offset := longint(length) * luxel_array_ptr^.multiplier1;
  offset := offset + longint(width) * luxel_array_ptr^.multiplier2;
  offset := offset + longint(height) * luxel_array_ptr^.multiplier3;
  Index_luxel_array :=
    light_ref_ptr_ref_type(longint(luxel_array_ptr^.light_ref_ptr) + offset);
end; {function Index_luxel_array}


procedure Luxelize_light(luxel_array_ptr: luxel_array_ptr_type;
  light_ptr: light_ptr_type);
var
  t: real;
  index: array[extent_type] of integer;
  x_ptr, y_ptr, z_ptr: light_ref_ptr_ref_type;
  x_counter, y_counter, z_counter: integer;
begin
  t := (light_ptr^.extent_box[left] - lighting_extent_box[left]) /
    lighting_dimensions.x;
  index[left] := Trunc(t * x_luxels);
  t := (light_ptr^.extent_box[right] - lighting_extent_box[left]) /
    lighting_dimensions.x;
  index[right] := round(t * x_luxels);

  t := (light_ptr^.extent_box[front] - lighting_extent_box[front]) /
    lighting_dimensions.y;
  index[front] := Trunc(t * y_luxels);
  t := (light_ptr^.extent_box[back] - lighting_extent_box[front]) /
    lighting_dimensions.y;
  index[back] := round(t * y_luxels);

  t := (light_ptr^.extent_box[bottom] - lighting_extent_box[bottom]) /
    lighting_dimensions.z;
  index[bottom] := Trunc(t * z_luxels);
  t := (light_ptr^.extent_box[top] - lighting_extent_box[bottom]) /
    lighting_dimensions.z;
  index[top] := round(t * z_luxels);

  z_ptr := Index_luxel_array(luxel_array_ptr, index[left], index[front],
    index[bottom]);

  for z_counter := index[bottom] to index[top] do
    begin
      y_ptr := z_ptr;

      for y_counter := index[front] to index[back] do
        begin
          x_ptr := y_ptr;

          for x_counter := index[left] to index[right] do
            begin
              Add_light_ref(x_ptr^, light_ptr);

              {*******************}
              { go to next column }
              {*******************}
              x_ptr := light_ref_ptr_ref_type(longint(x_ptr) +
                luxel_array_ptr^.multiplier1);
            end;

          {****************}
          { go to next row }
          {****************}
          y_ptr := light_ref_ptr_ref_type(longint(y_ptr) +
            luxel_array_ptr^.multiplier2);
        end;

      {******************}
      { go to next layer }
      {******************}
      z_ptr := light_ref_ptr_ref_type(longint(z_ptr) +
        luxel_array_ptr^.multiplier3);
    end;
end; {procedure Luxelize_light}


function Find_light_extent_box(light_ptr: light_ptr_type): extent_box_type;
var
  extent_box: extent_box_type;
begin
  Init_extent_box(extent_box);
  with light_ptr^ do
    begin
      extent_box[left] := location.x - max_distance;
      extent_box[right] := location.x + max_distance;
      extent_box[front] := location.y - max_distance;
      extent_box[back] := location.y + max_distance;
      extent_box[bottom] := location.z - max_distance;
      extent_box[top] := location.z + max_distance;
    end;

  Find_light_extent_box := extent_box;
end; {function Find_light_extent_box}


function Find_lighting_extent_box(light_ptr: light_ptr_type): extent_box_type;
var
  extent_box, light_extent_box: extent_box_type;
begin
  Init_extent_box(extent_box);
  while (light_ptr <> nil) do
    begin
      if (light_ptr^.kind <> distant_kind) then
        with light_ptr^ do
          begin
            light_extent_box := Find_light_extent_box(light_ptr);
            Extend_extent_box_to_extent_box(extent_box, light_extent_box);
          end;
      light_ptr := light_ptr^.next;
    end;

  Find_lighting_extent_box := extent_box;
end; {function Find_lighting_extent_box}


procedure Make_luxel_space;
var
  light_ptr: light_ptr_type;
  light_ref_ptr: light_ref_ptr_ref_type;
  same_luxel_dimensions: boolean;
  counter: longint;
begin
  if (number_of_point_lights + number_of_spot_lights > min_lights) then
    begin
      {********************************************}
      { compute lighting extent box and dimensions }
      {********************************************}
      lighting_extent_box := Find_lighting_extent_box(light_list);
      lighting_dimensions := Extent_box_dimensions(lighting_extent_box);

      {***********************************}
      { compute dimensions of luxel array }
      {***********************************}
      if (lighting_dimensions.x < lighting_dimensions.y) then
        begin
          if (lighting_dimensions.y < lighting_dimensions.z) then
            begin
              {************}
              { z greatest }
              {************}
              z_luxels := max_luxels;
              x_luxels := Trunc((lighting_dimensions.x / lighting_dimensions.z)
                * (max_luxels - 1)) + 1;
              y_luxels := Trunc((lighting_dimensions.y / lighting_dimensions.z)
                * (max_luxels - 1)) + 1;
            end
          else
            begin
              {************}
              { y greatest }
              {************}
              y_luxels := max_luxels;
              x_luxels := Trunc((lighting_dimensions.x / lighting_dimensions.y)
                * (max_luxels - 1)) + 1;
              z_luxels := Trunc((lighting_dimensions.z / lighting_dimensions.y)
                * (max_luxels - 1)) + 1;
            end;
        end
      else
        begin
          if (lighting_dimensions.x < lighting_dimensions.z) then
            begin
              {************}
              { z greatest }
              {************}
              z_luxels := max_luxels;
              x_luxels := Trunc((lighting_dimensions.x / lighting_dimensions.z)
                * (max_luxels - 1)) + 1;
              y_luxels := Trunc((lighting_dimensions.y / lighting_dimensions.z)
                * (max_luxels - 1)) + 1;
            end
          else
            begin
              {************}
              { x greatest }
              {************}
              x_luxels := max_luxels;
              y_luxels := Trunc((lighting_dimensions.y / lighting_dimensions.x)
                * (max_luxels - 1)) + 1;
              z_luxels := Trunc((lighting_dimensions.z / lighting_dimensions.x)
                * (max_luxels - 1)) + 1;
            end;
        end;

      {*******************************************}
      { free light refs from previous luxel array }
      {*******************************************}
      if luxel_array_ptr <> nil then
        begin
          light_ref_ptr := luxel_array_ptr^.light_ref_ptr;
          for counter := 1 to luxel_array_ptr^.elements do
            begin
              Free_light_refs(light_ref_ptr^);
              light_ref_ptr := light_ref_ptr_ref_type(longint(light_ref_ptr) +
                sizeof(light_ref_ptr_type));
            end;
        end;

      {*****************************************}
      { free previous luxel array if wrong size }
      {*****************************************}
      if (luxel_array_ptr <> nil) then
        begin
          same_luxel_dimensions := false;
          if x_luxels = luxel_array_ptr^.length then
            if y_luxels = luxel_array_ptr^.width then
              if z_luxels = luxel_array_ptr^.height then
                same_luxel_dimensions := true;

          if not same_luxel_dimensions then
            Free_ptr(ptr_type(luxel_array_ptr));
        end;

      {********************************}
      { allocate and initialize luxels }
      {********************************}
      if luxel_array_ptr = nil then
        luxel_array_ptr := New_luxel_array(x_luxels, y_luxels, z_luxels);

      {*******************************}
      { enter lights into luxel space }
      {*******************************}
      light_ptr := light_list;
      while (light_ptr <> nil) do
        begin
          if (light_ptr^.kind <> distant_kind) then
            Luxelize_light(luxel_array_ptr, light_ptr);
          light_ptr := light_ptr^.next;
        end;
    end;
end; {procedure Make_luxel_space}


{*****************************************************}
{ routine to initialize lights for a particular query }
{*****************************************************}


function New_light_block: light_block_ptr_type;
var
  light_block_ptr: light_block_ptr_type;
  counter: integer;
begin
  {********************************}
  { get light block from free list }
  {********************************}
  if (light_block_free_list <> nil) then
    begin
      light_block_ptr := light_block_free_list;
      light_block_free_list := light_block_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new light block');
      new(light_block_ptr);
    end;

  {************************}
  { initialize light block }
  {************************}
  with light_block_ptr^ do
    begin
      for counter := 1 to light_block_size do
        ptr_array[counter] := nil;
      next := nil;
    end;
  New_light_block := light_block_ptr;
end; {function New_light_block}


procedure Add_light_ref_to_block(light_ptr: light_ptr_type);
var
  index: integer;
begin
  {**********************************}
  { If necessary, create a new block }
  {**********************************}
  if (number_of_relevant_lights mod light_block_size) = 0 then
    begin
      if (last_light_block_ptr <> nil) then
        begin
          last_light_block_ptr^.next := New_light_block;
          last_light_block_ptr := last_light_block_ptr^.next;
        end
      else
        begin
          first_light_block_ptr := New_light_block;
          last_light_block_ptr := first_light_block_ptr;
        end;
    end;

  {**************************}
  { store light ptr in block }
  {**************************}
  number_of_relevant_lights := number_of_relevant_lights + 1;
  index := (number_of_relevant_lights - 1) mod light_block_size + 1;
  last_light_block_ptr^.ptr_array[index] := light_ptr;
end; {procedure Add_light_ref_to_block}


function Light_in_range(light_ptr: light_ptr_type;
  point: vector_type): boolean;
var
  in_range: boolean;
  vector: vector_type;
  distance_squared: real;
begin
  in_range := false;
  
  case light_ptr^.kind of
    distant_kind:
      begin
        in_range := true;
      end;

    point_kind, spot_kind:
      begin
        vector := Vector_difference(light_ptr^.location, point);
        distance_squared := Dot_product(vector, vector);
        in_range := distance_squared < light_ptr^.max_distance_squared;
      end;
  end;

  Light_in_range := in_range;
end; {function Light_in_range}


procedure Set_lighting_point(point: vector_type);
var
  light_ptr: light_ptr_type;
  temp: light_block_ptr_type;
  x_index, y_index, z_index: integer;
  light_ref_ptr: light_ref_ptr_type;
  t: real;
begin
  {**********************************************}
  { add light previous light blocks to free list }
  {**********************************************}
  number_of_relevant_lights := 0;
  last_light_block_ptr := nil;
  while (first_light_block_ptr <> nil) do
    begin
      temp := first_light_block_ptr;
      first_light_block_ptr := first_light_block_ptr^.next;
      temp^.next := light_block_free_list;
      light_block_free_list := temp;
    end;

  {******************************************************}
  { for each light, check whether it is relavent (within }
  { range of the shading point), and if so, add to list. }
  {******************************************************}
  if (luxel_array_ptr = nil) then
    begin
      {**********************************}
      { no luxels - check lights in list }
      {**********************************}
      light_ptr := light_list;
      while (light_ptr <> nil) do
        begin
          if Light_in_range(light_ptr, point) then
            begin
              Add_light_ref_to_block(light_ptr);
              Reset_light_info(light_ptr);
            end;
          light_ptr := light_ptr^.next;
        end;
    end
  else
    begin
      {****************************************}
      { luxels - check distant lights in list  }
      { and point / spot lights in luxel space }
      {****************************************}
      light_ptr := light_list;
      while (light_ptr <> nil) do
        begin
          if (light_ptr^.kind = distant_kind) then
            begin
              Add_light_ref_to_block(light_ptr);
              Reset_light_info(light_ptr);
            end;
          light_ptr := light_ptr^.next;
        end;

      t := (point.x - lighting_extent_box[left]) / lighting_dimensions.x;
      x_index := Trunc(t * x_luxels);
      t := (point.y - lighting_extent_box[front]) / lighting_dimensions.y;
      y_index := Trunc(t * y_luxels);
      t := (point.z - lighting_extent_box[bottom]) / lighting_dimensions.z;
      z_index := Trunc(t * z_luxels);

      if (x_index >= 0) and (x_index <= x_luxels) then
        if (y_index >= 0) and (y_index <= y_luxels) then
          if (z_index >= 0) and (z_index <= z_luxels) then
            begin
              light_ref_ptr := Index_luxel_array(luxel_array_ptr, x_index,
                y_index, z_index)^;
              while (light_ref_ptr <> nil) do
                begin
                  if Light_in_range(light_ref_ptr^.light_ptr, point) then
                    begin
                      Add_light_ref_to_block(light_ref_ptr^.light_ptr);
                      Reset_light_info(light_ref_ptr^.light_ptr);
                    end;
                  light_ref_ptr := light_ref_ptr^.next;
                end;
            end;
    end;
end; {procedure Set_lighting_point}


{*****************************************}
{ routines to query the lighting database }
{*****************************************}


function Get_light_number: integer;
begin
  Get_light_number := number_of_relevant_lights;
end; {function Get_light_number}


function Index_light(index: integer): light_ptr_type;
var
  light_ptr: light_ptr_type;
  light_block_ptr: light_block_ptr_type;
  block_index: integer;
  blocks: integer;
begin
  {**************************************}
  { check to see if we are accessing the }
  { same light as in the previous call   }
  {**************************************}
  if (index = last_light_index) then
    light_ptr := last_light_ptr

    {********************************}
    { check for light index overflow }
    {********************************}
  else if (index > number_of_relevant_lights) then
    begin
      writeln('Error - id index out of range');
      light_ptr := nil;
    end

      {***********************}
      { lookup light by index }
      {***********************}
  else
    begin
      light_block_ptr := first_light_block_ptr;
      blocks := (index - 1) div light_block_size;
      block_index := (index - 1) mod light_block_size + 1;
      while (blocks >= 1) do
        begin
          light_block_ptr := light_block_ptr^.next;
          blocks := blocks - 1;
        end;
      light_ptr := light_block_ptr^.ptr_array[block_index];
    end;

  Index_light := light_ptr;
end; {procedure Index_light}


initialization
  luxel_array_free_list := nil;

  light_ref_free_list := nil;
  light_ref_block_ptr := nil;
  light_ref_counter := 0;

  number_of_relevant_lights := 0;
  last_light_index := 0;
  last_light_ptr := nil;

  light_block_free_list := nil;
  first_light_block_ptr := nil;
  last_light_block_ptr := nil;

  luxel_array_ptr := nil;
  x_luxels := 0;
  y_luxels := 0;
  z_luxels := 0;
end.
