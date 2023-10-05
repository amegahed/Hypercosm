unit volumes;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              volumes                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{      The volumes module contains data structures for          }
{      defining volume objects.                                 }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, extents;


type
  {************************}
  { volume data structures }
  {************************}
  density_ptr_type = ^density_type;
  density_type = real;
  vector_ptr_type = ^vector_type;


  density_array_ptr_type = ^density_array_type;
  density_array_type = record
    length, width, height: integer;
    multiplier1, multiplier2, multiplier3: longint;
    density_ptr: density_ptr_type;
    next: density_array_ptr_type;
  end; {density_array_type}


  point_array_ptr_type = ^point_array_type;
  point_array_type = record
    length, width, height: integer;
    multiplier1, multiplier2, multiplier3: longint;
    point_ptr: vector_ptr_type;
    next: point_array_ptr_type;
  end; {point_array_type}


  volume_ptr_type = ^volume_type;
  volume_type = record
    density_array_ptr: density_array_ptr_type;
    point_array_ptr: point_array_ptr_type;
    threshold: real;
    capping: boolean;
    smoothing: boolean;
    next: volume_ptr_type;
  end; {volume_type}


  {*****************************************************}
  {                   Blobs / Metaballs                 }
  {*****************************************************}
  {       A blob is a primitive which is composed of:   }
  {       1) a group of metaballs defining a field      }
  {       2) a threshold value, T                       }
  {                                                     }
  {       The surface of the blob is defined as the     }
  {       isosurface where the field strength equals    }
  {       the density value.                            }
  {       Each metaball contributes to the field in a   }
  {       spherically symmetrical manner and is defined }
  {       by its position (x, y, z), its radius r, and  }
  {       its strength, s.                              }
  {                                                     }
  {       The density function for a blob is computed   }
  {       by adding together the density functions of   }
  {       all of the metaballs which comprise the blob. }
  {                                                     }
  {       The density function for a metaball is        }
  {       defined as:                                   }
  {                                                     }
  {       d(R) = (c4 * R^4) + (c2 * R^2) + (c0 * R)     }
  {       for (0 < R < r),                              }
  {       and 0 when R > r                              }
  {                                                     }
  {       where R = distance from a point to the center }
  {       of the metaball                               }
  {                                                     }
  {       The coefficients of the metaball field are    }
  {       computed as follows:                          }
  {       c4 = s / (r^4)                                }
  {       c2 = -(2 * s) / (r^2)                         }
  {       c0 = s                                        }
  {                                                     }
  {*****************************************************}


  metaball_ptr_type = ^metaball_type;
  metaball_type = record
    center: vector_type;
    radius, radius_squared: real;
    c0, c2, c4: real;
    next: metaball_ptr_type;
  end; {metaball_type}


{**************************************}
{ routines for creating density arrays }
{**************************************}
function New_density_array(length, width, height: integer):
  density_array_ptr_type;
procedure Clear_density_array(density_array_ptr: density_array_ptr_type;
  density: real);
function Index_density_array(density_array_ptr: density_array_ptr_type;
  length, width, height: integer): density_ptr_type;
procedure Free_density_array(var density_array_ptr: density_array_ptr_type);

{************************************}
{ routines for creating point arrays }
{************************************}
function New_point_array(length, width, height: integer): point_array_ptr_type;
function Index_point_array(point_array_ptr: point_array_ptr_type;
  length, width, height: integer): vector_ptr_type;
procedure Free_point_array(var point_array_ptr: point_array_ptr_type);

{*******************************}
{ routines for creating volumes }
{*******************************}
function New_volume(threshold: real;
  capping, smoothing: boolean): volume_ptr_type;
procedure Free_volume(var volume_ptr: volume_ptr_type);
function Volume_extents(volume_ptr: volume_ptr_type): extent_box_type;
procedure Transform_volume(volume_ptr: volume_ptr_type;
  extent_box: extent_box_type);

{**************************}
{ blob / metaball routines }
{**************************}
function New_metaball(center: vector_type;
  radius: real;
  strength: real): metaball_ptr_type;
function Metaball_extents(metaball_ptr: metaball_ptr_type): extent_box_type;
function Metaball_density(metaball_ptr: metaball_ptr_type;
  point: vector_type): real;
procedure Free_metaballs(var metaball_ptr: metaball_ptr_type);

{********************************************}
{ routine to compute the density function of }
{ a blob for a particular volume of space    }
{********************************************}
procedure Blob_to_volume(metaball_list: metaball_ptr_type;
  volume_ptr: volume_ptr_type;
  volume_extents: extent_box_type);


