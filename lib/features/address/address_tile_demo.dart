import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/core/dev_stubs/in_memory_address_repository.dart';
import 'package:wallet_test/core/di/get_it_injector.dart';
import 'package:wallet_test/features/address/address_repository.dart';
import 'package:wallet_test/features/address/address_tile.dart';

void main() {
  registerAppDependencies();
  runApp(const AddressTileDemoApp());
}

class AddressTileDemoApp extends StatelessWidget {
  const AddressTileDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AddressTileDemoPage(),
    );
  }
}

class AddressTileDemoPage extends StatefulWidget {
  const AddressTileDemoPage({super.key});

  @override
  State<AddressTileDemoPage> createState() => _AddressTileDemoPageState();
}

class _AddressTileDemoPageState extends State<AddressTileDemoPage> {
  late final InMemoryAddressRepository _repository =
  GetIt.instance<IAddressRepository>() as InMemoryAddressRepository;

  bool _largeText = false;
  bool _forceError = false;

  void _setLargeText(bool value) {
    setState(() {
      _largeText = value;
    });
  }

  void _setForceError(bool value) {
    setState(() {
      _forceError = value;
      _repository.shouldFail = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentMediaQuery = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AddressTile demo'),
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Large text'),
            value: _largeText,
            onChanged: _setLargeText,
          ),
          SwitchListTile(
            title: const Text('Force copy error'),
            value: _forceError,
            onChanged: _setForceError,
          ),
          const Divider(),
          MediaQuery(
            data: currentMediaQuery.copyWith(
              textScaler: TextScaler.linear(_largeText ? 2 : 1),
            ),
            child: const AddressTile(
              network: 'Ethereum',
              address:
              '0x1234567890abcdef1234567890abcdef12345678',
            ),
          ),
        ],
      ),
    );
  }
}