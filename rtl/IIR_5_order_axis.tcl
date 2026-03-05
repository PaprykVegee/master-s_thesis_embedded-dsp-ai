
################################################################
# This is a generated script based on design: IIR_5_order_axis
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
# source IIR_5_order_axis_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# biquad_axi, biquad_axi, biquad_axi, biquad_axi, biquad_axi

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
set design_name IIR_5_order_axis

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
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
biquad_axi\
biquad_axi\
biquad_axi\
biquad_axi\
biquad_axi\
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
  set aclk [ create_bd_port -dir I -type clk aclk ]
  set m_axis_tdata [ create_bd_port -dir O -from 15 -to 0 m_axis_tdata ]
  set m_axis_tlast [ create_bd_port -dir O m_axis_tlast ]
  set m_axis_tready [ create_bd_port -dir I m_axis_tready ]
  set m_axis_tvalid [ create_bd_port -dir O m_axis_tvalid ]
  set resetn [ create_bd_port -dir I -type rst resetn ]
  set s_axis_tdata [ create_bd_port -dir I -from 15 -to 0 s_axis_tdata ]
  set s_axis_tlast [ create_bd_port -dir I s_axis_tlast ]
  set s_axis_tready [ create_bd_port -dir O s_axis_tready ]
  set s_axis_tvalid [ create_bd_port -dir I s_axis_tvalid ]

  # Create instance: biquad_axi_0, and set properties
  set block_name biquad_axi
  set block_cell_name biquad_axi_0
  if { [catch {set biquad_axi_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $biquad_axi_0 eq "" } {
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
    CONFIG.internal_decimal_width {30} \
  ] $biquad_axi_0


  # Create instance: biquad_axi_1, and set properties
  set block_name biquad_axi
  set block_cell_name biquad_axi_1
  if { [catch {set biquad_axi_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $biquad_axi_1 eq "" } {
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
    CONFIG.coefficient_width {19} \
    CONFIG.internal_decimal_width {20} \
    CONFIG.internal_width {22} \
  ] $biquad_axi_1


  # Create instance: biquad_axi_2, and set properties
  set block_name biquad_axi
  set block_cell_name biquad_axi_2
  if { [catch {set biquad_axi_2 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $biquad_axi_2 eq "" } {
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
  ] $biquad_axi_2


  # Create instance: biquad_axi_3, and set properties
  set block_name biquad_axi
  set block_cell_name biquad_axi_3
  if { [catch {set biquad_axi_3 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $biquad_axi_3 eq "" } {
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
  ] $biquad_axi_3


  # Create instance: biquad_axi_4, and set properties
  set block_name biquad_axi
  set block_cell_name biquad_axi_4
  if { [catch {set biquad_axi_4 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $biquad_axi_4 eq "" } {
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
  ] $biquad_axi_4


  # Create port connections
  connect_bd_net -net aclk_0_1 [get_bd_ports aclk] [get_bd_pins biquad_axi_0/aclk] [get_bd_pins biquad_axi_1/aclk] [get_bd_pins biquad_axi_2/aclk] [get_bd_pins biquad_axi_3/aclk] [get_bd_pins biquad_axi_4/aclk]
  connect_bd_net -net biquad_axi_0_m_axis_tdata [get_bd_pins biquad_axi_0/m_axis_tdata] [get_bd_pins biquad_axi_1/s_axis_tdata]
  connect_bd_net -net biquad_axi_0_m_axis_tlast [get_bd_pins biquad_axi_0/m_axis_tlast] [get_bd_pins biquad_axi_1/s_axis_tlast]
  connect_bd_net -net biquad_axi_0_m_axis_tvalid [get_bd_pins biquad_axi_0/m_axis_tvalid] [get_bd_pins biquad_axi_1/s_axis_tvalid]
  connect_bd_net -net biquad_axi_0_s_axis_tready [get_bd_ports s_axis_tready] [get_bd_pins biquad_axi_0/s_axis_tready]
  connect_bd_net -net biquad_axi_1_m_axis_tdata [get_bd_pins biquad_axi_1/m_axis_tdata] [get_bd_pins biquad_axi_2/s_axis_tdata]
  connect_bd_net -net biquad_axi_1_m_axis_tlast [get_bd_pins biquad_axi_1/m_axis_tlast] [get_bd_pins biquad_axi_2/s_axis_tlast]
  connect_bd_net -net biquad_axi_1_m_axis_tvalid [get_bd_pins biquad_axi_1/m_axis_tvalid] [get_bd_pins biquad_axi_2/s_axis_tvalid]
  connect_bd_net -net biquad_axi_1_s_axis_tready [get_bd_pins biquad_axi_0/m_axis_tready] [get_bd_pins biquad_axi_1/s_axis_tready]
  connect_bd_net -net biquad_axi_2_m_axis_tdata [get_bd_pins biquad_axi_2/m_axis_tdata] [get_bd_pins biquad_axi_3/s_axis_tdata]
  connect_bd_net -net biquad_axi_2_m_axis_tlast [get_bd_pins biquad_axi_2/m_axis_tlast] [get_bd_pins biquad_axi_3/s_axis_tlast]
  connect_bd_net -net biquad_axi_2_m_axis_tvalid [get_bd_pins biquad_axi_2/m_axis_tvalid] [get_bd_pins biquad_axi_3/s_axis_tvalid]
  connect_bd_net -net biquad_axi_2_s_axis_tready [get_bd_pins biquad_axi_1/m_axis_tready] [get_bd_pins biquad_axi_2/s_axis_tready]
  connect_bd_net -net biquad_axi_3_m_axis_tdata [get_bd_pins biquad_axi_3/m_axis_tdata] [get_bd_pins biquad_axi_4/s_axis_tdata]
  connect_bd_net -net biquad_axi_3_m_axis_tlast [get_bd_pins biquad_axi_3/m_axis_tlast] [get_bd_pins biquad_axi_4/s_axis_tlast]
  connect_bd_net -net biquad_axi_3_m_axis_tvalid [get_bd_pins biquad_axi_3/m_axis_tvalid] [get_bd_pins biquad_axi_4/s_axis_tvalid]
  connect_bd_net -net biquad_axi_3_s_axis_tready [get_bd_pins biquad_axi_2/m_axis_tready] [get_bd_pins biquad_axi_3/s_axis_tready]
  connect_bd_net -net biquad_axi_4_m_axis_tdata [get_bd_ports m_axis_tdata] [get_bd_pins biquad_axi_4/m_axis_tdata]
  connect_bd_net -net biquad_axi_4_m_axis_tlast [get_bd_ports m_axis_tlast] [get_bd_pins biquad_axi_4/m_axis_tlast]
  connect_bd_net -net biquad_axi_4_m_axis_tvalid [get_bd_ports m_axis_tvalid] [get_bd_pins biquad_axi_4/m_axis_tvalid]
  connect_bd_net -net biquad_axi_4_s_axis_tready [get_bd_pins biquad_axi_3/m_axis_tready] [get_bd_pins biquad_axi_4/s_axis_tready]
  connect_bd_net -net m_axis_tready_0_1 [get_bd_ports m_axis_tready] [get_bd_pins biquad_axi_4/m_axis_tready]
  connect_bd_net -net resetn_0_1 [get_bd_ports resetn] [get_bd_pins biquad_axi_0/resetn] [get_bd_pins biquad_axi_1/resetn] [get_bd_pins biquad_axi_2/resetn] [get_bd_pins biquad_axi_3/resetn] [get_bd_pins biquad_axi_4/resetn]
  connect_bd_net -net s_axis_tdata_0_1 [get_bd_ports s_axis_tdata] [get_bd_pins biquad_axi_0/s_axis_tdata]
  connect_bd_net -net s_axis_tlast_0_1 [get_bd_ports s_axis_tlast] [get_bd_pins biquad_axi_0/s_axis_tlast]
  connect_bd_net -net s_axis_tvalid_0_1 [get_bd_ports s_axis_tvalid] [get_bd_pins biquad_axi_0/s_axis_tvalid]

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


