# Author: Hai Cao -- cxhai.sdh221@hcmut.edu.vn
# Copyright 2024

TOP=tb_cnn_data
SEED=1

TARGET = -f ./flist

.PHONY: batch
batch:
	@echo "[*] BATCH"
	xrun -access +rwc $(TARGET) -svseed $(SEED)

.PHONY: gui
gui:
	@echo "[*] GUI"
	xrun -gui -access +rwc $(TARGET) -svseed $(SEED) -input restore.tcl

.PHONY: clean
clean:
	@echo "[*] CLEAN"
	@xrun -clean
	@rm -rf wave* xrun.* *.err *.run *.log
