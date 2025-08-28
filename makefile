register_shift: OUT=./bin/register_right_shift.out
register_shift:
	./vasm6502_oldstyle -Fbin -dotdir ./src/register_right_shift.asm -o $(OUT)

hello_world_no_ram: OUT=./bin/hello_world_no_ram.out
hello_world_no_ram:
	./vasm6502_oldstyle -Fbin -dotdir ./src/led_hello_world_no_ram.asm -o $(OUT)

hello_world: OUT=./bin/hello_world.out
hello_world:
	./vasm6502_oldstyle -Fbin -dotdir ./src/led_hello_world.asm -o $(OUT)

hello_world_1MHz: OUT=./bin/hello_world_1MHz.out
hello_world_1MHz:
	./vasm6502_oldstyle -Fbin -dotdir ./src/hello_world_1MHz.asm -o $(OUT)

ifeq ($(PROGRAM),1)
	minipro -p AT28C256 -w $(OUT)
endif
