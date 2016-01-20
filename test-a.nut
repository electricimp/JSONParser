// few tests
// should run in both ei and vanilla squirrel

/**
 * JSON encoder.
 * @author Mikhail Yurasov <mikhail@electricimp.com>
 * @verion 0.3.3
 */
JSON <- {

  version = [0, 3, 3],

  // max structure depth
  // anything above probably has a cyclic ref
  _maxDepth = 32,

  /**
   * Encode value to JSON
   * @param {table|array|*} value
   * @returns {string}
   */
  stringify = function (value) {
    return JSON._encode(value);
  },

  /**
   * @param {table|array} val
   * @param {integer=0} depth – current depth level
   * @private
   */
  _encode = function (val, depth = 0) {

    // detect cyclic reference
    if (depth > JSON._maxDepth) {
      throw "Possible cyclic reference";
    }

    local
      r = "",
      s = "",
      i = 0;

    switch (type(val)) {

      case "table":
      case "class":
        s = "";

        // serialize properties, but not functions
        foreach (k, v in val) {
          if (type(v) != "function") {
            s += ",\"" + k + "\":" + JSON._encode(v, depth + 1);
          }
        }

        s = s.len() > 0 ? s.slice(1) : s;
        r += "{" + s + "}";
        break;

      case "array":
        s = "";

        for (i = 0; i < val.len(); i++) {
          s += "," + JSON._encode(val[i], depth + 1);
        }

        s = (i > 0) ? s.slice(1) : s;
        r += "[" + s + "]";
        break;

      case "integer":
      case "float":
      case "bool":
        r += val;
        break;

      case "null":
        r += "null";
        break;

      case "instance":

        if ("_serialize" in val && type(val._serialize) == "function") {

          // serialize instances by calling _serialize method
          r += JSON._encode(val._serialize(), depth + 1);

        } else {

          s = "";

          try {

            // iterate through instances which implement _nexti meta-method
            foreach (k, v in val) {
              s += ",\"" + k + "\":" + JSON._encode(v, depth + 1);
            }

          } catch (e) {

            // iterate through instances w/o _nexti
            // serialize properties, but not functions
            foreach (k, v in val.getclass()) {
              if (type(v) != "function") {
                s += ",\"" + k + "\":" + JSON._encode(val[k], depth + 1);
              }
            }

          }

          s = s.len() > 0 ? s.slice(1) : s;
          r += "{" + s + "}";
        }

        break;

      // strings and all other
      default:
        r += "\"" + this._escape(val.tostring()) + "\"";
        break;
    }

    return r;
  },

  /**
   * Escape strings according to http://www.json.org/ spec
   * @param {string} str
   */
  _escape = function (str) {
    local res = "";

    for (local i = 0; i < str.len(); i++) {

      local ch1 = (str[i] & 0xFF);

      if ((ch1 & 0x80) == 0x00) {
        // 7-bit Ascii

        ch1 = format("%c", ch1);

        if (ch1 == "\"") {
          res += "\\\"";
        } else if (ch1 == "\\") {
          res += "\\\\";
        } else if (ch1 == "/") {
          res += "\\/";
        } else if (ch1 == "\b") {
          res += "\\b";
        } else if (ch1 == "\f") {
          res += "\\f";
        } else if (ch1 == "\n") {
          res += "\\n";
        } else if (ch1 == "\r") {
          res += "\\r";
        } else if (ch1 == "\t") {
          res += "\\t";
        } else {
          res += ch1;
        }

      } else {

        if ((ch1 & 0xE0) == 0xC0) {
          // 110xxxxx = 2-byte unicode
          local ch2 = (str[++i] & 0xFF);
          res += format("%c%c", ch1, ch2);
        } else if ((ch1 & 0xF0) == 0xE0) {
          // 1110xxxx = 3-byte unicode
          local ch2 = (str[++i] & 0xFF);
          local ch3 = (str[++i] & 0xFF);
          res += format("%c%c%c", ch1, ch2, ch3);
        } else if ((ch1 & 0xF8) == 0xF0) {
          // 11110xxx = 4 byte unicode
          local ch2 = (str[++i] & 0xFF);
          local ch3 = (str[++i] & 0xFF);
          local ch4 = (str[++i] & 0xFF);
          res += format("%c%c%c%c", ch1, ch2, ch3, ch4);
        }

      }
    }

    return res;
  }
}

/**
 * JSON Parser & Tokenizer
 *
 * @author Mikhail Yurasov <mikhail@electricimp.com>
 * @package JSONParser
 * @version 0.1.0
 */

