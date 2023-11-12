// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32,
    parameter DELAYS=10,
    parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11,
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    wire [31:0] user_data; 
    wire [31:0] fir_data;
    wire [BITS-1:0] count;

    wire valid;
    wire IsUserAddr;
    wire IsFirAddr;
    wire [3:0] wstrb;
    wire [31:0] la_write;

    reg user_ready;
    reg fir_ready;

    reg [31:0] delay_count;

    assign IsUserAddr = (wbs_adr_i[31:20] == 12'h380) ? 1'b1 : 1'b0;
    assign IsFirAddr = (wbs_adr_i[31:20] == 12'h300) ? 1'b1 : 1'b0;

    // WB MI A
    assign valid = wbs_cyc_i && wbs_stb_i;
    assign wstrb = wbs_sel_i & {4{wbs_we_i}};
    
    assign clk = (~la_oenb[64]) ? la_data_in[64]: wb_clk_i;
    assign rst = (~la_oenb[65]) ? la_data_in[65]: wb_rst_i;

    // ==================== WB output ====================
    always (*) begin
        if (valid) begin
            if (IsFirAddr) begin
                assign wbs_dat_o = fir_data;
                assign wbs_ack_o = fir_ready;
            end
            else if (IsUserAddr) begin
                assign wbs_dat_o = user_data;
                assign wbs_ack_o = user_ready
            end
        end
    end

    // ====================================================

    // ==================== WB to Bram ====================

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            delay_count <= 0;
            user_ready <= 0;
        end else begin
            user_ready <= 0;
            if (valid && IsUserAddr && !user_ready) begin
                if (delay_count == DELAYS) begin
                    user_ready <= 1;
                    delay_count <= 0;
                end else begin
                    delay_count <= delay_count + 1;
                end
            end
        end  
    end

    bram user_bram (
        .CLK(clk),
        .WE0(wstrb),
        .EN0(valid && IsUserAddr),
        .Di0(wbs_dat_i),
        .Do0(user_data),
        .A0(wbs_adr_i)
    );

    // ====================================================

    // ==================== WB to AXI ====================

    wire                                awready;
    wire                                wready;
    reg                                 awvalid;
    reg         [(pADDR_WIDTH-1): 0]    awaddr;
    reg                                 wvalid;
    reg signed  [(pDATA_WIDTH-1) : 0]   wdata;
    wire                                arready;
    reg                                 rready;
    reg                                 arvalid;
    reg         [(pADDR_WIDTH-1): 0]    araddr;
    wire                                rvalid;
    wire signed [(pDATA_WIDTH-1): 0]    rdata;
    reg                                 ss_tvalid;
    reg signed [(pDATA_WIDTH-1) : 0]    ss_tdata;
    reg                                 ss_tlast;
    wire                                ss_tready;
    reg                                 sm_tready;
    wire                                sm_tvalid;
    wire signed [(pDATA_WIDTH-1) : 0]   sm_tdata;
    wire                                sm_tlast;
    reg                                 axis_clk;
    reg                                 axis_rst_n;

    // ram for tap
    wire [3:0]               tap_WE;
    wire                     tap_EN;
    wire [(pDATA_WIDTH-1):0] tap_Di;
    wire [(pADDR_WIDTH-1):0] tap_A;
    wire [(pDATA_WIDTH-1):0] tap_Do;

    // ram for data RAM
    wire [3:0]               data_WE;
    wire                     data_EN;
    wire [(pDATA_WIDTH-1):0] data_Di;
    wire [(pADDR_WIDTH-1):0] data_A;
    wire [(pDATA_WIDTH-1):0] data_Do;

    reg hs_aw; // handshake
    reg hs_w;
    reg hs_ar;

    wire axilite;
    assign axilite = wbs_adr_i < 0x30000080 ? : 1'b1 : 1'b0;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            hs_aw <= 0;
            hs_w <= 0;
            hs_ar <= 0;
        end
        else begin
            if(wbs_ack_o)               hs_aw <= 0;
            else if(awvalid && awready) hs_aw <= 1; // Is going to handshake
            else                        hs_aw <= hs_aw;

            if(wbs_ack_o)               hs_w <= 0;
            else if(wvalid && wready)   hs_w <= 1;
            else                        hs_w <= hs_w;

            if(wbs_ack_o)               hs_ar <= 0;
            else if(arvalid && arready) hs_ar <= 1;
            else                        hs_ar <= hs_ar;
        end
    end

    // AXI Write
    always @(*) begin
        if(valid && IsFirAddr && axilite) begin
            awvalid = (wbs_we_i && !hs_aw);
            wvalid = (wbs_we_i && !hs_w);
            awaddr = wbs_adr_i[11:0];
            wdata = wbs_dat_i;
        end else begin
            awvalid = 0;
            awaddr  = 0;
            wvalid  = 0;
            wdata   = 0;
        end
    end

    // AXI Read
    always @(*) begin
        if(valid && IsFirAddr && axilite) begin
            rready = (!wbs_we_i);
            arvalid = (!wbs_we_i && !hs_ar);
            araddr = wbs_adr_i[11:0];
        end else begin
            rready = 0;
            arvalid  = 0;
            araddr  = 0;
        end
    end

    // AXI Stream Slave (write x[i])
    always @(*) begin
        if(valid && IsFirAddr && !axilite && wbs_adr_i[7:0] == 8'h80) begin
            ss_tvalid = wbs_we_i;
            ss_tdata = wbs_dat_i;
            ss_tlast = 1;
        end else begin
            ss_tvalid = 0;
            ss_tdata = 0;
            ss_tlast = 0;
        end
    end
    // AXI Stream Master (read x[i])
    always @(*) begin
        if(valid && IsFirAddr && !axilite && wbs_adr_i[7:0] == 8'h84) begin
            sm_tready = 1;
        end else begin
            sm_tready = 0;
        end
    end

    // ACK/Data to WB
    always @(*) begin
        if(valid && IsFirAddr && axilite) begin
            fir_data = rdata;
        end else if(valid && IsFirAddr && !axilite) begin
            fir_data = sm_tdata;
        end else begin
            fir_data = 0;
        end

        fir_ready = (hs_aw == 1 && hs_w) || 
    end

    fir fir_DUT(
        .awready(awready),
        .wready(wready),
        .awvalid(awvalid),
        .awaddr(awaddr),
        .wvalid(wvalid),
        .wdata(wdata),
        .arready(arready),
        .rready(rready),
        .arvalid(arvalid),
        .araddr(araddr),
        .rvalid(rvalid),
        .rdata(rdata),
        .ss_tvalid(ss_tvalid),
        .ss_tdata(ss_tdata),
        .ss_tlast(ss_tlast),
        .ss_tready(ss_tready),
        .sm_tready(sm_tready),
        .sm_tvalid(sm_tvalid),
        .sm_tdata(sm_tdata),
        .sm_tlast(sm_tlast),

        // ram for tap
        .tap_WE(tap_WE),
        .tap_EN(tap_EN),
        .tap_Di(tap_Di),
        .tap_A(tap_A),
        .tap_Do(tap_Do),

        // ram for data
        .data_WE(data_WE),
        .data_EN(data_EN),
        .data_Di(data_Di),
        .data_A(data_A),
        .data_Do(data_Do),

        .axis_clk(axis_clk),
        .axis_rst_n(axis_rst_n)
    );
    
    bram11 tap_RAM (
        .CLK(axis_clk),
        .WE(tap_WE),
        .EN(tap_EN),
        .Di(tap_Di),
        .A(tap_A),
        .Do(tap_Do)
    );

    bram11 data_RAM(
        .CLK(axis_clk),
        .WE(data_WE),
        .EN(data_EN),
        .Di(data_Di),
        .A(data_A),
        .Do(data_Do)
    );

endmodule

`default_nettype wire
