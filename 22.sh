#!/bin/bash
source /functions.sh


export PATH="/home/abc/miniconda3/bin:$PATH"
export SD22_DIR=${BASE_DIR}/22-sd-forge

# disable the use of a python venv
export venv_dir="-"

# Install or update Stable-Diffusion-WebUI
mkdir -p ${SD22_DIR}

if [ ! -d ${SD22_DIR}/forge ]; then
    git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git ${SD22_DIR}/forge
fi

# check if remote is ahead of local
cd ${SD22_DIR}/forge
check_remote

#clean conda env
clean_env ${SD22_DIR}/conda-env

# Create Conda virtual env
if [ ! -d ${SD22_DIR}/conda-env ]; then
    conda create -p ${SD22_DIR}/conda-env -y
fi

#activate conda env + install base tools
source activate ${SD22_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 pip gcc gxx libcurand --solver=libmamba -y

if [ ! -f "$SD22_DIR/parameters.txt" ]; then
    cp -v "/opt/sd-install/parameters/22.txt" "$SD22_DIR/parameters.txt"
fi

#install custom requirements 
pip install --upgrade pip
pip install insightface==0.7.3
pip install onnxruntime-gpu==1.18.0

if [ -f ${SD22_DIR}/requirements_versions.txt ]; then
    pip install -r ${SD22_DIR}/requirements_versions.txt
fi

# Merge Models, vae, lora, and hypernetworks, and outputs
# Ignore move errors if they occur
sl_folder ${SD22_DIR}/forge embeddings ${BASE_DIR}/models embeddings

sl_folder ${SD22_DIR}/forge/models Stable-diffusion ${BASE_DIR}/models checkpoints
sl_folder ${SD22_DIR}/forge/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD22_DIR}/forge/models Lora ${BASE_DIR}/models lora
sl_folder ${SD22_DIR}/forge/models VAE ${BASE_DIR}/models vae
sl_folder ${SD22_DIR}/forge/models VAE-approx ${BASE_DIR}/models vae_approx
sl_folder ${SD22_DIR}/forge/models ESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD22_DIR}/forge/models GFPGAN ${BASE_DIR}/models upscale
sl_folder ${SD22_DIR}/forge/models LDSR ${BASE_DIR}/models upscale
sl_folder ${SD22_DIR}/forge/models RealESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD22_DIR}/forge/models BLIP ${BASE_DIR}/models blip
sl_folder ${SD22_DIR}/forge/models Codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD22_DIR}/forge/models ControlNet ${BASE_DIR}/models controlnet
sl_folder ${SD22_DIR}/forge/models adetailer ${BASE_DIR}/models detectors
sl_folder ${SD22_DIR}/forge/models LyCORIS ${BASE_DIR}/models lycoris
sl_folder ${SD22_DIR}/forge/models deepbooru ${BASE_DIR}/models deepbooru
sl_folder ${SD22_DIR}/forge/models karlo ${BASE_DIR}/models karlo
sl_folder ${SD22_DIR}/forge/models text_encoder ${BASE_DIR}/models clip
sl_folder ${SD22_DIR}/forge/models diffusers ${BASE_DIR}/models diffusers
sl_folder ${SD22_DIR}/forge/models diffusers ${BASE_DIR}/models diffusers
sl_folder ${SD22_DIR}/forge/models svd ${BASE_DIR}/models svd
sl_folder ${SD22_DIR}/forge/models z123 ${BASE_DIR}/models z123
sl_folder ${SD22_DIR}/forge/models insightface ${BASE_DIR}/models insightface

sl_folder ${SD22_DIR}/forge/extensions/sd-forge-animatediff model ${BASE_DIR}/models animatediff

sl_folder ${SD22_DIR}/forge outputs ${BASE_DIR}/outputs 22-sd-forge

# Run webUI
echo "Run Stable-Diffusion-WebUI-forge"
cd ${SD22_DIR}/forge
CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD22_DIR}/parameters.txt"
eval $CMD
wait 99999