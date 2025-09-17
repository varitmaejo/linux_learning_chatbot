import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/colors.dart';
import '../../data/models/file_system.dart';

class FileExplorer extends StatefulWidget {
  final FileSystemNode rootNode;
  final Function(FileSystemNode)? onFileSelected;
  final Function(FileSystemNode)? onDirectoryChanged;
  final Function(String)? onCommandGenerated;
  final bool showHiddenFiles;
  final bool allowMultiSelect;
  final String currentPath;

  const FileExplorer({
    Key? key,
    required this.rootNode,
    this.onFileSelected,
    this.onDirectoryChanged,
    this.onCommandGenerated,
    this.showHiddenFiles = false,
    this.allowMultiSelect = false,
    this.currentPath = '/',
  }) : super(key: key);

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer>
    with SingleTickerProviderStateMixin {
  late FileSystemNode _currentNode;
  final Set<String> _selectedFiles = {};
  final Map<String, bool> _expandedDirectories = {};
  late AnimationController _animationController;
  String _sortBy = 'name'; // name, type, size, modified
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _currentNode = _findNodeByPath(widget.currentPath) ?? widget.rootNode;
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  FileSystemNode? _findNodeByPath(String path) {
    if (path == '/') return widget.rootNode;

    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    FileSystemNode? current = widget.rootNode;

    for (final part in parts) {
      if (current?.children != null) {
        current = current!.children!.firstWhere(
              (child) => child.name == part,
          orElse: () => current!,
        );
      } else {
        break;
      }
    }

    return current;
  }

  List<FileSystemNode> _getFilteredAndSortedChildren(FileSystemNode node) {
    if (node.children == null) return [];

    List<FileSystemNode> children = node.children!.where((child) {
      if (!widget.showHiddenFiles && child.name.startsWith('.')) {
        return false;
      }
      return true;
    }).toList();

    children.sort((a, b) {
      int result = 0;

      // Directories first
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;

      switch (_sortBy) {
        case 'name':
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case 'type':
          result = a.type.compareTo(b.type);
          break;
        case 'size':
          result = (a.size ?? 0).compareTo(b.size ?? 0);
          break;
        case 'modified':
          result = (a.modifiedTime ?? DateTime.now())
              .compareTo(b.modifiedTime ?? DateTime.now());
          break;
      }

      return _sortAscending ? result : -result;
    });

    return children;
  }

  void _navigateToDirectory(FileSystemNode directory) {
    if (!directory.isDirectory) return;

    setState(() {
      _currentNode = directory;
      _selectedFiles.clear();
    });

    widget.onDirectoryChanged?.call(directory);
  }

  void _selectFile(FileSystemNode file) {
    if (widget.allowMultiSelect) {
      setState(() {
        if (_selectedFiles.contains(file.path)) {
          _selectedFiles.remove(file.path);
        } else {
          _selectedFiles.add(file.path);
        }
      });
    } else {
      setState(() {
        _selectedFiles.clear();
        _selectedFiles.add(file.path);
      });
    }

    widget.onFileSelected?.call(file);
  }

  void _toggleDirectoryExpansion(String path) {
    setState(() {
      _expandedDirectories[path] = !(_expandedDirectories[path] ?? false);
    });
  }

  void _generateCommand(String command, FileSystemNode node) {
    final commandText = command.replaceAll('{path}', node.path);
    widget.onCommandGenerated?.call(commandText);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        _buildPathBreadcrumb(),
        Expanded(
          child: _buildFileList(),
        ),
        if (_selectedFiles.isNotEmpty) _buildActionBar(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border(bottom: BorderSide(color: Colors.grey[700]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: _canGoBack() ? _goBack : null,
            tooltip: 'Back',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward, color: Colors.white70),
            onPressed: _canGoUp() ? _goUp : null,
            tooltip: 'Parent Directory',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
          const Spacer(),
          _buildSortMenu(),
          IconButton(
            icon: Icon(
              widget.showHiddenFiles ? Icons.visibility : Icons.visibility_off,
              color: Colors.white70,
            ),
            onPressed: _toggleHiddenFiles,
            tooltip: 'Toggle Hidden Files',
          ),
          _buildViewModeToggle(),
        ],
      ),
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort, color: Colors.white70),
      onSelected: (value) {
        setState(() {
          if (_sortBy == value) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = value;
            _sortAscending = true;
          }
        });
      },
      itemBuilder: (context) => [
        _buildSortMenuItem('name', 'Name'),
        _buildSortMenuItem('type', 'Type'),
        _buildSortMenuItem('size', 'Size'),
        _buildSortMenuItem('modified', 'Modified'),
      ],
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            _sortBy == value
                ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.sort,
            size: 16,
            color: _sortBy == value ? AppColors.primaryColor : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return IconButton(
      icon: const Icon(Icons.view_list, color: Colors.white70),
      onPressed: () {
        // Toggle between list and grid view
        // Implementation would depend on requirements
      },
      tooltip: 'View Mode',
    );
  }

  Widget _buildPathBreadcrumb() {
    final pathParts = _currentNode.path.split('/').where((p) => p.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(bottom: BorderSide(color: Colors.grey[700]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.folder, color: Colors.blue[300], size: 16),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _navigateToDirectory(widget.rootNode),
            child: Text(
              '/',
              style: TextStyle(
                color: Colors.blue[300],
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
          ...pathParts.map((part) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '/',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final targetPath = '/' + pathParts.take(pathParts.indexOf(part) + 1).join('/');
                    final targetNode = _findNodeByPath(targetPath);
                    if (targetNode != null) {
                      _navigateToDirectory(targetNode);
                    }
                  },
                  child: Text(
                    part,
                    style: TextStyle(
                      color: Colors.blue[300],
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    final children = _getFilteredAndSortedChildren(_currentNode);

    if (children.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'This directory is empty',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: children.length,
      itemBuilder: (context, index) {
        final node = children[index];
        return _buildFileItem(node);
      },
    );
  }

  Widget _buildFileItem(FileSystemNode node) {
    final isSelected = _selectedFiles.contains(node.path);
    final isExpanded = _expandedDirectories[node.path] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : null,
        border: Border(
          left: BorderSide(
            color: isSelected ? AppColors.primaryColor : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: _buildFileIcon(node),
            title: Text(
              node.name,
              style: TextStyle(
                color: isSelected ? AppColors.primaryColor : Colors.white,
                fontFamily: 'monospace',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: _buildFileSubtitle(node),
            trailing: _buildFileTrailing(node),
            onTap: () => _onFileItemTap(node),
            onLongPress: () => _showContextMenu(node),
          ),
          if (node.isDirectory && isExpanded && node.children != null)
            _buildExpandedDirectory(node),
        ],
      ),
    );
  }

  Widget _buildFileIcon(FileSystemNode node) {
    IconData icon;
    Color color;

    if (node.isDirectory) {
      icon = _expandedDirectories[node.path] == true
          ? Icons.folder_open
          : Icons.folder;
      color = Colors.blue[300]!;
    } else {
      final extension = node.name.split('.').last.toLowerCase();
      switch (extension) {
        case 'txt':
        case 'md':
        case 'readme':
          icon = Icons.description;
          color = Colors.yellow[300]!;
          break;
        case 'json':
        case 'xml':
        case 'yaml':
          icon = Icons.code;
          color = Colors.orange[300]!;
          break;
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
          icon = Icons.image;
          color = Colors.purple[300]!;
          break;
        case 'mp3':
        case 'wav':
        case 'flac':
          icon = Icons.audiotrack;
          color = Colors.green[300]!;
          break;
        case 'mp4':
        case 'avi':
        case 'mov':
          icon = Icons.videocam;
          color = Colors.red[300]!;
          break;
        case 'sh':
        case 'bash':
          icon = Icons.terminal;
          color = Colors.green[400]!;
          break;
        default:
          if (node.permissions?.contains('x') == true) {
            icon = Icons.play_arrow;
            color = Colors.green[300]!;
          } else {
            icon = Icons.insert_drive_file;
            color = Colors.grey[400]!;
          }
      }
    }

    return Stack(
      children: [
        Icon(icon, color: color, size: 24),
        if (_selectedFiles.contains(node.path))
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 8,
              ),
            ),
          ),
      ],
    );
  }

  Widget? _buildFileSubtitle(FileSystemNode node) {
    if (node.isDirectory) {
      final childCount = node.children?.length ?? 0;
      return Text(
        '$childCount items',
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
      );
    } else {
      return Text(
        '${_formatFileSize(node.size)} • ${_formatDate(node.modifiedTime)}',
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
      );
    }
  }

  Widget? _buildFileTrailing(FileSystemNode node) {
    if (node.isDirectory) {
      return IconButton(
        icon: Icon(
          _expandedDirectories[node.path] == true
              ? Icons.expand_less
              : Icons.expand_more,
          color: Colors.grey[500],
        ),
        onPressed: () => _toggleDirectoryExpansion(node.path),
      );
    }
    return null;
  }

  Widget _buildExpandedDirectory(FileSystemNode directory) {
    final children = _getFilteredAndSortedChildren(directory);

    return Container(
      margin: const EdgeInsets.only(left: 32),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
      ),
      child: Column(
        children: children.map((child) {
          return _buildFileItem(child);
        }).toList(),
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border(top: BorderSide(color: Colors.grey[700]!)),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedFiles.length} selected',
            style: const TextStyle(color: Colors.white70),
          ),
          const Spacer(),
          _buildActionButton('Copy', Icons.copy, () => _copyFiles()),
          _buildActionButton('Move', Icons.cut, () => _moveFiles()),
          _buildActionButton('Delete', Icons.delete, () => _deleteFiles()),
          _buildActionButton('Properties', Icons.info, () => _showProperties()),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  void _onFileItemTap(FileSystemNode node) {
    if (node.isDirectory) {
      if (_expandedDirectories[node.path] == true) {
        _navigateToDirectory(node);
      } else {
        _toggleDirectoryExpansion(node.path);
      }
    } else {
      _selectFile(node);
    }
  }

  void _showContextMenu(FileSystemNode node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildContextMenu(node),
    );
  }

  Widget _buildContextMenu(FileSystemNode node) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: _buildFileIcon(node),
            title: Text(
              node.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              node.path,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
          const Divider(color: Colors.grey),
          if (node.isDirectory) ...[
            _buildContextMenuItem(
              icon: Icons.folder_open,
              title: 'Open',
              onTap: () {
                Navigator.pop(context);
                _navigateToDirectory(node);
              },
            ),
            _buildContextMenuItem(
              icon: Icons.terminal,
              title: 'Open in Terminal',
              onTap: () {
                Navigator.pop(context);
                _generateCommand('cd {path}', node);
              },
            ),
          ] else ...[
            _buildContextMenuItem(
              icon: Icons.visibility,
              title: 'View',
              onTap: () {
                Navigator.pop(context);
                _generateCommand('cat {path}', node);
              },
            ),
            _buildContextMenuItem(
              icon: Icons.edit,
              title: 'Edit',
              onTap: () {
                Navigator.pop(context);
                _generateCommand('nano {path}', node);
              },
            ),
          ],
          _buildContextMenuItem(
            icon: Icons.copy,
            title: 'Copy Path',
            onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: node.path));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied: ${node.path}')),
              );
            },
          ),
          _buildContextMenuItem(
            icon: Icons.info,
            title: 'Properties',
            onTap: () {
              Navigator.pop(context);
              _showProperties();
            },
          ),
          _buildContextMenuItem(
            icon: Icons.delete,
            title: 'Delete',
            onTap: () {
              Navigator.pop(context);
              _confirmDelete([node]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContextMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: onTap,
    );
  }

  bool _canGoBack() {
    // Implementation would depend on navigation history
    return true;
  }

  bool _canGoUp() {
    return _currentNode.path != '/';
  }

  void _goBack() {
    // Implementation would depend on navigation history
  }

  void _goUp() {
    final parentPath = _currentNode.path.substring(0, _currentNode.path.lastIndexOf('/'));
    final parentNode = _findNodeByPath(parentPath.isEmpty ? '/' : parentPath);
    if (parentNode != null) {
      _navigateToDirectory(parentNode);
    }
  }

  void _refresh() {
    setState(() {
      // Refresh the current directory
    });
  }

  void _toggleHiddenFiles() {
    // This would be handled by the parent widget
    setState(() {
      // Toggle implementation
    });
  }

  void _copyFiles() {
    final selectedNodes = _getSelectedNodes();
    if (selectedNodes.isNotEmpty) {
      final paths = selectedNodes.map((node) => node.path).join(' ');
      _generateCommand('cp $paths', selectedNodes.first);
    }
  }

  void _moveFiles() {
    final selectedNodes = _getSelectedNodes();
    if (selectedNodes.isNotEmpty) {
      final paths = selectedNodes.map((node) => node.path).join(' ');
      _generateCommand('mv $paths', selectedNodes.first);
    }
  }

  void _deleteFiles() {
    final selectedNodes = _getSelectedNodes();
    if (selectedNodes.isNotEmpty) {
      _confirmDelete(selectedNodes);
    }
  }

  void _confirmDelete(List<FileSystemNode> nodes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          nodes.length == 1
              ? 'Are you sure you want to delete "${nodes.first.name}"?'
              : 'Are you sure you want to delete ${nodes.length} items?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final paths = nodes.map((node) => node.path).join(' ');
              _generateCommand('rm -rf $paths', nodes.first);
              setState(() {
                _selectedFiles.clear();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showProperties() {
    final selectedNodes = _getSelectedNodes();
    if (selectedNodes.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => _buildPropertiesDialog(selectedNodes.first),
    );
  }

  Widget _buildPropertiesDialog(FileSystemNode node) {
    return AlertDialog(
      title: Text('Properties: ${node.name}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPropertyRow('Name', node.name),
            _buildPropertyRow('Path', node.path),
            _buildPropertyRow('Type', node.isDirectory ? 'Directory' : 'File'),
            if (!node.isDirectory) ...[
              _buildPropertyRow('Size', _formatFileSize(node.size)),
              _buildPropertyRow('Extension', _getFileExtension(node.name)),
            ],
            _buildPropertyRow('Permissions', node.permissions ?? 'N/A'),
            _buildPropertyRow('Owner', node.owner ?? 'N/A'),
            _buildPropertyRow('Group', node.group ?? 'N/A'),
            _buildPropertyRow(
              'Modified',
              _formatDateTime(node.modifiedTime),
            ),
            _buildPropertyRow(
              'Created',
              _formatDateTime(node.createdTime),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  List<FileSystemNode> _getSelectedNodes() {
    return _selectedFiles
        .map((path) => _findNodeByPath(path))
        .where((node) => node != null)
        .cast<FileSystemNode>()
        .toList();
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getFileExtension(String filename) {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last : 'None';
  }
}

// Compact File Explorer for embedded use
class CompactFileExplorer extends StatefulWidget {
  final FileSystemNode rootNode;
  final Function(FileSystemNode)? onFileSelected;
  final double height;

  const CompactFileExplorer({
    Key? key,
    required this.rootNode,
    this.onFileSelected,
    this.height = 300,
  }) : super(key: key);

  @override
  State<CompactFileExplorer> createState() => _CompactFileExplorerState();
}

class _CompactFileExplorerState extends State<CompactFileExplorer> {
  late FileSystemNode _currentNode;

  @override
  void initState() {
    super.initState();
    _currentNode = widget.rootNode;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        children: [
          _buildCompactHeader(),
          Expanded(
            child: _buildCompactFileList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.folder, color: Colors.blue[300], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _currentNode.path,
              style: TextStyle(
                color: Colors.blue[300],
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          if (_currentNode.path != '/')
            IconButton(
              icon: const Icon(Icons.arrow_upward, color: Colors.white70, size: 16),
              onPressed: _goUp,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactFileList() {
    final children = _currentNode.children ?? [];

    return ListView.builder(
      itemCount: children.length,
      itemBuilder: (context, index) {
        final node = children[index];
        return _buildCompactFileItem(node);
      },
    );
  }

  Widget _buildCompactFileItem(FileSystemNode node) {
    return ListTile(
      dense: true,
      leading: _buildCompactFileIcon(node),
      title: Text(
        node.name,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
      onTap: () {
        if (node.isDirectory) {
          setState(() {
            _currentNode = node;
          });
        } else {
          widget.onFileSelected?.call(node);
        }
      },
    );
  }

  Widget _buildCompactFileIcon(FileSystemNode node) {
    if (node.isDirectory) {
      return Icon(Icons.folder, color: Colors.blue[300], size: 16);
    } else {
      return Icon(Icons.insert_drive_file, color: Colors.grey[400], size: 16);
    }
  }

  void _goUp() {
    // Navigate to parent directory logic would go here
    // For now, this is a placeholder
  }
}

// Tree View File Explorer
class TreeFileExplorer extends StatefulWidget {
  final FileSystemNode rootNode;
  final Function(FileSystemNode)? onNodeSelected;
  final Set<String> expandedPaths;

  const TreeFileExplorer({
    Key? key,
    required this.rootNode,
    this.onNodeSelected,
    this.expandedPaths = const {},
  }) : super(key: key);

  @override
  State<TreeFileExplorer> createState() => _TreeFileExplorerState();
}

class _TreeFileExplorerState extends State<TreeFileExplorer> {
  final Set<String> _expandedPaths = {};
  String? _selectedPath;

  @override
  void initState() {
    super.initState();
    _expandedPaths.addAll(widget.expandedPaths);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: _buildTreeNode(widget.rootNode, 0),
      ),
    );
  }

  Widget _buildTreeNode(FileSystemNode node, int depth) {
    final isExpanded = _expandedPaths.contains(node.path);
    final isSelected = _selectedPath == node.path;
    final hasChildren = node.children?.isNotEmpty == true;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _onNodeTap(node),
          child: Container(
            padding: EdgeInsets.only(
              left: 8.0 + (depth * 16.0),
              right: 8.0,
              top: 4.0,
              bottom: 4.0,
            ),
            color: isSelected ? AppColors.primaryColor.withOpacity(0.2) : null,
            child: Row(
              children: [
                if (node.isDirectory && hasChildren)
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 16,
                    color: Colors.grey[500],
                  )
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 4),
                _buildTreeNodeIcon(node),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(
                      color: isSelected ? AppColors.primaryColor : Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded && node.children != null)
          ...node.children!.map((child) => _buildTreeNode(child, depth + 1)),
      ],
    );
  }

  Widget _buildTreeNodeIcon(FileSystemNode node) {
    if (node.isDirectory) {
      return Icon(
        Icons.folder,
        color: Colors.blue[300],
        size: 16,
      );
    } else {
      return Icon(
        Icons.insert_drive_file,
        color: Colors.grey[400],
        size: 16,
      );
    }
  }

  void _onNodeTap(FileSystemNode node) {
    setState(() {
      _selectedPath = node.path;

      if (node.isDirectory && node.children?.isNotEmpty == true) {
        if (_expandedPaths.contains(node.path)) {
          _expandedPaths.remove(node.path);
        } else {
          _expandedPaths.add(node.path);
        }
      }
    });

    widget.onNodeSelected?.call(node);
  }
}