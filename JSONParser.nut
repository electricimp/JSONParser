/**
 * JSON Parser
 *
 * @author Mikhail Yurasov <mikhail@electricimp.com>
 * @version 0.0.1-dev
 */

class JSONTokenizer {

  // punctuation/true/false/null
  static ptfnPattern = "^(?:\\,|\\:|\\[|\\]|\\{|\\}|true|false|null)";

  // numbers
  static numberPattern = "^(?:\\-?\\d+(?:\\.\\d*)?(?:[eE][+\\-]?\\d+)?)";

  // strings
  static stringPattern = "^(?:\\\"((?:[^\\r\\n\\t\\\\\\\"]|\\\\(?:[\"\\\\\\/trnfb]|u[0-9a-fA-F]{4}))*)\\\")";

  // trimming pattern
  static trimPattern = regexp("^[\\s\\t\\n\\r]*");

  function tokenize() {

    local ptfnRegex = regex(this.ptfnPattern);
    local numberRegex = regex(this.numberPattern);
    local stringRegex = regex(this.stringPattern);



  }
}

class JSONParser {

  static version = [0, 0, 1, "dev"];

  // enable/disable debug output
  static debug = false;

  // punctuation/true/false/null
  static ptfnPattern = "^(?:\\,|\\:|\\[|\\]|\\{|\\}|true|false|null)";

  // numbers
  static numberPattern = "^(?:\\-?\\d+(?:\\.\\d*)?(?:[eE][+\\-]?\\d+)?)";

  // strings
  static stringPattern = "^(?:\\\"((?:[^\\r\\n\\t\\\\\\\"]|\\\\(?:[\"\\\\\\/trnfb]|u[0-9a-fA-F]{4}))*)\\\")";

  // regex for trimming
  static trimPattern = regexp("^[\\s\\t\\n\\r]*");

  /**
   * Extends regexp::capture() with capturing string
   * @param {regexp} regex
   * @param {string} str
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

  /**
   * Trim whitespace characters on the left
   * @param {string} str
   */
  function _lTrim(str) {

    static e = regexp(this.trimPattern)

    local r = e.capture(str);

    if (r) {
      return str.slice(r[0].end);
    } else {
      return str;
    }
  }

  /**
   * Debug printouts
   */
  function _debug(str) {
    if (this.debug) {
      if ("server" in getroottable() && "log" in server) {
        server.log(str);
      } else {
        ::print(str + "\n");
      }
    }
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

    /*try {*/

      local
        result,
        token;

      while (true) {

        str = this._lTrim(str);
        this._debug("str before: " + str);

        if (result = this._capture(this.ptfnRegex, str)) {

          // punctuation/true/false/null
          token = result[0].match;
          this._debug("state == " + state)
          this._debug("ptfn token found: " + token);
          action[token][state]();
          this._debug("state -> " + state);

        } else if (result = this._capture(this.numberRegex, str)) {

          // number
          token = result[0].match
          this._debug("state == " + state)
          this._debug("number token found: " + token);
          value = token.tofloat();
          number[state]();
          this._debug("state -> " + state);

        } else if (result = this._capture(this.stringRegex, str)) {

          // string
          token = result[1].match
          this._debug("state == " + state)
          this._debug("string token found: " + token);
          value = token;
          string[state]();
          this._debug("state -> " + state);

        } else {
          break;
        }

        str = str.slice(result[0].end);

        this._debug("str after: " + str);
        this._debug("");

      }

    /*} catch (e) {
      state = e;
      throw e;
    }*/

    // check is the final state is not ok
    // or if there is somethign left
    /*::print(str.len());*/
    if (state != "ok" || regexp("[^\\s]").capture(str)) {
      /*throw "JSON syntax error near " + str.slice(0, str.len() > 10 ? 10 : str.len());*/
    }

    return value;
  }
}

s <- "           {\"a\":123, \"c\":{\"_field\":123},\"b\":[1,2,3,4],\"e\":{\"field\":123},\"d\":5.125,\"g\":true,\"f\":null,\"i\":\"a\\ta\",\"h\":\"Some\\nùnicode\\rstring ø∆ø\"}";
/*o <- JSONParser.parse();*/
/*server.log(JSON.stringify(o));*/


/*r <- regexpEx("^(\\,\\:\\[\\]\\{\\})|true|false");*/


s <- "\"a\":123, \"bc\":222}";

// puntuation, true, false, null
r <- JSONParser.ptfnRegex;
server.log("ptfn:\n" + _(JSONParser._capture(r, s)));

// num
r <- JSONParser.numberRegex;
server.log("\n\nnum:\n" + _(JSONParser._capture(r, s)));

// string
r <- JSONParser.stringRegex;
server.log("\n\nstr:\n" + _(JSONParser._capture(r, s)));


/*s <- "{\"a\":123, \"bc\":222}";*/

/*JSONParser.debug <- true;
o <- JSONParser.parse(s);
server.log("\nres:" + _(o));*/
