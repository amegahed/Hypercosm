unit mesh_tracer;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            mesh_tracer                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The mesh_tracer module is used to traverse the          }
{       spatial database used for raytracing of meshes and      }
{       find the face intersected.                              }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, rays, trans, raytrace;


{**************************************************}
{ The first two intersection tests work for meshes }
{ with non-coplanar polygons. To perform the inter }
{ section test, we must transform the polygons to  }
{ the coordinates of the ray and perform the inter }
{ section test from the viewpoint of the ray.      }
{**************************************************}
function Mesh_intersection(ray: ray_type;
  tmin, tmax: real;
  mesh_voxel_ptr: mesh_voxel_ptr_type;
  var normal: vector_type;
  var texture_interpolation: interpolation_type): real;
function Smooth_mesh_intersection(ray: ray_type;
  tmin, tmax: real;
  mesh_voxel_ptr: mesh_voxel_ptr_type;
  var normal_interpolation: interpolation_type;
  var texture_interpolation: interpolation_type): real;

{**************************************************}
{ This intersection test is faster but can only be }
{ used w/ meshes which have only coplanar polygons }
{**************************************************}
function Fast_mesh_intersection(ray: ray_type;
  tmin, tmax: real;
  mesh_voxel_ptr: mesh_voxel_ptr_type): real;


implementation
uses
  constants, coord_axes, extents, topology;


function Leaf_voxel(mesh_voxel_ptr: mesh_voxel_ptr_type;
  point: vector_type): mesh_voxel_ptr_type;
var
  center: vector_type;
  length, width, height: extent_type;
begin
  {*********************************************}
  { find the leaf subvoxel containing the point }
  {*********************************************}
  while (mesh_voxel_ptr^.subdivided) do
    begin
      center := Extent_box_center(mesh_voxel_ptr^.extent_box);
      if (point.x < center.x) then
        length := left
      else
        length := right;
      if (point.y < center.y) then
        width := front
      else
        width := back;
      if (point.z < center.z) then
        height := bottom
      else
        height := top;
      mesh_voxel_ptr := mesh_voxel_ptr^.subvoxel_ptr[length, width, height];
    end;
  Leaf_voxel := mesh_voxel_ptr;
end; {function Leaf_voxel}


function Next_voxel(mesh_voxel_ptr: mesh_voxel_ptr_type;
  ray: ray_type): mesh_voxel_ptr_type;
var
  t, new_t: real;
  next, temp: extent_type;
  point: vector_type;
begin
  t := infinity;
  next := left;

  if (ray.direction.x <> 0) then
    begin
      if (ray.direction.x < 0) then
        begin
          t := (mesh_voxel_ptr^.extent_box[left] - ray.location.x) /
            ray.direction.x;
          next := left;
        end
      else
        begin
          t := (mesh_voxel_ptr^.extent_box[right] - ray.location.x) /
            ray.direction.x;
          next := right;
        end;
    end;

  if (ray.direction.y <> 0) then
    begin
      if (ray.direction.y < 0) then
        begin
          new_t := (mesh_voxel_ptr^.extent_box[front] - ray.location.y) /
            ray.direction.y;
          temp := front;
        end
      else
        begin
          new_t := (mesh_voxel_ptr^.extent_box[back] - ray.location.y) /
            ray.direction.y;
          temp := back;
        end;
      if (new_t < t) then
        begin
          t := new_t;
          next := temp;
        end;
    end;

  if (ray.direction.z <> 0) then
    begin
      if (ray.direction.z < 0) then
        begin
          new_t := (mesh_voxel_ptr^.extent_box[bottom] - ray.location.z) /
            ray.direction.z;
          temp := bottom;
        end
      else
        begin
          new_t := (mesh_voxel_ptr^.extent_box[top] - ray.location.z) /
            ray.direction.z;
          temp := top;
        end;
      if (new_t < t) then
        begin
          t := new_t;
          next := temp;
        end;
    end;

  mesh_voxel_ptr := mesh_voxel_ptr^.neighbor_voxel_ptr[next];
  if (mesh_voxel_ptr <> nil) then
    if (mesh_voxel_ptr^.subdivided) then
      begin
        point := Vector_sum(ray.location, Vector_scale(ray.direction, t));
        mesh_voxel_ptr := Leaf_voxel(mesh_voxel_ptr, point);
      end;

  Next_voxel := mesh_voxel_ptr;
end; {procedure Next_voxel}


function Voxel_intersection(ray: ray_type;
  var point: vector_type): real;
var
  t, new_t, extent: real;
  new_point: vector_type;
