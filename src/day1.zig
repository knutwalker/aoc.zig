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

    const parsed = try parse(day_input);
    measure.lapWithSize("parse", day_input.len);

    if (try part1(parsed)) |p1| {
        results.append(p1) catch unreachable;
        measure.lap("part 1");
    }

    if (try part2(parsed)) |p2| {
        results.append(p2) catch unreachable;
        measure.lap("part 2");
    }

    for (results.constSlice()) |res| {
        std.io.getStdOut().writer().print("{}\n", .{res}) catch {};
    }
}

const Parsed = struct { []u32, []u32 };

pub fn parse(input: Str) !Parsed {
    return try u.columnsOf(struct { u32, u32 }, input);
}

const Output = i64;

pub fn part1(input: Parsed) !?Output {
    const left, const right = input;

    u.mem.sortUnstable(u32, left, {}, u.asc(u32));
    u.mem.sortUnstable(u32, right, {}, u.asc(u32));

    var sum: Output = 0;
    for (left, right) |l, r| {
        sum += u.absDiff(l, r);
    }

    return sum;
}

pub fn part2(input: Parsed) !?Output {
    const left, const right = input;

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

    const in = try parse(input);
    try std.testing.expectEqual(11, try part1(in));
    try std.testing.expectEqual(31, try part2(in));
}

test "day1 input" {
    const in = try parse(day_input);
    try std.testing.expectEqual(1646452, try part1(in));
    try std.testing.expectEqual(23609874, try part2(in));
}
