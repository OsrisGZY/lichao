#*****************************************************************************
#
# Copyright 2013 Altera Corporation. All Rights Reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
# 
# 3. Neither the name of the copyright holder nor the names of its contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# 
#*****************************************************************************

#
# $Id$
#

ALT_DEVICE_FAMILY ?= soc_cv_av

SOCEDS_ROOT ?= $(SOCEDS_DEST_ROOT)
HWLIBS_ROOT = $(SOCEDS_ROOT)/ip/altera/hps/altera_hps/hwlib

HWLIBS_SRC  := alt_16550_uart.c alt_clock_manager.c alt_interrupt.c alt_printf.c alt_cache.c alt_can.c 
EXAMPLE_SRC := hwlib.c alt_16550_buffer.c alt_16550_prompt.c echo_prompt.c launcher_prompt.c memory_prompt.c fpga_uart.c fpga_timer.c socfpga_hps_init.c SST39VF160x.c
C_SRC       := $(EXAMPLE_SRC) $(HWLIBS_SRC)

LINKER_SCRIPT := scatter.scat

# Suppress ARMCC warning 9931: "Yours License for Compiler (feature compiler5) will expire in X days"
CFLAGS   := -g -O0 --c99 --strict --diag_error=warning --diag_suppress=9931 --cpu=Cortex-A9 --no_unaligned_access -I$(HWLIBS_ROOT)/include -I$(HWLIBS_ROOT)/include/$(ALT_DEVICE_FAMILY) -D$(ALT_DEVICE_FAMILY)
ASMFLAGS := -g --diag_error=warning --diag_suppress=9931 --cpu=Cortex-A9 --no_unaligned_access
LDFLAGS  := --strict --diag_error=warning --diag_suppress=9931 --entry=alt_interrupt_vector --cpu=Cortex-A9 --no_unaligned_access --scatter=$(LINKER_SCRIPT)

CROSS_COMPILE := arm-altera-eabi-
CC := armcc
AS := armasm
LD := armlink
AR := armar
NM := $(CROSS_COMPILE)nm
OD := $(CROSS_COMPILE)objdump
OC := $(CROSS_COMPILE)objcopy

RM := rm -rf
CP := cp -f

ELF ?= $(basename $(firstword $(C_SRC))).axf
SPL := u-boot-spl.axf
OBJ := $(patsubst %.c,%.o,$(C_SRC))

.PHONY: all
all: $(ELF) #$(SPL)

.PHONY: clean
clean:
	$(RM) $(ELF) $(SPL) $(OBJ) *.objdump *.map $(HWLIBS_SRC) alt_interrupt_armcc.*

define SET_HWLIBS_DEPENDENCIES
$(1): $(2)
	$(CP) $(2) $(1)
endef

ALL_HWLIBS_SRC = $(wildcard $(HWLIBS_ROOT)/src/hwmgr/*.c) $(wildcard $(HWLIBS_ROOT)/src/hwmgr/$(ALT_DEVICE_FAMILY)/*.c) $(wildcard $(HWLIBS_ROOT)/src/utils/*.c)

$(foreach file,$(ALL_HWLIBS_SRC),$(eval $(call SET_HWLIBS_DEPENDENCIES,$(notdir $(file)),$(file))))

alt_interrupt_armcc.s: $(HWLIBS_ROOT)/src/hwmgr/alt_interrupt_armcc.s
	$(CP) $< $@

$(OBJ): %.o: %.c Makefile
	$(CC) $(CFLAGS) -c $< -o $@

alt_interrupt_armcc.o: alt_interrupt_armcc.s
	$(AS) $(ASMFLAGS) $<

$(ELF): $(OBJ) $(LINKER_SCRIPT) alt_interrupt_armcc.o
	$(LD) $(LDFLAGS) $(OBJ) alt_interrupt_armcc.o -o $@
	$(OD) -d $@ > $@.objdump
	$(NM) $@ > $@.map

$(SPL):E:/EDA_Intel/EDA_16_CV/DEMO_RTL/FPGA_RL/software/spl_bsp/uboot-socfpga/spl/u-boot-spl
	$(CP) $< $@
	$(OD) -d $@ > $@.objdump
