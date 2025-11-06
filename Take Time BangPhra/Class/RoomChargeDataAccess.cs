using System;
using System.Collections.Generic;
using System.Data;

namespace Take_Time_BangPhra
{
    /// <summary>
    /// 🔒 SECURE Data Access Layer for Room Charge operations
    /// All methods use parameterized queries to prevent SQL Injection
    /// Created: 2025-11-06
    /// </summary>
    public class RoomChargeDataAccess
    {
        private readonly code _code;
        private readonly string _connectionString;

        public RoomChargeDataAccess(string connectionString)
        {
            _code = new code();
            _connectionString = connectionString;
        }

        #region Charge Creation

        /// <summary>
        /// Create a room charge record
        /// </summary>
        public long CreateRoomCharge(
            int reservationId,
            int productId,
            string productName,
            string productBarcode,
            int? categoryId,
            decimal quantity,
            decimal unitPrice,
            decimal totalAmount,
            string chargeType,
            int? chargedByAdminId,
            string notes = null)
        {
            var parameters = new Dictionary<string, object>
            {
                { "@reservationId", reservationId },
                { "@productId", productId },
                { "@productName", productName },
                { "@barcode", productBarcode ?? (object)DBNull.Value },
                { "@categoryId", categoryId ?? (object)DBNull.Value },
                { "@quantity", quantity },
                { "@unitPrice", unitPrice },
                { "@totalAmount", totalAmount },
                { "@chargeType", chargeType },
                { "@chargedBy", chargedByAdminId ?? (object)DBNull.Value },
                { "@notes", notes ?? (object)DBNull.Value }
            };

            return _code.DatabaseInsertReturnSafe(_connectionString,
                @"INSERT INTO Reservation_Product_Charges (
                    Reservation_ID, Product_ID, Product_Name, Product_Barcode,
                    Category_ID, Quantity, UnitPrice, TotalAmount, ChargeType,
                    ChargedBy_AdminID, Notes, Status, IsPaid, StockDeducted
                  )
                  VALUES (
                    @reservationId, @productId, @productName, @barcode,
                    @categoryId, @quantity, @unitPrice, @totalAmount, @chargeType,
                    @chargedBy, @notes, 'PENDING', 0, 1
                  );
                  SELECT SCOPE_IDENTITY();",
                parameters);
        }

        #endregion

        #region Charge Queries

        /// <summary>
        /// Get all charges for a reservation
        /// </summary>
        public DataTable GetReservationCharges(int reservationId, string status = null)
        {
            var parameters = new Dictionary<string, object>
            {
                { "@reservationId", reservationId }
            };

            string query = @"
                SELECT * FROM vw_ReservationProductCharges
                WHERE Reservation_ID = @reservationId";

            if (!string.IsNullOrEmpty(status))
            {
                query += " AND Status = @status";
                parameters.Add("@status", status);
            }

            query += " ORDER BY ChargedDate DESC";

            return _code.DatabaseQuerySafe(_connectionString, query, parameters);
        }

        /// <summary>
        /// Get a single charge by ID
        /// </summary>
        public DataTable GetChargeById(long chargeId)
        {
            var parameters = new Dictionary<string, object>
            {
                { "@chargeId", chargeId }
            };

            return _code.DatabaseQuerySafe(_connectionString,
                @"SELECT * FROM Reservation_Product_Charges
                  WHERE ID = @chargeId",
                parameters);
        }

        /// <summary>
        /// Get total pending charges for a reservation
        /// </summary>
        public decimal GetTotalPendingCharges(int reservationId)
        {
            var parameters = new Dictionary<string, object>
            {
                { "@reservationId", reservationId }
            };

            var result = _code.DatabaseQuerySafe(_connectionString,
                @"SELECT ISNULL(SUM(TotalAmount), 0) as TotalPending
                  FROM Reservation_Product_Charges
                  WHERE Reservation_ID = @reservationId
                  AND Status = 'PENDING'",
                parameters);

            if (result.Rows.Count > 0)
            {
                return Convert.ToDecimal(result.Rows[0]["TotalPending"]);
            }

            return 0;
        }

