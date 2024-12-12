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

const day_input = @embedFile("data/day11.txt");

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

const Parsed = []u57;

pub fn parse(input: Str) !Parsed {
    return try u.tryParse(Parsed, u.mem.trimRight(u8, input, "\n"));
}

const Output = u64;

var cache = Cache.init(a);

pub fn part1(input: Parsed) !?Output {
    return solveAll(input, 25);
}

pub fn part2(input: Parsed) !?Output {
    return solveAll(input, 75);
}

fn solveAll(stones: Parsed, iters: u7) Output {
    cache.ensureTotalCapacity(256 << 10) catch @panic("oom");
    var out: Output = 0;
    for (stones) |stone| out += solveCached(.{ .stone = stone, .iter = iters });
    return out;
}

const Key = packed struct(u64) {
    stone: u57,
    iter: u7,

    inline fn next(self: Key, stone: u57) Key {
        return .{ .stone = stone, .iter = self.iter - 1 };
    }
};
const Cache = Map(Key, Output);

fn solveCached(key: Key) Output {
    // can't use gop because fetching the value might
    // add new items and invalidate the gop pointer
    const cached = cache.get(key);
    if (cached) |v| return v;

    const value = solveNew(key);
    cache.putAssumeCapacityNoClobber(key, value);

    return value;
}

fn solveNew(key: Key) Output {
    if (key.iter == 0) return 1;
    if (key.stone == 0) return solveCached(key.next(1));

    const log = u.math.log10_int(key.stone);
    if (log % 2 == 1) {
        const split = u.math.powi(u57, 10, (log + 1) / 2) catch unreachable;
        const left = key.stone / split;
        const right = key.stone % split;

        const lv = solveCached(key.next(left));
        const rv = solveCached(key.next(right));
        return lv + rv;
    } else {
        return solveCached(key.next(key.stone * 2024));
    }
}

test "day11 example" {
    const input =
        \\125 17
        \\
    ;

    const in = try parse(input);
    try std.testing.expectEqual(55312, try part1(in));
    try std.testing.expectEqual(65601038650482, try part2(in));
}

test "day11 input" {
    const in = try parse(day_input);
    try std.testing.expectEqual(204022, try part1(in));
    try std.testing.expectEqual(241651071960597, try part2(in));
}
