unit opengl_video;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            opengl_video               3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains the OpenGL level interface 	}
{	to the display hardware.             		        }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  Windows, Graphics, OpenGL,
  strings, pixels, screen_boxes, colors, video, gdi_video, drawable;


type
  opengl_window_type = class(gdi_window_type, drawable_type,
    double_bufferable_type)

  public
    {*****************************}
    { opening and closing methods }
    {*****************************}
    procedure Open(title: string_type; size, center: pixel_type); override;
    procedure Close; override;

    {*****************************}
    { window manipulation methods }
    {*****************************}
    procedure Resize(size: pixel_type); override;

    {***********************}
    { display mode routines }
    {***********************}
    procedure Set_double_buffer_mode(mode: boolean);
    function Get_double_buffer_mode: boolean;

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
    procedure Draw_span(h1, h2, v: integer; color: color_type); override;

    {*************************}
    { window refresh routines }
    {*************************}
    procedure Clear; override;
    procedure Update; override;
    procedure Show; override;

  private
    {*************************************}
    { platform specific window attributes }
    {*************************************}
    h_RC: HGLRC; // OpenGL rendering context handle
    current_color: color_type;
    current_pixel: pixel_type;
    double_buffer_mode: boolean;
  end; {opengl_window}


implementation


{*****************************}
{ opening and closing methods }
{*****************************}


procedure opengl_window_type.Open(title: string_type; size, center: pixel_type);
const
  PixelDepth = 32;
var
  pfd: TPIXELFORMATDESCRIPTOR; // Settings for the OpenGL window
  PixelFormat: GLuint; // Settings for the OpenGL rendering
begin
  inherited Open(title, size, center);

  // Settings for the window
  //
  with pfd do
    begin
      nSize := SizeOf(TPIXELFORMATDESCRIPTOR);
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

  // Attempts to find the pixel format supported by a device context
  // that is the best match to a given pixel format specification.
  //
  PixelFormat := ChoosePixelFormat(h_DC, @pfd);
  if (PixelFormat = 0) then
    begin
      Close;
      MessageBox(0, 'Unable to find a suitable pixel format', 'Error', MB_OK or
        MB_ICONERROR);
      Exit;
    end;

  // Sets the specified device context's pixel format to the format
  // specified by the PixelFormat.
  //
  if (not SetPixelFormat(h_DC, PixelFormat, @pfd)) then
    begin
      Close;
      MessageBox(0, 'Unable to set the pixel format', 'Error', MB_OK or
        MB_ICONERROR);
      Exit;
    end;

  // Create a OpenGL rendering context
  //
  h_RC := wglCreateContext(h_DC);
  if (h_RC = 0) then
    begin
      Close;
      MessageBox(0, 'Unable to create an OpenGL rendering context', 'Error',
        MB_OK or MB_ICONERROR);
      Exit;
    end;

  // Makes the specified OpenGL rendering context the calling thread's
  // current rendering context
  //
  if (not wglMakeCurrent(h_DC, h_RC)) then
    begin
      Close;
      MessageBox(0, 'Unable to activate OpenGL rendering context', 'Error', MB_OK
        or MB_ICONERROR);
      Exit;
    end;

  // Ensure that the window is the topmost window
  //
  Activate;
  Resize(Get_size);
end; {procedure opengl_window_type.Open}


procedure opengl_window_type.Close;
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

  inherited Close;
end; {procedure opengl_window_type.Close}


procedure opengl_window_type.Resize(size: pixel_type);
begin
  inherited Resize(size);

  // Set the viewport for the OpenGL window
  //
  glLoadIdentity;
  glViewport(0, 0, size.h, size.v);
  glOrtho(0, size.h, size.v, 0, 0, 1);
end; {procedure opengl_window_type.Resize}


{***********************}
{ display mode routines }
{***********************}


procedure opengl_window_type.Set_double_buffer_mode(mode: boolean);
begin
  self.double_buffer_mode := mode;
  glDrawBuffer(GL_BACK);

  {
  if mode then
      glDrawBuffer(GL_BACK)
  else
      glDrawBuffer(GL_FRONT);
  }
end; {procedure opengl_window_type.Set_double_buffer_mode}


function opengl_window_type.Get_double_buffer_mode: boolean;
begin
  Get_double_buffer_mode := double_buffer_mode;
end; {function opengl_window_type.Get_double_buffer_mode}


{***********************}
{ color related methods }
{***********************}


procedure opengl_window_type.Set_color(color: color_type);
begin
  current_color := color;
end; {procedure opengl_window_type.Set_color}


function opengl_window_type.Get_color: color_type;
begin
  Get_color := current_color;
end; {function opengl_window_type.Get_color}


{******************}
{ drawing routines }
{******************}


procedure opengl_window_type.Move_to(pixel: pixel_type);
begin
  current_pixel := pixel;
end; {procedure opengl_window_type.Move}


procedure opengl_window_type.Line_to(pixel: pixel_type);
begin
  glBegin(GL_LINES);
  glColor3f(current_color.r, current_color.g, current_color.b);
  glVertex2i(current_pixel.h, current_pixel.v);
  glVertex2i(pixel.h, pixel.v);
  glEnd;
  current_pixel := pixel;
end; {procedure opengl_window_type.Line_to}


procedure opengl_window_type.Draw_pixel(pixel: pixel_type);
begin
  glBegin(GL_POINTS);
  glColor3f(current_color.r, current_color.g, current_color.b);
  glVertex2i(pixel.h, pixel.v);
  glEnd;
end; {procedure opengl_window_type.Draw_pixel}


procedure opengl_window_type.Fill_rect(pixel1, pixel2: pixel_type);
begin
  glBegin(GL_POLYGON);
  glColor3f(current_color.r, current_color.g, current_color.b);
  glVertex2i(pixel1.h, pixel1.v);
  glVertex2i(pixel2.h + 1, pixel1.v);
  glVertex2i(pixel2.h + 1, pixel2.v + 1);
  glVertex2i(pixel1.h, pixel2.v + 1);
  glEnd;
end; {procedure opengl_window_type.Fill_rect}


procedure opengl_window_type.Draw_span(h1, h2, v: integer; color: color_type);
begin
  glBegin(GL_LINES);
  glColor3f(current_color.r, current_color.g, current_color.b);
  glVertex2i(h1, v);
  glColor3f(color.r, color.g, color.b);
  glVertex2i(h2, v);
  glEnd;
end; {procedure opengl_window_type.Draw_span}


{*************************}
{ window refresh routines }
{*************************}


procedure opengl_window_type.Clear;
begin
  Resize(size);
  glDisable(GL_DEPTH_TEST);
  glClearColor(current_color.r, current_color.g, current_color.b, 0);
  glClear(GL_COLOR_BUFFER_BIT);
end; {procedure opengl_window_type.Clear}


procedure opengl_window_type.Update;
begin
  if double_buffer_mode then
    glFlush()
  else
    SwapBuffers(h_DC);
end; {procedure opengl_window_type.Update}


procedure opengl_window_type.Show;
begin
  if double_buffer_mode then
    SwapBuffers(h_DC);
end; {procedure opengl_window_type.Show}


end.