begin
  t := infinity;
  if (ray.direction.x <> 0) then
    begin
      if (ray.direction.x < 0) then
        extent := 1
      else
        extent := -1;
      new_t := (extent - ray.location.x) / ray.direction.x;
      if (new_t < t) and (new_t >= 0) then
        begin
          new_point.y := ray.location.y + ray.direction.y * new_t;
          if (abs(new_point.y) <= 1) then
            begin
              new_point.z := ray.location.z + ray.direction.z * new_t;
              if (abs(new_point.z) <= 1) then
                begin
                  t := new_t;
                  point.x := extent;
                  point.y := new_point.y;
                  point.z := new_point.z;
                end;
            end;
        end;
    end; {x}

  if (ray.direction.y <> 0) then
    begin
      if (ray.direction.y < 0) then
        extent := 1
      else
        extent := -1;
      new_t := (extent - ray.location.y) / ray.direction.y;
      if (new_t < t) and (new_t >= 0) then
        begin
          new_point.x := ray.location.x + ray.direction.x * new_t;
          if (abs(new_point.x) <= 1) then
            begin
              new_point.z := ray.location.z + ray.direction.z * new_t;
              if (abs(new_point.z) <= 1) then
                begin
                  t := new_t;
                  point.x := new_point.x;
                  point.y := extent;
                  point.z := new_point.z;
                end;
            end;
        end;
    end; {y}

  if (ray.direction.z <> 0) then
    begin
      if (ray.direction.z < 0) then
        extent := 1
      else
        extent := -1;
      new_t := (extent - ray.location.z) / ray.direction.z;
      if (new_t < t) and (new_t >= 0) then
        begin
          new_point.x := ray.location.x + ray.direction.x * new_t;
          if (abs(new_point.x) <= 1) then
            begin
              new_point.y := ray.location.y + ray.direction.y * new_t;
              if (abs(new_point.y) <= 1) then
                begin
                  t := new_t;
                  point.x := new_point.x;
                  point.y := new_point.y;
                  point.z := extent;
                end;
            end;
        end;
    end; {z}

  Voxel_intersection := t;
end; {function Voxel_intersection}


function Face_intersection(var coord_axes: coord_axes_type;
  var texture_interpolation: interpolation_type;
  face_ptr: face_ptr_type): real;
var
  directed_edge_ptr: directed_edge_ptr_type;
  first_vertex, vertex1, vertex2: vector_type;
  first_vertex_ptr, vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  follow: directed_edge_ptr_type;
  intersection: boolean;
  left, right: vector_type;
  count: integer;
  t, x: real;
begin
  right.x := infinity;
  left.x := -infinity;
  count := 0;
  directed_edge_ptr := face_ptr^.cycle_ptr^.directed_edge_ptr;
  with directed_edge_ptr^ do
    if orientation then
      begin
        vertex_ptr1 := edge_ptr^.vertex_ptr1;
        vertex1 := edge_ptr^.vertex_ptr1^.point_ptr^.point_geometry_ptr^.point;
      end
    else
      begin
        vertex_ptr1 := edge_ptr^.vertex_ptr2;
        vertex1 := edge_ptr^.vertex_ptr2^.point_ptr^.point_geometry_ptr^.point;
      end;
  Transform_point_to_axes(vertex1, coord_axes);
  first_vertex_ptr := vertex_ptr1;
  first_vertex := vertex1;

  {***********************}
  { point in polygon test }
  {***********************}
  follow := face_ptr^.cycle_ptr^.directed_edge_ptr;
  while (follow <> nil) do
    begin
      follow := follow^.next;
      if (follow <> nil) then
        begin
          with follow^ do
            if orientation then
              begin
                vertex_ptr2 := edge_ptr^.vertex_ptr1;
                vertex2 :=
                  edge_ptr^.vertex_ptr1^.point_ptr^.point_geometry_ptr^.point;
              end
            else
              begin
                vertex_ptr2 := edge_ptr^.vertex_ptr2;
                vertex2 :=
                  edge_ptr^.vertex_ptr2^.point_ptr^.point_geometry_ptr^.point;
              end;
          Transform_point_to_axes(vertex2, coord_axes);
        end
      else
        begin
          vertex_ptr2 := first_vertex_ptr;
          vertex2 := first_vertex;
        end;

      {*******************************************}
      { look for intersection with horizontal ray }
      {*******************************************}
      intersection := (vertex1.y < 0) and (vertex2.y > 0);
      if not intersection then
        intersection := (vertex1.y > 0) and (vertex2.y < 0);

      if intersection then
        begin
          {****************************}
          { compute intersection point }
          {****************************}
          t := vertex1.y / (vertex1.y - vertex2.y);
          x := vertex1.x + (vertex2.x - vertex1.x) * t;

          {******************}
          { increment parity }
          {******************}
          if x > tiny then
            count := count + 1;

          {******************************}
          { update left and right bounds }
          {******************************}
          if (x > 0) then
            begin
              if (x < right.x) then
                begin
                  right.x := x;
                  right.y := 0;
                  right.z := vertex1.z + (vertex2.z - vertex1.z) * t;

                  {***************************************************}
                  { save right edge texture interpolation information }
                  {***************************************************}
                  texture_interpolation.right_vector1 :=
                    vertex_ptr1^.vertex_geometry_ptr^.texture;
                  texture_interpolation.right_vector2 :=
                    vertex_ptr2^.vertex_geometry_ptr^.texture;
                  texture_interpolation.right_t := t;
                end;
            end
          else
            begin
              if (x > left.x) then
                begin
                  left.x := x;
                  left.y := 0;
                  left.z := vertex1.z + (vertex2.z - vertex1.z) * t;

                  {**************************************************}
                  { save left edge texture interpolation information }
                  {**************************************************}
                  texture_interpolation.left_vector1 :=
                    vertex_ptr1^.vertex_geometry_ptr^.texture;
                  texture_interpolation.left_vector2 :=
                    vertex_ptr2^.vertex_geometry_ptr^.texture;
                  texture_interpolation.left_t := t;
                end;
            end; {update bounds}
        end; {if intersection}

      {************************}
      { update previous vertex }
      {************************}
      vertex1 := vertex2;
      vertex_ptr1 := vertex_ptr2;
    end; {while}

  {****************************************}
  { if odd parity, then intersection found }
  {****************************************}
  if (count mod 2 = 1) then
    begin
      x := left.x / (left.x - right.x);

      {************************************}
      { save information on interpolating  }
      { between the right and left edges.  }
      {************************************}
      texture_interpolation.t := x;

      t := left.z + (right.z - left.z) * x;
      if (t < tiny) then
        t := infinity;
    end
  else
    t := infinity;

  Face_intersection := t;
