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

const day_input = @embedFile("data/day5.txt");

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

const max_node = 100;
const Node = u.math.IntFittingRange(0, max_node);
const Nodes = std.bit_set.StaticBitSet(max_node);
const Adj = std.bit_set.StaticBitSet(max_node);
const Graph = struct {
    nodes: Nodes,
    outs: [max_node]Adj,
    incs: [max_node]Adj,

    fn empty() Graph {
        return .{
            .nodes = Nodes.initEmpty(),
            .outs = .{Adj.initEmpty()} ** max_node,
            .incs = .{Adj.initEmpty()} ** max_node,
        };
    }

    fn add(self: *Graph, from: Node, to: Node) void {
        self.nodes.set(from);
        self.nodes.set(to);
        self.outs[from].set(to);
        self.incs[to].set(from);
    }

    fn valid(self: *const Graph, nodes: []const Node) bool {
        var adj: *const Adj = undefined;
        for (nodes, 0..) |node, i| {
            if (!self.nodes.isSet(node)) return false;
            if (i != 0 and !adj.isSet(node)) return false;
            adj = &self.outs[node];
        }
        return true;
    }

    fn validOrder(self: *const Graph, nodes: []const Node) []const Node {
        var filtered = self.filter(nodes);
        return filtered.intoOrder();
    }

    fn filter(self: *const Graph, filter_nodes: []const Node) Graph {
        var new = empty();
        for (filter_nodes) |n| new.nodes.set(n);
        new.nodes.setIntersection(self.nodes);

        var iter = new.nodes.iterator(.{});
        while (iter.next()) |node| {
            new.incs[node] = self.incs[node].intersectWith(new.nodes);
            new.outs[node] = self.outs[node].intersectWith(new.nodes);
        }

        return new;
    }

    fn intoOrder(self: *Graph) []const Node {
        var order = a.alloc(Node, self.nodes.count()) catch @panic("oom");

        var idx: usize = 0;
        outer: while (true) {
            var iter = self.nodes.iterator(.{});
            while (iter.next()) |node| {
                if (self.incs[node].count() == 0) {
                    order[idx] = @intCast(node);
                    idx += 1;
                    self.nodes.unset(node);

                    var out = self.outs[node].iterator(.{});
                    while (out.next()) |o| {
                        self.incs[o].unset(node);
                    }
                    continue :outer;
                }
            } else return order;
        }
    }
};

const Parsed = struct {
    updates: []const []const Node,
    graph: Graph,
};

pub fn parse(input: Str) !Parsed {
    var chunks = u.chunks(input);

    const rules = try u.linesOfSep([2]Node, chunks.next().?, .{ .scalar = '|' });
    const updates = try u.linesOfSep([]const Node, chunks.next().?, .{ .scalar = ',' });

    var graph = Graph.empty();
    for (rules) |rule| graph.add(rule[0], rule[1]);

    return .{ .updates = updates, .graph = graph };
}

const Output = i64;

pub fn part1(input: Parsed) !?Output {
    var sum: Output = 0;
    for (input.updates) |in| if (input.graph.valid(in)) {
        sum += in[in.len / 2];
    };
    return sum;
}

pub fn part2(input: Parsed) !?Output {
    var sum: Output = 0;
    for (input.updates) |in| if (!input.graph.valid(in)) {
        const order = input.graph.validOrder(in);
        sum += order[order.len / 2];
    };
    return sum;
}

test "day5 example" {
    const input =
        \\47|53
        \\97|13
        \\97|61
        \\97|47
        \\75|29
        \\61|13
        \\75|53
        \\29|13
        \\97|29
        \\53|29
        \\61|53
        \\97|53
        \\61|29
        \\47|13
        \\75|47
        \\97|75
        \\47|61
        \\75|61
        \\47|29
        \\75|13
        \\53|13
        \\
        \\75,47,61,53,29
        \\97,61,53,29,13
        \\75,29,13
        \\75,97,47,61,53
        \\61,13,29
        \\97,13,75,29,47
    ;

    const in = try parse(input);
    try std.testing.expectEqual(143, try part1(in));
    try std.testing.expectEqual(123, try part2(in));
}

test "day5 input" {
    const in = try parse(day_input);
    try std.testing.expectEqual(7024, try part1(in));
    try std.testing.expectEqual(4151, try part2(in));
}
