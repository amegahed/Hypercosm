unit scan_conversion;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          scan_conversion              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines and structures to         }
{	aid in the scan conversion of polygons.			}
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, colors, screen_boxes;


type
  {******************************}
  { scan conversion data structs }
  {******************************}
  z_edge_ptr_type = ^z_edge_type;
  z_edge_type = record

    {***************************************}
    { x, z = the projection of the vertex   }
    { vertex = the vertex in global coords  }
    { normal = the normal in global coords  }
    { texture = parametric coords of vertex }
    {***************************************}
    x, x_increment: real;
    z, z_increment: real;
    vertex, vertex_increment: vector_type;
    normal, normal_increment: vector_type;
    texture, texture_increment: vector_type;
    u_axis, u_axis_increment: vector_type;
    v_axis, v_axis_increment: vector_type;
    color, color_increment: color_type;

    y_max: integer;
    next: z_edge_ptr_type;
  end; {z_edge_type}


  {************************************}
  { dynamically allocated z edge table }
  {************************************}
  z_edge_table_type = z_edge_ptr_type;
  z_edge_table_ptr_type = ^z_edge_table_type;


{***************************************************************}
{ functions to allocate and deallocate scan converstion structs }
{***************************************************************}
function New_z_edge: z_edge_ptr_type;
procedure Free_z_edge(var z_edge_ptr: z_edge_ptr_type);
function New_z_edge_table(height: integer): z_edge_table_ptr_type;
procedure Free_z_edge_table(var z_edge_table_ptr: z_edge_table_ptr_type);
procedure Resize_z_edge_table(var z_edge_table_ptr: z_edge_table_ptr_type;
  height: integer);

{************************************}
{ functions to acces dynamic buffers }
{************************************}
procedure Clear_z_edge_table(z_edge_table_ptr: z_edge_table_ptr_type;
  size: integer);
function Index_z_edge_table(z_edge_table_ptr: z_edge_table_ptr_type;
  index: integer): z_edge_table_ptr_type;

{***************************}
{ scan conversion utilities }
{***************************}
procedure Sort_z_edges(var z_edge_ptr: z_edge_ptr_type);
procedure Write_z_active_edge_list(z_edge_ptr: z_edge_ptr_type);
procedure Update_z_screen_box(var screen_box: screen_box_type;
  point: vector_type);


implementation
uses
  errors, new_memory, constants;


const
  memory_alert = false;


var
  z_edge_free_list: z_edge_ptr_type;


{***************************************************************}
{ functions to allocate and deallocate scan converstion structs }
{***************************************************************}


function New_z_edge: z_edge_ptr_type;
var
  z_edge_ptr: z_edge_ptr_type;
begin
  {*******************************}
  { get new z edge from free list }
  {*******************************}
  if (z_edge_free_list <> nil) then
    begin
      z_edge_ptr := z_edge_free_list;
      z_edge_free_list := z_edge_free_list^.next;
    end
  else
    begin
      if memory_alert then
        writeln('allocating new z edge');
      new(z_edge_ptr);
    end;

  New_z_edge := z_edge_ptr;
end; {function New_z_edge}


procedure Free_z_edge(var z_edge_ptr: z_edge_ptr_type);
begin
  z_edge_ptr^.next := z_edge_free_list;
  z_edge_free_list := z_edge_ptr;
  z_edge_ptr := nil;
end; {procedure Free_z_edge}


function New_z_edge_table(height: integer): z_edge_table_ptr_type;
var
  z_edge_table_size: longint;
  z_edge_table_ptr: z_edge_table_ptr_type;
begin
  {***********************}
  { allocate z edge table }
  {***********************}
  z_edge_table_size := longint(height + 1) * sizeof(z_edge_table_type);

  if memory_alert then
    writeln('allocating new z edge table');
  z_edge_table_ptr := z_edge_table_ptr_type(New_ptr(z_edge_table_size));

  New_z_edge_table := z_edge_table_ptr;
end; {function New_z_edge_table}


procedure Free_z_edge_table(var z_edge_table_ptr: z_edge_table_ptr_type);
begin
  dispose(z_edge_table_ptr);
  z_edge_table_ptr := nil;
end; {procedure Free_z_edge_table}


procedure Resize_z_edge_table(var z_edge_table_ptr: z_edge_table_ptr_type;
  height: integer);
begin
  Free_z_edge_table(z_edge_table_ptr);
  z_edge_table_ptr := New_z_edge_table(height);
end; {procedure Resize_z_edge_table}


{************************************}
{ functions to acces dynamic buffers }
{************************************}


procedure Clear_z_edge_table(z_edge_table_ptr: z_edge_table_ptr_type;
  size: integer);
var
  counter: integer;
