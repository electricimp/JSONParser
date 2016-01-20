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
