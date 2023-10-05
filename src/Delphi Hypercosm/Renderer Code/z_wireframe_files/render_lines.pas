unit render_lines;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            render_lines               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is responsible for rendering lines          }
{       under the different shading modes.                      }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  colors, topology, xform_b_rep, renderable;


procedure Set_z_line_color(renderable: vertex_renderable_type;
  color: color_type);

{**************************}
{ routines to render lines }
{**************************}
procedure Render_line(renderable: line_renderable_type;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type);
procedure Render_thick_line(renderable: line_renderable_type;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  thickness: real);

{********************************************************}
{ This function works just like Render_line except       }
{ that it uses the b_rep structure to tell if vertices   }
{ have already been projected to avoid reprojecting them }
{********************************************************}
procedure Render_b_rep_line(renderable: line_renderable_type;
  point_data_ptr1: point_data_ptr_type;
  point_data_ptr2: point_data_ptr_type);

{****************************************************}
{ routines to render pre clipped and projected lines }
{****************************************************}
procedure Render_visible_line(renderable: line_renderable_type;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type);
procedure Render_visible_thick_line(renderable: line_renderable_type;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  thickness: real);


implementation
uses
  vectors, vectors2, geometry, state_vars, project, viewports, clip_lines,
  z_pipeline, z_screen_clip, z_clip, object_attr, shade_b_rep, z_renderer,
  z_flat_lines, z_smooth_lines, z_phong_lines;


procedure Set_z_line_color(renderable: vertex_renderable_type;
  color: color_type);
begin
  if Equal_color(color, background_color) then
    renderable.Set_color(Contrast_color(white_color, color))
  else
    renderable.Set_color(color);
end; {procedure Set_z_line_color}


{**************************}
{ routines to render lines }
{**************************}


procedure Render_line(renderable: line_renderable_type;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type);
var
  shading: shading_type;
  point_data_ptr: point_data_ptr_type;
  vertex_data_ptr: vertex_data_ptr_type;
  point_data_ptr1, point_data_ptr2: point_data_ptr_type;
  vertex_data_ptr1, vertex_data_ptr2: vertex_data_ptr_type;
begin
  if not attributes.valid[edge_shader_attributes] then
    shading := face_shading
  else
    shading := attributes.shading;

  case shading of

    {*******************}
    { flat shading mode }
    {*******************}
    face_shading:
      begin
        point_data_ptr1 := Get_point_data(vertex_ptr1^.point_ptr^.index);
        point_data_ptr2 := Get_point_data(vertex_ptr2^.point_ptr^.index);

        if attributes.valid[edge_shader_attributes] then
          renderable.Set_color(point_data_ptr1^.color);

        renderable.Begin_line;
        renderable.Add_vertex(point_data_ptr1^.trans_point);
        renderable.Add_vertex(point_data_ptr2^.trans_point);
        renderable.Draw_line;
      end;

    {**********************}
    { Gouraud shading mode }
    {**********************}
    vertex_shading:
      begin
        point_data_ptr1 := Get_point_data(vertex_ptr1^.point_ptr^.index);
        point_data_ptr2 := Get_point_data(vertex_ptr2^.point_ptr^.index);
        vertex_data_ptr1 := Get_vertex_data(vertex_ptr1^.index);
        vertex_data_ptr2 := Get_vertex_data(vertex_ptr2^.index);

        renderable.Begin_line;
        renderable.Set_color(vertex_data_ptr1^.front_color);
        renderable.Add_vertex(point_data_ptr1^.trans_point);
        renderable.Set_color(vertex_data_ptr2^.front_color);
        renderable.Add_vertex(point_data_ptr2^.trans_point);
        renderable.Draw_line;
      end;

    {********************}
    { Phong shading mode }
    {********************}
    pixel_shading:
      begin
        Begin_z_line;

        with vertex_ptr1^ do
          begin
            point_data_ptr := Get_point_data(point_ptr^.index);
            vertex_data_ptr := Get_vertex_data(vertex_ptr1^.index);

            Set_z_texture(vertex_geometry_ptr^.texture);
            Set_z_normal(vertex_data_ptr^.trans_normal);
            Set_z_vectors(vertex_data_ptr^.trans_u_axis,
              vertex_data_ptr^.trans_v_axis);
            Set_z_vertex(point_data_ptr^.trans_point);
            Add_z_vertex(point_data_ptr^.trans_point)
          end;

        with vertex_ptr2^ do
          begin
            point_data_ptr := Get_point_data(point_ptr^.index);
            vertex_data_ptr := Get_vertex_data(vertex_ptr2^.index);

            Set_z_texture(vertex_geometry_ptr^.texture);
            Set_z_normal(vertex_data_ptr^.trans_normal);
            Set_z_vectors(vertex_data_ptr^.trans_u_axis,
              vertex_data_ptr^.trans_v_axis);
            Set_z_vertex(point_data_ptr^.trans_point);
            Add_z_vertex(point_data_ptr^.trans_point);
          end;

        Phong_shade_z_line(z_renderer_type(renderable));
      end;
  end;
