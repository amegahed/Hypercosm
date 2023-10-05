unit video;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               video                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the interface to the display       }
{       hardware. Most porting changes will be here.            }
{                                                               }
{       This is intended to be a one way interface because      }
{       we can't always rely on being able to get data back     }
{       from the videoframe buffer. If we wish to query the     }
{       display, then these types of functions must be          }
{       provided in the display module, where we can keep       }
{       our own copy of the frame buffer so that any type       }
{       of operation is possible.                               }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  strings, pixels, screen_boxes, colors;


{******************}
{ initialize video }
{******************}
procedure Init_video;

{****************************************}
{ routines to create and destroy windows }
{****************************************}
function Open_video_window(title: string_type;
  size, center: pixel_type): integer;
procedure Close_video_window(window_id: integer);

{********************************}
{ routines to manipulate windows }
{********************************}
procedure Set_video_window(window_id: integer);
function Get_video_window: integer;

{*****************************}
{ routines to set video modes }
{*****************************}
procedure Set_backing_store(state: boolean);

{************************}
{ color related routines }
{************************}
procedure Set_video_color(color: color_type);
procedure Set_video_dither(mode: boolean);
procedure Set_video_depth(depth: integer);
procedure Set_normal_color_selection;
procedure Set_dynamic_color_selection;

{******************}
{ drawing routines }
{******************}
procedure Move_to_video(pixel: pixel_type);
procedure Draw_to_video(pixel: pixel_type);
procedure Draw_video_pixel(pixel: pixel_type);
procedure Draw_video_line(pixel1, pixel2: pixel_type);
procedure Draw_video_h_line(pixel: pixel_type; h: integer);
procedure Draw_video_span(pixel: pixel_type; h: integer;
  color: color_type);
procedure Draw_video_rect(pixel1, pixel2: pixel_type);
procedure Draw_video_frame;

{*************************}
{ window refresh routines }
{*************************}
procedure Clear_video_window(color: color_type);
procedure Update_video_window;
procedure Show_video_window;
procedure Restore_video_window;

{***********************}
{ screen query routines }
{***********************}
function Video_screen_size: pixel_type;
function Video_screen_center: pixel_type;


implementation
uses
  Windows, Messages, Graphics, OpenGL, errors;


const
  max_windows = 16;
  debug = false;


type
  window_ptr_type = ^window_type;
  window_type = record
    window_id: integer;

    {****************************************}
    { platform independent window attributes }
    {****************************************}
    title: string_type;
    size, center: pixel_type;
    screen_box: screen_box_type;
    fullscreen: boolean;

    {*************************************}
    { platform specific window attributes }
    {*************************************}
    h_Wnd: HWND; // Global window handle
    h_DC: HDC; // Global device context
    h_RC: HGLRC; // OpenGL rendering context
  end; {window_type}


var
  window_ptr_array: array[1..max_windows] of window_ptr_type;
  current_window_ptr: window_ptr_type;
  window_number: integer;


  {******************}
  { initialize video }
  {******************}


procedure Init_video;
var
  counter: integer;
begin
  if debug then
    writeln('Initializing video.');

  {****************************}
  { initialize window pointers }
  {****************************}
  current_window_ptr := nil;
  window_number := 0;
  for counter := 1 to max_windows do
    window_ptr_array[counter] := nil;
end; {procedure Init_video}


procedure Init_GL();
begin
  {
  glClearColor(0.0, 0.0, 0.0, 0.0); // Black Background
  glShadeModel(GL_SMOOTH); // Enables Smooth Color Shading
  glClearDepth(1.0); // Depth Buffer Setup
  glEnable(GL_DEPTH_TEST); // Enable Depth Buffer
  glDepthFunc(GL_LESS); // The Type Of Depth Test To Do
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
  //Realy Nice perspective calculations
  glEnable(GL_TEXTURE_2D); // Enable Texture Mapping
  }

  gluOrtho2d(0, current_window_ptr^.size.h, 0, current_window_ptr^.size.v);
  // glViewport(0, 0, current_window_ptr^.size.h, current_window_ptr^.size.v);
  // glOrtho(-1.0, 1.0, -1.0, 1.0, -1.0, 1.0);
end; {Init_GL}


{****************************************}
{ routines to create and destroy windows }
{****************************************}


function New_video_window: window_ptr_type;
var
  window_ptr: window_ptr_type;
begin
  new(window_ptr);

  window_number := window_number + 1;
  if window_number > max_windows then
    Error('opened too many windows');

  window_ptr^.window_id := window_number;
  window_ptr_array[window_number] := window_ptr;

  New_video_window := window_ptr;
end; {functioin New_video_window}


procedure Free_video_window(var window_ptr: window_ptr_type);
begin
  window_ptr_array[window_ptr^.window_id] := nil;
  dispose(window_ptr);
  window_ptr := nil;
end; {procedure Free_video_window}


procedure Resize_GL_window(size: pixel_type);
begin
  {
  if (size.h = 0) then // prevent divide by zero exception
    size.h := 1;
  }
  // glViewport(0, 0, size.h, size.v); // Set the viewport for the OpenGL window
  // glMatrixMode(GL_PROJECTION); // Change Matrix Mode to Projection
  // glLoadIdentity(); // Reset View
  // gluPerspective(45.0, Width / Height, 1.0, 100.0);
  // glMatrixMode(GL_MODELVIEW); // Return to the modelview matrix
  // glLoadIdentity(); // Reset View
end; {Resize_GL_window}


function WndProc(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM):
  LRESULT;
  stdcall;
begin
  case (Msg) of
    WM_CREATE:
      begin
        // Insert stuff you want executed when the program starts
      end;
    WM_CLOSE:
      begin
        PostQuitMessage(0);
        Result := 0
      end;
    WM_SIZE: // Resize the window with the new width and height
      begin
        Resize_GL_window(To_pixel(LOWORD(lParam), HIWORD(lParam)));
        Result := 0;
      end;
    else
      Result := DefWindowProc(hWnd, Msg, wParam, lParam);
      // Default result if nothing happens
  end;
end; {procedure WndProc}


procedure Create_window(window_ptr: window_ptr_type);
const
  PixelDepth = 32;
  WND_TITLE = 'untitled';
var
  wndClass: TWndClass; // Window class
  dwStyle: DWORD; // Window styles
  dwExStyle: DWORD; // Extended window styles
  dmScreenSettings: DEVMODE; // Screen settings (fullscreen, etc...)
  h_Instance: HINST; // Current instance
begin
  with window_ptr^ do
    begin
      h_Instance := GetModuleHandle(nil); //Grab An Instance For Our Window
      ZeroMemory(@wndClass, SizeOf(wndClass));
      // Clear the window class structure

      with wndClass do // Set up the window class
        begin
          style := CS_HREDRAW or // Redraws entire window if length changes
          CS_VREDRAW or // Redraws entire window if height changes
          CS_OWNDC; // Unique device context for the window
          lpfnWndProc := @WndProc;
          // Set the window procedure to our func WndProc
          hInstance := h_Instance;
          hCursor := LoadCursor(0, IDC_ARROW);
          lpszClassName := 'OpenGL';
        end;

      if (RegisterClass(wndClass) = 0) then
        // Attemp to register the window class
        begin
          MessageBox(0, 'Failed to register the window class!', 'Error', MB_OK
            or
            MB_ICONERROR);
          Exit;
        end;

      // Change to fullscreen if so desired
      if Fullscreen then
        begin
          ZeroMemory(@dmScreenSettings, SizeOf(dmScreenSettings));
          with dmScreenSettings do
            begin // Set parameters for the screen setting
              dmSize := SizeOf(dmScreenSettings);
              dmPelsWidth := size.h; // Window width
              dmPelsHeight := size.v; // Window height
              dmBitsPerPel := PixelDepth; // Window color depth
              dmFields := DM_PELSWIDTH or DM_PELSHEIGHT or DM_BITSPERPEL;
            end;

          // Try to change screen mode to fullscreen
          if (ChangeDisplaySettings(dmScreenSettings, CDS_FULLSCREEN) =
            DISP_CHANGE_FAILED) then
            begin
              MessageBox(0, 'Unable to switch to fullscreen!', 'Error', MB_OK or
                MB_ICONERROR);
              Fullscreen := False;
            end;
        end;

      // If we are still in fullscreen then
      if (Fullscreen) then
        begin
          dwStyle := WS_POPUP or // Creates a popup window
          WS_CLIPCHILDREN // Doesn't draw within child windows
          or WS_CLIPSIBLINGS; // Doesn't draw within sibling windows
          dwExStyle := WS_EX_APPWINDOW; // Top level window
          ShowCursor(False); // Turn of the cursor (gets in the way)
        end
      else
        begin
          dwStyle := WS_OVERLAPPEDWINDOW or // Creates an overlapping window
          WS_CLIPCHILDREN or // Doesn't draw within child windows
          WS_CLIPSIBLINGS; // Doesn't draw within sibling windows
          dwExStyle := WS_EX_APPWINDOW or // Top level window
          WS_EX_WINDOWEDGE; // Border with a raised edge
        end;

      // writeln('size = ', size.h, ', ', size.v);
      // Attempt to create the actual window
      h_Wnd := CreateWindowEx(dwExStyle, // Extended window styles
        'OpenGL', // Class name
        WND_TITLE, // Window title (caption)
        dwStyle, // Window styles
        screen_box.min.h, screen_box.min.v, // Window position
        size.h, size.v, // Size of window
        0, // No parent window
        0, // No menu
        h_Instance, // Instance
        nil); // Pass nothing to WM_CREATE

      if h_Wnd = 0 then
        begin
          // glKillWnd(Fullscreen); // Undo all the settings we've changed
          Close_video_window(window_id);
          MessageBox(0, 'Unable to create window!', 'Error', MB_OK or
            MB_ICONERROR);
          Exit;
        end;

      // Try to get a device context
      h_DC := GetDC(h_Wnd);
      if (h_DC = 0) then
        begin
          // glKillWnd(Fullscreen);
          Close_video_window(window_id);
          MessageBox(0, 'Unable to get a device context!', 'Error', MB_OK or
            MB_ICONERROR);
          Exit;
        end;
    end;
end; {procedure Create_window}


procedure Create_GL_window(window_ptr: window_ptr_type);
const
  PixelDepth = 32;
  WND_TITLE = 'untitled';
var
  PixelFormat: GLuint; // Settings for the OpenGL rendering
  pfd: PIXELFORMATDESCRIPTOR; // Settings for the OpenGL window
begin
  with window_ptr^ do
    begin
      // Settings for the OpenGL window
      with pfd do
        begin
          nSize := SizeOf(PIXELFORMATDESCRIPTOR);
          // Size Of This Pixel Format Descriptor
          nVersion := 1; // The version of this data structure
          dwFlags := PFD_DRAW_TO_WINDOW // Buffer supports drawing to window
          or PFD_SUPPORT_OPENGL // Buffer supports OpenGL drawing
          or PFD_DOUBLEBUFFER; // Supports double buffering
          iPixelType := PFD_TYPE_RGBA; // RGBA color format
          cColorBits := PixelDepth; // OpenGL color depth
          cRedBits := 0; // Number of red bitplanes
          cRedShift := 0; // Shift count for red bitplanes
          cGreenBits := 0; // Number of green bitplanes
          cGreenShift := 0; // Shift count for green bitplanes
          cBlueBits := 0; // Number of blue bitplanes
          cBlueShift := 0; // Shift count for blue bitplanes
          cAlphaBits := 0; // Not supported
          cAlphaShift := 0; // Not supported
          cAccumBits := 0; // No accumulation buffer
          cAccumRedBits := 0; // Number of red bits in a-buffer
          cAccumGreenBits := 0; // Number of green bits in a-buffer
          cAccumBlueBits := 0; // Number of blue bits in a-buffer
          cAccumAlphaBits := 0; // Number of alpha bits in a-buffer
          cDepthBits := 16; // Specifies the depth of the depth buffer
          cStencilBits := 0; // Turn off stencil buffer
          cAuxBuffers := 0; // Not supported
          iLayerType := PFD_MAIN_PLANE; // Ignored
          bReserved := 0; // Number of overlay and underlay planes
          dwLayerMask := 0; // Ignored
          dwVisibleMask := 0; // Transparent color of underlay plane
          dwDamageMask := 0; // Ignored
        end;

      // Attempts to find the pixel format supported by a device context that is the best match to a given pixel format specification.
      PixelFormat := ChoosePixelFormat(h_DC, @pfd);
      if (PixelFormat = 0) then
        begin
          // glKillWnd(Fullscreen);
          Close_video_window(window_id);
          MessageBox(0, 'Unable to find a suitable pixel format', 'Error', MB_OK
            or MB_ICONERROR);
          Exit;
        end;

      // Sets the specified device context's pixel format to the format specified by the PixelFormat.
      if (not SetPixelFormat(h_DC, PixelFormat, @pfd)) then
        begin
          // glKillWnd(Fullscreen);
          Close_video_window(window_id);
          MessageBox(0, 'Unable to set the pixel format', 'Error', MB_OK or
            MB_ICONERROR);
          Exit;
        end;

      // Create a OpenGL rendering context
      h_RC := wglCreateContext(h_DC);
      if (h_RC = 0) then
        begin
          // glKillWnd(Fullscreen);
          Close_video_window(window_id);
          MessageBox(0, 'Unable to create an OpenGL rendering context', 'Error',
            MB_OK or MB_ICONERROR);
          Exit;
        end;

      // Makes the specified OpenGL rendering context the calling thread's current rendering context
      if (not wglMakeCurrent(h_DC, h_RC)) then
        begin
          // glKillWnd(Fullscreen);
          Close_video_window(window_id);
          MessageBox(0, 'Unable to activate OpenGL rendering context', 'Error',
            MB_OK or MB_ICONERROR);
          Exit;
        end;

      // Settings to ensure that the window is the topmost window
      ShowWindow(h_Wnd, SW_SHOW);
      SetForegroundWindow(h_Wnd);
      SetFocus(h_Wnd);

      // Ensure the OpenGL window is resized properly
      Resize_GL_window(size);
      Init_GL();
    end;
end; {Create_GL_window}


function Open_video_window(title: string_type;
  size, center: pixel_type): integer;
var
  window_ptr: window_ptr_type;
  new_window_id: integer;
begin
  if debug then
    writeln('Opening video window.');
  window_ptr := New_video_window;
  current_window_ptr := window_ptr;
  new_window_id := current_window_ptr^.window_id;

  {*******************}
  { initialize window }
  {*******************}
  window_ptr^.title := title;
  window_ptr^.size := size;
  window_ptr^.center := center;
  window_ptr^.fullscreen := Equal_pixels(size, Video_screen_size);
  window_ptr^.screen_box.min := Pixel_difference(Video_screen_center, Pixel_scale(size, 0.5));
  window_ptr^.screen_box.max := Pixel_sum(window_ptr^.screen_box.min, size);

  {***********************************************}
  { initialize system dependent window attributes }
  {***********************************************}
  Create_window(window_ptr);
  Create_GL_window(window_ptr);

  Open_video_window := new_window_id;
end; {procedure Open_video_window}


procedure Kill_GL_window(window_ptr: window_ptr_type);
begin
  with window_ptr^ do
    begin
      if Fullscreen then // Change back to non fullscreen
        begin
          ChangeDisplaySettings(devmode(nil^), 0);
          ShowCursor(True);
        end;

      // Makes current rendering context not current, and releases the device
      // context that is used by the rendering context.
      if (not wglMakeCurrent(h_DC, 0)) then
        MessageBox(0, 'Release of DC and RC failed!', 'Error', MB_OK or
          MB_ICONERROR);

      // Attempts to delete the rendering context
      if (not wglDeleteContext(h_RC)) then
        begin
          MessageBox(0, 'Release of rendering context failed!', 'Error', MB_OK or
            MB_ICONERROR);
          h_RC := 0;
        end;

      // Attemps to release the device context
      if ((h_DC = 1) and (ReleaseDC(h_Wnd, h_DC) <> 0)) then
        begin
          MessageBox(0, 'Release of device context failed!', 'Error', MB_OK or
            MB_ICONERROR);
          h_DC := 0;
        end;

      // Attempts to destroy the window
      if ((h_Wnd <> 0) and (not DestroyWindow(h_Wnd))) then
        begin
          MessageBox(0, 'Unable to destroy window!', 'Error', MB_OK or
            MB_ICONERROR);
          h_Wnd := 0;
        end;

      // Attempts to unregister the window class
      if (not UnRegisterClass('OpenGL', hInstance)) then
        begin
          MessageBox(0, 'Unable to unregister window class!', 'Error', MB_OK or
            MB_ICONERROR);
          // hInstance := NULL;
        end;
    end; {with}
end; {procedure Kill_GL_window}


procedure Close_video_window(window_id: integer);
var
  window_ptr: window_ptr_type;
begin
  if debug then
    writeln('Closing video window.');
  if window_id <> 0 then
    begin
      window_ptr := window_ptr_array[window_id];
      Kill_GL_window(window_ptr);
      if current_window_ptr = window_ptr then
        current_window_ptr := nil;
      Free_video_window(window_ptr);
    end;
end; {procedure Close_video_window}


{********************************}
{ routines to manipulate windows }
{********************************}


procedure Set_video_window(window_id: integer);
begin
  current_window_ptr := window_ptr_array[window_id];
end; {procedure Set_video_window}


function Get_video_window: integer;
begin
  Get_video_window := current_window_ptr^.window_id;
end; {function Get_video_window}


{*****************************}
{ routines to set video modes }
{*****************************}


procedure Set_backing_store(state: boolean);
begin
end; {procedure Set_backing_store}


{************************}
{ color related routines }
{************************}


procedure Set_video_color(color: color_type);
begin
  glColor3f(color.r, color.g, color.b);
end; {procedure Set_video_color}


procedure Set_video_dither(mode: boolean);
begin
end; {procedure Set_video_dither}


procedure Set_video_depth(depth: integer);
begin
end; {procedure Set_video_depth}


procedure Set_normal_color_selection;
begin
end; {procedure Set_normal_color_selection}


procedure Set_dynamic_color_selection;
begin
end; {procedure Set_dynamic_color_selection}


{******************}
{ drawing routines }
{******************}


procedure Move_to_video(pixel: pixel_type);
begin
end; {procedure Move_to_video}


procedure Draw_to_video(pixel: pixel_type);
begin
end; {procedure Draw_to_video}


procedure Draw_video_pixel(pixel: pixel_type);
begin
end; {procedure Draw_video_pixel}


procedure Draw_video_line(pixel1, pixel2: pixel_type);
begin
  if debug then
    writeln('Drawing video line from ', pixel1.h, ', ', pixel1.v,
      ' to ', pixel2.h, ', ', pixel2.v, '.');

  glBegin(GL_LINE);
  glVertex2i(pixel1.h, pixel1.v);
  glVertex2i(pixel2.h, pixel2.v);
  glEnd;
end; {procedure Draw_line}


procedure Draw_video_h_line(pixel: pixel_type; h: integer);
begin
end; {procedure Draw_video_h_line}


procedure Draw_video_span(pixel: pixel_type; h: integer;
  color: color_type);
begin
end; {procedure Draw_video_span}


procedure Draw_video_rect(pixel1, pixel2: pixel_type);
begin
end; {procedure Draw_video_rect}


procedure Draw_video_frame;
begin
end; {procedure Draw_video_frame}


{*************************}
{ window refresh routines }
{*************************}


procedure Clear_video_window(color: color_type);
begin
  if debug then
    writeln('Clearing video window');
  glClearColor(color.r, color.g, color.b, 0.0);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
end; {procedure Clear_video_window}


procedure Restore_partial_video_window;
begin
end; {procedure Restore_partial_video_window}


procedure Update_video_window;
begin
end; {procedure Update_video_window}


procedure Show_video_window;
begin
  if debug then
    writeln('Showing video window');
  glFlush();
  Swapbuffers(current_window_ptr^.h_Dc);
end; {procedure Show_video_window}


procedure Restore_video_window;
begin
end; {procedure Restore_video_window}


procedure Save_video_window;
begin
end; {procedure Save_video_window}


{***********************}
{ screen query routines }
{***********************}


function Video_screen_size: pixel_type;
begin
  Video_screen_size := To_pixel(1024, 768);
end; {function Video_screen_size}


function Video_screen_center: pixel_type;
begin
  Video_screen_center := Pixel_scale(Video_screen_size, 0.5);
end; {function Video_screen_center}


end. {module video}

