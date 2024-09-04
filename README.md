# Fedora-build
## build-fedora-image
脚本的可用性、编译效率，并完善日志监控和磁盘网络情况监控，我们可以进行以下改进：
引入更细粒度的日志记录，包括编译过程中的每一步。
添加磁盘使用和网络带宽监控，以确保构建过程中的资源使用在可接受范围内。
优化脚本结构，包括使用函数来组织代码，提高可读性和维护性。
提高构建效率，通过优化构建步骤和资源管理。
优化说明
细化日志记录：
增加了对磁盘和网络带宽的监控，以确保资源使用情况在构建过程中被跟踪。
脚本结构优化：
通过函数来组织代码，提高了脚本的可读性和维护性。
将系统资源监控和构建逻辑分开，使脚本更加模块化。
构建效率提升：
通过并行处理不同的镜像格式转换任务来提高构建效率。
灵活的参数设置：
允许用户通过命令行参数来指定各种选项，增强了脚本的灵活性。
自动生成 ISO 文件名：
根据桌面环境和系统版本自动生成 ISO 文件名，确保文件命名一致性。
## Fedora-build
不断优化脚本，提高编译效率并减少错误，我们可以采用以下策略：
并行处理：充分利用多线程，尽量减少串行任务，特别是在镜像转换和构建步骤中。
错误处理：加强对错误的检测和处理，以便在出现问题时能够提供清晰的错误信息。
动态调整：根据实际资源情况动态调整构建参数，如并行线程数。
简化和模块化：使脚本更加模块化和易于维护，使用函数进行重用和结构化。
优化资源使用：定期监控系统资源，避免过度消耗。
优化说明
多线程处理：在convert_cloud_image函数中使用了并行处理以加快镜像格式转换的速度。
模块化：对功能进行了模块化，以便于维护和扩展。
错误处理：加入了更多的错误处理，确保脚本在遇到问题时能够提供有用的信息。
动态调整构建参数：根据系统资源动态调整线程数，确保在高负载时不会过度消耗资源。
监控系统资源：增加了磁盘和网络带宽的监控功能，以便跟踪系统的实时性能。
用户输入处理：通过命令行参数动态设置构建选项，增强了脚本的灵活性和可定制性。
这些改进旨在提升脚本的效率和稳定性，并提高用户的体验。


### 标准使用方法

1. **构建默认 Live 镜像**

   ```bash
   ./build-fedora-image.sh
   ```

   **说明**: 使用默认参数构建一个标准的 Live 镜像，输出目录为 `~/custom-fedora-images`，Fedora 版本为 40，日志记录在 `~/fedora_image_build.log`。

2. **构建指定桌面环境的 Live 镜像**

   ```bash
   ./build-fedora-image.sh -t live -d GNOME
   ```

   **说明**: 构建一个包含 GNOME 桌面环境的 Live 镜像。桌面环境参数（`-d`）可以是 `GNOME`、`KDE`、`XFCE`。

3. **构建指定版本的标准安装镜像**

   ```bash
   ./build-fedora-image.sh -t standard -r 39
   ```

   **说明**: 构建 Fedora 39 的标准安装镜像。系统版本参数（`-r`）默认为 40，可以根据需求指定其他版本。

4. **构建网络安装镜像，并指定自定义仓库路径**

   ```bash
   ./build-fedora-image.sh -t netinstall -p /path/to/repo
   ```

   **说明**: 构建一个网络安装镜像，使用指定的本地仓库路径。仓库路径参数（`-p`）用于指定网络安装所需的仓库。

5. **构建 Cloud 镜像，并指定镜像格式**

   ```bash
   ./build-fedora-image.sh -t cloud -f qcow2
   ```

   **说明**: 构建一个 Cloud 镜像，并将其转换为 QCOW2 格式。云镜像格式参数（`-f`）可以是 `raw`、`vhd`、`qcow2`、`virtualbox`、`ova`。

6. **构建 CoreOS 镜像，并指定输出目录和日志文件**

   ```bash
   ./build-fedora-image.sh -t coreos -o /path/to/output -l /path/to/logfile.log
   ```

   **说明**: 构建 CoreOS 镜像，并将输出文件保存到指定目录，同时日志记录到指定日志文件中。

