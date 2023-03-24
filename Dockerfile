FROM nvcr.io/nvidia/cuda:11.8.0-devel-ubuntu22.04

RUN apt update

RUN apt install -y build-essential cmake python3-dev python3-pip git

RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

RUN pip3 install pyg_lib torch_scatter torch_sparse torch_cluster torch_spline_conv -f https://data.pyg.org/whl/torch-2.0.0+cu118.html

RUN pip3 install torch_geometric

RUN mkdir workspace && cd workspace

RUN git clone https://github.com/NVIDIA/apex && cd apex

RUN pip3 install packaging

RUN pip3 install -v --disable-pip-version-check --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" ./

RUN pip3 install sklearn einops seaborn
