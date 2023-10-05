program video_test;


// {$APPTYPE CONSOLE}


uses
  Math,
  OpenGL,
  Messages,
  Windows,
  strings in '..\Common Code\basic_files\strings.pas',
  chars in '..\Common Code\basic_files\chars.pas',
  pixels in '..\Common Code\display_files\pixels.pas',
  colors in '..\Common Code\display_files\colors.pas',
  vectors in '..\Common Code\vector_files\vectors.pas',
  constants in '..\Common Code\math_files\constants.pas',
  system_events in '..\Nonportable Code\system_files\system_events.pas',
  screen_boxes in '..\Common Code\display_files\screen_boxes.pas',
  errors in '..\Nonportable Code\system_files\errors.pas',
  opengl_video in '..\Nonportable Code\video_files\opengl_video.pas',
  gdi_video in '..\Nonportable Code\video_files\gdi_video.pas',
  video in '..\Common Code\display_files\video.pas',
  draw in 'draw.pas',
  new_memory in '..\Nonportable Code\system_files\new_memory.pas',
  select_video in '..\Nonportable Code\video_files\select_video.pas',
  drawable in '..\Common Code\display_files\drawable.pas',
  keyboard_input in '..\Nonportable Code\device_files\keyboard_input.pas',
  mouse_input in '..\Nonportable Code\device_files\mouse_input.pas';


var
  video_window: video_window_type;


begin
  video_window := Select_new_window([does_color]);
  video_window.Open('Line Drawing Test', To_pixel(512, 384), Get_screen_center);

  while not finished do
    begin
      Draw_picture(video_window);
      Check_system_events;
    end;

  video_window.Close;
end.

