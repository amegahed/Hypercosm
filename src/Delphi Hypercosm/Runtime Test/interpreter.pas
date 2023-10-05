unit interpreter;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             interpreter               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       These are dummy routines to satisfy requirements        }
{	for runtime errors.  In the interpreter, this           }
{	module should be replaced by a module with actual       }
{	runtime error handling code.				}
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  strings;


procedure Runtime_error (error_message: string_type);


implementation


procedure Runtime_error (error_message: string_type);
begin
  writeln('Runtime error - ', error_message);
end;  {procedure Runtime_error}


end. {module interpreter}
