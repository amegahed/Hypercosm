unit image_files;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm            image_files                3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       This module contains routines to save pictures          }
{       to a file.                                              }
{                                                               }
{***************************************************************}
{                 Copyright 1999 Hypercosm Inc.                 }
{***************************************************************}


interface
uses
  images, strings;


{***********************************************}
{ routines to load and save raster based images }
{***********************************************}
procedure Save_image(name: string_type);
function Load_image(name: string_type): image_ptr_type;

{*************************************************************}
{ routines to save raster based images of a particular format }
{*************************************************************}
procedure Save_raw_image(name: string_type;
  image_ptr: image_ptr_type);
procedure Save_targa_image(name: string_type;
  image_ptr: image_ptr_type);
procedure Save_jpeg_image(name: string_type;
  image_ptr: image_ptr_type);

{*************************************************************}
{ routines to load raster based images of a particular format }
{*************************************************************}
function Load_raw_image(name: string_type): image_ptr_type;
function Load_targa_image(name: string_type): image_ptr_type;
function Load_jpeg_image(name: string_type): image_ptr_type;


implementation
uses
  Graphics, jpeg,
  errors, vectors, pixels, pixel_colors, bitmaps, find_files;


const
  memory_alert = false;


type
  TRGBTriple = packed record RgbtBlue: BYTE;
    rgbtGreen: BYTE;
    rgbtRed: BYTE;
  end;


  {**************************************}
  { routines to save raster based images }
  {**************************************}


procedure Save_raw_image(name: string_type;
  image_ptr: image_ptr_type);
begin
end; {procedure Save_raw_image}


procedure Save_targa_image(name: string_type;
  image_ptr: image_ptr_type);
begin
end; {procedure Save_targa_image}


procedure Save_jpeg_image(name: string_type;
  image_ptr: image_ptr_type);
begin
end; {procedure Save_jpeg_image}


{**************************************}
{ routines to load raster based images }
{**************************************}


function Load_raw_image(name: string_type): image_ptr_type;
begin
  Load_raw_image := nil;
end; {function Load_raw_image}


function Load_targa_image(name: string_type): image_ptr_type;
begin
  Load_targa_image := nil;
end; {function Load_targa_image}


function Load_jpeg_image(name: string_type): image_ptr_type;
begin
  Load_jpeg_image := nil;
end; {function Load_jpeg_image}


{***********************************************}
{ routines to load and save raster based images }
{***********************************************}


procedure Save_image(name: string_type);
begin
end; {procedure Save_image}


function Load_image(name: string_type): image_ptr_type;
type
  TRGBTripleArray = array[WORD] of TRGBTriple;
  pRGBTripleArray = ^TRGBTripleArray;
var
  Picture: TPicture;
  Bitmap: TBitmap;
  Scanline: pRGBTripleArray;
  image_ptr: image_ptr_type;
  h, v: integer;
  pixel_color: pixel_color_type;
  directory_name: string_type;
begin
  Picture := TPicture.Create;
  image_ptr := nil;

  if Found_file_in_search_path(name, search_path_ptr, directory_name) then
    begin
      try
        // Try to load the picture from a file.
        // I'm wrapping it in a try..except to capture
        // any exceptions that happen in loading the image from a stream.
        //
        try
          Picture.LoadFromFile(directory_name + name);
        except
          on E: EInvalidGraphic do
            begin
              Error('Load Error: ' + E.Message);
            end;
        end;

        Bitmap := TBitmap.Create;

        try
          // Assign the Graphic to the Bitmap; any drawing errors/exceptions
          // will happen here, and will be captured and shown to the user
          //
          Bitmap.Assign(Picture.Graphic);
          Bitmap.PixelFormat := pf24bit;
          image_ptr := New_image(To_pixel(Picture.Width, Picture.Width));

          try
            for v := 0 to Bitmap.Height - 1 do
              begin
                Scanline := Bitmap.ScanLine[Bitmap.Height - 1 - v];
                for h := 0 to Bitmap.Width - 1 do
                  begin
                    with Scanline[h] do
                      begin
                        pixel_color.r := rgbtRed;
                        pixel_color.g := rgbtGreen;
                        pixel_color.b := rgbtBlue;
                        Set_image_color(image_ptr, To_pixel(h, v), pixel_color);
                      end;
                  end;
              end;

          except
            // Eat invalid graphic messages (which may be raised when
            // a jpeg is being drawn)
            //
            on E: EInvalidGraphic do
              begin
                Error('Invalid JPEG: ' + Quotate_str(name) + ' ' + E.Message);
              end;
          end;

        finally
          Bitmap.Free;
        end;
      finally
        Picture.Free;
      end;
    end;

  Load_image := image_ptr;
end; {function Load_image}


end.

