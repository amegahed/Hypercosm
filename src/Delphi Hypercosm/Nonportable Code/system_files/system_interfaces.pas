unit system_interfaces;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm          system_interfaces            3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the interface to the               }
{       system dependent functions.                             }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface


{******************************************************}
{ functions for interfacing with other system entities }
{******************************************************}
procedure Set_url(url: string);
procedure Set_status(status: string);
procedure System_call(message: string);


implementation


procedure Set_url(url: string);
begin
  writeln('setting url to: ', url);
end; {procedure Set_url}


procedure Set_status(status: string);
begin
  writeln('setting status to: ', status);
end; {procedure Set_status}


procedure System_call(message: string);
begin
  writeln('system call: ', message);
end; {procedure System_call}


end.
