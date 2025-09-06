# Optional programming step
ifeq ($(PROGRAM),1)
	PROGRAM_CMD = minipro -p AT28C256 -w $(OUT)
endif

register_shift: OUT=./bin/register_right_shift.out
register_shift:
	./vasm6502_oldstyle -Fbin -dotdir ./src/register_right_shift.asm -o $(OUT)
	$(PROGRAM_CMD)

hello_world_no_ram: OUT=./bin/hello_world_no_ram.out
hello_world_no_ram:
	./vasm6502_oldstyle -Fbin -dotdir ./src/led_hello_world_no_ram.asm -o $(OUT)
	$(PROGRAM_CMD)

hello_world: OUT=./bin/hello_world.out
hello_world:
	./vasm6502_oldstyle -Fbin -dotdir ./src/led_hello_world.asm -o $(OUT)
	$(PROGRAM_CMD)

hello_world_1MHz: OUT=./bin/hello_world_1MHz.out
hello_world_1MHz:
	./vasm6502_oldstyle -Fbin -dotdir ./src/hello_world_1MHz.asm -o $(OUT)
	$(PROGRAM_CMD)

decimal_converter: OUT=./bin/decimal_converter.out
decimal_converter:
	./vasm6502_oldstyle -Fbin -dotdir ./src/decimal_converter.asm -o $(OUT)
	$(PROGRAM_CMD)

interupt_handler: OUT=./bin/interupt_handler.out
interupt_handler:
	./vasm6502_oldstyle -Fbin -dotdir ./src/interupt_handler.asm -o $(OUT)
	$(PROGRAM_CMD)

serial_port: OUT=./bin/serial_port.out
serial_port:
	./vasm6502_oldstyle -Fbin -dotdir -wdc02 ./src/serial_port.asm -o $(OUT)
	$(PROGRAM_CMD)

serial_console: OUT=./bin/serial_console/console.out
serial_console:
	./vasm6502_oldstyle -Fbin -dotdir -wdc02 ./src/serial_console/console.asm -o $(OUT)
	$(PROGRAM_CMD)
