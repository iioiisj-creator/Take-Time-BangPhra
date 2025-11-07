using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using iTextSharp;
using System.IO;
using iTextSharp.text;
using iTextSharp.text.pdf;
using System.Security.Cryptography;
using iTextSharp.text.pdf.qrcode;
using System.Text;
using System.Threading.Tasks;

namespace Take_Time_BangPhra
{
    public partial class ReserveTable : Page
    {
        code code2 = new code();
        string conn = ConfigurationManager.ConnectionStrings["TaketimeConnectionString"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            Page.MaintainScrollPositionOnPostBack = true;
            try
            {
                if (Session["permission"]?.ToString() == "True")
                {
                    if (!IsPostBack)
                    {
                        // Select today's date in the calendar
                        Calendar1.SelectedDate = DateTime.Today;
                        Calendar1.VisibleDate = DateTime.Today;

                        // Trigger the selection changed event to load today's reservations
                        Calendar1_SelectionChanged(sender, e);
                    }
                }
                else
                {
                    Response.Redirect("./Default");
                }
            }
            catch
            {
                Response.Redirect("./Default");
            }
        }

        protected void Calendar1_SelectionChanged(object sender, EventArgs e)
        {
            Label1.Text = Calendar1.SelectedDate.ToString("dd MMMM yyyy");

            DataTable dtReservation = DatabaseQuery(conn,
                @"SELECT * FROM Reservation 
                  INNER JOIN Customer ON Customer.MobilePhone = Reservation.Customer_MobilePhone 
                  WHERE @SelectedDate >= CheckinDate AND @SelectedDate < CheckoutDate 
                  AND (Reservation.Status != N'ยกเลิกคืนเงิน' AND Reservation.Status != N'ยกเลิกไม่คืนเงิน')",
                new SqlParameter("@SelectedDate", Calendar1.SelectedDate.ToString("yyyy-MM-dd")));

            DataTable dtReservation_Accom = DatabaseQuery(conn,
                @"SELECT * FROM Reservation 
                  RIGHT JOIN Reservation_Accommodation ON Reservation.ID = Reservation_Accommodation.Reservation_ID 
                  INNER JOIN Accommodation ON Accommodation.ID = Reservation_Accommodation.Accommodation_ID  
                  WHERE @SelectedDate >= CheckinDate AND @SelectedDate < CheckoutDate 
                  ORDER BY Accommodation.orderID ASC",
                new SqlParameter("@SelectedDate", Calendar1.SelectedDate.ToString("yyyy-MM-dd")));

            DataTable dtReservation_Items = DatabaseQuery(conn,
                @"SELECT * FROM Reservation 
                  RIGHT JOIN Reservation_Items ON Reservation.ID = Reservation_Items.Reservation_ID 
                  INNER JOIN Items ON Items.ID = Reservation_Items.Items_ID  
                  WHERE @SelectedDate >= CheckinDate AND @SelectedDate < CheckoutDate 
                  ORDER BY Items_ID ASC",
                new SqlParameter("@SelectedDate", Calendar1.SelectedDate.ToString("yyyy-MM-dd")));

            // Add additional columns if they don't exist
            if (!dtReservation.Columns.Contains("AccomName"))
                dtReservation.Columns.Add("AccomName");
            if (!dtReservation.Columns.Contains("Items"))
                dtReservation.Columns.Add("Items");
            if (!dtReservation.Columns.Contains("Remain"))
                dtReservation.Columns.Add("Remain");
            if (!dtReservation.Columns.Contains("Order"))
                dtReservation.Columns.Add("Order", typeof(int));
            if (!dtReservation.Columns.Contains("CountReserved"))
                dtReservation.Columns.Add("CountReserved");

            for (int i = 0; i < dtReservation.Rows.Count; i++)
            {
                dtReservation.Rows[i]["Name"] = $"{dtReservation.Rows[i]["Name"]} - {dtReservation.Rows[i]["NickName"]} - {dtReservation.Rows[i]["Customer_MobilePhone"]}";

                string AccomName = "";
                int orderID = 99;

                for (int j = 0; j < dtReservation_Accom.Rows.Count; j++)
                {
                    if (dtReservation.Rows[i]["ID"].ToString() == dtReservation_Accom.Rows[j]["Reservation_ID"].ToString())
                    {
                        AccomName += dtReservation_Accom.Rows[j]["AccomName"];
                        if (dtReservation_Accom.Rows[j]["LimitWithPeople"].ToString() == "True")
                        {
                            AccomName += $": ({dtReservation_Accom.Rows[j]["Amount"]}คน)";
                        }
                        AccomName += "\r\n";

                        if (Convert.ToInt32(dtReservation_Accom.Rows[j]["OrderID"]) < orderID)
                        {
                            orderID = Convert.ToInt32(dtReservation_Accom.Rows[j]["OrderID"]);
                        }
                    }
                }

                dtReservation.Rows[i]["Order"] = orderID;
                dtReservation.Rows[i]["AccomName"] = AccomName.Trim();

                string Items = "";
                for (int j = 0; j < dtReservation_Items.Rows.Count; j++)
                {
                    if (dtReservation.Rows[i]["ID"].ToString() == dtReservation_Items.Rows[j]["Reservation_ID"].ToString())
                    {
                        Items += $"[{dtReservation_Items.Rows[j]["ItemName"]} : ({dtReservation_Items.Rows[j]["Amount"]}ชิ้น)] ";
                    }
                }

                dtReservation.Rows[i]["Items"] = Items.Trim();

                // Calculate remaining amount using Payment_History (via SQL function)
                int reservationId = Convert.ToInt32(dtReservation.Rows[i]["ID"]);
                DataTable dtRemain = DatabaseQuery(conn,
                    "SELECT dbo.fn_GetRemainingBalance(@ReservationId) as RemainingBalance",
                    new SqlParameter("@ReservationId", reservationId));

                decimal remainingBalance = 0;
                if (dtRemain.Rows.Count > 0 && dtRemain.Rows[0]["RemainingBalance"] != DBNull.Value)
                {
                    remainingBalance = Convert.ToDecimal(dtRemain.Rows[0]["RemainingBalance"]);
                }
                dtReservation.Rows[i]["Remain"] = remainingBalance.ToString("N0");

                // Get reservation count
                string mobilePhone = dtReservation.Rows[i]["Customer_MobilePhone"].ToString();
                DataTable dtCount = DatabaseQuery(conn,
                    "SELECT COUNT([Customer_MobilePhone]) as CountReserved FROM [Reservation] WHERE Customer_MobilePhone = @MobilePhone AND Status = N'เช็คอินแล้ว'",
                    new SqlParameter("@MobilePhone", mobilePhone));

                dtReservation.Rows[i]["CountReserved"] = dtCount.Rows[0]["CountReserved"].ToString();
            }

            DataView view = dtReservation.DefaultView;
            view.Sort = "Order ASC";
            DataTable sortedReservation = view.ToTable();
            Session["dtShow"] = sortedReservation;

            GridView1.DataSource = sortedReservation;
            GridView1.DataBind();

            // Update button states
            foreach (GridViewRow row in GridView1.Rows)
            {
                if (row.RowType == DataControlRowType.DataRow)
                {
                    // Update button text for reservation count
                    Button bt6 = row.FindControl("Button6") as Button;
                    if (bt6 != null)
                    {
                        string countReserved = sortedReservation.Rows[row.RowIndex]["CountReserved"].ToString();
                        bt6.Text = countReserved + " ครั้ง";
                    }

                    // Check status and update buttons
                    string status = sortedReservation.Rows[row.RowIndex]["Status"].ToString();
                    bool isOwner = Session["User"]?.ToString() == "Owner";

                    if (status == "เช็คอินแล้ว")
                    {
                        // สำหรับการจองที่เช็คอินแล้ว
                        // Admin ทั่วไป: disable เช็คอิน/แก้ไข/ยกเลิก แต่เปิด เช่าเพิ่ม/จ่ายเพิ่ม/เช็คเอาท์/รายละเอียด
                        SetButtonEnabled(row, "Button1", false); // Check-in - ไม่สามารถเช็คอินซ้ำได้
                        SetButtonEnabled(row, "Button2", false); // Edit - ห้ามแก้ไขหลังเช็คอินแล้ว
                        SetButtonEnabled(row, "Button3", false); // Cancel no refund - ห้ามยกเลิกหลังเช็คอิน
                        SetButtonEnabled(row, "Button4", false); // Cancel with refund - ห้ามยกเลิกหลังเช็คอิน
                        // Button5 (เช่าเพิ่ม), Button8 (จ่ายเพิ่ม), Button9 (เช็คเอาท์), Button7 (รายละเอียด) ยังใช้งานได้

                        // Owner permissions - สามารถแก้ไข/ยกเลิกได้แม้หลังเช็คอิน
                        if (isOwner)
                        {
                            SetButtonEnabled(row, "Button2", true);  // Edit
                            SetButtonEnabled(row, "Button3", true);  // Cancel no refund
                            SetButtonEnabled(row, "Button4", true);  // Cancel with refund
                        }
                    }
                    else if (status == "เช็คเอ้าท์แล้ว")
                    {
                        // 🔧 สำหรับการจองที่เช็คเอาท์แล้ว (เสร็จสิ้น)
                        // ทุกคน: เห็นเฉพาะ รายละเอียด และ ประวัติ
                        SetButtonEnabled(row, "Button1", false); // Check-in
                        SetButtonEnabled(row, "Button2", false); // Edit
                        SetButtonEnabled(row, "Button3", false); // Cancel no refund
                        SetButtonEnabled(row, "Button4", false); // Cancel with refund
                        SetButtonEnabled(row, "Button5", false); // Rent more
                        SetButtonEnabled(row, "Button8", false); // Pay more
                        SetButtonEnabled(row, "Button9", false); // Checkout

                        // Button7 (รายละเอียด) และ Button6 (ประวัติ) ยังใช้งานได้สำหรับทุกคน
                    }
                    // สถานะอื่นๆ (มัดจำแล้ว, รอเช็คอิน ฯลฯ): ปุ่มทั้งหมดเปิดใช้งานตามปกติ
                }
            }
        }

