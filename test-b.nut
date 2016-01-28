#require "JSONParser.nut:0.2.0"

// few tests

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

o <- {a = 1, b = "Something", c = MyCustomType("100500") };
s <- JSONEncoder.encode(o);

p(s);
// == {"a":1,"c":"@mycustomtype:100500","b":"Something"}

result <- JSONParser.parse(s, function (val, type) {
  if ("number" == type) {
    return val.tofloat();
  } else if ("string" == type) {

    if (null != val.find("@mycustomtype")) {
      // convert my custom type
      val = MyCustomType(val.slice(14))
    }

    return val;
  }
});

p(result.c instanceof MyCustomType);
// == true
p(result.c.getValue());
// == 100500
