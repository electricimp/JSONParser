# Squirrel JSON Parser

State machine-based approach.

## Usage

```squirrel
result <- JSONParser.parse(str[, <converter function>]);
```

## Custom Types Converter

Custom converter function can be used to deserialize custom types.

Converter function takes 2 parameters:
- __value__ – string representation of a value
- __type__ – "string"|"number"

For example, the following converts all numbers to floats and makes strings uppercase:

```squirrel
result <- JSONParser.parse(str, function (val, type) {
  if ("number" == type) {
    return val.tofloat();
  } else if ("string" == type) {
    return val.toupper();
  }
});
```

If conjunction with **_serialize()** methods in JSON Encoder, it can be used to conveniently store custom data types in JSON.

The whole flow may look like:

```squirrel
class MyCustomType {
  _value = null;

 constructor(value) {
    this._value = value;
  }

  function _serialize() {
    return "@mycustomtype: " + this._value;
  }
}

o <- {a = 1, b = "Something", c = MyCustomType("100500") };
s <- JSONEncoder.encode(o);

result <- JSONParser.parse(s, function (val, type) {
  if ("number" == type) {
    return val.tofloat();
  } else if ("string" == type) {

    if (null != val.find("@mycustomtype")) {
      // convert my custom type
      val = val.slice(15);
    }

    return val;
  }
});

server.log(JSONEncoder.encode(result));
// == {"a":1,"c":"100500","b":"Something"}
```

## License

[MIT](LICENSE.txt)

## Author

Mikhail Yurasov <mikhail@electricimp.com>
