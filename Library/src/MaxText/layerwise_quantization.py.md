# Layerwise Quantization Module Documentation

## Module Overview

**Purpose**: Provides layer-by-layer quantization capabilities for large language models, enabling efficient compression of DeepSeek-family models through selective per-layer quantization without loading the entire model into memory at once.

**Key Features**:
- Layer-by-layer loading and quantization to reduce memory footprint
- Support for DeepSeek-family models (DeepSeek dense layers and mixture-of-experts layers)
- Selective quantization of specific layers while preserving unquantized layers
- Integration with orbax checkpointing for efficient parameter loading
- Automatic quantization mode configuration and conversion

**Integration**: Works with quantization strategies defined in `layers/quantizations.py`, checkpoint management via `checkpointing.py`, and DeepSeek model architecture in `layers/deepseek.py`.

---

## Architecture

### Component Structure

```
LayerwiseQuantization
├── __init__
│   ├── Config validation (DeepSeek only)
│   ├── Device mesh creation
│   ├── Quantization configuration
│   └── Abstract model state generation
├── load_and_quantize (main entry point)
│   ├── Initialize quantized params structure
│   ├── Set quantization mode to "convert"
│   ├── Process dense layers (0 to first_num_dense_layers)
│   ├── Process MoE layers (first_num_dense_layers to num_decoder_layers)
│   ├── Load and preserve unquantized layers
│   └── Save quantized checkpoint
├── _load_layer (parameter loading)
│   ├── Create partial abstract params
│   └── Load from checkpoint path
└── _create_partial_abstract_params (selective loading)
    ├── Filter abstract structure by layer name
    └── Use ocp.PLACEHOLDER for skipped layers
```

### Data Flow

```
Configuration
    ↓
Device Mesh & Quantization Setup
    ↓
Abstract Model State
    ↓
For each layer:
  ├── Load layer parameters (selective loading via PLACEHOLDER)
  ├── Apply quantization through model forward pass
  ├── Extract quantization metadata (AQT)
  ├── Remove quantized params from original
  └── Save to quantized_params dict
    ↓
Save full checkpoint (params + aqt metadata)
```

### Design Patterns

- **Selective Parameter Loading**: Uses orbax `PLACEHOLDER` to avoid loading unneeded layers into memory
- **Layerwise Processing**: Iterates through model layers to quantize sequentially
- **Separation of Concerns**: Divides dense and MoE layers separately with different layer types
- **Dual Parameter Storage**: Maintains both `params` (quantized weights) and `aqt` (quantization metadata)

### Dependencies

- **Internal**: `pyconfig`, `maxtext_utils`, `checkpointing`, `quantizations`, `deepseek`, `max_utils`, `common_types`
- **External**: JAX, Flax (linen partitioning), orbax checkpoint, tqdm, absl

---

## Classes & Methods

### `LayerwiseQuantization`

Main class for handling layer-by-layer quantization of large models.

#### Class Definition

```python
class LayerwiseQuantization:
  """Layerwise quantization for large models."""

  def __init__(self, config: Any)
  def load_and_quantize(self, rng: None | PRNGKeyType = None) -> None
  def _load_layer(self, layer_name: str) -> dict
  def _create_partial_abstract_params(self, abstract_unboxed_params, layer: str) -> dict
```

#### Constructor: `__init__(config: Any)`

**Purpose**: Initialize the quantization handler with model configuration and abstract state.

**Parameters**:
- `config` (Any): PyConfig instance containing model, quantization, and checkpoint settings

**Attributes Set**:
- `self.config`: Configuration object
- `self._mesh`: JAX Mesh for distributed computation
- `self.quant`: Quantization configuration (from `quantizations.configure_quantization`)
- `self.unboxed_abstract_state`: Abstract model state (parameter structure without values)

**Validation**:
- Asserts that `config.decoder_block == DecoderBlockType.DEEPSEEK` (only DeepSeek supported)

**Side Effects**:
- Creates device mesh based on config
- Initializes abstract model state (no actual parameters loaded)

---

#### Method: `load_and_quantize(rng: None | PRNGKeyType = None) -> None`

**Purpose**: Load parameters layer by layer, apply quantization, and save the result.

**Parameters**:
- `rng` (PRNGKey or None): Random number generator key for quantization operations

**Process**:
1. Initialize quantized parameters structure with empty decoder dict and aqt metadata dict
2. Set quantization mode to "convert" (for quantization-aware training)
3. Create two layer types: `DeepSeekDenseLayer` and `DeepSeekMoELayer`
4. Process dense layers (0 to `config.first_num_dense_layers`):
   - Load layer parameters selectively
   - Apply model forward pass to quantize
   - Extract AQT metadata from new_vars
   - Remove quantized params from original
5. Process MoE layers (`first_num_dense_layers` to `config.num_decoder_layers`):
   - Same process as dense layers