end; {procedure Render_line}


procedure Render_thick_line(renderable: line_renderable_type;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  thickness: real);
var
  vertex_data_ptr: vertex_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
  point_data_ptr1, point_data_ptr2: point_data_ptr_type;
  vertex_data_ptr1, vertex_data_ptr2: vertex_data_ptr_type;
begin
  case attributes.shading of

    {*******************}
    { flat shading mode }
    {*******************}
    face_shading:
      begin
        point_data_ptr1 := Get_point_data(vertex_ptr1^.point_ptr^.index);
        point_data_ptr2 := Get_point_data(vertex_ptr2^.point_ptr^.index);

        if attributes.valid[edge_shader_attributes] then
          renderable.Set_color(point_data_ptr1^.color);

        Begin_z_line;
        Add_z_vertex(point_data_ptr1^.trans_point);
        Add_z_vertex(point_data_ptr2^.trans_point);
        Flat_shade_z_thick_line(z_renderer_type(renderable), thickness);
      end;

    {**********************}
    { Gouraud shading mode }
    {**********************}
    vertex_shading:
      begin
        point_data_ptr1 := Get_point_data(vertex_ptr1^.point_ptr^.index);
        point_data_ptr2 := Get_point_data(vertex_ptr2^.point_ptr^.index);
        vertex_data_ptr1 := Get_vertex_data(vertex_ptr1^.index);
        vertex_data_ptr2 := Get_vertex_data(vertex_ptr2^.index);

        Begin_z_line;
        Set_z_color(vertex_data_ptr1^.front_color);
        Add_z_vertex(point_data_ptr1^.trans_point);
        Set_z_color(vertex_data_ptr2^.front_color);
        Add_z_vertex(point_data_ptr2^.trans_point);
        Gouraud_shade_z_thick_line(z_renderer_type(renderable), thickness);
      end;

    {********************}
    { Phong shading mode }
    {********************}
    pixel_shading:
      begin
        Begin_z_line;

        with vertex_ptr1^ do
          begin
            point_data_ptr := Get_point_data(point_ptr^.index);
            vertex_data_ptr := Get_vertex_data(vertex_ptr1^.index);

            Set_z_texture(vertex_geometry_ptr^.texture);
            Set_z_normal(vertex_data_ptr^.trans_normal);
            Set_z_vectors(vertex_data_ptr^.trans_u_axis,
              vertex_data_ptr^.trans_v_axis);
            Set_z_vertex(point_data_ptr^.trans_point);
            Add_z_vertex(point_data_ptr^.trans_point)
          end;

        with vertex_ptr2^ do
          begin
            point_data_ptr := Get_point_data(point_ptr^.index);
            vertex_data_ptr := Get_vertex_data(vertex_ptr2^.index);

            Set_z_texture(vertex_geometry_ptr^.texture);
            Set_z_normal(vertex_data_ptr^.trans_normal);
            Set_z_vectors(vertex_data_ptr^.trans_u_axis,
              vertex_data_ptr^.trans_v_axis);
            Set_z_vertex(point_data_ptr^.trans_point);
            Add_z_vertex(point_data_ptr^.trans_point);
          end;

        Phong_shade_z_thick_line(z_renderer_type(renderable), thickness);
      end;
  end;
end; {procedure Render_thick_line}


{********************************************************}
{ This function works just like Render_line except       }
{ that it uses the b_rep structure to tell if vertices   }
{ have already been projected to avoid reprojecting them }
{********************************************************}


procedure Render_b_rep_line(renderable: line_renderable_type;
  point_data_ptr1: point_data_ptr_type;
  point_data_ptr2: point_data_ptr_type);
var
  point1, point2: vector_type;
  line_exists: boolean;
  line1_exists, line2_exists: boolean;
  c1, c2: boolean;
  line, line1, line2: line_type;
  t: real;
