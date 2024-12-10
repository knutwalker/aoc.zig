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

const day_input = @embedFile("data/day3.txt");

pub fn main() !void {
    var results = std.BoundedArray(Output, 2){};

    var measure = u.Measure.start();
    defer measure.dump();

    const ops = try parse(day_input);
    measure.lapWithSize("parse", day_input.len);

    if (try part1(ops)) |p1| {
        results.append(p1) catch unreachable;
        measure.lap("part 1");
    }

    if (try part2(ops)) |p2| {
        results.append(p2) catch unreachable;
        measure.lap("part 2");
    }

    for (results.constSlice()) |res| {
        std.io.getStdOut().writer().print("{}\n", .{res}) catch {};
    }
}
// }}}

fn parse(input: Str) ![]const Op {
    return try u.tryParseSep([]const Op, input, .{ .scalar = 0 });
}

const Op = union(enum) {
    do,
    dont,
    mul: struct { u32, u32 },

    pub fn parse(tokens: anytype) !Op {
        while (true) {
            const op_name, const text = u.advanceWith(tokens, u.splitAtNext, "(") orelse {
                tokens.index = tokens.buffer.len;
                return error.NoMoreItems;
            };

            if (u.mem.endsWith(u8, op_name, "don't")) {
                if (text.len == 0 or text[0] != ')') continue;
                return .dont;
            } else if (u.mem.endsWith(u8, op_name, "do")) {
                if (text.len == 0 or text[0] != ')') continue;
                return .do;
            } else if (u.mem.endsWith(u8, op_name, "mul")) {
                const lt, const middle = u.splitAtNext(",", text) orelse continue;
                // if (lt.len < 1 or lt.len > 3) continue;
                const left = u.parseInt(u32, lt) catch continue;

                const rt, _ = u.splitAtNext(")", middle) orelse continue;
                // if (rt.len < 1 or rt.len > 3) continue;
                const right = u.parseInt(u32, rt) catch continue;

                return .{ .mul = .{ left, right } };
            }
        }
    }
};

const Output = i64;

pub fn part1(ops: []const Op) !?Output {
    var sum: Output = 0;
    for (ops) |op| {
        switch (op) {
            .mul => |m| sum += (m[0] * m[1]),
            else => {},
        }
    }
    return sum;
}

pub fn part2(ops: []const Op) !?Output {
    var sum: Output = 0;
    var do: bool = true;
    for (ops) |op| {
        switch (op) {
            .mul => |m| sum += (@intFromBool(do) * m[0] * m[1]),
            else => do = op == .do,
        }
    }
    return sum;
}

test "day3 example" {
    const input =
        \\xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))
    ;

    const ops = try parse(input);
    try std.testing.expectEqual(161, try part1(ops));
    try std.testing.expectEqual(48, try part2(ops));
}

test "day3 input" {
    // uncomment to test with actual input when ready

    const ops = try parse(day_input);
    try std.testing.expectEqual(189527826, try part1(ops));
    try std.testing.expectEqual(63013756, try part2(ops));
}
