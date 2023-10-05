unit silhouette;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             silhouette                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module draws a silhouette rendering of objects     }
{       from the viewing data structs.                          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  colors, trans, b_rep, state_vars, drawable;


procedure Silhouette_surface(drawable: drawable_type;
  surface_ptr: surface_ptr_type;
  edge_orientation: edge_orientation_type;
  trans: trans_type;
  color: color_type;
  clipping: boolean);


implementation
uses
  geometry, topology, xform_b_rep, project, show_lines, meshes;


procedure Transform_silhouette_geometry(surface_ptr: surface_ptr_type;
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
      {*************************************}
      { transform only those points which   }
      { belong to real or silhouette edges. }
      {*************************************}
      point_ptr := surface_ptr^.topology_ptr^.point_ptr;
      while (point_ptr <> nil) do
        begin
          point_data_ptr := Get_point_data(point_ptr^.index);
          if point_ptr^.real_point or (point_data_ptr^.surface_visibility =
            silhouette_edge) then
            Transform_point(point_data_ptr^.trans_point, trans);
          point_ptr := point_ptr^.next;
        end;
    end;
end; {procedure Transform_silhouette_geometry}


procedure Project_silhouette_geometry(surface_ptr: surface_ptr_type);
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
      {*************************************}
      { transform only those points which   }
      { belong to real or silhouette edges. }
      {*************************************}
      point_ptr := surface_ptr^.topology_ptr^.point_ptr;
      while (point_ptr <> nil) do
        begin
          point_data_ptr := Get_point_data(point_ptr^.index);
          if point_ptr^.real_point or (point_data_ptr^.surface_visibility =
            silhouette_edge) then
            with point_data_ptr^ do
              pixel := Project_point_to_pixel(trans_point);
          point_ptr := point_ptr^.next;
        end;
    end;
end; {procedure Project_silhouette_geometry}


procedure Silhouette_b_rep(drawable: drawable_type;
  surface_ptr: surface_ptr_type);
var
  edge_ptr: edge_ptr_type;
  point_ptr: point_ptr_type;
  point_data_ptr: point_data_ptr_type;
  point_data_ptr1, point_data_ptr2: point_data_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
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
end; {procedure Silhouette_b_rep}


procedure Silhouette_front_b_rep(drawable: drawable_type;
  surface_ptr: surface_ptr_type);
var
  edge_ptr: edge_ptr_type;
  point_ptr: point_ptr_type;
  point_data_ptr: point_data_ptr_type;
  point_data_ptr1, point_data_ptr2: point_data_ptr_type;
  edge_data_ptr: edge_data_ptr_type;
begin
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
end; {procedure Silhouette_front_b_rep}


procedure Silhouette_visible_b_rep(drawable: drawable_type;
  surface_ptr: surface_ptr_type);
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
  Project_silhouette_geometry(surface_ptr);

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
                drawable.Draw_line(point_data_ptr1^.pixel, point_data_ptr2^.pixel);
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
end; {procedure Silhouette_visible_b_rep}


procedure Silhouette_visible_front_b_rep(drawable: drawable_type;
  surface_ptr: surface_ptr_type);
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
  Project_silhouette_geometry(surface_ptr);

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
                  drawable.Draw_line(point_data_ptr1^.pixel, point_data_ptr2^.pixel);
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
end; {procedure Silhouette_visible_front_b_rep}


procedure Silhouette_surface(drawable: drawable_type;
  surface_ptr: surface_ptr_type;
  edge_orientation: edge_orientation_type;
  trans: trans_type;
  color: color_type;
  clipping: boolean);
begin
  Set_line_color(drawable, color);

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
  Transform_silhouette_geometry(surface_ptr, trans);

  case edge_orientation of

    full_edges:
      begin
        {****************************************************}
        { traverse b rep structure and draw silhouette edges }
        {****************************************************}
        if clipping then
          Silhouette_b_rep(drawable, surface_ptr)
        else
          Silhouette_visible_b_rep(drawable, surface_ptr);
      end;

    front_edges:
      begin
        {**********************************************************}
        { traverse b rep structure and draw front silhouette edges }
        {**********************************************************}
        if clipping then
          Silhouette_front_b_rep(drawable, surface_ptr)
        else
          Silhouette_visible_front_b_rep(drawable, surface_ptr);
      end;
  end; {case}
end; {procedure Silhouette_surface}


end.