        private void SetButtonEnabled(GridViewRow row, string buttonId, bool enabled)
        {
            Button button = row.FindControl(buttonId) as Button;
            if (button != null)
            {
                button.Enabled = enabled;
                if (!enabled)
                {
                    button.CssClass = button.CssClass.Replace("btn-success", "btn-outline-success")
                                                     .Replace("btn-warning", "btn-outline-warning")
                                                     .Replace("btn-danger", "btn-outline-danger")
                                                     .Replace("btn-secondary", "btn-outline-secondary");
                }
            }
        }

        public int DatabaseInsert(string connStr, string cmd, params SqlParameter[] parameters)
        {
            int ID = 0;
            using (SqlConnection connection = new SqlConnection(connStr))
            {
                using (SqlCommand command = new SqlCommand(cmd, connection))
                {
                    cmd = cmd.Replace("&nbsp;", "");
                    command.Parameters.AddRange(parameters);
                    connection.Open();
                    try
                    {
                        object result = command.ExecuteScalar();
                        if (result != null && result != DBNull.Value)
                        {
                            ID = Convert.ToInt32(result);
                        }
                    }
                    catch (Exception ex)
                    {
                        // Log exception if needed
                    }
                    connection.Close();
                }
            }
            return ID;
        }

        public DataTable DatabaseQuery(string connStr, string cmd, params SqlParameter[] parameters)
        {
            DataTable dt = new DataTable();
            using (SqlConnection con = new SqlConnection(connStr))
            {
                try
                {
                    cmd = cmd.Replace("&amp;", "&")
                            .Replace("&#39;", "''")
                            .Replace("&nbsp;", "");

                    SqlDataAdapter adapter = new SqlDataAdapter(cmd, con);
                    adapter.SelectCommand.Parameters.AddRange(parameters);
                    adapter.Fill(dt);
                }
                catch (Exception ex)
                {
                    // Log exception if needed
                }
            }
            return dt;
        }

