/**
 * More edge cases
 */

class Tricky_TestCase extends ImpTestCase {
  function test_1() {
    local s = "\"שָׁלוֹם\""; // hebrew for "peace"
    local d = JSONParser.parse(s);
    this.assertEqual(s, "\"" + d + "\"");
  }

  function test_2() {
    local s = "{\"unicode\":\"שָׁלוֹם\"}"; // hebrew for "peace"
    local d = JSONParser.parse(s);
    this.assertDeepEqual(d, {"unicode" : "שָׁלוֹם"});
  }

  function test_3() {
    local s = "{\"arrays\":[[\"Hello, world.\"]]}";
    local d = JSONParser.parse(s);
    this.assertDeepEqual(d, {"arrays": [["Hello, world."]]});
  }

  function test_4() {
    local s = "[\"one\",{\"obj\":\"two\"}];";
    local d = JSONParser.parse(s);
    this.assertDeepEqual(d,  ["one", {"obj":"two"}]);
  }
}
