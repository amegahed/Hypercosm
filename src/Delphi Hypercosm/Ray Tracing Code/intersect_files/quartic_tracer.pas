unit quartic_tracer;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           quartic_tracer              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module is used to find intersections between       }
{       rays and quartic primitives.                            }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  vectors, rays, volumes, quadric_tracer;


function Torus_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  inner_radius: real;
  umin, umax: real;
  vmin, vmax: real): real;

function Blob_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  metaball_ptr: metaball_ptr_type;
  threshold: real;
  dimensions: vector_type): real;


implementation
uses
  new_memory, constants, vectors2, rays2, trans2, roots, nonplanar_tracer;


const
  memory_alert = false;



type
  hit_kind_type = (entering, leaving);


  coeff_ptr_type = ^coeff_type;
  coeff_type = record
    coeff: quartic_coeff_type;
    next: coeff_ptr_type;
  end; {coeff_type}


  metaball_hit_ptr_type = ^metaball_hit_type;
  metaball_hit_type = record
    kind: hit_kind_type;
    t: double;
    metaball_ptr: metaball_ptr_type;
    coeff_ptr: coeff_ptr_type;
    next: metaball_hit_ptr_type;
  end; {metaball_hit_type}


var
  entering_free_list: metaball_hit_ptr_type;
  leaving_free_list: metaball_hit_ptr_type;


procedure Write_intersection(intersection: intersection_type);
begin
  case intersection of
    closest:
      write('closest');
    second_closest:
      write('second_closest');
  end;
end; {procedure Write_intersection}


procedure Write_hit_kind(kind: hit_kind_type);
begin
  case kind of
    entering:
      write('entering');
    leaving:
      write('leaving');
  end;
end; {procedure Write_hit_kind}


{**********************************}
{ metaball hit allocation routines }
{**********************************}


function New_metaball_hit(kind: hit_kind_type): metaball_hit_ptr_type;
var
  metaball_hit_ptr: metaball_hit_ptr_type;
begin
  metaball_hit_ptr := nil;

  case kind of

    entering:
      begin
        {*********************************}
        { get metaball hit from free list }
        {*********************************}
        if (entering_free_list <> nil) then
          begin
            metaball_hit_ptr := entering_free_list;
            entering_free_list := entering_free_list^.next;
          end
        else
          begin
            if memory_alert then
              writeln('allocating new metaball');
            new(metaball_hit_ptr);
            new(metaball_hit_ptr^.coeff_ptr);
          end;
      end;

    leaving:
      begin
        {*********************************}
        { get metaball hit from free list }
        {*********************************}
        if (leaving_free_list <> nil) then
          begin
            metaball_hit_ptr := leaving_free_list;
            leaving_free_list := leaving_free_list^.next;
          end
        else
          begin
            if memory_alert then
              writeln('allocating new metaball hit');
            new(metaball_hit_ptr);
          end;
      end;
  end;

  {*************************}
  { initialize metaball hit }
  {*************************}
  metaball_hit_ptr^.kind := kind;
  metaball_hit_ptr^.next := nil;

  New_metaball_hit := metaball_hit_ptr;
end; {function New_metaball_hit}


procedure Free_metaball_hits(var metaball_hit_list: metaball_hit_ptr_type);
var
  metaball_hit_ptr: metaball_hit_ptr_type;
begin
  while (metaball_hit_list <> nil) do
    begin
      metaball_hit_ptr := metaball_hit_list;
      metaball_hit_list := metaball_hit_list^.next;

      case metaball_hit_ptr^.kind of

        entering:
          begin
            metaball_hit_ptr^.next := entering_free_list;
            entering_free_list := metaball_hit_ptr;
          end;

        leaving:
          begin
            metaball_hit_ptr^.next := leaving_free_list;
            leaving_free_list := metaball_hit_ptr;
          end;

      end; {case}
    end; {while}
end; {procedure Free_metaball_hits}


procedure Write_metaball_hit_list(metaball_hit_list: metaball_hit_ptr_type);
begin
  writeln('metaball hit list:');
  writeln;
  while (metaball_hit_list <> nil) do
    begin
      with metaball_hit_list^ do
        begin
          Write_hit_kind(kind);
          writeln;
          writeln('t = ', t);
          writeln;
        end;
      metaball_hit_list := metaball_hit_list^.next;
    end;
end; {procedure Write_metaball_hit_list}


