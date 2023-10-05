unit outline;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm              outline                  3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module draws an outline rendering of objects       }
{       from the viewing data structs.                          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  colors, trans, b_rep, state_vars, drawable;


procedure Outline_surface(drawable: drawable_type;
  surface_ptr: surface_ptr_type;
  edge_orientation: edge_orientation_type;
  outline_kind: outline_kind_type;
  trans: trans_type;
  color: color_type;
  clipping: boolean);


implementation
uses
  geometry, topology, xform_b_rep, project, show_lines, meshes;


var
  weak_edge_color, bold_edge_color: color_type;


procedure Transform_outline_geometry(surface_ptr: surface_ptr_type;
  trans: trans_type);
var
  point_ptr: point_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  if (surface_ptr^.topology_ptr^.perimeter_vertices) then
    begin
      {**********************}
      { transform all points }
      {**********************}
      Transform_point_geometry(trans);
    end
  else
    begin
      {***********************************************}
      { transform only those points which belong to   }
      { real or pseudo edges or to silhouette edges.  }
      {***********************************************}
      point_ptr := surface_ptr^.topology_ptr^.point_ptr;
      while (point_ptr <> nil) do
        begin
          point_data_ptr := Get_point_data(point_ptr^.index);
          if point_ptr^.real_point or point_ptr^.pseudo_point or
            (point_data_ptr^.surface_visibility = silhouette_edge) then
            Transform_point(point_data_ptr^.trans_point, trans);
          point_ptr := point_ptr^.next;
        end;
    end;
end; {procedure Transform_outline_geometry}


procedure Project_outline_geometry(surface_ptr: surface_ptr_type);
var
  point_ptr: point_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  if (surface_ptr^.topology_ptr^.perimeter_vertices) then
    begin
      {********************}
      { project all points }
      {********************}
      Project_points_to_pixels;
    end
  else
    begin
      {***********************************************}
      { transform only those points which belong to   }
      { real edges, pseudo edges or silhouette edges. }
      {***********************************************}
      point_ptr := surface_ptr^.topology_ptr^.point_ptr;
      while (point_ptr <> nil) do
        begin
          point_data_ptr := Get_point_data(point_ptr^.index);
          if point_ptr^.real_point or point_ptr^.pseudo_point or
            (point_data_ptr^.surface_visibility = silhouette_edge) then
            with point_data_ptr^ do
              pixel := Project_point_to_pixel(trans_point);
          point_ptr := point_ptr^.next;
        end;
    end;
end; {procedure Project_outline_geometry}


procedure Outline_b_rep(drawable: drawable_type;
  surface_ptr: surface_ptr_type;
  outline_kind: outline_kind_type);
var
  edge_ptr: edge_ptr_type;
  point_ptr: point_ptr_type;
  point_data_ptr: point_data_ptr_type;
  point_data_ptr1, point_data_ptr2: point_data_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
  {******************************************************}
  { draw both front and back outline edges same strength }
  {******************************************************}
  case outline_kind of
    weak_outline:
      Set_line_color(drawable, weak_edge_color);
    bold_outline:
      Set_line_color(drawable, bold_edge_color);
  end;

  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  while (edge_ptr <> nil) do
    begin
      edge_data_ptr := Get_edge_data(edge_ptr^.index);
      if (edge_ptr^.edge_kind = pseudo_edge) then
        if (edge_data_ptr^.surface_visibility <> silhouette_edge) then
          begin
            point_data_ptr1 := Get_point_data(edge_ptr^.point_ptr1^.index);
            point_data_ptr2 := Get_point_data(edge_ptr^.point_ptr2^.index);
            Show_b_rep_line(drawable, point_data_ptr1, point_data_ptr2);
          end;
      edge_ptr := edge_ptr^.next;
    end;

  {********************************}
  { draw real and silhouette edges }
  {********************************}
  Set_line_color(drawable, bold_edge_color);
  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  if (edge_ptr <> nil) then
    begin
      {************}
      { draw edges }
      {************}
      while (edge_ptr <> nil) do
        begin
          edge_data_ptr := Get_edge_data(edge_ptr^.index);
          if (edge_ptr^.edge_kind = real_edge) or
            (edge_data_ptr^.surface_visibility = silhouette_edge) then
            if (edge_ptr^.edge_kind <> duplicate_edge) then
              begin
                point_data_ptr1 := Get_point_data(edge_ptr^.point_ptr1^.index);
                point_data_ptr2 := Get_point_data(edge_ptr^.point_ptr2^.index);
                Show_b_rep_line(drawable, point_data_ptr1, point_data_ptr2);
              end;
          edge_ptr := edge_ptr^.next;
        end;
    end
  else
    begin
      {***************}
      { draw vertices }
      {***************}
      point_ptr := surface_ptr^.topology_ptr^.point_ptr;
      while (point_ptr <> nil) do
        begin
          point_data_ptr := Get_point_data(point_ptr^.index);
          Show_point(drawable, point_data_ptr^.trans_point);
          point_ptr := point_ptr^.next;
        end;
    end;
end; {procedure Outline_b_rep}


procedure Outline_front_b_rep(drawable: drawable_type;
  surface_ptr: surface_ptr_type;
  outline_kind: outline_kind_type);
var
  edge_ptr: edge_ptr_type;
  point_ptr: point_ptr_type;
  point_data_ptr: point_data_ptr_type;
  point_data_ptr1, point_data_ptr2: point_data_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
  {*****************************************************}
  { draw front and back outlines in different strengths }
  {*****************************************************}

  {*******************}
  { draw back outline }
  {*******************}
  if outline_kind <> weak_outline then
    begin
      Set_line_color(drawable, weak_edge_color);
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      while (edge_ptr <> nil) do
        begin
          edge_data_ptr := Get_edge_data(edge_ptr^.index);
          if (edge_data_ptr^.surface_visibility = back_facing) then
            if (edge_ptr^.edge_kind in [pseudo_edge, real_edge]) then
              begin
                point_data_ptr1 := Get_point_data(edge_ptr^.point_ptr1^.index);
                point_data_ptr2 := Get_point_data(edge_ptr^.point_ptr2^.index);
                Show_b_rep_line(drawable, point_data_ptr1, point_data_ptr2);
              end;
          edge_ptr := edge_ptr^.next;
        end;
    end;

  {********************}
  { draw front outline }
  {********************}
  case outline_kind of
    weak_outline:
      Set_line_color(drawable, weak_edge_color);
    bold_outline:
      Set_line_color(drawable, bold_edge_color);
  end;

  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  while (edge_ptr <> nil) do
    begin
      edge_data_ptr := Get_edge_data(edge_ptr^.index);
      if (edge_data_ptr^.surface_visibility = front_facing) then
        if (edge_ptr^.edge_kind = pseudo_edge) then
          begin
            point_data_ptr1 := Get_point_data(edge_ptr^.point_ptr1^.index);
            point_data_ptr2 := Get_point_data(edge_ptr^.point_ptr2^.index);
            Show_b_rep_line(drawable, point_data_ptr1, point_data_ptr2);
          end;
      edge_ptr := edge_ptr^.next;
    end;

  {********************************}
  { draw real and silhouette edges }
  {********************************}
  Set_line_color(drawable, bold_edge_color);
  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  if (edge_ptr <> nil) then
    begin
      {************}
      { draw edges }
      {************}
      while (edge_ptr <> nil) do
        begin
          edge_data_ptr := Get_edge_data(edge_ptr^.index);
          if (edge_data_ptr^.surface_visibility <> back_facing) then
            if (edge_ptr^.edge_kind = real_edge) or
              (edge_data_ptr^.surface_visibility = silhouette_edge) then
              if (edge_ptr^.edge_kind <> duplicate_edge) then
                begin
                  point_data_ptr1 :=
                    Get_point_data(edge_ptr^.point_ptr1^.index);
                  point_data_ptr2 :=
                    Get_point_data(edge_ptr^.point_ptr2^.index);
                  Show_b_rep_line(drawable, point_data_ptr1, point_data_ptr2);
                end;
          edge_ptr := edge_ptr^.next;
        end;
    end
  else
    begin
      {***************}
      { draw vertices }
      {***************}
      point_ptr := surface_ptr^.topology_ptr^.point_ptr;
      while (point_ptr <> nil) do
        begin
          point_data_ptr := Get_point_data(point_ptr^.index);
          Show_point(drawable, point_data_ptr^.trans_point);
          point_ptr := point_ptr^.next;
        end;
    end;
end; {procedure Outline_front_b_rep}


procedure Outline_visible_b_rep(drawable: drawable_type;
  surface_ptr: surface_ptr_type;
  outline_kind: outline_kind_type);
var
  edge_ptr: edge_ptr_type;
  point_ptr: point_ptr_type;
  point_data_ptr: point_data_ptr_type;
  point_data_ptr1, point_data_ptr2: point_data_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
  {*************************************}
  { project eye coords to screen coords }
  {*************************************}
  Project_outline_geometry(surface_ptr);

  {******************************************************}
  { draw both front and back outline edges same strength }
  {******************************************************}
  case outline_kind of
    weak_outline:
      Set_line_color(drawable, weak_edge_color);
    bold_outline:
      Set_line_color(drawable, bold_edge_color);
  end;

  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  while (edge_ptr <> nil) do
    begin
      edge_data_ptr := Get_edge_data(edge_ptr^.index);
      if (edge_ptr^.edge_kind = pseudo_edge) then
        if (edge_data_ptr^.surface_visibility <> silhouette_edge) then
          begin
            point_data_ptr1 := Get_point_data(edge_ptr^.point_ptr1^.index);
            point_data_ptr2 := Get_point_data(edge_ptr^.point_ptr2^.index);
            drawable.Draw_line(point_data_ptr1^.pixel, point_data_ptr2^.pixel);
          end;
      edge_ptr := edge_ptr^.next;
    end;

  {********************************}
  { draw real and silhouette edges }
  {********************************}
  Set_line_color(drawable, bold_edge_color);
  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  if (edge_ptr <> nil) then
    begin
      {************}
      { draw edges }
      {************}
      while (edge_ptr <> nil) do
        begin
          edge_data_ptr := Get_edge_data(edge_ptr^.index);
          if (edge_ptr^.edge_kind = real_edge) or
            (edge_data_ptr^.surface_visibility = silhouette_edge) then
            if (edge_ptr^.edge_kind <> duplicate_edge) then
              begin
                point_data_ptr1 := Get_point_data(edge_ptr^.point_ptr1^.index);
                point_data_ptr2 := Get_point_data(edge_ptr^.point_ptr2^.index);
                drawable.Draw_line(point_data_ptr1^.pixel,
                  point_data_ptr2^.pixel);
              end;
          edge_ptr := edge_ptr^.next;
        end;
    end
  else
    begin
      {***************}
      { draw vertices }
      {***************}
      point_ptr := surface_ptr^.topology_ptr^.point_ptr;
      while (point_ptr <> nil) do
        begin
          point_data_ptr := Get_point_data(point_ptr^.index);
          drawable.Draw_pixel(point_data_ptr^.pixel);
          point_ptr := point_ptr^.next;
        end;
    end;
end; {procedure Outline_visible_b_rep}


procedure Outline_visible_front_b_rep(drawable: drawable_type;
  surface_ptr: surface_ptr_type;
  outline_kind: outline_kind_type);
var
  edge_ptr: edge_ptr_type;
  point_ptr: point_ptr_type;
  point_data_ptr: point_data_ptr_type;
  point_data_ptr1, point_data_ptr2: point_data_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
  {*************************************}
  { project eye coords to screen coords }
  {*************************************}
  Project_outline_geometry(surface_ptr);

  {*****************************************************}
  { draw front and back outlines in different strengths }
  {*****************************************************}

  {*******************}
  { draw back outline }
  {*******************}
  if outline_kind <> weak_outline then
    begin
      Set_line_color(drawable, weak_edge_color);
      edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
      while (edge_ptr <> nil) do
        begin
          edge_data_ptr := Get_edge_data(edge_ptr^.index);
          if (edge_data_ptr^.surface_visibility = back_facing) then
            if (edge_ptr^.edge_kind in [pseudo_edge, real_edge]) then
              begin
                point_data_ptr1 := Get_point_data(edge_ptr^.point_ptr1^.index);
                point_data_ptr2 := Get_point_data(edge_ptr^.point_ptr2^.index);
                drawable.Draw_line(point_data_ptr1^.pixel,
                  point_data_ptr2^.pixel);
              end;
          edge_ptr := edge_ptr^.next;
        end;
    end;

  {********************}
  { draw front outline }
  {********************}
  case outline_kind of
    weak_outline:
      Set_line_color(drawable, weak_edge_color);
    bold_outline:
      Set_line_color(drawable, bold_edge_color);
  end;

  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  while (edge_ptr <> nil) do
    begin
      edge_data_ptr := Get_edge_data(edge_ptr^.index);
      if (edge_data_ptr^.surface_visibility = front_facing) then
        if (edge_ptr^.edge_kind = pseudo_edge) then
          begin
            point_data_ptr1 := Get_point_data(edge_ptr^.point_ptr1^.index);
            point_data_ptr2 := Get_point_data(edge_ptr^.point_ptr2^.index);
            drawable.Draw_line(point_data_ptr1^.pixel, point_data_ptr2^.pixel);
          end;
      edge_ptr := edge_ptr^.next;
    end;

  {********************************}
  { draw real and silhouette edges }
  {********************************}
  Set_line_color(drawable, bold_edge_color);
  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  if (edge_ptr <> nil) then
    begin
      {************}
      { draw edges }
      {************}
      while (edge_ptr <> nil) do
        begin
          edge_data_ptr := Get_edge_data(edge_ptr^.index);
          if (edge_data_ptr^.surface_visibility <> back_facing) then
            if (edge_ptr^.edge_kind = real_edge) or
              (edge_data_ptr^.surface_visibility = silhouette_edge) then
              if (edge_ptr^.edge_kind <> duplicate_edge) then
                begin
                  point_data_ptr1 :=
                    Get_point_data(edge_ptr^.point_ptr1^.index);
                  point_data_ptr2 :=
                    Get_point_data(edge_ptr^.point_ptr2^.index);
                  drawable.Draw_line(point_data_ptr1^.pixel,
                    point_data_ptr2^.pixel);
                end;
          edge_ptr := edge_ptr^.next;
        end;
    end
  else
    begin
      {***************}
      { draw vertices }
      {***************}
      point_ptr := surface_ptr^.topology_ptr^.point_ptr;
      while (point_ptr <> nil) do
        begin
          point_data_ptr := Get_point_data(point_ptr^.index);
          drawable.Draw_pixel(point_data_ptr^.pixel);
          point_ptr := point_ptr^.next;
        end;
    end;
end; {procedure Outline_visible_front_b_rep}


procedure Outline_surface(drawable: drawable_type;
  surface_ptr: surface_ptr_type;
  edge_orientation: edge_orientation_type;
  outline_kind: outline_kind_type;
  trans: trans_type;
  color: color_type;
  clipping: boolean);
begin
  bold_edge_color := color;
  weak_edge_color := Intensify_color(Mix_color(color, background_color), 0.5);

  {***************************}
  { bind geometry to topology }
  {***************************}
  Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);
  Bind_face_geometry(surface_ptr, surface_ptr^.geometry_ptr);

  {********************************}
  { init auxilliary rendering data }
  {********************************}
  Init_point_data(surface_ptr);
  Init_edge_data(surface_ptr);
  Init_face_data(surface_ptr);

  {***********************}
  { compute mesh geometry }
  {***********************}
  if not surface_ptr^.geometry_ptr^.geometry_info.face_normals_avail then
    Find_mesh_face_normals(surface_ptr);

  {*********************************}
  { find silhouette in local coords }
  {*********************************}
  Find_face_visibility(surface_ptr, trans);
  Find_silhouette(surface_ptr);

  {**************************************}
  { transform local coords to eye coords }
  {**************************************}
  Transform_outline_geometry(surface_ptr, trans);

  case edge_orientation of

    full_edges:
      begin
        {*************************************************}
        { traverse b rep structure and draw outline edges }
        {*************************************************}
        if clipping then
          Outline_b_rep(drawable, surface_ptr, outline_kind)
        else
          Outline_visible_b_rep(drawable, surface_ptr, outline_kind);
      end;

    front_edges:
      begin
        {*******************************************************}
        { traverse b rep structure and draw front outline edges }
        {*******************************************************}
        if clipping then
          Outline_front_b_rep(drawable, surface_ptr, outline_kind)
        else
          Outline_visible_front_b_rep(drawable, surface_ptr, outline_kind);
      end;
  end; {case}
end; {procedure Outline_surface}


end.

