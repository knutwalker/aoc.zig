pub const std = @import("std");
pub const Alloc = std.mem.Allocator;
pub const List = std.ArrayList;
pub const MultiList = std.MultiArrayList;
pub const Map = std.AutoHashMap;
pub const StrMap = std.StringHashMap;
pub const BitSet = std.DynamicBitSet;
pub const Str = []const u8;

const u = @import("util.zig");
const a = u.gpa;

const day_input = @embedFile("data/day16.txt");

pub fn main() !void {
    var results = std.BoundedArray(Output, 2){};

    var measure = u.Measure.start();
    defer measure.dump();

    if (try part1(day_input)) |p1| {
        results.append(p1) catch unreachable;
        measure.lap("part 1");
    }

    if (try part2(day_input)) |p2| {
        results.append(p2) catch unreachable;
        measure.lap("part 2");
    }

    for (results.constSlice()) |res| {
        std.io.getStdOut().writer().print("{}\n", .{res}) catch {};
    }
}

const Parsed = Str;

pub fn parse(input: Str) !?Parsed {
    return input;
}

const Output = i64;

pub fn part1(input: Str) !?Output {
    _ = input;
    return null;
}

pub fn part2(input: Str) !?Output {
    _ = input;
    return null;
}

test "day16 example" {
    const input =
        \\
    ;

    try std.testing.expectEqual(null, try part1(input));
    try std.testing.expectEqual(null, try part2(input));
}

test "day16 input" {
    // uncomment to test with actual input when ready

    // try std.testing.expectEqual( , try part1(day_input) );
    // try std.testing.expectEqual( , try part2(day_input) );
}