implementation
uses
  new_memory, constants, trans;


const
  memory_alert = false;


var
  {************}
  { free lists }
  {************}
  density_array_free_list: density_array_ptr_type;
  point_array_free_list: point_array_ptr_type;

  volume_free_list: volume_ptr_type;
  metaball_free_list: metaball_ptr_type;


{**************************************}
{ routines for creating density arrays }
{**************************************}


function New_density_array(length, width, height: integer):
  density_array_ptr_type;
var
  density_array_size: longint;
  density_array_ptr: density_array_ptr_type;
begin
  {**********************************}
  { get density array from free list }
  {**********************************}
  if (density_array_free_list <> nil) then
    begin
      density_array_ptr := density_array_free_list;
      density_array_free_list := density_array_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocaing new density array');
      new(density_array_ptr);
    end;

  {**************************}
  { initialize density array }
  {**************************}
  density_array_ptr^.length := length;
  density_array_ptr^.width := width;
  density_array_ptr^.height := height;
  density_array_ptr^.next := nil;

  {*********************}
  { compute multipliers }
  {*********************}
  with density_array_ptr^ do
    begin
      multiplier1 := sizeof(density_type);
      multiplier2 := longint(length) * multiplier1;
      multiplier3 := longint(width) * multiplier2;
    end;

  {************************}
  { allocate density array }
  {************************}
  density_array_size := longint(length + 1) * longint(width + 1) * longint(height
    + 1);
  density_array_size := density_array_size * sizeof(density_type);

  if memory_alert then
    writeln('allocating new density array');
  density_array_ptr^.density_ptr :=
    density_ptr_type(New_ptr(density_array_size));

  New_density_array := density_array_ptr;
end; {function New_density_array}


procedure Clear_density_array(density_array_ptr: density_array_ptr_type;
  density: real);
var
  x_counter, y_counter, z_counter: integer;
  x_density_ptr, y_density_ptr, z_density_ptr: density_ptr_type;
begin

  z_density_ptr := density_array_ptr^.density_ptr;

  for z_counter := 1 to density_array_ptr^.height do
    begin

      {******************}
      { start next layer }
      {******************}
      y_density_ptr := z_density_ptr;

      for y_counter := 1 to density_array_ptr^.width do
        begin

          {****************}
          { start next row }
          {****************}
          x_density_ptr := y_density_ptr;

          for x_counter := 1 to density_array_ptr^.length do
            begin
              x_density_ptr^ := density;

              {*******************}
              { go to next column }
              {*******************}
              x_density_ptr := density_ptr_type(longint(x_density_ptr) +
                density_array_ptr^.multiplier1);
            end;

          {****************}
          { go to next row }
          {****************}
          y_density_ptr := density_ptr_type(longint(y_density_ptr) +
            density_array_ptr^.multiplier2);
        end;

      {******************}
      { go to next layer }
      {******************}
      z_density_ptr := density_ptr_type(longint(z_density_ptr) +
        density_array_ptr^.multiplier3);
    end;
end; {procedure Clear_density_array}


function Index_density_array(density_array_ptr: density_array_ptr_type;
  length, width, height: integer): density_ptr_type;
var
  offset: longint;
begin
  offset := longint(length) * density_array_ptr^.multiplier1;
  offset := offset + longint(width) * density_array_ptr^.multiplier2;
  offset := offset + longint(height) * density_array_ptr^.multiplier3;
  Index_density_array := density_ptr_type(longint(density_array_ptr^.density_ptr)
    + offset);
end; {function Index_density_array}


procedure Free_density_array(var density_array_ptr: density_array_ptr_type);
begin
  if (density_array_ptr <> nil) then
    begin
      Free_ptr(ptr_type(density_array_ptr^.density_ptr));

      density_array_ptr^.next := density_array_free_list;
      density_array_free_list := density_array_ptr;
      density_array_ptr := nil;
    end;
end; {procedure Free_density_array}


{************************************}
{ routines for creating point arrays }
{************************************}


function New_point_array(length, width, height: integer): point_array_ptr_type;
var
  point_array_size: longint;
  point_array_ptr: point_array_ptr_type;