6. Load and preserve unquantized layers:
   - `decoder_norm`
   - `logits_dense`
7. Load token embedder (not quantized)
8. Save quantized checkpoint

**Side Effects**:
- Modifies quantization mode
- Writes checkpoint to disk (if configured)
- Progress bar via tqdm

**Example**:
```python
config = pyconfig.initialize(argv)
quantizer = LayerwiseQuantization(config)
rng = jax.random.PRNGKey(42)
quantizer.load_and_quantize(rng)
```

---

#### Method: `_load_layer(layer_name: str) -> dict`

**Purpose**: Load a specific layer's parameters from the source checkpoint.

**Parameters**:
- `layer_name` (str): Name of the layer to load (e.g., "dense_layers_0", "moe_layers_5")

**Returns**:
- Dictionary containing loaded parameters with structure: `{"params": {...}, "aqt": {...}}`

**Implementation Details**:
- Creates partial abstract parameters (only for specified layer)
- Uses `checkpointing.load_params_from_path` with selective loading
- Respects checkpoint storage configuration (OCDBT, Zarr3)

**Side Effects**:
- Reads from checkpoint path specified in config

---

#### Method: `_create_partial_abstract_params(abstract_unboxed_params: dict, layer: str) -> dict`

**Purpose**: Create a filtered abstract parameter structure that only includes the specified layer.

**Parameters**:
- `abstract_unboxed_params` (dict): Full abstract parameter structure
- `layer` (str): Layer name to keep (all others replaced with PLACEHOLDER)

**Returns**:
- New abstract parameter structure with `ocp.PLACEHOLDER` for non-matching layers

**Implementation**:
- Uses `jax.tree_util.tree_map_with_path` to traverse parameter tree
- For each path: if layer name is in path keys, keep the value; otherwise, replace with `IGNORE` (PLACEHOLDER)

**Purpose of PLACEHOLDER**: Signals orbax to skip loading those parameters, reducing I/O and memory usage.

**Example**:
```python
# If layer = "dense_layers_0", only loads parameters under that path
# All other paths get ocp.PLACEHOLDER
```

---

## Functions

### `main(argv: Sequence[str]) -> None`

**Purpose**: Command-line entry point for the layerwise quantization script.

**Parameters**:
- `argv` (Sequence[str]): Command-line arguments (passed from absl)

**Process**:
1. Configure JAX with unsafe RBG PRNG (for reproducibility)
2. Set TensorFlow logging level to 0
3. Load configuration from YAML + CLI arguments
4. Validate configuration
5. Print system information
6. Create LayerwiseQuantization instance
7. Generate random keys for quantization
8. Call `load_and_quantize`

**Side Effects**:
- Initializes JAX and TensorFlow settings
- Prints diagnostic information
- Modifies checkpoint on disk

---

### `validate_config(config: Any) -> None`

**Purpose**: Validate that configuration is suitable for layerwise quantization.

**Validation**:
- Asserts that `config.load_full_state_path == ""` (must use parameter checkpoints, not full state)

**Raises**: AssertionError if full state loading is configured

---

## Configuration & Parameters

### Required Configuration

| Parameter | Type | Purpose | Example |
|-----------|------|---------|---------|
| `model_name` | str | Model identifier | `"deepseek2-16b"` |
| `load_parameters_path` | str | Path to source checkpoint | `"gs://bucket/ckpt"` |
| `save_quantized_params_path` | str | Path to save quantized checkpoint | `"gs://bucket/quantized"` |
| `quantization` | str | Quantization strategy | `"int8"` |
| `decoder_block` | DecoderBlockType | Model architecture type | `DecoderBlockType.DEEPSEEK` |

### Key Model Parameters

| Parameter | Type | Purpose |
|-----------|------|---------|
| `num_decoder_layers` | int | Total number of decoder layers |
| `first_num_dense_layers` | int | Number of dense layers before MoE layers |
| `base_emb_dim` | int | Base embedding dimension |
| `max_prefill_predict_length` | int | Maximum prefill sequence length |

### Quantization Parameters

| Parameter | Type | Purpose | Default |
|-----------|------|---------|---------|
| `attention` | str | Attention type | `"dot_product"` |
| `weight_dtype` | str | Weight data type | `"bfloat16"` |
| `per_device_batch_size` | int | Batch size per device | `1` |

### Distributed Training Parameters

| Parameter | Type | Purpose |
|-----------|------|---------|
| `ici_fsdp_parallelism` | int | FSDP degree within ICI |
| `ici_autoregressive_parallelism` | int | Autoregressive parallelism |
| `ici_tensor_parallelism` | int | Tensor parallelism degree |

### Checkpoint Parameters

