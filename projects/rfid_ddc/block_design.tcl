# Create clk_wiz
cell xilinx.com:ip:clk_wiz pll_0 {
  PRIMITIVE PLL
  PRIM_IN_FREQ.VALUE_SRC USER
  PRIM_IN_FREQ 125.0
  PRIM_SOURCE Differential_clock_capable_pin
  CLKOUT1_USED true
  CLKOUT1_REQUESTED_OUT_FREQ 125.0
  USE_RESET false
} {
  clk_in1_p adc_clk_p_i
  clk_in1_n adc_clk_n_i
}

# Create processing_system7
cell xilinx.com:ip:processing_system7 ps_0 {
  PCW_IMPORT_BOARD_PRESET cfg/red_pitaya.xml
  PCW_USE_S_AXI_HP0 1
} {
  M_AXI_GP0_ACLK pll_0/clk_out1
  S_AXI_HP0_ACLK pll_0/clk_out1
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {
  make_external {FIXED_IO, DDR}
  Master Disable
  Slave Disable
} [get_bd_cells ps_0]

# Create xlconstant
cell xilinx.com:ip:xlconstant const_0

# Create proc_sys_reset
cell xilinx.com:ip:proc_sys_reset rst_0 {} {
  ext_reset_in const_0/dout
}

# ADC

# Create axis_red_pitaya_adc
cell pavel-demin:user:axis_red_pitaya_adc adc_0 {
  ADC_DATA_WIDTH 14
} {
  aclk pll_0/clk_out1
  adc_dat_a adc_dat_a_i
  adc_dat_b adc_dat_b_i
  adc_csn adc_csn_o
}

# Create axi_cfg_register
cell pavel-demin:user:axi_cfg_register cfg_0 {
  CFG_DATA_WIDTH 96
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins cfg_0/S_AXI]

set_property RANGE 4K [get_bd_addr_segs ps_0/Data/SEG_cfg_0_reg0]
set_property OFFSET 0x40000000 [get_bd_addr_segs ps_0/Data/SEG_cfg_0_reg0]

# Create port_slicer
cell pavel-demin:user:port_slicer slice_1 {
  DIN_WIDTH 96 DIN_FROM 0 DIN_TO 0
} {
  din cfg_0/cfg_data
}

# Create port_slicer
cell pavel-demin:user:port_slicer slice_2 {
  DIN_WIDTH 96 DIN_FROM 1 DIN_TO 1
} {
  din cfg_0/cfg_data
}

# Create port_slicer
cell pavel-demin:user:port_slicer slice_3 {
  DIN_WIDTH 96 DIN_FROM 2 DIN_TO 2
} {
  din cfg_0/cfg_data
}

# Create port_slicer
cell pavel-demin:user:port_slicer slice_4 {
  DIN_WIDTH 96 DIN_FROM 63 DIN_TO 32
} {
  din cfg_0/cfg_data
}

# Create port_slicer
cell pavel-demin:user:port_slicer slice_5 {
  DIN_WIDTH 96 DIN_FROM 79 DIN_TO 64
} {
  din cfg_0/cfg_data
}

# Create axis_subset_converter
cell xilinx.com:ip:axis_subset_converter subset_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 2
  TDATA_REMAP {tdata[31:16]}
} {
  S_AXIS adc_0/M_AXIS
  aclk pll_0/clk_out1
  aresetn rst_0/peripheral_aresetn
}

# Create axis_constant
cell pavel-demin:user:axis_constant phase_0 {
  AXIS_TDATA_WIDTH 32
} {
  cfg_data slice_4/dout
  aclk pll_0/clk_out1
}

# Create dds_compiler
cell xilinx.com:ip:dds_compiler dds_0 {
  DDS_CLOCK_RATE 125
  SPURIOUS_FREE_DYNAMIC_RANGE 138
  FREQUENCY_RESOLUTION 0.2
  PHASE_INCREMENT Streaming
  DSP48_USE Maximal
  HAS_PHASE_OUT false
  PHASE_WIDTH 30
  OUTPUT_WIDTH 24
} {
  S_AXIS_PHASE phase_0/M_AXIS
  aclk pll_0/clk_out1
}

