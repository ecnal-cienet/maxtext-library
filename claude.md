# MaxText Library Documentation Generator

A comprehensive guide for generating and maintaining module documentation for the MaxText codebase.

---

## Overview

This repository uses an automated documentation generation system to create comprehensive, organized documentation for the MaxText codebase. Documentation is generated on-demand and stored in a mirrored directory structure, making it easy to locate, navigate, and maintain.

**Key Characteristics**:
- **Modular**: Each source file gets corresponding documentation
- **Organized**: Documentation mirrors source directory structure
- **Comprehensive**: Includes classes, functions, usage examples, and more
- **Accessible**: Centralized Library directory for easy reference
- **Incremental**: Build documentation piece by piece as needed

---

## Quick Start

### Generating Documentation

To generate documentation for any MaxText module, simply ask:

```
"Generate comprehensive documentation for src/MaxText/layers/pipeline.py"
```

The documentation will be automatically created at:
```
Library/src/MaxText/layers/pipeline.py.md
```

### Batch Documentation Generation

To generate documentation for multiple modules at once:

```
"Generate comprehensive documentation for the following modules:
- src/MaxText/maxengine.py
- src/MaxText/layers/moe.py
- src/MaxText/inference/kvcache.py
"
```

---

## Documentation Structure

### Directory Organization

The `Library/` directory mirrors the source code structure:

```
Library/
└── src/
    └── MaxText/
        ├── maxengine.py.md                    # Inference engine documentation
        ├── train.py.md                        # Training pipeline documentation
        ├── pyconfig.py.md                     # Configuration system documentation
        ├── layers/
        │   ├── models.py.md                   # Core model architecture
        │   ├── pipeline.py.md                 # Pipeline parallelism
        │   ├── attention_op.py.md             # Attention mechanisms
        │   ├── moe.py.md                      # Mixture of Experts
        │   ├── llama*.py.md                   # Llama family models
        │   ├── gemma*.py.md                   # Gemma family models
        │   └── [other layer documentation]
        ├── inference/
        │   ├── offline_engine.py.md
        │   ├── kvcache.py.md
        │   ├── paged_attention*.py.md
        │   └── [other inference documentation]
        ├── input_pipeline/
        │   ├── input_pipeline_interface.py.md
        │   ├── _grain_data_processing.py.md
        │   ├── _tfds_data_processing.py.md
        │   └── [other pipeline documentation]
        └── [other module documentation]
```

### Naming Convention

Documentation files follow the pattern: `<original_filename>.md`

Examples:
| Source File | Documentation File |
|------------|------------------|
| `src/MaxText/layers/pipeline.py` | `Library/src/MaxText/layers/pipeline.py.md` |
| `src/MaxText/maxengine.py` | `Library/src/MaxText/maxengine.py.md` |
| `src/MaxText/train.py` | `Library/src/MaxText/train.py.md` |
| `src/MaxText/inference/kvcache.py` | `Library/src/MaxText/inference/kvcache.py.md` |

---

## Documentation Content Standard

Each generated documentation file includes nine key sections:

### 1. Module Overview
- **Purpose**: One-sentence description of what the module does
- **Key Features**: 3-5 bullet points of main capabilities
- **Integration**: How it connects with other modules

### 2. Architecture
- **Component Structure**: How the module is organized internally
- **Data Flow**: Text diagrams showing information flow
- **Design Patterns**: Architectural patterns used
- **Dependencies**: What other modules it depends on

### 3. Classes & Methods
- **Full Class Signatures**: Including all attributes
- **Method Signatures**: With parameter types and return types
- **Docstrings**: Clear explanations of purpose
- **Access Patterns**: How to instantiate and use
- **State Management**: How class state is managed

### 4. Functions
- **Function Signatures**: Complete with type hints
- **Purpose and Behavior**: What the function does
- **Parameters**: Type, range, and constraints
- **Return Values**: Type and meaning
- **Side Effects**: Any state modifications

### 5. Configuration & Parameters
- **Configuration Options**: All configurable parameters
- **Default Values**: What the defaults are
- **Valid Ranges**: Min/max or allowed values
- **Environment Variables**: Related env vars
- **Examples**: Configuration usage examples

### 6. Usage Examples
- **Basic Usage**: Simple "hello world" example
- **Advanced Patterns**: Complex usage scenarios
- **Integration Patterns**: How to use with other modules
- **Common Pitfalls**: What to avoid
- **Best Practices**: Recommended approaches

