{-# LANGUAGE MultiWayIf #-}

module Algos (dist_naif, dist_1, dist_2, prog_dyn, sol_2)
  where
    import LocalUtils
    import Data.List
    import Data.Array
    import Data.Ord
    import Data.Tuple
    import Control.Monad.ST
    import Control.Monad
    import Data.Vector (freeze)
    import qualified Data.Vector.Unboxed as V
    import qualified Data.Vector.Unboxed.Mutable as VM

    c_ins :: (Num a, Eq a, Ord a) => a
    c_ins = 2
    c_del :: (Num a, Eq a, Ord a) => a
    c_del = 2

    c_sub :: (Num a, Eq a, Ord a) => Char -> Char -> a
    c_sub 'A' 'T' = 3
    c_sub 'T' 'A' = 3
    c_sub 'C' 'G' = 3
    c_sub 'G' 'C' = 3
    c_sub a b
      | a == b = 0
      | otherwise = 4


    -- Partie 3.1 du projet: tâche A
    dist_naif_rec :: (Num a, Eq a, Ord a, Show a) => String -> String -> Int -> Int -> PosInf a -> PosInf a -> PosInf a
    dist_naif_rec x y i j c dist
      | i == n - 1 && j == m - 1 && c < dist = c
      | i == n - 1 && j == m - 1 && c >= dist = dist
      | otherwise =
        let firstCall = optional_func ((i < n - 1) && (j < m - 1)) (rec_call (i + 1) (j + 1) (c + Finite (c_sub (x !! i) (y !! j))))
            secondCall = optional_func (i < n - 1) (rec_call (i + 1) j (c + Finite c_del))
            thirdCall = optional_func (j < m - 1) (rec_call i (j + 1) (c + Finite c_ins))
          in
           (thirdCall . secondCall . firstCall) dist
      where
        n = length x
        m = length y
        rec_call = dist_naif_rec x y

    dist_naif :: (Num a, Eq a, Ord a, Show a) => ADNInstance -> a
    dist_naif (x, y) = case dist_naif_rec x y 0 0 (Finite 0) Infinity of
                      Infinity -> error "distance d'édition infinie!"
                      Finite x -> x

    -- Vérification de la tâche A

    -- Partie 3.2.2 du projet: tâche B

    dist_1_array_helper :: Int -> Int -> Int -> Array (Int, Int) Int -> [Int]
    dist_1_array_helper i j sub a =
        [ a ! (i - 1, j) + c_ins, a ! (i, j - 1) + c_del, a ! (i - 1, j - 1) + sub ]

    dist_1_array :: String -> String -> Array (Int, Int) Int
    dist_1_array x y = a
      where
        a = array ((0, 0), (n, m)) (
          [((0, 0), 0)] ++
          [((i, 0), i*c_del) | i <- [1..n]] ++
          [((0, j), j*c_ins) | j <- [1..m]] ++
          [((i, j), min' (dist_1_array_helper i j (c_sub (x !! (i - 1)) (y !! (j - 1))) a)) | i <- [1..n], j <- [1..m]])
        n = length x
        m = length y
    
    dist_1_vector :: (V.Vector Char, V.Vector Char) -> V.Vector Int
    dist_1_vector (x, y) = runST $ do
      d <- VM.replicate ((n + 1)*(m + 1)) 0

      forM_ [1..n] (\i -> VM.write d (i*(n + 1)) (i*c_del))
      forM_ [1..m] (\j -> VM.write d j (j*c_ins))

      forM_ [1..n] $ \i -> do
        forM_ [1..m] $ \j -> do
          a <- VM.read d ((i - 1)*(n + 1) + j)
          s <- VM.read d (i*(n + 1) + (j - 1))
          c <- VM.read d ((i - 1)*(n + 1) + m)

          VM.write d (i*(n + 1) + j) (min' [a + c_ins, s + c_del, c + c_sub (x V.! (i - 1)) (y V.! (j - 1))])

      V.freeze d
        where
          n = V.length x
          m = V.length y

    dist_1a :: String -> String -> (Array (Int, Int) Int, Int)
    dist_1a x y = (a, a ! (n, m))
      where
        a = dist_1_array x y
        n = length x
        m = length y

    dist_1b :: String -> String -> (V.Vector Int, Int)
    dist_1b x y = (a, a V.! (n*(n + 1) + m))
      where
        a = dist_1_vector (V.fromList x, V.fromList y)
        n = length x
        m = length y

    dist_1 :: ADNInstance -> Int
    dist_1 (x, y) = snd (dist_1a x y)
  
    dist_1' :: ADNInstance -> Int
    dist_1' (x, y) = snd (dist_1b x y)
    
    sol_1_g :: ADNInstance -> ((Int, Int) -> Int) -> (String, String)
    sol_1_g (x, y) a = aux ("", "") n m (reverse x, reverse y)
      where
      n = length x
      m = length y
      aux (s, t) i j (u, v)
        | i > 0 && j > 0 && a (i, j) == a (i - 1, j - 1) + c_sub (head u) (head v) = aux ((head u) : s, (head v) : t) (i - 1) (j - 1) ((tail u), (tail v))
        | j > 0 && a (i, j) == (a (i, j - 1) + c_ins) = aux ('-' : s, (head v) : t) i (j - 1) (u, (tail v))
        | i > 0 && a (i, j) == (a (i - 1, j) + c_del) = aux ((head u) : s, '-' : t) (i - 1) j ((tail u), v)
        | otherwise = (s, t)
    
    sol_1 :: ADNInstance -> Array (Int, Int) Int -> (String, String)
    sol_1 (x, y) a = sol_1_g (x, y) ((!) a)

    sol_1' :: ADNInstance -> V.Vector Int -> (String, String)
    sol_1' (x, y) a = sol_1_g (x, y) (\(z, t) -> a V.! (z*(n + 1) + t))
      where
        n = length x
        m = length y

    prog_dyn :: ADNInstance -> (String, String)
    prog_dyn (x, y) = 
      let (t, d) = dist_1a x y
       in sol_1 (x, y) t

    -- Partie 3.3 du projet: tâche C
    
    dist_prog_dyn_value :: Int -> Int -> Int -> Char -> Char -> Int
    dist_prog_dyn_value a b c x_i y_j =
      min' [a + c_ins, b + c_del, c + c_sub x_i y_j]
    
    dist_2 :: ADNInstance -> Int
    dist_2 (xs, ys) = runST $ do
          lc <- VM.replicate (m + 1) 0
          ll <- VM.replicate (m + 1) 0

          forM_ [0..m] (\j -> VM.write ll j (j*c_ins))
          VM.copy lc ll

          forM_ [1..n] (\i -> do
            VM.write lc 0 (i*c_del)

            _ <- forM_ [1..m] (\j -> do
              a <- VM.read ll j -- D(i - 1, j)
              b <- VM.read lc (j - 1) -- D(i, j - 1)
              c <- VM.read ll (j - 1) -- D(i - 1, j - 1)

              VM.write lc j (dist_prog_dyn_value a b c (x V.! (i - 1)) (y V.! (j - 1))));

            VM.move ll lc -- on remplace la dernière ligne par la ligne courante.
            return ())
          d <- VM.read lc m

          return d
        where
          x = V.fromList xs
          y = V.fromList ys
          n = length xs
          m = length ys


    -- Partie 3.4 du projet: tâche D
    mot_gaps :: Int -> String
    mot_gaps k 
      | k < 0 = error ("Invalid length of word for mot_gaps: " ++ show k)
      | k == 0 = ""
      | k > 0 = '-' : mot_gaps (k - 1)

    argmin f l
      | null l = error "Given list is empty!"
      | otherwise = minimumBy (comparing f) l

    align_lettre_mot :: String -> String -> (String, String)
    align_lettre_mot x y
      -- 0 <= k_0 < m
      -- si k_0 = 0, alors: x ⋅ mot_gaps (m - 1)
      -- si k_0 >= 0, alors: mot_gaps (k_0 - 1) ⋅ x ⋅ mot_gaps (m - k_0)
      -- si k_0 = m - 1, alors: mot_gaps(m - 1) ⋅ x
      | c_del + c_ins >= c_sub (x !! 0) (y !! k_0) = if | k_0 == 0 -> ((head x) : mot_gaps (m - 1), y)
                                                        |  k_0 == m - 1 -> (reverse $ (head x) : mot_gaps (m - 1), y)
                                                        | otherwise -> (concat [mot_gaps (k_0 - 1), x, mot_gaps (m - k_0)], y)
      | otherwise = ((head x) : mot_gaps m, '-' : y)
      where
          n = length x
          m = length y
          k_0 = fst (argmin (\item -> c_sub (head x) (snd item)) $ zip [0..m-1] y)
  
    coupure :: (V.Vector Char, V.Vector Char) -> Int
    coupure (x, y) = runST $ do
      dlc <- VM.replicate (m + 1) 0
      dll <- VM.replicate (m + 1) 0
      ilc <- VM.replicate (m + 1) 0
      ill <- VM.replicate (m + 1) 0

      VM.write dlc 0 0

      VM.write ilc 0 0

      forM_ [0..m] $ \j -> do
        VM.write dlc j (j*c_ins)
        VM.write ilc j j

      forM_ [1..n] $ \i -> do
        VM.write dlc 0 (i*c_del)
        forM_ [1..m] $ \j -> do
            a <- VM.read dll j -- D(i - 1, j)
            b <- VM.read dlc (j - 1) -- D(i, j - 1)
            c <- VM.read dll (j - 1) -- D(i - 1, j - 1)

            VM.write dlc j (min' [a + c_ins, b + c_del, c + c_sub (x V.! (i - 1)) (y V.! (j - 1))])

            r <- VM.read dlc j
            case (i > i') of
              True -> do
                v <- (if
                   | r == a + c_ins -> do VM.read ill j
                   | r == b + c_del -> do VM.read ilc (j - 1)
                   | r == c + c_sub (x V.! (i - 1)) (y V.! (j - 1)) -> do VM.read ill (j - 1)
                   | otherwise -> error ("Unexpected value for DLigneCourante(i): " ++ show r))
                VM.write ilc j v
              False -> return ()

        VM.move dll dlc
        case (i > i') of
          True -> VM.move ill ilc
          False -> return ()
      
      v <- VM.read ilc m
      return v
        where
          n = V.length x
          m = V.length y
          i' = (n `div` 2)
      
    sol_2_helper :: (V.Vector Char, V.Vector Char) -> (String, String)
    sol_2_helper (x, y)
      | n == 0 || m == 0 = (concat [(mot_gaps m), V.toList x], concat [(mot_gaps n), V.toList y])
      | n == 1 = align_lettre_mot (V.toList x) (V.toList y)
      | m == 1 = swap (align_lettre_mot (V.toList y) (V.toList x))
      | otherwise =
        let i' = (n `div` 2)
            j' = coupure (x, y)
        in
        let (s, t) = sol_2_helper ((V.take i' x), (V.take j' y))
            (u, v) = sol_2_helper ((V.drop i' x), (V.drop j' y))
        in
          (concat [s, u], concat [t, v])
      where
        n = V.length x
        m = V.length y

    sol_2 :: ADNInstance -> (String, String)
    sol_2 (x, y) = sol_2_helper (V.fromList x, V.fromList y)
