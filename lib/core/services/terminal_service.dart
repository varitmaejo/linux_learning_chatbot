import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

class TerminalService {
  static TerminalService? _instance;
  static TerminalService get instance => _instance ??= TerminalService._();
  TerminalService._();

  // Terminal state
  String _currentDirectory = '/home/user';
  Map<String, dynamic> _fileSystem = {};
  Map<String, String> _environment = {};
  List<String> _commandHistory = [];
  int _historyIndex = -1;
  String _currentUser = 'user';
  String _hostname = 'linux-learning';
  Map<String, dynamic> _processes = {};
  int _nextPid = 1000;

  // Getters
  String get currentDirectory => _currentDirectory;
  String get currentUser => _currentUser;
  String get hostname => _hostname;
  List<String> get commandHistory => List.unmodifiable(_commandHistory);
  String get prompt => '$_currentUser@$_hostname:${_getShortPath(_currentDirectory)}\$ ';

  // Initialize virtual file system
  void initialize() {
    _initializeFileSystem();
    _initializeEnvironment();
    debugPrint('Terminal service initialized');
  }

  // Initialize virtual file system
  void _initializeFileSystem() {
    _fileSystem = {
      '/': {
        'type': 'directory',
        'contents': {
          'home': {
            'type': 'directory',
            'contents': {
              'user': {
                'type': 'directory',
                'contents': {
                  'Documents': {
                    'type': 'directory',
                    'contents': {
                      'readme.txt': {
                        'type': 'file',
                        'content': 'Welcome to Linux Learning!\nThis is a virtual terminal for practicing Linux commands.',
                        'size': 85,
                        'permissions': 'rw-r--r--',
                        'owner': 'user',
                        'group': 'user',
                      },
                      'sample.sh': {
                        'type': 'file',
                        'content': '#!/bin/bash\necho "Hello, Linux!"',
                        'size': 32,
                        'permissions': 'rwxr-xr-x',
                        'owner': 'user',
                        'group': 'user',
                      },
                    }
                  },
                  'Downloads': {
                    'type': 'directory',
                    'contents': {}
                  },
                  'Pictures': {
                    'type': 'directory',
                    'contents': {}
                  },
                }
              }
            }
          },
          'etc': {
            'type': 'directory',
            'contents': {
              'passwd': {
                'type': 'file',
                'content': 'root:x:0:0:root:/root:/bin/bash\nuser:x:1000:1000:user:/home/user:/bin/bash',
                'size': 82,
                'permissions': 'r--r--r--',
                'owner': 'root',
                'group': 'root',
              },
              'hosts': {
                'type': 'file',
                'content': '127.0.0.1\tlocalhost\n127.0.1.1\tlinux-learning',
                'size': 45,
                'permissions': 'r--r--r--',
                'owner': 'root',
                'group': 'root',
              }
            }
          },
          'var': {
            'type': 'directory',
            'contents': {
              'log': {
                'type': 'directory',
                'contents': {}
              }
            }
          },
          'tmp': {
            'type': 'directory',
            'contents': {}
          },
          'usr': {
            'type': 'directory',
            'contents': {
              'bin': {
                'type': 'directory',
                'contents': {}
              },
              'share': {
                'type': 'directory',
                'contents': {}
              }
            }
          }
        }
      }
    };
  }

  // Initialize environment variables
  void _initializeEnvironment() {
    _environment = {
      'PATH': '/usr/bin:/bin:/usr/local/bin',
      'HOME': '/home/$_currentUser',
      'USER': _currentUser,
      'SHELL': '/bin/bash',
      'PWD': _currentDirectory,
      'TERM': 'xterm-256color',
      'LANG': 'en_US.UTF-8',
    };
  }