begin
  {*************************}
  { initialize z edge table }
  {*************************}
  for counter := 0 to size do
    begin
      z_edge_table_ptr^ := nil;
      z_edge_table_ptr := z_edge_table_ptr_type(longint(z_edge_table_ptr) +
        sizeof(z_edge_table_type));
    end;
end; {procedure Clear_z_edge_table}


function Index_z_edge_table(z_edge_table_ptr: z_edge_table_ptr_type;
  index: integer): z_edge_table_ptr_type;
var
  offset: longint;
begin
  offset := (longint(z_edge_table_ptr) + longint(index) *
    sizeof(z_edge_table_type));
  Index_z_edge_table := z_edge_table_ptr_type(offset);
end; {function Index_z_edge_table}


{***************************}
{ scan conversion utilities }
{***************************}


procedure Sort_z_edges(var z_edge_ptr: z_edge_ptr_type);
var
  list1, list2, temp: z_edge_ptr_type;
begin
  {*********************************}
  { merge sort edges on incresing x }
  {*********************************}
  if (z_edge_ptr <> nil) then
    if (z_edge_ptr^.next <> nil) then
      begin
        {******************************}
        { there are at least two edges }
        {******************************}
        if (z_edge_ptr^.next^.next <> nil) then
          begin
            {*******************************}
            { there are more than two edges }
            {*******************************}
            list1 := nil;
            list2 := nil;

            {*****************************}
            { divide edges into two lists }
            {*****************************}
            while (z_edge_ptr <> nil) do
              begin
                {*******************}
                { add edge to list1 }
                {*******************}
                temp := z_edge_ptr;
                z_edge_ptr := z_edge_ptr^.next;
                temp^.next := list1;
                list1 := temp;

                {*******************}
                { add edge to list2 }
                {*******************}
                if (z_edge_ptr <> nil) then
                  begin
                    temp := z_edge_ptr;
                    z_edge_ptr := z_edge_ptr^.next;
                    temp^.next := list2;
                    list2 := temp;
                  end;
              end; {while}

            Sort_z_edges(list1);
            Sort_z_edges(list2);

            {*************}
            { merge lists }
            {*************}
            z_edge_ptr := nil;

            {*****************************}
            { temp points to tail of list }
            {*****************************}
            temp := nil;
            while (list1 <> nil) and (list2 <> nil) do
              begin
                if (list1^.x < list2^.x) then
                  begin
                    {**********************************}
                    { add edge from list1 to edge list }
                    {**********************************}
                    if (temp = nil) then
                      begin
                        z_edge_ptr := list1;
                        temp := list1;
                        list1 := list1^.next;
                      end
                    else
                      begin
                        temp^.next := list1;
                        temp := list1;
                        list1 := list1^.next;
                      end;
                  end
                else
                  begin
                    {**********************************}
                    { add edge from list2 to edge list }
                    {**********************************}
                    if (temp = nil) then
                      begin
                        z_edge_ptr := list2;
                        temp := list2;
                        list2 := list2^.next;
                      end
                    else
                      begin
                        temp^.next := list2;
                        temp := list2;
                        list2 := list2^.next;
                      end;
                  end;
              end; {while}
            if (temp <> nil) then
              begin
                if (list1 = nil) then
                  temp^.next := list2
                else
                  temp^.next := list1;
              end;
          end
        else
          begin
            {**************************}
            { there are two edges only }
            {**************************}
            if (z_edge_ptr^.x >= z_edge_ptr^.next^.x) then
              begin
                {************}
                { swap edges }
                {************}
                temp := z_edge_ptr;
                z_edge_ptr := z_edge_ptr^.next;
                z_edge_ptr^.next := temp;
                temp^.next := nil;
              end;
          end;
      end; {at least two edges}
end; {Sort_z_edges}


procedure Write_z_active_edge_list(z_edge_ptr: z_edge_ptr_type);
begin
  writeln('z_active_edge_list:');
  while (z_edge_ptr <> nil) do
    begin
      writeln('x = ', z_edge_ptr^.x);
      z_edge_ptr := z_edge_ptr^.next;
    end;
end; {procedure Write_z_active_edge_list}


procedure Update_z_screen_box(var screen_box: screen_box_type;
  point: vector_type);
var
  h, v: integer;
begin
  with screen_box do
    begin
      h := Trunc(point.x);
      if h < min.h then
        min.h := h;
      h := h + 1;
      if h > max.h then
        max.h := h;

      v := Trunc(point.y);
      if v < min.v then
        min.v := v;
      v := v + 1;
      if v > max.v then
        max.v := v;
    end;
end; {procedure Update_z_screen_box}


initialization
  {**************************************}
  { initialize scan conversion variables }
  {**************************************}
  z_edge_free_list := nil;
end.
