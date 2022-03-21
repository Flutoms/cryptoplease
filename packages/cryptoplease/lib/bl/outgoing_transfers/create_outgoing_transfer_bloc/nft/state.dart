part of 'bloc.dart';

@freezed
class NftCreateOutgoingTransferState with _$NftCreateOutgoingTransferState {
  const factory NftCreateOutgoingTransferState({
    required OutgoingTransferType transferType,
    NonFungibleToken? nft,
    OffChainMetadata? offChainMetadata,
    Amount? maxFee,
    String? recipientAddress,
    String? memo,
    String? reference,
    @Default(FlowInitial<Exception, OutgoingTransferId>())
        Flow<Exception, OutgoingTransferId> flow,
  }) = _NftCreateOutgoingTransferState;

  const NftCreateOutgoingTransferState._();

  Amount? get fee =>
      nft == null ? null : calculateFee(transferType, nft!.address);

  Token? get token => nft;
}