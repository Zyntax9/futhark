{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}
module Futhark.CodeGen.Backends.COpenCL.Boilerplate
  ( generateBoilerplate

  , kernelRuntime
  , kernelRuns
  ) where

import Data.FileEmbed
import qualified Data.Map as M
import qualified Language.C.Syntax as C
import qualified Language.C.Quote.OpenCL as C

import Futhark.CodeGen.ImpCode.OpenCL
import qualified Futhark.CodeGen.Backends.GenericC as GC
import Futhark.CodeGen.OpenCL.Kernels
import Futhark.Util (chunk)

generateBoilerplate :: String -> String -> [String] -> [PrimType]
                    -> M.Map VName (SizeClass, Name)
                    -> GC.CompilerM OpenCL () ()
generateBoilerplate opencl_code opencl_prelude kernel_names types sizes = do
  final_inits <- GC.contextFinalInits

  let (ctx_opencl_fields, ctx_opencl_inits, top_decls, later_top_decls) =
        openClDecls kernel_names opencl_code opencl_prelude

  GC.earlyDecls top_decls

  let size_name_inits = map (\k -> [C.cinit|$string:(pretty k)|]) $ M.keys sizes
      size_class_inits = map (\(c,_) -> [C.cinit|$string:(pretty c)|]) $ M.elems sizes
      size_entry_points_inits = map (\(_,e) -> [C.cinit|$string:(pretty e)|]) $ M.elems sizes

  GC.libDecl [C.cedecl|static const char *size_names[] = { $inits:size_name_inits };|]
  GC.libDecl [C.cedecl|static const char *size_classes[] = { $inits:size_class_inits };|]
  GC.libDecl [C.cedecl|static const char *size_entry_points[] = { $inits:size_entry_points_inits };|]

  GC.publicDef_ "get_num_sizes" GC.InitDecl $ \s ->
    ([C.cedecl|int $id:s(void);|],
     [C.cedecl|int $id:s(void) {
                return $int:(M.size sizes);
              }|])

  GC.publicDef_ "get_size_name" GC.InitDecl $ \s ->
    ([C.cedecl|const char* $id:s(int);|],
     [C.cedecl|const char* $id:s(int i) {
                return size_names[i];
              }|])

  GC.publicDef_ "get_size_class" GC.InitDecl $ \s ->
    ([C.cedecl|const char* $id:s(int);|],
     [C.cedecl|const char* $id:s(int i) {
                return size_classes[i];
              }|])

  GC.publicDef_ "get_size_entry" GC.InitDecl $ \s ->
    ([C.cedecl|const char* $id:s(int);|],
     [C.cedecl|const char* $id:s(int i) {
                return size_entry_points[i];
              }|])

  let size_decls = map (\k -> [C.csdecl|size_t $id:k;|]) $ M.keys sizes
  GC.libDecl [C.cedecl|struct sizes { $sdecls:size_decls };|]
  cfg <- GC.publicDef "context_config" GC.InitDecl $ \s ->
    ([C.cedecl|struct $id:s;|],
     [C.cedecl|struct $id:s { struct opencl_config opencl;
                              size_t sizes[$int:(M.size sizes)];
                            };|])

  let size_value_inits = map (\i -> [C.cstm|cfg->sizes[$int:i] = 0;|]) [0..M.size sizes-1]
  GC.publicDef_ "context_config_new" GC.InitDecl $ \s ->
    ([C.cedecl|struct $id:cfg* $id:s(void);|],
     [C.cedecl|struct $id:cfg* $id:s(void) {
                         struct $id:cfg *cfg = malloc(sizeof(struct $id:cfg));
                         if (cfg == NULL) {
                           return NULL;
                         }

                         $stms:size_value_inits
                         opencl_config_init(&cfg->opencl, $int:(M.size sizes),
                                            size_names, cfg->sizes, size_classes, size_entry_points);

                         cfg->opencl.transpose_block_dim = $int:(transposeBlockDim::Int);
                         return cfg;
                       }|])

  GC.publicDef_ "context_config_free" GC.InitDecl $ \s ->
    ([C.cedecl|void $id:s(struct $id:cfg* cfg);|],
     [C.cedecl|void $id:s(struct $id:cfg* cfg) {
                         free(cfg);
                       }|])

  GC.publicDef_ "context_config_set_debugging" GC.InitDecl $ \s ->
    ([C.cedecl|void $id:s(struct $id:cfg* cfg, int flag);|],
     [C.cedecl|void $id:s(struct $id:cfg* cfg, int flag) {
                         cfg->opencl.logging = cfg->opencl.debugging = flag;
                       }|])

  GC.publicDef_ "context_config_set_logging" GC.InitDecl $ \s ->
    ([C.cedecl|void $id:s(struct $id:cfg* cfg, int flag);|],
     [C.cedecl|void $id:s(struct $id:cfg* cfg, int flag) {
                         cfg->opencl.logging = flag;
                       }|])

  GC.publicDef_ "context_config_set_device" GC.InitDecl $ \s ->
    ([C.cedecl|void $id:s(struct $id:cfg* cfg, const char *s);|],
     [C.cedecl|void $id:s(struct $id:cfg* cfg, const char *s) {
                         set_preferred_device(&cfg->opencl, s);
                       }|])

  GC.publicDef_ "context_config_set_platform" GC.InitDecl $ \s ->
    ([C.cedecl|void $id:s(struct $id:cfg* cfg, const char *s);|],
     [C.cedecl|void $id:s(struct $id:cfg* cfg, const char *s) {
                         set_preferred_platform(&cfg->opencl, s);
                       }|])

  GC.publicDef_ "context_config_dump_program_to" GC.InitDecl $ \s ->
    ([C.cedecl|void $id:s(struct $id:cfg* cfg, const char *path);|],
     [C.cedecl|void $id:s(struct $id:cfg* cfg, const char *path) {
                         cfg->opencl.dump_program_to = path;
                       }|])

  GC.publicDef_ "context_config_load_program_from" GC.InitDecl $ \s ->
    ([C.cedecl|void $id:s(struct $id:cfg* cfg, const char *path);|],
     [C.cedecl|void $id:s(struct $id:cfg* cfg, const char *path) {
                         cfg->opencl.load_program_from = path;
                       }|])

  GC.publicDef_ "context_config_set_default_group_size" GC.InitDecl $ \s ->
    ([C.cedecl|void $id:s(struct $id:cfg* cfg, int size);|],
     [C.cedecl|void $id:s(struct $id:cfg* cfg, int size) {
                         cfg->opencl.default_group_size = size;
                         cfg->opencl.default_group_size_changed = 1;
                       }|])

  GC.publicDef_ "context_config_set_default_num_groups" GC.InitDecl $ \s ->
    ([C.cedecl|void $id:s(struct $id:cfg* cfg, int num);|],
     [C.cedecl|void $id:s(struct $id:cfg* cfg, int num) {
                         cfg->opencl.default_num_groups = num;
                       }|])

  GC.publicDef_ "context_config_set_default_tile_size" GC.InitDecl $ \s ->
    ([C.cedecl|void $id:s(struct $id:cfg* cfg, int num);|],
     [C.cedecl|void $id:s(struct $id:cfg* cfg, int size) {
                         cfg->opencl.default_tile_size = size;
                         cfg->opencl.default_tile_size_changed = 1;
                       }|])

  GC.publicDef_ "context_config_set_default_threshold" GC.InitDecl $ \s ->
    ([C.cedecl|void $id:s(struct $id:cfg* cfg, int num);|],
     [C.cedecl|void $id:s(struct $id:cfg* cfg, int size) {
                         cfg->opencl.default_threshold = size;
                       }|])

  GC.publicDef_ "context_config_set_size" GC.InitDecl $ \s ->
    ([C.cedecl|int $id:s(struct $id:cfg* cfg, const char *size_name, size_t size_value);|],
     [C.cedecl|int $id:s(struct $id:cfg* cfg, const char *size_name, size_t size_value) {

                         for (int i = 0; i < $int:(M.size sizes); i++) {
                           if (strcmp(size_name, size_names[i]) == 0) {
                             cfg->sizes[i] = size_value;
                             return 0;
                           }
                         }
                         return 1;
                       }|])

  (fields, init_fields) <- GC.contextContents
  ctx <- GC.publicDef "context" GC.InitDecl $ \s ->
    ([C.cedecl|struct $id:s;|],
     [C.cedecl|struct $id:s {
                         int detail_memory;
                         int debugging;
                         int logging;
                         typename lock_t lock;
                         char *error;
                         $sdecls:fields
                         $sdecls:ctx_opencl_fields
                         struct opencl_context opencl;
                         struct sizes sizes;
                       };|])

  mapM_ GC.libDecl later_top_decls
  let set_required_types = [ [C.cstm|required_types |= OPENCL_F64; |]
                           | FloatType Float64 `elem` types ]
      set_sizes = zipWith (\i k -> [C.cstm|ctx->sizes.$id:k = cfg->sizes[$int:i];|])
                          [(0::Int)..] $ M.keys sizes

  GC.libDecl [C.cedecl|static void init_context_early(struct $id:cfg *cfg, struct $id:ctx* ctx) {
                     typename cl_int error;
                     ctx->opencl.cfg = cfg->opencl;
                     ctx->detail_memory = cfg->opencl.debugging;
                     ctx->debugging = cfg->opencl.debugging;
                     ctx->logging = cfg->opencl.logging;
                     ctx->error = NULL;
                     create_lock(&ctx->lock);

                     $stms:init_fields
                     $stms:ctx_opencl_inits
  }|]

  GC.libDecl [C.cedecl|static void init_context_late(struct $id:cfg *cfg, struct $id:ctx* ctx, typename cl_program prog) {
                     typename cl_int error;
                     // Load all the kernels.
                     $stms:(map (loadKernelByName) kernel_names)

                     $stms:final_inits

                     $stms:set_sizes
  }|]

  GC.publicDef_ "context_new" GC.InitDecl $ \s ->
    ([C.cedecl|struct $id:ctx* $id:s(struct $id:cfg* cfg);|],
     [C.cedecl|struct $id:ctx* $id:s(struct $id:cfg* cfg) {
                          struct $id:ctx* ctx = malloc(sizeof(struct $id:ctx));
                          if (ctx == NULL) {
                            return NULL;
                          }

                          int required_types = 0;
                          $stms:set_required_types

                          init_context_early(cfg, ctx);
                          typename cl_program prog = setup_opencl(&ctx->opencl, opencl_program, required_types);
                          init_context_late(cfg, ctx, prog);
                          return ctx;
                       }|])

  GC.publicDef_ "context_new_with_command_queue" GC.InitDecl $ \s ->
    ([C.cedecl|struct $id:ctx* $id:s(struct $id:cfg* cfg, typename cl_command_queue queue);|],
     [C.cedecl|struct $id:ctx* $id:s(struct $id:cfg* cfg, typename cl_command_queue queue) {
                          struct $id:ctx* ctx = malloc(sizeof(struct $id:ctx));
                          if (ctx == NULL) {
                            return NULL;
                          }

                          int required_types = 0;
                          $stms:set_required_types

                          init_context_early(cfg, ctx);
                          typename cl_program prog = setup_opencl_with_command_queue(&ctx->opencl, queue, opencl_program, required_types);
                          init_context_late(cfg, ctx, prog);
                          return ctx;
                       }|])

  GC.publicDef_ "context_free" GC.InitDecl $ \s ->
    ([C.cedecl|void $id:s(struct $id:ctx* ctx);|],
     [C.cedecl|void $id:s(struct $id:ctx* ctx) {
                                 free_lock(&ctx->lock);
                                 free(ctx);
                               }|])

  GC.publicDef_ "context_sync" GC.InitDecl $ \s ->
    ([C.cedecl|int $id:s(struct $id:ctx* ctx);|],
     [C.cedecl|int $id:s(struct $id:ctx* ctx) {
                         OPENCL_SUCCEED(clFinish(ctx->opencl.queue));
                         return 0;
                       }|])

  GC.publicDef_ "context_get_error" GC.InitDecl $ \s ->
    ([C.cedecl|char* $id:s(struct $id:ctx* ctx);|],
     [C.cedecl|char* $id:s(struct $id:ctx* ctx) {
                         char* error = ctx->error;
                         ctx->error = NULL;
                         return error;
                       }|])

  GC.publicDef_ "context_clear_caches" GC.InitDecl $ \s ->
    ([C.cedecl|int $id:s(struct $id:ctx* ctx);|],
     [C.cedecl|int $id:s(struct $id:ctx* ctx) {
                         OPENCL_SUCCEED(opencl_free_all(&ctx->opencl));
                         return 0;
                       }|])

  GC.publicDef_ "context_get_command_queue" GC.InitDecl $ \s ->
    ([C.cedecl|typename cl_command_queue $id:s(struct $id:ctx* ctx);|],
     [C.cedecl|typename cl_command_queue $id:s(struct $id:ctx* ctx) {
                 return ctx->opencl.queue;
               }|])

  mapM_ GC.debugReport $ openClReport kernel_names

