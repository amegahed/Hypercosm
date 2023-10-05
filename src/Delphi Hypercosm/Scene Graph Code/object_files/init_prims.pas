unit init_prims;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             init_prims                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The init_prims module provides some routines for        }
{       creating the basic primitive shapes.                    }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, objects, polygons, polymeshes, volumes;


{**********}
{ quadrics }
{**********}
function Init_sphere(center: vector_type;
  radius: real;
  umin, umax: real;
  vmin, vmax: real): object_inst_ptr_type;
function Init_cylinder(end1, end2: vector_type;
  radius: real;
  umin, umax: real): object_inst_ptr_type;
function Init_cone(end1, end2: vector_type;
  radius1, radius2: real;
  umin, umax: real): object_inst_ptr_type;
function Init_paraboloid(top, base: vector_type;
  radius: real;
  umin, umax: real): object_inst_ptr_type;
function Init_hyperboloid1(end1, end2: vector_type;
  radius1, radius2: real;
  umin, umax: real): object_inst_ptr_type;
function Init_hyperboloid2(top, base: vector_type;
  radius, eccentricity: real;
  umin, umax: real): object_inst_ptr_type;

{*******************}
{ planar primitives }
{*******************}
function Init_plane(origin: vector_type;
  normal: vector_type): object_inst_ptr_type;
function Init_disk(center: vector_type;
  normal: vector_type;
  radius: real;
  umin, umax: real): object_inst_ptr_type;
function Init_ring(center: vector_type;
  normal: vector_type;
  inner_radius: real;
  outer_radius: real;
  umin, umax: real): object_inst_ptr_type;
function Init_triangle(vertex1: vector_type;
  vertex2: vector_type;
  vertex3: vector_type): object_inst_ptr_type;
function Init_parallelogram(vertex: vector_type;
  side1: vector_type;
  side2: vector_type): object_inst_ptr_type;
function Init_polygon(polygon_ptr: polygon_ptr_type): object_inst_ptr_type;

{***********************}
{ non-planar primitives }
{***********************}
function Init_torus(center: vector_type;
  normal: vector_type;
  inner_radius: real;
  outer_radius: real;
  umin, umax: real;
  vmin, vmax: real): object_inst_ptr_type;
function Init_block(vertex: vector_type;
  side1: vector_type;
  side2: vector_type;
  side3: vector_type): object_inst_ptr_type;
function Init_shaded_triangle(vertex1: vector_type;
  vertex2: vector_type;
  vertex3: vector_type;
  normal1: vector_type;
  normal2: vector_type;
  normal3: vector_type): object_inst_ptr_type;
function Init_shaded_polygon(shaded_polygon_ptr: shaded_polygon_ptr_type):
  object_inst_ptr_type;
function Init_mesh(mesh_ptr: mesh_ptr_type;
  smoothing, mending, closed: boolean): object_inst_ptr_type;
function Init_blob(metaball_ptr: metaball_ptr_type;
  threshold: real): object_inst_ptr_type;

{************************}
{ non-surface primitives }
{************************}
function Init_points(points_ptr: points_ptr_type): object_inst_ptr_type;
function Init_lines(lines_ptr: lines_ptr_type): object_inst_ptr_type;
function Init_volume(volume_ptr: volume_ptr_type): object_inst_ptr_type;

{*********************}
{ clipping primitives }
{*********************}
function Init_clipping_plane(origin: vector_type;
  normal: vector_type): object_inst_ptr_type;

{*********************}
{ lighting primitives }
{*********************}
function Init_distant_light(direction: vector_type;
  brightness: real;
  shadows: boolean): object_inst_ptr_type;
function Init_point_light(brightness: real;
  shadows: boolean): object_inst_ptr_type;
function Init_spot_light(direction: vector_type;
  brightness: real;
  angle: real;
  shadows: boolean): object_inst_ptr_type;


implementation
uses
  constants, binormals, trans, coord_axes, extents;


procedure Fix_longitude_range(var min, max: real);
begin
  {**************************************}
  { make both coords range from 0 to 360 }
  {**************************************}
  min := min - (Trunc(min / 360) * 360);
  max := max - (Trunc(max / 360) * 360);

  if (min < 0) then
    min := min + 360;
  if (max <= 0) then
    max := max + 360;