begin
  case current_projection_ptr^.kind of

    {*************************}
    { orthographic projection }
    {*************************}
    orthographic:
      begin
        line.point1 := point_data_ptr1^.trans_point;
        line.point2 := point_data_ptr2^.trans_point;
        Clip_line_to_origin_plane(line, c1, c2, t, y_vector);

        if not (c1 and c2) then
          begin
            if c1 then
              point1 := Project_point_to_point(line.point1)
            else
              with point_data_ptr1^ do
                begin
                  if not point_projected then
                    begin
                      vector := Project_point_to_point(line.point1);
                      point_projected := true;
                    end;
                  point1 := vector;
                end;

            if c2 then
              point2 := Project_point_to_point(line.point2)
            else
              with point_data_ptr2^ do
                begin
                  if not point_projected then
                    begin
                      vector := Project_point_to_point(line.point2);
                      point_projected := true;
                    end;
                  point2 := vector;
                end;

            renderable.Begin_line;
            renderable.Add_vertex(point1);
            renderable.Add_vertex(point2);
            renderable.Draw_line;
          end;
      end;

    {************************}
    { perspective projection }
    {************************}
    perspective:
      begin
        line.point1 := point_data_ptr1^.trans_point;
        line.point2 := point_data_ptr2^.trans_point;
        Clip_line_to_frustrum(line, line_exists, c1, c2,
          current_viewport_ptr^.clip_pyramid.frustrum);

        if line_exists then
          begin
            if c1 then
              point1 := Project_point_to_point(line.point1)
            else
              with point_data_ptr1^ do
                begin
                  if not point_projected then
                    begin
                      vector := Project_point_to_point(line.point1);
                      point_projected := true;
                    end;
                  point1 := vector;
                end;

            if c2 then
              point2 := Project_point_to_point(line.point2)
            else
              with point_data_ptr2^ do
                begin
                  if not point_projected then
                    begin
                      vector := Project_point_to_point(line.point2);
                      point_projected := true;
                    end;
                  point2 := vector;
                end;

            renderable.Begin_line;
            renderable.Add_vertex(point1);
            renderable.Add_vertex(point2);
            renderable.Draw_line;
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
            line.point1 := point_data_ptr1^.trans_point;
            line.point2 := point_data_ptr2^.trans_point;
            Clip_line_to_frustrum(line, line_exists, c1, c2,
              current_viewport_ptr^.outer_pyramid.frustrum);

            if line_exists then
              begin
                if c1 then
                  point1 := Project_point_to_point(line.point1)
                else
                  with point_data_ptr1^ do
                    begin
                      if not point_projected then
                        begin
                          vector := Project_point_to_point(line.point1);
                          point_projected := true;
                        end;
                      point1 := vector;
                    end;

                if c2 then
                  point2 := Project_point_to_point(line.point2)
                else
                  with point_data_ptr2^ do
                    begin
                      if not point_projected then
                        begin
                          vector := Project_point_to_point(line.point2);
                          point_projected := true;
                        end;
                      point2 := vector;
                    end;

                renderable.Begin_line;
                renderable.Add_vertex(point1);
                renderable.Add_vertex(point2);
                Clip_z_line_to_screen_box(z_line_list,
                  current_projection_ptr^.screen_box);
                renderable.Draw_line;
              end;
          end
        else if not current_viewport_ptr^.concave then
          begin
            {************************************}
            { field of view equal to 180 degrees }
            {************************************}
            line.point1 := point_data_ptr1^.trans_point;
            line.point2 := point_data_ptr2^.trans_point;
            Clip_line_to_origin_plane(line, c1, c2, t, y_vector);

            if not (c1 and c2) then
              begin
                if c1 then
                  point1 := Project_point_to_point(line.point1)
                else
                  with point_data_ptr1^ do
                    begin
                      if not point_projected then
                        begin
                          vector := Project_point_to_point(line.point1);
                          point_projected := true;
                        end;
                      point1 := vector;
                    end;

                if c2 then
                  point2 := Project_point_to_point(line.point2)
                else
                  with point_data_ptr2^ do
                    begin
                      if not point_projected then
                        begin
                          vector := Project_point_to_point(line.point2);
                          point_projected := true;
                        end;
                      point2 := vector;
                    end;

                renderable.Begin_line;
                renderable.Add_vertex(point1);
                renderable.Add_vertex(point2);
                Clip_z_line_to_screen_box(z_line_list,
                  current_projection_ptr^.screen_box);
                renderable.Draw_line;
              end;
          end
        else
          begin
            {****************************************}
            { field of view greater than 180 degrees }
            {****************************************}
            line1.point1 := point_data_ptr1^.trans_point;
            line1.point2 := point_data_ptr2^.trans_point;
            Clip_line_to_anti_frustrum(line1, line2, line1_exists, line2_exists,
              c1, c2, current_viewport_ptr^.outer_pyramid.frustrum);

            if line1_exists and line2_exists then
              begin
                {***********}
                { two lines }
                {***********}

                {*****************}
                { draw first line }
                {*****************}
                if c1 then
                  point1 := Project_point_to_point(line1.point1)
                else
                  with point_data_ptr1^ do
                    begin
                      if not point_projected then
                        begin
                          vector := Project_point_to_point(line1.point1);
                          point_projected := true;
                        end;
                      point1 := vector;
                    end;

                point2 := Project_point_to_point(line1.point2);
                renderable.Begin_line;
                renderable.Add_vertex(point1);
                renderable.Add_vertex(point2);
                Clip_z_line_to_screen_box(z_line_list,
                  current_projection_ptr^.screen_box);
                renderable.Draw_line;

                {******************}
                { draw second line }
                {******************}
                if c2 then
                  point2 := Project_point_to_point(line2.point2)
                else
                  with point_data_ptr2^ do
                    begin
                      if not point_projected then
                        begin
                          vector := Project_point_to_point(line2.point2);
                          point_projected := true;
                        end;
                      point2 := vector;
                    end;

                point1 := Project_point_to_point(line2.point1);
                renderable.Begin_line;
                renderable.Add_vertex(point1);
                renderable.Add_vertex(point2);
                Clip_z_line_to_screen_box(z_line_list,
                  current_projection_ptr^.screen_box);
                renderable.Draw_line;
              end
            else
              begin
                {**********}
                { one line }
                {**********}
                if line1_exists then
                  begin
                    if c1 then
                      point1 := Project_point_to_point(line1.point1)
                    else
                      with point_data_ptr1^ do
                        begin
                          if not point_projected then
                            begin
                              vector := Project_point_to_point(line1.point1);
                              point_projected := true;
                            end;
                          point1 := vector;
                        end;

                    if c2 then
                      point2 := Project_point_to_point(line1.point2)
                    else
                      with point_data_ptr2^ do
                        begin
                          if not point_projected then
                            begin
                              vector := Project_point_to_point(line1.point2);
                              point_projected := true;
                            end;
                          point2 := vector;
                        end;

                    renderable.Begin_line;
                    renderable.Add_vertex(point1);
                    renderable.Add_vertex(point2);
                    Clip_z_line_to_screen_box(z_line_list,
                      current_projection_ptr^.screen_box);
                    renderable.Draw_line;
                  end;
              end;
          end;
      end;
  end; {case}
