# Squirrel JSON Parser

## Usage

```squirrel
result <- JSONParser.parse(str[, <converter function>]);
```

## Custom types converter

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

## License

[MIT](LICENSE.txt)

## Author

Mikhail Yurasov <mikhail@electricimp.com>
