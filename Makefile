ifeq ($(OS),Windows_NT)
ifneq ("$(wildcard C:/msys64/ucrt64/bin/gfortran.exe)","")
FC = C:/msys64/ucrt64/bin/gfortran.exe
else
FC = gfortran
endif
else
FC = gfortran
endif

SRC := src/beacon_modern.f90
INC_DIR := src
BIN_DIR := bin
TARGET_NAME := beacon

ifeq ($(OS),Windows_NT)
EXEEXT := .exe
MKDIR_CMD := if not exist "$(BIN_DIR)" mkdir "$(BIN_DIR)"
CLEAN_CMD := if exist "$(BIN_DIR)\\beacon.exe" del /Q /F "$(BIN_DIR)\\beacon.exe" & if exist "$(BIN_DIR)\\beacon" del /Q /F "$(BIN_DIR)\\beacon"
else
EXEEXT :=
MKDIR_CMD := mkdir -p "$(BIN_DIR)"
CLEAN_CMD := rm -f "$(BIN_DIR)/beacon" "$(BIN_DIR)/beacon.exe"
endif

TARGET := $(BIN_DIR)/$(TARGET_NAME)$(EXEEXT)

OMP_FLAG ?= -fopenmp
LAPACK_LIBS ?= -llapack -lblas

FFLAGS ?= -std=legacy -Wall -O2 -ffree-form -ffree-line-length-none $(OMP_FLAG)
LDFLAGS ?=
LDLIBS ?= $(OMP_FLAG) $(LAPACK_LIBS)

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRC) | $(BIN_DIR)
	$(FC) $(FFLAGS) $< -I$(INC_DIR) -o $@ $(LDFLAGS) $(LDLIBS)

$(BIN_DIR):
	@$(MKDIR_CMD)

clean:
	@$(CLEAN_CMD)