        protected void Calendar1_DayRender(object sender, DayRenderEventArgs e)
        {
            DataTable dtReservation = DatabaseQuery(conn,
                @"SELECT * FROM Reservation 
                  RIGHT JOIN Reservation_Accommodation ON Reservation.ID = Reservation_Accommodation.Reservation_ID 
                  WHERE @SelectedDate >= CheckinDate AND @SelectedDate < CheckoutDate",
                new SqlParameter("@SelectedDate", e.Day.Date.ToString("yyyy-MM-dd")));

            DataTable dtAccommodation = DatabaseQuery(conn, "SELECT * FROM Accommodation WHERE Status = 1");
            int maxAccommodation = dtAccommodation.Rows.Count;

            for (int j = 0; j < dtAccommodation.Rows.Count; j++)
            {
                for (int i = 0; i < dtReservation.Rows.Count; i++)
                {
                    if (dtReservation.Rows[i]["Accommodation_ID"].ToString() == dtAccommodation.Rows[j]["ID"].ToString() ||
                        dtAccommodation.Rows[j]["LimitWithPeople"].ToString() == "True")
                    {
                        dtAccommodation.Rows.RemoveAt(j);
                        dtAccommodation.AcceptChanges();
                        i = dtReservation.Rows.Count + 1;
                        j = -1;
                        break;
                    }
                }
            }

            if (dtAccommodation.Rows.Count == 0)
            {
                e.Cell.ForeColor = System.Drawing.Color.Red;
                e.Cell.Font.Bold = true;
            }
            else if (dtAccommodation.Rows.Count == maxAccommodation)
            {
                e.Cell.ForeColor = System.Drawing.Color.DarkGreen;
            }
        }

