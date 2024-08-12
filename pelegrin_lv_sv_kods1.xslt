<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">
<xsl:output method="html"/>
  <xsl:template match="/">
   
   <xsl:variable name="nauda">
    <xsl:choose>
     <xsl:when test="/documents/document/valuuta!=''">
      <xsl:value-of select="/documents/document/valuuta" />
     </xsl:when>
     <xsl:otherwise>LVL</xsl:otherwise>
    </xsl:choose>
   </xsl:variable>
   
   <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
   <html>
   <head>
   <title>Artikuls</title>
   <script language="JavaScript" type="text/javascript"><![CDATA[
         // Script: http://www.parkscomputing.com/barcode.html
         
         /* Syntactical sugar to support object-oriented JavaScript. Code and 
         explanations may be found at the following address: 
         
         http://www.crockford.com/javascript/inheritance.html */
         
         Function.prototype.method = function (name, func) 
         {
             this.prototype[name] = func;
             return this;
         };
         
         Function.method('inherits', function (parent) 
         {
             var d = 0;
             var p = (this.prototype = new parent());
             
             this.method('base', function base(name) 
             {
                 var f;
                 var t = d;
                 var v = parent.prototype;
                 
                 if (t) 
                 {
                     while (t) 
                     {
                         v = v.constructor.prototype;
                         t -= 1;
                     }
                     
                     f = v[name];
                 } 
                 else 
                 {
                     f = p[name];
                     
                     if (f == this[name]) 
                     {
                         f = v[name];
                     }
                 }
                 
                 d += 1;
                 var r = f.apply(this, Array.prototype.slice.apply(arguments, [1]));
                 d -= 1;
                 return r;
             });
             
             return this;
         });

         Function.method('swiss', function (parent) 
         {
             for (var i = 1; i < arguments.length; ++i) 
             {
                 var name = arguments[i];
                 this.prototype[name] = parent.prototype[name];
             }
             
             return this;
         });


         /* This method formats a string using a supplied format string and a 
         variable number of parameters. It is based on the ECMA CLR (common-
         language runtime) class System.String's static method Format. */
         
         /* This function becomes a static method of the String object. */ 
         String.format = function(formatString) 
         { 
            if (arguments.length < 2) 
            { 
               return formatString; 
            } 

            /* Each JavaScript function has an implicit object named arguments that is 
            an array of the parameters passed to the function each time it is called. 
            The following line makes a reference to the arguments object so that it can 
            be used by the lambda function passed to the replace method, since it will 
            be available in the lambda's lexical scope. */ 
            var replArray = arguments; 
            
            /* Perform a regular-expression replacement of format placeholders. The 
            second parameter is a lambda function that is called on each regex match and 
            returns the appropriate replacement value. For example, {0} should be replaced 
            by element 1 in the replArray array, {1} by element 2, and so on. */ 
            return formatString.replace( 
               /\{(\d+)\}/g, 
               function(match, i) 
               { 
                  /* The '+' prefix operator converts a string to a numeric value. */ 
                  return replArray[+i + 1]; 
               } 
               ); 
         } 

        
         /* I found the information I needed to write this script in an article 
         on CodeProject (http://www.codeproject.com/csharp/EAN_13_Barcodes.asp) that 
         showed how to create a barcode in C#. The check-digit calculation is lifted 
         pretty much as-is from that article; the rest of the code is original. */
      
         function createAttribute(name, value)
         {
            var attr = document.createAttribute(name);
            attr.nodeValue = value;
            return attr;
         }
         
         
         function BarCodeUI(nodeID,c)
         {
            var self = this;
            
            code = c;
            var countryDispID = String.format("{0}_countryCode", nodeID);
            var group1DispID = String.format("{0}_group1", nodeID);
            var group2DispID = String.format("{0}_group2", nodeID);
            
            var countryDisp = document.getElementById(countryDispID).firstChild;
            var group1Disp = document.getElementById(group1DispID).firstChild;
            var group2Disp = document.getElementById(group2DispID).firstChild;
            
           /* IDs of the HTML elements used to display the encoded digits. */
           var digits = 
            [
               "",
               String.format("{0}_digit01", nodeID),
               String.format("{0}_digit02", nodeID),
               String.format("{0}_digit03", nodeID),
               String.format("{0}_digit04", nodeID),
               String.format("{0}_digit05", nodeID),
               String.format("{0}_digit06", nodeID),
               String.format("{0}_digit07", nodeID),
               String.format("{0}_digit08", nodeID),
               String.format("{0}_digit09", nodeID),
               String.format("{0}_digit10", nodeID),
               String.format("{0}_digit11", nodeID),
               String.format("{0}_digit12", nodeID)
            ];
            
            BarCodeUI.method('SetDigit', function(pos, pattern)
            {
               var digitNode = document.getElementById(digits[pos]);
               var bits = digitNode.getElementsByTagName("div");
               
               for (var j = 0; j < bits.length; ++j)
               {
                  bits[j].setAttributeNode(
                     createAttribute(
                        "class", 
                        pattern[j] ? "bitOn" : "bitOff"
                        )
                     );
               }
            });
               

            BarCodeUI.method('DisplayText', function()
            {  
               var countryCode = code.charAt(0);
               var group1 = code.substring(1, 7);
               var group2 = code.substring(7, 13);
               
               countryDisp.nodeValue = countryCode;
               group1Disp.nodeValue = group1;
               group2Disp.nodeValue = group2;
               
            });
         

            BarCodeUI.method('NodeID', function()
            {
               return nodeID;
            });
            
         };

         /* I plan to do a significant amount of refactoring to add support for 
         additional symbologies. First, I'll make the following class a base class and 
         specialize it for specific symbologies (EAN-8, UPC-A, etc.). Then I'll probably 
         separate the HTML/UI input interface from the output interface. */
         
         /* Define the application object. */
         function EAN13Generator()
         {
            /* Bit patterns for digits. Each digit takes up seven lines in a 
            barcode. A zero corresponds to a blank line, and a one corresponds to 
            a filled line. */
            
            /* Odd-parity left-hand digits. */
            var odd = 
               [
                  [0,0,0,1,1,0,1], // 0
                  [0,0,1,1,0,0,1], // 1
                  [0,0,1,0,0,1,1], // 2
                  [0,1,1,1,1,0,1], // 3
                  [0,1,0,0,0,1,1], // 4
                  [0,1,1,0,0,0,1], // 5
                  [0,1,0,1,1,1,1], // 6
                  [0,1,1,1,0,1,1], // 7
                  [0,1,1,0,1,1,1], // 8
                  [0,0,0,1,0,1,1]  // 9
               ];
         
            /* Even-parity left-hand digits. */
            var even = 
               [
                  [0,1,0,0,1,1,1], // 0
                  [0,1,1,0,0,1,1], // 1
                  [0,0,1,1,0,1,1], // 2
                  [0,1,0,0,0,0,1], // 3
                  [0,0,1,1,1,0,1], // 4
                  [0,1,1,1,0,0,1], // 5
                  [0,0,0,0,1,0,1], // 6
                  [0,0,1,0,0,0,1], // 7
                  [0,0,0,1,0,0,1], // 8
                  [0,0,1,0,1,1,1]  // 9
               ];
         
            /* Right-hand digits. */
            var right = 
               [
                  [1,1,1,0,0,1,0], // 0
                  [1,1,0,0,1,1,0], // 1
                  [1,1,0,1,1,0,0], // 2
                  [1,0,0,0,0,1,0], // 3
                  [1,0,1,1,1,0,0], // 4
                  [1,0,0,1,1,1,0], // 5
                  [1,0,1,0,0,0,0], // 6
                  [1,0,0,0,1,0,0], // 7
                  [1,0,0,1,0,0,0], // 8
                  [1,1,1,0,1,0,0]  // 9
               ];
               
            /* Digit parity is determined by the first digit of the code. This 
            array corresponds to the possible values of the code and uses the 
            parity tables described above. */
            var parity = 
               [
                  [ odd,  odd,  odd,  odd,  odd,  odd ], // 0
                  [ odd,  odd, even,  odd, even, even ], // 1
                  [ odd,  odd, even, even,  odd, even ], // 2
                  [ odd,  odd, even, even, even,  odd ], // 3
                  [ odd, even,  odd,  odd, even, even ], // 4
                  [ odd, even, even,  odd,  odd, even ], // 5
                  [ odd, even, even, even,  odd,  odd ], // 6
                  [ odd, even,  odd, even,  odd, even ], // 7
                  [ odd, even,  odd, even, even,  odd ], // 8
                  [ odd, even, even,  odd, even,  odd ]  // 9
               ];
               
            /* Private data members. */
                   
            var self = this;

            /* Public method that executes the script application. */
            EAN13Generator.method("Generate", function(ui)
            {
               var retVal = 0;
               
               if (code.length > 12)
               {
                  code = code.substring(0, 12);
               }
               else if (code.length == 11)
               {
                  code = "0" + code;
               }
               
               code = code + this.CalculateChecksumDigit(code);
               
               var parityDigit = parseInt(code.charAt(0));
               var parityTable = parity[parityDigit];
               
               for (var i = 1; i < code.length; ++i)
               {
                  var num = +code.charAt(i);
                  var pattern = null; // parityTable[0][0];
                  
                  if (i < 7)
                  {
                     pattern = parityTable[i - 1][num];
                  }
                  else
                  {
                     pattern = right[num];
                  }

                  ui.SetDigit(i, pattern);                  
               }
               
               ui.DisplayText();                  
               
               return retVal;
            });
            
            /* As mentioned above, this was borrowed from 
            http://www.codeproject.com/csharp/EAN_13_Barcodes.asp */
            EAN13Generator.method("CalculateChecksumDigit", function(code)
            {
                var sum = 0;
                var digit = 0;

                /* Calculate the checksum digit here. */
                for (var i = code.length; i >= 1; --i)
                {
                    digit = parseInt(code.substring( i - 1, i ) );

                    /* This appears to be backwards but the EAN-13 checksum must be calculated
                    this way to be compatible with UPC-A. */
                    if ( i % 2 == 0 )
                    {   /* odd */
                        sum += digit * 3;
                    }  
                    else 
                    {   /* even */
                        sum += digit * 1; 
                    }
                }
                
                var checkSum = ( 10 - ( sum % 10 ) )  % 10; 
                return checkSum;
            });
         }
         
         var barcodeObjects = null;
         var code='';
   ]]></script>
   <style type="text/css">
    body {
    text-align:center;
    font-family:sans-serif;
    font-size:10px;
    margin:0px;
    }
    
    .container {
    text-align:left;
    width:960px;
    margin:auto;
    }
    
    .pbreak {
    page-break-after:always;
    }
    
    .barcode { position:relative; height:80px; float:left; clear:left; font-size:10px;}
    .quietZone { float:left; height:92%; }
    .leader { float:left; height:92%; }
    .separator { float:left; height:92%; }
    .trailer { float:left; height:92%; }
    .digit { float:left; height:80%; }
    .bitOn { float:left; height:92%; border-left:1px solid black; background-color:#000000; }
    .bitOff { float:left; height:92%; width:1px; background-color:#FFFFFF; }
    .codeDisplay_countryCode { font-family:monospace; font-size:10px; position:absolute; color:black; background-color:white; top:60px; left:1%; }
    .codeDisplay_group1 { font-family:monospace; font-size:10px; position:absolute; color:black; background-color:white; top:60px; left:15%; }
    .codeDisplay_group2 { font-family:monospace; font-size:10px; position:absolute; color:black; background-color:white; top:60px; left:55%; }
   </style>

   </head>
   
   <body>
   <div class="container">
      <xsl:variable name="logo" select="/documents/footer/firma_logo" />
      <xsl:variable name="uid"><xsl:value-of select="concat('id',number,rn)" /></xsl:variable>
      <div style="float:left; padding:5px; border:1px dotted #000000; height:133px; width:360px; margin:5px;">
      <div style="float:left;">
       <!--<div>
        <img width="110" alt="Logo">
         <xsl:attribute name="src"><xsl:value-of select="$logo" /></xsl:attribute>
        </img>
       </div>
       <div style="padding:5px;">
        Skaits iepak. <xsl:value-of select="/documents/document/yhikumuut1" /> gab.<br />
        <b>Cena par 1 gab.</b><br />
       </div>
       <div style="padding:10px; font-size:16px; font-weight:bold; font-family:'Arial Black', sans-serif;">
        <xsl:value-of select="/documents/document/hind_tavaline" />&#160;<xsl:value-of select="$nauda" />
       </div>
      </div>
      <div style="float:left; padding-left:10px;">
       <div style="font-size:14px; font-family:'Arial Black', sans-serif;">
        Art.N <xsl:value-of select="/documents/document/kood" />
       </div>-->
       <div style="font-size:14px;">
        <xsl:value-of select="/documents/document/nimi" />
       </div>
       <!--<div>
        <xsl:value-of select="/documents/document/ribakood" />
       </div>-->
       <div class="barcode">
        <xsl:attribute name="id"><xsl:value-of select="$uid" /></xsl:attribute>
         <xsl:attribute name="id"><xsl:value-of select="concat($uid,'_desc')" /></xsl:attribute>
         <div class="quietZone">
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
         </div>
         <div class="leader">
          <div class="bitOn"></div>
          <div class="bitOff"></div>
          <div class="bitOn"></div>
         </div>
         <div class="digit">
          <xsl:attribute name="id"><xsl:value-of select="concat($uid,'_digit01')" /></xsl:attribute>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
         </div>
         <div class="digit">
          <xsl:attribute name="id"><xsl:value-of select="concat($uid,'_digit02')" /></xsl:attribute>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
         </div>
         <div class="digit">
          <xsl:attribute name="id"><xsl:value-of select="concat($uid,'_digit03')" /></xsl:attribute>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
         </div>
         <div class="digit">
          <xsl:attribute name="id"><xsl:value-of select="concat($uid,'_digit04')" /></xsl:attribute>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
         </div>
         <div class="digit">
          <xsl:attribute name="id"><xsl:value-of select="concat($uid,'_digit05')" /></xsl:attribute>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
         </div>
         <div class="digit">
          <xsl:attribute name="id"><xsl:value-of select="concat($uid,'_digit06')" /></xsl:attribute>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
         </div>
         <div class="separator">
          <div class="bitOff"></div>
          <div class="bitOn"></div>
          <div class="bitOff"></div>
          <div class="bitOn"></div>
          <div class="bitOff"></div>
         </div>
         <div class="digit">
          <xsl:attribute name="id"><xsl:value-of select="concat($uid,'_digit07')" /></xsl:attribute>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
         </div>
         <div class="digit">
          <xsl:attribute name="id"><xsl:value-of select="concat($uid,'_digit08')" /></xsl:attribute>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
         </div>
         <div class="digit">
          <xsl:attribute name="id"><xsl:value-of select="concat($uid,'_digit09')" /></xsl:attribute>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
         </div>
         <div class="digit">
          <xsl:attribute name="id"><xsl:value-of select="concat($uid,'_digit10')" /></xsl:attribute>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
         </div>
         <div class="digit">
          <xsl:attribute name="id"><xsl:value-of select="concat($uid,'_digit11')" /></xsl:attribute>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
         </div>
         <div class="digit">
          <xsl:attribute name="id"><xsl:value-of select="concat($uid,'_digit12')" /></xsl:attribute>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
         </div>
         <div class="trailer">
          <div class="bitOn"></div>
          <div class="bitOff"></div>
          <div class="bitOn"></div>
         </div>
         <div class="quietZone">
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
          <div class="bitOff"></div>
        </div>
        <div class="codeDisplay_countryCode">
         <xsl:attribute name="id"><xsl:value-of select="concat($uid,'_countryCode')" /></xsl:attribute>
         1
        </div>
        <div class="codeDisplay_group1">
         <xsl:attribute name="id"><xsl:value-of select="concat($uid,'_group1')" /></xsl:attribute>
         2
        </div>
        <div class="codeDisplay_group2">
         <xsl:attribute name="id"><xsl:value-of select="concat($uid,'_group2')" /></xsl:attribute>
         3
        </div>
       </div>
       <script language="JavaScript" type="text/javascript"><![CDATA[
        barcodeObjects = { ']]><xsl:value-of select="$uid" /><![CDATA[': { generator: new EAN13Generator(), ui: new BarCodeUI(']]><xsl:value-of select="$uid" /><![CDATA[',']]><xsl:value-of select="/documents/document/ribakood" /><![CDATA[') } };
        barcodeObjects[']]><xsl:value-of select="$uid" /><![CDATA['].generator.Generate(barcodeObjects[']]><xsl:value-of select="$uid" /><![CDATA['].ui);
       ]]></script>
      </div>
      </div>
    
   </div> <!-- Konteinera beigas -->
   </body>
   
   </html>
  </xsl:template>
</xsl:stylesheet>
