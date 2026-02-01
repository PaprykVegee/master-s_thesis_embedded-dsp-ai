
################################################################
# This is a generated script based on design: fft_test
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2022.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source fft_test_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# adc_sim, axis_counter_debug, frame_extractor, hann_win_applayer, hann_win_applayer, biquad_axis_v3, biquad_axis_v3, biquad_axis_v3, biquad_axis_v3, biquad_axis_v3, rfft_extractor, rfft_extractor

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xck26-sfvc784-2LV-c
   set_property BOARD_PART xilinx.com:kv260_som:part0:1.4 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name fft_test

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:sim_clk_gen:1.0\
xilinx.com:ip:c_addsub:12.0\
xilinx.com:ip:mult_gen:12.0\
xilinx.com:ip:xfft:9.1\
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:xlslice:1.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
adc_sim\
axis_counter_debug\
frame_extractor\
hann_win_applayer\
hann_win_applayer\
biquad_axis_v3\
biquad_axis_v3\
biquad_axis_v3\
biquad_axis_v3\
biquad_axis_v3\
rfft_extractor\
rfft_extractor\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: rfft2
proc create_hier_cell_rfft2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_rfft2() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir O m_axis_tlast
  create_bd_pin -dir O m_axis_tvalid
  create_bd_pin -dir O -from 31 -to 0 -type data rfft_out
  create_bd_pin -dir I s_axis_data_tlast
  create_bd_pin -dir I s_axis_data_tvalid
  create_bd_pin -dir I -from 15 -to 0 s_axis_tdata

  # Create instance: c_addsub_0, and set properties
  set c_addsub_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_addsub:12.0 c_addsub_0 ]
  set_property -dict [list \
    CONFIG.A_Width {32} \
    CONFIG.B_Value {00000000000000000000000000000000} \
    CONFIG.B_Width {32} \
    CONFIG.CE {false} \
    CONFIG.Implementation {DSP48} \
    CONFIG.Latency {1} \
    CONFIG.Out_Width {32} \
  ] $c_addsub_0


  # Create instance: mult_gen_0, and set properties
  set mult_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mult_gen:12.0 mult_gen_0 ]
  set_property -dict [list \
    CONFIG.PortAWidth {16} \
    CONFIG.PortBWidth {16} \
  ] $mult_gen_0


  # Create instance: mult_gen_1, and set properties
  set mult_gen_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mult_gen:12.0 mult_gen_1 ]
  set_property -dict [list \
    CONFIG.PortAWidth {16} \
    CONFIG.PortBWidth {16} \
  ] $mult_gen_1


  # Create instance: rfft_extractor_0, and set properties
  set block_name rfft_extractor
  set block_cell_name rfft_extractor_0
  if { [catch {set rfft_extractor_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $rfft_extractor_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: xfft_1, and set properties
  set xfft_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xfft:9.1 xfft_1 ]
  set_property -dict [list \
    CONFIG.data_format {fixed_point} \
    CONFIG.implementation_options {automatically_select} \
    CONFIG.input_width {16} \
    CONFIG.number_of_stages_using_block_ram_for_data_and_phase_factors {1} \
    CONFIG.output_ordering {natural_order} \
    CONFIG.phase_factor_width {16} \
    CONFIG.target_clock_frequency {100} \
    CONFIG.target_data_throughput {100} \
    CONFIG.transform_length {256} \
  ] $xfft_1


  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {16} \
    CONFIG.IN1_WIDTH {16} \
  ] $xlconcat_0


  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {16} \
  ] $xlconstant_0


  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1 ]

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {31} \
    CONFIG.DIN_TO {16} \
  ] $xlslice_0


  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1 ]
  set_property CONFIG.DIN_FROM {15} $xlslice_1


  # Create port connections
  connect_bd_net -net In1_0_1 [get_bd_pins s_axis_tdata] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net aclk_1 [get_bd_pins aclk] [get_bd_pins c_addsub_0/CLK] [get_bd_pins mult_gen_0/CLK] [get_bd_pins mult_gen_1/CLK] [get_bd_pins rfft_extractor_0/aclk] [get_bd_pins xfft_1/aclk]
  connect_bd_net -net aresetn_1 [get_bd_pins aresetn] [get_bd_pins rfft_extractor_0/aresetn]
  connect_bd_net -net c_addsub_0_S [get_bd_pins rfft_out] [get_bd_pins c_addsub_0/S]
  connect_bd_net -net mult_gen_0_P [get_bd_pins c_addsub_0/A] [get_bd_pins mult_gen_0/P]
  connect_bd_net -net mult_gen_1_P [get_bd_pins c_addsub_0/B] [get_bd_pins mult_gen_1/P]
  connect_bd_net -net rfft_extractor_0_m_axis_tdata [get_bd_pins rfft_extractor_0/m_axis_tdata] [get_bd_pins xlslice_0/Din] [get_bd_pins xlslice_1/Din]
  connect_bd_net -net rfft_extractor_0_m_axis_tlast [get_bd_pins m_axis_tlast] [get_bd_pins rfft_extractor_0/m_axis_tlast]
  connect_bd_net -net rfft_extractor_0_m_axis_tvalid [get_bd_pins m_axis_tvalid] [get_bd_pins rfft_extractor_0/m_axis_tvalid]
  connect_bd_net -net rfft_extractor_0_s_axis_tready [get_bd_pins rfft_extractor_0/s_axis_tready] [get_bd_pins xfft_1/m_axis_data_tready]
  connect_bd_net -net s_axis_data_tlast_1 [get_bd_pins s_axis_data_tlast] [get_bd_pins xfft_1/s_axis_data_tlast]
  connect_bd_net -net s_axis_data_tvalid_1 [get_bd_pins s_axis_data_tvalid] [get_bd_pins xfft_1/s_axis_data_tvalid]
  connect_bd_net -net xfft_1_m_axis_data_tdata [get_bd_pins rfft_extractor_0/s_axis_tdata] [get_bd_pins xfft_1/m_axis_data_tdata]
  connect_bd_net -net xfft_1_m_axis_data_tlast [get_bd_pins rfft_extractor_0/s_axis_tlast] [get_bd_pins xfft_1/m_axis_data_tlast]
  connect_bd_net -net xfft_1_m_axis_data_tvalid [get_bd_pins rfft_extractor_0/s_axis_tvalid] [get_bd_pins xfft_1/m_axis_data_tvalid]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins xfft_1/s_axis_data_tdata] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins xlconcat_0/In0] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net xlconstant_1_dout [get_bd_pins rfft_extractor_0/m_axis_tready] [get_bd_pins xlconstant_1/dout]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins mult_gen_0/A] [get_bd_pins mult_gen_0/B] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins mult_gen_1/A] [get_bd_pins mult_gen_1/B] [get_bd_pins xlslice_1/Dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: rfft1
proc create_hier_cell_rfft1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_rfft1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst aresetn
  create_bd_pin -dir O m_axis_tlast
  create_bd_pin -dir O m_axis_tvalid
  create_bd_pin -dir O -from 31 -to 0 -type data rfft_out
  create_bd_pin -dir I s_axis_data_tlast
  create_bd_pin -dir I s_axis_data_tvalid
  create_bd_pin -dir I -from 15 -to 0 s_axis_tdata

  # Create instance: c_addsub_0, and set properties
  set c_addsub_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_addsub:12.0 c_addsub_0 ]
  set_property -dict [list \
    CONFIG.A_Width {32} \
    CONFIG.B_Value {00000000000000000000000000000000} \
    CONFIG.B_Width {32} \
    CONFIG.CE {false} \
    CONFIG.Implementation {DSP48} \
    CONFIG.Latency {1} \
    CONFIG.Out_Width {32} \
  ] $c_addsub_0


  # Create instance: mult_gen_0, and set properties
  set mult_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mult_gen:12.0 mult_gen_0 ]
  set_property -dict [list \
    CONFIG.PortAWidth {16} \
    CONFIG.PortBWidth {16} \
  ] $mult_gen_0


  # Create instance: mult_gen_1, and set properties
  set mult_gen_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mult_gen:12.0 mult_gen_1 ]
  set_property -dict [list \
    CONFIG.PortAWidth {16} \
    CONFIG.PortBWidth {16} \
  ] $mult_gen_1


  # Create instance: rfft_extractor_0, and set properties
  set block_name rfft_extractor
  set block_cell_name rfft_extractor_0
  if { [catch {set rfft_extractor_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $rfft_extractor_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: xfft_1, and set properties
  set xfft_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xfft:9.1 xfft_1 ]
  set_property -dict [list \
    CONFIG.data_format {fixed_point} \
    CONFIG.implementation_options {automatically_select} \
    CONFIG.input_width {16} \
    CONFIG.number_of_stages_using_block_ram_for_data_and_phase_factors {1} \
    CONFIG.output_ordering {natural_order} \
    CONFIG.phase_factor_width {16} \
    CONFIG.target_clock_frequency {100} \
    CONFIG.target_data_throughput {100} \
    CONFIG.transform_length {256} \
  ] $xfft_1


  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {16} \
    CONFIG.IN1_WIDTH {16} \
  ] $xlconcat_0


  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {16} \
  ] $xlconstant_0


  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1 ]

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {31} \
    CONFIG.DIN_TO {16} \
  ] $xlslice_0


  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1 ]
  set_property CONFIG.DIN_FROM {15} $xlslice_1


  # Create port connections
  connect_bd_net -net In1_0_1 [get_bd_pins s_axis_tdata] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net aclk_1 [get_bd_pins aclk] [get_bd_pins c_addsub_0/CLK] [get_bd_pins mult_gen_0/CLK] [get_bd_pins mult_gen_1/CLK] [get_bd_pins rfft_extractor_0/aclk] [get_bd_pins xfft_1/aclk]
  connect_bd_net -net aresetn_1 [get_bd_pins aresetn] [get_bd_pins rfft_extractor_0/aresetn]
  connect_bd_net -net c_addsub_0_S [get_bd_pins rfft_out] [get_bd_pins c_addsub_0/S]
  connect_bd_net -net mult_gen_0_P [get_bd_pins c_addsub_0/A] [get_bd_pins mult_gen_0/P]
  connect_bd_net -net mult_gen_1_P [get_bd_pins c_addsub_0/B] [get_bd_pins mult_gen_1/P]
  connect_bd_net -net rfft_extractor_0_m_axis_tdata [get_bd_pins rfft_extractor_0/m_axis_tdata] [get_bd_pins xlslice_0/Din] [get_bd_pins xlslice_1/Din]
  connect_bd_net -net rfft_extractor_0_m_axis_tlast [get_bd_pins m_axis_tlast] [get_bd_pins rfft_extractor_0/m_axis_tlast]
  connect_bd_net -net rfft_extractor_0_m_axis_tvalid [get_bd_pins m_axis_tvalid] [get_bd_pins rfft_extractor_0/m_axis_tvalid]
  connect_bd_net -net rfft_extractor_0_s_axis_tready [get_bd_pins rfft_extractor_0/s_axis_tready] [get_bd_pins xfft_1/m_axis_data_tready]
  connect_bd_net -net s_axis_data_tlast_1 [get_bd_pins s_axis_data_tlast] [get_bd_pins xfft_1/s_axis_data_tlast]
  connect_bd_net -net s_axis_data_tvalid_1 [get_bd_pins s_axis_data_tvalid] [get_bd_pins xfft_1/s_axis_data_tvalid]
  connect_bd_net -net xfft_1_m_axis_data_tdata [get_bd_pins rfft_extractor_0/s_axis_tdata] [get_bd_pins xfft_1/m_axis_data_tdata]
  connect_bd_net -net xfft_1_m_axis_data_tlast [get_bd_pins rfft_extractor_0/s_axis_tlast] [get_bd_pins xfft_1/m_axis_data_tlast]
  connect_bd_net -net xfft_1_m_axis_data_tvalid [get_bd_pins rfft_extractor_0/s_axis_tvalid] [get_bd_pins xfft_1/m_axis_data_tvalid]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins xfft_1/s_axis_data_tdata] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins xlconcat_0/In0] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net xlconstant_1_dout [get_bd_pins rfft_extractor_0/m_axis_tready] [get_bd_pins xlconstant_1/dout]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins mult_gen_0/A] [get_bd_pins mult_gen_0/B] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins mult_gen_1/A] [get_bd_pins mult_gen_1/B] [get_bd_pins xlslice_1/Dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: cascade_biquad_v2_axis
proc create_hier_cell_cascade_biquad_v2_axis { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_cascade_biquad_v2_axis() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -type rst areset
  create_bd_pin -dir O -from 15 -to 0 m_axis_tdata
  create_bd_pin -dir O m_axis_tlast
  create_bd_pin -dir I m_axis_tready
  create_bd_pin -dir O m_axis_tvalid
  create_bd_pin -dir I -from 15 -to 0 s_axis_tdata
  create_bd_pin -dir I s_axis_tlast
  create_bd_pin -dir O s_axis_tready
  create_bd_pin -dir I s_axis_tvalid

  # Create instance: biquad_axis_v3_0, and set properties
  set block_name biquad_axis_v3
  set block_cell_name biquad_axis_v3_0
  if { [catch {set biquad_axis_v3_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $biquad_axis_v3_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [list \
    CONFIG.A1 {-78493} \
    CONFIG.A2 {38758} \
    CONFIG.B0 {32} \
    CONFIG.B1 {64} \
    CONFIG.B2 {32} \
    CONFIG.coefficient_decimal_width {16} \
    CONFIG.coefficient_width {19} \
    CONFIG.internal_decimal_width {20} \
    CONFIG.internal_width {22} \
  ] $biquad_axis_v3_0


  # Create instance: biquad_axis_v3_1, and set properties
  set block_name biquad_axis_v3
  set block_cell_name biquad_axis_v3_1
  if { [catch {set biquad_axis_v3_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $biquad_axis_v3_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [list \
    CONFIG.A1 {-66619} \
    CONFIG.A2 {40310} \
    CONFIG.B0 {65536} \
    CONFIG.B1 {131048} \
    CONFIG.B2 {65512} \
    CONFIG.coefficient_decimal_width {16} \
    CONFIG.coefficient_width {25} \
    CONFIG.internal_decimal_width {20} \
    CONFIG.internal_width {22} \
  ] $biquad_axis_v3_1


  # Create instance: biquad_axis_v3_2, and set properties
  set block_name biquad_axis_v3
  set block_cell_name biquad_axis_v3_2
  if { [catch {set biquad_axis_v3_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $biquad_axis_v3_2 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [list \
    CONFIG.A1 {-94229} \
    CONFIG.A2 {46787} \
    CONFIG.B0 {65536} \
    CONFIG.B1 {-50} \
    CONFIG.B2 {-65510} \
    CONFIG.coefficient_decimal_width {16} \
    CONFIG.coefficient_width {20} \
    CONFIG.internal_decimal_width {25} \
    CONFIG.internal_width {30} \
  ] $biquad_axis_v3_2


  # Create instance: biquad_axis_v3_3, and set properties
  set block_name biquad_axis_v3
  set block_cell_name biquad_axis_v3_3
  if { [catch {set biquad_axis_v3_3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $biquad_axis_v3_3 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [list \
    CONFIG.A1 {-65488} \
    CONFIG.A2 {54218} \
    CONFIG.B0 {65536} \
    CONFIG.B1 {-131079} \
    CONFIG.B2 {65543} \
    CONFIG.coefficient_decimal_width {16} \
    CONFIG.coefficient_width {20} \
    CONFIG.internal_decimal_width {30} \
    CONFIG.internal_width {33} \
  ] $biquad_axis_v3_3


  # Create instance: biquad_axis_v3_4, and set properties
  set block_name biquad_axis_v3
  set block_cell_name biquad_axis_v3_4
  if { [catch {set biquad_axis_v3_4 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $biquad_axis_v3_4 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [list \
    CONFIG.A1 {-108402} \
    CONFIG.A2 {58687} \
    CONFIG.B0 {65536} \
    CONFIG.B1 {-131053} \
    CONFIG.B2 {65517} \
    CONFIG.coefficient_decimal_width {16} \
    CONFIG.coefficient_width {19} \
    CONFIG.internal_decimal_width {20} \
    CONFIG.internal_width {22} \
  ] $biquad_axis_v3_4


  # Create port connections
  connect_bd_net -net aclk_1 [get_bd_pins aclk] [get_bd_pins biquad_axis_v3_0/aclk] [get_bd_pins biquad_axis_v3_1/aclk] [get_bd_pins biquad_axis_v3_2/aclk] [get_bd_pins biquad_axis_v3_3/aclk] [get_bd_pins biquad_axis_v3_4/aclk]
  connect_bd_net -net areset_1 [get_bd_pins areset] [get_bd_pins biquad_axis_v3_0/resetn] [get_bd_pins biquad_axis_v3_1/resetn] [get_bd_pins biquad_axis_v3_2/resetn] [get_bd_pins biquad_axis_v3_3/resetn] [get_bd_pins biquad_axis_v3_4/resetn]
  connect_bd_net -net biquad_axis_v3_0_m_axis_tdata [get_bd_pins biquad_axis_v3_0/m_axis_tdata] [get_bd_pins biquad_axis_v3_1/s_axis_tdata]
  connect_bd_net -net biquad_axis_v3_0_m_axis_tlast [get_bd_pins biquad_axis_v3_0/m_axis_tlast] [get_bd_pins biquad_axis_v3_1/s_axis_tlast]
  connect_bd_net -net biquad_axis_v3_0_m_axis_tvalid [get_bd_pins biquad_axis_v3_0/m_axis_tvalid] [get_bd_pins biquad_axis_v3_1/s_axis_tvalid]
  connect_bd_net -net biquad_axis_v3_0_s_axis_tready [get_bd_pins s_axis_tready] [get_bd_pins biquad_axis_v3_0/s_axis_tready]
  connect_bd_net -net biquad_axis_v3_1_m_axis_tdata [get_bd_pins biquad_axis_v3_1/m_axis_tdata] [get_bd_pins biquad_axis_v3_2/s_axis_tdata]
  connect_bd_net -net biquad_axis_v3_1_m_axis_tlast [get_bd_pins biquad_axis_v3_1/m_axis_tlast] [get_bd_pins biquad_axis_v3_2/s_axis_tlast]
  connect_bd_net -net biquad_axis_v3_1_m_axis_tvalid [get_bd_pins biquad_axis_v3_1/m_axis_tvalid] [get_bd_pins biquad_axis_v3_2/s_axis_tvalid]
  connect_bd_net -net biquad_axis_v3_1_s_axis_tready [get_bd_pins biquad_axis_v3_0/m_axis_tready] [get_bd_pins biquad_axis_v3_1/s_axis_tready]
  connect_bd_net -net biquad_axis_v3_2_m_axis_tdata [get_bd_pins biquad_axis_v3_2/m_axis_tdata] [get_bd_pins biquad_axis_v3_3/s_axis_tdata]
  connect_bd_net -net biquad_axis_v3_2_m_axis_tlast [get_bd_pins biquad_axis_v3_2/m_axis_tlast] [get_bd_pins biquad_axis_v3_3/s_axis_tlast]
  connect_bd_net -net biquad_axis_v3_2_m_axis_tvalid [get_bd_pins biquad_axis_v3_2/m_axis_tvalid] [get_bd_pins biquad_axis_v3_3/s_axis_tvalid]
  connect_bd_net -net biquad_axis_v3_2_s_axis_tready [get_bd_pins biquad_axis_v3_1/m_axis_tready] [get_bd_pins biquad_axis_v3_2/s_axis_tready]
  connect_bd_net -net biquad_axis_v3_3_m_axis_tdata [get_bd_pins biquad_axis_v3_3/m_axis_tdata] [get_bd_pins biquad_axis_v3_4/s_axis_tdata]
  connect_bd_net -net biquad_axis_v3_3_m_axis_tlast [get_bd_pins biquad_axis_v3_3/m_axis_tlast] [get_bd_pins biquad_axis_v3_4/s_axis_tlast]
  connect_bd_net -net biquad_axis_v3_3_m_axis_tvalid [get_bd_pins biquad_axis_v3_3/m_axis_tvalid] [get_bd_pins biquad_axis_v3_4/s_axis_tvalid]
  connect_bd_net -net biquad_axis_v3_3_s_axis_tready [get_bd_pins biquad_axis_v3_2/m_axis_tready] [get_bd_pins biquad_axis_v3_3/s_axis_tready]
  connect_bd_net -net biquad_axis_v3_4_m_axis_tdata [get_bd_pins m_axis_tdata] [get_bd_pins biquad_axis_v3_4/m_axis_tdata]
  connect_bd_net -net biquad_axis_v3_4_m_axis_tlast [get_bd_pins m_axis_tlast] [get_bd_pins biquad_axis_v3_4/m_axis_tlast]
  connect_bd_net -net biquad_axis_v3_4_m_axis_tvalid [get_bd_pins m_axis_tvalid] [get_bd_pins biquad_axis_v3_4/m_axis_tvalid]
  connect_bd_net -net biquad_axis_v3_4_s_axis_tready [get_bd_pins biquad_axis_v3_3/m_axis_tready] [get_bd_pins biquad_axis_v3_4/s_axis_tready]
  connect_bd_net -net m_axis_tready_1 [get_bd_pins m_axis_tready] [get_bd_pins biquad_axis_v3_4/m_axis_tready]
  connect_bd_net -net s_axis_tdata_1 [get_bd_pins s_axis_tdata] [get_bd_pins biquad_axis_v3_0/s_axis_tdata]
  connect_bd_net -net s_axis_tlast_1 [get_bd_pins s_axis_tlast] [get_bd_pins biquad_axis_v3_0/s_axis_tlast]
  connect_bd_net -net s_axis_tvalid_1 [get_bd_pins s_axis_tvalid] [get_bd_pins biquad_axis_v3_0/s_axis_tvalid]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports

  # Create ports
  set counts_0 [ create_bd_port -dir O -from 15 -to 0 counts_0 ]
  set filterd_signal [ create_bd_port -dir O -from 15 -to 0 filterd_signal ]
  set raw_signal [ create_bd_port -dir O -from 15 -to 0 raw_signal ]
  set rfft_out_0 [ create_bd_port -dir O -from 31 -to 0 -type data rfft_out_0 ]
  set rfft_out_1 [ create_bd_port -dir O -from 31 -to 0 -type data rfft_out_1 ]

  # Create instance: adc_sim_0, and set properties
  set block_name adc_sim
  set block_cell_name adc_sim_0
  if { [catch {set adc_sim_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $adc_sim_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [list \
    CONFIG.DATA_WIDTH {16} \
    CONFIG.MAX_INPUT {4} \
    CONFIG.SAMPLING_TIME {200000} \
  ] $adc_sim_0


  # Create instance: axis_counter_debug_0, and set properties
  set block_name axis_counter_debug
  set block_cell_name axis_counter_debug_0
  if { [catch {set axis_counter_debug_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axis_counter_debug_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: cascade_biquad_v2_axis
  create_hier_cell_cascade_biquad_v2_axis [current_bd_instance .] cascade_biquad_v2_axis

  # Create instance: frame_extractor_0, and set properties
  set block_name frame_extractor
  set block_cell_name frame_extractor_0
  if { [catch {set frame_extractor_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $frame_extractor_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [list \
    CONFIG.DATA_WIDTH {16} \
    CONFIG.EXTRACT_NUM {128} \
  ] $frame_extractor_0


  # Create instance: hann_win_applayer_0, and set properties
  set block_name hann_win_applayer
  set block_cell_name hann_win_applayer_0
  if { [catch {set hann_win_applayer_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $hann_win_applayer_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [list \
    CONFIG.DATA_WIDTH {16} \
    CONFIG.WINDOW_SIZE {256} \
  ] $hann_win_applayer_0


  # Create instance: hann_win_applayer_1, and set properties
  set block_name hann_win_applayer
  set block_cell_name hann_win_applayer_1
  if { [catch {set hann_win_applayer_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $hann_win_applayer_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [list \
    CONFIG.DATA_WIDTH {16} \
    CONFIG.WINDOW_SIZE {256} \
  ] $hann_win_applayer_1


  # Create instance: rfft1
  create_hier_cell_rfft1 [current_bd_instance .] rfft1

  # Create instance: rfft2
  create_hier_cell_rfft2 [current_bd_instance .] rfft2

  # Create instance: sim_clk_gen_0, and set properties
  set sim_clk_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:sim_clk_gen:1.0 sim_clk_gen_0 ]

  # Create port connections
  connect_bd_net -net adc_sim_0_m_axis_tdata [get_bd_ports raw_signal] [get_bd_pins adc_sim_0/m_axis_tdata] [get_bd_pins cascade_biquad_v2_axis/s_axis_tdata]
  connect_bd_net -net adc_sim_0_m_axis_tlast [get_bd_pins adc_sim_0/m_axis_tlast] [get_bd_pins cascade_biquad_v2_axis/s_axis_tlast]
  connect_bd_net -net adc_sim_0_m_axis_tvalid [get_bd_pins adc_sim_0/m_axis_tvalid] [get_bd_pins axis_counter_debug_0/val] [get_bd_pins cascade_biquad_v2_axis/s_axis_tvalid]
  connect_bd_net -net axis_counter_debug_0_counts [get_bd_ports counts_0] [get_bd_pins axis_counter_debug_0/counts]
  connect_bd_net -net cascade_biquad_v2_axis_m_axis_tdata1 [get_bd_ports filterd_signal] [get_bd_pins cascade_biquad_v2_axis/m_axis_tdata] [get_bd_pins frame_extractor_0/s_axis_tdata] [get_bd_pins hann_win_applayer_0/s_axis_tdata]
  connect_bd_net -net cascade_biquad_v2_axis_m_axis_tlast [get_bd_pins cascade_biquad_v2_axis/m_axis_tlast] [get_bd_pins frame_extractor_0/s_axis_tlast] [get_bd_pins hann_win_applayer_0/s_axis_tlast]
  connect_bd_net -net cascade_biquad_v2_axis_m_axis_tvalid [get_bd_pins cascade_biquad_v2_axis/m_axis_tvalid] [get_bd_pins frame_extractor_0/s_axis_tvalid] [get_bd_pins hann_win_applayer_0/s_axis_tvalid]
  connect_bd_net -net cascade_biquad_v2_axis_s_axis_tready [get_bd_pins adc_sim_0/m_axis_tready] [get_bd_pins cascade_biquad_v2_axis/s_axis_tready]
  connect_bd_net -net frame_extractor_0_m_axis_tdata [get_bd_pins frame_extractor_0/m_axis_tdata] [get_bd_pins hann_win_applayer_1/s_axis_tdata]
  connect_bd_net -net frame_extractor_0_m_axis_tlast [get_bd_pins frame_extractor_0/m_axis_tlast] [get_bd_pins hann_win_applayer_1/s_axis_tlast]
  connect_bd_net -net frame_extractor_0_m_axis_tvalid [get_bd_pins frame_extractor_0/m_axis_tvalid] [get_bd_pins hann_win_applayer_1/s_axis_tvalid]
  connect_bd_net -net hann_win_applayer_0_m_axis_tdata [get_bd_pins hann_win_applayer_0/m_axis_tdata] [get_bd_pins rfft1/s_axis_tdata]
  connect_bd_net -net hann_win_applayer_0_m_axis_tlast [get_bd_pins hann_win_applayer_0/m_axis_tlast] [get_bd_pins rfft1/s_axis_data_tlast]
  connect_bd_net -net hann_win_applayer_0_m_axis_tvalid [get_bd_pins hann_win_applayer_0/m_axis_tvalid] [get_bd_pins rfft1/s_axis_data_tvalid]
  connect_bd_net -net hann_win_applayer_1_m_axis_tdata [get_bd_pins hann_win_applayer_1/m_axis_tdata] [get_bd_pins rfft2/s_axis_tdata]
  connect_bd_net -net hann_win_applayer_1_m_axis_tlast [get_bd_pins hann_win_applayer_1/m_axis_tlast] [get_bd_pins rfft2/s_axis_data_tlast]
  connect_bd_net -net hann_win_applayer_1_m_axis_tvalid [get_bd_pins hann_win_applayer_1/m_axis_tvalid] [get_bd_pins rfft2/s_axis_data_tvalid]
  connect_bd_net -net hann_win_applayer_1_s_axis_tready [get_bd_pins frame_extractor_0/m_axis_tready] [get_bd_pins hann_win_applayer_1/s_axis_tready]
  connect_bd_net -net m_axis_tready_1 [get_bd_pins cascade_biquad_v2_axis/m_axis_tready] [get_bd_pins hann_win_applayer_0/s_axis_tready]
  connect_bd_net -net rfft1_rfft_out [get_bd_ports rfft_out_1] [get_bd_pins rfft1/rfft_out]
  connect_bd_net -net rfft2_rfft_out [get_bd_ports rfft_out_0] [get_bd_pins rfft2/rfft_out]
  connect_bd_net -net sim_clk_gen_0_clk [get_bd_pins adc_sim_0/aclk] [get_bd_pins axis_counter_debug_0/clk] [get_bd_pins cascade_biquad_v2_axis/aclk] [get_bd_pins frame_extractor_0/aclk] [get_bd_pins hann_win_applayer_0/aclk] [get_bd_pins hann_win_applayer_1/aclk] [get_bd_pins rfft1/aclk] [get_bd_pins rfft2/aclk] [get_bd_pins sim_clk_gen_0/clk]
  connect_bd_net -net sim_clk_gen_0_sync_rst [get_bd_pins adc_sim_0/areset] [get_bd_pins axis_counter_debug_0/resetn] [get_bd_pins cascade_biquad_v2_axis/areset] [get_bd_pins frame_extractor_0/resetn] [get_bd_pins hann_win_applayer_0/resetn] [get_bd_pins hann_win_applayer_1/resetn] [get_bd_pins rfft1/aresetn] [get_bd_pins rfft2/aresetn] [get_bd_pins sim_clk_gen_0/sync_rst]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


