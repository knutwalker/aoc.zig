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

const day_input = @embedFile("data/day6.txt");

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

const Parsed = struct { g: u.StrGrid, start: Pos };

pub fn parse(input: Str) !Parsed {
    const grid = u.StrGrid.fromInput(input, '\n');
    const start = u.indexOf(u8, input, '^') orelse unreachable;

    return .{ .g = grid, .start = Pos.at(start, 0) };
}

const directions = [_]u.Dir2d{
    .{ .y, .backward },
    .{ .x, .forward },
    .{ .y, .forward },
    .{ .x, .backward },
};

const Visited = struct {
    seen: []u4,

    fn init(ally: u.Alloc, len: usize) Visited {
        const seen = ally.alloc(u4, len) catch @panic("oom");
        @memset(seen, 0);
        return .{ .seen = seen };
    }

    fn deinit(self: Visited, ally: u.Alloc) void {
        ally.free(self.seen);
    }

    fn clone(self: Visited, ally: u.Alloc) Visited {
        const seen = ally.dupe(u4, self.seen) catch @panic("oom");
        return .{ .seen = seen };
    }

    fn alreadyVisited(self: Visited, pos: u16) bool {
        return self.seen[pos] != 0;
    }

    fn visitNew(self: Visited, pos: Pos) enum { already_seen, newly_visited } {
        const bit = @as(u4, 1) << pos.dir;

        if (self.seen[pos.pos] & bit == 0) {
            self.seen[pos.pos] |= bit;
            return .newly_visited;
        }
        return .already_seen;
    }
};

const Pos = struct {
    pos: u16,
    dir: u2,

    fn at(pos: anytype, dir: u2) Pos {
        return .{ .pos = @intCast(pos), .dir = dir };
    }
};

fn walkFree(
    grid: *const u.StrGrid,
    start: Pos,
    ctx: anytype,
    handle: *const fn (@TypeOf(ctx), *const u.StrGrid, Pos) bool,
) bool {
    return walk(grid, u.maxInt(u32), start, ctx, handle);
}

fn walk(
    grid: *const u.StrGrid,
    block: u32,
    start: Pos,
    ctx: anytype,
    handle: *const fn (@TypeOf(ctx), *const u.StrGrid, Pos) bool,
) bool {
    if (grid.input[start.pos] == '#' or start.pos == block) {
        std.debug.print("pos={} block={} grid={}\n", .{ start.pos, block, grid.input[start.pos] });
        @panic("starting at a block, aren't you");
    }

    var line = grid.line2d(start.pos, .straight, directions[start.dir]);
    var pos = start;

    while (true) {
        if (handle(ctx, grid, pos) == false) return false;

        const nxt = line.next() orelse return true;

        if (nxt == '#' or line.pos == block) {
            pos.dir +%= 1;
            line = grid.line2d(pos.pos, .straight, directions[pos.dir]);
            continue;
        }

        pos.pos = @intCast(line.pos);
    }
}

const Output = u64;

pub fn part1(parsed: Parsed) !?Output {
    const grid = parsed.g;
    var visited = try BitSet.initEmpty(a, grid.input.len);

    _ = walkFree(&grid, parsed.start, &visited, struct {
        fn handle(v: *BitSet, _: *const u.StrGrid, p: Pos) bool {
            v.set(p.pos);
            return true;
        }
    }.handle);

    return visited.count();
}

pub fn part2(parsed: Parsed) !?Output {
    const grid = parsed.g;
    const start = parsed.start;

    var visited = Visited.init(a, grid.input.len);
    defer visited.deinit(a);

    const Ctx = struct { vis: Visited, res: Output, old: Pos };
    var ctx = Ctx{ .vis = visited, .res = 0, .old = start };

    _ = walkFree(&grid, start, &ctx, struct {
        fn handle(c: *Ctx, g: *const u.StrGrid, pos: Pos) bool {
            if (pos.pos == c.old.pos or c.vis.alreadyVisited(pos.pos)) {
                return true;
            }

            if (checkPath(g, c.old, pos.pos, &c.vis)) {
                c.res += 1;
            }

            _ = c.vis.visitNew(c.old);
            c.old = pos;

            return true;
        }
    }.handle);

    return ctx.res;
}

fn checkPath(grid: *const u.StrGrid, pos: Pos, block: u32, visited_until_here: *const Visited) bool {
    var visited = visited_until_here.clone(a);
    defer visited.deinit(a);

    const acyclic = walk(grid, block, pos, &visited, struct {
        fn handle(vis: *Visited, _: *const u.StrGrid, p: Pos) bool {
            return vis.visitNew(p) == .newly_visited;
        }
    }.handle);

    return !acyclic;
}

test "day6 example" {
    const input =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;

    const in = try parse(input);
    try std.testing.expectEqual(41, try part1(in));
    try std.testing.expectEqual(6, try part2(in));
}

test "day6 input" {
    const in = try parse(day_input);
    try std.testing.expectEqual(5095, try part1(in));
    try std.testing.expectEqual(1933, try part2(in));
}
