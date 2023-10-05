unit make_instructs;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           make_instructs              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module defines recursive operations which          }
{       are performed on the instruction syntax trees.          }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  instructs;


{****************************************************}
{ routines for recursively copying instruction trees }
{****************************************************}
function Clone_instruct(instruct_ptr: instruct_ptr_type;
  copy_attributes: boolean): instruct_ptr_type;
function Clone_instructs(instruct_ptr: instruct_ptr_type;
  copy_attributes: boolean): instruct_ptr_type;

{****************************************************}
{ routines for recursively freeing instruction trees }
{****************************************************}
procedure Destroy_instruct(var instruct_ptr: instruct_ptr_type;
  free_attributes: boolean);
procedure Destroy_instructs(var instruct_ptr: instruct_ptr_type;
  free_attributes: boolean);

{****************************************************}
{ routines for recursively marking instruction trees }
{****************************************************}
procedure Mark_instruct(instruct_ptr: instruct_ptr_type;
  touched: boolean);
procedure Mark_instructs(instruct_ptr: instruct_ptr_type;
  touched: boolean);

{******************************************************}
{ routines for recursively comparing instruction trees }
{******************************************************}
function Equal_instructs(instruct_ptr1, instruct_ptr2: instruct_ptr_type):
  boolean;
function Same_instructs(instruct_ptr1, instruct_ptr2: instruct_ptr_type):
  boolean;


implementation
uses
  make_exprs;


{****************************************************}
{ routines for recursively copying instruction trees }
{****************************************************}


function Clone_instruct(instruct_ptr: instruct_ptr_type;
  copy_attributes: boolean): instruct_ptr_type;
var
  new_instruct_ptr: instruct_ptr_type;
begin
  if (instruct_ptr <> nil) then
    begin
      new_instruct_ptr := Copy_instruct(instruct_ptr);

      with new_instruct_ptr^ do
        case kind of

          {*****************************}
          { input / output instructions }
          {*****************************}
          boolean_write..write_newline, boolean_read..read_newline:
            argument_ptr := Clone_expr(argument_ptr, copy_attributes);

        end; {case}
    end
  else
    new_instruct_ptr := nil;

  Clone_instruct := new_instruct_ptr;
end; {function Clone_instruct}


function Clone_instructs(instruct_ptr: instruct_ptr_type;
  copy_attributes: boolean): instruct_ptr_type;
var
  new_instruct_ptr: instruct_ptr_type;
  first_instruct_ptr, last_instruct_ptr: instruct_ptr_type;
begin
  first_instruct_ptr := nil;
  last_instruct_ptr := nil;

  while instruct_ptr <> nil do
    begin
      new_instruct_ptr := Clone_instruct(instruct_ptr, copy_attributes);

      {*********************************}
      { add new instruct to end of list }
      {*********************************}
      if (last_instruct_ptr <> nil) then
        begin
          last_instruct_ptr^.next := new_instruct_ptr;
          last_instruct_ptr := new_instruct_ptr;
        end
      else
        begin
          first_instruct_ptr := new_instruct_ptr;
          last_instruct_ptr := new_instruct_ptr;
        end;

      instruct_ptr := instruct_ptr^.next;
    end;

  Clone_instructs := first_instruct_ptr;
end; {function Clone_instructs}


{****************************************************}
{ routines for recursively freeing instruction trees }
{****************************************************}


procedure Destroy_instruct(var instruct_ptr: instruct_ptr_type;
  free_attributes: boolean);
begin
  if (instruct_ptr <> nil) then
    begin
      with instruct_ptr^ do
        case kind of

          {*****************************}
          { input / output instructions }
          {*****************************}
          boolean_write..write_newline, boolean_read..read_newline:
            begin
              Destroy_expr(argument_ptr, free_attributes);
            end;

        end; {case}

      {***************************}
      { add instruct to free list }
      {***************************}
      Free_instruct(instruct_ptr);
    end;
end; {procedure Destroy_instruct}


procedure Destroy_instructs(var instruct_ptr: instruct_ptr_type;
  free_attributes: boolean);
var
  temp: instruct_ptr_type;
begin
  while (instruct_ptr <> nil) do
    begin
      temp := instruct_ptr;
      instruct_ptr := instruct_ptr^.next;
      Destroy_instruct(temp, free_attributes);
    end;
end; {procedure Destroy_instructs}


{****************************************************}
{ routines for recursively marking instruction trees }
{****************************************************}


procedure Mark_instruct(instruct_ptr: instruct_ptr_type;
  touched: boolean);
begin
  if (instruct_ptr <> nil) then
    begin
      with instruct_ptr^ do
        case kind of

          {*****************************}
          { input / output instructions }
          {*****************************}
          boolean_write..write_newline, boolean_read..read_newline:
            Mark_expr(argument_ptr, touched);

        end; {case}
    end;
end; {procedure Mark_instruct}


procedure Mark_instructs(instruct_ptr: instruct_ptr_type;
  touched: boolean);
begin
  while (instruct_ptr <> nil) do
    begin
      Mark_instruct(instruct_ptr, touched);
      instruct_ptr := instruct_ptr^.next;
    end;
end; {procedure Mark_instructs}


{******************************************************}
{ routines for recursively comparing instruction trees }
{******************************************************}


function Equal_instructs(instruct_ptr1, instruct_ptr2: instruct_ptr_type):
  boolean;
var
  equal: boolean;
begin
  equal := false;

  if (instruct_ptr1^.kind <> instruct_ptr2^.kind) then
    equal := false
  else
    case instruct_ptr1^.kind of

      {*****************************}
      { input / output instructions }
      {*****************************}
      boolean_write..write_newline, boolean_read..read_newline:
        equal := Equal_exprs(instruct_ptr1^.argument_ptr,
          instruct_ptr2^.argument_ptr);

    end; {case}

  Equal_instructs := equal;
end; {function Equal_instructs}


function Same_instructs(instruct_ptr1, instruct_ptr2: instruct_ptr_type):
  boolean;
var
  same: boolean;
begin
  same := false;

  if (instruct_ptr1^.kind <> instruct_ptr2^.kind) then
    same := false
  else
    case instruct_ptr1^.kind of

      {*****************************}
      { input / output instructions }
      {*****************************}
      boolean_write..write_newline, boolean_read..read_newline:
        same := Same_exprs(instruct_ptr1^.argument_ptr,
          instruct_ptr2^.argument_ptr);

    end; {case}

  Same_instructs := same;
end; {function Same_instructs}


end.
