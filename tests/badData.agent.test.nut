/*
 * Check for failure when passed bad JSON encoded string
 */
class badData extends ImpTestCase {

    function testBadBasic() {
        // local data = {
        //     "a" : 1,
        //     "b" : 2,
        //     "c" : 3,
        // };
        // this.info(JSONEncoder.encode(data))

        // delete a comma
        this.assertThrowsError(JSONParser.parse, JSONParser, ["{\"a\":1\"c\":3,\"b\":2}"]);

        // delete a curly bracket
        this.assertThrowsError(JSONParser.parse, JSONParser, ["\"a\":1,\"c\":3,\"b\":2}"]);

        // delete the value
        this.assertThrowsError(JSONParser.parse, JSONParser, ["{\"a\":1,\"c\":,\"b\":2}"]);

        // delete a colon
        this.assertThrowsError(JSONParser.parse, JSONParser, ["{\"a\"1,\"c\":3,\"b\":2}"]);

        // delete the other bracket
        this.assertThrowsError(JSONParser.parse, JSONParser, ["{\"a\":1,\"c\":3,\"b\":2"]);

        // delete all the quotes
        this.assertThrowsError(JSONParser.parse, JSONParser, ["{a:1,c:3,b:2}"]);
    }

    function testBadArray() {
        // local data1 = {
        //     a = [1,2,3],
        //     b = ["A", "B", "C"],
        //     c = [1.1, 2.2, 3.3]
        // };
        // this.info(JSONEncoder.encode(data1))

        // delete a bracket
        this.assertThrowsError(JSONParser.parse, JSONParser, ["\"a\":[1,2,3],\"c\":[1.1,2.2,3.3],\"b\":[\"A\",\"B\",\"C\"]}"]);
        this.assertThrowsError(JSONParser.parse, JSONParser, ["{\"a\":[1,2,3],\"c\":[1.1,2.2,3.3],\"b\":[\"A\",\"B\",\"C\"]"]);

        // delete a square bracket
        this.assertThrowsError(JSONParser.parse, JSONParser, ["{\"a\":[1,2,3],\"c\":[1.1,2.2,3.3],\"b\":[\"A\",\"B\",\"C\"}"]);
        this.assertThrowsError(JSONParser.parse, JSONParser, ["{\"a\":[1,2,3],\"c\":1.1,2.2,3.3],\"b\":[\"A\",\"B\",\"C\"]}"]);
        this.assertThrowsError(JSONParser.parse, JSONParser, ["{\"a\":[1,2,3,\"c\":[1.1,2.2,3.3],\"b\":[\"A\",\"B\",\"C\"]}"]);

        // destroy colons
        this.assertThrowsError(JSONParser.parse, JSONParser, ["{\"a\"[1,2,3],\"c\"[1.1,2.2,3.3],\"b\"[\"A\",\"B\",\"C\"]}"]);


        // local data2 = [1, 2, "red", "blue", {"a": "table"}];
        // this.info(JSONEncoder.encode(data2))
        // "[1,2,\"red\",\"blue\",{\"a\":\"table\"}]"

        this.assertThrowsError(JSONParser.parse, JSONParser, ["1,2,\"red\",\"blue\",{\"a\":\"table\"}]"]);
        this.assertThrowsError(JSONParser.parse, JSONParser, ["[1,2,\"red\",\"blue\",{\"a\":\"table\"}"]);
        this.assertThrowsError(JSONParser.parse, JSONParser, ["[1,2,\"red\",\"blue\",{\"a\":\"table\"]"]);
        this.assertThrowsError(JSONParser.parse, JSONParser, ["[1,2,\"red\",\"blue\",\"a\":\"table\"}]"]);
        this.assertThrowsError(JSONParser.parse, JSONParser, ["[1,2,\"red\",\"blue\",{\"a\"\"table\"}]"]);
        this.assertThrowsError(JSONParser.parse, JSONParser, ["[1,2\"red\"\"blue\"{\"a\":\"table\"}]"]);
    }

    function testBadTable() {
        // local data = {
        //     "a" : [1,2,3],
        //     "b" : "Hello world!"
        //     "c" : 1598.677
        // };
        // this.info(JSONEncoder.encode(data))

        // remove commas
        this.assertThrowsError(JSONParser.parse, JSONParser, ["{\"a\":[1,2,3],\"c\":1598.68\"b\":\"Hello world!\"}"])
        this.assertThrowsError(JSONParser.parse, JSONParser, ["{\"a\":[1,2,3]\"c\":1598.68,\"b\":\"Hello world!\"}"])

        // remove brackets
        this.assertThrowsError(JSONParser.parse, JSONParser, ["{\"a\":[1,2,3],\"c\":1598.68,\"b\":\"Hello world!\""])
        this.assertThrowsError(JSONParser.parse, JSONParser, ["\"a\":[1,2,3],\"c\":1598.68,\"b\":\"Hello world!\"}"])

        // and quotation marks
        this.assertThrowsError(JSONParser.parse, JSONParser, ["{\"a\":[1,2,3],\"c:1598.68,\"b\":\"Hello world!\"}"])
        this.assertThrowsError(JSONParser.parse, JSONParser, ["{\"a\":[1,2,3],\"c\":1598.68,\"b\":\"Hello world!}"])

        // whole chunk of data missing
        this.assertThrowsError(JSONParser.parse, JSONParser, ["{\"a\":,\"c\":1598.68,\"b\":\"Hello world!\"}"])
    }
}
