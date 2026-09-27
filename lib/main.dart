import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'controllers/popover_controller.dart';
import 'state/popover_state.dart';
import 'widgets/context_menu_popover.dart';
import 'widgets/dropdown_popover.dart';
import 'widgets/modal_popover.dart';
import 'widgets/tooltip_popover.dart';

void main() {
  runApp(const PopoverProApp());
}

/// A single popover definition loaded from
/// `assets/popover_config.json`, following the schema:
/// { id, type, position, content, backgroundColor, animationDuration }
class PopoverConfigEntry {
  const PopoverConfigEntry({
    required this.id,
    required this.type,
    required this.position,
    required this.content,
    required this.backgroundColor,
    required this.animationDuration,
  });

  final String id;
  final String type;
  final String position;
  final String content;
  final Color backgroundColor;
  final Duration animationDuration;

  factory PopoverConfigEntry.fromJson(Map<String, dynamic> json) {
    return PopoverConfigEntry(
      id: json['id'] as String,
      type: json['type'] as String,
      position: json['position'] as String,
      content: json['content'] as String,
      backgroundColor: _colorFromHex(json['backgroundColor'] as String),
      animationDuration:
          Duration(milliseconds: (json['animationDuration'] as num).toInt()),
    );
  }

  static Color _colorFromHex(String hex) {
    var value = hex.replaceFirst('#', '');
    if (value.length == 6) value = 'FF$value';
    return Color(int.parse(value, radix: 16));
  }
}

/// Loads and parses `assets/popover_config.json` into a list of
/// [PopoverConfigEntry] objects, keyed by id for convenient lookup.
class PopoverConfigLoader {
  static Future<Map<String, PopoverConfigEntry>> load() async {
    final raw =
        await rootBundle.loadString('assets/popover_config.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = (decoded['popovers'] as List)
        .cast<Map<String, dynamic>>()
        .map(PopoverConfigEntry.fromJson)
        .toList();
    return {for (final entry in list) entry.id: entry};
  }
}

class PopoverProApp extends StatelessWidget {
  const PopoverProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PopoverPro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3F51B5),
        useMaterial3: true,
      ),
      home: const PopoverDemoScreen(),
    );
  }
}

class PopoverDemoScreen extends StatefulWidget {
  const PopoverDemoScreen({super.key});

  @override
  State<PopoverDemoScreen> createState() => _PopoverDemoScreenState();
}

class _PopoverDemoScreenState extends State<PopoverDemoScreen> {
  late final PopoverState _popoverState;
  late final PopoverController _popoverController;

  final GlobalKey<ContextMenuPopoverState> _nestedMenuKey =
      GlobalKey<ContextMenuPopoverState>();
  final GlobalKey<ModalPopoverState> _modalKey =
      GlobalKey<ModalPopoverState>();

  Map<String, PopoverConfigEntry>? _config;
  String _statusMessage = 'No popover interacted with yet.';

  @override
  void initState() {
    super.initState();
    _popoverState = PopoverState();
    _popoverController = PopoverController(state: _popoverState);
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await PopoverConfigLoader.load();
    if (mounted) setState(() => _config = config);
  }

  @override
  void dispose() {
    _popoverController.dispose();
    _popoverState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;

    return PopoverScope(
      state: _popoverState,
      child: Scaffold(
        appBar: AppBar(title: const Text('PopoverPro')),
        body: config == null
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Status: $_statusMessage',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Tooltip'),
                      Center(
                        child: TooltipPopover(
                          controller: _popoverController,
                          id: config['info-tooltip']!.id,
                          message: config['info-tooltip']!.content,
                          backgroundColor:
                              config['info-tooltip']!.backgroundColor,
                          animationDuration:
                              config['info-tooltip']!.animationDuration,
                          child: const Icon(Icons.info_outline, size: 32),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _sectionTitle('Dropdown (tap an item to open a '
                          'nested context menu)'),
                      Center(
                        child: DropdownPopover(
                          controller: _popoverController,
                          id: config['actions-dropdown']!.id,
                          items: config['actions-dropdown']!
                              .content
                              .split('|'),
                          backgroundColor:
                              config['actions-dropdown']!.backgroundColor,
                          animationDuration:
                              config['actions-dropdown']!.animationDuration,
                          onItemSelected: (index, label, position) {
                            setState(() =>
                                _statusMessage = 'Dropdown item "$label" tapped');
                            // Nested popover: open a context menu right at
                            // the position of the tapped dropdown item.
                            _nestedMenuKey.currentState
                                ?.showAt(context, position);
                          },
                          child: ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.more_vert),
                            label: const Text('Actions'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _sectionTitle('Context menu (long-press)'),
                      ContextMenuPopover(
                        controller: _popoverController,
                        id: config['card-context-menu']!.id,
                        items:
                            config['card-context-menu']!.content.split('|'),
                        backgroundColor:
                            config['card-context-menu']!.backgroundColor,
                        animationDuration:
                            config['card-context-menu']!.animationDuration,
                        onItemSelected: (index, label) {
                          setState(() =>
                              _statusMessage = 'Context menu item "$label" selected');
                        },
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text('Long-press this card'),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _sectionTitle('Modal'),
                      ModalPopover(
                        key: _modalKey,
                        controller: _popoverController,
                        id: config['settings-modal']!.id,
                        title: 'Notification Settings',
                        message: config['settings-modal']!.content,
                        backgroundColor:
                            config['settings-modal']!.backgroundColor,
                        animationDuration:
                            config['settings-modal']!.animationDuration,
                        actions: [
                          TextButton(
                            onPressed: () =>
                                _modalKey.currentState?.close(),
                            child: const Text('Done'),
                          ),
                        ],
                        child: ElevatedButton(
                          onPressed: null,
                          child: const Text('Open settings modal'),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Nested context menu with no visible trigger of its
                      // own; it is opened programmatically from the
                      // dropdown's onItemSelected callback above.
                      ContextMenuPopover(
                        key: _nestedMenuKey,
                        controller: _popoverController,
                        id: 'nested-context-menu',
                        items: const ['Open', 'Rename', 'Delete'],
                        onItemSelected: (index, label) {
                          setState(() => _statusMessage =
                              'Nested context menu item "$label" selected');
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }
}