# Create axis_lfsr
cell pavel-demin:user:axis_lfsr lfsr_0 {} {
  aclk pll_0/clk_out1
  aresetn slice_1/dout
}

# Create cmpy
cell xilinx.com:ip:cmpy mult_0 {
  APORTWIDTH.VALUE_SRC USER
  BPORTWIDTH.VALUE_SRC USER
  APORTWIDTH 14
  BPORTWIDTH 24
  ROUNDMODE Random_Rounding
  OUTPUTWIDTH 33
} {
  S_AXIS_A subset_0/M_AXIS
  S_AXIS_B dds_0/M_AXIS_DATA
  S_AXIS_CTRL lfsr_0/M_AXIS
  aclk pll_0/clk_out1
}

# Create axis_broadcaster
cell xilinx.com:ip:axis_broadcaster bcast_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 10
  M_TDATA_NUM_BYTES 4
  M00_TDATA_REMAP {tdata[71:40]}
  M01_TDATA_REMAP {tdata[31:0]}
} {
  S_AXIS mult_0/M_AXIS_DOUT
  aclk pll_0/clk_out1
  aresetn rst_0/peripheral_aresetn
}

# Create axis_constant
cell pavel-demin:user:axis_constant rate_0 {
  AXIS_TDATA_WIDTH 16
} {
  cfg_data slice_5/dout
  aclk pll_0/clk_out1
}

# Create axis_packetizer
cell pavel-demin:user:axis_packetizer pktzr_0 {
  AXIS_TDATA_WIDTH 16
  CNTR_WIDTH 1
  CONTINUOUS FALSE
} {
  S_AXIS rate_0/M_AXIS
  cfg_data const_0/dout
  aclk pll_0/clk_out1
  aresetn slice_3/dout
}

# Create axis_constant
cell pavel-demin:user:axis_constant rate_1 {
  AXIS_TDATA_WIDTH 16
} {
  cfg_data slice_5/dout
  aclk pll_0/clk_out1
}

# Create axis_packetizer
cell pavel-demin:user:axis_packetizer pktzr_1 {
  AXIS_TDATA_WIDTH 16
  CNTR_WIDTH 1
  CONTINUOUS FALSE
} {
  S_AXIS rate_1/M_AXIS
  cfg_data const_0/dout
  aclk pll_0/clk_out1
  aresetn slice_3/dout
}

# Create cic_compiler
cell xilinx.com:ip:cic_compiler cic_0 {
  INPUT_DATA_WIDTH.VALUE_SRC USER
  FILTER_TYPE Decimation
  NUMBER_OF_STAGES 6
  SAMPLE_RATE_CHANGES Programmable
  MINIMUM_RATE 10
  MAXIMUM_RATE 25
  FIXED_OR_INITIAL_RATE 25
  INPUT_SAMPLE_FREQUENCY 125
  CLOCK_FREQUENCY 125
  INPUT_DATA_WIDTH 32
  QUANTIZATION Truncation
  OUTPUT_DATA_WIDTH 32
  HAS_ARESETN true
  USE_XTREME_DSP_SLICE false
} {
  S_AXIS_DATA bcast_0/M00_AXIS
  S_AXIS_CONFIG pktzr_0/M_AXIS
  aclk pll_0/clk_out1
  aresetn slice_3/dout
}

# Create cic_compiler
cell xilinx.com:ip:cic_compiler cic_1 {
  INPUT_DATA_WIDTH.VALUE_SRC USER
  FILTER_TYPE Decimation
  NUMBER_OF_STAGES 6
  SAMPLE_RATE_CHANGES Programmable
  MINIMUM_RATE 10
  MAXIMUM_RATE 25
  FIXED_OR_INITIAL_RATE 25
  INPUT_SAMPLE_FREQUENCY 125
  CLOCK_FREQUENCY 125
  INPUT_DATA_WIDTH 32
  QUANTIZATION Truncation
  OUTPUT_DATA_WIDTH 32
  HAS_ARESETN true
  USE_XTREME_DSP_SLICE false
} {
  S_AXIS_DATA bcast_0/M01_AXIS
  S_AXIS_CONFIG pktzr_1/M_AXIS
  aclk pll_0/clk_out1
  aresetn slice_3/dout
}

