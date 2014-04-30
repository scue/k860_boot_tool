# 联想K860/i Boot Tool

联想Lephone K860/K860i boot.img recovery.img 解压与打包工具

# 脚本使用

*   **解压操作：**

    +   在工作目录中需要存在 boot.img

    使用举例：

        ./k860_boot_test.sh unpack


*   **打包操作：**

    +   在工作目录中需要存在 root/ 目录
    +   假如有联想K860/K860i连接时，会自动刷入新的boot.img至手机

    使用举例：

        ./k860_boot_test.sh repack

# 效果展示

*   **帮助信息：**

![unpack](https://raw.githubusercontent.com/scue/k860_boot_tool/shots/shots/help.png)

*   **解压操作：**

![unpack](https://raw.githubusercontent.com/scue/k860_boot_tool/shots/shots/unpack.png)

*   **打包操作：**

![repack](https://raw.githubusercontent.com/scue/k860_boot_tool/shots/shots/repack.png)
