using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Collections.Generic;
using System.Linq;
using System.Configuration;
using OfficeOpenXml;
using System.IO;
using Take_Time_BangPhra.Services;

namespace Take_Time_BangPhra.Account
{
    public partial class CheckDocument : System.Web.UI.Page
    {
        private SqlConnection conn;
        private AccountingService accountingService;
        private code codeHelper;

        protected void Page_Load(object sender, EventArgs e)
        {
            codeHelper = new code();
            string connString = ConfigurationManager.ConnectionStrings["TaketimeConnectionString"].ConnectionString;
            conn = new SqlConnection(connString);
            accountingService = new AccountingService(conn);

            if (!IsPostBack)
            {
                CheckAdminLogin();
                InitializePage();
                LoadTodayData(); // Load today's Front team transactions by default
            }
        }

        private void CheckAdminLogin()
        {
            try
            {
                if (Session["permission"] == null || Session["permission"].ToString() != "True")
                {
                    Response.Redirect("/Default");
                }

                string userRole = Session["User"]?.ToString() ?? "";
                if (userRole != "Owner" && userRole != "Admin")
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
            // Set default date range to today
            txtStartDate.Text = DateTime.Now.ToString("yyyy-MM-dd");
            txtEndDate.Text = DateTime.Now.ToString("yyyy-MM-dd");
        }

        private void LoadTodayData()
        {
            DateTime today = DateTime.Now.Date;
            LoadData(today, today);
        }

        private void LoadData(DateTime startDate, DateTime endDate)
        {
            try
            {
                // Load summary cards
                LoadSummaryCards(startDate, endDate);

                // Load category breakdown
                LoadCategoryBreakdown(startDate, endDate);

                // Load payment channel breakdown
                LoadPaymentBreakdown(startDate, endDate);

                // Load transactions
                LoadTransactions(startDate, endDate);

                // Load daily summary
                LoadDailySummary(startDate, endDate);
            }
            catch (Exception ex)
            {
                ShowError("เกิดข้อผิดพลาดในการโหลดข้อมูล: " + ex.Message);
            }
        }

        private void LoadSummaryCards(DateTime startDate, DateTime endDate)
        {
            Dictionary<string, decimal> paymentSummary = accountingService.GetRevenueSummaryByPaymentChannel(startDate, endDate);

            decimal cashTotal = 0;
            decimal transferTotal = 0;
            decimal creditTotal = 0;

            // Map payment types to summary cards
            foreach (var item in paymentSummary)
            {
                string paymentType = item.Key.ToLower();
                decimal amount = item.Value;

                if (paymentType.Contains("สด") || paymentType.Contains("cash"))
                {
                    cashTotal += amount;
                }
                else if (paymentType.Contains("โอน") || paymentType.Contains("transfer"))
                {
                    transferTotal += amount;
                }
                else if (paymentType.Contains("บัตร") || paymentType.Contains("credit") || paymentType.Contains("card"))
                {
                    creditTotal += amount;
                }
            }

            lblCashTotal.Text = cashTotal.ToString("N2");
            lblTransferTotal.Text = transferTotal.ToString("N2");
            lblCreditTotal.Text = creditTotal.ToString("N2");
            lblGrandTotal.Text = (cashTotal + transferTotal + creditTotal).ToString("N2");
        }

        private void LoadCategoryBreakdown(DateTime startDate, DateTime endDate)
        {
            Dictionary<string, decimal> categorySummary = accountingService.GetRevenueSummaryByCategory(startDate, endDate);

            // Convert to list for binding
            var categoryList = categorySummary.Select(cat => new
            {
                CategoryName = GetCategoryDisplayName(cat.Key),
                Amount = cat.Value,
                Percentage = categorySummary.Values.Sum() > 0 ? (cat.Value / categorySummary.Values.Sum() * 100) : 0
            }).OrderByDescending(item => item.Amount).ToList();

            rptCategoryBreakdown.DataSource = categoryList;
            rptCategoryBreakdown.DataBind();
        }

        private void LoadPaymentBreakdown(DateTime startDate, DateTime endDate)
        {
            Dictionary<string, decimal> paymentSummary = accountingService.GetRevenueSummaryByPaymentChannel(startDate, endDate);

            // Convert to list for binding
            var paymentList = paymentSummary.Select(pay => new
            {
                PaymentName = pay.Key,
                Amount = pay.Value,
                Percentage = paymentSummary.Values.Sum() > 0 ? (pay.Value / paymentSummary.Values.Sum() * 100) : 0
            }).OrderByDescending(item => item.Amount).ToList();

            rptPaymentBreakdown.DataSource = paymentList;
            rptPaymentBreakdown.DataBind();
        }

        private void LoadTransactions(DateTime startDate, DateTime endDate)
        {
            // Critical logic: Loop through each date to get ONLY same-day transactions
            // This ensures we only show transactions where TransactionDate = the specific date
            // NOT advance bookings for future dates made on previous days
            List<DataRow> allTransactions = new List<DataRow>();

            for (DateTime date = startDate; date <= endDate; date = date.AddDays(1))
            {
                DataTable dt = accountingService.GetFrontTeamTransactions(date);
                if (dt != null && dt.Rows.Count > 0)
                {
                    foreach (DataRow row in dt.Rows)
                    {
                        allTransactions.Add(row);
                    }
                }
            }

            // Create consolidated DataTable
            DataTable consolidatedTable = null;
            if (allTransactions.Count > 0)
            {
                consolidatedTable = allTransactions[0].Table.Clone();
                foreach (DataRow row in allTransactions)
                {
                    consolidatedTable.ImportRow(row);
                }
            }
            else
            {
                // Create empty table with structure
                consolidatedTable = new DataTable();
                consolidatedTable.Columns.Add("TransactionDate", typeof(DateTime));
                consolidatedTable.Columns.Add("ReceiptNumber", typeof(string));
                consolidatedTable.Columns.Add("CustomerName", typeof(string));
                consolidatedTable.Columns.Add("RevenueCategory", typeof(string));
                consolidatedTable.Columns.Add("PaymentChannel", typeof(string));
                consolidatedTable.Columns.Add("Amount", typeof(decimal));
            }

            gvTransactions.DataSource = consolidatedTable;
            gvTransactions.DataBind();

            // Store in session for export
            Session["TransactionsData"] = consolidatedTable;
        }

        private void LoadDailySummary(DateTime startDate, DateTime endDate)
        {
            DataTable dt = accountingService.GetFrontTeamDailySummary(startDate, endDate);

            gvDailySummary.DataSource = dt;
            gvDailySummary.DataBind();

            // Store in session for export
            Session["DailySummaryData"] = dt;
        }

        protected string GetCategoryDisplayName(string category)
        {
            switch (category?.ToUpper())
            {
                case "ACCOMMODATION":
                    return "ห้องพัก";
                case "FOOD_BEVERAGE":
                    return "อาหารและเครื่องดื่ม";
                case "RENTAL":
                    return "เช่าอุปกรณ์";
                case "OTHER":
                    return "อื่นๆ";
                default:
                    return category ?? "ไม่ระบุ";
            }
        }

        protected string GetCategoryIcon(string category)
        {
            switch (category?.ToUpper())
            {
                case "ACCOMMODATION":
                case "ห้องพัก":
                    return "fas fa-bed";
                case "FOOD_BEVERAGE":
                case "อาหารและเครื่องดื่ม":
                    return "fas fa-utensils";
                case "RENTAL":
                case "เช่าอุปกรณ์":
                    return "fas fa-bicycle";
                case "OTHER":
                case "อื่นๆ":
                    return "fas fa-shopping-bag";
                default:
                    return "fas fa-tag";
            }
        }

        protected string GetPaymentIcon(string paymentChannel)
        {
            string channel = paymentChannel?.ToLower() ?? "";
            if (channel.Contains("สด") || channel.Contains("cash"))
                return "fas fa-money-bill-wave";
            else if (channel.Contains("โอน") || channel.Contains("transfer"))
                return "fas fa-university";
            else if (channel.Contains("บัตร") || channel.Contains("credit") || channel.Contains("card"))
                return "fas fa-credit-card";
            else
                return "fas fa-wallet";
        }

        protected string GetTransactionBadge(object isCheckIn)
        {
            if (isCheckIn != null && isCheckIn != DBNull.Value)
            {
                bool checkIn = Convert.ToBoolean(isCheckIn);
                return checkIn ? "badge-checkin" : "badge-sale";
            }
            return "badge-sale";
        }

        protected string GetTransactionStatus(object isCheckIn)
        {
            if (isCheckIn != null && isCheckIn != DBNull.Value)
            {
                bool checkIn = Convert.ToBoolean(isCheckIn);
                return checkIn ? "เช็คอิน" : "ขายสินค้า";
            }
            return "ขายสินค้า";
        }

        protected void btnSearch_Click(object sender, EventArgs e)
        {
            try
            {
                DateTime startDate = DateTime.Parse(txtStartDate.Text);
                DateTime endDate = DateTime.Parse(txtEndDate.Text);

                if (startDate > endDate)
                {
                    ShowError("วันที่เริ่มต้นต้องน้อยกว่าหรือเท่ากับวันที่สิ้นสุด");
                    return;
                }

                LoadData(startDate, endDate);
            }
            catch (Exception ex)
            {
                ShowError("รูปแบบวันที่ไม่ถูกต้อง: " + ex.Message);
            }
        }

        protected void btnToday_Click(object sender, EventArgs e)
        {
            txtStartDate.Text = DateTime.Now.ToString("yyyy-MM-dd");
            txtEndDate.Text = DateTime.Now.ToString("yyyy-MM-dd");
            LoadTodayData();
        }

        protected void btnThisWeek_Click(object sender, EventArgs e)
        {
            DateTime today = DateTime.Now.Date;
            DateTime startOfWeek = today.AddDays(-(int)today.DayOfWeek);

            txtStartDate.Text = startOfWeek.ToString("yyyy-MM-dd");
            txtEndDate.Text = today.ToString("yyyy-MM-dd");
            LoadData(startOfWeek, today);
        }

        protected void btnThisMonth_Click(object sender, EventArgs e)
        {
            DateTime today = DateTime.Now.Date;
            DateTime startOfMonth = new DateTime(today.Year, today.Month, 1);

            txtStartDate.Text = startOfMonth.ToString("yyyy-MM-dd");
            txtEndDate.Text = today.ToString("yyyy-MM-dd");
            LoadData(startOfMonth, today);
        }

        protected void btnExport_Click(object sender, EventArgs e)
        {
            try
            {
                ExportToExcel();
            }
            catch (Exception ex)
            {
                ShowError("เกิดข้อผิดพลาดในการ Export: " + ex.Message);
            }
        }

        private void ExportToExcel()
        {
            DateTime startDate = DateTime.Parse(txtStartDate.Text);
            DateTime endDate = DateTime.Parse(txtEndDate.Text);

            // EPPlus 4.5.3.3 doesn't require license context
            using (ExcelPackage package = new ExcelPackage())
            {
                // Sheet 1: Summary
                CreateSummarySheet(package, startDate, endDate);

                // Sheet 2: Transactions
                CreateTransactionsSheet(package);

                // Sheet 3: Daily Summary
                CreateDailySummarySheet(package);

                // Send file to browser
                string fileName = $"AccountingReport_{startDate:yyyyMMdd}_{endDate:yyyyMMdd}.xlsx";

                Response.Clear();
                Response.ContentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                Response.AddHeader("content-disposition", $"attachment; filename={fileName}");
                Response.BinaryWrite(package.GetAsByteArray());
                Response.End();
            }
        }

        private void CreateSummarySheet(ExcelPackage package, DateTime startDate, DateTime endDate)
        {
            var worksheet = package.Workbook.Worksheets.Add("สรุปภาพรวม");

            // Header
            worksheet.Cells["A1"].Value = "รายงานสรุปรายรับ - ทีม Front";
            worksheet.Cells["A1:F1"].Merge = true;
            worksheet.Cells["A1"].Style.Font.Bold = true;
            worksheet.Cells["A1"].Style.Font.Size = 16;
            worksheet.Cells["A1"].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

            worksheet.Cells["A2"].Value = $"ช่วงวันที่: {startDate:dd/MM/yyyy} - {endDate:dd/MM/yyyy}";
            worksheet.Cells["A2:F2"].Merge = true;
            worksheet.Cells["A2"].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

            // Payment Channel Summary
            worksheet.Cells["A4"].Value = "สรุปตามช่องทางชำระเงิน";
            worksheet.Cells["A4"].Style.Font.Bold = true;
            worksheet.Cells["A5"].Value = "ช่องทางชำระเงิน";
            worksheet.Cells["B5"].Value = "ยอดรวม (บาท)";
            worksheet.Cells["A5:B5"].Style.Font.Bold = true;

            Dictionary<string, decimal> paymentSummary = accountingService.GetRevenueSummaryByPaymentChannel(startDate, endDate);
            int row = 6;
            foreach (var item in paymentSummary.OrderByDescending(x => x.Value))
            {
                worksheet.Cells[$"A{row}"].Value = item.Key;
                worksheet.Cells[$"B{row}"].Value = item.Value;
                worksheet.Cells[$"B{row}"].Style.Numberformat.Format = "#,##0.00";
                row++;
            }

            // Total
            worksheet.Cells[$"A{row}"].Value = "รวมทั้งหมด";
            worksheet.Cells[$"A{row}"].Style.Font.Bold = true;
            worksheet.Cells[$"B{row}"].Value = paymentSummary.Values.Sum();
            worksheet.Cells[$"B{row}"].Style.Font.Bold = true;
            worksheet.Cells[$"B{row}"].Style.Numberformat.Format = "#,##0.00";

            // Category Summary
            int categoryStartRow = row + 3;
            worksheet.Cells[$"A{categoryStartRow}"].Value = "สรุปตามหมวดหมู่รายได้";
            worksheet.Cells[$"A{categoryStartRow}"].Style.Font.Bold = true;
            worksheet.Cells[$"A{categoryStartRow + 1}"].Value = "หมวดหมู่";
            worksheet.Cells[$"B{categoryStartRow + 1}"].Value = "ยอดรวม (บาท)";
            worksheet.Cells[$"A{categoryStartRow + 1}:B{categoryStartRow + 1}"].Style.Font.Bold = true;

            Dictionary<string, decimal> categorySummary = accountingService.GetRevenueSummaryByCategory(startDate, endDate);
            row = categoryStartRow + 2;
            foreach (var item in categorySummary.OrderByDescending(x => x.Value))
            {
                worksheet.Cells[$"A{row}"].Value = GetCategoryDisplayName(item.Key);
                worksheet.Cells[$"B{row}"].Value = item.Value;
                worksheet.Cells[$"B{row}"].Style.Numberformat.Format = "#,##0.00";
                row++;
            }

            // Total
            worksheet.Cells[$"A{row}"].Value = "รวมทั้งหมด";
            worksheet.Cells[$"A{row}"].Style.Font.Bold = true;
            worksheet.Cells[$"B{row}"].Value = categorySummary.Values.Sum();
            worksheet.Cells[$"B{row}"].Style.Font.Bold = true;
            worksheet.Cells[$"B{row}"].Style.Numberformat.Format = "#,##0.00";

            // Auto-fit columns
            worksheet.Cells.AutoFitColumns();
        }

        private void CreateTransactionsSheet(ExcelPackage package)
        {
            var worksheet = package.Workbook.Worksheets.Add("รายการธุรกรรม");

            DataTable dt = (DataTable)Session["TransactionsData"];
            if (dt == null || dt.Rows.Count == 0)
            {
                worksheet.Cells["A1"].Value = "ไม่มีข้อมูล";
                return;
            }

            // Headers
            for (int i = 0; i < dt.Columns.Count; i++)
            {
                worksheet.Cells[1, i + 1].Value = GetColumnDisplayName(dt.Columns[i].ColumnName);
                worksheet.Cells[1, i + 1].Style.Font.Bold = true;
            }

            // Data
            for (int i = 0; i < dt.Rows.Count; i++)
            {
                for (int j = 0; j < dt.Columns.Count; j++)
                {
                    object value = dt.Rows[i][j];

                    if (value is DateTime)
                    {
                        worksheet.Cells[i + 2, j + 1].Value = ((DateTime)value).ToString("dd/MM/yyyy HH:mm");
                    }
                    else if (value is decimal || value is double || value is float)
                    {
                        worksheet.Cells[i + 2, j + 1].Value = value;
                        worksheet.Cells[i + 2, j + 1].Style.Numberformat.Format = "#,##0.00";
                    }
                    else
                    {
                        worksheet.Cells[i + 2, j + 1].Value = value?.ToString() ?? "";
                    }
                }
            }

            // Auto-fit columns
            worksheet.Cells.AutoFitColumns();
        }

        private void CreateDailySummarySheet(ExcelPackage package)
        {
            var worksheet = package.Workbook.Worksheets.Add("สรุปรายวัน");

            DataTable dt = (DataTable)Session["DailySummaryData"];
            if (dt == null || dt.Rows.Count == 0)
            {
                worksheet.Cells["A1"].Value = "ไม่มีข้อมูล";
                return;
            }

            // Headers
            for (int i = 0; i < dt.Columns.Count; i++)
            {
                worksheet.Cells[1, i + 1].Value = GetColumnDisplayName(dt.Columns[i].ColumnName);
                worksheet.Cells[1, i + 1].Style.Font.Bold = true;
            }

            // Data
            for (int i = 0; i < dt.Rows.Count; i++)
            {
                for (int j = 0; j < dt.Columns.Count; j++)
                {
                    object value = dt.Rows[i][j];

                    if (value is DateTime)
                    {
                        worksheet.Cells[i + 2, j + 1].Value = ((DateTime)value).ToString("dd/MM/yyyy");
                    }
                    else if (value is decimal || value is double || value is float)
                    {
                        worksheet.Cells[i + 2, j + 1].Value = value;
                        worksheet.Cells[i + 2, j + 1].Style.Numberformat.Format = "#,##0.00";
                    }
                    else if (value is int)
                    {
                        worksheet.Cells[i + 2, j + 1].Value = value;
                        worksheet.Cells[i + 2, j + 1].Style.Numberformat.Format = "#,##0";
                    }
                    else
                    {
                        worksheet.Cells[i + 2, j + 1].Value = value?.ToString() ?? "";
                    }
                }
            }

            // Auto-fit columns
            worksheet.Cells.AutoFitColumns();
        }

        private string GetColumnDisplayName(string columnName)
        {
            switch (columnName)
            {
                case "TransactionDate":
                    return "วันที่ทำรายการ";
                case "ReceiptNumber":
                    return "เลขที่เอกสาร";
                case "CustomerName":
                    return "ชื่อลูกค้า";
                case "RevenueCategory":
                    return "หมวดหมู่";
                case "PaymentChannel":
                    return "ช่องทางชำระเงิน";
                case "Amount":
                    return "ยอดเงิน";
                case "PaymentTypeName":
                    return "ประเภทการชำระเงิน";
                case "TransactionCount":
                    return "จำนวนรายการ";
                case "TotalRevenue":
                    return "รายรับรวม";
                case "CheckInRevenue":
                    return "รายรับจากเช็คอิน";
                case "AccommodationRevenue":
                    return "รายรับห้องพัก";
                default:
                    return columnName;
            }
        }

        private void ShowError(string message)
        {
            // You can implement this to show error messages to the user
            // For example, using a Label or JavaScript alert
            string script = $"alert('{message.Replace("'", "\\'")}');";
            ScriptManager.RegisterStartupScript(this, GetType(), "ShowError", script, true);
        }

        protected void gvTransactions_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            gvTransactions.PageIndex = e.NewPageIndex;
            DataTable dt = (DataTable)Session["TransactionsData"];
            if (dt != null)
            {
                gvTransactions.DataSource = dt;
                gvTransactions.DataBind();
            }
        }

        protected void gvDailySummary_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            gvDailySummary.PageIndex = e.NewPageIndex;
            DataTable dt = (DataTable)Session["DailySummaryData"];
            if (dt != null)
            {
                gvDailySummary.DataSource = dt;
                gvDailySummary.DataBind();
            }
        }
    }
}
