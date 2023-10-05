unit cursor_control;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm           cursor_control              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the interface to system            }
{       dependent cursor control functions.                     }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface


procedure Show_cursor;
procedure Hide_cursor;


implementation


procedure Show_cursor;
begin
  InitCursor;
end; {procedure Show_cursor}


procedure Hide_cursor;
begin
end; {procedure Hide_cursor}


end. {cursor_control}
