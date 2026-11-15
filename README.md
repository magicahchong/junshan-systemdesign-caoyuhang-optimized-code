# GateANN稀有标签查询优化

在GateANN的YFCC查询程序中增加可选的稀有标签缓存。启动时按指定标签装入匹配向量和ID，查询命中缓存后顺序扫描原始向量并计算精确L2距离。其他查询沿用GateANN的图搜索和读盘前过滤。

## 构建

在x86-64 Linux或WSL下安装Python 3.10+和构建依赖。

```bash
sudo apt install build-essential cmake git libaio-dev libgoogle-perftools-dev \
  libopenblas-dev libeigen3-dev
bash scripts/prepare_gateann.sh
```

修改后的GateANN源码位于[`systems/GateANN-public/`](systems/GateANN-public/)。构建脚本直接用这份源码编译Release版本，启用Linux AIO。

## 文件说明

### 优化相关文件

| 文件 | 用途 |
|---|---|
| [`search_disk_index_yfcc.cpp`](systems/GateANN-public/tests/search_disk_index_yfcc.cpp) | 实现稀有标签缓存和内存精确搜索，负责选择查询路径并检查返回结果。 |
| [`gateann_adapter.py`](adapters/gateann_adapter.py) | 提供`--rare-labels`参数，检查标签ID并将参数传给查询程序。 |

### 课程兼容修复

[`linux_aligned_file_reader.cpp`](systems/GateANN-public/src/utils/linux_aligned_file_reader.cpp)包含课程提供的Linux AIO编译修复。

### 构建与实验工具

| 文件 | 用途 |
|---|---|
| [`prepare_gateann.sh`](scripts/prepare_gateann.sh) | 编译仓库中的GateANN源码。 |
| [`_common.py`](adapters/_common.py) | 提供数据检查、命令执行和CSV结果保存等公共功能。 |
| [`versions.json`](adapters/versions.json)、[`UPSTREAM_COMMIT`](systems/GateANN-public/UPSTREAM_COMMIT) | 记录GateANN的上游版本，供环境检查使用。 |

## 运行对照

先在课程实验目录中准备YFCC数据和GateANN的Formal预构建索引。将下方`course_dir`设为该目录，然后在本仓库根目录执行。

```bash
course_dir=/path/to/fvs-course-lab
args=(
  --repo "$PWD/systems/GateANN-public"
  --dataset-root "$course_dir/datasets/yfcc_course_v1"
  --run-root "$course_dir/course_runs"
  --tier formal --bucket low --threads 1 --beamwidth 8 --k 10 --L 320
)

python3 adapters/gateann_adapter.py search "${args[@]}" --run-id gateann-baseline
python3 adapters/gateann_adapter.py search "${args[@]}" --run-id gateann-rare-labels \
  --rare-labels 4780 600 747 113 42
```

每个标签的匹配比例上限为1%，向量与ID的缓存上限为32 MiB。若查询只有一个标签、该标签在缓存中且匹配向量至少有K个，程序直接在内存中找最相近的K个向量。每次运行记录召回率、平均查询延迟、QPS和逻辑I/O，并在日志中记录缓存大小、初始化耗时与命中查询数。重复运行时为各轮使用不同的`--run-id`。

上游GateANN使用MIT许可证，许可证随仓库保留。
