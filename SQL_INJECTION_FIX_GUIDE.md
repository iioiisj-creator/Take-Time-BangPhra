# 🔒 SQL Injection Fix - Migration Guide
## คู่มือการแก้ไขช่องโหว่ SQL Injection ทั้งระบบ

**วันที่**: 2025-11-05
**ความรุนแรง**: 🔴 CRITICAL
**ผลกระทบ**: ทั้งระบบ (26 ไฟล์)

---

## 📋 สรุปการแก้ไข

เพิ่ม **Secure Methods** ใน `Code.cs` เพื่อป้องกัน SQL Injection:

| Method เดิม (ไม่ปลอดภัย) | Method ใหม่ (ปลอดภัย) | การใช้งาน |
|--------------------------|----------------------|-----------|
| `DatabaseQuery()` | `DatabaseQuerySafe()` | SELECT queries |
| `DatabaseInsert()` | `DatabaseInsertSafe()` | INSERT/UPDATE/DELETE |
| `DatabaseInsertReturn()` | `DatabaseInsertReturnSafe()` | INSERT with ID return |

---

## ⚠️ ทำไมต้องแก้?

### ปัญหาเดิม (Vulnerable Code):
```csharp
// ❌ อันตราย! - SQL Injection
string phone = TextBox1.Text; // ถ้า user ใส่: ' OR '1'='1
DataTable dt = code.DatabaseQuery(conn,
    "SELECT * FROM Customer WHERE MobilePhone = '" + phone + "'");

// Query ที่เกิดขึ้น:
// SELECT * FROM Customer WHERE MobilePhone = '' OR '1'='1'
// ผลลัพธ์: ได้ข้อมูลลูกค้าทั้งหมด!
```

### ผลกระทบที่เกิดขึ้นได้:
1. **ขโมยข้อมูล**: ดูข้อมูลลูกค้าทั้งหมด
2. **ลบข้อมูล**: `'; DELETE FROM Customer; --`
3. **แก้ไขราคา**: เปลี่ยนราคาห้องเป็น 0 บาท
4. **สร้าง Admin**: เพิ่ม user ที่มีสิทธิ์ admin

---

## ✅ วิธีแก้ไขที่ถูกต้อง

### วิธีที่ 1: ใช้ DatabaseQuerySafe (แนะนำ)

```csharp
// ✅ ปลอดภัย! - Parameterized Query
var parameters = new Dictionary<string, object> {
    { "@phone", TextBox1.Text }  // ระบบจะ escape อัตโนมัติ
};

DataTable dt = code.DatabaseQuerySafe(conn,
    "SELECT * FROM Customer WHERE MobilePhone = @phone",
    parameters);
```

### วิธีที่ 2: สำหรับ Query ที่ไม่มี User Input

```csharp
// ✅ ปลอดภัย - ไม่มี user input
DataTable dt = code.DatabaseQuerySafe(conn,
    "SELECT * FROM Accommodation WHERE Status = 'Active'");
// ไม่ต้องใส่ parameters
```

---

## 📖 ตัวอย่างการแก้ไข

### ตัวอย่างที่ 1: SELECT Query

**เดิม (Vulnerable)**:
```csharp
string id = Request.QueryString["id"];
string phone = TextBox1.Text;
DataTable dt = code.DatabaseQuery(conn,
    "SELECT * FROM Reservation WHERE ID = " + id +
    " AND Customer_MobilePhone = '" + phone + "'");
```

**ใหม่ (Secure)**:
```csharp
string id = Request.QueryString["id"];
string phone = TextBox1.Text;

var parameters = new Dictionary<string, object> {
    { "@id", id },
    { "@phone", phone }
};

DataTable dt = code.DatabaseQuerySafe(conn,
    "SELECT * FROM Reservation WHERE ID = @id AND Customer_MobilePhone = @phone",
    parameters);
```

---

### ตัวอย่างที่ 2: INSERT Query

**เดิม (Vulnerable)**:
```csharp
code.DatabaseInsert(conn,
    "INSERT INTO Customer (MobilePhone, Name, Email) VALUES ('" +
    TextBox1.Text + "', N'" + TextBox2.Text + "', '" + TextBox3.Text + "')");
```

**ใหม่ (Secure)**:
```csharp
var parameters = new Dictionary<string, object> {
    { "@phone", TextBox1.Text },
    { "@name", TextBox2.Text },
    { "@email", TextBox3.Text }
};

code.DatabaseInsertSafe(conn,
    "INSERT INTO Customer (MobilePhone, Name, Email) VALUES (@phone, @name, @email)",
    parameters);
```

---

### ตัวอย่างที่ 3: INSERT with RETURNING ID

**เดิม (Vulnerable)**:
```csharp
int newId = code.DatabaseInsertReturn(conn,
    "INSERT INTO Reservation (Customer_MobilePhone, CheckinDate, TotalPrice) VALUES ('" +
    phone + "', '" + date + "', " + price + "); SELECT SCOPE_IDENTITY();");
```

