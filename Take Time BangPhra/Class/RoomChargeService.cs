using System;
using System.Data;

namespace Take_Time_BangPhra
{
    /// <summary>
    /// Room Charge Service - Business logic for room charge operations
    /// Handles charging products to guest rooms, stock management, and payment tracking
    /// Created: 2025-11-06
    /// </summary>
    public class RoomChargeService
    {
        private readonly string _connectionString;
        private readonly RoomChargeDataAccess _chargeDA;
        private readonly code _code;

        public RoomChargeService(string connectionString)
        {
            _connectionString = connectionString;
            _chargeDA = new RoomChargeDataAccess(connectionString);
            _code = new code();
        }

        #region Charge to Room

        /// <summary>
        /// Charge products to guest room
        /// </summary>
        /// <param name="reservationId">Reservation ID to charge to</param>
        /// <param name="cartItems">DataTable with columns: ID, Product_Name, Barcode, Amount, Sell_Price, Price_Total, Category_ID</param>
        /// <param name="adminId">Admin ID performing the charge</param>
        /// <param name="notes">Optional notes</param>
        /// <returns>ID of last charge created</returns>
        public long ChargeToRoom(
            int reservationId,
            DataTable cartItems,
            int? adminId,
            string notes = null)
        {
            long lastChargeId = 0;

            try
            {
                if (cartItems == null || cartItems.Rows.Count == 0)
                {
                    throw new Exception("ไม่มีสินค้าในตะกร้า");
                }

                foreach (DataRow item in cartItems.Rows)
                {
                    int productId = Convert.ToInt32(item["ID"]);
                    string productName = item["Product_Name"].ToString();
                    string barcode = item["Barcode"]?.ToString();
                    int? categoryId = item["Category_ID"] != DBNull.Value
                        ? Convert.ToInt32(item["Category_ID"])
                        : (int?)null;
                    decimal quantity = Convert.ToDecimal(item["Amount"]);
                    decimal unitPrice = Convert.ToDecimal(item["Sell_Price"]);
                    decimal total = Convert.ToDecimal(item["Price_Total"]);

                    // Check stock availability
                    decimal currentStock = _chargeDA.GetProductStock(productId);
                    if (currentStock < quantity)
                    {
                        throw new Exception(string.Format("สินค้า '{0}' มีจำนวนไม่เพียงพอ (คงเหลือ {1})", productName, currentStock));
                    }

                    // Deduct stock
                    _chargeDA.DeductProductStock(productId, quantity);

                    // Create charge record
                    lastChargeId = _chargeDA.CreateRoomCharge(
                        reservationId,
                        productId,
                        productName,
                        barcode,
                        categoryId,
                        quantity,
                        unitPrice,
                        total,
                        "ROOM_CHARGE",
                        adminId,
                        notes
                    );

                    // Update reservation total
                    _chargeDA.UpdateReservationTotal(reservationId, total, isAddition: true);
                }

                // Log success
                _code.Logs(_connectionString,
                    "RoomChargeService.ChargeToRoom",
                    string.Format("Charged {0} items to Reservation {1}", cartItems.Rows.Count, reservationId),
                    adminId?.ToString() ?? "SYSTEM");

                return lastChargeId;
            }
            catch (Exception ex)
            {
                _code.Logs(_connectionString,
                    "RoomChargeService.ChargeToRoom Error",
                    string.Format("ReservationID: {0}, Error: {1}", reservationId, ex.Message),
                    adminId?.ToString() ?? "SYSTEM");
                throw;
            }
        }