end; {procedure Fix_longitude_range}


procedure Fix_lattitude_range(var min, max: real);
var
  temp: real;
begin
  {**************************************}
  { make both coords range from 0 to 360 }
  {**************************************}
  min := min - (Trunc(min / 360) * 360);
  max := max - (Trunc(max / 360) * 360);

  {***********************}
  { make both coords < 90 }
  {***********************}
  if min > 90 then
    min := min - 180;
  if max > 90 then
    max := max - 180;

  {************************}
  { make both coords > -90 }
  {************************}
  if min < -90 then
    min := min + 180;
  if max < -90 then
    max := max + 180;

  {***************************}
  { make max greater than min }
  {***************************}
  if (min > max) then
    begin
      temp := max;
      max := min;
      min := temp;
    end;
end; {procedure Fix_lattitude_range}


{**********}
{ quadrics }
{**********}


function Init_sphere(center: vector_type;
  radius: real;
  umin, umax: real;
  vmin, vmax: real): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
begin
  {*********************************}
  { check for degenerate parameters }
  {*********************************}
  if (abs(radius) < tiny) then
    object_ptr := nil
  else
    begin
      {*******************}
      { initialize object }
      {*******************}
      object_ptr := New_geom_object_inst(sphere);
      Fix_longitude_range(umin, umax);
      Fix_lattitude_range(vmin, vmax);
      object_ptr^.umin := umin;
      object_ptr^.umax := umax;
      object_ptr^.vmin := vmin;
      object_ptr^.vmax := vmax;
      with object_ptr^.trans do
        begin
          origin := center;
          x_axis := Vector_scale(x_vector, radius);
          y_axis := Vector_scale(y_vector, radius);
          z_axis := Vector_scale(z_vector, radius);
        end;
    end;

  Init_sphere := object_ptr;
end; {function Init_sphere}


function Init_cylinder(end1, end2: vector_type;
  radius: real;
  umin, umax: real): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
begin
  {*********************************}
  { check for degenerate parameters }
  {*********************************}
  if (abs(radius) < tiny) then
    object_ptr := nil
  else
    begin
      {*******************}
      { initialize object }
      {*******************}
      object_ptr := New_geom_object_inst(cylinder);
      Fix_longitude_range(umin, umax);
      object_ptr^.umin := umin;
      object_ptr^.umax := umax;
      with object_ptr^ do
        with trans do
          begin
            origin := Vector_scale(Vector_sum(end1, end2), 0.5);
            z_axis := Vector_difference(end1, origin);
            trans := Vector_to_trans(origin, z_axis);
            x_axis := Vector_scale(x_axis, radius);
            y_axis := Vector_scale(y_axis, radius);
            if (z_axis.z < 0) then
              y_axis := Vector_reverse(y_axis);
          end;
    end;

  Init_cylinder := object_ptr;
end; {function Init_cylinder}


function Init_cone(end1, end2: vector_type;
  radius1, radius2: real;
  umin, umax: real): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
  top_radius, bottom_radius: real;
  top, bottom: vector_type;
begin
  {*********************************}
  { check for degenerate parameters }
  {*********************************}
  if (abs(radius1) < tiny) and (abs(radius2) < tiny) then
    object_ptr := nil
  else
    begin
      {*******************}
      { initialize object }
      {*******************}
      object_ptr := New_geom_object_inst(cone);
      Fix_longitude_range(umin, umax);
      object_ptr^.umin := umin;
      object_ptr^.umax := umax;
      with object_ptr^ do
        begin
          if (radius1 < radius2) then
            begin
              top := end1;
              bottom := end2;
              top_radius := radius1;
              bottom_radius := radius2;
            end
          else
            begin
              top := end2;
              bottom := end1;
              top_radius := radius2;
              bottom_radius := radius1;
            end;
          inner_radius := abs(top_radius / bottom_radius);
          with trans do
            begin
              origin := Vector_scale(Vector_sum(end1, end2), 0.5);
              z_axis := Vector_difference(top, origin);
              trans := Vector_to_trans(origin, z_axis);
              x_axis := Vector_scale(x_axis, abs(bottom_radius));
              y_axis := Vector_scale(y_axis, bottom_radius);
              if (z_axis.z < 0) then
                y_axis := Vector_reverse(y_axis);
            end;
        end;
    end;

  Init_cone := object_ptr;
