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


type
  video_window_ptr_type = ^video_window_type;
  video_window_type = record

    {****************************************}
    { platform independent window attributes }
    {****************************************}
    title: string_type;
    size, center: pixel_type;
    screen_box: screen_box_type;
    fullscreen: boolean;

    {**************************************}
    { platform dependent window attributes }
    {**************************************}
    system_window_ptr: Pointer;
  end; {video_window_type}


procedure Init_video;

{****************************************}
{ routines to create and destroy windows }
{****************************************}
function Open_video_window(title: string_type;
  size, center: pixel_type): video_window_ptr_type;
procedure Close_video_window(var video_window_ptr: video_window_ptr_type);
procedure Close_all_video_windows;

{********************************}
{ routines to manipulate windows }
{********************************}
procedure Set_current_video_window(video_window_ptr: video_window_ptr_type);
function Get_current_video_window: video_window_ptr_type;

{*****************************}
{ routines to set video modes }
{*****************************}
procedure Set_video_backing_store(state: boolean);

{************************}
{ color related routines }
{************************}
procedure Set_video_color(color: color_type);
procedure Set_video_dither(mode: boolean);
procedure Set_video_bit_depth(depth: integer);
procedure Set_video_normal_color_selection;
procedure Set_video_dynamic_color_selection;

{******************}
{ drawing routines }
{******************}
procedure Move_to_video(pixel: pixel_type);
procedure Line_to_video(pixel: pixel_type);
procedure Draw_video_pixel(pixel: pixel_type);
procedure Draw_video_line(pixel1, pixel2: pixel_type);
procedure Draw_video_h_line(h1, h2, v: integer);
procedure Draw_video_span(h1, h2, v: integer;
  color: color_type);
procedure Draw_video_rect(pixel1, pixel2: pixel_type);
procedure Fill_video_rect(pixel1, pixel2: pixel_type);

{*************************}
{ window refresh routines }
{*************************}
procedure Clear_video_window;
procedure Update_video_window;
procedure Show_video_window;

{***********************}
{ screen query routines }
{***********************}
function Get_screen_size: pixel_type;
function Get_screen_center: pixel_type;


implementation
uses
  Windows, Messages, Graphics, errors;


const
  debug = false;


type
  system_window_ptr_type = ^system_window_type;
  system_window_type = record
    {*************************************}
    { platform specific window attributes }
    {*************************************}
    h_Wnd: HWND; // Global window handle
    h_DC: HDC; // Global device context
    color_ref: COLORREF // Current drawing color
  end; {system_window_type}


  window_ref_ptr_type = ^window_ref_type;
  window_ref_type = record
    video_window_ptr: video_window_ptr_type;
    next: window_ref_ptr_type;
  end; {window_ref_type}


var
  current_window_ptr: video_window_ptr_type;
  window_ref_list: window_ref_ptr_type;


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
  window_ref_list := nil;
end; {procedure Init_video}


{***********************************************}
{ routines for window reference list management }
{***********************************************}


procedure Add_window_reference(video_window_ptr: video_window_ptr_type);
var
  window_ref_ptr: window_ref_ptr_type;
begin
  new(window_ref_ptr);
  window_ref_ptr^.video_window_ptr := video_window_ptr;

  {*******************************}
  { add reference to head of list }
  {*******************************}
  window_ref_ptr^.next := window_ref_list;
  window_ref_list := window_ref_ptr;
end; {procedure Add_window_reference}


procedure Remove_window_reference(video_window_ptr: video_window_ptr_type);
var
  prev, next: window_ref_ptr_type;
  found: boolean;
begin
  prev := nil;
  next := nil;

  {*******************************}
  { find window in reference list }
  {*******************************}
  found := false;
  next := window_ref_list;
  while not found and (next <> nil) do
    begin
      if next^.video_window_ptr = video_window_ptr then
        found := true
      else
        begin
          prev := next;
          next := next^.next;
        end;
    end;

  {****************************************}
  { unlink and dispose of window reference }
  {****************************************}
  if found then
    begin
      if prev <> nil then
        prev^.next := next^.next
      else
        window_ref_list := next^.next;
      dispose(next);
    end;
end; {procedure Remove_window_reference}


procedure Close_all_video_windows;
begin
  while (window_ref_list <> nil) do
    begin
      Close_video_window(window_ref_list^.video_window_ptr);
      Remove_window_reference(window_ref_list^.video_window_ptr);
    end;
