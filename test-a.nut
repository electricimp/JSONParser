#require "JSONParser.nut:0.1.2"

// few tests

function p(str) {
  if ("server" in getroottable()) {
    server.log(str);
  } else {
    ::print(str + "\n");
  }
}

s <- {};
s[0] <- "  {\"a\":123, \"c\":  {\"_field\":123},\"b\":[1,2,3,4],\"e\":{\"field\":123},\"d\":5.125,\"g\":true,\"f\":null,\"i\":\"a\\ta\",\"h\":\"Some\\nùnicode\\rstring ø∆ø\"}";
s[1] <- "{\n\"a\":123, \"bc\":222}";
s[2] <- "{\r\n    \"glossary\": {\r\n        \"title\": \"example glossary\",\r\n\t\t\"GlossDiv\": {\r\n            \"title\": \"S\",\r\n\t\t\t\"GlossList\": {\r\n                \"GlossEntry\": {\r\n                    \"ID\": \"SGML\",\r\n\t\t\t\t\t\"SortAs\": \"SGML\",\r\n\t\t\t\t\t\"GlossTerm\": \"Standard Generalized Markup Language\",\r\n\t\t\t\t\t\"Acronym\": \"SGML\",\r\n\t\t\t\t\t\"Abbrev\": \"ISO 8879:1986\",\r\n\t\t\t\t\t\"GlossDef\": {\r\n                        \"para\": \"A meta-markup language, used to create markup languages such as DocBook.\",\r\n\t\t\t\t\t\t\"GlossSeeAlso\": [\"GML\", \"XML\"]\r\n                    },\r\n\t\t\t\t\t\"GlossSee\": \"markup\"\r\n                }\r\n            }\r\n        }\r\n    }\r\n}";
s[3] <- "{\"widget\": {\r\n    \"debug\": \"on\",\r\n    \"window\": {\r\n        \"title\": \"Sample Konfabulator Widget\",\r\n        \"name\": \"main_window\",\r\n        \"width\": 500,\r\n        \"height\": 500\r\n    },\r\n    \"image\": { \r\n        \"src\": \"Images/Sun.png\",\r\n        \"name\": \"sun1\",\r\n        \"hOffset\": 250,\r\n        \"vOffset\": 250,\r\n        \"alignment\": \"center\"\r\n    },\r\n    \"text\": {\r\n        \"data\": \"Click Here\",\r\n        \"size\": 36,\r\n        \"style\": \"bold\",\r\n        \"name\": \"text1\",\r\n        \"hOffset\": 250,\r\n        \"vOffset\": 100,\r\n        \"alignment\": \"center\",\r\n        \"onMouseUp\": \"sun1.opacity = (sun1.opacity / 100) * 90;\"\r\n    }\r\n}} ";

foreach (k, v in s) {

  collectgarbage();

  if ("imp" in getroottable() && "getmemoryfree" in imp) {
    local m = imp.getmemoryfree();
    p("memory used: " + m);
  }

  o <- JSONParser.parse(v, function (val, type) {
    if ("number" == type) {
      return val.tofloat();
    } else if ("string" == type) {
      return val.toupper();
    }
  });

  if ("imp" in getroottable() && "getmemoryfree" in imp) {
    local m = imp.getmemoryfree();
    p("memory used: " + m);
  }

  p(JSON.stringify(o) + "\n\n");

}