end; {function Init_cone}


function Init_paraboloid(top, base: vector_type;
  radius: real;
  umin, umax: real): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
begin
  {*********************************}
  { check for degenerate parameters }
  {*********************************}
  if (abs(radius) < tiny) then
    object_ptr := nil
  else
    begin
      {*******************}
      { initialize object }
      {*******************}
      object_ptr := New_geom_object_inst(paraboloid);
      Fix_longitude_range(umin, umax);
      object_ptr^.umin := umin;
      object_ptr^.umax := umax;
      with object_ptr^ do
        with trans do
          begin
            origin := Vector_scale(Vector_sum(top, base), 0.5);
            z_axis := Vector_difference(top, origin);
            trans := Vector_to_trans(origin, z_axis);
            x_axis := Vector_scale(x_axis, radius);
            y_axis := Vector_scale(y_axis, radius);
            if (z_axis.z < 0) then
              y_axis := Vector_reverse(y_axis);
          end;
    end;

  Init_paraboloid := object_ptr;
end; {function Init_paraboloid}


function Init_hyperboloid1(end1, end2: vector_type;
  radius1, radius2: real;
  umin, umax: real): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
  top_radius, bottom_radius: real;
  top, bottom: vector_type;
begin
  {*********************************}
  { check for degenerate parameters }
  {*********************************}
  if (abs(radius1) < tiny) and (abs(radius2) < tiny) then
    object_ptr := nil
  else
    begin
      {*******************}
      { initialize object }
      {*******************}
      object_ptr := New_geom_object_inst(hyperboloid1);
      Fix_longitude_range(umin, umax);
      object_ptr^.umin := umin;
      object_ptr^.umax := umax;
      with object_ptr^ do
        begin
          if (radius1 < radius2) then
            begin
              top := end1;
              bottom := end2;
              top_radius := radius1;
              bottom_radius := radius2;
            end
          else
            begin
              top := end2;
              bottom := end1;
              top_radius := radius2;
              bottom_radius := radius1;
            end;
          inner_radius := abs(top_radius / bottom_radius);
          with trans do
            begin
              origin := Vector_scale(Vector_sum(end1, end2), 0.5);
              z_axis := Vector_difference(top, origin);
              trans := Vector_to_trans(origin, z_axis);
              x_axis := Vector_scale(x_axis, abs(bottom_radius));
              y_axis := Vector_scale(y_axis, bottom_radius);
              if (z_axis.z < 0) then
                y_axis := Vector_reverse(y_axis);
            end;
        end;
    end;

  Init_hyperboloid1 := object_ptr;
end; {function Init_hyperboloid1}


function Init_hyperboloid2(top, base: vector_type;
  radius, eccentricity: real;
  umin, umax: real): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
begin
  {*********************************}
  { check for degenerate parameters }
  {*********************************}
  if (abs(radius) < tiny) then
    object_ptr := nil
  else
    begin
      {*******************}
      { initialize object }
      {*******************}
      object_ptr := New_geom_object_inst(hyperboloid2);
      object_ptr^.eccentricity := eccentricity;
      Fix_longitude_range(umin, umax);
      object_ptr^.umin := umin;
      object_ptr^.umax := umax;
      with object_ptr^ do
        with trans do
          begin
            origin := Vector_scale(Vector_sum(top, base), 0.5);
            z_axis := Vector_difference(top, origin);
            trans := Vector_to_trans(origin, z_axis);
            x_axis := Vector_scale(x_axis, radius);
            y_axis := Vector_scale(y_axis, radius);
            if (z_axis.z < 0) then
              y_axis := Vector_reverse(y_axis);
          end;
    end;

  Init_hyperboloid2 := object_ptr;
end; {function Init_hyperboloid2}


{*******************}
{ planar primitives }
{*******************}


function Init_plane(origin: vector_type;
  normal: vector_type): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
begin
  object_ptr := New_geom_object_inst(plane);
  object_ptr^.trans := Vector_to_trans(origin, normal);

  Init_plane := object_ptr;
end; {function Init_plane}


function Init_disk(center: vector_type;
  normal: vector_type;
  radius: real;
  umin, umax: real): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
