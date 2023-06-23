import 'package:bip39/bip39.dart' as bip39;
import 'package:bloc_test/bloc_test.dart';
import 'package:espressocash_app/core/file_manager.dart';
import 'package:espressocash_app/core/wallet.dart';
import 'package:espressocash_app/features/accounts/models/account.dart';
import 'package:espressocash_app/features/accounts/models/mnemonic.dart';
import 'package:espressocash_app/features/accounts/models/profile.dart';
import 'package:espressocash_app/features/accounts/services/accounts_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:solana_seed_vault/solana_seed_vault.dart';

import 'accounts_bloc_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage, SeedVault])
Future<void> main() async {
  final seedVault = MockSeedVault();
  final storage = MockFlutterSecureStorage();
  final mnemonic = bip39.generateMnemonic();
  final wallet = await createLocalWallet(mnemonic: mnemonic);
  final testAccount = MyAccount(
    wallet: wallet,
    accessMode: const AccessMode.loaded(),
    profile: const Profile(firstName: 'Test', country: 'US'),
  );
  const fileManager = FileManager();

  tearDown(() {
    reset(storage);
  });

  AccountsBloc createBloc() => AccountsBloc(
        storage: storage,
        fileManager: fileManager,
        seedVault: seedVault,
      );

  blocTest<AccountsBloc, AccountsState>(
    'Tries to load account from storage',
    setUp: () {
      when(storage.read(key: anyNamed('key'), iOptions: anyNamed('iOptions')))
          .thenAnswer((_) async => null);
      when(storage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async {});
    },
    build: createBloc,
    act: (b) {
      b.add(const AccountsEvent.initialize());
    },
    expect: () => [
      const AccountsState(isProcessing: true),
      const AccountsState(),
    ],
    verify: (_) {
      verify(storage.read(key: anyNamed('key'), iOptions: anyNamed('iOptions')))
          .called(3);
      verifyNever(
        storage.write(key: anyNamed('key'), value: anyNamed('value')),
      );
    },
  );

  blocTest<AccountsBloc, AccountsState>(
    'Loads account from storage if it exists',
    setUp: () {
      when(
        storage.read(key: authTokenKey, iOptions: anyNamed('iOptions')),
      ).thenAnswer((_) async => null);
      when(
        storage.read(key: mnemonicKey, iOptions: anyNamed('iOptions')),
      ).thenAnswer((_) async => mnemonic);
      when(
        storage.read(key: nameKey, iOptions: anyNamed('iOptions')),
      ).thenAnswer((_) async => testAccount.profile.firstName);
      when(
        storage.read(key: countryKey, iOptions: anyNamed('iOptions')),
      ).thenAnswer((_) async => testAccount.profile.country);
      when(
        storage.read(key: photoKey, iOptions: anyNamed('iOptions')),
      ).thenAnswer((_) async => null);
      when(
        storage.read(key: onboardingKey, iOptions: anyNamed('iOptions')),
      ).thenAnswer((_) async => 'true');
      when(storage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async {});
    },
    build: createBloc,
    act: (b) {
      b.add(const AccountsEvent.initialize());
    },
    expect: () => [
      const AccountsState(isProcessing: true),
      allOf(
        predicate(
          (AccountsState a) => a.account?.address == testAccount.address,
          'has correct account address',
        ),
        predicate((AccountsState a) => !a.isProcessing, 'is not processing'),
        predicate(
          (AccountsState a) => a.hasFinishedOnboarding,
          'has finished onboarding',
        ),
      ),
    ],
  );

  blocTest<AccountsBloc, AccountsState>(
    'Saves account when created',
    setUp: () {
      when(storage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async {});
    },
    build: createBloc,
    act: (b) {
      b.add(
        AccountsEvent.created(
          source: AccountSource.local(Mnemonic.generated(mnemonic)),
          account: testAccount,
          hasFinishedOnboarding: false,
        ),
      );
    },
    expect: () => [
      const AccountsState(isProcessing: true),
      allOf(
        predicate(
          (AccountsState a) => a.account?.address == testAccount.address,
          'has correct account address',
        ),
        predicate((AccountsState a) => !a.isProcessing, 'is not processing'),
        predicate(
          (AccountsState a) => !a.hasFinishedOnboarding,
          'has not finished onboarding',
        ),
      ),
    ],
    verify: (_) {
      verify(
        storage.write(
          key: mnemonicKey,
          value: mnemonic,
          iOptions: anyNamed('iOptions'),
        ),
      ).called(1);
      verify(
        storage.write(
          key: nameKey,
          value: testAccount.profile.firstName,
          iOptions: anyNamed('iOptions'),
        ),
      ).called(1);
      verify(
        storage.write(
          key: onboardingKey,
          value: 'false',
          iOptions: anyNamed('iOptions'),
        ),
      ).called(1);
    },
  );
}