        /// <summary>
        /// Charge single product to room (immediate mode with guest selected)
        /// This creates a charge record marked as IMMEDIATE (paid immediately)
        /// </summary>
        public long ChargeImmediateWithGuest(
            int reservationId,
            int productId,
            string productName,
            string productBarcode,
            int? categoryId,
            decimal quantity,
            decimal unitPrice,
            decimal totalAmount,
            string receiptId,
            int? adminId,
            string notes = null)
        {
            try
            {
                // Check stock
                decimal currentStock = _chargeDA.GetProductStock(productId);
                if (currentStock < quantity)
                {
                    throw new Exception(string.Format("สินค้า '{0}' มีจำนวนไม่เพียงพอ", productName));
                }

                // Deduct stock
                _chargeDA.DeductProductStock(productId, quantity);

                // Create charge record with IMMEDIATE type and PAID status
                long chargeId = _chargeDA.CreateRoomCharge(
                    reservationId,
                    productId,
                    productName,
                    productBarcode,
                    categoryId,
                    quantity,
                    unitPrice,
                    totalAmount,
                    "IMMEDIATE",
                    adminId,
                    notes
                );

                // Mark as paid immediately
                _chargeDA.MarkChargeAsPaid(chargeId, receiptId);

                // Note: Don't update reservation total for immediate charges
                // as they're paid separately

                _code.Logs(_connectionString,
                    "RoomChargeService.ChargeImmediateWithGuest",
                    string.Format("Immediate charge for Product {0} linked to Reservation {1}, Receipt {2}", productId, reservationId, receiptId),
                    adminId?.ToString() ?? "SYSTEM");

                return chargeId;
            }
            catch (Exception ex)
            {
                _code.Logs(_connectionString,
                    "RoomChargeService.ChargeImmediateWithGuest Error",
                    string.Format("ProductID: {0}, ReservationID: {1}, Error: {2}", productId, reservationId, ex.Message),
                    adminId?.ToString() ?? "SYSTEM");
                throw;
            }
        }

        #endregion

        #region Cancel Charge

        /// <summary>
        /// Cancel room charge and return stock
        /// </summary>
        public void CancelRoomCharge(
            long chargeId,
            int? adminId,
            string reason)
        {
            try
            {
                // Get charge details
                var chargeData = _chargeDA.GetChargeById(chargeId);

                if (chargeData.Rows.Count == 0)
                    throw new Exception("ไม่พบรายการชาร์จนี้");

                var charge = chargeData.Rows[0];

                string status = charge["Status"].ToString();
                if (status != "PENDING")
                    throw new Exception("สามารถยกเลิกได้เฉพาะรายการที่ยังไม่ชำระเท่านั้น");

                int reservationId = Convert.ToInt32(charge["Reservation_ID"]);
                int productId = Convert.ToInt32(charge["Product_ID"]);
                decimal quantity = Convert.ToDecimal(charge["Quantity"]);
                decimal totalAmount = Convert.ToDecimal(charge["TotalAmount"]);
                string chargeType = charge["ChargeType"].ToString();

                // Return stock
                _chargeDA.ReturnProductStock(productId, quantity);

                // Mark as cancelled
                _chargeDA.CancelCharge(chargeId, adminId, reason);

                // Update reservation total (only for ROOM_CHARGE type)
                if (chargeType == "ROOM_CHARGE")
                {
                    _chargeDA.UpdateReservationTotal(reservationId, totalAmount, isAddition: false);
                }

                // Log
                _code.Logs(_connectionString,
                    "RoomChargeService.CancelRoomCharge",
                    string.Format("Cancelled Charge {0}, Returned {1} units of Product {2}, Reason: {3}", chargeId, quantity, productId, reason),
                    adminId?.ToString() ?? "SYSTEM");
            }
            catch (Exception ex)
            {
                _code.Logs(_connectionString,
                    "RoomChargeService.CancelRoomCharge Error",
                    string.Format("ChargeID: {0}, Error: {1}", chargeId, ex.Message),
                    adminId?.ToString() ?? "SYSTEM");
                throw;
            }
        }

        #endregion

        #region Payment Processing

        /// <summary>
        /// Get pending charges for receipt generation
        /// </summary>
        public DataTable GetPendingChargesForReceipt(int reservationId)
        {
            return _chargeDA.GetReservationCharges(reservationId, "PENDING");
        }