begin
  {*********************************}
  { check for degenerate parameters }
  {*********************************}
  if (abs(radius) < tiny) then
    object_ptr := nil
  else
    begin
      {*******************}
      { initialize object }
      {*******************}
      object_ptr := New_geom_object_inst(disk);
      Fix_longitude_range(umin, umax);
      object_ptr^.umin := umin;
      object_ptr^.umax := umax;
      with object_ptr^ do
        begin
          trans := Vector_to_trans(center, normal);
          with trans do
            begin
              x_axis := Vector_scale(x_axis, radius);
              y_axis := Vector_scale(y_axis, radius);
              if (z_axis.z < 0) then
                y_axis := Vector_reverse(y_axis);
            end;
        end;
    end;

  Init_disk := object_ptr;
end; {function Init_disk}


function Init_ring(center: vector_type;
  normal: vector_type;
  inner_radius: real;
  outer_radius: real;
  umin, umax: real): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
begin
  {*********************************}
  { check for degenerate parameters }
  {*********************************}
  if (inner_radius = outer_radius) then
    object_ptr := nil
  else
    begin
      {*******************}
      { initialize object }
      {*******************}
      object_ptr := New_geom_object_inst(ring);
      object_ptr^.inner_radius := abs(inner_radius / outer_radius);
      Fix_longitude_range(umin, umax);
      object_ptr^.umin := umin;
      object_ptr^.umax := umax;
      with object_ptr^ do
        begin
          trans := Vector_to_trans(center, normal);
          with trans do
            begin
              x_axis := Vector_scale(x_axis, outer_radius);
              y_axis := Vector_scale(y_axis, outer_radius);
              if (z_axis.z < 0) then
                y_axis := Vector_reverse(y_axis);
            end;
        end;
    end;

  Init_ring := object_ptr;
end; {function Init_ring}


function Init_triangle(vertex1: vector_type;
  vertex2: vector_type;
  vertex3: vector_type): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
begin
  object_ptr := New_geom_object_inst(triangle);
  with object_ptr^.trans do
    begin
      origin := Vector_scale(Vector_sum(vertex2, vertex3), 0.5);
      x_axis := Vector_scale(Vector_difference(vertex2, vertex1), 0.5);
      y_axis := Vector_scale(Vector_difference(vertex3, vertex1), 0.5);
      z_axis := Cross_product(x_axis, y_axis);
    end;

  Init_triangle := object_ptr;
end; {function Init_triangle}


function Init_parallelogram(vertex: vector_type;
  side1: vector_type;
  side2: vector_type): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
begin
  object_ptr := New_geom_object_inst(parallelogram);
  with object_ptr^.trans do
    begin
      x_axis := Vector_scale(side1, 0.5);
      y_axis := Vector_scale(side2, 0.5);
      origin := Vector_sum(vertex, Vector_sum(x_axis, y_axis));
      z_axis := Cross_product(x_axis, y_axis);
    end;

  Init_parallelogram := object_ptr;
end; {function Init_parallelogram}


function Init_polygon(polygon_ptr: polygon_ptr_type): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
  polygon_vertex_ptr, follow: polygon_vertex_ptr_type;
  extent_box: extent_box_type;
  dimensions: vector_type;
  point1, point2, point3: vector_type;
  x_axis, y_axis: vector_type;
  trans: trans_type;
  coord_axes: coord_axes_type;