  // Execute command
  Future<TerminalResult> executeCommand(String input) async {
    if (input.trim().isEmpty) {
      return TerminalResult(output: '', exitCode: 0);
    }

    // Add to history
    _addToHistory(input);

    // Parse command
    final parts = _parseCommand(input);
    if (parts.isEmpty) {
      return TerminalResult(output: '', exitCode: 0);
    }

    final command = parts[0];
    final args = parts.skip(1).toList();

    try {
      // Execute command
      switch (command) {
        case 'ls':
          return _executeLs(args);
        case 'cd':
          return _executeCd(args);
        case 'pwd':
          return _executePwd(args);
        case 'cat':
          return _executeCat(args);
        case 'echo':
          return _executeEcho(args);
        case 'mkdir':
          return _executeMkdir(args);
        case 'rmdir':
          return _executeRmdir(args);
        case 'rm':
          return _executeRm(args);
        case 'cp':
          return _executeCp(args);
        case 'mv':
          return _executeMv(args);
        case 'touch':
          return _executeTouch(args);
        case 'find':
          return _executeFind(args);
        case 'grep':
          return _executeGrep(args);
        case 'chmod':
          return _executeChmod(args);
        case 'chown':
          return _executeChown(args);
        case 'ps':
          return _executePs(args);
        case 'top':
          return _executeTop(args);
        case 'kill':
          return _executeKill(args);
        case 'df':
          return _executeDf(args);
        case 'du':
          return _executeDu(args);
        case 'which':
          return _executeWhich(args);
        case 'whoami':
          return _executeWhoami(args);
        case 'date':
          return _executeDate(args);
        case 'uptime':
          return _executeUptime(args);
        case 'history':
          return _executeHistory(args);
        case 'clear':
          return _executeClear(args);
        case 'man':
          return _executeMan(args);
        case 'help':
          return _executeHelp(args);
        case 'exit':
          return _executeExit(args);
        case 'env':
          return _executeEnv(args);
        case 'export':
          return _executeExport(args);
        case 'head':
          return _executeHead(args);
        case 'tail':
          return _executeTail(args);
        case 'wc':
          return _executeWc(args);
        case 'sort':
          return _executeSort(args);
        case 'uniq':
          return _executeUniq(args);
        case 'cut':
          return _executeCut(args);
        case 'sed':
          return _executeSed(args);
        case 'awk':
          return _executeAwk(args);
        case 'tar':
          return _executeTar(args);
        case 'gzip':
          return _executeGzip(args);
        case 'gunzip':
          return _executeGunzip(args);
        case 'wget':
          return _executeWget(args);
        case 'curl':
          return _executeCurl(args);
        case 'ping':
          return _executePing(args);
        case 'netstat':
          return _executeNetstat(args);
        case 'ssh':
          return _executeSsh(args);
        case 'scp':
          return _executeScp(args);
        default:
          return TerminalResult(
            output: '$command: command not found\nTip: ใช้คำสั่ง "help" เพื่อดูคำสั่งที่รองรับ',
            exitCode: 127,
            isError: true,
          );
      }
    } catch (e) {
      return TerminalResult(
        output: 'Error executing command: $e',
        exitCode: 1,
        isError: true,
      );
    }
  }

  // Parse command input
  List<String> _parseCommand(String input) {
    // Simple command parsing (can be enhanced for complex shell features)
    return input.trim().split(RegExp(r'\s+'));
  }

  // Add command to history
  void _addToHistory(String command) {
    _commandHistory.add(command);
    if (_commandHistory.length > 1000) {
      _commandHistory.removeAt(0);
    }
    _historyIndex = -1;
  }

  // Get previous command from history
  String? getPreviousCommand() {
    if (_commandHistory.isEmpty) return null;
    if (_historyIndex == -1) _historyIndex = _commandHistory.length - 1;
    else if (_historyIndex > 0) _historyIndex--;
    return _commandHistory[_historyIndex];
  }

  // Get next command from history
  String? getNextCommand() {
    if (_commandHistory.isEmpty || _historyIndex == -1) return null;
    if (_historyIndex < _commandHistory.length - 1) {
      _historyIndex++;
      return _commandHistory[_historyIndex];
    } else {
      _historyIndex = -1;
      return '';
    }
  }

