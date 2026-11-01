<h1 align="center">
   <img src="./Downloads/misc/icon.jpg  " width="100px" /> 
   <br>
      theodotdot's dots 
   <br>
      <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/palette/macchiato.png" width="600px" /> <br>
 
</h1>

##### Disclaimer: My dotfiles are managed using [chezmoi](https://github.com/twpayne/chezmoi). 
-------------------------------------
### 🖼️ Theme
I use [catppuccin](https://catppuccin.com/) macchiato everywhere I can 🐈‍⬛

### 🛠️ Tools I use

#### Zsh

[Antidote](https://getantidote.github.io/) is the plugin manager. Zsh config layout inspired by [antidote's zdotdir project](https://github.com/getantidote/zdotdir).  

|     Plugins                                                                                                       |     Others                                                                     |
| ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **[mattmc3/ez-compinit](https://github.com/mattmc3/ez-compinit)**                                                 | **[starship prompt](https://starship.rs/)**                                    |
| **[zsh-users/zsh-completions](https://github.com/zsh-users/zsh-completions)**                                     | **[direnv](https://direnv.net/)**                                              |
| **[aloxaf/fzf-tab](https://github.com/Aloxaf/fzf-tab)**                                                           | **[jump](https://github.com/gsamokovarov/jump)**                               |
| **[lincheney/fzf-tab-completion](https://github.com/lincheney/fzf-tab-completion)**                               | **[zoxide](https://github.com/ajeetdsouza/zoxide)**                            |
| **[belak/zsh-utils/editor](https://github.com/belak/zsh-utils/tree/main/editor)**                                 | **[modified dbt completion](https://github.com/dbt-labs/dbt-completion.bash)** |
| **[belak/zsh-utils/history](https://github.com/belak/zsh-utils/tree/main/history)**                               |
| **[belak/zsh-utils/utility](https://github.com/belak/zsh-utils/tree/main/utility)**                               |
| **[ohmyzsh/ohmyzsh/extract](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/extract)**                     |
| **[zdharma-continuum/fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)**   |
| **[zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)**                             |
| **[zsh-users/zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)**           |

### 🕹️ Thor gamepad

InputPlumber cannot map an analog axis to wheel steps (`Mouse::Wheel` from an axis source
is `NotImplemented` in 0.8x), so right-stick scrolling is done in user space in two places:

| Where | What |
|---|---|
| Plasma Mobile | `~/.config/scripts/pocknix-stick-scroll` (user unit `pocknix-stick-scroll.service`): adds the pad target to the composite device over D-Bus while the `Plasma Mobile` profile is loaded, reads `ABS_RX/ABS_RY` and emits `REL_WHEEL`/`REL_HWHEEL` on its own uinput device, rate scaled by deflection. Idle for every other profile. |
| Anki | `anki/local-addons/anki-gamepad` loads the `Anki` profile on focus, handles the face buttons/d-pad and scrolls the card with the right stick — see [anki/README.md](./anki/README.md). |
