# SQL Scripts - Room Charge System

## Installation Instructions

### 1. Create Database View

Execute the following SQL script in your SQL Server database to create the required view:

```sql
SQL/vw_ActiveGuestReservations.sql
```

**How to run:**
1. Open SQL Server Management Studio (SSMS)
2. Connect to your TakeTime database
3. Open the `vw_ActiveGuestReservations.sql` file
4. Execute the script (F5 or Execute button)

### 2. Verify Installation

After running the script, verify the view was created successfully:

```sql
-- Check if view exists
SELECT * FROM sys.views WHERE name = 'vw_ActiveGuestReservations';

-- Test the view
SELECT * FROM vw_ActiveGuestReservations;
```

## View Description

### vw_ActiveGuestReservations

This view displays active guest reservations for the room charge dropdown in the POS system.

**Columns:**
- `ReservationID` - Unique reservation ID
- `CustomerName` - Guest name
- `CustomerNickName` - Guest nickname
- `CustomerPhone` - Guest phone number
- `CheckInDate` - Check-in date
- `CheckOutDate` - Check-out date
- `Status` - Reservation status
- `TotalPrice` - Total reservation price
- `TotalPaid` - Amount paid (deposit)
- `RemainingBalance` - Outstanding balance
- `RoomNames` - Comma-separated list of room names
- `PendingCharges` - Sum of pending product charges
- `DisplayText` - Formatted text for dropdown display

**Filter Logic:**
- Status = 'เช็คอินแล้ว' (Checked In)
- OR Today is between CheckInDate and CheckOutDate
- Excludes cancelled and checked-out reservations

## Troubleshooting

### View not found error
If you see "Invalid object name 'vw_ActiveGuestReservations'" error:
1. Make sure you've executed the SQL script in the correct database
2. Refresh the database connection in your application
3. Check SQL Server error log for any issues

### Empty dropdown in POS
If the dropdown shows no guests:
1. Verify there are active reservations in the system
2. Check the view returns data: `SELECT * FROM vw_ActiveGuestReservations`
3. Verify reservation status is 'เช็คอินแล้ว' or today is within stay dates
4. Check application logs for any errors

### Permission denied error
If you see permission errors:
```sql
GRANT SELECT ON vw_ActiveGuestReservations TO [YourApplicationUser];
```
Replace `[YourApplicationUser]` with your application's database user.