  // Helper method to get short path for prompt
  String _getShortPath(String path) {
    if (path == '/home/$_currentUser') return '~';
    if (path.startsWith('/home/$_currentUser/')) {
      return '~${path.substring('/home/$_currentUser'.length)}';
    }
    return path;
  }

  // Helper method to resolve path
  String _resolvePath(String path) {
    if (path.isEmpty) return _currentDirectory;
    if (path.startsWith('/')) return path;
    if (path.startsWith('~/')) return '/home/$_currentUser${path.substring(1)}';
    if (path == '~') return '/home/$_currentUser';
    if (path == '.') return _currentDirectory;
    if (path == '..') {
      final parts = _currentDirectory.split('/');
      if (parts.length > 1) {
        parts.removeLast();
        return parts.join('/') == '' ? '/' : parts.join('/');
      }
      return '/';
    }
    return '$_currentDirectory/$path'.replaceAll('//', '/');
  }

  // Helper method to get file/directory from path
  Map<String, dynamic>? _getFileSystemItem(String path) {
    final resolvedPath = _resolvePath(path);
    final parts = resolvedPath.split('/').where((p) => p.isNotEmpty).toList();

    Map<String, dynamic> current = _fileSystem['/'];

    for (final part in parts) {
      if (current['type'] != 'directory' || current['contents'] == null) {
        return null;
      }
      if (!current['contents'].containsKey(part)) {
        return null;
      }
      current = current['contents'][part];
    }

    return current;
  }

  // Command implementations
  TerminalResult _executeLs(List<String> args) {
    String targetPath = _currentDirectory;
    bool showHidden = false;
    bool longFormat = false;
    bool showAll = false;

    // Parse arguments
    for (final arg in args) {
      if (arg.startsWith('-')) {
        if (arg.contains('a')) showAll = true;
        if (arg.contains('l')) longFormat = true;
        if (arg.contains('A')) showHidden = true;
      } else {
        targetPath = arg;
      }
    }

    final item = _getFileSystemItem(targetPath);
    if (item == null) {
      return TerminalResult(
        output: 'ls: cannot access \'$targetPath\': No such file or directory',
        exitCode: 2,
        isError: true,
      );
    }

    if (item['type'] != 'directory') {
      return TerminalResult(
        output: targetPath.split('/').last,
        exitCode: 0,
      );
    }

    final contents = item['contents'] as Map<String, dynamic>;
    final entries = <String>[];

    if (showAll || showHidden) {
      entries.add('.');
      entries.add('..');
    }

    contents.forEach((name, data) {
      if (!showAll && !showHidden && name.startsWith('.')) return;
      entries.add(name);
    });

    entries.sort();

    if (longFormat) {
      final output = StringBuffer();
      for (final entry in entries) {
        if (entry == '.' || entry == '..') {
          output.writeln('drwxr-xr-x 1 $_currentUser $_currentUser 4096 ${DateTime.now().toString().substring(0, 16)} $entry');
        } else {
          final data = contents[entry];
          final permissions = data['permissions'] ?? 'rw-r--r--';
          final size = data['size'] ?? 0;
          final owner = data['owner'] ?? _currentUser;
          final group = data['group'] ?? _currentUser;
          final type = data['type'] == 'directory' ? 'd' : '-';

          output.writeln('$type$permissions 1 $owner $group $size ${DateTime.now().toString().substring(0, 16)} $entry');
        }
      }
      return TerminalResult(output: output.toString().trim(), exitCode: 0);
    } else {
      return TerminalResult(output: entries.join('  '), exitCode: 0);
    }
  }

  TerminalResult _executeCd(List<String> args) {
    String targetPath = args.isEmpty ? '/home/$_currentUser' : args[0];
    final resolvedPath = _resolvePath(targetPath);

    final item = _getFileSystemItem(resolvedPath);
    if (item == null) {
      return TerminalResult(
        output: 'cd: no such file or directory: $targetPath',
        exitCode: 1,
        isError: true,
      );
    }

    if (item['type'] != 'directory') {
      return TerminalResult(
        output: 'cd: not a directory: $targetPath',
        exitCode: 1,
        isError: true,
      );
    }

    _currentDirectory = resolvedPath;
    _environment['PWD'] = _currentDirectory;
    return TerminalResult(output: '', exitCode: 0);
  }

