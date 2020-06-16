###############################################################################
####################Project STM32F103##################
##################### Thang HUST#####################
THISDIR:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))

BUILD_BASE  = build
FW_BASE = firmware
DEFS		+= -DSTM32F1

###################Target#############################
TARGET = stm32_test
###################include library####################
MODULES   = uart source
EXTRA_INCDIR    =  
INCLUDE := $(addprefix -I./,$(MODULES))
##############Check Operating System ##################

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S), Linux)
	OPENCM3_DIR ?= /opt/libopencm3
	#CC_PATH		?= /opt/gcc-arm/bin
endif

###############################################################################
# OPENCM3 define
#
OPENCM3_LIBS = lib
OPENCM3_INC  = include
OPENCM3_LD   = lib
##################### LD SCRIPT ##############################

LDDIR = $(THISDIR)/ld
LDSCRIPT = $(LDDIR)/stm32f103c8t6.ld

LD_SCRIPT = -T $(LDSCRIPT)
FLAVOR ?= release

###############################################################################
#Check openocd install global
ISOCD_EXIST := $(shell command -v openocd 2> /dev/null)
ifndef ISOCD_EXIST
	OPENOCD    = 0
else
	OPENOCD    = openocd
	OPENOCD_DIR = /usr/share/openocd
endif
##############Check Libopencm3##########################
OPENCM3_EXIST = 0
ifneq ("$(wildcard $(OPENCM3_DIR))","")
	OPENCM3_EXIST = 1
endif

ifneq ("$(wildcard vendor/libopencm3)","")
	OPENCM3_EXIST = 1
	OPENCM3_DIR = $(THISDIR)/vendor/libopencm3
endif
###############################################################################

PREFIX		?= arm-none-eabi

LIBNAME		= opencm3_stm32f1
DEFS		+= -DSTM32F1

FP_FLAGS	?= -msoft-float
ARCH_FLAGS	= -mthumb -mcpu=cortex-m3 $(FP_FLAGS) -mfix-cortex-m3-ldrd
ASFLAGS		= -mthumb -mcpu=cortex-m3

# libraries used in this project
LIBS    = opencm3_stm32f1 c gcc nosys m

CC		:= $(PREFIX)-gcc
CXX		:= $(PREFIX)-g++
LD		:= $(PREFIX)-gcc
AR		:= $(PREFIX)-ar
AS		:= $(PREFIX)-as
OBJCOPY		:= $(PREFIX)-objcopy
SIZE		:= $(PREFIX)-size
OBJDUMP		:= $(PREFIX)-objdump
GDB		:= $(PREFIX)-gdb
############################################################################
STFLASH		= $(shell which st-flash)
###############################################################################
OPT		:= -O0 -g
CSTD		?= -std=c99

#######  C flags #############################
CFLAGS    += $(OPT) $(CSTD)
CFLAGS    += $(ARCH_FLAGS)
CFLAGS    += -Wextra -Wshadow -Wimplicit-function-declaration
CFLAGS    += -Wredundant-decls -Wmissing-prototypes -Wstrict-prototypes
CFLAGS    += -fno-common -ffunction-sections -fdata-sections
CFLAGS    += -I$(OPENCM3_DIR)/include
CFLAGS    += $(DEFS)
CFLAGS    += $(INCLUDE)

###############################################################################
#######  C++ Flas ###########################
CXXFLAGS	+= $(OPT) $(CXXSTD)
CXXFLAGS	+= $(ARCH_FLAGS)
CXXFLAGS	+= -Wextra -Wshadow -Wredundant-decls  -Weffc++
CXXFLAGS	+= -fno-common -ffunction-sections -fdata-sections
###############################################################################
# C & C++ preprocessor common flags
CPPFLAGS	+= -MD
CPPFLAGS	+= -Wall -Wundef
CPPFLAGS	+= $(DEFS)
CPPFLAGS	+= -I$(OPENCM3_DIR)/include
#CPPFLAGS    += -I./source -I./uart
CPPFLAGS    += $(INCLUDE)
###############################################################################
# Linker flags
LDFLAGS	+= --static -nostartfiles
LDFLAGS	+= -T$(LDSCRIPT)
LDFLAGS	+= $(ARCH_FLAGS)
LDFLAGS	+= -Wl,-Map=$(*).map
LDFLAGS	+= -Wl,--gc-sections

LDLIBS		+= -specs=nosys.specs
LDLIBS		+= -Wl,--start-group -lc -lgcc -lnosys -Wl,--end-group
#LDLIBS		+= -L$(TOP_DIR)/rtos/libwwg -lwwg
LDLIBS		+= -L$(OPENCM3_DIR)/lib -lopencm3_stm32f1

###############################################################################
SRC_DIR   := $(MODULES)
BUILD_DIR := $(addprefix $(BUILD_BASE)/,$(MODULES))