end; {procedure Render_b_rep_line}


{****************************************************}
{ routines to render pre clipped and projected lines }
{****************************************************}


procedure Render_visible_line(renderable: line_renderable_type;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type);
var
  shading: shading_type;
  point_data_ptr: point_data_ptr_type;
  vertex_data_ptr: vertex_data_ptr_type;
  point_data_ptr1, point_data_ptr2: point_data_ptr_type;
  vertex_data_ptr1, vertex_data_ptr2: vertex_data_ptr_type;
begin
  if not attributes.valid[edge_shader_attributes] then
    shading := face_shading
  else
    shading := attributes.shading;

  case shading of

    {*******************}
    { flat shading mode }
    {*******************}
    face_shading:
      begin
        point_data_ptr1 := Get_point_data(vertex_ptr1^.point_ptr^.index);
        point_data_ptr2 := Get_point_data(vertex_ptr2^.point_ptr^.index);

        if attributes.valid[edge_shader_attributes] then
          renderable.Set_color(point_data_ptr1^.color);

        renderable.Begin_line;
        renderable.Add_vertex(point_data_ptr1^.vector);
        renderable.Add_vertex(point_data_ptr2^.vector);
        renderable.Draw_line;
      end;

    {**********************}
    { Gouraud shading mode }
    {**********************}
    vertex_shading:
      begin
        point_data_ptr1 := Get_point_data(vertex_ptr1^.point_ptr^.index);
        point_data_ptr2 := Get_point_data(vertex_ptr2^.point_ptr^.index);
        vertex_data_ptr1 := Get_vertex_data(vertex_ptr1^.index);
        vertex_data_ptr2 := Get_vertex_data(vertex_ptr2^.index);

        renderable.Begin_line;
        renderable.Set_color(vertex_data_ptr1^.front_color);
        renderable.Add_vertex(point_data_ptr1^.vector);
        renderable.Set_color(vertex_data_ptr2^.front_color);
        renderable.Add_vertex(point_data_ptr2^.vector);
        renderable.Draw_line;
      end;

    {********************}
    { Phong shading mode }
    {********************}
    pixel_shading:
      begin
        Begin_z_line;

        with vertex_ptr1^ do
          begin
            point_data_ptr := Get_point_data(point_ptr^.index);
            vertex_data_ptr := Get_vertex_data(vertex_ptr1^.index);

            Set_z_texture(vertex_geometry_ptr^.texture);
            Set_z_normal(vertex_data_ptr^.trans_normal);
            Set_z_vectors(vertex_data_ptr^.trans_u_axis,
              vertex_data_ptr^.trans_v_axis);
            Set_z_vertex(point_data_ptr^.trans_point);
            Add_z_vertex(point_data_ptr^.vector);
          end;

        with vertex_ptr2^ do
          begin
            point_data_ptr := Get_point_data(point_ptr^.index);
            vertex_data_ptr := Get_vertex_data(vertex_ptr2^.index);

            Set_z_texture(vertex_geometry_ptr^.texture);
            Set_z_normal(vertex_data_ptr^.trans_normal);
            Set_z_vectors(vertex_data_ptr^.trans_u_axis,
              vertex_data_ptr^.trans_v_axis);
            Set_z_vertex(point_data_ptr^.trans_point);
            Add_z_vertex(point_data_ptr^.vector);
          end;

        Phong_shade_z_line(z_renderer_type(renderable));
      end;
  end;
