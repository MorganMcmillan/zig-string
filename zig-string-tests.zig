const std = @import("std");
const eql = std.mem.eql;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

const zig_string = @import("./zig-string.zig");
const String = zig_string.String;
const ArenaAllocator = std.heap.ArenaAllocator;

fn expectStrEqual(expected: []const u8, actual: []const u8) !void {
    if (!std.mem.eql(u8, expected, actual)) {
        std.debug.print("expected \"{s}\", got \"{s}\"", .{ expected, actual });
        return error.TestUnexpectedResult;
    }
}

test "Basic Usage" {
    // Use your favorite allocator
    var arena = ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // Create your String
    var myString = String.init(arena.allocator());
    defer myString.deinit();

    // Use functions provided
    try myString.concat("🔥 Hello!");
    _ = myString.pop();
    try myString.concat(", World 🔥");

    // Success!
    try expectStrEqual(myString.str(), "🔥 Hello, World 🔥");
}

test "String Tests" {
    // Allocator for the String
    const page_allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(page_allocator);
    defer arena.deinit();

    // This is how we create the String
    var myStr = String.init(arena.allocator());
    defer myStr.deinit();

    // allocate & capacity
    try myStr.allocate(16);
    try expectEqual(myStr.capacity(), 16);
    try expectEqual(myStr.len(), 0);

    // truncate
    try myStr.truncate();
    try expectEqual(myStr.capacity(), myStr.len());
    try expectEqual(myStr.capacity(), 0);

    // concat
    try myStr.concat("A");
    try myStr.concat("\u{5360}");
    try myStr.concat("💯");
    try myStr.concat("Hello🔥");

    try expectEqual(myStr.len(), 17);

    // pop & length
    try expectEqual(myStr.char_count(), 9);
    try expect(eql(u8, myStr.pop().?, "🔥"));
    try expectEqual(myStr.char_count(), 8);
    try expect(eql(u8, myStr.pop().?, "o"));
    try expectEqual(myStr.char_count(), 7);
    try expectStrEqual(myStr.str(), "A\u{5360}💯Hell");

    // str & cmp
    try expect(myStr.cmp("A\u{5360}💯Hell"));
    try expect(myStr.cmp(myStr.str()));

    // charAt
    try expect(eql(u8, myStr.charAt(2).?, "💯"));
    try expect(eql(u8, myStr.charAt(1).?, "\u{5360}"));
    try expect(eql(u8, myStr.charAt(0).?, "A"));

    // insert
    try myStr.insert("🔥", 1);
    try expect(eql(u8, myStr.charAt(1).?, "🔥"));
    try expectStrEqual(myStr.str(), "A🔥\u{5360}💯Hell");

    // find
    try expectEqual(myStr.find("🔥").?, 1);
    try expectEqual(myStr.find("💯").?, 3);
    try expectEqual(myStr.find("Hell").?, 4);

    // remove & removeRange
    try myStr.removeRange(0, 3);
    try expectStrEqual(myStr.str(), "💯Hell");
    try expect(myStr.cmp("💯Hell"));
    try myStr.remove(myStr.len() - 1);
    try expect(myStr.cmp("💯Hel"));

    const whitelist = [_]u8{ ' ', '\t', '\n', '\r' };

    // trimStart
    try myStr.insert("      ", 0);
    myStr.trimStart(whitelist[0..]);
    try expect(myStr.cmp("💯Hel"));

    // trimEnd
    _ = try myStr.concat("lo💯\n      ");
    myStr.trimEnd(whitelist[0..]);
    try expect(myStr.cmp("💯Hello💯"));

    // clone
    var testStr = try myStr.clone();
    defer testStr.deinit();
    try expect(testStr.cmp(myStr.str()));

    // reverse
    myStr.reverse();
    try expect(myStr.cmp("💯olleH💯"));
    myStr.reverse();
    try expect(myStr.cmp("💯Hello💯"));

    // repeat
    try myStr.repeat(2);
    try expect(myStr.cmp("💯Hello💯💯Hello💯💯Hello💯"));

    // isEmpty
    try expect(!myStr.isEmpty());

    // split
    try expect(eql(u8, myStr.split("💯", 0).?, ""));
    try expect(eql(u8, myStr.split("💯", 1).?, "Hello"));
    try expect(eql(u8, myStr.split("💯", 2).?, ""));
    try expect(eql(u8, myStr.split("💯", 3).?, "Hello"));
    try expect(eql(u8, myStr.split("💯", 5).?, "Hello"));
    try expect(eql(u8, myStr.split("💯", 6).?, ""));

    var splitStr = String.init(arena.allocator());
    defer splitStr.deinit();

    try splitStr.concat("variable='value'");
    try expect(eql(u8, splitStr.split("=", 0).?, "variable"));
    try expect(eql(u8, splitStr.split("=", 1).?, "'value'"));

    // splitToString
    var newSplit = try splitStr.splitToString("=", 0);
    try expect(newSplit != null);
    defer newSplit.?.deinit();

    try expect(eql(u8, newSplit.?.str(), "variable"));

    // toLowercase & toUppercase
    myStr.toUppercase();
    try expect(myStr.cmp("💯HELLO💯💯HELLO💯💯HELLO💯"));
    myStr.toLowercase();
    try expect(myStr.cmp("💯hello💯💯hello💯💯hello💯"));

    // substr
    var subStr = try myStr.substr(0, 7);
    defer subStr.deinit();
    try expect(subStr.cmp("💯hello💯"));

    // clear
    myStr.clear();
    try expectEqual(myStr.len(), 0);
    try expectEqual(myStr.len(), 0);

    // writer
    const writer = myStr.writer();
    const length = try writer.write("This is a Test!");
    try expectEqual(length, 15);

    // owned
    const mySlice = try myStr.toOwned();
    try expect(eql(u8, mySlice.?, "This is a Test!"));
    arena.allocator().free(mySlice.?);

    // StringIterator
    var i: usize = 0;
    var iter = myStr.iterator();
    while (iter.next()) |ch| {
        if (i == 0) {
            try expect(eql(u8, "T", ch));
        }
        i += 1;
    }

    try expectEqual(i, myStr.len());

    // setStr
    const contents = "setStr Test!";
    try myStr.setStr(contents);
    try expect(myStr.cmp(contents));

    // non ascii supports in windows
    // try expectEqual(std.os.windows.kernel32.GetConsoleOutputCP(), 65001);
}

