unit clock_time;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             clock_time                3d       }
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


procedure Get_time(var hours, minutes, seconds: real);


implementation
  uses Windows;


type
  system_time_type = record
    hours: integer;
    minutes: integer;
    seconds: real;
  end; {system_time_type}


var
  start_time: system_time_type;
  start_ticks: DWORD;


procedure Get_system_time(var system_time: system_time_type);
var
  SystemTime: TSystemTime;
  FileTime: TFileTime;
begin
  GetSystemTimeAsFileTime(FileTime);
  FileTimeToSystemTime(FileTime, SystemTime);

  system_time.hours := SystemTime.wHour;
  system_time.minutes := SystemTime.wMinute;
  system_time.seconds := SystemTime.wSecond + (SystemTime.wMilliseconds / 1000);
end; {function Get_system_time}


procedure Get_time(var hours, minutes, seconds: real);
var
  elapsed_ticks: DWORD;
  integer_minutes, integer_hours: integer;
  time: system_time_type;
begin
  elapsed_ticks := GetTickCount - start_ticks;
  time := start_time;

  time.seconds := time.seconds + (elapsed_ticks / 1000);

  if time.seconds > 60 then
    begin
      integer_minutes := trunc(time.seconds / 60);
      time.minutes := time.minutes + integer_minutes;
      time.seconds := time.seconds - (integer_minutes * 60);
    end;

  if time.minutes > 60 then
    begin
      integer_hours := trunc(time.minutes / 60);
      time.hours := time.hours + integer_hours;
      time.minutes := time.minutes - (integer_hours * 60);
    end;

  seconds := time.seconds;
  minutes := time.minutes + (seconds / 60);
  hours := time.hours + (minutes / 60);
end; {procedure Get_time}


initialization
  start_ticks := GetTickCount;
  Get_system_time(start_time);
end.
