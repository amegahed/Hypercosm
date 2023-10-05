unit hidden_lines;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            hidden_lines               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is used to draw the edges of polygons       }
{       in the various edge modes which can be used with        }
{       the hidden_line rendering mode.                         }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  colors, topology, renderable;


var
  edge_color, pseudo_edge_color: color_type;


  {*************************************}
  { routines to draw all appropriate    }
  { polygon edges for a given edge mode }
  {*************************************}
procedure Draw_face_edges(renderable: line_renderable_type;
  face_ptr: face_ptr_type);
procedure Draw_visible_face_edges(renderable: line_renderable_type;
  face_ptr: face_ptr_type);

{****************************************}
{ routines to draw the appropriate non-  }
{ silhouette edges for a given edge mode }
{****************************************}
procedure Draw_face_mask(renderable: polygon_renderable_type;
  face_ptr: face_ptr_type);
procedure Draw_visible_face_mask(renderable: polygon_renderable_type;
  face_ptr: face_ptr_type);

{****************************************}
{ routines to the appropriate            }
{ silhouette edges for a given edge mode }
{****************************************}
procedure Draw_face_silhouette(renderable: line_renderable_type;
  face_ptr: face_ptr_type);
procedure Draw_visible_face_silhouette(renderable: line_renderable_type;
  face_ptr: face_ptr_type);


implementation
uses
  state_vars, xform_b_rep, z_pipeline, object_attr, shade_b_rep, render_lines;


{*************************************}
{ routines to draw all appropriate    }
{ polygon edges for a given edge mode }
{*************************************}


procedure Draw_face_edges(renderable: line_renderable_type;
  face_ptr: face_ptr_type);
var
  edge_ptr: edge_ptr_type;
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
  {***********************}
  { draw edges of polygon }
  {***********************}
  case attributes.edge_mode of

    silhouette_edges:
      begin
        {******************}
        { silhouette edges }
        {******************}
        Set_z_line_color(renderable, edge_color);
        cycle_ptr := face_ptr^.cycle_ptr;
        while (cycle_ptr <> nil) do
          begin
            directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
            while (directed_edge_ptr <> nil) do
              begin
                edge_ptr := directed_edge_ptr^.edge_ptr;
                if (edge_ptr^.edge_kind = duplicate_edge) then
                  edge_ptr := edge_ptr^.duplicate_edge_ptr;

                edge_data_ptr := Get_edge_data(edge_ptr^.index);
                with edge_ptr^ do
                  if (edge_kind = real_edge) or
                    (edge_data_ptr^.surface_visibility = silhouette_edge) then
                    Render_line(renderable, vertex_ptr1, vertex_ptr2);

                directed_edge_ptr := directed_edge_ptr^.next;
              end; {while}
            cycle_ptr := cycle_ptr^.next;
          end; {while}
      end;

    outline_edges:
      begin
        {***************}
        { outline edges }
        {***************}
        cycle_ptr := face_ptr^.cycle_ptr;
        while (cycle_ptr <> nil) do
          begin
            directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
            while (directed_edge_ptr <> nil) do
              begin
                edge_ptr := directed_edge_ptr^.edge_ptr;
                if (edge_ptr^.edge_kind = duplicate_edge) then
                  edge_ptr := edge_ptr^.duplicate_edge_ptr;

                edge_data_ptr := Get_edge_data(edge_ptr^.index);
                with edge_ptr^ do
                  if (edge_kind = real_edge) or
                    (edge_data_ptr^.surface_visibility = silhouette_edge) then
                    begin
                      Set_z_line_color(renderable, edge_color);
                      Render_line(renderable, vertex_ptr1, vertex_ptr2);
                    end
                  else if (edge_kind = pseudo_edge) then
                    begin
                      Set_z_line_color(renderable, pseudo_edge_color);
                      Render_line(renderable, vertex_ptr1, vertex_ptr2);
                    end;
                directed_edge_ptr := directed_edge_ptr^.next;
              end; {while}
            cycle_ptr := cycle_ptr^.next;
          end; {while}
      end;

    all_edges:
      begin
        {***********}
        { all edges }
        {***********}
        Set_z_line_color(renderable, edge_color);
        cycle_ptr := face_ptr^.cycle_ptr;
        while (cycle_ptr <> nil) do
          begin
            directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
            while (directed_edge_ptr <> nil) do
              begin
                with directed_edge_ptr^.edge_ptr^ do
                  Render_line(renderable, vertex_ptr1, vertex_ptr2);
                directed_edge_ptr := directed_edge_ptr^.next;
              end;
            cycle_ptr := cycle_ptr^.next;
          end; {while}
      end;

  end; {case}
