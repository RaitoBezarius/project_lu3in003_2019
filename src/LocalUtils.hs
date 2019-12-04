module LocalUtils where
  import Data.Array
  import System.Directory
  import Data.List
  import System.Random (randomRIO)
  import Data.List.Split
  import Data.Maybe (Maybe)
  import Control.Monad
  type ADNInstance = (String, String)

  data PosInf a = Infinity | Finite a deriving (Show, Read, Eq)

  instance Ord a => Ord (PosInf a) where
    compare Infinity Infinity = EQ
    compare Infinity Finite{} = GT
    compare Finite{} Infinity = LT
    compare (Finite a) (Finite b) = compare a b

  instance Num a => Num (PosInf a) where
    Finite x + Finite y = Finite (x + y)
    _ + _ = Infinity


  data FileCase = FileCase {
    case_name :: FilePath,
    size_n :: Int,
    size_m :: Int,
    file_input :: ADNInstance
  }
  
  printArray :: Show a => Array (Int, Int) a -> String
  printArray arr =
    let (_, (n, m)) = bounds arr
    in
    unlines [unwords [show (arr ! (x, y)) | x <- [0..n]] | y <- [0..m]]

  min' :: Ord a => [a] -> a
  min' = foldr1 (\x y -> if x <= y then x else y)

  optionals :: Bool -> [a] -> [a]
  optionals x y = if x then y else []

  optional_func :: Bool -> (a -> a) -> (a -> a)
  optional_func x y = if x then y else id

  -- Pour travailler avec les instances du projet
  instanceFromString :: String -> ADNInstance
  instanceFromString "" = error "empty instance"
  instanceFromString contents =
    let [n, m, x, y] = lines contents
    in
    (filter (/=' ') x, filter (/=' ') y)

  read_instance :: FilePath -> IO ADNInstance
  read_instance file_path = do
    contents <- readFile file_path
    let [n, m, x, y] = lines contents
    return (filter (/=' ') x, filter (/=' ') y)
  
  read_filecase :: FilePath -> IO FileCase
  read_filecase file_path = do
    (x, y) <- read_instance file_path
    return FileCase { case_name = file_path, size_n = (length x), size_m = (length y), file_input = (x, y) }

  get_testfiles_in_directory :: FilePath -> IO [FilePath]
  get_testfiles_in_directory folder = do
    files <- getDirectoryContents folder
    return $ sort (map (\f -> folder ++ "/" ++ f) (filter (\f -> f /= "." && f /= "..") files))

  load_testfiles :: [FilePath] -> IO [FileCase]
  load_testfiles = traverse read_filecase

  sizeFromFilePath :: FilePath -> Int
  sizeFromFilePath f = (read ((splitOn "_" f) !! 2)) :: Int

  filterBySize :: (Int -> Bool) -> [FilePath] -> [FilePath]
  filterBySize p = filter (\f -> p $ sizeFromFilePath f)
  
  randomFileCase :: [FileCase] -> IO FileCase
  randomFileCase [] = error "Empty filecase"
  randomFileCase xs = do
    random_filecase <- ((xs !!) <$> randomRIO (0, length xs - 1))
    return random_filecase

  setupEnv :: Int -> IO ADNInstance
  setupEnv n = do
    testfiles <- get_testfiles_in_directory "Instances_genome"
    all <- load_testfiles (filterBySize (== n) testfiles)
    fc <- randomFileCase all
    return $ file_input fc
