-- =============================================
-- View: vw_ActiveGuestReservations
-- Purpose: Display active guest reservations for room charge dropdown
-- Created: 2025-11-06
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

    -- Get room names (concatenated)
    RoomNames.Names AS RoomNames,

    -- Calculate pending product charges
    ISNULL(PendingCharges.Total, 0) AS PendingCharges,

    -- Formatted display text for dropdown
    CONCAT(
        C.Name,
        ' (',
        RoomNames.Names,
        ') - เข้า: ',
        FORMAT(R.CheckinDate, 'dd/MM/yyyy'),
        ' ออก: ',
        FORMAT(R.CheckoutDate, 'dd/MM/yyyy')
    ) AS DisplayText

FROM Reservation R
INNER JOIN Customer C ON R.Customer_MobilePhone = C.MobilePhone

-- Get room names
CROSS APPLY (
    SELECT STUFF((
        SELECT ', ' + A.AccomName
        FROM Reservation_Accommodation RA
        INNER JOIN Accommodation A ON RA.Accommodation_ID = A.ID
        WHERE RA.Reservation_ID = R.ID
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Names
) AS RoomNames

-- Get pending charges total
OUTER APPLY (
    SELECT SUM(TotalPrice) AS Total
    FROM Reservation_Product_Charges
    WHERE Reservation_ID = R.ID
    AND Status = 'PENDING'
) AS PendingCharges

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
