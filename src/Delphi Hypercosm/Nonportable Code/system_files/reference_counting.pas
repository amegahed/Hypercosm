unit reference_counting;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm         reference_counting            3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{        This module contains a base class for disabling        }
{        reference count based deallocation of objects.         }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface


type
   interfaced_object_type = class(TInterfacedObject, IUnknown)

    {*************************************}
    { interface memory management methods }
    {*************************************}
    function _AddRef: integer; stdcall;
    function _Release: integer; stdcall;
   end; {intefaced_object_type}


implementation


function interfaced_object_type._AddRef: integer;
begin
  Result := -1;
end; {function interfaced_object_type._AddRef}


function interfaced_object_type._Release: integer;
begin
  Result := -1;
end; {function interfaced_object_type._Release}


end.