openClDecls :: [String] -> String -> String
            -> ([C.FieldGroup], [C.Stm], [C.Definition], [C.Definition])
openClDecls kernel_names opencl_program opencl_prelude =
  (ctx_fields, ctx_inits, openCL_boilerplate, openCL_load)
  where opencl_program_fragments =
          -- Some C compilers limit the size of literal strings, so
          -- chunk the entire program into small bits here, and
          -- concatenate it again at runtime.
          [ [C.cinit|$string:s|] | s <- chunk 2000 (opencl_prelude++opencl_program) ]
        nullptr = [C.cinit|NULL|]

        ctx_fields =
          [ [C.csdecl|int total_runs;|],
            [C.csdecl|long int total_runtime;|] ] ++
          concat
          [ [ [C.csdecl|typename cl_kernel $id:name;|]
            , [C.csdecl|int $id:(kernelRuntime name);|]
            , [C.csdecl|int $id:(kernelRuns name);|]
            ]
          | name <- kernel_names ]

        ctx_inits =
          [ [C.cstm|ctx->total_runs = 0;|],
            [C.cstm|ctx->total_runtime = 0;|] ] ++
          concat
          [ [ [C.cstm|ctx->$id:(kernelRuntime name) = 0;|]
            , [C.cstm|ctx->$id:(kernelRuns name) = 0;|]
            ]
          | name <- kernel_names ]

        openCL_load = [
          [C.cedecl|
void post_opencl_setup(struct opencl_context *ctx, struct opencl_device_option *option) {
  $stms:(map sizeHeuristicsCode sizeHeuristicsTable)
}|]]

        openCL_h = $(embedStringFile "rts/c/opencl.h")

        openCL_boilerplate = [C.cunit|
          $esc:openCL_h
          const char *opencl_program[] =
            {$inits:(opencl_program_fragments++[nullptr])};|]

