const std = @import("std");

pub const disable_sub_measure = true;
const opts = @import("opts");

pub fn main() !void {
    var measure = @import("util.zig").BoundedMeasure(25).forceStart();
    defer measure.dump();

    if (comptime opts.has_input[1]) {
        try @import("./day1.zig").main();
        measure.lap("day 01");
    }

    if (comptime opts.has_input[2]) {
        try @import("./day2.zig").main();
        measure.lap("day 02");
    }

    if (comptime opts.has_input[3]) {
        try @import("./day3.zig").main();
        measure.lap("day 03");
    }

    if (comptime opts.has_input[4]) {
        try @import("./day4.zig").main();
        measure.lap("day 04");
    }

    if (comptime opts.has_input[5]) {
        try @import("./day5.zig").main();
        measure.lap("day 05");
    }

    if (comptime opts.has_input[6]) {
        try @import("./day6.zig").main();
        measure.lap("day 06");
    }

    if (comptime opts.has_input[7]) {
        try @import("./day7.zig").main();
        measure.lap("day 07");
    }

    if (comptime opts.has_input[8]) {
        try @import("./day8.zig").main();
        measure.lap("day 08");
    }

    if (comptime opts.has_input[9]) {
        try @import("./day9.zig").main();
        measure.lap("day 09");
    }

    if (comptime opts.has_input[10]) {
        try @import("./day10.zig").main();
        measure.lap("day 10");
    }

    if (comptime opts.has_input[11]) {
        try @import("./day11.zig").main();
        measure.lap("day 11");
    }

    if (comptime opts.has_input[12]) {
        try @import("./day12.zig").main();
        measure.lap("day 12");
    }

    if (comptime opts.has_input[13]) {
        try @import("./day13.zig").main();
        measure.lap("day 13");
    }

    if (comptime opts.has_input[14]) {
        try @import("./day14.zig").main();
        measure.lap("day 14");
    }

    if (comptime opts.has_input[15]) {
        try @import("./day15.zig").main();
        measure.lap("day 15");
    }

    if (comptime opts.has_input[16]) {
        try @import("./day16.zig").main();
        measure.lap("day 16");
    }

    if (comptime opts.has_input[17]) {
        try @import("./day17.zig").main();
        measure.lap("day 17");
    }

    if (comptime opts.has_input[18]) {
        try @import("./day18.zig").main();
        measure.lap("day 18");
    }

    if (comptime opts.has_input[19]) {
        try @import("./day19.zig").main();
        measure.lap("day 19");
    }

    if (comptime opts.has_input[20]) {
        try @import("./day20.zig").main();
        measure.lap("day 20");
    }

    if (comptime opts.has_input[21]) {
        try @import("./day21.zig").main();
        measure.lap("day 21");
    }

    if (comptime opts.has_input[22]) {
        try @import("./day22.zig").main();
        measure.lap("day 22");
    }

    if (comptime opts.has_input[23]) {
        try @import("./day23.zig").main();
        measure.lap("day 23");
    }

    if (comptime opts.has_input[24]) {
        try @import("./day24.zig").main();
        measure.lap("day 24");
    }

    if (comptime opts.has_input[25]) {
        try @import("./day25.zig").main();
        measure.lap("day 25");
    }
}