        protected async void GridView1_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            DataTable dtShow = (DataTable)Session["dtShow"];
            if (dtShow == null) return;

            string commandArg = e.CommandArgument?.ToString();
            if (string.IsNullOrEmpty(commandArg)) return;

            switch (e.CommandName)
            {
                case "Checkin":
                case "EditReservation":
                case "RentMore":
                case "CancelNoRefund":
                case "CancelRefund":
                case "CountReserved":
                case "PayMore":
                case "Checkout":
                    // สำหรับคำสั่งเหล่านี้ใช้ ID การจอง
                    DataTable dtCustomer = DatabaseQuery(conn,
                        @"SELECT Customer.MobilePhone FROM [Reservation]
                          INNER JOIN Customer ON Customer.MobilePhone = Reservation.Customer_MobilePhone
                          WHERE Reservation.ID = @ReservationId",
                        new SqlParameter("@ReservationId", commandArg));

                    if (dtCustomer.Rows.Count == 0) return;

                    string customerPhone = dtCustomer.Rows[0]["MobilePhone"].ToString();

                    if (e.CommandName == "Checkin")
                    {
                        Response.Redirect($"./Reserve?command=checkin&date={Calendar1.SelectedDate:yyyy-MM-dd}&id={commandArg}&check={customerPhone}", false);
                    }
                    else if (e.CommandName == "EditReservation")
                    {
                        Response.Redirect($"./Reserve?command=edit&date={Calendar1.SelectedDate:yyyy-MM-dd}&id={commandArg}&check={customerPhone}", false);
                    }
                    else if (e.CommandName == "RentMore")
                    {
                        Response.Redirect($"./Reserve?command=rentmore&date={Calendar1.SelectedDate:yyyy-MM-dd}&id={commandArg}&check={customerPhone}", false);
                    }
                    else if (e.CommandName == "PayMore")
                    {
                        Response.Redirect($"./Payment/MakePayment?id={commandArg}", false);
                    }
                    else if (e.CommandName == "Checkout")
                    {
                        Response.Redirect($"./Checkout?id={commandArg}", false);
                    }
                    else if (e.CommandName == "CancelNoRefund")
                    {
                        await CancelReservation(commandArg, false);
                        Response.Redirect("./ReserveTable", false);
                    }
                    else if (e.CommandName == "CancelRefund")
                    {
                        await CancelReservation(commandArg, true);
                        Response.Redirect("./ReserveTable", false);
                    }
                    else if (e.CommandName == "CountReserved")
                    {
                        Response.Redirect($"./CountReserved?telnum={customerPhone}", false);
                    }
                    break;

                case "Detail":
                    // สำหรับปุ่มรายละเอียดใช้ DataItemIndex
                    int rowIndex = Convert.ToInt32(commandArg);
                    if (rowIndex >= 0 && rowIndex < dtShow.Rows.Count)
                    {
                        string reservationId = dtShow.Rows[rowIndex]["ID"].ToString();
                        string customerMobile = dtShow.Rows[rowIndex]["Customer_MobilePhone"].ToString();
                        Response.Redirect($"./Reservation_Confirmed?id={reservationId}&check={customerMobile}", false);
                    }
                    break;
            }

            Context.ApplicationInstance.CompleteRequest();
        }

