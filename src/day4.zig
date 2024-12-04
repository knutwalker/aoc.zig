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

const day_input = @embedFile("data/day4.txt");

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

const Parsed = u.StrGrid;

pub fn parse(input: Str) !Parsed {
    const row_len = (u.indexOf(u8, input, '\n') orelse unreachable) + 1;
    return .{ .input = input, .row_len = @intCast(row_len) };
}

const Output = u32;

pub fn part1(input: Parsed) !?Output {
    var count: Output = 0;
    var xs = u.findChars(input.input, 'X');
    const target = "MAS";
    while (xs.next()) |x| {
        var lines = input.lines(x, .{});
        for (&lines) |*line| {
            if (line.match(target)) {
                count += 1;
            }
        }
    }

    return count;
}

pub fn part2(input: Parsed) !?Output {
    var count: Output = 0;
    var ms = u.findChars(input.input, 'M');
    const target = "AS";
    while (ms.next()) |m| {
        var lines = input.lines(m, .{ .kind = .diagonal, .axis = .x });
        for (&lines) |*line| {
            if (line.match(target)) {
                var cross_lines = crossLines(&input, m, line.config.dir);
                for (&cross_lines) |*cross| {
                    if (input.input[cross.pos] == 'M' and cross.match(target)) {
                        count += 1;
                        break;
                    }
                }
            }
        }
    }

    return count;
}

fn crossLines(grid: *const Parsed, m: usize, dir: u.Dir) [2]Parsed.Chars {
    const row_len = @as(usize, @intCast(grid.row_len));
    return switch (dir) {
        .forward => .{
            grid.chars(m + (2 * row_len), .diagonal, .y, .forward),
            grid.chars(m + 2, .diagonal, .y, .backward),
        },
        .backward => .{
            grid.chars(m - 2, .diagonal, .y, .forward),
            grid.chars(m - (2 * row_len), .diagonal, .y, .backward),
        },
    };
}

test "day4 example" {
    const input =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;

    const in = try parse(input);
    try std.testing.expectEqual(18, try part1(in));
    try std.testing.expectEqual(9, try part2(in));
}

test "day4 input" {
    const in = try parse(day_input);
    try std.testing.expectEqual(2500, try part1(in));
    try std.testing.expectEqual(1933, try part2(in));
}
