unit wireframe;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             wireframe                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module draws a wireframe rendering of objects      }
{       from the viewing data structs.                          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  colors, trans, state_vars, b_rep, drawable;


procedure Wireframe_surface(drawable: drawable_type;
  surface_ptr: surface_ptr_type;
  edge_orientation: edge_orientation_type;
  trans: trans_type;
  color: color_type;
  clipping: boolean);


implementation
uses
  topology, xform_b_rep, show_lines, meshes;


procedure Wireframe_b_rep(drawable: drawable_type;
  surface_ptr: surface_ptr_type);
var
  edge_ptr: edge_ptr_type;
  point_ptr: point_ptr_type;
  point_data_ptr1, point_data_ptr2: point_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
begin
  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  if (edge_ptr <> nil) then
    begin
      {************}
      { draw edges }
      {************}
      while (edge_ptr <> nil) do
        begin
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
end; {procedure Wireframe_b_rep}


procedure Wireframe_front_b_rep(drawable: drawable_type;
  surface_ptr: surface_ptr_type);
var
  edge_ptr: edge_ptr_type;
  point_ptr: point_ptr_type;
  point_data_ptr1, point_data_ptr2: point_data_ptr_type;
  point_data_ptr: point_data_ptr_type;
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
end; {procedure Wireframe_front_b_rep}


procedure Wireframe_visible_b_rep(drawable: drawable_type;
  surface_ptr: surface_ptr_type);
var
  edge_ptr: edge_ptr_type;
  point_ptr: point_ptr_type;
  point_data_ptr: point_data_ptr_type;
  point_data_ptr1, point_data_ptr2: point_data_ptr_type;
begin
  {*************************************}
  { project eye coords to screen coords }
  {*************************************}
  Project_points_to_pixels;

  edge_ptr := surface_ptr^.topology_ptr^.edge_ptr;
  if (edge_ptr <> nil) then
    begin
      {************}
      { draw edges }
      {************}
      while (edge_ptr <> nil) do
        begin
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
end; {procedure Wireframe_visible_b_rep}


procedure Wireframe_visible_front_b_rep(drawable: drawable_type;
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
  Project_points_to_pixels;

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
end; {procedure Wireframe_visible_front_b_rep}


procedure Wireframe_surface(drawable: drawable_type;
  surface_ptr: surface_ptr_type;
  edge_orientation: edge_orientation_type;
  trans: trans_type;
  color: color_type;
  clipping: boolean);
begin
  Set_line_color(drawable, color);

  case edge_orientation of

    full_edges:
      begin
        {***************************}
        { bind geometry to topology }
        {***************************}
        Bind_point_geometry(surface_ptr, surface_ptr^.geometry_ptr);

        {********************************}
        { init auxilliary rendering data }
        {********************************}
        Init_point_data(surface_ptr);

        {**************************************}
        { transform local coords to eye coords }
        {**************************************}
        Transform_point_geometry(trans);

        {*********************************************}
        { traverse b rep structure and draw all edges }
        {*********************************************}
        if clipping then
          Wireframe_b_rep(drawable, surface_ptr)
        else
          Wireframe_visible_b_rep(drawable, surface_ptr);
      end;

    front_edges:
      begin
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
        Transform_point_geometry(trans);

        {***********************************************}
        { traverse b rep structure and draw front edges }
        {***********************************************}
        if clipping then
          Wireframe_front_b_rep(drawable, surface_ptr)
        else
          Wireframe_visible_front_b_rep(drawable, surface_ptr);
      end;

  end; {case}
end; {procedure Wireframe_surface}


end.

