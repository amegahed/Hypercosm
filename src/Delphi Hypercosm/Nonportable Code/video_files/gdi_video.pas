unit gdi_video;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm             gdi_video                 3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the Windows GDI (graphics          }
{       device interface) level interface to the display        }
{       hardware.             				        }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  Windows, Messages, Graphics,
  strings, pixels, screen_boxes, colors, video, drawable;


type
  gdi_window_type = class(video_window_type, drawable_type)

  public
    {*****************************}
    { opening and closing methods }
    {*****************************}
    procedure Open(title: string_type; size, center: pixel_type); override;
    procedure Close; override;

    {*****************************}
    { window manipulation methods }
    {*****************************}
    procedure Activate; virtual;
    procedure Resize(size: pixel_type); virtual;

    {***********************}
    { color related methods }
    {***********************}
    procedure Set_color(color: color_type); override;
    function Get_color: color_type; override;

    {******************}
    { drawing routines }
    {******************}
    procedure Move_to(pixel: pixel_type); override;
    procedure Line_to(pixel: pixel_type); override;
    procedure Draw_pixel(pixel: pixel_type); override;
    procedure Fill_rect(pixel1, pixel2: pixel_type); override;

    {*************************}
    { window refresh routines }
    {*************************}
    procedure Clear; override;
    procedure Update; override;
    procedure Show; override;

  protected
    {*************************************}
    { platform specific window attributes }
    {*************************************}
    h_Wnd: HWND; 		// Global window handle
    h_DC: HDC; 			// Global device context

  private
    color_ref: COLORREF; 	// Current drawing color
  end; {gdi_window}


implementation
uses
  new_memory, errors;


const
  debug = false;


function WndProc(hWnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM):
  LRESULT; stdcall;
begin
  result := 0;

  case (Msg) of

    {**********************}
    { handle window events }
    {**********************}
    WM_CREATE:
      begin
        if debug then
          writeln('handling window create event');
      end;
    WM_CLOSE:
      begin
        if debug then
          writeln('handling window close event');
        PostQuitMessage(0);
      end;
    WM_SIZE:
      begin
        if debug then
          writeln('handling window resize event');
        gdi_window_type(current_window).Resize(To_pixel(LOWORD(lParam), HIWORD(lParam)));
      end;
    WM_MOVE:
      begin
        if debug then
          writeln('handling window move event');
      end;
    WM_DISPLAYCHANGE:
      begin
        if debug then
          writeln('handling window display change event');
        Error('Display properties have changed.');
      end;
    WM_PAINT:
      begin
        if debug then
          writeln('handling window paint event');
      end;
    WM_SETFOCUS:
      begin
        if debug then
          writeln('handling window set focus event');
      end;
    WM_KILLFOCUS:
      begin
        if debug then
          writeln('handling window kill focus event');
      end;

    {*********************}
    { handle mouse events }
    {*********************}
    WM_LBUTTONDOWN:
      begin
        if debug then
          writeln('handling window left button down event');
        current_window.mouse_state.button_state[1] := true;
      end;
    WM_LBUTTONUP:
      begin
        if debug then
          writeln('handling window left button up event');
        current_window.mouse_state.button_state[1] := false;
      end;
    WM_RBUTTONDOWN:
      begin
        if debug then
          writeln('handling window right button down event');
        current_window.mouse_state.button_state[2] := true;
      end;
    WM_RBUTTONUP:
      begin
        if debug then
          writeln('handling window right button up event');
        current_window.mouse_state.button_state[2] := false;
      end;
    WM_MOUSEMOVE:
      begin
        if debug then
          writeln('handling window mouse move event');
        current_window.mouse_state.mouse_location.v := HIWORD(lParam);
        current_window.mouse_state.mouse_location.h := LOWORD(lParam);
      end;

    {************************}
    { handle keyboard events }
    {************************}
    WM_KEYDOWN:
      begin
        if debug then
          writeln('handling window key down event');
        current_window.keyboard_state.last_key := wParam;
        current_window.keyboard_state.key_state[wParam] := True;
      end;
    WM_KEYUP:
      begin
        if debug then
          writeln('handling window key up event');
        current_window.keyboard_state.last_key := wParam;
        current_window.keyboard_state.key_state[wParam] := False;
      end;

    {***********************}
    { default event handler }
    {***********************}
    else
      result := DefWindowProc(hWnd, Msg, wParam, lParam);
  end;
