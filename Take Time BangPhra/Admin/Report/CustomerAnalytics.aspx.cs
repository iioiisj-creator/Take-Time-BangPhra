using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Web.UI;
using System.Web.UI.WebControls;
using Take_Time_BangPhra.Class;

namespace Take_Time_BangPhra.Admin.Report
{
    public partial class CustomerAnalytics : Page
    {
        private readonly string conn = ConfigurationManager.ConnectionStrings["TaketimeConnectionString"].ConnectionString;
        private code codeInstance = new code();

        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                // Check permission
                if (Session["permission"]?.ToString() != "True" ||
                    (Session["User"]?.ToString() != "Owner" && Session["User"]?.ToString() != "Admin"))
                {
                    Response.Redirect("/Default");
                    return;
                }

                if (!IsPostBack)
                {
                    InitializePage();
                    LoadCustomerData();
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("❌ CustomerAnalytics Error: {0}", ex.Message));
                Response.Redirect("/Default");
            }
        }

        private void InitializePage()
        {
            // Populate year dropdown (last 5 years)
            int currentYear = DateTime.Now.Year;
            ddlYear.Items.Clear();

            for (int i = 0; i < 5; i++)
            {
                int year = currentYear - i;
                ddlYear.Items.Add(new ListItem(year.ToString(), year.ToString()));
            }

            ddlYear.SelectedIndex = 0;
            litSelectedYear.Text = currentYear.ToString();
        }

        private void LoadCustomerData()
        {
            try
            {
                int selectedYear = Convert.ToInt32(ddlYear.SelectedValue);
                string customerType = ddlCustomerType.SelectedValue;
                int limit = Convert.ToInt32(ddlLimit.SelectedValue);

                System.Diagnostics.Debug.WriteLine(string.Format("📊 Loading Customer Data: Year={0}, Type={1}, Limit={2}", selectedYear, customerType, limit));

                // Update year display
                litSelectedYear.Text = selectedYear.ToString();

                // Load summary stats
                LoadSummaryStats(selectedYear);

                // Load repeat customers (ตามที่ user ขอ!)
                LoadRepeatCustomers(selectedYear);

                // Load all customers
                LoadAllCustomers(selectedYear, customerType, limit);

                // Load chart data
                LoadChartData(selectedYear);

                System.Diagnostics.Debug.WriteLine("✅ Customer data loaded successfully");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("❌ LoadCustomerData Error: {0}", ex.Message));
                ShowMessage(string.Format("เกิดข้อผิดพลาด: {0}", ex.Message), "error");
            }
        }

        #region Summary Stats

        private void LoadSummaryStats(int year)
        {
            try
            {
                string query = @"
                    SELECT
                        COUNT(DISTINCT c.MobilePhone) as TotalCustomers,
                        SUM(CASE WHEN BookingCount = 1 THEN 1 ELSE 0 END) as NewCustomers,
                        SUM(CASE WHEN BookingCount BETWEEN 2 AND 5 THEN 1 ELSE 0 END) as ReturningCustomers,
                        SUM(CASE WHEN BookingCount > 5 THEN 1 ELSE 0 END) as VIPCustomers
                    FROM (
                        SELECT
                            r.Customer_MobilePhone,
                            COUNT(*) as BookingCount
                        FROM Reservation r
                        WHERE YEAR(r.Created_Date) = @Year
                          AND r.Status NOT IN (N'ยกเลิกคืนเงิน', N'ยกเลิกไม่คืนเงิน')
                        GROUP BY r.Customer_MobilePhone
                    ) as CustomerStats
                    CROSS JOIN Customer c
                    WHERE c.MobilePhone = CustomerStats.Customer_MobilePhone";

                var parameters = new Dictionary<string, object> { { "@Year", year } };
                DataTable dt = codeInstance.DatabaseQuerySafe(conn, query, parameters);

                if (dt != null && dt.Rows.Count > 0)
                {
                    DataRow row = dt.Rows[0];
                    litTotalCustomers.Text = row["TotalCustomers"].ToString();
                    litNewCustomers.Text = row["NewCustomers"].ToString();
                    litReturningCustomers.Text = row["ReturningCustomers"].ToString();
                    litVIPCustomers.Text = row["VIPCustomers"].ToString();
                }
                else
                {
                    litTotalCustomers.Text = "0";
                    litNewCustomers.Text = "0";
                    litReturningCustomers.Text = "0";
                    litVIPCustomers.Text = "0";
                }

                System.Diagnostics.Debug.WriteLine(string.Format("📊 Summary Stats: Total={0}, New={1}, Returning={2}, VIP={3}", litTotalCustomers.Text, litNewCustomers.Text, litReturningCustomers.Text, litVIPCustomers.Text));
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("❌ LoadSummaryStats Error: {0}", ex.Message));
            }
        }

        #endregion

        #region Repeat Customers (ลูกค้าที่กลับมาพักซ้ำ - ตามที่ user ขอ!)

        private void LoadRepeatCustomers(int year)
        {
            try
            {
                string query = @"
                    SELECT
                        ISNULL(c.FullName, c.Name) as CustomerName,
                        c.MobilePhone as PhoneNumber,
                        COUNT(*) as TotalBookings,
                        SUM(r.TotalPrice) as TotalSpent,
                        AVG(r.TotalPrice) as AvgSpending,
                        MIN(r.Created_Date) as FirstVisit,
                        MAX(r.Created_Date) as LastVisit,
                        (
                            SELECT TOP 1 a.AccomName
                            FROM Reservation_Accommodation ra
                            INNER JOIN Accommodation a ON ra.Accommodation_ID = a.ID
                            WHERE ra.Reservation_ID IN (
                                SELECT ID FROM Reservation WHERE Customer_MobilePhone = c.MobilePhone
                            )
                            GROUP BY a.AccomName
                            ORDER BY COUNT(*) DESC
                        ) as PreferredAccommodation
                    FROM Reservation r
                    INNER JOIN Customer c ON r.Customer_MobilePhone = c.MobilePhone
                    WHERE YEAR(r.Created_Date) = @Year
                      AND r.Status NOT IN (N'ยกเลิกคืนเงิน', N'ยกเลิกไม่คืนเงิน')
                    GROUP BY c.FullName, c.Name, c.MobilePhone
                    HAVING COUNT(*) > 1  -- เฉพาะลูกค้าที่มาซ้ำ (>1 ครั้ง)
                    ORDER BY TotalBookings DESC, TotalSpent DESC";

                var parameters = new Dictionary<string, object> { { "@Year", year } };
                DataTable dt = codeInstance.DatabaseQuerySafe(conn, query, parameters);

                gvRepeatCustomers.DataSource = dt;
                gvRepeatCustomers.DataBind();

                // Update count
                litRepeatCount.Text = dt != null ? dt.Rows.Count.ToString() : "0";

                System.Diagnostics.Debug.WriteLine(string.Format("🔄 Repeat Customers: {0} found", litRepeatCount.Text));
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("❌ LoadRepeatCustomers Error: {0}", ex.Message));
                gvRepeatCustomers.DataSource = null;
                gvRepeatCustomers.DataBind();
                litRepeatCount.Text = "0";
            }
        }

        #endregion

        #region All Customers

        private void LoadAllCustomers(int year, string customerType, int limit)
        {
            try
            {
                // Build query based on customer type
                string whereClause = "";
                if (customerType == "NEW")
                {
                    whereClause = "HAVING COUNT(*) = 1";
                }
                else if (customerType == "RETURNING")
                {
                    whereClause = "HAVING COUNT(*) BETWEEN 2 AND 5";
                }
                else if (customerType == "VIP")
                {
                    whereClause = "HAVING COUNT(*) > 5";
                }

                string topClause = limit > 0 ? string.Format("TOP {0}", limit) : "";

                string query = $@"
                    SELECT {topClause}
                        ISNULL(c.FullName, c.Name) as CustomerName,
                        c.MobilePhone as PhoneNumber,
                        ISNULL(c.Email, '-') as Email,
                        COUNT(*) as TotalBookings,
                        SUM(r.TotalPrice) as TotalSpent,
                        MAX(r.Created_Date) as LastVisit
                    FROM Reservation r
                    INNER JOIN Customer c ON r.Customer_MobilePhone = c.MobilePhone
                    WHERE YEAR(r.Created_Date) = @Year
                      AND r.Status NOT IN (N'ยกเลิกคืนเงิน', N'ยกเลิกไม่คืนเงิน')
                    GROUP BY c.FullName, c.Name, c.MobilePhone, c.Email
                    {whereClause}
                    ORDER BY TotalBookings DESC, TotalSpent DESC";

                var parameters = new Dictionary<string, object> { { "@Year", year } };
                DataTable dt = codeInstance.DatabaseQuerySafe(conn, query, parameters);

                gvAllCustomers.DataSource = dt;
                gvAllCustomers.DataBind();

                // Update counts
                litDisplayCount.Text = dt != null ? dt.Rows.Count.ToString() : "0";

                // Get total count (without limit)
                string countQuery = $@"
                    SELECT COUNT(*) as Total
                    FROM (
                        SELECT c.MobilePhone, COUNT(*) as BookingCount
                        FROM Reservation r
                        INNER JOIN Customer c ON r.Customer_MobilePhone = c.MobilePhone
                        WHERE YEAR(r.Created_Date) = @Year
                          AND r.Status NOT IN (N'ยกเลิกคืนเงิน', N'ยกเลิกไม่คืนเงิน')
                        GROUP BY c.MobilePhone
                        {whereClause}
                    ) as Counts";

                DataTable countDt = codeInstance.DatabaseQuerySafe(conn, countQuery, parameters);
                litTotalCount.Text = countDt != null && countDt.Rows.Count > 0 ? countDt.Rows[0]["Total"].ToString() : "0";

                System.Diagnostics.Debug.WriteLine(string.Format("📋 All Customers: Showing {0} of {1}", litDisplayCount.Text, litTotalCount.Text));
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("❌ LoadAllCustomers Error: {0}", ex.Message));
                gvAllCustomers.DataSource = null;
                gvAllCustomers.DataBind();
                litDisplayCount.Text = "0";
                litTotalCount.Text = "0";
            }
        }

        #endregion

        #region Charts Data

        private void LoadChartData(int year)
        {
            try
            {
                // Customer Segmentation Chart
                int newCustomers = Convert.ToInt32(litNewCustomers.Text);
                int returningCustomers = Convert.ToInt32(litReturningCustomers.Text);
                int vipCustomers = Convert.ToInt32(litVIPCustomers.Text);

                hfSegmentationData.Value = string.Format("[{0}, {1}, {2}]", newCustomers, returningCustomers, vipCustomers);

                // Top 10 Customers Chart
                string query = @"
                    SELECT TOP 10
                        ISNULL(c.FullName, c.Name) as CustomerName,
                        SUM(r.TotalPrice) as TotalSpent
                    FROM Reservation r
                    INNER JOIN Customer c ON r.Customer_MobilePhone = c.MobilePhone
                    WHERE YEAR(r.Created_Date) = @Year
                      AND r.Status NOT IN (N'ยกเลิกคืนเงิน', N'ยกเลิกไม่คืนเงิน')
                    GROUP BY c.FullName, c.Name, c.MobilePhone
                    ORDER BY TotalSpent DESC";

                var parameters = new Dictionary<string, object> { { "@Year", year } };
                DataTable dt = codeInstance.DatabaseQuerySafe(conn, query, parameters);

                if (dt != null && dt.Rows.Count > 0)
                {
                    List<string> names = new List<string>();
                    List<decimal> amounts = new List<decimal>();

                    foreach (DataRow row in dt.Rows)
                    {
                        string name = row["CustomerName"].ToString();
                        // Truncate name if too long
                        if (name.Length > 20)
                        {
                            name = name.Substring(0, 17) + "...";
                        }
                        names.Add("\"{name}\"");
                        amounts.Add(Convert.ToDecimal(row["TotalSpent"]));
                    }

                    hfTopCustomersLabels.Value = "[" + string.Join(",", names) + "]";
                    hfTopCustomersData.Value = "[" + string.Join(",", amounts) + "]";
                }
                else
                {
                    hfTopCustomersLabels.Value = "['','','','','','','','','','']";
                    hfTopCustomersData.Value = "[0,0,0,0,0,0,0,0,0,0]";
                }

                System.Diagnostics.Debug.WriteLine(string.Format("📈 Chart Data: Segmentation={0}, TopCustomers={1}", hfSegmentationData.Value, dt?.Rows.Count ?? 0));
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("❌ LoadChartData Error: {0}", ex.Message));
                hfSegmentationData.Value = "[0,0,0]";
                hfTopCustomersLabels.Value = "['','','','','','','','','','']";
                hfTopCustomersData.Value = "[0,0,0,0,0,0,0,0,0,0]";
            }
        }

        #endregion

        #region Event Handlers

        protected void ddlYear_SelectedIndexChanged(object sender, EventArgs e)
        {
            LoadCustomerData();
        }

        protected void ddlCustomerType_SelectedIndexChanged(object sender, EventArgs e)
        {
            LoadCustomerData();
        }

        protected void ddlLimit_SelectedIndexChanged(object sender, EventArgs e)
        {
            LoadCustomerData();
        }

        protected void gvAllCustomers_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            gvAllCustomers.PageIndex = e.NewPageIndex;
            LoadCustomerData();
        }

        protected void btnExport_Click(object sender, EventArgs e)
        {
            try
            {
                int year = Convert.ToInt32(ddlYear.SelectedValue);

                // Create CSV content
                StringBuilder csv = new StringBuilder();

                // Add BOM for UTF-8 Excel compatibility
                csv.Append("\uFEFF");

                // Header
                csv.AppendLine(string.Format("รายงานวิเคราะห์ลูกค้า - ปี {0}", year));
                csv.AppendLine(string.Format("วันที่ออกรายงาน:,{0}", DateTime.Now:dd/MM/yyyy HH:mm:ss));
                csv.AppendLine("ผู้ออกรายงาน:,{Session["User"]?.ToString() ?? "ผู้ใช้งาน"}");
                csv.AppendLine();

                // Summary
                csv.AppendLine("สรุปข้อมูลลูกค้า");
                csv.AppendLine(string.Format("ลูกค้าทั้งหมด:,{0} ราย", litTotalCustomers.Text));
                csv.AppendLine(string.Format("ลูกค้าใหม่:,{0} ราย", litNewCustomers.Text));
                csv.AppendLine(string.Format("ลูกค้าประจำ:,{0} ราย", litReturningCustomers.Text));
                csv.AppendLine(string.Format("ลูกค้า VIP:,{0} ราย", litVIPCustomers.Text));
                csv.AppendLine();

                // Repeat Customers Section
                csv.AppendLine("ลูกค้าที่กลับมาพักซ้ำ");
                csv.AppendLine("#,ชื่อลูกค้า,เบอร์โทร,จำนวนครั้ง,ประเภท,ยอดใช้จ่ายรวม,ค่าเฉลี่ย/ครั้ง,มาครั้งแรก,มาครั้งล่าสุด,ที่พักที่ชอบ");

                DataTable repeatDt = GetRepeatCustomersDataForExport(year);
                if (repeatDt != null)
                {
                    int rowNum = 1;
                    foreach (DataRow row in repeatDt.Rows)
                    {
                        int bookings = Convert.ToInt32(row["TotalBookings"]);
                        string type = GetCustomerTypeText(bookings);
                        decimal totalSpent = row["TotalSpent"] != DBNull.Value ? Convert.ToDecimal(row["TotalSpent"]) : 0;
                        decimal avgSpending = row["AvgSpending"] != DBNull.Value ? Convert.ToDecimal(row["AvgSpending"]) : 0;
                        string firstVisit = row["FirstVisit"] != DBNull.Value ? Convert.ToDateTime(row["FirstVisit"]).ToString("dd/MM/yyyy") : "";
                        string lastVisit = row["LastVisit"] != DBNull.Value ? Convert.ToDateTime(row["LastVisit"]).ToString("dd/MM/yyyy") : "";

                        csv.AppendLine(string.Format("{0},", rowNum) +
                            "{row["CustomerName"]}," +
                            "{row["PhoneNumber"]}," +
                            string.Format("{0},", bookings) +
                            string.Format("{0},", type) +
                            string.Format("{0},", totalSpent:N2) +
                            string.Format("{0},", avgSpending:N2) +
                            string.Format("{0},", firstVisit) +
                            string.Format("{0},", lastVisit) +
                            "{row["PreferredAccommodation"]}");
                        rowNum++;
                    }
                }

                // Send file to browser
                Response.Clear();
                Response.ContentType = "text/csv";
                Response.ContentEncoding = Encoding.UTF8;
                Response.Charset = "UTF-8";
                Response.AddHeader("Content-Disposition", string.Format("attachment;filename=CustomerAnalytics_{0}_{1}.csv", year, DateTime.Now:yyyyMMdd));
                Response.Write(csv.ToString());
                Response.End();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("❌ Export Error: {0}", ex.Message));
                ShowMessage(string.Format("เกิดข้อผิดพลาดในการ export: {0}", ex.Message), "error");
            }
        }

        #endregion

        #region Helper Methods

        protected string GetCustomerTypeBadge(int bookingCount)
        {
            if (bookingCount == 1)
            {
                return "<span class='badge badge-new'>ลูกค้าใหม่</span>";
            }
            else if (bookingCount >= 2 && bookingCount <= 5)
            {
                return "<span class='badge badge-returning'>ลูกค้าประจำ</span>";
            }
            else
            {
                return "<span class='badge badge-vip'>VIP</span>";
            }
        }

        private string GetCustomerTypeText(int bookingCount)
        {
            if (bookingCount == 1)
                return "ลูกค้าใหม่";
            else if (bookingCount >= 2 && bookingCount <= 5)
                return "ลูกค้าประจำ";
            else
                return "VIP";
        }

        private DataTable GetRepeatCustomersDataForExport(int year)
        {
            try
            {
                string query = @"
                    SELECT
                        ISNULL(c.FullName, c.Name) as CustomerName,
                        c.MobilePhone as PhoneNumber,
                        COUNT(*) as TotalBookings,
                        SUM(r.TotalPrice) as TotalSpent,
                        AVG(r.TotalPrice) as AvgSpending,
                        MIN(r.Created_Date) as FirstVisit,
                        MAX(r.Created_Date) as LastVisit,
                        (
                            SELECT TOP 1 a.AccomName
                            FROM Reservation_Accommodation ra
                            INNER JOIN Accommodation a ON ra.Accommodation_ID = a.ID
                            WHERE ra.Reservation_ID IN (
                                SELECT ID FROM Reservation WHERE Customer_MobilePhone = c.MobilePhone
                            )
                            GROUP BY a.AccomName
                            ORDER BY COUNT(*) DESC
                        ) as PreferredAccommodation
                    FROM Reservation r
                    INNER JOIN Customer c ON r.Customer_MobilePhone = c.MobilePhone
                    WHERE YEAR(r.Created_Date) = @Year
                      AND r.Status NOT IN (N'ยกเลิกคืนเงิน', N'ยกเลิกไม่คืนเงิน')
                    GROUP BY c.FullName, c.Name, c.MobilePhone
                    HAVING COUNT(*) > 1
                    ORDER BY TotalBookings DESC, TotalSpent DESC";

                var parameters = new Dictionary<string, object> { { "@Year", year } };
                return codeInstance.DatabaseQuerySafe(conn, query, parameters);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(string.Format("❌ GetRepeatCustomersDataForExport Error: {0}", ex.Message));
                return null;
            }
        }

        private void ShowMessage(string message, string type)
        {
            string icon = type == "success" ? "✅" : "❌";
            ScriptManager.RegisterStartupScript(this, GetType(), "message",
                string.Format("alert('{0} {1}');", icon, message), true);
        }

        #endregion
    }
}