begin
  if polygon_ptr^.vertices <> 0 then
    begin
      object_ptr := New_geom_object_inst(flat_polygon);
      object_ptr^.polygon_ptr := polygon_ptr;

      {*********************************************}
      { compute face normal from first three points }
      {*********************************************}
      polygon_vertex_ptr := polygon_ptr^.vertex_ptr;
      point1 := polygon_vertex_ptr^.point;
      point2 := polygon_vertex_ptr^.next^.point;
      point3 := polygon_vertex_ptr^.next^.next^.point;
      x_axis := Vector_difference(point1, point2);
      y_axis := Vector_difference(point3, point2);
      object_ptr^.trans := Vector_to_trans(point1, Cross_product(x_axis,
        y_axis));

      {**********************************************}
      { transform points to axes aligned with normal }
      {**********************************************}
      coord_axes := Trans_to_axes(object_ptr^.trans);

      polygon_ptr := object_ptr^.polygon_ptr;
      while (polygon_ptr <> nil) do
        begin
          follow := polygon_ptr^.vertex_ptr;
          while (follow <> nil) do
            begin
              Transform_point_to_axes(follow^.point, coord_axes);
              follow := follow^.next;
            end;
          polygon_ptr := polygon_ptr^.next;
        end;

      {**************************************}
      { find max and min extents of vertices }
      {**************************************}
      Init_extent_box(extent_box);
      follow := polygon_vertex_ptr;
      while (follow <> nil) do
        begin
          Extend_extent_box_to_point(extent_box, follow^.point);
          follow := follow^.next;
        end;

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
      with object_ptr^.trans do
        begin
          origin := Vector_sum(origin, Vector_scale(x_axis, trans.origin.x));
          origin := Vector_sum(origin, Vector_scale(y_axis, trans.origin.y));
          origin := Vector_sum(origin, Vector_scale(z_axis, trans.origin.z));
          x_axis := Vector_scale(x_axis, dimensions.x);
          y_axis := Vector_scale(y_axis, dimensions.y);
          z_axis := Vector_scale(z_axis, dimensions.z);
        end;

      {**********************************}
      { transform vertices to new coords }
      {**********************************}
      polygon_ptr := object_ptr^.polygon_ptr;
      while (polygon_ptr <> nil) do
        begin
          follow := polygon_ptr^.vertex_ptr;
          while (follow <> nil) do
            begin
              follow^.point := Vector_difference(follow^.point, trans.origin);
              follow^.point := Vector_divide(follow^.point, dimensions);
              follow := follow^.next;
            end;
          polygon_ptr := polygon_ptr^.next;
        end;
    end
  else
    object_ptr := nil;

  Init_polygon := object_ptr;
end; {function Init_polygon}


{***********************}
{ non-planar primitives }
{***********************}


function Init_torus(center: vector_type;
  normal: vector_type;
  inner_radius: real;
  outer_radius: real;
  umin, umax: real;
  vmin, vmax: real): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
begin
  {*********************************}
  { check for degenerate parameters }
  {*********************************}
  if (abs(inner_radius - outer_radius) < tiny) then
    object_ptr := nil
  else
    begin
      {*******************}
      { initialize object }
      {*******************}
      object_ptr := New_geom_object_inst(torus);
      object_ptr^.inner_radius := (1 - abs(inner_radius / outer_radius)) / 2;
      Fix_longitude_range(umin, umax);
      Fix_longitude_range(vmin, vmax);
      object_ptr^.umin := umin;
      object_ptr^.umax := umax;
      object_ptr^.vmin := vmin;
      object_ptr^.vmax := vmax;
      with object_ptr^ do
        begin
          trans := Vector_to_trans(center, normal);
          with trans do
            begin
              x_axis := Vector_scale(x_axis, outer_radius);
              y_axis := Vector_scale(y_axis, outer_radius);
              z_axis := Vector_scale(Normalize(z_axis), object_ptr^.inner_radius
                *
                outer_radius);
              if (z_axis.z < 0) then
                y_axis := Vector_reverse(y_axis);
            end;
        end;
    end;

  Init_torus := object_ptr;
end; {function Init_torus}


function Init_block(vertex: vector_type;
  side1: vector_type;
  side2: vector_type;
  side3: vector_type): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
begin
  object_ptr := New_geom_object_inst(block);
  with object_ptr^.trans do
    begin
      x_axis := Vector_scale(side1, 0.5);
      y_axis := Vector_scale(side2, 0.5);
      z_axis := Vector_scale(side3, 0.5);
      origin := Vector_sum(vertex, Vector_sum(Vector_sum(x_axis, y_axis),
        z_axis));
    end;

  Init_block := object_ptr;
end; {function Init_block}


function Init_shaded_triangle(vertex1: vector_type;
  vertex2: vector_type;
  vertex3: vector_type;
  normal1: vector_type;
  normal2: vector_type;
  normal3: vector_type): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
  coord_axes: coord_axes_type;
  binormal1, binormal2, binormal3: binormal_type;