### 7. Performance Characteristics
- **Computational Complexity**: Time complexity analysis
- **Memory Usage**: Space complexity and footprint
- **Optimization Opportunities**: Where speedups are possible
- **Bottlenecks**: Known performance bottlenecks
- **Benchmarks**: Any available performance data

### 8. Testing & Verification
- **Related Test Files**: What tests cover this module
- **Test Examples**: Sample test code
- **How to Verify**: Steps to validate functionality
- **Edge Cases**: Boundary conditions and corner cases
- **Known Issues**: Any known limitations

### 9. Related Modules & References
- **Dependencies**: Modules this depends on
- **Dependents**: Modules that depend on this
- **Cross-References**: Related documentation files
- **External Dependencies**: Third-party libraries used
- **Related Concepts**: Conceptual connections

---

## Supported Module Categories

### Core Training
Request documentation for training infrastructure:
- `src/MaxText/train.py` - Main training loop
- `src/MaxText/train_compile.py` - XLA compilation
- `src/MaxText/train_utils.py` - Training utilities
- `src/MaxText/elastic_train.py` - Fault-tolerant training

### Inference Engine
Request documentation for inference components:
- `src/MaxText/maxengine.py` - High-performance inference engine
- `src/MaxText/inference/offline_engine.py` - Batch inference
- `src/MaxText/inference/kvcache.py` - KV-cache management
- `src/MaxText/inference/paged_attention*.py` - Paged attention kernels

### Model Architecture & Layers
Request documentation for model implementations:
- `src/MaxText/layers/models.py` - Core Transformer model
- `src/MaxText/layers/llama*.py` - Llama model variants
- `src/MaxText/layers/gemma*.py` - Gemma model variants
- `src/MaxText/layers/mistral.py` - Mistral implementation
- `src/MaxText/layers/attention_op.py` - Attention mechanisms
- `src/MaxText/layers/moe.py` - Mixture of Experts
- `src/MaxText/layers/pipeline.py` - Pipeline parallelism

### Data Pipeline
Request documentation for data loading:
- `src/MaxText/input_pipeline/input_pipeline_interface.py` - Pipeline interface
- `src/MaxText/input_pipeline/_grain_data_processing.py` - Grain integration
- `src/MaxText/input_pipeline/_tfds_data_processing.py` - TensorFlow Datasets
- `src/MaxText/input_pipeline/_hf_data_processing.py` - Hugging Face datasets
- `src/MaxText/input_pipeline/instruction_data_processing.py` - Instruction tuning

### Configuration System
Request documentation for configuration:
- `src/MaxText/pyconfig.py` - Pydantic-based configuration
- `src/MaxText/pyconfig_deprecated.py` - Legacy configuration

### Utilities & Infrastructure
Request documentation for utility modules:
- `src/MaxText/maxtext_utils.py` - MaxText-specific utilities
- `src/MaxText/max_utils.py` - General JAX/Flax utilities
- `src/MaxText/sharding.py` - Data/model sharding
- `src/MaxText/tokenizer.py` - Tokenization
- `src/MaxText/metric_logger.py` - Metrics logging

### Specialized Features
Request documentation for advanced features:
- `src/MaxText/layers/quantizations.py` - Quantization strategies
- `src/MaxText/vocabulary_tiling.py` - Vocabulary optimization
- `src/MaxText/layerwise_quantization.py` - Per-layer quantization
- `src/MaxText/sequence_packing.py` - Sequence packing
- `src/MaxText/prefill_packing.py` - Prefill optimization
- `src/MaxText/dpo_utils.py` - Direct Preference Optimization
- `src/MaxText/gradient_accumulation.py` - Gradient accumulation

---

## Generation Guidelines

### What Gets Documented

Each documentation file captures:
- ✅ Public APIs and their signatures
- ✅ Class attributes and methods
- ✅ Module-level functions
- ✅ Configuration parameters
- ✅ Integration points with other modules
- ✅ Practical usage examples
- ✅ Performance characteristics
- ✅ Known limitations and edge cases
- ✅ Related test files and testing strategies

### What Gets Analyzed

The generation process analyzes:
- **Code Structure**: Classes, functions, inheritance hierarchy
- **Type Hints**: Parameter and return types
- **Docstrings**: Existing documentation in code
- **Imports**: Dependencies on other modules
- **Configuration**: Parameters and defaults
- **Test Files**: Related unit and integration tests
- **Usage Patterns**: How the module is actually used

### Quality Standards