{*******************************}
{ routine to sort metaball hits }
{*******************************}


procedure Increasing_merge_sort(var metaball_hit_ptr: metaball_hit_ptr_type);
var
  list1, list2, temp: metaball_hit_ptr_type;
begin
  if (metaball_hit_ptr <> nil) then
    if (metaball_hit_ptr^.next <> nil) then
      begin {at least two objects}

        {*******************************}
        { divide objects into two lists }
        {*******************************}
        list1 := nil;
        list2 := nil;
        while (metaball_hit_ptr <> nil) do
          begin
            {*********************}
            { add object to list1 }
            {*********************}
            temp := metaball_hit_ptr;
            metaball_hit_ptr := metaball_hit_ptr^.next;
            temp^.next := list1;
            list1 := temp;

            {*********************}
            { add object to list2 }
            {*********************}
            if (metaball_hit_ptr <> nil) then
              begin
                temp := metaball_hit_ptr;
                metaball_hit_ptr := metaball_hit_ptr^.next;
                temp^.next := list2;
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
        metaball_hit_ptr := nil;
        temp := nil; {temp points to tail of list}
        while (list1 <> nil) and (list2 <> nil) do
          begin
            if (list1^.t <= list2^.t) then
              begin
                {********************************************}
                { add object from list1 to metaball hit list }
                {********************************************}
                if (temp = nil) then
                  begin
                    metaball_hit_ptr := list1;
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
                {********************************************}
                { add object from list2 to metaball hit list }
                {********************************************}
                if (temp = nil) then
                  begin
                    metaball_hit_ptr := list2;
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
      end;
end; {Increasing_merge_sort}


function Closest_point_on_ray2(ray: ray2_type;
  point: vector2_type): real;
var
  point1: vector2_type;
  temp: real;
  t: real;
begin
  {*********************************}
  { return the closest point on the }
  { line to the specified point.    }
  {*********************************}
  point1 := Vector2_difference(ray.location, point);

  {*************************************}
  { for line with endpoints, p1, p2:    }
  { line = p1 + v*t where v = (p2 - p1) }
  { dist to origin, d = (p1 + v * t)^2  }
  { d = p1^2 + 2*p1*v*t + v^2*t^2       }
  { dd/dt = v*p1*v + 2*v^2*t = 0        }
  {                                     }
  { dd/dt = 0 because at the closest    }
  { point, the distance will reach a    }
  { local minimum and the change in     }
  { distance will momentarily be 0.     }
  {                                     }
  { 0 = (p1*v) + (v*v)*t                }
  { t = -(p1*v) / (v*v)                 }
  {*************************************}
  temp := Dot_product2(ray.direction, ray.direction);
  t := -Dot_product2(point1, ray.direction) / temp;

  Closest_point_on_ray2 := t;
end; {function Closest_point_on_ray2}


function Closest_point_on_ray(ray: ray_type;
  point: vector_type): real;
var
  point1: vector_type;
  temp: real;
  t: real;
begin
  {*********************************}
  { return the closest point on the }
  { line to the specified point.    }
  {*********************************}
  point1 := Vector_difference(ray.location, point);

  {*************************************}
  { for line with endpoints, p1, p2:    }
  { line = p1 + v*t where v = (p2 - p1) }
  { dist to origin, d = (p1 + v * t)^2  }
  { d = p1^2 + 2*p1*v*t + v^2*t^2       }
  { dd/dt = v*p1*v + 2*v^2*t = 0        }
  {                                     }
  { dd/dt = 0 because at the closest    }
  { point, the distance will reach a    }
  { local minimum and the change in     }
  { distance will momentarily be 0.     }
  {                                     }
  { 0 = (p1*v) + (v*v)*t                }
  { t = -(p1*v) / (v*v)                 }
  {*************************************}
  temp := Dot_product(ray.direction, ray.direction);
  t := -Dot_product(point1, ray.direction) / temp;

  Closest_point_on_ray := t;
end; {function Closest_point_on_ray}


{***********************}
{ non_planar primitives }
{***********************}


function Torus_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  inner_radius: real;
  umin, umax: real;
  vmin, vmax: real): real;
const
  mystery_constant = 0.875;
  fudge_factor = 0.99;
