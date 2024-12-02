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

const day_input = @embedFile("data/day1.txt");

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

const Parsed = struct { []u32, []u32 };

pub fn parse(input: Str) !?Parsed {
    return try u.columnsOf(struct { u32, u32 }, input);
}

const Output = i64;

pub fn part1(input: Str) !?Output {
    const left, const right = try parse(input) orelse return null;

    u.sortAsc(left);
    u.sortAsc(right);

    var sum: Output = 0;
    for (left, right) |l, r| {
        sum += u.absDiff(l, r);
    }

    return sum;
}

pub fn part2(input: Str) !?Output {
    const left, const right = try parse(input) orelse return null;

    var right_counts = Map(u32, u32).init(a);
    for (right) |r| {
        (try right_counts.getOrPutValue(r, 0)).value_ptr.* += 1;
    }

    var score: Output = 0;
    for (left) |l| {
        const count = right_counts.get(l) orelse 0;
        score += (l * count);
    }

    return score;
}

test "day1 example" {
    const input =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;

    try std.testing.expectEqual(11, try part1(input));
    try std.testing.expectEqual(31, try part2(input));
}

test "day1 input" {
    try std.testing.expectEqual(1646452, try part1(day_input));
    try std.testing.expectEqual(23609874, try part2(day_input));
}
