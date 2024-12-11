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

const day_input = @embedFile("data/day10.txt");

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

const Grid = u.StrGrid;

pub fn parse(input: Str) !Grid {
    return Grid.fromInput(input, '\n');
}

const Output = u64;

pub fn part1(input: Grid) !?Output {
    var sum: Output = 0;
    var starts = u.findCharsComptime(input.input, .{ .scalar = '0' });
    while (starts.next()) |start| sum += start_hike(&input, start);
    return sum;
}

fn start_hike(g: *const Grid, start: usize) Output {
    var reached = BitSet.initEmpty(a, g.input.len) catch @panic("oom");
    defer reached.deinit();

    hike(g, start, '1', &reached);
    return reached.count();
}

fn hike(g: *const Grid, start: usize, comptime next_level: u8, reached: *BitSet) void {
    const dirs = g.neighbors(start, .{ .kind = .straight });
    for (dirs.constSlice()) |n| {
        if (g.input[n] == next_level) {
            if (next_level == '9') {
                reached.set(n);
            } else {
                hike(g, n, next_level + 1, reached);
            }
        }
    }
}

pub fn part2(input: Grid) !?Output {
    var sum: Output = 0;
    var starts = u.findCharsComptime(input.input, .{ .scalar = '0' });
    while (starts.next()) |start| sum += start_hike2(&input, start);
    return sum;
}

fn start_hike2(g: *const Grid, start: usize) Output {
    var rank: u32 = 1;
    hike2(g, start, '1', &rank);
    return rank;
}

fn hike2(g: *const Grid, start: usize, comptime next_level: u8, distinct: *u32) void {
    const dirs = g.neighbors(start, .{ .kind = .straight });
    var has_path = false;
    for (dirs.constSlice()) |n| {
        if (g.input[n] == next_level) {
            if (!has_path) {
                has_path = true;
            } else {
                distinct.* += 1;
            }
            if (next_level != '9') {
                hike2(g, n, next_level + 1, distinct);
            }
        }
    }
    if (!has_path) {
        distinct.* -= 1;
    }
}

test "day10 example" {
    const input =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
        \\
    ;

    const in = try parse(input);
    try std.testing.expectEqual(36, try part1(in));
    try std.testing.expectEqual(81, try part2(in));
}

test "day10 input" {
    const in = try parse(day_input);
    try std.testing.expectEqual(624, try part1(in));
    try std.testing.expectEqual(1483, try part2(in));
}
