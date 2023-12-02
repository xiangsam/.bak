# 自用深度学习docker image制作
FROM nvcr.io/nvidia/cuda:11.8.0-devel-ubuntu22.04

RUN apt update

RUN apt install -y build-essential cmake python3-dev python3-pip git 

# 常用工具
RUN apt install -y vim wget tmux

# 清华源，取消下行注释即可
# RUN pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 根据torch, docker cuda版本修改
RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
RUN pip3 install pyg_lib torch_scatter torch_sparse torch_cluster torch_spline_conv -f https://data.pyg.org/whl/torch-2.0.0+cu118.html
RUN pip3 install torch_geometric

# amp混合精度加速
RUN mkdir /workspace
WORKDIR /workspace
RUN git clone https://github.com/NVIDIA/apex
WORKDIR /workspace/apex
RUN pip3 install packaging
# if pip >= 23.1 (ref: https://pip.pypa.io/en/stable/news/#v23-1) which supports multiple `--config-settings` with the same key... 
RUN pip3 install -v --disable-pip-version-check --no-cache-dir --no-build-isolation --config-settings "--build-option=--cpp_ext" --config-settings "--build-option=--cuda_ext" ./
# otherwise
# RUN pip3 install -v --disable-pip-version-check --no-cache-dir --no-build-isolation --global-option="--cpp_ext" --global-option="--cuda_ext" ./

# 常用工具
RUN pip3 install scikit-learn einops seaborn numba transformers datasets pandas tqdm scikit-image

# RUN pip3 install hyperopt pymongo optunity sko

RUN pip3 install scipy joblib
RUN pip3 install wandb torchsummary

# 使用python3作为默认版本python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

WORKDIR /workspace
