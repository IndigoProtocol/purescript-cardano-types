module Cardano.Types.PlutusScript where

import Prelude

import Aeson
  ( class DecodeAeson
  , class EncodeAeson
  , decodeAeson
  , fromString
  )
import Cardano.AsCbor (class AsCbor, encodeCbor)
import Cardano.Serialization.Lib
  ( fromBytes
  , plutusScript_bytes
  , plutusScript_hash
  , plutusScript_languageVersion
  , plutusScript_new
  , plutusScript_newV2
  , toBytes
  )
import Cardano.Serialization.Lib as Csl
import Cardano.Types.Language (Language(PlutusV1, PlutusV2))
import Cardano.Types.Language as Language
import Cardano.Types.RawBytes (RawBytes)
import Cardano.Types.ScriptHash (ScriptHash)
import Data.Array.NonEmpty as NEA
import Data.Either (hush)
import Data.Function (on)
import Data.Generic.Rep (class Generic)
import Data.Maybe (fromJust)
import Data.Newtype (class Newtype, unwrap, wrap)
import Data.Show.Generic (genericShow)
import Data.Tuple.Nested (type (/\), (/\))
import Effect.Exception (throw)
import Effect.Unsafe (unsafePerformEffect)
import Partial.Unsafe (unsafePartial)
import Test.QuickCheck (class Arbitrary)
import Test.QuickCheck.Gen (oneOf)

-- | Corresponds to "Script" in Plutus
newtype PlutusScript = PlutusScript (Csl.PlutusScript /\ Language)

derive instance Generic PlutusScript _
derive instance Newtype PlutusScript _
derive newtype instance DecodeAeson PlutusScript
derive newtype instance EncodeAeson PlutusScript

instance Eq PlutusScript where
  eq = eq `on` encodeCbor

instance Ord PlutusScript where
  compare = compare `on` encodeCbor

instance Arbitrary PlutusScript where
  arbitrary = oneOf $ NEA.cons'
    ( pure $ unsafePartial $ fromJust $ map plutusV1Script $ hush
        $ decodeAeson
        $ fromString "4d01000033222220051200120011"
    )
    [ pure $ unsafePartial $ fromJust $ map plutusV2Script $ hush
        $ decodeAeson
        $ fromString "4d010000deadbeef33222220051200120011"
    ]

instance Show PlutusScript where
  show = genericShow

plutusV1Script :: RawBytes -> PlutusScript
plutusV1Script ba = unsafePerformEffect do
  let p = plutusScript_new (unwrap ba)
  let v = Language.fromCsl $ plutusScript_languageVersion p
  when (v /= PlutusV1) do
    throw "wrong plutus version - v1"
  pure $ PlutusScript $ p /\ PlutusV1

plutusV2Script :: RawBytes -> PlutusScript
plutusV2Script ba = unsafePerformEffect do
  let p = plutusScript_newV2 (unwrap ba)
  let v = Language.fromCsl $ plutusScript_languageVersion p
  when (v /= PlutusV2) do
    throw "wrong plutus version - v2"
  pure $ PlutusScript $ p /\ PlutusV2

instance AsCbor PlutusScript where
  encodeCbor = toCsl >>> toBytes >>> wrap
  decodeCbor = unwrap >>> fromBytes >>> map fromCsl

hash :: PlutusScript -> ScriptHash
hash = toCsl >>> plutusScript_hash >>> wrap

-- | Get raw Plutus script bytes
getBytes :: PlutusScript -> RawBytes
getBytes (PlutusScript (script /\ _)) = wrap $ plutusScript_bytes script

toCsl :: PlutusScript -> Csl.PlutusScript
toCsl (PlutusScript (script /\ lang)) =
  ( case lang of
      PlutusV1 -> plutusScript_new
      PlutusV2 -> plutusScript_newV2
  ) $ plutusScript_bytes script

fromCsl :: Csl.PlutusScript -> PlutusScript
fromCsl ps = PlutusScript (ps /\ Language.fromCsl (plutusScript_languageVersion ps))