loadKernelByName :: String -> C.Stm
loadKernelByName name = [C.cstm|{
  ctx->$id:name = clCreateKernel(prog, $string:name, &error);
  assert(error == 0);
  if (ctx->debugging) {
    fprintf(stderr, "Created kernel %s.\n", $string:name);
  }
  }|]

kernelRuntime :: String -> String
kernelRuntime = (++"_total_runtime")

kernelRuns :: String -> String
kernelRuns = (++"_runs")

openClReport :: [String] -> [C.BlockItem]
openClReport names = report_kernels ++ [report_total]
  where longest_name = foldl max 0 $ map length names
        report_kernels = concatMap reportKernel names
        format_string name =
          let padding = replicate (longest_name - length name) ' '
          in unwords ["Kernel",
                      name ++ padding,
                      "executed %6d times, with average runtime: %6ldus\tand total runtime: %6ldus\n"]
        reportKernel name =
          let runs = kernelRuns name
              total_runtime = kernelRuntime name
          in [[C.citem|
               fprintf(stderr,
                       $string:(format_string name),
                       ctx->$id:runs,
                       (long int) ctx->$id:total_runtime / (ctx->$id:runs != 0 ? ctx->$id:runs : 1),
                       (long int) ctx->$id:total_runtime);
              |],
              [C.citem|ctx->total_runtime += ctx->$id:total_runtime;|],
              [C.citem|ctx->total_runs += ctx->$id:runs;|]]

        report_total = [C.citem|
                          if (ctx->debugging) {
                            fprintf(stderr, "Ran %d kernels with cumulative runtime: %6ldus\n",
                                    ctx->total_runs, ctx->total_runtime);
                          }
                        |]

