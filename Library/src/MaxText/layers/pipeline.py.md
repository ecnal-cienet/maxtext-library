# Pipeline Parallelism Module (`pipeline.py`)

## Overview

The `pipeline.py` module implements **pipeline parallelism** for efficient distributed training of large language models across multiple stages. This module enables models to be split layer-wise across different devices, allowing computation to pipeline through stages while reducing per-device memory requirements and enabling larger model training.

### Key Characteristics

- **Stage-based execution**: Model layers distributed across stages, computed in parallel
- **Circular pipelining support**: Enables multiple passes through the same layers
- **Microbatch scheduling**: Automatically schedules microbatches through pipeline stages
- **Memory-efficient buffering**: Smart buffer management for intermediate activations
- **JAX/Flax integration**: Native integration with JAX's SPMD and Flax's vmap

### File Location
- **Path**: `src/MaxText/layers/pipeline.py`
- **Lines of code**: ~816 lines
- **Key dependencies**: JAX, Flax, MaxText configuration system

---

## Architecture Overview

### Pipeline Execution Model

```
Input Microbatches → [Stage 0] → [Stage 1] → [Stage 2] → [Stage 3] → Output
                      (Layers)    (Layers)    (Layers)    (Layers)
```

The pipeline works by:
1. **Splitting** the model into stages (groups of layers)
2. **Sharding** input data into microbatches
3. **Scheduling** microbatches to flow through stages sequentially
4. **Overlapping** computation across stages to maximize throughput

### Key Concepts

#### Microbatches
- **Definition**: The global batch is divided into smaller `num_pipeline_microbatches`
- **Purpose**: Allows stages to process different microbatches in parallel
- **Benefits**: Reduces pipeline bubble time and improves device utilization

#### Stages
- **Definition**: The model is divided into `num_stages` groups of layers
- **Calculation**: `num_stages = ici_pipeline_parallelism * dcn_pipeline_parallelism`
- **Purpose**: Each stage runs on different devices/hosts

#### Pipeline Bubble
- **Definition**: Time when some stages are idle waiting for data
- **Bubbles**: `bubble_iterations = forwarding_delay * (num_stages - 1)`
- **Optimization**: Larger microbatch counts reduce bubble overhead

#### Circular Pipelines
- **Definition**: Multiple passes through the same pipeline (weight sharing)
- **Use case**: Training with repeated forward passes
- **Enabled by**: `config.num_pipeline_repeats > 1`

---

## Core Components

### 1. Pipeline Class

```python
class Pipeline(nn.Module):
  """Module that implements pipelining across stages."""

  config: Config                    # Configuration with pipeline settings
  layers: nn.Module                 # Layer instances (single or multiple per stage)
  mesh: Mesh                        # JAX device mesh
  remat_policy: Any = None          # Gradient rematerialization policy
```

#### Configuration Parameters

| Parameter | Type | Purpose |
|-----------|------|---------|
| `num_pipeline_microbatches` | int | Total microbatches to divide global batch into |
| `ici_pipeline_parallelism` | int | ICI (intra-chip) pipeline stages |
| `dcn_pipeline_parallelism` | int | DCN (inter-chip) pipeline stages |
| `num_pipeline_repeats` | int | Number of passes through pipeline (circular) |
| `pipeline_delay_activation_forwarding` | bool | Use delayed forwarding for better scheduling |
| `micro_batch_size_to_train_on` | int | Effective micro batch size |
| `max_target_length` | int | Sequence length |
| `emb_dim` | int | Embedding dimension |
| `pipeline_fsdp_ag_once` | bool | All-gather weights once before loop |
| `scan_pipeline_iterations` | bool | Use scan instead of explicit loop |
| `set_remat_policy_on_pipeline_iterations` | bool | Apply rematerialization policy |

### 2. State Management

#### Loop State Dictionary

```python
loop_state = {
    "state_io": Array[num_stages, microbatches_per_stage, micro_size, seq_len, emb],
    "shift": Array[num_stages, micro_size, seq_len, emb],
    "circ_storage": Array[num_stages, num_microbatches, micro_size, seq_len, emb] or None,
    "circ_storage_mover": Array[num_stages, micro_size, seq_len, emb] or None,
    "prev_outputs": Array[num_stages, micro_size, seq_len, emb] or None,
    "loop_iteration": int
}
```

#### State Components