Generated documentation maintains:
- **Clarity**: Accessible to developers new to the codebase
- **Completeness**: Covers all public APIs
- **Accuracy**: Reflects actual code behavior
- **Organization**: Consistent structure across files
- **Examples**: Practical, runnable code samples
- **Cross-References**: Links to related documentation

---

## Browsing the Library

### Finding Documentation

Once generated, find documentation by:
1. **Direct Path**: Go directly to `Library/src/MaxText/[path]/[module].py.md`
2. **Browse**: Navigate the Library directory structure
3. **Search**: Use text search within individual .md files

Example:
```bash
# View inference engine documentation
cat Library/src/MaxText/maxengine.py.md

# View attention mechanism documentation
cat Library/src/MaxText/layers/attention_op.py.md
```

### Using Documentation

Each documentation file is self-contained and includes:
- **Table of Contents**: Jump to any section
- **Code Examples**: Copy-paste ready
- **Cross-References**: Links to related docs
- **Search-Friendly**: Full text searchable

### Building Understanding

Suggested learning path:
1. **Start**: Read high-level overviews in overview files
2. **Drill Down**: Read specific module documentation
3. **Understand Interactions**: Read related module docs to understand integration
4. **Practice**: Use code examples to understand usage

---

## Common Documentation Requests

### Training Pipeline
```
Generate comprehensive documentation for src/MaxText/train.py
```
Learn about the main training loop, checkpoint management, distributed training setup.

### Inference Engine
```
Generate comprehensive documentation for src/MaxText/maxengine.py
```
Understand how to use MaxText for text generation and serving.

### Model Architecture
```
Generate comprehensive documentation for src/MaxText/layers/models.py
```
Learn the core Transformer implementation and how to extend it.

### Data Loading
```
Generate comprehensive documentation for src/MaxText/input_pipeline/input_pipeline_interface.py
```
Understand how to load and preprocess training data.

### Multiple Modules
```
Generate comprehensive documentation for the following modules:
- src/MaxText/maxengine.py
- src/MaxText/inference/kvcache.py
- src/MaxText/inference/paged_attention.py
```
Understand complete inference subsystem.

---

## Maintaining Documentation

### When to Update Documentation

Generate new or updated documentation:
- **New Module Added**: Generate docs for new source files
- **Major Feature Addition**: Update docs when adding significant capabilities
- **API Changes**: Regenerate when public APIs change
- **Bug Fixes**: Update if documentation had incorrect information
- **Performance Improvements**: Document optimization changes
- **After Git Pull**: When pulling changes from main branch (see Automated Updates section below)

### Version Control

Documentation files are committed to version control:
- Treat docs like source code
- Include in pull requests for major changes
- Review documentation updates along with code changes
- Use commit messages like: "Add documentation for src/MaxText/layers/pipeline.py"

### Automated Documentation Updates with Post-Merge Hook

#### Overview

MaxText includes an automated system that detects when source files change after `git pull` and notifies you if corresponding documentation exists and needs updating. This ensures documentation stays in sync with code changes automatically.

#### How It Works

After you run `git pull origin main` (when there are commits to merge):

1. **Automatic Detection** - A git post-merge hook automatically runs
2. **File Analysis** - The hook identifies which `src/MaxText/` files were changed
3. **Documentation Check** - It checks if `Library/[file].py.md` exists for each changed file
4. **Smart Notification** - If documentation exists, it displays a formatted list with ready-to-use Claude Code commands
5. **Zero Setup** - Everything is pre-configured; no manual setup required

**Important**: The post-merge hook only runs when git performs an actual merge. If your branch is already up to date with `origin/main`, no merge happens and the hook doesn't trigger. See POST_MERGE_HOOK_GUIDE.md for details on when the hook runs and how to test it.

#### Example Workflow

```bash
# You pull changes from main
$ git pull origin main

# Hook automatically runs and displays:
======================================================================
📚 Documentation Update Needed
======================================================================

The following source files have been changed and have corresponding
documentation that may need updating:

  ✓ src/MaxText/layers/attention_op.py
    → Library/src/MaxText/layers/attention_op.py.md

  ✓ src/MaxText/inference/kvcache.py
    → Library/src/MaxText/inference/kvcache.py.md

======================================================================

To update documentation, use Claude Code:

  Generate comprehensive documentation for the following modules:
  - src/MaxText/layers/attention_op.py
  - src/MaxText/inference/kvcache.py

======================================================================

# You copy the command and paste it into Claude Code
# Documentation is automatically regenerated
```

#### Implementation Details

The automation system consists of three components:

