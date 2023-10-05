unit view_sorting;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            view_sorting               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The viewing module provides methods for sorting         }
{       viewing objects by distance.                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  trans, viewing;


{***************************************************}
{ routines for sorting the objects by their centers }
{***************************************************}
procedure Decreasing_center_depth_sort(var object_ptr:
  view_object_inst_ptr_type;
  trans: trans_type);
procedure Increasing_center_depth_sort(var object_ptr:
  view_object_inst_ptr_type;
  trans: trans_type);

{**********************************************************}
{ routines for sorting the objects by their closest points }
{**********************************************************}
procedure Decreasing_closest_depth_sort(var object_ptr:
  view_object_inst_ptr_type;
  trans: trans_type);
procedure Increasing_closest_depth_sort(var object_ptr:
  view_object_inst_ptr_type;
  trans: trans_type);

{***********************************************************}
{ routines for sorting the objects by their farthest points }
{***********************************************************}
procedure Decreasing_farthest_depth_sort(var object_ptr:
  view_object_inst_ptr_type;
  trans: trans_type);
procedure Increasing_farthest_depth_sort(var object_ptr:
  view_object_inst_ptr_type;
  trans: trans_type);


implementation
uses
  constants, vectors, extents, bounds, project;


procedure Decreasing_merge_sort(var object_ptr: view_object_inst_ptr_type);
var
  list1, list2, temp: view_object_inst_ptr_type;
begin
  if (object_ptr <> nil) then
    if (object_ptr^.spatial_next <> nil) then
      begin {at least two objects}

        {*******************************}
        { divide objects into two lists }
        {*******************************}
        list1 := nil;
        list2 := nil;
        while (object_ptr <> nil) do
          begin
            {*********************}
            { add object to list1 }
            {*********************}
            temp := object_ptr;
            object_ptr := object_ptr^.spatial_next;
            temp^.spatial_next := list1;
            list1 := temp;

            {*********************}
            { add object to list2 }
            {*********************}
            if (object_ptr <> nil) then
              begin
                temp := object_ptr;
                object_ptr := object_ptr^.spatial_next;
                temp^.spatial_next := list2;
                list2 := temp;
              end;
          end; {while}

        {***************}
        { sort sublists }
        {***************}
        Decreasing_merge_sort(list1);
        Decreasing_merge_sort(list2);

        {*************}
        { merge lists }
        {*************}
        object_ptr := nil;
        temp := nil; {temp points to tail of list}
        while (list1 <> nil) and (list2 <> nil) do
          begin
            if (list1^.distance >= list2^.distance) then
              begin
                {**************************************}
                { add object from list1 to object list }
                {**************************************}
                if (temp = nil) then
                  begin
                    object_ptr := list1;
                    temp := list1;
                    list1 := list1^.spatial_next;
                  end
                else
                  begin
                    temp^.spatial_next := list1;
                    temp := list1;
                    list1 := list1^.spatial_next;
                  end;
              end
            else
              begin
                {**************************************}
                { add object from list2 to object list }
                {**************************************}
                if (temp = nil) then
                  begin
                    object_ptr := list2;
                    temp := list2;
                    list2 := list2^.spatial_next;
                  end
                else
                  begin
                    temp^.spatial_next := list2;
                    temp := list2;
                    list2 := list2^.spatial_next;
                  end;
              end;
          end; {while}
        if (temp <> nil) then
          begin
            if (list1 = nil) then
              temp^.spatial_next := list2
            else
              temp^.spatial_next := list1;
          end;
      end;
end; {Decreasing_merge_sort}


procedure Increasing_merge_sort(var object_ptr: view_object_inst_ptr_type);
var
  list1, list2, temp: view_object_inst_ptr_type;
begin
  if (object_ptr <> nil) then
    if (object_ptr^.spatial_next <> nil) then
      begin {at least two objects}

        {*******************************}
        { divide objects into two lists }
        {*******************************}
        list1 := nil;
        list2 := nil;
        while (object_ptr <> nil) do
          begin
            {*********************}
            { add object to list1 }
            {*********************}
            temp := object_ptr;
            object_ptr := object_ptr^.spatial_next;
            temp^.spatial_next := list1;
            list1 := temp;

            {*********************}
            { add object to list2 }
            {*********************}
            if (object_ptr <> nil) then
              begin
                temp := object_ptr;
                object_ptr := object_ptr^.spatial_next;
                temp^.spatial_next := list2;
                list2 := temp;
              end;
          end; {while}

        {***************}
        { sort sublists }
        {***************}
        Increasing_merge_sort(list1);
        Increasing_merge_sort(list2);

        {*************}
        { merge lists }
        {*************}
        object_ptr := nil;
        temp := nil; {temp points to tail of list}
        while (list1 <> nil) and (list2 <> nil) do
          begin
            if (list1^.distance <= list2^.distance) then
              begin
                {**************************************}
                { add object from list1 to object list }
                {**************************************}
                if (temp = nil) then
                  begin
                    object_ptr := list1;
                    temp := list1;
                    list1 := list1^.spatial_next;
                  end
                else
                  begin
                    temp^.spatial_next := list1;
                    temp := list1;
                    list1 := list1^.spatial_next;
                  end;
              end
            else
              begin
                {**************************************}
                { add object from list2 to object list }
                {**************************************}
                if (temp = nil) then
                  begin
                    object_ptr := list2;
                    temp := list2;
                    list2 := list2^.spatial_next;
                  end
                else
                  begin
                    temp^.spatial_next := list2;
                    temp := list2;
                    list2 := list2^.spatial_next;
                  end;
              end;
          end; {while}
        if (temp <> nil) then
          begin
            if (list1 = nil) then
              temp^.spatial_next := list2
            else
              temp^.spatial_next := list1;
          end;
      end;
end; {Increasing_merge_sort}


{*********************************************}
{ routines for computing distances to objects }
{*********************************************}


function Closest_point_in_trans(trans: trans_type;
  bounding_kind: bounding_kind_type): vector_type;
var
  bounds: bounding_type;
  point: vector_type;
  distance: real;
  closest_point: vector_type;
  closest_distance: real;
  counter1, counter2, counter3: extent_type;
begin
  Make_bounds(bounds, bounding_kind, trans);

  case (bounds.bounding_kind) of

    null_bounds, infinite_planar_bounds, infinite_non_planar_bounds:
      closest_point := zero_vector;

    planar_bounds:
      begin
        closest_point := zero_vector;
        closest_distance := infinity;

        for counter1 := left to right do
          for counter2 := front to back do
            begin
              point := bounds.bounding_square[counter1, counter2];

              if current_projection_ptr^.kind = orthographic then
                distance := point.y
              else
                distance := Dot_product(point, point);

              if (distance < closest_distance) then
                begin
                  closest_distance := distance;
                  closest_point := point;
                end;
            end;
      end;

    non_planar_bounds:
      begin
        closest_point := zero_vector;
        closest_distance := infinity;

        for counter1 := left to right do
          for counter2 := front to back do
            for counter3 := bottom to top do
              begin
                point := bounds.bounding_box[counter1, counter2, counter3];

                if current_projection_ptr^.kind = orthographic then
                  distance := point.y
                else
                  distance := Dot_product(point, point);

                if (distance < closest_distance) then
                  begin
                    closest_distance := distance;
                    closest_point := point;
                  end;
              end;
      end;
  end; {case statement}

  Closest_point_in_trans := closest_point;
end; {function Closest_point_in_trans}


function Farthest_point_in_trans(trans: trans_type;
  bounding_kind: bounding_kind_type): vector_type;
var
  bounds: bounding_type;
  point: vector_type;
  distance: real;
  farthest_point: vector_type;
  farthest_distance: real;
  counter1, counter2, counter3: extent_type;
begin
  Make_bounds(bounds, bounding_kind, trans);

  case (bounds.bounding_kind) of

    null_bounds, infinite_planar_bounds, infinite_non_planar_bounds:
      farthest_point := zero_vector;

    planar_bounds:
      begin
        farthest_point := zero_vector;
        farthest_distance := 0;

        for counter1 := left to right do
          for counter2 := front to back do
            begin
              point := bounds.bounding_square[counter1, counter2];

              if current_projection_ptr^.kind = orthographic then
                distance := point.y
              else
                distance := Dot_product(point, point);

              if (distance > farthest_distance) then
                begin
                  farthest_distance := distance;
                  farthest_point := point;
                end;
            end;
      end;

    non_planar_bounds:
      begin
        farthest_point := zero_vector;
        farthest_distance := 0;

        for counter1 := left to right do
          for counter2 := front to back do
            for counter3 := bottom to top do
              begin
                point := bounds.bounding_box[counter1, counter2, counter3];

                if current_projection_ptr^.kind = orthographic then
                  distance := point.y
                else
                  distance := Dot_product(point, point);

                if (distance > farthest_distance) then
                  begin
                    farthest_distance := distance;
                    farthest_point := point;
                  end;
              end;
      end;
  end; {case statement}

  Farthest_point_in_trans := farthest_point;
end; {function Farthest_point_in_trans}


{***************************************************}
{ routines for sorting the objects by their centers }
{***************************************************}


procedure Decreasing_center_depth_sort(var object_ptr:
  view_object_inst_ptr_type;
  trans: trans_type);
var
  follow: view_object_inst_ptr_type;
  point: vector_type;
begin
  {**********************************************}
  { calculate depths of objects at their centers }
  {**********************************************}
  follow := object_ptr;
  while (follow <> nil) do
    begin
      case follow^.bounding_kind of

        null_bounds, infinite_planar_bounds, infinite_non_planar_bounds:
          follow^.distance := infinity;

        planar_bounds, non_planar_bounds:
          begin
            point := follow^.trans.origin;
            Transform_point(point, trans);

            if current_projection_ptr^.kind = orthographic then
              follow^.distance := point.y
            else
              follow^.distance := Dot_product(point, point);
          end;

      end; {case}

      follow^.spatial_next := follow^.next;
      follow := follow^.next;
    end;

  {******************************}
  { sort objects based on depths }
  {******************************}
  Decreasing_merge_sort(object_ptr);
end; {procedure Decreasing_center_depth_sort}


procedure Increasing_center_depth_sort(var object_ptr:
  view_object_inst_ptr_type;
  trans: trans_type);
var
  follow: view_object_inst_ptr_type;
  point: vector_type;
begin
  {**********************************************}
  { calculate depths of objects at their centers }
  {**********************************************}
  follow := object_ptr;
  while (follow <> nil) do
    begin
      case follow^.bounding_kind of

        null_bounds:
          follow^.distance := -infinity;

        infinite_planar_bounds, infinite_non_planar_bounds:
          follow^.distance := infinity;

        planar_bounds, non_planar_bounds:
          begin
            point := follow^.trans.origin;
            Transform_point(point, trans);

            if current_projection_ptr^.kind = orthographic then
              follow^.distance := point.y
            else
              follow^.distance := Dot_product(point, point);
          end;

      end; {case}

      follow^.spatial_next := follow^.next;
      follow := follow^.next;
    end;

  {******************************}
  { sort objects based on depths }
  {******************************}
  Increasing_merge_sort(object_ptr);
end; {procedure Increasing_center_depth_sort}


{**********************************************************}
{ routines for sorting the objects by their closest points }
{**********************************************************}


procedure Decreasing_closest_depth_sort(var object_ptr:
  view_object_inst_ptr_type;
  trans: trans_type);
var
  follow: view_object_inst_ptr_type;
  object_trans: trans_type;
  point: vector_type;
begin
  {*****************************************************}
  { calculate depths of objects at their closest points }
  {*****************************************************}
  follow := object_ptr;
  while (follow <> nil) do
    begin
      case follow^.bounding_kind of

        null_bounds, infinite_planar_bounds, infinite_non_planar_bounds:
          follow^.distance := infinity;

        planar_bounds, non_planar_bounds:
          begin
            object_trans := follow^.trans;
            Transform_trans(object_trans, trans);
            point := Closest_point_in_trans(object_trans,
              follow^.bounding_kind);
            follow^.distance := Dot_product(point, point);
          end;

      end; {case}

      follow^.spatial_next := follow^.next;
      follow := follow^.next;
    end;

  {******************************}
  { sort objects based on depths }
  {******************************}
  Decreasing_merge_sort(object_ptr);
end; {procedure Decreasing_closest_depth_sort}


procedure Increasing_closest_depth_sort(var object_ptr:
  view_object_inst_ptr_type;
  trans: trans_type);
var
  follow: view_object_inst_ptr_type;
  object_trans: trans_type;
  point: vector_type;
begin
  {*****************************************************}
  { calculate depths of objects at their closest points }
  {*****************************************************}
  follow := object_ptr;
  while (follow <> nil) do
    begin
      case follow^.bounding_kind of

        null_bounds:
          follow^.distance := -infinity;

        infinite_planar_bounds, infinite_non_planar_bounds:
          follow^.distance := infinity;

        planar_bounds, non_planar_bounds:
          begin
            object_trans := follow^.trans;
            Transform_trans(object_trans, trans);
            point := Closest_point_in_trans(object_trans,
              follow^.bounding_kind);
            follow^.distance := Dot_product(point, point);
          end;

      end; {case}

      follow^.spatial_next := follow^.next;
      follow := follow^.next;
    end;

  {******************************}
  { sort objects based on depths }
  {******************************}
  Increasing_merge_sort(object_ptr);
end; {procedure Increasing_closest_depth_sort}


{***********************************************************}
{ routines for sorting the objects by their farthest points }
{***********************************************************}


procedure Decreasing_farthest_depth_sort(var object_ptr:
  view_object_inst_ptr_type;
  trans: trans_type);
var
  follow: view_object_inst_ptr_type;
  object_trans: trans_type;
  point: vector_type;
begin
  {******************************************************}
  { calculate depths of objects at their farthest points }
  {******************************************************}
  follow := object_ptr;
  while (follow <> nil) do
    begin
      case follow^.bounding_kind of

        null_bounds, infinite_planar_bounds, infinite_non_planar_bounds:
          follow^.distance := infinity;

        planar_bounds, non_planar_bounds:
          begin
            object_trans := follow^.trans;
            Transform_trans(object_trans, trans);
            point := Farthest_point_in_trans(object_trans,
              follow^.bounding_kind);
            follow^.distance := Dot_product(point, point);
          end;

      end; {case}

      follow^.spatial_next := follow^.next;
      follow := follow^.next;
    end;

  {******************************}
  { sort objects based on depths }
  {******************************}
  Decreasing_merge_sort(object_ptr);
end; {procedure Decreasing_farthest_depth_sort}


procedure Increasing_farthest_depth_sort(var object_ptr:
  view_object_inst_ptr_type;
  trans: trans_type);
var
  follow: view_object_inst_ptr_type;
  object_trans: trans_type;
  point: vector_type;
begin
  {******************************************************}
  { calculate depths of objects at their farthest points }
  {******************************************************}
  follow := object_ptr;
  while (follow <> nil) do
    begin
      case follow^.bounding_kind of

        null_bounds:
          follow^.distance := -infinity;

        infinite_planar_bounds, infinite_non_planar_bounds:
          follow^.distance := infinity;

        planar_bounds, non_planar_bounds:
          begin
            object_trans := follow^.trans;
            Transform_trans(object_trans, trans);
            point := Farthest_point_in_trans(object_trans,
              follow^.bounding_kind);
            follow^.distance := Dot_product(point, point);
          end;

      end; {case}

      follow^.spatial_next := follow^.next;
      follow := follow^.next;
    end;

  {******************************}
  { sort objects based on depths }
  {******************************}
  Increasing_merge_sort(object_ptr);
end; {procedure Increasing_farthest_depth_sort}


end.
