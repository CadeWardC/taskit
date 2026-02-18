# Directus Setup for List Ordering & Sorting

To enable custom sorting for your To-Do lists and tasks, and to persist sort preferences per list, updating your Directus database schema is required.

## 1. Update `lists` Collection

1.  Log in to your Directus Admin App.
2.  Go to **Settings** > **Data Model**.
3.  Click on the `lists` collection.
4.  **Add `order` field:**
    *   Click **Create Field**.
    *   Select **Integer** type.
    *   Set the **Key** to `order`.
    *   Click **Save**.
5.  **Add `sort_option` field:**
    *   Click **Create Field**.
    *   Select **String** type.
    *   Set the **Key** to `sort_option`.
    *   (Optional) Set **Default Value** to `custom`.
    *   Click **Save**.

## 2. Update `todos` Collection

1.  Go to **Settings** > **Data Model**.
2.  Click on the `todos` collection.
3.  **Add `order` field:**
    *   Click **Create Field**.
    *   Select **Integer** type.
    *   Set the **Key** to `order`.
    *   Click **Save**.

## 3. Verify Permissions

Ensure your public or user role has **edit** access to these new fields.

1.  Go to **Settings** > **Roles & Permissions**.
2.  Select your user role.
3.  Click on the `lists` collection.
4.  Ensure **Field Permissions** includes `order` and `sort_option` for both Read and Update.
5.  Repeat for the `todos` collection (for `order` field).
