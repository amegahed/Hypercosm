unit show_lines;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             show_lines                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is responsible for displaying lines         }
{       under the different projections.                        }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, colors, bounds, clip_lines, xform_b_rep, drawable;


procedure Set_line_color(drawable: drawable_type;
  color: color_type);
procedure Show_line(drawable: drawable_type;
  line: line_type);
procedure Show_b_rep_line(drawable: drawable_type;
  point_data_ptr1: point_data_ptr_type;
  point_data_ptr2: point_data_ptr_type);
procedure Show_point(drawable: drawable_type;
  point: vector_type);
procedure Show_bounding_square(drawable: drawable_type;
  square: bounding_square_type);
procedure Show_bounding_box(drawable: drawable_type;
  box: bounding_box_type);
procedure Show_bounds(drawable: drawable_type;
  bounds: bounding_type);


implementation
uses
  extents, pixels, clip_planes, screen_clip, project, viewports, state_vars;


procedure Set_line_color(drawable: drawable_type;
  color: color_type);
begin
  if Equal_color(color, background_color) then
    drawable.Set_color(Contrast_color(white_color, color))
  else
    drawable.Set_color(color);
end; {procedure Set_line_color}


procedure Show_line(drawable: drawable_type;
  line: line_type);
var
  pixel1, pixel2: pixel_type;
  line_exists: boolean;
  line1_exists, line2_exists: boolean;
  c1, c2: boolean;
  line1, line2: line_type;
  t: real;
begin
  case current_projection_ptr^.kind of

    {*************************}
    { orthographic projection }
    {*************************}
    orthographic:
      begin
        Clip_line_to_origin_plane(line, c1, c2, t, y_vector);

        if not (c1 and c2) then
          begin
            pixel1 := Project_point_to_pixel(line.point1);
            pixel2 := Project_point_to_pixel(line.point2);
            Clip_line_to_screen_box(pixel1, pixel2, line_exists,
              current_projection_ptr^.screen_box);
            if line_exists then
              drawable.Draw_line(pixel1, pixel2);
          end;
      end;

    {************************}
    { perspective projection }
    {************************}
    perspective:
      begin
        Clip_line_to_frustrum(line, line_exists, c1, c2,
          current_viewport_ptr^.clip_pyramid.frustrum);

        if line_exists then
          begin
            pixel1 := Project_point_to_pixel(line.point1);
            pixel2 := Project_point_to_pixel(line.point2);
            drawable.Draw_line(pixel1, pixel2);
          end;
      end;

    {***********************************}
    { fisheye and panoramic projections }
    {***********************************}
    fisheye, panoramic:
      begin
        if current_viewport_ptr^.convex then
          begin
            {*************************************}
            { field of view less than 180 degrees }
            {*************************************}
            Clip_line_to_frustrum(line, line_exists, c1, c2,
              current_viewport_ptr^.outer_pyramid.frustrum);

            if line_exists then
              begin
                pixel1 := Project_point_to_pixel(line.point1);
                pixel2 := Project_point_to_pixel(line.point2);
                Clip_line_to_screen_box(pixel1, pixel2, line_exists,
                  current_projection_ptr^.screen_box);
                if line_exists then
                  drawable.Draw_line(pixel1, pixel2);
              end;
          end
        else if not current_viewport_ptr^.concave then
          begin
            {************************************}
            { field of view equal to 180 degrees }
            {************************************}
            Clip_line_to_origin_plane(line, c1, c2, t, y_vector);

            if not (c1 and c2) then
              begin
                pixel1 := Project_point_to_pixel(line.point1);
                pixel2 := Project_point_to_pixel(line.point2);
                Clip_line_to_screen_box(pixel1, pixel2, line_exists,
                  current_projection_ptr^.screen_box);
                if line_exists then
                  drawable.Draw_line(pixel1, pixel2);
              end;
          end
        else
          begin
            {****************************************}
            { field of view greater than 180 degrees }
            {****************************************}
            line1 := line;
            Clip_line_to_anti_frustrum(line1, line2, line1_exists, line2_exists,
              c1, c2, current_viewport_ptr^.outer_pyramid.frustrum);

            if line1_exists then
              begin
                pixel1 := Project_point_to_pixel(line1.point1);
                pixel2 := Project_point_to_pixel(line1.point2);
                Clip_line_to_screen_box(pixel1, pixel2, line_exists,
                  current_projection_ptr^.screen_box);
                if line_exists then
                  drawable.Draw_line(pixel1, pixel2);
              end;

            if line2_exists then
              begin
                pixel1 := Project_point_to_pixel(line2.point1);
                pixel2 := Project_point_to_pixel(line2.point2);
                Clip_line_to_screen_box(pixel1, pixel2, line_exists,
                  current_projection_ptr^.screen_box);
                if line_exists then
                  drawable.Draw_line(pixel1, pixel2);
              end;
          end;
      end;
  end; {case}
