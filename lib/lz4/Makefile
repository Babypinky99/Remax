ccflags-y += -DLZ4_FREESTANDING=1 \
             -DLZ4_FAST_DEC_LOOP=1
ccflags-y += -mllvm -inline-threshold=15000
ccflags-y += -mllvm -inlinehint-threshold=10000

obj-y += lz4.o

obj-$(CONFIG_ARM64) += $(addprefix lz4armv8/, lz4accel.o lz4armv8.o)