end; {procedure Close_all_video_windows}


{****************************************}
{ routines to create and destroy windows }
{****************************************}


function New_system_window: system_window_ptr_type;
var
  system_window_ptr: system_window_ptr_type;
begin
  new(system_window_ptr);

  {************************************************}
  { initialize platform specific window attributes }
  {************************************************}
  with system_window_ptr^ do
    begin
      h_Wnd := 0;
      h_DC := 0;
    end;

  New_system_window := system_window_ptr;
end; {function New_system_window}


function New_video_window: video_window_ptr_type;
var
  video_window_ptr: video_window_ptr_type;
begin
  new(video_window_ptr);

  with video_window_ptr^ do
    begin
      {*************************}
      { initialize video window }
      {*************************}
      title := '';
      size := null_pixel;
      center := null_pixel;
      screen_box := null_screen_box;
      fullscreen := false;

      {**************************************}
      { platform dependent window attributes }
      {**************************************}
      system_window_ptr := nil;
    end;

  {*************************************}
  { add reference to new window to list }
  {*************************************}
  Add_window_reference(video_window_ptr);

  New_video_window := video_window_ptr;
end; {function New_video_window}


procedure Free_video_window(var video_window_ptr: video_window_ptr_type);
var
  video_window_reference_ptr: video_window_ptr_type;
begin
  video_window_reference_ptr := video_window_ptr;
  dispose(video_window_ptr);
  video_window_ptr := nil;

  {***********************************}
  { remove window reference from list }
  {***********************************}
  Remove_window_reference(video_window_reference_ptr);
end; {procedure Free_video_window}


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
        current_window_ptr^.size.h := LOWORD(lParam);
        current_window_ptr^.size.v := HIWORD(lParam);
      end;
    else
      Result := DefWindowProc(hWnd, Msg, wParam, lParam);
      // Default result if nothing happens
  end;
end; {procedure WndProc}


procedure Create_video_window(video_window_ptr: video_window_ptr_type);
const
  PixelDepth = 32;
  WND_TITLE = 'untitled';
var
  wndClass: TWndClass; // Window class
  dwStyle: DWORD; // Window styles
  dwExStyle: DWORD; // Extended window styles
  dmScreenSettings: DEVMODE; // Screen settings (fullscreen, etc...)
  h_Instance: HINST; // Current instance
  pfd: TPIXELFORMATDESCRIPTOR; // Settings for the OpenGL window
begin
  with video_window_ptr^ do
    begin
      // Grab An Instance For Our Window
      //
      h_Instance := GetModuleHandle(nil);

      // Clear the window class structure
      //
      ZeroMemory(@wndClass, SizeOf(wndClass));

      // Set up the window class
      //
      with wndClass do
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

      // Attempt to register the window class
      //
      if (RegisterClass(wndClass) = 0) then
        begin
          MessageBox(0, 'Failed to register the window class!', 'Error', MB_OK
            or
            MB_ICONERROR);
          Exit;
        end;

      // Change to fullscreen if so desired
      //
      if fullscreen then
        begin
          ZeroMemory(@dmScreenSettings, SizeOf(dmScreenSettings));

          // Set parameters for the screen setting
          //
          with dmScreenSettings do
            begin
              dmSize := SizeOf(dmScreenSettings);
              dmPelsWidth := size.h; // Window width
              dmPelsHeight := size.v; // Window height
              dmBitsPerPel := PixelDepth; // Window color depth
              dmFields := DM_PELSWIDTH or DM_PELSHEIGHT or DM_BITSPERPEL;
            end;

          // Try to change screen mode to fullscreen
          //
          if (ChangeDisplaySettings(dmScreenSettings, CDS_FULLSCREEN) =
            DISP_CHANGE_FAILED) then
            begin
              MessageBox(0, 'Unable to switch to fullscreen!', 'Error', MB_OK or
                MB_ICONERROR);
              fullscreen := False;
            end;
        end;

      // If we are still in fullscreen then
      //
      if (fullscreen) then
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

      system_window_ptr := Pointer(New_system_window);
      with system_window_ptr_type(system_window_ptr)^ do
        begin
          // Attempt to create the actual window
          //
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
              Close_video_window(video_window_ptr);
              MessageBox(0, 'Unable to create window!', 'Error', MB_OK or
                MB_ICONERROR);
              Exit;
            end;

          // Try to get a device context
          h_DC := GetDC(h_Wnd);
          if (h_DC = 0) then
            begin
              Close_video_window(video_window_ptr);
              MessageBox(0, 'Unable to get a device context!', 'Error', MB_OK or
                MB_ICONERROR);
              Exit;
            end;

          // Settings for the OpenGL window
          with pfd do
            begin
              nSize := SizeOf(TPIXELFORMATDESCRIPTOR);
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

          // Settings to ensure that the window is the topmost window
          //
          ShowWindow(h_Wnd, SW_SHOW);
          SetForegroundWindow(h_Wnd);
          SetFocus(h_Wnd);
        end;
    end;
