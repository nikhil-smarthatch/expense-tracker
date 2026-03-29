# Quick Start Guide: Income Management & Image Preview

## 🎯 How to Use Income Features

### Add Income Entry
1. **Navigate to Income Screen**: Tap the "Income" tab in the bottom navigation bar
2. **Tap + Button**: Opens Add Transaction form
3. **Select Income Type**: The form shows **Income/Expense toggle** at the top - select **"Income"**
4. **Fill Details**:
   - Amount: Enter income amount
   - Category: Choose from Salary, Food, Travel, Bills, Shopping, Others
   - Date: Select when income was received
   - Note: Add descriptions (e.g., "January Salary", "Freelance Project XYZ")
   - Receipt: Optional - attach proof/documentation

5. **Save**: Tap "Add Transaction" button

### View Income Records
- Go to **Income** tab
- See **Summary Cards** at top:
  - This Month Total
  - 6-Month Average
  - Entry Count
- **Scroll down** to see all income entries
- **Tap any entry** to edit or view details

### View Receipt Images
**Option 1**: In Transaction List
- Tap **"View Receipt"** button on any income card with a receipt
- Full-screen viewer opens with zoom capability

**Option 2**: In Edit Form
- Tap the **receipt thumbnail** to open full-screen preview
- Pinch to zoom (1x to 3x magnification)
- Drag to pan when zoomed

**Option 3**: Attach New Receipt
- Tap **"Attach Receipt"** button
- Select image from gallery
- Image is compressed and saved automatically
- Preview appears immediately

### Edit or Delete Income
1. Go to **Income** tab
2. Tap any income entry
3. To **edit**: Change fields and tap "Save Changes"
4. To **delete**: Tap trash icon and confirm

---

## 💡 How It Works Behind the Scenes

### Income Storage
- **NOT a separate database** - income uses the same storage as expenses
- Marked with `isIncome = true` flag
- Automatically separated in UI for easy viewing

### Receipt Storage
- **Compressed automatically** for device storage (50% quality, max 800px width)
- **Saved to app documents** directory
- **Path stored** in transaction database

### Data Architecture
```
ExpenseModel (Hive Database)
├── id: Unique identifier
├── amount: Income amount
├── category: Income source category
├── date: When income was received
├── note: Description/notes
├── isIncome: true ← Marks as income (not expense)
├── receiptPath: Optional attachment path
└── ... other fields
```

---

## 🎨 Image Preview Features

### Inline Preview (Thumbnail)
- Shows in Add/Edit form
- Small preview image with remove button
- Indicates image is attached
- Click to zoom to full-screen

### Full-Screen Preview
- Interactive zoom (1x to 3x magnification)
- Pan and scroll support
- Tap to close
- Works with any image format

### Attachment Options
- **From Gallery**: Select existing photos
- **From Camera**: Take new photos (future)
- **Compression**: Automatic optimization
- **Removal**: Easy delete with one tap

---

## 📊 Dashboard Integration

The Income feature automatically updates:
- **Monthly Income Summary** on Dashboard
- **Income vs Expense** balance calculation  
- **Net balance** including income

---

## 🔍 Tips & Tricks

### Organizing Income
- Use **Categories** to group similar income
- Add **Notes** for reference (e.g., project names)
- **Attach receipts** for all significant transactions

### Finding Transactions
- Entries sorted by **date (newest first)**
- Check **monthly summary** for quick totals
- Income entries **appear separately** from expenses

### Managing Receipts
- Compress images automatically saved local
- View anytime even offline
- Use for personal records or documentation

---

## ❓ FAQ

**Q: Can I have recurring income?**  
A: Yes! Mark "Recurring Subscription?" toggle when adding income

**Q: How long are receipts stored?**  
A: Until you manually delete the transaction

**Q: Can I upload multiple receipts per income?**  
A: Currently one per transaction; easily replaced

**Q: Is income data backed up?**  
A: Currently local only; consider exporting regularly

**Q: How do I see income trends?**  
A: Go to Income tab to see monthly totals and comparisons

---

Created: 29 March 2026
Feature: Income Management v1.0
