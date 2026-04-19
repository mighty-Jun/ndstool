# SPDX-License-Identifier: CC0-1.0
# Modified for standalone cross-platform build

SOURCEDIRS	:= source
INCLUDEDIRS	:= source

# Version string handling
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

NAME		:= ndstool
BUILDDIR	:= build

# OS detection and linker flags
ifeq ($(OS),Windows_NT)
    ELF := $(NAME).exe
    LDFLAGS += -static
else
    ELF := $(NAME)
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        LDFLAGS += -static-libgcc -static-libstdc++
    endif
endif

ifeq ($(VERBOSE),1)
V		:=
else
V		:= @
endif

SOURCES_C	:= $(shell find -L $(SOURCEDIRS) -name "*.c")
SOURCES_CPP	:= $(shell find -L $(SOURCEDIRS) -name "*.cpp")

WARNFLAGS_C		:= -Wall -Wextra -Wpedantic -Wstrict-prototypes
WARNFLAGS_CXX	:= -Wall -Wextra

INCLUDEFLAGS	:= $(foreach path,$(INCLUDEDIRS),-I$(path))

CFLAGS		+= $(WARNFLAGS_C) $(DEFINES) $(INCLUDEFLAGS) -O3
CXXFLAGS	+= $(WARNFLAGS_CXX) $(DEFINES) $(INCLUDEFLAGS) -O3

OBJS		:= $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_C))) \
		   $(addsuffix .o,$(addprefix $(BUILDDIR)/,$(SOURCES_CPP)))

DEPS		:= $(OBJS:.o=.d)

.PHONY: all clean

all: $(ELF)

$(ELF): $(OBJS)
	@echo "  LINK    $@"
	$(V)g++ -o $@ $(OBJS) $(LDFLAGS)

clean:
	@echo "  CLEAN  "
	$(V)rm -rf $(ELF) $(NAME).exe $(BUILDDIR)

$(BUILDDIR)/%.c.o : %.c
	@echo "  CC      $<"
	@mkdir -p $(@D)
	$(V)gcc $(CFLAGS) -MMD -MP -c -o $@ $<

$(BUILDDIR)/%.cpp.o : %.cpp
	@echo "  CXX     $<"
	@mkdir -p $(@D)
	$(V)g++ $(CXXFLAGS) -MMD -MP -c -o $@ $<

-include $(DEPS)