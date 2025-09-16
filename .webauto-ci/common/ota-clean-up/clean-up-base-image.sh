#!/bin/bash -e
# cspell: ignore yaru gargi gubbi gujr gujr kacst kacst kalapi khmeros knda lklug sinhala lohit lohit lohit lohit gujr lohit knda mlym orya taml taml telu mlym nakula navilu opensymbol freefont
# cspell: ignore orya orya pagul sahadeva samyak samyak gujr samyak mlym samyak taml sarai abyssinica anjalioldlipi chilanka dyuthi gayathri karumbi keraleeyam manjari meera rachana raghumalayalamsans
# cspell: ignore suruma uroob taml telu telu tlwg tlwg garuda tlwg garuda tlwg kinnari tlwg kinnari laksaman laksaman loma loma norasi norasi purisa purisa sawasdee sawasdee umpush umpush waree waree
# cspell: ignore yrsa rasa hidpi adwaita xcursor prerm venvs cuda libcudnn8 libnvinfer noto webauto

echo "----- Start to remove unnecessary packages ..."
example_packages=(
    "cuda-samples"
    "libcudnn8-samples"
    "libnvinfer-samples"
    "nvidia-l4t-vulkan-sc-samples"
    "vpi2-samples"
    "vpi3-samples"
)

demo_packages=(
    "nvidia-l4t-graphics-demos"
    "vpi2-demos"
)

ubuntu_desktop_packages=(
    "firefox"
    "gnome-calculator"
    "gnome-calendar"
    "gnome-getting-started-docs"
    "gnome-mahjongg"
    "gnome-mines"
    "gnome-sudoku"
    "gnome-screenshot"
    "gnome-todo"
    "gnome-todo-common"
    "gnome-user-docs"
    "gnome-user-guide"
    "gnome-weather"
    "gnome-video-effects"
    "ubuntu-docs"
)

font_packages=(
    "fonts-beng"
    "fonts-beng-extra"
    "fonts-deva"
    "fonts-deva-extra"
    "fonts-gargi"
    "fonts-gubbi"
    "fonts-gujr"
    "fonts-gujr-extra"
    "fonts-guru"
    "fonts-guru-extra"
    "fonts-indic"
    "fonts-kacst"
    "fonts-kacst-one"
    "fonts-kalapi"
    "fonts-khmeros-core"
    "fonts-knda"
    "fonts-lao"
    "fonts-lklug-sinhala"
    "fonts-lohit-beng-assamese"
    "fonts-lohit-beng-bengali"
    "fonts-lohit-deva"
    "fonts-lohit-gujr"
    "fonts-lohit-guru"
    "fonts-lohit-knda"
    "fonts-lohit-mlym"
    "fonts-lohit-orya"
    "fonts-lohit-taml"
    "fonts-lohit-taml-classical"
    "fonts-lohit-telu"
    "fonts-lyx"
    "fonts-mlym"
    "fonts-nakula"
    "fonts-navilu"
    "fonts-orya"
    "fonts-orya-extra"
    "fonts-pagul"
    "fonts-sahadeva"
    "fonts-samyak-deva"
    "fonts-samyak-gujr"
    "fonts-samyak-mlym"
    "fonts-samyak-taml"
    "fonts-sarai"
    "fonts-sil-abyssinica"
    "fonts-sil-padauk"
    "fonts-smc"
    "fonts-smc-anjalioldlipi"
    "fonts-smc-chilanka"
    "fonts-smc-dyuthi"
    "fonts-smc-gayathri"
    "fonts-smc-karumbi"
    "fonts-smc-keraleeyam"
    "fonts-smc-manjari"
    "fonts-smc-meera"
    "fonts-smc-rachana"
    "fonts-smc-raghumalayalamsans"
    "fonts-smc-suruma"
    "fonts-smc-uroob"
    "fonts-taml"
    "fonts-telu"
    "fonts-telu-extra"
    "fonts-thai-tlwg"
    "fonts-tibetan-machine"
    "fonts-tlwg-garuda"
    "fonts-tlwg-garuda-ttf"
    "fonts-tlwg-kinnari"
    "fonts-tlwg-kinnari-ttf"
    "fonts-tlwg-laksaman"
    "fonts-tlwg-laksaman-ttf"
    "fonts-tlwg-loma"
    "fonts-tlwg-loma-ttf"
    "fonts-tlwg-mono"
    "fonts-tlwg-mono-ttf"
    "fonts-tlwg-norasi"
    "fonts-tlwg-norasi-ttf"
    "fonts-tlwg-purisa"
    "fonts-tlwg-purisa-ttf"
    "fonts-tlwg-sawasdee"
    "fonts-tlwg-sawasdee-ttf"
    "fonts-tlwg-typewriter"
    "fonts-tlwg-typewriter-ttf"
    "fonts-tlwg-typist"
    "fonts-tlwg-typist-ttf"
    "fonts-tlwg-typo"
    "fonts-tlwg-typo-ttf"
    "fonts-tlwg-umpush"
    "fonts-tlwg-umpush-ttf"
    "fonts-tlwg-waree"
    "fonts-tlwg-waree-ttf"
    "fonts-urw-base35"
    "fonts-yrsa-rasa"
)

icons_packages=(
    "apt-config-icons"
    "apt-config-icons-hidpi"
    "humanity-icon-theme"
    "sound-icons"
    "yaru-theme-icon"
)

packages_to_remove=()
packages_to_remove+=("${example_packages[@]}")
packages_to_remove+=("${demo_packages[@]}")
packages_to_remove+=("${ubuntu_desktop_packages[@]}")
packages_to_remove+=("${font_packages[@]}")
packages_to_remove+=("${icons_packages[@]}")

# remove the listed packages here
echo "Current working directory is: $(pwd)"
. .webauto-ci/common/ota-clean-up/package-processor.sh "${packages_to_remove[@]}"

echo "----- Finished removing unnecessary packages ..."

echo "----- Start to remove unnecessary folders and files ..."
items_to_remove=(
    "/boot/Image.backup"
    "/root/.cache/pip"
)

for item in "${items_to_remove[@]}"; do
    if [ -e "$item" ]; then
        echo "----- Removing: $item"
        sudo rm -rf "$item"
    else
        echo "----- Did not find: $item"
    fi
done
echo "----- Finished removing  unnecessary folders and files  ..."