end; {procedure WndProc}


{*****************************}
{ opening and closing methods }
{*****************************}


procedure gdi_window_type.Open(title: string_type; size, center: pixel_type);
const
  PixelDepth = 32;
var
  chars: array[1 .. string_size] of char;
  wndClass: TWndClass; // Window class
  dwStyle: DWORD; // Window styles
  dwExStyle: DWORD; // Extended window styles
  dmScreenSettings: DEVMODE; // Screen settings (fullscreen, etc...)
  h_Instance: HINST; // Current instance
  counter: integer;
begin
  inherited Open(title, size, center);

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
        or MB_ICONERROR);
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
  if fullscreen then
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

  // copy string to array of chars
  //
  for counter := 1 to Str_length(title) do
    begin
      chars[counter] := title[counter];
    end;
  chars[Str_length(title) + 1] := chr(0);

  // Attempt to create the actual window
  //
  h_Wnd := CreateWindowEx(dwExStyle, // Extended window styles
    'OpenGL', // Class name
    @chars, // Window title (caption)
    dwStyle, // Window styles
    screen_box.min.h, screen_box.min.v, // Window position
    size.h, size.v, // Size of window
    0, // No parent window
    0, // No menu
    h_Instance, // Instance
    nil); // Pass nothing to WM_CREATE

  if h_Wnd = 0 then
    begin
      Close;
      MessageBox(0, 'Unable to create window!', 'Error', MB_OK or
        MB_ICONERROR);
      Exit;
    end;

  // Try to get a device context
  //
  h_DC := GetDC(h_Wnd);
  if (h_DC = 0) then
    begin
      Close;
      MessageBox(0, 'Unable to get a device context!', 'Error', MB_OK or
        MB_ICONERROR);
      Exit;
    end;

  // Ensure that the window is the topmost window
  //
  Activate;
end; {procedure gdi_window_type.Open}


procedure gdi_window_type.Close;
begin
  // Change back to non fullscreen
  //
  if fullscreen then
    begin
      ChangeDisplaySettings(devmode(nil^), 0);
      ShowCursor(True);
    end;

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

  inherited Close;
end; {procedure gdi_window_type.Close}


{*****************************}
{ window manipulation methods }
{*****************************}


procedure gdi_window_type.Activate;
begin
  ShowWindow(h_Wnd, SW_SHOW);
  SetForegroundWindow(h_Wnd);
  SetFocus(h_Wnd);
end; {procedure gdi_window_type.Activate}


procedure gdi_window_type.Resize(size: pixel_type);
begin
  inherited Resize(size);
end; {procedure gdi_window_type.Resize}


{***********************}
{ color related methods }
{***********************}


procedure gdi_window_type.Set_color(color: color_type);
begin
end; {procedure gdi_window_type.Set_color}


function gdi_window_type.Get_color: color_type;
begin
end; {function gdi_window_type.Get_color}


{******************}
{ drawing routines }
{******************}


procedure gdi_window_type.Move_to(pixel: pixel_type);
begin
  MoveToEx(h_DC, pixel.h, pixel.v, nil);
end; {procedure gdi_window_type.Move}


procedure gdi_window_type.Line_to(pixel: pixel_type);
begin
  LineTo(h_DC, pixel.h, pixel.v);
end; {procedure gdi_window_type.Line_to}


procedure gdi_window_type.Draw_pixel(pixel: pixel_type);
begin
  SetPixel(h_DC, pixel.h, pixel.v, color_ref);
end; {procedure gdi_window_type.Draw_pixel}


procedure gdi_window_type.Fill_rect(pixel1, pixel2: pixel_type);
begin
  Rectangle(h_DC, pixel1.h, pixel1.v, pixel2.h, pixel2.v);
end; {procedure gdi_window_type.Fill_rect}


{*************************}
{ window refresh routines }
{*************************}


procedure gdi_window_type.Clear;
begin
  Fill_rect(null_pixel, size);
end; {procedure gdi_window_type.Clear}


procedure gdi_window_type.Update;
begin
end; {procedure gdi_window_type.Update}


procedure gdi_window_type.Show;
begin
end; {procedure gdi_window_type.Show}


end.

