# 常用深度学习docker image制作
FROM nvcr.io/nvidia/cuda:11.8.0-devel-ubuntu22.04

RUN apt update

RUN apt install -y build-essential cmake python3-dev python3-pip git

# 清华源
# RUN pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
# 根据torch, docker cuda版本修改
RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
RUN pip3 install pyg_lib torch_scatter torch_sparse torch_cluster torch_spline_conv -f https://data.pyg.org/whl/torch-2.0.0+cu118.html
RUN pip3 install torch_geometric

# amp混合精度加速
RUN mkdir workspace && cd workspace
RUN git clone https://github.com/NVIDIA/apex && cd apex
RUN pip3 install packaging
RUN pip3 install -v --disable-pip-version-check --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" ./

# 常用工具
RUN pip3 install scikit-learn einops seaborn numba transformers datasets pandas tqdm

# 调参工具
RUN pip3 install hyperopt pymongo optunity sko

# 基因算法
RUN pip3 install scipy joblib
RUN pip3 install deap update_checker stopit xgboost
RUN pip3 install tpot
