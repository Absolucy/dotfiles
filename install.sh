#!/bin/bash

mkdir -p "$HOME"/{.cargo,.config/paru}

ln -sf "$PWD/Cargo/config.toml" "$HOME/.cargo/config.toml"
ln -sf "$PWD/Git/gitconfig" "$HOME/.gitconfig"
ln -sf "$PWD/Git/gitignore_global" "$HOME/.gitignore_global"
ln -sf "$PWD/Paru/paru.conf" "$HOME/.config/paru/paru.conf"
ln -sf "$PWD/Shell/profile" "$HOME/.profile"
ln -sf "$PWD/Shell/zshrc" "$HOME/.zshrc"
