#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD02_DIR=${BASE_DIR}/02-sd-webui

# disable the use of a python venv
export venv_dir="-"

# Install or update Stable-Diffusion-WebUI
mkdir -p ${SD02_DIR}

# clone repository
if [ ! -d ${SD02_DIR}/webui ]; then
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git ${SD02_DIR}/webui
fi


# check if remote is ahead of local
cd ${SD02_DIR}/webui
check_remote

#clean conda env
clean_env ${SD02_DIR}/conda-env

# create conda env if needed
if [ ! -d ${SD02_DIR}/conda-env ]; then
    conda create -p ${SD02_DIR}/conda-env -y
fi

# activate conda env and install base tools
source activate ${SD02_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 pip gcc gxx libcurand --solver=libmamba -y

#copy default parameters if absent
if [ ! -f "$SD02_DIR/parameters.txt" ]; then
    cp -v "/opt/sd-install/parameters/02.txt" "$SD02_DIR/parameters.txt"
fi

# install custom requirements
pip install --upgrade pip
pip install insightface==0.7.3
pip install onnxruntime-gpu==1.18.0

if [ -f ${SD02_DIR}/requirements.txt ]; then
    pip install -r ${SD02_DIR}/requirements.txt
fi

# Merge Models, vae, lora, and hypernetworks, and outputs
# Ignore move errors if they occur
sl_folder ${SD02_DIR}/webui embeddings ${BASE_DIR}/models embeddings

sl_folder ${SD02_DIR}/webui/models Stable-diffusion ${BASE_DIR}/models checkpoints
sl_folder ${SD02_DIR}/webui/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${SD02_DIR}/webui/models Lora ${BASE_DIR}/models lora
sl_folder ${SD02_DIR}/webui/models VAE ${BASE_DIR}/models vae
sl_folder ${SD02_DIR}/webui/models VAE-approx ${BASE_DIR}/models vae_approx
sl_folder ${SD02_DIR}/webui/models BLIP ${BASE_DIR}/models blip
sl_folder ${SD02_DIR}/webui/models Codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD02_DIR}/webui/models GFPGAN ${BASE_DIR}/models upscale
sl_folder ${SD02_DIR}/webui/models LDSR ${BASE_DIR}/models upscale
sl_folder ${SD02_DIR}/webui/models RealESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD02_DIR}/webui/models ESRGAN ${BASE_DIR}/models upscale
sl_folder ${SD02_DIR}/webui/models ControlNet ${BASE_DIR}/models controlnet
sl_folder ${SD02_DIR}/webui/models adetailer ${BASE_DIR}/models detectors
sl_folder ${SD02_DIR}/webui/models LyCORIS ${BASE_DIR}/models lycoris
sl_folder ${SD02_DIR}/webui/models deepbooru ${BASE_DIR}/models deepbooru
sl_folder ${SD02_DIR}/webui/models karlo ${BASE_DIR}/models karlo
sl_folder ${SD02_DIR}/webui/models text_encoder ${BASE_DIR}/models clip

sl_folder ${SD02_DIR}/webui/extensions/sd-webui-inpaint-anything models ${BASE_DIR}/models sams

sl_folder ${SD02_DIR}/webui/extensions/sd-webui-segment-anything/models sam ${BASE_DIR}/models sams
sl_folder ${SD02_DIR}/webui/extensions/sd-webui-segment-anything/models grounding-dino ${BASE_DIR}/models grounding-dino

sl_folder ${SD02_DIR}/webui/extensions/sd-webui-controlnet models ${BASE_DIR}/models controlnet
sl_folder ${SD02_DIR}/webui/extensions/sd-webui-controlnet/annotator/downloads/clip_vision insightface ${BASE_DIR}/models insightface
sl_folder ${SD02_DIR}/webui/extensions/sd-webui-controlnet/annotator/downloads clip_vision ${BASE_DIR}/models clip_vision

sl_folder ${SD02_DIR}/webui/extensions/sd-webui-animatediff model ${BASE_DIR}/models animatediff

sl_folder ${SD02_DIR}/webui outputs ${BASE_DIR}/outputs 02-sd-webui

# run webUI
echo "Run Stable-Diffusion-WebUI"
cd ${SD02_DIR}/webui
CMD="bash webui.sh"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD02_DIR}/parameters.txt"
eval $CMD
wait 99999