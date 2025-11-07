using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data;
using System.Configuration;

namespace Take_Time_BangPhra.Admin
{
    public partial class Vendor : System.Web.UI.Page
    {
        _Default code = new _Default();
        string conn = ConfigurationManager.ConnectionStrings["TaketimeConnectionString"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                if (Session["permission"].ToString() == "True")
                {

                    if(!IsPostBack)
                    {
                        DataTable dtCustomerType = code.DatabaseQuery(conn, "Select [Customer_Type],ID From Customer_Type");
                        for (int i = 0; i < dtCustomerType.Rows.Count; i++)
                        {
                            DropDownList1.Items.Add(new ListItem(dtCustomerType.Rows[i][0].ToString(), dtCustomerType.Rows[i][1].ToString()));
                        }
                        DropDownList1.DataBind();

                        DataTable dtVendorCategory = code.DatabaseQuery(conn, "Select DISTINCT [Vendor_Group] From Vendor");
                        for (int i = 0; i < dtVendorCategory.Rows.Count; i++)
                        {
                            DropDownList5.Items.Add(new ListItem(dtVendorCategory.Rows[i][0].ToString(), dtVendorCategory.Rows[i][0].ToString()));
                        }
                        DropDownList5.DataBind();

                        getAddress("SELECT DISTINCT [Province] FROM [Address] order by Province ASC", "SELECT DISTINCT [District] FROM [Address] order by District ASC", "SELECT DISTINCT [SubDistrict] FROM [Address] order by SubDistrict ASC");

                    }
                }
                else
                {
                    Response.Redirect("/Default");
                }
            }
            catch { Response.Redirect("/Default");  }
        }

        protected void TextBox1_TextChanged(object sender, EventArgs e)
        {
            // ✅ รองรับการค้นหาด้วย Tax ID (13 หลัก)
            if(TextBox1.Text.Length == 13)
            {
                DataTable dt = code.DatabaseQuery(conn, "Select * from Vendor left join Customer_Type on Customer_Type.ID = Vendor_Type_ID left join Address on Address.ID = Address_ID Where IDNumber = '"+TextBox1.Text+"'");
                if(dt.Rows.Count > 0)
                {
                    TextBox2.Text = dt.Rows[0]["Name"].ToString();
                    TextBox3.Text = dt.Rows[0]["Branch_Number"].ToString();
                    TextBox7.Text = dt.Rows[0]["Phone_Number"].ToString();
                    TextBox4.Text = dt.Rows[0]["Address"].ToString();
                    TextBox5.Text = dt.Rows[0]["Address1"].ToString();

                    try //Address
                    {
                        TextBox6.Text = dt.Rows[0]["PostalCode"].ToString();
                        DropDownList2.ClearSelection();
                        DropDownList2.Items.FindByText(dt.Rows[0]["Province"].ToString()).Selected = true;
                        DropDownList2.SelectedIndex = DropDownList2.Items.IndexOf(DropDownList2.Items.FindByText(dt.Rows[0]["Province"].ToString()));
                        DropDownList3.ClearSelection();
                        DropDownList3.Items.FindByText(dt.Rows[0]["District"].ToString()).Selected = true;
                        DropDownList3.SelectedIndex = DropDownList3.Items.IndexOf(DropDownList3.Items.FindByText(dt.Rows[0]["District"].ToString()));
                        DropDownList4.ClearSelection();
                        DropDownList4.Items.FindByText(dt.Rows[0]["SubDistrict"].ToString()).Selected = true;
                        DropDownList4.SelectedIndex = DropDownList4.Items.IndexOf(DropDownList4.Items.FindByText(dt.Rows[0]["SubDistrict"].ToString()));

                        DropDownList1.ClearSelection();
                        DropDownList1.Items.FindByValue(dt.Rows[0]["Customer_Type_ID"].ToString()).Selected = true;
                        DropDownList1.SelectedIndex = DropDownList1.Items.IndexOf(DropDownList1.Items.FindByValue(dt.Rows[0]["Customer_Type_ID"].ToString()));

                    }
                    catch { }

                }
            }
        }

