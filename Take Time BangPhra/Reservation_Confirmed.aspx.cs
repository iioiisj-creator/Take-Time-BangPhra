using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.IO;

namespace Take_Time_BangPhra
{
    public partial class Reservation_Confirmed : System.Web.UI.Page
    {
        code code2 = new code();
        _Default code = new _Default();
        string conn = ConfigurationManager.ConnectionStrings["TaketimeConnectionString"].ConnectionString;

        protected async void Page_Load(object sender, EventArgs e)
        {
            Page.MaintainScrollPositionOnPostBack = true;
            try
            {
                string id = Request.QueryString["id"];
                string check = Request.QueryString["check"];

                DataTable dtReservationAccommodation = code.DatabaseQuery(conn,
                    "SELECT * FROM [Reservation] left join Customer on Customer.MobilePhone = Customer_MobilePhone " +
                    "right join Reservation_Accommodation on Reservation.ID = Reservation_Accommodation.Reservation_ID " +
                    "inner join Accommodation on Accommodation.ID = Accommodation_ID " +
                    "where Reservation.ID = " + id + " AND Customer_MobilePhone = '" + check + "' order by Accommodation.OrderID asc");

                // 🔍 Check if data exists
                if (dtReservationAccommodation == null || dtReservationAccommodation.Rows.Count == 0)
                {
                    Label10.Text = "ไม่พบข้อมูลการจอง - กรุณาตรวจสอบรหัสการจองและเบอร์โทรศัพท์";
                    code2.Logs(conn, "Reservation_Confirmed - No Data",
                        $"ID: {id}, Check: {check} - No reservation data found",
                        "SYSTEM");
                    return;
                }

                // Load payment slips from Payment_History
                LoadPaymentSlips(id, check);

                // Set basic information
                Label1.Text = id;
                Label2.Text = dtReservationAccommodation.Rows[0]["Name"].ToString();
                Label3.Text = dtReservationAccommodation.Rows[0]["NickName"].ToString();
                Label4.Text = check;
                Label5.Text = DateTime.Parse(dtReservationAccommodation.Rows[0]["CheckinDate"].ToString()).ToString("dd MMMM yyyy");
                Label6.Text = DateTime.Parse(dtReservationAccommodation.Rows[0]["CheckoutDate"].ToString()).ToString("dd MMMM yyyy");
                Label7.Text = dtReservationAccommodation.Rows[0]["StayDays"].ToString() + " คืน";

                // Set accommodation details with number of guests
                DataTable dtReservation = code.DatabaseQuery(conn,
                    "SELECT * FROM [Reservation] right join Reservation_Accommodation on Reservation.ID = Reservation_Accommodation.Reservation_ID " +
                    "inner join Accommodation on Accommodation.ID = Accommodation_ID " +
                    "where Reservation.ID = " + id + " order by Accommodation.OrderID asc");

                string Accom = "";
                for (int i = 0; i < dtReservation.Rows.Count; i++)
                {
                    int price = Convert.ToInt32(dtReservation.Rows[i]["Price"].ToString());
                    string peopleInfo = "";

                    // แสดงจำนวนผู้เข้าพักสำหรับแต่ละห้อง
                    if (dtReservation.Rows[i]["LimitWithPeople"].ToString() == "True")
                    {
                        peopleInfo = $" (จำนวนผู้เข้าพัก: {dtReservation.Rows[i]["Amount"].ToString()} คน)";
                    }
                    else
                    {
                        // ถ้าไม่ได้จำกัดจำนวนคนตาม Amount ให้ใช้ค่าเริ่มต้นหรือดึงจาก Reservation
                        peopleInfo = " (จำนวนผู้เข้าพัก: 2 คน)"; // หรือดึงจากฟิลด์อื่นที่เหมาะสม
                    }

                    Accom += $"• {dtReservation.Rows[i]["AccomName"].ToString()}{peopleInfo} - ฿{price:n0} บาท\r\n";
                }
                Label8.Text = Accom;

                // Set rent items
                string Items = "";
                DataTable dtReservationItems = code.DatabaseQuery(conn,
                    "SELECT * FROM [Reservation] right join Reservation_Items on Reservation.ID = Reservation_Items.Reservation_ID " +
                    "inner join Items on Items.ID = Items_ID where Reservation.ID = " + id);

                for (int i = 0; i < dtReservationItems.Rows.Count; i++)
                {
                    int price = Convert.ToInt32(dtReservationItems.Rows[i]["Price"].ToString()) * Convert.ToInt32(dtReservationItems.Rows[i]["Amount"].ToString());
                    Items += $"• {dtReservationItems.Rows[i]["ItemName"].ToString()} ({dtReservationItems.Rows[i]["Amount"].ToString()} ชิ้น) - ฿{price:n0} บาท\r\n";
                }
                Label9.Text = Items;

                // Set payment information using Payment_History
                int totalPrice = Convert.ToInt32(dtReservationAccommodation.Rows[0]["totalPrice"]);
                Label11.Text = totalPrice.ToString("n0");

                // Get total paid and remaining balance from Payment_History
                DataTable dtPayment = code.DatabaseQuery(conn,
                    $"SELECT dbo.fn_GetTotalPaid({id}) as TotalPaid, dbo.fn_GetRemainingBalance({id}) as RemainingBalance");

                decimal totalPaid = 0;
                decimal remainingBalance = totalPrice;
                if (dtPayment.Rows.Count > 0)
                {
                    totalPaid = dtPayment.Rows[0]["TotalPaid"] != DBNull.Value
                        ? Convert.ToDecimal(dtPayment.Rows[0]["TotalPaid"]) : 0;
                    remainingBalance = dtPayment.Rows[0]["RemainingBalance"] != DBNull.Value
                        ? Convert.ToDecimal(dtPayment.Rows[0]["RemainingBalance"]) : totalPrice;
                }

                Label12.Text = totalPaid.ToString("n0");
                Label13.Text = remainingBalance.ToString("n0");
                Label14.Text = dtReservationAccommodation.Rows[0]["Remark"].ToString();

                Label10.Text = "ยืนยันการจองสำเร็จ ✓";

                // Check if receipt exists and show receipt button
                CheckReceiptAvailability(id);
            }
            catch (Exception ex)
            {
                Label10.Text = "ยืนยันการจองผิดพลาด: " + ex.Message;

                // Log detailed error for debugging
                code2.Logs(conn, "Reservation_Confirmed Error",
                    $"ID: {Request.QueryString["id"]}, Check: {Request.QueryString["check"]}, Error: {ex.Message}, StackTrace: {ex.StackTrace}",
                    "SYSTEM");

                // Show detailed error in development
                System.Diagnostics.Debug.WriteLine($"Reservation_Confirmed Error: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"StackTrace: {ex.StackTrace}");
            }
        }

        private void LoadPaymentSlips(string reservationId, string customerPhone)
        {
            try
            {
                // Query payment slips from Payment_History + Payment_Slips
                string query = @"
                    SELECT
                        ph.PaymentDate,
                        ph.PaymentAmount,
                        ph.PaymentType,
                        ph.PaymentMethod,
                        ps.SlipFileURL,
                        ps.FileName
                    FROM Payment_History ph
                    LEFT JOIN Payment_Slips ps ON ph.PaymentSlip_ID = ps.ID
                    WHERE ph.Reservation_ID = @ReservationId
                      AND ph.Status = 'COMPLETED'
                    ORDER BY ph.PaymentDate DESC";

                var parameters = new Dictionary<string, object>
                {
                    { "@ReservationId", reservationId }
                };

                DataTable dtSlips = code2.DatabaseQuerySafe(conn, query, parameters);

                if (dtSlips.Rows.Count > 0)
                {
                    // Show slip count
                    lblSlipCount.Text = $"💳 มีการโอนเงินทั้งหมด {dtSlips.Rows.Count} ครั้ง";
                    lblSlipCount.Visible = true;

                    // Bind to repeater
                    rptPaymentSlips.DataSource = dtSlips;
                    rptPaymentSlips.DataBind();
                    rptPaymentSlips.Visible = true;

                    // Hide old image control
                    Image1.Visible = false;
                }
                else
                {
                    // Fallback to old slip image if no Payment_History records found
                    lblSlipCount.Text = "💳 ใช้รูปสลิปจากระบบเดิม";
                    lblSlipCount.Visible = true;
                    rptPaymentSlips.Visible = false;

                    Image1.ImageUrl = "./Upload/Slip/" + reservationId + "_" + customerPhone + ".jpg";
                    Image1.Visible = true;
                    Image1.DataBind();
                }
            }
            catch (Exception ex)
            {
                // Log error and fallback to old image
                lblSlipCount.Text = "⚠️ ไม่สามารถโหลดสลิปได้ แสดงรูปจากระบบเดิม";
                lblSlipCount.Visible = true;
                rptPaymentSlips.Visible = false;

                Image1.ImageUrl = "./Upload/Slip/" + reservationId + "_" + customerPhone + ".jpg";
                Image1.Visible = true;
                Image1.DataBind();

                code2.Logs(conn, "LoadPaymentSlips Error", ex.Message + " - " + ex.StackTrace, "SYSTEM");
            }
        }



        protected void btnViewReceipt_Click(object sender, EventArgs e)
        {
            string id = Request.QueryString["id"];
            string check = Request.QueryString["check"];

            try
            {
                DataTable dtReceipt = code.DatabaseQuery(conn,
                    $"SELECT UID, Created_Date, ID FROM [Account_Receipt] WHERE Reservation_ID = '{id}' AND Status = 'Normal'");

                if (dtReceipt.Rows.Count > 0)
                {
                    string receiptUID = dtReceipt.Rows[0]["UID"].ToString();
                    DateTime createdDate = Convert.ToDateTime(dtReceipt.Rows[0]["Created_Date"]);

                    string year = createdDate.Year.ToString();
                    string month = createdDate.Month.ToString("00"); // แปลงเป็น 2 หลัก
                    string receiptId = dtReceipt.Rows[0]["ID"].ToString();

                    // สร้าง path ไปยัง PDF file
                    string pdfPath = $"/Documents/Receipt/{year}/{month}/{receiptId}_{receiptUID}.pdf";

                    // เปิด PDF ในหน้าต่างใหม่หรือแท็บใหม่
                    string script = $@"
                <script type='text/javascript'>
                    window.open('{pdfPath}', '_blank', 'width=800,height=600,scrollbars=yes,resizable=yes');
                </script>";
                    ClientScript.RegisterStartupScript(this.GetType(), "openPDF", script, false);
                }
                else
                {
                    ClientScript.RegisterStartupScript(this.GetType(), "alert",
                        "alert('ไม่พบใบกำกับภาษีสำหรับการจองนี้');", true);
                }
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(this.GetType(), "alert",
                    $"alert('เกิดข้อผิดพลาด: {ex.Message}');", true);
            }
        }

        private void CheckReceiptAvailability(string reservationId)
        {
            try
            {
                // Check if receipt exists in database
                DataTable dtReceipt = code.DatabaseQuery(conn,
                    $"SELECT * FROM [Account_Receipt] WHERE Reservation_ID = '{reservationId}' AND Status = 'Normal'");

                if (dtReceipt.Rows.Count > 0)
                {
                    pnlReceipt.Visible = true;
                    btnViewReceipt.Visible = true;

                    // เก็บ UID ของใบกำกับภาษีไว้ใน ViewState เพื่อใช้ใน btnViewReceipt_Click
                    ViewState["ReceiptUID"] = dtReceipt.Rows[0]["UID"].ToString();
                }
                else
                {
                    pnlReceipt.Visible = false;
                    btnViewReceipt.Visible = false;
                }
            }
            catch (Exception ex)
            {
                pnlReceipt.Visible = false;
                btnViewReceipt.Visible = false;
                // คุณอาจต้องการ log error นี้
            }
        }

        private void GenerateAndDownloadReceipt(string reservationId)
        {
            // Implement PDF receipt generation and download
            // This is just a placeholder - you'll need to implement your PDF generation logic
            /*
            string filePath = GenerateReceiptPDF(reservationId);
            if (File.Exists(filePath))
            {
                Response.ContentType = "application/pdf";
                Response.AppendHeader("Content-Disposition", "attachment; filename=Receipt_" + reservationId + ".pdf");
                Response.TransmitFile(filePath);
                Response.End();
            }
            */
        }
    }
}