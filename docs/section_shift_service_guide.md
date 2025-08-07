# Section Shift Service - Code Documentation

## Overview
The `SectionShiftService` manages section-specific shift configurations for KPI calculations. It handles check-in times, grace periods, and punctuality logic for different work sections.

## Code Organization

### 1. CONSTANTS & CONFIGURATION
- **Firestore instance**: Database connection
- **Cache settings**: 5-minute cache validity
- **Default configurations**: Fallback shift settings for all sections

### 2. DEFAULT CONFIGURATIONS
```dart
static final Map<String, SectionShift> _defaultShifts = {
  'Fancy': SectionShift(checkInTime: '05:30', gracePeriodMinutes: 10),
  'KK': SectionShift(checkInTime: '05:30', gracePeriodMinutes: 10),
  'Anchor': SectionShift(checkInTime: '09:00', gracePeriodMinutes: 0),
  // ... other sections
};
```

### 3. PUBLIC API METHODS
- **`getSectionShift(String sectionName)`**: Main method for getting section configuration
- **`getSectionShiftSync(String sectionName)`**: Synchronous version for backward compatibility
- **`getAllSectionShifts()`**: Get all section configurations
- **`initialize()`**: Initialize service and populate cache

### 4. HELPER METHODS
- **`_isHardcodedSection()`**: Check if section is fully hardcoded (Admin Office only)
- **`_getHardcodedShift()`**: Return hardcoded configuration
- **`_ensureCacheIsValid()`**: Check and refresh cache if needed
- **`_getConfigurableShift()`**: Get configurable section from cache

### 5. CACHE MANAGEMENT
- **`_refreshCache()`**: Load data from Firestore into cache
- **`getAllSectionShifts()`**: Get all shifts with cache management
- **`getAllSectionShiftsSync()`**: Synchronous version using cache

### 6. DATA PERSISTENCE METHODS
- **`saveSectionShift()`**: Save single shift to Firestore
- **`loadSectionShiftsFromFirestore()`**: Load all shifts from Firestore
- **`saveDefaultShiftsToFirestore()`**: Initialize Firestore with defaults
- **`updateSectionShift()`**: Update shift configuration (main admin method)

### 7. PUNCTUALITY CALCULATION METHODS
- **`isEmployeeLate()`**: Check if employee is late based on section rules
- **`isEmployeeEarly()`**: Check if employee arrived early (15+ min before)
- **`isEmployeeOnTime()`**: Check if employee is on time (not late, not early)

### 8. UTILITY METHODS
- **`getShiftDurationHours()`**: Return standard 8-hour duration for display
- **`getShiftTimeDisplay()`**: Format shift time for UI display

### 9. PRIVATE HELPER METHODS
- **`_parseTime()`**: Parse time string (HH:mm) into DateTime object

### 10. DEBUG METHODS (DEVELOPMENT ONLY)
- **`debugJointSectionConfig()`**: Test function to verify configurations

## Section Types

### Hardcoded Sections
- **Admin Office**: 4PM check-in, fully managed in markQRAttendance
- Cannot be configured through admin interface

### Configurable Sections
- **All other sections**: Admin can set check-in time and grace period
- Includes Fancy, KK, Anchor, Joint, etc.
- Changes take effect immediately in KPI calculations

### Extended Checkout Sections
- **Fancy & KK**: Configurable check-in, but 6PM checkout in markQRAttendance
- Best of both worlds: flexible check-in, preserved attendance logic

## Data Flow

1. **Admin configures section** → `updateSectionShift()` → Firestore
2. **Cache invalidation** → `_refreshCache()` → Updated cache
3. **KPI calculation** → `getSectionShift()` → Current configuration
4. **Punctuality check** → `isEmployeeLate()` → Based on section rules

## Performance Optimizations

- **Caching**: 5-minute cache reduces Firestore calls
- **Batch operations**: Load all shifts at once
- **Fallback defaults**: Always available even if Firestore fails
- **Lazy loading**: Cache refreshes only when needed

## Usage Examples

```dart
// Get section configuration
final shift = await SectionShiftService.getSectionShift('Joint');

// Check punctuality
final isLate = SectionShiftService.isEmployeeLate('09:15', shift);

// Update configuration (admin)
await SectionShiftService.updateSectionShift(
  sectionName: 'Joint',
  checkInTime: '03:00',
  gracePeriodMinutes: 5,
);
```

## Benefits of Optimization

1. **Clear organization**: Logical grouping of related methods
2. **Better documentation**: Each section and method is well-documented
3. **Improved maintainability**: Easy to find and modify specific functionality
4. **Performance**: Efficient caching and data management
5. **Flexibility**: Supports both hardcoded and configurable sections
6. **Reliability**: Fallback mechanisms for error handling