        /// <summary>
        /// Get active guest reservations (for POS dropdown)
        /// </summary>
        public DataTable GetActiveGuestReservations()
        {
            return _code.DatabaseQuerySafe(_connectionString,
                "SELECT * FROM vw_ActiveGuestReservations ORDER BY CheckInDate DESC",
                null);
        }

        /// <summary>
        /// Get reservation info by ID (for guest selection)
        /// </summary>
        public DataTable GetReservationById(int reservationId)
        {
            var parameters = new Dictionary<string, object>
            {
                { "@reservationId", reservationId }
            };

            return _code.DatabaseQuerySafe(_connectionString,
                "SELECT * FROM vw_ActiveGuestReservations WHERE ReservationID = @reservationId",
                parameters);
        }

        #endregion

        #region Charge Updates

        /// <summary>
        /// Mark charge as paid (when receipt is generated)
        /// </summary>
        public void MarkChargeAsPaid(long chargeId, string receiptId)
        {
            var parameters = new Dictionary<string, object>
            {
                { "@chargeId", chargeId },
                { "@receiptId", receiptId },
                { "@paymentDate", DateTime.Now }
            };

            _code.DatabaseInsertSafe(_connectionString,
                @"UPDATE Reservation_Product_Charges
                  SET Status = 'PAID',
                      IsPaid = 1,
                      Receipt_ID = @receiptId,
                      PaymentDate = @paymentDate
                  WHERE ID = @chargeId",
                parameters);
        }

        /// <summary>
        /// Mark all pending charges as paid for a reservation
        /// </summary>
        public int MarkAllChargesAsPaid(int reservationId, string receiptId)
        {
            var parameters = new Dictionary<string, object>
            {
                { "@reservationId", reservationId },
                { "@receiptId", receiptId },
                { "@paymentDate", DateTime.Now }
            };

            _code.DatabaseInsertSafe(_connectionString,
                @"UPDATE Reservation_Product_Charges
                  SET Status = 'PAID',
                      IsPaid = 1,
                      Receipt_ID = @receiptId,
                      PaymentDate = @paymentDate
                  WHERE Reservation_ID = @reservationId
                  AND Status = 'PENDING'",
                parameters);

            // Return number of rows affected
            var countResult = _code.DatabaseQuerySafe(_connectionString,
                @"SELECT COUNT(*) as UpdateCount
                  FROM Reservation_Product_Charges
                  WHERE Reservation_ID = @reservationId
                  AND Receipt_ID = @receiptId",
                new Dictionary<string, object>
                {
                    { "@reservationId", reservationId },
                    { "@receiptId", receiptId }
                });

            if (countResult.Rows.Count > 0)
            {
                return Convert.ToInt32(countResult.Rows[0]["UpdateCount"]);
            }

            return 0;
        }

        /// <summary>
        /// Cancel charge and update status
        /// </summary>
        public void CancelCharge(
            long chargeId,
            int? cancelledByAdminId,
            string cancelReason)
        {
            var parameters = new Dictionary<string, object>
            {
                { "@chargeId", chargeId },
                { "@cancelledBy", cancelledByAdminId ?? (object)DBNull.Value },
                { "@cancelReason", cancelReason ?? (object)DBNull.Value },
                { "@cancelDate", DateTime.Now }
            };

            _code.DatabaseInsertSafe(_connectionString,
                @"UPDATE Reservation_Product_Charges
                  SET Status = 'CANCELLED',
                      StockReturned = 1,
                      CancelledDate = @cancelDate,
                      CancelledBy_AdminID = @cancelledBy,
                      CancelReason = @cancelReason
                  WHERE ID = @chargeId",
                parameters);
        }

        #endregion

        #region Stock Management