        public string CheckAddressID(string ZipCode, string Province, string District, string SubDistrict)
        {
            string ID = "0";

            try
            {
                DataTable dt = code.DatabaseQuery(conn, "Select ID from Address Where PostalCode = '" + ZipCode + "' AND Province = N'" + Province + "' AND District = N'" + District + "' AND SubDistrict = N'" + SubDistrict + "'");
                ID = dt.Rows[0][0].ToString();
            }
            catch { }

            return ID;
        }

        public void getAddress(string commp, string commd, string commsd)
        {
            string Command = Request.QueryString["Command"];
            string ID = Request.QueryString["ID"];
            DataTable dtProvince = code.DatabaseQuery(conn, commp);
            DataTable dtDistrict = code.DatabaseQuery(conn, commd);
            DataTable dtSubDistrict = code.DatabaseQuery(conn, commsd);
            try
            {
                if (dtProvince.Rows.Count <= 0)
                {
                    ClientScript.RegisterStartupScript(this.GetType(), "myalert", "alert('ไม่พบหมายเลขไปรษณีย์ที่คุณระบุ');", true);
                    TextBox6.Enabled = true;
                }
                else
                {

                        List<string> ddl = new List<string>();

                        for (int i = 0; i < dtProvince.Rows.Count; i++)
                        {
                            ddl.Add(dtProvince.Rows[i][0].ToString());
                        }
                        DropDownList2.DataSource = ddl;
                        DropDownList2.DataBind();
                        //DropDownList5.SelectedIndex = 0;

                        ddl.Clear();

                        for (int i = 0; i < dtDistrict.Rows.Count; i++)
                        {
                            ddl.Add(dtDistrict.Rows[i][0].ToString());
                        }
                        DropDownList3.DataSource = ddl;
                        DropDownList3.DataBind();
                        //DropDownList6.SelectedIndex = 0;

                        ddl.Clear();

                        for (int i = 0; i < dtSubDistrict.Rows.Count; i++)
                        {
                            ddl.Add(dtSubDistrict.Rows[i][0].ToString());
                        }
                        DropDownList4.DataSource = ddl;
                        DropDownList4.DataBind();
                        //DropDownList7.SelectedIndex = 0;
                }
            }
            catch { }
        }

        protected void Button6_Click(object sender, EventArgs e)
        {
            TextBox6.Enabled = true;
            TextBox6.Text = string.Empty;
            DropDownList2.Items.Clear();
            DropDownList3.Items.Clear();
            DropDownList4.Items.Clear();
        }

        protected void Button5_Click(object sender, EventArgs e)
        {
            TextBox6.Enabled = false;
            getAddress("SELECT DISTINCT [Province] FROM [Address] Where PostalCode = '" + TextBox6.Text + "' order by Province ASC", "SELECT DISTINCT [District] FROM [Address] Where PostalCode = '" + TextBox6.Text + "' order by District ASC", "SELECT DISTINCT [SubDistrict] FROM [Address] Where PostalCode = '" + TextBox6.Text + "' order by SubDistrict ASC");

        }