end; {procedure Render_visible_line}


procedure Render_visible_thick_line(renderable: line_renderable_type;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  thickness: real);
var
  vertex_data_ptr: vertex_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
  point_data_ptr1, point_data_ptr2: point_data_ptr_type;
  vertex_data_ptr1, vertex_data_ptr2: vertex_data_ptr_type;
begin
  case attributes.shading of

    {*******************}
    { flat shading mode }
    {*******************}
    face_shading:
      begin
        point_data_ptr1 := Get_point_data(vertex_ptr1^.point_ptr^.index);
        point_data_ptr2 := Get_point_data(vertex_ptr2^.point_ptr^.index);

        if attributes.valid[edge_shader_attributes] then
          renderable.Set_color(point_data_ptr1^.color);

        renderable.Begin_line;
        renderable.Add_vertex(point_data_ptr1^.vector);
        renderable.Add_vertex(point_data_ptr2^.vector);
        Flat_shade_z_thick_line(z_renderer_type(renderable), thickness);
      end;

    {**********************}
    { Gouraud shading mode }
    {**********************}
    vertex_shading:
      begin
        point_data_ptr1 := Get_point_data(vertex_ptr1^.point_ptr^.index);
        point_data_ptr2 := Get_point_data(vertex_ptr2^.point_ptr^.index);
        vertex_data_ptr1 := Get_vertex_data(vertex_ptr1^.index);
        vertex_data_ptr2 := Get_vertex_data(vertex_ptr2^.index);

        renderable.Begin_line;
        renderable.Set_color(vertex_data_ptr1^.front_color);
        renderable.Add_vertex(point_data_ptr1^.vector);
        renderable.Set_color(vertex_data_ptr2^.front_color);
        renderable.Add_vertex(point_data_ptr2^.vector);
        Gouraud_shade_z_thick_line(z_renderer_type(renderable), thickness);
      end;

    {********************}
    { Phong shading mode }
    {********************}
    pixel_shading:
      begin
        Begin_z_line;

        with vertex_ptr1^ do
          begin
            point_data_ptr := Get_point_data(point_ptr^.index);
            vertex_data_ptr := Get_vertex_data(vertex_ptr1^.index);

            Set_z_texture(vertex_geometry_ptr^.texture);
            Set_z_normal(vertex_data_ptr^.trans_normal);
            Set_z_vectors(vertex_data_ptr^.trans_u_axis,
              vertex_data_ptr^.trans_v_axis);
            Set_z_vertex(point_data_ptr^.trans_point);
            Add_z_vertex(point_data_ptr^.vector);
          end;

        with vertex_ptr2^ do
          begin
            point_data_ptr := Get_point_data(point_ptr^.index);
            vertex_data_ptr := Get_vertex_data(vertex_ptr2^.index);

            Set_z_texture(vertex_geometry_ptr^.texture);
            Set_z_normal(vertex_data_ptr^.trans_normal);
            Set_z_vectors(vertex_data_ptr^.trans_u_axis,
              vertex_data_ptr^.trans_v_axis);
            Set_z_vertex(point_data_ptr^.trans_point);
            Add_z_vertex(point_data_ptr^.vector);
          end;

        Phong_shade_z_thick_line(z_renderer_type(renderable), thickness);
      end;
  end;
end; {procedure Render_visible_thick_line}


end.