/**
 * JSON Tokenizer
 * @package JSONParser
 */
class JSONTokenizer {

  // should be the same for all components within JSONParser package
  static version = [0, 1, 0];

  _ptfnRegex = null;
  _numberRegex = null;
  _stringRegex = null;
  _ltrimRegex = null;
  _unescapeRegex = null;

  constructor() {
    // punctuation/true/false/null
    this._ptfnRegex = regexp("^(?:\\,|\\:|\\[|\\]|\\{|\\}|true|false|null)");

    // numbers
    this._numberRegex = regexp("^(?:\\-?\\d+(?:\\.\\d*)?(?:[eE][+\\-]?\\d+)?)");

    // strings
    this._stringRegex = regexp("^(?:\\\"((?:[^\\r\\n\\t\\\\\\\"]|\\\\(?:[\"\\\\\\/trnfb]|u[0-9a-fA-F]{4}))*)\\\")");

    // ltrim pattern
    this._ltrimRegex = regexp("^[\\s\\t\\n\\r]*");

    // string unescaper tokenizer pattern
    this._unescapeRegex = regexp("\\\\(?:(?:u\\d{4})|[\\\"\\\\/bfnrt])");
  }

  /**
   * Get next available token
   * @param {string} str
   * @param {integer} start
   * @return {{type,value,length}|null}
   */
  function nextToken(str, start = 0) {

    local
      m,
      type,
      token,
      value,
      length,
      whitespaces;

    // count # of left-side whitespace chars
    whitespaces = this._leadingWhitespaces(str, start);
    start += whitespaces;

    if (m = this._ptfnRegex.capture(str, start)) {
      // punctuation/true/false/null
      value = str.slice(m[0].begin, m[0].end);
      type = "ptfn";
    } else if (m = this._numberRegex.capture(str, start)) {
      // number
      value = str.slice(m[0].begin, m[0].end);
      type = "number";
    } else if (m = this._stringRegex.capture(str, start)) {
      // string
      value = str.slice(m[1].begin, m[1].end);
      type = "string";
    } else {
      return null;
    }

    token = {
      type = type,
      value = value,
      length = m[0].end - m[0].begin + whitespaces
    };

    return token;
  }

  /**
   * Count # of left-side whitespace chars
   * @param {string} str
   * @param {integer} start
   * @return {integer} number of leading spaces
   */
  function _leadingWhitespaces(str, start) {
    local r = this._ltrimRegex.capture(str, start);

    if (r) {
      return r[0].end - r[0].begin;
    } else {
      return 0;
    }
  }

  // unesacape() replacements table
  _unescapeReplacements = {
    "b": "\b",
    "f": "\f",
    "n": "\n",
    "r": "\r",
    "t": "\t"
  };

  /**
   * Unesacape string escaped per JSON standard
   * @param {string} str
   * @return {string}
   */
  function unescape(str) {

    local start = 0;
    local res = "";

    while (start < str.len()) {
      local m = this._unescapeRegex.capture(str, start);

      if (m) {
        local token = str.slice(m[0].begin, m[0].end);

        // append chars before match
        local pre = str.slice(start, m[0].begin);
        res += pre;

        if (token.len() == 6) {
          // unicode char in format \uhhhh, where hhhh is hex char code
          // todo: convert \uhhhh chars
          res += token;
        } else {
          // escaped char
          // @see http://www.json.org/
          local char = token.slice(1);

          if (char in this._unescapeReplacements) {
            res += this._unescapeReplacements[char];
          } else {
            res += char;
          }
        }

      } else {
        // append the rest of the source string
        res += str.slice(start);
        break;
      }

      start = m[0].end;
    }

    return res;
  }
}

/**
 * JSON Parser
 * @package JSONParser
 */
class JSONParser {

  // should be the same for all components within JSONParser package
  static version = [0, 1, 0];

