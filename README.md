# 🧼 Flutter Assets Cleanup Tool

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)
[![Flutter](https://img.shields.io/badge/Flutter-Compatible-02569B.svg)](https://flutter.dev)

A powerful command-line tool that automatically detects and cleans unused Flutter assets and constants, helping you reduce bundle size and improve app performance by removing dead code.

## ✨ Features

- 🔍 **Smart Auto-Detection**: Automatically finds Assets class files and asset directories
- 🎯 **Interactive Selection**: Choose from multiple matches when detected
- 🧹 **Dual Cleanup**: Removes both unused constants and asset files
- 🛡️ **Safe Operations**: Interactive confirmations before deletions
- ⚡ **Performance Boost**: Reduces bundle size by removing dead code
- 🔧 **Flexible Options**: Customizable cleanup operations
- 📝 **Detailed Logging**: Verbose output for tracking operations
- 🚀 **Easy Installation**: One-command installation with PATH integration

## 🚀 Quick Start

### Installation

Run the installer script:

```bash
curl -fsSL https://raw.githubusercontent.com/jamal-and/flutter_assets_cleaner/refs/heads/main/install.sh | bash
```

Or download and run locally:

```bash
# Download the installer
curl -O https://raw.githubusercontent.com/jamal-and/flutter_assets_cleaner/refs/heads/main/install.sh

# Make it executable
chmod +x install.sh

# Run the installer
./install.sh
```

### Basic Usage

Navigate to your Flutter project directory and run:

```bash
flutter-assets-cleaner
```

The tool will:
1. 🔍 Auto-detect your Assets class file
2. 🔍 Find unused static const variables
3. 🔍 Scan for unused asset files
4. 🗑️ Prompt for confirmation before deletion

## 📖 Usage Guide

### Command Line Options

```bash
flutter-assets-cleaner [OPTIONS]
```

#### Available Options

| Option | Description |
|--------|-------------|
| `--help`, `-h` | Show help message |
| `--version`, `-v` | Show version information |
| `--skip-constants` | Skip cleanup of unused static const variables |
| `--skip-files` | Skip cleanup of unused asset files |
| `--constants-only` | Only clean unused constants (skip files) |
| `--files-only` | Only clean unused files (skip constants) |
| `--auto-confirm`, `-y` | Automatically confirm all deletions |
| `--verbose` | Enable verbose output |
| `--asset-dir DIR` | Specify assets directory (default: `./assets`) |
| `--lib-dir DIR` | Specify lib directory (default: `./lib`) |

### Examples

#### Interactive Cleanup (Default)
```bash
flutter-assets-cleaner
```

#### Clean Only Constants
```bash
flutter-assets-cleaner --constants-only
```

#### Clean Only Files
```bash
flutter-assets-cleaner --files-only
```

#### Auto-Confirm All Operations
```bash
flutter-assets-cleaner --auto-confirm
```

#### Verbose Output
```bash
flutter-assets-cleaner --verbose
```

#### Custom Directories
```bash
flutter-assets-cleaner --asset-dir assets/images --lib-dir src
```

## 🔧 How It Works

### Step 1: Constants Cleanup

The tool automatically detects Assets class files by searching for:
- Files containing `class Assets` or similar patterns
- Static const String declarations
- Common filenames like `assets.dart`, `app_assets.dart`, etc.

**Example Assets class:**
```dart
class Assets {
  static const String iconHome = 'assets/icons/home.png';
  static const String iconProfile = 'assets/icons/profile.png';
  static const String backgroundImage = 'assets/images/bg.jpg';
}
```

### Step 2: File Cleanup

Scans your assets directory for unused files by:
- Finding all asset files (PNG, JPG, JSON, SVG, etc.)
- Checking references in Dart code and YAML files
- Identifying files not referenced anywhere

**Supported file types:**
- Images: `.png`, `.jpg`, `.jpeg`, `.svg`, `.webp`
- Fonts: `.ttf`, `.otf`
- Data: `.json`

## 🛠️ Requirements

- **Bash**: Version 4.0 or higher
- **Standard Unix tools**: `grep`, `find`, `curl`/`wget`
- **Flutter project**: Must be run from Flutter project root

## 📁 Project Structure

The tool expects a standard Flutter project structure:

```
your-flutter-project/
├── pubspec.yaml          # Required - validates Flutter project
├── lib/                  # Default lib directory
│   ├── main.dart
│   ├── assets.dart       # Assets class (auto-detected)
│   └── ...
├── assets/               # Default assets directory
│   ├── images/
│   ├── icons/
│   └── fonts/
└── ...
```

## 🔍 Auto-Detection Features

### Assets Class Detection

The tool automatically finds Assets class files using multiple strategies:

1. **Pattern Matching**: Searches for `class Assets` declarations
2. **Content Analysis**: Looks for `static const String` declarations
3. **Filename Patterns**: Checks common names like:
   - `assets.dart`
   - `app_assets.dart`
   - `asset_paths.dart`
   - `constants.dart`
   - `resources.dart`

### Multiple File Handling

When multiple potential Assets files are found:
- Interactive selection menu (unless `--auto-confirm` is used)
- Preview of each file showing constant count
- Option to skip constants cleanup

## 🛡️ Safety Features

- **Confirmation Prompts**: Interactive confirmation before deletions
- **Detailed Previews**: Shows exactly what will be deleted
- **Verbose Logging**: Track all operations with `--verbose`
- **Validation Checks**: Ensures you're in a Flutter project
- **Flexible Options**: Skip specific cleanup types

## 🎯 Use Cases

### Regular Maintenance
```bash
# Weekly cleanup
flutter-assets-cleaner --auto-confirm --verbose
```

### Pre-Release Cleanup
```bash
# Before app release
flutter-assets-cleaner --verbose
```

### Development Workflow
```bash
# During development
flutter-assets-cleaner --constants-only
```

### CI/CD Integration
```bash
# In automated pipelines
flutter-assets-cleaner --auto-confirm --files-only
```

## 🔧 Installation Methods

### Method 1: Automated Installation (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/jamal-and/flutter_assets_cleaner/refs/heads/main/install.sh | bash
```

### Method 2: Manual Installation

1. **Download the script:**
   ```bash
   curl -O https://raw.githubusercontent.com/jamal-and/flutter_assets_cleaner/refs/heads/main/flutter_assets_cleaner.sh
   ```

2. **Make it executable:**
   ```bash
   chmod +x flutter_assets_cleaner.sh
   ```

3. **Move to PATH:**
   ```bash
   sudo mv flutter_assets_cleaner.sh /usr/local/bin/flutter-assets-cleaner
   ```

### Method 3: Local Usage

```bash
# Download and run directly
curl -O https://raw.githubusercontent.com/jamal-and/flutter_assets_cleaner/refs/heads/main/flutter_assets_cleaner.sh
chmod +x flutter_assets_cleaner.sh
./flutter_assets_cleaner.sh
```

## 🗑️ Uninstallation

If installed via the installer:

```bash
flutter-assets-cleaner-uninstall
```

Or manually:

```bash
rm -f ~/.local/bin/flutter-assets-cleaner
rm -f ~/.local/bin/flutter-assets-cleaner-uninstall
```

## 📊 Performance Impact

Regular use of this tool can:
- ✅ Reduce APK/IPA bundle size
- ✅ Improve build times
- ✅ Simplify asset management
- ✅ Reduce maintenance overhead
- ✅ Keep codebase clean

## 🐛 Troubleshooting

### Common Issues

#### "No pubspec.yaml found"
- **Solution**: Navigate to your Flutter project root directory

#### "Assets directory not found"
- **Solution**: Use `--asset-dir` to specify correct path

#### "No Assets class file detected"
- **Solution**: Ensure your Assets class contains `static const String` declarations

#### Permission denied
- **Solution**: Ensure script has execute permissions: `chmod +x flutter_assets_cleaner.sh`

### Debug Mode

Enable verbose output to see detailed operations:

```bash
flutter-assets-cleaner --verbose
```

## 💡 Best Practices

1. **Regular Cleanup**: Run weekly or before releases
2. **Use Version Control**: Commit before running cleanup
3. **Test After Cleanup**: Verify app functionality
4. **Review Changes**: Check what was deleted
5. **Custom Workflows**: Use specific flags for different scenarios

## 📝 Contributing

We welcome contributions! Here's how you can help:

1. **Report Issues**: Found a bug? Open an issue
2. **Feature Requests**: Have an idea? Let us know
3. **Code Contributions**: Submit pull requests
4. **Documentation**: Help improve docs

### Development Setup

```bash
# Clone the repository
git clone https://github.com/jamal-and/flutter_assets_cleaner.git
cd flutter_assets_cleaner

# Make changes to flutter_assets_cleaner.sh

# Test locally
./flutter_assets_cleaner.sh --help
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Repository**: https://github.com/jamal-and/flutter_assets_cleaner
- **Issues**: https://github.com/jamal-and/flutter_assets_cleaner/issues
- **Releases**: https://github.com/jamal-and/flutter_assets_cleaner/releases

## 🙏 Acknowledgments

- Built with ❤️ for the Flutter community
- Inspired by the need for cleaner Flutter projects
- Thanks to all contributors and users

---

**Made with ❤️ for Flutter developers everywhere** 🚀