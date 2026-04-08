# QR Scanner App - Reusable Widgets Documentation

This document describes the reusable widgets created for improved scalability and maintainability of the QR Scanner application.

## Widget Architecture

All reusable widgets are located in `lib/features/qrscan/presentation/widgets/` and can be imported individually or as a group using the barrel file `widgets.dart`.

## Available Widgets

### 1. DetailRowWidget
**File:** `detail_row_widget.dart`

A reusable widget for displaying key-value pairs with consistent styling across the app.

**Features:**
- Customizable label and value colors
- Optional icon display
- Selectable text support
- Flexible padding and styling

**Usage:**
```dart
DetailRowWidget(
  label: 'Scanned At:',
  value: '2024-09-19 15:30:45',
  icon: Icons.access_time,
  isSelectable: true,
)
```

**Props:**
- `label` (String, required): The label text
- `value` (String, required): The value text
- `isSelectable` (bool): Whether text is selectable
- `icon` (IconData?): Optional icon
- `labelColor`, `valueColor` (Color?): Custom colors
- `labelStyle`, `valueStyle` (TextStyle?): Custom text styles
- `padding` (EdgeInsetsGeometry?): Custom padding

### 2. ScanCardWidget
**File:** `scan_card_widget.dart`

A reusable card widget for displaying scan information consistently across different pages.

**Features:**
- Automatic "today" highlighting
- Consistent spacing and styling
- Flexible date formatting
- Tap handling support

**Usage:**
```dart
ScanCardWidget(
  scan: scanObject,
  onTap: () => handleTap(scan),
  showFullDate: true,
)
```

**Props:**
- `scan` (Scan, required): The scan object to display
- `onTap` (VoidCallback?): Tap handler
- `showFullDate` (bool): Whether to show full date format
- `margin` (EdgeInsetsGeometry?): Custom margin

### 3. StatusContainerWidget
**File:** `status_container_widget.dart`

A versatile container widget for different application states with consistent styling.

**Features:**
- Multiple status types (processing, success, welcome, error, warning)
- Automatic color schemes per type
- Loading indicator support
- Custom actions support

**Usage:**
```dart
StatusContainerWidget(
  type: StatusType.processing,
  title: 'Processing scan...',
  subtitle: 'Getting location and saving data',
  showLoadingIndicator: true,
)
```

**Available Types:**
- `StatusType.processing`: Orange/yellow theme with loading
- `StatusType.success`: Green theme for successful operations
- `StatusType.welcome`: UDSM blue gradient for welcome screens
- `StatusType.error`: Red theme for errors
- `StatusType.warning`: Orange theme for warnings

**Props:**
- `type` (StatusType, required): The status type
- `title` (String, required): Main title
- `subtitle` (String, required): Subtitle text
- `icon` (IconData?): Custom icon
- `showLoadingIndicator` (bool): Show loading spinner
- `onTap` (VoidCallback?): Tap handler
- `additionalActions` (List<Widget>?): Extra action widgets

### 4. ScanDetailsDialog
**File:** `scan_details_dialog.dart`

A reusable dialog for displaying detailed scan information.

**Features:**
- Consistent dialog styling
- Integrated QR data display
- Automatic detail formatting
- Static show method for easy usage

**Usage:**
```dart
// Static method (recommended)
ScanDetailsDialog.show(
  context: context,
  scan: scanObject,
  title: 'Custom Title', // optional
);

// Or as widget
ScanDetailsDialog(
  scan: scanObject,
  additionalActions: [
    TextButton(
      onPressed: () => shareData(),
      child: Text('Share'),
    ),
  ],
)
```

**Props:**
- `scan` (Scan, required): The scan object to display
- `title` (String?): Custom dialog title
- `additionalActions` (List<Widget>?): Extra action buttons

### 5. EmptyStateWidget
**File:** `empty_state_widget.dart`

A consistent empty state widget for different scenarios throughout the app.

**Features:**
- Multiple predefined empty state types
- Consistent styling across the app
- Customizable icons and text
- Optional action buttons