var
  coeff: quartic_coeff_type;
  root: quartic_root_type;
  A, B: real;
  C1, C2, C3: real;
  t, t1, t2, initial_t: real;
  counter, roots: integer;
  factor, r: real;
  point: vector_type;
  distance: real;
  ray_length: real;
begin
  {************************************}
  { intersect first with bounding cube }
  {************************************}
  if (abs(ray.location.x) > 1) or (abs(ray.location.y) > 1) or
    (abs(ray.location.z) > 1) then
    t := Unit_cube_intersection(ray, 0, infinity, intersection)
  else
    t := 0;

  if (t <> infinity) then
    begin
      B := inner_radius;
      A := 1 - B;
      initial_t := (t * fudge_factor);

      {***************************************}
      { advance ray to limits of bounding box }
      {***************************************}
      if (initial_t <> 0) then
        ray.location := Vector_sum(ray.location, Vector_scale(ray.direction,
          initial_t));

      {************************************}
      { Vector_scale ray to bounding box of torus }
      {************************************}
      factor := sqrt(A);
      ray.direction.z := ray.direction.z * B;
      ray.location.z := ray.location.z * B;
      ray_length := Vector_length(ray.direction);
      ray.direction := Vector_scale(ray.direction, factor / ray_length);

      C1 := A;
      {C1 := Dot_product(ray.direction, ray.direction);}
      C2 := Dot_product(ray.direction, ray.location);
      C3 := Dot_product(ray.location, ray.location) + sqr(A) - sqr(B);

      coeff[4] := sqr(C1);
      coeff[3] := (4.0 * C1 * C2);
      coeff[2] := (4.0 * sqr(C2)) + (2.0 * C1 * C3) - (4.0 * sqr(A) *
        (sqr(ray.direction.x) + sqr(ray.direction.y)));
      coeff[1] := (4.0 * C2 * C3) - (8.0 * sqr(A) * ((ray.location.x *
        ray.direction.x) + (ray.location.y * ray.direction.y)));
      coeff[0] := sqr(C3) - (4.0 * sqr(A) * (sqr(ray.location.x) +
        sqr(ray.location.y)));

      {************************}
      { the four intersections }
      {************************}
      roots := Quartic_roots(coeff, root);

      {*********************}
      { check sweep surface }
      {*********************}
      if (umin <> 0) or (umax <> 360) or (vmin <> -90) or (vmax <> 90) then
        begin
          for counter := 0 to 3 do
            if (root[counter] > 0) and (root[counter] < infinity) then
              begin
                point := Vector_sum(ray.location, Vector_scale(ray.direction,
                  root[counter]));
                if not Longitude_ok(point.x, point.y, umin, umax) then
                  root[counter] := infinity
                else
                  begin
                    distance := sqrt((point.x * point.x) + (point.y * point.y));
                    distance := distance - (1 - inner_radius);
                    if not Longitude_ok(distance, point.z, vmin, vmax) then
                      root[counter] := infinity;
                  end;
              end
            else
              root[counter] := infinity;
        end;

      {***********************************************}
      { find closest intersection which is not behind }
      { the ray origin - find the smallest positive t }
      {***********************************************}
      t1 := infinity;
      t2 := infinity;
      if roots <> 0 then
        for counter := 0 to roots - 1 do
          begin
            r := root[counter];

            {***************}
            { reVector_scale roots }
            {***************}
            if (r <> infinity) then
              r := initial_t + (r / ray_length * mystery_constant);

            if (r > tmin) and (r < tmax) then
              begin
                if (r < t1) then
                  begin
                    t2 := t1;
                    t1 := r;
                  end
                else if (r < t2) then
                  t2 := r;
              end;
          end; {for}

      case intersection of
        closest:
          t := t1;
        second_closest:
          t := t2;
      end; {case}
    end;

  Torus_intersection := t;
end; {Torus_intersection}


function Blob_intersection(ray: ray_type;
  tmin, tmax: real;
  intersection: intersection_type;
  metaball_ptr: metaball_ptr_type;
  threshold: real;
  dimensions: vector_type): real;
var
  qa, qb, qc: real; { terms of quadratic equation                   }
  qd: real; { discrimanent of quadradic equation            }
  t1, t2: double; { the 2 intersections; t1=t2 if ray is tangent. }
  t, r: double; { parametric location of the intersection point }
  c0, c2, c4: double;
  a0, a1: double;
  location: vector_type;
  follow: metaball_ptr_type;
  metaball_hit_list, metaball_hit_ptr: metaball_hit_ptr_type;
  metaball_level: integer;
  coeff_ptr: coeff_ptr_type;
  coeff: quartic_coeff_type;
  root: quartic_root_type;
  roots, counter: integer;
  found: boolean;
  ray_length: real;
