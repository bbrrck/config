# Tibor Configuration Files

## Windows

## Windows

### Prerequisites

* Get [scoop](https://scoop.sh/)

### Installation

1. Install [nushell](https://www.nushell.sh/): `scoop install nushell`
2. Install [starship](https://starship.rs/): `scoop install starship`
3. *(Optional)* Install [neovim](https://neovim.io/): `scoop install neovim`
4. Run the following commands to initialize starship for nushell:

   ```bash
   mkdir ~/.cache/starship
   starship init nu > ~/.cache/starship/init.nu
   ```

### Setup

1. Clone the repo: `gh repo clone bbrrck/config ~/Projects/config`
2. Create the file `~/Projects/config/nu/env-vars-secret.nu` and add secret environment variables. Example:
  
    ```nu
    $env.DNA_METASTORE_PASSWORD = 'THIS_IS_REDACTED'
    $env.AZURE_DEV_OPS_TOKEN = 'ALSO_REDACTED'
    ```

3. Open the nushell config file: `nvim $nu.config-path`
4. Add the following to the end: `source ~/Projects/config/nu/_config.nu`.

### Apps

Install any additional packages via scoop. Below is a list for inspiration. This list was generated on 2024-01-18 14:00:00.

To install some of these packages, you will need to include additional scoop buckets:

```nu
scoop bucket add extras
scoop bucket add nerd-fonts
```

| Name                   | Version      | Source     | Updated             | Info           |
| ---------------------- | ------------ | ---------- | ------------------- | -------------- |
| 0xProto-NF-Mono        | 3.1.1        | nerd-fonts | 2024-01-17 22:42:25 |                |
| 7zip                   | 23.01        | main       | 2024-01-17 22:13:29 |                |
| aria2                  | 1.37.0-1     | main       | 2024-01-17 22:53:13 |                |
| azure-cli              |              |            | 2024-01-18 10:58:40 | Install failed |
| ccat                   | 1.1.0        | main       | 2024-01-17 22:27:11 |                |
| dark                   | 3.11.2       | main       | 2024-01-18 13:56:38 |                |
| dbeaver                | 23.3.2       | extras     | 2024-01-18 13:47:18 |                |
| Delugia-Mono-Nerd-Font | 2111.01.2    | nerd-fonts | 2024-01-17 22:41:31 |                |
| FiraCode               | 6.2          | nerd-fonts | 2024-01-17 22:40:06 |                |
| gh                     | 2.42.1       | main       | 2024-01-17 22:31:54 |                |
| git                    | 2.43.0       | main       | 2024-01-17 22:14:24 |                |
| github                 | 3.3.7        | extras     | 2024-01-17 22:30:05 |                |
| JetBrains-Mono         | 2.304        | nerd-fonts | 2024-01-17 22:46:24 |                |
| make                   | 4.4.1        | main       | 2024-01-18 13:59:05 |                |
| Monocraft-Nerd-Font    | 3.0          | nerd-fonts | 2024-01-17 22:38:58 |                |
| neovim                 | 0.9.5        | main       | 2024-01-18 14:28:25 |                |
| notepadplusplus        | 8.6.2        | extras     | 2024-01-17 22:24:15 |                |
| Noto-NF                | 3.1.1        | nerd-fonts | 2024-01-17 22:47:19 |                |
| nu                     | 0.89.0       | main       | 2024-01-17 22:17:25 |                |
| obsidian               | 1.5.3        | extras     | 2024-01-18 13:56:37 |                |
| oh-my-posh             | 19.6.0       | main       | 2024-01-17 22:34:10 |                |
| pshazz                 | 0.2022.03.09 | main       | 2024-01-17 22:55:27 |                |
| psutils                | 0.2023.06.28 | main       | 2024-01-17 22:59:57 |                |
| python                 | 3.12.1       | main       | 2024-01-18 13:58:53 |                |
| starship               | 1.17.1       | main       | 2024-01-17 23:12:44 |                |
| touch                  | 0.2018.07.25 | main       | 2024-01-17 23:13:59 |                |
| vscode                 | 1.85.1       | extras     | 2024-01-17 22:28:49 |                |
| which                  | 2.20         | main       | 2024-01-17 22:15:25 |                |
| youtube-music          | 3.2.2        | extras     | 2024-01-18 09:45:14 |                |
