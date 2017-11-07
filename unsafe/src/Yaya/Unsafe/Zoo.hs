module Yaya.Unsafe.Zoo where

import Control.Arrow
import Control.Comonad.Cofree
import Control.Comonad.Env
import Control.Monad.Trans.Free
import Data.Functor.Compose
import Data.Functor.Identity
import Data.Bitraversable

import Yaya
import Yaya.Control
import Yaya.Data
import Yaya.Unsafe.Control
import Yaya.Unsafe.Data

chrono
  :: Functor f
  => GAlgebra (Cofree f) f b
  -> GCoalgebra (Free f) f a
  -> a
  -> b
chrono = ghylo (distGHisto id) (distGFutu id)

codyna :: Functor f => Algebra f b -> GCoalgebra (Free f) f a -> a -> b
codyna φ = ghylo distCata (distGFutu id) $ φ . fmap runIdentity

-- | [Recursion Schemes for Dynamic Programming](https://www.researchgate.net/publication/221440162_Recursion_Schemes_for_Dynamic_Programming)
dyna :: Functor f => GAlgebra (Cofree f) f b -> Coalgebra f a -> a -> b
dyna φ ψ = ghylo (distGHisto id) distAna φ $ fmap Identity . ψ

-- | Unlike most 'hylo's, 'elgot' composes an algebra and coalgebra in a way
--   that allows information to move between them. The coalgebra can return,
--   effectively, a pre-folded branch, short-circuiting parts of the process.
elgot :: Functor f => Algebra f b -> ElgotCoalgebra (Either b) f a -> a -> b
elgot φ ψ = hylo ((id ||| φ) . getCompose) (Compose . ψ)

-- | The dual of 'elgot', 'coelgot' allows the _algebra_ to short-circuit in
--   some cases – operating directly on a part of the seed.
coelgot :: Functor f => ElgotAlgebra ((,) a) f b -> Coalgebra f a -> a -> b
coelgot φ ψ = hylo (φ . getCompose) (Compose . (id &&& ψ))

futu :: (Corecursive t f, Functor f) => GCoalgebra (Free f) f a -> a -> t
futu = gana $ distGFutu id

gprepro
  :: (Cursive t f, Recursive t f, Functor f, Comonad w)
  => DistributiveLaw f w
  -> GAlgebra w f a
  -> (forall a. f a -> f a)
  -> t
  -> a
gprepro k φ e = ghylo k distAna φ (fmap (Identity . cata (embed . e)) . project)

gpostpro
  :: (Cursive t f, Corecursive t f, Functor f, Monad m)
  => DistributiveLaw m f
  -> (forall a. f a -> f a)
  -> GCoalgebra m f a
  -> a
  -> t
gpostpro k e ψ =
  ghylo distCata k (embed . fmap (ana (e . project) . runIdentity)) ψ

histo :: (Recursive t f, Functor f) => GAlgebra (Cofree f) f a -> t -> a
histo = gcata $ distGHisto id

-- | The metamorphism definition from Gibbons’ paper.
stream :: Coalgebra (XNor c) b -> (b -> a -> b) -> b -> [a] -> [c]
stream f g = fstream f g (const None)

-- | Basically the definition from Gibbons’ paper, except the flusher (`h`) is a
--  'Coalgebra' instead of an 'unfold'.
fstream
  :: Coalgebra (XNor c) b
  -> (b -> a -> b)
  -> Coalgebra (XNor c) b
  -> b
  -> [a]
  -> [c]
fstream f g h = streamGApo h
                           (\b -> case f b of
                                    None -> Nothing
                                    other -> Just other)
                           (\case
                               None -> Nothing
                               Both a x' -> Just (flip g a, x'))

-- snoc :: [a] -> a -> [a]
-- snoc x a = x ++ [a]

-- x :: [Int]
-- x = stream project snoc [] [1, 2, 3, 4, 5]

-- TODO: Weaken 'Monad' constraint to 'Applicative'.
cotraverse
  :: ( Cursive t (f a)
     , Cursive u (f b)
     , Corecursive u (f b)
     , Bitraversable f
     , Traversable (f b)
     , Monad m)
  => (a -> m b)
  -> t
  -> m u
cotraverse f = anaM $ bitraverse f pure . project

-- | Zygohistomorphic prepromorphism – everyone’s favorite recursion scheme joke.
zygoHistoPrepro
  :: (Cursive t f, Recursive t f, Functor f)
  => (f b -> b)
  -> (f (EnvT b (Cofree f) a) -> a)
  -> (forall c. f c -> f c)
  -> t
  -> a
zygoHistoPrepro φ' φ e = gprepro (distZygoT φ' $ distGHisto id) φ e