begin
  {********************************}
  { get point array from free list }
  {********************************}
  if (point_array_free_list <> nil) then
    begin
      point_array_ptr := point_array_free_list;
      point_array_free_list := point_array_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new point array');
      new(point_array_ptr);
    end;

  {************************}
  { initialize point array }
  {************************}
  point_array_ptr^.length := length;
  point_array_ptr^.width := width;
  point_array_ptr^.height := height;
  point_array_ptr^.next := nil;

  {*********************}
  { compute multipliers }
  {*********************}
  with point_array_ptr^ do
    begin
      multiplier1 := sizeof(vector_type);
      multiplier2 := longint(length) * multiplier1;
      multiplier3 := longint(width) * multiplier2;
    end;

  {**********************}
  { allocate point array }
  {**********************}
  point_array_size := longint(length + 1) * longint(width + 1) * longint(height
    + 1);
  point_array_size := point_array_size * sizeof(vector_type);

  if memory_alert then
    writeln('allocating new point array');
  point_array_ptr^.point_ptr := vector_ptr_type(New_ptr(point_array_size));

  New_point_array := point_array_ptr;
end; {function New_point_array}


function Index_point_array(point_array_ptr: point_array_ptr_type;
  length, width, height: integer): vector_ptr_type;
var
  offset: longint;
begin
  offset := longint(length) * point_array_ptr^.multiplier1;
  offset := offset + longint(width) * point_array_ptr^.multiplier2;
  offset := offset + longint(height) * point_array_ptr^.multiplier3;
  Index_point_array := vector_ptr_type(longint(point_array_ptr^.point_ptr) +
    offset);
end; {function Index_point_array}


function Volume_extents(volume_ptr: volume_ptr_type): extent_box_type;
var
  extent_box: extent_box_type;
  point_array_ptr: point_array_ptr_type;
  length, width, height: integer;
  x_point_ptr, y_point_ptr, z_point_ptr: vector_ptr_type;
  x_counter, y_counter, z_counter: integer;
begin
  point_array_ptr := volume_ptr^.point_array_ptr;
  if (point_array_ptr <> nil) then
    begin
      length := point_array_ptr^.length;
      width := point_array_ptr^.width;
      height := point_array_ptr^.height;
      Init_extent_box(extent_box);

      z_point_ptr := point_array_ptr^.point_ptr;

      for z_counter := 1 to height do
        begin

          {******************}
          { start next layer }
          {******************}
          y_point_ptr := z_point_ptr;

          for y_counter := 1 to width do
            begin

              {****************}
              { start next row }
              {****************}
              x_point_ptr := y_point_ptr;

              for x_counter := 1 to length do
                begin
                  Extend_extent_box_to_point(extent_box, x_point_ptr^);

                  {*******************}
                  { go to next column }
                  {*******************}
                  x_point_ptr := vector_ptr_type(longint(x_point_ptr) +
                    point_array_ptr^.multiplier1);
                end;

              {****************}
              { go to next row }
              {****************}
              y_point_ptr := vector_ptr_type(longint(y_point_ptr) +
                point_array_ptr^.multiplier2);
            end;

          {******************}
          { go to next layer }
          {******************}
          z_point_ptr := vector_ptr_type(longint(z_point_ptr) +
            point_array_ptr^.multiplier3);
        end;
    end
  else
    begin
      extent_box := unit_extent_box;
    end;

  Volume_extents := extent_box;
end; {function Volume_extents}


procedure Transform_volume(volume_ptr: volume_ptr_type;
  extent_box: extent_box_type);
var
  point_array_ptr: point_array_ptr_type;
  length, width, height: integer;
  x_point_ptr, y_point_ptr, z_point_ptr: vector_ptr_type;
  x_counter, y_counter, z_counter: integer;
  point, dimensions: vector_type;
  trans: trans_type;
begin
  point_array_ptr := volume_ptr^.point_array_ptr;
  if (point_array_ptr <> nil) then
    begin
      {******************************************}
      { create transformation that spans extents }
      {******************************************}
      trans := Extent_box_trans(extent_box);
      with trans do
        begin
          if x_axis.x < tiny then
            x_axis.x := tiny;
          if y_axis.y < tiny then
            y_axis.y := tiny;
          if z_axis.z < tiny then
            z_axis.z := tiny;
          dimensions.x := x_axis.x;
          dimensions.y := y_axis.y;
          dimensions.z := z_axis.z;
        end;

      {**********************************}
      { transform vertices to new coords }
      {**********************************}
      length := point_array_ptr^.length;
      width := point_array_ptr^.width;
      height := point_array_ptr^.height;
      Init_extent_box(extent_box);

      z_point_ptr := point_array_ptr^.point_ptr;

      for z_counter := 1 to height do
        begin

          {******************}
          { start next layer }
          {******************}
          y_point_ptr := z_point_ptr;

          for y_counter := 1 to width do
            begin

              {****************}
              { start next row }
              {****************}
              x_point_ptr := y_point_ptr;

              for x_counter := 1 to length do
                begin
                  point := x_point_ptr^;
                  point := Vector_difference(point, trans.origin);
                  point := Vector_divide(point, dimensions);
                  x_point_ptr^ := point;

                  {*******************}
                  { go to next column }
                  {*******************}
                  x_point_ptr := vector_ptr_type(longint(x_point_ptr) +
                    point_array_ptr^.multiplier1);
                end;

              {****************}
              { go to next row }
              {****************}
              y_point_ptr := vector_ptr_type(longint(y_point_ptr) +
                point_array_ptr^.multiplier2);
            end;

          {******************}
          { go to next layer }
          {******************}
          z_point_ptr := vector_ptr_type(longint(z_point_ptr) +
            point_array_ptr^.multiplier3);
        end;
    end;
