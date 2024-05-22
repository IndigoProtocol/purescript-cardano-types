module Cardano.Types.NewConstitutionAction
  ( NewConstitutionAction(NewConstitutionAction)
  , fromCsl
  , toCsl
  ) where

import Prelude

import Cardano.Serialization.Lib as Csl
import Cardano.Types.Constitution (Constitution)
import Cardano.Types.Constitution (fromCsl, toCsl) as Constitution
import Cardano.Types.GovernanceActionId (GovernanceActionId)
import Cardano.Types.GovernanceActionId (fromCsl, toCsl) as GovernanceActionId
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe, maybe)
import Data.Newtype (class Newtype)
import Data.Nullable (toMaybe)
import Data.Show.Generic (genericShow)

newtype NewConstitutionAction = NewConstitutionAction
  { constitution :: Constitution
  , actionId :: Maybe GovernanceActionId
  }

derive instance Generic NewConstitutionAction _
derive instance Newtype NewConstitutionAction _
derive instance Eq NewConstitutionAction

instance Show NewConstitutionAction where
  show = genericShow

toCsl :: NewConstitutionAction -> Csl.NewConstitutionAction
toCsl (NewConstitutionAction rec) =
  maybe (Csl.newConstitutionAction_new constitution)
    (flip Csl.newConstitutionAction_newWithActionId constitution <<< GovernanceActionId.toCsl)
    rec.actionId
  where
  constitution = Constitution.toCsl rec.constitution

fromCsl :: Csl.NewConstitutionAction -> NewConstitutionAction
fromCsl action =
  NewConstitutionAction
    { constitution:
        Constitution.fromCsl $
          Csl.newConstitutionAction_constitution action
    , actionId:
        GovernanceActionId.fromCsl <$>
          toMaybe (Csl.newConstitutionAction_govActionId action)
    }
