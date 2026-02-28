# annotation_prep

用于准备鸡基因组 GRCg7b 的注释文件，服务于 RNA-seq 分析中的两类输入：

1. **Enhancer BED**：将 galGal6 的增强子注释 liftOver 到 GRCg7b，并将 RefSeq 染色体名转换为 Ensembl 染色体名。
2. **TE annotation**：基于 GRCg7b 的 RepeatMasker 结果构建 TElocal 可用的 TE GTF 和索引。

## 目录结构

```text
annotation_prep/
├── 01_enhancer/
│   ├── download.sh
│   ├── liftover.sh
│   ├── raw/
│   └── output/
├── 02_te_annotation/
│   ├── download.sh
│   ├── build_te_gtf.sh
│   ├── build_te_index.sh
│   ├── raw/
│   └── output/
└── shared/
    └── download_assembly_report.sh
```

## 依赖环境

- `bash`、`awk`、`sed`、`curl`、`gzip`、`unzip`
- UCSC `liftOver`
- `perl`（运行 `makeTEgtf.pl`）
- Python + `TElocal`/`TEtranscripts`（构建 `.locInd`）

推荐先准备一个可复用环境（如 conda）。

## 快速开始

在项目根目录执行。

### 1) 准备共享映射表（RefSeq -> Ensembl）

```bash
cd shared
bash download_assembly_report.sh
cd ..
```

生成：

- `shared/assembly_report.txt`
- `shared/refseq_to_ensembl.tsv`

### 2) 构建 enhancer 注释（BED）

```bash
cd 01_enhancer
bash download.sh
bash liftover.sh
cd ..
```

主要输出：

- `01_enhancer/output/*_enhancer_grcg7b.bed`

说明：

- `liftover.sh` 会自动筛选增强子状态（E6-E10/EnhA*）。
- liftOver 后会按 `shared/refseq_to_ensembl.tsv` 重命名染色体，并过滤掉不在主染色体映射表中的记录。

### 3) 构建 TE 注释（GTF + TElocal index）

```bash
cd 02_te_annotation
bash download.sh
bash build_te_gtf.sh
bash build_te_index.sh
cd ..
```

主要输出：

- `02_te_annotation/output/GRCg7b_rmsk_TE.gtf`
- `02_te_annotation/output/GRCg7b_rmsk_TE.locInd`

说明：

- `build_te_gtf.sh` 会将 RepeatMasker `.out` 转为 GTF，并修正 `class_id` / `family_id`。
- 会将 RefSeq 染色体名转换为 Ensembl 染色体名，且过滤 scaffold/unplaced 记录。

## 染色体命名约定

目标输出采用 Ensembl 风格主染色体命名：

- `1..33`, `W`, `Z`, `MT`

无 `chr` 前缀。

## 常见问题

- **报错找不到 `refseq_to_ensembl.tsv`**  
  先执行 `shared/download_assembly_report.sh`。

- **`liftOver: command not found`**  
  需要先安装 UCSC Kent 工具并确保 `liftOver` 在 `PATH` 中。

- **`ModuleNotFoundError: TElocal_Toolkit`**  
  需要安装并激活包含 TElocal/TEtranscripts 的 Python 环境。

## 可选：同步到 HPC

```bash
rsync -avz --exclude='*.gz' ./ HPC2-via-dell-frp:/work/home/zhgroup02/zzy/gtex/00_annotation_prep/
```

