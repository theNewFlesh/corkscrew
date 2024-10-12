<p>
    <a href="https://www.linkedin.com/in/alexandergbraun" rel="nofollow noreferrer">
        <img src="https://www.gomezaparicio.com/wp-content/uploads/2012/03/linkedin-logo-1-150x150.png"
             alt="linkedin" width="30px" height="30px"
        >
    </a>
    <a href="https://github.com/theNewFlesh" rel="nofollow noreferrer">
        <img src="https://tadeuzagallo.com/GithubPulse/assets/img/app-icon-github.png"
             alt="github" width="30px" height="30px"
        >
    </a>
    <a href="https://pypi.org/user/the-new-flesh" rel="nofollow noreferrer">
        <img src="https://cdn.iconscout.com/icon/free/png-256/python-2-226051.png"
             alt="pypi" width="30px" height="30px"
        >
    </a>
    <a href="http://vimeo.com/user3965452" rel="nofollow noreferrer">
        <img src="https://cdn.iconscout.com/icon/free/png-512/movie-52-151107.png?f=avif&w=512"
             alt="vimeo" width="30px" height="30px"
        >
    </a>
    <a href="http://www.alexgbraun.com" rel="nofollow noreferrer">
        <img src="https://i.ibb.co/fvyMkpM/logo.png"
             alt="alexgbraun" width="30px" height="30px"
        >
    </a>
</p>

<!-- <img id="logo" src="resources/logo.png" style="max-width: 717px"> -->

[![](https://img.shields.io/badge/License-MIT-F77E70?style=for-the-badge)](https://github.com/theNewFlesh/corkscrew/blob/master/LICENSE)

# Introduction
Corkscrew is library of various zsh functions and other command line tools
oriented towards MacOS and Ubuntu power users.

Corkscrew depends on zsh, oh-my-zsh, zsh plugins and other unix CLI tools.
Install whatever you like, just know that some tools will expect certain things
you do not have. The packages section lists everything that you may wish to
install. It is highly recommended you look over the code before installation,
as you may wish to comment out certain parts according to your taste.

# Installation
1. Install oh-my-zsh
2. Integrate zshrc into your ~/.zshrc file
3. Copy files according to the following:

```
~/.oh-my-zsh/custom
├── themes
│   ├── henanigans-syntax-theme.ini
│   └── henanigans.zsh-theme
|
├── plugins
│  ├── fast-syntax-highlighting
│  ├── zsh-autosuggestions
│  └── zsh-completions
|
└── scripts
   ├── aliases.sh
   ├── app_tools.sh
   ├── colors.sh
   ├── f_tools.sh
   ├── k8s_tools.sh
   ├── linux_tools.sh
   ├── ls_tools.sh
   ├── macos_tools.sh
   ├── misc_tools.sh
   ├── net_tools.sh
   ├── repo_tools.sh
   └── stdout_tools.sh
```

## Packages
  - batcat
  - bettersnap
  - brave
  - cruft
  - docker
  - dockviz
  - exa
  - ffmpeg
  - git
  - gnome-shell
  - iterm2
  - jq
  - kubectl
  - oh-my-zsh
  - parallel
  - pylint
  - ripgrep
  - rsync
  - spd-say
  - telnet
  - vlc
  - vscode
  - xsel
  - yq

## ZSH Plugins
  - aws
  - brew
  - common-aliases
  - command-not-found
  - debian
  - gem
  - git
  - npm
  - pip
  - python
  - ruby
  - sudo
  - fast-syntax-highlighting
  - zsh-autosuggestions
  - zsh-completions
  - zsh-history-enquirer

# Notes
  - The zshrc file assigns a custom zsh theme and plugins
  - The last line in the zshrc file sources all the scripts in ~/.oh-my-zsh/custom/scripts
  - Some scripts alter shell keybindings
  - Some scripts reassign common terminal utilities like `cat`
  - Some functions expect packages to exist on your system like `parallel` and `exa`