end; {function Transform_volume}


procedure Free_point_array(var point_array_ptr: point_array_ptr_type);
begin
  if (point_array_ptr <> nil) then
    begin
      Free_ptr(ptr_type(point_array_ptr^.point_ptr));

      point_array_ptr^.next := point_array_free_list;
      point_array_free_list := point_array_ptr;
      point_array_ptr := nil;
    end;
end; {procedure Free_point_array}


{*******************************}
{ routines for creating volumes }
{*******************************}


function New_volume(threshold: real;
  capping, smoothing: boolean): volume_ptr_type;
var
  volume_ptr: volume_ptr_type;
begin
  {***************************}
  { get volume from free list }
  {***************************}
  if (volume_free_list <> nil) then
    begin
      volume_ptr := volume_free_list;
      volume_free_list := volume_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new volume');
      new(volume_ptr);
    end;

  {*******************}
  { initialize volume }
  {*******************}
  volume_ptr^.threshold := threshold;
  volume_ptr^.capping := capping;
  volume_ptr^.smoothing := smoothing;
  volume_ptr^.density_array_ptr := nil;
  volume_ptr^.point_array_ptr := nil;
  volume_ptr^.next := nil;

  New_volume := volume_ptr;
end; {function New_volume}


procedure Free_volume(var volume_ptr: volume_ptr_type);
begin
  if (volume_ptr <> nil) then
    begin
      Free_density_array(volume_ptr^.density_array_ptr);
      Free_point_array(volume_ptr^.point_array_ptr);
      volume_ptr^.next := volume_free_list;
      volume_free_list := volume_ptr;
      volume_ptr := nil;
    end;
end; {procedure Free_volume}


{*****************************************}
{ routines to allocate and free metaballs }
{*****************************************}


function New_metaball(center: vector_type;
  radius: real;
  strength: real): metaball_ptr_type;
var
  metaball_ptr: metaball_ptr_type;
begin
  {*****************************}
  { get metaball from free list }
  {*****************************}
  if (metaball_free_list <> nil) then
    begin
      metaball_ptr := metaball_free_list;
      metaball_free_list := metaball_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new metaball');
      new(metaball_ptr);
    end;

  {*********************}
  { initialize metaball }
  {*********************}
  metaball_ptr^.center := center;
  metaball_ptr^.radius := radius;
  metaball_ptr^.radius_squared := radius * radius;
  metaball_ptr^.c0 := strength;
  metaball_ptr^.c2 := -(2 * strength) / (metaball_ptr^.radius_squared);
  metaball_ptr^.c4 := strength / sqr(metaball_ptr^.radius_squared);
  metaball_ptr^.next := nil;

  New_metaball := metaball_ptr;
end; {function New_metaball}


function Metaball_extents(metaball_ptr: metaball_ptr_type): extent_box_type;
var
  extent_box: extent_box_type;
begin
  extent_box[left] := metaball_ptr^.center.x - metaball_ptr^.radius;
  extent_box[right] := metaball_ptr^.center.x + metaball_ptr^.radius;

  extent_box[front] := metaball_ptr^.center.y - metaball_ptr^.radius;
  extent_box[back] := metaball_ptr^.center.y + metaball_ptr^.radius;

  extent_box[bottom] := metaball_ptr^.center.z - metaball_ptr^.radius;
  extent_box[top] := metaball_ptr^.center.z + metaball_ptr^.radius;

  Metaball_extents := extent_box;
end; {function Metaball_extents}


function Metaball_density(metaball_ptr: metaball_ptr_type;
  point: vector_type): real;
var
  radius_squared: real;
  density, d0, d2, d4: real;
begin
  radius_squared := Dot_product(point, point);

  if (radius_squared < metaball_ptr^.radius_squared) then
    begin
      d0 := metaball_ptr^.c0;
      d2 := metaball_ptr^.c2 * radius_squared;
      d4 := metaball_ptr^.c4 * sqr(radius_squared);
      density := d0 + d2 + d4;
    end
  else
    density := 0;

  Metaball_density := density;