- **state_io**: Input/output buffer, holds microbatches as they flow through pipeline
- **shift**: Rotation buffer, stores stage outputs to feed as next stage's inputs
- **circ_storage**: Circular buffer for microbatches when `num_microbatches > num_stages`
- **circ_storage_mover**: Intermediate buffer for pushing to circular storage
- **prev_outputs**: Previous iteration outputs (when using delayed forwarding)
- **loop_iteration**: Current iteration count

---

## Key Methods

### Initialization Methods

#### `setup(self)`

Initializes pipeline configuration and calculates derived parameters.

```python
def setup(self):
    self.num_stages = self.config.ici_pipeline_parallelism * self.config.dcn_pipeline_parallelism
    self.forwarding_delay = 2 if self.config.pipeline_delay_activation_forwarding else 1
    self.pipeline_microbatch_size = self.config.micro_batch_size_to_train_on // self.config.num_pipeline_microbatches
    microbatches_per_stage = self.config.num_pipeline_microbatches // self.num_stages
    self.microbatches_per_stage = microbatches_per_stage
    self.use_circ_storage = self.need_circ_storage()
    # ... axis name configuration
```

**Key calculations**:
- `num_stages`: Total pipeline stages (ICI × DCN)
- `forwarding_delay`: 1 or 2 depending on delayed forwarding
- `pipeline_microbatch_size`: Size of each microbatch
- `microbatches_per_stage`: How many microbatches each stage processes

---

#### `init_states(self, inputs)`

Initializes all buffers and state for pipeline execution.

**Input**:
- `inputs`: [num_microbatches, micro_batch_size, sequence, embed]

**Output**: Dictionary containing:
- `state_io`: Reshaped inputs [num_stages, microbatches_per_stage, ...]
- `shift`: Zero buffer [num_stages, micro_size, sequence, embed]
- `circ_storage`: Optional circular storage buffer
- `prev_outputs`: Optional previous outputs buffer
- `loop_iteration`: Initial value 0

**Logical constraints applied**:
- `"activation_stage"`: Pipeline stage dimension
- `"activation_batch"` or `"activation_batch_no_exp"`: Batch dimension
- `"activation_length"` or `"activation_length_no_exp"`: Sequence dimension
- `"activation_embed"`: Embedding dimension

---

### State Update Methods

#### `get_new_loop_state(self, output, loop_state)`

Updates loop state after one pipeline iteration completes.

**Operations**:
1. **Shift buffer update**: Rotate or shift previous outputs based on pipeline type
2. **State I/O update**: Rotate input/output buffer, inserting latest stage outputs
3. **Circular storage update**: If using circular pipeline, store outputs for reuse
4. **Iteration increment**: Increment loop counter

**Buffer rotations**:
- **_rotate_right()**: Circular rotation (last element moves to front)
- **_shift_right()**: Linear shift (pad at front, discard last)

**Usage**: Called after each `run_one_iteration()` completes

---

### Iteration Execution Methods

#### `get_iteration_inputs(self, loop_iteration, state_io, circ_storage, shift)`

Determines which inputs each stage receives for current iteration.

**Logic**:
```
For stage 0:
  - If early iterations: grab from state_io (new microbatches)
  - If later iterations: grab from circular storage or shift (previous stage outputs)

For stages 1+:
  - Always grab from shift (rotated outputs from previous iteration)
```

**Returns**: `stages_in` [num_stages, micro_size, sequence, embed]

---

#### `run_one_iteration(self, loop_state, pipeline_weights, positions, segment_ids, deterministic, model_mode, decoder_layer_instance)`

Executes one iteration of pipeline computation.

**Steps**:
1. Extract stage inputs from loop_state using `get_iteration_inputs()`
2. Gather weights for current repeat (if circular pipeline)
3. Gather positions and segment_ids for each stage's microbatch
4. Apply vmap to run all stages in parallel
5. Update loop_state with new outputs

**Parallel vmap**:
- Maps over stage dimension (0)
- Each stage gets its own slice of inputs and weights
- Broadcast positions, segment_ids, deterministic, model_mode

**Returns**: Updated `loop_state`

---

### Weight Management Methods

#### `get_current_stage_weights(self, pipeline_weights, loop_iteration)`

Retrieves correct weights for each stage at current iteration.

**For non-circular pipelines** (`num_pipeline_repeats == 1`):
- Returns full weights (same weights used every iteration)

**For circular pipelines** (`num_pipeline_repeats > 1`):
- Gathers weights corresponding to current repeat
- Each stage gets different repeat's weights
- Uses `vmap_parallel_gather()` for efficient gathering

**Returns**: Pytree with leading stage dimension [stages, ...]

---