| Parameter | Type | Purpose | Default |
|-----------|------|---------|---------|
| `checkpoint_storage_use_ocdbt` | bool | Use OCDBT format | False |
| `checkpoint_storage_use_zarr3` | bool | Use Zarr3 format | False |
| `checkpoint_storage_concurrent_gb` | float | Concurrent I/O in GB | 8 |

### Optional Features

| Parameter | Type | Purpose | Default |
|-----------|------|---------|---------|
| `async_checkpointing` | bool | Async checkpoint loading | false |
| `enable_single_controller` | bool | Single controller mode | true |
| `scan_layers` | bool | Use scan for layer stacking | false |
| `megablox` | bool | Enable Megablox | false |
| `sparse_matmul` | bool | Sparse matrix multiplication | false |

---

## Usage Examples

### Basic Command-Line Usage

```bash
python3 -m MaxText.layerwise_quantization src/MaxText/configs/base.yml \
  tokenizer_path=path/to/tokenizer.model \
  load_parameters_path=gs://bucket/source_ckpt \
  model_name=deepseek2-16b \
  ici_fsdp_parallelism=1 \
  ici_autoregressive_parallelism=1 \
  ici_tensor_parallelism=-1 \
  scan_layers=false \
  weight_dtype=bfloat16 \
  per_device_batch_size=1 \
  attention=dot_product \
  quantization=int8 \
  async_checkpointing=false \
  enable_single_controller=true \
  tokenizer_type=huggingface \
  megablox=false \
  sparse_matmul=false \
  save_quantized_params_path=gs://bucket/quantized_ckpt \
  checkpoint_storage_use_ocdbt=False \
  checkpoint_storage_use_zarr3=False
```

### Python API Usage

```python
from MaxText import pyconfig, layerwise_quantization
import jax

# Load configuration
config = pyconfig.initialize([
    "src/MaxText/configs/base.yml",
    "load_parameters_path=gs://bucket/ckpt",
    "save_quantized_params_path=gs://bucket/quantized",
    "model_name=deepseek2-16b",
    "quantization=int8"
])

# Create quantizer
quantizer = layerwise_quantization.LayerwiseQuantization(config)

# Run quantization
rng = jax.random.PRNGKey(1234)
quantizer.load_and_quantize(rng)
```

### Custom Quantization Mode

```python
from MaxText import layerwise_quantization, quantizations, pyconfig
import jax

config = pyconfig.initialize([...])
quantizer = layerwise_quantization.LayerwiseQuantization(config)

# Override quantization mode if needed
quantizer.quant.quant_mode = quantizations.get_quant_mode("custom_mode")

rng = jax.random.PRNGKey(42)
quantizer.load_and_quantize(rng)
```

### Processing Specific Layers

```python
# Access individual layer loading
quantizer = layerwise_quantization.LayerwiseQuantization(config)

# Load a single layer
layer_params = quantizer._load_layer("dense_layers_0")
print(f"Loaded parameters: {layer_params.keys()}")

# Create partial abstract params
partial_params = quantizer._create_partial_abstract_params(
    quantizer.unboxed_abstract_state.params,
    "moe_layers_5"
)
```

---

## Performance Characteristics

### Time Complexity

- **Overall**: O(n_layers × (load_time + quantize_time))
- **Layer Loading**: O(layer_size) - sequential I/O per layer
- **Quantization**: O(layer_size × seq_length) - forward pass through layer
- **Checkpoint Saving**: O(total_params) - full checkpoint write

### Memory Usage

- **Peak Memory**: Single layer size + model code footprint
- **Memory Efficiency**: ~1-2 GB per 10B parameter layer (vs ~20-40 GB for full model)
- **Bandwidth**: Depends on checkpoint storage (OCDBT/Zarr3 optimized)

### I/O Characteristics

- **Selective Loading**: Only loads required layers (via PLACEHOLDER)
- **Checkpoint I/O**: Depends on `checkpoint_storage_concurrent_gb` setting
- **Sequential Processing**: Layers processed one at a time (enables memory efficiency)

### Optimization Opportunities

- **Parallel Layer Processing**: Could process independent layer groups in parallel
- **Batch Quantization**: Multiple layers could be quantized in a single forward pass with proper scheduling
- **Streaming I/O**: Use async I/O to overlap loading and quantization
- **Memory Pre-allocation**: Pre-allocate quantized params structure for faster saves

### Bottlenecks

- **Checkpoint I/O**: Reading from distributed storage (GCS/S3) can dominate runtime
- **Forward Pass**: Quantization awareness requires full forward pass per layer
- **Serialization**: Saving quantized checkpoint to disk (especially for large models)

---

## Testing & Verification

### Related Test Files

While no specific test file is currently dedicated to `layerwise_quantization.py` in the repository, the module is tested indirectly through:
- `tests/quantizations_test.py` - Tests quantization strategies and modes
- `tests/model_test.py` - Tests model architecture (including DeepSeek)
- Integration tests with full training pipelines