  TerminalResult _executePwd(List<String> args) {
    return TerminalResult(output: _currentDirectory, exitCode: 0);
  }

  TerminalResult _executeCat(List<String> args) {
    if (args.isEmpty) {
      return TerminalResult(
        output: 'cat: missing file operand',
        exitCode: 1,
        isError: true,
      );
    }

    final output = StringBuffer();
    for (final filename in args) {
      final item = _getFileSystemItem(filename);
      if (item == null) {
        output.writeln('cat: $filename: No such file or directory');
        continue;
      }

      if (item['type'] != 'file') {
        output.writeln('cat: $filename: Is a directory');
        continue;
      }

      output.writeln(item['content'] ?? '');
    }

    return TerminalResult(output: output.toString().trim(), exitCode: 0);
  }

  TerminalResult _executeEcho(List<String> args) {
    return TerminalResult(output: args.join(' '), exitCode: 0);
  }

  TerminalResult _executeMkdir(List<String> args) {
    if (args.isEmpty) {
      return TerminalResult(
        output: 'mkdir: missing operand',
        exitCode: 1,
        isError: true,
      );
    }

    for (final dirname in args) {
      final resolvedPath = _resolvePath(dirname);
      final pathParts = resolvedPath.split('/').where((p) => p.isNotEmpty).toList();
      final parentPath = pathParts.length > 1
          ? '/' + pathParts.sublist(0, pathParts.length - 1).join('/')
          : '/';
      final dirName = pathParts.last;

      final parentItem = _getFileSystemItem(parentPath);
      if (parentItem == null || parentItem['type'] != 'directory') {
        return TerminalResult(
          output: 'mkdir: cannot create directory \'$dirname\': No such file or directory',
          exitCode: 1,
          isError: true,
        );
      }

      final contents = parentItem['contents'] as Map<String, dynamic>;
      if (contents.containsKey(dirName)) {
        return TerminalResult(
          output: 'mkdir: cannot create directory \'$dirname\': File exists',
          exitCode: 1,
          isError: true,
        );
      }

      contents[dirName] = {
        'type': 'directory',
        'contents': <String, dynamic>{},
        'permissions': 'rwxr-xr-x',
        'owner': _currentUser,
        'group': _currentUser,
      };
    }

    return TerminalResult(output: '', exitCode: 0);
  }

  TerminalResult _executeRmdir(List<String> args) {
    if (args.isEmpty) {
      return TerminalResult(
        output: 'rmdir: missing operand',
        exitCode: 1,
        isError: true,
      );
    }

    for (final dirname in args) {
      final item = _getFileSystemItem(dirname);
      if (item == null) {
        return TerminalResult(
          output: 'rmdir: failed to remove \'$dirname\': No such file or directory',
          exitCode: 1,
          isError: true,
        );
      }

      if (item['type'] != 'directory') {
        return TerminalResult(
          output: 'rmdir: failed to remove \'$dirname\': Not a directory',
          exitCode: 1,
          isError: true,
        );
      }

      final contents = item['contents'] as Map<String, dynamic>;
      if (contents.isNotEmpty) {
        return TerminalResult(
          output: 'rmdir: failed to remove \'$dirname\': Directory not empty',
          exitCode: 1,
          isError: true,
        );
      }

      // Remove directory
      final resolvedPath = _resolvePath(dirname);
      final pathParts = resolvedPath.split('/').where((p) => p.isNotEmpty).toList();
      final parentPath = pathParts.length > 1
          ? '/' + pathParts.sublist(0, pathParts.length - 1).join('/')
          : '/';
      final dirName = pathParts.last;

      final parentItem = _getFileSystemItem(parentPath);
      if (parentItem != null && parentItem['type'] == 'directory') {
        final parentContents = parentItem['contents'] as Map<String, dynamic>;
        parentContents.remove(dirName);
      }
    }

    return TerminalResult(output: '', exitCode: 0);
  }

