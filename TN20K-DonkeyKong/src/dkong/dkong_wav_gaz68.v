//============================================================================
// Walk, jump and stomp samples with the multi-channel sample player dkongjr_wav_dma
// (up to 8 channels, 3 used here; as the Donkey Kong Jr. Basys 3 port, 4 used there).
//
// Three independent channels, triggered on the 1 to 0 edge of the 6H latch bits
// (I_TRIG: 2 stomp, 1 jump, 0 walk), as in the DKJr port. Walk rotates
// over run01-03 in the MAME order {1,2,1,2,0,1,0}. The player's edge detector starts
// all three channels after each reset (as in the DKJr port).
//
// ROM dkong_wav (tools/dk_wave.bin, re-authored by make roms from the MAME sample set):
// 0x0000 run01, 0x0800 run02, 0x1000 run03, 0x1800 dkstomp, 0x3000 jump. The channels
// share the ROM: address at phase 0/2/4, data at 1/3/5 of a 4-bit phase counter stepped
// every 4 clocks.
// O_SAMPLE: sum of the three 16-bit channels, bits 17:8.
//============================================================================

module dkong_wav_gaz68 (
    input I_CLK,
    input I_RSTn,
    input [2:0] I_TRIG,
    output signed [9:0] O_SAMPLE
);

    // triggers from the core latch: 2-FF synchronizer
    (* ASYNC_REG = "TRUE" *) reg [2:0] trig_meta = 3'b000;
    (* ASYNC_REG = "TRUE" *) reg [2:0] trig_s = 3'b000;
    always @(posedge I_CLK) begin
        trig_meta <= I_TRIG;
        trig_s <= trig_meta;
    end

    // phase counter for the ROM time sharing
    reg [1:0] presc = 2'd0;
    reg [3:0] phase = 4'd0;
    always @(posedge I_CLK) begin
        presc <= presc + 1'd1;
        if (presc == 2'd3)
            phase <= phase + 1'd1;
    end

    // walk rotation, stepped on each walk trigger (as the DKJr port)
    reg [2:0] multsample_cnt;
    reg [1:0] multsample;
    reg walk_trig_d;
    always @(posedge I_CLK or negedge I_RSTn) begin
        if (!I_RSTn) begin
            multsample_cnt <= 0;
            multsample <= 0;
            walk_trig_d <= 0;
        end else begin
            walk_trig_d <= ~trig_s[0];
            if (~walk_trig_d & ~trig_s[0]) begin
                multsample_cnt <= multsample_cnt == 6 ? 3'd0 : multsample_cnt + 1'd1;
                case (multsample_cnt)
                    0: multsample <= 2'd1;
                    1: multsample <= 2'd2;
                    2: multsample <= 2'd1;
                    3: multsample <= 2'd2;
                    4: multsample <= 2'd0;
                    5: multsample <= 2'd1;
                    6: multsample <= 2'd0;
                    default: multsample <= 2'd0;
                endcase
            end
        end
    end

    wire [7:0] rom_data;
    reg [15:0] rom_addr = 16'd0;
    wire signed [15:0] wav_d = {~rom_data[7], rom_data[6:0], 8'h00};
    wire [15:0] ch_addr [0:2];
    wire signed [15:0] ch_snd [0:2];

    dkong_wav rom (
        .clk(I_CLK),
        .addr(rom_addr[14:0]),
        .data(rom_data)
    );

    always @(posedge I_CLK) begin
        case (phase)
            0: rom_addr <= ch_addr[0];
            2: rom_addr <= ch_addr[1];
            4: rom_addr <= ch_addr[2];
            default: ;
        endcase
    end

    // Walk
    dkongjr_wav_dma walk_sound (
        .I_CLK(I_CLK),
        .I_RSTn(I_RSTn),
        .I_H_CNT(phase),
        .I_DIV(12'd2229), // 24.576 MHz / 2229 = 11,025 Hz
        .I_VOL(4'd3), // unused with VOL_EN = 0
        .I_DMA_TRIG(~trig_s[0]),
        .I_DMA_STOP(1'b0),
        .I_DMA_CHAN(3'd0),
        .I_DMA_ADDR({3'b000, multsample, 11'h000}),
        .I_DMA_LEN(16'h07FF),
        .I_DMA_DATA(wav_d),
        .O_DMA_ADDR(ch_addr[0]),
        .O_SND(ch_snd[0])
    );

    // Jump
    dkongjr_wav_dma jump_sound (
        .I_CLK(I_CLK),
        .I_RSTn(I_RSTn),
        .I_H_CNT(phase),
        .I_DIV(12'd2229),
        .I_VOL(4'd3),
        .I_DMA_TRIG(~trig_s[1]),
        .I_DMA_STOP(1'b0),
        .I_DMA_CHAN(3'd1),
        .I_DMA_ADDR(16'h3000),
        .I_DMA_LEN(16'h1FFF),
        .I_DMA_DATA(wav_d),
        .O_DMA_ADDR(ch_addr[1]),
        .O_SND(ch_snd[1])
    );

    // Stomp
    dkongjr_wav_dma stomp_sound (
        .I_CLK(I_CLK),
        .I_RSTn(I_RSTn),
        .I_H_CNT(phase),
        .I_DIV(12'd2229),
        .I_VOL(4'd3),
        .I_DMA_TRIG(~trig_s[2]),
        .I_DMA_STOP(1'b0),
        .I_DMA_CHAN(3'd2),
        .I_DMA_ADDR(16'h1800),
        .I_DMA_LEN(16'h17FF),
        .I_DMA_DATA(wav_d),
        .O_DMA_ADDR(ch_addr[2]),
        .O_SND(ch_snd[2])
    );

    wire signed [17:0] sum = ch_snd[0] + ch_snd[1] + ch_snd[2];
    assign O_SAMPLE = sum[17:8];

endmodule