#### `vmap_parallel_gather(self, weights, repeat_ids, repeat_dim_in_weights, stages_dim_in_weights)`

Gathers per-stage weights from multi-repeat weight tensor using vmap.

**Purpose**: Efficiently gather different repeat indices from shared weight tensor

**Algorithm**:
```python
# For each stage:
gathered[stage] = weights[repeat_ids[stage], stage, ...]
```

**Uses `jax.lax.dynamic_slice_in_dim()` for differentiable gathering**

---

#### `vmap_gather(self, xs, ids, ids_dim)`

Gathers slices from shared tensor based on per-stage indices.

**Use case**: Gathering different microbatch's positions/segment_ids for each stage

**Algorithm**:
```python
# For each stage with id i:
out[stage] = xs[id[stage], ...]
```

---

### Auxiliary Methods

#### `get_microbatch_and_repeat_ids(self, loop_iteration)`

Calculates which microbatch and repeat each stage is processing.

**Calculation**:
```python
microbatches_processed = max(loop_iteration - forwarding_delay * stage_idx, 0)
microbatch_ids = microbatches_processed % num_pipeline_microbatches
repeat_ids = microbatches_processed // num_pipeline_microbatches
```

**Purpose**: Determines which data/weights each stage needs for current iteration

**Returns**: `(microbatch_ids, repeat_ids)` arrays of shape [num_stages]

---

#### `shard_dim_by_stages(self, x, dim: int)`

Adds sharding constraint for a dimension to be sharded across "stage" axis.

**Uses**: `jax.lax.with_sharding_constraint()` to enforce sharding

**Purpose**: Directs compiler to distribute data across pipeline stages

---

#### `permute_output_micro_per_stage_dim(self, output)`

Reorders output microbatches to match original input order.

**Why needed**: Due to pipelining, microbatches complete in different order than input

**Calculation**:
```python
microbatch_0_idx = iterations_to_complete_first_microbatch() % microbatches_per_stage
permutation = (arange(microbatches_per_stage) + microbatch_0_idx) % microbatches_per_stage
```

---

#### `get_pipeline_remat_policy(self)`

Returns JAX rematerialization (remat) policy for pipeline.

**Policy**:
- Saves `"iteration_input"` and `"decoder_layer_input"` checkpoints
- Combines with custom policy if provided
- Enables memory-efficient backpropagation

**Returns**: `jax.checkpoint_policies` instance

---

### Compute Iteration Helpers

#### `iterations_to_complete_first_microbatch_one_repeat(self)`

Returns iterations needed for microbatch 0 to complete one repeat.

**Formula**:
```
iterations = forwarding_delay * (num_stages - 1)
```

**Explanation**: Microbatch needs to flow through all stages minus 1 (already at stage 0)

---

#### `iterations_to_complete_first_microbatch(self)`

Returns iterations for microbatch 0 to finish the final stage of the last repeat.

**Formula**:
```
iterations = (num_microbatches * (num_repeats - 1))
             + iterations_to_complete_first_microbatch_one_repeat()
```

---

#### `need_circ_storage(self)`

Determines if circular storage buffer is needed.

**Condition**:
```python
return (num_pipeline_repeats > 1
        and num_pipeline_microbatches > num_stages * forwarding_delay)
```

**Use case**: When microbatches can't all fit in shift buffer, use circular storage

---

### vmap Setup Methods

#### `get_vmap_func_for_init(self)`

Creates vmap function used during parameter initialization only.

**Purpose**: Initialize layer parameters with proper stage sharding

**Features**:
- vmaps over `body_instance` (the layers)
- Variable axes: `params`, `_overwrite_with_gradient`
- Split RNGs: params (if initializing), dropout (if enabled)
- Metadata: partition name "layers", x_times = num_stages

**Returns**: `nn.vmap` function with stage vmapping

---

#### `get_main_vmap_func_for_iterations(self)`

Creates vmap function for main training iterations.

**Purpose**: Execute all stages in parallel for each iteration

**Features**:
- vmaps over `body_instance` and `weights`
- Variables: params sharded over stage dimension
- Allows dropout RNG splitting per iteration
- Metadata: partition name "layers", x_times = num_stages

**Returns**: `nn.vmap` function ready for use in iterations

---

### Sharding Methods

#### `get_weight_sharding(self, *init_args)`

Returns partition specifications for all pipeline weights.

**Process**:
1. Initialize module with dummy inputs
2. Extract `LogicallyPartitioned` specifications from weights
3. Return partition spec tree for "params" subtree

