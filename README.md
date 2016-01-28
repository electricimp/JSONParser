<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Squirrel JSON Parser](#squirrel-json-parser)
  - [Usage](#usage)
  - [Custom Types Converter](#custom-types-converter)
    - [Sample Flow](#sample-flow)
  - [License](#license)
  - [Author](#author)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Squirrel JSON Parser

Parses JSON into Squirrel data types.

_To add this library to your project, add **#require "JSONParser.nut:0.1.2"** to the top of your code._

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

### Sample Flow

The whole scenario may look like:

```squirrel
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

server.log(s);
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

server.log(result.c instanceof MyCustomType);
// == true
server.log(result.c.getValue());
// == 100500
```

## License

The code in this repository is licensed under [MIT License](https://github.com/electricimp/serializer/tree/master/LICENSE).

## Development

This repository uses [git-flow](http://jeffkreeftmeijer.com/2010/why-arent-you-using-git-flow/).
Please make your pull requests to the __develop__ branch.
