# Squirrel JSON Parser #

This library parses JSON into Squirrel data types.

**To include this library in your project, add** `#require "JSONParser.class.nut:1.0.1"` **at the top of your code.**

![Build Status](https://cse-ci.electricimp.com/app/rest/builds/buildType:(id:JSONParser_BuildAndTest)/statusIcon)

## Usage ##

JSONParser has no constructor and one public function, *parse()*.

### parse(*jsonString[, converter]*)

This method converts the supplied JSON to a table.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *jsonString* | String | Yes | The JSON to parse |
| *converter* | Function | No | A function used to convert custom types. See [**Custom Types Converter**](#custom-type-converter), below, for more information |

#### Custom Types Converter ####

An optional converter function can be passed into *parse()* to de-serialize custom types. The function has two parameters:

- *value* &mdash; String representation of a value.
- *type* &mdash; String indicating conversion type: `"string"` or `"number"`.

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

#### Return Value ####

Table &mdash; the full de-serialized data.

#### Basic Example ####

```squirrel
local jsonString = "{\"one\" : 1}";
result <- JSONParser.parse(jsonString);
server.log(result.one);
// Displays '1'
```

#### Extended Example ####

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
// Displays '{"a":1,"c":"@mycustomtype:100500","b":"Something"}'

result <- JSONParser.parse(s, function (val, type) {
    if ("number" == type) {
        return val.tofloat();
    } else if ("string" == type) {
        if (null != val.find("@mycustomtype")) {
            // Convert my custom type
            val = MyCustomType(val.slice(14))
        }

        return val;
    }
});

server.log(result.c instanceof MyCustomType);
// Displays 'true'

server.log(result.c.getValue());
// Displays '100500'
```

## Testing ##

This repository contains automated tests that can be run on the command line using [impt](https://github.com/electricimp/imp-central-impt). For documentation on how to configure and run tests please see the [impt testing guide](https://github.com/electricimp/imp-central-impt/blob/master/TestingGuide.md).

Test configuration is stored in the `.impt.test` file. To run tests locally:

- Update the *deviceGroupId* to a device group Id in your impCentral account.
- Use impt commands to log into your impCentral account.
- Run tests using the `impt test run` command.

Tests do not require any specific hardware or environment variables. Please do not include modified `.impt.test` configuration files when submitting pull requests to this repository.

## License ##

This library is licensed under the [MIT License](LICENSE). It is Partially based on Douglas Crockford's [state-machine JSON parser](https://github.com/douglascrockford/JSON-js/blob/master/json_parse_state.js) available as public domain.
