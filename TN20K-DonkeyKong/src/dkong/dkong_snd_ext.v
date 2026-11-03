//============================================================================
// Donkey Kong sound for dkong_main SND_EXT = 1, as the Donkey Kong Jr. Basys 3 port:
// - walk, jump and stomp samples on three channels of the multi-channel sample player
//   (dkong_wav_gaz68)
// - 8035 DAC data with the DAC-08 decay (dkongjr_dac, enabled by 8035 P2.7 low) and a
//   2nd order low-pass filter (iir_2nd_order, 1916 Hz, Q 0.74, 48 kHz)
// - 19-bit mix, 16-bit limiter, 8-bit unsigned output for the 1-bit DAC
// I_OPT: [0] reserved, [1] filter off, [2] decay off (switch up = off).
//============================================================================

module dkong_snd_ext (
    input I_CLK, // 24.576 MHz
    input I_RSTn,
    input [2:0] I_TRIG, // 6H[2:0]: stomp, jump, walk
    input [7:0] I_DIG, // 8035 DAC data (P1)
    input I_P2_7, // 8035 P2.7, low enables the decay
    input [2:0] I_OPT,
    output [7:0] O_DAC
);

    // samples: sum of the three channels, 8-bit source data, bits 17:8
    wire [9:0] smp;
    dkong_wav_gaz68 samples (
        .I_CLK(I_CLK),
        .I_RSTn(I_RSTn),
        .I_TRIG(I_TRIG),
        .O_SAMPLE(smp)
    );
    wire signed [18:0] smp_mix = {{1{smp[9]}}, smp, 8'h00};

    // digital sound: decay, low-pass filter
    wire signed [15:0] dig = {~I_DIG[7], I_DIG[6:0], 8'h00};
    wire signed [15:0] dig_decay;
    dkongjr_dac dac08 (
        .I_CLK(I_CLK),
        .I_DECAY_EN(~I_P2_7),
        .I_RESET_n(I_RSTn),
        .I_SND_DAT(dig),
        .O_SND_DAT(dig_decay)
    );
    wire signed [15:0] dig_d = I_OPT[2] ? dig : dig_decay;

    wire signed [15:0] dig_f;
    iir_2nd_order filter (
        .clk(I_CLK),
        .reset(~I_RSTn),
        .div(10'd512), // 24.576 MHz / 512 = 48 kHz
        .A2(-18'sd26649),
        .A3(18'sd11453),
        .B1(18'sd215),
        .B2(18'sd430),
        .B3(18'sd215),
        .in(dig_d),
        .out(dig_f)
    );
    wire signed [15:0] dig_out = I_OPT[1] ? dig_d : dig_f;

    // mixer: samples + digital sound, 16-bit limiter, 8-bit unsigned out
    wire signed [18:0] sound_mix = smp_mix + {{3{dig_out[15]}}, dig_out};
    reg signed [15:0] dac_di = 16'sd0;
    always @(posedge I_CLK) begin
        if (sound_mix >= 19'sh07FFF)
            dac_di <= 16'sh7FFF;
        else if (sound_mix <= -19'sh08000)
            dac_di <= -16'sh8000;
        else
            dac_di <= sound_mix[15:0];
    end

    assign O_DAC = {~dac_di[15], dac_di[14:8]};

endmodule