### How to Verify Functionality

```python
import jax
from MaxText import pyconfig, layerwise_quantization

# 1. Test configuration loading
config = pyconfig.initialize(["src/MaxText/configs/base.yml", "model_name=deepseek2-16b"])
assert config.model_name == "deepseek2-16b"

# 2. Test initialization
try:
    quantizer = layerwise_quantization.LayerwiseQuantization(config)
    print("✓ LayerwiseQuantization initialized successfully")
except AssertionError as e:
    print(f"✗ DeepSeek model required: {e}")

# 3. Test layer loading
layer_params = quantizer._load_layer("dense_layers_0")
assert "params" in layer_params
print("✓ Layer loading works")

# 4. Test quantization (with real checkpoint)
rng = jax.random.PRNGKey(42)
# This would require actual checkpoint files
# quantizer.load_and_quantize(rng)
```

### Edge Cases to Test

- **Invalid Model Type**: Non-DeepSeek models should raise AssertionError
- **Missing Checkpoint**: File not found should propagate from checkpointing module
- **Invalid Quantization Type**: Should be caught by quantizations module
- **Partial Checkpoints**: Missing layers should be handled gracefully
- **Large Models**: Test with 70B+ parameter models to verify memory efficiency

### Known Issues & Limitations

1. **DeepSeek-Only**: Only supports DeepSeek-family models (as enforced by assertion)
2. **Parameter Checkpoints**: Cannot work with full training state checkpoints
3. **Layer Structure**: Assumes specific dense/MoE layer structure (hardcoded layer names)
4. **Single RNG**: Uses single RNG key for all layer quantization (no randomness per layer)

---

## Related Modules & References

### Dependencies

**Internal Module Dependencies**:
- `pyconfig.py` - Configuration management (initialization, validation)
- `quantizations.py` - Quantization strategies and mode configuration
- `checkpointing.py` - Parameter loading from checkpoints
- `layers/deepseek.py` - DeepSeek model layer implementations
- `layers/models.py` - Model initialization and abstract state
- `maxtext_utils.py` - Utilities (device mesh, checkpoint saving, abstract state)
- `max_utils.py` - General JAX/Flax utilities
- `common_types.py` - Type definitions (DecoderBlockType, MODEL_MODE_*)

**External Dependencies**:
- `jax` - Numerical computing and autodiff
- `flax.linen` - Neural network definitions
- `orbax.checkpoint` - Checkpoint saving/loading (PLACEHOLDER mechanism)
- `absl.app` - Command-line application framework
- `tqdm` - Progress bars

### Modules That Depend On This

- Training pipelines that incorporate quantization
- Model serving systems that need quantized checkpoints
- Post-training optimization scripts

### Integration Points

1. **Configuration System** (`pyconfig.py`):
   - Loads configuration from YAML + CLI
   - Validates model name and checkpoint paths

2. **Quantization System** (`quantizations.py`):
   - Provides quantization mode and strategy
   - Handles `remove_quantized_params` extraction

3. **Checkpoint System** (`checkpointing.py`):
   - Loads parameters with selective loading via PLACEHOLDER
   - Saves quantized parameters back

4. **Model Architecture** (`layers/deepseek.py`, `layers/models.py`):
   - Provides layer definitions for forward pass
   - Supplies abstract state for parameter structure

### Cross-References

- **Quantization Documentation**: See `Library/src/MaxText/layers/quantizations.py.md`
- **DeepSeek Architecture**: See `Library/src/MaxText/layers/deepseek.py.md`
- **Checkpoint Management**: See `Library/src/MaxText/checkpointing.py.md`
- **Configuration System**: See `Library/src/MaxText/pyconfig.py.md`

### Related Concepts

- **Automatic Quantization Training (AQT)**: Learning quantization scales during training
- **Layer-wise Quantization**: Quantizing individual layers to reduce memory during conversion
- **Sparse Computation**: Similar concept to MoE (only active components compute)
- **Selective Parameter Loading**: Using placeholders to avoid unnecessary I/O

---

## Summary

The `layerwise_quantization.py` module provides an efficient mechanism for converting large DeepSeek models to quantized formats without requiring the entire model in memory simultaneously. By processing layers sequentially with selective parameter loading, it achieves significant memory reduction while maintaining quantization quality through proper metadata preservation.

Key design decisions:
- **Sequential Processing**: Process one layer at a time for memory efficiency
- **Selective Loading**: Use orbax PLACEHOLDER to avoid loading unneeded parameters
- **Dual Storage**: Maintain both quantized weights and quantization metadata
- **DeepSeek Focus**: Specialized for DeepSeek architecture (future expansion to other models possible)

The module is primarily used as a command-line tool for post-training quantization, though it can also be used programmatically for custom quantization workflows.
