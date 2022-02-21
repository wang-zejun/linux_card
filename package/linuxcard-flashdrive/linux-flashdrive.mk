################################################################################
#
# linuxcard-flashdrive
#
################################################################################

LINUXCARD_FLASHDRIVE_SITE = $(LINUXCARD_FLASHDRIVE_PKGDIR)files
LINUXCARD_FLASHDRIVE_SITE_METHOD = local
LINUXCARD_FLASHDRIVE_LICENSE = Proprietary
LINUXCARD_FLASHDRIVE_DEPENDENCIES = host-genimage host-dosfstools host-mtools
LINUXCARD_INSTALL_IMAGES = YES
LINUXCARD_INSTALL_TARGET = NO

define LINUXCARD_FLASHDRIVE_BUILD_CMDS
	rm -rf "$(@D)/tmp"
	mkdir -p $(@D)/dummyroot
	$(HOST_DIR)/bin/genimage \
		--config $(@D)/genimage.cfg \
		--inputpath $(@D) \
		--outputpath $(@D) \
		--tmppath $(@D)/tmp \
		--rootpath $(@D)/dummyroot \
		--mcopy $(HOST_DIR)/bin/mcopy \
		--mkdosfs $(HOST_DIR)/sbin/mkdosfs

endef

define LINUXCARD_FLASHDRIVE_INSTALL_TARGET_CMDS
	mkdir -p $(BINARIES_DIR)
	cp $(@D)/flashdrive.img $(BINARIES_DIR)/flashdrive.img
endef

$(eval $(generic-package))