**Use case**: Passing to distributed checkpointing/loading systems

---

#### `get_physical_spec_no_fsdp(self, full_logical)`

Converts logical partition specs to physical specs, removing FSDP sharding.

**Purpose**: Get physical sharding without fully-sharded data parallel axes

**Logic**:
- Removes "fsdp" and "fsdp_transpose" from all partition specs
- Converts logical specs to mesh-aligned physical specs

**Returns**: Physical partition spec with FSDP removed

---

#### `all_gather_over_fsdp(self, sharding_info)`

Applies all-gather constraint across FSDP dimension.

**Purpose**: Gather sharded weights across FSDP devices before pipeline

**Method**:
1. Get physical spec without FSDP
2. Apply sharding constraint to layers.variables

---

### Main Forward Pass Method

#### `__call__(self, inputs, segment_ids, positions, deterministic, model_mode=MODEL_MODE_TRAIN, partition_spec=None)`

Main entry point for pipeline execution.

**Input shapes**:
- `inputs`: [global_batch, sequence, embed]
- `segment_ids`: [global_batch, sequence]
- `positions`: [global_batch, sequence]

**Processing steps**:

1. **Reshape inputs into microbatches**:
   ```python
   inputs → [num_microbatches, pipeline_microbatch_size, sequence, embed]
   ```

2. **Initialize loop state**:
   ```python
   loop_state = init_states(inputs)
   ```

3. **Calculate iteration count**:
   ```
   real_iterations = num_microbatches * num_repeats
   bubble_iterations = forwarding_delay * (num_stages - 1)
   total_iterations = real_iterations + bubble_iterations
   ```

4. **Handle initialization (only first call)**:
   - Use `get_vmap_func_for_init()` to initialize parameters
   - For circular pipelines, wrap with repeat vmap
   - Return dummy output of correct shape

5. **All-gather weights if configured**:
   ```python
   if pipeline_fsdp_ag_once:
       all_pipeline_weights = all_gather_over_fsdp(...)
   else:
       all_pipeline_weights = layers.variables
   ```

6. **Run iterations** (either scanned or looped):
   - Scanned (if `scan_pipeline_iterations=True`):
     - Use `nn.scan` for all iterations
     - More JAX-friendly, better compiler optimizations
   - Looped (if `scan_pipeline_iterations=False`):
     - Explicit Python loop
     - Better for debugging

7. **Apply rematerialization** (if configured):
   ```python
   if set_remat_policy_on_pipeline_iterations:
       run_iteration_scannable = nn.remat(...)
   ```

8. **Permute and reshape output**:
   ```python
   final_output = permute_output_micro_per_stage_dim(loop_state["state_io"])
   final_output → [global_batch, sequence, embed]
   ```

**Return**: [global_batch, sequence, embed] tensor

---

## Advanced Features

### Circular Pipeline Support

Circular pipelines allow multiple passes through the same weighted layers, useful for:
- Multi-turn training
- Iterative refinement
- Repeat-based loss computation

**Configuration**:
```yaml
num_pipeline_repeats: 3  # 3 passes through pipeline
```

**Implementation**:
- Weights shape: [num_repeats, num_stages, ...]
- Each stage gathers its repeat-specific weights at each iteration
- Separate parameter initialization vmap for repeat dimension

---

### Delayed Activation Forwarding

When `pipeline_delay_activation_forwarding=True`:

**Benefit**: Better scheduling by delaying activation forwarding

**Mechanism**:
- Store `prev_outputs` separately from current `output`
- Use `prev_outputs` for next iteration's shift buffer
- Allows for better compute/communication overlap

**Effect**:
- Increases `forwarding_delay` from 1 to 2
- Doubles pipeline bubble: `2 * (num_stages - 1)`

---

### Rematerialization (Gradient Checkpointing)

**Purpose**: Trade compute for memory during backprop

**Policy**:
- Saves: `"iteration_input"` and `"decoder_layer_input"` checkpoints
- Recomputes: Other activations during backward pass

**Benefits**:
- Reduced peak memory during backprop
- Marginal compute overhead

---

### Multi-Repeat Weight Management

For circular pipelines:

1. **Initialization**: Weights created with shape [num_repeats, num_stages, ...]
2. **Per-iteration gathering**: Each stage gathers its repeat's weights
3. **vmap structure**:
   - Outer vmap: over repeats (initialization only)
   - Inner vmap: over stages (every iteration)

---

## Data Flow Diagram

### Single Iteration Example (3 stages, 4 microbatches)

