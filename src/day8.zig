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

const day_input = @embedFile("data/day8.txt");

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

const Parsed = u.StrGrid;

pub fn parse(input: Str) !Parsed {
    return u.StrGrid.fromInput(input, '\n');
}

const Output = u64;

pub fn part1(input: Parsed) !?Output {
    return solve(input, true);
}

pub fn part2(input: Parsed) !?Output {
    return solve(input, false);
}

fn solve(input: Parsed, comptime p1: bool) !?Output {
    var nodes = try BitSet.initEmpty(a, input.input.len);

    var antennas = u.findCharsComptime(input.input, .{ .none = ".\n" });
    while (antennas.next()) |pos| {
        const antenna = input.input[pos];
        if (comptime !p1) nodes.set(pos);

        var siblings = u.findChars(input.input[pos + 1 ..], .{ .scalar = antenna });
        while (siblings.next()) |ns| {
            const sibling = ns + pos + 1;
            if (comptime !p1) nodes.set(sibling);

            inline for (.{ .{ &input, pos, sibling }, .{ &input, sibling, pos } }) |args| {
                var spots = @call(.auto, u.StrGrid.spots, args);
                while (spots.next()) |_| {
                    nodes.set(spots.pos);
                    if (comptime p1) break;
                }
            }
        }
    }

    return nodes.count();
}

test "day8 example" {
    const input =
        \\............
        \\........0...
        \\.....0......
        \\.......0....
        \\....0.......
        \\......A.....
        \\............
        \\............
        \\........A...
        \\.........A..
        \\............
        \\............
    ;

    const in = try parse(input);
    try std.testing.expectEqual(14, try part1(in));
    try std.testing.expectEqual(34, try part2(in));
}

test "day8 input" {
    const in = try parse(day_input);
    try std.testing.expectEqual(305, try part1(in));
    try std.testing.expectEqual(1150, try part2(in));
}