        private async Task CancelReservation(string reservationId, bool refund)
        {
            string status = refund ? "ยกเลิกคืนเงิน" : "ยกเลิกไม่คืนเงิน";

            // 🔧 FIX: Cancel Payment_History records first
            try
            {
                string cancelNote = refund ? $"ยกเลิกจากการยกเลิกการจอง (คืนเงิน) ID: {reservationId}" :
                                            $"ยกเลิกจากการยกเลิกการจอง (ไม่คืนเงิน) ID: {reservationId}";

                DatabaseInsert(conn,
                    @"UPDATE [dbo].[Payment_History]
                      SET Status = 'CANCELLED', Notes = @Notes
                      WHERE Reservation_ID = @ReservationId AND Status = 'COMPLETED'",
                    new SqlParameter("@Notes", cancelNote),
                    new SqlParameter("@ReservationId", reservationId));

                System.Diagnostics.Debug.WriteLine($"✅ Cancelled Payment_History for Reservation {reservationId}");
            }
            catch (Exception phEx)
            {
                System.Diagnostics.Debug.WriteLine($"⚠️ Failed to cancel Payment_History: {phEx.Message}");
                // Continue - this is non-critical
            }

            // Update reservation status
            string updateCmd = refund ?
                "UPDATE [dbo].[Reservation] SET TotalPrice = 0, Deposit = 0, [Status] = @Status WHERE ID = @ReservationId" :
                "UPDATE [dbo].[Reservation] SET TotalPrice = 0, [Status] = @Status WHERE ID = @ReservationId";

            DatabaseInsert(conn, updateCmd,
                new SqlParameter("@Status", status),
                new SqlParameter("@ReservationId", reservationId));

            // Send Telegram notification
            await SendTelegramNotification(reservationId, refund);

            // Delete related records
            DatabaseInsert(conn, "DELETE FROM [dbo].[Reservation_Accommodation] WHERE Reservation_ID = @ReservationId",
                new SqlParameter("@ReservationId", reservationId));

            DatabaseInsert(conn, "DELETE FROM [dbo].[Reservation_Items] WHERE Reservation_ID = @ReservationId",
                new SqlParameter("@ReservationId", reservationId));

            if (refund)
            {
                ProcessRefund(reservationId);
            }
        }

        private async Task SendTelegramNotification(string reservationId, bool refund)
        {
            try
            {
                DataTable dt = DatabaseQuery(conn,
                    @"SELECT r.ID, r.Customer_MobilePhone, c.Name, c.NickName,
                      ra.Accommodation_ID, a.AccomName, r.CheckinDate, r.CheckoutDate,
                      r.StayDays, r.TotalPrice,
                      dbo.fn_GetTotalPaid(r.ID) AS TotalPaid
                      FROM [Reservation] r
                      INNER JOIN Reservation_Accommodation ra ON r.ID = ra.Reservation_ID
                      INNER JOIN Accommodation a ON a.ID = ra.Accommodation_ID
                      INNER JOIN Customer c ON c.MobilePhone = r.Customer_MobilePhone
                      WHERE r.ID = @ReservationId",
                    new SqlParameter("@ReservationId", reservationId));

                if (dt.Rows.Count > 0)
                {
                    string customerName = $"{dt.Rows[0]["Name"]} ({dt.Rows[0]["NickName"]})";
                    string phone = dt.Rows[0]["Customer_MobilePhone"].ToString();
                    DateTime checkinDate = Convert.ToDateTime(dt.Rows[0]["CheckinDate"]);
                    DateTime checkoutDate = Convert.ToDateTime(dt.Rows[0]["CheckoutDate"]);
                    int stayDays = Convert.ToInt32(dt.Rows[0]["StayDays"]);
                    decimal totalPrice = Convert.ToDecimal(dt.Rows[0]["TotalPrice"]);
                    decimal deposit = Convert.ToDecimal(dt.Rows[0]["TotalPaid"]);

                    StringBuilder roomDetails = new StringBuilder();
                    foreach (DataRow row in dt.Rows)
                    {
                        roomDetails.AppendLine($"   • {row["AccomName"]}");
                    }

                    string message = refund ?
                        $@"✅ *ยกเลิกการจอง (คืนเงิน)*

📋 *รายละเอียดการจอง:*
   🆔 หมายเลขการจอง: {reservationId}
   👤 ลูกค้า: {customerName}
   📞 โทรศัพท์: {phone}
   📅 เช็คอิน: {checkinDate:dd MMMM yyyy}
   📅 เช็คเอ้าท์: {checkoutDate:dd MMMM yyyy}
   🕐 จำนวนคืน: {stayDays} คืน
   💰 ราคารวม: {totalPrice:N0} บาท
   💵 มัดจำที่คืน: {deposit:N0} บาท

🏨 *ห้องพักที่ยกเลิก:*
{roomDetails}

💸 *หมายเหตุ:* คืนเงินมัดจำให้ลูกค้าแล้ว" :
                        $@"❌ *ยกเลิกการจอง (ไม่คืนเงิน)*

📋 *รายละเอียดการจอง:*
   🆔 หมายเลขการจอง: {reservationId}
   👤 ลูกค้า: {customerName}
   📞 โทรศัพท์: {phone}
   📅 เช็คอิน: {checkinDate:dd MMMM yyyy}
   📅 เช็คเอ้าท์: {checkoutDate:dd MMMM yyyy}
   🕐 จำนวนคืน: {stayDays} คืน
   💰 ราคารวม: {totalPrice:N0} บาท
   💵 มัดจำ: {deposit:N0} บาท

🏨 *ห้องพักที่ยกเลิก:*
{roomDetails}

⚠️ *หมายเหตุ:* ยกเลิกไม่คืนเงิน";

                    var bot = new TelegramBot2(ConfigurationManager.AppSettings["TelegramTokenTakeTime"]);
                    await bot.SendMessageAsync("-4969611371", message);
                }
            }
            catch (Exception ex)
            {
                // Log error if needed
            }
        }