        /// <summary>
        /// Deduct product stock by creating Product_Out record
        /// Stock = Product_In - Product_Out (no Amount column in Product table)
        /// </summary>
        public void DeductProductStock(int productId, decimal quantity, string receiptId = null, string remark = null)
        {
            var parameters = new Dictionary<string, object>
            {
                { "@productId", productId },
                { "@quantity", quantity },
                { "@receiptId", receiptId ?? (object)DBNull.Value },
                { "@remark", remark ?? "Room Charge Stock Deduction" },
                { "@dateTime", DateTime.Now }
            };

            _code.DatabaseInsertSafe(_connectionString,
                @"INSERT INTO Product_Out (DateTime_Out, Product_ID, Amount, PricePerUnit, Account_Receipt_ID, Remark)
                  SELECT @dateTime, @productId, @quantity,
                         ISNULL(Sell_Price, 0), @receiptId, @remark
                  FROM Product WHERE ID = @productId",
                parameters);
        }

        /// <summary>
        /// Return product stock by creating Product_In record
        /// Used when cancelling room charges
        /// </summary>
        public void ReturnProductStock(int productId, decimal quantity, string remark = null)
        {
            var parameters = new Dictionary<string, object>
            {
                { "@productId", productId },
                { "@quantity", quantity },
                { "@remark", remark ?? "Room Charge Cancellation - Stock Return" },
                { "@dateTime", DateTime.Now }
            };

            _code.DatabaseInsertSafe(_connectionString,
                @"INSERT INTO Product_In (DateTime_In, Product_ID, Amount, PricePerUnit, Remark)
                  SELECT @dateTime, @productId, @quantity,
                         ISNULL(Buy_Price, 0), @remark
                  FROM Product WHERE ID = @productId",
                parameters);
        }

        /// <summary>
        /// Get current product stock (calculated from Product_In - Product_Out)
        /// </summary>
        public decimal GetProductStock(int productId)
        {
            var parameters = new Dictionary<string, object>
            {
                { "@productId", productId }
            };

            var result = _code.DatabaseQuerySafe(_connectionString,
                @"SELECT dbo.fn_GetProductStock(@productId) as CurrentStock",
                parameters);

            if (result.Rows.Count > 0)
            {
                return Convert.ToDecimal(result.Rows[0]["CurrentStock"]);
            }

            return 0;
        }

        #endregion

        #region Reservation Updates

        /// <summary>
        /// Update reservation total price
        /// </summary>
        public void UpdateReservationTotal(int reservationId, decimal amount, bool isAddition)
        {
            string operation = isAddition ? "+" : "-";

            var parameters = new Dictionary<string, object>
            {
                { "@reservationId", reservationId },
                { "@amount", amount }
            };

            _code.DatabaseInsertSafe(_connectionString,
                $@"UPDATE Reservation
                   SET TotalPrice = TotalPrice {operation} @amount
                   WHERE ID = @reservationId",
                parameters);
        }

        /// <summary>
        /// Get reservation total price
        /// </summary>
        public decimal GetReservationTotal(int reservationId)
        {
            var parameters = new Dictionary<string, object>
            {
                { "@reservationId", reservationId }
            };

            var result = _code.DatabaseQuerySafe(_connectionString,
                @"SELECT ISNULL(TotalPrice, 0) as TotalPrice
                  FROM Reservation
                  WHERE ID = @reservationId",
                parameters);

            if (result.Rows.Count > 0)
            {
                return Convert.ToDecimal(result.Rows[0]["TotalPrice"]);
            }

            return 0;
        }

        #endregion

        #region Pre-bookable Products

        /// <summary>
        /// Get pre-bookable products (for new reservations)
        /// Stock is calculated from Product_In - Product_Out
        /// </summary>
        public DataTable GetPreBookableProducts()
        {
            return _code.DatabaseQuerySafe(_connectionString,
                @"SELECT
                    ID,
                    Product_Name,
                    Sell_Price,
                    Category_ID,
                    dbo.fn_GetProductStock(ID) AS CurrentStock
                  FROM Product
                  WHERE Status = 'True'
                  AND CanPreBook = 1
                  AND dbo.fn_GetProductStock(ID) > 0
                  ORDER BY Product_Name",
                null);
        }

        #endregion
    }
}
