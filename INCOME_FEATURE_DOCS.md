# Income Management & Image Preview Implementation

## Overview

This document describes the new Income Management and Image Preview features added to the Expense Tracker app.

---

## 📊 Income Management Feature

### How Income is Tracked

The app tracks income as transactions marked with an `isIncome` flag. Instead of a separate database table, income shares the same expense tracking system with the following characteristics:

- **Storage**: Income is stored in the same Hive box as expenses (`hiveExpenseBox`)
- **Identification**: Transactions are marked with `isIncome = true` field
- **Display**: The Income screen displays only transactions where `isIncome = true`

### Income List Screen

A dedicated **Income** tab in the bottom navigation bar shows all income transactions.

#### Features:

1. **Income Summary Cards**
   - **Current Month Income**: Shows total income for the current month with a progress bar compared to average
   - **Total Income**: Cumulative income since the app started
   - **Entries Count**: Shows entries for current month vs. total entries

2. **Income Records List**
   - Sorted by date (newest first)
   - Displays category, amount, date, notes, and receipt status
   - Tap any entry to edit or view details

#### Income Providers (State Management)

All income data is managed through Riverpod providers in `lib/features/income/presentation/providers/income_providers.dart`:

```dart
// Get all income transactions
incomeListProvider

// Get sorted income (newest first)
sortedIncomeProvider

// Get monthly income sum
monthlyIncomeProvider

// Get income by category breakdown
incomeByCategory

// Get average income over last 6 months
averageMonthlyIncomeProvider

// Get income statistics for dashboard display
incomeStatsProvider
```

### Adding Income

1. Navigate to the **Income** tab
2. Tap the **+ (Add)** floating action button
3. Select **"Income"** in the type toggle (visible at the top)
4. Fill in:
   - **Amount**: Income amount in rupees
   - **Category**: Select source (salary, freelance, bonus, etc.)
   - **Date**: When the income was received
   - **Note**: Optional description (e.g., "Monthly salary January")
   - **Receipt**: Optional attachment for proof/documentation

5. Tap **"Add Transaction"** to save

### Updating Income

1. Go to **Income** tab
2. Tap any income entry to edit
3. Make changes to any field
4. Tap **"Save Changes"**

### Deleting Income

1. Go to **Income** tab
2. Tap an entry to open edit screen
3. Tap the **Delete** icon (trash can) in the top right
4. Confirm deletion

---

## 📸 Image Preview Feature

### Receipt Upload & Storage

Users can attach receipt images to both income and expense transactions for record-keeping.

#### Features:

1. **Image Compression**: Images are automatically compressed to 50% quality and max 800px width to save storage
2. **Persistent Storage**: Receipts are saved to the app's documents directory
3. **Path Tracking**: Receipt paths are stored in the transaction database

### Image Preview Widgets

#### 1. **ImageThumbnailCard** - Interactive Thumbnail

```dart
ImageThumbnailCard(
  imagePath: receiptPath,
  onRemove: () => setState(() => _receiptPath = null),
  onPreview: () => showImagePreview(context, receiptPath),
  height: 120,
  width: double.infinity,
)
```

- Shows compressed preview of the image
- Click to open full-screen preview
- Remove button in top-right corner
- Zoom-in indicator overlay

#### 2. **showImagePreview()** - Full-Screen Dialog

Opens a full-screen image viewer with zoom capabilities:

```dart
showImagePreview(context, imagePath)
```

- Full-screen view
- Pinch-to-zoom support (1x to 3x magnification)
- Interactive pan and zoom using InteractiveViewer
- Close button to return

#### 3. **ReceiptUploadButton** - Upload Trigger

Simple, reusable button to trigger image picker:

```dart
ReceiptUploadButton(onPressed: _pickReceipt)
```

#### 4. **ImageGalleryPreview** - Multiple Images (Future)

For future multi-image support:

```dart
ImageGalleryPreview(
  imagePaths: [path1, path2, path3],
  onRemove: (index) => removeImage(index),
)
```

- Browse multiple attached images
- Previous/Next navigation
- Swipe support (future enhancement)

### Using Images in Transactions

#### Adding a Receipt