test "init with contents" {
    // Allocator for the String
    const page_allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(page_allocator);
    defer arena.deinit();

    const initial_contents = "String with initial contents!";

    // This is how we create the String with contents at the start
    var myStr = try String.initWithContents(arena.allocator(), initial_contents);
    try expect(eql(u8, myStr.str(), initial_contents));
}

test "startsWith Tests" {
    var arena = ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var myString = String.init(arena.allocator());
    defer myString.deinit();

    try myString.concat("bananas");
    try expect(myString.startsWith("bana"));
    try expect(!myString.startsWith("abc"));
}

test "endsWith Tests" {
    var arena = ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var myString = String.init(arena.allocator());
    defer myString.deinit();

    try myString.concat("asbananas");
    try expect(myString.endsWith("nas"));
    try expect(!myString.endsWith("abc"));

    try myString.truncate();
    try myString.concat("💯hello💯💯hello💯💯hello💯");
    std.debug.print("", .{});
    try expect(myString.endsWith("hello💯"));
}

test "replace Tests" {
    var arena = ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // Create your String
    var myString = String.init(arena.allocator());
    defer myString.deinit();

    try myString.concat("hi,how are you");
    var result = try myString.replace("hi,", "");
    try expect(result);
    try expect(eql(u8, myString.str(), "how are you"));

    result = try myString.replace("abc", " ");
    try expect(!result);

    myString.clear();
    try myString.concat("💯hello💯💯hello💯💯hello💯");
    _ = try myString.replace("hello", "hi");
    try expect(eql(u8, myString.str(), "💯hi💯💯hi💯💯hi💯"));
}

test "rfind Tests" {
    var arena = ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var myString = try String.initWithContents(arena.allocator(), "💯hi💯💯hi💯💯hi💯");
    defer myString.deinit();

    try expectEqual(myString.rfind("hi"), 9);
}
