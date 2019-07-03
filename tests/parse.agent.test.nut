/**
 * JSONParser Test Case A
 */

class Parsing_TestCase extends ImpTestCase {

  function test_1() {
    local s = "  {\"a\":123, \"c\":  {\"_field\":123},\"b\":[1,2,3,4],\"e\":{\"field\":123},\"d\":5.125,\"g\":true,\"f\":null,\"i\":\"a\\ta\",\"h\":\"Some\\nùnicode\\rstring ø∆ø\"}";
    local d = JSONParser.parse(s);
    this.assertDeepEqual(
      {
        "a": 123,
        "c": {
          "_field": 123
        },
        "b": [
          1,
          2,
          3,
          4
        ],
        "e": {
          "field": 123
        },
        "d": 5.125,
        "g": true,
        "f": null,
        "i": "a\ta",
        "h": "Some\nùnicode\rstring ø∆ø"
      }, d
    );
  }

  function test_2() {
    local s = "{\n\"a\":123, \"bc\":222}";
    local d = JSONParser.parse(s);
    this.assertDeepEqual(d, {"a":123, "bc":222});
  }

  function test_3() {
    local s = "{\r\n    \"glossary\": {\r\n        \"title\": \"example glossary\",\r\n\t\t\"GlossDiv\": {\r\n            \"title\": \"S\",\r\n\t\t\t\"GlossList\": {\r\n                \"GlossEntry\": {\r\n                    \"ID\": \"SGML\",\r\n\t\t\t\t\t\"SortAs\": \"SGML\",\r\n\t\t\t\t\t\"GlossTerm\": \"Standard Generalized Markup Language\",\r\n\t\t\t\t\t\"Acronym\": \"SGML\",\r\n\t\t\t\t\t\"Abbrev\": \"ISO 8879:1986\",\r\n\t\t\t\t\t\"GlossDef\": {\r\n                        \"para\": \"A meta-markup language, used to create markup languages such as DocBook.\",\r\n\t\t\t\t\t\t\"GlossSeeAlso\": [\"GML\", \"XML\"]\r\n                    },\r\n\t\t\t\t\t\"GlossSee\": \"markup\"\r\n                }\r\n            }\r\n        }\r\n    }\r\n}";
    local d = JSONParser.parse(s);

    this.assertDeepEqual(
       {
         "glossary": {
           "GlossDiv": {
             "GlossList": {
               "GlossEntry": {
                 "GlossSee": "markup",
                 "GlossDef": {
                   "GlossSeeAlso": [
                     "GML",
                     "XML"
                   ],
                   "para": "A meta-markup language, used to create markup languages such as DocBook."
                 },
                 "GlossTerm": "Standard Generalized Markup Language",
                 "Acronym": "SGML",
                 "ID": "SGML",
                 "Abbrev": "ISO 8879:1986",
                 "SortAs": "SGML"
               }
             },
             "title": "S"
           },
           "title": "example glossary"
         }
       }, d
    );
  }

  function test_4() {
    local s = "{\"widget\": {\r\n    \"debug\": \"on\",\r\n    \"window\": {\r\n        \"title\": \"Sample Konfabulator Widget\",\r\n        \"name\": \"main_window\",\r\n        \"width\": 500,\r\n        \"height\": 500\r\n    },\r\n    \"image\": { \r\n        \"src\": \"Images/Sun.png\",\r\n        \"name\": \"sun1\",\r\n        \"hOffset\": 250,\r\n        \"vOffset\": 250,\r\n        \"alignment\": \"center\"\r\n    },\r\n    \"text\": {\r\n        \"data\": \"Click Here\",\r\n        \"size\": 36,\r\n        \"style\": \"bold\",\r\n        \"name\": \"text1\",\r\n        \"hOffset\": 250,\r\n        \"vOffset\": 100,\r\n        \"alignment\": \"center\",\r\n        \"onMouseUp\": \"sun1.opacity = (sun1.opacity / 100) * 90;\"\r\n    }\r\n}} ";
    local d = JSONParser.parse(s);
    this.assertDeepEqual(
      {
        "widget": {
           "debug": "on",
           "window": {
               "title": "Sample Konfabulator Widget",
               "name": "main_window",
               "width": 500,
               "height": 500
           },
           "image": {
               "src": "Images/Sun.png",
               "name": "sun1",
               "hOffset": 250,
               "vOffset": 250,
               "alignment": "center"
           },
           "text": {
               "data": "Click Here",
               "size": 36,
               "style": "bold",
               "name": "text1",
               "hOffset": 250,
               "vOffset": 100,
               "alignment": "center",
               "onMouseUp": "sun1.opacity = (sun1.opacity / 100) * 90;"
           }
       }
     }, d
    );
  }

  function test_5() {
    local s = "77";
    local d = JSONParser.parse(s);
    this.assertDeepEqual(77, d);
  }

  function test_6() {
    local s = "\"Hello world!\"";
    local d = JSONParser.parse(s)
    this.assertDeepEqual("Hello world!", d)
  }

  function test_7() {
      local s = "77.8";
      local d = JSONParser.parse(s);
      this.assertDeepEqual(77.8, d);
  }

  function test_8() {
      local s = "[1,2,3]";
      local d = JSONParser.parse(s);
      this.assertDeepEqual([1,2,3], d);
  }
}