        /// <summary>
        /// Mark all pending charges as paid (when combined receipt is generated)
        /// </summary>
        public int MarkAllChargesAsPaid(int reservationId, string receiptId)
        {
            try
            {
                int affectedRows = _chargeDA.MarkAllChargesAsPaid(reservationId, receiptId);

                _code.Logs(_connectionString,
                    "RoomChargeService.MarkAllChargesAsPaid",
                    string.Format("Marked {0} charges as paid for Reservation {1}, Receipt {2}", affectedRows, reservationId, receiptId),
                    "SYSTEM");

                return affectedRows;
            }
            catch (Exception ex)
            {
                _code.Logs(_connectionString,
                    "RoomChargeService.MarkAllChargesAsPaid Error",
                    string.Format("ReservationID: {0}, ReceiptID: {1}, Error: {2}", reservationId, receiptId, ex.Message),
                    "SYSTEM");
                throw;
            }
        }

        /// <summary>
        /// Calculate total pending charges for a reservation
        /// </summary>
        public decimal CalculatePendingChargesTotal(int reservationId)
        {
            return _chargeDA.GetTotalPendingCharges(reservationId);
        }

        #endregion

        #region Guest Management

        /// <summary>
        /// Get active guests for POS dropdown
        /// </summary>
        public DataTable GetActiveGuests()
        {
            return _chargeDA.GetActiveGuestReservations();
        }

        /// <summary>
        /// Get guest reservation info
        /// </summary>
        public DataTable GetGuestInfo(int reservationId)
        {
            return _chargeDA.GetReservationById(reservationId);
        }

        /// <summary>
        /// Get guest reservation info for specific date
        /// </summary>
        public DataTable GetGuestInfo(int reservationId, DateTime searchDate)
        {
            return _chargeDA.GetReservationById(reservationId, searchDate);
        }

        /// <summary>
        /// Check if reservation has pending charges
        /// </summary>
        public bool HasPendingCharges(int reservationId)
        {
            decimal pendingTotal = _chargeDA.GetTotalPendingCharges(reservationId);
            return pendingTotal > 0;
        }

        #endregion

        #region Pre-bookable Products

        /// <summary>
        /// Get products available for pre-booking
        /// </summary>
        public DataTable GetPreBookableProducts()
        {
            return _chargeDA.GetPreBookableProducts();
        }

        /// <summary>
        /// Pre-book products with reservation (for new bookings)
        /// </summary>
        public long PreBookProducts(
            int reservationId,
            DataTable selectedProducts,
            int? adminId,
            string notes = null)
        {
            long lastChargeId = 0;

            try
            {
                if (selectedProducts == null || selectedProducts.Rows.Count == 0)
                {
                    throw new Exception("ไม่มีสินค้าที่เลือก");
                }

                foreach (DataRow item in selectedProducts.Rows)
                {
                    int productId = Convert.ToInt32(item["ID"]);
                    string productName = item["Product_Name"].ToString();
                    decimal quantity = Convert.ToDecimal(item["Quantity"]);
                    decimal unitPrice = Convert.ToDecimal(item["Sell_Price"]);
                    decimal total = quantity * unitPrice;
                    int? categoryId = item["Category_ID"] != DBNull.Value
                        ? Convert.ToInt32(item["Category_ID"])
                        : (int?)null;

                    // Check stock
                    decimal currentStock = _chargeDA.GetProductStock(productId);
                    if (currentStock < quantity)
                    {
                        throw new Exception(string.Format("สินค้า '{0}' มีจำนวนไม่เพียงพอ", productName));
                    }

                    // Deduct stock
                    _chargeDA.DeductProductStock(productId, quantity);

                    // Create charge record with PRE_BOOKING type
                    lastChargeId = _chargeDA.CreateRoomCharge(
                        reservationId,
                        productId,
                        productName,
                        null, // no barcode for pre-booking
                        categoryId,
                        quantity,
                        unitPrice,
                        total,
                        "PRE_BOOKING",
                        adminId,
                        notes ?? "จองพร้อมการจองห้องพัก"
                    );

                    // Update reservation total
                    _chargeDA.UpdateReservationTotal(reservationId, total, isAddition: true);
                }

                _code.Logs(_connectionString,
                    "RoomChargeService.PreBookProducts",
                    string.Format("Pre-booked {0} products for Reservation {1}", selectedProducts.Rows.Count, reservationId),
                    adminId?.ToString() ?? "SYSTEM");

                return lastChargeId;
            }
            catch (Exception ex)
            {
                _code.Logs(_connectionString,
                    "RoomChargeService.PreBookProducts Error",
                    string.Format("ReservationID: {0}, Error: {1}", reservationId, ex.Message),
                    adminId?.ToString() ?? "SYSTEM");
                throw;
            }
        }

