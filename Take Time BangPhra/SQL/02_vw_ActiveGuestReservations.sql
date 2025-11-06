-- =============================================
-- View: vw_ActiveGuestReservations
-- Purpose: Display active guest reservations for room charge dropdown
-- Created: 2025-11-06
-- Important: Run 01_fn_GetReservationRoomNames.sql first!
-- =============================================

IF OBJECT_ID('vw_ActiveGuestReservations', 'V') IS NOT NULL
    DROP VIEW vw_ActiveGuestReservations;
GO

CREATE VIEW vw_ActiveGuestReservations
AS
SELECT
    R.ID AS ReservationID,
    C.Name AS CustomerName,
    C.NickName AS CustomerNickName,
    C.MobilePhone AS CustomerPhone,
    R.CheckinDate AS CheckInDate,
    R.CheckoutDate AS CheckOutDate,
    R.Status,
    R.TotalPrice,
    R.Deposit AS TotalPaid,
    (R.TotalPrice - ISNULL(R.Deposit, 0)) AS RemainingBalance,

    -- Get room names using scalar function
    dbo.fn_GetReservationRoomNames(R.ID) AS RoomNames,

    -- Calculate pending product charges
    ISNULL((
        SELECT SUM(TotalPrice)
        FROM Reservation_Product_Charges RPC
        WHERE RPC.Reservation_ID = R.ID
        AND RPC.Status = 'PENDING'
    ), 0) AS PendingCharges,

    -- Formatted display text for dropdown (using simple string concatenation)
    C.Name + ' (' + dbo.fn_GetReservationRoomNames(R.ID) + ') - เข้า: ' +
    CONVERT(VARCHAR, R.CheckinDate, 103) + ' ออก: ' +
    CONVERT(VARCHAR, R.CheckoutDate, 103) AS DisplayText

FROM Reservation R
INNER JOIN Customer C ON R.Customer_MobilePhone = C.MobilePhone

WHERE
    -- Status is checked in
    (R.Status = N'เช็คอินแล้ว')
    -- OR today is within check-in/check-out range
    OR (
        CAST(GETDATE() AS DATE) >= CAST(R.CheckinDate AS DATE)
        AND CAST(GETDATE() AS DATE) < CAST(R.CheckoutDate AS DATE)
        AND R.Status <> N'ยกเลิก'
        AND R.Status <> N'เช็คเอาท์แล้ว'
    );
GO

-- Grant permissions
GRANT SELECT ON vw_ActiveGuestReservations TO PUBLIC;
GO

-- Test the view
-- SELECT * FROM vw_ActiveGuestReservations;