begin
  object_ptr := New_geom_object_inst(shaded_triangle);
  with object_ptr^.trans do
    begin
      origin := Vector_scale(Vector_sum(vertex2, vertex3), 0.5);
      x_axis := Vector_scale(Vector_difference(vertex2, vertex1), 0.5);
      y_axis := Vector_scale(Vector_difference(vertex3, vertex1), 0.5);
      z_axis := Cross_product(x_axis, y_axis);
    end;

  {*******************************}
  { create binormals from normals }
  {*******************************}
  binormal1 := Normal_to_binormal(normal1);
  binormal2 := Normal_to_binormal(normal2);
  binormal3 := Normal_to_binormal(normal3);

  {*********************}
  { transform binormals }
  {*********************}
  coord_axes := Trans_to_axes(object_ptr^.trans);
  Transform_binormal_to_axes(binormal1, coord_axes);
  Transform_binormal_to_axes(binormal2, coord_axes);
  Transform_binormal_to_axes(binormal3, coord_axes);

  {*******************************}
  { create normals from binormals }
  {*******************************}
  normal1 := Binormal_to_normal(binormal1);
  normal2 := Binormal_to_normal(binormal2);
  normal3 := Binormal_to_normal(binormal3);

  {*************************}
  { create triangle normals }
  {*************************}
  object_ptr^.triangle_normal_ptr := New_triangle_normals(normal1, normal2,
    normal3);

  Init_shaded_triangle := object_ptr;
end; {function Init_shaded_triangle}


function Init_shaded_polygon(shaded_polygon_ptr: shaded_polygon_ptr_type):
  object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
  shaded_polygon_vertex_ptr, follow: shaded_polygon_vertex_ptr_type;
  extent_box: extent_box_type;
  dimensions: vector_type;
  point1, point2, point3: vector_type;
  x_axis, y_axis: vector_type;
  trans: trans_type;
  coord_axes: coord_axes_type;
begin
  if shaded_polygon_ptr^.vertices <> 0 then
    begin
      object_ptr := New_geom_object_inst(shaded_polygon);
      object_ptr^.shaded_polygon_ptr := shaded_polygon_ptr;

      {*********************************************}
      { compute face normal from first three points }
      {*********************************************}
      shaded_polygon_vertex_ptr := shaded_polygon_ptr^.vertex_ptr;
      point1 := shaded_polygon_vertex_ptr^.point;
      point2 := shaded_polygon_vertex_ptr^.next^.point;
      point3 := shaded_polygon_vertex_ptr^.next^.next^.point;
      x_axis := Vector_difference(point1, point2);
      y_axis := Vector_difference(point3, point2);
      object_ptr^.trans := Vector_to_trans(point1, Cross_product(x_axis,
        y_axis));

      {**********************************************}
      { transform points to axes aligned with normal }
      {**********************************************}
      coord_axes := Trans_to_axes(object_ptr^.trans);
      follow := shaded_polygon_vertex_ptr;
      while (follow <> nil) do
        begin
          Transform_point_to_axes(follow^.point, coord_axes);
          follow := follow^.next;
        end;

      {**************************************}
      { find max and min extents of vertices }
      {**************************************}
      Init_extent_box(extent_box);
      follow := shaded_polygon_vertex_ptr;
      while (follow <> nil) do
        begin
          Extend_extent_box_to_point(extent_box, follow^.point);
          follow := follow^.next;
        end;

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
      with object_ptr^.trans do
        begin
          origin := Vector_sum(origin, Vector_scale(x_axis, trans.origin.x));
          origin := Vector_sum(origin, Vector_scale(y_axis, trans.origin.y));
          origin := Vector_sum(origin, Vector_scale(z_axis, trans.origin.z));
          x_axis := Vector_scale(x_axis, dimensions.x);
          y_axis := Vector_scale(y_axis, dimensions.y);
          z_axis := Vector_scale(z_axis, dimensions.z);
        end;

      {**********************************}
      { transform vertices to Init coords }
      {**********************************}
      follow := shaded_polygon_vertex_ptr;
      while (follow <> nil) do
        begin
          follow^.point := Vector_difference(follow^.point, trans.origin);
          follow^.point := Vector_divide(follow^.point, dimensions);
          follow^.normal := Vector_scale2(follow^.normal, dimensions);
          follow := follow^.next;
        end;
    end
  else
    object_ptr := nil;

  Init_shaded_polygon := object_ptr;
end; {function Init_shaded_polygon}


function Init_mesh(mesh_ptr: mesh_ptr_type;
  smoothing, mending, closed: boolean): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
  follow: mesh_vertex_ptr_type;
  extent_box: extent_box_type;
  dimensions: vector_type;
