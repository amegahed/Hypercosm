unit viewports;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             viewports                 3d       }
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
  vectors, project, clip_regions;


type
  viewport_ptr_type = ^viewport_type;
  viewport_type = record
    next: viewport_ptr_type;

    case kind: projection_kind_type of

      {**************************************}
      { for the orthographic projection, the }
      { viewing region is a rectangular tube }
      {**************************************}
      orthographic: (
        ortho_region: ortho_region_type;
        );

      {*****************************************}
      { for the perspective projection, the     }
      { viewing region is a rectangular pyramid }
      {*****************************************}
      perspective: (
        clip_pyramid: pyramid_type;
        );

      {********************************************}
      { for the fisheye projection, the viewing    }
      { region is curved and is approximated by    }
      { two pyramids, one inscribing and the other }
      { circumscribing the actual viewing region.  }
      {********************************************}
      fisheye, panoramic: (
        inner_pyramid: pyramid_type;
        outer_pyramid: pyramid_type;

        {***********************************************************}
        { if field of view > 180 then inner clipping region may be  }
        { a pyramid or an antipyramid depending on the window shape }
        {***********************************************************}
        convex: boolean; {if field of view < 180}
        concave: boolean; {if field of view > 180}

        {*************************************************}
        { quadrants in back of viewer used for clipping   }
        { polygons when field of view is greater than 180 }
        {*************************************************}
        quadrants: quadrants_type;
        );
  end; {viewport_type}


var
  current_viewport_ptr: viewport_ptr_type;


{*****************************************************************}
{ routines for setting the clipping region for a given projection }
{*****************************************************************}
function New_viewport(projection_ptr: projection_ptr_type): viewport_ptr_type;
procedure Free_viewport(var viewport_ptr: viewport_ptr_type);


implementation
uses
  math, errors, new_memory, constants, trigonometry, clip_planes, eye;


const
  memory_alert = false;


var
  viewport_free_list: viewport_ptr_type;


{*****************************************************************}
{ routines for setting the clipping region for a given projection }
{*****************************************************************}


function To_view_frustrum(h_slope, v_slope: real): frustrum_type;
var
  right_normal, left_normal, bottom_normal, top_normal: vector_type;
begin
  {****************************************}
  { initialize normals of sides of pyramid }
  {****************************************}
  with right_normal do
    begin
      x := -1;
      y := h_slope;
      z := 0;
    end;
  with left_normal do
    begin
      x := 1;
      y := h_slope;
      z := 0;
    end;
  with bottom_normal do
    begin
      x := 0;
      y := v_slope;
      z := 1;
    end;
  with top_normal do
    begin
      x := 0;
      y := v_slope;
      z := -1;
    end;

  To_view_frustrum := To_frustrum(right_normal, left_normal, bottom_normal,
    top_normal);
end; {function To_view_frustrum}


function To_view_pyramid(h_slope, v_slope: real): pyramid_type;
var
  apex, bottom_left, bottom_right, top_left, top_right: vector_type;
begin
  apex := zero_vector;

  {********************************}
  { initialize vertices of pyramid }
  {********************************}
  with bottom_left do
    begin
      x := -h_slope;
      y := 1;
      z := -v_slope;
    end;
  with bottom_right do
    begin
      x := h_slope;
      y := 1;
      z := -v_slope;
    end;
  with top_left do
    begin
      x := -h_slope;
      y := 1;
      z := v_slope;
    end;
  with top_right do
    begin
      x := h_slope;
      y := 1;
      z := v_slope;
    end;

  To_view_pyramid := To_pyramid(apex, bottom_left, bottom_right, top_left,
    top_right);
end; {function To_view_pyramid}


function Reverse_view_pyramid(pyramid: pyramid_type): pyramid_type;
begin
  with pyramid do
    begin
      {********************************}
      { reverse y direction of normals }
      {********************************}
      with frustrum do
        begin
          right_normal.y := -right_normal.y;
          left_normal.y := -left_normal.y;
          bottom_normal.y := -bottom_normal.y;
          top_normal.y := -top_normal.y;
        end;

      {********************************}
      { reverse y direction of corners }
      {********************************}
      bottom_left.y := -bottom_left.y;
      bottom_right.y := -bottom_right.y;
      top_left.y := -top_left.y;
      top_right.y := -top_right.y;
    end;

  Reverse_view_pyramid := pyramid;
end; {function Reverse_view_pyramid}


procedure Init_ortho_viewport(viewport_ptr: viewport_ptr_type;
  projection_ptr: projection_ptr_type);
var
  h, v, x, y: real;
  diagonal: real;
  eye_plane, left_plane, right_plane, bottom_plane, top_plane: plane_type;