end; {procedure Create_video_window}


function Open_video_window(title: string_type;
  size, center: pixel_type): video_window_ptr_type;
var
  video_window_ptr: video_window_ptr_type;
begin
  if debug then
    writeln('Opening video window.');
  video_window_ptr := New_video_window;
  current_window_ptr := video_window_ptr;

  {*******************}
  { initialize window }
  {*******************}
  video_window_ptr^.title := title;
  video_window_ptr^.size := size;
  video_window_ptr^.center := center;
  video_window_ptr^.fullscreen := Equal_pixels(size, Get_screen_size);
  video_window_ptr^.screen_box.min := Pixel_difference(Get_screen_center,
    Pixel_scale(size, 0.5));
  video_window_ptr^.screen_box.max := Pixel_sum(video_window_ptr^.screen_box.min, size);

  {***********************************************}
  { initialize system dependent window attributes }
  {***********************************************}
  Create_video_window(video_window_ptr);

  Open_video_window := video_window_ptr;
end; {procedure Open_video_window}


procedure Kill_video_window(video_window_ptr: video_window_ptr_type);
begin
  with video_window_ptr^ do
    begin
      // Change back to non fullscreen
      //
      if fullscreen then
        begin
          ChangeDisplaySettings(devmode(nil^), 0);
          ShowCursor(True);
        end;

      with system_window_ptr_type(system_window_ptr)^ do
        begin
          // Make current rendering context not current, and release the device
          // context that is used by the rendering context.
          //
          if (not wglMakeCurrent(h_DC, 0)) then
            MessageBox(0, 'Release of DC and RC failed!', 'Error', MB_OK or
              MB_ICONERROR);

          // Attempt to release the device context
          //
          if ((h_DC > 0) and (ReleaseDC(h_Wnd, h_DC) = 0)) then
            begin
              MessageBox(0, 'Release of device context failed!', 'Error', MB_OK
                or
                MB_ICONERROR);
              h_DC := 0;
            end;

          // Attempt to destroy the window
          //
          if ((h_Wnd <> 0) and (not DestroyWindow(h_Wnd))) then
            begin
              MessageBox(0, 'Unable to destroy window!', 'Error', MB_OK or
                MB_ICONERROR);
              h_Wnd := 0;
            end;

          // Attempt to unregister the window class
          //
          if (not UnRegisterClass('OpenGL', hInstance)) then
            begin
              MessageBox(0, 'Unable to unregister window class!', 'Error', MB_OK
                or
                MB_ICONERROR);
              hInstance := 0;
            end;
        end;
    end;
end; {procedure Kill_video_window}


procedure Close_video_window(var video_window_ptr: video_window_ptr_type);
begin
  if debug then
    writeln('Closing video window.');
  if video_window_ptr <> nil then
    begin
      Kill_video_window(video_window_ptr);
      if current_window_ptr = video_window_ptr then
        current_window_ptr := nil;
      Free_video_window(video_window_ptr);
    end;
end; {procedure Close_video_window}


{********************************}
{ routines to manipulate windows }
{********************************}


procedure Set_current_video_window(video_window_ptr: video_window_ptr_type);
begin
  current_window_ptr := video_window_ptr;
end; {procedure Set_current_video_window}


function Get_current_video_window: video_window_ptr_type;
begin
  Get_current_video_window := current_window_ptr;
end; {function Get_current_video_window}


{*****************************}
{ routines to set video modes }
{*****************************}


procedure Set_video_backing_store(state: boolean);
begin
end; {procedure Set_video_backing_store}


{************************}
{ color related routines }
{************************}