7. **构建 Server 镜像，并指定系统版本**

   ```bash
   ./build-fedora-image.sh -t server -v server
   ```

   **说明**: 构建一个 Server 镜像，并指定系统版本为 `server`。系统版本参数（`-v`）可以根据需求指定。

### 高级使用方法

1. **构建多个镜像类型，并将它们输出到不同目录**

   ```bash
   ./build-fedora-image.sh -t live -d KDE -o /path/to/live-output
   ./build-fedora-image.sh -t cloud -f raw -o /path/to/cloud-output
   ```

   **说明**: 使用两个命令分别构建 KDE 桌面环境的 Live 镜像和 Raw 格式的 Cloud 镜像，并将它们输出到不同目录。

2. **构建包含多个桌面环境的 Live 镜像，并同时指定构建参数**

   ```bash
   ./build-fedora-image.sh -t live -d GNOME -d KDE -r 38 -o /path/to/output -l /path/to/logfile.log
   ```

   **说明**: 构建一个包含 GNOME 和 KDE 桌面环境的 Live 镜像，指定 Fedora 38 版本，输出到指定目录，日志记录到指定文件。注意，桌面环境参数（`-d`）可以多次使用。

3. **通过脚本批量构建不同类型和版本的镜像**

   ```bash
   for type in live cloud coreos server; do
       for version in 40 39; do
           ./build-fedora-image.sh -t "$type" -r "$version" -o "/path/to/${type}_${version}_output" -l "/path/to/${type}_${version}_logfile.log"
       done
   done
   ```

   **说明**: 使用循环批量构建不同类型（Live、Cloud、CoreOS、Server）和版本（40、39）的镜像，输出到不同目录，并记录到不同日志文件中。

4. **构建指定桌面环境的网络安装镜像，使用自定义仓库**

   ```bash
   ./build-fedora-image.sh -t netinstall -d XFCE -p /custom/repo/path -o /path/to/netinstall-output -l /path/to/netinstall-logfile.log
   ```

   **说明**: 构建一个包含 XFCE 桌面环境的网络安装镜像，使用自定义仓库路径，输出到指定目录，日志记录到指定文件中。

5. **自动化构建 Cloud 镜像并转换为多个格式**

   ```bash
   ./build-fedora-image.sh -t cloud -f raw -o /path/to/cloud-output -l /path/to/cloud-logfile.log
   ./build-fedora-image.sh -t cloud -f qcow2 -o /path/to/cloud-output -l /path/to/cloud-logfile.log
   ```

   **说明**: 构建 Cloud 镜像并分别转换为 Raw 和 QCOW2 格式，输出到同一目录，日志记录到同一文件中。

### 常见命令行参数说明

- **`-t, --type <image-type>`**  
  指定镜像类型，支持的值包括 `live`、`standard`、`netinstall`、`iot`、`cloud`、`coreos`、`server`。

- **`-d, --desktop <environment>`**  
  指定桌面环境，仅对 `live` 和 `netinstall` 类型有效。支持的值包括 `GNOME`、`KDE`、`XFCE`。

- **`-r, --release <version>`**  
  指定 Fedora 版本，默认为 40。

- **`-p, --repo-path <dir>`**  
  指定网络安装镜像的本地仓库路径。

- **`-f, --cloud-format <format>`**  
  指定 Cloud 镜像格式。支持的格式包括 `raw`、`vhd`、`qcow2`、`virtualbox`、`ova`。

- **`-v, --system-version <version>`**  
  指定系统定制版本，如 `standard`、`lot`、`cloud`、`coreos`、`server`。

- **`-o, --output-dir <dir>`**  
  指定输出目录，默认为 `~/custom-fedora-images`。

- **`-l, --log-file <file>`**  
  指定日志文件路径，默认日志文件为 `~/fedora_image_build.log`。

- **`-h, --help`**  
  显示帮助信息，列出所有可用选项和用法说明。

这些示例涵盖了各种使用场景，从基础用法到高级用法，都能够满足不同需求的镜像构建任务。根据实际情况调整参数和选项，以便最佳地利用脚本的功能。