  /**
   * Parse JSON string into data structure
   *
   * @param {string} str
   * @param {function({string} value[, "number"|"string"])|null} converter
   * @return {*}
   */
  function parse(str, converter = null) {

    local state;
    local stack = []
    local container;
    local key;
    local value;

    // actions for string tokens
    local string = {
      go = function () {
        state = "ok";
      },
      firstokey = function () {
        key = value;
        state = "colon";
      },
      okey = function () {
        key = value;
        state = "colon";
      },
      ovalue = function () {
        value = this._convert(value, "string", converter);
        state = "ocomma";
      }.bindenv(this),
      firstavalue = function () {
        value = this._convert(value, "string", converter);
        state = "acomma";
      }.bindenv(this),
      avalue = function () {
        value = this._convert(value, "string", converter);
        state = "acomma";
      }.bindenv(this)
    };

    // the actions for number tokens
    local number = {
      go = function () {
        state = "ok";
      },
      ovalue = function () {
        value = this._convert(value, "number", converter);
        state = "ocomma";
      }.bindenv(this),
      firstavalue = function () {
        value = this._convert(value, "number", converter);
        state = "acomma";
      }.bindenv(this),
      avalue = function () {
        value = this._convert(value, "number", converter);
        state = "acomma";
      }.bindenv(this)
    };

    // action table
    // describes where the state machine will go from each given state
    local action = {

      "{": {
        go = function () {
          stack.push({state = "ok"});
          container = {};
          state = "firstokey";
        },
        ovalue = function () {
          stack.push({container = container, state = "ocomma", key = key});
          container = {};
          state = "firstokey";
        },
        firstavalue = function () {
          stack.push({container = container, state = "acomma"});
          container = {};
          state = "firstokey";
        },
        avalue = function () {
          stack.push({container = container, state = "acomma"});
          container = {};
          state = "firstokey";
        }
      },

      "}" : {
        firstokey = function () {
          local pop = stack.pop();
          value = container;
          container = ("container" in pop) ? pop.container : null;
          key = ("container" in pop) ? pop.key : null;
          state = pop.state;
        },
        ocomma = function () {
          local pop = stack.pop();
          container[key] <- value;
          value = container;
          container = ("container" in pop) ? pop.container : null;
          key = ("container" in pop) ? pop.key : null;
          state = pop.state;
        }
      },

      "[" : {
        go = function () {
          stack.push({state = "ok"});
          container = [];
          state = "firstavalue";
        },
        ovalue = function () {
          stack.push({container = container, state = "ocomma", key = key});
          container = [];
          state = "firstavalue";
        },
        firstavalue = function () {
          stack.push({container = container, state = "acomma"});
          container = [];
          state = "firstavalue";
        },
        avalue = function () {
          stack.push({container = container, state = "acomma"});
          container = [];
          state = "firstavalue";
        }
      },

      "]" : {
        firstavalue = function () {
          local pop = stack.pop();
          value = container;
          container = ("container" in pop) ? pop.container : null;
          key = ("container" in pop) ? pop.key : null;
          state = pop.state;
        },
        acomma = function () {
          local pop = stack.pop();
          container.push(value);
          value = container;
          container = ("container" in pop) ? pop.container : null;
          key = ("container" in pop) ? pop.key : null;
          state = pop.state;
        }
      },

      ":" : {
        colon = function () {
          // check if the key already exists
          if (key in container) {
            throw "Duplicate key \"" + key + "\"";
          }
          state = "ovalue";
        }
      },

      "," : {
        ocomma = function () {
          container[key] <- value;
          state = "okey";
        },
        acomma = function () {
          container.push(value);
          state = "avalue";
        }
      },

      "true" : {
        go = function () {
          value = true;
          state = "ok";
        },
        ovalue = function () {
          value = true;
          state = "ocomma";
        },
        firstavalue = function () {
          value = true;
          state = "acomma";
        },
        avalue = function () {
          value = true;
          state = "acomma";
        }
      },

      "false" : {
        go = function () {
          value = false;
          state = "ok";
        },
        ovalue = function () {
          value = false;
          state = "ocomma";
        },
        firstavalue = function () {
          value = false;
          state = "acomma";
        },
        avalue = function () {
          value = false;
          state = "acomma";
        }
      },

      "null" : {
        go = function () {
          value = null;
          state = "ok";
        },
        ovalue = function () {
          value = null;
          state = "ocomma";
        },
        firstavalue = function () {
          value = null;
          state = "acomma";
        },
        avalue = function () {
          value = null;
          state = "acomma";
        }
      }
    };

    //

    state = "go";
    stack = [];

    // current tokenizeing position
    local start = 0;

    try {

      local
        result,
        token,
        tokenizer = JSONTokenizer();

      while (true) {

        token = tokenizer.nextToken(str, start);

        if (!token) break;

        if ("ptfn" == token.type) {
          // punctuation/true/false/null
          action[token.value][state]();
        } else if ("number" == token.type) {
          // number
          value = token.value;
          /*value = this._convert(value, token.type, converter);*/
          number[state]();
        } else if ("string" == token.type) {
          // string
          value = tokenizer.unescape(token.value);
          /*value = this._convert(value, token.type, converter);*/
          string[state]();
        } else {
          break;
        }

        start += token.length;
      }

    } catch (e) {
      state = e;
    }

    // check is the final state is not ok
    // or if there is somethign left in the str
    if (state != "ok" || regexp("[^\\s]").capture(str, start)) {
      local min = @(a, b) a < b ? a : b;
      local near = str.slice(start, min(str.len(), start + 10));
      throw "JSON Syntax Error near `" + near + "`";
    }

    return value;
  }