**Usage:**
```dart
EmptyStateWidget(
  type: EmptyStateType.noScans,
  action: ElevatedButton(
    onPressed: () => startScanning(),
    child: Text('Start Scanning'),
  ),
)
```

**Available Types:**
- `EmptyStateType.noScans`: When no scans exist
- `EmptyStateType.noSearchResults`: When search returns no results
- `EmptyStateType.noHistory`: When history is empty
- `EmptyStateType.general`: Generic empty state

**Props:**
- `type` (EmptyStateType, required): The empty state type
- `title` (String?): Custom title (overrides default)
- `subtitle` (String?): Custom subtitle (overrides default)
- `icon` (IconData?): Custom icon (overrides default)
- `action` (Widget?): Optional action button
- `padding` (EdgeInsetsGeometry?): Custom padding

### 6. QRDataDisplay
**File:** `qr_data_display.dart`

The interactive QR data display widget with smart content detection and actions.

**Features:**
- Automatic content type detection
- Interactive links, emails, phone numbers
- Image preview for image URLs
- Consistent theming

**Usage:**
```dart
QRDataDisplay(
  qrData: qrCodeContent,
  isCompact: false, // optional
)
```

**Props:**
- `qrData` (String, required): The QR code data
- `isCompact` (bool): Whether to show compact version

## Benefits of Reusable Widgets

### 1. **Consistency**
- Uniform styling across all pages
- Consistent behavior and interactions
- Centralized theme compliance

### 2. **Maintainability**
- Single source of truth for UI components
- Easy to update styles globally
- Reduced code duplication

### 3. **Scalability**
- Easy to add new features to existing components
- Reusable across different parts of the app
- Faster development of new features

### 4. **Testing**
- Individual widget testing possible
- Isolated component behavior
- Better test coverage

## Usage Patterns

### Import Styles

**Individual Imports:**
```dart
import '../widgets/scan_card_widget.dart';
import '../widgets/empty_state_widget.dart';
```

**Barrel Import (Recommended):**
```dart
import '../widgets/widgets.dart';
```

### Common Patterns

**Status Flow:**
```dart
// Loading state
StatusContainerWidget(
  type: StatusType.processing,
  title: 'Loading...',
  subtitle: 'Please wait',
  showLoadingIndicator: true,
)

// Success state
StatusContainerWidget(
  type: StatusType.success,
  title: 'Success!',
  subtitle: 'Operation completed',
)
```

**List with Empty State:**
```dart
items.isEmpty
  ? EmptyStateWidget(type: EmptyStateType.noScans)
  : ListView.builder(
      itemBuilder: (context, index) => ScanCardWidget(
        scan: items[index],
        onTap: () => showDetails(items[index]),
      ),
    )
```

## Migration Guide

The following components have been replaced with reusable widgets:

1. **Custom ListTiles** → `ScanCardWidget`
2. **Custom Dialogs** → `ScanDetailsDialog`
3. **Status Containers** → `StatusContainerWidget`
4. **Empty State Columns** → `EmptyStateWidget`
5. **Detail Rows** → `DetailRowWidget`

### Before:
```dart
Container(
  // Custom styling
  child: Column(
    children: [
      // Custom empty state UI
    ],
  ),
)
```

### After:
```dart
EmptyStateWidget(
  type: EmptyStateType.noScans,
)
```

## UDSM Theme Integration

All widgets are fully integrated with the UDSM theme system:

- **Primary Colors**: UDSM Blue (#1E3A8A) and Gold (#F59E0B)
- **Status Colors**: Success Green, Warning Orange, Error Red
- **Typography**: Consistent with Material 3 design system
- **Spacing**: Standardized padding and margins

## Future Enhancements

Potential improvements for the reusable widget system:

1. **Animation Support**: Add smooth transitions between states
2. **Accessibility**: Enhanced screen reader support
3. **Localization**: Multi-language support
4. **Theming**: Support for custom theme variations
5. **Responsive Design**: Better tablet and desktop layouts

## Performance Considerations

- All widgets are stateless where possible for better performance
- Minimal rebuilds through proper state management
- Efficient use of Flutter's widget tree
- Cached decorations and styles where appropriate