end; {procedure Draw_face_edges}


procedure Draw_visible_face_edges(renderable: line_renderable_type;
  face_ptr: face_ptr_type);
var
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
  edge_ptr: edge_ptr_type;
begin
  {***********************}
  { draw edges of polygon }
  {***********************}
  case attributes.edge_mode of

    silhouette_edges:
      begin
        {******************}
        { silhouette edges }
        {******************}
        Set_z_line_color(renderable, edge_color);
        cycle_ptr := face_ptr^.cycle_ptr;
        while (cycle_ptr <> nil) do
          begin
            directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
            while (directed_edge_ptr <> nil) do
              begin
                edge_ptr := directed_edge_ptr^.edge_ptr;
                if (edge_ptr^.edge_kind = duplicate_edge) then
                  edge_ptr := edge_ptr^.duplicate_edge_ptr;

                edge_data_ptr := Get_edge_data(edge_ptr^.index);
                with edge_ptr^ do
                  if (edge_kind = real_edge) or
                    (edge_data_ptr^.surface_visibility = silhouette_edge) then
                    Render_visible_line(renderable, vertex_ptr1, vertex_ptr2);

                directed_edge_ptr := directed_edge_ptr^.next;
              end; {while}
            cycle_ptr := cycle_ptr^.next;
          end; {while}
      end;

    outline_edges:
      begin
        {***************}
        { outline edges }
        {***************}
        cycle_ptr := face_ptr^.cycle_ptr;
        while (cycle_ptr <> nil) do
          begin
            directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
            while (directed_edge_ptr <> nil) do
              begin
                edge_ptr := directed_edge_ptr^.edge_ptr;
                if (edge_ptr^.edge_kind = duplicate_edge) then
                  edge_ptr := edge_ptr^.duplicate_edge_ptr;

                edge_data_ptr := Get_edge_data(edge_ptr^.index);
                with edge_ptr^ do
                  if (edge_kind = real_edge) or
                    (edge_data_ptr^.surface_visibility = silhouette_edge) then
                    begin
                      Set_z_line_color(renderable, edge_color);
                      Render_visible_line(renderable, vertex_ptr1, vertex_ptr2);
                    end
                  else if (edge_kind = pseudo_edge) then
                    begin
                      Set_z_line_color(renderable, pseudo_edge_color);
                      Render_visible_line(renderable, vertex_ptr1, vertex_ptr2);
                    end;
                directed_edge_ptr := directed_edge_ptr^.next;
              end; {while}
            cycle_ptr := cycle_ptr^.next;
          end; {while}
      end;

    all_edges:
      begin
        {***********}
        { all edges }
        {***********}
        Set_z_line_color(renderable, edge_color);
        cycle_ptr := face_ptr^.cycle_ptr;
        while (cycle_ptr <> nil) do
          begin
            directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
            while (directed_edge_ptr <> nil) do
              begin
                with directed_edge_ptr^.edge_ptr^ do
                  Render_visible_line(renderable, vertex_ptr1, vertex_ptr2);
                directed_edge_ptr := directed_edge_ptr^.next;
              end;
            cycle_ptr := cycle_ptr^.next;
          end; {while}
      end;

  end; {case}
end; {procedure Draw_visible_face_edges}


{****************************************}
{ routines to draw the appropriate non-  }
{ silhouette edges for a given edge mode }
{****************************************}


procedure Draw_face_mask(renderable: polygon_renderable_type;
  face_ptr: face_ptr_type);
var
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
  edge_ptr: edge_ptr_type;
