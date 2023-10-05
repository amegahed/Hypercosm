unit new_memory;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             new_memory                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{        This module contains routines for handling             }
{        runtime (heap) memory allocation.                      }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface


type
  ptr_type = Pointer;


  {*****************************************************}
  { routines to allocate and free runtime (heap) memory }
  {*****************************************************}
function New_ptr(size: longint): ptr_type;
procedure Free_ptr(var ptr: ptr_type);


implementation


function New_ptr(size: longint): ptr_type;
begin
  New_ptr := SysGetMem(size);
end; {procedure New_ptr}


procedure Free_ptr(var ptr: ptr_type);
begin
  SysFreeMem(ptr);
  ptr := nil;
end; {procedure Free_ptr}


end.
