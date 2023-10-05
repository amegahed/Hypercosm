unit clip_regions;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            clip_regions               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The fisheye region forms a pyramid with the sides       }
{       curved in since the field of view is greater at         }
{       the corners than at the sides, therefore, when          }
{       testing whether an object is entirely within the        }
{       field of view, we must use the inner pyramid, but       }
{       when we clip a line to the field of view, we must       }
{       use the outer pyramid and then perform a 2D clip        }
{       with the window to approximate the curve.               }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, clip_planes;


type
  frustrum_kind_type = (pyramidal, antipyramidal);


  frustrum_type = record
    kind: frustrum_kind_type;

    {*******************************}
    { normals to planes of frustrum }
    {*******************************}
    left_normal, right_normal, bottom_normal, top_normal: vector_type;
  end; {frustrum_type}


  pyramid_type = record
    {******************}
    { pyramid vertices }
    {******************}
    apex, bottom_left, bottom_right, top_left, top_right: vector_type;

    {***************}
    { pyramid edges }
    {***************}
    bottom_left_edge, bottom_right_edge, top_left_edge, top_right_edge:
    vector_type;

    {***************}
    { pyramid faces }
    {***************}
    frustrum: frustrum_type;
  end; {pyramid_type}


  ortho_region_type = record
    eye_plane, left_plane, right_plane, bottom_plane, top_plane: plane_type;
  end; {ortho_region_type}


  quadrant_type = record
    normal1, normal2: vector_type;
  end; {quadrant_type}


  quadrants_type = record
    left_quadrant, right_quadrant, bottom_quadrant, top_quadrant: quadrant_type;
  end; {quadrants_type}


  {*******************************}
  { routines for making frustrums }
  {*******************************}
function To_frustrum(left_normal, right_normal, bottom_normal, top_normal:
  vector_type): frustrum_type;
function Anti_frustrum(frustrum: frustrum_type): frustrum_type;
function Point_in_frustrum(point: vector_type;
  frustrum: frustrum_type): boolean;

{******************************}
{ routines for making pyramids }
{******************************}
function To_pyramid(apex, bottom_left, bottom_right, top_left, top_right:
  vector_type): pyramid_type;
function Anti_pyramid(pyramid: pyramid_type): pyramid_type;

{***********************************}
{ routines for making ortho regions }
{***********************************}
function To_ortho_region(eye_plane, left_plane, right_plane, bottom_plane,
  top_plane: plane_type): ortho_region_type;

{*******************************}
{ routines for making quadrants }
{*******************************}
function To_quadrant(normal1, normal2: vector_type): quadrant_type;
function To_quadrants(left_quadrant, right_quadrant, bottom_quadrant,
  top_quadrant: quadrant_type): quadrants_type;


implementation
uses
  errors;


{*******************************}
{ routines for making frustrums }
{*******************************}


function To_frustrum(left_normal, right_normal, bottom_normal, top_normal:
  vector_type): frustrum_type;
var
  frustrum: frustrum_type;
  h_convex, v_convex: boolean;
begin
  {*********************}
  { initialize frustrum }
  {*********************}
  frustrum.left_normal := left_normal;
  frustrum.right_normal := right_normal;
  frustrum.bottom_normal := bottom_normal;
  frustrum.top_normal := top_normal;

  {*******************}
  { set frustrum kind }
  {*******************}
  h_convex := not Same_direction(left_normal, right_normal);
  v_convex := not Same_direction(bottom_normal, top_normal);

  if h_convex <> v_convex then
    Error('invalid frustrum')
  else if h_convex or v_convex then
    frustrum.kind := pyramidal
  else
    frustrum.kind := antipyramidal;

  To_frustrum := frustrum;
end; {function To_frustrum}


function Anti_frustrum(frustrum: frustrum_type): frustrum_type;
begin
  {**************************}
  { reverse frustrum normals }
  {**************************}
  with frustrum do
    begin
      left_normal := Vector_reverse(left_normal);
      right_normal := Vector_reverse(right_normal);
      bottom_normal := Vector_reverse(bottom_normal);
      top_normal := Vector_reverse(top_normal);
    end;

  Anti_frustrum := frustrum;
end; {function Anti_frustrum}


function Point_in_frustrum(point: vector_type;
  frustrum: frustrum_type): boolean;
var
  in_frustrum: boolean;
