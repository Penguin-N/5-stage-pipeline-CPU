module testCPU;

reg Clock;

ClockGeneration u_ClockGeneration(
    .Clock (Clock )
);

CPU u_CPU(Clock);

initial begin
Clock = 0;
end

always #1 Clock = ~Clock;

endmodule