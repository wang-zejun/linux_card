# linux_card 制作过程

## 正文开始

## 起因
无意间在网上看到一篇20元打造linux名片的文章，感觉非常有意思于是决定制作一个。
 [作者博客Bolg](https://www.thirtythreeforty.net/posts/2019/12/my-business-card-runs-linux/#source-code)
## 分区规划
| 分区序号 |  分区大小   |  分区内容  | 地址空间及分区名 |
| ------- | ---------- | ---------- | ---------------|
| mtd0 | 1MB(0X100000) | spl+uboot | 0x0000000-0x0100000 : “u-boot” |
| mtd1 | 8MB(0X800000) | spl+uboot | 0x0100000-0x0900000 : “rootfs” |
| mtd2 | 2MB(0X200000) | spl+uboot | 0x0900000-0x0B00000 : “flash” |
| mtd3 | 5MB(0X500000) | spl+uboot | 0x0B00000-0x0FFFFFF : “rootubi” |

### ubi分区在MTD3上,构成如下

| 分区序号 |  分区内容  | 分区名 |
| ------- | ---------- |  -----|
| ubi0:0 | kernel | zImage |
| ubi0:1 | dtb | linuxcard.dtb |
| ubi0:2 | persist | persist.ubifs |

## 项目地址

### 仓库地址
<https://github.com/wang-zejun/linux_card.git>

    使用时只需要克隆项目即可 git clone https://github.com/wang-zejun/linu_card.git

### 子模块初始化:

    git submodule update --init

### 切换到 Buildroot 目录:

    cd buildroot

### 初始化配置，包括 defconfig 和外部目录:

    make BR2_EXTERNAL=$PWD/../ linuxcard_defconfig

### 编译：

    make

这可能需要几个小时才能从头开始，具体取决于您机器的速度。

### 烧写

    sudo sunxi-fel -p spiflash-write 0 output/images/flash.bin

## u-boot介绍

    进入uboot参数配置界面
    make uboot-menuconfig 

对应 `CONFIG_BOOTCMD` 的宏定义
选中 

    [*] Enable a default value for bootcmd
        CONFIG_BOOTCOMMAND="setenv bootargs console=ttyS0,115200 earlyprintk panic=5 rootwait root=/dev/mtdblock1 rw rootfstype=jffs2 ubi.mtd=3 ubi.block=0,persist g_acm_ms.removable=1; sf probe 0 50000000; ubi part rootubi; ubi read ${kernel_addr_r} kernel; ubi read ${fdt_addr_r} dtb; bootz ${kernel_addr_r} - ${fdt_addr_r}"
    [*] MTD partition support 
        CONFIG_MTDPARTS_DEFAULT="mtdparts=spi-flash:1M(uboot),8M(rootfs),2M(flashdrive),-(rootubi)"

### 参数说明
    console=ttyS0,115200 earlyprintk panic=5 rootwait
    在串口0上输出信息，如果要用串口1做控制台就改为 console=ttyS1
    由于在kernel刚启动的过程中，还没有为串口等设备等注册console（在device probe阶段实现），此时无法通过正常的console来输出log。
    early console机制，用于实现为设备注册console之前的早期log的输出。
    earlyprintk 是基于 early console的基础上实现
    panic=5 崩溃后5秒重启.

    sf probe 0 50000000;
    初始化Flash设备（CS拉低） 50000000 是速度
    ubi part rootubi 
    rootubi是ubi
    ubi read ${kernel_addr_r} kernel; ubi read ${fdt_addr_r} dtb; bootz ${kernel_addr_r} - ${fdt_addr_r}"
    从ubi分区读取 kernel 放到内存 kernel_addr_r 偏移处。
    从ubi分区读取 dtb 放到内存 fdt_addr_r 偏移处。
    bootz ${kernel_addr_r} - ${fdt_addr_r}"
    启动内核
    kernel_addr_r （内核地址）- fdt_addr_r（dtb地址） 

    root=/dev/mtdblock1 rw rootfstype=jffs2 ubi.mtd=3 ubi.block=0,persist 
    根文件系统是mtd1；jffs2格式  root=31:01 等同于 /dev/mtdblock1 指的是mtd设备第一分区
    rw 可读可写 ubi.mtd=3 ubi分区在mtd设备的第三分区 ubi.block=0,persist 挂载ubi分区的persist分区

    mtdparts=spi-flash:1M(uboot),8M(rootfs),2M(flashdrive),-(rootubi)
    spi-flash是设备名，后面是分区大小，名字。

## linux kernel介绍

    进入linux内核配置界面
    make linux-menuconfig 

kernel配置

    File systems  --->
        [*] Miscellaneous filesystems  --->
            <*>   Journalling Flash File System v2 (JFFS2) support	# 打开jffs2的文件系统支持
            (0)     JFFS2 debugging verbosity (0 = quiet, 2 = noisy)
            [*]     JFFS2 write-buffering support
            [ ]     JFFS2 summary support
            [ ]     JFFS2 XATTR support
            [ ]     Advanced compression options for JFFS2
    Device Drivers  --->
        <*> Memory Technology Device (MTD) support  --->
            <*>   Command line partition table parsing	# 勾选，用来解析uboot传递过来的flash分区信息。（如果 bootarg 是用的我的方法一就需要勾选）
            <*>   Caching block device access to MTD devices	# 勾选，读写块设备用户模块
            <*>   SPI-NOR device support  --->
                [ ]   Use small 4096 B erase sectors	# 取消勾选，否则jffs2文件系统会报错

### 参数说明

    如果不勾选 Caching block device access to MTD devices，会卡在 Waiting for root device /dev/mtdblock3。

## Buildroot配置

    进入Buildroot配置界面
    make menuconfig 

Buildroot配置

    Target options  --->
        Target Architecture (ARM (little endian))  --->
        Target Architecture Variant (arm926t)  --->
    Toolchain  ---> 
        C library (musl)  --->
    System configuration  --->
        (gateway) System hostname	# 主机名，随便改
        (Welcome to gateway) System banner	# 欢迎语，随便改
        [*] Enable root login with password (NEW)
            (123456) Root password	# 登录密码，随便改
        [*] remount root filesystem read-write during boot (NEW)	# 重新挂载根文件系统到可读写
        [*] Install timezone info	# 安装时区信息，可选
            (asia) timezone list
            (Asia/Shanghai) default local time	
    Target packages  --->
        System tools  --->
        [*] util-linux  --->
            [*]   mount/umount	# 访问其它文件系统中的资源，如果要用overlayfs，那就要用这个挂载

** 生成 rootfs.jffs2 格式的rootfs，打开后会自动下载 mtd-utils 软件包。 **
看官方和论坛生成 rootfs.jffs2 格式的rootfs 都是自己再次打包的，其实 buildroot 可以直接选择生成这个格式的 rootfs ：

    Filesystem images  --->
        [*] jffs2 root filesystem
                Flash Type (Parallel flash with 64 kB erase size)  ---> # 具有64 kB擦除大小的并行闪存 -e 参数
            [*]   Do not use Cleanmarker	# 用于标记一个块是_完整地_被擦除了。 -n 参数 Do not use cleanmarkers if using NAND flash or Dataflash where the pagesize is not a power of 
            [*]   Pad output
                (0x800000) Pad output size (0x0 = to end of EB) 	# 指定 jffs2 分区总空间 -p（--pad） 参数
            Endianess (little-endian)  --->
            [ ]   Produce a summarized JFFS2 image (NEW)	# 生成镜像的
            [*]   Select custom virtual memory page size
            (0x100) Virtual memory page size	# 虚拟内存页大小	-s 参数

当然，要自己用命令行手动生成方法也列在下面，并做了详细注释：（要把内核模块直接打包进文件系统还是要自己动手）


    # 下载jffs2文件系统制作工具
    sudo apt-get install mtd-utils

    # 解压
    # -C 当前目录的绝对目录
    mkdir rootfs && sudo tar -xvf rootfs.tar -C ./rootfs

    # 生成 rootfs.jffs2
    # -r ：指定要做成image的目录名
    # -o : 指定输出image的文件名
    # -s ：页大小 0x100 256 字节
    # -e ：块大小 0x10000 64k
    # -p ：或--pad 参数指定 jffs2 分区总空间
    # 由此计算得到 0x1000000(16M)-0x10000(64K)-0x100000(1M)-0x400000(4M)=0xAF0000
    # -n 如果挂载后会出现类似：CLEANMARKER node found at0x0042c000 has totlen 0xc != normal 0x0  的警告，则加上-n 就会消失。
    # jffs2.img 是生成的文件系统镜像
    sudo mkfs.jffs2 -s 0x100 -e 0x10000 -p 0xAF0000 -r rootfs -o rootfs.jffs2 -n

    # 为根文件系统制作jffs2镜像包
    sudo mkfs.jffs2 -s 0x100 -e 0x10000 -p 0xAF0000 -d rootfs/ -o jffs2.img
    # 或者
    sudo mkfs.jffs2 -s 0x100 -e 0x10000 --pad=0xAF0000 -d rootfs/ -o jffs2.img

## 烧录

使用sunxi-fel烧录  
烧录单独镜像

    sudo sunxi-fel -p spiflash-write 0 ./u-boot/u-boot-sunxi-with-spl.bin   
    sudo sunxi-fel -p spiflash-write 0x0100000 ./linux/arch/arm/boot/dts/suniv-f1c100s-licheepi-nano.dtb
    sudo sunxi-fel -p spiflash-write 0x0110000 ./linux/arch/arm/boot/zImage 
    sudo sunxi-fel -p spiflash-write 0x0510000 ./buildroot-2017.08/output/images/rootfs.jffs2

烧录完整镜像
先打包成 flashimg.bin：

    # 下载jffs2文件系统制作工具
    sudo apt-get install mtd-utils

    dd if=/dev/zero of=f1c100s_spiflash_16M.bin bs=1M count=16
    dd if=u-boot/u-boot-sunxi-with-spl.bin of=f1c100s_spiflash_16M.bin bs=1K conv=notrunc
    dd if=linux/arch/arm/boot/dts/suniv-f1c100s-licheepi-nano.dtb of=f1c100s_spiflash_16M.bin bs=1K seek=384 conv=notrunc
    dd if=linux/arch/arm/boot/zImage of=f1c100s_spiflash_16M.bin bs=1K seek=400 conv=notrunc

    dd if=rootfs.img of=f1c100s_spiflash_16M.bin  bs=1K seek=4496  conv=notrunc
    dd if=jffs2.img of=f1c100s_spiflash_16M.bin bs=1K seek=9600 conv=notrunc

    mksquashfs rootfs_new/ rootfs_new.img -no-exports -no-xattrs -all-root
    mkfs.jffs2 -s 0x100 -e 0x10000 --pad=0x500000 -o jffs2.img -d overlay/

    在执行以下命令烧录：
    sudo sunxi-fel -p spiflash-write 0 flashimg.bin

## 问题解决

### 问题1：

    $ sudo sunxi-fel ver
    Warning: no 'soc_sram_info' data for your SoC (id=1663)
    AWUSBFEX soc=00001663(unknown) 00000001 ver=0001 44 08 scratchpad=00007e00 00000000 00000000
    解决：
    sunxi-tools 分支不对，用 git checkout 切换分支，具体可查看 全志sunxi-tools烧录工具安装和使用

### 问题2：

    SF: unrecognized JEDEC id bytes: 0b, 40, 18
    *** Warning - spi_flash_probe_bus_cs() failed, using default environment
    解决：
    uboot没有板上使用的FLASH支持，参考 1 楼的添加FLASH支持章节。
    识别成功后会显示：

    SF: Detected xt25f128b with page size 256 Bytes, erase size 4 KiB, total 16 MiB

### 问题3：

    spi_flash@0:50000000: failed to activate chip-select 50000000
    SF: error -2 reading JEDEC ID
    Failed to initialize SPI flash at 0:50000000 (error -2)
    No SPI flash selected. Please run `sf probe'
    No SPI flash selected. Please run `sf probe'
    解决：
    上面说了，官方文档的错误，"sf probe 0:50000000; " ，修改为 "sf probe 0 50000000; "

### 问题4：

    日志中有dts中的spiflash 分区信息打印，但仍然卡在 waiting for rootfs
    解决：
    内核配置：

    Device Drivers  --->
        <*> Memory Technology Device (MTD) support  --->
            <*>   Caching block device access to MTD devices	# 勾选，读写块设备用户模块
            [*] SPI support  --->
                < >   Allwinner A10 SoCs SPI controller   # 取消勾选
                <*>   Allwinner A31 SPI controller   # 勾选

### 问题5：

    [    1.476051] VFS: Cannot open root device "mtdblock3" or unknown-block(31,3): error -19
    [    1.484131] Please append a correct "root=" boot option; here are the available partitions:
    [    1.492542] 1f00            1024 mtdblock0 
    [    1.492554]  (driver?)
    [    1.499197] 1f01              64 mtdblock1 
    [    1.499208]  (driver?)
    [    1.505747] 1f02            4096 mtdblock2 
    [    1.505753]  (driver?)
    [    1.512349] 1f03           11200 mtdblock3 
    [    1.512358]  (driver?)
    解决：

    这个问题一般是 flash分区信息 没有正确配置导致的。

    如果 bootarg 是用的我的传参方法配置的，内核需要勾选上mtd的 <*> Command line partition table parsing 支持，该项是用来解析uboot传递过来的flash分区信息。

    没添加对jffs2文件系统的支持，需要勾选 File systems ‣ Miscellaneous filesystems ‣ Journalling Flash File System v2 (JFFS2) support

## 其他

### buildroot命令

    make show-targets            #查看安装的包

    make uboot-rebuild           #单独编译uboot
    
    make uboot-menuconfig        #uboot配置

    make uboot-savedefconfig     #保存uboot配置

    make savedefconfig           #保存buildroot配置

### uboot和linux编译命令

    make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig

    make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j4

### uboot配置备份

    # squashfs mtd分区 1   已验证可以使用
    CONFIG_BOOTCOMMAND="setenv bootargs console=ttyS0,115200 earlyprintk panic=5 rootwait root=/dev/mtdblock1 ubi.mtd=2 ubi.block=0,persist ubi.block=0,flashdrive g_acm_ms.removable=1; sf probe 0 20000000; ubi part rootubi; ubi read ${kernel_addr_r} kernel; ubi read ${fdt_addr_r} dtb; bootz ${kernel_addr_r} - ${fdt_addr_r}"


    # jffs2 mtd分区 1  已验证可以使用
    CONFIG_BOOTCOMMAND="setenv bootargs console=ttyS0,115200 earlyprintk panic=5 rootwait root=/dev/mtdblock1 rw rootfstype=jffs2 ubi.mtd=2 ubi.block=0,persist ubi.block=0,flashdrive g_acm_ms.removable=1; sf probe 0 20000000; ubi part rootubi; ubi read ${kernel_addr_r} kernel; ubi read ${fdt_addr_r} dtb; bootz ${kernel_addr_r} - ${fdt_addr_r}"


    # squashfs ubi分区 2 已验证可以使用
    CONFIG_BOOTCOMMAND="setenv bootargs console=ttyS0,115200 ubi.mtd=3 ubi.block=0,root ubi.block=0,flashdrive root=/dev/ubiblock0_2 g_acm_ms.removable=1; sf probe 0 20000000; ubi part rootubi; ubi read ${kernel_addr_r} kernel; ubi read ${fdt_addr_r} dtb; bootz ${kernel_addr_r} - ${fdt_addr_r}"


    # jffs2 ubi分区 2  已验证不能使用
    CONFIG_BOOTCOMMAND="setenv bootargs console=ttyS0,115200 ubi.mtd=3 ubi.block=0,root ubi.block=0,flashdrive root=/dev/ubiblock0_2 rw rootfstype=jffs2 g_acm_ms.removable=1; sf probe 0 20000000; ubi part rootubi; ubi read ${kernel_addr_r} kernel; ubi read ${fdt_addr_r} dtb; bootz ${kernel_addr_r} - ${fdt_addr_r}"

### 编译命令
    gcc -o hello hello.c    # 虚拟机编译
    ../../../../output/host/bin/arm-linux-gcc -o boardhello hello.c     # 根文件系统编译