sizeHeuristicsCode :: SizeHeuristic -> C.Stm
sizeHeuristicsCode (SizeHeuristic platform_name device_type which what) =
  [C.cstm|
   if ($exp:which' == 0 &&
       strstr(option->platform_name, $string:platform_name) != NULL &&
       option->device_type == $exp:(clDeviceType device_type)) {
     $stm:get_size
   }|]
  where clDeviceType DeviceGPU = [C.cexp|CL_DEVICE_TYPE_GPU|]
        clDeviceType DeviceCPU = [C.cexp|CL_DEVICE_TYPE_CPU|]

        which' = case which of
                   LockstepWidth -> [C.cexp|ctx->lockstep_width|]
                   NumGroups -> [C.cexp|ctx->cfg.default_num_groups|]
                   GroupSize -> [C.cexp|ctx->cfg.default_group_size|]
                   TileSize -> [C.cexp|ctx->cfg.default_tile_size|]

        get_size = case what of
                     HeuristicConst x ->
                       [C.cstm|$exp:which' = $int:x;|]
                     HeuristicDeviceInfo s ->
                       -- This only works for device info that fits in the variable.
                       let s' = "CL_DEVICE_" ++ s
                       in [C.cstm|clGetDeviceInfo(ctx->device,
                                                  $id:s',
                                                  sizeof($exp:which'),
                                                  &$exp:which',
                                                  NULL);|]