        #endregion

        #region Validation

        /// <summary>
        /// Validate if room charge operation is allowed
        /// </summary>
        public void ValidateRoomChargeAllowed(int reservationId)
        {
            // Get reservation info
            var reservationInfo = _chargeDA.GetReservationById(reservationId);

            if (reservationInfo.Rows.Count == 0)
            {
                throw new Exception("ไม่พบข้อมูลการจอง");
            }

            var row = reservationInfo.Rows[0];
            string status = row["Status"].ToString();

            // Check if reservation status allows charging
            if (status == "ยกเลิกคืนเงิน" || status == "ยกเลิกไม่คืนเงิน")
            {
                throw new Exception("ไม่สามารถชาร์จสินค้าเข้าการจองที่ถูกยกเลิกได้");
            }

            // Additional validations can be added here
            // e.g., check-out date, credit limit, etc.
        }

        /// <summary>
        /// Validate if room charge operation is allowed for specific date
        /// </summary>
        public void ValidateRoomChargeAllowed(int reservationId, DateTime searchDate)
        {
            // Get reservation info for the specified date
            var reservationInfo = _chargeDA.GetReservationById(reservationId, searchDate);

            if (reservationInfo.Rows.Count == 0)
            {
                throw new Exception("ไม่พบข้อมูลการจอง");
            }

            var row = reservationInfo.Rows[0];
            string status = row["Status"].ToString();

            // Check if reservation status allows charging
            if (status == "ยกเลิกคืนเงิน" || status == "ยกเลิกไม่คืนเงิน")
            {
                throw new Exception("ไม่สามารถชาร์จสินค้าเข้าการจองที่ถูกยกเลิกได้");
            }

            // Additional validations can be added here
            // e.g., check-out date, credit limit, etc.
        }

        #endregion

        #region Summary & Reports

        /// <summary>
        /// Get charge summary for a reservation
        /// </summary>
        public DataTable GetChargeSummary(int reservationId)
        {
            var summary = _chargeDA.GetReservationCharges(reservationId);

            // Add summary row if needed
            // Could calculate totals by status, type, etc.

            return summary;
        }

        /// <summary>
        /// Get detailed charge information for display
        /// </summary>
        public string GetChargesSummaryText(int reservationId)
        {
            decimal pending = _chargeDA.GetTotalPendingCharges(reservationId);
            var charges = _chargeDA.GetReservationCharges(reservationId);

            int totalCharges = charges.Rows.Count;
            int pendingCount = 0;
            int paidCount = 0;

            foreach (DataRow row in charges.Rows)
            {
                string status = row["Status"].ToString();
                if (status == "PENDING") pendingCount++;
                else if (status == "PAID") paidCount++;
            }

            return string.Format("รายการทั้งหมด: {0} | รอชำระ: {1} ({2} บาท) | ชำระแล้ว: {3}", totalCharges, pendingCount, pending:N2, paidCount);
        }

        #endregion
    }
}
