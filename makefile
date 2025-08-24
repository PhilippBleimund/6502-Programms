register_shift: OUT=./bin/register_right_shift.out
register_shift:
	./vasm6502_oldstyle -Fbin -dotdir ./src/register_right_shift.asm -o $(OUT)

hello_world: OUT=./bin/hello_world.out
hello_world:
	./vasm6502_oldstyle -Fbin -dotdir ./src/led_hello_world.asm -o $(OUT)

ifeq ($(PROGRAM),1)
	minipro -p AT28C256 -w $(OUT)
endif