**ใหม่ (Secure)**:
```csharp
var parameters = new Dictionary<string, object> {
    { "@phone", phone },
    { "@date", date },
    { "@price", price }
};

int newId = code.DatabaseInsertReturnSafe(conn,
    "INSERT INTO Reservation (Customer_MobilePhone, CheckinDate, TotalPrice) " +
    "VALUES (@phone, @date, @price); SELECT SCOPE_IDENTITY();",
    parameters);
```

---

### ตัวอย่างที่ 4: UPDATE Query

**เดิม (Vulnerable)**:
```csharp
code.DatabaseInsert(conn,
    "UPDATE Reservation SET TotalPrice = " + TextBox4.Text +
    ", Remark = N'" + TextBox6.Text + "' WHERE ID = " + id);
```

**ใหม่ (Secure)**:
```csharp
var parameters = new Dictionary<string, object> {
    { "@price", TextBox4.Text },
    { "@remark", TextBox6.Text },
    { "@id", id }
};

code.DatabaseInsertSafe(conn,
    "UPDATE Reservation SET TotalPrice = @price, Remark = @remark WHERE ID = @id",
    parameters);
```

---

### ตัวอย่างที่ 5: Complex Query with Multiple Conditions

**เดิม (Vulnerable)**:
```csharp
DataTable dt = code.DatabaseQuery(conn,
    "SELECT * FROM Reservation_Accommodation " +
    "INNER JOIN Reservation ON Reservation.ID = Reservation_ID " +
    "WHERE CheckinDate = '" + code2.ParseDate(TextBox12.Text).Value.ToString("yyyy-MM-dd") + "' " +
    "AND AccomName = N'" + accomName + "' " +
    "AND Reservation_ID != " + id);
```

**ใหม่ (Secure)**:
```csharp
var parameters = new Dictionary<string, object> {
    { "@checkinDate", code2.ParseDate(TextBox12.Text).Value.ToString("yyyy-MM-dd") },
    { "@accomName", accomName },
    { "@reservationId", id }
};

DataTable dt = code.DatabaseQuerySafe(conn,
    "SELECT * FROM Reservation_Accommodation " +
    "INNER JOIN Reservation ON Reservation.ID = Reservation_ID " +
    "WHERE CheckinDate = @checkinDate " +
    "AND AccomName = @accomName " +
    "AND Reservation_ID != @reservationId",
    parameters);
```

---

### ตัวอย่างที่ 6: Coupon Validation (จาก Reserve.aspx.cs)

**เดิม (Vulnerable)**:
```csharp
DataTable dtDiscount = code.DatabaseQuery(conn,
    "SELECT * FROM Affiliate_Member WHERE Coupon_Code = N'" + TextBox19.Text + "'");
```

**ใหม่ (Secure)**:
```csharp
var parameters = new Dictionary<string, object> {
    { "@couponCode", TextBox19.Text }
};

DataTable dtDiscount = code.DatabaseQuerySafe(conn,
    "SELECT * FROM Affiliate_Member WHERE Coupon_Code = @couponCode",
    parameters);
```

---

## 🎯 ขั้นตอนการ Migrate (ทีละไฟล์)

### 1. เปิดไฟล์ที่ต้องการแก้ไข
```csharp
// เช่น Reserve.aspx.cs, ReserveTable.aspx.cs
```

### 2. หา Pattern ที่ต้องแก้
ค้นหา regex: `DatabaseQuery.*\+|DatabaseInsert.*\+`

### 3. แก้ไขทีละจุด
- แยก query string และ parameter values
- สร้าง Dictionary สำหรับ parameters
- เปลี่ยน `DatabaseQuery` → `DatabaseQuerySafe`
- เปลี่ยน `DatabaseInsert` → `DatabaseInsertSafe`
- เปลี่ยน `DatabaseInsertReturn` → `DatabaseInsertReturnSafe`

### 4. Test
- ทดสอบ functionality ปกติ
- ทดสอบ SQL Injection attack: ใส่ `' OR '1'='1` ในช่อง input
- ตรวจสอบ error handling

---

## 📊 สถานะการแก้ไข

### ไฟล์ที่ต้องแก้ไข (26 ไฟล์):

| ลำดับ | ไฟล์ | ความสำคัญ | สถานะ |
|------|------|----------|-------|
| 1 | Reserve.aspx.cs | 🔴 Critical | ⏳ Pending |
| 2 | ReserveTable.aspx.cs | 🔴 Critical | ⏳ Pending |
| 3 | Reservation.aspx.cs | 🟠 High | ⏳ Pending |
| 4 | Reservation_Confirmed.aspx.cs | 🟠 High | ⏳ Pending |
| 5 | Admin/Login.aspx.cs | 🔴 Critical | ⏳ Pending |
| 6 | Affiliate/Login.aspx.cs | 🔴 Critical | ⏳ Pending |
| 7 | Affiliate/Register.aspx.cs | 🟠 High | ⏳ Pending |
| 8 | Account/Receipt.aspx.cs | 🟠 High | ⏳ Pending |
| 9 | Account/CheckDocument.aspx.cs | 🟡 Medium | ⏳ Pending |
| 10 | DisplayReserve.aspx.cs | 🟡 Medium | ⏳ Pending |
| 11+ | อื่นๆ อีก 15 ไฟล์ | 🟡 Medium | ⏳ Pending |

