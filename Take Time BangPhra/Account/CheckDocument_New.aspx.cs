using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.IO;
using System.Linq;
using System.Text;
using System.Web.UI;
using System.Web.UI.WebControls;
using Take_Time_BangPhra.Class;

namespace Take_Time_BangPhra.Account
{
    public partial class CheckDocument_New : System.Web.UI.Page
    {
        private readonly string conn = ConfigurationManager.ConnectionStrings["TaketimeConnectionString"].ConnectionString;
        private code codeInstance = new code();
        private LoggingService loggingService;

        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                // Initialize services
                loggingService = new LoggingService(conn);

                if (Session["permission"]?.ToString() == "True" &&
                    (Session["User"]?.ToString() == "Owner" || Session["User"]?.ToString() == "Admin"))
                {
                    if (!IsPostBack)
                    {
                        InitializePage();
                    }
                }
                else
                {
                    Response.Redirect("/Default");
                }
            }
            catch (Exception ex)
            {
                loggingService?.LogException(ex, LoggingService.LogCategory.Accounting,
                    "Page load failed", GetCurrentUserId());
                Response.Redirect("/Default");
            }
        }

        private void InitializePage()
        {
            // Set default dates
            txtStartDate.Text = DateTime.Now.ToString("yyyy-MM-dd");
            txtEndDate.Text = DateTime.Now.ToString("yyyy-MM-dd");

            // Populate year dropdown
            string thisYear = DateTime.Now.Year > 2500 ?
                (DateTime.Now.Year - 543).ToString() : DateTime.Now.Year.ToString();
            string lastYear = DateTime.Now.AddYears(-1).Year > 2500 ?
                (DateTime.Now.AddYears(-1).Year - 543).ToString() : DateTime.Now.AddYears(-1).Year.ToString();

            ddlYear.Items.Clear();
            ddlYear.Items.Add(new ListItem(thisYear, thisYear));
            ddlYear.Items.Add(new ListItem(lastYear, lastYear));
        }

        protected void btnSearch_Click(object sender, EventArgs e)
        {
            try
            {
                DateTime startDate, endDate;

                // Determine date range
                if (ddlMonth.SelectedIndex > 0 && !string.IsNullOrEmpty(ddlYear.SelectedValue))
                {
                    // Use month/year selection
                    int month = Convert.ToInt32(ddlMonth.SelectedValue);
                    int year = Convert.ToInt32(ddlYear.SelectedValue);
                    startDate = new DateTime(year, month, 1);
                    endDate = startDate.AddMonths(1).AddDays(-1);

                    System.Diagnostics.Debug.WriteLine($"🔍 Search Mode: Month/Year - {year}/{month}");
                }
                else
                {
                    // Use date range
                    startDate = Convert.ToDateTime(txtStartDate.Text);
                    endDate = Convert.ToDateTime(txtEndDate.Text);

                    System.Diagnostics.Debug.WriteLine($"🔍 Search Mode: Date Range");
                }

                System.Diagnostics.Debug.WriteLine($"📅 Date Range: {startDate:yyyy-MM-dd HH:mm:ss} to {endDate:yyyy-MM-dd HH:mm:ss}");

                // Show debug info on page
                lblDateRange.Text = $"{startDate:dd/MM/yyyy} - {endDate:dd/MM/yyyy} <small style='color: #999;'>(Debug: {startDate:yyyy-MM-dd} to {endDate:yyyy-MM-dd})</small>";

                // Log revenue calculation request (gracefully handle if System_Logs doesn't exist)
                try
                {
                    loggingService.LogAccountingOperation(
                        "RevenueCalculationRequest",
                        $"Date range: {startDate:yyyy-MM-dd} to {endDate:yyyy-MM-dd}",
                        true,
                        GetCurrentUserId());
                }
                catch { /* Ignore logging errors */ }

                // Calculate revenue by category (always use Normal status, never include Cancel)
                try
                {
                    System.Diagnostics.Debug.WriteLine($"⚙️ Calling CalculateRevenue...");
                    CalculateRevenue(startDate, endDate);
                    System.Diagnostics.Debug.WriteLine($"✅ CalculateRevenue completed");
                }
                catch (Exception calcEx)
                {
                    System.Diagnostics.Debug.WriteLine($"❌ CalculateRevenue failed: {calcEx.Message}");
                    lblDateRange.Text += $" <span style='color: red;'>[CalculateRevenue Error: {calcEx.Message}]</span>";
                    ShowError($"เกิดข้อผิดพลาดในการคำนวณรายได้:\n{calcEx.Message}\n\nStack:\n{calcEx.StackTrace}");
                    // Continue to LoadDetails even if CalculateRevenue fails
                }

                // Load details (show all documents including Cancel)
                System.Diagnostics.Debug.WriteLine($"⚙️ Calling LoadDetails...");
                LoadDetails(startDate, endDate);
                System.Diagnostics.Debug.WriteLine($"✅ LoadDetails completed");

                // Show validation
                try
                {
                    ValidateTotal();
                }
                catch (Exception valEx)
                {
                    System.Diagnostics.Debug.WriteLine($"⚠️ ValidateTotal failed: {valEx.Message}");
                    // Ignore validation errors
                }
            }
            catch (Exception ex)
            {
                // Log exception (gracefully handle if System_Logs doesn't exist)
                try
                {
                    loggingService.LogException(ex, LoggingService.LogCategory.Revenue,
                        "Revenue calculation failed", GetCurrentUserId());
                }
                catch { /* Ignore logging errors */ }

                ShowError("เกิดข้อผิดพลาด: " + ex.Message + "\n\nDetails: " + ex.StackTrace);
            }
        }

        private void CalculateRevenue(DateTime startDate, DateTime endDate)
        {
            try
            {
                System.Diagnostics.Debug.WriteLine($"💰 CalculateRevenue started");

                // Always calculate revenue for Normal status only (exclude Cancel)
                string status = "Normal";

                // Initialize all totals
                decimal cat1Cash = 0, cat1KBANK = 0, cat1KTB = 0, cat1Director = 0;
                decimal cat2Cash = 0, cat2KBANK = 0, cat2KTB = 0, cat2Director = 0;
                decimal cat3Cash = 0, cat3KBANK = 0, cat3KTB = 0, cat3Director = 0;
                decimal cat4Cash = 0, cat4KBANK = 0, cat4KTB = 0, cat4Director = 0;
                decimal totalVAT = 0;
                int docCount = 0;

                // Category 1: Reservations with check-in in date range
                try
                {
                    var cat1Data = GetCategory1Revenue(startDate, endDate, status);
                    System.Diagnostics.Debug.WriteLine($"Category 1 (Payment_History): {cat1Data?.Rows.Count ?? 0} rows");

                    // ⚠️ Fallback: ถ้า Payment_History ไม่มีข้อมูล ให้ใช้ Account_Receipt
                    if (cat1Data == null || cat1Data.Rows.Count == 0)
                    {
                        cat1Data = GetCategory1RevenueFallback(startDate, endDate, status);
                        System.Diagnostics.Debug.WriteLine($"Category 1 (Fallback Account_Receipt): {cat1Data?.Rows.Count ?? 0} rows");
                    }

                    if (cat1Data != null)
                    {
                        cat1Cash = GetAmountByPaymentMethod(cat1Data, 2);
                        cat1KBANK = GetAmountByPaymentMethod(cat1Data, 1);
                        cat1KTB = GetAmountByPaymentMethod(cat1Data, 4);
                        cat1Director = GetAmountByPaymentMethod(cat1Data, 3);
                        System.Diagnostics.Debug.WriteLine($"   Cat1: Cash={cat1Cash:N2}, KBANK={cat1KBANK:N2}, KTB={cat1KTB:N2}, Director={cat1Director:N2}");
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"   ❌ Category 1 failed: {ex.Message}");
                }

                // Category 2: Reservations with payment in date range but check-in outside
                try
                {
                    var cat2Data = GetCategory2Revenue(startDate, endDate, status);
                    System.Diagnostics.Debug.WriteLine($"Category 2 (Payment_History): {cat2Data?.Rows.Count ?? 0} rows");

                    // ⚠️ Fallback: ถ้า Payment_History ไม่มีข้อมูล ให้ใช้ Account_Receipt
                    if (cat2Data == null || cat2Data.Rows.Count == 0)
                    {
                        cat2Data = GetCategory2RevenueFallback(startDate, endDate, status);
                        System.Diagnostics.Debug.WriteLine($"Category 2 (Fallback Account_Receipt): {cat2Data?.Rows.Count ?? 0} rows");
                    }

                    if (cat2Data != null)
                    {
                        cat2Cash = GetAmountByPaymentMethod(cat2Data, 2);
                        cat2KBANK = GetAmountByPaymentMethod(cat2Data, 1);
                        cat2KTB = GetAmountByPaymentMethod(cat2Data, 4);
                        cat2Director = GetAmountByPaymentMethod(cat2Data, 3);
                        System.Diagnostics.Debug.WriteLine($"   Cat2: Cash={cat2Cash:N2}, KBANK={cat2KBANK:N2}, KTB={cat2KTB:N2}, Director={cat2Director:N2}");
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"   ❌ Category 2 failed: {ex.Message}");
                }

                // Category 3: Product sales
                try
                {
                    var cat3Data = GetCategory3Revenue(startDate, endDate, status);
                    System.Diagnostics.Debug.WriteLine($"Category 3: {cat3Data?.Rows.Count ?? 0} rows");

                    if (cat3Data != null)
                    {
                        cat3Cash = GetAmountByPaymentMethod(cat3Data, 2);
                        cat3KBANK = GetAmountByPaymentMethod(cat3Data, 1);
                        cat3KTB = GetAmountByPaymentMethod(cat3Data, 4);
                        cat3Director = GetAmountByPaymentMethod(cat3Data, 3);
                        System.Diagnostics.Debug.WriteLine($"   Cat3: Cash={cat3Cash:N2}, KBANK={cat3KBANK:N2}, KTB={cat3KTB:N2}, Director={cat3Director:N2}");
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"   ❌ Category 3 failed: {ex.Message}");
                }

                // Category 4: Others
                try
                {
                    var cat4Data = GetCategory4Revenue(startDate, endDate, status);
                    System.Diagnostics.Debug.WriteLine($"Category 4: {cat4Data?.Rows.Count ?? 0} rows");

                    if (cat4Data != null)
                    {
                        cat4Cash = GetAmountByPaymentMethod(cat4Data, 2);
                        cat4KBANK = GetAmountByPaymentMethod(cat4Data, 1);
                        cat4KTB = GetAmountByPaymentMethod(cat4Data, 4);
                        cat4Director = GetAmountByPaymentMethod(cat4Data, 3);
                        System.Diagnostics.Debug.WriteLine($"   Cat4: Cash={cat4Cash:N2}, KBANK={cat4KBANK:N2}, KTB={cat4KTB:N2}, Director={cat4Director:N2}");
                    }
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"   ❌ Category 4 failed: {ex.Message}");
                }

                // Update UI - Category 1
                lblCat1Cash.Text = cat1Cash.ToString("N2");
                lblCat1KBANK.Text = cat1KBANK.ToString("N2");
                lblCat1KTB.Text = cat1KTB.ToString("N2");
                lblCat1Director.Text = cat1Director.ToString("N2");
                lblCat1Total.Text = (cat1Cash + cat1KBANK + cat1KTB + cat1Director).ToString("N2");

                // Update UI - Category 2
                lblCat2Cash.Text = cat2Cash.ToString("N2");
                lblCat2KBANK.Text = cat2KBANK.ToString("N2");
                lblCat2KTB.Text = cat2KTB.ToString("N2");
                lblCat2Director.Text = cat2Director.ToString("N2");
                lblCat2Total.Text = (cat2Cash + cat2KBANK + cat2KTB + cat2Director).ToString("N2");

                // Update UI - Category 3
                lblCat3Cash.Text = cat3Cash.ToString("N2");
                lblCat3KBANK.Text = cat3KBANK.ToString("N2");
                lblCat3KTB.Text = cat3KTB.ToString("N2");
                lblCat3Director.Text = cat3Director.ToString("N2");
                lblCat3Total.Text = (cat3Cash + cat3KBANK + cat3KTB + cat3Director).ToString("N2");

                // Update UI - Category 4
                lblCat4Cash.Text = cat4Cash.ToString("N2");
                lblCat4KBANK.Text = cat4KBANK.ToString("N2");
                lblCat4KTB.Text = cat4KTB.ToString("N2");
                lblCat4Director.Text = cat4Director.ToString("N2");
                lblCat4Total.Text = (cat4Cash + cat4KBANK + cat4KTB + cat4Director).ToString("N2");

                // Update UI - Totals
                decimal totalCash = cat1Cash + cat2Cash + cat3Cash + cat4Cash;
                decimal totalKBANK = cat1KBANK + cat2KBANK + cat3KBANK + cat4KBANK;
                decimal totalKTB = cat1KTB + cat2KTB + cat3KTB + cat4KTB;
                decimal totalDirector = cat1Director + cat2Director + cat3Director + cat4Director;

                lblTotalCash.Text = totalCash.ToString("N2");
                lblTotalKBANK.Text = totalKBANK.ToString("N2");
                lblTotalKTB.Text = totalKTB.ToString("N2");
                lblTotalDirector.Text = totalDirector.ToString("N2");
                lblGrandTotal.Text = (totalCash + totalKBANK + totalKTB + totalDirector).ToString("N2");

                System.Diagnostics.Debug.WriteLine($"   💵 Totals: Cash={totalCash:N2}, KBANK={totalKBANK:N2}, KTB={totalKTB:N2}, Director={totalDirector:N2}");
                System.Diagnostics.Debug.WriteLine($"   💰 Grand Total: {(totalCash + totalKBANK + totalKTB + totalDirector):N2}");

                // Get VAT and document count
                try
                {
                    var allData = GetAllReceipts(startDate, endDate, status);
                    if (allData != null)
                    {
                        foreach (DataRow row in allData.Rows)
                        {
                            totalVAT += row["Vat"] != DBNull.Value ? Convert.ToDecimal(row["Vat"]) : 0;
                            docCount++;
                        }
                    }

                    lblTotalVAT.Text = totalVAT.ToString("N2");
                    lblDocCount.Text = docCount.ToString();

                    System.Diagnostics.Debug.WriteLine($"   📄 Documents: {docCount}, VAT: {totalVAT:N2}");
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"   ⚠️ VAT/DocCount calculation failed: {ex.Message}");
                    lblTotalVAT.Text = "0.00";
                    lblDocCount.Text = "0";
                }

                // Log revenue calculation result (gracefully handle logging errors)
                try
                {
                    decimal grandTotal = totalCash + totalKBANK + totalKTB + totalDirector;
                    string breakdown = $"Category 1: {(cat1Cash + cat1KBANK + cat1KTB + cat1Director):N2}\n" +
                                     $"Category 2: {(cat2Cash + cat2KBANK + cat2KTB + cat2Director):N2}\n" +
                                     $"Category 3: {(cat3Cash + cat3KBANK + cat3KTB + cat3Director):N2}\n" +
                                     $"Category 4: {(cat4Cash + cat4KBANK + cat4KTB + cat4Director):N2}\n" +
                                     $"Total Cash: {totalCash:N2}\n" +
                                     $"Total KBANK: {totalKBANK:N2}\n" +
                                     $"Total KTB: {totalKTB:N2}\n" +
                                     $"Total Director: {totalDirector:N2}\n" +
                                     $"Document Count: {docCount}\n" +
                                     $"Total VAT: {totalVAT:N2}";

                    loggingService.LogRevenueCalculation(startDate, endDate, grandTotal, breakdown, GetCurrentUserId());
                }
                catch (Exception logEx)
                {
                    System.Diagnostics.Debug.WriteLine($"   ⚠️ Logging failed (ignored): {logEx.Message}");
                }

                System.Diagnostics.Debug.WriteLine($"✅ CalculateRevenue completed successfully");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ CalculateRevenue FAILED: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"   Stack: {ex.StackTrace}");
                throw; // Re-throw to be caught by outer try-catch in btnSearch_Click
            }
        }

        private DataTable GetCategory1Revenue(DateTime startDate, DateTime endDate, string status)
        {
            // Reservations with check-in in date range
            // Use Payment_History to get accurate amounts per payment method
            // Only count Payment_History that links to valid receipts
            string query = @"
                SELECT DISTINCT ph.ID as PaymentHistoryID, ph.PaymentMethod, ph.PaymentAmount, ar.ID as ReceiptID
                FROM Payment_History ph
                INNER JOIN Reservation r ON ph.Reservation_ID = r.ID
                INNER JOIN Account_Receipt ar ON ph.Receipt_ID = ar.ID
                WHERE CAST(r.CheckinDate AS DATE) >= CAST(@StartDate AS DATE)
                  AND CAST(r.CheckinDate AS DATE) <= CAST(@EndDate AS DATE)
                  AND ar.Status LIKE @Status
                  AND ph.Status = 'COMPLETED'
                  AND ph.Receipt_ID IS NOT NULL
                  AND ar.Reservation_ID > 0";

            var parameters = new Dictionary<string, object>
            {
                { "@StartDate", startDate },
                { "@EndDate", endDate },
                { "@Status", status }
            };

            return codeInstance.DatabaseQuerySafe(conn, query, parameters);
        }

        private DataTable GetCategory2Revenue(DateTime startDate, DateTime endDate, string status)
        {
            // Reservations with receipt created in date range but check-in outside
            // Use Payment_History to get accurate amounts per payment method
            // Only count Payment_History that links to valid receipts
            string query = @"
                SELECT DISTINCT ph.ID as PaymentHistoryID, ph.PaymentMethod, ph.PaymentAmount, ar.ID as ReceiptID
                FROM Payment_History ph
                INNER JOIN Reservation r ON ph.Reservation_ID = r.ID
                INNER JOIN Account_Receipt ar ON ph.Receipt_ID = ar.ID
                WHERE CAST(ar.Created_Date AS DATE) >= CAST(@StartDate AS DATE)
                  AND CAST(ar.Created_Date AS DATE) <= CAST(@EndDate AS DATE)
                  AND (CAST(r.CheckinDate AS DATE) < CAST(@StartDate AS DATE)
                       OR CAST(r.CheckinDate AS DATE) > CAST(@EndDate AS DATE)
                       OR r.CheckinDate IS NULL)
                  AND ar.Status LIKE @Status
                  AND ph.Status = 'COMPLETED'
                  AND ph.Receipt_ID IS NOT NULL
                  AND ar.Reservation_ID > 0";

            var parameters = new Dictionary<string, object>
            {
                { "@StartDate", startDate },
                { "@EndDate", endDate },
                { "@Status", status }
            };

            return codeInstance.DatabaseQuerySafe(conn, query, parameters);
        }

        private DataTable GetCategory3Revenue(DateTime startDate, DateTime endDate, string status)
        {
            // Product sales (ProductType_ID = 3) - Non-reservation items
            // Note: For non-reservation items, we still use Account_Receipt since Payment_History
            // is only for reservations. We return individual payment methods split from Paid_Type.
            string query = @"
                SELECT ar.ID, ar.Paid_Type, ar.Total_Amount
                FROM Account_Receipt ar
                INNER JOIN Account_Receipt_Detail ard ON ar.ID = ard.Receipt_ID
                WHERE CAST(ar.Created_Date AS DATE) >= CAST(@StartDate AS DATE)
                  AND CAST(ar.Created_Date AS DATE) <= CAST(@EndDate AS DATE)
                  AND ard.ProductType_ID = 3
                  AND ar.Status LIKE @Status
                  AND (ar.Reservation_ID = 0 OR ar.Reservation_ID IS NULL)";

            var parameters = new Dictionary<string, object>
            {
                { "@StartDate", startDate },
                { "@EndDate", endDate },
                { "@Status", status }
            };

            return codeInstance.DatabaseQuerySafe(conn, query, parameters);
        }

        private DataTable GetCategory4Revenue(DateTime startDate, DateTime endDate, string status)
        {
            // Others (not in categories 1-3) - Non-reservation items
            // Note: For non-reservation items, we still use Account_Receipt since Payment_History
            // is only for reservations. We return individual payment methods split from Paid_Type.
            string query = @"
                SELECT ar.ID, ar.Paid_Type, ar.Total_Amount
                FROM Account_Receipt ar
                LEFT JOIN Account_Receipt_Detail ard ON ar.ID = ard.Receipt_ID
                WHERE CAST(ar.Created_Date AS DATE) >= CAST(@StartDate AS DATE)
                  AND CAST(ar.Created_Date AS DATE) <= CAST(@EndDate AS DATE)
                  AND ar.Status LIKE @Status
                  AND (ar.Reservation_ID = 0 OR ar.Reservation_ID IS NULL)
                  AND (ard.ProductType_ID IS NULL OR ard.ProductType_ID != 3)";

            var parameters = new Dictionary<string, object>
            {
                { "@StartDate", startDate },
                { "@EndDate", endDate },
                { "@Status", status }
            };

            return codeInstance.DatabaseQuerySafe(conn, query, parameters);
        }

        /// <summary>
        /// Fallback: ดึงข้อมูล Category 1 จาก Account_Receipt ถ้า Payment_History ไม่มีข้อมูล
        /// </summary>
        private DataTable GetCategory1RevenueFallback(DateTime startDate, DateTime endDate, string status)
        {
            // ใช้ Account_Receipt สำหรับระบบเก่าที่ยังไม่มี Payment_History
            string query = @"
                SELECT ar.ID, ar.Paid_Type, ar.Total_Amount
                FROM Account_Receipt ar
                INNER JOIN Reservation r ON ar.Reservation_ID = r.ID
                WHERE CAST(r.CheckinDate AS DATE) >= CAST(@StartDate AS DATE)
                  AND CAST(r.CheckinDate AS DATE) <= CAST(@EndDate AS DATE)
                  AND ar.Status LIKE @Status
                  AND ar.Reservation_ID > 0";

            var parameters = new Dictionary<string, object>
            {
                { "@StartDate", startDate },
                { "@EndDate", endDate },
                { "@Status", status }
            };

            return codeInstance.DatabaseQuerySafe(conn, query, parameters);
        }

        /// <summary>
        /// Fallback: ดึงข้อมูล Category 2 จาก Account_Receipt ถ้า Payment_History ไม่มีข้อมูล
        /// </summary>
        private DataTable GetCategory2RevenueFallback(DateTime startDate, DateTime endDate, string status)
        {
            // ใช้ Account_Receipt สำหรับระบบเก่าที่ยังไม่มี Payment_History
            string query = @"
                SELECT ar.ID, ar.Paid_Type, ar.Total_Amount
                FROM Account_Receipt ar
                INNER JOIN Reservation r ON ar.Reservation_ID = r.ID
                WHERE CAST(ar.Created_Date AS DATE) >= CAST(@StartDate AS DATE)
                  AND CAST(ar.Created_Date AS DATE) <= CAST(@EndDate AS DATE)
                  AND (CAST(r.CheckinDate AS DATE) < CAST(@StartDate AS DATE)
                       OR CAST(r.CheckinDate AS DATE) > CAST(@EndDate AS DATE)
                       OR r.CheckinDate IS NULL)
                  AND ar.Status LIKE @Status
                  AND ar.Reservation_ID > 0
                  AND ar.IsDeposit = 1";

            var parameters = new Dictionary<string, object>
            {
                { "@StartDate", startDate },
                { "@EndDate", endDate },
                { "@Status", status }
            };

            return codeInstance.DatabaseQuerySafe(conn, query, parameters);
        }

        private decimal GetAmountByPaymentMethod(DataTable dt, int paymentMethodID)
        {
            // Legacy payment method mapping (hard-coded, no table lookup needed)
            // 1 = KBANK (โอนกสิกร), 2 = CASH (เงินสด), 3 = DIRECTOR (เงินกรรมการ), 4 = KTB (โอนกรุงไทย)
            string paymentMethodName = GetPaymentMethodNameByLegacyId(paymentMethodID);
            if (string.IsNullOrEmpty(paymentMethodName))
            {
                return 0;
            }

            decimal total = 0;
            HashSet<string> processedPayments = new HashSet<string>(); // Track processed payments to avoid duplicates

            foreach (DataRow row in dt.Rows)
            {
                // Check if this is Payment_History data (has PaymentHistoryID column)
                if (dt.Columns.Contains("PaymentHistoryID"))
                {
                    // Category 1-2: Use Payment_History data (already split by payment method)
                    string paymentHistoryID = row["PaymentHistoryID"]?.ToString() ?? "";
                    string paymentMethod = row["PaymentMethod"]?.ToString() ?? "";

                    // Avoid counting same Payment_History row multiple times
                    if (!string.IsNullOrEmpty(paymentHistoryID) &&
                        !processedPayments.Contains(paymentHistoryID) &&
                        paymentMethod.Contains(paymentMethodName))
                    {
                        decimal amount = row["PaymentAmount"] != DBNull.Value ?
                            Convert.ToDecimal(row["PaymentAmount"]) : 0;
                        total += amount;
                        processedPayments.Add(paymentHistoryID);
                    }
                }
                else
                {
                    // Category 3-4: Use Account_Receipt data (need to split if multiple payment methods)
                    string receiptId = row["ID"]?.ToString() ?? "";
                    string paidType = row["Paid_Type"]?.ToString() ?? "";
                    decimal receiptAmount = row["Total_Amount"] != DBNull.Value ?
                        Convert.ToDecimal(row["Total_Amount"]) : 0;

                    // Check if this payment method is in the Paid_Type using simple string matching
                    if (!string.IsNullOrEmpty(paidType) && paidType.Contains(paymentMethodName))
                    {
                        // Only count this receipt once per payment method
                        string uniqueKey = $"{receiptId}_{paymentMethodName}";
                        if (!processedPayments.Contains(uniqueKey))
                        {
                            // If multiple payment methods (comma-separated), split the amount evenly
                            int methodCount = paidType.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries).Length;
                            decimal amountForThisMethod = methodCount > 1 ? receiptAmount / methodCount : receiptAmount;
                            total += amountForThisMethod;
                            processedPayments.Add(uniqueKey);
                        }
                    }
                }
            }
            return total;
        }

        private DataTable GetAllReceipts(DateTime startDate, DateTime endDate, string status)
        {
            // Show receipts created in the date range only
            // Note: This may not match revenue totals because:
            // - Category 1 includes receipts where CheckinDate is in range (even if Created_Date is outside)
            // - This detail list only shows receipts where Created_Date is in range
            string query = @"
                SELECT ar.ID, ar.Reservation_ID, ar.Created_Date, ar.Paid_Type,
                       ar.Total_Amount, ar.Vat, ar.IsDeposit, ar.UseDeposit,
                       ar.Status,
                       c.FullName as CustomerName,
                       r.Customer_MobilePhone,
                       r.Remark,
                       a.Username as Created_By
                FROM Account_Receipt ar
                LEFT JOIN Reservation r ON ar.Reservation_ID = r.ID
                LEFT JOIN Customer c ON r.Customer_MobilePhone = c.MobilePhone
                LEFT JOIN Admin a ON ar.Created_By_ID = a.ID
                WHERE CAST(ar.Created_Date AS DATE) >= CAST(@StartDate AS DATE)
                  AND CAST(ar.Created_Date AS DATE) <= CAST(@EndDate AS DATE)
                  AND ar.Status LIKE @Status
                ORDER BY ar.ID ASC";

            var parameters = new Dictionary<string, object>
            {
                { "@StartDate", startDate },
                { "@EndDate", endDate },
                { "@Status", status }
            };

            System.Diagnostics.Debug.WriteLine($"📋 GetAllReceipts Query:");
            System.Diagnostics.Debug.WriteLine($"   @StartDate = {startDate:yyyy-MM-dd HH:mm:ss}");
            System.Diagnostics.Debug.WriteLine($"   @EndDate = {endDate:yyyy-MM-dd HH:mm:ss}");
            System.Diagnostics.Debug.WriteLine($"   @Status = {status}");

            var result = codeInstance.DatabaseQuerySafe(conn, query, parameters);
            System.Diagnostics.Debug.WriteLine($"   ✅ Result: {result?.Rows.Count ?? 0} rows");

            // If no results, try a simpler query to see if there's ANY data
            if (result == null || result.Rows.Count == 0)
            {
                System.Diagnostics.Debug.WriteLine($"   ⚠️ No results from main query. Running diagnostic queries...");

                // Test 1: Count all receipts (no filters)
                var allQuery = "SELECT COUNT(*) as Total FROM Account_Receipt";
                var allResult = codeInstance.DatabaseQuerySafe(conn, allQuery, new Dictionary<string, object>());
                System.Diagnostics.Debug.WriteLine($"   🔍 Total receipts in database (no filter): {allResult?.Rows[0]["Total"]}");

                // Test 2: Count receipts in date range (any status)
                var testQuery = "SELECT COUNT(*) as Total FROM Account_Receipt ar WHERE CAST(ar.Created_Date AS DATE) >= CAST(@StartDate AS DATE) AND CAST(ar.Created_Date AS DATE) <= CAST(@EndDate AS DATE)";
                var testResult = codeInstance.DatabaseQuerySafe(conn, testQuery, parameters);
                System.Diagnostics.Debug.WriteLine($"   🔍 Total receipts in date range (any status): {testResult?.Rows[0]["Total"]}");

                // Test 3: Count receipts with matching status (any date)
                var statusQuery = "SELECT COUNT(*) as Total FROM Account_Receipt ar WHERE ar.Status LIKE @Status";
                var statusParams = new Dictionary<string, object> { { "@Status", status } };
                var statusResult = codeInstance.DatabaseQuerySafe(conn, statusQuery, statusParams);
                System.Diagnostics.Debug.WriteLine($"   🔍 Total receipts with status '{status}' (any date): {statusResult?.Rows[0]["Total"]}");

                // Test 4: Get sample receipts without date filter
                var sampleQuery = "SELECT TOP 5 ID, Created_Date, Status FROM Account_Receipt ORDER BY Created_Date DESC";
                var sampleResult = codeInstance.DatabaseQuerySafe(conn, sampleQuery, new Dictionary<string, object>());
                System.Diagnostics.Debug.WriteLine($"   🔍 Sample receipts (latest 5):");
                if (sampleResult != null)
                {
                    foreach (DataRow row in sampleResult.Rows)
                    {
                        System.Diagnostics.Debug.WriteLine($"      - ID: {row["ID"]}, Created: {row["Created_Date"]}, Status: {row["Status"]}");
                    }
                }

                // Test 5: Try simple query without JOINs
                var simpleQuery = @"
                    SELECT ar.ID, ar.Reservation_ID, ar.Created_Date, ar.Paid_Type,
                           ar.Total_Amount, ar.Vat, ar.Status
                    FROM Account_Receipt ar
                    WHERE CAST(ar.Created_Date AS DATE) >= CAST(@StartDate AS DATE)
                      AND CAST(ar.Created_Date AS DATE) <= CAST(@EndDate AS DATE)
                      AND ar.Status LIKE @Status
                    ORDER BY ar.ID ASC";
                var simpleResult = codeInstance.DatabaseQuerySafe(conn, simpleQuery, parameters);
                System.Diagnostics.Debug.WriteLine($"   🔍 Simple query (no JOINs): {simpleResult?.Rows.Count ?? 0} rows");

                // If simple query works but main query doesn't, it's a JOIN issue
                if (simpleResult != null && simpleResult.Rows.Count > 0 && (result == null || result.Rows.Count == 0))
                {
                    System.Diagnostics.Debug.WriteLine($"   ⚠️ JOIN is causing the issue! Using simple result instead.");
                    return simpleResult;
                }
            }

            return result;
        }

        private void LoadDetails(DateTime startDate, DateTime endDate)
        {
            DataTable dt = null;
            try
            {
                System.Diagnostics.Debug.WriteLine($"📊 LoadDetails called:");
                System.Diagnostics.Debug.WriteLine($"   Start: {startDate:yyyy-MM-dd HH:mm:ss}");
                System.Diagnostics.Debug.WriteLine($"   End: {endDate:yyyy-MM-dd HH:mm:ss}");

                // Always show all documents (both Normal and Cancel) in GridView
                try
                {
                    dt = GetAllReceipts(startDate, endDate, "%");
                    System.Diagnostics.Debug.WriteLine($"   Retrieved {dt?.Rows.Count ?? 0} rows from GetAllReceipts");
                }
                catch (Exception queryEx)
                {
                    System.Diagnostics.Debug.WriteLine($"   ❌ GetAllReceipts failed: {queryEx.Message}");
                    lblDateRange.Text += $" <span style='color: red;'>[Query Error: {queryEx.Message}]</span>";
                    throw;
                }

                // Debug: Add message to date range label (ALWAYS execute this)
                if (dt != null && dt.Rows.Count > 0)
                {
                    lblDateRange.Text += $" <span style='color: green; font-weight: bold;'>(✓ พบ {dt.Rows.Count} เอกสาร)</span>";
                    System.Diagnostics.Debug.WriteLine($"   ✅ Showing {dt.Rows.Count} documents in GridView");
                }
                else
                {
                    lblDateRange.Text += $" <span style='color: red; font-weight: bold;'>(⚠️ ไม่พบเอกสาร)</span>";
                    System.Diagnostics.Debug.WriteLine($"   ⚠️ No documents found!");

                    // Get diagnostic info to show on page
                    string diagInfo = "";
                    try
                    {
                        // Count all receipts
                        var allQuery = "SELECT COUNT(*) as Total FROM Account_Receipt";
                        var allResult = codeInstance.DatabaseQuerySafe(conn, allQuery, new Dictionary<string, object>());
                        int totalReceipts = allResult != null ? Convert.ToInt32(allResult.Rows[0]["Total"]) : 0;

                        // Count in date range
                        var testQuery = "SELECT COUNT(*) as Total FROM Account_Receipt ar WHERE CAST(ar.Created_Date AS DATE) >= CAST(@StartDate AS DATE) AND CAST(ar.Created_Date AS DATE) <= CAST(@EndDate AS DATE)";
                        var testParams = new Dictionary<string, object> { { "@StartDate", startDate }, { "@EndDate", endDate } };
                        var testResult = codeInstance.DatabaseQuerySafe(conn, testQuery, testParams);
                        int inRange = testResult != null ? Convert.ToInt32(testResult.Rows[0]["Total"]) : 0;

                        // Get latest receipt date
                        var latestQuery = "SELECT TOP 1 Created_Date FROM Account_Receipt ORDER BY Created_Date DESC";
                        var latestResult = codeInstance.DatabaseQuerySafe(conn, latestQuery, new Dictionary<string, object>());
                        string latestDate = latestResult != null && latestResult.Rows.Count > 0 ?
                            Convert.ToDateTime(latestResult.Rows[0]["Created_Date"]).ToString("dd/MM/yyyy") : "ไม่มี";

                        diagInfo = $"\n\nข้อมูลเพิ่มเติม:\n- มีเอกสารทั้งหมดในระบบ: {totalReceipts} รายการ\n- มีเอกสารในช่วง {startDate:dd/MM/yyyy} - {endDate:dd/MM/yyyy}: {inRange} รายการ\n- เอกสารล่าสุดสร้างวันที่: {latestDate}";

                        System.Diagnostics.Debug.WriteLine($"   📊 Diagnostic: Total={totalReceipts}, InRange={inRange}, Latest={latestDate}");
                    }
                    catch (Exception diagEx)
                    {
                        System.Diagnostics.Debug.WriteLine($"   ⚠️ Diagnostic query failed: {diagEx.Message}");
                        diagInfo = "\n\n(ไม่สามารถดึงข้อมูลสถิติได้)";
                    }

                    // Show helpful message to user
                    ShowError($"ไม่พบเอกสารในช่วง {startDate:dd/MM/yyyy} - {endDate:dd/MM/yyyy}{diagInfo}\n\nกรุณาตรวจสอบ:\n1. เลือกช่วงวันที่ที่มีเอกสาร\n2. วันที่ที่เลือกถูกต้องหรือไม่\n3. ตรวจสอบ Debug Output สำหรับรายละเอียดเพิ่มเติม");
                }

                // Bind to GridView
                gvDetails.DataSource = dt;
                gvDetails.DataBind();
                System.Diagnostics.Debug.WriteLine($"   ✅ GridView.DataBind() completed");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"   ❌ Error in LoadDetails: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"   Stack: {ex.StackTrace}");
                lblDateRange.Text += $" <span style='color: red; font-weight: bold;'>[LoadDetails Error: {ex.Message}]</span>";
                ShowError($"เกิดข้อผิดพลาดในการโหลดข้อมูล:\n{ex.Message}\n\nStack Trace:\n{ex.StackTrace}");

                // Try to bind empty DataTable to prevent further errors
                try
                {
                    gvDetails.DataSource = new DataTable();
                    gvDetails.DataBind();
                }
                catch { }
            }
        }

        private void ValidateTotal()
        {
            // Validate that sum of categories equals grand total
            decimal cat1 = Convert.ToDecimal(lblCat1Total.Text);
            decimal cat2 = Convert.ToDecimal(lblCat2Total.Text);
            decimal cat3 = Convert.ToDecimal(lblCat3Total.Text);
            decimal cat4 = Convert.ToDecimal(lblCat4Total.Text);
            decimal calculated = cat1 + cat2 + cat3 + cat4;

            decimal grandTotal = Convert.ToDecimal(lblGrandTotal.Text);

            pnlValidation.Visible = true;

            if (Math.Abs(calculated - grandTotal) < 0.01m)
            {
                pnlValidation.CssClass = "validation-box validation-success";
                lblValidationIcon.Text = "✅";
                lblValidationMessage.Text = $"ยอดถูกต้อง: ยอดรวมทั้งหมด {grandTotal:N2} บาท (หมวด 1+2+3+4 = {calculated:N2} บาท)";
            }
            else
            {
                pnlValidation.CssClass = "validation-box validation-error";
                lblValidationIcon.Text = "⚠️";
                lblValidationMessage.Text = $"ยอดไม่ตรง! ยอดรวม {grandTotal:N2} บาท แต่ผลรวมหมวด {calculated:N2} บาท (ต่าง {Math.Abs(calculated - grandTotal):N2} บาท)";
            }
        }

        protected void btnExport_Click(object sender, EventArgs e)
        {
            try
            {
                DateTime startDate, endDate;

                // Determine date range
                if (ddlMonth.SelectedIndex > 0 && !string.IsNullOrEmpty(ddlYear.SelectedValue))
                {
                    int month = Convert.ToInt32(ddlMonth.SelectedValue);
                    int year = Convert.ToInt32(ddlYear.SelectedValue);
                    startDate = new DateTime(year, month, 1);
                    endDate = startDate.AddMonths(1).AddDays(-1);
                }
                else
                {
                    startDate = Convert.ToDateTime(txtStartDate.Text);
                    endDate = Convert.ToDateTime(txtEndDate.Text);
                }

                // Create CSV content
                StringBuilder csv = new StringBuilder();

                // Add BOM for UTF-8 Excel compatibility
                csv.Append("\uFEFF");

                // Header
                csv.AppendLine("สรุปรายได้ตามหมวด");
                csv.AppendLine($"ช่วงวันที่:,{startDate:dd/MM/yyyy} - {endDate:dd/MM/yyyy}");
                csv.AppendLine($"การคำนวณยอด:,คำนวณเฉพาะเอกสารปกติ (ไม่รวมยกเลิก)");
                csv.AppendLine($"รายละเอียดเอกสาร:,แสดงทั้งหมด (รวมยกเลิก)");
                csv.AppendLine($"วันที่ออกรายงาน:,{DateTime.Now:dd/MM/yyyy HH:mm:ss}");
                csv.AppendLine();

                // Summary table
                csv.AppendLine("หมวดรายได้,เงินสด,โอนกสิกร,โอนกรุงไทย,เงินกรรมการ,รวม");
                csv.AppendLine($"1. จองพัก (เช็คอินในช่วง),{lblCat1Cash.Text},{lblCat1KBANK.Text},{lblCat1KTB.Text},{lblCat1Director.Text},{lblCat1Total.Text}");
                csv.AppendLine($"2. จองพัก (โอนในช่วง),{lblCat2Cash.Text},{lblCat2KBANK.Text},{lblCat2KTB.Text},{lblCat2Director.Text},{lblCat2Total.Text}");
                csv.AppendLine($"3. ขายสินค้า,{lblCat3Cash.Text},{lblCat3KBANK.Text},{lblCat3KTB.Text},{lblCat3Director.Text},{lblCat3Total.Text}");
                csv.AppendLine($"4. อื่นๆ,{lblCat4Cash.Text},{lblCat4KBANK.Text},{lblCat4KTB.Text},{lblCat4Director.Text},{lblCat4Total.Text}");
                csv.AppendLine($"รวมทั้งหมด,{lblTotalCash.Text},{lblTotalKBANK.Text},{lblTotalKTB.Text},{lblTotalDirector.Text},{lblGrandTotal.Text}");
                csv.AppendLine();

                // Additional info
                csv.AppendLine($"จำนวนเอกสาร (เฉพาะปกติ):,{lblDocCount.Text}");
                csv.AppendLine($"ยอดรวม VAT (เฉพาะปกติ):,{lblTotalVAT.Text}");
                csv.AppendLine();

                // Detail records (show all including Cancel)
                var dt = GetAllReceipts(startDate, endDate, "%");
                csv.AppendLine("รายละเอียดเอกสาร");
                csv.AppendLine("เลขที่เอกสาร,รหัสจอง,วันที่,ชื่อลูกค้า,เบอร์โทร,วิธีชำระ,ยอดรวม,VAT,มัดจำ,ใช้มัดจำ,สถานะ,หมายเหตุ,ผู้สร้าง");

                foreach (DataRow row in dt.Rows)
                {
                    string docId = row["ID"]?.ToString() ?? "";
                    string reservationId = row["Reservation_ID"]?.ToString() ?? "";
                    string date = row["Created_Date"] != DBNull.Value ? Convert.ToDateTime(row["Created_Date"]).ToString("dd/MM/yyyy HH:mm") : "";
                    string customer = row["CustomerName"]?.ToString() ?? "-";
                    string phone = row["Customer_MobilePhone"]?.ToString() ?? "";
                    string paidType = row["Paid_Type"]?.ToString() ?? "";
                    string amount = row["Total_Amount"] != DBNull.Value ? Convert.ToDecimal(row["Total_Amount"]).ToString("N2") : "0.00";
                    string vat = row["Vat"] != DBNull.Value ? Convert.ToDecimal(row["Vat"]).ToString("N2") : "0.00";
                    string isDeposit = row["IsDeposit"]?.ToString() ?? "";
                    string useDeposit = row["UseDeposit"]?.ToString() ?? "";
                    string status = row["Status"]?.ToString() ?? "";
                    string remark = row["Remark"]?.ToString() ?? "";
                    string createdBy = row["Created_By"]?.ToString() ?? "";

                    csv.AppendLine($"{docId},{reservationId},{date},{customer},{phone},{paidType},{amount},{vat},{isDeposit},{useDeposit},{status},{remark},{createdBy}");
                }

                // Send file to browser
                Response.Clear();
                Response.ContentType = "text/csv";
                Response.ContentEncoding = Encoding.UTF8;
                Response.Charset = "UTF-8";
                Response.AddHeader("Content-Disposition", $"attachment;filename=รายงานรายได้_{startDate:yyyyMMdd}_{endDate:yyyyMMdd}.csv");
                Response.Write(csv.ToString());
                Response.End();
            }
            catch (Exception ex)
            {
                ShowError("เกิดข้อผิดพลาดในการ export: " + ex.Message);
            }
        }

        // GridView Event Handlers
        protected void gvDetails_RowDeleting(object sender, GridViewDeleteEventArgs e)
        {
            if (!chkEnableDelete.Checked)
            {
                ShowError("กรุณาเปิดใช้งานปุ่มลบก่อน");
                return;
            }

            try
            {
                string docNum = gvDetails.Rows[e.RowIndex].Cells[3].Text;
                string docType = docNum.Remove(3, 9);
                string docYear = "20" + docNum.Remove(0, 3).Remove(2, 7);
                string docMonth = Convert.ToInt32(docNum.Remove(0, 5).Remove(2, 5)).ToString();

                if (docType.Length > 3)
                {
                    docType = docNum.Remove(3, 12);
                    docYear = "20" + docNum.Remove(0, 3).Remove(2, 10);
                    docMonth = Convert.ToInt32(docNum.Remove(0, 5).Remove(2, 8)).ToString();
                }

                if (docType == "REC")
                {
                    string path = ConfigurationManager.AppSettings["ReceiptFolderPath"] + "\\" + docYear + "\\" + docMonth;

                    // Delete Payment_History records first
                    codeInstance.DatabaseInsert(conn, "DELETE FROM [dbo].[Payment_History] WHERE Receipt_ID = '" + docNum + "'");

                    // Delete receipt details
                    codeInstance.DatabaseInsert(conn, "DELETE FROM [dbo].[Account_Receipt_Detail] WHERE Receipt_ID = '" + docNum + "'");

                    // Delete receipt record
                    codeInstance.DatabaseInsert(conn, "DELETE FROM [dbo].[Account_Receipt] WHERE ID = '" + docNum + "'");

                    // Delete receipt files
                    if (Directory.Exists(path))
                    {
                        string[] files = Directory.GetFiles(path, docNum + "*");
                        foreach (string file in files)
                        {
                            File.Delete(file);
                        }
                    }
                }
                else if (docType == "PAY")
                {
                    string path = ConfigurationManager.AppSettings["PaymentFolderPath"] + "\\" + docYear + "\\" + docMonth;

                    // Delete payment details
                    codeInstance.DatabaseInsert(conn, "DELETE FROM [dbo].[Account_Payment_Detail] WHERE Payment_ID = '" + docNum + "'");

                    // Delete payment record
                    codeInstance.DatabaseInsert(conn, "DELETE FROM [dbo].[Account_Payment] WHERE ID = '" + docNum + "'");

                    // Delete payment files
                    if (Directory.Exists(path))
                    {
                        string[] files = Directory.GetFiles(path, docNum + "*");
                        foreach (string file in files)
                        {
                            File.Delete(file);
                        }
                    }
                }

                Response.Redirect("/Account/CheckDocument_New");
            }
            catch (Exception ex)
            {
                ShowError("ลบเอกสารไม่สำเร็จ: " + ex.Message);
            }
        }

        protected void gvDetails_SelectedIndexChanging(object sender, GridViewSelectEventArgs e)
        {
            try
            {
                string docStatus = gvDetails.Rows[e.NewSelectedIndex].Cells[13].Text; // Status column
                string docNum = gvDetails.Rows[e.NewSelectedIndex].Cells[3].Text; // ID column

                System.Diagnostics.Debug.WriteLine($"📄 Opening document: {docNum}, Status: {docStatus}");

                // Parse document type, year, and month from document number
                string docType = docNum.Length >= 3 ? docNum.Substring(0, 3) : "";
                string docYear = "";
                string docMonth = "";

                // Format: REC2410-0001 or REC241030-0001
                if (docNum.Length >= 9) // REC2410-0001 format (8 chars before dash)
                {
                    docYear = "20" + docNum.Substring(3, 2); // REC24 → 2024
                    docMonth = docNum.Substring(5, 2); // REC2410 → 10
                }
                else
                {
                    throw new Exception($"Invalid document number format: {docNum}");
                }

                System.Diagnostics.Debug.WriteLine($"   Parsed: Type={docType}, Year={docYear}, Month={docMonth}");

                if (docType == "REC")
                {
                    // Get receipt UID from database
                    string path = ConfigurationManager.AppSettings["ReceiptFolderPath"];
                    var uidResult = codeInstance.DatabaseQuery(conn,
                        "SELECT [UID] FROM [dbo].[Account_Receipt] WHERE ID = '" + docNum + "'");

                    string uid = "";
                    if (uidResult != null && uidResult.Rows.Count > 0 && uidResult.Rows[0][0] != DBNull.Value)
                    {
                        uid = uidResult.Rows[0][0].ToString();
                    }

                    System.Diagnostics.Debug.WriteLine($"   UID from DB: '{uid}'");

                    // Build file paths in priority order
                    List<string> filesToCheck = new List<string>();

                    if (docStatus == "Cancel")
                    {
                        // For Cancel status: Try UID version first, then fallback
                        if (!string.IsNullOrEmpty(uid))
                        {
                            filesToCheck.Add($"{path}\\{docYear}\\{docMonth}\\{docNum}_{uid}_Cancel.pdf");
                        }
                        filesToCheck.Add($"{path}\\{docYear}\\{docMonth}\\{docNum}_Cancel.pdf");
                    }
                    else
                    {
                        // For Normal status: Try UID version first, then fallback
                        if (!string.IsNullOrEmpty(uid))
                        {
                            filesToCheck.Add($"{path}\\{docYear}\\{docMonth}\\{docNum}_{uid}.pdf");
                        }
                        filesToCheck.Add($"{path}\\{docYear}\\{docMonth}\\{docNum}.pdf");
                    }

                    // Check each file and redirect to the first one that exists
                    foreach (var filePath in filesToCheck)
                    {
                        System.Diagnostics.Debug.WriteLine($"   Checking: {filePath}");
                        if (File.Exists(filePath))
                        {
                            string relativeUrl = filePath.Replace(path, "/Documents/Receipt").Replace("\\", "/");
                            System.Diagnostics.Debug.WriteLine($"   ✅ Found! Redirecting to: {relativeUrl}");
                            Response.Redirect(relativeUrl);
                            return;
                        }
                    }

                    // If no file found, show error
                    throw new Exception($"ไม่พบไฟล์ PDF สำหรับเอกสาร {docNum}\n\nตรวจสอบแล้ว:\n{string.Join("\n", filesToCheck)}");
                }
                else if (docType == "PAY")
                {
                    // Get payment UID from database
                    string path = ConfigurationManager.AppSettings["PaymentFolderPath"];
                    var uidResult = codeInstance.DatabaseQuery(conn,
                        "SELECT [UID] FROM [dbo].[Account_Payment] WHERE ID = '" + docNum + "'");

                    string uid = "";
                    if (uidResult != null && uidResult.Rows.Count > 0 && uidResult.Rows[0][0] != DBNull.Value)
                    {
                        uid = uidResult.Rows[0][0].ToString();
                    }

                    System.Diagnostics.Debug.WriteLine($"   UID from DB: '{uid}'");

                    // Build file paths in priority order
                    List<string> filesToCheck = new List<string>();

                    if (docStatus == "Cancel")
                    {
                        // For Cancel status: Try UID version first, then fallback
                        if (!string.IsNullOrEmpty(uid))
                        {
                            filesToCheck.Add($"{path}\\{docYear}\\{docMonth}\\{docNum}_{uid}_Cancel.pdf");
                        }
                        filesToCheck.Add($"{path}\\{docYear}\\{docMonth}\\{docNum}_Cancel.pdf");
                    }
                    else
                    {
                        // For Normal status: Try UID version first, then fallback
                        if (!string.IsNullOrEmpty(uid))
                        {
                            filesToCheck.Add($"{path}\\{docYear}\\{docMonth}\\{docNum}_{uid}.pdf");
                        }
                        filesToCheck.Add($"{path}\\{docYear}\\{docMonth}\\{docNum}.pdf");
                    }

                    // Check each file and redirect to the first one that exists
                    foreach (var filePath in filesToCheck)
                    {
                        System.Diagnostics.Debug.WriteLine($"   Checking: {filePath}");
                        if (File.Exists(filePath))
                        {
                            string relativeUrl = filePath.Replace(path, "/Documents/Payment").Replace("\\", "/");
                            System.Diagnostics.Debug.WriteLine($"   ✅ Found! Redirecting to: {relativeUrl}");
                            Response.Redirect(relativeUrl);
                            return;
                        }
                    }

                    // If no file found, show error
                    throw new Exception($"ไม่พบไฟล์ PDF สำหรับเอกสาร {docNum}\n\nตรวจสอบแล้ว:\n{string.Join("\n", filesToCheck)}");
                }
                else
                {
                    throw new Exception($"ประเภทเอกสารไม่ถูกต้อง: {docType}");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"   ❌ Error: {ex.Message}");
                ShowError("เปิดเอกสารไม่สำเร็จ:\n" + ex.Message);
            }
        }

        protected void gvDetails_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName == "edit")
            {
                try
                {
                    int rowIndex = Convert.ToInt32(e.CommandArgument);
                    string docNum = gvDetails.Rows[rowIndex].Cells[3].Text;
                    string docType = docNum.Remove(3, 9);

                    if (docType.Length > 3)
                    {
                        docType = docNum.Remove(3, 12);
                    }

                    if (docType == "REC")
                    {
                        string uid = codeInstance.DatabaseQuery(conn, "SELECT [UID] FROM [Taketime].[dbo].[Account_Receipt] Where ID = '" + docNum + "'").Rows[0][0].ToString();
                        Response.Redirect("/Account/Receipt?command=edit&uid=" + uid);
                    }
                    else if (docType == "PAY")
                    {
                        string uid = codeInstance.DatabaseQuery(conn, "SELECT [UID] FROM [Taketime].[dbo].[Account_Payment] Where ID = '" + docNum + "'").Rows[0][0].ToString();
                        Response.Redirect("/Account/PaymentVoucher?command=edit&uid=" + uid);
                    }
                }
                catch (Exception ex)
                {
                    ShowError("แก้ไขเอกสารไม่สำเร็จ: " + ex.Message);
                }
            }
        }

        private void ShowError(string message)
        {
            ScriptManager.RegisterStartupScript(this, GetType(), "error", $"alert('{message}');", true);
        }

        /// <summary>
        /// Get current user ID from session
        /// </summary>
        private int? GetCurrentUserId()
        {
            try
            {
                if (Session["UserID"] != null)
                {
                    return Convert.ToInt32(Session["UserID"]);
                }
            }
            catch { }
            return null;
        }

        /// <summary>
        /// Get payment method name in Thai by legacy ID (hard-coded, no table lookup)
        /// Legacy mapping: 1=KBANK, 2=CASH, 3=DIRECTOR, 4=KTB
        /// </summary>
        private string GetPaymentMethodNameByLegacyId(int legacyId)
        {
            switch (legacyId)
            {
                case 1: return "โอนกสิกร"; // KBANK
                case 2: return "เงินสด"; // CASH
                case 3: return "เงินกรรมการ"; // DIRECTOR
                case 4: return "โอนกรุงไทย"; // KTB
                default: return "";
            }
        }
    }
}