function Color_to_COLORREF(color: color_type): COLORREF;
var
  red, green, blue: Byte;
begin
  red := trunc(color.r * 255);
  green := trunc(color.g * 255);
  blue := trunc(color.b * 255);
  Color_to_COLORREF := RGB(red, green, blue);
end; {function Color_to_COLORREF}


procedure Set_video_color(color: color_type);
begin
  with system_window_ptr_type(current_window_ptr^.system_window_ptr)^ do
    begin
      color_ref := GetNearestColor(h_DC, Color_to_COLORREF(color));
      // color_ref := SetDCPenColor(h_DC, color_ref);
    end;
end; {procedure Set_video_color}


procedure Set_video_dither(mode: boolean);
begin
end; {procedure Set_video_dither}


procedure Set_video_bit_depth(depth: integer);
begin
end; {procedure Set_video_bit_depth}


procedure Set_video_normal_color_selection;
begin
end; {procedure Set_video_normal_color_selection}


procedure Set_video_dynamic_color_selection;
begin
end; {procedure Set_video_dynamic_color_selection}


{******************}
{ drawing routines }
{******************}


procedure Move_to_video(pixel: pixel_type);
begin
  with system_window_ptr_type(current_window_ptr^.system_window_ptr)^ do
    MoveToEx(h_DC, pixel.h, pixel.v, nil);
end; {procedure Move_to_video}


procedure Line_to_video(pixel: pixel_type);
begin
  with system_window_ptr_type(current_window_ptr^.system_window_ptr)^ do
    LineTo(h_DC, pixel.h, pixel.v);
end; {procedure Line_to_video}


procedure Draw_video_pixel(pixel: pixel_type);
begin
  with system_window_ptr_type(current_window_ptr^.system_window_ptr)^ do
    SetPixel(h_DC, pixel.h, pixel.v, color_ref);
end; {procedure Draw_video_pixel}


procedure Draw_video_line(pixel1, pixel2: pixel_type);
begin
  Move_to_video(pixel1);
  Line_to_video(pixel2);
end; {procedure Draw_video_line}


procedure Draw_video_h_line(h1, h2, v: integer);
begin
  Move_to_video(To_pixel(h1, v));
  Line_to_video(To_pixel(h2, v));
end; {procedure Draw_video_h_line}


procedure Draw_video_span(h1, h2, v: integer;
  color: color_type);
begin
  Move_to_video(To_pixel(h1, v));
  Line_to_video(To_pixel(h2, v));
end; {procedure Draw_video_span}


procedure Draw_video_rect(pixel1, pixel2: pixel_type);
begin
  Move_to_video(pixel1);
  Line_to_video(To_pixel(pixel2.h, pixel1.v));
  Line_to_video(To_pixel(pixel2.v, pixel1.v));
  Line_to_video(To_pixel(pixel1.h, pixel2.v));
  Line_to_video(pixel1);
end; {procedure Draw_video_rect}


procedure Fill_video_rect(pixel1, pixel2: pixel_type);
begin
  with system_window_ptr_type(current_window_ptr^.system_window_ptr)^ do
    Rectangle(h_DC, pixel1.h, pixel1.v, pixel2.h, pixel2.v);
end; {procedure Fill_video_rect}

{*************************}
{ window refresh routines }
{*************************}


procedure Clear_video_window;
begin
  if debug then
    writeln('Clearing video window');
  with current_window_ptr^ do
    with system_window_ptr_type(system_window_ptr)^ do
      begin
        SetBkColor(h_DC, color_ref);
        Rectangle(h_DC, 0, 0, size.h, size.v);
      end;
end; {procedure Clear_video_window}


procedure Update_video_window;
begin
end; {procedure Update_video_window}


procedure Show_video_window;
begin
  if debug then
    writeln('Showing video window');
  with system_window_ptr_type(current_window_ptr^.system_window_ptr)^ do
    ShowWindow(h_DC, SW_SHOW);
end; {procedure Show_video_window}


{***********************}
{ screen query routines }
{***********************}


function Get_screen_size: pixel_type;
begin
  Get_screen_size := To_pixel(1024, 768);
end; {function Get_screen_size}


function Get_screen_center: pixel_type;
begin
  Get_screen_center := Pixel_scale(Get_screen_size, 0.5);
end; {function Get_screen_center}


end. {module video}