---

## 🧪 การทดสอบ

### Test Case 1: ทดสอบ SQL Injection Attack
```
Input: ' OR '1'='1
Expected: Error หรือ no results (ไม่ควรได้ข้อมูลทั้งหมด)
```

### Test Case 2: ทดสอบ Special Characters
```
Input: O'Reilly
Expected: ทำงานปกติ ไม่ error
```

### Test Case 3: ทดสอบ NULL Values
```
Input: null or empty string
Expected: ทำงานปกติ ไม่ crash
```

### Test Case 4: ทดสอบ Unicode
```
Input: ทดสอบภาษาไทย
Expected: บันทึกและแสดงผลถูกต้อง
```

---

## ⚙️ Best Practices

### 1. ใช้ Parameters เสมอ
```csharp
// ✅ ดี
var p = new Dictionary<string, object> { { "@id", id } };
dt = code.DatabaseQuerySafe(conn, "SELECT * FROM Table WHERE ID = @id", p);

// ❌ ไม่ดี (แม้ว่าจะไม่ได้มาจาก user input)
dt = code.DatabaseQuery(conn, "SELECT * FROM Table WHERE ID = " + id);
```

### 2. ตั้งชื่อ Parameter ให้ชัดเจน
```csharp
// ✅ ดี - ชัดเจน
{ "@customerPhone", phone }
{ "@checkInDate", date }
{ "@reservationId", id }

// ❌ ไม่ดี - งงง่าย
{ "@p1", phone }
{ "@x", date }
{ "@a", id }
```

### 3. ใช้ Type ที่ถูกต้อง
```csharp
// ✅ ดี
{ "@price", Convert.ToDecimal(TextBox4.Text) }  // decimal
{ "@id", Convert.ToInt32(id) }                  // int
{ "@date", DateTime.Parse(dateString) }         // DateTime

// ❌ ไม่ดี - ทุกอย่างเป็น string
{ "@price", TextBox4.Text }  // อาจเกิด type mismatch
```

### 4. Handle Null Values
```csharp
// ✅ ดี
{ "@email", string.IsNullOrEmpty(email) ? (object)DBNull.Value : email }

// ❌ ไม่ดี - อาจ error
{ "@email", email }  // ถ้า email = null
```

---

## 🚨 ข้อควรระวัง

### 1. LIKE Queries
```csharp
// ❌ ยังไม่ดีพอ
{ "@search", "%" + searchText + "%" }

// ✅ ดีกว่า - escape % และ _
string escaped = searchText.Replace("%", "[%]").Replace("_", "[_]");
{ "@search", "%" + escaped + "%" }
```

### 2. IN Clauses
```csharp
// ❌ ยาก - IN clause ไม่รองรับ array
"WHERE ID IN (@ids)"

// ✅ แก้ไข - ใช้ Table-Valued Parameters หรือสร้าง dynamic query ปลอดภัย
string[] ids = new[] { "1", "2", "3" };
var safeIds = string.Join(",", ids.Select((id, i) => $"@id{i}"));
var parameters = ids.Select((id, i) => new { Key = $"@id{i}", Value = (object)id })
                     .ToDictionary(x => x.Key, x => x.Value);
DataTable dt = code.DatabaseQuerySafe(conn, $"SELECT * FROM Table WHERE ID IN ({safeIds})", parameters);
```

### 3. Dynamic Table/Column Names
```csharp
// ❌ ไม่สามารถใช้ parameter กับชื่อตารางหรือคอลัมน์
"SELECT * FROM @tableName"  // ไม่ทำงาน!

// ✅ ใช้ whitelist validation
string[] allowedTables = { "Customer", "Reservation", "Accommodation" };
if (!allowedTables.Contains(tableName))
    throw new ArgumentException("Invalid table name");

string query = $"SELECT * FROM {tableName} WHERE ID = @id";  // Safe เพราะ validated
```

---

## 📚 เอกสารอ้างอิง

- [OWASP SQL Injection Prevention](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)
- [Microsoft SQL Parameters Best Practices](https://docs.microsoft.com/en-us/dotnet/api/system.data.sqlclient.sqlparameter)
- [Code.cs Documentation](./Take%20Time%20BangPhra/Code.cs)

---

## 📞 Support

หากมีปัญหาหรือข้อสงสัย:
1. อ่าน guide นี้อีกครั้ง
2. ดูตัวอย่างที่แก้ไขแล้ว
3. ติดต่อทีม Dev

---

## ✅ Checklist สำหรับแต่ละไฟล์

- [ ] หา SQL queries ทั้งหมดที่มี string concatenation
- [ ] แปลงเป็น parameterized queries
- [ ] Test functionality ปกติ
- [ ] Test SQL Injection attacks
- [ ] Test edge cases (null, special chars, unicode)
- [ ] Update documentation
- [ ] Code review
- [ ] Commit with clear message

---

**อัพเดทล่าสุด**: 2025-11-05
**ผู้รับผิดชอบ**: Development Team
**ความสำคัญ**: 🔴 CRITICAL - ต้องแก้ไขทันที!
