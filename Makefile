.PHONY: test clean

CXXFLAGS += -Wall -std=c++17

hx-run: index.md
	@echo HX
	@which hx >/dev/null && hx || true
	@date >$@
	@make --no-print-directory test

xtx.cpp: xtx.h
	@touch xtx.cpp

xtx: xtx.cpp

test: xtx
	@echo XTX
	@./xtx
	
clean:
	@echo RM
	@rm -f xtx xtx.cpp xtx.h hx-run