**1. Post-Merge Hook** (`.git/hooks/post-merge`)
- Executes automatically after every successful merge or pull
- Non-blocking - never fails the merge operation
- Silently exits if no changes detected

**2. Detection Helper** (`.git/hooks/update-docs-helper.py`)
- Analyzes changed files using git diff
- Identifies Python files in `src/MaxText/` directory
- Checks for corresponding documentation in `Library/`
- Generates user-friendly colored output
- Saves update list to `.git/docs-to-update.txt` for scripting

**3. Manual Trigger Script** (`scripts/update-docs-from-pull.sh`)
- Optional script to manually check for documentation updates
- Useful if you want to check without pulling
- Run with: `./scripts/update-docs-from-pull.sh`

#### Setup Instructions

**No setup required!** The automation is pre-installed. However, if you need to set it up manually:

```bash
# Make hook executable
chmod +x .git/hooks/post-merge
chmod +x .git/hooks/update-docs-helper.py

# Verify setup
ls -l .git/hooks/post-merge
ls -l .git/hooks/update-docs-helper.py
```

#### Advanced Usage

**Disable the hook temporarily**:
```bash
mv .git/hooks/post-merge .git/hooks/post-merge.disabled
# Re-enable later:
mv .git/hooks/post-merge.disabled .git/hooks/post-merge
```

**Manually check for documentation updates**:
```bash
./scripts/update-docs-from-pull.sh
```

**View the list of files needing documentation updates**:
```bash
cat .git/docs-to-update.txt
```

**Use in CI/CD pipeline**:
```bash
python3 .git/hooks/update-docs-helper.py "$PWD"
if [ -f .git/docs-to-update.txt ]; then
    echo "Documentation updates needed:"
    cat .git/docs-to-update.txt
fi
```

#### Best Practices

1. **Act on notifications promptly** - Update documentation soon after pulling changes
2. **Keep docs in sync** - Make it a habit to update docs when code changes
3. **Commit together** - Include documentation updates in the same PR as code changes
4. **Review output** - Generated documentation should be reviewed for accuracy
5. **Verify quality** - Use Claude Code to regenerate if changes are significant

#### Troubleshooting

**Hook not running after pull**:
```bash
# Check if hook is executable
ls -l .git/hooks/post-merge

# Make it executable if needed
chmod +x .git/hooks/post-merge
chmod +x .git/hooks/update-docs-helper.py
```

**No notification after pull**:
- No Python files in `src/MaxText/` were changed, OR
- Changed files don't have corresponding documentation, OR
- Run `python3 .git/hooks/update-docs-helper.py "$(pwd)"` to debug

**Documentation helper script not found**:
- Verify `.git/hooks/update-docs-helper.py` exists
- Run setup commands above if needed

### Organizing Documentation Tasks

To document multiple modules systematically:

```
Priority 1 (Core Training):
- src/MaxText/train.py
- src/MaxText/layers/models.py
- src/MaxText/pyconfig.py

Priority 2 (Inference):
- src/MaxText/maxengine.py
- src/MaxText/inference/kvcache.py
- src/MaxText/inference/offline_engine.py

Priority 3 (Data):
- src/MaxText/input_pipeline/input_pipeline_interface.py
- src/MaxText/input_pipeline/_grain_data_processing.py
- src/MaxText/input_pipeline/_tfds_data_processing.py

Priority 4 (Advanced):
- src/MaxText/layers/moe.py
- src/MaxText/layers/pipeline.py
- src/MaxText/layers/attention_op.py
```

---

## File Structure Reference

### MaxText Source Organization

