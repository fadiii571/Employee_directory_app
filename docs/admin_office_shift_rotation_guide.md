# Admin Office Shift Rotation System - Complete Guide

## 🎯 **Overview**

Your Admin Office now has a **shift rotation system** for managing 2 employees with alternating shifts. When one employee is present, the other is absent, ensuring continuous coverage while managing workload.

## 📋 **System Features**

### **Core Functionality:**
- ✅ **Alternating Shifts**: 2 employees work on alternating days
- ✅ **4PM-4PM Schedule**: Both follow standard 4PM-4PM shift with 6PM extended checkout
- ✅ **Automatic Rotation**: System tracks who should work each day
- ✅ **Schedule Preview**: View upcoming 14-day rotation schedule
- ✅ **Flexible Management**: Enable/disable rotation, switch order

### **Business Benefits:**
- ✅ **Workload Distribution**: Prevents employee burnout
- ✅ **Continuous Coverage**: Always one employee available
- ✅ **Fair Scheduling**: Equal work distribution
- ✅ **Easy Management**: Admin can control rotation easily

## 🔧 **How It Works**

### **Rotation Logic:**
```
Day 1: Employee A works (Employee B absent)
Day 2: Employee B works (Employee A absent)
Day 3: Employee A works (Employee B absent)
Day 4: Employee B works (Employee A absent)
... and so on
```

### **Shift Details:**
- **Work Hours**: 4:00 PM - 4:00 PM next day (24-hour shift)
- **Extended Checkout**: Until 6:00 PM next day (26-hour maximum)
- **Storage Logic**: Same 4PM-4PM shift date storage as other sections
- **Attendance Tracking**: Normal QR check-in/check-out process

## 📱 **Using the System**

### **1. Setup Rotation (Admin)**

#### **Access the Screen:**
1. Open main menu (hamburger icon)
2. Select "Admin Office Rotation"
3. You'll see the rotation management screen

#### **Configure New Rotation:**
1. **Select Employees**: Choose 2 Admin Office employees from dropdowns
2. **Set Start Date**: Pick when rotation begins
3. **Choose Order**: Select which employee starts first
4. **Save**: Click "Setup Rotation" to activate

#### **Example Setup:**
```
Employee 1: John Smith
Employee 2: Jane Doe
Start Date: January 15, 2024
John starts first: ✓ (checked)

Result:
- Jan 15: John works
- Jan 16: Jane works
- Jan 17: John works
- Jan 18: Jane works
```

### **2. Managing Active Rotation**

#### **Current Status Card:**
- Shows active/inactive status
- Displays employee names and start date
- Shows current rotation order

#### **Control Options:**
- **Enable/Disable**: Turn rotation on/off
- **Switch Order**: Change which employee goes first
- **View Schedule**: See next 14 days preview

### **3. Daily Operations**

#### **For Employees:**
- **Check Schedule**: Admin can tell them their assigned days
- **Normal Attendance**: Use regular QR check-in/check-out
- **Same Rules**: 4PM-4PM shift with 6PM extended checkout

#### **For Admin:**
- **Monitor Attendance**: Check if scheduled employee is present
- **Adjust if Needed**: Can disable rotation for emergencies
- **View Reports**: Attendance history shows actual vs scheduled

## 📊 **Integration with Existing Systems**

### **Attendance Tracking:**
- ✅ **Same QR Process**: No changes to check-in/check-out
- ✅ **Same Storage**: Uses existing 4PM-4PM shift logic
- ✅ **Same Extended Checkout**: 6PM rule still applies
- ✅ **Same History**: Appears in attendance history normally

### **KPI Calculations:**
- ✅ **Individual KPIs**: Each employee gets separate metrics
- ✅ **Section KPIs**: Admin Office section shows combined data
- ✅ **Punctuality**: Based on 4PM check-in time
- ✅ **Attendance Rate**: Calculated per employee's scheduled days

### **Payroll Integration:**
- ✅ **Individual Payroll**: Each employee paid for their worked days
- ✅ **Absent Day Handling**: Only deducted for scheduled days missed
- ✅ **Same Calculation**: Uses existing 30-day payroll logic
- ✅ **Paid Leave**: Can still mark paid leave for scheduled days

## 🎯 **Example Scenarios**

