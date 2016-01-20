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
 * JSON Parser
 *
 * @author Mikhail Yurasov <mikhail@electricimp.com>
 * @version 0.0.1-dev
 */

class JSONParser {

  static version = [0, 0, 1, "dev"];

  // punctuation/true/false/null
  static ptfnRegex = regexp("^(?:\\s)*(\\,|\\:|\\,|\\[|\\]|\\{|\\}|true|false|null)");

  // numbers
  static numberRegex = regexp("^(?:\\s)*(\\-?\\d+(?:\\.\\d*)?(?:[eE][+\\-]?\\d+)?)");

  // strings
  static stringRegex = regexp("^(?:\\s)*(\\\"(?:[^\\r\\n\\t\\\\\\\"]|\\\\(?:[\"\\\\\\/trnfb]|u[0-9a-fA-F]{4}))*\\\")");

  /**
   * Extends regexp::capture() with capturing string
   */
  function _capture(regex, str) {
    local r = regex.capture(str);

    if (r) {
      foreach (k, v in r) {
        r[k].match <- str.slice(v.begin, v.end);
      }
    }

    return r;
  }

  parse = function (str) {

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
        state = "ocomma";
      },
      firstavalue = function () {
        state = "acomma";
      },
      avalue = function () {
        state = "acomma";
      }
    };

    // the actions for number tokens
    local number = {
      go = function () {
        state = "ok";
      },
      ovalue = function () {
        state = "ocomma";
      },
      firstavalue = function () {
        state = "acomma";
      },
      avalue = function () {
        state = "acomma";
      }
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
          container = pop.container;
          key = pop.key;
          state = pop.state;
        },
        ocomma = function () {
          local pop = stack.pop();
          container[key] = value;
          value = container;
          container = pop.container;
          key = pop.key;
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
          container = pop.container;
          key = pop.key;
          state = pop.state;
        },
        acomma = function () {
          local pop = stack.pop();
          container.push(value);
          value = container;
          container = pop.container;
          key = pop.key;
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
          container[key] = value;
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

    try {

      local
        result,
        token;

      while (true) {

        server.log("str before: " + str);

        if (result = this._capture(this.ptfnRegex, str)) {
          // punctuation/true/false/null
          token = result[1].match;
          server.log("state == " + state)
          server.log("ptfn token found: " + token);
          action[token][state]();
          server.log("state -> " + state);
        } else if (result = this._capture(this.numberRegex, str)) {
          // number
          token = result[1].match
          server.log("state == " + state)
          server.log("number token found: " + token);
          value = token.tofloat();
          number[state]();
          server.log("state -> " + state);
        } else if (result = this._capture(this.stringRegex, str)) {
          // string
          token = result[1].match
          server.log("state == " + state)
          server.log("string token found: " + token);
          value = token;
          string[state]();
          server.log("state -> " + state);
        } else {
          break;
        }

        str = str.slice(result[0].end);

        server.log("str after: " + str);
        server.log("");

      }

    } catch (e) {
      state = e;
    }

    return value;
  }
}

s <- "   {\"a\":123, \"c\":{\"_field\":123},\"b\":[1,2,3,4],\"e\":{\"field\":123},\"d\":5.125,\"g\":true,\"f\":null,\"i\":\"a\\ta\",\"h\":\"Some\\nùnicode\\rstring ø∆ø\"}";
/*o <- JSONParser.parse();*/
/*server.log(JSON.stringify(o));*/


/*r <- regexpEx("^(\\,\\:\\[\\]\\{\\})|true|false");*/


/*s <- "1,2]";

// puntuation, true, false, null
r <- JSONParser.ptfnRegex;
server.log("ptfn:\n" + JSON.stringify(JSONParser._capture(r, s)));

// num
r <- JSONParser.numberRegex;
server.log("\n\nnum:\n" + JSON.stringify(JSONParser._capture(r, s)));

// string
r <- JSONParser.stringRegex;
server.log("\n\nstr:\n" + JSON.stringify(JSONParser._capture(r, s)));*/

s <- "{\"a\":123}";

o <- JSONParser.parse(s);
server.log(JSON.stringify(o));
