using System;
using System.Configuration;
using System.Data;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Take_Time_BangPhra.Payment
{
    public partial class MakePayment : System.Web.UI.Page
    {
        private readonly string connectionString = ConfigurationManager.ConnectionStrings["ATATB"].ConnectionString;
        private PaymentService paymentService;
        private PaymentDataAccess paymentDataAccess;
        private code codeInstance = new code();

        protected void Page_Load(object sender, EventArgs e)
        {
            paymentService = new PaymentService(connectionString);
            paymentDataAccess = new PaymentDataAccess(connectionString);

            if (!IsPostBack)
            {
                LoadReservationData();
                LoadPaymentHistory();
            }
        }

        private void LoadReservationData()
        {
            int reservationId = GetReservationId();
            if (reservationId == 0)
            {
                ShowError("ไม่พบรหัสการจองที่ระบุ");
                return;
            }

            try
            {
                // Get reservation details
                var parameters = new System.Collections.Generic.Dictionary<string, object>
                {
                    { "@reservationId", reservationId }
                };

                string query = @"
                    SELECT
                        r.ID,
                        r.Customer_MobilePhone,
                        c.Name AS CustomerName,
                        r.CheckinDate,
                        r.CheckoutDate,
                        r.TotalPrice,
                        r.Deposit AS TotalPaid,
                        r.Status
                    FROM Reservation r
                    LEFT JOIN Customer c ON r.Customer_MobilePhone = c.MobilePhone
                    WHERE r.ID = @reservationId";

                DataTable dt = codeInstance.DatabaseQuerySafe(connectionString, query, parameters);

                if (dt.Rows.Count > 0)
                {
                    DataRow row = dt.Rows[0];

                    lblReservationID.Text = row["ID"].ToString();
                    lblCustomerName.Text = row["CustomerName"].ToString();
                    lblCustomerPhone.Text = row["Customer_MobilePhone"].ToString();
                    lblCheckinDate.Text = Convert.ToDateTime(row["CheckinDate"]).ToString("dd/MM/yyyy");
                    lblCheckoutDate.Text = Convert.ToDateTime(row["CheckoutDate"]).ToString("dd/MM/yyyy");

                    decimal totalPrice = Convert.ToDecimal(row["TotalPrice"]);
                    decimal totalPaid = row["TotalPaid"] != DBNull.Value ? Convert.ToDecimal(row["TotalPaid"]) : 0;

                    // Get accurate total paid from Payment_History
                    try
                    {
                        totalPaid = paymentDataAccess.GetTotalPaidAmount(reservationId);
                    }
                    catch
                    {
                        // Fallback to Deposit if Payment_History not available
                    }

                    decimal remainingBalance = totalPrice - totalPaid;

                    lblTotalPrice.Text = totalPrice.ToString("N2");
                    lblTotalPaid.Text = totalPaid.ToString("N2");
                    lblRemainingBalance.Text = remainingBalance.ToString("N2");

                    // Check if already fully paid
                    if (remainingBalance <= 0)
                    {
                        ShowWarning("การจองนี้ชำระเงินครบแล้ว");
                        btnSubmit.Enabled = false;
                    }

                    // Set max amount in textbox
                    txtPaymentAmount.Text = remainingBalance.ToString("0.00");
                }
                else
                {
                    ShowError("ไม่พบข้อมูลการจอง");
                }
            }
            catch (Exception ex)
            {
                ShowError("เกิดข้อผิดพลาดในการโหลดข้อมูล: " + ex.Message);
            }
        }

        private void LoadPaymentHistory()
        {
            int reservationId = GetReservationId();
            if (reservationId == 0) return;

            try
            {
                DataTable dtHistory = paymentDataAccess.GetPaymentHistory(reservationId);
                gvPaymentHistory.DataSource = dtHistory;
                gvPaymentHistory.DataBind();
            }
            catch (Exception ex)
            {
                // If Payment_History table doesn't exist yet, show empty
                gvPaymentHistory.DataSource = null;
                gvPaymentHistory.DataBind();
            }
        }

        protected void btnSubmit_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid) return;

            int reservationId = GetReservationId();
            if (reservationId == 0)
            {
                ShowError("ไม่พบรหัสการจอง");
                return;
            }

            try
            {
                decimal paymentAmount = decimal.Parse(txtPaymentAmount.Text);
                string paymentMethod = ddlPaymentMethod.SelectedValue;
                string notes = txtNotes.Text.Trim();
                string customerPhone = lblCustomerPhone.Text;

                // Validate payment amount
                decimal remainingBalance = decimal.Parse(lblRemainingBalance.Text.Replace(",", ""));
                if (paymentAmount > remainingBalance)
                {
                    ShowError($"จำนวนเงินที่ชำระ ({paymentAmount:N2}) มากกว่ายอดคงเหลือ ({remainingBalance:N2})");
                    return;
                }

                if (paymentAmount <= 0)
                {
                    ShowError("จำนวนเงินต้องมากกว่า 0");
                    return;
                }

                // Get uploaded file
                var slipFile = fuPaymentSlip.HasFile ? fuPaymentSlip.PostedFile : null;

                // Validate slip upload for transfer payment
                if (paymentMethod == "โอนเงิน" && slipFile == null)
                {
                    ShowWarning("แนะนำให้อัพโหลดสลิปการโอนเงินเพื่อยืนยันการชำระ");
                }

                // Get admin ID from session (if available)
                int? adminId = Session["AdminID"] != null ? (int?)Convert.ToInt32(Session["AdminID"]) : null;

                // Process payment
                var result = paymentService.ProcessAdditionalPayment(
                    reservationId,
                    paymentAmount,
                    paymentMethod,
                    slipFile,
                    adminId,
                    customerPhone,
                    notes
                );

                if (result.Success)
                {
                    ShowSuccess($"ชำระเงินสำเร็จ! จำนวน {paymentAmount:N2} บาท<br/>" +
                               $"เลขที่ใบเสร็จ: {result.ReceiptId}<br/>" +
                               $"ยอดคงเหลือ: {result.RemainingBalance:N2} บาท");

                    // Reload data
                    LoadReservationData();
                    LoadPaymentHistory();

                    // Clear form
                    txtPaymentAmount.Text = result.RemainingBalance.ToString("0.00");
                    ddlPaymentMethod.SelectedIndex = 0;
                    txtNotes.Text = "";
                }
                else
                {
                    ShowError("การชำระเงินล้มเหลว: " + result.Message);
                }
            }
            catch (Exception ex)
            {
                ShowError("เกิดข้อผิดพลาด: " + ex.Message);
            }
        }

        private int GetReservationId()
        {
            if (Request.QueryString["id"] != null && int.TryParse(Request.QueryString["id"], out int id))
            {
                return id;
            }
            return 0;
        }

        private void ShowSuccess(string message)
        {
            pnlSuccess.Visible = true;
            pnlError.Visible = false;
            lblSuccess.Text = message;
        }

        private void ShowError(string message)
        {
            pnlError.Visible = true;
            pnlSuccess.Visible = false;
            lblError.Text = message;
        }

        private void ShowWarning(string message)
        {
            pnlError.Visible = true;
            pnlSuccess.Visible = false;
            pnlError.CssClass = "alert alert-warning";
            lblError.Text = message;
        }
    }
}
