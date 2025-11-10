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

            // 🔧 FIX: Include checked-out and completed status + use parameterized query for security
            var parameters = new Dictionary<string, object>
            {
                { "@MobilePhone", telNum }
            };

            DataTable dt = code.DatabaseQuerySafe(conn,
                @"SELECT MobilePhone, [Name], [NickName], AccomName, CheckinDate, CheckoutDate, StayDays,
                         Reservation_Accommodation.Price, TotalPrice
                  FROM [Taketime].[dbo].[Reservation]
                  RIGHT JOIN Reservation_Accommodation ON Reservation.ID = Reservation_Accommodation.Reservation_ID
                  INNER JOIN Accommodation ON Accommodation.ID = Accommodation_ID
                  INNER JOIN Customer ON Customer.MobilePhone = Customer_MobilePhone
                  WHERE Customer_MobilePhone = @MobilePhone
                    AND Reservation.Status IN (N'เช็คอินแล้ว', N'เช็คเอาท์แล้ว', N'เสร็จสิ้น')
                  ORDER BY CheckinDate DESC",
                parameters);
            GridView1.DataSource = dt;
            GridView1.DataBind();
        }
    }
}