begin
  {************************************}
  { intersect first with bounding cube }
  {************************************}
  if (abs(ray.location.x) > 1) or (abs(ray.location.y) > 1) or
    (abs(ray.location.z) > 1) then
    t := Unit_cube_intersection(ray, 0, infinity, intersection)
  else
    t := 0;

  if (t <> infinity) then
    begin
      {*******************}
      { scale ray to blob }
      {*******************}
      ray.location := Vector_scale2(ray.location, dimensions);
      ray.direction := Vector_scale2(ray.direction, dimensions);
      ray_length := Vector_length(ray.direction);
      ray.direction := Vector_scale(ray.direction, 1 / ray_length);

      {****************************}
      { make list of intersections }
      {****************************}
      metaball_hit_list := nil;

      follow := metaball_ptr;
      while (follow <> nil) do
        begin
          location := Vector_scale(Vector_difference(ray.location,
            follow^.center), 1 /
            follow^.radius);
          qa := Dot_product(ray.direction, ray.direction);
          qb := 2.0 * Dot_product(location, ray.direction);
          qc := Dot_product(location, location) - 1.0;
          qd := qb * qb - 4 * qa * qc;

          if (qd > -tiny) then
            begin
              {***********************************************}
              { find closest intersection which is not behind }
              { the ray origin - find the smallest positive t }
              {***********************************************}
              qd := sqrt(abs(qd));
              qa := 2 * qa;

              {***********************}
              { the two intersections }
              {***********************}
              t1 := (-qb - qd) / qa;
              t2 := (-qb + qd) / qa;

              t1 := t1 * follow^.radius;
              t2 := t2 * follow^.radius;

              {*******************************}
              { enter intersections into list }
              {*******************************}
              if (t1 < tiny) then
                t1 := 0;

              if (t2 > t1) then
                begin
                  metaball_hit_ptr := New_metaball_hit(entering);
                  metaball_hit_ptr^.metaball_ptr := follow;
                  metaball_hit_ptr^.t := t1;
                  coeff_ptr := metaball_hit_ptr^.coeff_ptr;
                  metaball_hit_ptr^.next := metaball_hit_list;
                  metaball_hit_list := metaball_hit_ptr;

                  metaball_hit_ptr := New_metaball_hit(leaving);
                  metaball_hit_ptr^.metaball_ptr := follow;
                  metaball_hit_ptr^.t := t2;
                  metaball_hit_ptr^.coeff_ptr := coeff_ptr;
                  metaball_hit_ptr^.next := metaball_hit_list;
                  metaball_hit_list := metaball_hit_ptr;
                end;

            end;
          follow := follow^.next;
        end; {while}

      {************************************}
      { intersect metaballs along hit list }
      {************************************}

      if (metaball_hit_list = nil) then
        begin
          {**************************}
          { no metaballs intersected }
          {**************************}
          t := infinity;
        end
      else
        begin
          {********************************}
          { sort metaball hits by distance }
          {********************************}
          Increasing_merge_sort(metaball_hit_list);

          {*******************}
          { initialize coeffs }
          {*******************}
          coeff[4] := 0;
          coeff[3] := 0;
          coeff[2] := 0;
          coeff[1] := 0;
          coeff[0] := -threshold;

          {******************************************}
          { add coeffs of metaballs that surround us }
          {******************************************}
          metaball_level := 0;
          metaball_hit_ptr := metaball_hit_list;
          while (metaball_hit_ptr^.t < 0) do
            begin
              {****************}
              { compute coeffs }
              {****************}
              c0 := metaball_hit_ptr^.metaball_ptr^.c0;
              c2 := metaball_hit_ptr^.metaball_ptr^.c2;
              c4 := metaball_hit_ptr^.metaball_ptr^.c4;

              location := Vector_difference(ray.location,
                metaball_hit_ptr^.metaball_ptr^.center);
              a0 := Dot_product(location, location);
              a1 := Dot_product(location, ray.direction);

              with metaball_hit_ptr^.coeff_ptr^ do
                begin
                  coeff[4] := c4;
                  coeff[3] := 4.0 * c4 * a1;
                  coeff[2] := 2.0 * c4 * ((2.0 * a1 * a1) + a0) + c2;
                  coeff[1] := 2.0 * a1 * ((2.0 * c4 * a0) + c2);
                  coeff[0] := (c4 * a0 * a0) + (c2 * a0) + c0;
                end;

              {***********************}
              { add metaball to field }
              {***********************}
              for counter := 0 to 4 do
                coeff[counter] := coeff[counter] +
                  metaball_hit_ptr^.coeff_ptr^.coeff[counter];

              metaball_level := metaball_level + 1;
              metaball_hit_ptr := metaball_hit_ptr^.next;
            end;

          {*****************}
          { check each span }
          {*****************}
          found := false;
          while (metaball_hit_ptr <> nil) and (not found) do
            begin
              case metaball_hit_ptr^.kind of

                entering:
                  begin
                    {*******************}
                    { entering metaball }
                    {*******************}
                    metaball_level := metaball_level + 1;

                    {****************}
                    { compute coeffs }
                    {****************}
                    c0 := metaball_hit_ptr^.metaball_ptr^.c0;
                    c2 := metaball_hit_ptr^.metaball_ptr^.c2;
                    c4 := metaball_hit_ptr^.metaball_ptr^.c4;

                    {*******************************}
                    { advance ray to limits of blob }
                    {*******************************}
                    location := Vector_difference(ray.location,
                      metaball_hit_ptr^.metaball_ptr^.center);
                    a0 := Dot_product(location, location);
                    a1 := Dot_product(location, ray.direction);

                    with metaball_hit_ptr^.coeff_ptr^ do
                      begin
                        coeff[4] := c4;
                        coeff[3] := 4.0 * c4 * a1;
                        coeff[2] := 2.0 * c4 * ((2.0 * a1 * a1) + a0) + c2;
                        coeff[1] := 2.0 * a1 * ((2.0 * c4 * a0) + c2);
                        coeff[0] := (c4 * a0 * a0) + (c2 * a0) + c0;
                      end;

                    {***********************}
                    { add metaball to field }
                    {***********************}
                    for counter := 0 to 4 do
                      coeff[counter] := coeff[counter] +
                        metaball_hit_ptr^.coeff_ptr^.coeff[counter];
                  end;

                leaving:
                  begin
                    {*******************}
                    { entering metaball }
                    {*******************}
                    metaball_level := metaball_level - 1;

                    {******************************}
                    { subtract metaball from field }
                    {******************************}
                    for counter := 0 to 4 do
                      coeff[counter] := coeff[counter] -
                        metaball_hit_ptr^.coeff_ptr^.coeff[counter];
                  end;
              end; {case}

              {**********************************}
              { if still inside a metaball field }
              {**********************************}
              if (metaball_level <> 0) then
                begin

                  {************************}
                  { check for intersection }
                  {************************}
                  roots := Quartic_roots(coeff, root);

                  {***********************************************}
                  { find closest intersection which is not behind }
                  { the ray origin - find the smallest positive t }
                  {***********************************************}
                  t1 := infinity;
                  t2 := infinity;
                  if roots <> 0 then
                    for counter := 0 to roots - 1 do
                      begin
                        r := root[counter];
                        if (abs(r) < tiny) then
                          r := tiny
                        else
                          r := r / ray_length;

                        {************************************}
                        { check if roots are within interval }
                        {************************************}
                        if (r > metaball_hit_ptr^.t) then
                          if (r < metaball_hit_ptr^.next^.t) then
                            if (r >= tmin) and (r < tmax) then
                              begin
                                if (r < t1) then
                                  begin
                                    t2 := t1;
                                    t1 := r;
                                  end
                                else if (r < t2) then
                                  t2 := r;
                              end;
                      end; {for}

                  case intersection of
                    closest:
                      t := t1;
                    second_closest:
                      t := t2;
                  end; {case}

                  if (t <> infinity) then
                    found := true;
                end;

              metaball_hit_ptr := metaball_hit_ptr^.next;
            end;

          {***********************************}
          { return metaball hits to free list }
          {***********************************}
          Free_metaball_hits(metaball_hit_list);
        end;
    end; {inside bounding cube}

  Blob_intersection := t;
end; {function Blob_intersection}


initialization
  entering_free_list := nil;
  leaving_free_list := nil;
end.