end; {procedure Show_line}


procedure Show_b_rep_line(drawable: drawable_type;
  point_data_ptr1: point_data_ptr_type;
  point_data_ptr2: point_data_ptr_type);
var
  pixel1, pixel2: pixel_type;
  line_exists: boolean;
  line1_exists, line2_exists: boolean;
  c1, c2: boolean;
  clipped1, clipped2: boolean;
  line: line_type;
  line1, line2: line_type;
  t: real;
begin
  {******************************************************}
  { This function works just like Show_line except that  }
  { it uses the b_rep structure to tell if vertices have }
  { already been projected to avoid reprojecting them.   }
  {******************************************************}
  line.point1 := point_data_ptr1^.trans_point;
  line.point2 := point_data_ptr2^.trans_point;

  {*******************************************}
  { clip against user defined clipping planes }
  {*******************************************}
  Clip_line_to_region(line, clipped1, clipped2, t, clipping_planes_ptr);

  if not (clipped1 and clipped2) then
    case current_projection_ptr^.kind of

      {*************************}
      { orthographic projection }
      {*************************}
      orthographic:
        begin
          Clip_line_to_origin_plane(line, c1, c2, t, y_vector);

          if not (c1 and c2) then
            begin
              if (clipped1 or c1) then
                pixel1 := Project_point_to_pixel(line.point1)
              else
                with point_data_ptr1^ do
                  begin
                    if not point_projected then
                      begin
                        pixel := Project_point_to_pixel(line.point1);
                        point_projected := true;
                      end;
                    pixel1 := pixel;
                  end;

              if (clipped2 or c2) then
                pixel2 := Project_point_to_pixel(line.point2)
              else
                with point_data_ptr2^ do
                  begin
                    if not point_projected then
                      begin
                        pixel := Project_point_to_pixel(line.point2);
                        point_projected := true;
                      end;
                    pixel2 := pixel;
                  end;

              Clip_line_to_screen_box(pixel1, pixel2, line_exists,
                current_projection_ptr^.screen_box);
              if line_exists then
                drawable.Draw_line(pixel1, pixel2);
            end;
        end;

      {************************}
      { perspective projection }
      {************************}
      perspective:
        begin
          Clip_line_to_frustrum(line, line_exists, c1, c2,
            current_viewport_ptr^.clip_pyramid.frustrum);

          if line_exists then
            begin
              if (clipped1 or c1) then
                pixel1 := Project_point_to_pixel(line.point1)
              else
                with point_data_ptr1^ do
                  begin
                    if not point_projected then
                      begin
                        pixel := Project_point_to_pixel(line.point1);
                        point_projected := true;
                      end;
                    pixel1 := pixel;
                  end;

              if (clipped2 or c2) then
                pixel2 := Project_point_to_pixel(line.point2)
              else
                with point_data_ptr2^ do
                  begin
                    if not point_projected then
                      begin
                        pixel := Project_point_to_pixel(line.point2);
                        point_projected := true;
                      end;
                    pixel2 := pixel;
                  end;
              drawable.Draw_line(pixel1, pixel2);
            end;
        end;

      {***********************************}
      { fisheye and panoramic projections }
      {***********************************}
      fisheye, panoramic:
        begin
          if current_viewport_ptr^.convex then
            begin
              {*************************************}
              { field of view less than 180 degrees }
              {*************************************}
              Clip_line_to_frustrum(line, line_exists, c1, c2,
                current_viewport_ptr^.outer_pyramid.frustrum);

              if line_exists then
                begin
                  if (clipped1 or c1) then
                    pixel1 := Project_point_to_pixel(line.point1)
                  else
                    with point_data_ptr1^ do
                      begin
                        if not point_projected then
                          begin
                            pixel := Project_point_to_pixel(line.point1);
                            point_projected := true;
                          end;
                        pixel1 := pixel;
                      end;

                  if (clipped2 or c2) then
                    pixel2 := Project_point_to_pixel(line.point2)
                  else
                    with point_data_ptr2^ do
                      begin
                        if not point_projected then
                          begin
                            pixel := Project_point_to_pixel(line.point2);
                            point_projected := true;
                          end;
                        pixel2 := pixel;
                      end;

                  Clip_line_to_screen_box(pixel1, pixel2, line_exists,
                    current_projection_ptr^.screen_box);
                  if line_exists then
                    drawable.Draw_line(pixel1, pixel2);
                end;
            end
          else if not current_viewport_ptr^.concave then
            begin
              {************************************}
              { field of view equal to 180 degrees }
              {************************************}
              Clip_line_to_origin_plane(line, c1, c2, t, y_vector);

              if not (c1 and c2) then
                begin
                  if (clipped1 or c1) then
                    pixel1 := Project_point_to_pixel(line.point1)
                  else
                    with point_data_ptr1^ do
                      begin
                        if not point_projected then
                          begin
                            pixel := Project_point_to_pixel(line.point1);
                            point_projected := true;
                          end;
                        pixel1 := pixel;
                      end;

                  if (clipped2 or c2) then
                    pixel2 := Project_point_to_pixel(line.point2)
                  else
                    with point_data_ptr2^ do
                      begin
                        if not point_projected then
                          begin
                            pixel := Project_point_to_pixel(line.point2);
                            point_projected := true;
                          end;
                        pixel2 := pixel;
                      end;
                  drawable.Draw_line(pixel1, pixel2);
                end;
            end
          else
            begin
              {****************************************}
              { field of view greater than 180 degrees }
              {****************************************}
              line1 := line;
              Clip_line_to_anti_frustrum(line1, line2, line1_exists,
                line2_exists, c1, c2,
                current_viewport_ptr^.outer_pyramid.frustrum);

              if line1_exists and line2_exists then
                begin
                  {***********}
                  { two lines }
                  {***********}

                  {*****************}
                  { draw first line }
                  {*****************}
                  if (clipped1 or c1) then
                    pixel1 := Project_point_to_pixel(line1.point1)
                  else
                    with point_data_ptr1^ do
                      begin
                        if not point_projected then
                          begin
                            pixel := Project_point_to_pixel(line1.point1);
                            point_projected := true;
                          end;
                        pixel1 := pixel;
                      end;

                  pixel2 := Project_point_to_pixel(line1.point2);
                  Clip_line_to_screen_box(pixel1, pixel2, line_exists,
                    current_projection_ptr^.screen_box);
                  if line_exists then
                    drawable.Draw_line(pixel1, pixel2);

                  {******************}
                  { draw second line }
                  {******************}
                  if (clipped2 or c2) then
                    pixel2 := Project_point_to_pixel(line2.point2)
                  else
                    with point_data_ptr2^ do
                      begin
                        if not point_projected then
                          begin
                            pixel := Project_point_to_pixel(line2.point2);
                            point_projected := true;
                          end;
                        pixel2 := pixel;
                      end;

                  pixel1 := Project_point_to_pixel(line2.point1);
                  Clip_line_to_screen_box(pixel1, pixel2, line_exists,
                    current_projection_ptr^.screen_box);
                  if line_exists then
                    drawable.Draw_line(pixel1, pixel2);
                end
              else
                begin
                  {**********}
                  { one line }
                  {**********}
                  if line1_exists then
                    begin
                      if (clipped1 or c1) then
                        pixel1 := Project_point_to_pixel(line1.point1)
                      else
                        with point_data_ptr1^ do
                          begin
                            if not point_projected then
                              begin
                                pixel := Project_point_to_pixel(line1.point1);
                                point_projected := true;
                              end;
                            pixel1 := pixel;
                          end;

                      if (clipped2 or c2) then
                        pixel2 := Project_point_to_pixel(line1.point2)
                      else
                        with point_data_ptr2^ do
                          begin
                            if not point_projected then
                              begin
                                pixel := Project_point_to_pixel(line1.point2);
                                point_projected := true;
                              end;
                            pixel2 := pixel;
                          end;

                      Clip_line_to_screen_box(pixel1, pixel2, line_exists,
                        current_projection_ptr^.screen_box);
                      if line_exists then
                        drawable.Draw_line(pixel1, pixel2);
                    end;
                end;
            end;
        end;
    end; {case}