Main directories to document:
- **src/MaxText/** - Core package (229 Python files)
  - **layers/** - Neural network layers and model architectures
  - **inference/** - Inference engines and utilities
  - **input_pipeline/** - Data loading and preprocessing
  - **sft/** - Supervised fine-tuning modules
  - **rl/** - Reinforcement learning training
  - **utils/** - Utility functions and helpers
  - **integration/** - Third-party framework integrations
  - **experimental/** - Experimental features
  - **configs/** - Configuration files (YAML)
  - **assets/** - Pre-built resources (tokenizers)

### Documentation Organization

Mirrored structure in Library/:
```
Library/src/MaxText/
├── maxengine.py.md
├── train.py.md
├── pyconfig.py.md
├── layers/
│   ├── models.py.md
│   ├── pipeline.py.md
│   ├── attention_op.py.md
│   ├── moe.py.md
│   └── ...
├── inference/
│   ├── offline_engine.py.md
│   ├── kvcache.py.md
│   └── ...
├── input_pipeline/
│   ├── input_pipeline_interface.py.md
│   ├── _grain_data_processing.py.md
│   └── ...
└── ...
```

---

## Tips for Effective Documentation

### Request Specific, Well-Scoped Documentation

**Good**:
```
Generate comprehensive documentation for src/MaxText/layers/attention_op.py
```

**Too Broad**:
```
Document all the layers
```

### Include Related Files in One Request

When documenting interconnected components:
```
Generate comprehensive documentation for:
- src/MaxText/inference/kvcache.py
- src/MaxText/inference/paged_attention.py
- src/MaxText/inference/page_manager.py
```

### Focus on Understanding Integration

Include context about how modules integrate:
```
Generate comprehensive documentation for src/MaxText/layers/moe.py,
including how it integrates with src/MaxText/layers/models.py
```

### Keep Documentation Fresh

Periodically review and update:
- Check if APIs have changed
- Verify examples still work
- Update performance characteristics if optimized
- Add new usage patterns as they emerge

---

## Example Workflows

### Workflow: New Developer Onboarding

1. **Start with Core**: Generate docs for training pipeline
   ```
   Generate comprehensive documentation for src/MaxText/train.py
   ```

2. **Learn Models**: Generate model documentation
   ```
   Generate comprehensive documentation for src/MaxText/layers/models.py
   ```

3. **Understand Data**: Generate data pipeline docs
   ```
   Generate comprehensive documentation for src/MaxText/input_pipeline/input_pipeline_interface.py
   ```

4. **Explore Inference**: Generate inference engine docs
   ```
   Generate comprehensive documentation for src/MaxText/maxengine.py
   ```

5. **Browse Library**: Navigate Library/ to understand full system

### Workflow: Feature Implementation

1. **Understand Existing Code**: Read relevant module documentation
2. **Generate New Module Docs**: If adding new module
3. **Update Related Docs**: If modifying existing modules
4. **Commit Documentation**: Include docs in pull request

### Workflow: System Optimization

1. **Identify Bottleneck Module**: Read current documentation
2. **Deep Dive**: Generate detailed documentation of the module
3. **Analyze Performance**: Review performance section
4. **Implement Optimization**: Make changes
5. **Update Documentation**: Regenerate or update docs with improvements

---

## Notes for Developers

### Understanding the Documentation Generation Process

When you request documentation:
1. Claude analyzes the source file thoroughly
2. Extracts all public APIs, classes, and functions
3. Examines type hints and existing docstrings
4. Identifies relationships with other modules
5. Finds related test files
6. Creates comprehensive documentation with examples
7. Saves to Library/ with mirrored directory structure

### Documentation is Not Code Comments

- Documentation is **external** to code (in Library/ directory)
- Focused on **usage** and **understanding**
- Includes **practical examples** and **integration patterns**
- Not a replacement for inline code comments
- Designed for **onboarding** and **reference**

### Leveraging Documentation

Use generated documentation to:
- **Onboard** new team members quickly
- **Reference** APIs without reading source code
- **Understand** system architecture and interactions
- **Plan** new features and integrations
- **Train** others on the codebase

---

## Quick Reference

### Generation Command Template

```
Generate comprehensive documentation for [path/to/module.py]
```

### Batch Generation Template

```
Generate comprehensive documentation for the following modules:
- [path/to/module1.py]
- [path/to/module2.py]
- [path/to/module3.py]
```

### Location Template

Documentation will be created at:
```
Library/[path/to/module.py].md
```

### Feedback & Updates

To improve or regenerate documentation:
```
Update the documentation for [path/to/module.py] to include [specific improvements]
```

### Automated Documentation Updates

**After pulling changes from main**, the post-merge hook automatically detects changed files and suggests documentation updates.

**Manual trigger**:
```bash
./scripts/update-docs-from-pull.sh
```

**Check what files need updating**:
```bash
cat .git/docs-to-update.txt
```

**View the automation details**:
- See "Automated Documentation Updates with Post-Merge Hook" section above
- See `DOCUMENTATION_AUTO_UPDATE.md` for full automation guide

---

## Summary

This documentation generation system provides:
- **Organization**: All docs in mirrored Library/ structure
- **Consistency**: Standard format across all modules
- **Accessibility**: Easy to find and navigate
- **Completeness**: Covers all public APIs
- **Maintainability**: Can be regenerated and updated as code evolves

Start generating documentation by requesting a specific module. The documentation will be created automatically in the Library/ directory, ready for reference and sharing with the team.
