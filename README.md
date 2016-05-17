<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Squirrel JSON Parser](#squirrel-json-parser)
  - [Usage](#usage)
  - [Custom Types Converter](#custom-types-converter)
    - [Sample Flow](#sample-flow)
  - [Testing](#testing)
  - [Development](#development)
  - [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

<br/>

[![Build Status](https://travis-ci.org/electricimp/JSONParser.svg?branch=master)](https://travis-ci.org/electricimp/JSONParser)

# Squirrel JSON Parser

Parses JSON into Squirrel data types.

**To add this library to your project, add** `#require "JSONParser.nut:1.0.0"` **to the top of your code.**

## Usage

JSONParser has no constructor and one public function *parse*.

### parse(*jsonString[, converterFunction]*)

The **parse** method takes one required parameter a JSON encoded string and one optional parameter a function used to convert custom types.  The method returns a deserialized version of the object that was passed in.

###### Basic Example:
```squirrel
local jsonString = "{\"one\" : 1}";
result <- JSONParser.parse(jsonString);
server.log(result.one);
// == 1
```

#### Custom Types Converter

The custom converter function can be used to deserialize custom types. It takes two parameters:

- *value* &mdash; String representation of a value
- *type* &mdash; String indicating conversion type: `"string"` or `"number"`

For example, the following code converts all numbers to floats and makes strings uppercase:

```squirrel
result <- JSONParser.parse(jsonString, function (value, type) {
  if (type == "number") {
    return val.tofloat();
  } else if (type == "string") {
    return val.toupper();
  }
});
```

###### Extended Example:

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

## Testing

Repository contains [impUnit](https://github.com/electricimp/impUnit) tests and a configuration for [impTest](https://github.com/electricimp/impTest) tool.

Tests can be launched with:

```bash
imptest test
```

By default configuration for the testing is read from [.imptest](https://github.com/electricimp/impTest/blob/develop/docs/imptest-spec.md).

To run test with your settings (for example while you are developing), create your copy of **.imptest** file and name it something like **.imptest.local**, then run tests with:

 ```bash
 imptest test -c .imptest.local
 ```

Tests do not require any specific hardware.

## Development

This repository uses [git-flow](http://jeffkreeftmeijer.com/2010/why-arent-you-using-git-flow/).
Please make your pull requests to the __develop__ branch.

## License

The code in this repository is licensed under [MIT License](https://github.com/electricimp/serializer/tree/master/LICENSE). Partially based on Douglas Crockford's [state-machine JSON parser](https://github.com/douglascrockford/JSON-js/blob/master/json_parse_state.js) available as public domain.
