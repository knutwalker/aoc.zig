// prelude {{{
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

const day_input = @embedFile("data/day23.txt");

pub fn main() !void {
    var results = std.BoundedArray(Output, 2){};

    var measure = u.Measure.start();
    defer measure.dump();

    const in = try parse(day_input);
    measure.lapWithSize("parse", day_input.len);

    if (try part1(in)) |p1| {
        results.append(p1) catch unreachable;
        measure.lap("part 1");
    }

    if (try part2(in)) |p2| {
        results.append(p2) catch unreachable;
        measure.lap("part 2");
    }

    for (results.constSlice()) |res| {
        std.io.getStdOut().writer().print("{}\n", .{res}) catch {};
    }
}
// }}}

const Parsed = Str;

pub fn parse(input: Str) !Parsed {
    return input;
}

const Output = i64;

pub fn part1(input: Parsed) !?Output {
    _ = input; //autofix
    return null;
}

pub fn part2(input: Parsed) !?Output {
    _ = input; //autofix
    return null;
}

test "day23 example" {
    const input =
        \\
    ;

    const in = try parse(input);
    try std.testing.expectEqual(null, try part1(in));
    try std.testing.expectEqual(null, try part2(in));
}

test "day23 input" {
    if ("remove_this_when_ready".len > 0) return error.SkipZigTest;

    const in = try parse(day_input);
    try std.testing.expectEqual(null, try part1(in));
    try std.testing.expectEqual(null, try part2(in));
}
