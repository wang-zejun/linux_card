# Linux Card

这是一个足够小的 Linux 发行版，可以从我的 Linux 名片上的 16MB 存储空间运行。
它由 Allwinner F1C100s 提供支持，这是一款 1.40 美元的支持 Linux 的 ARM 片上系统。
此存储库是其固件映像的源代码，基于 Buildroot 2021.02.09。
该目录是“Buildroot external”，在主线 Buildroot 之上提供了一些补丁、附加包和板支持文件。


## 构建

子模块初始化:

	git submodule update --init

切换到 Buildroot 目录:

	cd buildroot

初始化配置，包括 defconfig 和外部目录:

	make BR2_EXTERNAL=$PWD/../ linuxcard_defconfig
	
编译：

	make

这可能需要几个小时才能从头开始，具体取决于您机器的速度。
## 烧写

	output/host/bin/sunxi-fel -p spiflash-write 0 output/images/flash.bin

## License

Subject to the below exceptions, code is released under the GNU General Public License, version 2 or (at your option) any later version.
See also the [Buildroot license notice][buildroot-license] for more nuances about the meaning of this license.

Patches are not covered by this license. Instead, they are covered by the license of the software to which the patches are applied.


