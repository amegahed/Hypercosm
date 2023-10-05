unit system_events;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            system_events              3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the interface to system            }
{       dependent time functions.                               }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface


var
  finished: boolean;


procedure Check_system_events;


implementation
uses
  Windows, Messages, errors;


procedure Check_system_events;
var
  msg: TMsg;
begin
  if (PeekMessage(msg, 0, 0, 0, PM_REMOVE)) then
    // Check if there is a message for this window
    begin
      if (msg.message = WM_QUIT) then
        // If WM_QUIT message received then we are done
        finished := True
      else
        begin // Else translate and dispatch the message to this window
          TranslateMessage(msg);
          DispatchMessage(msg);
        end;
    end;
end; {procedure Check_system_events}


initialization
  finished := false;
end.