end; {procedure Show_b_rep_line}


procedure Show_point(drawable: drawable_type;
  point: vector_type);
var
  clipping_plane_ptr: clipping_plane_ptr_type;
  pixel: pixel_type;
  clipped: boolean;
begin
  clipped := false;
  if (current_projection_ptr^.kind in [orthographic, perspective]) then
    if (point.y < 0) then
      clipped := true;

  if not clipped and (clipping_planes_ptr <> nil) then
    begin
      clipping_plane_ptr := clipping_planes_ptr;
      while (clipping_plane_ptr <> nil) and not clipped do
        begin
          if Dot_product(Vector_difference(point,
            clipping_plane_ptr^.plane.origin),
            clipping_plane_ptr^.plane.normal) < 0 then
            clipped := true
          else
            clipping_plane_ptr := clipping_plane_ptr^.next;
        end;
    end;

  if not clipped then
    begin
      pixel := Project_point_to_pixel(point);
      drawable.Draw_pixel(pixel);
    end;
end; {procedure Show_point}


procedure Show_bounding_square(drawable: drawable_type;
  square: bounding_square_type);
begin
  Show_line(drawable, To_line(square[right, front], square[right, back]));
  Show_line(drawable, To_line(square[right, back], square[left, back]));
  Show_line(drawable, To_line(square[left, back], square[left, front]));
  Show_line(drawable, To_line(square[left, front], square[right, front]));