end; {function Metaball_density}


procedure Free_metaballs(var metaball_ptr: metaball_ptr_type);
var
  last_metaball_ptr: metaball_ptr_type;
begin
  last_metaball_ptr := metaball_ptr;
  while (last_metaball_ptr^.next <> nil) do
    last_metaball_ptr := last_metaball_ptr^.next;

  last_metaball_ptr^.next := metaball_free_list;
  metaball_free_list := metaball_ptr;
  metaball_ptr := nil;
end; {procedure Free_metaballs}


{******************************************}
{ routine for computing metaball densities }
{******************************************}


procedure Add_metaball_density(metaball_ptr: metaball_ptr_type;
  volume_ptr: volume_ptr_type;
  volume_extents: extent_box_type);
var
  meta_extents: extent_box_type;
  x_counter, y_counter, z_counter: integer;
  x_density_ptr, y_density_ptr, z_density_ptr: density_ptr_type;
  vector, increment: vector_type;
  radius_squared: real;
  density, d0, d2, d4: real;
  dimensions: vector_type;
  length, width, height: integer;
  density_array_ptr: density_array_ptr_type;
  point: vector_type;
begin
  meta_extents := Metaball_extents(metaball_ptr);

  if not Disjoint_extent_boxes(volume_extents, meta_extents) then
    begin
      {********************}
      { compute increments }
      {********************}
      dimensions.x := (volume_extents[right] - volume_extents[left]);
      dimensions.y := (volume_extents[back] - volume_extents[front]);
      dimensions.z := (volume_extents[top] - volume_extents[bottom]);

      density_array_ptr := volume_ptr^.density_array_ptr;
      length := density_array_ptr^.length;
      width := density_array_ptr^.width;
      height := density_array_ptr^.height;

      increment.x := dimensions.x / (length - 1);
      increment.y := dimensions.y / (width - 1);
      increment.z := dimensions.z / (height - 1);

      {************************************************}
      { add metaball influence at each point in volume }
      {************************************************}
      z_density_ptr := density_array_ptr^.density_ptr;
      vector.z := volume_extents[bottom];

      for z_counter := 1 to height do
        begin

          {******************}
          { start next layer }
          {******************}
          y_density_ptr := z_density_ptr;
          vector.y := volume_extents[front];

          for y_counter := 1 to width do
            begin

              {****************}
              { start next row }
              {****************}
              x_density_ptr := y_density_ptr;
              vector.x := volume_extents[left];

              for x_counter := 1 to length do
                begin
                  point := Vector_difference(vector, metaball_ptr^.center);
                  radius_squared := Dot_product(point, point);

                  if (radius_squared < metaball_ptr^.radius_squared) then
                    begin
                      d0 := metaball_ptr^.c0;
                      d2 := metaball_ptr^.c2 * radius_squared;
                      d4 := metaball_ptr^.c4 * radius_squared * radius_squared;
                      density := d0 + d2 + d4;
                      x_density_ptr^ := x_density_ptr^ + density;
                    end;

                  {*******************}
                  { go to next column }
                  {*******************}
                  x_density_ptr := density_ptr_type(longint(x_density_ptr) +
                    density_array_ptr^.multiplier1);
                  vector.x := vector.x + increment.x;
                end;

              {****************}
              { go to next row }
              {****************}
              y_density_ptr := density_ptr_type(longint(y_density_ptr) +
                density_array_ptr^.multiplier2);
              vector.y := vector.y + increment.y;
            end;

          {******************}
          { go to next layer }
          {******************}
          z_density_ptr := density_ptr_type(longint(z_density_ptr) +
            density_array_ptr^.multiplier3);
          vector.z := vector.z + increment.z;
        end;
    end;
end; {procedure Add_metaball_density}


{********************************************}
{ routine to compute the density function of }
{ a blob for a particular volume of space    }
{********************************************}

procedure Blob_to_volume(metaball_list: metaball_ptr_type;
  volume_ptr: volume_ptr_type;
  volume_extents: extent_box_type);
begin
  Clear_density_array(volume_ptr^.density_array_ptr, 0);
  while (metaball_list <> nil) do
    begin
      Add_metaball_density(metaball_list, volume_ptr, volume_extents);
      metaball_list := metaball_list^.next;
    end;
end; {procedure Blob_to_volume}


initialization
  density_array_free_list := nil;
  point_array_free_list := nil;

  volume_free_list := nil;
  metaball_free_list := nil;
end.
