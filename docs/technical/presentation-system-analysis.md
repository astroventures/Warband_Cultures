# Warband Presentation System Analysis

## Overview

The Warband Module System includes a comprehensive presentation (UI) system that enables custom menus and interfaces. This analysis documents capabilities for the unit creation flow.

## Available UI Elements

### 1. Text Overlays
```python
create_text_overlay, <destination>, <string_id>, [flags]
```
- **Flags**: `tf_center_justify`, `tf_left_align`, `tf_right_align`, `tf_double_space`, `tf_vertical_align_center`, `tf_scrollable`, `tf_single_line`, `tf_with_outline`
- **Dynamic updates**: Use `overlay_set_text` to change text at runtime
- **Supports**: `{reg0}` for numeric values, `{s0}` for string registers

### 2. Buttons
```python
create_button_overlay, <destination>, <string_id>, [flags]
create_game_button_overlay, <destination>, <string_id>  # Styled button
create_in_game_button_overlay, <destination>, <string_id>  # In-game styled
create_image_button_overlay, <destination>, <mesh_id>, <pressed_mesh_id>  # Custom graphics
```
- Fires `ti_on_presentation_event_state_change` when clicked
- Value parameter is typically ignored for buttons

### 3. Sliders
```python
create_slider_overlay, <destination>, <min_value>, <max_value>
```
- **Range**: Set via creation parameters
- **Extended range**: `overlay_set_boundaries` can modify after creation
- **Get/Set**: `overlay_set_val` / read via `store_trigger_param_2`
- **Ideal for**: Stat allocation, percentage values

### 4. Number Boxes
```python
create_number_box_overlay, <destination>, <min_value>, <max_value>
```
- Spin box with +/- buttons
- **Good for**: Precise numeric values (tier selection, quantities)
- Fires state change on value modification

### 5. Combo Boxes (Dropdowns)
```python
create_combo_button_overlay, <destination>
overlay_add_item, <overlay_id>, <string_id>  # Add options
overlay_set_val, <overlay_id>, <index>  # Set selection
```
- Zero-indexed selection
- **Ideal for**: Unit type selection, equipment choices
- Fires state change with new index value

### 6. Check Boxes
```python
create_check_box_overlay, <destination>
```
- Toggle on/off (0 or 1)
- **Good for**: Boolean options

### 7. List Boxes
```python
create_listbox_overlay, <destination>
overlay_add_item, <overlay_id>, <string_id>
```
- Scrollable list selection
- **Useful for**: Equipment browsing, long lists

### 8. Text Input Boxes
```python
create_text_box_overlay, <destination>  # Scrollable multiline
create_simple_text_box_overlay, <destination>  # Single line input
```
- Note: Limited to existing string system

### 9. Progress Bars
```python
create_progress_overlay, <destination>, <min_value>, <max_value>
```
- Visual progress indicator (read-only)

### 10. Mesh Overlays (Icons/Images)
```python
create_mesh_overlay, <destination>, <mesh_id>
create_mesh_overlay_with_item_id, <destination>, <item_id>  # Shows item model
create_mesh_overlay_with_tableau_material, <destination>, <mesh_id>, <tableau_id>, <value>
```
- **Key for unit creation**: Can display armor/weapon previews using `create_mesh_overlay_with_item_id`

## Layout System

### Coordinate System
- Virtual coordinates: typically 1000x750
- Set with: `set_fixed_point_multiplier, 1000`
- Origin: Bottom-left (0,0)
- Use `position_set_x/y` then `overlay_set_position`

### Sizing
```python
position_set_x, pos1, <width_multiplier>
position_set_y, pos1, <height_multiplier>
overlay_set_size, <overlay_id>, pos1
```
- 1000 = 100% of default size
- Common sizes: 600-1500 for text

### Containers (Scrollable Regions)
```python
set_container_overlay, <overlay_id>  # Begin container
# ... add child overlays ...
set_container_overlay, -1  # End container (return to main)

overlay_set_area_size, <container_id>, pos1  # Set scroll area
```

## Event Handling

### Presentation Triggers
| Trigger | Purpose |
|---------|---------|
| `ti_on_presentation_load` | Initial setup, create UI elements |
| `ti_on_presentation_run` | Per-frame updates (param1 = elapsed ms) |
| `ti_on_presentation_event_state_change` | User interaction (param1=overlay, param2=value) |
| `ti_on_presentation_mouse_enter_leave` | Hover effects |
| `ti_on_presentation_mouse_press` | Low-level mouse events |

### State Change Pattern
```python
(ti_on_presentation_event_state_change, [
  (store_trigger_param_1, ":object"),  # Which overlay
  (store_trigger_param_2, ":value"),   # New value
  (try_begin),
    (eq, ":object", "$my_slider"),
    # Handle slider change
  (else_try),
    (eq, ":object", "$my_button"),
    # Handle button click
  (try_end),
]),
```

## Prototype Created

A prototype presentation `wc_unit_creator_prototype` has been added to `module_presentations.py` demonstrating:
- Stat sliders with point tracking
- Unit type combo box
- Tier number box
- Confirm/Cancel/Reset buttons
- Dynamic text updates

## Implications for Unit Creation Flow

### What Works Well
1. **Sliders**: Perfect for stat/skill allocation (1-30 range typical)
2. **Combo boxes**: Good for unit type, equipment categories
3. **Item mesh overlays**: Can preview equipment visually
4. **Containers**: Enable scrollable equipment lists
5. **Number boxes**: Tier selection

### Limitations
1. **No drag-and-drop**: Must use button clicks for equipment assignment
2. **No tree visualization**: Unit upgrade trees need custom mesh-based solution
3. **String system**: Equipment names must be pre-defined or use item name functions
4. **Performance**: Many overlays can cause lag (~50-100 max recommended)

### Recommended UI Patterns for Unit Creation

1. **Page-based navigation**: Split into screens (Stats → Skills → Equipment → Confirm)
2. **Category tabs**: Use buttons to switch equipment categories
3. **Preview panel**: Reserve right side for item mesh preview
4. **Point counters**: Show remaining points prominently
5. **Validation**: Disable confirm until requirements met

## Files Modified

| File | Changes |
|------|---------|
| `module_strings.py` | Added 16 test strings (`wc_test_*`) |
| `module_presentations.py` | Added `wc_unit_creator_prototype` presentation |

## Next Steps

1. Test in-game rendering of prototype
2. Explore tableau materials for troop preview
3. Investigate `create_mesh_overlay_with_item_id` for equipment display
4. Consider performance with multiple equipment options
