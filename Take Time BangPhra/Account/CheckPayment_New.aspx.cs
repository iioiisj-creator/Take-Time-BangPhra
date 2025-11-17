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
    public partial class CheckPayment_New : System.Web.UI.Page
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

                    System.Diagnostics.Debug.WriteLine(string.Format("🔍 Search Mode: Month/Year - {0}/{1}", year, month));
                }
                else
                {
                    // Use date range
                    startDate = Convert.ToDateTime(txtStartDate.Text);
                    endDate = Convert.ToDateTime(txtEndDate.Text);

                    System.Diagnostics.Debug.WriteLine("🔍 Search Mode: Date Range");
                }

                System.Diagnostics.Debug.WriteLine(string.Format("📅 Date Range: {0} to {1}", startDate:yyyy-MM-dd HH:mm:ss, endDate:yyyy-MM-dd HH:mm:ss));

                // Show debug info on page
                lblDateRange.Text = string.Format("{0} - {1}", startDate:dd/MM/yyyy, endDate:dd/MM/yyyy);

                // Log expense calculation request
                try
                {
                    loggingService.LogAccountingOperation(
                        "ExpenseCalculationRequest",
                        string.Format("Date range: {0} to {1}", startDate:yyyy-MM-dd, endDate:yyyy-MM-dd),
                        true,
                        GetCurrentUserId());
                }
                catch { /* Ignore logging errors */ }

                // Calculate expenses by payment method
                try
                {
                    System.Diagnostics.Debug.WriteLine("⚙️ Calling CalculateExpenses...");
                    CalculateExpenses(startDate, endDate);
                    System.Diagnostics.Debug.WriteLine("✅ CalculateExpenses completed");
                }
                catch (Exception calcEx)
                {
                    System.Diagnostics.Debug.WriteLine(string.Format("❌ CalculateExpenses failed: {0}", calcEx.Message));
                    lblDateRange.Text += string.Format(" <span style='color: red;'>[CalculateExpenses Error: {0}]</span>", calcEx.Message);
                    ShowError(string.Format("เกิดข้อผิดพลาดในการคำนวณค่าใช้จ่าย:\\n{0}", calcEx.Message));
                }

                // Load details
                System.Diagnostics.Debug.WriteLine("⚙️ Calling LoadDetails...");
                LoadDetails(startDate, endDate);
                System.Diagnostics.Debug.WriteLine("✅ LoadDetails completed");
            }
            catch (Exception ex)
            {
                // Log exception
                try
                {
                    loggingService.LogException(ex, LoggingService.LogCategory.Accounting,
                        "Expense calculation failed", GetCurrentUserId());
                }
                catch { /* Ignore logging errors */ }

                ShowError("เกิดข้อผิดพลาด: " + ex.Message);
            }
        }

        private void CalculateExpenses(DateTime startDate, DateTime endDate)
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("💸 CalculateExpenses started");

                // Always calculate expenses for Normal status only (exclude Cancel)
                string status = "Normal";

                // Initialize totals
                decimal cashTotal = 0, kbankTotal = 0, ktbTotal = 0, directorTotal = 0, otherTotal = 0;
                int cashCount = 0, kbankCount = 0, ktbCount = 0, directorCount = 0, otherCount = 0;
                decimal totalVAT = 0;
                int docCount = 0;
                decimal grandTotal = 0;

                // Get all payments
                var payments = GetAllPayments(startDate, endDate, status);

                if (payments != null && payments.Rows.Count > 0)
                {
                    System.Diagnostics.Debug.WriteLine(string.Format("   📊 Processing {0} payment records...", payments.Rows.Count));

                    foreach (DataRow row in payments.Rows)
                    {
                        string paidHow = row["Paid_How"]?.ToString() ?? ""; // วิธีชำระ
                        string paidType = row["Paid_Type"]?.ToString() ?? ""; // ประเภทค่าใช้จ่าย
                        decimal amount = row["Total_Amount"] != DBNull.Value ? Convert.ToDecimal(row["Total_Amount"]) : 0;
                        decimal vat = row["Vat"] != DBNull.Value ? Convert.ToDecimal(row["Vat"]) : 0;

                        System.Diagnostics.Debug.WriteLine(string.Format("   Record: Paid_How='{0}', Paid_Type='{1}', Amount={2}", paidHow, paidType, amount:N2));

                        // Add to grand total regardless
                        grandTotal += amount;

                        // Count payment methods based on Paid_How (not Paid_Type!)
                        bool categorized = false;

                        if (paidHow.Contains("เงินสด") || paidHow.Contains("สด"))
                        {
                            cashTotal += amount;
                            cashCount++;
                            categorized = true;
                        }
                        if (paidHow.Contains("กสิกร") || paidHow.Contains("KBANK"))
                        {
                            kbankTotal += amount;
                            kbankCount++;
                            categorized = true;
                        }
                        if (paidHow.Contains("กรุงไทย") || paidHow.Contains("KTB"))
                        {
                            ktbTotal += amount;
                            ktbCount++;
                            categorized = true;
                        }
                        if (paidHow.Contains("กรรมการ") || paidHow.Contains("Director"))
                        {
                            directorTotal += amount;
                            directorCount++;
                            categorized = true;
                        }

                        if (!categorized)
                        {
                            otherTotal += amount;
                            otherCount++;
                            System.Diagnostics.Debug.WriteLine(string.Format("   ⚠️ Uncategorized payment method: '{0}'", paidHow));
                        }

                        totalVAT += vat;
                        docCount++;
                    }
                }
                else
                {
                    System.Diagnostics.Debug.WriteLine("   ⚠️ No payment records found!");
                }

                // Update UI
                lblCashTotal.Text = cashTotal.ToString("N2");
                lblCashCount.Text = cashCount.ToString();

                lblKBANKTotal.Text = kbankTotal.ToString("N2");
                lblKBANKCount.Text = kbankCount.ToString();

                lblKTBTotal.Text = ktbTotal.ToString("N2");
                lblKTBCount.Text = ktbCount.ToString();

                lblDirectorTotal.Text = directorTotal.ToString("N2");
                lblDirectorCount.Text = directorCount.ToString();

                int totalCount = cashCount + kbankCount + ktbCount + directorCount + otherCount;

                lblGrandTotal.Text = grandTotal.ToString("N2");
                lblTotalCount.Text = totalCount.ToString();
                lblTotalVAT.Text = totalVAT.ToString("N2");
                lblDocCount.Text = docCount.ToString();

                System.Diagnostics.Debug.WriteLine(string.Format("   💵 Cash: {0} ({1})", cashTotal:N2, cashCount));
                System.Diagnostics.Debug.WriteLine(string.Format("   🏦 KBANK: {0} ({1})", kbankTotal:N2, kbankCount));
                System.Diagnostics.Debug.WriteLine(string.Format("   🏦 KTB: {0} ({1})", ktbTotal:N2, ktbCount));
                System.Diagnostics.Debug.WriteLine(string.Format("   👔 Director: {0} ({1})", directorTotal:N2, directorCount));
                System.Diagnostics.Debug.WriteLine(string.Format("   ❓ Other: {0} ({1})", otherTotal:N2, otherCount));
                System.Diagnostics.Debug.WriteLine(string.Format("   💰 Grand Total: {0} ({1})", grandTotal:N2, totalCount));

                // Log expense calculation result
                try
                {
                    string breakdown = string.Format("Cash: {0} ({1})\n", cashTotal:N2, cashCount) +
                                     string.Format("KBANK: {0} ({1})\n", kbankTotal:N2, kbankCount) +
                                     string.Format("KTB: {0} ({1})\n", ktbTotal:N2, ktbCount) +
                                     string.Format("Director: {0} ({1})\n", directorTotal:N2, directorCount) +
                                     string.Format("Other: {0} ({1})\n", otherTotal:N2, otherCount) +
                                     string.Format("Document Count: {0}\n", docCount) +
                                     string.Format("Total VAT: {0}", totalVAT:N2);

                    loggingService.LogAccountingOperation(
                        "ExpenseCalculationResult",
                        string.Format("Total: {0}\n{1}", grandTotal:N2, breakdown),
                        true,
                        GetCurrentUserId());
                }
                catch { /* Ignore logging errors */ }

                System.Diagnostics.Debug.WriteLine("✅ CalculateExpenses completed successfully");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("❌ CalculateExpenses FAILED: {0}", ex.Message));
                throw;
            }
        }

        private DataTable GetAllPayments(DateTime startDate, DateTime endDate, string status)
        {
            // Get all payment vouchers in the date range
            string query = @"
                SELECT ap.ID, ap.Created_Date, ap.Paid_How, ap.Paid_Type, ap.Total_Amount, ap.Vat,
                       ap.Status,
                       ISNULL(v.Name, '-') as Vendor_Name,
                       a.Username as Created_By
                FROM Account_Payment ap
                LEFT JOIN Vendor v ON ap.Vendor_ID = v.ID
                LEFT JOIN Admin a ON ap.Created_By_ID = a.ID
                WHERE CAST(ap.Created_Date AS DATE) >= CAST(@StartDate AS DATE)
                  AND CAST(ap.Created_Date AS DATE) <= CAST(@EndDate AS DATE)
                  AND ap.Status LIKE @Status";

            // Admin permission check: Hide employee-related expenses
            if (Session["User"]?.ToString() == "Admin")
            {
                query += " AND (v.Vendor_Group IS NULL OR v.Vendor_Group != N'01-พนักงานประจำ')";
                System.Diagnostics.Debug.WriteLine("   🔒 Admin mode: Hiding employee expenses");
            }

            query += " ORDER BY ap.ID ASC";

            var parameters = new Dictionary<string, object>
            {
                { "@StartDate", startDate },
                { "@EndDate", endDate },
                { "@Status", status }
            };

            System.Diagnostics.Debug.WriteLine("📋 GetAllPayments Query:");
            System.Diagnostics.Debug.WriteLine("   User: {Session["User"]?.ToString() ?? "Unknown"}");
            System.Diagnostics.Debug.WriteLine(string.Format("   @StartDate = {0}", startDate:yyyy-MM-dd HH:mm:ss));
            System.Diagnostics.Debug.WriteLine(string.Format("   @EndDate = {0}", endDate:yyyy-MM-dd HH:mm:ss));
            System.Diagnostics.Debug.WriteLine(string.Format("   @Status = {0}", status));

            var result = codeInstance.DatabaseQuerySafe(conn, query, parameters);
            System.Diagnostics.Debug.WriteLine(string.Format("   ✅ Result: {0} rows", result?.Rows.Count ?? 0));

            return result;
        }

        private void LoadDetails(DateTime startDate, DateTime endDate)
        {
            DataTable dt = null;
            try
            {
                System.Diagnostics.Debug.WriteLine("📊 LoadDetails called:");
                System.Diagnostics.Debug.WriteLine(string.Format("   Start: {0}", startDate:yyyy-MM-dd HH:mm:ss));
                System.Diagnostics.Debug.WriteLine(string.Format("   End: {0}", endDate:yyyy-MM-dd HH:mm:ss));

                // Show all documents (both Normal and Cancel)
                dt = GetAllPayments(startDate, endDate, "%");
                System.Diagnostics.Debug.WriteLine(string.Format("   Retrieved {0} rows", dt?.Rows.Count ?? 0));

                if (dt != null && dt.Rows.Count > 0)
                {
                    lblDateRange.Text += string.Format(" <span style='color: green; font-weight: bold;'>(✓ พบ {0} เอกสาร)</span>", dt.Rows.Count);
                    System.Diagnostics.Debug.WriteLine(string.Format("   ✅ Showing {0} documents", dt.Rows.Count));
                }
                else
                {
                    lblDateRange.Text += " <span style='color: red; font-weight: bold;'>(⚠️ ไม่พบเอกสาร)</span>";
                    System.Diagnostics.Debug.WriteLine("   ⚠️ No documents found!");
                }

                // Bind to GridView
                gvDetails.DataSource = dt;
                gvDetails.DataBind();
                System.Diagnostics.Debug.WriteLine("   ✅ GridView.DataBind() completed");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("   ❌ Error in LoadDetails: {0}", ex.Message));
                lblDateRange.Text += string.Format(" <span style='color: red;'>[LoadDetails Error: {0}]</span>", ex.Message);
                ShowError(string.Format("เกิดข้อผิดพลาดในการโหลดข้อมูล:\\n{0}", ex.Message));

                // Bind empty DataTable
                try
                {
                    gvDetails.DataSource = new DataTable();
                    gvDetails.DataBind();
                }
                catch { }
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
                csv.Append("\uFEFF"); // BOM for UTF-8

                // Header
                csv.AppendLine("สรุปค่าใช้จ่าย");
                csv.AppendLine(string.Format("ช่วงวันที่:,{0} - {1}", startDate:dd/MM/yyyy, endDate:dd/MM/yyyy));
                csv.AppendLine(string.Format("วันที่ออกรายงาน:,{0}", DateTime.Now:dd/MM/yyyy HH:mm:ss));
                csv.AppendLine();

                // Summary table
                csv.AppendLine("วิธีชำระเงิน,ยอดรวม,จำนวนรายการ");
                csv.AppendLine(string.Format("เงินสด,{0},{1}", lblCashTotal.Text, lblCashCount.Text));
                csv.AppendLine(string.Format("โอนกสิกร,{0},{1}", lblKBANKTotal.Text, lblKBANKCount.Text));
                csv.AppendLine(string.Format("โอนกรุงไทย,{0},{1}", lblKTBTotal.Text, lblKTBCount.Text));
                csv.AppendLine(string.Format("เงินกรรมการ,{0},{1}", lblDirectorTotal.Text, lblDirectorCount.Text));
                csv.AppendLine(string.Format("รวมทั้งหมด,{0},{1}", lblGrandTotal.Text, lblTotalCount.Text));
                csv.AppendLine();

                // Detail records
                var dt = GetAllPayments(startDate, endDate, "%");
                csv.AppendLine("รายละเอียดเอกสาร");
                csv.AppendLine("เลขที่เอกสาร,วันที่,ผู้รับเงิน,วิธีชำระ,ยอดรวม,VAT,สถานะ,ผู้สร้าง");

                if (dt != null)
                {
                    foreach (DataRow row in dt.Rows)
                    {
                        string docId = row["ID"]?.ToString() ?? "";
                        string date = row["Created_Date"] != DBNull.Value ? Convert.ToDateTime(row["Created_Date"]).ToString("dd/MM/yyyy HH:mm") : "";
                        string vendor = row["Vendor_Name"]?.ToString() ?? "-";
                        string paidHow = row["Paid_How"]?.ToString() ?? ""; // วิธีชำระ (payment method)
                        string amount = row["Total_Amount"] != DBNull.Value ? Convert.ToDecimal(row["Total_Amount"]).ToString("N2") : "0.00";
                        string vat = row["Vat"] != DBNull.Value ? Convert.ToDecimal(row["Vat"]).ToString("N2") : "0.00";
                        string status = row["Status"]?.ToString() ?? "";
                        string createdBy = row["Created_By"]?.ToString() ?? "";

                        csv.AppendLine(string.Format("{0},{1},{2},{3},{4},{5},{6},{7}", docId, date, vendor, paidHow, amount, vat, status, createdBy));
                    }
                }

                // Send file
                Response.Clear();
                Response.ContentType = "text/csv";
                Response.ContentEncoding = Encoding.UTF8;
                Response.Charset = "UTF-8";
                Response.AddHeader("Content-Disposition", string.Format("attachment;filename=รายงานค่าใช้จ่าย_{0}_{1}.csv", startDate:yyyyMMdd, endDate:yyyyMMdd));
                Response.Write(csv.ToString());
                Response.End();
            }
            catch (Exception ex)
            {
                ShowError("เกิดข้อผิดพลาดในการ export: " + ex.Message);
            }
        }

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
                string docType = docNum.Length >= 3 ? docNum.Substring(0, 3) : "";
                string docYear = docNum.Length >= 5 ? "20" + docNum.Substring(3, 2) : "";
                string docMonth = docNum.Length >= 7 ? docNum.Substring(5, 2) : "";

                if (docType == "PAY")
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

                    Response.Redirect("/Account/CheckPayment_New");
                }
                else
                {
                    ShowError("เอกสารนี้ไม่ใช่ใบสำคัญจ่าย");
                }
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
                string docStatus = gvDetails.Rows[e.NewSelectedIndex].Cells[11].Text; // Status column (index เพิ่มเพราะเพิ่ม Paid_Type column)
                string docNum = gvDetails.Rows[e.NewSelectedIndex].Cells[3].Text; // ID column

                System.Diagnostics.Debug.WriteLine(string.Format("📄 Opening document: {0}, Status: {1}", docNum, docStatus));

                // Parse document info
                string docType = docNum.Length >= 3 ? docNum.Substring(0, 3) : "";
                string docYear = docNum.Length >= 5 ? "20" + docNum.Substring(3, 2) : "";
                string docMonth = docNum.Length >= 7 ? docNum.Substring(5, 2) : "";

                System.Diagnostics.Debug.WriteLine(string.Format("   Parsed: Type={0}, Year={1}, Month={2}", docType, docYear, docMonth));

                if (docType == "PAY")
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

                    // Build file paths
                    List<string> filesToCheck = new List<string>();

                    if (docStatus == "Cancel")
                    {
                        if (!string.IsNullOrEmpty(uid))
                        {
                            filesToCheck.Add(string.Format("{0}\\{1}\\{2}\\{3}_{4}_Cancel.pdf", path, docYear, docMonth, docNum, uid));
                        }
                        filesToCheck.Add(string.Format("{0}\\{1}\\{2}\\{3}_Cancel.pdf", path, docYear, docMonth, docNum));
                    }
                    else
                    {
                        if (!string.IsNullOrEmpty(uid))
                        {
                            filesToCheck.Add(string.Format("{0}\\{1}\\{2}\\{3}_{4}.pdf", path, docYear, docMonth, docNum, uid));
                        }
                        filesToCheck.Add(string.Format("{0}\\{1}\\{2}\\{3}.pdf", path, docYear, docMonth, docNum));
                    }

                    // Check and redirect
                    foreach (var filePath in filesToCheck)
                    {
                        System.Diagnostics.Debug.WriteLine(string.Format("   Checking: {0}", filePath));
                        if (File.Exists(filePath))
                        {
                            string relativeUrl = filePath.Replace(path, "/Documents/Payment").Replace("\\", "/");
                            System.Diagnostics.Debug.WriteLine(string.Format("   ✅ Found! Redirecting to: {0}", relativeUrl));
                            Response.Redirect(relativeUrl);
                            return;
                        }
                    }

                    throw new Exception(string.Format("ไม่พบไฟล์ PDF สำหรับเอกสาร {0}", docNum));
                }
                else
                {
                    throw new Exception(string.Format("ประเภทเอกสารไม่ถูกต้อง: {0}", docType));
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("   ❌ Error: {0}", ex.Message));
                ShowError("เปิดเอกสารไม่สำเร็จ:\\n" + ex.Message);
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
                    string docType = docNum.Length >= 3 ? docNum.Substring(0, 3) : "";

                    if (docType == "PAY")
                    {
                        string uid = codeInstance.DatabaseQuery(conn, "SELECT [UID] FROM [Taketime].[dbo].[Account_Payment] WHERE ID = '" + docNum + "'").Rows[0][0].ToString();
                        Response.Redirect("/Account/PaymentVoucher?command=edit&uid=" + uid);
                    }
                    else
                    {
                        ShowError("เอกสารนี้ไม่ใช่ใบสำคัญจ่าย");
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
            ScriptManager.RegisterStartupScript(this, GetType(), "error", string.Format("alert('{0}');", message), true);
        }

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
    }
}
