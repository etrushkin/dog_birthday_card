
## General Flags
PROJECT = birthday_card
MCU = attiny45
TARGET = $(PROJECT).elf
CC = avr-gcc

## Include Directories
AVR_GCC_PATH = $(shell dirname `which avr-gcc`)
INCLUDES = -I$(AVR_GCC_PATH)/../avr/include

#CPP = avr-g++

## Options common to compile, link and assembly rules
COMMON = -mmcu=$(MCU)

## Compile options common for all C compilation units.
CFLAGS = $(COMMON)
CFLAGS += -Wall -gdwarf-2 -std=gnu99
CFLAGS += -MD -MP -MT $(*F).o -MF $(@F).d
CFLAGS += -Winline -Wdisabled-optimization -Wignored-qualifiers -Wswitch-default -Wswitch -Wcast-align -Wstrict-prototypes -Wdouble-promotion -Wfloat-equal

#Debug flags
DEBUG_CFLAGS = -D__AVR_ATtiny45__ -O0
#Release flags
RELEASE_CFLAGS = -Os

## Assembly specific flags
ASMFLAGS = $(COMMON)
ASMFLAGS += $(CFLAGS)
ASMFLAGS += -Wa,-gdwarf2

## Linker flags
LDFLAGS = $(COMMON)
#LDFLAGS += -Wl,-u,vfprintf $(BUILD_NUMBER_LDFLAGS) -Wl,-Map=lep.map
LDFLAGS += -Wl,-u -Wl,-Map=$(PROJECT).map

## Intel Hex file production flags
HEX_FLASH_FLAGS = -R .eeprom -R .fuse -R .lock -R .signature

HEX_EEPROM_FLAGS = -j .eeprom
HEX_EEPROM_FLAGS += --set-section-flags=.eeprom="alloc,load"
HEX_EEPROM_FLAGS += --change-section-lma .eeprom=0 --no-change-warnings


## Libraries
LIBS = -lc

## Objects that must be built in order to link
OBJECTS = main.o

## Objects explicitly added by the user
LINKONLYOBJECTS =

## Build

all: CFLAGS += $(RELEASE_CFLAGS)
all: internal_all

internal_all: $(TARGET) $(PROJECT).hex $(PROJECT).eep $(PROJECT).lss size #post-build

debug: CFLAGS += $(DEBUG_CFLAGS)
debug: internal_all

## Compile

%.o: %.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

##Link
$(TARGET): $(OBJECTS)
	 $(CC) $(LDFLAGS) $(OBJECTS) $(LINKONLYOBJECTS) $(LIBDIRS) $(LIBS) -o $(TARGET)

%.hex: $(TARGET)
	avr-objcopy -O ihex $(HEX_FLASH_FLAGS)  $< $@

%.eep: $(TARGET)
	-avr-objcopy $(HEX_EEPROM_FLAGS) -O ihex $< $@ || exit 0

%.lss: $(TARGET)
	avr-objdump -h -S $< > $@

size: ${TARGET}
	@echo
	@avr-size -C --mcu=${MCU} ${TARGET}

## Clean target
clean:
	-rm -rf $(OBJECTS) *.o.d $(PROJECT).elf $(PROJECT).hex $(PROJECT).eep $(PROJECT).lss $(PROJECT).map

## Burn flash with debugwire
burn: $(PROJECT).hex
	avrdude -p t45 -c jtag2dw -P usb -v -U flash:w:$(PROJECT).hex:i -D -E noreset

## Burn flash with debugwire (reset enabled)
burn_res: $(PROJECT).hex
		avrdude -p t45 -c jtag2dw -P usb -v -U flash:w:$(PROJECT).hex:i -D

## Burn EEPROM with debugwire 
burn_eeprom: $(PROJECT).eep
	avrdude -p t45 -c jtag2dw -P usb -v -U eeprom:w:$(PROJECT).eep:i -D -E noreset

## Burn fuses via ISP interface to enable debugwire
fuse:
	avrdude -p t45 -c jtag2isp -P usb -v -U hfuse:w:0x9f:m

#tiny_flash.bin: tiny_flash.elf
#	@echo 'Create Flash image (ihex format)'
#	-avr-objcopy -R .eeprom -R .fuse -R .lock -R .signature -O binary tiny_flash.elf  "tiny_flash.bin"
#	@echo 'Finished building: $@'
#	@echo ' '

#post-build: tiny_flash.bin
#	-@echo 'creating binary,adding zeroes and copy binary to defined folder'
#	-avr-objcopy -O binary -R .eeprom -R .nwram  tiny_flash.elf tiny_flash.bin && python add_zeroes.py tiny_flash.bin #tiny_flash.bin && cp -f tiny_flash.bin ./export/
#	-@echo ' '