```
Iteration 0:  MB0 → [ ] [ ] [ ]     Stage 0 processes MB0
              MB1 → [ ] [ ] [ ]
              MB2 → [ ] [ ] [ ]
              MB3 → [ ] [ ] [ ]

Iteration 1:  MB1 → [0] [ ] [ ]     Stage 0→MB1, Stage 1→MB0
              MB2 → [0] [ ] [ ]
              MB3 → [0] [ ] [ ]
              MB0↻ → [ ] [0] [ ]

Iteration 2:  MB2 → [1] [0] [ ]     Stage 0→MB2, Stage 1→MB1, Stage 2→MB0
              MB3 → [1] [0] [ ]
              MB0↻ → [1] [0] [ ]
              MB1↻ → [ ] [1] [0]

Iteration 3:  MB3 → [2] [1] [0]     All stages busy
              MB0↻ → [2] [1] [0]
              MB1↻ → [2] [1] [0]
              MB2↻ → [ ] [2] [1]

... and so on until all microbatches complete all repeats
```

---

## Configuration Examples

### Basic Pipeline (3 stages, single pass)

```yaml
ici_pipeline_parallelism: 3
dcn_pipeline_parallelism: 1
num_pipeline_microbatches: 12
num_pipeline_repeats: 1
micro_batch_size_to_train_on: 256
max_target_length: 4096
emb_dim: 4096
```

**Result**:
- 3 pipeline stages
- 12 microbatches → 4 microbatches per stage
- No pipeline bubbling in final iterations

### Circular Pipeline (2 stages, 3 repeats)

```yaml
ici_pipeline_parallelism: 2
dcn_pipeline_parallelism: 1
num_pipeline_microbatches: 8
num_pipeline_repeats: 3
num_pipeline_repeats: 3
pipeline_delay_activation_forwarding: true
micro_batch_size_to_train_on: 512
```

**Result**:
- 2 stages processing in circular fashion
- Each microbatch flows through 3 times
- Delayed forwarding reduces bubble

### Large-Scale Pipeline (Multi-chip)

```yaml
ici_pipeline_parallelism: 8    # Within-chip stages
dcn_pipeline_parallelism: 4    # Between-chip stages
num_pipeline_microbatches: 64
num_pipeline_repeats: 1
pipeline_fsdp_ag_once: true    # Gather weights before loop
scan_pipeline_iterations: true  # Use scan for efficiency
```

**Result**:
- 32 total stages (8 ICI × 4 DCN)
- Highly parallelized across TPU pod
- Scanned iterations for compiler optimization

---

## Performance Considerations

### Memory Usage

**Per-Stage Memory**:
- `state_io`: O(num_microbatches × batch_size × seq × embed)
- `shift`: O(batch_size × seq × embed)
- `circ_storage`: O(num_microbatches × batch_size × seq × embed) if needed
- Layer weights: O(layer_size / num_stages)

**Total**: Reduced by factor of `num_stages` compared to non-pipelined

### Throughput

**Pipeline Bubble**:
- Idle iterations: `forwarding_delay * (num_stages - 1)`
- Efficiency: `(microbatches × repeats) / (microbatches × repeats + bubble_iterations)`
- Improves with larger `num_pipeline_microbatches`

**Optimal Settings**:
- `num_pipeline_microbatches ≥ 4 × num_stages` (minimize bubble)
- `num_pipeline_repeats = 1` (unless needed)
- Use scan if available for better compilation

### Computation Overlap

**Benefits of pipelining**:
- Stage 0 fetches next microbatch while Stage 1 computes
- Allows overlapping communication and computation
- Reduces per-device memory requirements

---

## Error Handling and Edge Cases

### When to use circular storage

```python
use_circ_storage = (
    num_pipeline_repeats > 1
    and num_pipeline_microbatches > num_stages * forwarding_delay
)
```

If not used:
- Shift buffer directly feeds back to stage 0
- Only works when microbatches fit in shift buffer
- Circular pipelines with small batch count may fail

### Microbatch divisibility

The module assumes:
- `micro_batch_size_to_train_on % num_pipeline_microbatches == 0`
- Microbatches evenly divide batch size

### Repeat weight handling

For circular pipelines:
- Weights must be initialized with repeat dimension
- Each stage gathers appropriate repeat during iteration
- Incompatible with some optimizer states

---

## Integration with MaxText

### Usage in Training Loop

