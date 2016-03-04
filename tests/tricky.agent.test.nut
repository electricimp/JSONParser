/**
 * More edge cases
 */

class Tricky_TestCase extends ImpTestCase {
  function test_1() {
    local s = "\"שָׁלוֹם\"";
    local d = JSONParser.parse(s);
    this.assertEqual(s, "\"" + d + "\"");
  }

  function test_2() {
    local s = "{\"unicode\":\"שָׁלוֹם\"}";
    local d = JSONParser.parse(s);
    this.assertDeepEqual({"unicode" : "שָׁלוֹם"}, d);
  }

  function test_3() {
    local s = "{\"arrays\":[[\"Hello, world.\"]]}";
    local d = JSONParser.parse(s);
    this.assertDeepEqual({"arrays": [["Hello, world."]]}, d);
  }

  function test_4() {
    local s = "[\"one\",{\"obj\":\"two\"}]";
    local d = JSONParser.parse(s);
    this.assertDeepEqual(["one", {"obj":"two"}], d);
  }
}
