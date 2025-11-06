using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.IO;
using System.Text;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Take_Time_BangPhra.Account
{
    public partial class CheckDocument_New : System.Web.UI.Page
    {
        private readonly string conn = ConfigurationManager.ConnectionStrings["TaketimeConnectionString"].ConnectionString;
        private code codeInstance = new code();

        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
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
            catch
            {
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
                }
                else
                {
                    // Use date range
                    startDate = Convert.ToDateTime(txtStartDate.Text);
                    endDate = Convert.ToDateTime(txtEndDate.Text);
                }

                lblDateRange.Text = $"{startDate:dd/MM/yyyy} - {endDate:dd/MM/yyyy}";

                // Calculate revenue by category (always use Normal status, never include Cancel)
                CalculateRevenue(startDate, endDate);

                // Load details (show all documents including Cancel)
                LoadDetails(startDate, endDate);

                // Show validation
                ValidateTotal();
            }
            catch (Exception ex)
            {
                ShowError("เกิดข้อผิดพลาด: " + ex.Message);
            }
        }

        private void CalculateRevenue(DateTime startDate, DateTime endDate)
        {
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
            var cat1Data = GetCategory1Revenue(startDate, endDate, status);
            cat1Cash = GetAmountByPaymentMethod(cat1Data, 2);
            cat1KBANK = GetAmountByPaymentMethod(cat1Data, 1);
            cat1KTB = GetAmountByPaymentMethod(cat1Data, 4);
            cat1Director = GetAmountByPaymentMethod(cat1Data, 3);

            // Category 2: Reservations with payment in date range but check-in outside
            var cat2Data = GetCategory2Revenue(startDate, endDate, status);
            cat2Cash = GetAmountByPaymentMethod(cat2Data, 2);
            cat2KBANK = GetAmountByPaymentMethod(cat2Data, 1);
            cat2KTB = GetAmountByPaymentMethod(cat2Data, 4);
            cat2Director = GetAmountByPaymentMethod(cat2Data, 3);

            // Category 3: Product sales
            var cat3Data = GetCategory3Revenue(startDate, endDate, status);
            cat3Cash = GetAmountByPaymentMethod(cat3Data, 2);
            cat3KBANK = GetAmountByPaymentMethod(cat3Data, 1);
            cat3KTB = GetAmountByPaymentMethod(cat3Data, 4);
            cat3Director = GetAmountByPaymentMethod(cat3Data, 3);

            // Category 4: Others
            var cat4Data = GetCategory4Revenue(startDate, endDate, status);
            cat4Cash = GetAmountByPaymentMethod(cat4Data, 2);
            cat4KBANK = GetAmountByPaymentMethod(cat4Data, 1);
            cat4KTB = GetAmountByPaymentMethod(cat4Data, 4);
            cat4Director = GetAmountByPaymentMethod(cat4Data, 3);

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

            // Get VAT and document count
            var allData = GetAllReceipts(startDate, endDate, status);
            foreach (DataRow row in allData.Rows)
            {
                totalVAT += row["Vat"] != DBNull.Value ? Convert.ToDecimal(row["Vat"]) : 0;
                docCount++;
            }

            lblTotalVAT.Text = totalVAT.ToString("N2");
            lblDocCount.Text = docCount.ToString();
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
                WHERE r.CheckinDate >= @StartDate AND r.CheckinDate <= @EndDate
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
                WHERE ar.Created_Date >= @StartDate AND ar.Created_Date <= @EndDate
                  AND (r.CheckinDate < @StartDate OR r.CheckinDate > @EndDate OR r.CheckinDate IS NULL)
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
                WHERE ar.Created_Date >= @StartDate AND ar.Created_Date <= @EndDate
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
                WHERE ar.Created_Date >= @StartDate AND ar.Created_Date <= @EndDate
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

        private decimal GetAmountByPaymentMethod(DataTable dt, int paymentMethodID)
        {
            // Map payment method IDs to their Thai names
            string paymentMethodName = "";
            switch (paymentMethodID)
            {
                case 1: paymentMethodName = "เงินโอน บัญชี ธ.กสิกรไทย"; break;  // KBANK transfer
                case 2: paymentMethodName = "เงินสด"; break;     // Cash
                case 3: paymentMethodName = "กรรมการ"; break; // Director money
                case 4: paymentMethodName = "เงินโอน บัญชี ธ.กรุงไทย"; break;  // KTB transfer
                default: return 0;
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

                    // Check if this payment method is in the Paid_Type
                    if (!string.IsNullOrEmpty(paidType) && paidType.Contains(paymentMethodName))
                    {
                        // Count how many payment methods are in this receipt
                        string[] paymentMethods = paidType.Split(new[] { ',', '/' }, StringSplitOptions.RemoveEmptyEntries);
                        int methodCount = paymentMethods.Length;

                        // Only count this receipt once per payment method
                        string uniqueKey = $"{receiptId}_{paymentMethodName}";
                        if (!processedPayments.Contains(uniqueKey))
                        {
                            // If multiple payment methods, split the amount evenly
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
            // Fixed: Include receipts from all 4 categories to match revenue calculation
            // - Category 1: Reservation check-in in date range
            // - Category 2: Receipt created in date range (check-in outside)
            // - Category 3-4: Receipt created in date range (non-reservation)
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
                WHERE ar.Status LIKE @Status
                  AND (
                      (ar.Created_Date >= @StartDate AND ar.Created_Date <= @EndDate)
                      OR (r.CheckinDate >= @StartDate AND r.CheckinDate <= @EndDate AND ar.Reservation_ID > 0)
                  )
                ORDER BY ar.ID ASC";

            var parameters = new Dictionary<string, object>
            {
                { "@StartDate", startDate },
                { "@EndDate", endDate },
                { "@Status", status }
            };

            return codeInstance.DatabaseQuerySafe(conn, query, parameters);
        }

        private void LoadDetails(DateTime startDate, DateTime endDate)
        {
            // Always show all documents (both Normal and Cancel) in GridView
            var dt = GetAllReceipts(startDate, endDate, "%");
            gvDetails.DataSource = dt;
            gvDetails.DataBind();
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
                string docStatus = gvDetails.Rows[e.NewSelectedIndex].Cells[13].Text; // Status column (now at index 13)
                string docNum = gvDetails.Rows[e.NewSelectedIndex].Cells[3].Text; // ID column (at index 3)
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
                    string path = ConfigurationManager.AppSettings["ReceiptFolderPath"];
                    string uid = codeInstance.DatabaseQuery(conn, "SELECT [UID] FROM [Taketime].[dbo].[Account_Receipt] Where ID = '" + docNum + "'").Rows[0][0].ToString();

                    if (docStatus == "Cancel")
                    {
                        if (File.Exists($"{path}\\{docYear}\\{docMonth}\\{docNum}_{uid}_Cancel.pdf"))
                        {
                            Response.Redirect($"/Documents/Receipt/{docYear}/{docMonth}/{docNum}_{uid}_Cancel.pdf");
                        }
                        else
                        {
                            Response.Redirect($"/Documents/Receipt/{docYear}/{docMonth}/{docNum}_Cancel.pdf");
                        }
                    }
                    else
                    {
                        if (File.Exists($"{path}\\{docYear}\\{docMonth}\\{docNum}_{uid}.pdf"))
                        {
                            Response.Redirect($"/Documents/Receipt/{docYear}/{docMonth}/{docNum}_{uid}.pdf");
                        }
                        else
                        {
                            Response.Redirect($"/Documents/Receipt/{docYear}/{docMonth}/{docNum}.pdf");
                        }
                    }
                }
                else if (docType == "PAY")
                {
                    string path = ConfigurationManager.AppSettings["PaymentFolderPath"];
                    string uid = codeInstance.DatabaseQuery(conn, "SELECT [UID] FROM [Taketime].[dbo].[Account_Payment] Where ID = '" + docNum + "'").Rows[0][0].ToString();

                    if (docStatus == "Cancel")
                    {
                        if (File.Exists($"{path}\\{docYear}\\{docMonth}\\{docNum}_{uid}_Cancel.pdf"))
                        {
                            Response.Redirect($"/Documents/Payment/{docYear}/{docMonth}/{docNum}_{uid}_Cancel.pdf");
                        }
                        else
                        {
                            Response.Redirect($"/Documents/Payment/{docYear}/{docMonth}/{docNum}_Cancel.pdf");
                        }
                    }
                    else
                    {
                        if (File.Exists($"{path}\\{docYear}\\{docMonth}\\{docNum}_{uid}.pdf"))
                        {
                            Response.Redirect($"/Documents/Payment/{docYear}/{docMonth}/{docNum}_{uid}.pdf");
                        }
                        else
                        {
                            Response.Redirect($"/Documents/Payment/{docYear}/{docMonth}/{docNum}.pdf");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ShowError("เปิดเอกสารไม่สำเร็จ: " + ex.Message);
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
    }
}
