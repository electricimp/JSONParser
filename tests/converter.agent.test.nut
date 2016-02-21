/**
 * Test custom converter
 */

/**
 * Example of the class with custom serialization behavior
 */
class MyCustomType {
  _value = null;

 constructor(value) {
    this._value = value;
 }

  function _serialize() {
    return "@mycustomtype:" + this._value;
  }

  function getValue() {
    return this._value;
  }
}

class Custom_Converter_TestCase extends ImpTestCase {
  function test_1() {

    local s = "{\"a\":1,\"c\":\"@mycustomtype:abc\",\"b\":2}";

    // use custom conveter to revreate MyCustomType
    local d = JSONParser.parse(s, function (val, type) {
      if ("number" == type) {
        return val.tofloat();
      } else if ("string" == type) {
        if (null != val.find("@mycustomtype")) {
          // convert my custom type
          val = MyCustomType(val.slice(14));
        }
        return val;
      }
    });

    this.assertTrue(d.c instanceof MyCustomType);
    this.assertTrue(d.c.getValue() == "abc");
  }
}
