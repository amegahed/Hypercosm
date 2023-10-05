/***************************************************************\
| |\  /|                                                We Put  |
| | >< Hypercosm           ie_png_fix.js                3d      |
| |/  \|                                                To Work |
|***************************************************************|
|                                                               |
|        This file contains some javascript utilities that      |
|        are used to work with the web browser.                 |
|                                                               |
|***************************************************************|
|                Copyright (c) 2007 Hypercosm, LLC.             |
\***************************************************************/

//
// correctly handle PNG transparency in Win IE 5.5 & 6.
//

var useCorrectedPNGFix = ((getIEVersion() >= 5.5) && (getIEVersion() < 7));
var correctingPNGImages = false;
var correctedPNGImages = false;

function correctPNG() {
  if (useCorrectedPNGFix && !correctingPNGImages) {
    correctingPNGImages = true;
    for (var i = 0; i < document.images.length; i++) {
      var img = document.images[i];
      var imgName = img.src.toUpperCase();
      
      if (imgName.substring(imgName.length-3, imgName.length) == "PNG") {
        var imgID = (img.id) ? "id='" + img.id + "' " : "";
        var imgClass = (img.className) ? "class='" + img.className + "' " : "";
        var imgTitle = (img.title) ? "title='" + img.title + "' " : "title='" + img.alt + "' ";
        var imgStyle = "display:inline-block;" + img.style.cssText;
        if (img.align == "left") imgStyle = "float:left;" + imgStyle;
        if (img.align == "right") imgStyle = "float:right;" + imgStyle;
        if (img.parentElement.href) imgStyle = "cursor:hand;" + imgStyle;
        var strNewHTML = "<span " + imgID + imgClass + imgTitle
          + " style=\"" + "width:" + img.width + "px; height:" + img.height + "px;" + imgStyle + ";"
          + "filter:progid:DXImageTransform.Microsoft.AlphaImageLoader"
          + "(src=\'" + img.src + "\', sizingMethod='image');\"></span>";
          
        img.outerHTML = strNewHTML;
        i = i - 1;
      }
    }
    correctedPNGImages = true;
  }
}  // correctPNG

function swapPNG(image, src) {
  if (useCorrectedPNGFix)
    image.filters(0).src = src;
  else
    image.src = src;
}    // swapPNG
