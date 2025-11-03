using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Configuration;
using System.Data;

namespace Take_Time_BangPhra.Admin
{
    public partial class Login : System.Web.UI.Page
    {
        _Default code = new _Default();
        string conn = ConfigurationManager.ConnectionStrings["TaketimeConnectionString"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                if (Session["permission"].ToString() == "True")
                {
                    //Response.Redirect("/ReserveTable.aspx");
                    Button1.Visible = false;
                    Button2.Visible = true;
                    Label9.Text = "Password";
                    Label10.Text = "Confirm Pssword";
                }
            }
            catch
            {
                Button1.Visible = true;
                Button2.Visible = false;
                Label9.Text = "User";
                Label10.Text = "Pssword";
            }
        }

        protected void Button1_Click(object sender, EventArgs e)
        {
            DataTable dtAdmin = code.DatabaseQuery(conn, "Select * from Admin Where Status = 1");
            for (int i = 0; i < dtAdmin.Rows.Count; i++)
            {
                if (TextBox1.Text == dtAdmin.Rows[i]["Username"].ToString() && TextBox2.Text == dtAdmin.Rows[i]["Password"].ToString())
                {
                    Session["permission"] = "True";
                    Session["UserName"] = TextBox1.Text.ToLower();
                    Session["User"] = dtAdmin.Rows[i]["Role"].ToString();
                    Session["UserID"] = dtAdmin.Rows[i]["ID"].ToString();
                    Response.Redirect("/ReserveTable.aspx");
                }
            }


        }

        protected void Button2_Click(object sender, EventArgs e)
        {
            if(TextBox1.Text == TextBox2.Text)
            {
                code.DatabaseInsert(conn, "UPDATE [dbo].[Admin] SET [Password] = '"+TextBox2.Text+"' WHERE ID = "+ Session["UserID"]);
                Response.Redirect("/Admin/Login");
            }
            else
            {
                ClientScript.RegisterStartupScript(this.GetType(), "myalert", "alert('รหัสผ่านยืนยันไม่ตรงกัน');", true);
            }
        }
    }
}