# Create axis_combiner
cell  xilinx.com:ip:axis_combiner comb_0 {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 4
} {
  S00_AXIS cic_0/M_AXIS_DATA
  S01_AXIS cic_1/M_AXIS_DATA
  aclk pll_0/clk_out1
  aresetn rst_0/peripheral_aresetn
}

# Create fir_compiler
cell xilinx.com:ip:fir_compiler fir_0 {
  DATA_WIDTH.VALUE_SRC USER
  DATA_WIDTH 32
  COEFFICIENTVECTOR {-6.31205679801719e-08, 7.30926012591262e-09, 5.58953452660316e-08, 4.87316950414411e-08, 1.07546133379516e-07, 3.01597505273952e-08, -4.29713011972205e-07, -5.15088683751126e-07, 6.65424773061835e-07, 1.61445611220616e-06, -2.65343636858081e-07, -3.19225955598462e-06, -1.4656956635344e-06, 4.51693256356331e-06, 4.95158733722241e-06, -4.26319378220919e-06, -9.7977498553796e-06, 9.44159216789214e-07, 1.441864781152e-05, 6.24458921740868e-06, -1.62108808252072e-05, -1.64853641255889e-05, 1.24879640578905e-05, 2.68673275185905e-05, -2.00749793274122e-06, -3.29542220537769e-05, -1.35587081091376e-05, 3.05974201003771e-05, 2.91704971507981e-05, -1.8518941384538e-05, -3.7799439825986e-05, 4.62942167460686e-07, 3.37382068187074e-05, 1.46141908228077e-05, -1.68363906144596e-05, -1.54744850104491e-05, -4.47829930408245e-06, -5.60815641581475e-06, 1.36919077773766e-05, 4.60682513345666e-05, 8.27297098324278e-06, -8.87336580662072e-05, -7.32338727071921e-05, 0.000103549328633743, 0.000175033457667912, -5.71933641796373e-05, -0.000283319306782567, -7.10198225130815e-05, 0.000347086648094344, 0.0002725529592572, -0.000310298185337442, -0.000500615805888086, 0.000136574477778254, 0.000676310580518881, 0.000165855478664172, -0.000712826035124893, -0.000531288259905026, 0.000552473370010762, 0.000846425444211122, -0.000203614400308839, -0.000987306081720199, -0.00024148557557037, 0.000874365380478607, 0.000622784687698624, -0.00052633212807923, -0.000767978042535689, 8.61930091998568e-05, 0.000575466705863226, 0.000203788903800764, -9.58942652276285e-05, -8.58738542248142e-05, -0.000426377291248088, -0.000586353574146813, 0.000586394287322406, 0.00171842961976755, 5.92652821292847e-05, -0.00289800600426928, -0.00179922254626698, 0.00342264027436982, 0.00455508633511873, -0.00246031750071, -0.00772680712889434, -0.000673365374407288, 0.0101676277313623, 0.00617506528822861, -0.0103448387509704, -0.0134514322246294, 0.00667744450716941, 0.0209459642925805, 0.0020053761720137, -0.026158551925879, -0.0159903667756223, 0.0258381410378789, 0.0342981867210979, -0.016190566750313, -0.0544180098277801, -0.00733626972481323, 0.0718523260750129, 0.0520124078773443, -0.0774924202696119, -0.137214106628167, 0.0359573137235839, 0.346857509696945, 0.503987573448888, 0.346857509696945, 0.0359573137235838, -0.137214106628167, -0.0774924202696119, 0.0520124078773442, 0.0718523260750129, -0.00733626972481316, -0.0544180098277801, -0.016190566750313, 0.0342981867210979, 0.0258381410378788, -0.0159903667756223, -0.026158551925879, 0.00200537617201369, 0.0209459642925805, 0.00667744450716941, -0.0134514322246294, -0.0103448387509704, 0.00617506528822858, 0.0101676277313623, -0.000673365374407245, -0.00772680712889434, -0.00246031750071, 0.00455508633511873, 0.0034226402743698, -0.00179922254626699, -0.00289800600426929, 5.92652821292939e-05, 0.00171842961976755, 0.000586394287322401, -0.000586353574146832, -0.000426377291248088, -8.58738542248089e-05, -9.58942652276304e-05, 0.000203788903800761, 0.000575466705863229, 8.61930091998532e-05, -0.000767978042535691, -0.000526332128079237, 0.000622784687698626, 0.000874365380478613, -0.000241485575570369, -0.000987306081720197, -0.00020361440030884, 0.000846425444211121, 0.000552473370010762, -0.000531288259905019, -0.000712826035124894, 0.000165855478664166, 0.000676310580518881, 0.000136574477778256, -0.000500615805888085, -0.000310298185337445, 0.000272552959257198, 0.000347086648094346, -7.10198225130807e-05, -0.000283319306782565, -5.71933641796392e-05, 0.00017503345766791, 0.000103549328633745, -7.32338727071911e-05, -8.87336580662082e-05, 8.27297098323674e-06, 4.60682513345666e-05, 1.36919077773794e-05, -5.60815641581445e-06, -4.47829930408515e-06, -1.54744850104495e-05, -1.68363906144591e-05, 1.46141908228082e-05, 3.37382068187067e-05, 4.62942167460444e-07, -3.77994398259859e-05, -1.85189413845379e-05, 2.9170497150799e-05, 3.05974201003769e-05, -1.35587081091375e-05, -3.2954222053777e-05, -2.00749793274087e-06, 2.68673275185905e-05, 1.24879640578904e-05, -1.64853641255888e-05, -1.62108808252074e-05, 6.24458921740866e-06, 1.44186478115199e-05, 9.44159216789226e-07, -9.79774985537956e-06, -4.26319378220916e-06, 4.95158733722243e-06, 4.51693256356326e-06, -1.46569566353445e-06, -3.19225955598459e-06, -2.65343636858069e-07, 1.61445611220614e-06, 6.65424773061808e-07, -5.15088683751126e-07, -4.29713011972229e-07, 3.01597505273901e-08, 1.07546133379525e-07, 4.87316950414471e-08, 5.5895345266022e-08, 7.30926012591106e-09, -6.31205679801768e-08}
  COEFFICIENT_WIDTH 32
  QUANTIZATION Quantize_Only
  BESTPRECISION true
  FILTER_TYPE Decimation
  DECIMATION_RATE 2
  NUMBER_PATHS 2
  RATESPECIFICATION Input_Sample_Period
  SAMPLEPERIOD 10
  OUTPUT_ROUNDING_MODE Truncate_LSBs
  OUTPUT_WIDTH 16
} {
  S_AXIS_DATA comb_0/M_AXIS
  aclk pll_0/clk_out1
}

