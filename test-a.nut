// few tests
// should run in both ei and vanilla squirrel

/**
 * JSON Parser & Tokenizer
 *
 * @author Mikhail Yurasov <mikhail@electricimp.com>
 * @package JSONParser
 * @version 0.1.1
 */

/**
 * JSON Parser
 * @package JSONParser
 */
class JSONParser {

  // should be the same for all components within JSONParser package
  static version = [0, 1, 1];

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

      while (token = tokenizer.nextToken(str, start)) {

        if ("ptfn" == token.type) {
          // punctuation/true/false/null
          action[token.value][state]();
        } else if ("number" == token.type) {
          // number
          value = token.value;
          number[state]();
        } else if ("string" == token.type) {
          // string
          value = tokenizer.unescape(token.value);
          string[state]();
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

      // .getinfos() is missing on ei platform
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

/**
 * JSON Tokenizer
 * @package JSONParser
 */
class JSONTokenizer {

  // should be the same for all components within JSONParser package
  static version = [0, 1, 1];

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