begin
  if (Dot_product(point, frustrum.right_normal) < 0) then
    in_frustrum := false
  else if (Dot_product(point, frustrum.left_normal) < 0) then
    in_frustrum := false
  else if (Dot_product(point, frustrum.bottom_normal) < 0) then
    in_frustrum := false
  else if (Dot_product(point, frustrum.top_normal) < 0) then
    in_frustrum := false
  else
    in_frustrum := true;

  Point_in_frustrum := in_frustrum;
end; {function Point_in_frustrum}


{******************************}
{ routines for making pyramids }
{******************************}


function To_pyramid(apex, bottom_left, bottom_right, top_left, top_right:
  vector_type): pyramid_type;
var
  pyramid: pyramid_type;
  right_normal, left_normal, bottom_normal, top_normal: vector_type;
begin
  {*****************************}
  { initialize pyramid vertices }
  {*****************************}
  pyramid.apex := apex;
  pyramid.bottom_left := bottom_left;
  pyramid.bottom_right := bottom_right;
  pyramid.top_left := top_left;
  pyramid.top_right := top_right;

  {**************************}
  { initialize pyramid edges }
  {**************************}
  pyramid.bottom_left_edge := Vector_difference(bottom_left, apex);
  pyramid.bottom_right_edge := Vector_difference(bottom_right, apex);
  pyramid.top_left_edge := Vector_difference(top_left, apex);
  pyramid.top_right_edge := Vector_difference(top_right, apex);

  {**************************}
  { initialize pyramid faces }
  {**************************}
  left_normal := Cross_product(pyramid.bottom_left_edge, pyramid.top_left_edge);
  right_normal := Cross_product(pyramid.top_right_edge,
    pyramid.bottom_right_edge);
  bottom_normal := Cross_product(pyramid.bottom_right_edge,
    pyramid.bottom_left_edge);
  top_normal := Cross_product(pyramid.top_left_edge, pyramid.top_right_edge);
  pyramid.frustrum := To_frustrum(left_normal, right_normal, bottom_normal,
    top_normal);

  To_pyramid := pyramid;
end; {function To_pyramid}


function Anti_pyramid(pyramid: pyramid_type): pyramid_type;
begin
  with pyramid do
    begin
      {*****************************}
      { reverse vertices about apex }
      {*****************************}
      bottom_left := Vector_sum(bottom_left,
        Vector_scale(Vector_difference(apex,
        bottom_left), 2));
      bottom_right := Vector_sum(bottom_right,
        Vector_scale(Vector_difference(apex,
        bottom_right),
        2));
      top_left := Vector_sum(top_left, Vector_scale(Vector_difference(apex,
        top_left),
        2));
      top_right := Vector_sum(top_right, Vector_scale(Vector_difference(apex,
        top_right), 2));

      {***************}
      { reverse edges }
      {***************}
      bottom_left_edge := Vector_reverse(bottom_left_edge);
      bottom_right_edge := Vector_reverse(bottom_right_edge);
      top_left_edge := Vector_reverse(top_left_edge);
      top_right_edge := Vector_reverse(top_right_edge);

      {***************}
      { reverse faces }
      {***************}
      frustrum := Anti_frustrum(frustrum);
    end;

  Anti_pyramid := pyramid;
end; {function Anti_pyramid}


{***********************************}
{ routines for making ortho regions }
{***********************************}


function To_ortho_region(eye_plane, left_plane, right_plane, bottom_plane,
  top_plane: plane_type): ortho_region_type;
var
  ortho_region: ortho_region_type;
begin
  {*************************}
  { initialize ortho planes }
  {*************************}
  ortho_region.eye_plane := eye_plane;
  ortho_region.left_plane := left_plane;
  ortho_region.right_plane := right_plane;
  ortho_region.bottom_plane := bottom_plane;
  ortho_region.top_plane := top_plane;

  To_ortho_region := ortho_region;
end; {function To_ortho_region}


{*******************************}
{ routines for making quadrants }
{*******************************}


function To_quadrant(normal1, normal2: vector_type): quadrant_type;
var
  quadrant: quadrant_type;
begin
  quadrant.normal1 := normal1;
  quadrant.normal2 := normal2;
  To_quadrant := quadrant;
end; {To_quadrant}


function To_quadrants(left_quadrant, right_quadrant, bottom_quadrant,
  top_quadrant: quadrant_type): quadrants_type;
var
  quadrants: quadrants_type;
begin
  quadrants.left_quadrant := left_quadrant;
  quadrants.right_quadrant := right_quadrant;
  quadrants.bottom_quadrant := bottom_quadrant;
  quadrants.top_quadrant := top_quadrant;

  To_quadrants := quadrants;
end; {function To_quadrants}


end.