begin
  if projection_ptr^.kind <> orthographic then
    Error('invalid projection kind')
  else
    begin
      {**********************************}
      { initialize viewport's projection }
      {**********************************}
      viewport_ptr^.kind := orthographic;

      {***************************************}
      { initialize viewport's clipping region }
      {***************************************}
      with projection_ptr^ do
        begin
          if pixel_aspect_ratio = 0 then
            Error('Invalid aspect ratio.');

          h := projection_size.h / pixel_aspect_ratio;
          v := projection_size.v;
          diagonal := sqrt(sqr(h) + sqr(v));
          x := (h / 2) * field_of_view / diagonal;
          y := (v / 2) * field_of_view / diagonal;
        end; {with}

      {*************************}
      { initialize ortho planes }
      {*************************}
      eye_plane := To_plane(zero_vector, y_vector);
      left_plane := To_plane(To_vector(-x, 0, 0), x_vector);
      right_plane := To_plane(To_vector(x, 0, 0), neg_x_vector);
      bottom_plane := To_plane(To_vector(0, 0, -y), z_vector);
      top_plane := To_plane(To_vector(0, 0, y), neg_z_vector);

      {*************************}
      { initialize ortho region }
      {*************************}
      viewport_ptr^.ortho_region := To_ortho_region(eye_plane, left_plane,
        right_plane, bottom_plane, top_plane);
    end; {else}
end; {procedure Init_ortho_viewport}


procedure Init_perspective_viewport(viewport_ptr: viewport_ptr_type;
  projection_ptr: projection_ptr_type);
var
  h_slope, v_slope: real;
begin
  if projection_ptr^.kind <> perspective then
    Error('invalid projection kind')
  else
    begin
      {**********************************}
      { initialize viewport's projection }
      {**********************************}
      viewport_ptr^.kind := perspective;

      {***************************************}
      { initialize viewport's clipping region }
      {***************************************}
      with projection_ptr^ do
        begin
          if pixel_aspect_ratio = 0 then
            Error('Invalid aspect ratio.');
          if projection_plane_distance = 0 then
            Error('Invalid projection constant.');

          h_slope := (projection_size.h + 0.5) / 2 / pixel_aspect_ratio /
            projection_plane_distance;
          v_slope := (projection_size.v + 0.5) / 2 / projection_plane_distance;
          viewport_ptr^.clip_pyramid := To_view_pyramid(h_slope, v_slope);
        end; {with}
    end; {else}
end; {procedure Init_perspective_viewport}


procedure Init_fisheye_viewport(viewport_ptr: viewport_ptr_type;
  projection_ptr: projection_ptr_type);
var
  h, v: real;
  diagonal: real;
  h_slope, v_slope: real;
  h_angle, v_angle: real;
  inner_projection_plane_distance: real;
begin
  if projection_ptr^.kind <> fisheye then
    Error('invalid projection kind')
  else
    begin
      {**********************************}
      { initialize viewport's projection }
      {**********************************}
      viewport_ptr^.kind := fisheye;

      {***************************************}
      { initialize viewport's clipping region }
      {***************************************}
      with projection_ptr^ do
        begin
          if pixel_aspect_ratio = 0 then
            Error('Invalid aspect ratio.');
          if projection_plane_distance = 0 then
            Error('Invalid projection constant.');

          h := projection_size.h / pixel_aspect_ratio;
          v := projection_size.v;
          diagonal := sqrt(sqr(h) + sqr(v));

          with viewport_ptr^ do
            begin
              convex := field_of_view < 180;
              concave := field_of_view > 180;

              {********************}
              { make outer pyramid }
              {********************}
              h_slope := projection_size.h / 2 / pixel_aspect_ratio /
                projection_plane_distance;
              v_slope := projection_size.v / 2 / projection_plane_distance;
              outer_pyramid := To_view_pyramid(h_slope, v_slope);

              {********************}
              { make inner pyramid }
              {********************}
              h_angle := projection_size.h / 2 * field_of_view / diagonal;
              v_angle := projection_size.v / 2 * field_of_view / diagonal;

              {***********************************************************}
              { if field of view > 180 then inner clipping region may be  }
              { a pyramid or an antipyramid depending on the window shape }
              {***********************************************************}
              if concave then
                begin
                  if (h_angle <= 90) or (v_angle <= 90) then
                    begin
                      if (h_angle >= 90) then
                        h_angle := 89;
                      if (v_angle >= 90) then
                        v_angle := 89;
                    end;
                end;

              h_angle := h_angle * degrees_to_radians;
              v_angle := v_angle * degrees_to_radians;
              inner_projection_plane_distance := projection_size.h / 2 /
                abs(tan(h_angle));
              h_slope := projection_size.h / 2 / pixel_aspect_ratio /
                inner_projection_plane_distance;
              inner_projection_plane_distance := projection_size.v / 2 /
                abs(tan(v_angle));
              v_slope := projection_size.v / 2 /
                inner_projection_plane_distance;
              inner_pyramid := To_view_pyramid(h_slope, v_slope);

              if concave then
                outer_pyramid := Reverse_view_pyramid(outer_pyramid);
              if inner_pyramid.frustrum.kind = antipyramidal then
                inner_pyramid := Reverse_view_pyramid(inner_pyramid);
            end;
        end; {with}
    end; {else}
end; {procedure Init_fisheye_viewport}


procedure Init_panoramic_viewport(viewport_ptr: viewport_ptr_type;
  projection_ptr: projection_ptr_type);
const
  big = 1000;
var
  h_slope, v_slope: real;
  factor: real;
  outer_projection_plane_distance: real;
begin
  if projection_ptr^.kind <> panoramic then
    Error('invalid projection kind')
  else
    begin
      {**********************************}
      { initialize viewport's projection }
      {**********************************}
      viewport_ptr^.kind := panoramic;

      {***************************************}
      { initialize viewport's clipping region }
      {***************************************}
      with projection_ptr^ do
        begin
          if projection_plane_distance = 0 then
            Error('Invalid projection constant.');

          {********************}
          { make outer pyramid }
          {********************}
          h_slope := abs(tan(field_of_view / 2 * degrees_to_radians));
          factor := cos(field_of_view / 2 * degrees_to_radians);
          if (factor = 0) then
            v_slope := big
          else
            begin
              outer_projection_plane_distance := projection_plane_distance *
                factor;
              v_slope := projection_size.v / 2 /
                outer_projection_plane_distance;
            end;

          with viewport_ptr^ do
            begin
              convex := field_of_view < 180;
              concave := field_of_view > 180;

              if concave then
                v_slope := -v_slope;
              outer_pyramid := To_view_pyramid(h_slope, v_slope);

              {********************}
              { make inner pyramid }
              {********************}
              v_slope := projection_size.v / 2 / projection_plane_distance;
              inner_pyramid := To_view_pyramid(h_slope, v_slope);
              if concave then
                outer_pyramid := Reverse_view_pyramid(outer_pyramid);
            end; {with}
        end; {with}
    end; {else}
end; {procedure Init_panoramic_viewport}


procedure Set_viewport_quadrants(viewport_ptr: viewport_ptr_type);
begin
  with viewport_ptr^ do
    with outer_pyramid do
      begin
        {***************}
        { left quadrant }
        {***************}
        with quadrants.left_quadrant do
          begin
            normal1 := Cross_product(top_left, neg_y_vector);
            normal2 := Cross_product(neg_y_vector, bottom_left);
          end;

        {****************}
        { right quadrant }
        {****************}
        with quadrants.right_quadrant do
          begin
            normal1 := Cross_product(neg_y_vector, top_right);
            normal2 := Cross_product(bottom_right, neg_y_vector);
          end;

        {*****************}
        { bottom quadrant }
        {*****************}
        with quadrants.bottom_quadrant do
          begin
            normal1 := Cross_product(bottom_left, neg_y_vector);
            normal2 := Cross_product(neg_y_vector, bottom_right);
          end;

        {**************}
        { top quadrant }
        {**************}
        with quadrants.top_quadrant do
          begin
            normal1 := Cross_product(neg_y_vector, top_left);
            normal2 := Cross_product(top_right, neg_y_vector);
          end;

      end; {with}
end; {procedure Set_viewport_quadrants}


procedure Init_viewport(viewport_ptr: viewport_ptr_type;
  projection_ptr: projection_ptr_type);
begin
  case projection_ptr^.kind of
    orthographic:
      Init_ortho_viewport(viewport_ptr, projection_ptr);
    perspective:
      Init_perspective_viewport(viewport_ptr, projection_ptr);
    fisheye:
      Init_fisheye_viewport(viewport_ptr, projection_ptr);
    panoramic:
      Init_panoramic_viewport(viewport_ptr, projection_ptr);
  end; {case}

  Set_viewport_quadrants(viewport_ptr);
end; {function Find_clipping_region}


function New_viewport(projection_ptr: projection_ptr_type): viewport_ptr_type;
var
  viewport_ptr: viewport_ptr_type;
begin
  {*********************************}
  { get new viewport from free list }
  {*********************************}
  if viewport_free_list <> nil then
    begin
      viewport_ptr := viewport_free_list;
      viewport_free_list := viewport_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new viewport');
      new(viewport_ptr);
    end;

  {*********************}
  { initialize viewport }
  {*********************}
  Init_viewport(viewport_ptr, projection_ptr);

  New_viewport := viewport_ptr;
end; {function New_viewport}


procedure Free_viewport(var viewport_ptr: viewport_ptr_type);
begin
  {***************************}
  { add viewport to free list }
  {***************************}
  viewport_ptr^.next := viewport_free_list;
  viewport_free_list := viewport_ptr;
  viewport_ptr := nil;
end; {procedure Free_viewport}


initialization
  current_viewport_ptr := nil;
  viewport_free_list := nil;
end.