end; {function Face_intersection}


function Smooth_face_intersection(var coord_axes: coord_axes_type;
  var normal_interpolation: interpolation_type;
  var texture_interpolation: interpolation_type;
  face_ptr: face_ptr_type): real;
var
  directed_edge_ptr: directed_edge_ptr_type;
  first_vertex, vertex1, vertex2: vector_type;
  first_vertex_ptr, vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  follow: directed_edge_ptr_type;
  intersection: boolean;
  left, right: vector_type;
  count: integer;
  t, x: real;
begin
  right.x := infinity;
  left.x := -infinity;
  count := 0;
  directed_edge_ptr := face_ptr^.cycle_ptr^.directed_edge_ptr;
  with directed_edge_ptr^ do
    if orientation then
      begin
        vertex_ptr1 := edge_ptr^.vertex_ptr1;
        vertex1 := edge_ptr^.vertex_ptr1^.point_ptr^.point_geometry_ptr^.point;
      end
    else
      begin
        vertex_ptr1 := edge_ptr^.vertex_ptr2;
        vertex1 := edge_ptr^.vertex_ptr2^.point_ptr^.point_geometry_ptr^.point;
      end;
  Transform_point_to_axes(vertex1, coord_axes);
  first_vertex_ptr := vertex_ptr1;
  first_vertex := vertex1;

  {***********************}
  { point in polygon test }
  {***********************}
  follow := face_ptr^.cycle_ptr^.directed_edge_ptr;
  while (follow <> nil) do
    begin
      follow := follow^.next;
      if (follow <> nil) then
        begin
          with follow^ do
            if orientation then
              begin
                vertex_ptr2 := edge_ptr^.vertex_ptr1;
                vertex2 :=
                  edge_ptr^.vertex_ptr1^.point_ptr^.point_geometry_ptr^.point;
              end
            else
              begin
                vertex_ptr2 := edge_ptr^.vertex_ptr2;
                vertex2 :=
                  edge_ptr^.vertex_ptr2^.point_ptr^.point_geometry_ptr^.point;
              end;
          Transform_point_to_axes(vertex2, coord_axes);
        end
      else
        begin
          vertex_ptr2 := first_vertex_ptr;
          vertex2 := first_vertex;
        end;

      {*******************************************}
      { look for intersection with horizontal ray }
      {*******************************************}
      intersection := (vertex1.y < 0) and (vertex2.y > 0);
      if not intersection then
        intersection := (vertex1.y > 0) and (vertex2.y < 0);

      if intersection then
        begin
          {****************************}
          { compute intersection point }
          {****************************}
          t := vertex1.y / (vertex1.y - vertex2.y);
          x := vertex1.x + (vertex2.x - vertex1.x) * t;

          {******************}
          { increment parity }
          {******************}
          if x > tiny then
            count := count + 1;

          {******************************}
          { update left and right bounds }
          {******************************}
          if (x > 0) then
            begin
              if (x < right.x) then
                begin
                  right.x := x;
                  right.y := 0;
                  right.z := vertex1.z + (vertex2.z - vertex1.z) * t;

                  {**************************************************}
                  { save right edge normal interpolation information }
                  {**************************************************}
                  normal_interpolation.right_vector1 :=
                    vertex_ptr1^.vertex_geometry_ptr^.normal;
                  normal_interpolation.right_vector2 :=
                    vertex_ptr2^.vertex_geometry_ptr^.normal;
                  normal_interpolation.right_t := t;

                  {***************************************************}
                  { save right edge texture interpolation information }
                  {***************************************************}
                  texture_interpolation.right_vector1 :=
                    vertex_ptr1^.vertex_geometry_ptr^.texture;
                  texture_interpolation.right_vector2 :=
                    vertex_ptr2^.vertex_geometry_ptr^.texture;
                  texture_interpolation.right_t := t;
                end;
            end
          else
            begin
              if (x > left.x) then
                begin
                  left.x := x;
                  left.y := 0;
                  left.z := vertex1.z + (vertex2.z - vertex1.z) * t;

                  {*************************************************}
                  { save left edge normal interpolation information }
                  {*************************************************}
                  normal_interpolation.left_vector1 :=
                    vertex_ptr1^.vertex_geometry_ptr^.normal;
                  normal_interpolation.left_vector2 :=
                    vertex_ptr2^.vertex_geometry_ptr^.normal;
                  normal_interpolation.left_t := t;

                  {**************************************************}
                  { save left edge texture interpolation information }
                  {**************************************************}
                  texture_interpolation.left_vector1 :=
                    vertex_ptr1^.vertex_geometry_ptr^.texture;
                  texture_interpolation.left_vector2 :=
                    vertex_ptr2^.vertex_geometry_ptr^.texture;
                  texture_interpolation.left_t := t;
                end;
            end; {update bounds}
        end; {if intersection}

      {************************}
      { update previous vertex }
      {************************}
      vertex1 := vertex2;
      vertex_ptr1 := vertex_ptr2;
    end; {while}

  {****************************************}
  { if odd parity, then intersection found }
  {****************************************}
  if (count mod 2 = 1) then
    begin
      x := left.x / (left.x - right.x);

      {************************************}
      { save information on interpolating  }
      { between the right and left edges.  }
      {************************************}
      normal_interpolation.t := x;
      texture_interpolation.t := x;

      t := left.z + (right.z - left.z) * x;
      if (t < tiny) then
        t := infinity;
    end
  else
    t := infinity;

  Smooth_face_intersection := t;