### **Scenario 1: Normal Rotation**
```
Setup:
- Employee A: John (starts first)
- Employee B: Jane
- Start: January 15, 2024

Schedule:
Jan 15 (Mon): John works 4PM-4PM (can extend to 6PM Jan 16)
Jan 16 (Tue): Jane works 4PM-4PM (can extend to 6PM Jan 17)
Jan 17 (Wed): John works 4PM-4PM (can extend to 6PM Jan 18)
Jan 18 (Thu): Jane works 4PM-4PM (can extend to 6PM Jan 19)
```

### **Scenario 2: Employee Absence**
```
Scheduled: John should work January 15
Reality: John doesn't show up

System Response:
- Attendance: Marked as absent for John
- KPI: Affects John's attendance rate
- Payroll: John loses pay for January 15
- Coverage: Admin can manually assign Jane or disable rotation
```

### **Scenario 3: Emergency Coverage**
```
Situation: Jane is sick for 3 days
Admin Action:
1. Disable rotation temporarily
2. John works all days during Jane's absence
3. Re-enable rotation when Jane returns
4. Mark Jane's sick days as paid leave if needed
```

## 🔧 **Technical Implementation**

### **Database Structure:**
```
shift_rotations/
└── Admin office/
    ├── employee1Id: "john_123"
    ├── employee1Name: "John Smith"
    ├── employee2Id: "jane_456"
    ├── employee2Name: "Jane Doe"
    ├── startDate: "2024-01-15"
    ├── employee1StartsFirst: true
    ├── isActive: true
    ├── createdAt: Timestamp
    └── lastUpdated: Timestamp
```

### **Rotation Calculation:**
```dart
// Calculate which employee should work
final daysSinceStart = date.difference(startDate).inDays;
final isEvenDay = daysSinceStart % 2 == 0;

if (employee1StartsFirst) {
  return isEvenDay ? employee1Id : employee2Id;
} else {
  return isEvenDay ? employee2Id : employee1Id;
}
```

### **API Methods:**
```dart
// Setup rotation
ShiftRotationService.setupShiftRotation(...)

// Get scheduled employee
ShiftRotationService.getScheduledEmployee(date)

// Check if employee is scheduled
ShiftRotationService.isEmployeeScheduled(employeeId, date)

// Get rotation schedule
ShiftRotationService.getRotationSchedule(startDate, endDate)

// Update rotation
ShiftRotationService.updateRotation(...)
```

## 📈 **Benefits for Your Business**

### **Employee Wellbeing:**
- **Prevents Burnout**: No single employee works every day
- **Work-Life Balance**: Predictable schedule with days off
- **Fair Distribution**: Equal workload between employees
- **Flexibility**: Can adjust rotation as needed

### **Operational Efficiency:**
- **Continuous Coverage**: Always one employee available
- **Reduced Overtime**: Prevents excessive hours
- **Better Planning**: Predictable staffing schedule
- **Cost Control**: Manages labor costs effectively

### **Management Benefits:**
- **Easy Scheduling**: Automated rotation system
- **Clear Accountability**: Know who should be working
- **Flexible Control**: Can override when needed
- **Integrated Tracking**: Works with existing systems

## 🚀 **Getting Started**

### **Step 1: Identify Employees**
- Ensure you have exactly 2 employees in Admin Office section
- Both should be trained on 4PM-4PM shift procedures
- Both should understand extended checkout rules

### **Step 2: Setup Rotation**
1. Go to main menu → "Admin Office Rotation"
2. Select your 2 Admin Office employees
3. Choose start date (recommend starting on Monday)
4. Decide which employee starts first
5. Click "Setup Rotation"

### **Step 3: Monitor and Adjust**
- Check schedule preview to verify rotation
- Monitor attendance to ensure compliance
- Adjust rotation order if needed
- Use enable/disable for special situations

### **Step 4: Train Staff**
- Explain rotation schedule to employees
- Ensure they understand their assigned days
- Clarify that attendance tracking remains the same
- Provide contact for schedule questions

## 🎉 **Summary**

Your Admin Office shift rotation system provides:

- ✅ **Automated alternating shifts** for 2 employees
- ✅ **Same 4PM-4PM schedule** with 6PM extended checkout
- ✅ **Integrated with existing** attendance, KPI, and payroll systems
- ✅ **Flexible management** with enable/disable and order switching
- ✅ **Clear scheduling** with 14-day preview
- ✅ **Fair workload distribution** preventing employee burnout

**Your Admin Office now has a professional shift rotation system that ensures continuous coverage while maintaining employee wellbeing!** 🎯