        private void ProcessRefund(string reservationId)
        {
            string path = ConfigurationManager.AppSettings["ReceiptFolderPath"];
            string Imagespath = ConfigurationManager.AppSettings["ImagesFolderPath"];
            DataTable dtRec = DatabaseQuery(conn,
                "SELECT * FROM Account_Receipt WHERE Status = 'Normal' AND Reservation_ID = @ReservationId",
                new SqlParameter("@ReservationId", reservationId));

            for (int i = 0; i < dtRec.Rows.Count; i++)
            {
                string receiptId = dtRec.Rows[i]["ID"].ToString();

                // ✅ 1. Delete Payment_History records for this receipt
                DatabaseInsert(conn,
                    "DELETE FROM [dbo].[Payment_History] WHERE Receipt_ID = @ReceiptId",
                    new SqlParameter("@ReceiptId", receiptId));

                // ✅ 2. Update receipt status to Cancel
                DatabaseInsert(conn,
                    "UPDATE [dbo].[Account_Receipt] SET [Status] = 'Cancel' WHERE ID = @ReceiptId",
                    new SqlParameter("@ReceiptId", receiptId));

                // ✅ 3. Stamp "Cancel" on PDF
                string uid = dtRec.Rows[i]["UID"].ToString();
                DateTime createdDate = Convert.ToDateTime(dtRec.Rows[i]["Created_Date"]);

                ProcessReceiptFile(path, Imagespath, receiptId, uid, createdDate);
            }
        }

        private void ProcessReceiptFile(string path, string imagesPath, string receiptId, string uid, DateTime createdDate)
        {
            string inputPdfPath = GetFilePath(path, createdDate, receiptId, uid, "");
            string outputPdfPath = GetFilePath(path, createdDate, receiptId, uid, "_Cancel");

            if (File.Exists(inputPdfPath))
            {
                try
                {
                    using (Stream inputPdfStream = new FileStream(inputPdfPath, FileMode.Open, FileAccess.Read, FileShare.Read))
                    using (Stream inputImageStream = new FileStream(Path.Combine(imagesPath, "Cancel.png"), FileMode.Open, FileAccess.Read, FileShare.Read))
                    using (Stream outputPdfStream = new FileStream(outputPdfPath, FileMode.Create, FileAccess.Write, FileShare.None))
                    {
                        var reader = new PdfReader(inputPdfStream);
                        var stamper = new PdfStamper(reader, outputPdfStream);
                        var pdfContentByte = stamper.GetOverContent(1);

                        iTextSharp.text.Image image = iTextSharp.text.Image.GetInstance(inputImageStream);
                        image.SetAbsolutePosition(100, 100);
                        pdfContentByte.AddImage(image);
                        stamper.Close();
                    }
                    File.Delete(inputPdfPath);

                    // Try to delete e-tax file if exists
                    string etaxPath = inputPdfPath.Replace(".pdf", "_etax.pdf");
                    if (File.Exists(etaxPath))
                    {
                        File.Delete(etaxPath);
                    }
                }
                catch (Exception ex)
                {
                    // Log file processing error
                }
            }
        }

        private string GetFilePath(string basePath, DateTime date, string receiptId, string uid, string suffix)
        {
            string yearPath = Path.Combine(basePath, date.Year.ToString());
            string monthPath = Path.Combine(yearPath, date.Month.ToString());

            // Create directory if it doesn't exist
            if (!Directory.Exists(monthPath))
            {
                Directory.CreateDirectory(monthPath);
            }

            string fileName = string.IsNullOrEmpty(uid) ?
                $"{receiptId}{suffix}.pdf" :
                $"{receiptId}_{uid}{suffix}.pdf";

            return Path.Combine(monthPath, fileName);
        }

        protected void btnPrint_Click(object sender, EventArgs e)
        {

        }
    }
}