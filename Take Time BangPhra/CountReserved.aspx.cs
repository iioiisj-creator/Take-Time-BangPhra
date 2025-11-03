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
    public partial class CountReserved : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            _Default code = new _Default();
            string telNum = Request.QueryString["telnum"];
            string conn = ConfigurationManager.ConnectionStrings["TaketimeConnectionString"].ConnectionString;

            DataTable dt = code.DatabaseQuery(conn, "SELECT MobilePhone,[Name],[NickName],AccomName,CheckinDate,CheckoutDate,StayDays,Reservation_Accommodation.Price,TotalPrice FROM [Taketime].[dbo].[Reservation] right join Reservation_Accommodation on Reservation.ID = Reservation_Accommodation.Reservation_ID inner join Accommodation on Accommodation.ID = Accommodation_ID inner join Customer on Customer.MobilePhone=Customer_MobilePhone Where Customer_MobilePhone = '"+telNum+"'  AND Reservation.Status = N'เช็คอินแล้ว' order by CheckinDate desc");
            GridView1.DataSource = dt;
            GridView1.DataBind();
        }
    }
}