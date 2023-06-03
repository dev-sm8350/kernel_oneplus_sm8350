# SPDX-License-Identifier: GPL-2.0-only
debugfs-objs	:= inode.o file.o

ifeq ($(CONFIG_DEBUG_FS),y)
obj-y += debugfs.o
else ifeq ($(CONFIG_PGO_GEN),y)
obj-y += debugfs.o
endif