# Create axis_dwidth_converter
cell xilinx.com:ip:axis_dwidth_converter conv_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 8
} {
  S_AXIS fir_0/M_AXIS_DATA
  aclk pll_0/clk_out1
  aresetn slice_2/dout
}

# Create xlconstant
cell xilinx.com:ip:xlconstant const_1 {
  CONST_WIDTH 32
  CONST_VAL 503316480
}

# Create axis_ram_writer
cell pavel-demin:user:axis_ram_writer writer_0 {
  ADDR_WIDTH 15
} {
  S_AXIS conv_0/M_AXIS
  M_AXI ps_0/S_AXI_HP0
  cfg_data const_1/dout
  aclk pll_0/clk_out1
  aresetn slice_2/dout
}

assign_bd_address [get_bd_addr_segs ps_0/S_AXI_HP0/HP0_DDR_LOWOCM]

# Create axi_sts_register
cell pavel-demin:user:axi_sts_register sts_0 {
  STS_DATA_WIDTH 32
  AXI_ADDR_WIDTH 32
  AXI_DATA_WIDTH 32
} {
  sts_data writer_0/sts_data
}

# Create all required interconnections
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {
  Master /ps_0/M_AXI_GP0
  Clk Auto
} [get_bd_intf_pins sts_0/S_AXI]

set_property RANGE 4K [get_bd_addr_segs ps_0/Data/SEG_sts_0_reg0]
set_property OFFSET 0x40001000 [get_bd_addr_segs ps_0/Data/SEG_sts_0_reg0]
