import 'package:solana/metaplex.dart';
import 'package:solana/solana.dart';
import 'package:test/test.dart';

import '../../config.dart';

Future<void> main() async {
  const uri = 'https://arweave.net/LogULMuEjDSOg-TnsboIF6UvmZyyr6j3BDCN4p46Frc';
  const name = 'Cofre #514';
  const symbol = 'COFR';

  // TODO(KB): Setup localnet with the metaplex program deployed.
  final client = createTestSolanaClient(useLocal: false);
  final owner = await Ed25519HDKeyPair.random();
  await client.requestAirdrop(
    address: owner.publicKey,
    lamports: 1 * lamportsPerSol,
    commitment: Commitment.confirmed,
  );
  final mint = await client.initializeMint(
    mintAuthority: owner,
    decimals: 0,
    commitment: Commitment.confirmed,
  );

  test(
    'creates metadata account',
    () async {
      final data = CreateMetadataAccountV3Data(
        name: name,
        symbol: symbol,
        uri: uri,
        sellerFeeBasisPoints: 550,
        isMutable: false,
        colectionDetails: false,
      );
      final instruction = await createMetadataAccountV3(
        mint: mint.address,
        mintAuthority: owner.publicKey,
        payer: owner.publicKey,
        updateAuthority: owner.publicKey,
        data: data,
      );

      final message = Message.only(instruction);

      await client.sendAndConfirmTransaction(
        message: message,
        signers: [owner],
        commitment: Commitment.confirmed,
      );

      final metadata = await client.rpcClient.getMetadata(
        mint: mint.address,
        commitment: Commitment.confirmed,
      );

      expect(metadata?.name, name);
      expect(metadata?.symbol, symbol);
      expect(metadata?.uri, uri);
    },
    skip: 'Setup localnet with the metaplex program deployed.',
  );
}