  /**
   * Convert strings/numbers
   * Uses custom converter function
   *
   * @param {string} value
   * @param {string} type
   * @param {function|null} converter
   */
  function _convert(value, type, converter) {
    if ("function" == typeof converter) {

      // # of params for converter function

      local parametercCount = 2;

      // .getinfos() is missing from imp
      if ("getinfos" in converter) {
        parametercCount = converter.getinfos().parameters.len()
          - 1 /* "this" is also included */;
      }

      if (parametercCount == 1) {
        return converter(value);
      } else if (parametercCount == 2) {
        return converter(value, type);
      } else {
        throw "Error: converter function must take 1 or 2 parameters"
      }

    } else if ("number" == type) {
      return value.tofloat();
    } else {
      return value;
    }
  }
}

// few tests

function p(str) {
    if ("server" in getroottable()) {
    server.log(str);
  } else {
    ::print(str + "\n");
  }
}

s <- {};
s[0] <- "  {\"a\":123, \"c\":  {\"_field\":123},\"b\":[1,2,3,4],\"e\":{\"field\":123},\"d\":5.125,\"g\":true,\"f\":null,\"i\":\"a\\ta\",\"h\":\"Some\\nùnicode\\rstring ø∆ø\"}";
s[1] <- "{\n\"a\":123, \"bc\":222}";
s[2] <- "{\r\n    \"glossary\": {\r\n        \"title\": \"example glossary\",\r\n\t\t\"GlossDiv\": {\r\n            \"title\": \"S\",\r\n\t\t\t\"GlossList\": {\r\n                \"GlossEntry\": {\r\n                    \"ID\": \"SGML\",\r\n\t\t\t\t\t\"SortAs\": \"SGML\",\r\n\t\t\t\t\t\"GlossTerm\": \"Standard Generalized Markup Language\",\r\n\t\t\t\t\t\"Acronym\": \"SGML\",\r\n\t\t\t\t\t\"Abbrev\": \"ISO 8879:1986\",\r\n\t\t\t\t\t\"GlossDef\": {\r\n                        \"para\": \"A meta-markup language, used to create markup languages such as DocBook.\",\r\n\t\t\t\t\t\t\"GlossSeeAlso\": [\"GML\", \"XML\"]\r\n                    },\r\n\t\t\t\t\t\"GlossSee\": \"markup\"\r\n                }\r\n            }\r\n        }\r\n    }\r\n}";
s[3] <- "{\"widget\": {\r\n    \"debug\": \"on\",\r\n    \"window\": {\r\n        \"title\": \"Sample Konfabulator Widget\",\r\n        \"name\": \"main_window\",\r\n        \"width\": 500,\r\n        \"height\": 500\r\n    },\r\n    \"image\": { \r\n        \"src\": \"Images/Sun.png\",\r\n        \"name\": \"sun1\",\r\n        \"hOffset\": 250,\r\n        \"vOffset\": 250,\r\n        \"alignment\": \"center\"\r\n    },\r\n    \"text\": {\r\n        \"data\": \"Click Here\",\r\n        \"size\": 36,\r\n        \"style\": \"bold\",\r\n        \"name\": \"text1\",\r\n        \"hOffset\": 250,\r\n        \"vOffset\": 100,\r\n        \"alignment\": \"center\",\r\n        \"onMouseUp\": \"sun1.opacity = (sun1.opacity / 100) * 90;\"\r\n    }\r\n}} ";

foreach (k, v in s) {

  collectgarbage();

  if ("imp" in getroottable() && "getmemoryfree" in imp) {
    local m = imp.getmemoryfree();
    p("memory used: " + m);
  }

  o <- JSONParser.parse(v, function (val, type) {
    if ("number" == type) {
      return val.tofloat();
    } else if ("string" == type) {
      return val.toupper();
    }
  });

  if ("imp" in getroottable() && "getmemoryfree" in imp) {
    local m = imp.getmemoryfree();
    p("memory used: " + m);
  }

  p(JSON.stringify(o) + "\n\n");

}
