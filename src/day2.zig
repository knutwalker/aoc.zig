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

const day_input = @embedFile("data/day2.txt");

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

const Parsed = []const []i32;

pub fn parse(input: Str) !Parsed {
    return try u.linesOf([]i32, input);
}

const Output = i64;

pub fn part1(input: Parsed) !?Output {
    return solve(input, 0);
}

pub fn part2(input: Parsed) !?Output {
    return solve(input, u.math.maxInt(usize));
}

fn solve(reports: Parsed, max_tries: usize) !?Output {
    var safe: Output = 0;
    for (reports) |r| {
        const tries = @min(r.len, max_tries) + 1;
        const is_safe = safe: for (0..tries) |bad| {
            if (bad >= 2) {
                if (bad >= 3) std.mem.rotate(i32, r[0 .. bad - 1], 1);
                std.mem.rotate(i32, r[0..bad], bad - 1);
            }

            var windows = u.mem.window(i32, r[@min(1, bad)..], 2, 1);
            var dir: i32 = 0;
            var idx: usize = 0;
            while (windows.next()) |w| : (idx += 1) {
                const this_diff = w[1] - w[0];
                const this_dir = u.math.sign(this_diff);

                if ((dir != 0 and this_dir != dir) or // direction differs
                    this_dir == 0 or // no increase or decrease at the beginning
                    (@abs(this_diff) -% 1) > 2 // diff too large
                ) {
                    break;
                }

                dir = this_dir;
            } else break :safe true;
        } else break :safe false;

        safe += @intFromBool(is_safe);
    }
    return safe;
}

test "day2 example" {
    const input =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
        \\8 9 7 6 5
    ;

    const in = try parse(input);
    try std.testing.expectEqual(2, try part1(in));
    try std.testing.expectEqual(5, try part2(in));
}

test "day2 input" {
    const in = try parse(day_input);
    try std.testing.expectEqual(390, try part1(in));
    try std.testing.expectEqual(439, try part2(in));
}
