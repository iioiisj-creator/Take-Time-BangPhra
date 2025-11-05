using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
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

                // Calculate revenue by category
                CalculateRevenue(startDate, endDate);

                // Load details
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
            string status = ddlStatus.SelectedValue;

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
            string query = @"
                SELECT ar.Paid_Type, ph.PaymentMethod, SUM(ph.PaymentAmount) as Total, aph.ID as PaymentMethodID
                FROM Payment_History ph
                INNER JOIN Reservation r ON ph.Reservation_ID = r.ID
                INNER JOIN Account_Receipt ar ON ar.Reservation_ID = r.ID
                LEFT JOIN Account_Paid_How aph ON ar.Paid_Type LIKE '%' + aph.Paid_How + '%'
                WHERE r.CheckinDate >= @StartDate AND r.CheckinDate <= @EndDate
                  AND ph.Status = 'COMPLETED'
                  AND ar.Status LIKE @Status
                GROUP BY ar.Paid_Type, ph.PaymentMethod, aph.ID";

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
            // Reservations with payment in date range but check-in outside
            string query = @"
                SELECT ar.Paid_Type, ph.PaymentMethod, SUM(ph.PaymentAmount) as Total, aph.ID as PaymentMethodID
                FROM Payment_History ph
                INNER JOIN Reservation r ON ph.Reservation_ID = r.ID
                INNER JOIN Account_Receipt ar ON ar.Reservation_ID = r.ID
                LEFT JOIN Account_Paid_How aph ON ar.Paid_Type LIKE '%' + aph.Paid_How + '%'
                WHERE ph.PaymentDate >= @StartDate AND ph.PaymentDate <= @EndDate
                  AND (r.CheckinDate < @StartDate OR r.CheckinDate > @EndDate)
                  AND ph.Status = 'COMPLETED'
                  AND ar.Status LIKE @Status
                GROUP BY ar.Paid_Type, ph.PaymentMethod, aph.ID";

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
            // Product sales (ProductType_ID = 3)
            string query = @"
                SELECT ar.Paid_Type, SUM(ar.Total_Amount) as Total, aph.ID as PaymentMethodID
                FROM Account_Receipt ar
                INNER JOIN Account_Receipt_Detail ard ON ar.ID = ard.Receipt_ID
                LEFT JOIN Account_Paid_How aph ON ar.Paid_Type LIKE '%' + aph.Paid_How + '%'
                WHERE ar.Created_Date >= @StartDate AND ar.Created_Date <= @EndDate
                  AND ard.ProductType_ID = 3
                  AND ar.Status LIKE @Status
                  AND (ar.Reservation_ID = 0 OR ar.Reservation_ID IS NULL)
                GROUP BY ar.Paid_Type, aph.ID";

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
            // Others (not in categories 1-3)
            string query = @"
                SELECT ar.Paid_Type, SUM(ar.Total_Amount) as Total, aph.ID as PaymentMethodID
                FROM Account_Receipt ar
                LEFT JOIN Account_Receipt_Detail ard ON ar.ID = ard.Receipt_ID
                LEFT JOIN Account_Paid_How aph ON ar.Paid_Type LIKE '%' + aph.Paid_How + '%'
                WHERE ar.Created_Date >= @StartDate AND ar.Created_Date <= @EndDate
                  AND ar.Status LIKE @Status
                  AND (ar.Reservation_ID = 0 OR ar.Reservation_ID IS NULL)
                  AND (ard.ProductType_ID IS NULL OR ard.ProductType_ID != 3)
                GROUP BY ar.Paid_Type, aph.ID";

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
            decimal total = 0;
            foreach (DataRow row in dt.Rows)
            {
                if (row["PaymentMethodID"] != DBNull.Value &&
                    Convert.ToInt32(row["PaymentMethodID"]) == paymentMethodID)
                {
                    total += row["Total"] != DBNull.Value ? Convert.ToDecimal(row["Total"]) : 0;
                }
            }
            return total;
        }

        private DataTable GetAllReceipts(DateTime startDate, DateTime endDate, string status)
        {
            string query = @"
                SELECT ar.*, c.Name as CustomerName, 'รายได้' as Category
                FROM Account_Receipt ar
                LEFT JOIN Reservation r ON ar.Reservation_ID = r.ID
                LEFT JOIN Customer c ON r.Customer_MobilePhone = c.MobilePhone
                WHERE ar.Created_Date >= @StartDate AND ar.Created_Date <= @EndDate
                  AND ar.Status LIKE @Status
                ORDER BY ar.Created_Date DESC";

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
            var dt = GetAllReceipts(startDate, endDate, ddlStatus.SelectedValue);
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
            // TODO: Implement CSV export
            ShowError("ฟังก์ชั่น Export CSV กำลังพัฒนา");
        }

        private void ShowError(string message)
        {
            // TODO: Implement error display
            ScriptManager.RegisterStartupScript(this, GetType(), "error", $"alert('{message}');", true);
        }
    }
}
