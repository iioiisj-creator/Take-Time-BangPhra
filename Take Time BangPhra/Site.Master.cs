using System;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Take_Time_BangPhra
{
    public partial class SiteMaster : MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                if (Session["permission"]?.ToString() == "True")
                {
                    // Set admin navigation labels - shorter and cleaner
                    Label1.Text = "ผู้เข้าพักรายวัน";
                    Label2.Text = "ผู้เข้าพักรายเดือน";
                    Label3.Text = "ผู้เลื่อนเข้าพัก";
                    Label4.Text = "รายงานระบบ";
                    Label5.Text = "ขาย Voucher";
                    Label6.Text = "ฐานข้อมูล";
                    Label7.Text = "ใบสำคัญจ่าย";
                    Label8.Text = "ตรวจสอบเอกสาร";
                    Label9.Text = "ใบเสร็จรับเงิน";
                    Label11.Text = "จ่ายเงิน Affiliate";

                    // Show admin panel and logout button
                    pnlAdminNav.Visible = true;
                    btnLogout.Visible = true;
                    hlLogin.Visible = false;

                    // Check if user is Owner to show owner-only menus
                    bool isOwner = Session["User"]?.ToString() == "Owner";
                    pnlOwnerOnly.Visible = isOwner;
                }
                else
                {
                    // Hide admin controls
                    Label1.Visible = false;
                    Label2.Visible = false;
                    Label3.Visible = false;
                    Label4.Visible = false;
                    Label5.Visible = false;
                    Label6.Visible = false;
                    Label7.Visible = false;
                    Label8.Visible = false;
                    Label9.Visible = false;
                    Label11.Visible = false;

                    // Show login button
                    pnlAdminNav.Visible = false;
                    pnlOwnerOnly.Visible = false;
                    btnLogout.Visible = false;
                    hlLogin.Visible = true;
                }
            }
            catch
            {
                // Hide admin controls on error
                Label1.Visible = false;
                Label2.Visible = false;
                Label3.Visible = false;
                Label4.Visible = false;
                Label5.Visible = false;
                Label6.Visible = false;
                Label7.Visible = false;
                Label8.Visible = false;
                Label9.Visible = false;
                Label11.Visible = false;

                // Show login button
                pnlAdminNav.Visible = false;
                pnlOwnerOnly.Visible = false;
                btnLogout.Visible = false;
                hlLogin.Visible = true;
            }
        }

        protected void btnLogout_Click(object sender, EventArgs e)
        {
            PerformSecureLogout();
        }

        private void PerformSecureLogout()
        {
            try
            {
                // Clear session
                Session.Clear();
                Session.Abandon();

                // Clear authentication cookie
                if (Request.Cookies["ASP.NET_SessionId"] != null)
                {
                    Response.Cookies["ASP.NET_SessionId"].Value = string.Empty;
                    Response.Cookies["ASP.NET_SessionId"].Expires = DateTime.Now.AddMonths(-20);
                }

                // Redirect to home page
                Response.Redirect("~/Default", true);
            }
            catch (Exception ex)
            {
                // Log error and redirect anyway
                System.Diagnostics.Debug.WriteLine($"Logout error: {ex.Message}");
                Response.Redirect("~/Default", true);
            }
        }
    }
}