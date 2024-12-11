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

const day_input = @embedFile("data/day9.txt");

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

const Parsed = []const extern struct { files: u8, free: u8 };

pub fn parse(input: Str) !Parsed {
    const blocks = u.mem.bytesAsSlice(@typeInfo(Parsed).Pointer.child, input);
    u.assert(blocks[blocks.len - 1].free == '\n');
    return blocks;
}

const Output = u64;

inline fn partial_sum(id: Output, pos: Output, count: Output) Output {
    const sum: Output = @divExact(count * (pos + pos + count - 1), 2);
    return sum * id;
}

pub fn part1(blocks: Parsed) !?Output {
    var checksum: Output = 0;

    var start: u16 = 0;
    var end: u16 = @intCast(blocks.len - 1);
    var last_files = blocks[end].files - '0';
    var check_pos: u16 = 0;

    outer: while (start < end) : (start += 1) {
        const left_files = blocks[start].files - '0';
        checksum += partial_sum(start, check_pos, left_files);
        check_pos += left_files;

        var left_free = blocks[start].free - '0';

        while (left_free > 0) {
            while (last_files == 0) {
                end -= 1;
                if (end <= start) break :outer;
                last_files = blocks[end].files - '0';
            }

            const fill = @min(left_free, last_files);
            last_files -= fill;
            left_free -= fill;

            checksum += partial_sum(end, check_pos, fill);
            check_pos += fill;
        }
    }

    if (last_files > 0) {
        checksum += partial_sum(end, check_pos, last_files);
    }

    return checksum;
}

pub fn part2(input: Parsed) !?Output {
    var blocks = a.dupe(@typeInfo(Parsed).Pointer.child, input) catch @panic("oom");

    var start: u16 = 0;
    var end: u16 = @intCast(blocks.len - 1);
    var start_pos: u16 = blocks[start].files - '0';

    var checksum: Output = 0;
    checksum += partial_sum(0, 0, start_pos);

    outer: while (start < end) : (end -= 1) {
        const last_files = blocks[end].files - '0';
        var left_free = blocks[start].free - '0';

        var insert = start;
        var insert_pos = start_pos;

        while (left_free < last_files) {
            insert_pos += input[insert].free - '0';

            insert += 1;
            if (insert >= end) {
                checksum += partial_sum(end, insert_pos, last_files);
                continue :outer;
            }

            insert_pos += blocks[insert].files - '0';
            left_free = blocks[insert].free - '0';
        }

        insert_pos += (input[insert].free - blocks[insert].free);
        checksum += partial_sum(end, insert_pos, last_files);
        blocks[insert].free -= last_files;

        while (blocks[start].free == '0') {
            start_pos += input[start].free - '0';
            start += 1;
            if (start >= end) break :outer;

            checksum += partial_sum(start, start_pos, blocks[start].files - '0');
            start_pos += blocks[start].files - '0';
        }
    }

    return checksum;
}

test "day9 example" {
    const input =
        \\2333133121414131402
        \\
    ;

    const in = try parse(input);
    try std.testing.expectEqual(1928, try part1(in));
    try std.testing.expectEqual(2858, try part2(in));
}

test "day9 input" {
    const in = try parse(day_input);
    try std.testing.expectEqual(6279058075753, try part1(in));
    try std.testing.expectEqual(6301361958738, try part2(in));
}
