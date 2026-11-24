Might need to run
```
mkdir -p ~/.local/share/fonts
cd /tmp

wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz

mkdir -p ~/.local/share/fonts/JetBrainsMonoNerd

tar -xf /tmp/JetBrainsMono.tar.xz \
    -C ~/.local/share/fonts/JetBrainsMonoNerd
```

```
fc-cache -fv

fc-list : family | grep -i "JetBrainsMono Nerd Font"
```
to setup fonts (jetbrains mono)