1. In Add/Edit Transaction screen, scroll to "Receipt Attachment" section
2. Tap **"Attach Receipt"** button
3. Select image from gallery
4. Image is compressed and saved automatically
5. Preview thumbnail appears immediately

#### Viewing a Receipt

1. **Option 1**: In Add/Edit form, tap the receipt thumbnail to zoom
2. **Option 2**: In Income/Expense list, tap **"View Receipt"** button
3. Full-screen viewer opens with pinch-zoom capability
4. Pinch out/in to zoom (1x to 3x)
5. Drag to pan when zoomed
6. Tap close button to return

#### Removing a Receipt

1. In Add/Edit form, tap the **red X** button on the thumbnail
2. Image is removed from transaction
3. Receipt is deleted from disk on save

---

## 💾 Database Changes

No new tables were created. The existing `ExpenseModel` Hive adapter now fully utilizes:

```dart
@HiveField(5, defaultValue: false)
bool isIncome;  // True for income, false for expense

@HiveField(6)
String? receiptPath;  // Path to attached receipt image
```

### Hive Box Usage

- **Box Name**: `hiveExpenseBox`
- **All transactions** (income + expenses) stored together
- **Filtered in UI** by the `isIncome` flag

---

## 🔍 Dashboard Integration

The dashboard already displays:

- **Monthly Income**: `monthlyIncomeProvider` from expenses with `isIncome=true`
- **Income vs. Expense Balance**: Calculated as `income - expenses`
- **Net Balance Card**: Shows total balance including income

### Future Enhancements for Dashboard

Could add:

- Income trend chart over time
- Income source pie chart
- Top income categories
- Recurring income indicators

---

## 🎯 Use Cases

### Tracking Salary

1. Create monthly income entry
2. Select "Salary" category
3. Add month and year to notes
4. Attach pay slip or bank statement screenshot

### Freelance Income

1. Add entry for each completed project
2. Category: "Freelance" or appropriate type
3. Note: Project name/client
4. Receipt: Optional invoice or payment proof

### Investment Returns

1. Category: "Investment" or "Bonus"
2. Note: What investment returned
3. Date: Transaction date
4. Receipt: Optional statement screenshot

### Gift/Reimbursement

1. Add as income transaction
2. Note: Who sent it or reason
3. Receipt: Screenshot of transfer if needed
4. Date: When received

---

## 🛠️ Technical Details

### File Structure

```
lib/features/
├── income/
│   └── presentation/
│       ├── screens/
│       │   └── income_list_screen.dart
│       ├── widgets/
│       │   └── (future image widgets)
│       └── providers/
│           └── income_providers.dart
└── expense/
    └── presentation/
        └── widgets/
            └── image_preview_widget.dart
```

### State Management

- **Framework**: Riverpod (Provider)
- **Caching**: Automatic via FutureProvider
- **Refresh**: Pull-to-refresh on Income list screen

### Image Storage

- **Location**: App documents directory
- **Naming**: `{timestamp}_{originalFilename}`
- **Format**: Original format (JPEG/PNG)
- **Quality**: Compressed to 50%, max 800px width

---

## 🐛 Troubleshooting

### Images not showing in Income list

- Ensure receipt path is set (`receiptPath != null`)
- Check file still exists in app documents directory
- Try re-attaching the image

### Income not appearing on Income screen

- Verify transaction is saved with `isIncome = true`
- Pull down to refresh the list
- Check transaction date is not in future or very old (> year 2000)

### Performance issues with large receipts

- App automatically compresses images to improve performance
- If still slow, consider clearing old transactions

---

## 📝 Notes for Future Development

1. **Recurring Income**: Can add monthly recurring salary tracking
2. **Income Categories**: Consider adding more income categories (bonus, investment, gift, etc.)
3. **Multiple Receipts**: Extend to support multiple images per transaction
4. **Income Goals**: Set monthly/yearly income targets
5. **Tax Categories**: Mark income for tax purposes
6. **Export**: Generate income reports and receipts

---

## Summary

The app now provides **complete income management** with:
✅ Dedicated Income tracking screen  
✅ Income statistics and summaries  
✅ Monthly income visualization  
✅ Receipt/image attachment support  
✅ Full-screen image previews with zoom  
✅ Persistent storage of income history

All income data is displayed in the bottom navigation **Income** tab alongside Expenses, Loans, and Cards.