  TerminalResult _executeTouch(List<String> args) {
    if (args.isEmpty) {
      return TerminalResult(
        output: 'touch: missing file operand',
        exitCode: 1,
        isError: true,
      );
    }

    for (final filename in args) {
      final resolvedPath = _resolvePath(filename);
      final pathParts = resolvedPath.split('/').where((p) => p.isNotEmpty).toList();
      final parentPath = pathParts.length > 1
          ? '/' + pathParts.sublist(0, pathParts.length - 1).join('/')
          : '/';
      final fileName = pathParts.last;

      final parentItem = _getFileSystemItem(parentPath);
      if (parentItem == null || parentItem['type'] != 'directory') {
        return TerminalResult(
          output: 'touch: cannot touch \'$filename\': No such file or directory',
          exitCode: 1,
          isError: true,
        );
      }

      final contents = parentItem['contents'] as Map<String, dynamic>;
      if (!contents.containsKey(fileName)) {
        contents[fileName] = {
          'type': 'file',
          'content': '',
          'size': 0,
          'permissions': 'rw-r--r--',
          'owner': _currentUser,
          'group': _currentUser,
        };
      }
    }

    return TerminalResult(output: '', exitCode: 0);
  }

  TerminalResult _executeWhoami(List<String> args) {
    return TerminalResult(output: _currentUser, exitCode: 0);
  }

  TerminalResult _executeDate(List<String> args) {
    return TerminalResult(output: DateTime.now().toString(), exitCode: 0);
  }

  TerminalResult _executeHistory(List<String> args) {
    final output = StringBuffer();
    for (int i = 0; i < _commandHistory.length; i++) {
      output.writeln('${i + 1}  ${_commandHistory[i]}');
    }
    return TerminalResult(output: output.toString().trim(), exitCode: 0);
  }

  TerminalResult _executeClear(List<String> args) {
    return TerminalResult(output: '\x1B[2J\x1B[H', exitCode: 0, clearScreen: true);
  }

  TerminalResult _executeHelp(List<String> args) {
    const helpText = '''
คำสั่ง Linux ที่รองรับ:

การจัดการไฟล์และไดเร็กทอรี:
  ls [options] [path]    - แสดงรายการไฟล์
  cd [path]             - เปลี่ยนไดเร็กทอรี  
  pwd                   - แสดงไดเร็กทอรีปัจจุบัน
  mkdir <name>          - สร้างไดเร็กทอรี
  rmdir <name>          - ลบไดเร็กทอรี (ว่าง)
  touch <file>          - สร้างไฟล์เปล่า
  rm <file>             - ลบไฟล์
  cp <src> <dest>       - คัดลอกไฟล์
  mv <src> <dest>       - ย้าย/เปลี่ยนชื่อไฟล์

การอ่านไฟล์:
  cat <file>            - แสดงเนื้อหาไฟล์
  head <file>           - แสดง 10 บรรทัดแรก
  tail <file>           - แสดง 10 บรรทัดสุดท้าย

ข้อมูลระบบ:
  whoami                - แสดงชื่อผู้ใช้
  date                  - แสดงวันที่และเวลา
  pwd                   - แสดงไดเร็กทอรีปัจจุบัน

อื่นๆ:
  echo <text>           - แสดงข้อความ
  history               - แสดงประวัติคำสั่ง
  clear                 - ล้างหน้าจอ
  help                  - แสดงความช่วยเหลือนี้
  exit                  - ออกจากเทอร์มินัล

เคล็ดลับ: ใช้ Tab สำหรับ autocomplete, ↑↓ สำหรับดูประวัติคำสั่ง
''';
    return TerminalResult(output: helpText, exitCode: 0);
  }

