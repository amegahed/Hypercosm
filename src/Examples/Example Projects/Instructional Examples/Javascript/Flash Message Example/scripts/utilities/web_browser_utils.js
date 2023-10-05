/***************************************************************\
| |\  /|                                                We Put  |
| | >< Hypercosm         web_browser_utils.js           3d      |
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
// browser detection
//

var internetExplorer = navigator.appName.indexOf("Microsoft") != -1;

function getIEVersion() {
  var arVersion = navigator.appVersion.split("MSIE");
  var version = parseFloat(arVersion[1]);
  return version;
}    // getIEVersion

//
// event handling 
//

function addEvent(object, eventType, eventHandler) { 
 if (object.addEventListener) { 
   object.addEventListener(eventType, eventHandler, false); 
   return true; 
 } else if (object.attachEvent) { 
   return object.attachEvent("on" + eventType, eventHandler); 
 } else { 
   return false; 
 } 
}    // addEvent

//
// DOM searching method
//

function getElementById(id, parent) {
	
  // if no parent is specified, then use document
  //
  if (!parent)
    return document.getElementById(id);
  // search parent's subtree for node with id
  //
  if (typeof(parent) == "string")
    var root = document.getElementById(parent);
  else
    var root = parent;
  
  // recursively search children for id
  //
  var child = root.firstChild;
  while (child) {
    if (child.id == id)
      return child;
    else {
      var element = getElementById(id, child);
      if (element)
        return element;
    }
    child = child.nextSibling;
  }
  
  return undefined;
}	// getElementById

function getElementsByIds(ids, parent) {
  var elements = new Array();
  
  for (var counter = 0; counter < ids.length; counter++)
    elements[counter] = getElementById(ids[counter]);
	
  return elements;
}	// getElementsByIds

//
// ActiveX / plug-in adding method
//

function createIEControl(element, classID, objectID, width, height, params) {
  // write object begin tag
  //
  var HTML = "<object id='" + objectID + "' width='" + width + "' height='" + height + "'" + " classid='" + classID + "'>";
  
  // add parameters
  //
  for (var counter = 0; counter < params.length; counter++)
    HTML += "<param name='" + params[counter][0] + "' value=" + getQuotatedString(params[counter][1]) + ">";
  // write object end tag
  //
  HTML += "</object>";
  // add to document
  //
  element.innerHTML = HTML;
  
  return document[objectID];
}	// createIEControl

function createMozillaControl(element, objectID, params) {
  // write embed begin tag
  //
  var HTML = "<embed";
  
  // add parameters
  //
  for (var counter = 0; counter < params.length; counter++)
    HTML += " " + params[counter][0] + "=" + getQuotatedString(params[counter][1]);
  
  // write close of embed tag
  //
  HTML += ">";
  // add to document
  //
  element.innerHTML = HTML;
  
  return document[objectID];
}	// createMozillaControl

//
// runtime script file including
//

function include(fileName) {
  var head = document.getElementsByTagName('head').item(0);
  var script = document.createElement('script');
  script.setAttribute('language', 'javascript');
  script.setAttribute('type', 'text/javascript');
  script.setAttribute('src', fileName);
  head.appendChild(script);
}    // include
  
  
//
// image manipulation methods
//

function swapImage(image, src) {
  var suffix = src.substring(src.length - 3, src.length);
  if (((suffix == "png") || (suffix == "PNG")) && (typeof(swapPNG) != "undefined"))
    swapPNG(image, src);
  else
    image.src = src;
}    // swapImage

function getImageSrc(element) {
  if (element.src)
    return element.src;
  else
    return element.filters(0).src;
}	// getImageSrc

//
// window status bar methods
//

function setStatus(status) {
  window.status = status;
}    // setStatus

function clearStatus() {
  window.status = "";
}    // clearStatus

//
// printing methods
//

function printPage() {
  window.print();
}    // printPage

//
// message display methods
//

function showMessage(title, message, style, width, height, backgroundColor) {
  if (style == null)
    style = "font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 10px";
  if (backgroundColor == null)
    backgroundColor = "#D4D0C8";
    
  text = "<html>";
  text += "<head>";
  text += "<title>" + title + "</title>";
  text += "<style type='text/css'>";
  text += ".normal {" + style + "}";
  text += "body {" + "background-color: " + backgroundColor + ";" + "}";
  text += "</style>";
  text += "<body>";
  text += "<span class='normal'>" + message + "</span>";
  text += "</body>";
  text += "</html>";
  // set window parameters
  //
  URL = "";
  name = "_blank";
  
  // set window default width and height, if not specified
  //
  if (width == null)
    width = 200;
  if (height == null)
    height = 100;
    
  var popUpWindow = openPopUpWindow(URL, width, height);
  popUpWindow.document.write(text);
}    // showMessage

openPopUpWindow = function(windowSrc, width, height) {
  var left = (screen.width - width) / 2;
  var top = (screen.height - height) / 2;
  
  // open collaboration ip address selection dialog box
  //
  return window.open(windowSrc, "_blank", 
    "width=" + width + ", height=" + height + ", top=" + top + ", left=" + left +
    ", resizeable=no, status=no, toolbar=no, menubar=no, location=no, scrollbars=no, directories=no");
}	// openPopUpWindow

//
// URL query string methods
//

function getQueryString() {
  return window.top.location.search.substring(1);
}    // getQueryString

function addQueryString(queryString, newString) {
  if (queryString && newString && (newString != undefined))
    return queryString + "&" + newString;
  else if (queryString)
    return queryString;
  else
    return newString;
}    // getQueryString

function getQueryVariable(queryString, variable) {
  if (!queryString)
    return undefined;
	
  var vars = queryString.split("&");
  for (var i = 0; i < vars.length; i++) {
    var pair = vars[i].split("=");
    if (pair[0] == variable) {
      return pair[1];
    }
  }
  
  return undefined;
}    // getQueryVariable

function getQueryVariables(queryString, variable) {
  if (!queryString)
    return new Array();
  var queryVariables = new Array();
  var vars = queryString.split("&");
  var count = 0;
  
  for (var i = 0; i < vars.length; i++) {
    var pair = vars[i].split("=");
    if (pair[0] == variable) {
      queryVariables[count] = pair[1];
      count += 1;
    }
  } 
  
  return queryVariables;
}    // getQueryVariables

//
// clipboard  methods
//

function copyTextToClipBoard(text) {
  if (window.clipboardData && clipboardData.setData)
    clipboardData.setData("Text", s);
  else
    alert("Internet Explorer required");
}    // copyTextToClipboard

//
// window URL location address methods
//

function setWindowLocation(text) {
  window.top.location.href = text;
}    // setWindowLocation

function getWindowLocation() {
  return window.top.location.href;
}    // getWindowLocation

function appendToWindowLocation(text) {
  window.top.location.href = window.top.location.href + text;
}    // appendToWindowLocation

function getBaseLocation(location) {
  var strings = location.split("?");
  return strings[0];
}    // getBaseLocation
		  
//
// HTTP request functions
//

function makeHTTPRequest(url, callback) { 
  if (window.XMLHttpRequest) {  // Mozilla, Safari,... 
    request = new XMLHttpRequest(); 
  } else if (window.ActiveXObject) { // IE 
    request = new ActiveXObject("Microsoft.XMLHTTP"); 
  } 
  var action = callback;
  request.onreadystatechange = function() {alertHTTPRequest(action)}; 
  request.open('GET', url, true); 
  request.send(null); 
}	// makeHTTPRequest

function alertHTTPRequest(callback) {
  if (request.readyState == 4) {
    if (request.status == 200)
	  var result = request.responseText;
    callback(result);
  }
}	// alertHTTPRequest

function makeTinyURL(url, action) {
  makeHTTPRequest("http://tinyurl.com/api-create.php?url=" + url, action);  
}	// makeTinyURL

//
// methods to handle strings that contain special characters
//

function stringToURL(string) {
  // This function uses a regular expression to specify
  // a global search and replace within the string.
  //
  // The syntax takes the form of: string.replace(/findstring/g, newstring)
  // where the "g" signifies the global search and replace.
  //
  // There are 11 special "metacharacters" that are used in regular
  // expressions that require an extra backslash in front of them to specify.
  // These characters include: the opening square bracket [, the backslash \, 
  // the caret ^, the dollar sign $, the period or dot ., the vertical bar 
  // or pipe symbol |, the question mark ?, the asterisk or star *, the plus 
  // sign +, the opening round bracket ( and the closing round bracket ). 
  //
  var URL = string;
  URL = URL.replace(/%/g, "%25");
  URL = URL.replace(/ /g, "%20");
  URL = URL.replace(/~/g, "%7E");
  URL = URL.replace(/`/g, "%60");
  URL = URL.replace(/!/g, "%33"); 
  URL = URL.replace(/@/g, "%40"); 
  URL = URL.replace(/#/g, "%23"); 
  URL = URL.replace(/\$/g, "%24");
  URL = URL.replace(/\^/g, "%5E"); 
  URL = URL.replace(/&/g, "%26");
  URL = URL.replace(/\*/g, "%2A");
  URL = URL.replace(/\(/g, "%28");
  URL = URL.replace(/\)/g, "%29");
  URL = URL.replace(/-/g, "%2D");							
  URL = URL.replace(/\+/g, "%2B");
  URL = URL.replace(/=/g, "%3D"); 
  URL = URL.replace(/{/g, "%7B"); 
  URL = URL.replace(/}/g, "%7D"); 
  URL = URL.replace(/\[/g, "%5B"); 
  URL = URL.replace(/]/g, "%5D"); 
  URL = URL.replace(/\|/g, "%7C"); 
  URL = URL.replace(/\//g, "%5C"); 
  URL = URL.replace(/:/g, "%3A"); 
  URL = URL.replace(/;/g, "%3B");
  URL = URL.replace(/"/g, "%22"); 
  URL = URL.replace(/'/g, "%27"); 
  URL = URL.replace(/</g, "%3C"); 
  URL = URL.replace(/>/g, "%3E"); 
  URL = URL.replace(/,/g, "%2C");
  URL = URL.replace(/\./g, "%2E"); 
  URL = URL.replace(/\?/g, "%3F");  
  URL = URL.replace(/\//, "%2F"); 
 
  return URL;
}	// stringToURL

function stringsToURLs(strings) {
  var URLs = new Array(strings.length);
  for (var counter = 0; counter < strings.length; counter++)
    URLs[counter] = stringToURL(strings[counter]);
  return URLs;
}	// stringsToURLs

function URLToString(URL) {
  var string = URL;
  string = string.replace(/%20/g, " ");
  string = string.replace(/%7E/g, "~");
  string = string.replace(/%60/g, "`");
  string = string.replace(/%33/g, "!"); 
  string = string.replace(/%40/g, "@"); 
  string = string.replace(/%23/g, "#"); 
  string = string.replace(/%24/g, "$");
  string = string.replace(/%5E/g, "^"); 
  string = string.replace(/%26/g, "&");
  string = string.replace(/%2A/g, "*");
  string = string.replace(/%28/g, "(");
  string = string.replace(/%29/g, ")");
  string = string.replace(/%2D/g, "-");							
  string = string.replace(/%2B/g, "+");
  string = string.replace(/%3D/g, "="); 
  string = string.replace(/%7B/g, "{"); 
  string = string.replace(/%7D/g, "}"); 
  string = string.replace(/%5B/g, "["); 
  string = string.replace(/%5D/g, "]"); 
  string = string.replace(/%7C/g, "|"); 
  string = string.replace(/%5C/g, "\\");
  string = string.replace(/%3A/g, ":"); 
  string = string.replace(/%3B/g, ";");
  string = string.replace(/%22/g, '"'); 
  string = string.replace(/%27/g, "'"); 
  string = string.replace(/%3C/g, "<"); 
  string = string.replace(/%3C/g, ">"); 
  string = string.replace(/%2C/g, ",");
  string = string.replace(/%2E/g, "."); 
  string = string.replace(/%3F/g, "?");   
  string = string.replace(/%2F/g, "/"); 
  string = string.replace(/%25/g, "%");
	
  return string;
}	// URLToString

function URLsToStrings(URLs) {
  var strings = new Array(URLs.length);
  for (var counter = 0; counter < URLs.length; counter++)
    strings[counter] = URLToString(URLs[counter]);
  return strings;
}	// URLsToStrings

function textToURL(text) {
  if (typeof(text) == "string")
  
    // string text
    //
    return stringToURL(text);
  else if (text.length == 1)
  
    // single line text
    //
    return stringToURL(text[0]);
  else {
	  
    // multi line text
    //  
    var URL = "";
    for (var line = 0; line < text.length; line++) {
      URL += stringToURL(text[line]);
	  if (line < text.length - 1)
	    URL += "%12";
    }
	
    return URL;
  }
}	// textToURL

function URLToText(URL) {
  var words = URL.split("%");
  var text = new Array();
  var lines = 1;
  text[lines - 1] = words[0];
  
  for (var counter = 1; counter < words.length; counter++) {
	var code = "%" + words[counter].substring(0, 2);
	
	// check each escape code
	//
	if (code == "%12") {
		
	  // start new line
	  //
          lines += 1;
          text[lines - 1] = words[counter].substring(2, words[counter].length);	  
	} else {
		
          // add to existing line
	  //
	  text[lines - 1] += URLToString(code) + words[counter].substring(2, words[counter].length);
    }
  }
	
  return text;
}	// URLToText
