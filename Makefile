obj-m := tscs454.o

SRC := $(shell pwd)

all:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC)

modules_install:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) modules_install

clean:
	rm -f *.o *~ core .depend .*.cmd *.ko *.mod.c *.dtbo
	rm -f Module.markers Module.symvers modules.order
	rm -rf .tmp_versions Modules.symvers
