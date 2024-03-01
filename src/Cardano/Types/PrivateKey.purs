module Cardano.Types.PrivateKey where

import Prelude

import Aeson (class EncodeAeson, encodeAeson)
import Cardano.Serialization.Lib
  ( privateKey_asBytes
  , privateKey_fromBech32
  , privateKey_sign
  , privateKey_toBech32
  , privateKey_toPublic
  )
import Cardano.Serialization.Lib as Csl
import Cardano.Types.Bech32String (Bech32String)
import Cardano.Types.Ed25519Signature (Ed25519Signature)
import Cardano.Types.Internal.Helpers (eqOrd)
import Cardano.Types.PublicKey (PublicKey)
import Cardano.Types.RawBytes (RawBytes)
import Cardano.Types.TransactionHash (TransactionHash)
import Cardano.Types.Vkeywitness (Vkeywitness)
import Cardano.Types.Vkeywitness as Vkeywitness
import Data.ByteArray (ByteArray)
import Data.Function (on)
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe)
import Data.Newtype (class Newtype, unwrap, wrap)
import Data.Nullable (toMaybe)

newtype PrivateKey = PrivateKey Csl.PrivateKey

derive instance Generic PrivateKey _
derive instance Newtype PrivateKey _

instance Eq PrivateKey where
  eq = eqOrd

instance Ord PrivateKey where
  compare = compare `on` (unwrap >>> privateKey_asBytes)

instance EncodeAeson PrivateKey where
  encodeAeson = unwrap >>> privateKey_asBytes >>> encodeAeson

instance Show PrivateKey where
  show _ = "(PrivateKey <HIDDEN>)"

toBech32 :: PrivateKey -> Bech32String
toBech32 = unwrap >>> privateKey_toBech32

fromBech32 :: Bech32String -> Maybe PrivateKey
fromBech32 = privateKey_fromBech32 >>> toMaybe >>> map wrap

toPublicKey :: PrivateKey -> PublicKey
toPublicKey = unwrap >>> privateKey_toPublic >>> wrap

toRawBytes :: PrivateKey -> RawBytes
toRawBytes = unwrap >>> privateKey_asBytes >>> wrap

sign :: PrivateKey -> ByteArray -> Ed25519Signature
sign pk bytes = wrap $ privateKey_sign (unwrap pk) bytes

-- | Sign a transaction body hash
makeVkeyWitness :: TransactionHash -> PrivateKey -> Vkeywitness
makeVkeyWitness th pk =
  Vkeywitness.fromCsl $ Csl.makeVkeyWitness (unwrap th) (unwrap pk)
