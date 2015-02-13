module Futhark.Analysis.ScalExp
  ( RelOp0(..)
  , ScalExp(..)
  , scalExpType
  , subExpToScalExp
  , toScalExp
  , LookupVar
  , fromScalExp
  , fromScalExp'
  , getIds
  , sproduct
  , ssum
  )
where

import Control.Applicative
import Control.Monad
import Data.List

import Text.PrettyPrint.Mainland hiding (pretty)

import Futhark.Representation.AST
import Futhark.MonadFreshNames
import Futhark.Substitute
import Futhark.Tools

-----------------------------------------------------------------
-- BINARY OPERATORS for Numbers                                --
-- Note that MOD, BAND, XOR, BOR, SHIFTR, SHIFTL not supported --
--   `a SHIFTL/SHIFTR p' can be translated if desired as as    --
--   `a * 2^p' or `a / 2^p                                     --
-----------------------------------------------------------------

-- | Relational operators.
data RelOp0 = LTH0
            | LEQ0
             deriving (Eq, Ord, Enum, Bounded, Show)

-- | Representation of a scalar expression, which is:
--
--    (i) an algebraic expression, e.g., min(a+b, a*b),
--
--   (ii) a relational expression: a+b < 5,
--
--  (iii) a logical expression: e1 and (not (a+b>5)
data ScalExp= Val     BasicValue
            | Id      Ident
            | SNeg    ScalExp
            | SNot    ScalExp
            | SPlus   ScalExp ScalExp
            | SMinus  ScalExp ScalExp
            | STimes  ScalExp ScalExp
            | SPow    ScalExp ScalExp
            | SDivide ScalExp ScalExp
            | MaxMin  Bool   [ScalExp]
            | RelExp  RelOp0  ScalExp
            | SLogAnd ScalExp ScalExp
            | SLogOr  ScalExp ScalExp
              deriving (Eq, Ord, Show)

instance Pretty ScalExp where
  pprPrec _ (Val val) = ppr $ BasicVal val
  pprPrec _ (Id v) = ppr v
  pprPrec _ (SNeg e) = text "-" <> pprPrec 9 e
  pprPrec _ (SNot e) = text "not" <+> pprPrec 9 e
  pprPrec prec (SPlus x y) = ppBinOp prec "+" 4 4 x y
  pprPrec prec (SMinus x y) = ppBinOp prec "-" 4 10 x y
  pprPrec prec (SPow x y) = ppBinOp prec "^" 6 6 x y
  pprPrec prec (STimes x y) = ppBinOp prec "*" 5 5 x y
  pprPrec prec (SDivide x y) = ppBinOp prec "/" 5 10 x y
  pprPrec prec (SLogOr x y) = ppBinOp prec "||" 0 0 x y
  pprPrec prec (SLogAnd x y) = ppBinOp prec "&&" 1 1 x y
  pprPrec prec (RelExp LTH0 e) = ppBinOp prec "<" 2 2 e (Val $ IntVal 0)
  pprPrec prec (RelExp LEQ0 e) = ppBinOp prec "<=" 2 2 e (Val $ IntVal 0)
  pprPrec _ (MaxMin True es) = text "min" <> parens (commasep $ map ppr es)
  pprPrec _ (MaxMin False es) = text "max" <> parens (commasep $ map ppr es)

ppBinOp :: Int -> String -> Int -> Int -> ScalExp -> ScalExp -> Doc
ppBinOp p bop precedence rprecedence x y =
  parensIf (p > precedence) $
           pprPrec precedence x <+/>
           text bop <+>
           pprPrec rprecedence y

instance Substitute ScalExp where
  substituteNames subst e =
    case e of Id v -> Id $ substituteNames subst v
              Val v -> Val v
              SNeg x -> SNeg $ substituteNames subst x
              SNot x -> SNot $ substituteNames subst x
              SPlus x y -> substituteNames subst x `SPlus` substituteNames subst y
              SMinus x y -> substituteNames subst x `SMinus` substituteNames subst y
              SPow x y -> substituteNames subst x `SPow` substituteNames subst y
              STimes x y -> substituteNames subst x `STimes` substituteNames subst y
              SDivide x y -> substituteNames subst x `SDivide` substituteNames subst y
              MaxMin m es -> MaxMin m $ map (substituteNames subst) es
              RelExp r x -> RelExp r $ substituteNames subst x
              SLogAnd x y -> substituteNames subst x `SLogAnd` substituteNames subst y
              SLogOr x y -> substituteNames subst x `SLogOr` substituteNames subst y

scalExpType :: ScalExp -> BasicType
scalExpType (Val ( IntVal _) ) = Int
scalExpType (Val (RealVal _) ) = Real
scalExpType (Val ( LogVal _) ) = Bool
scalExpType (Val val) =
  error $ "scalExpType: scalar exp cannot have type " ++
          pretty (basicDecl $ basicValueType val) ++ "."
scalExpType (Id  idd) =
  case identType idd of
    Basic bt -> bt
    t        -> error $ "scalExpType: var in scalar exp cannot have type " ++
                         pretty t ++ "."
scalExpType (SNeg  e) = scalExpType e
scalExpType (SNot  _) = Bool
scalExpType (SPlus   e _) = scalExpType e
scalExpType (SMinus  e _) = scalExpType e
scalExpType (STimes  e _) = scalExpType e
scalExpType (SDivide e _) = scalExpType e
scalExpType (SPow    e _) = scalExpType e
scalExpType (SLogAnd _ _) = Bool
scalExpType (SLogOr  _ _) = Bool
scalExpType (RelExp  _ _) = Bool
scalExpType (MaxMin _ []) = Int
scalExpType (MaxMin _ (e:_)) = scalExpType e

-- | A function that checks whether a variable name corresponds to a
-- scalar expression.
type LookupVar = VName -> Maybe ScalExp

-- | Non-recursively convert a subexpression to a 'ScalExp'.
subExpToScalExp :: SubExp -> ScalExp
subExpToScalExp (Var v)        = Id v
subExpToScalExp (Constant val) = Val val

toScalExp :: LookupVar -> Exp lore -> Maybe ScalExp
toScalExp look (PrimOp (SubExp se))    =
  toScalExp' look se
toScalExp look (PrimOp (BinOp Less x y _)) =
  RelExp LTH0 <$> (sminus <$> toScalExp' look x <*> toScalExp' look y)
toScalExp look (PrimOp (BinOp Leq x y _)) =
  RelExp LEQ0 <$> (sminus <$> toScalExp' look x <*> toScalExp' look y)
toScalExp look (PrimOp (BinOp Equal x y Int)) = do
  x' <- toScalExp' look x
  y' <- toScalExp' look y
  return $ RelExp LEQ0 (x' `sminus` y') `SLogAnd` RelExp LEQ0 (y' `sminus` x')
toScalExp look (PrimOp (Negate e)) =
  SNeg <$> toScalExp' look e
toScalExp look (PrimOp (Not e)) =
  SNot <$> toScalExp' look e
toScalExp look (PrimOp (BinOp bop x y t))
  | t `elem` [Int, Bool] = -- XXX: Only integers and booleans, OK?
  binOpScalExp bop <*> toScalExp' look x <*> toScalExp' look y

toScalExp _ _ = Nothing

-- | "Smart constructor" that checks whether we are subtracting zero,
-- and if so just returns the first argument.
sminus :: ScalExp -> ScalExp -> ScalExp
sminus x (Val (IntVal 0))  = x
sminus x (Val (RealVal 0)) = x
sminus x y                 = x `SMinus` y

-- | Take the product of a list of 'ScalExp's, or the integer @1@ if
-- the list is empty.
sproduct :: [ScalExp] -> ScalExp
sproduct []       = Val $ IntVal 1
sproduct (se:ses) = foldl STimes se ses

-- | Take the sum of a list of 'ScalExp's, or the integer @0@ if the
-- list is empty.
ssum :: [ScalExp] -> ScalExp
ssum []       = Val $ IntVal 0
ssum (se:ses) = foldl STimes se ses

binOpScalExp :: BinOp -> Maybe (ScalExp -> ScalExp -> ScalExp)
binOpScalExp bop = liftM snd $ find ((==bop) . fst)
                   [ (Plus, SPlus)
                   , (Minus, SMinus)
                   , (Times, STimes)
                   , (Divide, SDivide)
                   , (Pow, SPow)
                   , (LogAnd, SLogAnd)
                   , (LogOr, SLogOr)
                   ]

toScalExp' :: LookupVar -> SubExp -> Maybe ScalExp
toScalExp' look (Var v) =
  look (identName v) <|> Just (Id v)
toScalExp' _ (Constant val) =
  Just $ Val val

fromScalExp :: (Proper lore, Bindable lore, MonadFreshNames m) =>
               ScalExp
            -> m (Exp lore, [Binding lore])
fromScalExp = runBinder'' . fromScalExp'

fromScalExp' :: MonadBinder m => ScalExp
             -> m (Exp (Lore m))
fromScalExp' = convert
  where convert (Val val) = return $ PrimOp $ SubExp $ Constant val
        convert (Id v)    = return $ PrimOp $ SubExp $ Var v
        convert (SNeg se) = eNegate $ convert se
        convert (SNot se) = eNot $ convert se
        convert (SPlus x y) = arithBinOp Plus x y
        convert (SMinus x y) = arithBinOp Minus x y
        convert (STimes x y) = arithBinOp Times x y
        convert (SDivide x y) = arithBinOp Divide x y
        convert (SPow x y) = arithBinOp Pow x y
        convert (SLogAnd x y) = eBinOp LogAnd (convert x) (convert y) Bool
        convert (SLogOr x y) = eBinOp LogOr (convert x) (convert y) Bool
        convert (RelExp LTH0 x) = eBinOp Less (convert x) (pure $ zero $ scalExpType x)
                                  Bool
        convert (RelExp LEQ0 x) = eBinOp Leq (convert x) (pure $ zero $ scalExpType x)
                                  Bool
        convert (MaxMin _ []) = fail "ScalExp.fromScalExp: MaxMin empty list"
        convert (MaxMin isMin (e:es)) = do
          e'  <- convert e
          es' <- mapM convert es
          foldM (select isMin) e' es'

        arithBinOp bop x y = do
          x' <- convert x
          y' <- convert y
          eBinOp bop (pure x') (pure y') t
          where t = scalExpType x

        select isMin cur next =
          let cmp = eBinOp Less (pure cur) (pure next) Bool
              (pick, discard)
                | isMin     = (cur, next)
                | otherwise = (next, cur)
          in eIf cmp (eBody [pure pick]) (eBody [pure discard])

        zero Int = PrimOp $ SubExp $ intconst 0
        zero _   = PrimOp $ SubExp $ constant (0::Double)

------------------------
--- Helper Functions ---
------------------------
getIds :: ScalExp -> [Ident]
getIds (Val   _) = []
getIds (Id    i) = [i]
getIds (SNeg  e) = getIds e
getIds (SNot  e) = getIds e
getIds (SPlus x y)   = getIds x ++ getIds y
getIds (SMinus x y)  = getIds x ++ getIds y
getIds (SPow x y)    = getIds x ++ getIds y
getIds (STimes x y)  = getIds x ++ getIds y
getIds (SDivide x y) = getIds x ++ getIds y
getIds (SLogOr x y)  = getIds x ++ getIds y
getIds (SLogAnd x y) = getIds x ++ getIds y
getIds (RelExp LTH0 e) = getIds e
getIds (RelExp LEQ0 e) = getIds e
getIds (MaxMin _  es) = concatMap getIds es