begin
  if mesh_ptr^.vertices <> 0 then
    begin
      object_ptr := New_geom_object_inst(mesh);
      object_ptr^.mesh_ptr := mesh_ptr;
      object_ptr^.smoothing := smoothing;
      object_ptr^.mending := mending;
      object_ptr^.closed := closed;

      {**************************************}
      { find max and min extents of vertices }
      {**************************************}
      Init_extent_box(extent_box);
      follow := mesh_ptr^.vertex_ptr;
      while (follow <> nil) do
        begin
          Extend_extent_box_to_point(extent_box, follow^.point);
          follow := follow^.next;
        end;
      object_ptr^.trans := Extent_box_trans(extent_box);

      with object_ptr^.trans do
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

      {**********************************************}
      { transform vertices and normals to new coords }
      {**********************************************}
      follow := mesh_ptr^.vertex_ptr;
      while (follow <> nil) do
        begin
          follow^.point := Vector_difference(follow^.point,
            object_ptr^.trans.origin);
          follow^.point := Vector_divide(follow^.point, dimensions);
          follow^.normal := Vector_scale2(follow^.normal, dimensions);
          follow := follow^.next;
        end;
    end
  else
    object_ptr := nil;

  Init_mesh := object_ptr;
end; {function Init_mesh}


function Init_blob(metaball_ptr: metaball_ptr_type;
  threshold: real): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
  extent_box, extents: extent_box_type;
  follow: metaball_ptr_type;
begin
  if metaball_ptr <> nil then
    begin
      object_ptr := New_geom_object_inst(blob);
      object_ptr^.metaball_ptr := metaball_ptr;
      object_ptr^.threshold := threshold;

      {***************************}
      { find extents of metaballs }
      {***************************}
      with metaball_ptr^ do
        begin
          extent_box[left] := center.x - radius;
          extent_box[right] := center.x + radius;
          extent_box[front] := center.y - radius;
          extent_box[back] := center.y + radius;
          extent_box[bottom] := center.z - radius;
          extent_box[top] := center.z + radius;
        end;

      follow := metaball_ptr^.next;
      while (follow <> nil) do
        begin
          with follow^ do
            begin
              extents[left] := center.x - radius;
              extents[right] := center.x + radius;
              extents[front] := center.y - radius;
              extents[back] := center.y + radius;
              extents[bottom] := center.z - radius;
              extents[top] := center.z + radius;
            end;

          Extend_extent_box_to_extent_box(extent_box, extents);
          follow := follow^.next;
        end;

      {***********************************}
      { transform metaballs to new coords }
      {***********************************}
      object_ptr^.trans := Extent_box_trans(extent_box);
      with object_ptr^ do
        begin
          dimensions.x := trans.x_axis.x;
          dimensions.y := trans.y_axis.y;
          dimensions.z := trans.z_axis.z;
        end;

      follow := metaball_ptr;
      while follow <> nil do
        begin
          follow^.center := Vector_difference(follow^.center,
            object_ptr^.trans.origin);
          follow := follow^.next;
        end;
    end
  else
    object_ptr := nil;

  Init_blob := object_ptr;
end; {function Init_blob}


{************************}
{ non-surface primitives }
{************************}


function Init_points(points_ptr: points_ptr_type): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
  point_vertex_ptr, follow: point_vertex_ptr_type;
  extent_box: extent_box_type;
  dimensions: vector_type;
begin
  if points_ptr <> nil then
    begin
      object_ptr := New_geom_object_inst(points);
      object_ptr^.points_ptr := points_ptr;
      point_vertex_ptr := points_ptr^.vertex_ptr;

      {**************************************}
      { find max and min extents of vertices }
      {**************************************}
      Init_extent_box(extent_box);
      follow := point_vertex_ptr;
      while (follow <> nil) do
        begin
          Extend_extent_box_to_point(extent_box, follow^.point);
          follow := follow^.next;
        end;

      {******************************************}
      { create transformation that spans extents }
      {******************************************}
      object_ptr^.trans := Extent_box_trans(extent_box);
      with object_ptr^.trans do
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
      follow := point_vertex_ptr;
      while (follow <> nil) do
        begin
          follow^.point := Vector_difference(follow^.point,
            object_ptr^.trans.origin);
          follow^.point := Vector_divide(follow^.point, dimensions);
          follow := follow^.next;
        end;
    end
  else
    object_ptr := nil;

  Init_points := object_ptr;