  // Placeholder implementations for other commands
  TerminalResult _executeRm(List<String> args) => TerminalResult(output: 'rm: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeCp(List<String> args) => TerminalResult(output: 'cp: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeMv(List<String> args) => TerminalResult(output: 'mv: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeFind(List<String> args) => TerminalResult(output: 'find: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeGrep(List<String> args) => TerminalResult(output: 'grep: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeChmod(List<String> args) => TerminalResult(output: 'chmod: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeChown(List<String> args) => TerminalResult(output: 'chown: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executePs(List<String> args) => TerminalResult(output: 'PID TTY TIME CMD\n1234 pts/0 00:00:01 bash', exitCode: 0);
  TerminalResult _executeTop(List<String> args) => TerminalResult(output: 'top: not implemented in demo mode', exitCode: 1, isError: true);
  TerminalResult _executeKill(List<String> args) => TerminalResult(output: 'kill: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeDf(List<String> args) => TerminalResult(output: 'Filesystem Size Used Avail Use% Mounted on\n/dev/sda1 20G 5.2G 13G 30% /', exitCode: 0);
  TerminalResult _executeDu(List<String> args) => TerminalResult(output: 'du: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeWhich(List<String> args) => TerminalResult(output: args.isNotEmpty ? '/usr/bin/${args[0]}' : '', exitCode: 0);
  TerminalResult _executeUptime(List<String> args) => TerminalResult(output: 'up 1 day, 2:30, 1 user, load average: 0.15, 0.10, 0.05', exitCode: 0);
  TerminalResult _executeMan(List<String> args) => TerminalResult(output: 'man: manual pages not available in demo mode', exitCode: 1, isError: true);
  TerminalResult _executeExit(List<String> args) => TerminalResult(output: 'exit', exitCode: 0, shouldExit: true);
  TerminalResult _executeEnv(List<String> args) => TerminalResult(output: _environment.entries.map((e) => '${e.key}=${e.value}').join('\n'), exitCode: 0);
  TerminalResult _executeExport(List<String> args) => TerminalResult(output: 'export: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeHead(List<String> args) => TerminalResult(output: 'head: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeTail(List<String> args) => TerminalResult(output: 'tail: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeWc(List<String> args) => TerminalResult(output: 'wc: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeSort(List<String> args) => TerminalResult(output: 'sort: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeUniq(List<String> args) => TerminalResult(output: 'uniq: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeCut(List<String> args) => TerminalResult(output: 'cut: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeSed(List<String> args) => TerminalResult(output: 'sed: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeAwk(List<String> args) => TerminalResult(output: 'awk: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeTar(List<String> args) => TerminalResult(output: 'tar: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeGzip(List<String> args) => TerminalResult(output: 'gzip: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeGunzip(List<String> args) => TerminalResult(output: 'gunzip: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeWget(List<String> args) => TerminalResult(output: 'wget: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeCurl(List<String> args) => TerminalResult(output: 'curl: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executePing(List<String> args) => TerminalResult(output: 'ping: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeNetstat(List<String> args) => TerminalResult(output: 'netstat: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeSsh(List<String> args) => TerminalResult(output: 'ssh: not implemented in demo', exitCode: 1, isError: true);
  TerminalResult _executeScp(List<String> args) => TerminalResult(output: 'scp: not implemented in demo', exitCode: 1, isError: true);

  // Reset terminal to initial state
  void reset() {
    _currentDirectory = '/home/user';
    _commandHistory.clear();
    _historyIndex = -1;
    _initializeFileSystem();
    _initializeEnvironment();
  }
}

// Terminal result class
class TerminalResult {
  final String output;
  final int exitCode;
  final bool isError;
  final bool clearScreen;
  final bool shouldExit;
  final Map<String, dynamic>? metadata;

  const TerminalResult({
    required this.output,
    required this.exitCode,
    this.isError = false,
    this.clearScreen = false,
    this.shouldExit = false,
    this.metadata,
  });

  bool get isSuccess => exitCode == 0;
}