OPENCM3_LIBDIR  := $(addprefix $(OPENCM3_DIR)/,$(OPENCM3_LIBS))
OPENCM3_INCDIR  := $(addprefix -I$(OPENCM3_DIR)/,$(OPENCM3_INC))
OPENCM3_LDDIR   := $(addprefix -L$(OPENCM3_DIR)/,$(OPENCM3_LD))
# Inclusion of library header files

SRC   := $(foreach sdir,$(SRC_DIR),$(wildcard $(sdir)/*.c))
OBJ   := $(patsubst %.c,$(BUILD_BASE)/%.o,$(SRC))

LIBS    	:= $(addprefix -l,$(LIBS))
HEX_OUT   	:= $(addprefix $(FW_BASE)/,$(TARGET).hex)
BIN_OUT		:= $(addprefix $(FW_BASE)/,$(TARGET).bin)
MAP_OUT		:= $(addprefix $(BUILD_BASE)/,$(TARGET).map)

TARGET_OUT  := $(addprefix $(BUILD_BASE)/,$(TARGET).elf)

INCDIR  := $(addprefix -I.,$(SRC_DIR))
#EXTRA_INCDIR  := $(addprefix -I.,$(EXTRA_INCDIR))
#MODULE_INCDIR := $(addsuffix /include,$(INCDIR))

#######################################################################################
V ?= $(VERBOSE)
ifeq ("$(V)","1")
Q :=
vecho := @true
else
Q := @
vecho := @echo
endif

vpath %.c $(SRC_DIR)

define compile-objects
$1/%.o: %.c
	$(vecho) "CC $$< "
	$(Q) $(CC) $(INCDIR) $(MODULE_INCDIR) $(EXTRA_INCDIR) $(OPENCM3_INCDIR) $(CFLAGS) $(ARCH_FLAGS)  -c $$< -o $$@
endef

#######################################################################################

.PHONY: all checkdirs clean

all: checkdirs $(TARGET_OUT) $(HEX_OUT) $(BIN_OUT)

flash-stlink:
	$(OPENOCD) 	-s $(OPENOCD_DIR)\
			   	-f interface/stlink-v2.cfg\
				-f target/stm32f1x_stlink.cfg\
		        -c init -c targets -c "reset halt" \
		        -c "flash write_image erase $(HEX_OUT)" \
		        -c "verify_image $(HEX_OUT)" \
		        -c "reset run" -c shutdown

flash-jlink:
	$(OPENOCD) -f $(OPENOCD_DIR)/scripts
	-c "adapter_khz 1000" \
	-f interface/jlink.cfg \
	-c "transport select swd" \
	-f target/stm32f1x.cfg \
	-c "program $(HEX_OUT) verify reset exit"
flash:	$(BIN_OUT)
	$(STFLASH) $(FLASHSIZE) write $(BIN_OUT) 0x8000000

debug:
	$(OPENOCD) -f $(OPENOCD_DIR)/scripts/interface/stlink-v2.cfg -f $(OPENOCD_DIR)/scripts/target/stm32f1x.cfg
	#-c "adapter_khz 1000" \
	#-f interface/st-linkv2.cfg \
	#-f target/stm32f1x.cfg

$(BIN_OUT): $(TARGET_OUT)
	$(vecho) "OBJCOPY $@"
	$(Q) $(OBJCOPY) -Obinary $(TARGET_OUT) $@
	$(Q) $(SIZE) $(TARGET_OUT)

$(HEX_OUT): $(TARGET_OUT)
	$(vecho) "OBJCOPY $@"
	$(Q) $(OBJCOPY) -Oihex $(TARGET_OUT) $@
	$(Q) $(SIZE) $(TARGET_OUT)

$(TARGET_OUT) $(MAP_OUT): $(OBJ)
	$(vecho) "LD $@"
	$(Q) $(LD) $(OPENCM3_LDDIR) $(LDFLAGS) $(ARCH_FLAGS) $(OBJ) -Wl,--start-group $(LIBS) -Wl,--end-group -o $@
	
	
checkdirs: $(BUILD_DIR) $(FW_BASE) checkcm3

$(BUILD_DIR):
	$(Q) mkdir -p $@
$(FW_BASE):
	$(Q) mkdir -p $@

checkcm3:
ifeq ($(OPENCM3_EXIST), 0)
	@git clone https://github.com/libopencm3/libopencm3.git vendor/libopencm3\
	&& cd vendor/libopencm3 && make && cd ../../
endif

fast: clean all flash-jlink

rebuild: clean all
clean:
	$(Q) rm -rf $(BUILD_DIR)
	$(Q) rm -rf $(BUILD_BASE)
	$(Q) rm -rf $(FW_BASE)
	rm -f *.map 


$(foreach bdir,$(BUILD_DIR),$(eval $(call compile-objects,$(bdir))))



	