```python
from MaxText.layers.pipeline import Pipeline

# In model definition
self.pipeline = Pipeline(
    config=config,
    layers=decoder_layers,
    mesh=mesh,
    remat_policy=remat_policy
)

# In forward pass
output = self.pipeline(
    inputs=inputs,
    segment_ids=segment_ids,
    positions=positions,
    deterministic=is_eval,
    model_mode=mode,
    partition_spec=weight_partition_spec
)
```

### Configuration Integration

```yaml
# In MaxText config
pipeline:
  ici_pipeline_parallelism: 8
  dcn_pipeline_parallelism: 1
  num_pipeline_microbatches: 16
  num_pipeline_repeats: 1
  pipeline_delay_activation_forwarding: false
  pipeline_fsdp_ag_once: true
  scan_pipeline_iterations: true
  set_remat_policy_on_pipeline_iterations: true
```

---

## Testing and Debugging

### Key test scenarios

1. **Shape correctness**: Verify output shape matches input batch shape
2. **Gradient flow**: Ensure gradients backprop through pipeline
3. **Circular pipelines**: Test with multiple repeats
4. **Large pipelines**: Verify with many stages and microbatches
5. **Rematerialization**: Check memory usage with remat policies

### Debugging tips

- Use `loop_iteration` to trace which iteration is problematic
- Check `state_io` shape for buffer overflow issues
- Verify `get_microbatch_and_repeat_ids()` outputs for weight selection
- Enable JAX tracing for sharding constraint violations

---

## Known Limitations and Future Work

### Current Limitations

1. **Fixed stage count**: Cannot dynamically change number of stages
2. **Synchronous execution**: All stages synchronize at iteration boundaries
3. **Bubble overhead**: Non-negligible for small numbers of microbatches
4. **Weight sharding complexity**: Circular pipelines increase complexity

### Potential Improvements (noted in comments)

- **Memory optimization** (b/347603101): Reduce circ_storage by sharding dummy stages differently
- **Asynchronous communication**: Overlap stage-to-stage communication with computation
- **Dynamic load balancing**: Adjust microbatch scheduling based on stage compute time
- **Heterogeneous stages**: Support stages with different layer counts

---

## Related Modules and Files

### Dependencies
- `MaxText.common_types`: Config, MODEL_MODE_TRAIN, EP_AS_CONTEXT
- `MaxText.sharding`: all_gather_over_fsdp function
- `MaxText.layers.models`: Decoder layers executed in pipeline
- JAX: Core computation and sharding
- Flax: Module system, transformations

### Dependents
- `MaxText.layers.models.TransformerLM`: Uses Pipeline when configured
- `MaxText.train`: Orchestrates training with pipelined models
- Distributed training infrastructure

### Related files
- `layers/decoder.py`: Decoder layers that Pipeline executes
- `sharding.py`: Sharding utilities used in pipeline
- `input_pipeline/`: Data loading for pipelined training

---

## References and Further Reading

### JAX Concepts Used

- **vmap**: Auto-vectorization over dimensions
- **pmap/shard_map**: Parallel mapping for distributed execution
- **with_sharding_constraint**: Enforce distributed array sharding
- **dynamic_slice**: Dynamically indexed slicing
- **scan**: Loop abstraction with carry variables
- **remat**: Gradient checkpointing for memory efficiency
- **lax.cond/where**: Conditional computation

### Flax Concepts Used

- **nn.Module**: Base class for layers
- **nn.compact**: Function-style module definition
- **LogicallyPartitioned**: Logical sharding specification
- **nn.scan/nn.vmap**: Flax-integrated transformations
- **variable_axes**: Per-variable partitioning in transforms

### Pipeline Parallelism References

- GPipe (Huang et al., 2018): Original gradient checkpointing
- PipeDream (Narayanan et al., 2019): Pipeline scheduling optimization
- Interleaved Pipeline Parallelism (Narayanan et al., 2021): Circular pipelines
- ZB-Stage (Karakus et al., 2021): Zero-bubble pipeline scheduling

---

## Summary

The Pipeline module is a sophisticated implementation of pipeline parallelism for MaxText, enabling efficient distributed training of large models by:

1. **Spatial partitioning**: Dividing model into stages across devices
2. **Temporal scheduling**: Flowing microbatches through stages in sequence
3. **Buffer management**: Smart circular and linear buffering strategies
4. **Memory efficiency**: Enabling training models that wouldn't fit on single device
5. **Flexible configuration**: Supporting various parallelism modes and options

Key strength is its integration with JAX's compilation and automatic differentiation, allowing the compiler to optimize the pipelined execution while maintaining clean, readable code.