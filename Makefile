# SPDX-License-Identifier: CC0-1.0
#
# SPDX-FileContributor: Antonio Niño Díaz, 2023-2025
# Modified for standalone Windows build (.exe)

# Source code paths
# -----------------
SOURCEDIRS	:= source
INCLUDEDIRS	:= source

# Version string handling
# -----------------------
ifeq ($(VERSION_STRING),)
    VERSION_STRING	:= $(shell git describe --tags --exact-match --dirty 2>/dev/null)
    ifeq ($(VERSION_STRING),)
        VERSION_STRING	:= $(shell git describe --tags --dirty 2>/dev/null)
        ifeq ($(VERSION_STRING),)
            VERSION_STRING	:= DEV
        endif
    endif
endif

DEFINES		:= -DVERSION_STRING=\"$(VERSION_STRING)\"

# Build artifacts
# ---------------
NAME		:= ndstool
BUILDDIR	:= build

# 운영체제별 확장자 및 정적 링크 설정 자동화
ifeq ($(OS),Windows_NT)
    ELF := $(NAME).exe
    LDFLAGS += -static
else
    ELF := $(NAME)
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        LDFLAGS += -static
    endif

endif

# Verbose flag
# ------------
ifeq ($(VERBOSE),1)
V		:=
else
V		:= @
endif

# Source files
# ------------
SOURCES_C	:= $(shell find -L $(SOURCEDIRS) -name "*.c")
SOURCES_CPP	:= $(shell find -L $(SOURCEDIRS) -name "*.cpp")

# Compiler and linker flags
# -------------------------
WARNFLAGS_C		:= -Wall -Wextra -Wpedantic -Wstrict-prototypes
WARNFLAGS_CXX	:= -Wall -Wextra

ifeq ($(SOURCES_CPP),)
    HOSTLD	:= $(HOSTCC)
else
    HOSTLD	:= $(HOSTCXX)
endif

INCLUDEFLAGS	:= $(foreach path,$(INCLUDEDIRS),-I$(path))

CFLAGS		+= $(WARNFLAGS_C) $(DEFINES) $(INCLUDEFLAGS) -O3
CXXFLAGS	+= $(WARNFLAGS_CXX) $(DEFINES) $(INCLUDEFLAGS) -O3

LDFLAGS		+= -static

# Intermediate build files
# ------------------------
OBJS		:= $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_C))) \
		   $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_CPP)))

DEPS		:= $(OBJS:.o=.d)

# Targets
# -------
.PHONY: all clean

all: $(ELF)

$(ELF): $(OBJS)
	@echo "  HOSTLD  $@"
	$(V)$(HOSTLD) -o $@ $(OBJS) $(LDFLAGS)

clean:
	@echo "  CLEAN  "
	$(V)$(RM) $(ELF) $(BUILDDIR)

# Rules
# -----
$(BUILDDIR)/%.c.o : %.c
	@echo "  HOSTCC  $<"
	@$(MKDIR) -p $(@D)
	$(V)$(HOSTCC) $(CFLAGS) -MMD -MP -c -o $@ $<

$(BUILDDIR)/%.cpp.o : %.cpp
	@echo "  HOSTCXX $<"
	@$(MKDIR) -p $(@D)
	$(V)$(HOSTCXX) $(CXXFLAGS) -MMD -MP -c -o $@ $<

# Include dependency files if they exist
# --------------------------------------
-include $(DEPS)