end; {function Smooth_face_intersection}


function Plane_intersection(ray: ray_type;
  origin, normal: vector_type): real;
var
  temp: real;
  t: real;
begin
  temp := Dot_product(ray.direction, normal);
  if (temp = 0) then
    t := infinity
  else
    begin
      t := Dot_product(Vector_difference(origin, ray.location), normal) / temp;
      if (t < tiny) then
        t := infinity;
    end;
  Plane_intersection := t;
end; {function Plane_intersection}


function Fast_face_intersection(ray: ray_type;
  face_ptr: face_ptr_type): real;
var
  intersection: vector_type;
  origin, normal: vector_type;
  vertex_ptr, first_vertex_ptr: vertex_ptr_type;
  vertex_ptr1, vertex_ptr2: vertex_ptr_type;
  directed_edge_ptr: directed_edge_ptr_type;
  x1, y1, x2, y2, x3, y3: real;
  edge_count: integer;
  test_count: integer;
  t, t2: real;
begin
  {********************************************}
  { first, find where the ray intersects the   }
  { plane of the polygon using the normal from }
  { the b rep.                                 }
  {********************************************}
  vertex_ptr := face_ptr^.cycle_ptr^.directed_edge_ptr^.edge_ptr^.vertex_ptr1;
  origin := vertex_ptr^.point_ptr^.point_geometry_ptr^.point;
  normal := face_ptr^.face_geometry_ptr^.normal;
  t := Plane_intersection(ray, origin, normal);

  if (t <> infinity) then
    begin
      {*******************************************************}
      { we must test in two of the three principle directions }
      {*******************************************************}
      test_count := 0;
      intersection := Vector_sum(ray.location, Vector_scale(ray.direction, t));

      {*************************************}
      { point in polygon test:    x-y plane }
      {*************************************}
      if (t <> infinity) then
        if (normal.z <> 0) then
          begin
            {**************************************}
            { projection intersection to x-y plane }
            {**************************************}
            x3 := intersection.x;
            y3 := intersection.y;
            test_count := test_count + 1;

            directed_edge_ptr := face_ptr^.cycle_ptr^.directed_edge_ptr;
            if (directed_edge_ptr^.orientation) then
              first_vertex_ptr := directed_edge_ptr^.edge_ptr^.vertex_ptr1
            else
              first_vertex_ptr := directed_edge_ptr^.edge_ptr^.vertex_ptr2;

            edge_count := 0;
            vertex_ptr2 := first_vertex_ptr;
            while (directed_edge_ptr <> nil) do
              begin
                directed_edge_ptr := directed_edge_ptr^.next;

                vertex_ptr1 := vertex_ptr2;
                if directed_edge_ptr <> nil then
                  begin
                    if (directed_edge_ptr^.orientation) then
                      vertex_ptr2 := directed_edge_ptr^.edge_ptr^.vertex_ptr1
                    else
                      vertex_ptr2 := directed_edge_ptr^.edge_ptr^.vertex_ptr2;
                  end
                else
                  begin
                    vertex_ptr2 := first_vertex_ptr;
                  end;

                {***************************}
                { project edge to x-y plane }
                {***************************}
                x1 := vertex_ptr1^.point_ptr^.point_geometry_ptr^.point.x;
                y1 := vertex_ptr1^.point_ptr^.point_geometry_ptr^.point.y;

                x2 := vertex_ptr2^.point_ptr^.point_geometry_ptr^.point.x;
                y2 := vertex_ptr2^.point_ptr^.point_geometry_ptr^.point.y;

                {**********************************}
                { shoot ray out to right and count }
                { the # of edges intersected. Even }
                { # means point is outside polygon }
                {**********************************}
                if (y2 <> y1) then
                  begin
                    {************************}
                    { edge is not horizontal }
                    {************************}
                    t2 := (y3 - y1) / (y2 - y1);
                    if (t2 >= 0) and (t2 <= 1) then
                      if (x1 + (x2 - x1) * t2 > x3) then
                        edge_count := edge_count + 1;
                  end;
              end; {while loop}

            if (edge_count mod 2) = 0 then
              t := infinity; {no intersection}
          end; {x-y point in polygon test}


      {*************************************}
      { point in polygon test:    y-z plane }
      {*************************************}
      if (t <> infinity) then
        if (normal.x <> 0) then
          begin
            {**************************************}
            { projection intersection to y-z plane }
            {**************************************}
            x3 := intersection.y;
            y3 := intersection.z;
            test_count := test_count + 1;

            directed_edge_ptr := face_ptr^.cycle_ptr^.directed_edge_ptr;
            if (directed_edge_ptr^.orientation) then
              first_vertex_ptr := directed_edge_ptr^.edge_ptr^.vertex_ptr1
            else
              first_vertex_ptr := directed_edge_ptr^.edge_ptr^.vertex_ptr2;

            edge_count := 0;
            vertex_ptr2 := first_vertex_ptr;
            while (directed_edge_ptr <> nil) do
              begin
                directed_edge_ptr := directed_edge_ptr^.next;

                vertex_ptr1 := vertex_ptr2;
                if directed_edge_ptr <> nil then
                  begin
                    if (directed_edge_ptr^.orientation) then
                      vertex_ptr2 := directed_edge_ptr^.edge_ptr^.vertex_ptr1
                    else
                      vertex_ptr2 := directed_edge_ptr^.edge_ptr^.vertex_ptr2;
                  end
                else
                  begin
                    vertex_ptr2 := first_vertex_ptr;
                  end;

                {***************************}
                { project edge to y-z plane }
                {***************************}
                x1 := vertex_ptr1^.point_ptr^.point_geometry_ptr^.point.y;
                y1 := vertex_ptr1^.point_ptr^.point_geometry_ptr^.point.z;

                x2 := vertex_ptr2^.point_ptr^.point_geometry_ptr^.point.y;
                y2 := vertex_ptr2^.point_ptr^.point_geometry_ptr^.point.z;

                {**********************************}
                { shoot ray out to right and count }
                { the # of edges intersected. Even }
                { # means point is outside polygon }
                {**********************************}
                if (y2 <> y1) then
                  begin
                    {************************}
                    { edge is not horizontal }
                    {************************}
                    t2 := (y3 - y1) / (y2 - y1);
                    if (t2 >= 0) and (t2 <= 1) then
                      if (x1 + (x2 - x1) * t2 > x3) then
                        edge_count := edge_count + 1;
                  end;
              end; {while loop}

            if (edge_count mod 2) = 0 then
              t := infinity; {no intersection}
          end; {y-z point in polygon test}


      {*************************************}
      { point in polygon test:    x-z plane }
      {*************************************}
      if (t <> infinity) then
        if (normal.y <> 0) then
          if (test_count < 2) then
            begin
              {**************************************}
              { projection intersection to x-z plane }
              {**************************************}
              x3 := intersection.x;
              y3 := intersection.z;

              directed_edge_ptr := face_ptr^.cycle_ptr^.directed_edge_ptr;
              if (directed_edge_ptr^.orientation) then
                first_vertex_ptr := directed_edge_ptr^.edge_ptr^.vertex_ptr1
              else
                first_vertex_ptr := directed_edge_ptr^.edge_ptr^.vertex_ptr2;

              edge_count := 0;
              vertex_ptr2 := first_vertex_ptr;
              while (directed_edge_ptr <> nil) do
                begin
                  directed_edge_ptr := directed_edge_ptr^.next;

                  vertex_ptr1 := vertex_ptr2;
                  if directed_edge_ptr <> nil then
                    begin
                      if (directed_edge_ptr^.orientation) then
                        vertex_ptr2 := directed_edge_ptr^.edge_ptr^.vertex_ptr1
                      else
                        vertex_ptr2 := directed_edge_ptr^.edge_ptr^.vertex_ptr2;
                    end
                  else
                    begin
                      vertex_ptr2 := first_vertex_ptr;
                    end;

                  {***************************}
                  { project edge to x-z plane }
                  {***************************}
                  x1 := vertex_ptr1^.point_ptr^.point_geometry_ptr^.point.x;
                  y1 := vertex_ptr1^.point_ptr^.point_geometry_ptr^.point.z;

                  x2 := vertex_ptr2^.point_ptr^.point_geometry_ptr^.point.x;
                  y2 := vertex_ptr2^.point_ptr^.point_geometry_ptr^.point.z;

                  {**********************************}
                  { shoot ray out to right and count }
                  { the # of edges intersected. Even }
                  { # means point is outside polygon }
                  {**********************************}
                  if (y2 <> y1) then
                    begin
                      {************************}
                      { edge is not horizontal }
                      {************************}
                      t2 := (y3 - y1) / (y2 - y1);
                      if (t2 >= 0) and (t2 <= 1) then
                        if (x1 + (x2 - x1) * t2 > x3) then
                          edge_count := edge_count + 1;
                    end;
                end; {while loop}

              if (edge_count mod 2) = 0 then
                t := infinity; {no intersection}
            end; {x-z point in polygon test}
    end; {point in polygon tests}

  Fast_face_intersection := t;
end; {function Fast_face_intersection}


function Point_in_face(point_ptr: point_ptr_type;
  face_ptr: face_ptr_type): boolean;
var
  in_face: boolean;
  follow: directed_edge_ptr_type;
  first_vertex_ptr: vertex_ptr_type;
begin
  in_face := false;
  if point_ptr <> nil then
    begin
      follow := face_ptr^.cycle_ptr^.directed_edge_ptr;
      while (follow <> nil) and not in_face do
        begin
          if (follow^.orientation) then
            first_vertex_ptr := follow^.edge_ptr^.vertex_ptr1
          else
            first_vertex_ptr := follow^.edge_ptr^.vertex_ptr2;

          if (first_vertex_ptr^.point_ptr = point_ptr) then
            in_face := true
          else
            follow := follow^.next;
        end;
    end;

  Point_in_face := in_face;
end; {function Point_in_face}


function Face_node_intersection(ray: ray_type;
  tmin, tmax: real;
  var coord_axes: coord_axes_type;
  var texture_interpolation: interpolation_type;
  face_node_ptr: face_node_ptr_type): real;
var
  t: real;
  mailbox_hit: boolean;
begin
  mailbox_hit := false;
  if Equal_vector(ray.direction, face_node_ptr^.mesh_mailbox.ray.direction) then
    if Equal_vector(ray.location, face_node_ptr^.mesh_mailbox.ray.location) then
      mailbox_hit := true;

  if mailbox_hit then
    begin
      t := face_node_ptr^.mesh_mailbox.t;
    end
  else if Point_in_face(source_point_ptr, face_node_ptr^.face_ptr) then
    begin
      t := infinity;
    end
  else
    begin
      t := Face_intersection(coord_axes, texture_interpolation,
        face_node_ptr^.face_ptr);
      if (t < tmin) or (t > tmax) then
        t := infinity;
      face_node_ptr^.mesh_mailbox.ray := ray;
      face_node_ptr^.mesh_mailbox.t := t;
    end;

  Face_node_intersection := t;
end; {function Face_node_intersection}


function Smooth_face_node_intersection(ray: ray_type;
  tmin, tmax: real;
  var coord_axes: coord_axes_type;
  var normal_interpolation: interpolation_type;
  var texture_interpolation: interpolation_type;
  face_node_ptr: face_node_ptr_type): real;
var
  t: real;
  mailbox_hit: boolean;
begin
  mailbox_hit := false;
  if Equal_vector(ray.direction, face_node_ptr^.mesh_mailbox.ray.direction) then
    if Equal_vector(ray.location, face_node_ptr^.mesh_mailbox.ray.location) then
      mailbox_hit := true;

  if mailbox_hit then
    begin
      {**************************************************}
      { mailbox does not contain interpolation therefore }
      { the closest interpolation must be maintained as  }
      { we advance the ray so we can retreive it when we }
      { find that our closest intersection is inside of  }
      { the current voxel that we are traversing.        }
      {**************************************************}
      t := face_node_ptr^.mesh_mailbox.t;
    end
  else if Point_in_face(source_point_ptr, face_node_ptr^.face_ptr) then
    begin
      t := infinity;
    end
  else
    begin
      t := Smooth_face_intersection(coord_axes, normal_interpolation,
        texture_interpolation, face_node_ptr^.face_ptr);
      if (t < tmin) or (t > tmax) then
        t := infinity;
      face_node_ptr^.mesh_mailbox.ray := ray;
      face_node_ptr^.mesh_mailbox.t := t;
    end;

  Smooth_face_node_intersection := t;
end; {function Smooth_face_node_intersection}


function Fast_face_node_intersection(ray: ray_type;
  tmin, tmax: real;
  face_node_ptr: face_node_ptr_type): real;
var
  t: real;
  mailbox_hit: boolean;
begin
  mailbox_hit := false;
  if Equal_vector(ray.direction, face_node_ptr^.mesh_mailbox.ray.direction) then
    if Equal_vector(ray.location, face_node_ptr^.mesh_mailbox.ray.location) then
      mailbox_hit := true;

  if mailbox_hit then
    begin
      t := face_node_ptr^.mesh_mailbox.t;
    end
  else if Point_in_face(source_point_ptr, face_node_ptr^.face_ptr) then
    begin
      t := infinity;
    end
  else
    begin
      t := Fast_face_intersection(ray, face_node_ptr^.face_ptr);
      if (t < tmin) or (t > tmax) then
        t := infinity;
      face_node_ptr^.mesh_mailbox.ray := ray;
      face_node_ptr^.mesh_mailbox.t := t;
    end;

  Fast_face_node_intersection := t;
end; {function Fast_face_node_intersection}


function Mesh_intersection(ray: ray_type;
  tmin, tmax: real;
  mesh_voxel_ptr: mesh_voxel_ptr_type;
  var normal: vector_type;
  var texture_interpolation: interpolation_type): real;
var
  t, new_t: real;
  point: vector_type;
  found, found_hit: boolean;
  inside_voxels: boolean;
  ray_hits_voxels: boolean;
  follow: face_node_ref_ptr_type;
  face_node_ptr: face_node_ptr_type;
  trans: trans_type;
  coord_axes: coord_axes_type;
  new_texture_interpolation: interpolation_type;
begin
  t := infinity;
  point := ray.location;

  {***********************************}
  { find if ray starts in voxel space }
  {***********************************}
  inside_voxels := false;
  if (abs(point.x) <= 1) then
    if (abs(point.y) <= 1) then
      if (abs(point.z) <= 1) then
        inside_voxels := true;

  {******************************}
  { find if ray hits voxel space }
  {******************************}
  ray_hits_voxels := true;
  if not inside_voxels then
    if (Voxel_intersection(ray, point) = infinity) then
      ray_hits_voxels := false;

  {*******************}
  { check voxel space }
  {*******************}
  if (ray_hits_voxels) then
    begin
      {***************************************}
      { compute transformation to axes of ray }
      {***************************************}
      trans := Vector_to_trans(ray.location, ray.direction);
      coord_axes := Trans_to_axes(trans);

      mesh_voxel_ptr := Leaf_voxel(mesh_voxel_ptr, point);
      found := false;

      while ((mesh_voxel_ptr <> nil) and (not found)) do
        begin
          {***********************************************}
          { find nearest intersection of objects in voxel }
          {***********************************************}
          found_hit := false;
          follow := mesh_voxel_ptr^.face_node_ref_ptr;
          while (follow <> nil) do
            begin
              face_node_ptr := follow^.face_node_ptr;
              if (face_node_ptr^.face_ptr <> source_face_ptr) then
                begin
                  {*********************************}
                  { send closest interpolation into }
                  { test in case of mailbox strike. }
                  {*********************************}
                  new_texture_interpolation := texture_interpolation;
                  new_t := Face_node_intersection(ray, tmin, tmax, coord_axes,
                    new_texture_interpolation, face_node_ptr);
                  if (new_t < t) then
                    begin
                      normal :=
                        face_node_ptr^.face_ptr^.face_geometry_ptr^.normal;
                      texture_interpolation := new_texture_interpolation;
                      t := new_t;
                      found_hit := true;
                      target_face_ptr := face_node_ptr^.face_ptr;
                    end;
                end;
              follow := follow^.next;
            end; {while loop}

          {**************************************}
          { find if we have a valid intersection }
          {**************************************}
          if found_hit then
            begin
              point := Vector_sum(ray.location, Vector_scale(ray.direction, t));
              if Point_in_extent_box(point, mesh_voxel_ptr^.extent_box) then
                found := true
              else
                mesh_voxel_ptr := Next_voxel(mesh_voxel_ptr, ray);
            end
          else
            mesh_voxel_ptr := Next_voxel(mesh_voxel_ptr, ray);
        end; {while loop}
    end; {mesh intersection}

  Mesh_intersection := t;
end; {function Mesh_intersection}


function Smooth_mesh_intersection(ray: ray_type;
  tmin, tmax: real;
  mesh_voxel_ptr: mesh_voxel_ptr_type;
  var normal_interpolation: interpolation_type;
  var texture_interpolation: interpolation_type): real;
var
  t, new_t: real;
  point: vector_type;
  found, found_hit: boolean;
  inside_voxels: boolean;
  ray_hits_voxels: boolean;
  follow: face_node_ref_ptr_type;
  face_node_ptr: face_node_ptr_type;
  trans: trans_type;
  coord_axes: coord_axes_type;
  new_normal_interpolation: interpolation_type;
  new_texture_interpolation: interpolation_type;
begin
  t := infinity;
  point := ray.location;

  {***********************************}
  { find if ray starts in voxel space }
  {***********************************}
  inside_voxels := false;
  if (abs(point.x) <= 1) then
    if (abs(point.y) <= 1) then
      if (abs(point.z) <= 1) then
        inside_voxels := true;

  {******************************}
  { find if ray hits voxel space }
  {******************************}
  ray_hits_voxels := true;
  if not inside_voxels then
    if (Voxel_intersection(ray, point) = infinity) then
      ray_hits_voxels := false;

  {*******************}
  { check voxel space }
  {*******************}
  if (ray_hits_voxels) then
    begin
      {***************************************}
      { compute transformation to axes of ray }
      {***************************************}
      trans := Vector_to_trans(ray.location, ray.direction);
      coord_axes := Trans_to_axes(trans);

      mesh_voxel_ptr := Leaf_voxel(mesh_voxel_ptr, point);
      found := false;

      while ((mesh_voxel_ptr <> nil) and (not found)) do
        begin
          {***********************************************}
          { find nearest intersection of objects in voxel }
          {***********************************************}
          found_hit := false;
          follow := mesh_voxel_ptr^.face_node_ref_ptr;
          while (follow <> nil) do
            begin
              face_node_ptr := follow^.face_node_ptr;
              if (face_node_ptr^.face_ptr <> source_face_ptr) then
                begin
                  {*********************************}
                  { send closest interpolation into }
                  { test in case of mailbox strike. }
                  {*********************************}
                  new_normal_interpolation := normal_interpolation;
                  new_texture_interpolation := texture_interpolation;
                  new_t := Smooth_face_node_intersection(ray, tmin, tmax,
                    coord_axes, new_normal_interpolation,
                    new_texture_interpolation, face_node_ptr);
                  if (new_t < t) then
                    begin
                      t := new_t;
                      normal_interpolation := new_normal_interpolation;
                      texture_interpolation := new_texture_interpolation;
                      target_face_ptr := face_node_ptr^.face_ptr;
                      found_hit := true;
                    end;
                end;
              follow := follow^.next;
            end; {while loop}

          {**************************************}
          { find if we have a valid intersection }
          {**************************************}
          if found_hit then
            begin
              point := Vector_sum(ray.location, Vector_scale(ray.direction, t));
              if Point_in_extent_box(point, mesh_voxel_ptr^.extent_box) then
                found := true
              else
                mesh_voxel_ptr := Next_voxel(mesh_voxel_ptr, ray);
            end
          else
            mesh_voxel_ptr := Next_voxel(mesh_voxel_ptr, ray);
        end; {while loop}
    end; {mesh intersection}

  Smooth_mesh_intersection := t;
end; {function Smooth_mesh_intersection}


function Fast_mesh_intersection(ray: ray_type;
  tmin, tmax: real;
  mesh_voxel_ptr: mesh_voxel_ptr_type): real;
var
  t, new_t: real;
  point: vector_type;
  found, found_hit: boolean;
  inside_voxels: boolean;
  ray_hits_voxels: boolean;
  follow: face_node_ref_ptr_type;
  face_node_ptr: face_node_ptr_type;
begin
  t := infinity;
  point := ray.location;

  {***********************************}
  { find if ray starts in voxel space }
  {***********************************}
  inside_voxels := false;
  if (abs(point.x) <= 1) then
    if (abs(point.y) <= 1) then
      if (abs(point.z) <= 1) then
        inside_voxels := true;

  {******************************}
  { find if ray hits voxel space }
  {******************************}
  ray_hits_voxels := true;
  if not inside_voxels then
    if (Voxel_intersection(ray, point) = infinity) then
      ray_hits_voxels := false;

  {*******************}
  { check voxel space }
  {*******************}
  if (ray_hits_voxels) then
    begin
      mesh_voxel_ptr := Leaf_voxel(mesh_voxel_ptr, point);
      found := false;

      while ((mesh_voxel_ptr <> nil) and (not found)) do
        begin
          {***********************************************}
          { find nearest intersection of objects in voxel }
          {***********************************************}
          found_hit := false;
          follow := mesh_voxel_ptr^.face_node_ref_ptr;
          while (follow <> nil) do
            begin
              face_node_ptr := follow^.face_node_ptr;
              if (face_node_ptr^.face_ptr <> source_face_ptr) then
                begin
                  new_t := Fast_face_node_intersection(ray, tmin, tmax,
                    face_node_ptr);
                  if (new_t < t) then
                    begin
                      t := new_t;
                      target_face_ptr := face_node_ptr^.face_ptr;
                      found_hit := true;
                    end;
                end;
              follow := follow^.next;
            end; {while loop}

          {**************************************}
          { find if we have a valid intersection }
          {**************************************}
          if found_hit then
            begin
              point := Vector_sum(ray.location, Vector_scale(ray.direction, t));
              if Point_in_extent_box(point, mesh_voxel_ptr^.extent_box) then
                found := true
              else
                mesh_voxel_ptr := Next_voxel(mesh_voxel_ptr, ray);
            end
          else
            mesh_voxel_ptr := Next_voxel(mesh_voxel_ptr, ray);
        end; {while loop}
    end; {mesh intersection}

  Fast_mesh_intersection := t;
end; {function Fast_mesh_intersection}


end.
