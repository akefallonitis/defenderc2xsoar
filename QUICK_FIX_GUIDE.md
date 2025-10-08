# Quick Fix Guide - Workbook API Errors

## 🔴 Problem

You see this error in your workbook:
```
"Please provide the api-version URL parameter (e.g. api-version=2019-06-01)"
```

## ✅ Solution

This has been fixed! The workbook files now use the correct `body` field instead of `httpBodySchema`.

## 📥 How to Deploy the Fix

### Option 1: Update via Azure Portal (Recommended)

1. **Open Azure Portal** → Navigate to Monitor → Workbooks

2. **For DefenderC2 Main Workbook:**
   - Open "DefenderC2 Command & Control Console"
   - Click **Edit** → **Advanced Editor** (</> icon)
   - Copy content from: `workbook/DefenderC2-Workbook.json`
   - Paste and replace all content in the editor
   - Click **Apply** → **Save**

3. **For File Operations Workbook:**
   - Open "File Operations" workbook
   - Click **Edit** → **Advanced Editor** (</> icon)
   - Copy content from: `workbook/FileOperations.workbook`
   - Paste and replace all content in the editor
   - Click **Apply** → **Save**

4. **Verify the Fix:**
   - Refresh both workbooks
   - Navigate through all tabs
   - Verify no error messages appear
   - Test queries to ensure data is returned

### Option 2: Deploy via ARM Template

If you're deploying the entire solution via ARM template, the fix is already included in the template. Just redeploy:

```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file deployment/azuredeploy.json \
  --parameters @deployment/azuredeploy.parameters.json
```

## 🎯 What Was Fixed

Changed 13 queries across both workbooks from:
- ❌ `"httpBodySchema": "{\"action\":...}"` (WRONG - causes api-version error)
- ✅ `"body": "{\"action\":...}"` (CORRECT - works with Function Apps)

## ✅ After Deployment

You should see:
- ✅ No "api-version" errors
- ✅ All tabs display data correctly
- ✅ All queries work with Function App endpoints
- ✅ Workbook functions as expected

## 🔍 Need More Details?

See `WORKBOOK_API_FIX_SUMMARY.md` for complete technical details.

## 💡 Still Having Issues?

1. Verify Function App Name parameter is set correctly in the workbook
2. Check Function App is deployed and running
3. Verify Function App authentication settings
4. Check Azure Function logs for any errors

---

**Fix verified and tested** ✅  
**Ready for production deployment** ✅
