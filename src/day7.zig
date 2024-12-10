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

const day_input = @embedFile("data/day7.txt");

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

const Eq = struct { res: u64, ops: []const u16 };
const Parsed = []Eq;

pub fn parse(input: Str) !Parsed {
    return try u.linesOfSep(Eq, input, .{ .any = ": " });
}

const Output = u64;

pub fn part1(input: Parsed) !?Output {
    var count: Output = 0;
    for (input) |line| {
        if (solve(line.res, line.ops, .{ .add, .mul })) {
            count += line.res;
        }
    }
    return count;
}

pub fn part2(input: Parsed) !?Output {
    var count: Output = 0;
    for (input) |line| {
        if (solve(line.res, line.ops, .{ .add, .mul, .merge })) {
            count += line.res;
        }
    }
    return count;
}

const Op = enum { add, mul, merge };

fn solve(res: u64, nums: []const u16, comptime ops: anytype) bool {
    if (nums.len == 0) return false;
    if (nums.len == 1) return nums[0] == res;

    const prefix, const rhs = u.splitLast(u16, nums);
    inline for (ops) |op| {
        switch (comptime @as(Op, op)) {
            .add => {
                if (u.math.sub(u64, res, rhs)) |rem| {
                    if (solve(rem, prefix, ops)) return true;
                } else |_| {}
            },
            .mul => {
                if (u.math.divExact(u64, res, rhs)) |rem| {
                    if (solve(rem, prefix, ops)) return true;
                } else |_| {}
            },
            .merge => {
                if (u.math.sub(u64, res, rhs)) |factored| {
                    const exp = u.math.log10_int(rhs) + 1;
                    const factor = u.math.powi(u64, 10, exp) catch unreachable;
                    if (u.math.divExact(u64, factored, factor)) |rem| {
                        if (solve(rem, prefix, ops)) return true;
                    } else |_| {}
                } else |_| {}
            },
        }
    }

    return false;
}

test "day7 example" {
    const input =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
    ;

    const in = try parse(input);
    try std.testing.expectEqual(3749, try part1(in));
    try std.testing.expectEqual(11387, try part2(in));
}

test "day7 input" {
    const in = try parse(day_input);
    try std.testing.expectEqual(1708857123053, try part1(in));
    try std.testing.expectEqual(189207836795655, try part2(in));
}