        protected void Button2_Click(object sender, EventArgs e)
        {
            // ✅ Validation: ต้องมีชื่อและเบอร์โทรศัพท์
            if (string.IsNullOrEmpty(TextBox2.Text.Trim()))
            {
                ClientScript.RegisterStartupScript(this.GetType(), "myalert", "alert('⚠️ กรุณากรอกชื่อผู้เสียภาษี / ชื่อบริษัท');", true);
                return;
            }

            if (string.IsNullOrEmpty(TextBox7.Text.Trim()))
            {
                ClientScript.RegisterStartupScript(this.GetType(), "myalert", "alert('⚠️ กรุณากรอกเบอร์โทรศัพท์');", true);
                return;
            }

            // ✅ Validation: ถ้ามี Tax ID ต้องยาว 13 หลัก
            string taxId = TextBox1.Text.Trim();
            if (!string.IsNullOrEmpty(taxId) && taxId.Length != 13)
            {
                ClientScript.RegisterStartupScript(this.GetType(), "myalert", "alert('⚠️ เลขผู้เสียภาษีต้องมี 13 หลัก (หรือเว้นว่างไว้ถ้าไม่มี)');", true);
                return;
            }

            try
            {
                DataTable dt;
                bool isDuplicate = false;

                // 🔍 Check duplicate based on available data
                if (!string.IsNullOrEmpty(taxId))
                {
                    // มี Tax ID: check ด้วย IDNumber + Branch_Number
                    dt = code.DatabaseQuery(conn,
                        $"SELECT * FROM Vendor WHERE IDNumber = '{taxId}' AND Branch_Number = '{TextBox3.Text.Trim()}'");
                    isDuplicate = dt.Rows.Count > 0;
                }
                else
                {
                    // ไม่มี Tax ID: check ด้วย Name + Phone_Number
                    dt = code.DatabaseQuery(conn,
                        $"SELECT * FROM Vendor WHERE Name = N'{TextBox2.Text.Trim().Replace("'", "''")}' AND Phone_Number = '{TextBox7.Text.Trim()}'");
                    isDuplicate = dt.Rows.Count > 0;
                }

                string addressId = CheckAddressID(TextBox6.Text, DropDownList2.SelectedValue, DropDownList3.SelectedValue, DropDownList4.SelectedValue);

                if (isDuplicate)
                {
                    // 📝 UPDATE existing vendor
                    if (!string.IsNullOrEmpty(taxId))
                    {
                        // Update by IDNumber
                        code.DatabaseInsert(conn,
                            $@"UPDATE [dbo].[Vendor] SET
                                [IDNumber] = '{taxId.Replace("'", "''")}',
                                [Vendor_Type_ID] = {DropDownList1.SelectedValue},
                                [Name] = N'{TextBox2.Text.Trim().Replace("'", "''")}',
                                [Address] = N'{TextBox4.Text.Trim().Replace("'", "''")}',
                                [Address1] = N'{TextBox5.Text.Trim().Replace("'", "''")}',
                                [Address_ID] = {addressId},
                                [Phone_Number] = '{TextBox7.Text.Trim().Replace("'", "''")}',
                                [Vendor_Group] = N'{DropDownList5.SelectedItem.Text.Replace("'", "''")}',
                                [Branch_Number] = '{TextBox3.Text.Trim().Replace("'", "''")}'
                            WHERE IDNumber = '{taxId}' AND Branch_Number = '{TextBox3.Text.Trim()}'");
                    }
                    else
                    {
                        // Update by Name + Phone_Number
                        code.DatabaseInsert(conn,
                            $@"UPDATE [dbo].[Vendor] SET
                                [Vendor_Type_ID] = {DropDownList1.SelectedValue},
                                [Name] = N'{TextBox2.Text.Trim().Replace("'", "''")}',
                                [Address] = N'{TextBox4.Text.Trim().Replace("'", "''")}',
                                [Address1] = N'{TextBox5.Text.Trim().Replace("'", "''")}',
                                [Address_ID] = {addressId},
                                [Phone_Number] = '{TextBox7.Text.Trim().Replace("'", "''")}',
                                [Vendor_Group] = N'{DropDownList5.SelectedItem.Text.Replace("'", "''")}',
                                [Branch_Number] = '{TextBox3.Text.Trim().Replace("'", "''")}'
                            WHERE Name = N'{TextBox2.Text.Trim().Replace("'", "''")}' AND Phone_Number = '{TextBox7.Text.Trim()}'");
                    }

                    ClientScript.RegisterStartupScript(this.GetType(), "success", "alert('✅ อัพเดทข้อมูล Vendor สำเร็จ');", true);
                }
                else
                {
                    // ➕ INSERT new vendor
                    string idNumberValue = string.IsNullOrEmpty(taxId) ? "NULL" : $"'{taxId.Replace("'", "''")}'";

                    code.DatabaseInsert(conn,
                        $@"INSERT INTO [dbo].[Vendor]
                            (IDNumber, Vendor_Type_ID, Name, Branch_Number, Phone_Number, Address, Address1, Address_ID, Vendor_Group)
                        VALUES (
                            {idNumberValue},
                            {DropDownList1.SelectedValue},
                            N'{TextBox2.Text.Trim().Replace("'", "''")}',
                            '{TextBox3.Text.Trim().Replace("'", "''")}',
                            '{TextBox7.Text.Trim().Replace("'", "''")}',
                            N'{TextBox4.Text.Trim().Replace("'", "''")}',
                            N'{TextBox5.Text.Trim().Replace("'", "''")}',
                            {addressId},
                            N'{DropDownList5.SelectedItem.Text.Replace("'", "''")}'
                        )");

                    ClientScript.RegisterStartupScript(this.GetType(), "success", "alert('✅ บันทึกข้อมูล Vendor สำเร็จ');", true);
                }

                // Clear form after save
                Response.Redirect("/Admin/Vendor");
            }
            catch (Exception ex)
            {
                ClientScript.RegisterStartupScript(this.GetType(), "error",
                    $"alert('❌ เกิดข้อผิดพลาด: {ex.Message}');", true);
            }
        }

        protected void TextBox3_TextChanged(object sender, EventArgs e)
        {
            if (TextBox3.Text.Length == 5)
            {
                
            }
            else { ClientScript.RegisterStartupScript(this.GetType(), "myalert", "alert('เลขสาขาไม่ครบ 5 หลัก');", true); }
        }

        protected void TextBox7_TextChanged(object sender, EventArgs e)
        {
            TextBox7.Text = TextBox7.Text.Replace("-","").Replace(" ", "");
        }

        protected void DropDownList2_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (TextBox6.Enabled == false)
            {
                getAddress("SELECT DISTINCT [Province] FROM [Address] Where PostalCode = '" + TextBox6.Text + "' AND Province = '" + DropDownList2.SelectedValue + "' order by Province ASC", "SELECT DISTINCT [District] FROM [Address] Where PostalCode = '" + TextBox6.Text + "' AND Province = '" + DropDownList2.SelectedValue + "' order by District ASC", "SELECT DISTINCT [SubDistrict] FROM [Address] Where PostalCode = '" + TextBox6.Text + "' AND Province = '" + DropDownList2.SelectedValue + "' order by SubDistrict ASC");
            }
            else
            {
                getAddress("SELECT DISTINCT [Province] FROM [Address] Where Province = N'" + DropDownList2.SelectedValue + "' order by Province ASC", "SELECT DISTINCT [District] FROM [Address] Where Province = N'" + DropDownList2.SelectedValue + "' order by District ASC", "SELECT DISTINCT [SubDistrict] FROM [Address] Where Province = N'" + DropDownList2.SelectedValue + "' order by SubDistrict ASC");
            }
        }

        protected void DropDownList3_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (TextBox6.Enabled == false)
            {
                getAddress("SELECT DISTINCT [Province] FROM [Address] Where PostalCode = '" + TextBox6.Text + "' AND District = '" + DropDownList3.SelectedValue + "' order by Province ASC", "SELECT DISTINCT [District] FROM [Address] Where PostalCode = '" + TextBox6.Text + "' AND District = '" + DropDownList3.SelectedValue + "' order by District ASC", "SELECT DISTINCT [SubDistrict] FROM [Address] Where PostalCode = '" + TextBox6.Text + "' AND District = '" + DropDownList3.SelectedValue + "' order by SubDistrict ASC");
            }
            else
            {
                getAddress("SELECT DISTINCT [Province] FROM [Address] Where District = N'" + DropDownList3.SelectedValue + "' order by Province ASC", "SELECT DISTINCT [District] FROM [Address] Where District = N'" + DropDownList3.SelectedValue + "' order by District ASC", "SELECT DISTINCT [SubDistrict] FROM [Address] Where District = N'" + DropDownList3.SelectedValue + "' order by SubDistrict ASC");
            }
        }
    }
}