end; {function Init_points}


function Init_lines(lines_ptr: lines_ptr_type): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
  line_vertex_ptr, follow: line_vertex_ptr_type;
  extent_box: extent_box_type;
  dimensions: vector_type;
begin
  if lines_ptr <> nil then
    begin
      object_ptr := New_geom_object_inst(lines);
      object_ptr^.lines_ptr := lines_ptr;
      line_vertex_ptr := lines_ptr^.vertex_ptr;

      {**************************************}
      { find max and min extents of vertices }
      {**************************************}
      Init_extent_box(extent_box);
      follow := line_vertex_ptr;
      while (follow <> nil) do
        begin
          Extend_extent_box_to_point(extent_box, follow^.point);
          follow := follow^.next;
        end;

      {******************************************}
      { create transformation that spans extents }
      {******************************************}
      object_ptr^.trans := Extent_box_trans(extent_box);
      with object_ptr^.trans do
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
      follow := line_vertex_ptr;
      while (follow <> nil) do
        begin
          follow^.point := Vector_difference(follow^.point,
            object_ptr^.trans.origin);
          follow^.point := Vector_divide(follow^.point, dimensions);
          follow := follow^.next;
        end;
    end
  else
    object_ptr := nil;

  Init_lines := object_ptr;
end; {function Init_lines}


function Init_volume(volume_ptr: volume_ptr_type): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
  extent_box: extent_box_type;
begin
  if volume_ptr <> nil then
    begin
      object_ptr := New_geom_object_inst(volume);
      object_ptr^.volume_ptr := volume_ptr;
      extent_box := Volume_extents(volume_ptr);
      object_ptr^.trans := Extent_box_trans(extent_box);
      Transform_volume(volume_ptr, extent_box);
    end
  else
    object_ptr := nil;

  Init_volume := object_ptr;
end; {function Init_volume}


{*********************}
{ clipping primitives }
{*********************}


function Init_clipping_plane(origin: vector_type;
  normal: vector_type): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
begin
  object_ptr := New_geom_object_inst(clipping_plane);
  object_ptr^.trans := Vector_to_trans(origin, normal);

  Init_clipping_plane := object_ptr;
end; {function Init_clipping_plane}


{*********************}
{ lighting primitives }
{*********************}


function Init_distant_light(direction: vector_type;
  brightness: real;
  shadows: boolean): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
begin
  object_ptr := New_geom_object_inst(distant_light);
  object_ptr^.shadows := shadows;
  with object_ptr^ do
    begin
      trans := Vector_to_trans(zero_vector, Normalize(direction));
      with trans do
        begin
          x_axis := Vector_scale(x_axis, brightness);
          y_axis := Vector_scale(y_axis, brightness);
          z_axis := Vector_scale(z_axis, brightness);
        end;
    end;

  Init_distant_light := object_ptr;
end; {function Init_distant_light}


function Init_point_light(brightness: real;
  shadows: boolean): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
begin
  object_ptr := New_geom_object_inst(point_light);
  object_ptr^.shadows := shadows;
  with object_ptr^.trans do
    begin
      origin := zero_vector;
      x_axis := Vector_scale(x_vector, brightness);
      y_axis := Vector_scale(y_vector, brightness);
      z_axis := Vector_scale(z_vector, brightness);
    end;

  Init_point_light := object_ptr;
end; {function Init_point_light}


function Init_spot_light(direction: vector_type;
  brightness: real;
  angle: real;
  shadows: boolean): object_inst_ptr_type;
var
  object_ptr: object_inst_ptr_type;
begin
  object_ptr := New_geom_object_inst(spot_light);
  object_ptr^.shadows := shadows;
  with object_ptr^ do
    begin
      spot_angle := angle;
      trans := Vector_to_trans(zero_vector, Normalize(direction));
      with trans do
        begin
          x_axis := Vector_scale(x_axis, brightness);
          y_axis := Vector_scale(y_axis, brightness);
          z_axis := Vector_scale(z_axis, brightness);
        end;
    end;

  Init_spot_light := object_ptr;
end; {function Init_spot_light}


end.