begin
  {***********************}
  { draw edges of polygon }
  {***********************}
  case attributes.edge_mode of

    silhouette_edges:
      begin
        {******************}
        { silhouette edges }
        {******************}
        Set_z_line_color(renderable, edge_color);
        cycle_ptr := face_ptr^.cycle_ptr;
        while (cycle_ptr <> nil) do
          begin
            directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
            while (directed_edge_ptr <> nil) do
              begin
                edge_data_ptr :=
                  Get_edge_data(directed_edge_ptr^.edge_ptr^.index);
                if edge_data_ptr^.surface_visibility <> silhouette_edge then
                  with directed_edge_ptr^.edge_ptr^ do
                    if (edge_kind = real_edge) then
                      Render_line(renderable, vertex_ptr1, vertex_ptr2);
                directed_edge_ptr := directed_edge_ptr^.next;
              end; {while}
            cycle_ptr := cycle_ptr^.next;
          end; {while}
      end;

    outline_edges:
      begin
        {***************}
        { outline edges }
        {***************}
        cycle_ptr := face_ptr^.cycle_ptr;
        while (cycle_ptr <> nil) do
          begin
            directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
            while (directed_edge_ptr <> nil) do
              begin
                edge_ptr := directed_edge_ptr^.edge_ptr;
                if (edge_ptr^.edge_kind = duplicate_edge) then
                  edge_ptr := edge_ptr^.duplicate_edge_ptr;

                edge_data_ptr := Get_edge_data(edge_ptr^.index);
                if edge_data_ptr^.surface_visibility <> silhouette_edge then
                  with edge_ptr^ do
                    if (edge_kind = real_edge) then
                      begin
                        Set_z_line_color(renderable, edge_color);
                        Render_line(renderable, vertex_ptr1, vertex_ptr2);
                      end
                    else if (edge_kind = pseudo_edge) then
                      begin
                        Set_z_line_color(renderable, pseudo_edge_color);
                        Render_line(renderable, vertex_ptr1, vertex_ptr2);
                      end;
                directed_edge_ptr := directed_edge_ptr^.next;
              end; {while}
            cycle_ptr := cycle_ptr^.next;
          end; {while}
      end;

    all_edges:
      begin
        {***********}
        { all edges }
        {***********}
        Set_z_line_color(renderable, edge_color);
        cycle_ptr := face_ptr^.cycle_ptr;
        while (cycle_ptr <> nil) do
          begin
            directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
            while (directed_edge_ptr <> nil) do
              begin
                with directed_edge_ptr^.edge_ptr^ do
                  Render_line(renderable, vertex_ptr1, vertex_ptr2);
                directed_edge_ptr := directed_edge_ptr^.next;
              end;
            cycle_ptr := cycle_ptr^.next;
          end; {while}
      end;

  end; {case}
end; {procedure Draw_face_mask}


procedure Draw_visible_face_mask(renderable: polygon_renderable_type;
  face_ptr: face_ptr_type);
var
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
  edge_ptr: edge_ptr_type;
