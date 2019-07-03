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
    local d = JSONParser.parse(s, function (val, type, key) {
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

  function test_2() {
    local s = "\"Hello world!\"";
    local d = JSONParser.parse(s, function(value, type, key){
      if (type == "string") {
        return value;
      } else if (type == "number") {
        throw "JSONParse passed wrong type!"
      } else {
        throw "JSONParse passed invalid type!"
      }
    });

    this.assertDeepEqual("Hello world!", d)
  }

  function test_3() {
    // Arrays with custom parsing
    local s = "[1,2,3]";
    local d = JSONParser.parse(s, function(value, type, key){
      if (type == "string") {
        throw "JSONParse passed wrong type!"
      } else if (type == "number") {
        return value.tointeger();
      } else {
        throw "JSONParse passed invalid type!"
      }
    });

    this.assertDeepEqual([1,2,3], d)
  }

  function test_4() {
    // Integers with custom parsing
    local s = "77";
    local d = JSONParser.parse(s, function(value, type, key){
      if (type == "string") {
        throw "JSONParse passed wrong type!"
      } else if (type == "number") {
        return value.tointeger();
      } else {
        throw "JSONParse passed invalid type!"
      }
    });

    this.assertDeepEqual(77, d)
  }

  function test_5() {
    local s = "77.8";
    local d = JSONParser.parse(s, function(value, type, key){
      if (type == "string") {
        throw "JSONParse passed wrong type!"
      } else if (type == "number") {
        return value.tofloat();
      } else {
        throw "JSONParse passed invalid type!"
      }
    });

    this.assertDeepEqual(77.8, d)
  }

  function test_6() {
    local s = "{\"a\":\"Hello world!\",\"c\":1.667,\"b\":1024}"
    local d = JSONParser.parse(s, function(value, type, key){
      if (type == "string" && key == "a") {
        return value;
      } else if (type == "number") {
        if (key == "c") {
          return value.tofloat();
        } else if (key == "b") {
          return value.tointeger();
        } else {
          throw "JSONParse passed bad key!"
        }
      } else {
        throw "JSONParse key testing failed!"
      }
    });

    this.assertDeepEqual({
          a = "Hello world!",
          b = 1024,
          c = 1.667
        }, d)
  }
}
