module mist_adapter
(
        input AUDIO_CLK,
        input AUDIO_RES,

        input [13:0] AUDIO_OPLL,
        input  [9:0] AUDIO_PSG,
        input [15:0] AUDIO_PCM,
        input  [7:0] AUDIO_TRPCM,

        output [15:0] AUDIO_L,
        output [15:0] AUDIO_R,
        output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
        output  [1:0] AUDIO_MIX,  // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

        output I2S_CE,
        output [15:0] AUDIO_L_FLT,
        output [15:0] AUDIO_R_FLT    
);

wire [16:0] pcm   = {AUDIO_PCM[15], AUDIO_PCM} + {AUDIO_TRPCM[7], AUDIO_TRPCM, 8'd0};
wire [15:0] fm    = {AUDIO_OPLL, 2'b00} + {1'b0, AUDIO_PSG, 5'b00000};
wire [16:0] audio = {pcm[16], pcm[16:1]} + {fm[15], fm};
wire audio_s = 1;

wire [15:0] compr[7:0];
assign compr[0] = {1'b1, audio[13:0], 1'b0};
assign compr[1] = {16'h8000};
assign compr[2] = {16'h8000};
assign compr[3] = {16'h8000};
assign compr[4] = {16'h7FFF};
assign compr[5] = {16'h7FFF};
assign compr[6] = {16'h7FFF};
assign compr[7] = {1'b0, audio[13:0], 1'b0};

assign AUDIO_L = compr[audio[16:14]];
assign AUDIO_R = AUDIO_L;

reg  [4:0] vol_att;
initial vol_att = 5'b11111;
wire  [1:0] audio_mix = 2'b00;
wire       audio_96k  = 1'b0;

assign AUDIO_S = audio_s;
assign AUDIO_MIX = audio_mix;

reg [31:0] aflt_rate = 7056000;
reg [39:0] acx  = 4258969;
reg  [7:0] acx0 = 3;
reg  [7:0] acx1 = 3;
reg  [7:0] acx2 = 1;
reg [23:0] acy0 = -24'd6216759;
reg [23:0] acy1 =  24'd6143386;
reg [23:0] acy2 = -24'd2023767;
wire [15:0] alsa_l = 16'h0000;
wire [15:0] alsa_r = 16'h0000;

audio_out audio_out
(
    .reset(AUDIO_RES),
    .clk(AUDIO_CLK),

    .att(vol_att),
    .mix(audio_mix),
    .sample_rate(audio_96k),

    .flt_rate(aflt_rate),
    .cx(acx),
    .cx0(acx0),
    .cx1(acx1),
    .cx2(acx2),
    .cy0(acy0),
    .cy1(acy1),
    .cy2(acy2),

    .is_signed(audio_s),
    .core_l(compr[audio[16:14]]),
    .core_r(compr[audio[16:14]]),

    .alsa_l(alsa_l),
    .alsa_r(alsa_r),

    .o_i2s_ce(I2S_CE),
    .o_l_audio_flt(AUDIO_L_FLT),
    .o_r_audio_flt(AUDIO_R_FLT)    
);

endmodule