end; {procedure Show_bounding_square}


procedure Show_bounding_box(drawable: drawable_type;
  box: bounding_box_type);
begin
  {***********}
  { top edges }
  {***********}
  Show_line(drawable, To_line(box[right, front, top], box[right, back, top]));
  Show_line(drawable, To_line(box[right, back, top], box[left, back, top]));
  Show_line(drawable, To_line(box[left, back, top], box[left, front, top]));
  Show_line(drawable, To_line(box[left, front, top], box[right, front, top]));

  {**************}
  { bottom edges }
  {**************}
  Show_line(drawable, To_line(box[right, front, bottom], box[right, back, bottom]));
  Show_line(drawable, To_line(box[right, back, bottom], box[left, back, bottom]));
  Show_line(drawable, To_line(box[left, back, bottom], box[left, front, bottom]));
  Show_line(drawable, To_line(box[left, front, bottom], box[right, front, bottom]));

  {************}
  { side edges }
  {************}
  Show_line(drawable, To_line(box[right, front, bottom], box[right, front, top]));
  Show_line(drawable, To_line(box[right, back, bottom], box[right, back, top]));
  Show_line(drawable, To_line(box[left, back, bottom], box[left, back, top]));
  Show_line(drawable, To_line(box[left, front, bottom], box[left, front, top]));
end; {procedure Show_bounding_box}


procedure Show_bounds(drawable: drawable_type;
  bounds: bounding_type);
begin
  case bounds.bounding_kind of
    infinite_planar_bounds, infinite_non_planar_bounds:
      ; {do nothing}
    planar_bounds:
      Show_bounding_square(drawable, bounds.bounding_square);
    non_planar_bounds:
      Show_bounding_box(drawable, bounds.bounding_box);
  end;
end; {procedure Show_bounds}


end.