begin
  {***********************}
  { draw edges of polygon }
  {***********************}
  case attributes.edge_mode of

    silhouette_edges:
      begin
        {******************}
        { silhouette edges }
        {******************}
        Set_z_line_color(renderable, edge_color);
        cycle_ptr := face_ptr^.cycle_ptr;
        while (cycle_ptr <> nil) do
          begin
            directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
            while (directed_edge_ptr <> nil) do
              begin
                edge_data_ptr :=
                  Get_edge_data(directed_edge_ptr^.edge_ptr^.index);
                if edge_data_ptr^.surface_visibility <> silhouette_edge then
                  with directed_edge_ptr^.edge_ptr^ do
                    if (edge_kind = real_edge) then
                      Render_visible_line(renderable, vertex_ptr1, vertex_ptr2);
                directed_edge_ptr := directed_edge_ptr^.next;
              end; {while}
            cycle_ptr := cycle_ptr^.next;
          end; {while}
      end;

    outline_edges:
      begin
        {***************}
        { outline edges }
        {***************}
        cycle_ptr := face_ptr^.cycle_ptr;
        while (cycle_ptr <> nil) do
          begin
            directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
            while (directed_edge_ptr <> nil) do
              begin
                edge_ptr := directed_edge_ptr^.edge_ptr;
                if (edge_ptr^.edge_kind = duplicate_edge) then
                  edge_ptr := edge_ptr^.duplicate_edge_ptr;

                edge_data_ptr := Get_edge_data(edge_ptr^.index);
                if edge_data_ptr^.surface_visibility <> silhouette_edge then
                  with edge_ptr^ do
                    if (edge_kind = real_edge) then
                      begin
                        Set_z_line_color(renderable, edge_color);
                        Render_visible_line(renderable, vertex_ptr1, vertex_ptr2);
                      end
                    else if (edge_kind = pseudo_edge) then
                      begin
                        Set_z_line_color(renderable, pseudo_edge_color);
                        Render_visible_line(renderable, vertex_ptr1, vertex_ptr2);
                      end;
                directed_edge_ptr := directed_edge_ptr^.next;
              end; {while}
            cycle_ptr := cycle_ptr^.next;
          end; {while}
      end;

    all_edges:
      begin
        {***********}
        { all edges }
        {***********}
        Set_z_line_color(renderable, edge_color);
        cycle_ptr := face_ptr^.cycle_ptr;
        while (cycle_ptr <> nil) do
          begin
            directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
            while (directed_edge_ptr <> nil) do
              begin
                with directed_edge_ptr^.edge_ptr^ do
                  Render_visible_line(renderable, vertex_ptr1, vertex_ptr2);
                directed_edge_ptr := directed_edge_ptr^.next;
              end;
            cycle_ptr := cycle_ptr^.next;
          end; {while}
      end;

  end; {case}
end; {procedure Draw_visible_face_mask}


{****************************************}
{ routines to the appropriate            }
{ silhouette edges for a given edge mode }
{****************************************}


procedure Draw_face_silhouette(renderable: line_renderable_type;
  face_ptr: face_ptr_type);
var
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
  edge_ptr: edge_ptr_type;
begin
  {**********************************}
  { draw silhouette edges of polygon }
  {**********************************}
  if (attributes.edge_mode <> all_edges) then
    begin
      Set_z_line_color(renderable, edge_color);
      cycle_ptr := face_ptr^.cycle_ptr;
      while (cycle_ptr <> nil) do
        begin
          directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
          while (directed_edge_ptr <> nil) do
            begin
              edge_ptr := directed_edge_ptr^.edge_ptr;
              if (edge_ptr^.edge_kind = duplicate_edge) then
                edge_ptr := edge_ptr^.duplicate_edge_ptr;

              edge_data_ptr := Get_edge_data(edge_ptr^.index);
              if edge_data_ptr^.surface_visibility = silhouette_edge then
                with edge_ptr^ do
                  Render_thick_line(renderable, vertex_ptr1, vertex_ptr2, 1.0);

              directed_edge_ptr := directed_edge_ptr^.next;
            end; {while}
          cycle_ptr := cycle_ptr^.next;
        end; {while}
    end;
end; {procedure Draw_face_silhouette}


procedure Draw_visible_face_silhouette(renderable: line_renderable_type;
  face_ptr: face_ptr_type);
var
  cycle_ptr: cycle_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
  edge_ptr: edge_ptr_type;
begin
  {**********************************}
  { draw silhouette edges of polygon }
  {**********************************}
  if attributes.edge_mode <> all_edges then
    begin
      Set_z_line_color(renderable, edge_color);
      cycle_ptr := face_ptr^.cycle_ptr;
      while (cycle_ptr <> nil) do
        begin
          directed_edge_ptr := cycle_ptr^.directed_edge_ptr;
          while (directed_edge_ptr <> nil) do
            begin
              edge_ptr := directed_edge_ptr^.edge_ptr;
              if (edge_ptr^.edge_kind = duplicate_edge) then
                edge_ptr := edge_ptr^.duplicate_edge_ptr;

              edge_data_ptr := Get_edge_data(edge_ptr^.index);
              if edge_data_ptr^.surface_visibility = silhouette_edge then
                with edge_ptr^ do
                  Render_visible_thick_line(renderable, vertex_ptr1, vertex_ptr2, 1.0);

              directed_edge_ptr := directed_edge_ptr^.next;
            end; {while}
          cycle_ptr := cycle_ptr^.next;
        end; {while}
    end;
end; {procedure Draw_visible_face_silhouette}


end.
