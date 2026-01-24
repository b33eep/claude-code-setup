# Install demo - show curl command, run wizard
Output docs/assets/install.gif

Set Shell "bash"
Set FontSize 13
Set Width 900
Set Height 550
Set Theme "Dracula"
Set Padding 15
Set TypingSpeed 20ms

# Setup: clean HOME, prepare alias to show curl but run local
Hide
Type "export HOME=$(mktemp -d)"
Enter
Type "cd /Users/grazi/Coding/claude-setup"
Enter
Type "alias curl='./install.sh #'"
Enter
Type "clear"
Enter
Show

Sleep 300ms

# Show the curl command from README (alias runs ./install.sh instead)
Type "curl -fsSL https://raw.githubusercontent.com/b33eep/claude-code-setup/main/quick-install.sh | bash"
Enter
Sleep 4s

# Select MCP servers: 3 = pdf-reader
Type "3"
Enter
Sleep 3s

# Select skills: 2 3 4 = standards
Type "2 3 4"
Enter
Sleep 3s

# Enable ccstatusline: Y
Type "Y"
Enter
Sleep 8s

Sleep 2s
