# WSL2_PLUS: 
### A Comprehensive Windows Subsystem for Linux Management Tool

WSL2_PLUS is a PowerShell-based tool designed to simplify the management of Windows Subsystem for Linux (WSL) distributions. This project aims to provide a user-friendly interface for installing, managing, and customizing WSL distributions, making it easier for users to take full advantage of the WSL ecosystem.

## Key Features

- **Distribution Management**: Install, update, and manage WSL distributions with ease.
- **Customization**: Clone and customize WSL distributions to suit your needs.
- **Internet Connection Detection**: Automatically detect internet connectivity and prompt for installation of required packages.
- **Root-Only Login**: Set up root-only login for enhanced testing freedom.
- **Directory Creation**: Automatically create required directories for WSL2 distributions.
- **AUDIO & GUI SUPPORT**: Fully automated audio/video setup with [wsl_stabilizer.sh](#stabilization-script) including:
  - PulseAudio configuration
  - ALSA device routing
  - X11 display setup
  - Self-healing audio daemon
  - Validation tests

## Getting Started

1. Clone the repository:
```bash
git clone https://github.com/SorrentinoPro/WSL2_PLUS.git
```
2. Run the `WSL_PLUS.ps1` file to launch the management tool

3. The system is plug & play - double click to run with admin rights from any folder
4. **For Audio/Video Support**:
   - Copy `wsl_stabilizer.sh` to your WSL instance
   - Run the script as shown below

## Stabilization Script

The `wsl_stabilizer.sh` automates WSL audio/video configuration. Simply:

1. Copy the script to your WSL instance
2. Make it executable:
```bash
chmod +x wsl_stabilizer.sh
```
3. Run it:
```bash
./wsl_stabilizer.sh
```
or
**Install/Upgrade in One Line**  
```bash
wget -O wsl_stabilizer.sh https://raw.githubusercontent.com/SorrentinoPro/WSL2_PLUS/main/wsl_stabilizer.sh && chmod +x wsl_stabilizer.sh
```

**What it does**:
✅ Installs required packages (pulseaudio/alsa-utils/x11-apps)  
✅ Configures PulseAudio to never timeout  
✅ Sets up ALSA-PulseAudio bridging  
✅ Configures X11 display settings  
✅ Runs validation tests (audio playback/recording/graphics)

## Usage

The WSL2_PLUS tool provides a simple interface for managing WSL distributions:

**Main Menu Options**:
- Manage Current Installed Distribution
- Install New Distribution
- Show Installed Distros Info
- Set/Fix/check AUDIO & GUI (automates Windows-side configuration)
- EXIT

## Troubleshooting

If using `wsl_stabilizer.sh`, ensure:
1. Windows has:
   - X Server running (VcXsrv/MobaXterm)
   - PulseAudio for Windows running
   - Microphone permissions enabled in Windows

Common fixes:
```bash
# Restart PulseAudio in WSL
pulseaudio --kill && pulseaudio --start

# Regenerate ALSA config
alsa force-reload
```

## License

WSL_PLUS is licensed under the [MIT License](LICENSE.md).

## Contributing

Contributions to WSL_PLUS are welcome! If you'd like to contribute to this project, please:

1. Fork the repository
2. Create a new branch for your feature or bug fix
3. Submit a pull request

## Acknowledgments

WSL_PLUS is built on top of the Windows Subsystem for Linux (WSL) technology developed by Microsoft. Special thanks to:

- The WSL community for testing and feedback
- PulseAudio and ALSA maintainers
- Open-source X Server projects

## Contact

If you have any questions or need help with my script, please don't hesitate to contact me:

- **Email**: [francesco@sorrentino.pro](mailto:francesco@sorrentino.pro)
- **X/Twitter**: [@SorrentinoPro](https://x.com/SorrentinoPro)
